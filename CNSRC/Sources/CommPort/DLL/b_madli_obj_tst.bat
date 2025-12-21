echo madli_obj_tst.c > err

bcc32.EXE -c -WC madli_obj_tst.c >> err

brcc32 -ic:\borland\bcc55\include madli_obj_tst.rc >> err

ilink32 /Tpe /ap /Gi /GD /c /Gn c0x32.obj madli_obj_tst.obj, madli_obj_tst.exe,, madli.lib import32.lib cw32.lib user32.lib winmm.lib, ,  >> err

type err


