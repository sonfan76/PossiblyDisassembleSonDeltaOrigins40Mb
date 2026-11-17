# ghidra_auto_bank.py (v3 + Runtime Switch Importer)
import os
import json
from ghidra.program.model.symbol import SourceType
from ghidra.program.model.data import ByteDataType, ArrayDataType
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
        comment = "[RUNTIME TRACE: {} <- {} ({} hits)]".format(",".join(regs), ",".join(vals), sum(s["hit_count"] for s in sw_list))
        try:
            sym_table.createLabel(target_addr, lbl, SourceType.USER_DEFINED)
            listing.setComment(target_addr, 0, comment)
        except Exception:
            pass

def run():
    prog_name = currentProgram.getName()
    bank_index = 0
    for part in prog_name.replace(".", "_").split("_"):
        if part.isdigit():
            bank_index = int(part)
            break
    label_genesis_hardware()
    apply_ram_symbols()
    apply_upstream_matches(bank_index)
    apply_neto_hooks(bank_index)
    apply_runtime_switches(bank_index)

run()
