{$X+,O+,F+}
unit ExecPrim;

interface

uses Dos, Objects, Drivers, Views, Dialogs, ProgList, TPDate;

const
  mnSwap = 0;
  mnUnload = 1;
  mnNone = 2;
{ Added 2005.12.12 to support ExecNT }
  mnXNT = 3;
  mnArc = 4;
  mnView = 5;
  mnXView = 6;
  mnEdit = 7;
  mnXEdit = 8;
  mndBASE = 9;
  mnPanel = 10;
  mnIcon = 11;
  mnHelp = 12;
  mnHTML = 13;
  mnPrint = 14;
  mnMenu = 15;
  mnPrg = 16;
  mnEmpty = $FF;

  suSaveEditorFiles = 1;
  suSaveDesktop = 2;
  suLoadSnipper = 4;

  opMessage        = $0001;
  opLoadCOMMANDCOM = $0002;
  opSwapToDisk     = $0004;
  opNoRedraw       = $0020;
  opNoReread       = $0040;
  opNoMsgWin       = $0080;
  opNoXfer         = $0100;
  opUserScr        = $0800;
  opStdError       = $1000;
  opInfoBit        = $4000;
  opPrepared       = $8000;

  ProgramCalled: Boolean = False;
  MultiExec: Boolean = False;

  SourceName: FNameStr = '';

  IconParams: PString = nil;

  PrgName = 'CONNECT.PRG';
  ExtName = 'CONNECT.EXT';
  ViewerName = 'CONNECT.VIE';
  QuickViewerName = 'CONNECT.QVW';
  ExecRecName = 'CONNECT.EXR';
  SelListName = 'SELECTED.LST';
  CmdFileName = 'CONNECT.CMD';

  slAddPath = $01;
  slAddSize = $02;
  slAddTime = $04;
  slAddAttr = $08;
  slSkipDir = $10;
  slBkSlash = $20;
  slLQuotes = $40;
  slAppend  = $80;
  SelListOptions: Byte = 0;

  SelListDateMask: DateString = '';
  SelListTimeMask: DateString = '';
  SelListPrefixStr: String[63] = '';
  SelListSuffixStr: String[63] = '';

var
  ExecRec: TExecRec;
  ExecMem: Longint;

procedure SetPrgName(P: PString; var Name: FNameStr);
procedure ProgDlg(P: PString);
procedure UserMenuDlg(P: PString; Alt: Boolean);
procedure ExecHotKey(var Event: TEvent);
procedure WaitForProgram;
procedure ExtDlg(const AFocusName: FNameStr);
procedure ViewDlg(const AFocusName: FNameStr);
function ExtractExecRec(var Rec: TExecRec;
  const Name: FNameStr; AKey: Word; Viewer: Boolean): Boolean;

function ValidateParams(var Params: String): Boolean;
procedure PrepareExecEvent;
function PrepareExecPrim: Boolean;
procedure CancelExecution;
procedure LoadMultiExecRec;
procedure SaveMsgFilters;

{ Added 2005.12.12 to support ExecNT }
function ExecNT: Longint;

implementation

uses
  Memory, App, MsgBox, Hotkeys, KeyDlg, Funcs, HistList, History, HistWin,
  Desktops, ExtList, EditMsg, EditFile, FMUsrMnu, FMSecond, DirPrim, Swaps,
  ProgPath, RevPos, StrFiles, Strings, Spooler, EnvDlg, UserScr, HeapUMB,
  Clipbrd, LFN, DosTools, Disks, StrCol, TPString, Consts, Commands, Defaults;

const
  ExecCollection: PCollection = nil;
  ExecColIndex: Integer = 0;
  ExecColPos: Word = 0;

  smNot = 0;
  smShort = 1;
  smLong = 2;
  SourceMsgSent: Byte = smNot;

(*
function DataAddress(P: Pointer): Pointer;
type
  SO = record
    O, S: Word;
  end;
  JumpInstr = record
    Opcode: Byte;
    Address: Pointer;
  end;
begin
  if SO(P).S <> CSeg then DataAddress := JumpInstr(P^).Address
  else DataAddress := P;
end;

{$L EXECMAC.OBJ}
procedure EXECDirectives; external;

type
  PExecDirectives = ^TExecDirectives;
  TExecDirectives = Array[edXVIEW..edMEM] of String[8];

function Directives(Index: Integer): String;
begin
  Directives := PExecDirectives(DataAddress(@EXECDirectives))^[Index];
end;
*)

const
  edFirst    = 0;
  edARC      = 0;
  edCLIP     = 1;
  edCMD      = 2;
  edCN       = 3;
  edCURDIR   = 4;
  edDAY      = 5;
  edDBASE    = 6;
  edDIRARC   = 7;
  edDIRNAME  = 8;
  edEDIT     = 9;
  edENV      = 10;
  edERR      = 11;
  edEXT      = 12;
  edFILTER   = 13;
  edFINDDIR  = 14;
  edFINDFST  = 15;
  edFINDNAME = 16;
  edFNAME    = 17;
  edFYEAR    = 18;
  edGET      = 19;
  edHELP     = 20;
  edHIST     = 21;
  edHOUR     = 22;
  edHREF     = 23;
  edHTML     = 24;
  edICON     = 25;
  edKBD      = 26;
  edLCURDIR  = 27;
  edLEFT     = 28;
  edLEXT     = 29;
  edLFINDFST = 30;
  edLFNAME   = 31;
  edLGET     = 32;
  edLLEFT    = 33;
  edLNAME    = 34;
  edLOEXT    = 35;
  edLONAME   = 36;
  edLOPATH   = 37;
  edLOPP     = 38;
  edLPATH    = 39;
  edLRIGHT   = 40;
  edLSEL     = 41;
  edMAC      = 42;
  edMEM      = 43;
  edMENU     = 44;
  edMIN      = 45;
  edMONTH    = 46;
  edMSEC     = 47;
  edMSG      = 48;
  edNAME     = 49;
  edNMW      = 50;
  edNOMSGWIN = 51;
  edNOREDRAW = 52;
  edNOREREAD = 53;
  edNRD      = 54;
  edNRR      = 55;
  edNTM      = 56;
  edOEXT     = 57;
  edONAME    = 58;
  edOPATH    = 59;
  edOPPOSITE = 60;
  edPANEL    = 61;
  edPATH     = 62;
  edPRG      = 63;
  edPRINT    = 64;
  edPROMPT   = 65;
  edPUT      = 66;
  edRDBLK    = 67;
  edREPORT   = 68;
  edRIGHT    = 69;
  edSAMEWIN  = 70;
  edSEC      = 71;
  edSEL      = 72;
  edSET      = 73;
  edSLAPPEND = 74;
  edSLATTR   = 75;
  edSLBKSLSH = 76;
  edSLDMASK  = 77;
  edSLPATH   = 78;
  edSLPREFIX = 79;
  edSLQUOTES = 80;
  edSLSIZE   = 81;
  edSLSKIPD  = 82;
  edSLSUFFIX = 83;
  edSLTIME   = 84;
  edSLTMASK  = 85;
  edSWAPDIR  = 86;
  edUSERSCR  = 87;
  edUSR      = 88;
  edVIEW     = 89;
  edVM       = 90;
  edWINCLIP  = 91;
  edWORD     = 92;
  edWRBLK    = 93;
  edXEDIT    = 94;
  edXM       = 95;
  edXNT      = 96;
  edXVIEW    = 97;
  edXW       = 98;
  edXX       = 99;
  edYEAR     = 100;
  edLast     = 100;

  Directives: Array[edFirst..edLast] of String[8] =
    ('ARC',      'CLIP',     'CMD',      'CN',       'CURDIR',
     'DAY',      'DBASE',    'DIRARC',   'DIRNAME',  'EDIT',
     'ENV',      'ERR',      'EXT',      'FILTER',   'FINDDIR',
     'FIND1ST',  'FINDNAME', 'FNAME',    'FYEAR',    'GET',
     'HELP',     'HIST',     'HOUR',     'HREF',     'HTML',
     'ICON',     'KBD',      'LCURDIR',  'LEFT',     'LEXT',
     'LFIND1ST', 'LFNAME',   'LGET',     'LLEFT',    'LNAME',
     'LOEXT',    'LONAME',   'LOPATH',   'LOPP',     'LPATH',
     'LRIGHT',   'LSEL',     'MAC',      'MEM',      'MENU',
     'MIN',      'MONTH',    'MSEC',     'MSG',      'NAME',
     'NMW',      'NOMSGWIN', 'NOREDRAW', 'NOREREAD', 'NRD',
     'NRR',      'NTM',      'OEXT',     'ONAME',    'OPATH',
     'OPPOSITE', 'PANEL',    'PATH',     'PRG',      'PRINT',
     'PROMPT',   'PUT',      'RDBLK',    'REPORT',   'RIGHT',
     'SAMEWIN',  'SEC',      'SEL',      'SET',      'SLAPPEND',
     'SLATTR',   'SLBKSLSH', 'SLDMASK',  'SLPATH',   'SLPREFIX',
     'SLQUOTES', 'SLSIZE',   'SLSKIPD',  'SLSUFFIX', 'SLTIME',
     'SLTMASK',  'SWAPDIR',  'USERSCR',  'USR',      'VIEW',
     'VM',       'WINCLIP',  'WORD',     'WRBLK',    'XEDIT',
     'XM',       'XNT',      'XVIEW',    'XW',       'XX',
     'YEAR');

  XXRecur: Boolean = False;
  XXNamePtr: PString = nil;

