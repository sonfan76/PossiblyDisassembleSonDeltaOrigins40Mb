#!/bin/sh
#RENDER_SHOWCASE
#  Written in 2026
#
#To the extent possible under law, the author(s) have dedicated all copyright
#and related and neighboring rights to this software to the public domain
#worldwide. This software is distributed without any warranty.
#
#You should have received a copy of the CC0 Public Domain Dedication along
#with this software. If not, see
#<http://creativecommons.org>.

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ -z "$1" ] || [ -z "$2" ]; then
  cat << 'HELP'
Usage: ./render_showcase.sh <video.mp4> <mastered_audio.mp3> ["Banner Title"] [theme|hex_colors]

CC0 1.0 Public Domain — Combine a guitar practice video with a studio-mastered audio track, adding:
  - Live edge-to-edge audio waveform overlay along the bottom edge
  - Warm stage contrast/saturation polish + subtle lens vignette
  - Top-left title banner overlay (escapes colons/apostrophes safely)
  - Automatic Intel/AMD VA-API GPU encoding (/dev/dri/renderD128) with CPU fallback

Arguments:
  <video.mp4>               Source video file (auto-detects width via ffprobe)
  <mastered_audio.mp3>      Mastered audio file (.mp3, .wav, .flac)
  ["Banner Title"]          Optional top-left title (defaults to audio filename)
  [theme|hex_colors]        Optional waveform color theme or FFmpeg hex pair:
                              silver  - Crisp translucent white/slate (default, blends with any room)
                              amber   - Rising Force gold/crimson
                              genesis - Thunder Force IV M68K cyan/blue
                              priest  - JP86 steel-silver/electric-blue
                              doom    - Sabbath/Kyuss deep violet/magenta
                              emerald - Matrix/M68K phosphor green/lime

Examples:
  # 1. Default Rising Force amber/crimson showcase:
  ./render_showcase.sh raw_jam.mp4 master_ym1.mp3 "DOOM & NEOCLASSICAL — RISING FORCE"

  # 2. Sega Genesis Thunder Force IV neon cyan/blue waveform:
  ./render_showcase.sh raw_jam.mp4 master_thunderforce.mp3 "THUNDER FORCE IV SHRED" genesis

  # 3. Custom FFmpeg hex colors:
  ./render_showcase.sh raw_jam.mp4 master_jp86.mp3 "JP86 TWIN LEAD" "0xffffff@0.85|0x3399ff@0.85"
HELP
  [ "$1" = "-h" ] || [ "$1" = "--help" ] && exit 0 || exit 1
fi

VID="$1"
AUD="$2"
BASE=$(basename "${AUD%.*}")
RAW_TITLE="${3:-$BASE}"
TITLE=$(printf '%s' "$RAW_TITLE" | sed "s/'/\\\\'/g; s/:/\\\\:/g")
THEME="${4:-silver}"

case "$THEME" in
  silver)  COLORS="0xffffff@0.75|0x8899aa@0.65" ;;
  amber)   COLORS="0xffaa00@0.85|0xff3300@0.85" ;;
  genesis) COLORS="0x00ffff@0.85|0x0055ff@0.85" ;;
  priest)  COLORS="0xddeeff@0.85|0x2277ff@0.85" ;;
  doom)    COLORS="0xbb44ff@0.85|0x5500aa@0.85" ;;
  emerald) COLORS="0x00ff66@0.85|0x008822@0.85" ;;
  *)       COLORS="$THEME" ;;
esac

OUT="${BASE}_showcase.mp4"
WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$VID")
[ -z "$WIDTH" ] && WIDTH=1280

if [ -e /dev/dri/renderD128 ]; then
  ffmpeg -y -vaapi_device /dev/dri/renderD128 \
    -i "$VID" -i "$AUD" \
    -filter_complex "\
      [0:v]eq=contrast=1.10:brightness=0.02:saturation=1.18,vignette=angle=PI/5[base]; \
      [1:a]showwaves=s=${WIDTH}x90:mode=cline:colors=${COLORS}:scale=sqrt[wave]; \
      [base][wave]overlay=0:H-90:shortest=1, \
      drawtext=text='${TITLE}':fontcolor=white@0.92:fontsize=22:x=24:y=24:shadowcolor=black@0.85:shadowx=2:shadowy=2, \
      format=nv12,hwupload[vout]" \
    -map "[vout]" -map 1:a \
    -c:v h264_vaapi -qp 20 \
    -c:a aac -b:a 256k \
    "$OUT"
else
  ffmpeg -y \
    -i "$VID" -i "$AUD" \
    -filter_complex "\
      [0:v]eq=contrast=1.10:brightness=0.02:saturation=1.18,vignette=angle=PI/5[base]; \
      [1:a]showwaves=s=${WIDTH}x90:mode=cline:colors=${COLORS}:scale=sqrt[wave]; \
      [base][wave]overlay=0:H-90:shortest=1, \
      drawtext=text='${TITLE}':fontcolor=white@0.92:fontsize=22:x=24:y=24:shadowcolor=black@0.85:shadowx=2:shadowy=2[vout]" \
    -map "[vout]" -map 1:a \
    -c:v libx264 -preset veryfast -crf 20 \
    -c:a aac -b:a 256k \
    "$OUT"
fi

echo "Done [$THEME] -> $OUT"
