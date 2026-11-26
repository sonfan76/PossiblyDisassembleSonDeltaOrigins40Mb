#!/bin/sh

PRESET="unpolished"
TRIM_START=""
TRIM_END=""
FORMAT="mp3"
ALBUM="Scalloped Warbeast Sessions (2026)"
ARTIST="Assembly LKE"

while [ $# -gt 0 ]; do
  case "$1" in
    --unpolished|--raw|-u) PRESET="unpolished"; shift ;;
    --alreadypolished|--already-polished|-p) PRESET="alreadypolished"; shift ;;
    --boomy|-b) PRESET="boomy"; shift ;;
    --echoey|-e) PRESET="echoey"; shift ;;
    --hall|-H) PRESET="hall"; shift ;;
    --doom|-d) PRESET="doom"; shift ;;
    --shred|-s) PRESET="shred"; shift ;;
    --vintage|-v) PRESET="vintage"; shift ;;
    --loud|-l) PRESET="loud"; shift ;;
    --direct|-D) PRESET="direct"; shift ;;
    --jp86|-j) PRESET="jp86"; shift ;;
    --jp86dark|-J) PRESET="jp86dark"; shift ;;
    --dio|-O) PRESET="dio"; shift ;;
    --ballad|-L) PRESET="ballad"; shift ;;
    --baroque|-B) PRESET="baroque"; shift ;;
    --mj|-m) PRESET="mj"; shift ;;
    --thriller|-T) PRESET="thriller"; shift ;;
    --vault|-V) PRESET="vault"; shift ;;
    --dk1|-k) PRESET="dk1"; shift ;;
    --dk2|-K) PRESET="dk2"; shift ;;
    --ym1|-y) PRESET="ym1"; shift ;;
    --ym2|-Y) PRESET="ym2"; shift ;;
    --priest|-P) PRESET="priest"; shift ;;
    --maiden|-M) PRESET="maiden"; shift ;;
    --freedom|-F) PRESET="freedom"; shift ;;
    --gfunk|-g) PRESET="gfunk"; shift ;;
    --boombap|-w) PRESET="boombap"; shift ;;
    --trap|-x) PRESET="trap"; shift ;;
    --dragon|-G) PRESET="dragon"; shift ;;
    --numetal|-N) PRESET="numetal"; shift ;;
    --skies|-S) PRESET="skies"; shift ;;
    --thrash|-R) PRESET="thrash"; shift ;;
    --jpopmetal|-A) PRESET="jpopmetal"; shift ;;
    --gallop|-C) PRESET="gallop"; shift ;;
    --jazzy|-z) PRESET="jazzy"; shift ;;
    --phonk|-W) PRESET="phonk"; shift ;;
    --westcoast|-Q) PRESET="westcoast"; shift ;;
    --golden|-Z) PRESET="golden"; shift ;;
    --amiga|-a) PRESET="amiga"; shift ;;
    --blackmore|-r) PRESET="blackmore"; shift ;;
    --sabbath|-I) PRESET="sabbath"; shift ;;
    --cockpit|-c) PRESET="cockpit"; shift ;;
    --cdj|-U) PRESET="cdj"; shift ;;
    --latenight|-n) PRESET="latenight"; shift ;;
    --thunderforce|-4) PRESET="thunderforce"; shift ;;
    --ym2612|-2) PRESET="ym2612"; shift ;;
    --genesis|-1) PRESET="genesis"; shift ;;
    --sonic|-3) PRESET="sonic"; shift ;;
    --model1|-0) PRESET="model1"; shift ;;
    --neogeo|-9) PRESET="neogeo"; shift ;;
    --snes|-7) PRESET="snes"; shift ;;
    --kyuss|-q) PRESET="kyuss"; shift ;;
    --synthwave|-o) PRESET="synthwave"; shift ;;
    --acoustic|-5) PRESET="acoustic"; shift ;;
    --jcm800|-8) PRESET="jcm800"; shift ;;
    --swedish|-E) PRESET="swedish"; shift ;;
    --clean|-f) PRESET="clean"; shift ;;
    --car|-i) PRESET="car"; shift ;;
    --start|--ss) TRIM_START="$2"; shift 2 ;;
    --trim|--end|-t) TRIM_END="$2"; shift 2 ;;
    --mp3) FORMAT="mp3"; shift ;;
    --video|--mp4) FORMAT="mp4"; shift ;;
    --wav) FORMAT="wav"; shift ;;
    --flac) FORMAT="flac"; shift ;;
    --album) ALBUM="$2"; shift 2 ;;
    --artist) ARTIST="$2"; shift 2 ;;
    --help|-h)
      cat << 'HELP'