{ Added 2005.12.12 to support ExecNT }
const
  CmdBufSize = $1000;
  CmdBuf: PByteArray = nil;
  CmdBufLen: Word = 0;
  XNTFlags: Longint = 0;
  XNTOptions: Longint = 0;

procedure SetAssocName(const MaskName: FNameStr; var Name: FNameStr);
begin
  if LocalAssocs then
  begin
    GetCurDir(0, Name);
    repeat
      Name := AddedSlash(Name) + MaskName;
      LogEvent := lcDiskRead;
      DrawStatusLine('Searching for local association file ' +
        TrimmedName(Name, 30) + '.');
      if ThisFileExists(Name) then Exit;
      if Length(Name) < Length(MaskName) + 5 then Break;
      Name := PrevDir(JustPathName(Name));
    until False;
  end;
  Name := ConfigPath + MaskName;
end;

procedure SetPrgName(P: PString; var Name: FNameStr);
var
  I, Code: Integer;
  S: String;
begin
  if P <> nil then
  begin
    S := P^;
    I := Pos(' ', S);
    if I <> 0 then
    begin
      Val(Trim(Copy(S, I + 1, 255)), LastProgIndex, Code);
      if LastProgIndex > 0 then Dec(LastProgIndex);
      S[0] := Char(I - 1);
    end
    else LastProgIndex := 0;
    Name := lFExpand(S);
  end
  else SetAssocName(PrgName, Name);
end;

procedure SetExtName(var Name: FNameStr);
begin
  SetAssocName(ExtName, Name);
end;

procedure SetViewerName(var Name: FNameStr);
begin
  SetAssocName(ViewerName, Name);
end;

procedure SetQuickViewerName(var Name: FNameStr);
begin
  SetAssocName(QuickViewerName, Name);
end;

procedure SetExecRecName(var Name: FNameStr);
begin
  Name := ConfigPath + ExecRecName;
end;

procedure ProgDlg(P: PString);
var
  Name: FNameStr;
begin
  SetPrgName(P, Name);
  if Application^.ExecuteDialog(
    New(PProgDialog, Init(Name, '')), @ExecRec, True) <> cmCancel then
      PrepareExecEvent;
end;

procedure UserMenuDlg(P: PString; Alt: Boolean);
var
  Name: FNameStr;
begin
  if Alt then LocalAssocs := not LocalAssocs;
  SetPrgName(P, Name);
  if Alt then LocalAssocs := not LocalAssocs;
  if Application^.ExecuteDialog(
    New(PUserMenuDialog, Init(Name, '')), @ExecRec, True) <> cmCancel then
      PrepareExecEvent;
end;

procedure ReadPrograms(Name: FNameStr; var Programs: PCollection);
var
  Item: PExecItem;
  S: TDosStream;
begin
  Programs := New(PCollection, Init(16, 16));
  LogEvent := lcDiskRead;
  DrawStatusLine('Loading programs from ' + TrimmedName(Name, 45) + '.');
  S.Init(Name, stOpenRead);
  if S.Status = stOk then
  begin
    while not LowMemory do
    begin
      Item := PExecItem(S.Get);
      if S.Status <> stOk then
      begin
        CouldNotReadMsgBox(Name);
        Break;
      end
      else if Item = nil then Break;
      Programs^.Insert(Item);
    end;
  end;
  S.Done;
end;

procedure ExecHotKey(var Event: TEvent);
var
  Found: Boolean;
  KbdState: Byte;
  Key: Word;
  I: Integer;
  P: PExecItem;
begin
  KbdState := GetShiftState;
  Key := Event.KeyCode;
  GlobalSequence[ExecColPos] := Key;
  Found := False;
  while ExecColIndex < ExecCollection^.Count do
  begin
    P := ExecCollection^.At(ExecColIndex);
    if P = nil then Break;
    if (ExecColPos = 0) and SameKey(Key, P^.HotKey) then
    begin
      Found := True;
      Break;
    end;
    if (P^.HotKey = hkSeq) and (ExecColPos < P^.HotKeyCount) and
      SameSequence(GlobalSequence, P^.HotKeySequence^, ExecColPos + 1) and
      HotKeyOptMatch(KbdState, P^.HotKeyOpt, ExecColPos) then
    begin
      if ExecColPos = P^.HotKeyCount - 1 then
      begin
        Found := True;
        Break;
      end;
      DrawSequenceStatusLine(ExecColPos);
      Inc(ExecColPos);
      Event.What := evNothing;
      Exit;
    end;
    Inc(ExecColIndex);
  end;
  if Found then
  begin
    P^.GetData(ExecRec, Key);
    PrepareExecEvent;
  end;
  Dispose(ExecCollection, Done);
  ExecCollection := nil;
  ExecColIndex := 0;
  ExecColPos := 0;
  ProgramCalled := False;
end;

procedure WaitForProgram;
var
  S: FNameStr;
begin
  if ExecCollection = nil then
  begin
    SetPrgName(nil, S);
    ReadPrograms(S, ExecCollection);
  end;
  StatusLine^.Update;
  DrawStatusLine('Waiting for user program hotkey.');
  ProgramCalled := True;
end;

procedure ExtDlg(const AFocusName: FNameStr);
var
  Name: FNameStr;
begin
  SetExtName(Name);
  Application^.ExecuteDialog(
    New(PAssocDialog, Init(Name, AFocusName, False)), @ExecRec, False);
end;

procedure ViewDlg(const AFocusName: FNameStr);
var
  Name: FNameStr;
begin
  if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
    SetQuickViewerName(Name)
  else SetViewerName(Name);
  Application^.ExecuteDialog(
    New(PAssocDialog, Init(Name, AFocusName, True)), @ExecRec, False);
end;

function ExtractExecRec(var Rec: TExecRec;
  const Name: FNameStr; AKey: Word; Viewer: Boolean): Boolean;
var
  Found, NextFound: Boolean;
  W: Word;
  Item, NextItem: PExecItem;
  List: PCollection;
  S: TDosStream;
  FName: FNameStr;
  Mask, Title, Condition: String;

procedure GetAssocSelection;
const
  AssocHistoryID = 199;
var
  B: Boolean;
  C: Word;
  I: Integer;
  P: PHistoryRec;
  W: PHistoryWindow;
  R: TRect;
