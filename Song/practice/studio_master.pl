#!/usr/bin/perl
#STUDIO_MASTER
#  Written in 2026
#
#To the extent possible under law, the author(s) have dedicated all copyright
#and related and neighboring rights to this software to the public domain
#worldwide. This software is distributed without any warranty.
#
#You should have received a copy of the CC0 Public Domain Dedication along
#with this software. If not, see
#<http://creativecommons.org>.

use strict;
use warnings;
use File::Basename;
use File::Spec;
use File::Path qw(mkpath);

#################################################################################
## 58 Room, Retro M68K/YM2612, Metal, Rock & Hip-Hop Mastering Presets
my %PRESETS = (
	'acoustic' => ['5', 'Bright steel-string acoustic / unplugged body & air clarity', 'highpass=f=85,lowpass=f=14500,equalizer=f=220:t=q:w=1.5:g=-3.0,equalizer=f=420:t=q:w=1.5:g=-2.5,equalizer=f=4500:t=q:w=1.3:g=2.6,equalizer=f=8000:t=q:w=1.4:g=2.4,aecho=0.8:0.9:30|45:0.12|0.08,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-15dB:ratio=2.5:attack=14:release=120:makeup=2.6,alimiter=limit=0.95'],
	'alreadypolished' => ['p', 'Master an already-EQ\'d file (prevents double EQ)', 'stereotools=mlev=1.0:slev=1.22,equalizer=f=110:t=q:w=1.2:g=2.0,equalizer=f=4200:t=q:w=1.4:g=1.8,acompressor=threshold=-14dB:ratio=2.5:attack=15:release=120:makeup=2.5,alimiter=limit=0.95'],
	'amiga' => ['a', 'Commodore Amiga / M68K Paula 8-bit tracker grit & warmth', 'highpass=f=80,lowpass=f=7200,equalizer=f=130:t=q:w=1.3:g=3.2,equalizer=f=950:t=q:w=1.4:g=2.4,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.32,acompressor=threshold=-16dB:ratio=3.2:attack=8:release=90:makeup=3.0,alimiter=limit=0.95'],
	'ballad' => ['L', 'Clean-to-heavy dynamic power ballad warmth & stereo hall', 'highpass=f=75,lowpass=f=12500,equalizer=f=160:t=q:w=1.3:g=2.4,equalizer=f=320:t=q:w=1.5:g=-2.8,equalizer=f=3200:t=q:w=1.3:g=2.0,aecho=0.8:0.88:48|72:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-14dB:ratio=2.4:attack=22:release=145:makeup=2.5,alimiter=limit=0.95'],
	'baroque' => ['B', 'Cathedral chamber reverb + dramatic harmonic-minor clarity', 'highpass=f=80,lowpass=f=12500,equalizer=f=300:t=q:w=1.5:g=-3.0,equalizer=f=2800:t=q:w=1.3:g=2.5,aecho=0.8:0.88:55|85:0.22|0.16,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-15dB:ratio=2.5:attack=14:release=120:makeup=2.5,alimiter=limit=0.95'],
	'blackmore' => ['r', '1970s Rainbow Rising woody midrange & dramatic room tail', 'highpass=f=75,lowpass=f=10000,equalizer=f=650:t=q:w=1.4:g=2.6,equalizer=f=1800:t=q:w=1.3:g=2.2,aecho=0.8:0.89:38|58:0.15|0.11,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-14dB:ratio=2.5:attack=16:release=125:makeup=2.6,alimiter=limit=0.95'],
	'boombap' => ['w', '90s East Coast MPC vinyl-sampler warmth & gritty midrange', 'highpass=f=70,lowpass=f=9500,equalizer=f=90:t=q:w=1.2:g=3.0,equalizer=f=1200:t=q:w=1.4:g=2.2,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.15,acompressor=threshold=-17dB:ratio=3.5:attack=8:release=95:makeup=3.0,alimiter=limit=0.95'],
	'boomy' => ['b', 'Small/carpeted room or close amps (heavy bass/mud cut)', 'highpass=f=95,lowpass=f=11500,equalizer=f=160:t=q:w=1.4:g=-4.5,equalizer=f=320:t=q:w=1.5:g=-4.0,equalizer=f=2600:t=q:w=1.2:g=2.5,equalizer=f=4500:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-16dB:ratio=3:attack=10:release=100:makeup=3.0,alimiter=limit=0.95'],
	'car' => ['i', 'Car stereo / small speaker bass harmonics & translation', 'highpass=f=75,lowpass=f=12500,equalizer=f=130:t=q:w=1.2:g=3.0,equalizer=f=240:t=q:w=1.4:g=2.0,equalizer=f=3200:t=q:w=1.3:g=2.4,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=3.8:attack=8:release=95:makeup=3.2,alimiter=limit=0.94'],
	'cdj' => ['U', 'Numark CDJ / PA club speaker sub-control & mid cut-through', 'highpass=f=45,lowpass=f=14500,equalizer=f=70:t=q:w=1.2:g=2.5,equalizer=f=250:t=q:w=1.6:g=-3.8,equalizer=f=2800:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.5:attack=8:release=90:makeup=3.0,alimiter=limit=0.96'],
	'clean' => ['f', 'Fingerstyle clean / jazz-fusion warm neck-pickup tone', 'highpass=f=70,lowpass=f=12500,equalizer=f=220:t=q:w=1.3:g=2.4,equalizer=f=3800:t=q:w=1.5:g=-1.8,aecho=0.8:0.9:35|50:0.12|0.08,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-14dB:ratio=2.2:attack=20:release=140:makeup=2.4,alimiter=limit=0.95'],
	'cockpit' => ['c', '1986 Top Gun / Sunset Strip glossy arena lead & wide chorus', 'highpass=f=90,lowpass=f=14500,equalizer=f=300:t=q:w=1.6:g=-3.8,equalizer=f=5000:t=q:w=1.3:g=3.0,equalizer=f=8000:t=q:w=1.4:g=2.5,aecho=0.8:0.88:44|66:0.16|0.12,stereotools=mlev=1.0:slev=1.32,acompressor=threshold=-15dB:ratio=2.8:attack=10:release=100:makeup=2.8,alimiter=limit=0.95'],
	'dio' => ['O', '80s arena heavy-metal low-mid weight & punchy chug', 'highpass=f=70,lowpass=f=9500,equalizer=f=130:t=q:w=1.2:g=3.0,equalizer=f=550:t=q:w=1.4:g=2.0,equalizer=f=2800:t=q:w=1.3:g=1.5,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-15dB:ratio=2.8:attack=18:release=135:makeup=2.8,alimiter=limit=0.95'],
	'direct' => ['D', 'Direct CabDryVR line-in (adds room air, skips mic EQ)', 'highpass=f=65,equalizer=f=120:t=q:w=1.2:g=1.5,equalizer=f=3800:t=q:w=1.4:g=1.5,aecho=0.8:0.9:28|42:0.12|0.09,stereotools=mlev=1.0:slev=1.18,acompressor=threshold=-14dB:ratio=2.5:attack=15:release=120:makeup=2.5,alimiter=limit=0.95'],
	'dk1' => ['k', 'Heavy progressive wall of sound + crisp classical-break clarity', 'highpass=f=65,lowpass=f=13000,equalizer=f=75:t=q:w=1.2:g=3.2,equalizer=f=250:t=q:w=1.6:g=-4.0,equalizer=f=3600:t=q:w=1.3:g=2.6,equalizer=f=6000:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-16dB:ratio=3.2:attack=10:release=105:makeup=3.0,alimiter=limit=0.95'],
	'dk2' => ['K', 'Tight modern high-gain metal razor & aggressive chug bite', 'highpass=f=85,lowpass=f=12500,equalizer=f=280:t=q:w=1.6:g=-4.2,equalizer=f=1800:t=q:w=1.3:g=2.8,equalizer=f=4200:t=q:w=1.3:g=2.5,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-18dB:ratio=4.0:attack=6:release=80:makeup=3.2,alimiter=limit=0.94'],
	'doom' => ['d', 'Extra sub-bass weight + scooped mids for heavy slow riffs', 'highpass=f=60,lowpass=f=11000,equalizer=f=85:t=q:w=1.1:g=3.5,equalizer=f=300:t=q:w=1.5:g=-3.5,equalizer=f=2200:t=q:w=1.2:g=2.0,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=3:attack=15:release=130:makeup=3.0,alimiter=limit=0.95'],
	'dragon' => ['G', 'DragonForce hyper-speed power-metal shimmer & clarity', 'highpass=f=105,lowpass=f=14500,equalizer=f=280:t=q:w=1.6:g=-4.0,equalizer=f=4400:t=q:w=1.3:g=3.2,equalizer=f=8000:t=q:w=1.4:g=2.6,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-17dB:ratio=3.5:attack=5:release=70:makeup=3.0,alimiter=limit=0.95'],
	'echoey' => ['e', 'Bare/hard-walled room (tames slapback reflections)', 'highpass=f=85,lowpass=f=10500,equalizer=f=450:t=q:w=1.8:g=-4.0,equalizer=f=1200:t=q:w=1.6:g=-2.5,equalizer=f=3000:t=q:w=1.3:g=2.0,acompressor=threshold=-15dB:ratio=3.5:attack=8:release=80:makeup=3.0,alimiter=limit=0.95'],
	'freedom' => ['F', 'High-speed JP melodic power-metal sparkle & fast transients', 'highpass=f=90,lowpass=f=14000,equalizer=f=240:t=q:w=1.6:g=-3.5,equalizer=f=4500:t=q:w=1.3:g=3.0,equalizer=f=7500:t=q:w=1.4:g=2.4,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-16dB:ratio=3.2:attack=6:release=80:makeup=2.8,alimiter=limit=0.95'],
	'gallop' => ['C', 'Driving Euro-power triplet gallop + harmonized arena punch', 'highpass=f=80,lowpass=f=13000,equalizer=f=720:t=q:w=1.4:g=2.4,equalizer=f=2300:t=q:w=1.3:g=2.6,aecho=0.8:0.9:30|46:0.12|0.08,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=3.0:attack=10:release=105:makeup=2.8,alimiter=limit=0.95'],
	'genesis' => ['1', '1991-93 Mega Drive action (Streets of Rage / Shinobi)', 'highpass=f=80,lowpass=f=11000,equalizer=f=90:t=q:w=1.2:g=3.0,equalizer=f=220:t=q:w=1.4:g=2.0,equalizer=f=3000:t=q:w=1.3:g=2.2,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.2:attack=10:release=100:makeup=3.0,alimiter=limit=0.95'],
	'gfunk' => ['g', '90s West Coast G-Funk sub-bass + silky singing lead shimmer', 'highpass=f=55,lowpass=f=13000,equalizer=f=65:t=q:w=1.2:g=3.4,equalizer=f=320:t=q:w=1.6:g=-3.8,equalizer=f=3000:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-16dB:ratio=3.0:attack=12:release=115:makeup=3.0,alimiter=limit=0.95'],
	'golden' => ['Z', 'Crisp 90s golden-era lyrical boom-bap midrange punch', 'highpass=f=75,lowpass=f=12000,equalizer=f=85:t=q:w=1.2:g=2.8,equalizer=f=1500:t=q:w=1.3:g=2.4,equalizer=f=3200:t=q:w=1.3:g=2.2,stereotools=mlev=1.0:slev=1.18,acompressor=threshold=-17dB:ratio=3.5:attack=6:release=85:makeup=3.0,alimiter=limit=0.95'],
	'hall' => ['H', 'Subtle studio hall reverb + wide stereo spread', 'highpass=f=75,lowpass=f=12500,equalizer=f=280:t=q:w=1.5:g=-3.0,equalizer=f=110:t=q:w=1.2:g=2.0,equalizer=f=4200:t=q:w=1.4:g=2.0,aecho=0.8:0.88:45|65:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=2.5:attack=15:release=120:makeup=2.5,alimiter=limit=0.95'],
	'jazzy' => ['z', 'Warm Rhodes / soul-chopped boom-bap velvet low-mids', 'highpass=f=65,lowpass=f=10500,equalizer=f=120:t=q:w=1.2:g=2.8,equalizer=f=420:t=q:w=1.4:g=2.0,equalizer=f=2600:t=q:w=1.5:g=-1.8,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-15dB:ratio=2.4:attack=18:release=135:makeup=2.5,alimiter=limit=0.95'],
	'jcm800' => ['8', '1983 Marshall JCM800 British upper-mid hard-rock bark', 'highpass=f=90,lowpass=f=13000,equalizer=f=280:t=q:w=1.6:g=-3.2,equalizer=f=1400:t=q:w=1.3:g=2.6,equalizer=f=2800:t=q:w=1.3:g=2.8,equalizer=f=5000:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.2:attack=10:release=100:makeup=2.8,alimiter=limit=0.95'],
	'jp86' => ['j', '80s JP neoclassical power-metal brightness & dual-lead shimmer', 'highpass=f=95,lowpass=f=13500,equalizer=f=260:t=q:w=1.6:g=-3.5,equalizer=f=3800:t=q:w=1.3:g=2.8,equalizer=f=6500:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-15dB:ratio=3:attack=8:release=90:makeup=2.8,alimiter=limit=0.95'],
	'jp86dark' => ['J', 'Heavier, darker JP86 chug + neoclassical lead bite', 'highpass=f=75,lowpass=f=13000,equalizer=f=80:t=q:w=1.2:g=2.8,equalizer=f=600:t=q:w=1.4:g=1.8,equalizer=f=4200:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=3:attack=10:release=100:makeup=2.8,alimiter=limit=0.95'],
	'jpopmetal' => ['A', 'Anime-opening symphonic power-metal clean-to-shred sparkle', 'highpass=f=95,lowpass=f=14500,equalizer=f=260:t=q:w=1.6:g=-3.4,equalizer=f=3400:t=q:w=1.3:g=2.8,equalizer=f=5500:t=q:w=1.4:g=2.4,equalizer=f=8500:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=3.0:attack=7:release=85:makeup=2.8,alimiter=limit=0.95'],
	'kyuss' => ['q', '1992 Palm Desert stoner fuzz & bass-amp cabinet rumble', 'highpass=f=55,lowpass=f=8800,equalizer=f=65:t=q:w=1.2:g=3.8,equalizer=f=160:t=q:w=1.3:g=2.8,equalizer=f=550:t=q:w=1.4:g=2.2,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.0:attack=18:release=140:makeup=3.0,alimiter=limit=0.95'],
	'loud' => ['l', 'High-volume/garage jam (tames mic overload harshness)', 'highpass=f=110,lowpass=f=10000,equalizer=f=250:t=q:w=1.5:g=-3.5,equalizer=f=3500:t=q:w=1.4:g=-3.0,acompressor=threshold=-20dB:ratio=4:attack=5:release=90:makeup=3.5,alimiter=limit=0.92'],
	'maiden' => ['M', 'NWOBHM / Euro power-metal gallop + warm British midrange', 'highpass=f=80,lowpass=f=12500,equalizer=f=680:t=q:w=1.4:g=2.2,equalizer=f=2100:t=q:w=1.3:g=2.4,aecho=0.8:0.9:32|48:0.13|0.09,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=110:makeup=2.8,alimiter=limit=0.95'],
	'midnight' => ['n', 'Low-volume late-night headphone contour & warm hall', 'highpass=f=65,lowpass=f=10500,equalizer=f=95:t=q:w=1.2:g=2.8,equalizer=f=3500:t=q:w=1.5:g=-2.5,aecho=0.8:0.88:48|72:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=2.5:attack=18:release=135:makeup=2.6,alimiter=limit=0.95'],
	'mj' => ['m', '80s Bad-era funk-pop studio snap & sparkling finger attack', 'highpass=f=90,lowpass=f=14000,equalizer=f=300:t=q:w=1.6:g=-3.8,equalizer=f=4800:t=q:w=1.3:g=3.0,equalizer=f=8000:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.5:attack=5:release=70:makeup=3.0,alimiter=limit=0.95'],
	'model1' => ['0', '1989 Genesis Model 1 (VA2/VA3) warm preamp saturation', 'highpass=f=70,lowpass=f=9500,equalizer=f=140:t=q:w=1.2:g=3.2,equalizer=f=480:t=q:w=1.4:g=2.2,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-15dB:ratio=2.8:attack=14:release=120:makeup=2.8,alimiter=limit=0.95'],
	'neogeo' => ['9', 'SNK Neo Geo AES (M68K + YM2610) beefy arcade punch', 'highpass=f=75,lowpass=f=11500,equalizer=f=115:t=q:w=1.2:g=3.2,equalizer=f=500:t=q:w=1.4:g=2.2,equalizer=f=3600:t=q:w=1.3:g=2.6,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.4:attack=8:release=95:makeup=3.0,alimiter=limit=0.95'],
	'numetal' => ['N', '2000s drop-tuned groove punch + syncopated palm-mute slap', 'highpass=f=55,lowpass=f=12000,equalizer=f=65:t=q:w=1.2:g=3.6,equalizer=f=360:t=q:w=1.6:g=-4.4,equalizer=f=2500:t=q:w=1.3:g=2.8,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-18dB:ratio=4.2:attack=5:release=80:makeup=3.2,alimiter=limit=0.94'],
	'phonk' => ['W', 'Dark underground lo-fi sub-bass rumble + gritty bite', 'highpass=f=48,lowpass=f=11500,equalizer=f=55:t=q:w=1.2:g=4.0,equalizer=f=340:t=q:w=1.6:g=-4.5,equalizer=f=3600:t=q:w=1.3:g=2.6,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=4.0:attack=6:release=85:makeup=3.2,alimiter=limit=0.94'],
	'priest' => ['P', '1988 Blood Red Skies twin-guitar laser precision & bite', 'highpass=f=95,lowpass=f=13500,equalizer=f=280:t=q:w=1.6:g=-3.8,equalizer=f=3500:t=q:w=1.3:g=3.0,equalizer=f=6800:t=q:w=1.4:g=2.4,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=3.0:attack=8:release=90:makeup=2.8,alimiter=limit=0.95'],
	'sabbath' => ['I', '1970s Tony Iommi woolly low-mid doom fuzz & tape saturation', 'highpass=f=65,lowpass=f=9000,equalizer=f=140:t=q:w=1.2:g=3.2,equalizer=f=650:t=q:w=1.4:g=2.6,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-15dB:ratio=2.8:attack=18:release=135:makeup=2.8,alimiter=limit=0.95'],
	'shred' => ['s', 'Neoclassical clarity: tight lows + sharp finger articulation', 'highpass=f=100,lowpass=f=13000,equalizer=f=350:t=q:w=1.6:g=-4.0,equalizer=f=3200:t=q:w=1.3:g=3.0,equalizer=f=5500:t=q:w=1.4:g=2.0,stereotools=mlev=1.0:slev=1.20,acompressor=threshold=-16dB:ratio=3.5:attack=6:release=75:makeup=3.0,alimiter=limit=0.95'],
	'skies' => ['S', 'Dark synth-metal atmosphere + wide brooding lead sustain', 'highpass=f=75,lowpass=f=12500,equalizer=f=85:t=q:w=1.2:g=2.6,equalizer=f=520:t=q:w=1.4:g=1.8,equalizer=f=3800:t=q:w=1.3:g=2.5,aecho=0.8:0.88:40|60:0.16|0.12,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=115:makeup=2.8,alimiter=limit=0.95'],
	'snes' => ['7', 'Super Nintendo SPC700 Gaussian-filtered velvet & echo', 'highpass=f=70,lowpass=f=6500,equalizer=f=180:t=q:w=1.3:g=3.0,equalizer=f=900:t=q:w=1.5:g=1.8,aecho=0.8:0.88:42|64:0.18|0.14,stereotools=mlev=1.0:slev=1.28,acompressor=threshold=-15dB:ratio=2.6:attack=16:release=130:makeup=2.8,alimiter=limit=0.95'],
	'sonic' => ['3', 'Sonic 3 & Knuckles bouncy FM bass + bright PSG sparkle', 'highpass=f=75,lowpass=f=12500,equalizer=f=80:t=q:w=1.2:g=3.2,equalizer=f=280:t=q:w=1.5:g=-3.0,equalizer=f=5500:t=q:w=1.4:g=2.8,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.25,acompressor=threshold=-16dB:ratio=3.5:attack=6:release=85:makeup=3.0,alimiter=limit=0.95'],
	'swedish' => ['E', '90s Gothenburg / HM-2 chainsaw melodeath midrange grind', 'highpass=f=80,lowpass=f=12500,equalizer=f=1100:t=q:w=1.3:g=3.2,equalizer=f=2400:t=q:w=1.3:g=3.0,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=4.2:attack=6:release=80:makeup=3.2,alimiter=limit=0.94'],
	'synthwave' => ['o', '1984 Outrun / John Carpenter analog chorus & stereo delay', 'highpass=f=75,lowpass=f=14000,equalizer=f=300:t=q:w=1.6:g=-3.6,equalizer=f=5500:t=q:w=1.3:g=2.8,equalizer=f=8500:t=q:w=1.4:g=2.4,aecho=0.8:0.88:45|70:0.18|0.14,stereotools=mlev=1.0:slev=1.32,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=110:makeup=2.8,alimiter=limit=0.95'],
	'thrash' => ['R', 'Aggressive thrash/power-metal palm-mute razor & snarl', 'highpass=f=95,lowpass=f=13500,equalizer=f=340:t=q:w=1.6:g=-4.5,equalizer=f=1600:t=q:w=1.3:g=2.8,equalizer=f=4600:t=q:w=1.3:g=2.8,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-18dB:ratio=4.0:attack=5:release=75:makeup=3.2,alimiter=limit=0.94'],
	'thriller' => ['T', '1982 funk-rock punch + Lukather/EVH midrange bite', 'highpass=f=85,lowpass=f=13500,equalizer=f=100:t=q:w=1.2:g=2.2,equalizer=f=1400:t=q:w=1.3:g=2.4,equalizer=f=3200:t=q:w=1.3:g=2.6,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3.2:attack=7:release=85:makeup=2.8,alimiter=limit=0.95'],
	'thunderforce' => ['4', 'Thunder Force IV (Lightening Force) FM heavy-metal shred', 'highpass=f=95,lowpass=f=12000,equalizer=f=320:t=q:w=1.6:g=-4.0,equalizer=f=3400:t=q:w=1.3:g=3.2,equalizer=f=6200:t=q:w=1.4:g=2.5,asoftclip=type=tanh,acrusher=bits=12:mode=log:samples=2,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-17dB:ratio=3.8:attack=6:release=80:makeup=3.2,alimiter=limit=0.94'],
	'trap' => ['x', 'Modern 808 sub-weight + hyper-crisp finger-pluck sparkle', 'highpass=f=50,lowpass=f=14500,equalizer=f=55:t=q:w=1.2:g=3.6,equalizer=f=260:t=q:w=1.6:g=-4.2,equalizer=f=4800:t=q:w=1.3:g=2.8,equalizer=f=8500:t=q:w=1.4:g=2.4,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-18dB:ratio=3.8:attack=5:release=75:makeup=3.2,alimiter=limit=0.94'],
	'unpolished' => ['u', 'Bedroom laptop-mic cleanup + studio master (default)', 'highpass=f=75,lowpass=f=12000,equalizer=f=280:t=q:w=1.5:g=-3.0,equalizer=f=110:t=q:w=1.2:g=2.0,equalizer=f=2400:t=q:w=1.2:g=2.0,equalizer=f=4200:t=q:w=1.4:g=1.5,stereotools=mlev=1.0:slev=1.22,acompressor=threshold=-16dB:ratio=3:attack=12:release=110:makeup=3.0,alimiter=limit=0.95'],
	'vault' => ['V', 'Classic NWOBHM / Maiden dual-lead midrange gallop & air', 'highpass=f=85,lowpass=f=12500,equalizer=f=750:t=q:w=1.4:g=2.4,equalizer=f=2200:t=q:w=1.3:g=2.6,aecho=0.8:0.9:35|52:0.14|0.10,stereotools=mlev=1.0:slev=1.26,acompressor=threshold=-15dB:ratio=2.8:attack=12:release=110:makeup=2.8,alimiter=limit=0.95'],
	'vintage' => ['v', '1980s analog cassette/tape warmth + soft saturation', 'highpass=f=70,lowpass=f=8500,equalizer=f=140:t=q:w=1.2:g=2.5,equalizer=f=400:t=q:w=1.4:g=1.8,equalizer=f=2800:t=q:w=1.5:g=-1.5,asoftclip=type=tanh,stereotools=mlev=1.0:slev=1.15,acompressor=threshold=-15dB:ratio=2.5:attack=20:release=140:makeup=2.5,alimiter=limit=0.95'],
	'westcoast' => ['Q', 'Bouncy 90s M-Style synth-funk snap + wide stereo whistle', 'highpass=f=60,lowpass=f=13500,equalizer=f=75:t=q:w=1.2:g=3.2,equalizer=f=280:t=q:w=1.6:g=-3.6,equalizer=f=3400:t=q:w=1.3:g=2.8,equalizer=f=7200:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-16dB:ratio=3.2:attack=8:release=95:makeup=3.0,alimiter=limit=0.95'],
	'ym1' => ['y', '1984 Rising Force bell-like DOD 250 + Strat glassy clarity', 'highpass=f=105,lowpass=f=13500,equalizer=f=320:t=q:w=1.6:g=-4.2,equalizer=f=4200:t=q:w=1.3:g=3.2,equalizer=f=7000:t=q:w=1.4:g=2.2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-15dB:ratio=3.2:attack=6:release=80:makeup=2.8,alimiter=limit=0.95'],
	'ym2' => ['Y', 'Full-tilt symphonic neoclassical anthem + wide hall shimmer', 'highpass=f=80,lowpass=f=13500,equalizer=f=125:t=q:w=1.2:g=2.5,equalizer=f=280:t=q:w=1.5:g=-3.5,equalizer=f=5200:t=q:w=1.4:g=2.6,aecho=0.8:0.89:42|62:0.16|0.12,stereotools=mlev=1.0:slev=1.30,acompressor=threshold=-15dB:ratio=2.8:attack=10:release=100:makeup=2.8,alimiter=limit=0.95'],
	'ym2612' => ['2', 'Sega Genesis YM2612 FM synth lead + 11-bit DAC grit', 'highpass=f=110,lowpass=f=11500,equalizer=f=1800:t=q:w=1.3:g=2.8,equalizer=f=4200:t=q:w=1.4:g=2.4,acrusher=bits=11:mode=log:samples=2,stereotools=mlev=1.0:slev=1.24,acompressor=threshold=-16dB:ratio=3.2:attack=8:release=90:makeup=3.0,alimiter=limit=0.95'],
);

