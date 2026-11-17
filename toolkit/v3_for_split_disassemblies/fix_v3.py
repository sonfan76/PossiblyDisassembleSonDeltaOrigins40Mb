from pathlib import Path

bs = chr(92)

# 1. Fix double backslashes and missing .pop(0) in xref_enricher.py
xref = Path("xref_enricher.py")
x_txt = xref.read_text().replace(bs + bs, bs)
x_txt = x_txt.replace("lbl = sanitize_symbol(names)", "lbl = sanitize_symbol(names.pop(0))")
xref.write_text(x_txt)

# 2. Fix missing .pop(0) in import_upstream_constants.py
imp = Path("import_upstream_constants.py")
i_txt = imp.read_text().replace(bs + bs, bs)
i_txt = i_txt.replace('code_part = line.split(";")', 'code_part = line.split(";").pop(0)')
imp.write_text(i_txt)

# 3. Fix missing .pop(0) in source_block_swapper.py
sbs = Path("source_block_swapper.py")
s_txt = sbs.read_text().replace(bs + bs, bs)
s_txt = s_txt.replace('code_only = line.split(";")', 'code_only = line.split(";").pop(0)')
s_txt = s_txt.replace("parts.lower()", "parts.copy().pop(1).lower()")
s_txt = s_txt.replace("defined.add(parts)", "defined.add(parts.pop(0))")
sbs.write_text(s_txt)

print("All missing .pop(0) list indexes restored.")
