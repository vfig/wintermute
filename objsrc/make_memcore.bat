@echo off
bsp memcorea.e memcorea.bin -l3 -V -o -M0.866
bsp memcoreb.e memcoreb.bin -l3 -V -o -M0.866
bsp mem4x4x4lod1.e mem4x4x4lod1.bin -N -l0 -V -o -M0.866
bsp mem4x4x4lod2.e mem4x4x4lod2.bin -l0 -V -o -M0.866
copy /y memcorea.bin ..\obj\
copy /y memcoreb.bin ..\obj\
copy /y mem4x4x4lod1.bin ..\obj\
copy /y mem4x4x4lod2.bin ..\obj\
copy /y memcore.png ..\obj\txt16
copy /y memcorelod2a.png ..\obj\txt16
copy /y memcorelod2b.png ..\obj\txt16
copy /y memcorelod2c.png ..\obj\txt16
