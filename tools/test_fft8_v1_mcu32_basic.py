#!/usr/bin/env python3
"""
Host-side checker for asm/fft8_v1_mcu32_basic.s.

This script directly interprets the small ARM-like instruction subset used by
the first MCU32 FFT program. It checks:

1. The assembly only uses the intended first-version instruction subset.
2. The input program-view stride is +4 and sign-extends 16-bit data into registers.
3. The work RAM stride is +4 and stores 32-bit signed intermediate values.
4. The output program-view stride is +4 and produces bit-reversal FFT/8 results.
5. Immediates used by data-processing and memory instructions fit imm12.
"""

from __future__ import annotations

import cmath
import math
import random
import re
from dataclasses import dataclass
from pathlib import Path

N = 8
INPUT_BASE = 0
WORK_BASE = 0x100
OUTPUT_BASE = 0x200
WORK_BYTES = 64
IO_BYTES = 64
INV_SQRT2_Q15 = 23170
BIT_REVERSAL_ORDER = [0, 4, 2, 6, 1, 5, 3, 7]
ALLOWED_OPS = {"MOV", "ADD", "SUB", "CMP", "LDR", "STR", "B", "BEQ", "BNE", "MUL", "ASR"}


@dataclass
class Program:
    instructions: list[tuple[int, str]]
    labels: dict[str, int]


@dataclass
class RunResult:
    output: list[int]
    steps_before_done: int
    timed_steps: int


def s16(value: int) -> int:
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value


def s32(value: int) -> int:
    value &= 0xFFFFFFFF
    return value - 0x100000000 if value & 0x80000000 else value


def asr(value: int, bits: int) -> int:
    return s32(value) >> bits


def add32(a: int, b: int) -> int:
    return s32(s32(a) + s32(b))


def sub32(a: int, b: int) -> int:
    return s32(s32(a) - s32(b))


def mul32(a: int, b: int) -> int:
    return s32(s32(a) * s32(b))


def load_program(path: Path) -> Program:
    instructions: list[tuple[int, str]] = []
    labels: dict[str, int] = {}

    for lineno, line in enumerate(path.read_text().splitlines(), start=1):
        line = line.split(";", 1)[0].strip()
        if not line:
            continue
        if line.endswith(":"):
            label = line[:-1]
            if not label:
                raise ValueError(f"{path}:{lineno}: empty label")
            labels[label] = len(instructions)
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


def split_args(text: str) -> list[str]:
    return [part.strip() for part in text.split(",")]


def is_input_addr(addr: int) -> bool:
    return INPUT_BASE <= addr < INPUT_BASE + IO_BYTES and (addr - INPUT_BASE) % 4 == 0


def is_work_addr(addr: int) -> bool:
    return WORK_BASE <= addr < WORK_BASE + WORK_BYTES and (addr - WORK_BASE) % 4 == 0


def is_output_addr(addr: int) -> bool:
    return OUTPUT_BASE <= addr < OUTPUT_BASE + IO_BYTES and (addr - OUTPUT_BASE) % 4 == 0


def run_program(program: Program, input_values: list[int]) -> RunResult:
    if len(input_values) != 2 * N:
        raise ValueError("expected 16 signed input values: re0, im0, ..., re7, im7")

    regs = [0] * 16
    flags = {"Z": False, "N": False}
    input_mem = {INPUT_BASE + 4 * i: s16(value) for i, value in enumerate(input_values)}
    work_mem: dict[int, int] = {}
    output_mem: dict[int, int] = {}

    pc = program.labels.get("START", 0)
    steps = 0
    timing_active = False
    timed_steps = 0
    last_output_timed_steps = 0

    def read_mem(addr: int) -> int:
        if is_input_addr(addr):
            return input_mem[addr]
        if is_work_addr(addr):
            return work_mem.get(addr, 0)
        raise AssertionError(f"read from unmapped address {addr}")

    def write_mem(addr: int, value: int) -> None:
        if is_work_addr(addr):
            work_mem[addr] = s32(value)
            return
        if is_output_addr(addr):
            output_mem[addr] = s16(value)
            return
        raise AssertionError(f"write to unmapped address {addr}")

    while True:
        if steps > 5000:
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
            elif op in {"ADD", "SUB", "MUL"}:
                rd_text, ra_text, rb_text = split_args(arg_text)
                rd = parse_reg(rd_text)
                a = operand_value(ra_text, regs)
                b = operand_value(rb_text, regs)
                if op == "ADD":
                    regs[rd] = add32(a, b)
                elif op == "SUB":
                    regs[rd] = sub32(a, b)
                else:
                    regs[rd] = mul32(a, b)
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
                if is_input_addr(addr) and not timing_active:
                    timing_active = True
                    count_this = True
                regs[parse_reg(rd_text)] = s32(read_mem(addr))
            elif op == "STR":
                rd_text, mem_text = split_args(arg_text)
                addr = parse_mem(mem_text, regs)
                write_mem(addr, regs[parse_reg(rd_text)])
                external_output_write = is_output_addr(addr)
            elif op == "B":
                next_pc = program.labels[arg_text.strip()]
            elif op == "BEQ":
                if flags["Z"]:
                    next_pc = program.labels[arg_text.strip()]
            elif op == "BNE":
                if not flags["Z"]:
                    next_pc = program.labels[arg_text.strip()]
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


