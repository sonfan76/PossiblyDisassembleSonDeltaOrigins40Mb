=======================================+=======================================
PRACTICE SESSIONS —                    & MASTERING SUITE (2026)
=======================================+=======================================

1. OVERVIEW & GEAR CHAIN
------------------------
Late-night / early-morning doom metal and neoclassical improvisation recorded
live on Devuan GNU/Linux.

- Guitar:      Scalloped B.C. Rich Warbeast (bare-handed / no pick)
- Overdrive:   DOD Overdrive Preamp 250
- Tuning:      Standard / Drop-D (harmonic minor, Phrygian dominant & doom riffs)
- License:     CC0 1.0 Universal (Public Domain Dedication)


2. INCLUDED AUDIO FILES (ROOM-CORRECTED BASELINE + 4 GENRE PRESET MASTERS)
--------------------------------------------------------------------------
All 320 kbps / 44.1 kHz MP3 files come from the November 26, 2026 practice
session. Because the baseline (_final) recording already had room-acoustics
cleanup applied beforehand, the four preset renders demonstrate pure tonal
and stylistic mastering variations on top of a clean, room-corrected mix:

- ..._original_unmastered.mp3 (or ..._baseline.mp3)
  320 kbps audio extraction of the room-corrected _final recording prior to
  applying genre/era mastering presets (included for A/B comparison).

- ..._ballad_studio.mp3 (-L / --ballad)
  Clean-to-heavy dynamic power ballad warmth with wide stereo hall reverb.

- ..._jp86_studio.mp3 (-j / --jp86)
  1986 Judas Priest neoclassical power-metal brightness & dual-lead shimmer.

- ..._ym1_studio.mp3 (-y / --ym1)
  1984 Yngwie Malmsteen "Rising Force" bell-like DOD 250 + Strat glassy clarity.

- ..._thunderforce_studio.mp3 (-4 / --thunderforce)
  1992 Sega Genesis "Thunder Force IV" M68K + YM2612 FM-synth shred grit.


3. INCLUDED MASTERING SCRIPTS (58 PRESETS)
------------------------------------------
NOTE ON RAW RECORDINGS:
- Single-Pass (Standard): These scripts do NOT require a pre-cleaned file.
  Every preset already includes its own high-pass rumble filter (75-105 Hz),
  boxy-midrange cleanup (240-360 Hz cut), compression, and peak limiter, so
  you can run any preset directly on a brand-new raw laptop-mic take.
- Two-Step Tip (Extra-Boomy / Echoey Rooms): If a future room recording is
  unusually boomy or echoey, run --boomy (-b) or --echoey (-e) first to
  create a clean baseline, then run your genre preset (-4, -y, -j, -L) on
  that cleaned output.
- Already-EQ'd Files: Use -p / --alreadypolished when you want a clean
  studio master without applying a second pass of room-mud EQ.

Three standalone command-line FFmpeg mastering & conversion scripts are included:

- studio_master.pl   (CC0 Public Domain Perl 5 — zero CPAN dependencies,
                      supports --batch folder mode and --norm -14 LUFS)
- studio_master.py   (Standalone Python 3 — zero external libraries,
                      supports --batch folder mode and --norm -14 LUFS)
- studio_master.sh   (Zero-dependency POSIX /bin/sh script for single files)


4. QUICK USAGE EXAMPLES
-----------------------
Show all 58 presets and options:
  ./studio_master.pl --help

Master a raw webcam MP4 -> 320 kbps MP3 (default --unpolished cleanup):
  ./studio_master.pl practice_raw.mp4 "Late Night Warbeast"

Master an already-EQ'd file without double-EQing (-p):
  ./studio_master.pl -p practice_final.mp4 "Clean Studio Master"

Render with Ballad (-L), JP86 (-j), Rising Force (-y), or Thunder Force (-4):
  ./studio_master.pl -L practice_final.mp4 "Ballad"
  ./studio_master.pl -j practice_final.mp4 "JP86"
  ./studio_master.pl -y practice_final.mp4 "Rising Force"
  ./studio_master.pl -4 practice_final.mp4 "Thunder Force IV"

Re-master an existing MP3 for Numark CDJ / club speakers (--cdj):
  ./studio_master.pl --cdj existing_track.mp3 "Club Master"

Batch-process a folder with uniform -14 LUFS volume leveling:
  ./studio_master.pl --batch ./Practice -y --norm --outdir ./Practice/masters


5. PUBLIC DOMAIN DEDICATION (CC0 1.0)
-------------------------------------
To the extent possible under law, all audio recordings, presets, and scripts
in this directory are dedicated to the public domain worldwide under CC0 1.0:
<http://creativecommons.org>

================================================================================
SESSION LOG: ROLAND BOUTIQUE JX-03 CATHEDRAL SYNTH ORGAN (NOV 27, 2026)
================================================================================
Rig & Wet/Dry Stereo Routing:
- Synth: Roland Boutique JX-03 + K-25m 25-key keyboard
- Effect: Custom 3-knob DIY reverb/delay pedal (top output -> right amp,
  side output -> left amp for wet/dry stereo split)
- Amps: Dual Blackstar Fly 3 (Union Jack stereo setup)
- Mastering & Video: studio_master.sh (default studio preset, -p / --alreadypolished)
  + render_showcase.sh (doom & silver waveform themes, VA-API hardware encode)

Published Audio & Video (CC0 Public Domain):
- Part I Audio: roland_jx03_one_dark_cathedral_swells_studio_mastered.mp3
- Part II Audio: roland_jx03_two_neoclassical_organ_lines_studio_mastered.mp3