Usage: studio_master.sh [OPTIONS] <input_file> [track_title]

Master, EQ, and convert any audio or video file (.mp4, .wav, .flac, .mp3, .mkv)
into a tagged 320 kbps MP3 (default), or .wav / .flac / stream-copied .mp4.
Default behavior: raw laptop-mic cleanup + studio master (--unpolished) to .mp3.

Output & Trimming Options:
  --mp3                     Output 320 kbps CBR MP3 at 44.1 kHz (default)
  --wav                     Output lossless 16-bit / 44.1 kHz WAV
  --flac                    Output lossless FLAC
  --video, --mp4            Keep original video stream untouched (-c:v copy)
  --start, --ss HH:MM:SS    Trim silence or warm-up from the beginning
  --trim, --end, -t TIME    Cut off cable unplugging/noise at timestamp
  --album "NAME"            Set ID3 album tag (default: Scalloped Warbeast Sessions (2026))
  --artist "NAME"           Set ID3 artist tag (default: Assembly LKE)
  -h, --help                Display this help text and exit

Room, Playback & Cleanup Presets:
  -u, --unpolished          Bedroom laptop-mic cleanup + studio master (default)
  -p, --alreadypolished     Master an already-EQ'd file (prevents double EQ)
  -b, --boomy               Small/carpeted room or close amps (heavy bass/mud cut)
  -e, --echoey              Bare/hard-walled room (tames slapback reflections)
  -l, --loud                High-volume/garage jam (tames mic overload harshness)
  -D, --direct              Direct CabDryVR line-in (adds room air, skips mic EQ)
  -U, --cdj                 Numark CDJ / PA club speaker sub-control & mid cut-through
  -i, --car                 Car stereo / small speaker bass harmonics & translation
  -n, --midnight            Low-volume late-night headphone contour & warm hall

16-Bit Retro Console & Arcade Presets (M68K Era):
  -4, --thunderforce        Thunder Force IV (Lightening Force) FM heavy-metal shred
  -2, --ym2612              Sega Genesis YM2612 FM synth lead + 11-bit DAC grit
  -1, --genesis             1991-93 Mega Drive action (Streets of Rage / Shinobi)
  -3, --sonic               Sonic 3 & Knuckles bouncy FM bass + bright PSG sparkle
  -0, --model1              1989 Genesis Model 1 (VA2/VA3) warm preamp saturation
  -9, --neogeo              SNK Neo Geo AES (M68K + YM2610) beefy arcade punch
  -7, --snes                Super Nintendo SPC700 Gaussian-filtered velvet & echo
  -a, --amiga               Commodore Amiga / M68K Paula 8-bit tracker grit & warmth

Metal, Rock & Pop Style Presets:
  -d, --doom                Extra sub-bass weight + scooped mids for heavy slow riffs
  -I, --sabbath             1970s Tony Iommi woolly low-mid doom fuzz & tape saturation
  -q, --kyuss               1992 Palm Desert stoner fuzz & bass-amp cabinet rumble
  -r, --blackmore           1970s Rainbow Rising woody midrange & dramatic room tail
  -8, --jcm800              1983 Marshall JCM800 British upper-mid hard-rock bark
  -s, --shred               Neoclassical clarity: tight lows + sharp finger articulation
  -v, --vintage             1980s analog cassette/tape warmth + soft saturation
  -o, --synthwave           1984 Outrun / John Carpenter analog chorus & stereo delay
  -c, --cockpit             1986 Top Gun / Sunset Strip glossy arena lead & wide chorus
  -H, --hall                Subtle studio hall reverb + wide stereo spread
  -f, --clean               Fingerstyle clean / jazz-fusion warm neck-pickup tone
  -5, --acoustic            Bright steel-string acoustic / unplugged body & air clarity
  -j, --jp86                80s JP neoclassical power-metal brightness & dual-lead shimmer
  -J, --jp86dark            Heavier, darker JP86 chug + neoclassical lead bite
  -O, --dio                 80s arena heavy-metal low-mid weight & punchy chug
  -L, --ballad              Clean-to-heavy dynamic power ballad warmth & stereo hall
  -B, --baroque             Cathedral chamber reverb + dramatic harmonic-minor clarity
  -m, --mj                  80s Bad-era funk-pop studio snap & sparkling finger attack
  -T, --thriller            1982 funk-rock punch + Lukather/EVH midrange bite
  -V, --vault               Classic NWOBHM / Maiden dual-lead midrange gallop & air
  -k, --dk1                 Heavy progressive wall of sound + crisp classical-break clarity
  -K, --dk2                 Tight modern high-gain metal razor & aggressive chug bite
  -y, --ym1                 1984 Rising Force bell-like DOD 250 + Strat glassy clarity
  -Y, --ym2                 Full-tilt symphonic neoclassical anthem + wide hall shimmer
  -P, --priest              1988 Blood Red Skies twin-guitar laser precision & bite
  -S, --skies               Dark synth-metal atmosphere + wide brooding lead sustain
  -R, --thrash              Aggressive thrash/power-metal palm-mute razor & snarl
  -E, --swedish             90s Gothenburg / HM-2 chainsaw melodeath midrange grind
  -M, --maiden              NWOBHM / Euro power-metal gallop + warm British midrange
  -C, --gallop              Driving Euro-power triplet gallop + harmonized arena punch
  -F, --freedom             High-speed JP melodic power-metal sparkle & fast transients
  -A, --jpopmetal           Anime-opening symphonic power-metal clean-to-shred sparkle
  -G, --dragon              DragonForce hyper-speed power-metal shimmer & clarity
  -N, --numetal             2000s drop-tuned groove punch + syncopated palm-mute slap

