@echo off
bsp winhex.e winhex.bin -ep1.0 -l3 -V -o -M0.5
bsp winhexbr.e winhexbr.bin -ep1.0 -l3 -V -o -M0.5
bsp wintrap.e wintrap.bin -ep1.0 -l3 -V -o -M0.5
bsp wintrapgr.e dorfrenca.bin -ep1.0 -l3 -V -o -M0.5
copy /y winhex.bin ..\obj\
copy /y winhexbr.bin ..\obj\
copy /y wintrap.bin ..\obj\
copy /y wintrapgr.bin ..\obj\
