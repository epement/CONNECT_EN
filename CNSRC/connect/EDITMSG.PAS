{$F+,O+}
unit EditMsg;

interface

uses Objects, Views, LFN;

const
  EditorAborted: Boolean = False;

function AbortMsgBox: Word;
function AbortAction: Boolean;
procedure OutOfMemoryMsgBox;
procedure FileHandlesMsgBox(B: Byte);
procedure SystemErrorMsgBox(Code: Byte);
procedure ExecErrorMsgBox(Code: Longint; const Name: FNameStr);
procedure ConfigOpenErrorMsgBox;
procedure ConfigReadErrorMsgBox;
procedure ConfigCreateErrorMsgBox;
procedure ConfigWriteErrorMsgBox;
procedure DesktopOpenErrorMsgBox;
procedure DesktopReadErrorMsgBox;
procedure DesktopCreateErrorMsgBox;
procedure DesktopWriteErrorMsgBox;
procedure InvalidSwapDirMsgBox;
procedure SearchStringNotFoundMsgBox;
procedure SearchStringTooLongMsgBox;
procedure SwapAccessErrorMsgBox;
procedure SwapReadErrorMsgBox;
procedure SwapWriteErrorMsgBox;
procedure ResourceNotFoundMsgBox(const Name: FNameStr);
function ModifiedSaveMsgBox(const Name: FNameStr): Word;
function ModifiedRebuildMsgBox: Word;
function TruncateLinesMsgBox(const Name: FNameStr): Word;
function TruncateNoSwapMsgBox(const Name: FNameStr): Word;
function TimeChangedMsgBox(const Kind, Name: FNameStr): Word;
procedure InvalidViewerMsgBox(const Kind, Name: FNameStr);
procedure FileIsDeviceMsgBox(const Name: FNameStr);
function CreateNewFileMsgBox(const Name: FNameStr): Word;
procedure CouldNotOpenMsgBox(const Name: FNameStr);
procedure CouldNotOpenCodeMsgBox(const Name: FNameStr; Code: Integer);
procedure CouldNotCreateMsgBox(const Name: FNameStr);
procedure CouldNotReadMsgBox(const Name: FNameStr);
procedure CouldNotWriteMsgBox(const Name: FNameStr);
function OverwriteReadOnlyMsgBox(const Name: FNameStr): Word;
procedure CannotWriteToItselfMsgBox;
function PrinterQueueMsgBox: Word;
function SpoolerNotEmptyMsgBox: Word;
function TerminalStatusMsgBox(const S: String): Word;
procedure TermcapNotFoundMsgBox(const Name, Iden: String);
procedure InvalidProgFileMsgBox(const Name: FNameStr);
procedure ProtInProgMsgBox(const ActionStr: String);
procedure DupHotKeyMsgBox(const Key, Title: String);
procedure InvalidDBFieldMsgBox(const Field: String);
procedure InvalidInputMsgBox(const Input, Description: String);
function ClearHistoryMsgBox(var All: Boolean): Word;
function DeleteItemMsgBox: Word;
function DeleteItemsMsgBox(Count: Integer): Word;
procedure LFNNotSupportedMsgBox(APIType: lAPIType);
function ExitMsgBox: Word;
procedure DrawReadDataStatus(const Name: FNameStr);
procedure DrawWriteDataStatus(const Name: FNameStr);
function IsScrollKey(Key: Word): Boolean;
procedure MultiScroll(Caller: PWindow; Key: Word);
procedure PlayEndingSignal;

implementation

uses CNCrt, Drivers, MsgBox, App, Keyboard, Swaps, DosTools, TPString,
  Consts, Commands, Defaults;

function AbortMsgBox: Word;
begin
  AbortMsgBox := MessageBox(^C'Abort current operation ?',
    nil, mfConfirmation + mfYesNo + mfNoEsc);
end;

function AbortAction: Boolean;
var
  B: Boolean;
begin
  AbortAction := False;
  repeat until KeyPressed or (KbdStatus <> 1);
  if not EscPressed then Exit;
  ClearKbd;
  B := (ConfirmOptions and coAbortEditor = 0) or (AbortMsgBox = cmYes);
  if B then DrawStatusLine('Aborting current Editor operation.')
  else DrawStatusLine('');
  EditorAborted := B;
  AbortAction := B;
end;

procedure OutOfMemoryMsgBox;
begin
  OutOfMemInUse := True;
  CtxMessageBox(
    ^C'There is not enough memory available to complete operation.',
    nil, mfError + mfOkButton, 0{hcAppOutOfMemory});
  OutOfMemInUse := False;
