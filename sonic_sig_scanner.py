import sys
import json

# Official open-source signature blocks from the S3&K GitHub Disassembly
# These hex patterns represent compiled Motorola 68000 assembly that never changes
SIGNATURE_DATABASE = {
    "Kosinski_Decomp": {
        "hex_pattern": "48E70E3C267900FFB00042801018", 
        "description": "Sonic 3 & Knuckles Kosinski graphical decompression algorithm routine engine."
    },
    "Sonic_Physics_Floor_Collision": {
        "hex_pattern": "4E56FFFC48E73C3C4E7B00004280102E",
        "description": "Core Sega Genesis Sonic physics floor and angle calculation collision array engine loop."
    },
    "Comper_Decomp": {
        "hex_pattern": "48E7E0E0207C00FFB00042811218",
        "description": "Sega Comper compression decompression routine framework handler."
    }
}

def scan_for_signatures(rom_path, json_banks_path):
    print(f"[*] Loading bank metadata from {json_banks_path}...")
    try:
        with open(json_banks_path, "r") as j_file:
            bank_map = json.load(j_file)
    except FileNotFoundError:
        print(f"[!] Error: Could not find '{json_banks_path}'. Run unwrap_ssf2.py first.")
        return

    try:
        with open(rom_path, "rb") as r_file:
            rom_data = r_file.read()
    except FileNotFoundError:
        print(f"[!] Error: Could not find ROM file '{rom_path}'.")
        return

    print("[*] Initiating signature scan across detected memory structures...")
    identified_functions = []

    # Iterate through the bank switch points detected in Phase A
    for point in bank_map.get("switch_points", []):
        offset_hex = point["physical_file_offset"]
        offset = int(offset_hex, 16)
        target_reg = point["target_hardware_register"]

        # Scan a 512KB window from the bank switch point
        scan_window_size = 512 * 1024
        end_offset = min(offset + scan_window_size, len(rom_data))
        
        bank_chunk = rom_data[offset:end_offset]

        # Look for our known GitHub signatures inside this bank
        for label, sig_data in SIGNATURE_DATABASE.items():
            pattern_bytes = bytes.fromhex(sig_data["hex_pattern"])
            
            # Find all occurrences of the algorithm signature inside the bank window
            find_index = bank_chunk.find(pattern_bytes)
            while find_index != -1:
                absolute_physical_pos = offset + find_index
                
                match = {
                    "matched_label": label,
                    "absolute_physical_offset": f"0x{absolute_physical_pos:06X}",
                    "relative_bank_offset": f"0x{find_index:05X}",
                    "switched_via_register": target_reg,
                    "description": sig_data["description"]
                }
                identified_functions.append(match)
                
                # Continue searching the rest of the bank window
                find_index = bank_chunk.find(pattern_bytes, find_index + 1)

    # Document the results
    output_report = {
        "source_rom": rom_path,
        "total_signatures_identified": len(identified_functions),
        "identified_functions": identified_functions
    }

    report_filename = "sonic_liberated_labels.json"
    with open(report_filename, "w") as out_p:
        json.dump(output_report, out_p, indent=4)

    print(f"[+] Scan Complete! Identified {len(identified_functions)} core engine functions.")
    print(f"[+] Re-indexed blueprint written to: '{report_filename}'")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("[!] Usage: python sonic_sig_scanner.py <rom.bin> <ssf2_detected_banks.json>")
    else:
        scan_for_signatures(sys.argv[1], sys.argv[2])
