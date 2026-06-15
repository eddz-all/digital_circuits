#!/usr/bin/env python3
"""
Host-side checker for asm/fft8_v1_mcu32_basic.s.

The checker interprets the first-version ARM-like MCU instruction subset and
verifies the program against the teacher-provided 2026 DFT/FFT COE layout:

* input slots   0..63   DFT matrix real coefficients, Q7
* input slots  64..127  DFT matrix imaginary coefficients, Q7
* input slots 128..135  signal real samples, Q5
* input slots 136..143  signal imaginary samples, Q5
* output slots 0..7     DFT result real parts, Q12
* output slots 8..15    DFT result imaginary parts, Q12
"""

from __future__ import annotations

import random
import re
from dataclasses import dataclass
from pathlib import Path

N = 8
INPUT_SLOTS = 144
OUTPUT_SLOTS = 16
SIGNAL_REAL_BASE_SLOT = 128
SIGNAL_IMAG_BASE_SLOT = 136
MATRIX_IMAG_BASE_SLOT = 64
TEACHER_OUTPUT_BASE = 0x800
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


def add32(a: int, b: int) -> int:
    return s32(s32(a) + s32(b))


def sub32(a: int, b: int) -> int:
    return s32(s32(a) - s32(b))


def mul32(a: int, b: int) -> int:
    return s32(s32(a) * s32(b))


def asr(value: int, bits: int) -> int:
    return s32(value) >> bits


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
    return 0 <= addr < INPUT_SLOTS * 4 and addr % 4 == 0


def is_output_addr(addr: int) -> bool:
    return TEACHER_OUTPUT_BASE <= addr < TEACHER_OUTPUT_BASE + OUTPUT_SLOTS * 4 and addr % 4 == 0


def run_program(program: Program, input_values: list[int]) -> RunResult:
    if len(input_values) != INPUT_SLOTS:
        raise ValueError(f"expected {INPUT_SLOTS} signed input values")

    regs = [0] * 16
    flags = {"Z": False, "N": False}
    input_mem = {4 * i: s16(value) for i, value in enumerate(input_values)}
    output_mem: dict[int, int] = {}

    pc = program.labels.get("START", 0)
    steps = 0
    timing_active = False
    timed_steps = 0
    last_output_timed_steps = 0

    def read_mem(addr: int) -> int:
        if is_input_addr(addr):
            return input_mem[addr]
        raise AssertionError(f"read from unmapped address {addr}")

    def write_mem(addr: int, value: int) -> None:
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

    output = [output_mem[TEACHER_OUTPUT_BASE + 4 * i] for i in range(OUTPUT_SLOTS)]
    return RunResult(output=output, steps_before_done=steps, timed_steps=last_output_timed_steps)


def direct_dft_model(input_values: list[int]) -> list[int]:
    output: list[int] = []
    real_results: list[int] = []
    imag_results: list[int] = []

    for k in range(N):
        real_acc = 0
        imag_acc = 0
        for n in range(N):
            xr = s16(input_values[SIGNAL_REAL_BASE_SLOT + n])
            xi = s16(input_values[SIGNAL_IMAG_BASE_SLOT + n])
            wr = s16(input_values[k * N + n])
            wi = s16(input_values[MATRIX_IMAG_BASE_SLOT + k * N + n])
            real_acc = add32(real_acc, mul32(xr, wr))
            real_acc = sub32(real_acc, mul32(xi, wi))
            imag_acc = add32(imag_acc, mul32(xr, wi))
            imag_acc = add32(imag_acc, mul32(xi, wr))
        real_results.append(s16(real_acc))
        imag_results.append(s16(imag_acc))

    output.extend(real_results)
    output.extend(imag_results)
    return output


def parse_coe_values(path: Path) -> list[int]:
    values = [s16(int(token, 16)) for token in re.findall(r"\b[0-9a-fA-F]{4}\b", path.read_text())]
    if not values:
        raise ValueError(f"no 16-bit hex values found in {path}")
    return values


def find_sample_dir(root: Path) -> Path:
    if (root / "FFT_input.coe").exists() and (root / "FFT_output.coe").exists():
        return root
    for path in root.iterdir():
        if path.is_dir() and (path / "FFT_input.coe").exists() and (path / "FFT_output.coe").exists():
            return path
    raise FileNotFoundError("could not find a sample directory with FFT_input.coe and FFT_output.coe")


def print_flat_vector(label: str, values: list[int]) -> None:
    print(label)
    for i, value in enumerate(values):
        print(f"  [{i:02d}] {value:7d}  0x{value & 0xFFFF:04X}")


def run_case(program: Program, input_values: list[int], expected_output: list[int] | None = None) -> RunResult:
    interpreted = run_program(program, input_values)
    direct = direct_dft_model(input_values)
    if interpreted.output != direct:
        print_flat_vector("interpreted assembly output:", interpreted.output)
        print_flat_vector("direct fixed DFT output:", direct)
        raise AssertionError("interpreted assembly does not match direct fixed DFT model")
    if expected_output is not None and interpreted.output != expected_output:
        print_flat_vector("interpreted assembly output:", interpreted.output)
        print_flat_vector("teacher expected output:", expected_output)
        raise AssertionError("interpreted assembly does not match teacher FFT_output.coe")
    return interpreted


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    sample_dir = find_sample_dir(root)
    sample_input = parse_coe_values(sample_dir / "FFT_input.coe")
    sample_output = parse_coe_values(sample_dir / "FFT_output.coe")
    if len(sample_input) != INPUT_SLOTS:
        raise AssertionError(f"expected {INPUT_SLOTS} FFT input values, got {len(sample_input)}")
    if len(sample_output) != OUTPUT_SLOTS:
        raise AssertionError(f"expected {OUTPUT_SLOTS} FFT output values, got {len(sample_output)}")

    program = load_program(root / "asm" / "fft8_v1_mcu32_basic.s")
    result = run_case(program, sample_input, sample_output)
    print_flat_vector("teacher sample output:", result.output)

    rng = random.Random(20260615)
    matrix_values = sample_input[:SIGNAL_REAL_BASE_SLOT]
    for _ in range(100):
        signal_real = [rng.randint(-32, 31) for _ in range(N)]
        signal_imag = [rng.randint(-32, 31) for _ in range(N)]
        values = matrix_values + signal_real + signal_imag
        result = run_case(program, values)

    print(f"{len(program.instructions)} instructions before labels/comments.")
    print(f"{result.steps_before_done} instructions executed before DONE self-loop.")
    print(f"{result.timed_steps} instructions from first input read through last output write.")
    print("teacher sample passed.")
    print("100 random Q5 signal tests passed against the sample DFT matrix.")


if __name__ == "__main__":
    main()
