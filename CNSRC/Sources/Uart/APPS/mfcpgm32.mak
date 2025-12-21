#
# Microsoft makefile for mfc_pgm [Win32]
# Requires WSC32.DLL & WSC32.LIB
#
# To use: "nmake mfcpgm32.mak"
#
# File nafxcw.lib may have to be copied from MFC\LIB on your
# Microsoft Visual C/C++ compiler CD.

CCFLAGS = /GX /c /W3 /Od /Gy /MT /D_MBCS /D_X86
MAKPCH = /Ycstdafx.h /Fp.\stdafx.pch /Fo.\stdafx.obj
USEPCH = /Yustdafx.h /Fp.\stdafx.pch

mfc_pgm.exe: stdafx.obj mfc_pgm.res mfc_pgm.obj mfc_pgm.def wsc32.lib
    link /subsystem:windows /out:mfc_pgm.exe mfc_pgm stdafx wsc32.lib mfc_pgm.res

mfc_pgm.res: mfc_pgm.rc
    rc -dWIN32 mfc_pgm.rc

stdafx.obj: stdafx.cpp stdafx.h wsc.h
   cl $(CCFLAGS) $(MAKPCH) stdafx.cpp

mfc_pgm.obj: mfc_pgm.cpp mfc_pgm.h wsc.h
   cl $(CCFLAGS) $(USEPCH) mfc_pgm.cpp

