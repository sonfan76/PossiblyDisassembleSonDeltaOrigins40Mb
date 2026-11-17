#!/usr/bin/env python3
import re
import json
import argparse
from pathlib import Path

BANK_SIZE = 0x80000
MIN_ASSET_SIZE = 64
MIN_CODE_SIZE = 24
ASSET_EXTENSIONS = {".bin", ".nem", ".kos", ".kosm", ".eni", ".unc", ".wav"}

def mask_m68k_relocations(code_bytes):
    buf = bytearray(code_bytes)
    n = len(buf)
    i = 0
    while i + 1 < n:
        op = (buf[i] << 8) | buf[i + 1]
        if op in (0x4EB9, 0x4EF9) and i + 6 <= n:
            buf[i + 2 : i + 6] = b"\x00\x00\x00\x00"
            i += 6
            continue
        if (op & 0xF1FF) == 0x41F9 and i + 6 <= n:
            buf[i + 2 : i + 6] = b"\x00\x00\x00\x00"
            i += 6
            continue
        if (op & 0xF1FF) == 0x207C and i + 6 <= n:
            buf[i + 2 : i + 6] = b"\x00\x00\x00\x00"
            i += 6
            continue
        i += 2
    return bytes(buf)

def parse_as_listing(lst_path):
    symbols = []
    label_re = re.compile(r"^\s*\d+/\s*([0-9A-Fa-f]+)\s*:\s*([A-Za-z_][A-Za-z0-9_]*)\s*:")
    text = lst_path.read_text(encoding="utf-8", errors="ignore")
    for line in text.splitlines():
        m = label_re.match(line)
        if m:
            addr = int(m.group(1), 16)
            name = m.group(2)
            if not name.startswith(("loc_", ".", "@", "+")):
                symbols.append((name, addr))

    symbols = sorted(set(symbols), key=lambda x: x[1])
    routines = []
    for idx, (name, start) in enumerate(symbols):
        end = symbols[idx + 1][1] if idx + 1 < len(symbols) else start
        size = end - start
        if MIN_CODE_SIZE <= size <= 0x4000:
            routines.append((name, start, size))
    return routines

def index_reference_repos(repo_dirs):
    asset_prefix_index = {}
    code_exact_index = {}
    code_masked_index = {}

    for label, root_path in repo_dirs.items():
        root = Path(root_path)
        if not root.exists():
            print(f"[!] Warning: Reference directory not found: {root}")
            continue

        asset_count = 0
        for filepath in root.rglob("*"):
            if not filepath.is_file() or filepath.suffix.lower() not in ASSET_EXTENSIONS:
                continue
            data = filepath.read_bytes()
            if len(data) < MIN_ASSET_SIZE:
                continue

            rel_path = str(filepath.relative_to(root))
            entry = {"type": "asset", "repo": label, "name": rel_path, "size": len(data)}
            asset_prefix_index.setdefault(data[:32], []).append((data, entry))
            asset_count += 1
        print(f"[+] Indexed {asset_count} binary assets from {label}")

        code_count = 0
        for lst_file in root.glob("*.lst"):
            bin_candidate = lst_file.with_suffix(".bin")
            if not bin_candidate.exists():
                continue
            ref_rom = bin_candidate.read_bytes()
            routines = parse_as_listing(lst_file)
            for sym_name, start, size in routines:
                if start + size > len(ref_rom):
                    continue
                chunk = ref_rom[start : start + size]
                masked = mask_m68k_relocations(chunk)
                meta = {"type": "code", "repo": label, "name": sym_name, "ref_offset": f"0x{start:06X}", "size": size}
                code_exact_index.setdefault(chunk[:16], []).append((chunk, meta))
                code_masked_index.setdefault(masked[:16], []).append((masked, meta))
                code_count += 1
        if code_count > 0:
            print(f"[+] Indexed {code_count} compiled 68K routines from {label}")

    return asset_prefix_index, code_exact_index, code_masked_index

