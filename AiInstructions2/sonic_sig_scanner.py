import sys
import json

SIGNATURE_DATABASE = {
    "Kosinski_Decomp": {"hex_pattern": "48E70E3C267900FFB00042801018", "desc": "Kosinski decompression engine"},
    "Sonic_Physics_Floor_Collision": {"hex_pattern": "4E56FFFC48E73C3C4E7B00004280102E", "desc": "Sonic physics collision loop"},
    "Comper_Decomp": {"hex_pattern": "48E7E0E0207C00FFB00042811218", "desc": "Comper compression decompression framework"}
}

def scan_for_signatures(rom_path, json_banks_path):
    try:
        with open(json_banks_path, "r") as j_file:
            bank_map = json.load(j_file)
        with open(rom_path, "rb") as r_file:
            rom_data = r_file.read()
    except Exception as e:
        print(f"[!] Error: {e}")
        return

    identified_functions = []
    for point in bank_map.get("switch_points", []):
        offset = int(point["physical_file_offset"], 16)
        target_reg = point["target_hardware_register"]
        
        bank_chunk = rom_data[offset:min(offset + 512*1024, len(rom_data))]

        for label, sig_data in SIGNATURE_DATABASE.items():
            pattern_bytes = bytes.fromhex(sig_data["hex_pattern"])
            find_index = bank_chunk.find(pattern_bytes)
            while find_index != -1:
                match = {
                    "matched_label": label,
                    "absolute_physical_offset": f"0x{offset + find_index:06X}",
                    "switched_via_register": target_reg
                }
                identified_functions.append(match)
                find_index = bank_chunk.find(pattern_bytes, find_index + 1)

    with open("sonic_liberated_labels.json", "w") as out_p:
        json.dump({"identified_functions": identified_functions}, out_p, indent=4)
    print(f"[+] Re-indexed blueprint written to sonic_liberated_labels.json")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("[!] Usage: python sonic_sig_scanner.py <rom.bin> <ssf2_detected_banks.json>")
    else:
        scan_for_signatures(sys.argv[1], sys.argv[2])
