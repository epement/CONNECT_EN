unit ErrMsgs;

interface

uses Objects;

const
  MaxCompilerErrors = 24;
  MaxRunErrors = 37;
  MaxAsyncErrors = 10000;

procedure RSRCompilerErrors(RSR: PResourceFile);
procedure RSRRunErrors(RSR: PResourceFile);
procedure RSRAsyncErrors(RSR: PResourceFile);

implementation

uses APMisc;

function RunErrorString(Code: Byte): String;
begin
  case Code of
    0  : RunErrorString	:= 'Internal error';
    1  : RunErrorString := 'Program not found';
    2  : RunErrorString := 'Invalid program file';
    3  : RunErrorString	:= 'Source file not found';
    4  : RunErrorString	:= 'Memory allocation error';
    5  : RunErrorString	:= 'Invalid pointer operation';
    6  : RunErrorString	:= 'Invalid RS-232 init line';
    7  : RunErrorString	:= 'Stack overflow';
    8  : RunErrorString	:= 'RET without GOSUB';
    9  : RunErrorString	:= 'File not closed';
    10 : RunErrorString	:= 'Could not open file';
    11 : RunErrorString	:= 'User file not found';
    14 : RunErrorString	:= 'Division by zero';
    18 : RunErrorString	:= 'Could not access any Editor window';
    19 : RunErrorString	:= 'Invalid buffer index';
    20 : RunErrorString	:= 'Out of memory';
    22 : RunErrorString	:= 'Invalid pointer operation';
    23 : RunErrorString	:= 'Index out of range';
    24 : RunErrorString	:= 'Value out of range';
    25 : RunErrorString	:= 'Invalid numeric format';
    27 : RunErrorString	:= 'Disk error';
    28 : RunErrorString	:= 'File not open';
    29 : RunErrorString	:= 'Invalid user file';
    30 : RunErrorString	:= 'User file too large';
    31 : RunErrorString	:= 'Stop';
    32 : RunErrorString	:= 'Internal stack overflow';
    35 : RunErrorString	:= 'User break';
    36 : RunErrorString	:= 'RS-232 not initialized';
    else RunErrorString	:= '';
  end;
end;

function CompilerErrorString(Code: Byte): String;
begin
  case Code of
    0  : CompilerErrorString := 'Internal error';
    1  : CompilerErrorString := 'Out of memory';
    2  : CompilerErrorString := 'Program too large';
    3  : CompilerErrorString := '" expected';
    4  : CompilerErrorString := 'Collection error';
    5  : CompilerErrorString := 'Syntax error';
    6  : CompilerErrorString := 'Invalid "()"';
    7  : CompilerErrorString := '"(" expected';
    8  : CompilerErrorString := '")" expected';
    10 : CompilerErrorString := 'Invalid label';
    11 : CompilerErrorString := 'Error in expression';
    12 : CompilerErrorString := 'Duplicate labels';
    13 : CompilerErrorString := 'Invalid label position';
    14 : CompilerErrorString := 'Invalid IF position';
    15 : CompilerErrorString := 'Error in IF..THEN statement';
    16 : CompilerErrorString := 'Label expected';
    17 : CompilerErrorString := 'Write file error';
    18 : CompilerErrorString := 'Could not create output file';
    19 : CompilerErrorString := 'Unknown label';
    20 : CompilerErrorString := 'Invalid Goto address';
    21 : CompilerErrorString := 'File not found';
    22 : CompilerErrorString := '"}" expected';
    23 : CompilerErrorString := 'Error in integer constant';
    else CompilerErrorString := '';
  end;
end;

function AsyncStatusString(Code: Word): String;
var
  S: String;
