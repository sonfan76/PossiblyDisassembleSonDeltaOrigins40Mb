#!/usr/bin/env bash
set -euo pipefail

ROM="${1:-Sonic_Delta_Origins_2026.bin}"
GHIDRA_HEADLESS="${GHIDRA_HEADLESS:-analyzeHeadless}"
REPO_OUT="${REPO_OUT:-sonic_delta_disasm_repo}"

python3 import_upstream_constants.py --out upstream_ram_symbols.json
python3 extract_neto_custom.py --rom "$ROM" --json-out neto_custom_hooks.json --inc-out src/custom_neto/neto_hooks_map.inc
python3 match_upstream.py --rom "$ROM" --out upstream_matches.json

mkdir -p banks disasm_banks ghidra_proj
split -b 524288 -d -a 2 --additional-suffix=.bin "$ROM" banks/bank_

if command -v "$GHIDRA_HEADLESS" >/dev/null 2>&1; then
    for bank_bin in banks/bank_*.bin; do
        base=$(basename "$bank_bin" .bin)
        "$GHIDRA_HEADLESS" ./ghidra_proj "SonicDelta_${base}" \
            -import "$bank_bin" \
            -processor 68000:BE:32:default \
            -postScript ghidra_auto_bank.py \
            -overwrite
    done
fi

if [ -f format_for_vasm.py ]; then
    for raw_asm in disasm_banks/raw_bank_*.asm; do
        [ -e "$raw_asm" ] || continue
        out_asm="disasm_banks/$(basename "$raw_asm" | sed 's/^raw_//')"
        python3 format_for_vasm.py "$raw_asm" "$out_asm"
    done
fi

python3 split_to_repo.py --rom "$ROM" --matches upstream_matches.json --hooks neto_custom_hooks.json --asm-dir disasm_banks --out "$REPO_OUT"
python3 xref_enricher.py --repo "$REPO_OUT" --matches upstream_matches.json --ram upstream_ram_symbols.json --hooks neto_custom_hooks.json --switches resolved_switches.json
python3 macro_beautifier.py --repo "$REPO_OUT"
python3 source_block_swapper.py --repo "$REPO_OUT" --matches upstream_matches.json