my %SHORT_MAP = ();
for my $k (keys %PRESETS)
{
	my ($s) = @{$PRESETS{$k}};
	$SHORT_MAP{$s} = $k if $s ne '';
}

my $preset = 'unpolished';
my $fmt    = 'mp3';
my $start  = '';
my $trim   = '';
my $outdir = '';
my $norm   = 0;
my $batch  = 0;
my $album  = 'Scalloped Warbeast Sessions (2026)';
my $artist = 'Assembly LKE';
my @positional = ();

while (@ARGV)
{
	my $arg = shift @ARGV;
	if ($arg eq '-h' || $arg eq '--help')
	{
		&print_help();
		exit(0);
	}
	elsif ($arg eq '--list')
	{
		for my $k (sort keys %PRESETS)
		{
			my ($s, $d) = @{$PRESETS{$k}};
			printf "  -%-1s, --%-16s %s\n", $s, $k, $d;
		}
		exit(0);
	}
	elsif ($arg eq '--mp3')
	{
		$fmt = 'mp3';
	}
	elsif ($arg eq '--wav')
	{
		$fmt = 'wav';
	}
	elsif ($arg eq '--flac')
	{
		$fmt = 'flac';
	}
	elsif ($arg eq '--video' || $arg eq '--mp4')
	{
		$fmt = 'mp4';
	}
	elsif ($arg eq '--norm')
	{
		$norm = 1;
	}
	elsif ($arg eq '--batch')
	{
		$batch = 1;
	}
	elsif ($arg eq '--start' || $arg eq '--ss')
	{
		$start = shift @ARGV;
	}
	elsif ($arg eq '--trim' || $arg eq '--end' || $arg eq '-t')
	{
		$trim = shift @ARGV;
	}
	elsif ($arg eq '--outdir')
	{
		$outdir = shift @ARGV;
	}
	elsif ($arg eq '--album')
	{
		$album = shift @ARGV;
	}
	elsif ($arg eq '--artist')
	{
		$artist = shift @ARGV;
	}
	elsif ($arg eq '--preset')
	{
		$preset = shift @ARGV;
	}
	elsif ($arg =~ /^--([a-z0-9]+)$/ && exists $PRESETS{$1})
	{
		$preset = $1;
	}
	elsif ($arg =~ /^-([a-zA-Z0-9])$/ && exists $SHORT_MAP{$1})
	{
		$preset = $SHORT_MAP{$1};
	}
	elsif ($arg =~ /^-/)
	{
		die "Unknown option: $arg (try --help)\n";
	}
	else
	{
		push @positional, $arg;
	}
}

