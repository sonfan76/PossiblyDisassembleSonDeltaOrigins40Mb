#!/usr/bin/env python3
import subprocess, sys
from pathlib import Path

ALL_TRACKS = [
    (1,  "1_Unlock_the_Gate.wav", "Unlock the Gate (Opening Manifesto)"),
    (2,  "2_Free_the_Source_.wav", "Free the Source"),
    (3,  "3_Mstyle_Free_the_Source__.wav", "Free the Source (M-Style)"),
    (4,  "4_Unlock_the_Gate___.wav", "Unlock the Gate (Alt)"),
    (5,  "ASM_For_Free__.wav", "ASM For Free (Take 1)"),
    (6,  "ASM_For_Free___.wav", "ASM For Free (Take 2 - Ice Cube Style)"),
    (7,  "ASM_For_Free____.wav", "ASM For Free (Take 3)"),
    (8,  "ASM_FOR_FREE.wav", "ASM For Free (Main)"),
    (9,  "B10_IM_Free_the Software.wav", "Free the Software (Iron Maiden Style)"),
    (10, "B11_IM_Free_the Software_.wav", "Free the Software (Iron Maiden Style - Alt)"),
    (11, "B15_JP_HP_For_Freedom.wav", "Hell Patrol for Freedom (Judas Priest Style)"),
    (12, "B16_JP_HP_For_Freedom_.wav", "Hell Patrol for Freedom (Judas Priest Style - Alt)"),
    (13, "B17_IM_Free_the_Software__.wav", "Free the Software (1970s Fantasy Parchment Edition)"),
    (14, "C15___AX_6_FTS.wav", "Free the Software (AX-6 Tupac Style)"),
    (15, "C16___AX_6_FTS_.wav", "Free the Software (AX-6 Tupac Style - Alt)"),
    (16, "C20_M68K_under_Blood_Red_Skies.wav", "M68K Under Blood Red Skies"),
    (17, "C21_M68K_under_Blood_Red_Skies_.wav", "M68K Under Blood Red Skies (Alt)"),
    (18, "C24_YM_Copyleft_Dawn.wav", "Copyleft Dawn (Yngwie Malmsteen Style)"),
    (19, "C25_YM_Copyleft_Dawn_.wav", "Copyleft Dawn (Yngwie Malmsteen Style - Alt)"),
    (20, "C26_DK_DISASSEMBLE.wav", "DISASSEMBLE (Dethklok Style)"),
    (21, "C27_DK_DISASSEMBLE_.wav", "DISASSEMBLE (Dethklok Style - Alt)"),
    (22, "C28_IM_Break_the_Vault.wav", "Break the Vault (Iron Maiden / Parchment Edition)"),
    (23, "C29_IM_Break_the_Vault_.wav", "Break the Vault (Iron Maiden / Parchment Edition - Alt)"),
    (24, "xx7_BLOOD_RED_SKIES_1.wav", "Blood Red Skies (Crimson Mix)"),
    (25, "xx9_B12_NuMtl_HP_FOR_COPYLEFT.wav", "Hell Patrol for Copyleft (Nu-Metal Mix)"),
    (26, "xx9_B13_DrgnFrcMtl_HP_FOR_COPYLEFT.wav", "Hell Patrol for Copyleft (DragonForce Mix)"),
    (27, "zz9_E30_MJ_Smooth_Disassembler1.wav", "Smooth Disassembler (Michael Jackson Style)"),
    (28, "zz9_E31_MJ_Smooth_Disassembler_2.wav", "Smooth Disassembler (Michael Jackson Style - Alt)"),
    (29, "zz9_E33______silence.wav", "Silence (Interlude)"),
    (30, "zz9_E35_DO_When_born_in_the_dark_BONUS.wav", "When Born in the Dark (Dio Style) [Bonus]"),
    (31, "zz9_E36_DO_When_born_in_the_dark___BONUS.wav", "When Born in the Dark (Dio Style - Alt) [Bonus]"),
    (32, "zz9_E37_DO_Remember_the_Fire_1983_BONUS.wav", "Remember the Fire 1983 (Dio Style) [Bonus]"),
    (33, "zz9_E38_DO_Remember_the_Fire_1983___BONUS.wav", "Remember the Fire 1983 (Dio Style - Alt) [Bonus]"),
    (34, "zz9_E39_JP86_M68K_Dawn__The_Software_Is_Free_BONUS.wav", "M68K Dawn (The Software Is Free) [Part I] (Judas Priest '86) [Bonus]"),
    (35, "zz9_E40_JP86_M68K_Dawn__The_Software_Is_Free___BONUS.wav", "M68K Dawn (The Software Is Free) (Judas Priest '86) [Bonus]"),
]

ABRIDGED_NUMS = [1, 6, 9, 12, 13, 15, 16, 18, 20, 21, 22, 24, 26, 28, 29, 30, 33, 35]
ALT_NUMS      = [2, 3, 4, 5, 7, 8, 10, 11, 14, 17, 19, 20, 21, 23, 25, 27, 29, 31, 32, 34]

# Title overrides for Abridged Edition (drops "[Bonus]" tag on the main single-disc cut)
ABRIDGED_TITLE_OVERRIDES = {
    30: "When Born in the Dark (Dio Style)",
    33: "Remember the Fire 1983 (Dio Style - Alt)",
    35: "M68K Dawn (The Software Is Free) (Judas Priest '86)",
}

