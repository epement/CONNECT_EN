{$A+,B-,D-,E+,F+,G-,I-,L-,N+,O-,R-,S-,V-,X+}
{$DEFINE Connect}
unit Compiler;

interface

uses Objects, Drivers, LFN;

const
  Source: Pointer = nil;
  SaveCPUFlag: Boolean = False;
  Debugging: Boolean = False;
  ProgRunning: Boolean = False;
  ProgTerminated: Boolean = False;
  AbortProgram: Boolean = False;
  DebugCommand: Word = 0;
  CompileResult: Byte = 0;
  ProgramResult: Byte = 0;
  CPUInUse: Boolean = False;
  RevProg: Boolean = False;

  dcNothing = 0;
  dcRun = 1;
  dcReset = 2;
  dcGoTo = 3;
  dcTrace = 4;
  dcStep = 5;

  AnimateEvent: TEvent = (What: evNothing);
  AbortPending: TEvent = (What: evNothing);

  MaxKeyWords = 97;
  KeyWords: Array[1..MaxKeyWords] of String[6] =
    ('"', '&', '()', '*', '+', '-', '/', ';', '<', '<=', '<>', '=',
     '==', '>', '>=', '@', 'AND', 'BEEP', 'CHKRS', 'CLOSE', 'CMPSTR',
     'CONCAT', 'COPY', 'CRC32', 'CTS', 'DCD', 'DELETE', 'DIAL', 'DISBUF',
     'DNLOAD', 'DONERS', 'DSR', 'DTR', 'ELSE', 'FIND', 'FMTSTR', 'GETBUF',
     'GETCHR', 'GETSTR', 'GETWRD', 'GOSUB', 'GOTO', 'GOTOXY', 'IDLE', 'IF',
     'INDBAR', 'INITRS', 'INPUTS', 'INPUTV', 'INSERT', 'KEYPRS', 'LOCASE',
     'LODBLK', 'LODUSR', 'MARK', 'MAXY', 'MENU', 'NEWWIN', 'NOT', 'OPEN',
     'OR', 'PARAMS', 'POS', 'PRINTS', 'PRINTV', 'PUTKEY', 'PUTSTR', 'RDBLK',
     'RDBUF', 'RECBLK', 'RECEIV', 'RELEAS', 'REM', 'REPLAC', 'RET', 'RING',
     'RTS', 'SEEK', 'SEND', 'SETINS', 'SNDBLK', 'SNDSTR', 'STOBLK', 'STOP',
     'THEN', 'UPCASE', 'UPLOAD', 'USER', 'WAIT', 'WHEREX', 'WHEREY', 'WRBLK',
     'WRBUF', 'WRSTAT', 'XOR', '{L', '|');
  KeyCodes: Array[17..MaxKeyWords - 2] of Word =
    (1388, 5524, 21675, 22009, 20786, 21984, 5417, 21326, 1331, 1288,
     17221, 5336, 18674, 18608, 18891, 1374, 1346, 5257, 5228, 17458,
     18738, 18754, 18482, 18556, 20710, 5167, 17353, 6005, 354, 32374,
     31771, 31315, 31318, 31628, 31579, 27353, 27483, 27214, 5715, 5737,
     5757, 27866, 1416, 6042, 366, 4343, 1135, 1443, 1446, 1533, 1074,
     18011, 17970, 6299, 6370, 6919, 1145, 7303, 1120, 4463, 1059, 4559,
     4588, 6651, 5723, 5938, 3739, 4332, 4314, 4569, 4784, 4406, 4256,
     300, 301, 18139, 18098, 7888, 1262);

