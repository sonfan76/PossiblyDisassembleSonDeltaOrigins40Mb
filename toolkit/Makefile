# =============================================================================
# VASM REBUILD PIPELINE FOR 40MBIT (5MB) SSF2 SEGA GENESIS ROM
# =============================================================================

VASM       = vasmm68k_mot
VASMFLAGS  = -Fbin -m68000 -no-opt -spaces
PYTHON     = python3
TARGET     = rebuilt_sonic_delta_40mb.bin

ASM_FILES  = $(sort $(wildcard BANK_*.asm))
BIN_SLICES = $(ASM_FILES:.asm=.bin)

.PHONY: all format clean verify

all: format $(TARGET)

format:
	$(PYTHON) format_for_vasm.py

%.bin: %.asm
	$(VASM) $(VASMFLAGS) -o $@ $<
	$(PYTHON) -c "data = open('$@','rb').read(); assert len(data) <= 0x80000, f'$@ exceeds 512KB ({len(data)} bytes)'; open('$@','wb').write(data.ljust(0x80000, b'\xFF')); print(f'[SLICE OK] $@ -> 524,288 bytes')"

$(TARGET): $(BIN_SLICES)
	cat $(BIN_SLICES) > $(TARGET)
	$(PYTHON) -c "\
import struct; \
rom = bytearray(open('$(TARGET)', 'rb').read()); \
csum = sum(struct.unpack('>' + 'H' * ((len(rom) - 0x200) // 2), rom[0x200:])) & 0xFFFF; \
struct.pack_into('>H', rom, 0x18E, csum); \
open('$(TARGET)', 'wb').write(rom); \
print(f'[ROM READY] {len(rom)} bytes written to $(TARGET) | Checksum: 0x{csum:04X}')"

verify: $(TARGET)
	cmp -l ../sonic_delta_origins.bin $(TARGET) | head -n 10 || true

clean:
	rm -f $(BIN_SLICES) $(TARGET)
