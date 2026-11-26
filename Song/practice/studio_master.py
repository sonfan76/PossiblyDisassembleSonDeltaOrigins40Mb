#!/usr/bin/env python3
import argparse, re, subprocess, sys
from pathlib import Path

MEDIA_EXTS = {".mp4", ".mkv", ".webm", ".avi", ".wav", ".flac", ".mp3", ".ogg", ".m4a"}

PRESETS = {'acoustic': ('5',
              'Bright steel-string acoustic / unplugged body & air clarity',
              'highpass=f=85,lowpass=f=14500,equalizer=f=220:t=q:w=1.5:g=-3.0,equalizer=f=420:t=q:w=1.5:g=-2.5,equalizer=f=4500:t=q:w=1.3:g=2.6,equalizer=f=8000:t=q:w=1.4:g=2.4,aecho=0.8:0.9:30|45:0.12|0.08,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-15dB:ratio=2.5:attack=14:release=120:makeup=2.6,alimiter=limit=0.95'),
 'alreadypolished': ('p',
                     "Master an already-EQ'd file (prevents double EQ)",
                     'stereotools=mlev=1.0:slev=1.22,equalizer=f=110:t=q:w=1.2:g=2.0,equalizer=f=4200:t=q:w=1.4:g=1.8,acompressor=threshold=-14dB:ratio=2.5:attack=15:release=120:makeup=2.5,alimiter=limit=0.95'),
 'amiga': ('a',
           'Commodore Amiga / M68K Paula 8-bit tracker grit & warmth',
           'highpass=f=80,lowpass=f=7200,equalizer=f=130:t=q:w=1.3:g=3.2,equalizer=f=950:t=q:w=1.4:g=2.4,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.32,acompressor=threshold=-16dB:ratio=3.2:attack=8:release=90:makeup=3.0,alimiter=limit=0.95'),
 'ballad': ('L',
            'Clean-to-heavy dynamic power ballad warmth & stereo hall',
            'highpass=f=75,lowpass=f=12500,equalizer=f=160:t=q:w=1.3:g=2.4,equalizer=f=320:t=q:w=1.5:g=-2.8,equalizer=f=3200:t=q:w=1.3:g=2.0,aecho=0.8:0.88:48|72:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-14dB:ratio=2.4:attack=22:release=145:makeup=2.5,alimiter=limit=0.95'),
 'baroque': ('B',
             'Cathedral chamber reverb + dramatic harmonic-minor clarity',
             'highpass=f=80,lowpass=f=12500,equalizer=f=300:t=q:w=1.5:g=-3.0,equalizer=f=2800:t=q:w=1.3:g=2.5,aecho=0.8:0.88:55|85:0.22|0.16,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-15dB:ratio=2.5:attack=14:release=120:makeup=2.5,alimiter=limit=0.95'),
 'blackmore': ('r',
               '1970s Rainbow Rising woody midrange & dramatic room tail',
               'highpass=f=75,lowpass=f=10000,equalizer=f=650:t=q:w=1.4:g=2.6,equalizer=f=1800:t=q:w=1.3:g=2.2,aecho=0.8:0.89:38|58:0.15|0.11,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-14dB:ratio=2.5:attack=16:release=125:makeup=2.6,alimiter=limit=0.95'),
 'boombap': ('w',
             '90s East Coast MPC vinyl-sampler warmth & gritty midrange',
             'highpass=f=70,lowpass=f=9500,equalizer=f=90:t=q:w=1.2:g=3.0,equalizer=f=1200:t=q:w=1.4:g=2.2,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.15,acompressor=threshold=-17dB:ratio=3.5:attack=8:release=95:makeup=3.0,alimiter=limit=0.95'),
 'boomy': ('b',
           'Small/carpeted room or close amps (heavy bass/mud cut)',
           'highpass=f=95,lowpass=f=11500,equalizer=f=160:t=q:w=1.4:g=-4.5,equalizer=f=320:t=q:w=1.5:g=-4.0,equalizer=f=2600:t=q:w=1.2:g=2.5,equalizer=f=4500:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-16dB:ratio=3:attack=10:release=100:makeup=3.0,alimiter=limit=0.95'),
 'car': ('i',
         'Car stereo / small speaker bass harmonics & translation',
         'highpass=f=75,lowpass=f=12500,equalizer=f=130:t=q:w=1.2:g=3.0,equalizer=f=240:t=q:w=1.4:g=2.0,equalizer=f=3200:t=q:w=1.3:g=2.4,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=3.8:attack=8:release=95:makeup=3.2,alimiter=limit=0.94'),
 'cdj': ('U',
         'Numark CDJ / PA club speaker sub-control & mid cut-through',
         'highpass=f=45,lowpass=f=14500,equalizer=f=70:t=q:w=1.2:g=2.5,equalizer=f=250:t=q:w=1.6:g=-3.8,equalizer=f=2800:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.5:attack=8:release=90:makeup=3.0,alimiter=limit=0.96'),
 'clean': ('f',
           'Fingerstyle clean / jazz-fusion warm neck-pickup tone',
           'highpass=f=70,lowpass=f=12500,equalizer=f=220:t=q:w=1.3:g=2.4,equalizer=f=3800:t=q:w=1.5:g=-1.8,aecho=0.8:0.9:35|50:0.12|0.08,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-14dB:ratio=2.2:attack=20:release=140:makeup=2.4,alimiter=limit=0.95'),
 'cockpit': ('c',
             '1986 Top Gun / Sunset Strip glossy arena lead & wide chorus',
             'highpass=f=90,lowpass=f=14500,equalizer=f=300:t=q:w=1.6:g=-3.8,equalizer=f=5000:t=q:w=1.3:g=3.0,equalizer=f=8000:t=q:w=1.4:g=2.5,aecho=0.8:0.88:44|66:0.16|0.12,stereotools=mlev=1.0:slev=1.32,acompressor=threshold=-15dB:ratio=2.8:attack=10:release=100:makeup=2.8,alimiter=limit=0.95'),
 'dio': ('O',
         '80s arena heavy-metal low-mid weight & punchy chug',
         'highpass=f=70,lowpass=f=9500,equalizer=f=130:t=q:w=1.2:g=3.0,equalizer=f=550:t=q:w=1.4:g=2.0,equalizer=f=2800:t=q:w=1.3:g=1.5,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-15dB:ratio=2.8:attack=18:release=135:makeup=2.8,alimiter=limit=0.95'),
 'direct': ('D',
            'Direct CabDryVR line-in (adds room air, skips mic EQ)',
            'highpass=f=65,equalizer=f=120:t=q:w=1.2:g=1.5,equalizer=f=3800:t=q:w=1.4:g=1.5,aecho=0.8:0.9:28|42:0.12|0.09,stereotools=mlev=1.0:slev=1.18,acompressor=threshold=-14dB:ratio=2.5:attack=15:release=120:makeup=2.5,alimiter=limit=0.95'),
 'dk1': ('k',
         'Heavy progressive wall of sound + crisp classical-break clarity',
         'highpass=f=65,lowpass=f=13000,equalizer=f=75:t=q:w=1.2:g=3.2,equalizer=f=250:t=q:w=1.6:g=-4.0,equalizer=f=3600:t=q:w=1.3:g=2.6,equalizer=f=6000:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-16dB:ratio=3.2:attack=10:release=105:makeup=3.0,alimiter=limit=0.95'),
 'dk2': ('K',
         'Tight modern high-gain metal razor & aggressive chug bite',
         'highpass=f=85,lowpass=f=12500,equalizer=f=280:t=q:w=1.6:g=-4.2,equalizer=f=1800:t=q:w=1.3:g=2.8,equalizer=f=4200:t=q:w=1.3:g=2.5,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-18dB:ratio=4.0:attack=6:release=80:makeup=3.2,alimiter=limit=0.94'),
 'doom': ('d',
          'Extra sub-bass weight + scooped mids for heavy slow riffs',
          'highpass=f=60,lowpass=f=11000,equalizer=f=85:t=q:w=1.1:g=3.5,equalizer=f=300:t=q:w=1.5:g=-3.5,equalizer=f=2200:t=q:w=1.2:g=2.0,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=3:attack=15:release=130:makeup=3.0,alimiter=limit=0.95'),
 'dragon': ('G',
            'DragonForce hyper-speed power-metal shimmer & clarity',
            'highpass=f=105,lowpass=f=14500,equalizer=f=280:t=q:w=1.6:g=-4.0,equalizer=f=4400:t=q:w=1.3:g=3.2,equalizer=f=8000:t=q:w=1.4:g=2.6,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-17dB:ratio=3.5:attack=5:release=70:makeup=3.0,alimiter=limit=0.95'),
 'echoey': ('e',
            'Bare/hard-walled room (tames slapback reflections)',
            'highpass=f=85,lowpass=f=10500,equalizer=f=450:t=q:w=1.8:g=-4.0,equalizer=f=1200:t=q:w=1.6:g=-2.5,equalizer=f=3000:t=q:w=1.3:g=2.0,acompressor=threshold=-15dB:ratio=3.5:attack=8:release=80:makeup=3.0,alimiter=limit=0.95'),
 'freedom': ('F',
             'High-speed JP melodic power-metal sparkle & fast transients',
             'highpass=f=90,lowpass=f=14000,equalizer=f=240:t=q:w=1.6:g=-3.5,equalizer=f=4500:t=q:w=1.3:g=3.0,equalizer=f=7500:t=q:w=1.4:g=2.4,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-16dB:ratio=3.2:attack=6:release=80:makeup=2.8,alimiter=limit=0.95'),
 'gallop': ('C',
            'Driving Euro-power triplet gallop + harmonized arena punch',
            'highpass=f=80,lowpass=f=13000,equalizer=f=720:t=q:w=1.4:g=2.4,equalizer=f=2300:t=q:w=1.3:g=2.6,aecho=0.8:0.9:30|46:0.12|0.08,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=3.0:attack=10:release=105:makeup=2.8,alimiter=limit=0.95'),
 'genesis': ('1',
             '1991-93 Mega Drive action (Streets of Rage / Shinobi)',
             'highpass=f=80,lowpass=f=11000,equalizer=f=90:t=q:w=1.2:g=3.0,equalizer=f=220:t=q:w=1.4:g=2.0,equalizer=f=3000:t=q:w=1.3:g=2.2,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.2:attack=10:release=100:makeup=3.0,alimiter=limit=0.95'),
 'gfunk': ('g',
           '90s West Coast G-Funk sub-bass + silky singing lead shimmer',
           'highpass=f=55,lowpass=f=13000,equalizer=f=65:t=q:w=1.2:g=3.4,equalizer=f=320:t=q:w=1.6:g=-3.8,equalizer=f=3000:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-16dB:ratio=3.0:attack=12:release=115:makeup=3.0,alimiter=limit=0.95'),
 'golden': ('Z',
            'Crisp 90s golden-era lyrical boom-bap midrange punch',
            'highpass=f=75,lowpass=f=12000,equalizer=f=85:t=q:w=1.2:g=2.8,equalizer=f=1500:t=q:w=1.3:g=2.4,equalizer=f=3200:t=q:w=1.3:g=2.2,stereotools=mlev=1.0:slev=1.18,acompressor=threshold=-17dB:ratio=3.5:attack=6:release=85:makeup=3.0,alimiter=limit=0.95'),
 'hall': ('H',
          'Subtle studio hall reverb + wide stereo spread',
          'highpass=f=75,lowpass=f=12500,equalizer=f=280:t=q:w=1.5:g=-3.0,equalizer=f=110:t=q:w=1.2:g=2.0,equalizer=f=4200:t=q:w=1.4:g=2.0,aecho=0.8:0.88:45|65:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=2.5:attack=15:release=120:makeup=2.5,alimiter=limit=0.95'),
 'jazzy': ('z',
           'Warm Rhodes / soul-chopped boom-bap velvet low-mids',
           'highpass=f=65,lowpass=f=10500,equalizer=f=120:t=q:w=1.2:g=2.8,equalizer=f=420:t=q:w=1.4:g=2.0,equalizer=f=2600:t=q:w=1.5:g=-1.8,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-15dB:ratio=2.4:attack=18:release=135:makeup=2.5,alimiter=limit=0.95'),
 'jcm800': ('8',
            '1983 Marshall JCM800 British upper-mid hard-rock bark',
            'highpass=f=90,lowpass=f=13000,equalizer=f=280:t=q:w=1.6:g=-3.2,equalizer=f=1400:t=q:w=1.3:g=2.6,equalizer=f=2800:t=q:w=1.3:g=2.8,equalizer=f=5000:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.2:attack=10:release=100:makeup=2.8,alimiter=limit=0.95'),
 'jp86': ('j',
          '80s JP neoclassical power-metal brightness & dual-lead shimmer',
          'highpass=f=95,lowpass=f=13500,equalizer=f=260:t=q:w=1.6:g=-3.5,equalizer=f=3800:t=q:w=1.3:g=2.8,equalizer=f=6500:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-15dB:ratio=3:attack=8:release=90:makeup=2.8,alimiter=limit=0.95'),
 'jp86dark': ('J',
              'Heavier, darker JP86 chug + neoclassical lead bite',
              'highpass=f=75,lowpass=f=13000,equalizer=f=80:t=q:w=1.2:g=2.8,equalizer=f=600:t=q:w=1.4:g=1.8,equalizer=f=4200:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=3:attack=10:release=100:makeup=2.8,alimiter=limit=0.95'),
 'jpopmetal': ('A',
               'Anime-opening symphonic power-metal clean-to-shred sparkle',
               'highpass=f=95,lowpass=f=14500,equalizer=f=260:t=q:w=1.6:g=-3.4,equalizer=f=3400:t=q:w=1.3:g=2.8,equalizer=f=5500:t=q:w=1.4:g=2.4,equalizer=f=8500:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=3.0:attack=7:release=85:makeup=2.8,alimiter=limit=0.95'),
 'kyuss': ('q',
           '1992 Palm Desert stoner fuzz & bass-amp cabinet rumble',
           'highpass=f=55,lowpass=f=8800,equalizer=f=65:t=q:w=1.2:g=3.8,equalizer=f=160:t=q:w=1.3:g=2.8,equalizer=f=550:t=q:w=1.4:g=2.2,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.0:attack=18:release=140:makeup=3.0,alimiter=limit=0.95'),
 'loud': ('l',
          'High-volume/garage jam (tames mic overload harshness)',
          'highpass=f=110,lowpass=f=10000,equalizer=f=250:t=q:w=1.5:g=-3.5,equalizer=f=3500:t=q:w=1.4:g=-3.0,acompressor=threshold=-20dB:ratio=4:attack=5:release=90:makeup=3.5,alimiter=limit=0.92'),
 'maiden': ('M',
            'NWOBHM / Euro power-metal gallop + warm British midrange',
            'highpass=f=80,lowpass=f=12500,equalizer=f=680:t=q:w=1.4:g=2.2,equalizer=f=2100:t=q:w=1.3:g=2.4,aecho=0.8:0.9:32|48:0.13|0.09,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=110:makeup=2.8,alimiter=limit=0.95'),
 'midnight': ('n',
              'Low-volume late-night headphone contour & warm hall',
              'highpass=f=65,lowpass=f=10500,equalizer=f=95:t=q:w=1.2:g=2.8,equalizer=f=3500:t=q:w=1.5:g=-2.5,aecho=0.8:0.88:48|72:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=2.5:attack=18:release=135:makeup=2.6,alimiter=limit=0.95'),
 'mj': ('m',
        '80s Bad-era funk-pop studio snap & sparkling finger attack',
        'highpass=f=90,lowpass=f=14000,equalizer=f=300:t=q:w=1.6:g=-3.8,equalizer=f=4800:t=q:w=1.3:g=3.0,equalizer=f=8000:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.5:attack=5:release=70:makeup=3.0,alimiter=limit=0.95'),
 'model1': ('0',
            '1989 Genesis Model 1 (VA2/VA3) warm preamp saturation',
            'highpass=f=70,lowpass=f=9500,equalizer=f=140:t=q:w=1.2:g=3.2,equalizer=f=480:t=q:w=1.4:g=2.2,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-15dB:ratio=2.8:attack=14:release=120:makeup=2.8,alimiter=limit=0.95'),
 'neogeo': ('9',
            'SNK Neo Geo AES (M68K + YM2610) beefy arcade punch',
            'highpass=f=75,lowpass=f=11500,equalizer=f=115:t=q:w=1.2:g=3.2,equalizer=f=500:t=q:w=1.4:g=2.2,equalizer=f=3600:t=q:w=1.3:g=2.6,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.4:attack=8:release=95:makeup=3.0,alimiter=limit=0.95'),
 'numetal': ('N',
             '2000s drop-tuned groove punch + syncopated palm-mute slap',
             'highpass=f=55,lowpass=f=12000,equalizer=f=65:t=q:w=1.2:g=3.6,equalizer=f=360:t=q:w=1.6:g=-4.4,equalizer=f=2500:t=q:w=1.3:g=2.8,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-18dB:ratio=4.2:attack=5:release=80:makeup=3.2,alimiter=limit=0.94'),
 'phonk': ('W',
           'Dark underground lo-fi sub-bass rumble + gritty bite',
           'highpass=f=48,lowpass=f=11500,equalizer=f=55:t=q:w=1.2:g=4.0,equalizer=f=340:t=q:w=1.6:g=-4.5,equalizer=f=3600:t=q:w=1.3:g=2.6,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=4.0:attack=6:release=85:makeup=3.2,alimiter=limit=0.94'),
 'priest': ('P',
            '1988 Blood Red Skies twin-guitar laser precision & bite',
            'highpass=f=95,lowpass=f=13500,equalizer=f=280:t=q:w=1.6:g=-3.8,equalizer=f=3500:t=q:w=1.3:g=3.0,equalizer=f=6800:t=q:w=1.4:g=2.4,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=3.0:attack=8:release=90:makeup=2.8,alimiter=limit=0.95'),
 'sabbath': ('I',
             '1970s Tony Iommi woolly low-mid doom fuzz & tape saturation',
             'highpass=f=65,lowpass=f=9000,equalizer=f=140:t=q:w=1.2:g=3.2,equalizer=f=650:t=q:w=1.4:g=2.6,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-15dB:ratio=2.8:attack=18:release=135:makeup=2.8,alimiter=limit=0.95'),
 'shred': ('s',
           'Neoclassical clarity: tight lows + sharp finger articulation',
           'highpass=f=100,lowpass=f=13000,equalizer=f=350:t=q:w=1.6:g=-4.0,equalizer=f=3200:t=q:w=1.3:g=3.0,equalizer=f=5500:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-16dB:ratio=3.5:attack=6:release=75:makeup=3.0,alimiter=limit=0.95'),
 'skies': ('S',
           'Dark synth-metal atmosphere + wide brooding lead sustain',
           'highpass=f=75,lowpass=f=12500,equalizer=f=85:t=q:w=1.2:g=2.6,equalizer=f=520:t=q:w=1.4:g=1.8,equalizer=f=3800:t=q:w=1.3:g=2.5,aecho=0.8:0.88:40|60:0.16|0.12,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=115:makeup=2.8,alimiter=limit=0.95'),
 'snes': ('7',
          'Super Nintendo SPC700 Gaussian-filtered velvet & echo',
          'highpass=f=70,lowpass=f=6500,equalizer=f=180:t=q:w=1.3:g=3.0,equalizer=f=900:t=q:w=1.5:g=1.8,aecho=0.8:0.88:42|64:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=2.6:attack=16:release=130:makeup=2.8,alimiter=limit=0.95'),
 'sonic': ('3',
           'Sonic 3 & Knuckles bouncy FM bass + bright PSG sparkle',
           'highpass=f=75,lowpass=f=12500,equalizer=f=80:t=q:w=1.2:g=3.2,equalizer=f=280:t=q:w=1.5:g=-3.0,equalizer=f=5500:t=q:w=1.4:g=2.8,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-16dB:ratio=3.5:attack=6:release=85:makeup=3.0,alimiter=limit=0.95'),
 'swedish': ('E',
             '90s Gothenburg / HM-2 chainsaw melodeath midrange grind',
             'highpass=f=80,lowpass=f=12500,equalizer=f=1100:t=q:w=1.3:g=3.2,equalizer=f=2400:t=q:w=1.3:g=3.0,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=4.2:attack=6:release=80:makeup=3.2,alimiter=limit=0.94'),
 'synthwave': ('o',
               '1984 Outrun / John Carpenter analog chorus & stereo delay',
               'highpass=f=75,lowpass=f=14000,equalizer=f=300:t=q:w=1.6:g=-3.6,equalizer=f=5500:t=q:w=1.3:g=2.8,equalizer=f=8500:t=q:w=1.4:g=2.4,aecho=0.8:0.88:45|70:0.18|0.14,stereotools=mlev=1.0:slev=1.32,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=110:makeup=2.8,alimiter=limit=0.95'),
 'thrash': ('R',
            'Aggressive thrash/power-metal palm-mute razor & snarl',
            'highpass=f=95,lowpass=f=13500,equalizer=f=340:t=q:w=1.6:g=-4.5,equalizer=f=1600:t=q:w=1.3:g=2.8,equalizer=f=4600:t=q:w=1.3:g=2.8,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=4.0:attack=5:release=75:makeup=3.2,alimiter=limit=0.94'),
 'thriller': ('T',
              '1982 funk-rock punch + Lukather/EVH midrange bite',
              'highpass=f=85,lowpass=f=13500,equalizer=f=100:t=q:w=1.2:g=2.2,equalizer=f=1400:t=q:w=1.3:g=2.4,equalizer=f=3200:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.2:attack=7:release=85:makeup=2.8,alimiter=limit=0.95'),
 'thunderforce': ('4',
                  'Thunder Force IV (Lightening Force) FM heavy-metal shred',
                  'highpass=f=95,lowpass=f=12000,equalizer=f=320:t=q:w=1.6:g=-4.0,equalizer=f=3400:t=q:w=1.3:g=3.2,equalizer=f=6200:t=q:w=1.4:g=2.5,asoftclip=type=tanh,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-17dB:ratio=3.8:attack=6:release=80:makeup=3.2,alimiter=limit=0.94'),
 'trap': ('x',
          'Modern 808 sub-weight + hyper-crisp finger-pluck sparkle',
          'highpass=f=50,lowpass=f=14500,equalizer=f=55:t=q:w=1.2:g=3.6,equalizer=f=260:t=q:w=1.6:g=-4.2,equalizer=f=4800:t=q:w=1.3:g=2.8,equalizer=f=8500:t=q:w=1.4:g=2.4,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-18dB:ratio=3.8:attack=5:release=75:makeup=3.2,alimiter=limit=0.94'),
 'unpolished': ('u',
                'Bedroom laptop-mic cleanup + studio master (default)',
                'highpass=f=75,lowpass=f=12000,equalizer=f=280:t=q:w=1.5:g=-3.0,equalizer=f=110:t=q:w=1.2:g=2.0,equalizer=f=2400:t=q:w=1.2:g=2.0,equalizer=f=4200:t=q:w=1.4:g=1.5,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3:attack=12:release=110:makeup=3.0,alimiter=limit=0.95'),
 'vault': ('V',
           'Classic NWOBHM / Maiden dual-lead midrange gallop & air',
           'highpass=f=85,lowpass=f=12500,equalizer=f=750:t=q:w=1.4:g=2.4,equalizer=f=2200:t=q:w=1.3:g=2.6,aecho=0.8:0.9:35|52:0.14|0.10,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=110:makeup=2.8,alimiter=limit=0.95'),
 'vintage': ('v',
             '1980s analog cassette/tape warmth + soft saturation',
             'highpass=f=70,lowpass=f=8500,equalizer=f=140:t=q:w=1.2:g=2.5,equalizer=f=400:t=q:w=1.4:g=1.8,equalizer=f=2800:t=q:w=1.5:g=-1.5,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.15,acompressor=threshold=-15dB:ratio=2.5:attack=20:release=140:makeup=2.5,alimiter=limit=0.95'),
 'westcoast': ('Q',
               'Bouncy 90s M-Style synth-funk snap + wide stereo whistle',
               'highpass=f=60,lowpass=f=13500,equalizer=f=75:t=q:w=1.2:g=3.2,equalizer=f=280:t=q:w=1.6:g=-3.6,equalizer=f=3400:t=q:w=1.3:g=2.8,equalizer=f=7200:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-16dB:ratio=3.2:attack=8:release=95:makeup=3.0,alimiter=limit=0.95'),
 'ym1': ('y',
         '1984 Rising Force bell-like DOD 250 + Strat glassy clarity',
         'highpass=f=105,lowpass=f=13500,equalizer=f=320:t=q:w=1.6:g=-4.2,equalizer=f=4200:t=q:w=1.3:g=3.2,equalizer=f=7000:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-15dB:ratio=3.2:attack=6:release=80:makeup=2.8,alimiter=limit=0.95'),
 'ym2': ('Y',
         'Full-tilt symphonic neoclassical anthem + wide hall shimmer',
         'highpass=f=80,lowpass=f=13500,equalizer=f=125:t=q:w=1.2:g=2.5,equalizer=f=280:t=q:w=1.5:g=-3.5,equalizer=f=5200:t=q:w=1.4:g=2.6,aecho=0.8:0.89:42|62:0.16|0.12,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-15dB:ratio=2.8:attack=10:release=100:makeup=2.8,alimiter=limit=0.95'),
 'ym2612': ('2',
            'Sega Genesis YM2612 FM synth lead + 11-bit DAC grit',
            'highpass=f=110,lowpass=f=11500,equalizer=f=1800:t=q:w=1.3:g=2.8,equalizer=f=4200:t=q:w=1.4:g=2.4,acrusher=bits=11:mode=log:samples=2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.2:attack=8:release=90:makeup=3.0,alimiter=limit=0.95')}

