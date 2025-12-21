echo m.dll > err

bcc32 -c -WD cn_nt.c >> err
bcc32 -c -WD ntvdm.c >> err
bcc32 -c -WD exec.c >> err
bcc32 -c -WD recycle.c >> err
bcc32 -c -WD sysinfo.c >> err
bcc32 -c -WD ExAttr.c >> err
bcc32 -c -WD comm.c >> err

brcc32 -ic:\borland\bcc55\include cn_nt.rc >> err

implib -c -f ntvdm.lib %systemroot%\system32\ntvdm.exe
implib -c -f shellapi.lib %systemroot%\system32\shell.dll
implib -c -f Advapi32.lib %systemroot%\system32\Advapi32.dll
implib -c -f winmm.lib %systemroot%\system32\winmm.dll

ilink32 /Tpd /ap /Gi /GD /c /Gn c0d32.obj cn_nt.obj exec.obj sysinfo.obj ExAttr.obj ntvdm.obj recycle.obj comm.obj, cn_nt.dll,,import32.lib cw32mt.lib ntvdm.lib shellapi.lib Advapi32.lib user32.lib winmm.lib,,cn_nt >> err

type err