if (!@positional)
{
	&print_help();
	exit(1);
}

die "Unknown preset: $preset\n" unless exists $PRESETS{$preset};

my $in_arg    = shift @positional;
my $title_arg = @positional ? shift(@positional) : '';

if ($batch)
{
	die "Error: $in_arg is not a directory.\n" unless -d $in_arg;
	opendir(DIR, $in_arg) or die "Cannot open $in_arg: $!";
	my @files = sort grep { /\.(mp4|mkv|webm|avi|wav|flac|mp3|ogg|m4a)$/i && -f File::Spec->catfile($in_arg, $_) } readdir(DIR);
	closedir(DIR);
	for my $f (@files)
	{
		&process_file(File::Spec->catfile($in_arg, $f), '');
	}
}
else
{
	die "Error: $in_arg not found.\n" unless -f $in_arg;
	&process_file($in_arg, $title_arg);
}

sub print_help
{
	print "Usage: ./studio_master.pl [OPTIONS] <input_file_or_dir> [track_title]\n\n";
	print "Perl 5 standalone mastering & conversion suite (58 presets, CC0 Public Domain).\n";
	print "Default: raw laptop-mic cleanup + studio master (--unpolished) to 320k MP3.\n\n";
	print "Options:\n";
	print "  --mp3, --wav, --flac, --video   Output format (default: mp3; --video copies video)\n";
	print "  --start, --ss HH:MM:SS          Trim start timestamp\n";
	print "  --trim, --end, -t HH:MM:SS      Trim end timestamp\n";
	print "  --batch                         Batch-process all media files in input folder\n";
	print "  --outdir DIR                    Output directory\n";
	print "  --norm                          Normalize loudness to -14 LUFS\n";
	print "  --album NAME / --artist NAME    Override ID3 metadata tags\n";
	print "  --list                          List all 58 presets and descriptions\n";
	print "  -h, --help                      Show this help message\n\n";
	print "Presets:\n";
	for my $k (sort keys %PRESETS)
	{
		my ($s, $d) = @{$PRESETS{$k}};
		printf "  -%-1s, --%-16s %s\n", $s, $k, $d;
	}
	print "\nExamples:\n";
	print "  ./studio_master.pl practice_raw.mp4 \"Late Night Warbeast\"\n";
	print "  ./studio_master.pl -p -4 practice_final.mp4 \"Thunder Force IV\"\n";
	print "  ./studio_master.pl --cdj existing_track.mp3 \"Club Master\"\n";
	print "  ./studio_master.pl --wav -I pedalboard_take.wav \"Sabbath Lossless\"\n";
	print "  ./studio_master.pl --batch ./raw_takes/ -4 --norm --outdir ./cdj_ready/\n";
}

