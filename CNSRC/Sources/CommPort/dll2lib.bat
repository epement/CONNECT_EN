
::implib -c -f ntvdm.lib %systemroot%\system32\ntvdm.exe
::implib -c -f shellapi.lib %systemroot%\system32\shell.dll
::implib -c -f Advapi32.lib %systemroot%\system32\Advapi32.dll
::implib -c -f winmm.lib %systemroot%\system32\winmm.dll
implib -c -f hid.lib %systemroot%\system32\hid.dll
implib -c -f setupapi.lib %systemroot%\system32\setupapi.dll


