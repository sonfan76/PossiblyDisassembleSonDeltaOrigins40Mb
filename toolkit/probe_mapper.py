#!/usr/bin/env python3
import sys
import struct

rom_path = sys.argv[1] if len(sys.argv) > 1 else "sonic_delta_origins.bin"
with open(rom_path, "rb") as f:
    data = f.read()

print(f"[PROBE] Scanning {len(data)} bytes ({len(data)//1024} KB) for Sega SSF2 mapper references...")

ssf2_targets = {
    0x00A130F1: "SSF2 Slot 0 / SRAM Latch ($000000-$07FFFF or SRAM)",
    0x00A130F3: "SSF2 Slot 1 ($080000-$0FFFFF)",
    0x00A130F5: "SSF2 Slot 2 ($100000-$17FFFF)",
    0x00A130F7: "SSF2 Slot 3 ($180000-$1FFFFF)",
    0x00A130F9: "SSF2 Slot 4 ($200000-$27FFFF)",
    0x00A130FB: "SSF2 Slot 5 ($280000-$2FFFFF)",
    0x00A130FD: "SSF2 Slot 6 ($300000-$37FFFF)",
    0x00A130FF: "SSF2 Slot 7 ($380000-$3FFFFF)",
}

active_bank_regs = []
for addr, desc in ssf2_targets.items():
    packed = struct.pack(">I", addr)
    offsets = []
    pos = 0
    while True:
        idx = data.find(packed, pos)
        if idx == -1:
            break
        offsets.append(idx)
        pos = idx + 1
    if offsets:
        sample_pcs = ", ".join(f"${o:06X}" for o in offsets[:6])
        print(f"  [HIT] ${addr:06X} ({desc}) -> {len(offsets)} refs (e.g. {sample_pcs})")
        if addr != 0x00A130F1:
            active_bank_regs.append(addr)

with open("blastem_probe.txt", "w") as f:
    for r in (active_bank_regs if active_bank_regs else [k for k in ssf2_targets if k != 0x00A130F1]):
        f.write(f"watch ${r:06X}\n")
    f.write("c\n")

print(f"\n[READY] Generated blastem_probe.txt with {len(active_bank_regs)} ROM bank watchpoints (SRAM $A130F1 excluded).")
print(f"Run: blastem -d {rom_path} < blastem_probe.txt")
