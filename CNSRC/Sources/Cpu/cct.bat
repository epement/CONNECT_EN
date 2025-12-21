implib -c -f winmm.lib %systemroot%\system32\winmm.dll
bcc32.EXE  -WC timeBP.c winmm.lib