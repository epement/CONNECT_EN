# Microsoft Developer Studio Generated NMAKE File, Format Version 4.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

!IF "$(CFG)" == ""
CFG=term - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to term - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "term - Win32 Release" && "$(CFG)" != "term - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "term.mak" CFG="term - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "term - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "term - Win32 Debug" (based on "Win32 (x86) Application")
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

!IF  "$(CFG)" == "term - Win32 Release"

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

ALL : "$(OUTDIR)\term.exe"

CLEAN : 
	-@erase ".\Release\term.exe"
	-@erase ".\Release\Term.obj"
	-@erase ".\Release\About.obj"
	-@erase ".\Release\Accept.obj"
	-@erase ".\Release\Ansi.obj"
	-@erase ".\Release\Config.obj"
	-@erase ".\Release\Line.obj"
	-@erase ".\Release\Menu.obj"
	-@erase ".\Release\Paint.obj"
	-@erase ".\Release\Progress.obj"
	-@erase ".\Release\Sioerror.obj"
	-@erase ".\Release\Asdrv.obj"
	-@erase ".\Release\Term.res"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /ML /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/term.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /win32
MTL_PROJ=/nologo /D "NDEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/Term.res" /d "NDEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/term.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /incremental:no /pdb:"$(OUTDIR)/term.pdb" /machine:I386\
 /out:"$(OUTDIR)/term.exe" 
LINK32_OBJS= \
	"$(INTDIR)/Term.obj" \
	"$(INTDIR)/About.obj" \
	"$(INTDIR)/Accept.obj" \
	"$(INTDIR)/Ansi.obj" \
	"$(INTDIR)/Config.obj" \
	"$(INTDIR)/Line.obj" \
	"$(INTDIR)/Menu.obj" \
	"$(INTDIR)/Paint.obj" \
	"$(INTDIR)/Progress.obj" \
	"$(INTDIR)/Sioerror.obj" \
	"$(INTDIR)/Asdrv.obj" \
	"$(INTDIR)/Term.res" \
	".\wsc32.lib" \
	".\mio32.lib" \
	".\xym32.lib"

"$(OUTDIR)\term.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "term - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "term___W"
# PROP BASE Intermediate_Dir "term___W"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "term___W"
# PROP Intermediate_Dir "term___W"
# PROP Target_Dir ""
OUTDIR=.\term___W
INTDIR=.\term___W

ALL : "$(OUTDIR)\term.exe"

CLEAN : 
	-@erase ".\term___W\term.exe"
	-@erase ".\term___W\Term.obj"
	-@erase ".\term___W\About.obj"
	-@erase ".\term___W\Accept.obj"
	-@erase ".\term___W\Ansi.obj"
	-@erase ".\term___W\Config.obj"
	-@erase ".\term___W\Line.obj"
	-@erase ".\term___W\Menu.obj"
	-@erase ".\term___W\Paint.obj"
	-@erase ".\term___W\Progress.obj"
	-@erase ".\term___W\Sioerror.obj"
	-@erase ".\term___W\Asdrv.obj"
	-@erase ".\term___W\Term.res"
	-@erase ".\term___W\term.ilk"
	-@erase ".\term___W\term.pdb"
	-@erase ".\term___W\vc40.pdb"
	-@erase ".\term___W\vc40.idb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /MLd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/term.pch" /YX /Fo"$(INTDIR)/" /Fd"$(INTDIR)/" /c 
CPP_OBJS=.\term___W/
CPP_SBRS=
# ADD BASE MTL /nologo /D "_DEBUG" /win32
# ADD MTL /nologo /D "_DEBUG" /win32
MTL_PROJ=/nologo /D "_DEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/Term.res" /d "_DEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/term.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /debug /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /debug /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /incremental:yes /pdb:"$(OUTDIR)/term.pdb" /debug\
 /machine:I386 /out:"$(OUTDIR)/term.exe" 
