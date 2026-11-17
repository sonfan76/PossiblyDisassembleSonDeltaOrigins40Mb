#!/usr/bin/env python3
import re
import json
import argparse
from pathlib import Path

UPSTREAM_ROOTS = {
    "s1disasm": Path("s1disasm-AS"),
    "s2disasm": Path("s2disasm-master"),
    "skdisasm": Path("skdisasm-master"),
}

HEX_OPERAND_RE = re.compile(r"\(\$([0-9A-Fa-f]{4,8})\)\.(w|l)")
NETO_HOOK_LABEL_RE = re.compile(r"^Neto_SSF2_[A-Z0-9_]+_([0-9A-Fa-f]{6})\s*:")

def sanitize_symbol(name):
    clean = "".join(c if c.isalnum() else "_" for c in name)
    while "__" in clean:
        clean = clean.replace("__", "_")
    return clean.strip("_")

def locate_upstream_source(repo_tag, symbol_name):
    root = UPSTREAM_ROOTS.get(repo_tag)
    if not root or not root.exists():
        return None
    raw_sym = symbol_name
    for prefix in ("s1disasm_", "s2disasm_", "skdisasm_"):
        if raw_sym.startswith(prefix):
            raw_sym = raw_sym[len(prefix):]
    raw_sym = re.sub(r"_[0-9A-Fa-f]{5,6}$", "", raw_sym)
    pattern = re.compile(rf"^\s*{re.escape(raw_sym)}\s*:", re.MULTILINE)
    for asm_file in root.rglob("*.asm"):
        try:
            text = asm_file.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        m = pattern.search(text)
        if m:
            line_no = text[: m.start()].count("\n") + 1
            return f"{asm_file.as_posix()}:{line_no} ({raw_sym})"
    return None

def load_runtime_switches(switches_path):
    by_pc = {}
    p = Path(switches_path)
    if not p.exists():
        return by_pc
    data = json.loads(p.read_text(encoding="utf-8"))
    for sw in data.get("switches", []):
        by_pc.setdefault(sw["pc_int"], []).append(sw)
    return by_pc

def format_runtime_comment(sw_list):
    parts = []
    for sw in sw_list:
        val = sw["value_written"]
        hits = sw["hit_count"]
        target = sw.get("target_rom_offset")
        if target:
            parts.append(f"{sw['register']}<-{val} (ROM {target}, {hits}x)")
        else:
            parts.append(f"{sw['register']}<-{val} ({hits}x)")
    return "; [RUNTIME TRACE: " + " | ".join(parts) + "]"

def build_symbol_tables(matches_path, ram_path, hooks_path, switches_by_pc):
    addr_to_label = {}
    const_defs = {}
    hw = {
        0x00A10001: "HW_VERSION",
        0x00A10003: "JOYPAD_1_DATA",
        0x00A10005: "JOYPAD_2_DATA",
        0x00A10009: "JOYPAD_1_CTRL",
        0x00A1000B: "JOYPAD_2_CTRL",
        0x00A11100: "Z80_BUSREQ",
        0x00A11200: "Z80_RESET",
        0x00C00000: "VDP_DATA",
        0x00C00004: "VDP_CTRL",
        0x00C00008: "VDP_HV_COUNTER",
        0x00C00011: "PSG_CTRL",
    }
    for addr, name in hw.items():
        addr_to_label[addr] = name
        const_defs[name] = f"${addr:08X}"

    if Path(ram_path).exists():
        ram_data = json.loads(Path(ram_path).read_text(encoding="utf-8"))
        for _, info in ram_data.items():
            addr = info["address_int"]
            names = info.get("names", [])
            if names:
                lbl = sanitize_symbol(names[0])
                addr_to_label[addr] = lbl
                const_defs[lbl] = f"${addr:08X}"

    if Path(matches_path).exists():
        match_data = json.loads(Path(matches_path).read_text(encoding="utf-8"))
        for m in match_data.get("matches", []):
            addr = m["rom_offset_int"]
            lbl = f"{m['repo']}_{sanitize_symbol(m['symbol'])}_{addr:06X}"
            addr_to_label[addr] = lbl
            const_defs[lbl] = f"${addr:08X}"

    if Path(hooks_path).exists():
        hook_data = json.loads(Path(hooks_path).read_text(encoding="utf-8"))
        for h in hook_data.get("ssf2_accesses", []):
            addr = h["rom_offset_int"]
            lbl = f"Neto_SSF2_{h['register_name']}_{addr:06X}"
            addr_to_label[addr] = lbl
            const_defs[lbl] = f"${addr:08X}"

    for pc_int, sw_list in switches_by_pc.items():
        if pc_int not in addr_to_label:
            regs = "_".join(sorted(set(s["register"] for s in sw_list)))
            lbl = f"Runtime_SSF2_{regs}_{pc_int:06X}"
            addr_to_label[pc_int] = lbl
            const_defs[lbl] = f"${pc_int:08X}"

    return addr_to_label, const_defs