begin
  case Code mod 10000 of

    ecOk :
      S := 'Ok';

    {DOS errors}
    ecFileNotFound :
      S := 'File not found';
    ecPathNotFound :
      S := 'Path not found';
    ecTooManyFiles :
      S := 'Too many open files';
    ecAccessDenied :
      S := 'File access denied';
    ecInvalidHandle :
      S := 'Invalid file handle';
    ecOutOfMemory :
      S := 'Insufficient memory';
    ecInvalidDrive :
      S := 'Invalid drive';
    ecNoMoreFiles :
      S := 'No more files';

    {Turbo Pascal I/O errors}
    ecDiskRead :
      S := 'Attempt to read beyond end of file';
    ecDiskFull :
      S := 'Disk is full';
    ecNotAssigned :
      S := 'File not assigned';
    ecNotOpen :
      S := 'File not open';
    ecNotOpenInput :
      S := 'File not open for input';
    ecNotOpenOutput :
      S := 'File not open for output';

    {DOS critical errors}
    ecWriteProtected :
      S := 'Disk is write-protected';
    ecUnknownUnit :
      S := 'Unknown disk unit';
    ecDriveNotReady :
      S := 'Drive is not ready';
    ecUnknownCommand :
      S := 'Unknown command';
    ecCrcError :
      S := 'Data error';
    ecBadStructLen :
      S := 'Bad request structure length';
    ecSeekError :
      S := 'Seek error';
    ecUnknownMedia :
      S := 'Unknown media type';
    ecSectorNotFound :
      S := 'Disk sector not found';
    ecOutOfPaper :
      S := 'Printer is out of paper';
    ecDeviceWrite :
      S := 'Device write error';
    ecDeviceRead :
      S := 'Device read error';
    ecHardwareFailure :
      S := 'General failure';

    {APUART port errors}
    ecNoMorePorts :
      S := 'Cannot open port, no slots available';
    ecOverrunError :
      S := 'UART receiver overrun';
    ecParityError :
      S := 'UART receiver parity error';
    ecFramingError :
      S := 'UART receiver framing error';

    {APINT14 port errors}
    ecTransmitFailed :
      S := 'Int14 transmit failed';
    ecUartError :
      S := 'Int14 receive failed';

    {APCOM/OOCOM errors/status}
    ecBlockIncomplete :
      S := 'Block shorter than requested';
    ecBufferIsFull :
      S := 'No room for new char in buffer';
    ecBufferIsEmpty :
      S := 'No characters to get';
    ecTimeout :
      S := 'Timed out waiting for data';
    ecStringIncomplete :
      S := 'String shorter than requested';
    ecStringOverrun :
      S := 'String longer than 255';
    ecUserAbort :
      S := 'User aborted while waiting';

    {APMODEM/OOMODEM errors}
    ecTableFull :
      S := 'No room in table to add new entry';
    ecNullCommand :
      S := 'Modem - no command registered';

    {APCOM/OOCOM port errors}
    ecBadPortNumber :
      S := 'Out-of-range port number';
    ecOutofRange :
      S := 'General out-of-range error';
    ecPortNotOpen :
      S := 'Port not open';
    ecInvalidBaudRate :
      S := 'Bad baud rate for this device';
    ecInvalidArgument :
      S := 'General programming error';
    ecNoDevice :
      S := 'No device layer installed';
    ecNotaUart :
      S := 'No UART at this address';
    ecInvalidParity :
      S := 'Bad parity option for this device';
    ecBadFileList :
      S := 'No end of list marker found in file list';
    ecNotBuffered :
      S := 'Operation only allowed on buffered ports';
    ecNotSupported :
      S := 'Function not supported by device layer';

    {APXMODEM/OOABSPCL status codes}
    ecInitFail :
      S := 'Xmodem init failed';
    ecInitCancel :
      S := 'Xmodem init was canceled on request';
    ecCancelRequested :
      S := 'Cancel requested';
    ecError :
      S := 'Modem returned error (or other misc errors)';
    ecDuplicateBlock :
      S := 'Duplicate block received';
    ecSequenceError :
      S := 'Wrong block number received';
    ecDirNotFound :
      S := 'Directory not found in protocol transmit';
    ecNoMatchingFiles :
      S := 'No matching files in protocol transmit';
    ecLongPacket :
      S := 'Long packet received during protocol';
    ecEndFile :
      S := 'End of transmitted file';
    ecHandshakeInProgress :
      S := 'Protocol handshake in progress';
    ecFileRenamed :
      S := 'Incoming file was renamed';
    ecFileAlreadyExists :
      S := 'Incoming file already exists';
    ecInvalidFilesize :
      S := 'Header has bad file size';
    ecInvalidDateTime :
      S := 'Header has bad date/time';
    ecUnexpectedChar :
      S := 'Unexpected char during protocol';
    ecBlockCheckError :
      S := 'Incorrect CRC or checksum received';
    ecNoSearchMask  :
      S := 'No search mask specified for transmit';
    ecNoFilename :
      S := 'No filename specified';
    ecAsciiReceiveInProgress :
      S := 'ASCII receive - Press Esc to end';
    ecFileRejected :
      S := 'Received file rejected';
    ecTooManyErrors :
      S := 'Too many errors received during protocol';
    ecNoCD :
      S := 'Data carrier detect required';

    {APZMODEM/OOZMODEM status codes}
    ecGotCrcE :
      S := 'Zmodem - got CrcE DataSubpacket';
    ecGotCrcW :
      S := 'Zmodem - got CrcW DataSubpacket';
    ecGotCrcQ :
      S := 'Zmodem - got CrcQ DataSubpacket';
    ecGotCrcG :
      S := 'Zmodem - got CrcG DataSubpacket';
    ecGarbage :
      S := 'Zmodem - got garbage from remote';
    ecSkipFile :
      S := 'Zmodem - skip file';
    ecBadPosition :
      S := 'Zmodem - bad file position';
    ecFileDoesntExist :
      S := 'Zmodem - specified file does not exist';
    ecCantWriteFile :
      S := 'Zmodem - not allowed to overwrite file';
    ecFailedToHandshake :
      S := 'Zmodem - never got proper handshake';
    ecNoFilesToReceive :
      S := 'Zmodem - no files to receive';

    {APBPLUS/OOBPLUS status codes}
    ecResync     :
      S := 'Resyncing with host';
    ecWaitACK    :
      S := 'Host busy, waiting';
    ecDropout    :
      S := 'Unexpected break in connection';
    ecHostCan    :
      S := 'Host cancelled transfer';
    ecTryResume  :
      S := 'Attempting resume';
    ecHostResume :
      S := 'Host verifying resume request';
    ecResumeOK   :
      S := 'Resuming partial transfer';
    ecResumeBad  :
      S := 'Host refused resume request';
    ecUnPacket   :
      S := 'Unknown packet type received';

    {APMODEM/OOMODEM status codes}
    ecUnknownModemResult :
      S := 'Unexpected data in modem result';
    ecConnect :
      S := 'Modem response - CONNECT';
    ecRing :
      S := 'Modem response - RING';
    ecNoCarrier :
      S := 'Modem response - NO CARRIER';
    ecNoDialTone :
      S := 'Modem response - NO DIALTONE';
    ecBusy :
      S := 'Modem response - BUSY';
    ecNoAnswer :
      S := 'Modem response - NO ANSWER';
    ecRinging :
      S := 'Modem response - RINGING';
    ecVoice :
      S := 'Modem response - VOICE';

    else S := '';
  end;
  AsyncStatusString := S;