LINK32_OBJS= \
	"$(INTDIR)/Term.obj" \
	"$(INTDIR)/About.obj" \
	"$(INTDIR)/Accept.obj" \
	"$(INTDIR)/Ansi.obj" \
	"$(INTDIR)/Config.obj" \
	"$(INTDIR)/Line.obj" \
	"$(INTDIR)/Menu.obj" \
	"$(INTDIR)/Paint.obj" \
	"$(INTDIR)/Progress.obj" \
	"$(INTDIR)/Sioerror.obj" \
	"$(INTDIR)/Asdrv.obj" \
	"$(INTDIR)/Term.res" \
	".\wsc32.lib" \
	".\mio32.lib" \
	".\xym32.lib"

"$(OUTDIR)\term.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
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

# Name "term - Win32 Release"
# Name "term - Win32 Debug"

!IF  "$(CFG)" == "term - Win32 Release"

!ELSEIF  "$(CFG)" == "term - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=.\Term.c
DEP_CPP_TERM_=\
	".\wsc.h"\
	".\mio.h"\
	".\xym.h"\
	".\term.h"\
	".\message.h"\
	".\ascii.h"\
	".\config.h"\
	".\paint.h"\
	".\line.h"\
	".\menu.h"\
	".\about.h"\
	".\sioerror.h"\
	".\accept.h"\
	".\ansi.h"\
	".\asdrv.h"\
	".\progress.h"\
	

"$(INTDIR)\Term.obj" : $(SOURCE) $(DEP_CPP_TERM_) "$(INTDIR)"


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

SOURCE=.\Accept.c
DEP_CPP_ACCEP=\
	".\accept.h"\
	

"$(INTDIR)\Accept.obj" : $(SOURCE) $(DEP_CPP_ACCEP) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\Ansi.c
DEP_CPP_ANSI_=\
	".\paint.h"\
	".\ascii.h"\
	".\wsc.h"\
	

"$(INTDIR)\Ansi.obj" : $(SOURCE) $(DEP_CPP_ANSI_) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\Config.c
DEP_CPP_CONFI=\
	".\config.h"\
	".\wsc.h"\
	".\menu.h"\
	".\message.h"\
	".\sioerror.h"\
	

"$(INTDIR)\Config.obj" : $(SOURCE) $(DEP_CPP_CONFI) "$(INTDIR)"


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

SOURCE=.\Menu.c
DEP_CPP_MENU_=\
	".\wsc.h"\
	".\menu.h"\
	

"$(INTDIR)\Menu.obj" : $(SOURCE) $(DEP_CPP_MENU_) "$(INTDIR)"


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

SOURCE=.\Progress.c
DEP_CPP_PROGR=\
	".\progress.h"\
	

"$(INTDIR)\Progress.obj" : $(SOURCE) $(DEP_CPP_PROGR) "$(INTDIR)"


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

SOURCE=.\wsc32.lib

!IF  "$(CFG)" == "term - Win32 Release"

!ELSEIF  "$(CFG)" == "term - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\mio32.lib

!IF  "$(CFG)" == "term - Win32 Release"

!ELSEIF  "$(CFG)" == "term - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\xym32.lib

!IF  "$(CFG)" == "term - Win32 Release"

!ELSEIF  "$(CFG)" == "term - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\Asdrv.c
DEP_CPP_ASDRV=\
	".\wsc.h"\
	".\ascodes.h"\
	".\ascii.h"\
	".\asdrv.h"\
	".\paint.h"\
	

"$(INTDIR)\Asdrv.obj" : $(SOURCE) $(DEP_CPP_ASDRV) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\Term.rc
DEP_RSC_TERM_R=\
	".\msc.ico"\
	".\message.h"\
	".\accept.h"\
	

"$(INTDIR)\Term.res" : $(SOURCE) $(DEP_RSC_TERM_R) "$(INTDIR)"
   $(RSC) $(RSC_PROJ) $(SOURCE)


# End Source File
# End Target
# End Project
################################################################################
