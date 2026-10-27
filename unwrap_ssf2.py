import sys
import json

# Define the SSF2 Mapper Hardware Registry Bounds
# Registers sit at odd bytes between $A130F1 and $A130FF
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
    print(f"[*] Total ROM Size: {rom_size / (1024*1024):.2f} MB ({rom_size} bytes)")

    bank_switch_events = []

    # Motorola 68000 Opcode patterns for writing to Absolute Long Addresses
    # Standard: move.b dX, ($A130FX) -> Machine code often starts with 13C0 or similar
    # We will search sequentially for the exact byte signatures of the hardware registers
    for offset in range(0, rom_size - 6, 2):
        # Read a 4-byte slice to check for destination addresses
        # SSF2 registers match the pattern: 00 A1 30 FX
        if rom_data[offset+2] == 0x00 and rom_data[offset+3] == 0xA1 and rom_data[offset+4] == 0x30:
            reg_byte = rom_data[offset+5]
            # Verify it hits an odd register between F1 and FF
            if 0xF1 <= reg_byte <= 0xFF and reg_byte % 2 != 0:
                register_address = f"0xA130{reg_byte:02X}"
                
                # Capture the surrounding opcode context for the AI parser
                opcode_context = rom_data[offset:offset+6].hex().upper()
                
                event = {
                    "physical_file_offset": f"0x{offset:06X}",
                    "target_hardware_register": register_address,
                    "raw_hex_instruction": opcode_context
                }
                bank_switch_events.append(event)

    # Structure the found metadata into a clean layout
    memory_map = {
        "rom_name": rom_path,
        "total_detected_switches": len(bank_switch_events),
        "switch_points": bank_switch_events
    }

    # Export to a structured JSON file that your AI agents can read natively
    output_filename = "ssf2_detected_banks.json"
    with open(output_filename, "w") as out_file:
        json.dump(memory_map, out_file, indent=4)
        
    print(f"[+] Scan complete! Found {len(bank_switch_events)} bank-switching vectors.")
    print(f"[+] Output successfully mapped to structural file: '{output_filename}'")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("[!] Usage: python unwrap_ssf2.py <path_to_sonic_delta_rom.bin>")
    else:
        scan_ssf2_bank_switches(sys.argv[1])
	
