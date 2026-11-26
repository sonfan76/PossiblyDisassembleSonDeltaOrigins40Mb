#!/bin/sh
#MAKE_SHORT
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
Usage: ./make_short.sh <input_video.mp4> <start_time> [duration_sec] ["Hook Caption"]

CC0 1.0 Public Domain — Extract a highlight clip and render a 1080x1920 (9:16)
YouTube Short with blurred background fill, hook caption, and smooth audio fades.

Arguments:
  <input_video.mp4>     Source showcase or practice video
  <start_time>          Start timestamp (e.g., 00:01:55 or 115)
  [duration_sec]        Clip length in seconds (default: 35, max 59 for Shorts)
  ["Hook Caption"]      Optional top hook text (default: "Scalloped Fretboard (No Pick)")

Examples:
  ./make_short.sh practice_showcase.mp4 00:01:55 42 "Scalloped Fretboard (No Pick)"
HELP
  [ "$1" = "-h" ] || [ "$1" = "--help" ] && exit 0 || exit 1
fi

IN="$1"
START="$2"
DUR="${3:-35}"
RAW_HOOK="${4:-Scalloped Fretboard (No Pick)}"
HOOK=$(printf '%s' "$RAW_HOOK" | sed "s/'/\\\\'/g; s/:/\\\\:/g")
BASE=$(basename "${IN%.*}")
SAFE_START=$(printf '%s' "$START" | tr ':' '-')
OUT="${BASE}_short_${SAFE_START}.mp4"
FADEOUT=$((DUR - 2))
[ "$FADEOUT" -lt 1 ] && FADEOUT=1

if [ -e /dev/dri/renderD128 ]; then
  ffmpeg -y -vaapi_device /dev/dri/renderD128 \
    -ss "$START" -t "$DUR" -i "$IN" \
    -filter_complex "\
      [0:v]scale=180:320:force_original_aspect_ratio=increase,crop=180:320,boxblur=6:2,scale=1080:1920[bg]; \
      [0:v]scale=1080:-2[fg]; \
      [bg][fg]overlay=(W-w)/2:(H-h)/2, \
      drawtext=text='${HOOK}':fontcolor=white@0.95:fontsize=46:x=(w-text_w)/2:y=240:box=1:boxcolor=black@0.65:boxborderw=18, \
      format=nv12,hwupload[vout]" \
    -af "afade=t=in:st=0:d=0.3,afade=t=out:st=${FADEOUT}:d=2" \
    -map "[vout]" -map 0:a \
    -c:v h264_vaapi -qp 20 \
    -c:a aac -b:a 256k \
    "$OUT"
else
  ffmpeg -y \
    -ss "$START" -t "$DUR" -i "$IN" \
    -filter_complex "\
      [0:v]scale=180:320:force_original_aspect_ratio=increase,crop=180:320,boxblur=6:2,scale=1080:1920[bg]; \
      [0:v]scale=1080:-2[fg]; \
      [bg][fg]overlay=(W-w)/2:(H-h)/2, \
      drawtext=text='${HOOK}':fontcolor=white@0.95:fontsize=46:x=(w-text_w)/2:y=240:box=1:boxcolor=black@0.65:boxborderw=18[vout]" \
    -af "afade=t=in:st=0:d=0.3,afade=t=out:st=${FADEOUT}:d=2" \
    -map "[vout]" -map 0:a \
    -c:v libx264 -preset veryfast -crf 20 \
    -c:a aac -b:a 256k \
    "$OUT"
fi

echo "Done -> $OUT"
