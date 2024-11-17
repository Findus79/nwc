echo "params: " %1 %2

call "D:\Projekte\nintentool\bin\nintentool.exe" --inputdir %1 --project %2 --target snes --mode sprite --outdir D:/Projekte/Christmas/Data/Sprites ^
 --spritelayer name=Player_NW tileoffset=0 bpp=4 ^
 --spritelayer name=Player_SF tileoffset=0 bpp=4 ^
 --spritelayer name=gingerbreadman tileoff=0 bpp=4
 
 
