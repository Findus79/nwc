echo "params: " %1 %2

call "D:\Projekte\nintentool\bin\nintentool.exe" --inputdir %1 --project %2 --target snes --mode sprite --outdir D:/Projekte/Christmas/Data/Sprites ^
 --spritelayer name=snowflake_small_a tileoffset=0 bpp=4 ^
 --spritelayer name=snowflake_medium_a tileoffset=0 bpp=4
 
 
