import sys
import json

SSF2_REG_START = 0xA130F1
SSF2_REG_END = 0xA130FF

def scan_ssf2_bank_switches(rom_path):
    print(f"[*] Scanning {rom_path} for SSF2 bank-switch operations...")
    try:
        with open(rom_path, "rb") as f:
            rom_data = f.read()
    except FileNotFoundError:
        print(f"[!] Error: File '{rom_path}' not found.")
        return

    rom_size = len(rom_data)
    bank_switch_events = []

    for offset in range(0, rom_size - 6, 2):
        if rom_data[offset+2] == 0x00 and rom_data[offset+3] == 0xA1 and rom_data[offset+4] == 0x30:
            reg_byte = rom_data[offset+5]
            if 0xF1 <= reg_byte <= 0xFF and reg_byte % 2 != 0:
                register_address = f"0xA130{reg_byte:02X}"
                opcode_context = rom_data[offset:offset+6].hex().upper()
                event = {
                    "physical_file_offset": f"0x{offset:06X}",
                    "target_hardware_register": register_address,
                    "raw_hex_instruction": opcode_context
                }
                bank_switch_events.append(event)

    memory_map = {
        "rom_name": rom_path,
        "total_detected_switches": len(bank_switch_events),
        "switch_points": bank_switch_events
    }

    with open("ssf2_detected_banks.json", "w") as out_file:
        json.dump(memory_map, out_file, indent=4)
    print(f"[+] Found {len(bank_switch_events)} bank-switching vectors.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("[!] Usage: python unwrap_ssf2.py <path_to_rom.bin>")
    else:
        scan_ssf2_bank_switches(sys.argv[1])