begin
  Rec.Path := #0;
  Found := False;

  List := New(PCollection, Init(4, 4));
  List^.Insert(Item);
  repeat
    List^.Insert(NextItem);
    NextItem := PExecItem(S.Get);
    if NextItem <> nil then
    begin
      if (S.Status = stOk) and (NextItem^.HotKey = AKey) and
         (NextItem^.Title <> nil) and not LowMemory then
      begin
        SplitExecTitle(NextItem, Mask, Title, Condition);
        if WildCardMatch(Name, Mask) then Continue;
      end;
      Dispose(NextItem, Done);
    end;
    Break;
  until False;

  for I := 0 to List^.Count - 1 do
  begin
    Item := List^.At(I);
    SplitExecTitle(Item, Mask, Title, Condition);
    B := Condition <> '';
    if B then Break;
  end;

  if B then
  begin
    for I := List^.Count - 1 downto 0 do
    begin
      Item := List^.At(I);
      SplitExecTitle(Item, Mask, Title, Condition);
      if not ConditionOK(Condition) then List^.AtFree(I);
    end;

    if List^.Count <= 1 then
    begin
      if List^.Count = 1 then
      begin
        Item := List^.At(0);
        List^.AtDelete(0);
        Found := True;
      end;
      Dispose(List, Done);
      Exit;
    end;
  end;

  for I := List^.Count - 1 downto 0 do
  begin
    Item := List^.At(I);
    SplitExecTitle(Item, Mask, Title, Condition);
    if Title = '' then Title := 'Untitled';
    PadSt(Title, ExecTitleLen + 2);
    if Item^.Path <> nil then Title := Title + Item^.Path^;
{
    GetMem(P, SizeOf(THistoryRec));
    P^.StrPtr := NewStr(Title);
}
    GetMemUMB(P, SizeOf(THistoryRec));
    P^.StrPtr := NewStrUMB(Title);
    P^.Id := AssocHistoryId;
    if I < 9 then Byte(P^.Lock) := I + $31
    else P^.Lock := False;
    HistoryList^.Insert(P);
  end;

  if Viewer then Title := 'viewers'
  else Title := 'associations';
  GetHistWinBounds(AssocHistoryID, '', R);
  R.B.X := R.A.X + 38;
  W := New(PSpecialHistWindow, Init(R, AssocHistoryID));
  DisposeStr(W^.Title);
  W^.Title := NewStr(Mask + ' ' + Title);
  W^.Options := W^.Options or ofCentered;
  W^.HelpCtx := hcAssocHistory;
  if Application^.ValidView(W) <> nil then
  begin
    C := Desktop^.ExecView(W);
    if C = cmOk then
    begin
      I := W^.Viewer^.Focused;
      Item := List^.At(I);
      List^.AtDelete(I);
      Found := True;
    end;
    Dispose(W, Done);
  end;
  ClearHistoryId(AssocHistoryID);
  Dispose(List, Done);
end;

begin
  Rec.Path := '';
  Found := False;
  NextFound := False;
  if Byte(Viewer) = 2 then SetQuickViewerName(FName)
  else if Viewer then SetViewerName(FName)
  else SetExtName(FName);
  S.Init(FName, stOpenRead);
  while not Found and (S.Status = stOk) do
  begin
    Item := PExecItem(S.Get);
    if Item <> nil then
    begin
      if (Item^.HotKey = AKey) and (Item^.Title <> nil) then
      begin
        SplitExecTitle(Item, Mask, Title, Condition);
        Found := WildCardMatch(Name, Mask);
        if Found then
        begin
          NextItem := PExecItem(S.Get);
          if NextItem <> nil then
          begin
            if (NextItem^.HotKey = AKey) and (NextItem^.Title <> nil) then
            begin
              SplitExecTitle(NextItem, Mask, Title, Condition);
              NextFound := WildCardMatch(Name, Mask);
              if NextFound then
              begin
                GetAssocSelection;
                Break;
              end;
            end;
            if not NextFound then Dispose(NextItem, Done)
          end;
        end;
      end;
      if not Found then Dispose(Item, Done)
    end;
  end;
  S.Done;
  if Found then
  begin
    SplitExecTitle(Item, Mask, Title, Condition);
    Item^.GetData(Rec, W);
    Dispose(Item, Done);
    ExtractExecRec := (Rec.Path <> '') and ConditionOk(Condition);
  end
  else ExtractExecRec := False;
end;

procedure GetValidSource(Long: Boolean);
var
  P: PString;
begin
  if SourceMsgSent = Byte(Long) + 1 then Exit;
  if XXNamePtr <> nil then P := XXNamePtr
  else P := Message(Application, evBroadcast, cmGetSource, nil);
  if P = nil then SourceName := ''
  else
  begin
    SourceName := P^;
    if (XXNamePtr = nil) and not Long then
      lGetShortFileName(SourceName, SourceName);
  end;
  SourceMsgSent := Byte(Long) + 1;
end;

procedure GetOppSource(Long: Boolean; var Name: FNameStr);
var
  P: PString;
begin
  P := Message(Application, evBroadcast, cmGetOppSource, nil);
  if P = nil then Name := ''
  else
  begin
    Name := P^;
    if not Long then lGetShortFileName(Name, Name);
  end;
end;

procedure GetValidArcDir(var Name: FNameStr);
var
  P: PString;
begin
  P := Message(Application, evBroadcast, cmGetArcDir, nil);
  if P = nil then Name := ''
  else Name := P^;
{  UpcaseSt(Name);}
end;

procedure ConvertExecStr(const P: String; var S: String);
var
  I: Integer;
begin
  S := '';
  for I := 1 to Length(P) do
  begin
    Inc(S[0]);
    if P[I] = '(' then S[I] := ''
    else if P[I] = ')' then S[I] := ''
    else S[I] := TPString.Upcase(P[I]);
  end;
end;

procedure InvalidVMMsgBox;
begin
  MessageBox(
    ^C'Bad or missing custom video mode parameter. Valid range is: 0..255',
    nil, mfError + mfOkButton);
end;

function ValidateParams(var Params: String): Boolean;
const
  MaxKeys = 16;
var
  Cancel, CmdFlag: Boolean;
  B, E, K, P, Code: Integer;
  L: Longint;
  PS: PString;
  Keys: Array[0..MaxKeys - 1] of Word;
  F: lText;
  S, CS, ES, Name, CmdName: String;

{ Added 2005.12.08 to store params in file instead of string }
procedure SaveCmdBuf;
var
  F: lFile;
begin
  lAssignFile(F, CmdName);
  lRewriteFile(F, 1);
  if IOResult <> 0 then Exit;
  if NotAccessible(FileRec(F.F).Handle) then
  begin
    Close(F.F);
    InOutRes := 0;
    Exit;
  end;
  BlockWrite(F.F, CmdBuf^[1], CmdBufLen);
  Close(F.F);
  InOutRes := 0;
end;

procedure ReplaceText(Count: Integer);
var
  I: Integer;
begin
  Delete(CS, P, Count);
  Insert(Name, CS, P);
  Delete(ES, P, Count);
  Insert(Name, ES, P);
{ Added 2005.12.08 to store params in file instead of string }
  if CmdBuf <> nil then
  begin
    I := Length(Name) - Count;
    if CmdBufLen + I >= CmdBufSize - 2 then Exit;
    Move(CmdBuf^[P + Count], CmdBuf^[P + Count + I],
      CmdBufLen - P - Count + 1);
    Move(Name[1], CmdBuf^[P], Length(Name));
    Inc(CmdBufLen, I);
  end;
end;

procedure FindClosingArrow;
var
  C: Byte;
begin
  C := 0;
  E := B;
  while (E <> 0) and (E <= Length(ES)) do
  begin
    if ES[E] = '' then Inc(C)
    else if ES[E] = '' then
      if C <> 0 then Dec(C) else Exit;
    Inc(E);
  end;
end;

