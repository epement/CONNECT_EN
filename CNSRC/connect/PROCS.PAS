{$I-,O+,F+,X+}
{$DEFINE Connect}
unit Procs;

interface

uses Objects;

type
  MemoryPtr = ^MemoryType;
  MemoryType = record
    Block: Pointer;
    BlockSize: Word;
  end;

  PMemoryCollection = ^TMemoryCollection;
  TMemoryCollection = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
    function Search(P: Pointer; var Index: Integer): Boolean; virtual;
  end;

  PPortCollection = ^TPortCollection;
  TPortCollection = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
    function Search(PortName: Byte; var Index: Integer): Boolean; virtual;
  end;

  PDim = ^TDim;
  TDim = Array[0..$FFF0] of Byte;

const
  MemoryList: PMemoryCollection = nil;
  FileList: PCollection = nil;
  PortList: PCollection = nil;

 Function Upload(var C, B, A : Longint):Longint;
 Function Download(var C, B, A : Longint):Longint;
 Function Dial(var A : Longint):Longint;
 Function FSeek(var B, A : Longint):Longint;
 Function Send(var C, B, A : Longint):Longint;
 Function SendBlock(var D, C, B, A : Longint):Longint;
 Function SendString(var B, A : Longint):Longint;
 Function CheckRS(var A: Longint):Longint;
 Function Receive(var D, C, B, A : Longint):Longint;
 Function ReceiveBlock(var E, D, C, B, A: Longint):Longint;
 Function WaitForString(var D, C, B, A: Longint):Longint;
 Function GetBuff(var B, A : Longint):Longint;
 Function DispBuff(var A : Longint):Longint;
 Function ReadBuff(var C, B, A : Longint):Longint;
 Function WriteBuff(var D, C, B, A : Longint):Longint;
 Function KeyPrs(var A: Longint):Longint;
 Function FOpen(var C, B, A : Longint):Longint;
 Function FClose(var A : Longint):Longint;
 Function LoadUser(var B, A : Longint):Longint;
 Function User(var C, B, A : Longint):Longint;
 Function RdBlk(var C, B, A : Longint):Longint;
 Function WrBlk(var C, B, A : Longint):Longint;
 Function PrintS(var C, B, A : Longint):Longint;
 Function InputS(var A : Longint):Longint;
 Function PrintV(var D, C, B, A : Longint):Longint;
 Function InputV(var A : Longint):Longint;
 Function RTS(var B, A : Longint):Longint;
 Function CTS(var A: Longint):Longint;
 Function DTR(var B, A : Longint):Longint;
 Function DSR(var A: Longint):Longint;
 Function DCD(var A: Longint):Longint;
 Function RING(var A: Longint):Longint;
 Function Init_RS(var A : Longint):Longint;
 Function Done_RS(var A : Longint):Longint;
 Function INDBAR(var C, B, A : Longint):Longint;
 Function WriteStatus(var B, A : Longint):Longint;
 Function GetCRC32(var B, A : Longint):Longint;
 Function AddL(var A, B : Longint):Longint;
 Function SubL(var A, B : Longint):Longint;
 Function DivL(var A, B : Longint):Longint;
 Function MulL(var A, B : Longint):Longint;
 Function Let(var A, B : Longint):Longint;
 Function LE(var A, B : Longint):Longint;
 Function GE(var A, B : Longint):Longint;
 Function EQ(var A, B : Longint):Longint;
 Function Empty(var A, B : Longint):Longint;
 Function NE(var A, B : Longint):Longint;
 Function LS(var A, B : Longint):Longint;
 Function GR(var A, B : Longint):Longint;
 Function ANDL(var A, B : Longint):Longint;
 Function ORL(var A, B : Longint):Longint;
 Function XORL(var A, B : Longint):Longint;
 Function NOTL(var A : Longint):Longint;
 Function Menu(var B, A : Longint):Longint;
 Function Beep(var A, B : Longint): Longint;
 function Idle(var A : Longint): Longint;
 function MarkFunc: Longint;
 function ReleaseFunc(var A : Longint): Longint;
 function GetProgParams: Longint;
 Procedure Stop(var A : Longint);

 Procedure InitRTL(Params: PString);
 Procedure DoneRTL;
 Procedure CloseAllFiles;
 Procedure CloseBar;
 procedure Error(Code,I : Integer);
 function BlockUsed(P: Pointer; var Index: Integer): Boolean;

 function NewWin(var A: Longint): Longint;
 function PutStr(var A: Longint): Longint;
 function PutKey(var A: Longint): Longint;
 function GetStr: Longint;
 function GetWrd: Longint;
 function GetChr: Longint;
 function Find(var B, A: Longint): Longint;
 function Replace(var C, B, A: Longint): Longint;
 function StoreBlock(var A: Longint): Longint;
 function LoadBlock(var A: Longint): Longint;
 function GotoXY(var B, A: Longint): Longint;
 function WhereCurX: Longint;
 function WhereCurY: Longint;
 function MaxY: Longint;
 function SetIns(var A): Longint;

 function StrCompare(var C, B, A: Longint): Longint;
 function StrConcat(var B, A: Longint): Longint;
 function StrPos(var E, D, C, B, A: Longint): Longint;
 function StrCopy(var C, B, A: Longint): Longint;
 function StrDelete(var C, B, A: Longint): Longint;
 function StrInsert(var C, B, A: Longint): Longint;
 function StrUpcase(var A: Longint): Longint;
 function StrLocase(var A: Longint): Longint;
 function FrmtStr(var B, A: Longint): Longint;

Implementation

uses CNCrt, Dos, Drivers, Memory, RevPos, TPString, DosTools, Jump,
  Compiler, UserPrim, APMisc, APPort, APCom, AsynPrim, APAbsPcl,
  ProtPrim, CRC32,
{$IFDEF Connect}
  App, HistList, History, Funcs, Views, MsgBox, Gauges, Spooler, BarWin,
  DirPrim, FindDlg, FEditor, EditPrim, OutWin, Terminal, RegExp, LFN,
  Consts, Commands, Defaults
{$ENDIF};

