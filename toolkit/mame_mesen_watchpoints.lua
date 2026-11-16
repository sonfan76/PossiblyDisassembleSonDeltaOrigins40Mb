-- =============================================================================
-- M68K DYNAMIC SSF2 BANK-SWITCH LOGGER (MAME / Mesen Lua API)
-- Watches $A130F3-$A130FF (excludes $A130F1 SRAM latch)
-- =============================================================================

local log_file = io.open("ssf2_bank_trace.log", "w")
local seen_switches = {}

local SSF2_SLOTS = {
    [0xA130F3] = 0x080000,
    [0xA130F5] = 0x100000,
    [0xA130F7] = 0x180000,
    [0xA130F9] = 0x200000,
    [0xA130FB] = 0x280000,
    [0xA130FD] = 0x300000,
    [0xA130FF] = 0x380000
}

local function dump_m68k_state(pc, addr, val)
    local bank = val & 0xFF
    local key = string.format("%06X_%06X_%02X", pc, addr, bank)
    if seen_switches[key] then return end
    seen_switches[key] = true

    local win = SSF2_SLOTS[addr] or 0x380000
    local phys = bank * 0x80000

    local regs = string.format(
        "D0=%08X D1=%08X D2=%08X D3=%08X D4=%08X D5=%08X D6=%08X D7=%08X\n" ..
        "A0=%08X A1=%08X A2=%08X A3=%08X A4=%08X A5=%08X A6=%08X A7=%08X",
        emu:get_reg("D0"), emu:get_reg("D1"), emu:get_reg("D2"), emu:get_reg("D3"),
        emu:get_reg("D4"), emu:get_reg("D5"), emu:get_reg("D6"), emu:get_reg("D7"),
        emu:get_reg("A0"), emu:get_reg("A1"), emu:get_reg("A2"), emu:get_reg("A3"),
        emu:get_reg("A4"), emu:get_reg("A5"), emu:get_reg("A6"), emu:get_reg("A7")
    )

    local entry = string.format(
        "[SSF2 SWITCH] PC=$%06X -> Reg=$%06X Bank=%02d (Window=$%06X, BasePhys=0x%06X)\n%s\n" ..
        "------------------------------------------------------------------------\n",
        pc, addr, bank, win, phys, regs
    )

    print(entry)
    if log_file then
        log_file:write(entry)
        log_file:flush()
    end
end

for addr, _ in pairs(SSF2_SLOTS) do
    emu:add_watchpoint(addr, 1, "w", function()
        local pc = emu:get_reg("PC")
        local target = emu:get_watchpoint_address()
        local val = emu:read_byte(target)
        dump_m68k_state(pc, target, val)
    end)
end

print("[SSF2 TRACE] Watchpoints active on $A130F3-$A130FF ($A130F1 SRAM filtered).")
