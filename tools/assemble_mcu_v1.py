#!/usr/bin/env python3
"""
Assembler/encoder for the first-version MCU instruction format.

The encoder follows the two latest project documents:

* 第一版MCU指令格式说明.md
* 第一版MCU对成员A接口说明.md

It intentionally supports only the subset used by asm/fft8_v1_mcu32_basic.s.
Running it validates that every instruction is encodable as a 32-bit machine
word with imm12 data/memory immediates and PC+8 branch offsets.
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path

COND = {
    "B": 0xE,
    "BEQ": 0x0,
    "BNE": 0x1,
}

DATA_OPCODE = {
    "AND": 0b0000,
    "ADD": 0b0100,
    "SUB": 0b0010,
    "ORR": 0b1100,
    "MOV": 0b1101,
    "CMP": 0b1010,
    "MUL": 0b1001,
    "ASR": 0b1111,
}

DATA_OPS = set(DATA_OPCODE)
MEM_OPS = {"LDR", "STR"}
BRANCH_OPS = {"B", "BEQ", "BNE"}
SUPPORTED_OPS = DATA_OPS | MEM_OPS | BRANCH_OPS


@dataclass
class Instruction:
    lineno: int
    text: str
    pc: int


@dataclass
class Program:
    instructions: list[Instruction]
    labels: dict[str, int]


def parse_source(path: Path) -> Program:
    instructions: list[Instruction] = []
    labels: dict[str, int] = {}

    for lineno, raw_line in enumerate(path.read_text().splitlines(), start=1):
        line = raw_line.split(";", 1)[0].strip()
        if not line:
            continue
        if line.endswith(":"):
            label = line[:-1].strip()
            if not label:
                raise ValueError(f"{path}:{lineno}: empty label")
            if label in labels:
                raise ValueError(f"{path}:{lineno}: duplicate label {label}")
            labels[label] = 4 * len(instructions)
            continue
        op = line.split(None, 1)[0].upper()
        if op not in SUPPORTED_OPS:
            raise ValueError(f"{path}:{lineno}: unsupported instruction {op}: {line}")
        instructions.append(Instruction(lineno=lineno, text=line, pc=4 * len(instructions)))

    return Program(instructions=instructions, labels=labels)


def split_args(text: str) -> list[str]:
    return [part.strip() for part in text.split(",")]


def parse_reg(text: str) -> int:
    match = re.fullmatch(r"R([0-9]|1[0-5])", text.strip().upper())
    if not match:
        raise ValueError(f"bad register {text!r}")
    return int(match.group(1))


def parse_imm(text: str, bits: int, *, signed: bool = False) -> int:
    text = text.strip()
    if text.startswith("#"):
        text = text[1:]
    value = int(text, 0)
    if signed:
        lo = -(1 << (bits - 1))
        hi = (1 << (bits - 1)) - 1
        if not lo <= value <= hi:
            raise ValueError(f"signed immediate {value} does not fit {bits} bits")
        return value & ((1 << bits) - 1)
    if not 0 <= value < (1 << bits):
        raise ValueError(f"immediate {value} does not fit unsigned {bits} bits")
    return value


def is_imm(text: str) -> bool:
    return text.strip().startswith("#")


def parse_mem_operand(text: str) -> tuple[int, int]:
    match = re.fullmatch(
        r"\[(R[0-9]|R1[0-5])\s*(?:\+\s*#?(\d+)|,\s*#?(\d+))\]",
        text.strip().upper(),
    )
    if not match:
        raise ValueError(f"bad memory operand {text!r}")
    rn = parse_reg(match.group(1))
    imm_text = match.group(2) if match.group(2) is not None else match.group(3)
    return rn, parse_imm(imm_text, 12)


def encode_data(op: str, args: list[str]) -> int:
    cond = 0xE
    opcode = DATA_OPCODE[op]
    s_bit = 1 if op == "CMP" else 0
    i_bit = 0
    rn = 0
    rd = 0
    operand2 = 0

    if op == "MOV":
        if len(args) != 2:
            raise ValueError("MOV expects 2 operands")
        rd = parse_reg(args[0])
        if is_imm(args[1]):
            i_bit = 1
            operand2 = parse_imm(args[1], 12)
        else:
            operand2 = parse_reg(args[1])
    elif op == "CMP":
        if len(args) != 2:
            raise ValueError("CMP expects 2 operands")
        rn = parse_reg(args[0])
        if is_imm(args[1]):
            i_bit = 1
            operand2 = parse_imm(args[1], 12)
        else:
            operand2 = parse_reg(args[1])
    elif op == "MUL":
        if len(args) != 3:
            raise ValueError("MUL expects 3 operands")
        rd = parse_reg(args[0])
        rn = parse_reg(args[1])
        operand2 = parse_reg(args[2])
    elif op == "ASR":
        if len(args) != 3:
            raise ValueError("ASR expects 3 operands")
        rd = parse_reg(args[0])
        rn = parse_reg(args[1])
        if not is_imm(args[2]):
            raise ValueError("first-version ASR only supports immediate shift")
        i_bit = 1
        operand2 = parse_imm(args[2], 12)
    else:
        if len(args) != 3:
            raise ValueError(f"{op} expects 3 operands")
        rd = parse_reg(args[0])
        rn = parse_reg(args[1])
        if is_imm(args[2]):
            i_bit = 1
            operand2 = parse_imm(args[2], 12)
        else:
            operand2 = parse_reg(args[2])

    if i_bit == 0 and operand2 > 0xF:
        raise ValueError("register operand2 must fit Rm[3:0]")

    return (
        (cond << 28)
        | (i_bit << 25)
        | (opcode << 21)
        | (s_bit << 20)
        | (rn << 16)
        | (rd << 12)
        | operand2
    )


def encode_mem(op: str, args: list[str]) -> int:
    if len(args) != 2:
        raise ValueError(f"{op} expects 2 operands")
    rd = parse_reg(args[0])
    rn, imm = parse_mem_operand(args[1])
    l_bit = 1 if op == "LDR" else 0
    u_bit = 1
    return (
        (0xE << 28)
        | (0b01 << 26)
        | (l_bit << 25)
        | (u_bit << 24)
        | (rn << 16)
        | (rd << 12)
        | imm
    )


def encode_branch(op: str, args: list[str], pc: int, labels: dict[str, int]) -> int:
    if len(args) != 1:
        raise ValueError(f"{op} expects 1 label operand")
    label = args[0]
    if label not in labels:
        raise ValueError(f"unknown branch target {label!r}")
    target = labels[label]
    delta = target - (pc + 8)
    if delta % 4 != 0:
        raise ValueError(f"branch target {label!r} is not word-aligned")
    imm = delta // 4
    imm24 = parse_imm(str(imm), 24, signed=True)
    return (COND[op] << 28) | (0b10 << 26) | imm24


def encode_instruction(inst: Instruction, labels: dict[str, int]) -> int:
    op, _, arg_text = inst.text.partition(" ")
    op = op.upper()
    args = split_args(arg_text) if arg_text else []
    try:
        if op in DATA_OPS:
            return encode_data(op, args)
        if op in MEM_OPS:
            return encode_mem(op, args)
        return encode_branch(op, args, inst.pc, labels)
    except Exception as exc:
        raise ValueError(f"line {inst.lineno}: {inst.text}: {exc}") from exc


def encode_program(program: Program) -> list[int]:
    return [encode_instruction(inst, program.labels) for inst in program.instructions]


def main() -> None:
    parser = argparse.ArgumentParser(description="Encode first-version MCU assembly into 32-bit words.")
    parser.add_argument("asm", type=Path, nargs="?", default=Path("asm/fft8_v1_mcu32_basic.s"))
    parser.add_argument("--mem-out", type=Path, help="write hex words, one per line")
    parser.add_argument("--lst-out", type=Path, help="write address/word/source listing")
    args = parser.parse_args()

    program = parse_source(args.asm)
    words = encode_program(program)

    if args.mem_out:
        args.mem_out.write_text("".join(f"{word:08X}\n" for word in words))
    if args.lst_out:
        lines = []
        for inst, word in zip(program.instructions, words):
            lines.append(f"{inst.pc:04X}: {word:08X}    {inst.text}\n")
        args.lst_out.write_text("".join(lines))

    print(f"encoded {len(words)} instructions from {args.asm}")
    if "DONE" in program.labels:
        done_pc = program.labels["DONE"]
        done_index = done_pc // 4
        if done_index < len(words):
            print(f"DONE at PC 0x{done_pc:04X}, word 0x{words[done_index]:08X}")


if __name__ == "__main__":
    main()
