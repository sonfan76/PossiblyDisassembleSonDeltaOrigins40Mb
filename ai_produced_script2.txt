import os

def split_sonic_delta_rom(rom_path, output_dir="extracted_banks"):
    # The SSFII mapper shifts data in strict 512 KB chunks (0x80000 bytes)
    BANK_SIZE = 0x80000  
    
    # Verify the file exists
    if not os.path.exists(rom_path):
        print(f"Error: Could not find the ROM file at '{rom_path}'")
        print("Please check the filename and try again.")
        return

    # Check the file size to ensure it's the 40-Megabit version
    file_size = os.path.getsize(rom_path)
    file_size_mb = (file_size * 8) / 1000000
    print(f"Opening ROM: {rom_path} ({file_size_mb:.1f} Megabits / {file_size} bytes)")

    # Create the output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created output directory: '{output_dir}/'")

    # Read the ROM and slice it up sequentially
    with open(rom_path, "rb") as rom_file:
        bank_number = 0
        while True:
            # Read exactly 512 KB at a time
            bank_data = rom_file.read(BANK_SIZE)
            
            # Break the loop if we hit the end of the file
            if not bank_data:
                break
                
            # Calculate the hex range for clear labeling
            start_offset = bank_number * BANK_SIZE
            end_offset = start_offset + len(bank_data) - 1
            
            # Generate the file name for this specific chunk
            output_filename = f"bank_{bank_number:02d}_[0x{start_offset:06X}-0x{end_offset:06X}].bin"
            output_path = os.path.join(output_dir, output_filename)
            
            # Write out the isolated bank file
            with open(output_path, "wb") as out_file:
                out_file.write(bank_data)
                
            print(f" -> Successfully extracted Bank {bank_number:02d} -> {output_filename}")
            bank_number += 1

    print("\nExtraction complete! All hardware banks have been cleanly separated.")
    print("You can now cross-reference these files individually inside Ghidra or your hex editor.")

# --- Execute the script ---
# Replace 'Sonic_Delta_Origins.md' with the exact filename of your ROM hack file
ROM_FILENAME = "Sonic_Delta_Origins.md" 

split_sonic_delta_rom(ROM_FILENAME)
