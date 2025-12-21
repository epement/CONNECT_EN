{$F+,O+,I-,X+}
unit AsynPrim;

interface

uses APCom, APPort;

const
  PortAddress: Word = 0;
  IRQNumber: Byte = 0;
  COMVector: Byte = 0;
  ComName: ComNameType = Com2;
  Baud: Longint = 9600;
  Parity: ParityType = NoParity;
  DataBits: DataBitType = 8;
  StopBits: StopBitType = 2;
  HWFlow: Word = hfUseRTS + hfRequireCTS;
  SWFlow: Word = sfReceiveFlow + sfTransmitFlow;
  InBufSize: Word = 4096;
  OutBufSize: Word = 4096;
  PortOptions: Word = DefPortOptionsSimple;
  TryTimeout: Word = 18;
  FullTimeout: Word = $FFF0;
  LastModemStatus: Byte = 0;

  ErrorMsgInUse: Boolean = False;
  CancelReq: Boolean = False;

procedure EnableAsyncErrors;
procedure DisableAsyncErrors;
function AsyncStatusString(Code: Word): String;
function KbdAbort: Boolean;
procedure AsyncErrorProc(P: Pointer; var Code: Word);

procedure InitPortPrim(var P: PortRecPtr; ComName: ComNameType; Baud: LongInt;
  Parity: ParityType; DataBits: DataBitType; StopBits: StopBitType;
  InSize, OutSize: Word; Options: Word);
procedure DonePortPrim(var P: PortRecPtr);
function GetCharPrim(P: PortRecPtr; var C: Char): Boolean;
function PutCharPrim(P: PortRecPtr; C: Char): Boolean;

implementation

uses Objects, Drivers, Views, App, MsgBox, APMisc, APUart, DevLayer,
  Keyboard, Timer, Commands, Defaults;

procedure EnableAsyncErrors;
begin
  ErrorMsgInUse := False;
end;

procedure DisableAsyncErrors;
begin
  ErrorMsgInUse := True;
end;

function AsyncStatusString(Code: Word): String;
var
  ErrorList: PStringList;
  S: String;
begin
  ErrorList := PStringList(Resource^.Get('ASYNCERRORS'));
  if ErrorList <> nil then
  begin
    S := ErrorList^.Get(Code);
    Dispose(ErrorList, Done);
    if S = '' then S := 'Unknown async error';
  end
  else S := 'Resource file access error';
  AsyncStatusString := S;
end;

function KbdAbort: Boolean;
begin
  if ProtInProg then KbdAbort := CancelReq
  else if KbdStatus = 1 then
  begin
    ClearKbd;
    KbdAbort := True;
  end
  else KbdAbort := False;
end;

procedure AsyncErrorProc(P: Pointer; var Code: Word);
var
  W: Word;
begin
  if ErrorMsgInUse then Exit;
  W := Code mod 10000;
  if (W <> ecOk) and (W <> ecUserAbort) and
     ((PortOptions and ptIgnoreBufferErrors = 0) or
      ((W <> ecOverrunError) and (W <> ecParityError) and
       (W <> ecFramingError) and (W <> ecBufferIsFull))) then
  begin
    DisableAsyncErrors;
    if not DisableSounds then Write(^G);
    InitTimer(50, evCommand, cmOk, True);
    MessageBox(^C + AsyncStatusString(W) + '.', nil, mfError + mfOkButton);
    EnableAsyncErrors;
  end;
end;

procedure InitPortPrim(var P: PortRecPtr; ComName: ComNameType; Baud: LongInt;
  Parity: ParityType; DataBits: DataBitType; StopBits: StopBitType;
  InSize, OutSize: Word; Options: Word);
var
  B: Boolean;
  I: Integer;
  BufferFull, BufferResume: Word;
  SaveBase: Array[0..255] of Byte;
begin
  InitDeviceLayer;
  B := False;
  for I := 1 to MaxActivePort do
    if (ActiveComPort[I] <> nil) and
       (ActiveComPort[I]^.PortName = ComName) then
    begin
      B := True;
      Break;
    end;
  if B then AsyncStatus := ecNoMorePorts
  else
  begin
    Move(DefBaseAddr, SaveBase, Ofs(DefStdVector) + 2 - Ofs(DefBaseAddr));
    if DeviceLayer = dlUART then
      SetUART(ComName, PortAddress, IRQNumber, COMVector);
    InitPort(P, ComName, Baud, Parity, DataBits, StopBits,
      InSize, OutSize, Options);
    Move(SaveBase, DefBaseAddr, Ofs(DefStdVector) + 2 - Ofs(DefBaseAddr));
  end;
  if AsyncStatus <> ecOk then AsyncErrorProc(P, AsyncStatus)
  else
  begin
    SetDTR(P, True);
    SetRTS(P, True);
    BufferFull := Round(InSize * 0.75);
    BufferResume := Round(InSize * 0.25);
    if HWFlow and $FF = 0 then HWFlowDisable(P)
    else HWFlowEnable(P, BufferFull, BufferResume, HWFlow);
    if SWFlow and $03 = 0 then SWFlowDisable(P)
    else SWFlowEnableOpt(P, BufferFull, BufferResume, SWFlow);
    SetAbortFunc(P, KbdAbort);
    SetErrorProc(P, AsyncErrorProc);
  end;
end;

procedure DonePortPrim(var P: PortRecPtr);
begin
  DonePort(P);
end;

function GetCharPrim(P: PortRecPtr; var C: Char): Boolean;
begin
  GetCharPrim := False;
  if ErrorMsgInUse then Exit;
  if not CharReady(P) then Exit;
  GetChar(P, C);
  GetCharPrim := AsyncStatus = ecOk;
end;

function PutCharPrim(P: PortRecPtr; C: Char): Boolean;
var
  S: String[71];
begin
  PutCharPrim := False;
  if ErrorMsgInUse then Exit;
  DisableAsyncErrors;
  APCom.PutCharTimeout(P, C, TryTimeout);
  EnableAsyncErrors;
  if AsyncStatus <> ecOk then
  begin
    Message(Application, evBroadcast, cmNotReadyShow, nil);
    LogEvent := lcCommun;
    if StatusLine^.HelpCtx = $FFFF then
      S := StatusLine^.StatusMsg else S := '';
    DrawStatusLine('Device not ready. Keep waiting or press Esc to abort.');
    APCom.PutCharTimeout(P, C, FullTimeout);
    Message(Application, evBroadcast, cmNotReadyHide, nil);
    if S <> '' then
    begin
      LogEvent := lcCommun;
      DrawStatusLine(S);
    end;
  end;
  PutCharPrim := AsyncStatus = ecOk;
end;

end.