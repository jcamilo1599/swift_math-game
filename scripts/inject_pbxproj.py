#!/usr/bin/env python3
"""
Surgically inject new Swift files into MathGame.xcodeproj/project.pbxproj.

Reads `pbx_plan.json` (sibling file) which lists:
  groups: ordered list of (group_name, parent_group_name)
  files:  ordered list of (relative_path, group_name)

Edits the pbxproj in place. Idempotent: re-running detects existing entries and skips them.
"""

from __future__ import annotations
import json
import re
import sys
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PBX = ROOT / "MathGame.xcodeproj" / "project.pbxproj"
PLAN = Path(__file__).resolve().parent / "pbx_plan.json"

def uuid(seed: str) -> str:
    """Deterministic 24-char hex UUID derived from a stable seed."""
    h = hashlib.sha256(seed.encode()).hexdigest().upper()
    return h[:24]

def main() -> int:
    plan = json.loads(PLAN.read_text())
    txt = PBX.read_text()

    target_name = "MathGame"
    parent_group_lookup_name = "MathGame"  # PBXGroup name housing app-level groups

    # Pre-compute UUIDs
    group_ids = {name: uuid(f"group:{name}") for name, _ in plan["groups"]}
    file_ref_ids = {p: uuid(f"fileref:{p}") for p, _ in plan["files"]}
    build_ids = {p: uuid(f"buildfile:{p}") for p, _ in plan["files"]}

    # 1) Insert PBXBuildFile lines
    bf_block_re = re.compile(r"(/\* Begin PBXBuildFile section \*/\n)(.*?)(/\* End PBXBuildFile section \*/)", re.S)
    m = bf_block_re.search(txt)
    if not m:
        print("No PBXBuildFile section found"); return 1
    existing = m.group(2)
    additions = []
    for rel, _ in plan["files"]:
        base = Path(rel).name
        bid = build_ids[rel]
        fid = file_ref_ids[rel]
        if bid in existing or f"/* {base} in Sources */" in existing and rel.endswith(".swift") and "in Sources" in existing:
            # Be conservative: just check if this exact bid is already present.
            pass
        if bid not in existing:
            additions.append(f"\t\t{bid} /* {base} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {base} */; }};\n")
    if additions:
        new_body = existing + "".join(additions)
        txt = txt[:m.start(2)] + new_body + txt[m.end(2):]

    # 2) Insert PBXFileReference lines
    fr_block_re = re.compile(r"(/\* Begin PBXFileReference section \*/\n)(.*?)(/\* End PBXFileReference section \*/)", re.S)
    m = fr_block_re.search(txt)
    if not m:
        print("No PBXFileReference section found"); return 1
    existing = m.group(2)
    additions = []
    for rel, _ in plan["files"]:
        base = Path(rel).name
        fid = file_ref_ids[rel]
        if fid in existing:
            continue
        # path attribute is the file name only; we'll reference by hierarchy
        # The file lives in MathGame/<group_path>/<base>; the group has path=<group_name>
        # so file ref path can just be the basename.
        additions.append(
            f'\t\t{fid} /* {base} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{base}"; sourceTree = "<group>"; }};\n'
        )
    if additions:
        new_body = existing + "".join(additions)
        txt = txt[:m.start(2)] + new_body + txt[m.end(2):]

    # 3) Insert into PBXSourcesBuildPhase
    sources_re = re.compile(r"(/\* Begin PBXSourcesBuildPhase section \*/\s*\n\s*[0-9A-F]+ /\* Sources \*/ = \{\s*\n[^}]*?files = \(\s*\n)(.*?)(\s*\);)", re.S)
    m = sources_re.search(txt)
    if not m:
        print("No PBXSourcesBuildPhase found"); return 1
    existing = m.group(2)
    additions = []
    for rel, _ in plan["files"]:
        base = Path(rel).name
        bid = build_ids[rel]
        if bid in existing:
            continue
        additions.append(f"\t\t\t\t{bid} /* {base} in Sources */,\n")
    if additions:
        new_body = existing + "".join(additions)
        txt = txt[:m.start(2)] + new_body + txt[m.end(2):]

    # 4) Insert/ensure PBXGroups
    # Detect existing groups by id (or by name).
    existing_group_block_re = re.compile(r"/\* Begin PBXGroup section \*/(.*?)/\* End PBXGroup section \*/", re.S)
    mg = existing_group_block_re.search(txt)
    if not mg:
        print("No PBXGroup section found"); return 1
    groups_block_text = mg.group(1)

    # For each group we'll add a PBXGroup if missing.
    new_groups = []
    for name, parent in plan["groups"]:
        gid = group_ids[name]
        if gid in groups_block_text:
            continue
        new_groups.append((name, parent, gid))

    # Append the new group entries before "End PBXGroup section"
    if new_groups:
        # First, compute each group's children. Children are:
        # - Files whose group_name == this group
        # - Other groups whose parent == this group
        children_by_group: dict[str, list[tuple[str, str, str]]] = {n: [] for n, _ in plan["groups"]}
        # Track files
        for rel, gname in plan["files"]:
            base = Path(rel).name
            children_by_group.setdefault(gname, []).append(("file", base, file_ref_ids[rel]))
        # Track sub-groups
        for name, parent in plan["groups"]:
            children_by_group.setdefault(parent, []).append(("group", name, group_ids[name]))

        addition_text = ""
        for name, parent, gid in new_groups:
            children_lines = ""
            for kind, label, cid in children_by_group.get(name, []):
                if kind == "file":
                    children_lines += f"\t\t\t\t{cid} /* {label} */,\n"
                else:
                    children_lines += f"\t\t\t\t{cid} /* {label} */,\n"
            addition_text += (
                f"\t\t{gid} /* {name} */ = {{\n"
                f"\t\t\tisa = PBXGroup;\n"
                f"\t\t\tchildren = (\n"
                f"{children_lines}"
                f"\t\t\t);\n"
                f"\t\t\tpath = {name};\n"
                f"\t\t\tsourceTree = \"<group>\";\n"
                f"\t\t}};\n"
            )
        # Insert before the closing comment
        txt = txt.replace("/* End PBXGroup section */", addition_text + "/* End PBXGroup section */", 1)

    # 5) Hook top-level "MathGame" group to include our new top-level groups (Domain, Data, Services).
    # The current MathGame group ends after `Preview Content`. We add Domain/Data/Services groups as
    # children of the MathGame group (which already houses Presentation, Enums, MathGameApp.swift, etc.).
    # The plan lists which groups attach to which parent. We need to insert child IDs into the parent group.
    parent_to_new_children: dict[str, list[tuple[str, str]]] = {}
    for name, parent in plan["groups"]:
        parent_to_new_children.setdefault(parent, []).append((name, group_ids[name]))

    # Find MathGame group (path = MathGame, not project root)
    mathgame_grp_re = re.compile(
        r"([0-9A-F]+) /\* MathGame \*/ = \{\s*\n\s*isa = PBXGroup;\s*\n\s*children = \(\s*\n(.*?)\s*\);\s*\n\s*path = MathGame;",
        re.S,
    )
    mm = mathgame_grp_re.search(txt)
    if mm and "MathGame" in parent_to_new_children:
        children_block = mm.group(2)
        additions = ""
        for name, gid in parent_to_new_children["MathGame"]:
            if gid not in children_block and f"/* {name} */" not in children_block:
                additions += f"\t\t\t\t{gid} /* {name} */,\n"
        if additions:
            new_children_block = children_block + additions
            txt = txt[:mm.start(2)] + new_children_block + txt[mm.end(2):]

    # Also for Presentation group, we may have added sub-groups (Molecules, Theme, ViewModels).
    presentation_re = re.compile(
        r"([0-9A-F]+) /\* Presentation \*/ = \{\s*\n\s*isa = PBXGroup;\s*\n\s*children = \(\s*\n(.*?)\s*\);\s*\n\s*path = Presentation;",
        re.S,
    )
    pm = presentation_re.search(txt)
    if pm and "Presentation" in parent_to_new_children:
        children_block = pm.group(2)
        additions = ""
        for name, gid in parent_to_new_children["Presentation"]:
            if gid not in children_block and f"/* {name} */" not in children_block:
                additions += f"\t\t\t\t{gid} /* {name} */,\n"
        if additions:
            new_children_block = children_block + additions
            txt = txt[:pm.start(2)] + new_children_block + txt[pm.end(2):]

    # For Pages and Atoms which already exist, we need to add new file children.
    def patch_existing_group(group_name: str):
        nonlocal txt
        rgx = re.compile(
            r"([0-9A-F]+) /\* " + re.escape(group_name) + r" \*/ = \{\s*\n\s*isa = PBXGroup;\s*\n\s*children = \(\s*\n(.*?)\s*\);\s*\n\s*path = " + re.escape(group_name) + r";",
            re.S,
        )
        m = rgx.search(txt)
        if not m:
            return
        children_block = m.group(2)
        additions = ""
        for rel, gname in plan["files"]:
            if gname != group_name:
                continue
            base = Path(rel).name
            fid = file_ref_ids[rel]
            if fid in children_block:
                continue
            additions += f"\t\t\t\t{fid} /* {base} */,\n"
        if additions:
            new_children_block = children_block + additions
            txt = txt[:m.start(2)] + new_children_block + txt[m.end(2):]

    for existing_group in ["Pages", "Atoms"]:
        patch_existing_group(existing_group)

    # 6) Add fr and pt-BR to knownRegions.
    txt = re.sub(
        r"(knownRegions = \(\s*\n)(.*?)(\s*\);)",
        lambda mo: (
            mo.group(1)
            + mo.group(2)
            + ("\n\t\t\t\tfr," if ",\n\t\t\t\tfr," not in mo.group(2) and "fr," not in mo.group(2) else "")
            + ("\n\t\t\t\t\"pt-BR\"," if "pt-BR" not in mo.group(2) else "")
            + mo.group(3)
        ),
        txt,
        count=1,
        flags=re.S,
    )

    PBX.write_text(txt)
    print(f"OK — added {len(file_ref_ids)} files, {len(new_groups)} new groups.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