type
  PBreakRec = ^TBreakRec;
  TBreakRec = record
    Address: Pointer;
    Value: Byte;
  end;

  PBreaksCollection = ^TBreaksCollection;
  TBreaksCollection = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
    function Search(P: Pointer; var Index: Integer): Boolean; virtual;
  end;

  PointRec = record
    Offset, Segment: Word;
  end;

  Fn0 = Function : Longint;
  Fn1 = Function(Var A : Longint) : Longint;
  Fn2 = Function(Var A, B : Longint) : Longint;
  Fn3 = Function(Var A, B, C : Longint) : Longint;
  Fn4 = Function(Var A, B, C, D : Longint) : Longint;
  Fn5 = Function(Var A, B, C, D, E : Longint) : Longint;

  TGlobal = Array[0..100] of Longint;
  TProgr = Array[0..$FFF0] of Byte;

const
  PProgr: ^TProgr = nil;
  ProgrData: Pointer = nil;
  LineNumber: Integer = 0;
  InstrPtr: Word = 0;
  CurrentAddr: Word = 0;
  CurrentLine: Integer = 0;
  DebugLine: Integer = -1;

var
  BreaksCollection: PBreaksCollection;
  StackPtr : Word;
  TempIndex : Byte;
  LstFile : Text;
  LstFullName: TNameZ;
  ProgrSize, ProgrCodeSize, ProgrDataSize: Word;
  WriteToDisk: Boolean;
  CBPRName: FNameStr;

procedure Error(Code : Byte; Num: Integer);
procedure InitCompiler;
procedure DoneCompiler;
procedure InitSource(ASource: Pointer);
function GetData: Pointer;
function GetCommon: Pointer;
function GetCurrentAddr: Word;
function GetCurrentLine: Integer;
procedure Compile;
procedure Run;
procedure InitProgram(FName: String);
procedure DoneProgram;
procedure CompileDebug;
procedure RunDebug;
procedure CloseCPUWindow;
function AbortUserProgram: Boolean;
procedure RevProgram;
function GetParameter(Const AName: String; var Value: Longint): Boolean;
procedure SetParameter(Const AName: String; AValue: Longint);

Implementation

uses Views, Memory, App, Gauges, CompPrim, FEditor, Jump, Procs, Spooler,
  Terminal, EditMsg, DosTools, TPString, Commands, Defaults, Overlay;

procedure TBreaksCollection.FreeItem(Item: Pointer);
var
 P: Pointer;
begin
 if Item <> nil then
 begin
   P := PBreakRec(Item)^.Address;
   Byte(P^) := PBreakRec(Item)^.Value;
   FreeMem(Item, SizeOf(TBreakRec));
 end;
end;

function TBreaksCollection.Search(P: Pointer; var Index: Integer): Boolean;
begin
 if Count = 0 then Search := False
   else
 begin
   Index := Pred(Count);
   while (Index > 0) and (PBreakRec(At(Index))^.Address <> P) do Dec(Index);
   Search := PBreakRec(At(Index))^.Address = P;
 end;
end;

function ErrorString(Code: Byte): String;
var
  ErrorList: PStringList;
  S: String;
begin
  ErrorList := PStringList(Resource^.Get('COMPILERERRORS'));
  if ErrorList <> nil then
  begin
    S := ErrorList^.Get(Code);
    Dispose(ErrorList, Done);
  end
  else S := 'Resource file access error';
  ErrorString := S;
end;

procedure Error(Code : Byte; Num: Integer);
var
  Params: Array[0..1] of Longint;
  S, ES: String;
