# Microsoft Developer Studio Generated NMAKE File, Format Version 4.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

!IF "$(CFG)" == ""
CFG=modem - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to modem - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "modem - Win32 Release" && "$(CFG)" != "modem - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "modem.mak" CFG="modem - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "modem - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "modem - Win32 Debug" (based on "Win32 (x86) Application")
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
# PROP Target_Last_Scanned "modem - Win32 Debug"
RSC=rc.exe
MTL=mktyplib.exe
CPP=cl.exe

!IF  "$(CFG)" == "modem - Win32 Release"

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

ALL : "$(OUTDIR)\modem.exe"

CLEAN : 
	-@erase ".\Release\modem.exe"
	-@erase ".\Release\sioerror.obj"
	-@erase ".\Release\menu.obj"
	-@erase ".\Release\about.obj"
	-@erase ".\Release\modem.obj"
	-@erase ".\Release\paint.obj"
	-@erase ".\Release\config.obj"
	-@erase ".\Release\line.obj"
	-@erase ".\Release\modem.res"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /ML /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/modem.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /win32
MTL_PROJ=/nologo /D "NDEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/modem.res" /d "NDEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/modem.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /incremental:no /pdb:"$(OUTDIR)/modem.pdb" /machine:I386\
 /out:"$(OUTDIR)/modem.exe" 
LINK32_OBJS= \
	"$(INTDIR)/sioerror.obj" \
	"$(INTDIR)/menu.obj" \
	"$(INTDIR)/about.obj" \
	"$(INTDIR)/modem.obj" \
	"$(INTDIR)/paint.obj" \
	"$(INTDIR)/config.obj" \
	"$(INTDIR)/line.obj" \
	"$(INTDIR)/modem.res" \
	".\wsc32.lib"

"$(OUTDIR)\modem.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "modem - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "modem___"
# PROP BASE Intermediate_Dir "modem___"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "modem___"
# PROP Intermediate_Dir "modem___"
# PROP Target_Dir ""
OUTDIR=.\modem___
INTDIR=.\modem___

ALL : "$(OUTDIR)\modem.exe"

CLEAN : 
	-@erase ".\modem___\vc40.pdb"
	-@erase ".\modem___\vc40.idb"
	-@erase ".\modem___\modem.exe"
	-@erase ".\modem___\config.obj"
	-@erase ".\modem___\about.obj"
	-@erase ".\modem___\modem.obj"
	-@erase ".\modem___\paint.obj"
	-@erase ".\modem___\sioerror.obj"
	-@erase ".\modem___\line.obj"
	-@erase ".\modem___\menu.obj"
	-@erase ".\modem___\modem.res"
	-@erase ".\modem___\modem.ilk"
	-@erase ".\modem___\modem.pdb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /MLd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/modem.pch" /YX /Fo"$(INTDIR)/" /Fd"$(INTDIR)/" /c 
CPP_OBJS=.\modem___/
CPP_SBRS=
# ADD BASE MTL /nologo /D "_DEBUG" /win32
# ADD MTL /nologo /D "_DEBUG" /win32
MTL_PROJ=/nologo /D "_DEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/modem.res" /d "_DEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/modem.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /debug /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /debug /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /incremental:yes /pdb:"$(OUTDIR)/modem.pdb" /debug\
 /machine:I386 /out:"$(OUTDIR)/modem.exe" 
LINK32_OBJS= \
	"$(INTDIR)/config.obj" \
	"$(INTDIR)/about.obj" \
	"$(INTDIR)/modem.obj" \
	"$(INTDIR)/paint.obj" \
	"$(INTDIR)/sioerror.obj" \
	"$(INTDIR)/line.obj" \
	"$(INTDIR)/menu.obj" \
	"$(INTDIR)/modem.res" \
	".\wsc32.lib"

"$(OUTDIR)\modem.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
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

# Name "modem - Win32 Release"
# Name "modem - Win32 Debug"

!IF  "$(CFG)" == "modem - Win32 Release"

!ELSEIF  "$(CFG)" == "modem - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=.\modem.c
DEP_CPP_MODEM=\
	".\modem.h"\
	".\message.h"\
	".\wsc.h"\
	".\keycode.h"\
	".\ascii.h"\
	".\config.h"\
	".\paint.h"\
	".\line.h"\
	".\menu.h"\
	".\about.h"\
	".\sioerror.h"\
	

"$(INTDIR)\modem.obj" : $(SOURCE) $(DEP_CPP_MODEM) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\about.c
DEP_CPP_ABOUT=\
	".\about.h"\
	

"$(INTDIR)\about.obj" : $(SOURCE) $(DEP_CPP_ABOUT) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\config.c
DEP_CPP_CONFI=\
	".\config.h"\
	".\wsc.h"\
	".\menu.h"\
	".\message.h"\
	".\sioerror.h"\
	

"$(INTDIR)\config.obj" : $(SOURCE) $(DEP_CPP_CONFI) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\line.c
DEP_CPP_LINE_=\
	".\wsc.h"\
	".\line.h"\
	".\sioerror.h"\
	".\paint.h"\
	

"$(INTDIR)\line.obj" : $(SOURCE) $(DEP_CPP_LINE_) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\menu.c
DEP_CPP_MENU_=\
	".\wsc.h"\
	".\menu.h"\
	

"$(INTDIR)\menu.obj" : $(SOURCE) $(DEP_CPP_MENU_) "$(INTDIR)"


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

SOURCE=.\sioerror.c
DEP_CPP_SIOER=\
	".\sioerror.h"\
	".\wsc.h"\
	".\paint.h"\
	

"$(INTDIR)\sioerror.obj" : $(SOURCE) $(DEP_CPP_SIOER) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\wsc32.lib

!IF  "$(CFG)" == "modem - Win32 Release"

!ELSEIF  "$(CFG)" == "modem - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\modem.rc
DEP_RSC_MODEM_=\
	".\msc.ico"\
	".\message.h"\
	

"$(INTDIR)\modem.res" : $(SOURCE) $(DEP_RSC_MODEM_) "$(INTDIR)"
   $(RSC) $(RSC_PROJ) $(SOURCE)


# End Source File
# End Target
# End Project
################################################################################