def parse_ts(ts: str) -> float:
    p = [float(x) for x in ts.split(":")]
    return p[0] * 3600 + p[1] * 60 + p[2] if len(p) == 3 else (p[0] * 60 + p[1] if len(p) == 2 else p[0])

def get_dur(path: Path) -> float:
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1", str(path)], capture_output=True, text=True, check=True)
    return float(r.stdout.strip())

def process_file(infile: Path, preset: str, fmt: str, title: str, artist: str,
                 album: str, start: str, end: str, norm: bool, outdir: object):
    af = PRESETS[preset][2] + (",loudnorm=I=-14:TP=-1.5:LRA=11" if norm else "")
    dur = (parse_ts(end) if end else get_dur(infile)) - (parse_ts(start) if start else 0)
    fadeout = max(1, int(dur) - 5)
    out_dir = outdir if outdir else infile.parent
    out_dir.mkdir(parents=True, exist_ok=True)
    outfile = out_dir / f"{infile.stem}_{preset}_studio.{fmt}"
    cmd = ["ffmpeg", "-y"] + (["-ss", start] if start else []) + ["-i", str(infile)] + (["-to", end] if end else [])
    cmd += ["-af", f"{af},afade=t=in:st=0:d=0.5,afade=t=out:st={fadeout}:d=5"]
    if fmt == "mp4": cmd += ["-c:v", "copy", "-c:a", "aac", "-b:a", "192k"]
    elif fmt == "wav": cmd += ["-vn", "-c:a", "pcm_s16le", "-ar", "44100"]
    elif fmt == "flac": cmd += ["-vn", "-c:a", "flac", "-ar", "44100"]
    else: cmd += ["-vn", "-c:a", "libmp3lame", "-b:a", "320k", "-ar", "44100"]
    cmd += ["-metadata", f"title={title or infile.stem}", "-metadata", f"artist={artist}", "-metadata", f"album={album}", str(outfile)]
    subprocess.run(cmd, check=True)
    print(f"Done [{preset} -> {fmt}] -> {outfile}")