begin
{$IFDEF Connect}
  if Source <> nil then
  begin
    ES := ErrorString(Code);
    if ES = '' then ES := 'Internal error';
    Params[0] := Code;
    Params[1] := Num + 1;
    if Params[1] = 0 then FormatStr(S, 'Error %d: ' + ES + '.', Params[0])
    else
    begin
      FormatStr(S, 'Error %d (%d): ' + ES + '.', Params);
      PFileEditor(Source)^.GoToPos(0, Num);
    end;
    if LstFlag then
    begin
      WriteLn(LstFile, S);
      Close(LstFile);
    end;
    PFileEditor(Source)^.DrawError(S, Code);
  end;
{$ELSE}
  case Code of
    1  : ES := 'Out of memory';
    2  : ES := 'Program too large';
    3  : ES := '" expected';
    4  : ES := 'Collection error';
    5  : ES := 'Syntax error';
    6  : ES := 'Invalid "()"';
    7  : ES := '"(" expected';
    8  : ES := '")" expected';
    10 : ES := 'Invalid label';
    11 : ES := 'Error in expression';
    12 : ES := 'Duplicate labels';
    13 : ES := 'Invalid label position';
    14 : ES := 'Invalid IF position';
    15 : ES := 'Error in IF..THEN statement';
    16 : ES := 'Label expected';
    17 : ES := 'Write file error';
    18 : ES := 'Could not create output file';
    19 : ES := 'Unknown label';
    20 : ES := 'Invalid Goto address';
    21 : ES := 'File not found';
    22 : ES := '{ expected';
    23 : ES := 'Error in integer constant';
    else ES := 'Internal error';
  end;
  Writeln(ES, ' at line ',Num);
{$ENDIF}
  CompileResult := Code;
  LongJump;
end;

procedure InitCompiler;
begin
 SetJump;
 InstrPtr := 0;
 LineNumber := 0;
 CurrentAddr := 0;
 CurrentLine := 0;
 DebugLine := -1;
 CompileResult := 0;
 ProgramResult := 0;
 if MaxAvail > $fff0 + 10000 then ProgrSize := $fff0
 else ProgrSize := MaxAvail - 10000;
 PProgr := MemAllocSeg(ProgrSize);
 if PProgr = Nil then Error(1,-1);
 FillChar(PProgr^,ProgrSize,$90);
 Move(CStartCode,PProgr^,SizeOf(CStartCode));
 Inc(InstrPtr,SizeOf(CStartCode));
 IdColl := new(PIdColl, Init(10,10));
 LabValColl := new(PLabValColl, Init(10,10));
 FixLabelColl := new(PFixLabelColl, Init(10,10));
 LineColl := new(PLineColl, Init(10,10));
 LongJump;
end;

procedure DoneCompiler;
begin
 Source := nil;
 if IdColl <> nil then Dispose(IdColl,Done);
 IdColl := Nil;
 if LabValColl <> nil then Dispose(LabValColl,Done);
 LabValColl := Nil;
 if FixLabelColl <> nil then Dispose(FixLabelColl,Done);
 FixLabelColl := nil;
 if LineColl <> nil then Dispose(LineColl,Done);
 LineColl := Nil;
 if PProgr <> nil then FreeMem(PProgr,ProgrSize);
 PProgr := Nil;
end;

procedure InitSource(ASource: Pointer);
begin
  Source := ASource;
end;

procedure ErrRun(Code : Longint);
begin
  Fn1(Functions[0].FnAddr)(Code)
end;

procedure MainLoop;
label
  Loop;
var
  C: Word;
  Event: TEvent;
begin
  OpenCPUWindow := SaveCPUFlag;
  with PFileEditor(Source)^ do
  begin
    SourceLine := CurrentLine;
    GoToPos(Delta.X + Cursor.X, SourceLine);
    DrawView;
  end;
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
  Loop:
  DebugCommand := dcNothing;
  repeat
    NestedEventCount := 0;
    Application^.GetEvent(Event);
    if AnimateEvent.What <> evNothing then
    begin
      if (Event.What = evKeyDown) or (Event.What = evMouseDown) then
      begin
	AnimateEvent.What := evNothing;
	Application^.ClearEvent(Event);
      end
      else Event := AnimateEvent;
      if AnimateDelay <> 0 then Pause(AnimateDelay);
    end;
    Application^.HandleEvent(Event);
  until DebugCommand <> dcNothing;
  SaveCPUFlag := OpenCPUWindow;
  if DebugCommand = dcReset then LongJump;
  if PFileEditor(Source)^.DebugModified then
  begin
    C := ModifiedRebuildMsgBox;
    if C = cmCancel then Goto Loop
    else if C = cmNo then PFileEditor(Source)^.DebugModified := False
    else
    begin
      Pending.What := evCommand;
      Pending.Command := cmRun + DebugCommand - 1;
      LongJump;
    end;
  end;
