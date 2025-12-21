# Microsoft Developer Studio Generated NMAKE File, Format Version 4.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

!IF "$(CFG)" == ""
CFG=simple - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to simple - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "simple - Win32 Release" && "$(CFG)" != "simple - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "simple.mak" CFG="simple - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "simple - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "simple - Win32 Debug" (based on "Win32 (x86) Application")
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
MTL=mktyplib.exe
CPP=cl.exe

!IF  "$(CFG)" == "simple - Win32 Release"

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

ALL : "$(OUTDIR)\simple.exe"

CLEAN : 
        -@erase ".\Release\simple.exe"
        -@erase ".\Release\Sioerror.obj"
        -@erase ".\Release\Line.obj"
        -@erase ".\Release\Paint.obj"
        -@erase ".\Release\Simple.obj"
        -@erase ".\Release\About.obj"
        -@erase ".\Release\Simple.res"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /ML /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/simple.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /win32
MTL_PROJ=/nologo /D "NDEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/Simple.res" /d "NDEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/simple.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /incremental:no /pdb:"$(OUTDIR)/simple.pdb" /machine:I386\
 /out:"$(OUTDIR)/simple.exe" 
LINK32_OBJS= \
        "$(INTDIR)/Sioerror.obj" \
        "$(INTDIR)/Line.obj" \
        "$(INTDIR)/Paint.obj" \
        "$(INTDIR)/Simple.obj" \
        "$(INTDIR)/About.obj" \
        "$(INTDIR)/Simple.res" \
        ".\wsc32.lib"

"$(OUTDIR)\simple.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "simple - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "$(OUTDIR)\simple.exe"

CLEAN : 
        -@erase ".\Debug\simple.exe"
        -@erase ".\Debug\Sioerror.obj"
        -@erase ".\Debug\Line.obj"
        -@erase ".\Debug\Paint.obj"
        -@erase ".\Debug\Simple.obj"
        -@erase ".\Debug\About.obj"
        -@erase ".\Debug\Simple.res"
        -@erase ".\Debug\simple.ilk"
        -@erase ".\Debug\simple.pdb"
        -@erase ".\Debug\vc40.pdb"
        -@erase ".\Debug\vc40.idb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /MLd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/simple.pch" /YX /Fo"$(INTDIR)/" /Fd"$(INTDIR)/" /c 
CPP_OBJS=.\Debug/
CPP_SBRS=
# ADD BASE MTL /nologo /D "_DEBUG" /win32
# ADD MTL /nologo /D "_DEBUG" /win32
MTL_PROJ=/nologo /D "_DEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/Simple.res" /d "_DEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/simple.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /debug /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /debug /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /incremental:yes /pdb:"$(OUTDIR)/simple.pdb" /debug\
 /machine:I386 /out:"$(OUTDIR)/simple.exe" 
LINK32_OBJS= \
        "$(INTDIR)/Sioerror.obj" \
        "$(INTDIR)/Line.obj" \
        "$(INTDIR)/Paint.obj" \
        "$(INTDIR)/Simple.obj" \
        "$(INTDIR)/About.obj" \
        "$(INTDIR)/Simple.res" \
        ".\wsc32.lib"

"$(OUTDIR)\simple.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
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

# Name "simple - Win32 Release"
# Name "simple - Win32 Debug"

!IF  "$(CFG)" == "simple - Win32 Release"

!ELSEIF  "$(CFG)" == "simple - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=.\wsc32.lib

!IF  "$(CFG)" == "simple - Win32 Release"

!ELSEIF  "$(CFG)" == "simple - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\Sioerror.c
DEP_CPP_SIOER=\
        ".\sioerror.h"\
        ".\wsc.h"\
        ".\paint.h"\
        

"$(INTDIR)\Sioerror.obj" : $(SOURCE) $(DEP_CPP_SIOER) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\Line.c
DEP_CPP_LINE_=\
        ".\wsc.h"\
        ".\line.h"\
        ".\sioerror.h"\
        ".\paint.h"\
        

"$(INTDIR)\Line.obj" : $(SOURCE) $(DEP_CPP_LINE_) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\Paint.c
DEP_CPP_PAINT=\
        ".\paint.h"\
        ".\ascii.h"\
        

"$(INTDIR)\Paint.obj" : $(SOURCE) $(DEP_CPP_PAINT) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\Simple.c
DEP_CPP_SIMPL=\
        ".\simple.h"\
        ".\wsc.h"\
        ".\sioerror.h"\
        ".\ascii.h"\
        ".\message.h"\
        ".\line.h"\
        ".\paint.h"\
        ".\about.h"\
        

"$(INTDIR)\Simple.obj" : $(SOURCE) $(DEP_CPP_SIMPL) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\About.c
DEP_CPP_ABOUT=\
        ".\about.h"\
        

"$(INTDIR)\About.obj" : $(SOURCE) $(DEP_CPP_ABOUT) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\Simple.rc
DEP_RSC_SIMPLE=\
        ".\msc.ico"\
        ".\message.h"\
        

"$(INTDIR)\Simple.res" : $(SOURCE) $(DEP_RSC_SIMPLE) "$(INTDIR)"
   $(RSC) $(RSC_PROJ) $(SOURCE)


# End Source File
# End Target
# End Project
################################################################################
