# Microsoft Developer Studio Generated NMAKE File, Format Version 4.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

!IF "$(CFG)" == ""
CFG=selftest - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to selftest - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "selftest - Win32 Release" && "$(CFG)" !=\
 "selftest - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "Selftest.mak" CFG="selftest - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "selftest - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "selftest - Win32 Debug" (based on "Win32 (x86) Application")
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
# PROP Target_Last_Scanned "selftest - Win32 Debug"
CPP=cl.exe
RSC=rc.exe
MTL=mktyplib.exe

!IF  "$(CFG)" == "selftest - Win32 Release"

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

ALL : "$(OUTDIR)\Selftest.exe"

CLEAN : 
        -@erase ".\Release\Selftest.exe"
        -@erase ".\Release\Runtest.obj"
        -@erase ".\Release\Sioerror.obj"
        -@erase ".\Release\Selftest.obj"
        -@erase ".\Release\About.obj"
        -@erase ".\Release\Menu.obj"
        -@erase ".\Release\Paint.obj"
        -@erase ".\Release\Selftest.res"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /ML /W3 /GX /D "WIN32" /D "NDEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/Selftest.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /win32
MTL_PROJ=/nologo /D "NDEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/Selftest.res" /d "NDEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/Selftest.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib\
 odbccp32.lib /nologo /subsystem:windows /incremental:no\
 /pdb:"$(OUTDIR)/Selftest.pdb" /machine:I386 \
 /out:"$(OUTDIR)/Selftest.exe" 
LINK32_OBJS= \
        "$(INTDIR)/Runtest.obj" \
        "$(INTDIR)/Sioerror.obj" \
        "$(INTDIR)/Selftest.obj" \
        "$(INTDIR)/About.obj" \
        "$(INTDIR)/Menu.obj" \
        "$(INTDIR)/Paint.obj" \
        "$(INTDIR)/Selftest.res" \
        ".\wsc32.lib"

"$(OUTDIR)\Selftest.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "selftest - Win32 Debug"

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

ALL : "$(OUTDIR)\Selftest.exe"

CLEAN : 
        -@erase ".\Debug\vc40.pdb"
        -@erase ".\Debug\vc40.idb"
        -@erase ".\Debug\Selftest.exe"
        -@erase ".\Debug\Paint.obj"
        -@erase ".\Debug\Sioerror.obj"
        -@erase ".\Debug\Menu.obj"
        -@erase ".\Debug\Runtest.obj"
        -@erase ".\Debug\Selftest.obj"
        -@erase ".\Debug\About.obj"
        -@erase ".\Debug\Selftest.res"
        -@erase ".\Debug\Selftest.ilk"
        -@erase ".\Debug\Selftest.pdb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /MLd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/Selftest.pch" /YX /Fo"$(INTDIR)/" /Fd"$(INTDIR)/" /c 
CPP_OBJS=.\Debug/
CPP_SBRS=
# ADD BASE MTL /nologo /D "_DEBUG" /win32
# ADD MTL /nologo /D "_DEBUG" /win32
MTL_PROJ=/nologo /D "_DEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
RSC_PROJ=/l 0x409 /fo"$(INTDIR)/Selftest.res" /d "_DEBUG" 
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/Selftest.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib\
 odbccp32.lib /nologo /subsystem:windows /incremental:yes\
 /pdb:"$(OUTDIR)/Selftest.pdb" /debug /machine:I386 \
 /out:"$(OUTDIR)/Selftest.exe" 
LINK32_OBJS= \
        "$(INTDIR)/Paint.obj" \
        "$(INTDIR)/Sioerror.obj" \
        "$(INTDIR)/Menu.obj" \
        "$(INTDIR)/Runtest.obj" \
        "$(INTDIR)/Selftest.obj" \
        "$(INTDIR)/About.obj" \
        "$(INTDIR)/Selftest.res" \
        ".\wsc32.lib"

"$(OUTDIR)\Selftest.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
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

# Name "selftest - Win32 Release"
# Name "selftest - Win32 Debug"

!IF  "$(CFG)" == "selftest - Win32 Release"

!ELSEIF  "$(CFG)" == "selftest - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=.\About.c
DEP_CPP_ABOUT=\
        ".\about.h"\
        

"$(INTDIR)\About.obj" : $(SOURCE) $(DEP_CPP_ABOUT) "$(INTDIR)"


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

SOURCE=.\Runtest.c
DEP_CPP_RUNTE=\
        ".\wsc.h"\
        ".\sioerror.h"\
        ".\paint.h"\
        ".\runtest.h"\
        

"$(INTDIR)\Runtest.obj" : $(SOURCE) $(DEP_CPP_RUNTE) "$(INTDIR)"


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

SOURCE=.\Selftest.rc
DEP_RSC_SELFT=\
        ".\msc.ico"\
        ".\message.h"\
        

"$(INTDIR)\Selftest.res" : $(SOURCE) $(DEP_RSC_SELFT) "$(INTDIR)"
   $(RSC) $(RSC_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=.\wsc32.lib

!IF  "$(CFG)" == "selftest - Win32 Release"

!ELSEIF  "$(CFG)" == "selftest - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\Selftest.c
DEP_CPP_SELFTE=\
        ".\selftest.h"\
        ".\message.h"\
        ".\wsc.h"\
        ".\ascii.h"\
        ".\paint.h"\
        ".\menu.h"\
        ".\about.h"\
        ".\runtest.h"\
        ".\sioerror.h"\
        

"$(INTDIR)\Selftest.obj" : $(SOURCE) $(DEP_CPP_SELFTE) "$(INTDIR)"


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
# End Target
# End Project
################################################################################