def get_duration(p):
    r = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", str(p)],
        capture_output=True, text=True, check=True
    )
    return float(r.stdout.strip())

def fmt(sec):
    m, s = divmod(int(round(sec)), 60)
    return f"{m:02d}:{s:02d}"

def write_disc(src, cue_name, album_title, track_list):
    cue = [
        'REM GENRE "Heavy Metal / Hip-Hop"',
        'REM DATE 2026',
        'REM COMMENT "Dedicated in memory of Mircea Kitsune - CC0 1.0 Public Domain"',
        f'TITLE "{album_title}"',
    ]
    lines = []
    off = 0.0
    for idx, t in enumerate(track_list, 1):
        stitle = t["title"].replace('"', "'")
        cue += [
            f'FILE "{t["fn"]}" WAVE',
            f'  TRACK {idx:02d} AUDIO',
            '    FLAGS DCP',
            f'    TITLE "{stitle}"',
            '    INDEX 01 00:00:00',
        ]
        lines.append(f"  {idx:02d} (Orig #{t['num']:02d}) [{fmt(off)}] {t['title']} ({fmt(t['dur'])}) -> {t['fn']}")
        off += t["dur"]
    (src / cue_name).write_text("\n".join(cue) + "\n", encoding="utf-8")
    return lines, off

def main():
    src = Path(".").resolve()
    catalog = {}

    for num, fn, title in ALL_TRACKS:
        p = src / fn
        if not p.exists():
            sys.exit(f"Missing: {fn}")
        catalog[num] = {"num": num, "fn": fn, "title": title, "dur": get_duration(p)}

    # 1. Abridged Single-Disc Edition
    abridged_list = []
    for n in ABRIDGED_NUMS:
        item = dict(catalog[n])
        if n in ABRIDGED_TITLE_OVERRIDES:
            item["title"] = ABRIDGED_TITLE_OVERRIDES[n]
        abridged_list.append(item)

    lines, dur = write_disc(
        src, "Abridged_One_CD.cue",
        "M68K Free the Software (Abridged Single-Disc Edition)",
        abridged_list
    )
    (src / "MANIFEST_Abridged.txt").write_text(
        "M68K FREE THE SOFTWARE \u2014 ABRIDGED SINGLE-DISC EDITION (CC0 1.0 | COPY PERMITTED)\n\n"
        + "\n".join(lines)
        + f"\n\nTotal Runtime: {fmt(dur)}\nBurn with: cdrdao write --device /dev/sr0 --speed 8 --eject Abridged_One_CD.cue\n",
        encoding="utf-8"
    )
    print(f"[OK] Abridged_One_CD.cue ({fmt(dur)}) + MANIFEST_Abridged.txt")

    # 2. Alternate & Companion Disc
    alt_list = [dict(catalog[n]) for n in ALT_NUMS]
    lines, dur = write_disc(
        src, "Alt_One_CD.cue",
        "M68K Free the Software (Alternate & Companion Disc)",
        alt_list
    )
    (src / "MANIFEST_Alt.txt").write_text(
        "M68K FREE THE SOFTWARE \u2014 ALTERNATE & COMPANION DISC (CC0 1.0 | COPY PERMITTED)\n\n"
        + "\n".join(lines)
        + f"\n\nTotal Runtime: {fmt(dur)}\nBurn with: cdrdao write --device /dev/sr0 --speed 8 --eject Alt_One_CD.cue\n",
        encoding="utf-8"
    )
    print(f"[OK] Alt_One_CD.cue      ({fmt(dur)}) + MANIFEST_Alt.txt")

    # 3. Complete 2-CD Archive
    d1_list = [catalog[n] for n in range(1, 20)]
    d2_list = [catalog[n] for n in range(20, 36)]
    l1, dur1 = write_disc(src, "Complete_Disc_01.cue", "M68K Free the Software (Complete 2-CD Archive) - Disc 1", d1_list)
    l2, dur2 = write_disc(src, "Complete_Disc_02.cue", "M68K Free the Software (Complete 2-CD Archive) - Disc 2", d2_list)

    (src / "MANIFEST_Complete.txt").write_text(
        f"M68K FREE THE SOFTWARE \u2014 COMPLETE 2-CD ARCHIVE ({fmt(dur1 + dur2)}, 2 CDs | CC0 1.0 | COPY PERMITTED)\n\n"
        f"DISC 01 (Tracks 01-19 | {fmt(dur1)})\n" + "\n".join(l1) + "\n\n"
        f"DISC 02 (Tracks 20-35 | {fmt(dur2)})\n" + "\n".join(l2) + "\n\n"
        "Burn with: cdrdao write --device /dev/sr0 --speed 8 --eject Complete_Disc_01.cue\n",
        encoding="utf-8"
    )
    print(f"[OK] Complete_Disc_01.cue ({fmt(dur1)}) & Complete_Disc_02.cue ({fmt(dur2)}) + MANIFEST_Complete.txt")
    print("\nAll .cue sheets generated with FLAGS DCP (COPY PERMITTED) and 0 extra bytes used.")

if __name__ == "__main__":
    main()
