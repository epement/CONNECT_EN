# Microsoft Developer Studio Generated NMAKE File, Based on recycle.dsp
!IF "$(CFG)" == ""
CFG=recycle - Win32 Debug
!MESSAGE No configuration specified. Defaulting to recycle - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "recycle - Win32 Release" && "$(CFG)" != "recycle - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "recycle.mak" CFG="recycle - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "recycle - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "recycle - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 

!IF  "$(CFG)" == "recycle - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release
# Begin Custom Macros
OutDir=.\Release
# End Custom Macros

ALL : "$(OUTDIR)\recycle.exe"


CLEAN :
	-@erase "$(INTDIR)\RecycFile.obj"
	-@erase "$(INTDIR)\recycle.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(OUTDIR)\recycle.exe"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP=cl.exe
CPP_PROJ=/nologo /MD /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_recycle" /D "_MBCS" /D "_AFXDLL" /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c 

.c{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

RSC=rc.exe
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\recycle.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=setargv.obj kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /incremental:no /pdb:"$(OUTDIR)\recycle.pdb" /machine:I386 /out:"$(OUTDIR)\recycle.exe" 
LINK32_OBJS= \
	"$(INTDIR)\RecycFile.obj" \
	"$(INTDIR)\recycle.obj"

"$(OUTDIR)\recycle.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "recycle - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug
# Begin Custom Macros
OutDir=.\Debug
# End Custom Macros

ALL : "$(OUTDIR)\recycle.exe"


CLEAN :
	-@erase "$(INTDIR)\RecycFile.obj"
	-@erase "$(INTDIR)\recycle.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vc60.pdb"
	-@erase "$(OUTDIR)\recycle.exe"
	-@erase "$(OUTDIR)\recycle.ilk"
	-@erase "$(OUTDIR)\recycle.pdb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP=cl.exe
CPP_PROJ=/nologo /MDd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_recycle" /D "_MBCS" /D "_AFXDLL" /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c 

.c{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

RSC=rc.exe
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\recycle.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=setargv.obj kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /incremental:yes /pdb:"$(OUTDIR)\recycle.pdb" /debug /machine:I386 /out:"$(OUTDIR)\recycle.exe" /pdbtype:sept 
LINK32_OBJS= \
	"$(INTDIR)\RecycFile.obj" \
	"$(INTDIR)\recycle.obj"

"$(OUTDIR)\recycle.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ENDIF 


!IF "$(NO_EXTERNAL_DEPS)" != "1"
!IF EXISTS("recycle.dep")
!INCLUDE "recycle.dep"
!ELSE 
!MESSAGE Warning: cannot find "recycle.dep"
!ENDIF 
!ENDIF 


!IF "$(CFG)" == "recycle - Win32 Release" || "$(CFG)" == "recycle - Win32 Debug"
SOURCE=.\RecycFile.cpp

"$(INTDIR)\RecycFile.obj" : $(SOURCE) "$(INTDIR)" 


SOURCE=.\recycle.cpp

"$(INTDIR)\recycle.obj" : $(SOURCE) "$(INTDIR)" 



!ENDIF 