end;

procedure FileHandlesMsgBox(B: Byte);
begin
  MessageBox(^C'Number of file handles available: ' + Char(B + $30),
    nil, mfWarning + mfOkButton);
end;

procedure SystemErrorMsgBox(Code: Byte);
var
  L: Longint;
begin
  L := Code;
  MessageBox(^C'System error %d.', @L, mfError + mfOkButton);
end;

procedure ExecErrorMsgBox(Code: Longint; const Name: FNameStr);
var
  S: String;
begin
  if Code = -1 then S := 'insufficient memory to store free list.'
  else if Code = -5 then S := 'unable to allocate EMS or open swap file.'
  else S := 'unable to execute'#13^C'|' + Name + '|.';
  MessageBox(^C'Error %d: ' + S, @Code, mfError + mfOkButton);
end;

procedure CFGDSKReadErrorMsgBox(const FS, OS: FNameStr);
begin
  MessageBox(
    ^C'Error reading ' + FS + ' file.'#13^C'Options³Setup³Auto save ' +
    OS + #13^C'is now unchecked.', nil, mfError + mfOkButton);
end;

procedure ConfigOpenErrorMsgBox;
begin
  MessageBox(^C'Could not open configuration file.',
    nil, mfWarning + mfOkButton);
end;

procedure ConfigReadErrorMsgBox;
begin
  CFGDSKReadErrorMsgBox('configuration', 'environment');
end;

procedure ConfigCreateErrorMsgBox;
begin
  MessageBox(^C'Could not create configuration file.',
    nil, mfError + mfOkButton);
end;

procedure ConfigWriteErrorMsgBox;
begin
  MessageBox(^C'Error writing to configuration file.',
    nil, mfError + mfOkButton);
end;

procedure DesktopOpenErrorMsgBox;
begin
  MessageBox(^C'Could not open desktop file.',
    nil, mfWarning + mfOkButton);
end;

procedure DesktopReadErrorMsgBox;
begin
  CFGDSKReadErrorMsgBox('desktop', 'desktop');
end;

procedure DesktopCreateErrorMsgBox;
begin
  MessageBox(^C'Could not create desktop file.',
    nil, mfError + mfOkButton);
end;

procedure DesktopWriteErrorMsgBox;
begin
  MessageBox(^C'Error writing to desktop file.',
    nil, mfError + mfOkButton);
end;

procedure InvalidSwapDirMsgBox;
begin
  MessageBox(^C'Invalid swap file directory:'#13#13 +
    ^C'"|' + SwapDir + '|".', nil, mfError + mfOkButton);
end;

procedure SearchStringNotFoundMsgBox;
begin
  MessageBox(^C'Search string not found.', nil, mfError + mfOkButton);
end;

procedure SearchStringTooLongMsgBox;
begin
  MessageBox(^C'Incremental search string too long.',
    nil, mfError + mfOkButton);
end;

procedure SwapAccessErrorMsgBox;
begin
  MessageBox(^C'Swap file access error.', nil, mfError + mfOkButton);
end;

procedure SwapReadErrorMsgBox;
begin
  MessageBox(^C'Error reading swap file.', nil, mfError + mfOkButton);
end;

procedure SwapWriteErrorMsgBox;
begin
  CtxMessageBox(^C'Error writing to swap file.',
    nil, mfError + mfOkButton, hcAppOutOfMemory);
end;

procedure ResourceNotFoundMsgBox(const Name: FNameStr);
begin
  MessageBox(^C'Resource not found: ' + Name + '.',
    nil, mfError + mfOkButton);
end;

function ModifiedSaveMsgBox(const Name: FNameStr): Word;
var
  C: Word;
  R: TRect;
begin
  C := MessageBox(^C'File |' + Name +
    '|'#13^C'has been modified. Save ?',
    nil, mfWarning + mfYesAllNoCancel);
  if C = cmOk then
  begin
    Message(Desktop, evBroadcast, cmSaveAll, nil);
    C := cmNo;
  end;
  ModifiedSaveMsgBox := C;
end;

function ModifiedRebuildMsgBox: Word;
begin
  ModifiedRebuildMsgBox := MessageBox(
    ^C'Source has been modified. Rebuild ?',
    nil, mfConfirmation + mfYesNoCancel);
end;

function TruncateLinesMsgBox(const Name: FNameStr): Word;
begin
  TruncateLinesMsgBox := CtxMessageBox(^C'File |' + Name +
    '|'#13^C'too large to fit in memory.'#13^C'Truncate ?',
    nil, mfConfirmation + mfOkCancel, hcAppOutOfMemory);
end;

function TruncateNoSwapMsgBox(const Name: FNameStr): Word;
begin
  TruncateNoSwapMsgBox := CtxMessageBox(
    ^C'Not enough swap space to load'#13^C'|' +
    Name + '|.'#13^C'Truncate ?',
    nil, mfConfirmation + mfOkCancel, hcAppOutOfMemory);
end;

function TimeChangedMsgBox(const Kind, Name: FNameStr): Word;
begin
  TimeChangedMsgBox := MessageBox(
    ^C + Kind + ' file'#13^C'|' + Name +
    '|''s time/date'#13^C'has changed. Reload from disk ?',
    nil, mfConfirmation + mfOkCancel);
end;

procedure InvalidViewerMsgBox(const Kind, Name: FNameStr);
begin
  MessageBox(^C + Kind + ' file'#13^C'|' + Name +
    '| has been erased.'#13^C'The viewer is no longer valid.',
    nil, mfWarning + mfOkButton);
end;

procedure FileIsDeviceMsgBox(const Name: FNameStr);
begin
  MessageBox(^C'File |' + Name + '|'#13^C'is a device.',
    nil, mfError + mfOkButton);
end;

function CreateNewFileMsgBox(const Name: FNameStr): Word;
begin
  CreateNewFileMsgBox := MessageBox(
    ^C'Could not find'#13^C'|' + Name + '|.'#13^C'Create new ?',
    nil, mfConfirmation + mfOkCancel);
end;

procedure CouldNotOpenMsgBox(const Name: FNameStr);
begin
  MessageBox(^C'Could not open'#13^C'|' + Name + '|.',
    nil, mfError + mfOkButton);
end;

procedure CouldNotOpenCodeMsgBox(const Name: FNameStr; Code: Integer);
var
  L: Longint;
begin
  L := Code;
  MessageBox(^C'Error %d. Could not open'#13^C'|' +
    Name + '|.', @L, mfError + mfOkButton);
end;

procedure CouldNotCreateMsgBox(const Name: FNameStr);
begin
  MessageBox(^C'Could not create'#13^C'|' + Name + '|.',
    nil, mfError + mfOkButton);
end;

procedure CouldNotReadMsgBox(const Name: FNameStr);
begin
  MessageBox(^C'Error reading data from'#13^C'|' + Name + '|.',
    nil, mfError + mfOkButton);
end;

procedure CouldNotWriteMsgBox(const Name: FNameStr);
begin
  MessageBox(^C'Error writing data to'#13^C'|' + Name + '|.',
    nil, mfError + mfOkButton);
end;

function OverwriteReadOnlyMsgBox(const Name: FNameStr): Word;
begin
  OverwriteReadOnlyMsgBox := MessageBox(
    ^C'File |' + Name + '|'#13^C'is marked ''Read only'' or ''Hidden''.' +
    #13^C'Do you still wish to overwrite it ?',
    nil, mfConfirmation + mfOkCancel);
end;

procedure CannotWriteToItselfMsgBox;
begin
  MessageBox(^C'Cannot write file block to itself.',
    nil, mfError + mfOkButton);
end;

function PrinterQueueMsgBox: Word;
begin
  PrinterQueueMsgBox := MessageBox(
    ^C'Window is in the printer queue.'#13^C'Close still ?',
    nil, mfConfirmation + mfOkCancel);
end;

function SpoolerNotEmptyMsgBox: Word;
begin
  SpoolerNotEmptyMsgBox := MessageBox(
    ^C'Printer queue not empty.'#13^C'Execute still ?',
    nil, mfConfirmation + mfOkCancel);
end;

function TerminalStatusMsgBox(const S: String): Word;
begin
  TerminalStatusMsgBox := MessageBox(
    ^C'Terminal status: ' + S + '.'#13^C'Close still ?',
    nil, mfConfirmation + mfOkCancel);
end;

procedure TermcapNotFoundMsgBox(const Name, Iden: String);
begin
  MessageBox(^C'The termcap file'#13^C'|' + Name +
    '|'#13^C'does not contain "' + Iden + '".',
    nil, mfError + mfOkButton);
end;

procedure InvalidProgFileMsgBox(const Name: FNameStr);
begin
  MessageBox(^C'Invalid program file:'#13#13^C'|' +
    Name + '|.', nil, mfError + mfOkButton);
end;

procedure ProtInProgMsgBox(const ActionStr: String);
begin
  MessageBox(
    ^C'Cannot ' + ActionStr + ' while protocol handshake is in progress.',
    nil, mfInformation + mfOkButton);
end;

procedure DupHotKeyMsgBox(const Key, Title: String);
begin
  MessageBox(^C'The hot key ' + Key +
    #13^C'has already been assigned to'#13^C + Title + '.',
    nil, mfWarning + mfOKButton);
end;

procedure InvalidDBFieldMsgBox(const Field: String);
begin
  MessageBox(^C'Invalid database record field:'#13#13 +
    ^C'"' + Field + '".', nil, mfError + mfOkButton);
end;

procedure InvalidInputMsgBox(const Input, Description: String);
begin
  MessageBox(
    ^C + '"' + Input + '" is not a valid ' + Description + '.',
    nil, mfError + mfOkButton);
end;

function ClearHistoryMsgBox(var All: Boolean): Word;
var
  C: Word;
  S: String[15];
begin
  if ConfirmOptions and coClearHistory = 0 then ClearHistoryMsgBox := cmOk
  else
  begin
    if All then
    begin
      S := 'all';
      C := mfOkCancel;
    end
    else
    begin
      S := 'unlocked';
      C := mfYesAllCancel;
    end;
    C := MessageBox(^C'Clear ' + S + ' history items ?',
      nil, mfConfirmation + C);
    if not All and (C = cmOk) then All := True;
    ClearHistoryMsgBox := C;
  end;
end;

function DeleteItemMsgBox: Word;
begin
  if ConfirmOptions and coDeleteItem = 0 then DeleteItemMsgBox := cmOk
  else DeleteItemMsgBox := MessageBox(
    ^C'Remove the selected item from the list ?',
    nil, mfConfirmation + mfOkCancel);
end;

function DeleteItemsMsgBox(Count: Integer): Word;
var
  L: Longint;
  S: String[7];
begin
  if ConfirmOptions and coDeleteItem = 0 then DeleteItemsMsgBox := cmOk
  else
  begin
    S := 'items';
    L := Count;
    if L = 1 then Dec(S[0]);
    DeleteItemsMsgBox := MessageBox(
      ^C'Remove %d selected ' + S + ' from the list ?',
      @L, mfConfirmation + mfOkCancel);
  end;
end;

procedure LFNNotSupportedMsgBox(APIType: lAPIType);
begin
  MessageBox(^C'Long filename API functions are not supported ' +
    'by the operating system currently in use.',
    nil, mfWarning + mfOkButton);
end;

function ExitMsgBox: Word;
var
  R: TRect;
begin
  if ConfirmOptions and coExit = 0 then ExitMsgBox := cmYes
  else
  begin
    R.Assign(
      ScreenWidth div 2 - 24, ScreenHeight div 2 - 4,
      ScreenWidth div 2 + 24, ScreenHeight div 2 + 3);
    ExitMsgBox := MessageBoxRect(R,
      ^C'Do you want to quit the IBM HandShaker ?',
      nil, mfConfirmation + mfYesNo);
  end;
end;

procedure DrawReadDataStatus(const Name: FNameStr);
begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Reading data from ' + TrimmedName(Name, 49) + '.');
end;

procedure DrawWriteDataStatus(const Name: FNameStr);
begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Writing data to ' + TrimmedName(Name, 51) + '.');
end;

function IsScrollKey(Key: Word): Boolean;
begin
  case CtrlToArrow(Key) of
    kbDown, kbUp, kbCtrlDn, kbCtrlUp,
    kbPgDn, kbPgUp, kbCtrlPgDn, kbCtrlPgUp,
    kbRight, kbLeft, kbCtrlRight, kbCtrlLeft,
    kbEnd, kbHome, kbCtrlEnd, kbCtrlHome: IsScrollKey := True
    else IsScrollKey := False;
  end;
end;

procedure MultiScroll(Caller: PWindow; Key: Word);

procedure DoScroll(P: PWindow); far;
begin
  if (P <> Caller) and (TypeOf(P^) = TypeOf(Caller^)) and
     (P^.State and sfVisible <> 0) then Message(P, evKeyDown, Key, nil);
end;

begin
  MultiScrolling := True;
  Desktop^.ForEach(@DoScroll);
  MultiScrolling := False;
end;

procedure PlayEndingSignal;
begin
  if DisableSounds then Exit;

  Sound(740);
  Delay(64);
  NoSound;
  Delay(48);

  Sound(880);
  Delay(64);
  NoSound;
  Delay(48);

  Sound(1180);
  Delay(64);
  NoSound;
end;

end.
