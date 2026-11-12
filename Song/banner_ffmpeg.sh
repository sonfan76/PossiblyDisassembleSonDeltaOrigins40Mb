ffmpeg -y \
  -f lavfi -i "color=c=0x060b28:s=2560x1440" \
  -i "../../product-75140.jpg" \
  -filter_complex "\
    [1:v]crop=iw:ih*0.33:0:ih*0.07,scale=1750:620,eq=contrast=1.35:brightness=0.08:saturation=1.6,rotate=-10*PI/180:c=black,crop=1546:423:(iw-1546)/2:(ih-423)/2,format=rgba,colorchannelmixer=aa=0.55[matrix]; \
    [0:v][matrix]overlay=x=507:y=508[bg]; \
    [bg]drawgrid=w=0:h=4:t=1:c=black@0.35, \
        drawbox=x=507:y=508:w=1546:h=423:color=0x000000@0.25:t=fill, \
        drawbox=x=507:y=508:w=1546:h=423:color=0xff1a1a:t=3, \
        drawtext=text='@assembly_LKE':fontcolor=0xffffff:fontsize=96:shadowcolor=0x000000:shadowx=4:shadowy=4:x=(w-text_w)/2:y=590, \
        drawtext=text='M68K ASSEMBLY  |  16-BIT HARDWARE STUDY  |  FREE THE SOFTWARE':fontcolor=0xffc400:fontsize=32:shadowcolor=0x000000:shadowx=3:shadowy=3:x=(w-text_w)/2:y=720, \
        drawtext=text='CC0 PUBLIC DOMAIN  •  1983 GNU ETHOS':fontcolor=0x00ffff:fontsize=26:shadowcolor=0x000000:shadowx=3:shadowy=3:x=(w-text_w)/2:y=790, \
        vignette=PI/4[v]" \
  -map "[v]" -frames:v 1 banner.png
