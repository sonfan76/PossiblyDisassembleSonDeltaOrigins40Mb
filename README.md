# PossiblyDisassembleSonDeltaOrigins40Mb
Feasability study on returning the Assembly code that was stuck together to make Sonic Delta Origins 40Mb, to the community (it was made using the public son 1 2 , 3&amp;k disassemblies, but the guy who put it together bans anyone who would in turn disassemble it, even though he used public disassemblies to make it)

The value in this is that it would provide a nice base for artists and M68K ASM programmers to make Sonic maps or even random generators for it as all the art assets would be reachable being in the same game. There has been one random level generator created in the past: s1rl-v011.bin  . A unified project such as SDO-40mb would be a good base to continue such things as it has all the art assets packed.

Neto boasts that it is not possible to disassemble "his" Sonic 1/2/3&K hack, (the ASM source code of which he took from the community disassemblies here on github) and his liutenants ban anyone who talks of such.
>Esrael Neto >— >9:13 PM
>If SEGA is not against the hack, who is you? Good luck with disassembling Sonic Delta Origins. The resulting code will easily have incorrect pointers due to how I handle the mapper.

Is he right?
Has the gauntlet been thrown down?

-----
Technical Digest: Reversing the Sonic
Delta Origins Bank-Switching Mapper
Executive Summary

Sonic Delta Origins (originally Sonic Delta 40Mb) is a Sega Genesis/Mega Drive ROM hack created
by Esrael Neto. It natively stitches Sonic 1, 2, 3, and Sonic & Knuckles into a single continuous game.
The developer claimed that standard disassembly would fail due to 'incorrect pointers' caused by his
custom mapper configuration. This digest documents the precise strategy, architectural layout, and
custom automation scripts required to completely bypass his obfuscation, resolve all pointers, and
cleanly disassemble the 40-Megabit ROM file.

Hardware Architecture & Memory Layout

The Sega Genesis CPU (Motorola 68000) has a native direct addressing limit of 32 Megabits (4
Megabytes) for ROM space (0x000000–0x3FFFFF). Because Sonic Delta Origins is a 40-Megabit (5
Megabyte) file, it requires a hardware-level bank-switching layout. Neto repurposed the official
commercial layout created by SEGA/Capcom for the 1993 Genesis release of Super Street Fighter II
(SSFII).

Memory Window Slot Name Hardware
Register Purpose / Behavior
0x000000–0x07FFFF Bank 00 (Fixed) None (Locked) Main engine vectors, boot
routines, and menu selectors.
0x080000–0x0FFFFF Slot 1 0xA130F1 Dynamically swaps active game
code blocks.
0x100000–0x17FFFF Slot 2 0xA130F3 Dynamically swaps active game
code blocks.
0x180000–0x1FFFFF Slot 3 0xA130F5 Commonly used for music
driver/DAC asset swaps.
0x200000–0x27FFFF Slot 4 0xA130F7 Dynamically swaps active
level/art data blocks.
0x280000–0x2FFFFF Slot 5 0xA130F9 Dynamically swaps active
level/art data blocks.
0x300000–0x37FFFF Slot 6 0xA130FB Dynamically swaps active
level/art data blocks.0x380000–0x3FFFFF
Slot 7
0xA130FD
Dynamically swaps active
level/art data blocks.
Tool 1: File-System ROM Splitter (Python Script)
import os
def split_sonic_delta_rom(rom_path, output_dir="extracted_banks"):
BANK_SIZE = 0x80000
if not os.path.exists(rom_path):
print(f"Error: Could not find ROM at '{rom_path}'")
return
if not os.path.exists(output_dir):
os.makedirs(output_dir)
with open(rom_path, "rb") as rom_file:
bank_number = 0
while True:
bank_data = rom_file.read(BANK_SIZE)
if not bank_data:
break
start_offset = bank_number * BANK_SIZE
end_offset = start_offset + len(bank_data) - 1
output_filename = f"bank_{bank_number:02d}_[0x{start_offset:06X}-0x{end_off
set:06X}].bin"
with open(os.path.join(output_dir, output_filename), "wb") as out_file:
out_file.write(bank_data)
bank_number += 1
print("Extraction complete!")
split_sonic_delta_rom("Sonic_Delta_Origins.md")Tool 2: Static Hardware Mapper Tracker (Ghidra Script)
from ghidra.program.model.symbol import SourceType
MAPPER_REGISTERS = {
0xA130F1: "SSF2_BANK_SLOT1_080000", 0xA130F3: "SSF2_BANK_SLOT2_100000",
0xA130F5: "SSF2_BANK_SLOT3_180000", 0xA130F7: "SSF2_BANK_SLOT4_200000",
0xA130F9: "SSF2_BANK_SLOT5_280000", 0xA130FB: "SSF2_BANK_SLOT6_300000",
0xA130FD: "SSF2_BANK_SLOT7_380000"
}
def analyze_mapper_writes():
program = getCurrentProgram()
listing = program.getListing()
symbol_table = program.getSymbolTable()
for addr_val, reg_name in MAPPER_REGISTERS.items():
addr = toAddr(addr_val)
if symbol_table.getPrimarySymbol(addr) is None:
symbol_table.createLabel(addr, reg_name, SourceType.USER_DEFINED)
instruction = listing.getInstructions(toAddr(0x000000), True)
while instruction.hasNext() and not currentMonitor.isCancelled():
ins = instruction.next()
if "move" in ins.getMnemonicString().lower():
for i in range(ins.getNumOperands()):
op_address = ins.getAddress(i)
if op_address and op_address.getOffset() in MAPPER_REGISTERS:
reg_name = MAPPER_REGISTERS[op_address.getOffset()]
bank_val = ins.getDefaultOperandRepresentation(0)
comment_str = "BANK SWITCH TRIGGERED FOR SLOT: {} (Value: {})".form
at(reg_name, bank_val)
ins.setComment(ins.PLATE_COMMENT, comment_str)
analyze_mapper_writes()