procedure ProcessOpenDirective(const Directive: String);
begin
  B := P + Length(Directive) + 1;
  if (Length(ES) >= B) and (ES[B] = '') then
  begin
    Inc(B);
    FindClosingArrow;
    Name := Copy(CS, B, E - B);
  end
  else if Directive[1] = 'A' then Name := '$' + Directive
  else
  begin
    GetValidSource(True);
    Name := SourceName;
  end;
  CS := lFExpand(Name);
  ES := '';
  P := 0;
  if Name = '' then ExecRec.Main := mnEmpty
  else
  case Directive[1] of
    'A': ExecRec.Main := mnArc;
    'V': ExecRec.Main := mnView;
    'E': ExecRec.Main := mnEdit;
    'D': ExecRec.Main := mndBASE;
    'I': ExecRec.Main := mnIcon;
    'M': ExecRec.Main := mnMenu;
    'P': if Directive[2] = 'A' then ExecRec.Main := mnPanel
         else ExecRec.Main := mnPrint;
    'H': if Directive[2] = 'E' then ExecRec.Main := mnHelp
         else ExecRec.Main := mnHTML;
    else if Directive[2] = 'E' then
         ExecRec.Main := mnXEdit else
         ExecRec.Main := mnXView;
  end;
end;

procedure ProcessCMDDirective;
begin
  CmdFlag := True;
  B := P + 4;
  if (Length(ES) >= B) and (ES[B] = '') then
  begin
    Inc(B);
    FindClosingArrow;
    CmdName := Copy(CS, B, E - B);
  end
  else
  begin
    GetValidSwapDir(CmdName, False);
    CmdName := CmdName + CmdFileName;
    E := B - 1;
  end;
  Name := '';
  ReplaceText(E - P + 1);
end;

procedure ProcessCNDirective;
begin
  Name := ClearedSlash(ProgramPath);
  ReplaceText(3);
end;

procedure ProcessCurDirDirective(const Directive: String);
begin
  GetCurDir(0, Name);
  Name := AddedSlash(Name);
  if Directive[1] <> 'L' then lGetShortFileName(Name, Name);
  ReplaceText(Length(Directive) + 1);
end;

procedure ProcessDateTimeDirective(Index: Integer);
var
  H, M, S, HS: Word;

procedure LeftPadZero(W, L: Word);
begin
  Str(W, Name);
  while Length(Name) < L do Name := '0' + Name;
  while Length(Name) > L do Delete(Name, 1, 1);
end;

begin
  case Index of
    edDAY, edMONTH, edYEAR, edFYEAR: GetDate(H, M, S, HS);
    else GetTime(H, M, S, HS);
  end;
  case Index of
    edDAY: LeftPadZero(S, 2);
    edMONTH: LeftPadZero(M, 2);
    edYEAR: LeftPadZero(H, 2);
    edFYEAR: LeftPadZero(H, 4);
    edHOUR: LeftPadZero(H, 2);
    edMIN: LeftPadZero(M, 2);
    edSEC: LeftPadZero(S, 2);
    else LeftPadZero(HS, 3);
  end;
  ReplaceText(Length(Directives[Index]) + 1);
end;

procedure ProcessDIRARCDirective;
begin
  GetValidArcDir(Name);
  Name := ClearedSlash(Name);
  ReplaceText(7);
end;

procedure ProcessDIRNAMEDirective;
begin
  B := P + 9;
  FindClosingArrow;
  Name := JustFileName(ClearedSlash(Copy(CS, B, E - B)));
  ReplaceText(E - P + 1);
end;

procedure ProcessENVDirective;
begin
  B := P + 5;
  FindClosingArrow;
  Name := GetEnvUC(Copy(CS, B, E - B));
  ReplaceText(E - P + 1);
end;

procedure ProcessEXTDirective(const Directive: String);
begin
  GetValidSource(Directive[1] = 'L');
  Name := JustExtension(SourceName);
  if Name <> '' then Name := '.' + Name;
  ReplaceText(Length(Directive) + 1);
end;

procedure ProcessOEXTDirective(const Directive: String);
begin
  GetOppSource(Directive[1] = 'L', Name);
  Name := JustExtension(Name);
  if Name <> '' then Name := '.' + Name;
  ReplaceText(Length(Directive) + 1);
end;

procedure ProcessFINDNAMEDirective(const Directive: String);
begin
  B := P + Length(Directive) + 2;
  FindClosingArrow;
  S := Copy(CS, B, E - B);
  Name := FSearch(S, GetEnv('PATH'));
  if Name = '' then Name := S;
  Name := FExpand(Name);
  if Directive[5] = 'D' then
    Name := ClearedSlash(JustPathName(Name));
  ReplaceText(E - P + 1);
end;

procedure ProcessFINDFIRSTDirective(const Directive: String);
var
  SR: lSearchRec;
begin
  B := P + Length(Directive) + 2;
  FindClosingArrow;
  S := Copy(CS, B, E - B);
  lFindFirst(S, AnyFile and not (VolumeID + Directory), SR);
  lFindClose(SR);
  if (DosError <> 0) or (SR.SR.Attr and Directory <> 0) then Name := ''
  else if Directive[1] = 'L' then Name := SR.FullName
  else Name := SR.SR.Name;
  ReplaceText(E - P + 1);
end;

procedure ProcessFNAMEDirective(const Directive: String);
var
  SaveAPI: lAPIType;
begin
  B := P + Length(Directive) + 1;
  if (Length(ES) >= B) and (ES[B] = '') then
  begin
    Inc(B);
    FindClosingArrow;
    S := Copy(CS, B, E - B);
  end
  else
  begin
    S := HistoryStr(HistoryID, 0);
    E := B - 1;
  end;
  SaveAPI := lAPI;
  if Directive[1] <> 'L' then lAPI := lDOS;
  if not GetFName(S) then Cancel := True
  else
  begin
    Name := S;
    ReplaceText(E - P + 1);
  end;
  lAPI := SaveAPI;
end;

procedure ProcessGETDirective;
var
  N: Integer;
  StrFile: TStrFile;
begin
  B := P + 5;
  FindClosingArrow;
  S := Copy(CS, B, E - B);
  N := Pos('>', S);
  if N <> 0 then
  begin
    StrFile.Init(lFExpand(Trim(Copy(S, 1, N - 1))));
    StrFile.GetStr(Copy(S, N + 1, 255), S);
    StrFile.Done;
  end
  else S := '';
  Name := S;
  ReplaceText(E - P + 1);
end;

procedure ProcessLGETDirective;
var
  I: Integer;
  L: PStringsCollection;
  Q: PString;
  F: lText;
begin
  B := P + 6;
  FindClosingArrow;
  S := lFExpand(Trim(Copy(CS, B, E - B)));
  Name := '';
  ReplaceText(E - P + 1);
  lAssignText(F, S);
  Reset(F.T);
  if IOResult <> 0 then Exit;
  if IsDevice(TextRec(F.T).Handle) then
  begin
    Close(F.T);
    InOutRes := 0;
    Exit;
  end;
  L := New(PStringsCollection, Init(16, 16));
  I := CmdBufLen;
  while not Eof(F.T) and (I < CmdBufSize) do
  begin
    Readln(F.T, S);
    TrimSt(S);
    if (S = '') or (S[1] = ';') then Continue;
{    L^.Insert(NewStr(S));}
    L^.Insert(NewStrUMB(S));
    Inc(I, Length(S) + 1);
  end;
  Close(F.T);
  InOutRes := 0;
  for I := L^.Count - 1 downto 0 do
  begin
    Q := L^.At(I);
    if Q <> nil then
    begin
      Name := Q^ + ' ';
      ReplaceText(0);
    end;
  end;
  Dispose(L, Done);
end;

procedure ProcessKBDDirective;