end;

procedure RSRRunErrors(RSR: PResourceFile);
var
  M: PStrListMaker;
  S: String;
  I: Byte;
begin
  M := New(PStrListMaker, Init(16383, $FF));
  for I := 0 to MaxRunErrors - 1 do
  begin
    S := RunErrorString(I);
    if S <> '' then M^.Put(I, S);
  end;
  RSR^.Put(M, 'RUNERRORS');
  Dispose(M, Done);
end;

procedure RSRCompilerErrors(RSR: PResourceFile);
var
  M: PStrListMaker;
  S: String;
  I: Byte;
begin
  M := New(PStrListMaker, Init(16383, $FF));
  for I := 0 to MaxCompilerErrors - 1 do
  begin
    S := CompilerErrorString(I);
    if S <> '' then M^.Put(I, S);
  end;
  RSR^.Put(M, 'COMPILERERRORS');
  Dispose(M, Done);
end;

procedure RSRAsyncErrors(RSR: PResourceFile);
var
  M: PStrListMaker;
  S: String;
  I: Word;
begin
  M := New(PStrListMaker, Init(16383, $FF));
  for I := 0 to MaxAsyncErrors - 1 do
  begin
    S := AsyncStatusString(I);
    if S <> '' then M^.Put(I, S);
  end;
  RSR^.Put(M, 'ASYNCERRORS');
  Dispose(M, Done);
end;

end.