end;

procedure Common(var V1, V2, V3, V4, V5 : Longint);
const
  Count: Integer = 0;
  MaxCount = 255;
Var
 Args : Byte;
 FnCode : Byte;
 InfIndex : Integer;
 DataSeg, Stack : Word;
 Result : Longint;
 LineInfo : TLineInfo;
begin
 asm
  mov FnCode,al
  mov DataSeg,ds
  mov ax,seg @Data
  mov ds,ax
  mov ax,word ptr [bp+2]
  mov CurrentAddr,ax
  mov Stack,bp
 end;

 Inc(Count);
 if Count > MaxCount then
 begin
   Count := 0;
   GiveTicks;
   if Clock <> nil then Clock^.Update;
   if Heap <> nil then Heap^.Update;
   if TheSpooler <> nil then TheSpooler^.ProcessItems;
 end;

 if LineColl <> nil then
 begin
   LineInfo.Addr := CurrentAddr;
   LineColl^.Search(Pointer(LineInfo),InfIndex);
   if InfIndex <> 0 then
   begin
     Pointer(LineInfo) := LineColl^.At(InfIndex-1);
     CurrentLine := LineInfo.LineNum;
   end
   else CurrentLine := -1;
 end;
 if StackPtr - Stack > $800 then Procs.Error(7,0);
 if CtrlBreakHit then Procs.Error(35, 0);
 if AbortProgram then Procs.Error(31, 0);
 if Debugging then with PFileEditor(Source)^ do
   if (CurrentLine >= 0) and (CurrentLine <= FileLines^.Count) then
   begin
     case DebugCommand of
       dcRun: if (DebugLine <> CurrentLine) and
         (IsBreakPoint(CurrentLine) <> -1) then MainLoop;
       dcGoTo: if (DebugLine <> CurrentLine) and
         (CurrentLine = Delta.Y + Cursor.Y) then MainLoop;
       dcTrace, dcStep: if DebugLine <> CurrentLine then MainLoop;
     end;
     if (DebugCommand = dcTrace) or
        (DebugCommand = dcGoTo) then OpenCPUWindow := SaveCPUFlag
     else OpenCPUWindow := False;
     DebugLine := CurrentLine;
     if SourceLine <> -1 then
     begin
       SourceLine := -1;
       if (DebugCommand = dcRun) or
          (DebugCommand = dcGoTo) then DrawView;
     end;
   end;
  if FnCode <> 255 then
   if FnCode >= $80 then Result := Fn2(OpsAddr[FnCode-$80])(V5,V4)
   else Result := Fn5(Functions[FnCode].FnAddr)(V1, V2, V3, V4, V5)
  else Result := 0;
 asm
  mov ax,Word ptr Result
  mov dx,Word ptr Result+2
  mov ds,DataSeg
  mov sp,bp
  pop bp
  retf
 end;
end;

function GetData : Pointer;
begin
 GetData := ProgrData;
end;

function GetCommon : Pointer;
begin
 GetCommon := @Common;
end;

Function GetCurrentAddr : Word;
begin
 GetCurrentAddr := CurrentAddr;
end;

Function GetCurrentLine : Integer;
begin
 GetCurrentLine := CurrentLine;
end;

procedure Run;
begin
  SetJump;
  if ProgramResult <> 0 then ErrRun(ProgramResult);
  with TStartCode(Pointer(PProgr)^) do
  begin
    if Signature <> 'CBPR' then ErrRun(2);
    LibFnAddr := Longint(@Common);
    ProgrDataSize := DataSize;
    ProgrData := MemAllocSeg(ProgrDataSize);
    if ProgrData = Nil then ErrRun(20);
    FillChar(ProgrData^, ProgrDataSize, 0);
    asm
      les ax,PProgr
      add ax,offset StartAddr
      push es
      push ax
      mov StackPtr,sp
      mov ds,PointRec(ProgrData).Segment
      retf
    end;
  end;
  LongJump;
end;

procedure InitProgram(FName: String);
var
  BytesRead: Word;
  P: Pointer;
  F: lFile;
