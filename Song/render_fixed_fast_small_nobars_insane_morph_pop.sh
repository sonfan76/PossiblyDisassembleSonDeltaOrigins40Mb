#!/usr/bin/env bash

shopt -s nullglob

COUNT=0

for f in *.mp3; do
  if [[ "$f" == *silence* ]]; then
    continue
  fi

  out="${f%.*}.mp4"

  # Skip if output file already exists and is larger than 1MB
  if [[ -f "$out" && $(stat -c%s "$out") -gt 1048576 ]]; then
    echo "Already done, skipping: $out"
    continue
  fi

  # Get exact audio duration in seconds so the background matches the full song
  DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f")

  # Default: Red foreground on Black background, static background
  BG="0x000000"
  FG="0xff0000"
  HUE_SHIFT="0"
  LIGHT_BG=0

  # Rule 1: Starts with a single number followed by _ (Blue on Black)
  if [[ "$f" =~ ^[0-9]_ ]]; then
    BG="0x000000"
    FG="0x0066ff"
  fi

  # Rule 2: Starts with xx7 (Dark Red background, Lighter Red foreground)
  if [[ "$f" == xx7* ]]; then
    BG="0x330000"
    FG="0xff4444"
  fi

  # Rule 3: Contains _YM_ (Heavenly warm ivory-yellow background, rich golden oscilloscope)
  if [[ "$f" == *_YM_* ]]; then
    BG="0xfffbe6"
    FG="0xe6a800"
    HUE_SHIFT="sin(t*0.2)*12"
    LIGHT_BG=1
  fi

  # Rule 4: Contains _DK_ (Dark Green shifting background, Bright Green foreground)
  if [[ "$f" == *_DK_* ]]; then
    BG="0x00260d"
    FG="0x00ff33"
    HUE_SHIFT="sin(t*0.3)*25"
  fi

  # Rule 5: Contains _JP_ (Dark Orange/Black shifting background, Blue-Purple foreground)
  if [[ "$f" == *_JP_* ]]; then
    BG="0x1f0a00"
    FG="0x7a29ff"
    HUE_SHIFT="sin(t*0.25)*35"
  fi

  # Rule 6: Contains _IM_ (1970s Cream Parchment if 17, Aged Scroll Parchment if Break_the_Vault, else Red on Black)
  if [[ "$f" == *_IM_* ]]; then
    if [[ "$f" == *17* ]]; then
      BG="0xf5ebd6"
      FG="0xcc0000"
      HUE_SHIFT="sin(t*0.15)*10"
      LIGHT_BG=1
    elif [[ "$f" == *Break_the_Vault* ]]; then
      BG="0xe8dcc2"
      FG="0x8a0000"
      HUE_SHIFT="sin(t*0.14)*12"
      LIGHT_BG=1
    else
      BG="0x000000"
      FG="0xff0000"
    fi
  fi

  # Rule 7: Contains _MJ_ (Midnight Black background, Glittering Silver-White foreground)
  if [[ "$f" == *_MJ_* ]]; then
    BG="0x000000"
    FG="0xf0f4ff"
  fi

  # Rule 8: Contains M68K (Default 16-bit Amiga Workbench Deep Blue & Retro Orange)
  if [[ "$f" == *M68K* ]]; then
    BG="0x001a4d"
    FG="0xff7700"
  fi

  # Rule 9: Contains M68K AND Blood_Red_Skies (Smoldering Crimson Sky & Blazing Scarlet)
  if [[ "$f" == *M68K* && "$f" == *Blood_Red_Skies* ]]; then
    BG="0x2b0000"
    FG="0xff1a1a"
    HUE_SHIFT="sin(t*0.2)*15"
  fi

  # Rule 10: Contains NuMtl (Late-90s Industrial Charcoal & Safety Amber)
  if [[ "$f" == *NuMtl* ]]; then
    BG="0x141414"
    FG="0xffaa00"
  fi

  # Rule 11: Contains DrgnFrcMtl (DragonForce Hyper-Speed Indigo & Electric Cyan)
  if [[ "$f" == *DrgnFrcMtl* ]]; then
    BG="0x0b0026"
    FG="0x00ffff"
    HUE_SHIFT="sin(t*0.5)*45"
  fi

  # Rule 12: Starts with ASM_ (Classic Assembly Terminal Phosphor)
  if [[ "$f" == ASM_* ]]; then
    BG="0x020a02"
    FG="0x33ff77"
  fi

  # Rule 13: Contains _AX_ (Tupac West Coast Sunset Gold on Deep Obsidian)
  if [[ "$f" == *_AX_* ]]; then
    BG="0x0a0400"
    FG="0xffb300"
    HUE_SHIFT="sin(t*0.2)*20"
  fi
  
  # Rule 14: Contains HP_FOR_COPYLEFT without genre tag (e.g. B14 short interlude - Electric Blue Patrol)
  if [[ "$f" == *HP_FOR_COPYLEFT* && "$f" != *NuMtl* && "$f" != *DrgnFrcMtl* ]]; then
    BG="0x040d26"
    FG="0x1eb8ff"
    HUE_SHIFT="sin(t*0.28)*25"
  fi


  # Convert hex FG (0xRRGGBB) to RGB decimals (0-255) for avectorscope
  R=$((16#${FG:2:2}))
  G=$((16#${FG:4:2}))
  B=$((16#${FG:6:2}))

  # Convert RGB decimals (0-255) to 0.0-1.0 floats for showcqt cscheme
  RF=$(awk "BEGIN {printf \"%.2f\", $R/255}")
  GF=$(awk "BEGIN {printf \"%.2f\", $G/255}")
  BF=$(awk "BEGIN {printf \"%.2f\", $B/255}")

  # Generate unique irregular wave frequencies per track (switches every ~12-40s unpredictably)
  F1=$(awk "BEGIN {printf \"%.3f\", 0.09 + ($RANDOM % 10) * 0.011}")
  F2=$(awk "BEGIN {printf \"%.3f\", 0.05 + ($RANDOM % 10) * 0.007}")
  PHASE=$(awk "BEGIN {printf \"%.2f\", ($RANDOM % 628) / 100}")
  SWITCH_EXPR="gt(sin(t*${F1}+${PHASE})+cos(t*${F2}),0)"

  # Light backgrounds alternate between 2 morph combos; dark backgrounds alternate between 4 morph combos
  if [[ $LIGHT_BG -eq 1 ]]; then
    COMBO=$((COUNT % 2))
  else
    COMBO=$((COUNT % 4))
  fi
  COUNT=$((COUNT + 1))

  case $COMBO in
    0)
      VIS_NAME="CRT Bloom Wave <-> Double-Helix Stereo"
      VIS_A="[a1]showwaves=s=854x480:mode=cline:colors=${FG}:rate=15,split[w1][w2];[w2]gblur=sigma=6[glow];[w1][glow]blend=all_mode=addition:all_opacity=0.7[va]"
      VIS_B="[a2]showwaves=s=854x480:mode=cline:colors=${FG}:rate=15:split_channels=1[vb]"
      ;;
    1)
      VIS_NAME="Sharp Point Wave <-> Hypnotic Spinning Wave"
      VIS_A="[a1]showwaves=s=854x480:mode=p2p:colors=${FG}:rate=15[va]"
      VIS_B="[a2]showwaves=s=854x480:mode=line:colors=${FG}:rate=15,rotate=t*0.35:c=none:ow=854:oh=480[vb]"
      ;;
    2)
      VIS_NAME="Double-Helix Stereo <-> Quad-Kaleidoscope Tunnel"
      VIS_A="[a1]showwaves=s=854x480:mode=cline:colors=${FG}:rate=15:split_channels=1[va]"
      VIS_B="[a2]avectorscope=s=427x240:r=15:mode=lissajous:draw=line:rc=${R}:gc=${G}:bc=${B}:rf=40:gf=40:bf=40,split=4[q1][q2][q3][q4];[q2]hflip[q2f];[q3]vflip[q3f];[q4]hflip,vflip[q4f];[q1][q2f]hstack[top];[q3f][q4f]hstack[bot];[top][bot]vstack[vb]"
      ;;
    3)
      VIS_NAME="Spinning Polar Vortex <-> Custom-Colored Pitch Ribbon"
      VIS_A="[a1]avectorscope=s=854x480:r=15:mode=polar:draw=line:rc=${R}:gc=${G}:bc=${B}:rf=35:gf=35:bf=35,rotate=t*0.4:c=black[va]"
      VIS_B="[a2]showcqt=s=854x480:r=15:sono_h=0:bar_g=2:bar_v=12:fontcolor=none:axis=0:cscheme=${RF}|${GF}|${BF}|${RF}|${GF}|${BF}[vb]"
      ;;
  esac

  echo "[$VIS_NAME] Rendering (${DUR}s): $f -> $out [BG: $BG | FG: $FG]"

  ffmpeg -hide_banner -loglevel error -stats -y \
    -f lavfi -t "$DUR" -i "color=c=${BG}:s=854x480:r=15" \
    -i "$f" \
    -filter_complex "[1:a]asplit=2[a1][a2];[0:v]hue=h='${HUE_SHIFT}'[bg];${VIS_A};${VIS_B};[bg][va]overlay=format=auto:enable='${SWITCH_EXPR}'[v1];[v1][vb]overlay=format=auto:enable='not(${SWITCH_EXPR})'[v2];[v2]rgbashift=rh=-2:bh=2,drawgrid=w=0:h=3:t=1:c=black@0.25,vignette=PI/4[v]" \
    -map "[v]" -map 1:a \
    -c:v libx264 -preset faster -crf 26 \
    -c:a aac -b:a 192k -pix_fmt yuv420p \
    "$out"
done

echo "All tracks finished!"