def write_runtime_switches_inc(src_dir, switches_by_pc):
    if not switches_by_pc:
        return False
    custom_dir = src_dir / "custom_neto"
    custom_dir.mkdir(parents=True, exist_ok=True)
    out_inc = custom_dir / "runtime_bank_switches.inc"
    lines = ["; Live Runtime SSF2 Bank Switch Summary", ""]
    for pc_int in sorted(switches_by_pc.keys()):
        sw_list = switches_by_pc[pc_int]
        regs = "_".join(sorted(set(s["register"] for s in sw_list)))
        lbl = f"Runtime_SSF2_{regs}_{pc_int:06X}"
        lines.append(f"{lbl:<44} equ ${pc_int:06X} {format_runtime_comment(sw_list)}")
    out_inc.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return True

def enrich_repository(repo_dir, addr_to_label, const_defs, switches_by_pc):
    repo = Path(repo_dir)
    src_dir = repo / "src"
    inc_lines = ["; Auto-generated Cross-Referenced Human-Readable Symbols", ""]
    for name, hex_val in sorted(const_defs.items()):
        inc_lines.append(f"{name:<44} equ {hex_val}")
    (src_dir / "human_constants.inc").write_text("\n".join(inc_lines) + "\n", encoding="utf-8")

    has_runtime_inc = write_runtime_switches_inc(src_dir, switches_by_pc)
    main_asm = repo / "main.asm"
    if main_asm.exists():
        main_txt = main_asm.read_text(encoding="utf-8")
        headers = ['    include "src/human_constants.inc"']
        if has_runtime_inc:
            headers.append('    include "src/custom_neto/runtime_bank_switches.inc"')
        missing = [h for h in headers if h not in main_txt]
        if missing:
            main_asm.write_text("\n".join(missing) + "\n" + main_txt, encoding="utf-8")

    for asm_file in src_dir.rglob("*.asm"):
        if asm_file.name == "upstream_assets.asm":
            continue
        lines = asm_file.read_text(encoding="utf-8", errors="ignore").splitlines()
        new_lines = []
        changed = False
        stem = asm_file.stem
        for repo_tag in ("s1disasm", "s2disasm", "skdisasm"):
            if stem.startswith(repo_tag + "_"):
                xref_loc = locate_upstream_source(repo_tag, stem)
                if xref_loc and (not lines or "XREF Upstream Source:" not in lines[0]):
                    new_lines.append(f"; XREF Upstream Source: {xref_loc}")
                    changed = True
                break

        for line in lines:
            m_hook = NETO_HOOK_LABEL_RE.match(line.strip())
            if m_hook and switches_by_pc:
                hook_pc = int(m_hook.group(1), 16)
                if hook_pc in switches_by_pc:
                    rt_comment = format_runtime_comment(switches_by_pc[hook_pc])
                    if not new_lines or new_lines[-1] != rt_comment:
                        new_lines.append(rt_comment)
                        changed = True

            def _sub_addr(match):
                nonlocal changed
                raw_hex = match.group(1)
                size_suffix = match.group(2)
                val = int(raw_hex, 16) & 0x00FFFFFF
                if size_suffix == "w" and val >= 0x8000:
                    val = 0x00FF0000 | val
                lbl = addr_to_label.get(val)
                if lbl:
                    changed = True
                    return f"({lbl}).{size_suffix}"
                return match.group(0)

            new_lines.append(HEX_OPERAND_RE.sub(_sub_addr, line))

        if changed:
            asm_file.write_text("\n".join(new_lines) + "\n", encoding="utf-8")

def main():
    parser = argparse.ArgumentParser(description="Enrich split disassembly with cross-references")
    parser.add_argument("--repo", default="sonic_delta_disasm_repo")
    parser.add_argument("--matches", default="upstream_matches.json")
    parser.add_argument("--ram", default="upstream_ram_symbols.json")
    parser.add_argument("--hooks", default="neto_custom_hooks.json")
    parser.add_argument("--switches", default="resolved_switches.json")
    args = parser.parse_args()
    switches_by_pc = load_runtime_switches(args.switches)
    addr_to_label, const_defs = build_symbol_tables(args.matches, args.ram, args.hooks, switches_by_pc)
    enrich_repository(args.repo, addr_to_label, const_defs, switches_by_pc)

if __name__ == "__main__":
    main()
