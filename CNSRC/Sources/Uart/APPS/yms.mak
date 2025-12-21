# Microsoft Developer Studio Generated NMAKE File, Format Version 4.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

!IF "$(CFG)" == ""
CFG=yms - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to yms - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "yms - Win32 Release" && "$(CFG)" != "yms - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "yms.mak" CFG="yms - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "yms - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "yms - Win32 Debug" (based on "Win32 (x86) Console Application")
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
RSC=rc.exe
CPP=cl.exe

!IF  "$(CFG)" == "yms - Win32 Release"

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

ALL : "$(OUTDIR)\yms.exe"

CLEAN : 
	-@erase ".\Release\yms.exe"
	-@erase ".\Release\yms.obj"
	-@erase ".\Release\sayerror.obj"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /YX /c
# ADD CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /YX /c
CPP_PROJ=/nologo /ML /W3 /GX /D "WIN32" /D "NDEBUG" /D "_CONSOLE"\
 /Fp"$(INTDIR)/yms.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/yms.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:console /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:console /incremental:no /pdb:"$(OUTDIR)/yms.pdb" /machine:I386\
 /out:"$(OUTDIR)/yms.exe" 
LINK32_OBJS= \
	"$(INTDIR)/yms.obj" \
	"$(INTDIR)/sayerror.obj" \
	".\xym32.lib" \
	".\wsc32.lib"

"$(OUTDIR)\yms.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "yms - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "yms___Wi"
# PROP BASE Intermediate_Dir "yms___Wi"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "yms___Wi"
# PROP Intermediate_Dir "yms___Wi"
# PROP Target_Dir ""
OUTDIR=.\yms___Wi
INTDIR=.\yms___Wi

ALL : "$(OUTDIR)\yms.exe"

CLEAN : 
	-@erase ".\yms___Wi\yms.exe"
	-@erase ".\yms___Wi\yms.obj"
	-@erase ".\yms___Wi\sayerror.obj"
	-@erase ".\yms___Wi\yms.ilk"
	-@erase ".\yms___Wi\yms.pdb"
	-@erase ".\yms___Wi\vc40.pdb"
	-@erase ".\yms___Wi\vc40.idb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /YX /c
# ADD CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /YX /c
CPP_PROJ=/nologo /MLd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE"\
 /Fp"$(INTDIR)/yms.pch" /YX /Fo"$(INTDIR)/" /Fd"$(INTDIR)/" /c 
CPP_OBJS=.\yms___Wi/
CPP_SBRS=
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/yms.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:console /debug /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:console /debug /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:console /incremental:yes /pdb:"$(OUTDIR)/yms.pdb" /debug\
 /machine:I386 /out:"$(OUTDIR)/yms.exe" 
LINK32_OBJS= \
	"$(INTDIR)/yms.obj" \
	"$(INTDIR)/sayerror.obj" \
	".\xym32.lib" \
	".\wsc32.lib"

"$(OUTDIR)\yms.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
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

# Name "yms - Win32 Release"
# Name "yms - Win32 Debug"

!IF  "$(CFG)" == "yms - Win32 Release"

!ELSEIF  "$(CFG)" == "yms - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=.\yms.c
DEP_CPP_YMS_C=\
	".\wsc.h"\
	".\xym.h"\
	".\sayerror.h"\
	

"$(INTDIR)\yms.obj" : $(SOURCE) $(DEP_CPP_YMS_C) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\sayerror.C
DEP_CPP_SAYER=\
	".\sayerror.h"\
	".\wsc.h"\
	

"$(INTDIR)\sayerror.obj" : $(SOURCE) $(DEP_CPP_SAYER) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\xym32.lib

!IF  "$(CFG)" == "yms - Win32 Release"

!ELSEIF  "$(CFG)" == "yms - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\wsc32.lib

!IF  "$(CFG)" == "yms - Win32 Release"

!ELSEIF  "$(CFG)" == "yms - Win32 Debug"

!ENDIF 

# End Source File
# End Target
# End Project
################################################################################
