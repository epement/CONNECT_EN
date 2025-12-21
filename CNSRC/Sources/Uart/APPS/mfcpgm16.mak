#
# Makefile for MFC example program MFC_PGM
#
# To make, type: NMAKE -f MFCPGM16.MAK
#
# File nafxcw.lib may have to be copied from MFC\LIB on your
# Microsoft Visual C/C++ compiler CD.

MAKPCH = /YcSTDAFX.H
USEPCH = /YuSTDAFX.H
FIRSTCPP = STDAFX.CPP
CFLAGS = /nologo /W3 /AM /O1 /D "NDEBUG" /FR /GA
LFLAGS = /NOLOGO /NOD /PACKC:61440 /STACK:10240 /ALIGN:16 /ONERROR:NOEXE
LIBS = mafxcw oldnames libw mlibcew commdlg.lib shell.lib wsc16.lib
RESFLAGS = /nologo
DEFFILE = MFC_PGM.DEF
MAPFILE = MFC_PGM.MAP
RCFLAGS = /nologo
RCDEFINES = -dNDEBUG
!if [if exist MSVC.BND del MSVC.BND]
!endif
SBRS = STDAFX.SBR MFC_PGM.SBR

all:    MFC_PGM.EXE MFC_PGM.BSC MFCPGM16.MAK

STDAFX.OBJ: STDAFX.CPP $(STDAFX_DEP)
    cl $(CFLAGS) $(MAKPCH) /c STDAFX.CPP

MFC_PGM.OBJ:    MFC_PGM.CPP $(MFC_PGM_DEP)
    cl $(CFLAGS) $(USEPCH) /c MFC_PGM.CPP

MFC_PGM.RES:    MFC_PGM.RC $(MFC_PGM_RCDEP)
    rc $(RCFLAGS) $(RCDEFINES) -r MFC_PGM.RC

MFC_PGM.EXE::   MFC_PGM.RES

MFC_PGM.EXE::   STDAFX.OBJ MFC_PGM.OBJ $(DEFFILE)
    echo >NUL @<<MFC_PGM.CRF
STDAFX.OBJ MFC_PGM.OBJ
MFC_PGM.EXE
MFC_PGM.MAP
$(LIBS)
MFC_PGM.DEF;
<<
    link $(LFLAGS) @MFC_PGM.CRF
    rc $(RESFLAGS) MFC_PGM.RES $@
    @copy MFC_PGM.CRF MSVC.BND

MFC_PGM.EXE:: MFC_PGM.RES
    if not exist MSVC.BND   rc $(RESFLAGS) MFC_PGM.RES $@

MFC_PGM.BSC: $(SBRS)
    bscmake @<<
/o$@ $(SBRS)
<<
