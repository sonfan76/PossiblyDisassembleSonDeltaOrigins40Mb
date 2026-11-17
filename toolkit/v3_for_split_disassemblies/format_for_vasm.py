#!/usr/bin/env python3
import re
import sys
from pathlib import Path

ADDR_PREFIX_RE = re.compile(r"^(?:ram:)?([0-9A-Fa-f]{6,8})\s+(?:[0-9A-Fa-f]{2}\s+)+")
HEX_LITERAL_RE = re.compile(r"\b0x([0-9A-Fa-f]+)\b")
AS_LOCAL_DEF_RE = re.compile(r"^(\s*)@([A-Za-z0-9_]+)\s*:")
AS_LOCAL_REF_RE = re.compile(r"(?<![A-Za-z0-9_])@([A-Za-z0-9_]+)\b")


def normalize_vasm_operands(code_part: str) -> str:
    """
    Enforce strict vasmm68k_mot operand rules:
      - Preserve leading indentation and single whitespace separator between mnemonic and operands
      - Strip ALL spaces inside the operand field (commas, parentheses, movem slashes)
      - Preserve spaces inside quoted strings ('...' or "...")
    """
    m_indent = re.match(r"^(\s*)(.*)$", code_part)
    indent, body = m_indent.group(1), m_indent.group(2)
    if not body:
        return code_part

    # If line is a label definition only (e.g. "EntryPoint:"), leave as-is
    if re.match(r"^[A-Za-z_.][A-Za-z0-9_.]*\s*:$", body):
        return indent + body.rstrip()

    # Split optional leading label + mnemonic from the operand field
    # e.g. "Label: move.b (a0), d1" or "move.b (a0), d1"
    m_split = re.match(r"^((?:[A-Za-z_.][A-Za-z0-9_.]*:\s*)?[A-Za-z_][A-Za-z0-9_.]*)(\s+)(.*)$", body)
    if not m_split:
        return indent + body

    head, sep, operands = m_split.groups()

    # Strip all unquoted spaces inside operands
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

    return f"{indent}{head}{sep}{''.join(cleaned_ops)}"


def convert_line(line: str) -> str:
    stripped = line.rstrip()
    if not stripped:
        return ""
    if stripped.lstrip().startswith((";", "*")):
        return stripped

    # Separate code from trailing ';' comment
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

    # 1. Strip leading Ghidra address + raw hex byte columns
    cleaned = ADDR_PREFIX_RE.sub("    ", code_part)

    # 2. Convert C-style 0xABCD literals to Motorola $ABCD syntax
    cleaned = HEX_LITERAL_RE.sub(r"$\1", cleaned)

    # 3. Convert AS local labels (@loop) to vasm local labels (.loop)
    cleaned = AS_LOCAL_DEF_RE.sub(r"\1.\2:", cleaned)
    cleaned = AS_LOCAL_REF_RE.sub(r".\1", cleaned)

    # 4. Convert Ghidra data directives to vasm dc.b / dc.w / dc.l
    cleaned = re.sub(r"\b(?:db|undefined1)\b", "dc.b", cleaned)
    cleaned = re.sub(r"\b(?:dw|undefined2)\b", "dc.w", cleaned)
    cleaned = re.sub(r"\b(?:dd|undefined4)\b", "dc.l", cleaned)

    # 5. Strip all unquoted spaces inside the operand field
    cleaned = normalize_vasm_operands(cleaned)

    return cleaned + comment_part


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 format_for_vasm.py <input_raw.asm> <output_vasm.asm>")
        sys.exit(1)

    in_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])

    lines = in_path.read_text(encoding="utf-8", errors="ignore").splitlines()
    converted = [convert_line(line) for line in lines]
    out_path.write_text("\n".join(converted) + "\n", encoding="utf-8")
    print(f"[+] Formatted {in_path.name} -> {out_path}")


if __name__ == "__main__":
    main()