procedure StrToKeys(const KS: String);
begin
  if (K <> 0) and (KS[1] = '$') and Str2Long(KS, L) and
     (L > 0) and (L <= $FFFF) then
  begin
    Dec(K);
    Keys[K] := LongRec(L).Lo;
  end
  else
  begin
    B := Length(KS);
    while (B <> 0) and (K <> 0) do
    begin
      Dec(K);
      Keys[K] := Byte(KS[B]);
      Dec(B);
    end;
  end;
end;

begin
  B := P + 5;
  FindClosingArrow;
  StrToKeys(Copy(CS, B, E - B));
  Name := '';
  ReplaceText(E - P + 1);
end;

procedure ProcessGETSTRDirective(const Directive: String; ACommand: Word);
begin
  PS := Message(Application, evBroadcast, ACommand, nil);
  if PS <> nil then Name := PS^ else Name := '';
  if (ACommand <> cmGetWord) and (ACommand <> cmHRef) and
     ((Directive[1] <> 'L') or (Directive[2] = 'E')) then
    lGetShortFileName(Name, Name);
  ReplaceText(Length(Directive) + 1);
end;

procedure ProcessHISTDirective;
begin
  GetExecHistStr(Name, 'Exec history', True, True);
  if Name = '' then Cancel := True
  else
  begin
    B := Pos(' ', Name);
    if B <> 0 then
    begin
      ExecRec.Params := Trim(Copy(Name, B + 1, 255));
      Name[0] := Char(B - 1);
    end;
    ReplaceText(5);
  end;
end;

procedure ProcessMEMDirective;
begin
  B := P + 5;
  FindClosingArrow;
  Val(Copy(CS, B, E - B), L, Code);
  if Code = 0 then ExecMem := L * 1024 + LowMemSize * 16;
  Name := '';
  ReplaceText(E - P + 1);
end;

procedure ProcessMSGDirective;
begin
  B := P + 4;
  if (Length(ES) >= B) and (ES[B] = '') then
  begin
    Inc(B);
    FindClosingArrow;
    Name := ' | ' + Copy(CS, B, E - B);
    ExecRec.Options := ExecRec.Options or opLoadCOMMANDCOM;
  end
  else
  begin
    Name := '';
    E := B - 1;
  end;
  ExecRec.Options := ExecRec.Options or opMessage;
  ReplaceText(E - P + 1);
end;

procedure ProcessNAMEDirective(const Directive: String);
begin
  GetValidSource(Directive[1] = 'L');
  Name := JustName(SourceName);
  ReplaceText(Length(Directive) + 1);
end;

procedure ProcessONAMEDirective(const Directive: String);
begin
  GetOppSource(Directive[1] = 'L', Name);
  Name := JustName(Name);
  ReplaceText(Length(Directive) + 1);
end;

procedure ProcessFLAGDirective(const Directive: String; AMask: Word);
begin
  ExecRec.Options := ExecRec.Options or AMask;
  Name := '';
  ReplaceText(Length(Directive) + 1);
end;

procedure ProcessPATHDirective(const Directive: String);
begin
  GetValidSource(Directive[1] = 'L');
  Name := AddBackSlash(JustPathName(SourceName));
  ReplaceText(Length(Directive) + 1);
end;

procedure ProcessOPATHDirective(const Directive: String);
begin
  GetOppSource(Directive[1] = 'L', Name);
  Name := AddBackSlash(JustPathName(Name));
  ReplaceText(Length(Directive) + 1);
end;

procedure ProcessPROMPTDirective;
var
  ATitle, ALabel: String[127];
begin
  ATitle := '';
  ALabel := '';

  B := P + 7;
  if (Length(ES) >= B) and (ES[B] = '') then
  begin
    Inc(B);
    FindClosingArrow;
    S := Copy(CS, B, E - B);

    B := 1;
    while (B < Length(S)) do
    begin
      if S[B] = ',' then
        if S[B + 1] = ',' then Delete(S, B, 1)
        else
        begin
          ALabel := Copy(S, B + 1, 255);
          S[0] := Char(B - 1);
        end;
      Inc(B);
    end;

    if ALabel <> '' then
    begin
      B := 1;
      while (B < Length(ALabel)) do
      begin
        if ALabel[B] = ',' then
          if ALabel[B + 1] = ',' then Delete(ALabel, B, 1)
          else
          begin
            ATitle := Copy(ALabel, B + 1, 255);
            ALabel[0] := Char(B - 1);
          end;
        Inc(B);
      end;
    end;
  end
  else
  begin
    S := HistoryStr(PromptHistoryID, 0);
    E := B - 1;
  end;

  if not GetPrompt(S, ATitle, ALabel) then Cancel := True
  else
  begin
    Name := S;
    ReplaceText(E - P + 1);
  end;
end;

procedure ProcessPUTDirective;
var
  StrFile: TStrFile;
begin
  B := P + 5;
  FindClosingArrow;
  S := Copy(CS, B, E - B);
  B := Pos('<', S);
  if B <> 0 then
  begin
    StrFile.Init(lFExpand(Trim(Copy(S, 1, B - 1))));
    Delete(S, 1, B);
    B := Pos('=', S);
    if B <> 0 then StrFile.PutStr(
      Copy(S, 1, B - 1), Copy(S, B + 1, 255));
    StrFile.Done;
  end;
  Name := '';
  ReplaceText(E - P + 1);
end;

procedure ProcessBLKDirective(const Directive: String;
  AMask, ACommand: Word);
begin
  B := P + Length(Directive) + 2;
  FindClosingArrow;
  S := Copy(CS, B, E - B);
  Name := '';
  ReplaceText(E - P + 1);
{ Added 2005.10.08 to fix $prg() exec problem }
  if (ACommand = cmUserPrograms) and NoModalWindows then
  begin
    ExecRec.Main := mnPrg;
    CS := lFExpand(S);
    ES := '';
    P := 0;
    Exit;
  end;
  Message(Application, AMask, ACommand, @S);
end;

procedure ProcessREPORTDirective;
begin
  Name := ReportFile;
  ReplaceText(7);
end;

procedure ProcessSELDirective(const Directive: String);
var
  C: Word;
begin
  B := P + Length(Directive) + 1;
  if (Length(ES) >= B) and (ES[B] = '') then
  begin
    Inc(B);
    FindClosingArrow;
    Name := Copy(CS, B, E - B);
  end
  else
  begin
    GetValidSwapDir(Name, False);
    Name := Name + SelListName;
    E := B - 1;
  end;
  ReplaceText(E - P + 1);
  lAssignText(F, Name);
  if SelListOptions and slAppend <> 0 then Append(F.T)
  else Rewrite(F.T);
  if IOResult = 0 then
  begin
    Close(F.T);
    if Directive[1] = 'L' then C := cmLSaveSelected
    else C := cmSaveSelected;
    Message(Application, evBroadcast, C, @Name);
  end
  else MessageBox(^C'Could not create list file'#13^C'|' +
    Name + '|.', nil, mfError + mfOkButton);
end;

procedure ProcessSelListOptionsDirective(const Directive: String; AMask: Word);
begin
  SelListOptions := SelListOptions or AMask;
  Name := '';
  ReplaceText(Length(Directive) + 1);
end;

procedure ProcessSelListDateTimeMaskDirective(const Directive: String;
  DirectiveIndex: Integer);
begin
  B := P + Length(Directive) + 2;
  FindClosingArrow;
  if DirectiveIndex = edSLTMASK then
    SelListTimeMask := Copy(CS, B, E - B)
  else SelListDateMask := Copy(CS, B, E - B);
  Name := '';
  ReplaceText(E - P + 1);
end;

procedure ProcessSelListPSDirective(const Directive: String;
  DirectiveIndex: Integer);
begin
  B := P + Length(Directive) + 2;
  FindClosingArrow;
  if DirectiveIndex = edSLSUFFIX then
    SelListSuffixStr := Copy(CS, B, E - B)
  else SelListPrefixStr := Copy(CS, B, E - B);
  Name := '';
  ReplaceText(E - P + 1);
end;

