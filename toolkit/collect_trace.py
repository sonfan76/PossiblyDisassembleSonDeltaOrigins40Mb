#!/usr/bin/env python3
import subprocess
import re
import json
import sys

ROM_FILE = "sonic_delta_origins.bin"
OUTPUT_JSON = "resolved_switches.json"

# Standard Sega SSF2 512KB ROM bank registers -> CPU swap window base
# ($A130F1 intentionally excluded so SRAM save/load writes do not interrupt trace)
SSF2_WINDOWS = {
    0xA130F3: 0x080000,
    0xA130F5: 0x100000,
    0xA130F7: 0x180000,
    0xA130F9: 0x200000,
    0xA130FB: 0x280000,
    0xA130FD: 0x300000,
    0xA130FF: 0x380000,
}

def extract_bank_value(disasm_lines, regs):
    for line in disasm_lines:
        m = re.search(r"move\.[bw]\s+([^,]+),\s*(.+)", line, re.IGNORECASE)
        if not m:
            continue
        src = m.group(1).strip().lower()

        if src.startswith("#$"):
            return int(src[2:], 16) & 0xFF
        if src.startswith("#"):
            return int(src[1:], 10) & 0xFF
        if re.fullmatch(r"d[0-7]", src) and src in regs:
            return regs[src] & 0xFF
        ind = re.fullmatch(r"\((a[0-6])\)\+?", src)
        if ind and ind.group(1) in regs:
            return regs[ind.group(1)] & 0xFF

    return regs.get("d0", 0) & 0xFF

def run_blastem_trace(rom_path):
    proc = subprocess.Popen(
        ["blastem", "-d", rom_path],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    init_cmds = [f"watch ${reg:06X}" for reg in SSF2_WINDOWS] + ["c"]
    proc.stdin.write("\n".join(init_cmds) + "\n")
    proc.stdin.flush()

    switches = {}
    current_block = []

    print("[TRACE] BlastEm active (SSF2 $A130F3-$A130FF watchpoints enabled; $A130F1 SRAM filtered).")
    print("[TRACE] Play through zones/menus, then close BlastEm window to save resolved_switches.json.")

    for line in proc.stdout:
        clean = line.strip()
        current_block.append(clean)

        if "Watchpoint" in clean:
            proc.stdin.write("p\ndisasm\nbt\nc\n")
            proc.stdin.flush()

        elif "(blastem)" in clean and len(current_block) > 4:
            blob = "\n".join(current_block)
            pc_match = re.search(r"pc:\s*([0-9a-fA-F]+)", blob)
            wp_match = re.search(r"Watchpoint.*?([0-9a-fA-F]{6})", blob)

            if pc_match and wp_match:
                pc = int(pc_match.group(1), 16)
                reg = int(wp_match.group(1), 16)

                regs = {}
                for r_name, r_val in re.findall(r"([da][0-7]):\s*([0-9a-fA-F]+)", blob):
                    regs[r_name.lower()] = int(r_val, 16)

                disasm_lines = [
                    l for l in current_block
                    if re.match(r"^[0-9a-fA-F]{6}:", l)
                ]

                bank = extract_bank_value(disasm_lines, regs)
                win_base = SSF2_WINDOWS.get(reg, 0x380000)

                target_ptrs = [
                    val for name, val in regs.items()
                    if name.startswith("a") and name != "a7" and win_base <= val < (win_base + 0x80000)
                ]
                sample_ptr = target_ptrs[0] if target_ptrs else win_base
                phys_offset = (sample_ptr - win_base) + (bank * 0x80000)

                key = f"{pc:06X}_{reg:06X}_{bank:02X}"
                if key not in switches:
                    switches[key] = {
                        "caller_pc": f"0x{pc:06X}",
                        "mapper_reg": f"0x{reg:06X}",
                        "bank_index": bank,
                        "window_base": f"0x{win_base:06X}",
                        "resolved_target_ptr": f"0x{sample_ptr:06X}",
                        "physical_rom_offset": f"0x{phys_offset:06X}",
                        "disasm_context": disasm_lines[:6]
                    }
                    print(
                        f"[CAPTURED] PC=${pc:06X} | Reg=${reg:06X} | Bank={bank:02d} "
                        f"| Win=${win_base:06X} | Ptr=${sample_ptr:06X} -> Phys=0x{phys_offset:06X}"
                    )
            current_block.clear()

    with open(OUTPUT_JSON, "w") as f:
        json.dump(list(switches.values()), f, indent=2)
    print(f"[DONE] Saved {len(switches)} resolved SSF2 bank switches to {OUTPUT_JSON}")

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else ROM_FILE
    run_blastem_trace(target)
