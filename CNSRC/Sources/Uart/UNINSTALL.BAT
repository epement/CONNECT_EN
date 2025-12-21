@echo off
REM
REM un-install script for WSC4C.
REM
if (%windir%) == () goto WIN31

if not exist %windir%\WSC16.DLL goto TEST2
echo Delete %windir%\WSC16.DLL MIO16.DLL XYM16.DLL ASD16.DLL ?
pause
del %windir%\WSC16.DLL
del %windir%\MIO16.DLL
del %windir%\XYM16.DLL
del %windir%\ASD16.DLL

:TEST2
if not exist %windir%\WSC32.DLL goto DONE
echo Delete %windir%\WSC32.DLL MIO32.DLL XYM32.DLL ASD32.DLL ?
pause
del %windir%\WSC32.DLL
del %windir%\MIO32.DLL
del %windir%\XYM32.DLL
del %windir%\ASD32.DLL
goto DONE

:WIN31

if not exist C:\WINDOWS\WSC16.DLL goto TEST4
echo Delete C:\WINDOWS\WSC16.DLL MIO16.DLL XYM16.DLL ASD16.DLL ?
pause
del C:\WINDOWS\WSC16.DLL
del C:\WINDOWS\MIO16.DLL
del C:\WINDOWS\XYM16.DLL
del C:\WINDOWS\ASD16.DLL

:TEST4
if not exist C:\WINDOWS\WSC32.DLL goto DONE
echo Delete C:\WINDOWS\WSC32.DLL MIO32.DLL XYM32.DLL ASD32.DLL ?
pause
del C:\WINDOWS\WSC32.DLL
del C:\WINDOWS\MIO32.DLL
del C:\WINDOWS\XYM32.DLL
del C:\WINDOWS\ASD32.DLL

:DONE


