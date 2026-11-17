#!/usr/bin/env python3
import re
import json
import argparse
from pathlib import Path

BANK_SIZE = 0x80000

SLOT_WINDOWS = {
    "SSF2_SRAM_CTRL": ("SRAM/ROM Control", 0x200000),
    "SSF2_BANK_1":    ("Slot 1", 0x080000),
    "SSF2_BANK_2":    ("Slot 2", 0x100000),
    "SSF2_BANK_3":    ("Slot 3", 0x180000),
    "SSF2_BANK_4":    ("Slot 4", 0x200000),
    "SSF2_BANK_5":    ("Slot 5", 0x280000),
    "SSF2_BANK_6":    ("Slot 6", 0x300000),
    "SSF2_BANK_7":    ("Slot 7", 0x380000),
}

TRACE_LINE_RE = re.compile(
    r"^\s*0x([0-9A-Fa-f]+)\s*\|\s*([A-Z0-9_]+)\s*\|\s*0x([0-9A-Fa-f]+)\s*(?:\|\s*(.*))?$"
)

def parse_trace_file(trace_path: Path):
    if not trace_path.exists():
        raise FileNotFoundError(f"Trace log not found: {trace_path}")

    events = []
    seen_pairs = {}

    for raw_line in trace_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or line.startswith("Hardware watchpoint"):
            continue

        m = TRACE_LINE_RE.match(line)
        if not m:
            continue

        pc_val = int(m.group(1), 16) & 0xFFFFFF
        reg_name = m.group(2).strip()
        bank_val = int(m.group(3), 16) & 0xFF
        note = (m.group(4) or "").strip()

        key = (pc_val, reg_name, bank_val)
        seen_pairs[key] = seen_pairs.get(key, 0) + 1

        if seen_pairs[key] == 1:
            slot_label, base_vaddr = SLOT_WINDOWS.get(reg_name, ("Unknown Slot", 0))
            target_rom_offset = f"0x{bank_val * BANK_SIZE:06X}" if reg_name != "SSF2_SRAM_CTRL" else None

            events.append({
                "pc": f"0x{pc_val:06X}",
                "pc_int": pc_val,
                "pc_bank": pc_val // BANK_SIZE,
                "pc_bank_offset": f"0x{pc_val % BANK_SIZE:05X}",
                "register": reg_name,
                "slot": slot_label,
                "mapped_window_start": f"0x{base_vaddr:06X}",
                "value_written": f"0x{bank_val:02X}",
                "value_int": bank_val,
                "target_rom_offset": target_rom_offset,
                "note": note,
                "hit_count": 1,
            })

    for ev in events:
        key = (ev["pc_int"], ev["register"], ev["value_int"])
        ev["hit_count"] = seen_pairs[key]

    return events

def main():
    parser = argparse.ArgumentParser(description="Parse MAME/Mesen/BlastEm SSF2 trace logs")
    parser.add_argument("--trace", default="trace_banks.txt", help="Input trace log path")
    parser.add_argument("--out", default="resolved_switches.json", help="Output JSON path")
    args = parser.parse_args()

    events = parse_trace_file(Path(args.trace))
    slot_summary = {}
    for ev in events:
        slot_summary.setdefault(ev["register"], set()).add(ev["value_written"])

    report = {
        "source_trace": args.trace,
        "unique_switch_sites": len(events),
        "total_logged_writes": sum(e["hit_count"] for e in events),
        "observed_values_per_register": {k: sorted(v) for k, v in sorted(slot_summary.items())},
        "switches": events,
    }

    Path(args.out).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"[+] Parsed {report['total_logged_writes']} SSF2 writes across {len(events)} unique PCs -> {args.out}")

if __name__ == "__main__":
    main()
