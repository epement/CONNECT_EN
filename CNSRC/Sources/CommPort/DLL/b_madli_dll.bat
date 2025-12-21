echo madli.dll > err

bcc32 -c -WD -D_MADLI_DLL_ madli.c >> err

brcc32 -ic:\borland\bcc55\include madli.rc >> err

implib -c -f winmm.lib %systemroot%\system32\winmm.dll

ilink32 /Tpd /ap /Gi /GD /c /Gn c0d32.obj madli.obj, madli.dll, , import32.lib cw32mt.lib  user32.lib winmm.lib, ,madli >> err

type err
