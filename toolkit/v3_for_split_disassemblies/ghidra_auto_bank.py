# ghidra_auto_bank.py (v3.1 + Runtime Switch Importer + vasm Listing Exporter)
import os
import json
from ghidra.program.model.symbol import SourceType
from ghidra.program.model.data import ByteDataType, ArrayDataType
from ghidra.program.model.listing import Instruction
from ghidra.app.cmd.disassemble import DisassembleCommand


def sanitize_symbol(name):
    clean = "".join(c if c.isalnum() else "_" for c in name)
    while "__" in clean:
        clean = clean.replace("__", "_")
    return clean.strip("_")


def label_genesis_hardware():
    hw_regs = {
        0x00A10001: "HW_VERSION",
        0x00A10003: "JOYPAD_1_DATA",
        0x00A10005: "JOYPAD_2_DATA",
        0x00A10009: "JOYPAD_1_CTRL",
        0x00A1000B: "JOYPAD_2_CTRL",
        0x00A11100: "Z80_BUSREQ",
        0x00A11200: "Z80_RESET",
        0x00A130F1: "SSF2_SRAM_CTRL",
        0x00A130F3: "SSF2_BANK_1",
        0x00A130F5: "SSF2_BANK_2",
        0x00A130F7: "SSF2_BANK_3",
        0x00A130F9: "SSF2_BANK_4",
        0x00A130FB: "SSF2_BANK_5",
        0x00A130FD: "SSF2_BANK_6",
        0x00A130FF: "SSF2_BANK_7",
        0x00C00000: "VDP_DATA",
        0x00C00004: "VDP_CTRL",
        0x00C00008: "VDP_HV_COUNTER",
        0x00C00011: "PSG_CTRL",
    }
    sym_table = currentProgram.getSymbolTable()
    space = currentProgram.getAddressFactory().getDefaultAddressSpace()
    for addr_int, name in hw_regs.items():
        try:
            sym_table.createLabel(space.getAddress(addr_int), name, SourceType.USER_DEFINED)
        except Exception:
            pass


def apply_ram_symbols():
    ram_path = "upstream_ram_symbols.json"
    if not os.path.exists(ram_path):
        return
    with open(ram_path, "r") as f:
        ram_map = json.load(f)
    sym_table = currentProgram.getSymbolTable()
    space = currentProgram.getAddressFactory().getDefaultAddressSpace()
    for _, info in ram_map.items():
        addr = space.getAddress(info["address_int"])
        names = info.get("names", [])
        if names:
            primary_name = sanitize_symbol("_or_".join(names[:3]))
            try:
                sym_table.createLabel(addr, primary_name, SourceType.USER_DEFINED)
            except Exception:
                pass


def apply_upstream_matches(bank_index):
    matches_path = "upstream_matches.json"
    if not os.path.exists(matches_path):
        return
    with open(matches_path, "r") as f:
        report = json.load(f)
    sym_table = currentProgram.getSymbolTable()
    listing = currentProgram.getListing()
    space = currentProgram.getAddressFactory().getDefaultAddressSpace()
    base_addr = currentProgram.getImageBase().getOffset()

    for m in report.get("matches", []):
        if m.get("bank") != bank_index:
            continue
        local_offset = int(m["bank_offset"], 16)
        size = m["size"]
        kind = m["kind"]
        repo = m["repo"]
        sym_raw = m["symbol"]
        mode = m.get("match_mode", "exact")
        target_addr = space.getAddress(base_addr + local_offset)
        sym_name = "{}_{}_{:05X}".format(repo, sanitize_symbol(sym_raw), local_offset)
        try:
            sym_table.createLabel(target_addr, sym_name, SourceType.USER_DEFINED)
            listing.setComment(target_addr, 0, "[UPSTREAM: {} | {} | {} | {} bytes]".format(repo, kind, mode, size))
        except Exception:
            pass

        if kind == "asset":
            end_addr = space.getAddress(base_addr + local_offset + size - 1)
            listing.clearCodeUnits(target_addr, end_addr, False)
            try:
                listing.createData(target_addr, ArrayDataType(ByteDataType.dataType, size, 1))
            except Exception:
                pass
        elif kind == "code":
            DisassembleCommand(target_addr, None, True).applyTo(currentProgram)


def apply_neto_hooks(bank_index):
    hooks_path = "neto_custom_hooks.json"
    if not os.path.exists(hooks_path):
        return
    with open(hooks_path, "r") as f:
        report = json.load(f)
    sym_table = currentProgram.getSymbolTable()
    listing = currentProgram.getListing()
    space = currentProgram.getAddressFactory().getDefaultAddressSpace()
    base_addr = currentProgram.getImageBase().getOffset()

    for h in report.get("ssf2_accesses", []):
        if h.get("bank") != bank_index:
            continue
        local_offset = int(h["bank_offset"], 16)
        target_addr = space.getAddress(base_addr + local_offset)
        lbl = "Neto_SSF2_{}_{:05X}".format(h["register_name"], local_offset)
        try:
            sym_table.createLabel(target_addr, lbl, SourceType.USER_DEFINED)
            listing.setComment(target_addr, 0, "[NETO CUSTOM: {}]".format(h["disassembly"]))
            DisassembleCommand(target_addr, None, True).applyTo(currentProgram)
        except Exception:
            pass