procedure ProcessSETDirective;
begin
  B := P + 5;
  FindClosingArrow;
  SetEnvVar(Copy(CS, B, E - B));
  Name := '';
  ReplaceText(E - P + 1);
end;

procedure ProcessSWAPDIRDirective;
begin
  GetValidSwapDir(Name, False);
  Name := ClearedSlash(Name);
  ReplaceText(8);
end;

procedure ProcessVMDirective;
var
  SaveRestore: Boolean;
begin
  B := P + 4;
  FindClosingArrow;
  Val(Copy(CS, B, E - B), L, Code);
  if (Code = 0) and (L >= 0) and (L <= 255) then
  begin
    CustomVideoMode := L;
    SaveRestore := RestoreVideoMode;
    RestoreVideoMode := True;
    UpdateScreen(StartupMode);
    RestoreVideoMode := SaveRestore;
  end
  else InvalidVMMsgBox;
  Name := '';
  ReplaceText(E - P + 1);
end;

procedure ProcessCLIPDirective(const Directive: String);
var
  Event: TEvent;
begin
  B := P + Length(Directive) + 2;
  FindClosingArrow;
  S := Copy(CS, B, E - B);
  Name := '';
  ReplaceText(E - P + 1);
  if S <> '' then
    if Directive[1] = 'W' then
    begin
      Event.InfoByte := 0;
      ClipCopyToMT(S, Event);
    end
    else Message(Application, evBroadcast, cmCopy, @S);
end;

procedure ProcessXMDirective;
begin
  B := P + 4;
  FindClosingArrow;
  Val(Copy(CS, B, E - B), L, Code);
  if (Code = 0) and (L >= 0) and (L <= 255) then XVideoMode := L
  else InvalidVMMsgBox;
  Name := '';
  ReplaceText(E - P + 1);
end;

procedure ProcessXNTDirective;
begin
  B := P + 4;
  if (Length(ES) >= B) and (ES[B] = '') then
  begin
    Inc(B);
    FindClosingArrow;
    S := Copy(CS, B, E - B);
    B := Pos(',', S);
    if B <> 0 then
    begin
      Val(Trim(Copy(S, 1, B - 1)), XNTFlags, Code);
      Val(Trim(Copy(S, B + 1, 255)), XNTOptions, Code);
    end
    else
    begin
      Val(Trim(S), XNTFlags, Code);
      XNTOptions := 0;
    end;
  end
  else
  begin
    E := B - 1;
    XNTFlags := 0;
    XNTOptions := 0;
  end;
  Name := '';
  ExecRec.Main := mnXNT;
  ReplaceText(E - P + 1);
end;

procedure ProcessXXDirective(const Directive: String);
var
  View, Ok: Boolean;
  Event: TEvent;
  R, SaveR: TExecRec;
begin
  if XXRecur then
  begin
    MessageBox(^C'Invalid use of the directive'#13 +
      ^C'$' + Directive + '.', nil, mfError + mfOkButton);
    XXRecur := False;
    Cancel := True;
    Exit;
  end;
  View := Directive[2] = 'W';
  B := P + Length(Directive) + 2;
  FindClosingArrow;
  S := Copy(CS, B, E - B);
  XXNamePtr := @S;
  Ok := ExtractExecRec(R, JustFileName(S), 0, View);
  if View and not Ok then
  begin
    FillChar(R, SizeOf(TExecRec), 0);
    R.Path := '$VIEW';
    Ok := True;
  end;
  if Ok then
  begin
    Name := '';
    ReplaceText(E - P + 1);
    SaveR := ExecRec;
    ExecRec := R;
    PrepareExecEvent;
    XXRecur := True;
    while Pending.What <> evNothing do
    begin
      Event := Pending;
      Pending.What := evNothing;
      Application^.HandleEvent(Event);
    end;
    XXRecur := False;
    ExecRec := SaveR;
  end
  else Cancel := True;
  XXNamePtr := nil;
end;

procedure ProcessDirective;
var
  I: Integer;
begin
  for I := edFirst to edLast do
  begin
    B := FIPos(Directives[I], ES, P);
    if B = P + 1 then
    begin
      case I of
        edARC, edDBASE, edEDIT, edHELP, edHTML, edICON,
        edMenu, edPANEL, edPRINT, edVIEW, edXEDIT, edXVIEW:
          ProcessOpenDirective(Directives[I]);
        edCMD:
          ProcessCMDDirective;
        edCN:
          ProcessCNDirective;
        edCURDIR, edLCURDIR:
          ProcessCurDirDirective(Directives[I]);
        edDAY, edMONTH, edYEAR, edFYEAR, edHOUR, edMIN, edSEC, edMSEC:
          ProcessDateTimeDirective(I);
        edDIRARC:
          ProcessDIRARCDirective;
        edDIRNAME:
          ProcessDIRNAMEDirective;
        edENV:
          ProcessENVDirective;
        edERR:
          ProcessFLAGDirective(Directives[I], opStdError);
        edEXT, edLEXT:
          ProcessEXTDirective(Directives[I]);
        edFILTER:
          ProcessBLKDirective(Directives[I], evBroadcast, cmFilter);
        edFINDDIR, edFINDNAME:
          ProcessFINDNAMEDirective(Directives[I]);
        edFINDFST, edLFINDFST:
          ProcessFINDFIRSTDirective(Directives[I]);
        edFNAME, edLFNAME:
          ProcessFNAMEDirective(Directives[I]);
        edGET:
          ProcessGETDirective;
        edLGET:
          ProcessLGETDirective;
        edHIST:
          ProcessHISTDirective;
        edHREF:
          ProcessGETSTRDirective(Directives[I], cmHRef);
        edKBD:
          ProcessKBDDirective;
        edLEFT, edLLEFT:
          ProcessGETSTRDirective(Directives[I], cmGetLeftPath);
        edMAC:
          ProcessBLKDirective(Directives[I], evCommand, cmUserMacros);
        edMEM:
          ProcessMEMDirective;
        edMSG:
          ProcessMSGDirective;
        edNAME, edLNAME:
          ProcessNAMEDirective(Directives[I]);
        edNOMSGWIN, edNMW:
          ProcessFLAGDirective(Directives[I], opNoMsgWin);
        edNOREDRAW, edNRD:
          ProcessFLAGDirective(Directives[I], opNoRedraw);
        edNOREREAD, edNRR:
          ProcessFLAGDirective(Directives[I], opNoReread);
        edNTM:
          ProcessFLAGDirective(Directives[I], opNoXfer);
        edOEXT, edLOEXT:
          ProcessOEXTDirective(Directives[I]);
        edONAME, edLONAME:
          ProcessONAMEDirective(Directives[I]);
        edOPATH, edLOPATH:
          ProcessOPATHDirective(Directives[I]);
        edOPPOSITE, edLOPP:
          ProcessGETSTRDirective(Directives[I], cmGetOppositePath);
        edPATH, edLPATH:
          ProcessPATHDirective(Directives[I]);
        edPRG:
          ProcessBLKDirective(Directives[I], evCommand, cmUserPrograms);
        edPROMPT:
          ProcessPROMPTDirective;
        edPUT:
          ProcessPUTDirective;
        edRDBLK:
          ProcessBLKDirective(Directives[I], evBroadcast, cmCtrlKR);
        edREPORT:
          ProcessREPORTDirective;
        edRIGHT, edLRIGHT:
          ProcessGETSTRDirective(Directives[I], cmGetRightPath);
        edSAMEWIN:
          ProcessFLAGDirective(Directives[I], opInfoBit);
        edSEL, edLSEL:
          ProcessSELDirective(Directives[I]);
        edSET: ProcessSETDirective;
        edSLAPPEND: ProcessSelListOptionsDirective(Directives[I], slAppend);
        edSLATTR: ProcessSelListOptionsDirective(Directives[I], slAddAttr);
        edSLBKSLSH: ProcessSelListOptionsDirective(Directives[I], slBkSlash);
        edSLPATH: ProcessSelListOptionsDirective(Directives[I], slAddPath);
        edSLQUOTES: ProcessSelListOptionsDirective(Directives[I], slLQuotes);
        edSLSIZE: ProcessSelListOptionsDirective(Directives[I], slAddSize);
        edSLSKIPD: ProcessSelListOptionsDirective(Directives[I], slSkipDir);
        edSLTIME: ProcessSelListOptionsDirective(Directives[I], slAddTime);
        edSLDMASK, edSLTMASK:
          ProcessSelListDateTimeMaskDirective(Directives[I], I);
        edSLPREFIX, edSLSUFFIX:
          ProcessSelListPSDirective(Directives[I], I);
        edSWAPDIR:
          ProcessSWAPDIRDirective;
        edUSERSCR, edUSR:
          ProcessFLAGDirective(Directives[I], opUserScr);
        edVM:
          ProcessVMDirective;
        edCLIP, edWINCLIP:
          ProcessCLIPDirective(Directives[I]);
        edWORD:
          ProcessGETSTRDirective(Directives[I], cmGetWord);
        edWRBLK:
          ProcessBLKDirective(Directives[I], evBroadcast, cmCtrlKW);
        edXM:
          ProcessXMDirective;
        edXNT:
          ProcessXNTDirective;
        edXW, edXX:
          ProcessXXDirective(Directives[I]);
      end;
      Break;
    end;
  end;
