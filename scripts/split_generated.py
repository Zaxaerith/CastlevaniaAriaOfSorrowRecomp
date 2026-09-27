#!/usr/bin/env python3
"""Split gbarecomp recompiled_*.cpp shards into functionally named modules.

Reads src/generated/recompiled_*.cpp + recompiled.h and emits themed
translation units under src/game/ (SMK / CotM style). Generated shards
themselves stay local-only (gitignored).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GEN = ROOT / "src" / "generated"
OUT = ROOT / "src" / "game"

# Address/name → module (checked in order)
RULES = [
    (r"^gf_(autojt_|jump_)", "jump_tables"),
    (r"^gf_.*iwram", "iwram_reloc"),
    (r"^gf_(tfunc_|afunc_)?03", "iwram_reloc"),
    (r"^gf_.*start_vector", "boot_system"),
    (r"^gf_(cart_|boot_)", "boot_system"),
    (0x03000000, 0x03008000, "iwram_reloc"),
    (0x08000000, 0x08002000, "boot_system"),
    (0x08002000, 0x08004000, "memory_dma"),
    (0x08004000, 0x08008000, "engine_scene"),
    (0x08008000, 0x08010000, "gameplay_core"),
    (0x08010000, 0x08020000, "save_system"),
    (0x08020000, 0x08080000, "world_actors"),
    (0x08080000, 0x080C0000, "ui_audio"),
    (0x080C0000, 0x08120000, "engine_tail"),
]


def pick_module(name: str, addr: int) -> str:
    for rule in RULES:
        if isinstance(rule[0], str):
            if re.search(rule[0], name):
                return rule[1]
        else:
            lo, hi, mod = rule
            if lo <= addr < hi:
                return mod
    if addr >= 0x08000000:
        return "engine_tail"
    return "misc"


def main() -> int:
    if not GEN.is_dir():
        print(f"missing {GEN} — run generate.ps1 first", file=sys.stderr)
        return 1
    hdr_path = GEN / "recompiled.h"
    if not hdr_path.is_file():
        print(f"missing {hdr_path}", file=sys.stderr)
        return 1

    hdr = hdr_path.read_text(encoding="utf-8", errors="replace")
    sigs = re.findall(
        r"void\s+(gf_\w+)\(void\);\s*/\*\s*(0x[0-9A-Fa-f]+)\s+(arm|thumb)\s*\*/",
        hdr,
    )
    by_name = {n: (int(a, 16), m) for n, a, m in sigs}
    print(f"functions in header: {len(by_name)}")

    body_re = re.compile(r"^(void\s+gf_\w+\(void\)\s*\{)", re.M)
    chunks: dict[str, str] = {}
    for shard in sorted(GEN.glob("recompiled_*.cpp")):
        text = shard.read_text(encoding="utf-8", errors="replace")
        starts = [m.start() for m in body_re.finditer(text)]
        for i, s in enumerate(starts):
            e = starts[i + 1] if i + 1 < len(starts) else len(text)
            chunk = text[s:e]
            m = re.match(r"void\s+(gf_\w+)\(void\)", chunk)
            if not m:
                continue
            name = m.group(1)
            chunks[name] = chunk.rstrip() + "\n\n"

    OUT.mkdir(parents=True, exist_ok=True)
    buckets: dict[str, list[str]] = {}
    for name, body in chunks.items():
        addr = by_name.get(name, (0, "thumb"))[0]
        mod = pick_module(name, addr)
        buckets.setdefault(mod, []).append(body)

    banner = (
        "// AUTO-GENERATED guest translation unit (split from gba_recompile shards).\n"
        "// Regenerate with scripts/generate.ps1 — do not edit by hand.\n"
        "// ROM-derived; not published in git.\n\n"
        '#include "runtime_arm.h"\n'
        '#include "recompiled.h"\n\n'
    )
    for mod, parts in sorted(buckets.items()):
        out = OUT / f"{mod}.cpp"
        out.write_text(banner + "".join(parts), encoding="utf-8")
        print(f"  {out.name:24s}  {len(parts):5d} funcs  {out.stat().st_size/1e6:.2f} MB")

    # Thin re-export header + dispatch / symbol map stay in src/game after generate.
    for extra in ("dispatch_table.cpp", "symbol_map.cpp", "recompiled.h"):
        src = GEN / extra
        if src.is_file():
            dst = OUT / extra
            dst.write_text(src.read_text(encoding="utf-8", errors="replace"), encoding="utf-8")
            print(f"  copied {extra}")

    print("Done. Keep src/generated/ local (gitignored).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
