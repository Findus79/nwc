echo "params: " %1 %2

call "D:\Projekte\nintentool\bin\nintentool.exe" --inputdir %1 --project %2 --target snes --mode map --outdir D:/Projekte/Christmas/Data/Gameover ^
 --layer name=gameover width=32 height=28 bpp=4 tileorder=horizontal paloffset=0 header=0
