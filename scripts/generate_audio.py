#!/usr/bin/env python3
"""
Generate MathGame's 10 short SFX as 16-bit mono WAVs, then convert to .caf.

These are synthesized (sine/triangle + ADSR-ish envelope, musical intervals).
They're meant as shippable-but-replaceable placeholders. Re-run any time:

    python3 scripts/generate_audio.py

Output: MathGame/Audio/Resources/<name>.caf
"""

from __future__ import annotations
import math
import struct
import wave
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "MathGame" / "Audio" / "Resources"
SR = 44100

# Equal-temperament note frequencies (Hz)
N = {
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00, "B4": 493.88,
    "C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46, "G5": 783.99, "A5": 880.00, "B5": 987.77,
    "C6": 1046.50, "E6": 1318.51, "G6": 1567.98, "B6": 1975.53,
}


def env(i: int, total: int, attack: float = 0.005, release: float = 0.45, curve: float = 4.0) -> float:
    """Linear attack to avoid clicks + exponential-ish decay for a 'ding' feel."""
    t = i / SR
    dur = total / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    # exponential decay over the whole note
    d = math.exp(-curve * (t / dur))
    # short release ramp at the very end
    r = 1.0
    rel_start = dur * (1.0 - release)
    if t > rel_start and release > 0:
        r = max(0.0, 1.0 - (t - rel_start) / (dur * release))
    return a * d * r


def osc(freq: float, i: int, kind: str) -> float:
    ph = 2 * math.pi * freq * (i / SR)
    if kind == "sine":
        return math.sin(ph)
    if kind == "triangle":
        return 2 / math.pi * math.asin(math.sin(ph))
    if kind == "square":
        return 1.0 if math.sin(ph) >= 0 else -1.0
    return math.sin(ph)


def note(freq: float, dur: float, vol: float = 0.7, kind: str = "sine", curve: float = 4.0) -> list[float]:
    total = int(SR * dur)
    return [vol * env(i, total, curve=curve) * osc(freq, i, kind) for i in range(total)]


def chord(freqs: list[float], dur: float, vol: float = 0.5, kind: str = "sine", curve: float = 3.0) -> list[float]:
    total = int(SR * dur)
    out = []
    for i in range(total):
        s = sum(osc(f, i, kind) for f in freqs) / len(freqs)
        out.append(vol * env(i, total, curve=curve) * s)
    return out


def seq(*chunks: list[float]) -> list[float]:
    out: list[float] = []
    for c in chunks:
        out.extend(c)
    return out


def mix(*chunks: list[float]) -> list[float]:
    """Overlay chunks (sum, then soft-clip)."""
    n = max(len(c) for c in chunks)
    out = [0.0] * n
    for c in chunks:
        for i, v in enumerate(c):
            out[i] += v
    return out


def soft_clip(samples: list[float]) -> list[float]:
    return [math.tanh(s) for s in samples]


def write_wav(path: Path, samples: list[float]) -> None:
    samples = soft_clip(samples)
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = int(max(-1.0, min(1.0, s)) * 32767)
            frames += struct.pack("<h", v)
        w.writeframes(bytes(frames))


def to_caf(wav: Path, caf: Path) -> None:
    subprocess.run(
        ["afconvert", "-f", "caff", "-d", f"LEI16@{SR}", str(wav), str(caf)],
        check=True,
    )


# ---- Sound design -----------------------------------------------------------

def make_sounds() -> dict[str, list[float]]:
    s: dict[str, list[float]] = {}

    # correct: bright rising two-note chime C5 -> E5
    s["correct"] = seq(note(N["C5"], 0.10, 0.7), note(N["E5"], 0.16, 0.7))

    # wrong: soft low descending triangle buzz A3-ish -> F (use A4->F4 lowered an octave feel)
    s["wrong"] = seq(
        note(N["A4"] / 2, 0.12, 0.6, kind="triangle", curve=2.5),
        note(N["F4"] / 2, 0.20, 0.6, kind="triangle", curve=2.5),
    )

    # level_up: ascending arpeggio C5-E5-G5-C6
    s["level_up"] = seq(
        note(N["C5"], 0.09, 0.6), note(N["E5"], 0.09, 0.6),
        note(N["G5"], 0.09, 0.6), note(N["C6"], 0.22, 0.7),
    )

    # streak_milestone: two quick sparkle notes E6, B6
    s["streak_milestone"] = seq(note(N["E6"], 0.08, 0.55), note(N["B6"], 0.16, 0.55))

    # daily_complete: little fanfare — C5 E5 G5 then a sustained C6 chord shimmer
    s["daily_complete"] = seq(
        note(N["C5"], 0.10, 0.55), note(N["E5"], 0.10, 0.55), note(N["G5"], 0.10, 0.55),
        chord([N["C6"], N["E6"], N["G6"]], 0.35, 0.5, curve=2.5),
    )

    # tap: very short soft blip
    s["tap"] = note(N["A5"], 0.04, 0.35, curve=8.0)

    # navigation: soft short blip a bit lower
    s["navigation"] = note(N["E5"], 0.05, 0.35, curve=7.0)

    # achievement: bright sustained triad
    s["achievement"] = chord([N["C5"], N["E5"], N["G5"], N["C6"]], 0.40, 0.5, curve=2.0)

    # time_tick: short high tick
    s["time_tick"] = note(N["B5"], 0.03, 0.4, curve=10.0)

    # game_over: descending three notes G4 E4 C4
    s["game_over"] = seq(
        note(N["G4"], 0.16, 0.6, curve=3.0),
        note(N["E4"], 0.16, 0.6, curve=3.0),
        note(N["C4"], 0.30, 0.6, curve=2.5),
    )

    return s


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    sounds = make_sounds()
    with tempfile.TemporaryDirectory() as tmp:
        for name, samples in sounds.items():
            wav = Path(tmp) / f"{name}.wav"
            caf = OUT / f"{name}.caf"
            write_wav(wav, samples)
            to_caf(wav, caf)
            print(f"  {caf.name}  ({caf.stat().st_size} bytes)")
    print(f"OK — {len(sounds)} sounds written to {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