Hip-Hop & DJ / CDJ Presets:
  -g, --gfunk               90s West Coast G-Funk sub-bass + silky singing lead shimmer
  -Q, --westcoast           Bouncy 90s M-Style synth-funk snap + wide stereo whistle
  -w, --boombap             90s East Coast MPC vinyl-sampler warmth & gritty midrange
  -z, --jazzy               Warm Rhodes / soul-chopped boom-bap velvet low-mids
  -Z, --golden              Crisp 90s golden-era lyrical boom-bap midrange punch
  -W, --phonk               Dark underground lo-fi sub-bass rumble + gritty bite
  -x, --trap                Modern 808 sub-weight + hyper-crisp finger-pluck sparkle

Examples:
  # DEFAULT (MP4 -> MP3, raw laptop-mic cleanup + studio master):
  ./studio_master.sh practice_raw.mp4 "Late Night Warbeast"

  # Already-polished MP4 -> studio MP3 (no double EQ):
  ./studio_master.sh -p practice_final.mp4 "Doom & Neoclassical"

  # MP3 -> MP3 (re-master an existing MP3 for CDJ / club speakers, or -p if already EQ'd):
  ./studio_master.sh --cdj existing_track.mp3 "Club Master"
  ./studio_master.sh -p -4 existing_polished.mp3 "Thunder Force Remix"

  # WAV -> MP3 (lossless recording -> 320 kbps studio MP3):
  ./studio_master.sh -d pedalboard_take.wav "Doom Riff"

  # WAV -> WAV (lossless recording -> lossless 16-bit/44.1kHz master WAV):
  ./studio_master.sh --wav -I pedalboard_take.wav "Sabbath Lossless Master"

  # MP4 -> MP4 (polished YouTube video, copies video stream untouched in ~2 sec):
  ./studio_master.sh --video -y raw_jam.mp4

  # Trimming start & end (cuts warm-up & cable unplugging noise):
  ./studio_master.sh -4 --start 00:00:05 --trim 00:05:52 raw_jam.mp4 "Clean Take"
HELP
      exit 0
      ;;
    -*) echo "Unknown option: $1 (try --help)"; exit 1 ;;
    *) break ;;
  esac
done
if [ -z "$1" ]; then
  echo "Usage: ./studio_master.sh [OPTIONS] <input_file> [track_title]"
  echo "Run ./studio_master.sh --help for all presets and examples."
  exit 1
fi

IN="$1"
BASE=$(basename "${IN%.*}")
TITLE="${2:-$BASE}"
OUT="${BASE}_${PRESET}_studio.${FORMAT}"
START_ARG=""
[ -n "$TRIM_START" ] && START_ARG="-ss $TRIM_START"

if [ -n "$TRIM_END" ]; then
  DUR=$(echo "$TRIM_END" | awk -F: '{ if (NF==3) print ($1*3600)+($2*60)+$3; else if (NF==2) print ($1*60)+$2; else print $1 }')
  TRIM_ARG="-to $TRIM_END"
else
  DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$IN" | cut -d. -f1)
  TRIM_ARG=""
fi

if [ -n "$TRIM_START" ]; then
  SDUR=$(echo "$TRIM_START" | awk -F: '{ if (NF==3) print ($1*3600)+($2*60)+$3; else if (NF==2) print ($1*60)+$2; else print $1 }')
  DUR=$((DUR - SDUR))
