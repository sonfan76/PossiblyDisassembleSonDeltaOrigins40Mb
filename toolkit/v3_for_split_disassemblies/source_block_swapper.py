#!/usr/bin/env python3
import re
import json
import argparse
from pathlib import Path

UPSTREAM_ROOTS = {
    "s1disasm": Path("s1disasm-AS"),
    "s2disasm": Path("s2disasm-master"),
    "skdisasm": Path("skdisasm-master"),
}

GLOBAL_LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:")
TERMINATOR_RE = re.compile(r"^\s*(?:rts|rte|jmp)\b", re.IGNORECASE)
BRANCH_TARGET_RE = re.compile(
    r"^\s*(?:bra|bsr|beq|bne|bpl|bmi|bcc|bcs|bvc|bvs|bhi|bls|bge|blt|bgt|ble|jmp|jsr)(?:\.[bws])?\s+([A-Za-z0-9_@.+/-]+)",
    re.IGNORECASE,
)
ANON_LABEL_DEF_RE = re.compile(r"^\s*[+-]+\s*:?\s*(?:;.*)?$")
AS_LOCAL_DEF_RE = re.compile(r"^(\s*)@([A-Za-z0-9_]+)\s*:")
AS_LOCAL_REF_RE = re.compile(r"(?<![A-Za-z0-9_])@([A-Za-z0-9_]+)\b")


def load_defined_constants(repo_dir: Path):
    defined = set()
    for inc_name in ("human_constants.inc", "ssf2_mapper.inc"):
        inc_file = repo_dir / "src" / inc_name
        if not inc_file.exists():
            continue
        for line in inc_file.read_text(encoding="utf-8", errors="ignore").splitlines():
            parts = line.strip().split()
            if len(parts) >= 3 and parts[1].lower() in ("equ", "="):
                defined.add(parts[0])
    return defined


def normalize_line_for_vasm(line: str) -> str:
    """Convert AS @local labels to .local and strip unquoted spaces in operands."""
    stripped = line.rstrip()
    if not stripped or stripped.lstrip().startswith((";", "*")):
        return stripped

    # Separate code from ';' comment
    comment_part = ""
    in_quote = None
    split_idx = None
    for idx, ch in enumerate(stripped):
        if in_quote:
            if ch == in_quote:
                in_quote = None
        elif ch in ('"', "'"):
            in_quote = ch
        elif ch == ";":
            split_idx = idx
            break

    if split_idx is not None:
        code_part = stripped[:split_idx]
        comment_part = stripped[split_idx:]
    else:
        code_part = stripped

    # Convert @local -> .local
    code_part = AS_LOCAL_DEF_RE.sub(r"\1.\2:", code_part)
    code_part = AS_LOCAL_REF_RE.sub(r".\1", code_part)

    # Strip unquoted spaces inside operand field
    m_indent = re.match(r"^(\s*)(.*)$", code_part)
    indent, body = m_indent.group(1), m_indent.group(2)
    if not body or re.match(r"^[A-Za-z_.][A-Za-z0-9_.]*\s*:$", body):
        return indent + body.rstrip() + comment_part

    m_split = re.match(r"^((?:[A-Za-z_.][A-Za-z0-9_.]*:\s*)?[A-Za-z_][A-Za-z0-9_.]*)(\s+)(.*)$", body)
    if not m_split:
        return indent + body + comment_part

    head, sep, operands = m_split.groups()
    cleaned_ops = []
    in_quote = None
    for ch in operands:
        if in_quote:
            cleaned_ops.append(ch)
            if ch == in_quote:
                in_quote = None
            continue
        if ch in ('"', "'"):
            in_quote = ch
            cleaned_ops.append(ch)
            continue
        if ch in (" ", "\t"):
            continue
        cleaned_ops.append(ch)

    return f"{indent}{head}{sep}{''.join(cleaned_ops)}{comment_part}"


