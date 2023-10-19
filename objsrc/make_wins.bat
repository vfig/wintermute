@echo off
bsp winhex.e winhex.bin -ep1.0 -l3 -V -o -M0.5
bsp winhexbr.e winhexbr.bin -ep1.0 -l3 -V -o -M0.5
bsp wintrap.e wintrap.bin -ep1.0 -l3 -V -o -M0.5
bsp wintrapbr.e wintrapbr.bin -ep1.0 -l3 -V -o -M0.5
bsp wintrapgr.e dorfrenca.bin -ep1.0 -l3 -V -o -M0.5
bsp wintrap2.e wintrap2.bin -ep1.0 -l3 -V -o -M0.5
bsp wintrap2br.e wintrap2br.bin -ep1.0 -l3 -V -o -M0.5
copy /y winhex.bin ..\obj\
copy /y winhexbr.bin ..\obj\
copy /y wintrap.bin ..\obj\
copy /y wintrapbr.bin ..\obj\
copy /y wintrapgr.bin ..\obj\
copy /y wintrap2.bin ..\obj\
copy /y wintrap2br.bin ..\obj\