def mul_inv_sqrt2(value: int) -> int:
    return asr(mul32(value, INV_SQRT2_Q15), 15)


def butterfly_w0(values: list[tuple[int, int]], a: int, b: int) -> None:
    ar, ai = values[a]
    br, bi = values[b]
    values[a] = (asr(add32(ar, br), 1), asr(add32(ai, bi), 1))
    values[b] = (asr(sub32(ar, br), 1), asr(sub32(ai, bi), 1))


def butterfly_neg_j(values: list[tuple[int, int]], a: int, b: int) -> None:
    ar, ai = values[a]
    br, bi = values[b]
    sr = asr(add32(ar, br), 1)
    si = asr(add32(ai, bi), 1)
    dr = asr(sub32(ar, br), 1)
    di = asr(sub32(ai, bi), 1)
    values[a] = (sr, si)
    values[b] = (di, sub32(0, dr))


def butterfly_w1(values: list[tuple[int, int]], a: int, b: int) -> None:
    ar, ai = values[a]
    br, bi = values[b]
    sr = asr(add32(ar, br), 1)
    si = asr(add32(ai, bi), 1)
    dr = asr(sub32(ar, br), 1)
    di = asr(sub32(ai, bi), 1)
    values[a] = (sr, si)
    values[b] = (mul_inv_sqrt2(add32(dr, di)), mul_inv_sqrt2(sub32(di, dr)))


def butterfly_w3(values: list[tuple[int, int]], a: int, b: int) -> None:
    ar, ai = values[a]
    br, bi = values[b]
    sr = asr(add32(ar, br), 1)
    si = asr(add32(ai, bi), 1)
    dr = asr(sub32(ar, br), 1)
    di = asr(sub32(ai, bi), 1)
    values[a] = (sr, si)
    values[b] = (mul_inv_sqrt2(sub32(di, dr)), sub32(0, mul_inv_sqrt2(add32(dr, di))))


def direct_fixed_model(input_values: list[int]) -> list[int]:
    values = [(s16(input_values[2 * i]), s16(input_values[2 * i + 1])) for i in range(N)]

    butterfly_w0(values, 0, 4)
    butterfly_w1(values, 1, 5)
    butterfly_neg_j(values, 2, 6)
    butterfly_w3(values, 3, 7)

    butterfly_w0(values, 0, 2)
    butterfly_neg_j(values, 1, 3)
    butterfly_w0(values, 4, 6)
    butterfly_neg_j(values, 5, 7)

    butterfly_w0(values, 0, 1)
    butterfly_w0(values, 2, 3)
    butterfly_w0(values, 4, 5)
    butterfly_w0(values, 6, 7)

    output: list[int] = []
    for real, imag in values:
        output.extend([s16(real), s16(imag)])
    return output


def dft_reference_scaled_br(input_values: list[int]) -> list[complex]:
    samples = [complex(s16(input_values[2 * i]), s16(input_values[2 * i + 1])) for i in range(N)]
    natural: list[complex] = []
    for k in range(N):
        acc = 0j
        for n, sample in enumerate(samples):
            acc += sample * cmath.exp(-2j * math.pi * k * n / N)
        natural.append(acc / N)
    return [natural[index] for index in BIT_REVERSAL_ORDER]


def print_flat_vector(label: str, values: list[int]) -> None:
    print(label)
    for i in range(N):
        print(f"  [{i}] real={values[2 * i]:7d}, imag={values[2 * i + 1]:7d}")


def check_float_tolerance(input_values: list[int], output_values: list[int], tolerance: float) -> None:
    reference = dft_reference_scaled_br(input_values)
    worst = 0.0
    for i, expected in enumerate(reference):
        worst = max(
            worst,
            abs(output_values[2 * i] - expected.real),
            abs(output_values[2 * i + 1] - expected.imag),
        )
    if worst > tolerance:
        print_flat_vector("input:", input_values)
        print_flat_vector("fixed output:", output_values)
        print("floating DFT / 8 in bit-reversal order:")
        for i, value in enumerate(reference):
            print(f"  [{i}] real={value.real:10.3f}, imag={value.imag:10.3f}")
        raise AssertionError(f"worst fixed-point error {worst:.3f} exceeds tolerance {tolerance}")


def run_case(program: Program, input_values: list[int], tolerance: float = 8.0) -> RunResult:
    interpreted = run_program(program, input_values)
    direct = direct_fixed_model(input_values)
    if interpreted.output != direct:
        print_flat_vector("input:", input_values)
        print_flat_vector("interpreted assembly output:", interpreted.output)
        print_flat_vector("direct fixed model output:", direct)
        raise AssertionError("interpreted assembly does not match direct fixed model")
    check_float_tolerance(input_values, interpreted.output, tolerance)
    return interpreted


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    program = load_program(root / "asm" / "fft8_v1_mcu32_basic.s")

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
        result = run_case(program, values)

    print(f"{len(program.instructions)} instructions before labels/comments.")
    print(f"{result.steps_before_done} instructions executed before DONE self-loop.")
    print(f"{result.timed_steps} instructions from first input read through last output write.")
    print(f"{len(edge_cases)} edge-case tests passed.")
    print("1000 random moderate-amplitude tests passed.")
    print("5000 random full-range tests passed.")


if __name__ == "__main__":
    main()
