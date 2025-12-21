#Compile Dll
#Dim All
#Include "win32api.inc"
'-----------------------------------------------------------------------------
'
'       DOS 16 bit to Protected mode 32 bit interface using NTVDM Call
'
'-----------------------------------------------------------------------------

'--GLOBAL VARIABLES--
Global hInst        As Long

'--NTVDM Function Definitions--
Declare Function getBX Lib "ntvdm.exe" Alias "getBX"() As Long
Declare Function setAX Lib "ntvdm.exe" Alias "setAX"(ByVal Long) As Long

    Sub AxDisp Alias "AxDisp" () Export     'This routine is 16-->32 interface
        Local InBX As Long
        Local OutAX As Long

        InBX = getBX() And &H0FFFF          'Retrieve registers from 16 bit App
        MsgBox "Received '"+chr$(InBX and 255)+"' From 16 bit app, adding 1",, _
               "32 bit DLL Dispatch Rx"

        setAX(InBX+1)
    End Sub


    Sub AxInit Alias "AxInit" () Export
        MsgBox "Init routine activated",,"32 bit DLL"

    End Sub


'--Main Entry Point for .DLL--
Function LibMain(ByVal hInstance As Long, _
                 ByVal Reason    As Long, _
                 ByVal Reserved  As Long) _
                 Export As Long

    Select Case reason
        Case %DLL_PROCESS_ATTACH
            hInst = hInstance
            LibMain = 1
            Exit Function
        Case %DLL_PROCESS_DETACH
                '
            Exit Function
        Case %DLL_THREAD_ATTACH
                '
            Exit Function
        Case %DLL_THREAD_DETACH
                '
            Exit Function
    End Select

    MsgBox "Windows Error in LIBMAIN()"     'We should never get here
    LibMain = 0                             'Failure
End Function

