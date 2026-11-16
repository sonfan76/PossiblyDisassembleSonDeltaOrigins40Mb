#!/bin/bash
set -e

GHIDRA_DIR="/opt/ghidra"
PROJECT_DIR="./ghidra_proj"
ROM="${1:-sonic_delta_origins.bin}"

echo "[1/3] Capturing live SSF2 bank switches from BlastEm..."
python3 collect_trace.py "$ROM"
cp -f resolved_switches.json ~/resolved_switches.json

echo "[2/3] Running Ghidra headless overlay builder and vasm exporter..."
mkdir -p "$PROJECT_DIR"
"$GHIDRA_DIR/support/analyzeHeadless" "$PROJECT_DIR" SonicDeltaSSF2Proj \
    -import "$ROM" \
    -processor "68000:BE:32:default" \
    -postScript ghidra_auto_bank.py \
    -deleteProject

echo "[3/3] Copying vasm formatter and Makefile to export folder..."
cp -f format_for_vasm.py Makefile ~/sonic_delta_vasm_export/
echo "[COMPLETE] Run 'cd ~/sonic_delta_vasm_export && make && make verify' to build and verify."
