#!/usr/bin/env python3
"""Generate deterministic random FFT8 vectors for RTL scoreboard tests."""

from __future__ import annotations

import random
from pathlib import Path

from test_fft8_v1_mcu32_basic import N, direct_fixed_model
from test_fft8_v2_packed_dsp import packed_fixed_model


ROOT = Path(__file__).resolve().parents[1]
CASE_COUNT = 100
SEED = 20260603


def write_vectors(path: Path, cases: list[list[int]], expected: list[list[int]]) -> None:
    with path.open("w") as f:
        for inputs, outputs in zip(cases, expected):
            if len(inputs) != 2 * N or len(outputs) != 2 * N:
                raise AssertionError("each case must contain 16 inputs and 16 outputs")
            f.write(" ".join(str(value) for value in inputs + outputs))
            f.write("\n")


def main() -> None:
    rng = random.Random(SEED)
    cases = [[rng.randint(-32768, 32767) for _ in range(2 * N)] for _ in range(CASE_COUNT)]

    v1_expected = [direct_fixed_model(values) for values in cases]
    v5_expected = [packed_fixed_model(values) for values in cases]

    write_vectors(ROOT / "tb" / "fft8_v1_random_vectors.txt", cases, v1_expected)
    write_vectors(ROOT / "tb" / "fft8_v5_random_vectors.txt", cases, v5_expected)

    print(f"wrote {CASE_COUNT} cases with seed {SEED}")


if __name__ == "__main__":
    main()
