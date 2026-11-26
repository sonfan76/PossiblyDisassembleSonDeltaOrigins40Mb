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


2. INCLUDED AUDIO MASTERS (4 MP3 RENDER VARIATIONS)
---------------------------------------------------
All four 320 kbps / 44.1 kHz MP3 masters were generated from the November 26,
2026 practice session using different presets in the mastering suite:

- ..._unpolished_studio.mp3 (or ..._alreadypolished_studio.mp3)
  Clean studio master preserving the raw DOD 250 + scalloped neck dynamics,
  tight low-end control, stereo widening, and smooth fade-in/fade-out.

- ..._jp86_studio.mp3 (-j / --jp86)
  1986 Judas Priest neoclassical power-metal brightness (3.8 kHz & 6.5 kHz
  harmonic lift) with wide dual-lead stereo shimmer.

- ..._ym1_studio.mp3 (-y / --ym1)
  1984 Yngwie Malmsteen "Rising Force" bell-like DOD 250 + Strat glassy clarity
  (105 Hz tight low cut, 4.2 kHz & 7.0 kHz upper-mid snap for bare-handed runs).

- ..._thunderforce_studio.mp3 (-4 / --thunderforce)
  1992 Sega Genesis / Mega Drive "Thunder Force IV (Lightening Force)" M68K +
  YM2612 FM-synth shred tone with 12-bit DAC quantization crunch and tanh clip.


3. INCLUDED MASTERING SCRIPTS (58 PRESETS)
------------------------------------------
Three standalone command-line FFmpeg mastering & conversion scripts are included
in this directory. Every script supports any-to-any conversion (.mp4, .mkv,
.wav, .flac, .mp3 -> .mp3, .wav, .flac, or stream-copied .mp4), start/end
trimming, custom ID3 tags, and 58 room, retro console, metal, and DJ presets:

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

Render with Thunder Force IV (-4) or Rising Force (-y) preset:
  ./studio_master.pl -4 practice_final.mp4 "Thunder Force IV"
  ./studio_master.pl -y practice_final.mp4 "Rising Force"

Re-master an existing MP3 for Numark CDJ / club speakers (--cdj):
  ./studio_master.pl --cdj existing_track.mp3 "Club Master"

Batch-process a folder with uniform -14 LUFS volume leveling:
  ./studio_master.pl --batch ./Practice -y --norm --outdir ./Practice/masters


5. PUBLIC DOMAIN DEDICATION (CC0 1.0)
-------------------------------------
To the extent possible under law, all audio recordings, presets, and scripts
in this directory are dedicated to the public domain worldwide under CC0 1.0:
<http://creativecommons.org>
