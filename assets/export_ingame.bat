echo "params: " %1 %2

call "D:\Projekte\nintentool\bin\nintentool.exe" --inputdir %1 --project %2 --target snes --mode map --outdir D:/Projekte/Christmas/Data/Ingame ^
 --layer name=Background width=32 height=64 bpp=4 tileorder=horizontal paloffset=0 header=0 ^
 --layer name=Foreground width=32 height=64 bpp=4 tileorder=horizontal paloffset=0 header=0