fi

FADEOUT=$((DUR - 5))
[ "$FADEOUT" -lt 1 ] && FADEOUT=1

case "$PRESET" in
  unpolished) AF="highpass=f=75,lowpass=f=12000,equalizer=f=280:t=q:w=1.5:g=-3.0,equalizer=f=110:t=q:w=1.2:g=2.0,equalizer=f=2400:t=q:w=1.2:g=2.0,equalizer=f=4200:t=q:w=1.4:g=1.5,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3:attack=12:release=110:makeup=3.0,alimiter=limit=0.95" ;;
  alreadypolished) AF="stereotools=mlev=1.0:slev=1.22,equalizer=f=110:t=q:w=1.2:g=2.0,equalizer=f=4200:t=q:w=1.4:g=1.8,acompressor=threshold=-14dB:ratio=2.5:attack=15:release=120:makeup=2.5,alimiter=limit=0.95" ;;
  boomy) AF="highpass=f=95,lowpass=f=11500,equalizer=f=160:t=q:w=1.4:g=-4.5,equalizer=f=320:t=q:w=1.5:g=-4.0,equalizer=f=2600:t=q:w=1.2:g=2.5,equalizer=f=4500:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-16dB:ratio=3:attack=10:release=100:makeup=3.0,alimiter=limit=0.95" ;;
  echoey) AF="highpass=f=85,lowpass=f=10500,equalizer=f=450:t=q:w=1.8:g=-4.0,equalizer=f=1200:t=q:w=1.6:g=-2.5,equalizer=f=3000:t=q:w=1.3:g=2.0,acompressor=threshold=-15dB:ratio=3.5:attack=8:release=80:makeup=3.0,alimiter=limit=0.95" ;;
  hall) AF="highpass=f=75,lowpass=f=12500,equalizer=f=280:t=q:w=1.5:g=-3.0,equalizer=f=110:t=q:w=1.2:g=2.0,equalizer=f=4200:t=q:w=1.4:g=2.0,aecho=0.8:0.88:45|65:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=2.5:attack=15:release=120:makeup=2.5,alimiter=limit=0.95" ;;
  ym2612) AF="highpass=f=110,lowpass=f=11500,equalizer=f=1800:t=q:w=1.3:g=2.8,equalizer=f=4200:t=q:w=1.4:g=2.4,acrusher=bits=11:mode=log:samples=2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.2:attack=8:release=90:makeup=3.0,alimiter=limit=0.95" ;;
  genesis) AF="highpass=f=80,lowpass=f=11000,equalizer=f=90:t=q:w=1.2:g=3.0,equalizer=f=220:t=q:w=1.4:g=2.0,equalizer=f=3000:t=q:w=1.3:g=2.2,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.2:attack=10:release=100:makeup=3.0,alimiter=limit=0.95" ;;
  thunderforce) AF="highpass=f=95,lowpass=f=12000,equalizer=f=320:t=q:w=1.6:g=-4.0,equalizer=f=3400:t=q:w=1.3:g=3.2,equalizer=f=6200:t=q:w=1.4:g=2.5,asoftclip=type=tanh,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-17dB:ratio=3.8:attack=6:release=80:makeup=3.2,alimiter=limit=0.94" ;;
  sonic) AF="highpass=f=75,lowpass=f=12500,equalizer=f=80:t=q:w=1.2:g=3.2,equalizer=f=280:t=q:w=1.5:g=-3.0,equalizer=f=5500:t=q:w=1.4:g=2.8,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-16dB:ratio=3.5:attack=6:release=85:makeup=3.0,alimiter=limit=0.95" ;;
  model1) AF="highpass=f=70,lowpass=f=9500,equalizer=f=140:t=q:w=1.2:g=3.2,equalizer=f=480:t=q:w=1.4:g=2.2,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-15dB:ratio=2.8:attack=14:release=120:makeup=2.8,alimiter=limit=0.95" ;;
  neogeo) AF="highpass=f=75,lowpass=f=11500,equalizer=f=115:t=q:w=1.2:g=3.2,equalizer=f=500:t=q:w=1.4:g=2.2,equalizer=f=3600:t=q:w=1.3:g=2.6,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.4:attack=8:release=95:makeup=3.0,alimiter=limit=0.95" ;;
  snes) AF="highpass=f=70,lowpass=f=6500,equalizer=f=180:t=q:w=1.3:g=3.0,equalizer=f=900:t=q:w=1.5:g=1.8,aecho=0.8:0.88:42|64:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=2.6:attack=16:release=130:makeup=2.8,alimiter=limit=0.95" ;;
  amiga) AF="highpass=f=80,lowpass=f=7200,equalizer=f=130:t=q:w=1.3:g=3.2,equalizer=f=950:t=q:w=1.4:g=2.4,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.32,acompressor=threshold=-16dB:ratio=3.2:attack=8:release=90:makeup=3.0,alimiter=limit=0.95" ;;
  doom) AF="highpass=f=60,lowpass=f=11000,equalizer=f=85:t=q:w=1.1:g=3.5,equalizer=f=300:t=q:w=1.5:g=-3.5,equalizer=f=2200:t=q:w=1.2:g=2.0,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=3:attack=15:release=130:makeup=3.0,alimiter=limit=0.95" ;;
  sabbath) AF="highpass=f=65,lowpass=f=9000,equalizer=f=140:t=q:w=1.2:g=3.2,equalizer=f=650:t=q:w=1.4:g=2.6,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-15dB:ratio=2.8:attack=18:release=135:makeup=2.8,alimiter=limit=0.95" ;;
  kyuss) AF="highpass=f=55,lowpass=f=8800,equalizer=f=65:t=q:w=1.2:g=3.8,equalizer=f=160:t=q:w=1.3:g=2.8,equalizer=f=550:t=q:w=1.4:g=2.2,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.0:attack=18:release=140:makeup=3.0,alimiter=limit=0.95" ;;
  blackmore) AF="highpass=f=75,lowpass=f=10000,equalizer=f=650:t=q:w=1.4:g=2.6,equalizer=f=1800:t=q:w=1.3:g=2.2,aecho=0.8:0.89:38|58:0.15|0.11,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-14dB:ratio=2.5:attack=16:release=125:makeup=2.6,alimiter=limit=0.95" ;;
  jcm800) AF="highpass=f=90,lowpass=f=13000,equalizer=f=280:t=q:w=1.6:g=-3.2,equalizer=f=1400:t=q:w=1.3:g=2.6,equalizer=f=2800:t=q:w=1.3:g=2.8,equalizer=f=5000:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.2:attack=10:release=100:makeup=2.8,alimiter=limit=0.95" ;;
  shred) AF="highpass=f=100,lowpass=f=13000,equalizer=f=350:t=q:w=1.6:g=-4.0,equalizer=f=3200:t=q:w=1.3:g=3.0,equalizer=f=5500:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-16dB:ratio=3.5:attack=6:release=75:makeup=3.0,alimiter=limit=0.95" ;;
  vintage) AF="highpass=f=70,lowpass=f=8500,equalizer=f=140:t=q:w=1.2:g=2.5,equalizer=f=400:t=q:w=1.4:g=1.8,equalizer=f=2800:t=q:w=1.5:g=-1.5,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.15,acompressor=threshold=-15dB:ratio=2.5:attack=20:release=140:makeup=2.5,alimiter=limit=0.95" ;;
  synthwave) AF="highpass=f=75,lowpass=f=14000,equalizer=f=300:t=q:w=1.6:g=-3.6,equalizer=f=5500:t=q:w=1.3:g=2.8,equalizer=f=8500:t=q:w=1.4:g=2.4,aecho=0.8:0.88:45|70:0.18|0.14,stereotools=mlev=1.0:slev=1.32,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=110:makeup=2.8,alimiter=limit=0.95" ;;
  cockpit) AF="highpass=f=90,lowpass=f=14500,equalizer=f=300:t=q:w=1.6:g=-3.8,equalizer=f=5000:t=q:w=1.3:g=3.0,equalizer=f=8000:t=q:w=1.4:g=2.5,aecho=0.8:0.88:44|66:0.16|0.12,stereotools=mlev=1.0:slev=1.32,acompressor=threshold=-15dB:ratio=2.8:attack=10:release=100:makeup=2.8,alimiter=limit=0.95" ;;
  loud) AF="highpass=f=110,lowpass=f=10000,equalizer=f=250:t=q:w=1.5:g=-3.5,equalizer=f=3500:t=q:w=1.4:g=-3.0,acompressor=threshold=-20dB:ratio=4:attack=5:release=90:makeup=3.5,alimiter=limit=0.92" ;;
  direct) AF="highpass=f=65,equalizer=f=120:t=q:w=1.2:g=1.5,equalizer=f=3800:t=q:w=1.4:g=1.5,aecho=0.8:0.9:28|42:0.12|0.09,stereotools=mlev=1.0:slev=1.18,acompressor=threshold=-14dB:ratio=2.5:attack=15:release=120:makeup=2.5,alimiter=limit=0.95" ;;
  clean) AF="highpass=f=70,lowpass=f=12500,equalizer=f=220:t=q:w=1.3:g=2.4,equalizer=f=3800:t=q:w=1.5:g=-1.8,aecho=0.8:0.9:35|50:0.12|0.08,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-14dB:ratio=2.2:attack=20:release=140:makeup=2.4,alimiter=limit=0.95" ;;
  acoustic) AF="highpass=f=85,lowpass=f=14500,equalizer=f=220:t=q:w=1.5:g=-3.0,equalizer=f=420:t=q:w=1.5:g=-2.5,equalizer=f=4500:t=q:w=1.3:g=2.6,equalizer=f=8000:t=q:w=1.4:g=2.4,aecho=0.8:0.9:30|45:0.12|0.08,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-15dB:ratio=2.5:attack=14:release=120:makeup=2.6,alimiter=limit=0.95" ;;
  car) AF="highpass=f=75,lowpass=f=12500,equalizer=f=130:t=q:w=1.2:g=3.0,equalizer=f=240:t=q:w=1.4:g=2.0,equalizer=f=3200:t=q:w=1.3:g=2.4,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=3.8:attack=8:release=95:makeup=3.2,alimiter=limit=0.94" ;;
  midnight) AF="highpass=f=65,lowpass=f=10500,equalizer=f=95:t=q:w=1.2:g=2.8,equalizer=f=3500:t=q:w=1.5:g=-2.5,aecho=0.8:0.88:48|72:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=2.5:attack=18:release=135:makeup=2.6,alimiter=limit=0.95" ;;
  cdj) AF="highpass=f=45,lowpass=f=14500,equalizer=f=70:t=q:w=1.2:g=2.5,equalizer=f=250:t=q:w=1.6:g=-3.8,equalizer=f=2800:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.5:attack=8:release=90:makeup=3.0,alimiter=limit=0.96" ;;
  jp86) AF="highpass=f=95,lowpass=f=13500,equalizer=f=260:t=q:w=1.6:g=-3.5,equalizer=f=3800:t=q:w=1.3:g=2.8,equalizer=f=6500:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-15dB:ratio=3:attack=8:release=90:makeup=2.8,alimiter=limit=0.95" ;;
  jp86dark) AF="highpass=f=75,lowpass=f=13000,equalizer=f=80:t=q:w=1.2:g=2.8,equalizer=f=600:t=q:w=1.4:g=1.8,equalizer=f=4200:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=3:attack=10:release=100:makeup=2.8,alimiter=limit=0.95" ;;
  dio) AF="highpass=f=70,lowpass=f=9500,equalizer=f=130:t=q:w=1.2:g=3.0,equalizer=f=550:t=q:w=1.4:g=2.0,equalizer=f=2800:t=q:w=1.3:g=1.5,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-15dB:ratio=2.8:attack=18:release=135:makeup=2.8,alimiter=limit=0.95" ;;
  ballad) AF="highpass=f=75,lowpass=f=12500,equalizer=f=160:t=q:w=1.3:g=2.4,equalizer=f=320:t=q:w=1.5:g=-2.8,equalizer=f=3200:t=q:w=1.3:g=2.0,aecho=0.8:0.88:48|72:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-14dB:ratio=2.4:attack=22:release=145:makeup=2.5,alimiter=limit=0.95" ;;
  baroque) AF="highpass=f=80,lowpass=f=12500,equalizer=f=300:t=q:w=1.5:g=-3.0,equalizer=f=2800:t=q:w=1.3:g=2.5,aecho=0.8:0.88:55|85:0.22|0.16,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-15dB:ratio=2.5:attack=14:release=120:makeup=2.5,alimiter=limit=0.95" ;;
  mj) AF="highpass=f=90,lowpass=f=14000,equalizer=f=300:t=q:w=1.6:g=-3.8,equalizer=f=4800:t=q:w=1.3:g=3.0,equalizer=f=8000:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.5:attack=5:release=70:makeup=3.0,alimiter=limit=0.95" ;;
  thriller) AF="highpass=f=85,lowpass=f=13500,equalizer=f=100:t=q:w=1.2:g=2.2,equalizer=f=1400:t=q:w=1.3:g=2.4,equalizer=f=3200:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.2:attack=7:release=85:makeup=2.8,alimiter=limit=0.95" ;;
  vault) AF="highpass=f=85,lowpass=f=12500,equalizer=f=750:t=q:w=1.4:g=2.4,equalizer=f=2200:t=q:w=1.3:g=2.6,aecho=0.8:0.9:35|52:0.14|0.10,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=110:makeup=2.8,alimiter=limit=0.95" ;;
  dk1) AF="highpass=f=65,lowpass=f=13000,equalizer=f=75:t=q:w=1.2:g=3.2,equalizer=f=250:t=q:w=1.6:g=-4.0,equalizer=f=3600:t=q:w=1.3:g=2.6,equalizer=f=6000:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-16dB:ratio=3.2:attack=10:release=105:makeup=3.0,alimiter=limit=0.95" ;;
  dk2) AF="highpass=f=85,lowpass=f=12500,equalizer=f=280:t=q:w=1.6:g=-4.2,equalizer=f=1800:t=q:w=1.3:g=2.8,equalizer=f=4200:t=q:w=1.3:g=2.5,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-18dB:ratio=4.0:attack=6:release=80:makeup=3.2,alimiter=limit=0.94" ;;
  ym1) AF="highpass=f=105,lowpass=f=13500,equalizer=f=320:t=q:w=1.6:g=-4.2,equalizer=f=4200:t=q:w=1.3:g=3.2,equalizer=f=7000:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-15dB:ratio=3.2:attack=6:release=80:makeup=2.8,alimiter=limit=0.95" ;;
  ym2) AF="highpass=f=80,lowpass=f=13500,equalizer=f=125:t=q:w=1.2:g=2.5,equalizer=f=280:t=q:w=1.5:g=-3.5,equalizer=f=5200:t=q:w=1.4:g=2.6,aecho=0.8:0.89:42|62:0.16|0.12,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-15dB:ratio=2.8:attack=10:release=100:makeup=2.8,alimiter=limit=0.95" ;;
  priest) AF="highpass=f=95,lowpass=f=13500,equalizer=f=280:t=q:w=1.6:g=-3.8,equalizer=f=3500:t=q:w=1.3:g=3.0,equalizer=f=6800:t=q:w=1.4:g=2.4,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=3.0:attack=8:release=90:makeup=2.8,alimiter=limit=0.95" ;;
  skies) AF="highpass=f=75,lowpass=f=12500,equalizer=f=85:t=q:w=1.2:g=2.6,equalizer=f=520:t=q:w=1.4:g=1.8,equalizer=f=3800:t=q:w=1.3:g=2.5,aecho=0.8:0.88:40|60:0.16|0.12,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=115:makeup=2.8,alimiter=limit=0.95" ;;
  thrash) AF="highpass=f=95,lowpass=f=13500,equalizer=f=340:t=q:w=1.6:g=-4.5,equalizer=f=1600:t=q:w=1.3:g=2.8,equalizer=f=4600:t=q:w=1.3:g=2.8,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=4.0:attack=5:release=75:makeup=3.2,alimiter=limit=0.94" ;;
  swedish) AF="highpass=f=80,lowpass=f=12500,equalizer=f=1100:t=q:w=1.3:g=3.2,equalizer=f=2400:t=q:w=1.3:g=3.0,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=4.2:attack=6:release=80:makeup=3.2,alimiter=limit=0.94" ;;
  maiden) AF="highpass=f=80,lowpass=f=12500,equalizer=f=680:t=q:w=1.4:g=2.2,equalizer=f=2100:t=q:w=1.3:g=2.4,aecho=0.8:0.9:32|48:0.13|0.09,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=110:makeup=2.8,alimiter=limit=0.95" ;;
  gallop) AF="highpass=f=80,lowpass=f=13000,equalizer=f=720:t=q:w=1.4:g=2.4,equalizer=f=2300:t=q:w=1.3:g=2.6,aecho=0.8:0.9:30|46:0.12|0.08,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=3.0:attack=10:release=105:makeup=2.8,alimiter=limit=0.95" ;;
  freedom) AF="highpass=f=90,lowpass=f=14000,equalizer=f=240:t=q:w=1.6:g=-3.5,equalizer=f=4500:t=q:w=1.3:g=3.0,equalizer=f=7500:t=q:w=1.4:g=2.4,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-16dB:ratio=3.2:attack=6:release=80:makeup=2.8,alimiter=limit=0.95" ;;
  jpopmetal) AF="highpass=f=95,lowpass=f=14500,equalizer=f=260:t=q:w=1.6:g=-3.4,equalizer=f=3400:t=q:w=1.3:g=2.8,equalizer=f=5500:t=q:w=1.4:g=2.4,equalizer=f=8500:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=3.0:attack=7:release=85:makeup=2.8,alimiter=limit=0.95" ;;
  dragon) AF="highpass=f=105,lowpass=f=14500,equalizer=f=280:t=q:w=1.6:g=-4.0,equalizer=f=4400:t=q:w=1.3:g=3.2,equalizer=f=8000:t=q:w=1.4:g=2.6,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-17dB:ratio=3.5:attack=5:release=70:makeup=3.0,alimiter=limit=0.95" ;;
  numetal) AF="highpass=f=55,lowpass=f=12000,equalizer=f=65:t=q:w=1.2:g=3.6,equalizer=f=360:t=q:w=1.6:g=-4.4,equalizer=f=2500:t=q:w=1.3:g=2.8,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-18dB:ratio=4.2:attack=5:release=80:makeup=3.2,alimiter=limit=0.94" ;;
  gfunk) AF="highpass=f=55,lowpass=f=13000,equalizer=f=65:t=q:w=1.2:g=3.4,equalizer=f=320:t=q:w=1.6:g=-3.8,equalizer=f=3000:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-16dB:ratio=3.0:attack=12:release=115:makeup=3.0,alimiter=limit=0.95" ;;
  westcoast) AF="highpass=f=60,lowpass=f=13500,equalizer=f=75:t=q:w=1.2:g=3.2,equalizer=f=280:t=q:w=1.6:g=-3.6,equalizer=f=3400:t=q:w=1.3:g=2.8,equalizer=f=7200:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-16dB:ratio=3.2:attack=8:release=95:makeup=3.0,alimiter=limit=0.95" ;;
  boombap) AF="highpass=f=70,lowpass=f=9500,equalizer=f=90:t=q:w=1.2:g=3.0,equalizer=f=1200:t=q:w=1.4:g=2.2,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.15,acompressor=threshold=-17dB:ratio=3.5:attack=8:release=95:makeup=3.0,alimiter=limit=0.95" ;;
  jazzy) AF="highpass=f=65,lowpass=f=10500,equalizer=f=120:t=q:w=1.2:g=2.8,equalizer=f=420:t=q:w=1.4:g=2.0,equalizer=f=2600:t=q:w=1.5:g=-1.8,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-15dB:ratio=2.4:attack=18:release=135:makeup=2.5,alimiter=limit=0.95" ;;
  golden) AF="highpass=f=75,lowpass=f=12000,equalizer=f=85:t=q:w=1.2:g=2.8,equalizer=f=1500:t=q:w=1.3:g=2.4,equalizer=f=3200:t=q:w=1.3:g=2.2,stereotools=mlev=1.0:slev=1.18,acompressor=threshold=-17dB:ratio=3.5:attack=6:release=85:makeup=3.0,alimiter=limit=0.95" ;;
  phonk) AF="highpass=f=48,lowpass=f=11500,equalizer=f=55:t=q:w=1.2:g=4.0,equalizer=f=340:t=q:w=1.6:g=-4.5,equalizer=f=3600:t=q:w=1.3:g=2.6,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=4.0:attack=6:release=85:makeup=3.2,alimiter=limit=0.94" ;;
  trap) AF="highpass=f=50,lowpass=f=14500,equalizer=f=55:t=q:w=1.2:g=3.6,equalizer=f=260:t=q:w=1.6:g=-4.2,equalizer=f=4800:t=q:w=1.3:g=2.8,equalizer=f=8500:t=q:w=1.4:g=2.4,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-18dB:ratio=3.8:attack=5:release=75:makeup=3.2,alimiter=limit=0.94" ;;
esac

case "$FORMAT" in
  mp4) OUT_ARGS="-c:v copy -c:a aac -b:a 192k" ;;
  wav) OUT_ARGS="-vn -c:a pcm_s16le -ar 44100" ;;
  flac) OUT_ARGS="-vn -c:a flac -ar 44100" ;;
  *) OUT_ARGS="-vn -c:a libmp3lame -b:a 320k -ar 44100" ;;
esac

ffmpeg -y $START_ARG -i "$IN" $TRIM_ARG \
  -af "${AF},afade=t=in:st=0:d=0.5,afade=t=out:st=${FADEOUT}:d=5" \
  $OUT_ARGS \
  -metadata title="$TITLE" \
  -metadata artist="$ARTIST" \
  -metadata album="$ALBUM" \
  "$OUT"

echo "Done [$PRESET -> $FORMAT] -> $OUT"
