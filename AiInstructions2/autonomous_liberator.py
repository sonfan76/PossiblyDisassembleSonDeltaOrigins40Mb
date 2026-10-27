import subprocess
import os
import sys

def main():
    if len(sys.argv) < 2:
        print("Usage: python autonomous_liberator.py <rom_file.bin>")
        return
        
    rom_file = sys.argv[1]
    
    print("[1/3] Executing SSF2 Hardware Register Unwrapping...")
    subprocess.run(["python", "unwrap_ssf2.py", rom_file])
    
    if not os.path.exists("ssf2_detected_banks.json"):
        print("[!] Phase A Failed.")
        return
        
    print("[2/3] Executing Signature-Matching Cross-Reference Scanner...")
    subprocess.run(["python", "sonic_sig_scanner.py", rom_file, "ssf2_detected_banks.json"])
    
    if not os.path.exists("sonic_liberated_labels.json"):
        print("[!] Phase B Failed.")
        return
        
    print("[3/3] System Mapping Ready. Feed the output 'sonic_liberated_labels.json' straight into Cursor IDE / local Claude workspace to fully extract human-readable .asm!")

if __name__ == "__main__":
    main()