sub parse_ts
{
	my ($ts) = @_;
	my @p = split(/:/, $ts);
	my $sec = 0;
	my $mult = 1;
	while (@p)
	{
		$sec += pop(@p) * $mult;
		$mult *= 60;
	}
	return $sec;
}

sub get_dur
{
	my ($file) = @_;
	open(PROBE, '-|', 'ffprobe', '-v', 'error', '-show_entries', 'format=duration',
	     '-of', 'default=noprint_wrappers=1:nokey=1', $file) or die "ffprobe failed: $!";
	my $d = <PROBE>;
	close(PROBE);
	chomp($d) if defined $d;
	return ($d || 10) + 0;
}

sub process_file
{
	my ($in, $custom_title) = @_;
	my ($base, $dir, $ext) = fileparse($in, qr/\.[^.]*/);
	my $title = $custom_title ne '' ? $custom_title : $base;
	my $target_dir = $outdir ne '' ? $outdir : $dir;
	mkpath($target_dir) unless -d $target_dir;
	my $out = File::Spec->catfile($target_dir, "${base}_${preset}_studio.${fmt}");

	my ($s, $d, $af) = @{$PRESETS{$preset}};
	$af .= ',loudnorm=I=-14:TP=-1.5:LRA=11' if $norm;

	my $dur = $trim ne '' ? &parse_ts($trim) : &get_dur($in);
	$dur -= &parse_ts($start) if $start ne '';
	my $fadeout = int($dur) - 5;
	$fadeout = 1 if $fadeout < 1;

	my @cmd = ('ffmpeg', '-y');
	push @cmd, ('-ss', $start) if $start ne '';
	push @cmd, ('-i', $in);
	push @cmd, ('-to', $trim) if $trim ne '';
	push @cmd, ('-af', "${af},afade=t=in:st=0:d=0.5,afade=t=out:st=${fadeout}:d=5");

	if ($fmt eq 'mp4')
	{
		push @cmd, ('-c:v', 'copy', '-c:a', 'aac', '-b:a', '192k');
	}
	elsif ($fmt eq 'wav')
	{
		push @cmd, ('-vn', '-c:a', 'pcm_s16le', '-ar', '44100');
	}
	elsif ($fmt eq 'flac')
	{
		push @cmd, ('-vn', '-c:a', 'flac', '-ar', '44100');
	}
	else
	{
		push @cmd, ('-vn', '-c:a', 'libmp3lame', '-b:a', '320k', '-ar', '44100');
	}

	push @cmd, ('-metadata', "title=$title", '-metadata', "artist=$artist", '-metadata', "album=$album", $out);
	system(@cmd) == 0 or die "ffmpeg failed on $in\n";
	print "Done [$preset -> $fmt] -> $out\n";
}