end;

procedure StuffKey;
const
  KbdStart = $1E;
  KbdEnd = $3C;
var
  KbdHead: Word absolute $40:$1A;
  KbdTail: Word absolute $40:$1C;
  SaveKbdTail: Word;
begin
  SaveKbdTail := KbdTail;
  if KbdTail = KbdEnd then KbdTail := KbdStart
  else Inc(KbdTail, 2);
  if KbdTail = KbdHead then KbdTail := SaveKbdTail
  else MemW[$40:SaveKbdTail] := Keys[B];
end;

begin
  ValidateParams := False;
  Cancel := False;
  CmdFlag := False;
  CmdBuf := nil;
  CS := Params;
  ConvertExecStr(Params, ES);
{ Added 2005.12.08 to store params in file instead of string }
  if CmdBuf <> nil then
  begin
    FreeMem(CmdBuf, CmdBufSize);
    CmdBuf := nil;
  end;
  CmdBufLen := 0;
  if Pos(Directives[edCMD], ES) <> 0 then
  begin
    CmdBuf := MemAlloc(CmdBufSize);
    if CmdBuf <> nil then
    begin
      FillChar(CmdBuf^, CmdBufSize, 0);
      CmdBufLen := Length(CS);
      Move(CS[1], CmdBuf^[1], CmdBufLen);
    end;
  end;
  K := MaxKeys;
  P := Length(ES);
  while P <> 0 do
  begin
    if ES[P] = '$' then
    begin
      ProcessDirective;
      if Cancel then Exit;
    end;
    Dec(P);
  end;
{ Added 2005.12.08 to store params in file instead of string }
  if CmdBuf <> nil then
  begin
    if CmdFlag then
    begin
      CS := CmdName;
      SaveCmdBuf;
    end;
    if ExecRec.Main <> mnXNT then
    begin
      FreeMem(CmdBuf, CmdBufSize);
      CmdBuf := nil;
    end;
  end;
  Params := Trim(CS);
  for B := K to MaxKeys - 1 do StuffKey;
  ValidateParams := True;
end;

procedure SetFullExecPath;
var
  P: Byte;
  Ext: ExtStr;
  Name: NameStr;
  Dir: DirStr;
  PathVar: String;

procedure CheckBAT;
begin
  if CompUCString(Ext, '.BAT') = Equal then
    ExecRec.Options := ExecRec.Options or opLoadCOMMANDCOM;
end;

function Exists(const FName: FNameStr): Boolean;
begin
  if ThisFileExists(FName) then
  begin
    ExecRec.Path := FName;
    FSplit(FName, Dir, Name, Ext);
    CheckBAT;
    Exists := True;
  end
  else Exists := False;
end;

function OneOfThreeExists: Boolean;
begin
  OneOfThreeExists := Exists(Dir + Name + '.COM') or
    Exists(Dir + Name + '.EXE') or Exists(Dir + Name + '.BAT');
end;

begin
  GetCurDir(0, PathVar);
  PathVar := AddedSlash(PathVar);
  if Pos(PathVar, ExecRec.Path) = 1 then
    Delete(ExecRec.Path, 1, Length(PathVar));
{ Added 2006.01.07 }
  if (ExecRec.Path <> '') and (ExecRec.Path[1] = '"') then P := 0
  else P := Pos(' ', ExecRec.Path);
  if P <> 0 then
  begin
    ExecRec.Params :=
      Trim(Copy(ExecRec.Path, P + 1, 255)) + ' ' + ExecRec.Params;
    ExecRec.Path[0] := Char(P - 1);
  end;
  P := Pos(':', ExecRec.Path);
  lGetShortFileName(ExecRec.Path, ExecRec.Path);
  if (P = 0) and (Pos(':', ExecRec.Path) = 2) then
    ExecRec.Path := JustFileName(ExecRec.Path);
  if (ExecRec.Main = mnSwap) and (Length(ExecRec.Path) >= 64) then
    ExecRec.Options := ExecRec.Options or opLoadCOMMANDCOM;
  if ExecRec.Options and opLoadCOMMANDCOM <> 0 then Exit;
  FSplit(ExecRec.Path, Dir, Name, Ext);
  if Dir <> '' then
  begin
    if Ext <> '' then CheckBAT
    else OneOfThreeExists;
    Exit;
  end;
  PathVar := ';' + GetEnv('PATH');
  while PathVar[Length(PathVar)] = ';' do Dec(PathVar[0]);
  repeat
    P := Pos(';', PathVar) - 1;
    Dir := Trim(Copy(PathVar, 1, P));
    Delete(PathVar, 1, P + 1);
    if Dir <> '' then Dir := AddedSlash(Dir);
    if Ext <> '' then
      if Exists(Dir + ExecRec.Path) then Exit else
    else if OneOfThreeExists then Exit;
  until PathVar = '';
end;

procedure PrepareExecEvent;
begin
  Pending.What := evCommand;
  Pending.Command := cmExecRec;
end;

function SpecialCharPos(C: Char; var S: String): Integer;
var
  I: Integer;
begin
  I := 1;
  while I <= Length(S) do
  begin
    if S[I] = C then
      if (I = Length(S)) or (S[I + 1] = C) then Delete(S, I, 1)
      else Break;
    Inc(I);
  end;
  if I > Length(S) then I := 0;
  SpecialCharPos := I;
end;

procedure CheckMultiExec;
var
  P: Integer;
  S: TDosStream;
  Name: FNameStr;
  R: TExecRec;
begin
  MultiExec := False;
  P := SpecialCharPos(';', ExecRec.Path);
  if P = 0 then Exit;
  R.Path := Trim(Copy(ExecRec.Path, 1, P - 1));
  ExecRec.Path := Trim(Copy(ExecRec.Path, P + 1, 255));
  P := SpecialCharPos(';', ExecRec.Params);
  if P <> 0 then
  begin
    R.Params := Trim(Copy(ExecRec.Params, 1, P - 1));
    ExecRec.Params := Trim(Copy(ExecRec.Params, P + 1, 255));
  end
  else
  begin
    R.Params := ExecRec.Params;
    ExecRec.Params := '';
  end;
  R.FileMask := ExecRec.FileMask;
  R.LineMask := ExecRec.LineMask;
  R.Main := ExecRec.Main;
  R.Setup := ExecRec.Setup;
  R.Options := ExecRec.Options;
  SetExecRecName(Name);
  S.Init(Name, stCreate);
  if S.Status = stOk then S.Write(ExecRec, SizeOf(TExecRec));
  S.Done;
  ExecRec := R;
  MultiExec := True;
end;

