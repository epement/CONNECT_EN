echo cn_nt.dll > err

bcc32 -c -WD cn_nt.c >> err
bcc32 -c -WD ntvdm.c >> err
bcc32 -c -WD exec.c >> err
bcc32 -c -WD recycle.c >> err
bcc32 -c -WD sysinfo.c >> err
bcc32 -c -WD ExAttr.c >> err

brcc32 -ic:\borland\bcc55\include cn_nt.rc >> err

implib -c -f ntvdm.lib %systemroot%\system32\ntvdm.exe
::implib -c -f shellapi.lib %systemroot%\system32\shell.dll

ilink32 /Tpd /ap /Gi /GD /c /Gn c0d32.obj cn_nt.obj exec.obj sysinfo.obj ExAttr.obj ntvdm.obj recycle.obj, cn_nt.dll,,import32.lib cw32mt.lib ntvdm.lib user32.lib,,cn_nt >> err

type err
