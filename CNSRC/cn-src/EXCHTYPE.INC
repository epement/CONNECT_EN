ExchBufferType  struc
 ProgrToExecute db 81 dup (?)
 CmdLine        db 128 dup (?)
 DosStr <Source>
 DosStr <ReportFile> ; ASCIIZ имя $Report файла
 DosStr <ConfigMask>
 DosStr <OldDir>
 Error          db ?
 Options        db ?
 SnippFlag      db ?
 SnippInUse     db ?
 VideoSeg       dw ?
 TxtBufferEnd   dw ?
 TxtBufferPtr   Pointer <?,?>
 Snipp_Init     Pointer <?,?>
 Snipp_Done     Pointer <?,?>
 Snipp_ClearBuffer Pointer <?,?>
 CN_NT_Handler  dw ?
ExchBufferType  ends

; Options bits
RedirFlag      = 1
CommandFlag    = 2
MsgWinFlag     = 4
MultiExecFlag  = 8
RedirFlag2     = 16
CN_NT          = 32
