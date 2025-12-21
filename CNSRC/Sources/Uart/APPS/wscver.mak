# Microsoft Developer Studio Generated NMAKE File, Format Version 4.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

!IF "$(CFG)" == ""
CFG=wscver - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to wscver - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "wscver - Win32 Release" && "$(CFG)" != "wscver - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "wscver.mak" CFG="wscver - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "wscver - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "wscver - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 
################################################################################
# Begin Project
MTL=mktyplib.exe
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "wscver - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
OUTDIR=.\Release
INTDIR=.\Release

ALL : "$(OUTDIR)\wscver.exe"

CLEAN : 
	-@erase ".\Release\wscver.exe"
	-@erase ".\Release\wscver.obj"
	-@erase ".\Release\paint.obj"
	-@erase ".\Release\wscver.res"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /ML /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/wscver.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /win32
MTL_PROJ=/nologo /D "NDEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/wscver.res" /d "NDEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/wscver.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /incremental:no /pdb:"$(OUTDIR)/wscver.pdb" /machine:I386\
 /out:"$(OUTDIR)/wscver.exe" 
LINK32_OBJS= \
	"$(INTDIR)/wscver.obj" \
	"$(INTDIR)/paint.obj" \
	"$(INTDIR)/wscver.res" \
	".\wsc32.lib"

"$(OUTDIR)\wscver.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "wscver - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "wscver__"
# PROP BASE Intermediate_Dir "wscver__"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "wscver__"
# PROP Intermediate_Dir "wscver__"
# PROP Target_Dir ""
OUTDIR=.\wscver__
INTDIR=.\wscver__

ALL : "$(OUTDIR)\wscver.exe"

CLEAN : 
	-@erase ".\wscver__\wscver.exe"
	-@erase ".\wscver__\wscver.obj"
	-@erase ".\wscver__\paint.obj"
	-@erase ".\wscver__\wscver.res"
	-@erase ".\wscver__\wscver.ilk"
	-@erase ".\wscver__\wscver.pdb"
	-@erase ".\wscver__\vc40.pdb"
	-@erase ".\wscver__\vc40.idb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /MLd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/wscver.pch" /YX /Fo"$(INTDIR)/" /Fd"$(INTDIR)/" /c 
CPP_OBJS=.\wscver__/
CPP_SBRS=
# ADD BASE MTL /nologo /D "_DEBUG" /win32
# ADD MTL /nologo /D "_DEBUG" /win32
MTL_PROJ=/nologo /D "_DEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/wscver.res" /d "_DEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/wscver.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /debug /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /debug /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /incremental:yes /pdb:"$(OUTDIR)/wscver.pdb" /debug\
 /machine:I386 /out:"$(OUTDIR)/wscver.exe" 
LINK32_OBJS= \
	"$(INTDIR)/wscver.obj" \
	"$(INTDIR)/paint.obj" \
	"$(INTDIR)/wscver.res" \
	".\wsc32.lib"

"$(OUTDIR)\wscver.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ENDIF 

.c{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.c{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

################################################################################
# Begin Target

# Name "wscver - Win32 Release"
# Name "wscver - Win32 Debug"

!IF  "$(CFG)" == "wscver - Win32 Release"

!ELSEIF  "$(CFG)" == "wscver - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=.\wscver.c
DEP_CPP_WSCVE=\
	".\wscver.h"\
	".\wsc.h"\
	".\message.h"\
	".\paint.h"\
	

"$(INTDIR)\wscver.obj" : $(SOURCE) $(DEP_CPP_WSCVE) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\paint.c
DEP_CPP_PAINT=\
	".\paint.h"\
	".\ascii.h"\
	

"$(INTDIR)\paint.obj" : $(SOURCE) $(DEP_CPP_PAINT) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\wscver.rc
DEP_RSC_WSCVER=\
	".\msc.ico"\
	".\message.h"\
	

"$(INTDIR)\wscver.res" : $(SOURCE) $(DEP_RSC_WSCVER) "$(INTDIR)"
   $(RSC) $(RSC_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=.\wsc32.lib

!IF  "$(CFG)" == "wscver - Win32 Release"

!ELSEIF  "$(CFG)" == "wscver - Win32 Debug"

!ENDIF 

# End Source File
# End Target
# End Project
################################################################################
