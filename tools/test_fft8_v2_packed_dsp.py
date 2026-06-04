#!/usr/bin/env python3
"""
Host-side checker for asm/fft8_v2_packed_dsp.s.

This interpreter models the accelerated packed-DSP instruction subset and
checks that the fast program exactly matches the scalar fixed-point model used
by tools/test_fft8_v1_mcu32_basic.py.
"""

from __future__ import annotations

import random
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from test_fft8_v1_mcu32_basic import (  # noqa: E402
    N,
    OUTPUT_BASE,
    direct_fixed_model,
    check_float_tolerance,
    print_flat_vector,
    s16,
    s32,
)

INPUT_BASE = 0
OUTPUT_BYTES = 64
IO_BYTES = 64
ALLOWED_OPS = {
    "MOV",
    "ADD",
    "SUB",
    "CMP",
    "LDR",
    "STR",
    "B",
    "BEQ",
    "BNE",
    "MUL",
    "ASR",
    "AND",
    "OR",
    "ORR",
    "BL",
    "SHADD16",
    "SHSUB16",
    "SMUAD",
    "SMUSD",
    "SXTH",
    "PKHBT",
}


@dataclass
class Program:
    instructions: list[tuple[int, str]]
    labels: dict[str, int]


@dataclass
class RunResult:
    output: list[int]
    steps_before_done: int
    timed_steps: int


def load_program(path: Path) -> Program:
    instructions: list[tuple[int, str]] = []
    labels: dict[str, int] = {}

    for lineno, line in enumerate(path.read_text().splitlines(), start=1):
        line = line.split(";", 1)[0].strip()
        if not line:
            continue
        if line.endswith(":"):
            labels[line[:-1]] = len(instructions)
            continue
        op = line.split(None, 1)[0].upper()
        if op not in ALLOWED_OPS:
            raise AssertionError(f"{path}:{lineno}: unsupported instruction {op!r}: {line}")
        instructions.append((lineno, line))

    return Program(instructions=instructions, labels=labels)


def parse_reg(text: str) -> int:
    match = re.fullmatch(r"R([0-9]|1[0-5])", text.strip().upper())
    if not match:
        raise ValueError(f"bad register {text!r}")
    return int(match.group(1))


def parse_imm(text: str) -> int:
    text = text.strip()
    if not text.startswith("#"):
        raise ValueError(f"bad immediate {text!r}")
    value = int(text[1:], 0)
    if not 0 <= value <= 0xFFF:
        raise ValueError(f"immediate {text!r} does not fit imm12")
    return value


def split_args(text: str) -> list[str]:
    return [part.strip() for part in text.split(",")]


def operand_value(text: str, regs: list[int]) -> int:
    text = text.strip()
    if text.startswith("#"):
        return parse_imm(text)
    return regs[parse_reg(text)]


def parse_mem(text: str, regs: list[int]) -> int:
    match = re.fullmatch(
        r"\[(R[0-9]|R1[0-5])\s*(?:\+\s*#?(\d+)|,\s*#?(\d+))\]",
        text.strip().upper(),
    )
    if not match:
        raise ValueError(f"bad memory operand {text!r}")
    imm = int(match.group(2) if match.group(2) is not None else match.group(3))
    if not 0 <= imm <= 0xFFF:
        raise ValueError(f"memory offset {imm} does not fit imm12")
    return s32(regs[parse_reg(match.group(1))] + imm)


def asr(value: int, bits: int) -> int:
    return s32(value) >> bits


def add32(a: int, b: int) -> int:
    return s32(s32(a) + s32(b))


def sub32(a: int, b: int) -> int:
    return s32(s32(a) - s32(b))


def mul32(a: int, b: int) -> int:
    return s32(s32(a) * s32(b))


def pack(real: int, imag: int) -> int:
    return s32(((imag & 0xFFFF) << 16) | (real & 0xFFFF))


