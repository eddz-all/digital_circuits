#!/usr/bin/env python3
"""
Host-side checker for asm/fft8_dif_q15_armv7em.s.

This does not execute the ARM assembly. It simulates the same packed Q15
radix-2 DIF operations on a normal computer so the FFT dataflow, signs, and
output order can be checked before moving to the FPGA soft MCU.
"""

from __future__ import annotations

import cmath
import math
import random

INV_SQRT2_Q15 = 0x5A82
N = 8


def s16(x: int) -> int:
    x &= 0xFFFF
    return x - 0x10000 if x & 0x8000 else x


def pack(real: int, imag: int) -> int:
    return ((imag & 0xFFFF) << 16) | (real & 0xFFFF)


def unpack(word: int) -> tuple[int, int]:
    return s16(word), s16(word >> 16)


def shadd16(a: int, b: int) -> int:
    ar, ai = unpack(a)
    br, bi = unpack(b)
    return pack((ar + br) >> 1, (ai + bi) >> 1)


def shsub16(a: int, b: int) -> int:
    ar, ai = unpack(a)
    br, bi = unpack(b)
    return pack((ar - br) >> 1, (ai - bi) >> 1)


def cmul_w1(z: int) -> int:
    real, imag = unpack(z)
    out_real = (INV_SQRT2_Q15 * (real + imag)) >> 15
    out_imag = (INV_SQRT2_Q15 * (imag - real)) >> 15
    return pack(out_real, out_imag)


def cmul_w3(z: int) -> int:
    real, imag = unpack(z)
    out_real = (INV_SQRT2_Q15 * (imag - real)) >> 15
    out_imag = (-INV_SQRT2_Q15 * (real + imag)) >> 15
    return pack(out_real, out_imag)


def cmul_neg_j(z: int) -> int:
    real, imag = unpack(z)
    return pack(imag, -real)


def fft8_kernel_model(samples: list[int]) -> list[int]:
    if len(samples) != N:
        raise ValueError("expected exactly 8 packed complex samples")

    r = samples[:]

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
    r[7] = cmul_w3(shsub16(r[3], r[7]))
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

    return r


def dft_reference_scaled_br(samples: list[int]) -> list[complex]:
    x = [complex(*unpack(word)) for word in samples]
    natural = []
    for k in range(N):
        acc = 0j
        for n, value in enumerate(x):
            acc += value * cmath.exp(-2j * math.pi * k * n / N)
        natural.append(acc / N)
    bit_reversal_order = [0, 4, 2, 6, 1, 5, 3, 7]
    return [natural[i] for i in bit_reversal_order]


def print_vector(label: str, values: list[int]) -> None:
    print(label)
    for i, word in enumerate(values):
        real, imag = unpack(word)
        print(f"  [{i}] real={real:6d}, imag={imag:6d}, packed=0x{word:08X}")


def check_against_float_reference(samples: list[int], tolerance: float = 4.0) -> None:
    got = fft8_kernel_model(samples)
    ref = dft_reference_scaled_br(samples)
    worst = 0.0
    for word, expected in zip(got, ref):
        real, imag = unpack(word)
        worst = max(worst, abs(real - expected.real), abs(imag - expected.imag))
    if worst > tolerance:
        print_vector("input:", samples)
        print_vector("kernel:", got)
        print("float DFT / 8 in bit-reversal order:")
        for i, value in enumerate(ref):
            print(f"  [{i}] real={value.real:9.3f}, imag={value.imag:9.3f}")
        raise AssertionError(f"worst error {worst:.3f} exceeds tolerance {tolerance}")


def main() -> None:
    impulse = [pack(32760, 0)] + [pack(0, 0)] * 7
    print_vector("impulse x0 output:", fft8_kernel_model(impulse))

    shifted_impulse = [pack(0, 0), pack(32760, 0)] + [pack(0, 0)] * 6
    print_vector("impulse x1 output:", fft8_kernel_model(shifted_impulse))

    rng = random.Random(0)
    for _ in range(1000):
        # Keep amplitudes moderate so the no-saturation model is compared in
        # the intended operating range.
        samples = [pack(rng.randint(-12000, 12000), rng.randint(-12000, 12000)) for _ in range(N)]
        check_against_float_reference(samples)

    print("1000 random moderate-amplitude tests passed.")


if __name__ == "__main__":
    main()