procedure LoadMultiExecRec;
var
  S: TDosStream;
  F: File;
  Name: FNameStr;
  R: TExecRec;
begin
  MultiExec := False;
  SetExecRecName(Name);
  S.Init(Name, stOpenRead);
  if S.Status = stOk then
  begin
    S.Read(ExecRec, SizeOf(TExecRec));
    Byte(MultiExec) := 2;
  end;
  S.Done;
  if MultiExec then
  begin
    Assign(F, Name);
    Erase(F);
    InOutRes := 0;
    PrepareExecEvent;
  end;
end;

procedure AddSpoolerItem;
var
  C: Boolean;
  I: Integer;
  P: PSpoolerRec;
  T: ConvertTable;
begin
  C := BinaryPrinting;
  I := UCPos('/B', ExecRec.Params);
  if I <> 0 then
  begin
    ExecRec.Params[0] := Char(I - 1);
    BinaryPrinting := True;
  end
  else BinaryPrinting := False;
  P := TheSpooler^.NewSource(ExecRec.Path);
  BinaryPrinting := C;
  if (P <> nil) and (ExecRec.Params <> '') then
  begin
    ReadConvertTable(T, ExecRec.Params, C);
    SetSpoolerXLAT(P, T);
  end;
end;

function PrepareExecPrim: Boolean;
var
  WriteToHistory: Boolean;
  OpenCommand: Word;
  OpenPtr: Pointer;
label
  CancelExec;
begin
  WriteToHistory := HistoryOpened;
  HistoryOpened := False;
  SourceMsgSent := smNot;
  ExecMem := 655560;
  CheckMultiExec;
  if not ValidateParams(ExecRec.Path) then Goto CancelExec;
  if not ValidateParams(ExecRec.Params) then Goto CancelExec;
  SelListOptions := 0;
  SelListDateMask := '';
  SelListTimeMask := '';
  SelListPrefixStr := '';
  SelListSuffixStr := '';
  if ExecRec.Main >= mnArc then
  begin
    case ExecRec.Main of
      mnArc:   OpenCommand := cmOpenArchive;
      mnView:  OpenCommand := cmOpenTextViewer;
      mnXView: OpenCommand := cmOpenHexViewer;
      mnEdit:  OpenCommand := cmOpenASCII;
      mnXEdit: OpenCommand := cmOpenHex;
      mndBASE: OpenCommand := cmOpenDataViewer;
      mnIcon:  OpenCommand := cmLoadIcon;
      mnMenu:  OpenCommand := cmUserPrograms;
      mnPrg:   OpenCommand := cmUserPrograms;
      mnPanel: OpenCommand := cmReadFileList;
      mnPrint: OpenCommand := cmPrint;
      mnHelp:  OpenCommand := cmHelp;
      mnHTML:  OpenCommand := cmOpenHTML;
      else     OpenCommand := 0;
    end;
    if ExecRec.Path = '' then OpenPtr := nil
    else OpenPtr := @ExecRec;
    if OpenCommand = cmLoadIcon then IconParams := @ExecRec.Params;
    if OpenCommand <> 0 then
      if OpenCommand = cmHelp then
      begin
        Pending.What := evCommand;
        Pending.Command := cmHelp;
        Pending.InfoPtr := OpenPtr;
      end
      else if OpenCommand = cmUserPrograms then
        if ExecRec.Main = mnPrg then ProgDlg(OpenPtr)
        else UserMenuDlg(OpenPtr, False)
      else if OpenCommand = cmPrint then AddSpoolerItem
      else Message(Application, evCommand, OpenCommand, OpenPtr);
    if MultiExec then LoadMultiExecRec;
    Goto CancelExec;
  end;
  if (ExecRec.Path = '') and (ExecRec.Params = '') then
  begin
    if MultiExec then LoadMultiExecRec;
    Goto CancelExec;
  end;
  if (Length(ExecRec.Path) = 2) and
     (CompUCString(ExecRec.Path, 'CD') = Equal) and
     (ExecRec.Params <> '') then
  begin
    FailSysErrors := True;
    lChDir(ExecRec.Params);
    FailSysErrors := False;
    InOutRes := 0;
    if MultiExec then LoadMultiExecRec;
    Goto CancelExec;
  end;
  if (Length(ExecRec.Path) = 4) and
     (CompUCString(ExecRec.Path, 'CDFM') = Equal) and
     (ExecRec.Params <> '') then
  begin
    Message(Desktop, evBroadcast, cmCDFM, nil);
    if MultiExec then LoadMultiExecRec;
    Goto CancelExec;
  end;
  SetFullExecPath;
  if WriteToHistory then HistoryAdd(
    FPromptHistoryID, ExecRec.Path + ' ' + ExecRec.Params, True);
  ExecRec.Options := ExecRec.Options or opPrepared;
  if GlobalQuietExec then ExecRec.Options := ExecRec.Options or
    (opMessage + opNoRedraw + opNoReread + opNoMsgWin + opNoXfer);
  PrepareExecPrim := True;
  Exit;

CancelExec:
  SelListOptions := 0;
  SelListDateMask := '';
  SelListTimeMask := '';
  CancelExecution;
  PrepareExecPrim := False;
end;

procedure CancelExecution;
begin
  Message(Application, evBroadcast, cmCancelExec, nil);
end;

procedure SaveMsgFilters;
var
  F: Text;
begin
  if Byte(MultiExec) > 1 then Exit;
  Assign(F, ReportFile);
  Rewrite(F);
  if IOResult = 0 then
  begin
    if ExecRec.Options and opNoMsgWin = 0 then
    begin
      Writeln(F, ExecRec.FileMask);
      Writeln(F, ExecRec.LineMask);
    end;
    Flush(F);
    Close(F);
  end;
end;

function SHExec(cmd, params: String; Flag: Longint): Longint;
var
 Result: Longint;
 Regs: Registers;
begin
 Result := -2;
 if CN_NT and (Length(cmd) < 255) and (Length(params) < 255) then
  With Regs do
  begin
   cmd[Length(cmd)+1] := #0;
   params[Length(params)+1] := #0;
   ax := $170e; {}
   bx := ofs(cmd[1]);
   es := seg(cmd[1]);
   cx := ofs(params[1]);
   ds := seg(params[1]);
   dx := Word(Flag);
   Intr($2f, Regs);
   Result := Longint(BX) shl 16 + AX;
   if Result > 32 then Result := 0;
  end;
  SHExec := Result;
end;

{ Added 2005.12.12 to support ExecNT }
function ExecNT: Longint;
var
  Regs: Registers;
  Result: Longint;
begin
  if ((XNTFlags = -1) and (XNTOptions = -1)) or (XNTFlags = 1) then
  begin
    ExecNT := SHExec(ExecRec.Path, ExecRec.Params, XNTFlags);
    Exit;
  end;
  Result := -2;
  if CN_NT and (Length(ExecRec.Path) < 255) then with Regs do
  begin
    if (CmdBuf <> Nil) and (CmdBufLen + 2 < CmdBufSize) then
     begin
      CmdBuf^[CmdBufLen + 1] := 0;
      CmdBuf^[CmdBufLen + 2] := 0;
      ExecRec.Path[Length(ExecRec.Path) + 1] := #0;
      AX := $1715; {ExecNT}
      BX := PtrRec(CmdBuf).Ofs+1;
      ES := PtrRec(CmdBuf).Seg;
      CX := Ofs(ExecRec.Path[1]);
      DS := Seg(ExecRec.Path[1]);

      dx := XNTFlags and $FFFC;
      si := XNTFlags shr 16;
      bp := XNTOptions; {options, eoErrIgnore = 1, eoErrZero = 2, eoAsync = 4}

      Intr($2F, Regs);
      Result := Longint(BX) shl 16 + AX;
     end
    else Result := -1;
  end;
  if CmdBuf <> nil then
  begin
    FreeMem(CmdBuf, CmdBufSize);
    CmdBuf := nil;
  end;
  ExecNT := Result;
end;

end.