def apply_runtime_switches(bank_index):
    switches_path = "resolved_switches.json"
    if not os.path.exists(switches_path):
        return
    with open(switches_path, "r") as f:
        report = json.load(f)
    sym_table = currentProgram.getSymbolTable()
    listing = currentProgram.getListing()
    space = currentProgram.getAddressFactory().getDefaultAddressSpace()
    base_addr = currentProgram.getImageBase().getOffset()

    by_pc = {}
    for sw in report.get("switches", []):
        if sw.get("pc_bank") == bank_index:
            by_pc.setdefault(int(sw["pc_bank_offset"], 16), []).append(sw)

    for local_off, sw_list in sorted(by_pc.items()):
        target_addr = space.getAddress(base_addr + local_off)
        regs = sorted(set(s["register"] for s in sw_list))
        vals = sorted(set(s["value_written"] for s in sw_list))
        lbl = "Runtime_SSF2_{}_{:05X}".format("_".join(regs), local_off)
        comment = "[RUNTIME TRACE: {} <- {} ({} hits)]".format(
            ",".join(regs), ",".join(vals), sum(s["hit_count"] for s in sw_list)
        )
        try:
            sym_table.createLabel(target_addr, lbl, SourceType.USER_DEFINED)
            listing.setComment(target_addr, 0, comment)
        except Exception:
            pass


def export_bank_listing(bank_index):
    if not os.path.exists("disasm_banks"):
        os.makedirs("disasm_banks")

    out_path = os.path.join("disasm_banks", "raw_bank_{:02d}.asm".format(bank_index))
    listing = currentProgram.getListing()
    sym_table = currentProgram.getSymbolTable()
    base_offset = currentProgram.getImageBase().getOffset()
    global_bank_base = bank_index * 0x80000

    out_lines = [
        "; Auto-exported by ghidra_auto_bank.py v3.1 (Bank {:02d} | ROM 0x{:06X})".format(
            bank_index, global_bank_base
        ),
        "    org ${:06X}".format(global_bank_base),
        "",
    ]

    cu_iter = listing.getCodeUnits(True)
    while cu_iter.hasNext() and not monitor.isCancelled():
        cu = cu_iter.next()
        addr = cu.getMinAddress()
        local_off = addr.getOffset() - base_offset
        if local_off < 0 or local_off >= 0x80000:
            continue

        for sym in sym_table.getSymbols(addr):
            s_name = sym.getName()
            if s_name.startswith("LAB_"):
                s_name = "loc_{:06X}".format(global_bank_base + local_off)
            out_lines.append("{}:".format(s_name))

        pre_cmt = cu.getComment(0)
        cmt_suffix = " ; {}".format(pre_cmt.replace("\n", " ")) if pre_cmt else ""

        raw_bytes = cu.getBytes()
        hex_cols = " ".join("{:02X}".format(b & 0xFF) for b in raw_bytes[:8])
        addr_str = "{:08X}".format(global_bank_base + local_off)

        if isinstance(cu, Instruction):
            inst_str = cu.toString()
            out_lines.append("{} {}    {}{}".format(addr_str, hex_cols, inst_str, cmt_suffix))
        else:
            total_len = len(raw_bytes)
            for chunk_start in range(0, total_len, 16):
                chunk = raw_bytes[chunk_start : chunk_start + 16]
                chunk_addr = "{:08X}".format(global_bank_base + local_off + chunk_start)
                chunk_hex = " ".join("{:02X}".format(b & 0xFF) for b in chunk[:8])
                dc_vals = ",".join("${:02X}".format(b & 0xFF) for b in chunk)
                line_cmt = cmt_suffix if chunk_start == 0 else ""
                out_lines.append("{} {}    dc.b {}{}".format(chunk_addr, chunk_hex, dc_vals, line_cmt))

    with open(out_path, "w") as f:
        f.write("\n".join(out_lines) + "\n")
    print("[+] Exported {} ({} lines)".format(out_path, len(out_lines)))


def run():
    prog_name = currentProgram.getName()
    bank_index = 0
    for part in prog_name.replace(".", "_").split("_"):
        if part.isdigit():
            bank_index = int(part)
            break

    if bank_index == 0:
        space = currentProgram.getAddressFactory().getDefaultAddressSpace()
        mem = currentProgram.getMemory()
        try:
            entry_pc = mem.getInt(space.getAddress(0x000004)) & 0x00FFFFFF
            if 0 < entry_pc < 0x80000:
                DisassembleCommand(space.getAddress(entry_pc), None, True).applyTo(currentProgram)
        except Exception:
            pass

    label_genesis_hardware()
    apply_ram_symbols()
    apply_upstream_matches(bank_index)
    apply_neto_hooks(bank_index)
    apply_runtime_switches(bank_index)
    export_bank_listing(bank_index)


run()