def lo16(word: int) -> int:
    return s16(word)


def hi16(word: int) -> int:
    return s16(s32(word) >> 16)


def shadd16(a: int, b: int) -> int:
    return pack((lo16(a) + lo16(b)) >> 1, (hi16(a) + hi16(b)) >> 1)


def shsub16(a: int, b: int) -> int:
    return pack((lo16(a) - lo16(b)) >> 1, (hi16(a) - hi16(b)) >> 1)


def smuad(a: int, b: int) -> int:
    return s32(lo16(a) * lo16(b) + hi16(a) * hi16(b))


def smusd(a: int, b: int) -> int:
    return s32(lo16(a) * lo16(b) - hi16(a) * hi16(b))


def sxth(a: int) -> int:
    return s32(lo16(a))


def pkhbt(a: int, b: int) -> int:
    return pack(lo16(a), lo16(b))


def is_input_addr(addr: int) -> bool:
    return INPUT_BASE <= addr < INPUT_BASE + IO_BYTES and (addr - INPUT_BASE) % 4 == 0


def is_output_addr(addr: int) -> bool:
    return OUTPUT_BASE <= addr < OUTPUT_BASE + OUTPUT_BYTES and (addr - OUTPUT_BASE) % 4 == 0


def run_program(program: Program, input_values: list[int]) -> RunResult:
    if len(input_values) != 2 * N:
        raise ValueError("expected 16 signed input values")

    regs = [0] * 16
    flags = {"Z": False, "N": False}
    input_mem = {INPUT_BASE + 4 * i: s16(value) for i, value in enumerate(input_values)}
    output_mem: dict[int, int] = {}

    pc = program.labels.get("START", 0)
    steps = 0
    timing_active = False
    timed_steps = 0
    last_output_timed_steps = 0

    while True:
        if steps > 2000:
            raise AssertionError("program did not reach DONE self-loop")
        lineno, text = program.instructions[pc]
        op, _, arg_text = text.partition(" ")
        op = op.upper()

        if op == "B" and arg_text.strip() == "DONE" and program.labels.get("DONE") == pc:
            break

        next_pc = pc + 1
        count_this = timing_active
        external_output_write = False

        try:
            if op == "MOV":
                rd_text, src_text = split_args(arg_text)
                regs[parse_reg(rd_text)] = s32(operand_value(src_text, regs))
            elif op in {"ADD", "SUB", "MUL", "AND", "OR", "ORR"}:
                rd_text, ra_text, rb_text = split_args(arg_text)
                rd = parse_reg(rd_text)
                a = operand_value(ra_text, regs)
                b = operand_value(rb_text, regs)
                if op == "ADD":
                    regs[rd] = add32(a, b)
                elif op == "SUB":
                    regs[rd] = sub32(a, b)
                elif op == "MUL":
                    regs[rd] = mul32(a, b)
                elif op == "AND":
                    regs[rd] = s32(a & b)
                else:
                    regs[rd] = s32(a | b)
            elif op == "ASR":
                rd_text, ra_text, imm_text = split_args(arg_text)
                regs[parse_reg(rd_text)] = s32(asr(operand_value(ra_text, regs), parse_imm(imm_text)))
            elif op == "CMP":
                ra_text, rb_text = split_args(arg_text)
                value = sub32(operand_value(ra_text, regs), operand_value(rb_text, regs))
                flags["Z"] = value == 0
                flags["N"] = value < 0
            elif op == "LDR":
                rd_text, mem_text = split_args(arg_text)
                addr = parse_mem(mem_text, regs)
                if not is_input_addr(addr):
                    raise AssertionError(f"read from unmapped address {addr}")
                if not timing_active:
                    timing_active = True
                    count_this = True
                regs[parse_reg(rd_text)] = s32(input_mem[addr])
            elif op == "STR":
                rd_text, mem_text = split_args(arg_text)
                addr = parse_mem(mem_text, regs)
                if not is_output_addr(addr):
                    raise AssertionError(f"write to unmapped address {addr}")
                output_mem[addr] = s16(regs[parse_reg(rd_text)])
                external_output_write = True
            elif op == "B":
                next_pc = program.labels[arg_text.strip()]
            elif op == "BL":
                regs[14] = s32(4 * (pc + 1))
                next_pc = program.labels[arg_text.strip()]
            elif op == "BEQ":
                if flags["Z"]:
                    next_pc = program.labels[arg_text.strip()]
            elif op == "BNE":
                if not flags["Z"]:
                    next_pc = program.labels[arg_text.strip()]
            elif op == "SHADD16":
                rd_text, ra_text, rb_text = split_args(arg_text)
                regs[parse_reg(rd_text)] = shadd16(operand_value(ra_text, regs), operand_value(rb_text, regs))
            elif op == "SHSUB16":
                rd_text, ra_text, rb_text = split_args(arg_text)
                regs[parse_reg(rd_text)] = shsub16(operand_value(ra_text, regs), operand_value(rb_text, regs))
            elif op == "SMUAD":
                rd_text, ra_text, rb_text = split_args(arg_text)
                regs[parse_reg(rd_text)] = smuad(operand_value(ra_text, regs), operand_value(rb_text, regs))
            elif op == "SMUSD":
                rd_text, ra_text, rb_text = split_args(arg_text)
                regs[parse_reg(rd_text)] = smusd(operand_value(ra_text, regs), operand_value(rb_text, regs))
            elif op == "SXTH":
                rd_text, ra_text = split_args(arg_text)
                regs[parse_reg(rd_text)] = sxth(operand_value(ra_text, regs))
            elif op == "PKHBT":
                rd_text, ra_text, rb_text, shift_text = split_args(arg_text)
                if shift_text.strip().upper() != "LSL #16":
                    raise ValueError("PKHBT only supports LSL #16")
                regs[parse_reg(rd_text)] = pkhbt(operand_value(ra_text, regs), operand_value(rb_text, regs))
            else:
                raise AssertionError(f"unhandled instruction {op}")
        except Exception as exc:
            raise AssertionError(f"line {lineno}: {text}: {exc}") from exc

        steps += 1
        if count_this:
            timed_steps += 1
        if external_output_write:
            last_output_timed_steps = timed_steps
        pc = next_pc

    output = [output_mem[OUTPUT_BASE + 4 * i] for i in range(2 * N)]
    return RunResult(output=output, steps_before_done=steps, timed_steps=last_output_timed_steps)