begin
  ProgramResult := 0;
  CurrentLine := -1;
  CurrentAddr := 0;
  if PProgr <> nil then
  begin
    ProgrCodeSize := InstrPtr;
    OvrClearBuf;
    Move(PProgr^, Ptr(OvrHeapOrg, 0)^, ProgrCodeSize);
    FreeMem(PProgr, ProgrSize);
    P := MemAllocSeg(ProgrCodeSize);
    Move(Ptr(OvrHeapOrg, 0)^, P^, ProgrCodeSize);
    PProgr := P;
    Exit;
  end;
  lAssignFile(F, FName);
  lResetReadOnly(F, 1);
  if IOResult <> 0 then
  begin
    ProgramResult := 1;
    Exit;
  end;
  ProgrCodeSize := FileSize(F.F);
  PProgr := MemAllocSeg(ProgrCodeSize);
  if PProgr = nil then
  begin
    Close(F.F);
    ProgramResult := 20;
    Exit;
  end;
  BlockRead(F.F,PProgr^,ProgrCodeSize,BytesRead);
  if (IOResult <> 0) or (ProgrCodeSize <> BytesRead) then
    ProgramResult := 27;
  Close(F.F);
end;

procedure DoneProgram;
begin
  if PProgr <> nil then FreeMem(PProgr, ProgrCodeSize);
  PProgr := nil;
  if ProgrData <> nil then FreeMem(ProgrData, ProgrDataSize);
  ProgrData := nil;
end;

procedure ListVars;
var
 Index : Integer;
begin
 for Index :=  0 to IdColl^.Count-1 do
   WriteLn(LstFile,String(IdColl^.At(Index)^),' : ',HexW(Index shl 2),'H');
end;

procedure ListLabels;
var
 Index : Integer;
 PItem : PLabelValue;
begin
 for Index := 0 to LabValColl^.Count - 1 do
  begin
   PItem := LabValColl^.At(Index);
   with PItem^ do
    Writeln(LstFile,PLabel^,' : ', HexW(Value),'H');
  end;
end;

procedure CompileSource; far;
var
  DoUpdate: Boolean;
  I: Integer;
  L: Longint;
  LstName: FNameStr;
  S: String;
  OutFile : lFile;
