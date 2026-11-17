-- trace_ssf2_live.lua
-- Unified MAME & Mesen Lua script for logging Sega SSF2 mapper & SRAM writes ($A130F1 - $A130FF)

local LOG_FILE = "trace_banks.txt"
local out = assert(io.open(LOG_FILE, "w"))
out:write("# Sonic Delta 40Mb Live SSF2 Mapper Trace\n")
out:write("# Format: PC_HEX | REGISTER | VALUE_HEX | SLOT_RANGE\n")
out:flush()

local REG_NAMES = {
    [0xA130F1] = { "SSF2_SRAM_CTRL", "SRAM/ROM Toggle ($200000-$3FFFFF)" },
    [0xA130F3] = { "SSF2_BANK_1",    "Slot 1 ($080000-$0FFFFF)" },
    [0xA130F5] = { "SSF2_BANK_2",    "Slot 2 ($100000-$17FFFF)" },
    [0xA130F7] = { "SSF2_BANK_3",    "Slot 3 ($180000-$1FFFFF)" },
    [0xA130F9] = { "SSF2_BANK_4",    "Slot 4 ($200000-$27FFFF)" },
    [0xA130FB] = { "SSF2_BANK_5",    "Slot 5 ($280000-$2FFFFF)" },
    [0xA130FD] = { "SSF2_BANK_6",    "Slot 6 ($300000-$37FFFF)" },
    [0xA130FF] = { "SSF2_BANK_7",    "Slot 7 ($380000-$3FFFFF)" },
}

local function log_write(pc, addr, val)
    local info = REG_NAMES[addr]
    if not info then return end
    local line = string.format("0x%06X | %-14s | 0x%02X | %s\n", pc & 0xFFFFFF, info, val & 0xFF, info)
    out:write(line)
    out:flush()
    print("[SSF2] " .. line:gsub("\n", ""))
end

if emu and emu.addMemoryCallback then
    emu.addMemoryCallback(function(addr, val)
        local state = emu.getState()
        local pc = state["cpu.pc"] or state["pc"] or 0
        log_write(pc, addr, val)
    end, emu.callbackType.write, 0xA130F1, 0xA130FF)
elseif manager and manager.machine then
    local cpu = manager.machine.devices[":maincpu"]
    local space = cpu.spaces["program"]
    space:install_write_tap(0xA130F1, 0xA130FF, "ssf2_mapper_tap", function(offset, data, mask)
        local pc = cpu.state["PC"].value
        log_write(pc, offset, data)
        return data
    end)
end
