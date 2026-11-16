# Ghidra Jython Script: SSF2 Dynamic Overlay Mapper & Byte-Accurate vasm Exporter
# @category SegaGenesis.SSF2

import os
import json
from ghidra.app.cmd.disassemble import DisassembleCommand
from ghidra.program.model.symbol import SourceType, RefType

BANK_SIZE = 0x80000          # 512KB per SSF2 bank
FALLBACK_WINDOW = 0x380000   # Default Slot 7 window ($380000-$3FFFFF) if unseen in trace
OUTPUT_DIR = os.path.expanduser("~/sonic_delta_vasm_export")
TRACE_JSON = os.path.expanduser("~/resolved_switches.json")

mem = currentProgram.getMemory()
listing = currentProgram.getListing()
ref_mgr = currentProgram.getReferenceManager()
addr_factory = currentProgram.getAddressFactory()

all_file_bytes = mem.getAllFileBytes()
if not all_file_bytes:
    print("[ERROR] No FileBytes found in current program.")
    exit()

rom_bytes = all_file_bytes[0]
total_size = rom_bytes.getSize()
num_banks = total_size // BANK_SIZE
print("[GHIDRA] Total ROM size: {} bytes ({} x 512KB SSF2 banks)".format(total_size, num_banks))

# Load trace JSON first so each bank gets mapped to its exact runtime CPU window
switches = []
bank_window_map = {}
if os.path.exists(TRACE_JSON):
    with open(TRACE_JSON, "r") as f:
        switches = json.load(f)
    for sw in switches:
        b_idx = int(sw["bank_index"])
        w_base = int(sw["window_base"], 16)
        if b_idx not in bank_window_map:
            bank_window_map[b_idx] = w_base

# Create Overlay Blocks for Banks 8+ (everything above 4MB / 32Mbit)
for bank_idx in range(8, num_banks):
    block_name = "BANK_{:02d}".format(bank_idx)
    file_offset = bank_idx * BANK_SIZE
    win_addr = bank_window_map.get(bank_idx, FALLBACK_WINDOW)

    if mem.getBlock(block_name) is None:
        start_addr = addr_factory.getDefaultAddressSpace().getAddress(win_addr)
        block = mem.createInitializedBlock(
            block_name, start_addr, rom_bytes, file_offset, BANK_SIZE, True
        )
        block.setRead(True)
        block.setWrite(False)
        block.setExecute(True)
        print("[OVERLAY] Created {} -> CPU ${:06X} (File Offset 0x{:06X})".format(
            block_name, win_addr, file_offset))

# Apply Dynamic Trace References & Disassemble Target Entry Points
for sw in switches:
    pc_val = int(sw["caller_pc"], 16)
    bank_idx = int(sw["bank_index"])
    win_addr = int(sw["window_base"], 16)
    target_ptr = int(sw["resolved_target_ptr"], 16)
    caller_addr = addr_factory.getDefaultAddressSpace().getAddress(pc_val)

    listing.setComment(
        caller_addr,
        listing.EOL_COMMENT,
        "SSF2-TRACE: Bank {:02d} -> Win ${:06X} via {} (Ptr=${:06X})".format(
            bank_idx, win_addr, sw["mapper_reg"], target_ptr
        )
    )

    overlay_space = addr_factory.getAddressSpace("BANK_{:02d}".format(bank_idx))
    if overlay_space and win_addr <= target_ptr < (win_addr + BANK_SIZE):
        dest_addr = overlay_space.getAddress(target_ptr)
        ref_mgr.addMemoryReference(
            caller_addr, dest_addr, RefType.DATA, SourceType.USER_DEFINED, 0
        )
        DisassembleCommand(dest_addr, None, True).applyTo(currentProgram)

# Byte-Accurate Hybrid Instruction + Raw Data Exporter
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

for block in mem.getBlocks():
    if not block.isInitialized():
        continue
    out_path = os.path.join(OUTPUT_DIR, "{}.asm".format(block.getName()))
    cursor = block.getStart()
    end_addr = block.getEnd()

    with open(out_path, "w") as asm_out:
        asm_out.write("; ============================================================================\n")
        asm_out.write("; BYTE-ACCURATE SSF2 BANK EXPORT: {} (Start: ${:06X}, Size: ${:X})\n".format(
            block.getName(), cursor.getOffset(), block.getSize()))
        asm_out.write("; ============================================================================\n")
        asm_out.write("\torg\t${:06X}\n\n".format(cursor.getOffset()))

        while cursor.compareTo(end_addr) <= 0:
            inst = listing.getInstructionAt(cursor)
            if inst is not None:
                addr_off = cursor.getOffset()
                asm_out.write("loc_{:06X}:\t{}\n".format(addr_off, inst.toString()))
                cursor = cursor.add(inst.getLength())
            else:
                byte_vals = []
                row_start = cursor.getOffset()
                while len(byte_vals) < 16 and cursor.compareTo(end_addr) <= 0:
                    if listing.getInstructionAt(cursor) is not None:
                        break
                    raw_b = mem.getByte(cursor) & 0xFF
                    byte_vals.append("${:02X}".format(raw_b))
                    cursor = cursor.add(1)
                asm_out.write("dat_{:06X}:\tdc.b\t{}\n".format(row_start, ", ".join(byte_vals)))

    print("[EXPORT] Wrote byte-accurate bank {}".format(out_path))