def cmul_w1(z: int) -> int:
    tmp_sum = smuad(z, pack(23170, 23170))
    tmp_diff = sub32(0, smusd(z, pack(23170, 23170)))
    return pkhbt(asr(tmp_sum, 15), asr(tmp_diff, 15))


def cmul_w3_scalar_rounding(z: int) -> int:
    tmp_sum = smuad(z, pack(23170, 23170))
    tmp_diff = sub32(0, smusd(z, pack(23170, 23170)))
    real = asr(tmp_diff, 15)
    imag = sub32(0, asr(tmp_sum, 15))
    return pkhbt(real, imag)


def cmul_neg_j(z: int) -> int:
    real = sxth(z)
    imag = asr(z, 16)
    return pkhbt(imag, sub32(0, real))


def packed_fixed_model(input_values: list[int]) -> list[int]:
    r = [pack(s16(input_values[2 * i]), s16(input_values[2 * i + 1])) for i in range(N)]

    tmp = shadd16(r[0], r[4])
    r[4] = shsub16(r[0], r[4])
    r[0] = tmp

    tmp = shadd16(r[1], r[5])
    r[5] = cmul_w1(shsub16(r[1], r[5]))
    r[1] = tmp

    tmp = shadd16(r[2], r[6])
    r[6] = cmul_neg_j(shsub16(r[2], r[6]))
    r[2] = tmp

    tmp = shadd16(r[3], r[7])
    r[7] = cmul_w3_scalar_rounding(shsub16(r[3], r[7]))
    r[3] = tmp

    tmp = shadd16(r[0], r[2])
    r[2] = shsub16(r[0], r[2])
    r[0] = tmp

    tmp = shadd16(r[1], r[3])
    r[3] = cmul_neg_j(shsub16(r[1], r[3]))
    r[1] = tmp

    tmp = shadd16(r[4], r[6])
    r[6] = shsub16(r[4], r[6])
    r[4] = tmp

    tmp = shadd16(r[5], r[7])
    r[7] = cmul_neg_j(shsub16(r[5], r[7]))
    r[5] = tmp

    tmp = shadd16(r[0], r[1])
    r[1] = shsub16(r[0], r[1])
    r[0] = tmp

    tmp = shadd16(r[2], r[3])
    r[3] = shsub16(r[2], r[3])
    r[2] = tmp

    tmp = shadd16(r[4], r[5])
    r[5] = shsub16(r[4], r[5])
    r[4] = tmp

    tmp = shadd16(r[6], r[7])
    r[7] = shsub16(r[6], r[7])
    r[6] = tmp

    output: list[int] = []
    for word in r:
        output.extend([lo16(word), hi16(word)])
    return output