const
  IdChars: Set of Char =
    [#9,' ','!','#','_', '0'..'9','$','A'..'Z','a'..'z'];

  TermPort: Boolean = False;
  IncomeSeq: PString = nil;
  ProgParams: PString = nil;

var
  SaveInt1Ptr, SaveInt3Ptr: Pointer;

function ErrorString(Code: Byte): String;
var
  ErrorList: PStringList;
  S: String;
begin
  ErrorList := PStringList(Resource^.Get('RUNERRORS'));
  if ErrorList <> nil then
  begin
    S := ErrorList^.Get(Code);
    Dispose(ErrorList, Done);
  end
  else S := 'Resource file access error';
  ErrorString := S;
end;

procedure Error(Code, I: Integer);
var
 L: Longint;
 ES: String;
begin
 {$IFDEF Connect}
 Message(Desktop, evBroadcast, cmDoneCPU, nil);
 if Code <> 31 then
 begin
   ES := ErrorString(Code);
   if ES = '' then
   begin
     ES := 'Internal error';
     Code := 0;
   end;
   L := GetCurrentLine + 1;
   if (I <> -1) and (L > 0) then
     if (CtxMessageBox(^C + ES + ' at line %d.',
	  @L, mfError + mfOkButton, hcError + Code) = cmOk) and
	(Source <> nil) then
       PFileEditor(Source)^.GoToPos(0, GetCurrentLine) else
   else
   begin
     L := GetCurrentAddr;
     CtxMessageBox(^C + ES + ' at address %04x.',
       @L, mfError + mfOkButton, hcError + Code)
   end;
 end;
 {$ELSE}
 case Code of
    1  : ES     := 'Program not found';
    2  : ES     := 'Invalid program file';
    3  : ES     := 'Source file not found';
    4  : ES     := 'Memory allocation error';
    5  : ES     := 'Invalid pointer operation';
    6  : ES     := 'Invalid RS-232 init line';
    7  : ES     := 'Stack overflow';
    8  : ES     := 'RET without GOSUB';
    9  : ES     := 'File not closed';
    10 : ES     := 'Could not open file';
    11 : ES     := 'User file not found';
    14 : ES     := 'Division by zero';
    19 : ES     := 'Invalid buffer index';
    20 : ES     := 'Out of memory';
    22 : ES     := 'Invalid pointer operation';
    23 : ES     := 'Index out of range';
    24 : ES     := 'Value out of range';
    25 : ES     := 'Invalid numeric format';
    27 : ES     := 'Disk error';
    28 : ES     := 'File not open';
    29 : ES     := 'Invalid user file';
    30 : ES     := 'User file too large';
    31 : ES     := 'Stop';
    32 : ES     := 'Internal stack overflow';
    35 : ES     := 'User break';
    36 : ES     := 'RS-232 not initialized';
    else ES     := 'Internal error';
  end;
 Write(ES);
 L := GetCurrentAddr;
 Writeln(' at address ',HexW(Word(L)));
 {$ENDIF}
 LongJump;
end;

procedure TMemoryCollection.FreeItem(Item: Pointer);
begin
  if Item <> nil then with MemoryPtr(Item)^ do
  begin
    if Block <> nil then FreeMem(Block, BlockSize);
    FreeMem(Item, SizeOf(MemoryType));
  end;
end;

function TMemoryCollection.Search(P: Pointer; var Index: Integer): Boolean;
begin
  Index := Pred(Count);
  while (Index >= 0) and (MemoryPtr(At(Index))^.Block <> P) do Dec(Index);
  Search := (Index >= 0) and (MemoryPtr(At(Index))^.Block = P);
end;

procedure TPortCollection.FreeItem(Item: Pointer);
begin
  DonePortPrim(PortRecPtr(Item));
end;

function TPortCollection.Search(PortName: Byte;
  var Index: Integer): Boolean;
begin
  Index := 0;
  repeat
    if Index >= Count then Break;
    if PortRecPtr(At(Index))^.PortName = ComNameType(PortName) then Break;
    Inc(Index);
  until False;
  Search := Index < Count;
end;

function GetPort(PortName: ComNameType): PortRecPtr;
var
  I: Integer;
begin
  if PPortCollection(PortList)^.Search(Byte(PortName), I) then
    GetPort := PortList^.At(I)
  else GetPort := nil;
end;

function PortAccessible(A: Longint): PortRecPtr;
var
  P: PortRecPtr;
begin
  if A = 0 then
    if TermPort then
      if TheTerminal = nil then P := nil
      else P := PTerminal(TheTerminal)^.ComPort
    else P := PortList^.At(0)
  else P := GetPort(ComNameType(A - 1));
  PortAccessible := P;
  if P = nil then Error(36, 0); {RS-232 not initialized}
end;

procedure GetMemory(var P: Pointer; Size: Word);
var
  NewBlock: MemoryPtr;
begin
  P := MemAlloc(Size);
  if P = nil then Error(4,0);
  NewBlock := MemAlloc(SizeOf(MemoryType));
  if NewBlock = nil then
  begin
    FreeMem(P, Size);
    Error(4,0);
  end;
  NewBlock^.Block := P;
  NewBlock^.BlockSize := Size;
  MemoryList^.Insert(Pointer(NewBlock));
end;

function NewString(const S: String): Longint;
var
  P: Pointer;
begin
  GetMemory(P, Length(S) + 1);
  PString(P)^ := S;
  NewString := Longint(P);
end;

procedure FreeMemory(var P: Pointer);
var
  Index : Integer;
begin
  with MemoryList^ do
   if Search(P, Index) then
     AtFree(Index)
   else Error(4,-1); {Memory allocation error}
end;

procedure TermOutStr(const S: String);
var
  B: Byte;
begin
  for B := 1 to Length(S) do PTerminal(TheTerminal)^.GetChar(S[B]);
end;

 Procedure InitRTL(Params: PString);
  begin
   GetIntVec(1, SaveInt1Ptr);
   GetIntVec(3, SaveInt3Ptr);
   CtrlBreakHit := False;
   MemoryList := New(PMemoryCollection, Init(4, 4));
   FileList := New(PCollection, Init(4,4));
   PortList := New(PPortCollection, Init(4,4));
   ProgRunning := True;
   AbortProgram := False;
   ProgTerminated := False;
   TermPort := False;
   GetMem(IncomeSeq, SizeOf(String));
   IncomeSeq^ := '';
   ProgParams := Params;
  end;

 procedure DoneRTL;
 begin
   FreeMem(IncomeSeq, SizeOf(String));
   if PortList <> Nil then Dispose(PortList, Done);
   PortList := Nil;
   CloseAllFiles;
   if MemoryList <> Nil then Dispose(MemoryList, Done);
   MemoryList := Nil;
   CloseBar;
   SetIntVec(1, SaveInt1Ptr);
   SetIntVec(3, SaveInt3Ptr);
   ProgRunning := False;
 end;

 Procedure CheckAccess(Ptr : Pointer; AIndex : Longint);
 var
  Item : MemoryType;
  Index : Integer;
 begin
  Item.Block := Ptr;
  if not MemoryList^.Search(Ptr,Index) then Error(5,0)
   {'Invalid pointer operation',}
  else if MemoryType(MemoryList^.At(Index)^).BlockSize < Word(AIndex) then
   Error(23,0);{'Index out of range'}
 end;

 Function Transfer(A, B, C: Longint; W: Word): Longint;
 var
   Protocol: Byte;
   P: PortRecPtr;
   S: String;
 begin
   P := PortAccessible(C);
   if A = 0 then S := ''
   else S := CNFileName(PString(A)^);
   case B of
     1: Protocol := ASCII;
     2: Protocol := XModem;
     3: Protocol := YModem;
     4: Protocol := Kermit;
     5: Protocol := BPlus;
   else Protocol := ZModem;
   end;
   TransferFiles(P, W, Protocol, S);
   Transfer := AsyncStatus;
 end;

 Function Upload;
 begin
   Transfer(A, B, C, cmUpload);
 end;

 Function Download;
 begin
   Transfer(A, B, C, cmDownload);
 end;

function Dial;
var
  L: Longint;
  S: String;
begin
  if A = 0 then S := ''
  else S := PString(A)^;
  Message(Application, evCommand, cmTerminal, nil);
  if S = '' then
    if TheTerminal = nil then
    else with PTerminal(TheTerminal)^ do
    begin
      AbortDialing(True);
      DialList^.FreeAll;
    end
  else
  begin
    Message(Desktop, evBroadcast, cmDialQueue, @S);
    L := 0;
    Idle(L);
  end;
end;

 Function FSeek;
 begin
   if FileList^.IndexOf(Pointer(A)) = -1 then Error(28,0);{file not open}
   PDosStream(A)^.Seek(B);
   FSeek := PDosStream(A)^.Status;
   if PDosStream(A)^.Status <> stOk then PDosStream(A)^.Reset;
 end;

procedure TransmissionStatus;
begin
  LogEvent := lcCommun;
  DrawStatusLine('Transmission in progress. Esc aborts.');
end;

procedure ReceptionStatus;
begin
  LogEvent := lcCommun;
  DrawStatusLine('Reception in progress. Esc aborts.');
end;

procedure DeviceNotReadyStatus;
begin
  Message(Application, evBroadcast, cmNotReadyShow, nil);
  LogEvent := lcCommun;
  DrawStatusLine('Device not ready. Keep waiting or press Esc to abort.');
end;

 Function Send;
 type
   TSend = Array[1..4] of Char;
 var
   I: Integer;
   Result: Byte;
   P: PortRecPtr;
 begin
   P := PortAccessible(C);
   if not (Byte(B) in [1..4]) then Error(24, 0);{Value out of range}
{$IFDEF DEMO}
   Result := 0;
{$ELSE}
   for I := 1 to Byte(B) do
   begin
     if KbdAbort then
     begin
       AsyncStatus := ecUserAbort;
       Break;
     end;
     if not PutCharPrim(P, TSend(A)[I]) then Break;
     GiveTicks;
     if Clock <> nil then Clock^.Update;
     if Heap <> nil then Heap^.Update;
     if TheSpooler <> nil then TheSpooler^.ProcessItems;
   end;
   case AsyncStatus mod 10000 of
     ecOk: Result := 0;
     ecUserAbort: Result := 1;
     else Result := 2;
   end;
{$ENDIF}
   Send := Longint(Result);
 end;

 Function SendBlock;
 type
   TSendBlk = Array[1..64000] of Char;
 var
   I: Word;
   Result: Byte;
   P: PortRecPtr;
 begin
   P := PortAccessible(D);
   CheckAccess(Pointer(A), B);
   TransmissionStatus;
   for I := 1 to Word(B) do
   begin
{$IFDEF DEMO}
     Result := 0;
{$ELSE}
     if KbdAbort then
     begin
       AsyncStatus := ecUserAbort;
       Break;
     end;
     if not PutCharPrim(P, TSendBlk(Pointer(A)^)[I]) then Break;
{$ENDIF}
     if C = 0 then Message(Application, evBroadcast, cmUpdateBar, nil);
     GiveTicks;
     if Clock <> nil then Clock^.Update;
     if Heap <> nil then Heap^.Update;
     if TheSpooler <> nil then TheSpooler^.ProcessItems;
   end;
   case AsyncStatus mod 10000 of
     ecOk: Result := 0;
     ecUserAbort: Result := 1;
     else Result := 2;
   end;
   SendBlock := Longint(Result);
 end;

 Function SendString;
 var
   I: Byte;
   P: PortRecPtr;
 begin
   P := PortAccessible(B);
   if A <> 0 then for I := 1 to Length(PString(A)^) do
   begin
     if KbdAbort then
     begin
       AsyncStatus := ecUserAbort;
       Break;
     end;
     if not PutCharPrim(P, PString(A)^[I]) then Break;
   end;
   case AsyncStatus mod 10000 of
     ecOk: I := 0;
     ecUserAbort: I := 1;
     else I := 2;
   end;
   SendString := Longint(I);
 end;

 Function CheckRS;
 var
   P: PortRecPtr;
 begin
  P := PortAccessible(A);
  CheckRS := Longint(CharReady(P));
 end;

 Function Receive;
 type
   TReceive = Array[1..4] of Char;
 var
   I: Integer;
   Result: Byte;
   P: PortRecPtr;
 begin
   P := PortAccessible(D);
   if not (Byte(B) in [1..4]) then Error(24, 0);
   if (C = 0) or (C > FullTimeout div 18) then C := FullTimeout div 18;
   A := 0;
{$IFDEF DEMO}
   Result := 0;
{$ELSE}
   for I := 1 to Byte(B) do
   begin
     if KbdAbort then
     begin
       AsyncStatus := ecUserAbort;
       Break;
     end;
     DisableAsyncErrors;
     APCom.GetCharTimeout(P, TReceive(A)[I], TryTimeout);
     EnableAsyncErrors;
     if AsyncStatus <> ecOk then
     begin
       DeviceNotReadyStatus;
       APCom.GetCharTimeout(P, TReceive(A)[I], C * 18);
       Message(Application, evBroadcast, cmNotReadyHide, nil);
       StatusLine^.Update;
     end;
     GiveTicks;
     if Clock <> nil then Clock^.Update;
     if Heap <> nil then Heap^.Update;
     if TheSpooler <> nil then TheSpooler^.ProcessItems;
     if AsyncStatus <> ecOk then Break;
   end;
   case AsyncStatus mod 10000 of
     ecOk: Result := 0;
     ecUserAbort: Result := 1;
     ecBufferIsFull: Result := 2;
     ecTimeout: Result := 8;
     else Result := 4;
   end;
   if InBuffFree(P) = 0 then Result := Result or 2;
{$ENDIF}
   Receive := Longint(Result);
 end;

 Function ReceiveBlock;
 type
   TReceiveBlk = Array[1..64000] of Char;
 var
   I: Word;
   Result: Byte;
   P: PortRecPtr;
   S: String;
 begin
   P := PortAccessible(E);
   CheckAccess(Pointer(A), B);
   if (C = 0) or (C > FullTimeout div 18) then C := FullTimeout div 18;
   ReceptionStatus;
{$IFDEF DEMO}
   Result := 0;
{$ELSE}
   for I := 1 to Word(B) do
   begin
     if KbdAbort then
     begin
       AsyncStatus := ecUserAbort;
       Break;
     end;
     DisableAsyncErrors;
     APCom.GetCharTimeout(P, TReceiveBlk(Pointer(A)^)[I], TryTimeout);
     EnableAsyncErrors;
     if AsyncStatus <> ecOk then
     begin
       DeviceNotReadyStatus;
       APCom.GetCharTimeout(P, TReceiveBlk(Pointer(A)^)[I], C * 18);
       Message(Application, evBroadcast, cmNotReadyHide, nil);
       ReceptionStatus;
     end;
     if D = 0 then Message(Application, evBroadcast, cmUpdateBar, nil);
     GiveTicks;
     if Clock <> nil then Clock^.Update;
     if Heap <> nil then Heap^.Update;
     if TheSpooler <> nil then TheSpooler^.ProcessItems;
     if AsyncStatus <> ecOk then Break;
   end;
   case AsyncStatus mod 10000 of
     ecOk: Result := 0;
     ecUserAbort: Result := 1;
     ecBufferIsFull: Result := 2;
     ecTimeout: Result := 8;
     else Result := 4;
   end;
   if InBuffFree(P) = 0 then Result := Result or 2;
{$ENDIF}
   ReceiveBlock := Longint(Result);
 end;

function WaitForString;
var
  Ch: Char;
  N, L, I, StartTicks: Longint;
  P: PortRecPtr;
  Event: TEvent;
  SS: String[1];
  Match: String;
begin
  WaitForString := 0;
  P := PortAccessible(D);
  if C = 0 then IncomeSeq^ := '';
  if A = 0 then Match := ''
  else Match := StUpcase(PString(A)^);
  StartTicks := MemL[$40:$6C];
  if TermPort then TerminalDisabled := True;
  repeat
    if GetCharPrim(P, Ch) then
    begin
      SS := Ch;
      L := Longint(@SS);
      I := 1;
      N := 0;
      PrintS(N, I, L);
      if Length(IncomeSeq^) = 255 then System.Delete(IncomeSeq^, 1, 1);
      Inc(IncomeSeq^[0]);
      IncomeSeq^[Length(IncomeSeq^)] := TPString.Upcase(Ch);
    end;
    if Pos(Match, IncomeSeq^) <> 0 then
    begin
      WaitForString := 1;
      Break;
    end;
    NestedEventCount := 0;
    Application^.GetEvent(Event);
    Application^.HandleEvent(Event);
  until AbortProgram or CtrlBreakHit or
    (MemL[$40:$6C] - StartTicks > B * 18);
  TerminalDisabled := False;
end;

function GetRSMode(S: String; var Port: ComNameType; var Bd: Longint;
  var Pr: ParityType; var DB: DataBitType; var SB: StopBitType;
  var PA: Word; var IRQ: Byte; var CV: Byte;
  var HF: Word; var SF: Word): Boolean;
var
  Ps : Byte;
  Code : Integer;
  Result : Longint;
  SubStr : String;

procedure GetSubStr;
begin
  SubStr := '';
  while (Ps < Length(S)) and (S[Ps + 1] in IdChars) do
  begin
    Inc(SubStr[0]);
    SubStr[Length(SubStr)] := S[Ps + 1];
    Inc(Ps);
  end;
end;

function GetResult(Min, Max: Longint): Boolean;
begin
  GetSubStr;
  if SubStr <> '' then
  begin
    Val(SubStr, Result, Code);
    GetResult := (Code = 0) and (Result >= Min) and (Result <= Max);
  end
  else GetResult := False;
end;

label
  Done;
begin
  GetRSMode := False;
  UpcaseSt(S);
  DelChar(' ', S);

  {Port}
  Ps := Pos('COM', S);
  if Ps <> 1 then Exit;
  Inc(Ps, 2);
  if not GetResult(1, 8) then Exit;
  Port := ComNameType(Result - 1);
  {Baud}
  Ps := Pos(',', S);
  if (Ps = 0) or not GetResult(110, 115200) then Exit;
  Bd := Result;
  {Data}
  Ps := FIPos(',', S, Ps);
  if (Ps = 0) or not GetResult(5, 8) then Exit;
  DB := Result;
  {Stop}
  Ps := FIPos(',', S, Ps);
  if (Ps = 0) or not GetResult(1, 2) then Exit;
  SB := Result;
  {Parity}
  Ps := FIPos(',', S, Ps);
  if Ps = 0 then Exit;
  GetSubStr;
  if Pos('N', SubStr) <> 0 then Pr := NoParity
  else if Pos('O', SubStr) <> 0 then Pr := OddParity
  else if Pos('E', SubStr) <> 0 then Pr := EvenParity
  else if Pos('M', SubStr) <> 0 then Pr := MarkParity
  else if Pos('S', SubStr) <> 0 then Pr := SpaceParity
  else Exit;
  {Port}
  Ps := FIPos(',', S, Ps);
  if Ps = 0 then Goto Done;
  if not GetResult(0, $FFF) then Exit;
  PA := Result;
  {IRQ}
  Ps := FIPos(',', S, Ps);
  if Ps = 0 then Goto Done;
  if not GetResult(0, 99) then Exit;
  IRQ := Result;
  {Vector}
  Ps := FIPos(',', S, Ps);
  if Ps = 0 then Goto Done;
  if not GetResult(0, $FF) then Exit;
  CV := Result;
  {HWFlow}
  Ps := FIPos(',', S, Ps);
  if Ps = 0 then Goto Done;
  if not GetResult(0, $FF) then Exit;
  HF := Result;
  {SWFlow}
  Ps := FIPos(',', S, Ps);
  if Ps = 0 then Goto Done;
  if not GetResult(0, 3) then Exit;
  SF := Result;

Done:
  GetRSMode := True;
end;

 Function Init_RS;
 var
   Port: ComNameType;
   Bd: Longint;
   Pr: ParityType;
   DB: DataBitType;
   SB: StopBitType;
   I: Integer;
   P: PortRecPtr;
   PA, SavePA: Word;
   IRQ, SaveIRQ: Byte;
   CV, SaveCV: Byte;
   HF, SaveHF: Word;
   SF, SaveSF: Word;
 begin
   Init_RS := 0;
   Port := ComName;
   Bd := Baud;
   Pr := Parity;
   DB := DataBits;
   SB := StopBits;
   PA := 0;
   IRQ := 0;
   CV := 0;
   HF := HWFlow;
   SF := SWFlow;
   if (Pointer(A) <> nil) and (PString(A)^ <> '') then
     if (Length(PString(A)^) = 1) and
	(TPString.Upcase(PString(A)^[1]) = 'T') then
     begin
       if TheTerminal = nil then Message(
	 Application, evCommand, cmTerminal, nil);
       if (TheTerminal = nil) or
	  (PTerminal(TheTerminal)^.ComPort = nil) then
	 Error(36,0);  {RS-232 not initialized};
       TermPort := True;
       Init_RS := 1;
       Exit;
     end
     else if not GetRSMode(PString(A)^,
       Port, Bd, Pr, DB, SB, PA, IRQ, CV, HF, SF) then
	 Error(6,0);  {Invalid RS-232 init string}
   P := GetPort(Port);
   if P <> nil then SetLine(P, Bd, Pr, DB, SB)
   else
   begin
     SavePA := PortAddress;
     SaveIRQ := IRQNumber;
     SaveCV := COMVector;
     SaveHF := HWFlow;
     SaveSF := SWFlow;
     if PA <> 0 then PortAddress := PA;
     if IRQ <> 0 then IRQNumber := IRQ;
     if CV <> 0 then COMVector := CV;
     HWFlow := HF;
     SWFlow := SF;
     InitPortPrim(P, Port, Bd, Pr, DB, SB,
       InBufSize, OutBufSize, PortOptions);
     PortAddress := SavePA;
     IRQNumber := SaveIRQ;
     COMVector := SaveCV;
     HWFlow := SaveHF;
     SWFlow := SaveSF;
     if P <> nil then PortList^.Insert(P);
   end;
   Init_RS := Byte(AsyncStatus = ecOk);
 end;

 Function Done_RS;
 var
   I: Integer;
   L: Longint;
   P: PortRecPtr;
 begin
   if (A <> 0) and (Length(PString(A)^) = 1) and
      (TPString.Upcase(PString(A)^[1]) = 'T') then L := 0
   else L := A;
   P := PortAccessible(L);
   if TermPort and (TheTerminal <> nil) and
     (P = PTerminal(TheTerminal)^.ComPort) then
   begin
     Message(PTerminal(TheTerminal)^.Owner, evCommand, cmClose, nil);
     TermPort := TheTerminal <> nil;
   end
   else
   begin
     I := PortList^.IndexOf(P);
     if I <> -1 then PortList^.AtFree(I);
   end;
 end;

 procedure CloseBar;
 begin
   {$IFDEF Connect}
   Message(Application, evBroadcast, cmCloseBar, nil);
   {$ENDIF}
 end;

 Function GetCRC32(var B, A : Longint):Longint;
 var
  CRC :	Longint;
 begin
  CheckAccess(Pointer(A), B);
  CRC := -1;
  IncCRC(Pointer(A)^, Word(B), CRC);
  GetCRC32 := not CRC;
 end;

 Function AddL(var A, B : Longint):Longint;
 begin
  AddL := A + B;
 end;

 Function SubL(var A, B : Longint):Longint;
 begin
  SubL := A - B;
 end;

 Function DivL(var A, B : Longint):Longint;
 begin
  if B <> 0 then DivL := A Div B
  else Error(14,0);{Division by zero}
 end;

 Function MulL(var A, B : Longint):Longint;
 begin
  MulL := A * B;
 end;

 Function GetBuff;
 begin
  if (B > $ffe0) or (B < 1 ) then Error(19,0);{ Index > ffe0 }
  GetMemory(Pointer(A),B);
  FillChar(Pointer(A)^,Word(B),0);
  GetBuff := A;
 end;

 Function DispBuff(var A : Longint):Longint;
 begin
  FreeMemory(Pointer(A));
 end;

 Function ReadBuff;
 begin
{   if PtrRec(A).Seg <> PtrRec(PProgr).Seg then CheckAccess(Pointer(A),B);}
   case Byte(C) of
     0, 1: ReadBuff := PByteArray(A)^[B];
     2: ReadBuff := Integer(Addr(PByteArray(A)^[B])^);
     4: ReadBuff := LongInt(Addr(PByteArray(A)^[B])^);
     else Error(24, 0);{Value out of range}
   end;
 end;

 Function WriteBuff;
 begin
  case Byte(D) of
     0, 1:
       begin
	 CheckAccess(Pointer(A),B);
	 if C > 255 then Error(24,0);{Value out of range}
	 PByteArray(A)^[B] := Byte(C);
       end;
     2:
       begin
	 CheckAccess(Pointer(A),B+2);
	 if C > $ffff then Error(24,0);{Value out of range}
	 Integer(Addr(PByteArray(A)^[B])^) := Integer(C);
       end;
     4:
       begin
	 CheckAccess(Pointer(A),B+4);
	 Longint(Addr(PByteArray(A)^[B])^) := C;
       end;
     else Error(24, 0);{Value out of range}
   end;
  WriteBuff:=C;
 end;

 Function KeyPrs;
 var
  Event: TEvent;
 begin
   KeyPrs := 0;
   if TermPort then TerminalDisabled := True;
   NestedEventCount := 0;
   Application^.GetEvent(Event);
   Application^.HandleEvent(Event);
   if Event.What = evKeyDown then
     if A <> 0 then KeyPrs := Word(Event.KeyCode)
     else KeyPrs := Byte(Event.CharCode);
   TerminalDisabled := False;
 end;

 procedure File_Dialog(var Name: String);
 begin
   {$IFDEF Connect}
   if Name = '' then Name := HistoryStr(HistoryID, 0)
   else Name := lFExpand(Name);
   if not GetFileName(Name) then Error(31, 0); {Stop}
   {$ELSE}
   Write('Enter file name ');
   ReadLn(Name);
   {$ENDIF}
 end;

 Function FOpen;
 var
   PStream: PDosStream;
   W: Word;
   F: lFile;
   S: String;
 begin
  if FileList^.IndexOf(Pointer(A)) <> -1 then Error(9,0);
  { File already opened }
  if B = 0 then S := ''
  else S := CNFileName(PString(B)^);
  if (S = '') or IsWild(S) then
  begin
    File_Dialog(S);
    FOpen := NewString(S);
  end
  else FOpen := B;
  if C = 0 then
  begin {Reset}
    lAssignFile(F, S);
    lGetFattr(F, W);
    if DosError = 0 then W := stOpen
    else W := stCreate;
  end
  else W := stCreate;
  PStream := New(PDosStream,Init(S, W));
  if (PStream^.Status <> stOk) or IsDevice(PStream^.Handle) then
  begin
    Dispose(PStream,Done);
    Error(10,0); { Can't open file}
  end;
  FileList^.Insert(PStream);

  A := Longint(PStream);
  C := PStream^.GetSize;
  if PStream^.Status <> stOk then Error(10,0); { Can't open }
 end;

 Function FClose(var A : Longint):Longint;
 var
  Index : Integer;
  begin
   Index := FileList^.IndexOf(Pointer(A));
   if Index = -1 then Error(28,0); { File not open }
   FileList^.AtFree(Index);
{$IFDEF Connect}
   Message(Desktop, evBroadcast, cmUpdateTime, nil);
{$ENDIF}
  end;

 Function LoadUser;
 var
  F             : lFile;
  Size          : Longint;
  Result        : Word;
  NewBlock      : MemoryPtr;
  S             : String;

 procedure CloseAndShowError(Code: Integer);
 begin
   Close(F.F);
   InOutRes := 0;
   Error(Code, 0);
 end;

 begin
  if B = 0 then S := ''
  else S := CNFileName(PString(B)^);
  if (S = '') or IsWild(S) then
  begin
    File_Dialog(S);
    LoadUser := NewString(S);
  end
  else LoadUser := B;
  lAssignFile(F,S);
  lResetReadOnly(F,1);
  if IOResult <> 0 then Error(11,0); {User file not found}
  if IsDevice(FileRec(F.F).Handle) then
    CloseAndShowError(11); {User file not found}
  Size := FileSize(F.F);
  if Size > 64000 then
    CloseAndShowError(30); {User file too large}
  Pointer(A) := MemAllocSeg(Size + 32);
  if Pointer(A) = Nil then
    CloseAndShowError(4); { Out of memory }
  NewBlock := MemAlloc(SizeOf(MemoryType));
  if NewBlock = Nil then
    CloseAndShowError(4); { Out of memory }
  NewBlock^.Block := Pointer(A);
  NewBlock^.BlockSize  := Size + 32;
  MemoryList^.Insert(NewBlock);
  BlockRead(F.F,Pointer(A)^,Size,Result);
  if (IOResult <> 0) or ( Size <> Result) then
    CloseAndShowError(27);{Disk Error}
  Close(F.F);
  InOutRes := 0;
 end;

function MarkFunc: Longint;
begin
  MarkFunc := MemoryList^.Count;
end;

function ReleaseFunc(var A : Longint): Longint;
var
  I: Integer;
begin
  if A >= 0 then for I := MemoryList^.Count - 1 downto A do
    MemoryList^.AtFree(I);
end;

function GetProgParams: Longint;
var
  S: String;
begin
  if ProgParams = nil then S := ''
  else S := ProgParams^;
  GetProgParams := NewString(S);
end;

 procedure Stop(var A : Longint);
 begin
  if A = 0 then Error(31,0)
  else Error(A,0);
 end;

 Function User;
 begin
   User := UserPrim.User(C, B, A);
 end;

 Procedure CloseAllFiles;
  begin
   if FileList <> Nil then Dispose(FileList, Done);
   FileList := Nil;
   {$IFDEF Connect}
   Message(Desktop, evBroadcast, cmUpdateTime, nil);
   {$ENDIF}
  end;

 Function RDBLK;
 begin
  if FileList^.IndexOf(Pointer(A)) = -1 then Error(28,0);{file not open}
  CheckAccess(Pointer(B),C);
  PDosStream(A)^.ReadBlock(Pointer(B)^,Word(C),Word(C));
  if PDosStream(A)^.Status <> stOk then Error(27,0);{Disk Error}
  RDBLK:=C;
 end;

 Function WRBLK;
 begin
  if FileList^.IndexOf(Pointer(A)) = -1 then Error(28,0);{file not open}
  CheckAccess(Pointer(B),C);
  PDosStream(A)^.Write(Pointer(B)^,Word(C));
  if PDosStream(A)^.Status <> stOk then Error(27,0);{Disk Error}
  WRBLK:=C;
 end;

 Function PrintS;
 begin
{$IFDEF Connect}
  if TermPort and (C = 0) then
  begin
    if (TheTerminal = nil) or
       (PTerminal(TheTerminal)^.ComPort = nil) then
      Error(36, 0); {RS-232 not initialized};
    if B <> 0 then TermOutStr(PString(A)^)
    else TermOutStr(PString(A)^+#13#10);
  end
  else if B <> 0 then OutStr(PString(A)^)
  else OutStr(PString(A)^+#13#10);
{$ELSE}
  if B <> 0 then Write(PString(A)^)
  else WriteLn(PString(A)^);
{$ENDIF}
  PrintS := A;
 end;

 Function InputS(var A : Longint):Longint;
 var
  S : String;
  begin
     S := PString(A)^;
{$IFDEF Connect}
     if not GetString(S) then Error(31, 0);
{$ELSE}
     Write('Enter string ');
     ReadLn(S);
{$ENDIF}
     InputS := NewString(S);
  end;

 procedure FormatString(var S: String; A: Longint; const Form: String);
 begin
   if Form = '' then FormatStr(S, '%d', A)
   else if Upcase(Form[1]) = 'B' then
   begin
     if (Form[0] = #2) and (Upcase(Form[2]) = 'B') then
       S := BinaryB(A)
     else if (Form[0] = #2) and (Upcase(Form[2]) = 'W') then
       S := BinaryW(A)
     else S := BinaryL(A);
   end
   else FormatStr(S, '%' + Form, A);
 end;

 Function PrintV;
 var
   S, F: String;
 begin
  if C = 0 then F := '' else F := PString(C)^;
  FormatString(S, A, F);
{$IFDEF Connect}
  if TermPort and (D = 0) then
  begin
    if (TheTerminal = nil) or
       (PTerminal(TheTerminal)^.ComPort = nil) then
      Error(36, 0); {RS-232 not initialized};
    if B <> 0 then TermOutStr(S)
    else TermOutStr(S+#13#10);
  end
  else if B <> 0 then OutStr(S)
  else OutStr(S+#13#10);
{$ELSE}
  if B <> 0 then Write(S)
  else WriteLn(S);
{$ENDIF}
  PrintV := A;
 end;

 Function InputV(var A : Longint):Longint;
 var
   W: Word;
 begin
  {$IFDEF Connect}
  W := GetValue(A);
  if W = cmNo then
  else if W = cmCancel then Error(31, 0)
  else InputV := A;
  {$ELSE}
  Write('Enter value ');
  ReadLn(A);
  if IOResult <> 0 then Error(25, 0);
  InputV := A;
  {$ENDIF}
 end;

 Function RTS;
 var
   P: PortRecPtr;
 begin
   P := PortAccessible(B);
   SetRTS(P, Boolean(A));
   RTS := A;
 end;

 Function CTS;
 var
   P: PortRecPtr;
 begin
   P := PortAccessible(A);
   CTS := Longint(CheckCTS(P));
 end;

 Function DTR;
 var
   P: PortRecPtr;
 begin
   P := PortAccessible(B);
   SetDTR(P, Boolean(A));
   DTR := A;
 end;

 Function DSR;
 var
   P: PortRecPtr;
 begin
   P := PortAccessible(A);
   DSR := Longint(CheckDSR(P));
 end;

 Function DCD;
 var
   P: PortRecPtr;
 begin
   P := PortAccessible(A);
   DCD := Longint(CheckDCD(P));
 end;

 Function RING;
 var
   P: PortRecPtr;
 begin
   P := PortAccessible(A);
   RING := Longint(CheckRI(P));
 end;

 Function INDBAR;
 {$IFDEF Connect}
 var
   W: PBarWindow;
 {$ENDIF}
 begin
   {$IFDEF Connect}
   if not (Byte(A) in [0..1]) then Error(24, 0);
   if A = 0 then CloseBar
   else if Message(Application, evBroadcast, cmUpdateBar, nil) = nil then
     BarWindow('Progress bar', 'Device not ready.', B, Boolean(C));
   {$ENDIF}
 end;

function WriteStatus;
begin
{$IFDEF Connect}
  if A = 0 then StatusLine^.Update
  else
  begin
    if B = 0 then LogEvent := 0
    else LogEvent := 1 shl (B - 1);
    DrawStatusLine(PString(A)^);
  end;
{$ENDIF}
end;

 Function Let(var A, B : Longint):Longint;
 begin
  Let := B;
  A := B;
 end;

 Function LE(var A, B : Longint):Longint;
 begin
  LE := Longint(A <= B);
 end;

 Function GE(var A, B : Longint):Longint;
 begin
  GE := Longint(A >= B);
 end;

 Function EQ(var A, B : Longint):Longint;
 begin
  EQ := Longint(A = B);
 end;

 Function NE(var A, B : Longint):Longint;
 begin
  NE := Longint( A <> B);
 end;

 Function LS(var A, B : Longint):Longint;
 begin
  LS := Longint( A < B);
 end;

 Function GR(var A, B : Longint):Longint;
 begin
  GR := Longint( A > B);
 end;

 Function ANDL(var A, B : Longint):Longint;
 begin
  ANDL := A And B;
 end;

 Function ORL(var A, B : Longint):Longint;
 begin
  ORL := A OR B;
 end;

 Function XORL(var A, B : Longint):Longint;
 begin
  XORL := A XOR B;
 end;

 Function NOTL(var A : Longint):Longint;
 begin
  NOTL := NOT A;
 end;

 Function Empty(var A, B : Longint):Longint;
 begin
   {$IFDEF Connect}
   GiveTicks;
   if Clock <> nil then Clock^.Update;
   if Heap <> nil then Heap^.Update;
   if TheSpooler <> nil then TheSpooler^.ProcessItems;
   {$ENDIF}
   Empty := 0;
 end;

 Function Menu(var B, A : Longint):Longint;
 {$IFNDEF Connect}
 var
  F : Text;
  I : Byte;
  R : Longint;
  S : String;
 {$ENDIF}
 begin
   {$IFDEF Connect}
   Menu := Longint(GetStringNum(CNFileName(PString(A)^),
     Debugging or (B = 0), @AbortProgram));
   {$ELSE}
   Assign(F,PString(A)^);
   Reset(F);
   if IOResult <> 0 then
    begin
     Menu := 0;
     Exit;
    end;
   I := 1;
   WriteLn('Menu');
   while not eof(f) do
    begin
     Readln(F,S);
     if IOResult <> 0 then
     begin
      Menu := 0;
      Exit;
     end;
     Writeln(I,') ',S);
     Inc(I);
    end;
   Close(F);
   Write('Enter number ');
   ReadLn(R);
   if IOResult <> 0 then
     begin
      Menu := 0;
      Exit;
     end;
   Writeln(R);
   Menu := R;
   {$ENDIF}
 end;

Function Beep(var A, B : Longint) : Longint;
begin
 Sound(B);
 Delay(A);
 NoSound;
end;

function BlockUsed(P: Pointer; var Index: Integer): Boolean;
begin
  BlockUsed := (MemoryList <> nil) and MemoryList^.Search(P, Index);
end;

function Idle;
type
  PLong = ^Longint;
var
  Event: TEvent;
begin
  if (A <> 0) and TermPort then TerminalDisabled := True;
  NestedEventCount := 0;
  Application^.GetEvent(Event);
  Idle := PLong(@Event)^;
  Application^.HandleEvent(Event);
  TerminalDisabled := False;
end;

var
  CurEditor: PFileEditor;

procedure GetCurEditor;
var
  W: PView;

function IsASCII(P: PView): Boolean;
begin
  IsASCII := (P^.Options and ofASCII <> 0) and
    (P^.State and sfVisible <> 0) and not
    PFileEditor(PEditorWindow(P)^.Editor)^.IsDebug;
end;

begin
  W := Desktop^.FirstThat(@IsASCII);
  if W = nil then Error(18, 0);
  CurEditor := PFileEditor(PEditorWindow(W)^.Editor);
  CurEditor^.Owner^.Select;
end;

function NewWin;
var
  S: String;
begin
  if A = 0 then S := ''
  else S := PString(A)^;
  if (S = '') or IsWild(S) then File_Dialog(S)
  else S := lFExpand(S);
  Message(Application, evCommand, cmOpenASCII, @S);
  NewWin := Byte(
    Message(Application, evBroadcast, cmASCIIOpened, @S) <> nil);
end;

function PutStr;
var
  P: Byte;
  C: Char;
  S: String;
begin
  GetCurEditor;
  if A = 0 then Exit;
  S := PString(A)^;
  P := 1;
  while P <= Length(S) do
  begin
    if (S[P] = '^') and (P < Length(S)) then
    begin
      C := Upcase(S[P + 1]);
      if C in ['A'..'Z'] then
      begin
	Delete(S, P, 1);
	S[P] := Char(Byte(C) - $40);
      end;
    end;
    Inc(P);
  end;
  PutStrPrim(CurEditor, S);
  PutStr := 1;
end;

function PutKey;
var
  Event: TEvent;
begin
  if TermPort then TerminalDisabled := True;
  Pending.What := evKeyDown;
  Pending.KeyCode := Word(A);
  Pending.InfoPtr := nil;
  NestedEventCount := 0;
  Application^.GetEvent(Event);
  Application^.HandleEvent(Event);
  TerminalDisabled := False;
  PutKey := A;
end;

function GetStr;
var
  S: String;
begin
  GetCurEditor;
  with CurEditor^ do GetValidLine(Delta.Y + Cursor.Y, S);
  GetStr := NewString(S);
end;

function GetWrd;
var
  B, E: Byte;
  S: String;
begin
  GetCurEditor;
  S := CurEditor^.GetWord(B, E);
  GetWrd := NewString(S);
end;

function GetChr;
var
  S: String;
begin
  GetCurEditor;
  with CurEditor^ do
  begin
    GetValidLine(Delta.Y + Cursor.Y, S);
    if Delta.X + Cursor.X >= Length(S) then GetChr := 0
    else GetChr := Byte(S[Delta.X + Cursor.X + 1]);
  end;
end;

procedure GetSearchOptions(const S: String; var W: Word);
const
  NumOpts = 8;
  OpChars: Array[1..NumOpts] of Char =
    ('C', 'F', 'W', 'R', 'S', 'B', 'P', 'G');
  OpMasks: Array[1..NumOpts] of Byte =
    (1, 2, 4, 8, $10, $20, $40, $80);
var
  B, P: Byte;
begin
  for B := 1 to NumOpts do
  begin
    P := Pos(OpChars[B], S);
    if (P > 0) and (P < Length(S)) then
      if S[P + 1] = '+' then W := W or OpMasks[B]
      else if S[P + 1] = '-' then W := W and not OpMasks[B];
  end;
end;

procedure RegexpError;
begin
  MessageBox(^C'Invalid regular expression:'#13#13^C +
    RegError + '.', nil, mfError + mfOkButton);
  Error(31, 0);
end;

function Find;
var
  S: String;
begin
  GetCurEditor;
  if A = 0 then SearchData.MatchStr := ''
  else SearchData.MatchStr := PString(A)^;
  if B = 0 then S := ''
  else S := StUpcase(PString(B)^);
  if S <> '' then GetSearchOptions(S, SearchData.Options);
  if (SearchData.Options and frRegExp <> 0) and
     (SearchData.MatchStr <> '') and
     not ValidRegExp(SearchData.MatchStr) then RegexpError;
  if (SearchData.MatchStr = '') and
     (Application^.ExecuteDialog(LoadFindDialog(False, True, 0),
       @SearchData, False) = cmCancel) then Error(31, 0);
  CurEditor^.IsReplacing := True;
  Find := Byte(CurEditor^.Search(SearchData.MatchStr, SearchData.Options));
  CurEditor^.IsReplacing := False;
end;

function Replace;
var
  Flag: Boolean;
  S: String;
begin
  GetCurEditor;
  if A = 0 then ReplaceData.MatchStr := ''
  else ReplaceData.MatchStr := PString(A)^;
  if B = 0 then ReplaceData.NewString := ''
  else ReplaceData.NewString := PString(B)^;
  if C = 0 then S := ''
  else S := StUpcase(PString(C)^);
  if S <> '' then GetSearchOptions(S, ReplaceData.Options);
  if (ReplaceData.Options and frRegExp <> 0) and
     (ReplaceData.MatchStr <> '') and
     not ValidRegExp(ReplaceData.MatchStr) then RegexpError;
  if (ReplaceData.MatchStr = '') and (Application^.ExecuteDialog(
    LoadReplaceDialog(0), @ReplaceData, False) = cmCancel) then Error(31, 0);
  CurEditor^.DebugModified := False;
  Byte(Flag) := 2;
  CurEditor^.Replace(Flag);
  Replace := Byte(CurEditor^.DebugModified);
end;

function StoreBlock;
var
  S: String;
begin
  GetCurEditor;
  if A = 0 then S := ''
  else S := PString(A)^;
  if (S = '') or IsWild(S) then File_Dialog(S)
  else S := lFExpand(S);
  A := Byte(CurEditor^.WriteBlockToFile(S, False, False));
end;

function LoadBlock;
var
  S: String;
begin
  GetCurEditor;
  if A = 0 then S := ''
  else S := PString(A)^;
  if (S = '') or IsWild(S) then File_Dialog(S)
  else S := lFExpand(S);
  A := Byte(CurEditor^.ReadBlockFromFile(S, False));
  CurEditor^.DrawView;
  CurEditor^.Indicator^.DrawView;
end;

function GotoXY(var B, A: Longint): Longint;
var
  L: Longint;
  X, Y: Integer;
begin
  GetCurEditor;
  if A < 0 then X := 0
  else if A = 0 then X := CurEditor^.Delta.X + CurEditor^.Cursor.X
  else if A > CurEditor^.Limit.X then X := CurEditor^.Limit.X
  else X := A - 1;
  if B < 0 then Y := 0
  else if B = 0 then Y := CurEditor^.Delta.Y + CurEditor^.Cursor.Y
  else if B > CurEditor^.FileLines^.Count then
    Y := CurEditor^.FileLines^.Count
  else Y := B - 1;
  CurEditor^.GoToPos(X, Y);
  LongRec(L).Lo := X + 1;
  LongRec(L).Hi := Y + 1;
  GotoXY := L;
end;

function WhereCurX;
begin
  GetCurEditor;
  WhereCurX := CurEditor^.Delta.X + CurEditor^.Cursor.X + 1;
end;

function WhereCurY;
begin
  GetCurEditor;
  WhereCurY := CurEditor^.Delta.Y + CurEditor^.Cursor.Y + 1;
end;

function MaxY;
begin
  GetCurEditor;
  MaxY := CurEditor^.FileLines^.Count;
end;

function SetIns;
var
  B: Boolean;
begin
  GetCurEditor;
  B := CurEditor^.IsInsert;
  if B <> Boolean(A) then CurEditor^.ToggleInsert;
  SetIns := Byte(CurEditor^.IsInsert);
end;

function StrCompare;
var
  CS: CompareType;
  SA, SB: String;
begin
  if A = 0 then SA := ''
  else if C <> 0 then SA := StUpcase(PString(A)^)
  else SA := PString(A)^;
  if B = 0 then SB := ''
  else if C <> 0 then SB := StUpcase(PString(B)^)
  else SB := PString(B)^;
  CS := CompString(SA, SB);
  if CS = Less then StrCompare := 2
  else if CS = Greater then StrCompare := 1
  else StrCompare := 0;
end;

function StrConcat;
var
  SA, SB: String;
begin
  if A = 0 then SA := ''
  else SA := PString(A)^;
  if B = 0 then SB := ''
  else SB := PString(B)^;
  SA := Concat(SA, SB);
  StrConcat := NewString(SA);
end;

function StrPos;
var
  W: Word;
  Regex: Pointer;
  DelimSet: CharSet;
  SA, SB, SC: String;
begin
  if C = 0 then SC := ''
  else SC := StUpcase(PString(C)^);
  W := 0;
  if SC <> '' then GetSearchOptions(SC, W);
  if A = 0 then SA := ''
  else if W and frCaseSensitive = 0 then SA := StUpcase(PString(A)^)
  else SA := PString(A)^;
  if B = 0 then SB := ''
  else if W and frCaseSensitive = 0 then SB := StUpcase(PString(B)^)
  else SB := PString(B)^;
  if (W and frRegExp <> 0) and (SA <> '') then
  begin
    Regex := nil;
    Regex := RegCompile(SA);
    if (Regex = nil) and not ValidRegExp(SA) then RegexpError;
    SA := RegSearch(Regex, SB);
    RegFree(Regex);
    E := Length(SA);
  end;
  if W and frWholeWordsOnly <> 0 then
  begin
    DelimSet := [' '];
    if D <> 0 then for W := 1 to Length(PString(D)^) do
      Include(DelimSet, PString(D)^[W]);
    StrPos := WordPos(SA, SB, DelimSet, False);
  end
  else StrPos := Pos(SA, SB);
end;

function StrCopy;
var
  S: String;
begin
  if A = 0 then S := ''
  else S := PString(A)^;
  S := Copy(S, B, C);
  StrCopy := NewString(S);
end;

function StrDelete;
var
  S: String;
begin
  if A = 0 then S := ''
  else S := PString(A)^;
  Delete(S, B, C);
  StrDelete := NewString(S);
end;

function StrInsert;
var
  SA, SB: String;
begin
  if A = 0 then SA := ''
  else SA := PString(A)^;
  if B = 0 then SB := ''
  else SB := PString(B)^;
  Insert(SA, SB, C);
  StrInsert := NewString(SB);
end;

function StrUpcase;
var
  S: String;
begin
  if A = 0 then S := ''
  else S := PString(A)^;
  UpcaseSt(S);
  StrUpcase := NewString(S);
end;

function StrLocase;
var
  S: String;
begin
  if A = 0 then S := ''
  else S := PString(A)^;
  LocaseSt(S);
  StrLocase := NewString(S);
end;

function FrmtStr;
var
  S, F: String;
begin
  if B = 0 then F := '' else F := PString(B)^;
  FormatString(S, A, F);
  FrmtStr := NewString(S);
end;

end.
