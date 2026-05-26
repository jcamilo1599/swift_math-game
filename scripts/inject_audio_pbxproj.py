#!/usr/bin/env python3
"""
Register the generated .caf audio files into MathGame.xcodeproj as resources.

Adds:
  - PBXFileReference for each .caf
  - PBXBuildFile (in Resources) for each
  - a PBXGroup "Audio" (child of the MathGame group) holding them
  - the build files into the PBXResourcesBuildPhase

Idempotent. Run after generate_audio.py.
"""

from __future__ import annotations
import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PBX = ROOT / "MathGame.xcodeproj" / "project.pbxproj"
AUDIO_DIR = ROOT / "MathGame" / "Audio" / "Resources"

GROUP_NAME = "Audio"
# Group path is relative to the MathGame group; files sit in Audio/Resources/<name>.caf
GROUP_PATH = "Audio/Resources"


def uuid(seed: str) -> str:
    return hashlib.sha256(seed.encode()).hexdigest().upper()[:24]


def main() -> int:
    cafs = sorted(p.name for p in AUDIO_DIR.glob("*.caf"))
    if not cafs:
        print("No .caf files found — run generate_audio.py first.")
        return 1

    txt = PBX.read_text()

    group_id = uuid(f"group:{GROUP_NAME}:audio")
    file_ref = {c: uuid(f"audioref:{c}") for c in cafs}
    build_id = {c: uuid(f"audiobuild:{c}") for c in cafs}

    # 1) PBXBuildFile entries (Resources)
    m = re.search(r"(/\* Begin PBXBuildFile section \*/\n)(.*?)(/\* End PBXBuildFile section \*/)", txt, re.S)
    body = m.group(2)
    adds = ""
    for c in cafs:
        if build_id[c] in body:
            continue
        adds += f"\t\t{build_id[c]} /* {c} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_ref[c]} /* {c} */; }};\n"
    if adds:
        txt = txt[:m.start(2)] + body + adds + txt[m.end(2):]

    # 2) PBXFileReference entries
    m = re.search(r"(/\* Begin PBXFileReference section \*/\n)(.*?)(/\* End PBXFileReference section \*/)", txt, re.S)
    body = m.group(2)
    adds = ""
    for c in cafs:
        if file_ref[c] in body:
            continue
        adds += f'\t\t{file_ref[c]} /* {c} */ = {{isa = PBXFileReference; lastKnownFileType = file; path = "{c}"; sourceTree = "<group>"; }};\n'
    if adds:
        txt = txt[:m.start(2)] + body + adds + txt[m.end(2):]

    # 3) PBXGroup "Audio" (create if missing)
    if group_id not in txt:
        children = "".join(f"\t\t\t\t{file_ref[c]} /* {c} */,\n" for c in cafs)
        group_block = (
            f"\t\t{group_id} /* {GROUP_NAME} */ = {{\n"
            f"\t\t\tisa = PBXGroup;\n"
            f"\t\t\tchildren = (\n{children}\t\t\t);\n"
            f"\t\t\tpath = {GROUP_PATH};\n"
            f"\t\t\tname = {GROUP_NAME};\n"
            f"\t\t\tsourceTree = \"<group>\";\n"
            f"\t\t}};\n"
        )
        txt = txt.replace("/* End PBXGroup section */", group_block + "/* End PBXGroup section */", 1)

        # Attach the Audio group to the MathGame group children.
        mg = re.search(
            r"([0-9A-F]+) /\* MathGame \*/ = \{\s*\n\s*isa = PBXGroup;\s*\n\s*children = \(\s*\n(.*?)\s*\);\s*\n\s*path = MathGame;",
            txt, re.S,
        )
        if mg and group_id not in mg.group(2):
            new_children = mg.group(2) + f"\t\t\t\t{group_id} /* {GROUP_NAME} */,\n"
            txt = txt[:mg.start(2)] + new_children + txt[mg.end(2):]

    # 4) PBXResourcesBuildPhase
    m = re.search(
        r"(/\* Begin PBXResourcesBuildPhase section \*/\s*\n\s*[0-9A-F]+ /\* Resources \*/ = \{\s*\n[^}]*?files = \(\s*\n)(.*?)(\s*\);)",
        txt, re.S,
    )
    body = m.group(2)
    adds = ""
    for c in cafs:
        if build_id[c] in body:
            continue
        adds += f"\t\t\t\t{build_id[c]} /* {c} in Resources */,\n"
    if adds:
        txt = txt[:m.start(2)] + body + adds + txt[m.end(2):]

    PBX.write_text(txt)
    print(f"OK — registered {len(cafs)} .caf resources.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
