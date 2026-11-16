#!/bin/bash
ROM="${1:-sonic_delta_origins.bin}"
OUT_DIR="rom_512kb_slices"
mkdir -p "$OUT_DIR"

FILE_SIZE=$(wc -c < "$ROM")
BANKS=$((FILE_SIZE / 524288))
echo "[SPLIT] Slicing $ROM ($FILE_SIZE bytes) into $BANKS x 512KB SSF2 banks..."

for ((i=0; i<BANKS; i++)); do
    printf -v OUT_NAME "%s/BANK_%02d.bin" "$OUT_DIR" "$i"
    dd if="$ROM" of="$OUT_NAME" bs=524288 skip="$i" count=1 status=none
    echo "  Wrote $OUT_NAME"
done