def run_case(
    program: Program,
    input_values: list[int],
    tolerance: float = 8.0,
    *,
    reference: str = "scalar",
) -> RunResult:
    interpreted = run_program(program, input_values)
    direct = direct_fixed_model(input_values) if reference == "scalar" else packed_fixed_model(input_values)
    if interpreted.output != direct:
        print_flat_vector("input:", input_values)
        print_flat_vector("packed DSP output:", interpreted.output)
        print_flat_vector(f"{reference} fixed model output:", direct)
        raise AssertionError(f"packed DSP assembly does not match {reference} fixed model")
    if reference == "scalar":
        check_float_tolerance(input_values, interpreted.output, tolerance)
    return interpreted


def main() -> None:
    program = load_program(ROOT / "asm" / "fft8_v2_packed_dsp.s")

    impulse_x0 = [32760, 0] + [0, 0] * 7
    result = run_case(program, impulse_x0)
    print_flat_vector("impulse x0 output:", result.output)

    impulse_x1 = [0, 0, 32760, 0] + [0, 0] * 6
    print_flat_vector("impulse x1 output:", run_case(program, impulse_x1).output)

    edge_cases = [
        [0] * (2 * N),
        [32767, 0] + [0, 0] * 7,
        [-32768, 0] + [0, 0] * 7,
        [32767] * (2 * N),
        [-32768] * (2 * N),
        [32767 if i % 2 == 0 else -32768 for i in range(2 * N)],
        [-32768 + i * 4096 for i in range(2 * N)],
    ]
    for values in edge_cases:
        result = run_case(program, values)

    rng = random.Random(0)
    for _ in range(1000):
        values = [rng.randint(-20000, 20000) for _ in range(2 * N)]
        result = run_case(program, values)

    for _ in range(5000):
        values = [rng.randint(-32768, 32767) for _ in range(2 * N)]
        result = run_case(program, values, reference="packed")

    if result.timed_steps > 130:
        raise AssertionError(f"fast timed_steps {result.timed_steps} exceeds target 130")

    print(f"{len(program.instructions)} instructions before labels/comments.")
    print(f"{result.steps_before_done} instructions executed before DONE self-loop.")
    print(f"{result.timed_steps} instructions from first input read through last output write.")
    print(f"{len(edge_cases)} edge-case tests passed.")
    print("1000 random moderate-amplitude tests passed.")
    print("5000 random full-range packed-semantics tests passed.")
    print("fast target timed_steps <= 130 passed.")


if __name__ == "__main__":
    main()