def scan_rom(rom_path, asset_idx, code_exact_idx, code_masked_idx):
    rom_data = Path(rom_path).read_bytes()
    rom_size = len(rom_data)
    print(f"[*] Scanning {rom_path} ({rom_size:,} bytes / {rom_size // BANK_SIZE} banks)...")

    matches = []
    pos = 0
    while pos <= rom_size - MIN_CODE_SIZE:
        matched = False

        if pos <= rom_size - MIN_ASSET_SIZE:
            p32 = rom_data[pos : pos + 32]
            if p32 in asset_idx:
                for ref_bytes, meta in asset_idx[p32]:
                    end_pos = pos + meta["size"]
                    if end_pos <= rom_size and rom_data[pos:end_pos] == ref_bytes:
                        matches.append({
                            "rom_offset": f"0x{pos:06X}",
                            "rom_offset_int": pos,
                            "bank": pos // BANK_SIZE,
                            "bank_offset": f"0x{pos % BANK_SIZE:05X}",
                            "size": meta["size"],
                            "kind": "asset",
                            "match_mode": "exact",
                            "repo": meta["repo"],
                            "symbol": meta["name"],
                        })
                        pos = (end_pos + 1) & ~1
                        matched = True
                        break
        if matched:
            continue

        p16 = rom_data[pos : pos + 16]
        if p16 in code_exact_idx:
            for ref_bytes, meta in code_exact_idx[p16]:
                end_pos = pos + meta["size"]
                if end_pos <= rom_size and rom_data[pos:end_pos] == ref_bytes:
                    matches.append({
                        "rom_offset": f"0x{pos:06X}",
                        "rom_offset_int": pos,
                        "bank": pos // BANK_SIZE,
                        "bank_offset": f"0x{pos % BANK_SIZE:05X}",
                        "size": meta["size"],
                        "kind": "code",
                        "match_mode": "exact",
                        "repo": meta["repo"],
                        "symbol": meta["name"],
                    })
                    pos = (end_pos + 1) & ~1
                    matched = True
                    break
        if matched:
            continue

        if code_masked_idx:
            window_masked = mask_m68k_relocations(rom_data[pos : pos + 16])
            if window_masked in code_masked_idx:
                for ref_masked, meta in code_masked_idx[window_masked]:
                    end_pos = pos + meta["size"]
                    if end_pos <= rom_size:
                        cand_masked = mask_m68k_relocations(rom_data[pos:end_pos])
                        if cand_masked == ref_masked:
                            matches.append({
                                "rom_offset": f"0x{pos:06X}",
                                "rom_offset_int": pos,
                                "bank": pos // BANK_SIZE,
                                "bank_offset": f"0x{pos % BANK_SIZE:05X}",
                                "size": meta["size"],
                                "kind": "code",
                                "match_mode": "relocated",
                                "repo": meta["repo"],
                                "symbol": meta["name"],
                            })
                            pos = (end_pos + 1) & ~1
                            matched = True
                            break
        if matched:
            continue

        pos += 2

    return matches

def main():
    parser = argparse.ArgumentParser(description="Match upstream assets & 68K code against 40Mb ROM")
    parser.add_argument("--rom", default="Sonic_Delta_Origins_2026.bin", help="Path to 40Mbit ROM")
    parser.add_argument("--s1", default="s1disasm-AS", help="Path to s1disasm-AS")
    parser.add_argument("--s2", default="s2disasm-master", help="Path to s2disasm-master")
    parser.add_argument("--sk", default="skdisasm-master", help="Path to skdisasm-master")
    parser.add_argument("--out", default="upstream_matches.json", help="Output JSON report")
    args = parser.parse_args()

    repos = {"s1disasm": args.s1, "s2disasm": args.s2, "skdisasm": args.sk}
    asset_idx, code_exact_idx, code_masked_idx = index_reference_repos(repos)
    matches = scan_rom(args.rom, asset_idx, code_exact_idx, code_masked_idx)

    bank_summary = {}
    for m in matches:
        b = m["bank"]
        bank_summary[b] = bank_summary.get(b, 0) + m["size"]

    report = {
        "rom": args.rom,
        "total_matches": len(matches),
        "asset_matches": sum(1 for m in matches if m["kind"] == "asset"),
        "code_matches": sum(1 for m in matches if m["kind"] == "code"),
        "matched_bytes_per_bank": {f"bank_{k:02d}": v for k, v in sorted(bank_summary.items())},
        "matches": matches,
    }

    Path(args.out).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"[+] Saved {len(matches)} total matches ({report['asset_matches']} assets, {report['code_matches']} code) -> {args.out}")

if __name__ == "__main__":
    main()