def main():
    epilog = """Examples:
  ./studio_master.py practice_raw.mp4 "Late Night Warbeast"
  ./studio_master.py -p -4 practice_final.mp4 "Thunder Force Jam"
  ./studio_master.py --cdj existing_track.mp3 "Club Master"
  ./studio_master.py --wav -I pedalboard_take.wav "Sabbath Lossless"
  ./studio_master.py --batch ./raw_takes/ -4 --norm --outdir ./cdj_ready/"""
    ap = argparse.ArgumentParser(description="Batch & single-file mastering wrapper (58 presets from studio_master.sh).",
        epilog=epilog, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input", nargs="?", help="Input file (or folder with --batch)")
    ap.add_argument("title", nargs="?", help="Optional track title metadata")
    ap.add_argument("--preset", default="unpolished", choices=PRESETS.keys())
    ap.add_argument("--list", action="store_true", help="List all 58 presets and exit")
    ap.add_argument("--batch", action="store_true", help="Batch-process all media files in input folder")
    ap.add_argument("--outdir", type=Path, help="Output directory")
    ap.add_argument("--norm", action="store_true", help="Normalize loudness to -14 LUFS")
    ap.add_argument("--mp3", dest="fmt", action="store_const", const="mp3", default="mp3")
    ap.add_argument("--wav", dest="fmt", action="store_const", const="wav")
    ap.add_argument("--flac", dest="fmt", action="store_const", const="flac")
    ap.add_argument("--video", "--mp4", dest="fmt", action="store_const", const="mp4")
    ap.add_argument("--start", "--ss", help="Start timestamp (HH:MM:SS)")
    ap.add_argument("--trim", "--end", "-t", help="End timestamp (HH:MM:SS)")
    ap.add_argument("--album", default="Scalloped Warbeast Sessions (2026)")
    ap.add_argument("--artist", default="Assembly LKE")
    for name, (short, desc, _) in PRESETS.items():
        opts = [f"-{short}", f"--{name}"] if short else [f"--{name}"]
        ap.add_argument(*opts, dest="preset", action="store_const", const=name, help=desc)
    args = ap.parse_args()
    if args.list:
        for k, (s, d, _) in PRESETS.items(): print(f"  -{s}, --{k:<16} {d}")
        sys.exit(0)
    if not args.input: ap.print_help(); sys.exit(1)
    p = Path(args.input)
    files = sorted(f for f in p.iterdir() if f.suffix.lower() in MEDIA_EXTS) if args.batch else [p]
    for f in files: process_file(f, args.preset, args.fmt, None if args.batch else args.title, args.artist, args.album, args.start, args.trim, args.norm, args.outdir)

if __name__ == "__main__":
    main()
