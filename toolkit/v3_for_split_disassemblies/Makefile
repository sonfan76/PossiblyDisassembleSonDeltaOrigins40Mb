ROM ?= Sonic_Delta_Origins_2026.bin
REPO_OUT ?= sonic_delta_disasm_repo

.PHONY: all constants neto match trace pipeline repo xref clean

all: pipeline

constants:
	python3 import_upstream_constants.py --out upstream_ram_symbols.json

neto:
	python3 extract_neto_custom.py --rom $(ROM) --json-out neto_custom_hooks.json --inc-out src/custom_neto/neto_hooks_map.inc

match:
	python3 match_upstream.py --rom $(ROM) --out upstream_matches.json

trace:
	python3 collect_trace.py --trace trace_banks.txt --out resolved_switches.json

pipeline:
	chmod +x run_pipeline.sh
	./run_pipeline.sh $(ROM)

repo:
	python3 split_to_repo.py --rom $(ROM) --matches upstream_matches.json --hooks neto_custom_hooks.json --asm-dir disasm_banks --out $(REPO_OUT)
	python3 xref_enricher.py --repo $(REPO_OUT) --matches upstream_matches.json --ram upstream_ram_symbols.json --hooks neto_custom_hooks.json --switches resolved_switches.json
	python3 macro_beautifier.py --repo $(REPO_OUT)
	python3 source_block_swapper.py --repo $(REPO_OUT) --matches upstream_matches.json

xref:
	python3 xref_enricher.py --repo $(REPO_OUT) --matches upstream_matches.json --ram upstream_ram_symbols.json --hooks neto_custom_hooks.json --switches resolved_switches.json
	python3 macro_beautifier.py --repo $(REPO_OUT)
	python3 source_block_swapper.py --repo $(REPO_OUT) --matches upstream_matches.json

clean:
	rm -rf banks disasm_banks ghidra_proj upstream_ram_symbols.json neto_custom_hooks.json upstream_matches.json resolved_switches.json src/custom_neto $(REPO_OUT)
