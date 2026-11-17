#!/usr/bin/env python3
import shutil
import struct
import tempfile
import subprocess
from pathlib import Path

REQUIRED_SCRIPTS = [
    "import_upstream_constants.py",
    "extract_neto_custom.py",
    "match_upstream.py",
    "split_to_repo.py",
    "xref_enricher.py",
    "macro_beautifier.py",
    "source_block_swapper.py",
]

def build_test_fixtures(work_dir: Path):
    s1_dir = work_dir / "s1disasm-AS"
    sk_dir = work_dir / "skdisasm-master"
    (s1_dir / "artnem").mkdir(parents=True)
    (sk_dir / "General").mkdir(parents=True)

    (s1_dir / "_Variables.asm").write_text("v_screenposx = $FFFFF700\n", encoding="utf-8")
    (sk_dir / "s3.constants.asm").write_text("Camera_X_pos equ $FFFFEE00\n", encoding="utf-8")
    fake_nem = bytes((i * 7 + 3) & 0xFF for i in range(128))
    (s1_dir / "artnem" / "TestArt.nem").write_bytes(fake_nem)

    rom_buf = bytearray(0x100000)
    rom_buf[0x000400:0x000408] = struct.pack(">HHI", 0x13FC, 0x0001, 0x00A130F1)
    rom_buf[0x000408:0x000410] = struct.pack(">HHI", 0x13FC, 0x0004, 0x00A130F3)
    sig = b"--Neto - Depurador Hex-- Excecao $41: SRAM nao disponivel\x00"
    rom_buf[0x000500 : 0x000500 + len(sig)] = sig
    rom_buf[0x081000 : 0x081000 + len(fake_nem)] = fake_nem

    rom_path = work_dir / "test_sonic_delta.bin"
    rom_path.write_bytes(rom_buf)

    disasm_dir = work_dir / "disasm_banks"
    disasm_dir.mkdir()
    sample_asm = """    org $000000
EntryPoint:
    move.w  #$0100, ($00A11100).l
    move.w  #$8004, ($00C00004).l
    move.l  #$40000000, ($00C00004).l
    move.w  ($FFFFF700).w, d0
    move.w  #$0000, ($00A11100).l
Neto_SSF2_SSF2_SRAM_CTRL_000400:
    move.b  #$01, ($00A130F1).l
    move.b  #$04, ($00A130F3).l
    rts
"""
    (disasm_dir / "bank_00.asm").write_text(sample_asm, encoding="utf-8")
    return rom_path, s1_dir, sk_dir, disasm_dir

def run_cmd(cmd, cwd):
    res = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{res.stderr}")

def main():
    toolkit_dir = Path.cwd()
    with tempfile.TemporaryDirectory(prefix="sd_v3_test_") as tmp:
        work = Path(tmp)
        for script in REQUIRED_SCRIPTS:
            shutil.copy2(toolkit_dir / script, work / script)
        rom_path, s1_dir, sk_dir, disasm_dir = build_test_fixtures(work)
        repo_out = work / "test_repo"

        run_cmd(["python3", "import_upstream_constants.py", "--out", "upstream_ram_symbols.json"], work)
        run_cmd(["python3", "extract_neto_custom.py", "--rom", rom_path.name], work)
        run_cmd(["python3", "match_upstream.py", "--rom", rom_path.name, "--s1", str(s1_dir), "--sk", str(sk_dir)], work)
        run_cmd(["python3", "split_to_repo.py", "--rom", rom_path.name, "--asm-dir", str(disasm_dir), "--out", str(repo_out)], work)
        run_cmd(["python3", "xref_enricher.py", "--repo", str(repo_out)], work)
        run_cmd(["python3", "macro_beautifier.py", "--repo", str(repo_out)], work)
        run_cmd(["python3", "source_block_swapper.py", "--repo", str(repo_out)], work)

        part0 = (repo_out / "src" / "banks" / "bank_00_part000.asm").read_text()
        assert "s1_v_screenposx" in part0
        assert "stopZ80" in part0
        print("[+] ALL V3 PIPELINE TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
