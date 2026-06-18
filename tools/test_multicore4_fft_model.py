#!/usr/bin/env python3
"""
Golden model for the 4-lane non-pipelined FFT8 prototype.

This model mirrors the proposed multicore4 controller:

* load the teacher signal window 128..143
* pack Q5 real/imag samples into Q12 complex words in bit-reversed order
* execute three radix-2 DIT stages with four butterflies per stage
* dump natural-order real0..real7 followed by imag0..imag7

The arithmetic intentionally matches the current ARM-like packed DSP semantics
used by asm/fft8_v1_mcu32_basic.s and tools/test_fft8_v1_mcu32_basic.py.
"""

from __future__ import annotations

import random
import re
from pathlib import Path

N = 8
INPUT_SLOTS = 144
OUTPUT_SLOTS = 16
SIGNAL_REAL_BASE_SLOT = 128
SIGNAL_IMAG_BASE_SLOT = 136
MATRIX_IMAG_BASE_SLOT = 64
BITREV_ORDER = (0, 4, 2, 6, 1, 5, 3, 7)


def s16(value: int) -> int:
    value &= 0xFFFF
    return value - 0x10000 if value & 0x8000 else value


def s32(value: int) -> int:
    value &= 0xFFFFFFFF
    return value - 0x100000000 if value & 0x80000000 else value


def u32(value: int) -> int:
    return value & 0xFFFFFFFF


def lo16(value: int) -> int:
    return s16(value)


def hi16(value: int) -> int:
    return s16(value >> 16)


def asr(value: int, bits: int) -> int:
    return s32(value) >> bits


def lsl(value: int, bits: int) -> int:
    return s32(s32(value) << bits)


def pkhbt(low_value: int, high_value: int, shift: int) -> int:
    high_half = (u32(high_value) << shift) & 0xFFFF0000
    return s32(high_half | (low_value & 0xFFFF))


def pack_complex(real: int, imag: int) -> int:
    return pkhbt(real, imag, 16)


def sadd16(a: int, b: int) -> int:
    return pack_complex(s16(lo16(a) + lo16(b)), s16(hi16(a) + hi16(b)))


def ssub16(a: int, b: int) -> int:
    return pack_complex(s16(lo16(a) - lo16(b)), s16(hi16(a) - hi16(b)))


def ssax(a: int, b: int) -> int:
    return pack_complex(s16(lo16(a) + hi16(b)), s16(hi16(a) - lo16(b)))


def smuad(a: int, b: int) -> int:
    return s32(lo16(a) * lo16(b) + hi16(a) * hi16(b))


def smusd(a: int, b: int) -> int:
    return s32(lo16(a) * lo16(b) - hi16(a) * hi16(b))


def pack_q5_to_q12(real_q5: int, imag_q5: int) -> int:
    real_q12 = lsl(s16(real_q5), 7)
    imag_q5_sx = s32(s16(imag_q5))
    return pkhbt(real_q12, imag_q5_sx, 23)


def twiddle(value: int, mode: int) -> int:
    coeff_pos = pack_complex(91, 91)
    coeff_neg = pack_complex(-91, -91)
    zero = 0

    if mode == 0:
        return value
    if mode == 2:
        return ssax(zero, value)
    if mode == 1:
        tmp_re = smuad(value, coeff_pos)
        tmp_im = smusd(value, coeff_neg)
        return pkhbt(asr(tmp_re, 7), tmp_im, 9)
    if mode == 3:
        tmp_re = smusd(value, coeff_neg)
        tmp_im = smuad(value, coeff_neg)
        return pkhbt(asr(tmp_re, 7), tmp_im, 9)
    raise ValueError(f"bad twiddle mode {mode}")


def butterfly(a: int, b: int, mode: int) -> tuple[int, int]:
    t = twiddle(b, mode)
    return sadd16(a, t), ssub16(a, t)


def multicore4_model(input_values: list[int]) -> list[int]:
    if len(input_values) != INPUT_SLOTS:
        raise ValueError(f"expected {INPUT_SLOTS} input values")

    buf_a = [0] * N
    buf_b = [0] * N

    for dst, src in enumerate(BITREV_ORDER):
        buf_a[dst] = pack_q5_to_q12(
            input_values[SIGNAL_REAL_BASE_SLOT + src],
            input_values[SIGNAL_IMAG_BASE_SLOT + src],
        )

    stage1 = (
        (0, 1, 0),
        (2, 3, 0),
        (4, 5, 0),
        (6, 7, 0),
    )
    for even_idx, odd_idx, mode in stage1:
        buf_b[even_idx], buf_b[odd_idx] = butterfly(buf_a[even_idx], buf_a[odd_idx], mode)

    stage2 = (
        (0, 2, 0),
        (1, 3, 2),
        (4, 6, 0),
        (5, 7, 2),
    )
    for even_idx, odd_idx, mode in stage2:
        buf_a[even_idx], buf_a[odd_idx] = butterfly(buf_b[even_idx], buf_b[odd_idx], mode)

    stage3 = (
        (0, 4, 0),
        (1, 5, 1),
        (2, 6, 2),
        (3, 7, 3),
    )
    for even_idx, odd_idx, mode in stage3:
        buf_b[even_idx], buf_b[odd_idx] = butterfly(buf_a[even_idx], buf_a[odd_idx], mode)

    return [lo16(value) for value in buf_b] + [hi16(value) for value in buf_b]


def direct_dft_model(input_values: list[int]) -> list[int]:
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
            real_acc = s32(real_acc + s32(xr * wr))
            real_acc = s32(real_acc - s32(xi * wi))
            imag_acc = s32(imag_acc + s32(xr * wi))
            imag_acc = s32(imag_acc + s32(xi * wr))
        real_results.append(s16(real_acc))
        imag_results.append(s16(imag_acc))

    return real_results + imag_results


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
    raise FileNotFoundError("could not find FFT_input.coe and FFT_output.coe")


def run_case(input_values: list[int], expected_output: list[int] | None = None) -> None:
    multicore = multicore4_model(input_values)
    direct = direct_dft_model(input_values)
    if multicore != direct:
        raise AssertionError(f"multicore model mismatch\nmulticore={multicore}\ndirect={direct}")
    if expected_output is not None and multicore != expected_output:
        raise AssertionError(f"teacher output mismatch\nmulticore={multicore}\nteacher={expected_output}")


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    sample_dir = find_sample_dir(root)
    sample_input = parse_coe_values(sample_dir / "FFT_input.coe")
    sample_output = parse_coe_values(sample_dir / "FFT_output.coe")
    if len(sample_input) != INPUT_SLOTS:
        raise AssertionError(f"expected {INPUT_SLOTS} sample input values, got {len(sample_input)}")
    if len(sample_output) != OUTPUT_SLOTS:
        raise AssertionError(f"expected {OUTPUT_SLOTS} sample output values, got {len(sample_output)}")

    run_case(sample_input, sample_output)

    rng = random.Random(20260618)
    matrix_values = sample_input[:SIGNAL_REAL_BASE_SLOT]
    for _ in range(100):
        signal_real = [rng.randint(-32, 31) for _ in range(N)]
        signal_imag = [rng.randint(-32, 31) for _ in range(N)]
        run_case(matrix_values + signal_real + signal_imag)

    print("multicore4 model teacher sample passed.")
    print("multicore4 model 100 random Q5 signal tests passed.")
    print("stage mapping: 4 butterflies per stage, DIT bit-reversed input, natural-order output.")


if __name__ == "__main__":
    main()