begin
  SetJump;
  DoUpdate := False;
  with PFileEditor(Source)^ do
  begin
    DebugModified := False;
    if LstFlag then
    begin
      LstName := ForceExtension(FileName^, 'CBL');
      lAssignText(lText(Addr(LstFile)^), LstName);
      Rewrite(LstFile);
      if IOResult <> 0 then Error(18, -1);
    end;
    DrawStatusLine('Compiling ' + TrimmedName(FileName^, 57) + '.');
    for I := 0 to FileLines^.Count - 1 do
    begin
      GetValidLine(I, S);
      if LstFlag then WriteLn(LstFile, HexW(InstrPtr), 'H: ', S);
      if S <> '' then
      begin
        TrimSt(S);
        CompileString(S);
        L := LineNumber + 1;
        FormatStr(S, 'Compiling ' + TrimmedName(FileName^, 51) + ': %d', L);
        LogEvent := 0;
        DrawStatusLine(S);
      end;
      Inc(LineNumber);
    end;
    if LstFlag then WriteLn(LstFile, HexW(InstrPtr), 'H: Stop(31)');
    if LineColl^.Count = 0 then Error(5, 0);
    Pointer(L) := LineColl^.At(LineColl^.Count - 1);
    LineNumber := LongRec(L).Hi;
    CompileString('STOP(31)');
    if LstFlag then
    begin
      WriteLn(LstFile, 'Id : Value ');
      ListVars;
      WriteLn(LstFile, 'Label : Value ');
      ListLabels;
      Close(LstFile);
      DoUpdate := True;
    end;
    FixUp;
    TStartCode(Addr(PProgr^)^).DataSize := IdColl^.Count * 4;
    if WriteToDisk then
    begin
      S := ForceExtension(FileName^, 'CBB');
      lAssignFile(OutFile, S);
      lRewriteFile(OutFile, 1);
      if IOResult <> 0 then Error(18, -1);
      BlockWrite(OutFile.F, PProgr^, InstrPtr);
      if IOResult <> 0 then Error(17, -1);
      Close(OutFile.F);
      DoUpdate := True;
    end;
  end;
  if DoUpdate then
  begin
    Message(Desktop, evBroadcast, cmUpdateTime, nil);
    while (S <> '') and (S[Length(S)] <> '\') do Dec(S[0]);
    if S <> '' then Dec(S[0]);
    Message(Desktop, evBroadcast, cmReRead, @S);
  end;
  LongJump;
end;

procedure Compile;
begin
  if Source = nil then Exit;
  InitCompiler;
  if CompileResult <> 0 then Exit;
  WriteToDisk := True;
  CompileSource;
  DoneCompiler;
end;

procedure CompileDebug;
begin
  if Debugging or (Source = nil) then Exit;
  InitCompiler;
  if CompileResult <> 0 then Exit;
  WriteToDisk := False;
  CompileSource;
  if CompileResult <> 0 then DoneCompiler;
end;

procedure RunDebug;
begin
  if Debugging or (Source = nil) or (CompileResult <> 0) then Exit;
  Debugging := True;
  SaveCPUFlag := OpenCPUWindow;
  InitProgram('');
  InitRTL(nil);
  Run;
  DoneRTL;
  PFileEditor(Source)^.ProgramReset;
  DoneProgram;
  DoneCompiler;
  OpenCPUWindow := SaveCPUFlag;
  AnimateEvent.What := evNothing;
  Debugging := False;
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
  if AbortProgram then Pending := AbortPending;
  RevProg := True;
end;

procedure CloseCPUWindow;
begin
  if BreaksCollection <> nil then Dispose(BreaksCollection, Done);
  Message(Desktop, evBroadcast, cmDoneCPU, nil);
  CPUInUse := False;
end;

function AbortUserProgram: Boolean;
var
  C: Word;
  SavePending: TEvent;

function SpoolerEmpty: Boolean;
begin
  SpoolerEmpty := (TheSpooler^.Count = 0) or (SpoolerNotEmptyMsgBox = cmOk);
end;

begin
  AbortUserProgram := False;
  SavePending := Pending;
  Pending.What := evNothing;
  if ProtInProg then
  begin
    ProtInProgMsgBox('execute this command');
    Exit;
  end;
  if not SpoolerEmpty then Exit;
  if AbortProgram then C := 0
  else if Debugging then C := DebugMsgBox
  else if ProgRunning then
    case AbortUser of
      auYesAndDo: C := cmYes;
      auYesAndDoNot: C := cmNo;
      auNo: C := cmCancel;
      else C := RunMsgBox;
    end
  else C := 0;
  case C of
    0: AbortUserProgram := True;
    cmOk, cmYes, cmNo:
    begin
      AbortProgram := True;
      ProgTerminated := C = cmYes;
      AbortPending := SavePending;
      if Debugging then
        Message(Application, evCommand, cmProgramReset, nil);
    end;
  end;
end;

procedure RevProgram;
begin
  RevProg := False;
  Pending.What := evBroadcast;
  Pending.Command := cmLoadIcon;
end;

function GetParameter(Const AName: String; var Value: Longint): Boolean;
var
  B: Boolean;
  I: Integer;
  SS : String;
begin
  if IdColl = nil then B := False
  else
  begin
    SS := StUpCase(AName);
    B := IdColl^.Search(@SS, I);
    if B then Value := TGlobal(ProgrData^)[I];
  end;
  GetParameter := B;
end;

procedure SetParameter(Const AName: String; AValue: Longint);
var
  I: Integer;
  SS : String;
begin
  SS := StUpCase(AName);
  if (IdColl <> nil) and IdColl^.Search(@SS, I) then
    TGlobal(ProgrData^)[I] := AValue;
end;

end.