def extract_upstream_routine(repo_tag: str, raw_symbol: str):
    root = UPSTREAM_ROOTS.get(repo_tag)
    if not root or not root.exists():
        return None, None
    label_re = re.compile(rf"^\s*{re.escape(raw_symbol)}\s*:")
    for asm_file in root.rglob("*.asm"):
        try:
            lines = asm_file.read_text(encoding="utf-8", errors="ignore").splitlines()
        except Exception:
            continue
        for idx, line in enumerate(lines):
            if not label_re.match(line):
                continue
            start_idx = idx
            while start_idx > 0 and idx - start_idx <= 5:
                if lines[start_idx - 1].strip().startswith(";"):
                    start_idx -= 1
                else:
                    break
            block = []
            saw_terminator = False
            for cur_idx in range(start_idx, len(lines)):
                cur_line = lines[cur_idx]
                stripped = cur_line.strip()
                if cur_idx > idx:
                    m_lbl = GLOBAL_LABEL_RE.match(stripped)
                    if m_lbl and not m_lbl.group(1).startswith(("loc_", "byte_", "word_")):
                        if saw_terminator:
                            break
                        return None, None
                block.append(cur_line)
                if TERMINATOR_RE.match(stripped):
                    saw_terminator = True
            if saw_terminator and len(block) >= 2:
                return block, f"{asm_file.as_posix()}:{idx + 1}"
    return None, None


def is_block_self_contained(block_lines, entry_symbol: str, defined_symbols: set):
    local_labels = {entry_symbol}
    for line in block_lines:
        stripped = line.strip()
        # Reject blocks that define AS anonymous '+' or '-' labels
        if ANON_LABEL_DEF_RE.match(stripped):
            return False
        m_lbl = GLOBAL_LABEL_RE.match(stripped)
        if m_lbl:
            local_labels.add(m_lbl.group(1))

    for line in block_lines:
        code_only = line.split(";")[0]
        m_br = BRANCH_TARGET_RE.match(code_only)
        if m_br:
            target = m_br.group(1)
            # Reject branches targeting AS anonymous '+' / '-' labels
            if target.startswith(("+", "-")):
                return False
            # Local labels starting with '.' or '@' are safe
            if target.startswith((".", "@")):
                continue
            if target not in local_labels and target not in defined_symbols:
                return False
    return True


def main():
    parser = argparse.ArgumentParser(description="Swap exact-match routines with verbatim upstream ASM blocks")
    parser.add_argument("--repo", default="sonic_delta_disasm_repo")
    parser.add_argument("--matches", default="upstream_matches.json")
    args = parser.parse_args()

    repo = Path(args.repo)
    report = json.loads(Path(args.matches).read_text(encoding="utf-8"))
    defined_symbols = load_defined_constants(repo)

    swapped = 0
    skipped = 0

    for m in report.get("matches", []):
        if m.get("kind") != "code" or m.get("match_mode") != "exact":
            continue
        repo_tag = m["repo"]
        raw_sym = m["symbol"]
        rom_offset = m["rom_offset_int"]
        module_stem = f"{repo_tag}_{raw_sym}_{rom_offset:06X}"
        target_asm = repo / "src" / repo_tag / f"{module_stem}.asm"
        if not target_asm.exists():
            continue

        block_lines, src_loc = extract_upstream_routine(repo_tag, raw_sym)
        if not block_lines or not is_block_self_contained(block_lines, raw_sym, defined_symbols):
            skipped += 1
            continue

        bak_file = target_asm.with_suffix(".asm.ghidra.bak")
        if not bak_file.exists():
            bak_file.write_text(target_asm.read_text(encoding="utf-8"), encoding="utf-8")

        vasm_lines = [normalize_line_for_vasm(l) for l in block_lines]
        header = [
            f"; VERBATIM UPSTREAM SOURCE SWAP: {src_loc}",
            f"{module_stem}:",
        ]
        target_asm.write_text("\n".join(header + vasm_lines) + "\n", encoding="utf-8")
        swapped += 1

    print(f"[+] Source-block swapper complete: {swapped} upgraded ({skipped} kept as Ghidra disassembly).")


if __name__ == "__main__":
    main()
