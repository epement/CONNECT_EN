# makefile for cn.exe
.asm.obj:
    tasm /zi/z/m4/t/dCN $<

cn.exe : executes.exe snipp.bin
 copy /b executes.exe + snipp.bin cn.exe

snipp.bin : snipp.obj
    tlink /t snipp.obj,snipp.bin

executes.exe : executes.obj exec.obj envstr.obj dosfuncs.obj \
snipldex.obj umbsnip.obj posstr.obj buffsize.obj snipp.bin

    tlink /m/s/v  executes.obj umbsnip.obj exec.obj envstr.obj \
dosfuncs.obj snipldex.obj posstr.obj buffsize.obj
    tdstrip -s executes.exe

executes.obj : executes.asm repeats.mac strucs.mac exchtype.inc
exec.obj     : exec.asm     repeats.mac strucs.mac
envstr.obj   : envstr.asm   repeats.mac strucs.mac
dosfuncs.obj : dosfuncs.asm repeats.mac strucs.mac
snipldex.obj : snipldex.asm repeats.mac strucs.mac
umbsnip.obj  : umbsnip.asm  repeats.mac strucs.mac exchtype.inc
snipp.obj    : snipp.asm    repeats.mac strucs.mac int1.mac
posstr.obj   : posstr.asm   repeats.mac strucs.mac
buffsize.obj : buffsize.asm repeats.mac strucs.mac