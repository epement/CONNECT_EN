{$I-,X+,O+,F+}
unit StdDlg;

interface

uses Dos, Objects, Drivers, Views, Dialogs;

type
  PSearchRec = ^TSearchRec;
  TSearchRec = record
    Attr: Byte;
    Time: Longint;
    Size: Longint;
    Name: String[12];
    FullName: PString;
  end;

type
  PFileInputLine = ^TFileInputLine;
  TFileInputLine = object(TInputLine)
    constructor Init(var Bounds: TRect; AMaxLen: Integer);
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PFileCollection = ^TFileCollection;
  TFileCollection = object(TSortedCollection)
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PFileList = ^TFileList;
  TFileList = object(TListBox)
    SearchPos: Word;
    ShiftStatus: Byte;
    constructor Init(var Bounds: TRect; ANumCols: Word;
      AHScrollBar, AVScrollBar: PScrollBar);
    destructor Done; virtual;
    function DataSize: Word; virtual;
    procedure Draw; virtual;
    procedure FocusItem(Item: Integer); virtual;
    procedure GetData(var Rec); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure ReadDirectory(AWildCard: FNameStr);
  end;

  PFileInfoPane = ^TFileInfoPane;
  TFileInfoPane = object(TView)
    SR: TSearchRec;
    constructor Init(var Bounds: TRect);
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  TWildStr = FNameStr;

const
  fdOkButton       = $0001;
  fdOpenButton     = $0002;
  fdReplaceButton  = $0004;
  fdClearButton    = $0008;
  fdHelpButton     = $0010;
  fdMaskButton     = $0020;
  fdSelButton      = $0040;
  fdRunButton      = $0100;
  fdLoadButton     = $0200;
  fdStoreButton    = $0400;
  fdNoLoadDir      = $4000;
  fdView           = $8000;

  fsName           = $00;
  fsExt            = $01;
  fsTime           = $02;
  fsSize           = $03;
  fsAscend         = $00;
  fsDescend        = $01;

  cmfsName         = 2100;
  cmfsExt          = 2101;
  cmfsTime         = 2102;
  cmfsSize         = 2103;
  cmfsAscend       = 2104;
  cmfsDescend      = 2105;

  ViewLine: Boolean = False;
  SingleColumn: Boolean = False;
  FileSortMode: Byte = fsName;
  FileSortDir: Byte = fsAscend;

type
  PViewCheck = ^TViewCheck;
  TViewCheck = object(TCheckBoxes)
    function DataSize: Word; virtual;
    procedure GetData(var Rec); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Press(Item: Integer); virtual;
    procedure SetData(var Rec); virtual;
  end;

  PToggleLabel = ^TToggleLabel;
  TToggleLabel = object(TLabel)
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure UpdateText;
  end;

  PFileDialog = ^TFileDialog;
  TFileDialog = object(TDialog)
    FileName: PFileInputLine;
    FileList: PFileList;
    ToggleLabel: PToggleLabel;
    WildCard: TWildStr;
    DirectoryStr: PString;
    constructor Init(const AWildCard: TWildStr; const ATitle: String;
      const InputName: String; AOptions: Word; HistoryID: Word);
    destructor Done; virtual;
    procedure GetData(var Rec); virtual;
    procedure GetFileName(var S: FNameStr);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    function Valid(Command: Word): Boolean; virtual;
  private
    procedure ReadDirectory;
    procedure ToggleListColumns;
  end;

  PDirInputLine = ^TDirInputLine;
  TDirInputLine = object(TInputLine)
    procedure SetData(var Rec); virtual;
  end;

  PDirEntry = ^TDirEntry;
  TDirEntry = record
    DisplayText: PString;
    DirectoryStr: PString;
  end;

  PDirCollection = ^TDirCollection;
  TDirCollection = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PDirListBox = ^TDirListBox;
  TDirListBox = object(TListBox)
    Dir: String;
    Cur: Word;
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar);
    destructor Done; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function IsSelected(Item: Integer): Boolean; virtual;
    procedure NewDirectory(var ADir: String);
    procedure SetState(AState: Word; Enable: Boolean); virtual;
  end;

const
  cdNormal     = $0000;
  cdNoLoadDir  = $0001;
  cdHelpButton = $0002;

type

  PChDirDialog = ^TChDirDialog;
  TChDirDialog = object(TDialog)
    DirInput: PInputLine;
    DirList: PDirListBox;
    OkButton: PButton;
    ChDirButton: PButton;
    constructor Init(AOptions: Word; HistoryId: Word);
    function DataSize: Word; virtual;
    procedure GetData(var Rec); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    function Valid(Command: Word): Boolean; virtual;
  private
    procedure SetUpDialog;
  end;

const
  CInfoPane = #30;


procedure CreateDir(const S: String);
function CreateDirMsgBox(const S: String): Word;
procedure InvalidDirMsgBox(const S: String);
procedure InvalidFileNameMsgBox(const S: String);
procedure ChangeDir;

implementation

uses Memory, Menus, App, Gauges, Calendar, HistList, History, MsgBox,
  Popups, DirPrim, DiskPrim, DiskBase, Disks, LFN, TPString, Consts,
  Commands, Defaults;

procedure CreateDir(const S: String);
begin
  MkDirPrim(S, nil);
  Message(Desktop, evBroadcast, cmUpdateDisk, nil);
end;

function CreateDirMsgBox(const S: String): Word;
begin
  CreateDirMsgBox := MessageBox(^C'The directory'#13^C'|' + S +
    '|'#13^C'does not exist. Create ?', nil, mfConfirmation + mfOkCancel);
end;

procedure InvalidDirMsgBox(const S: String);
begin
  MessageBox(^C'Invalid drive or directory:'#13#13^C'|' +
    S + '|.', nil, mfError + mfOkButton);
end;

procedure InvalidFileNameMsgBox(const S: String);
begin
  MessageBox(^C'Invalid file name:'#13#13^C'|' +
    S + '|.', nil, mfError + mfOkButton);
end;

{ Added 2005.10.18 }
function ContainsIllegalChars(const S: String): Boolean;
const
  IllegalChars: set of Char = ['<', '>', '|', '"', '/'];
var
  B: Byte;
begin
  ContainsIllegalChars := False;
  for B := 1 to Length(S) do
    if S[B] in IllegalChars then
    begin
      ContainsIllegalChars := True;
      Exit;
    end;
end;

function ValidFileName(var FileName: FNameStr): Byte;
{const}
{  IllegalChars = ';,=+<>|"[]\';}
var
  Dir, Name, Ext: String;

(*
function Contains(S1, S2: String): Boolean; near; assembler;
asm
        PUSH    DS
        CLD
        LDS     SI,S1
        LES     DI,S2
        MOV     DX,DI
        XOR     AH,AH
        LODSB
        MOV     BX,AX
        OR      BX,BX
        JZ      @@2
        MOV     AL,ES:[DI]
        XCHG    AX,CX
@@1:    PUSH    CX
        MOV     DI,DX
        LODSB
        REPNE   SCASB
        POP     CX
        JE      @@3
        DEC     BX
        JNZ     @@1
@@2:    XOR     AL,AL
        JMP     @@4
@@3:    MOV     AL,1
@@4:    POP     DS
end;
*)

begin
  ValidFileName := 0;
  if ContainsIllegalChars(FileName) then ValidFileName := 1
  else
  begin
    lFSplit(FileName, Dir, Name, Ext);
    if not ((Dir = '') or DirPresent(Dir)) then ValidFileName := 2;
  end;
end;

function GetCurDir: String;
var
  CurDir: String;
begin
  lGetDir(0, CurDir);
  if (Length(CurDir) > 3) and (Length(CurDir) < 255) then
  begin
    Inc(CurDir[0]);
    CurDir[Length(CurDir)] := '\';
  end;
  GetCurDir := CurDir;
end;

function IsDir(var S: String): Boolean;
var
  SR: lSearchRec;
begin
  lFindFirst(S, Directory, SR);
  lFindClose(SR);
  IsDir := (DosError = 0) and (SR.SR.Attr and Directory <> 0);
end;

constructor TFileInputLine.Init(var Bounds: TRect; AMaxLen: Integer);
begin
  TInputLine.Init(Bounds, AMaxLen);
  EventMask := EventMask or evBroadcast;
end;

procedure TFileInputLine.HandleEvent(var Event: TEvent);
var
  P: PSearchRec;
  Path, Name: FNameStr;
begin
  TInputLine.HandleEvent(Event);
  if (Event.What = evBroadcast) and (Event.Command = cmListItemSelected) and
     (State and sfSelected = 0) then
  begin
    if PFileDialog(Owner)^.DirectoryStr = nil then Path := lFExpand('')
    else Path := lFExpand(PFileDialog(Owner)^.DirectoryStr^);
    P := Event.InfoPtr;
    if P = nil then Name := Concat(Path, PFileDialog(Owner)^.WildCard)
    else
    begin
      if P^.FullName <> nil then Name := P^.FullName^
      else Name := P^.Name;
      if P^.Attr and Directory <> 0 then
        Name := Concat(Name, '\', PFileDialog(Owner)^.WildCard)
      else Name := Concat(Path, Name);
    end;
    SetData(Name);
  end;
end;

function TFileCollection.Compare(Key1, Key2: Pointer): Integer;
var
  SortMode: Byte;
  C: CompareType;
  Name1, Name2: FNameStr;
label
  CompareByName;
begin
  if PSearchRec(Key1)^.Name = '..' then
    if PSearchRec(Key2)^.Name = '..' then Compare := 0
    else Compare := -1
  else if PSearchRec(Key2)^.Name = '..' then
    if PSearchRec(Key1)^.Name = '..' then Compare := 0
    else Compare := 1
  else if (PSearchRec(Key1)^.Attr and Directory <> 0) and
    (PSearchRec(Key2)^.Attr and Directory = 0) then Compare := -1
  else if (PSearchRec(Key2)^.Attr and Directory <> 0) and
    (PSearchRec(Key1)^.Attr and Directory = 0) then Compare := 1
  else
  begin
    SortMode := FileSortMode;
CompareByName:
    if SortMode = fsName then
      if SingleColumn then
      begin
	if PSearchRec(Key1)^.FullName <> nil then
	  Name1 := PSearchRec(Key1)^.FullName^
	else Name1 := PSearchRec(Key1)^.Name;
	if PSearchRec(Key2)^.FullName <> nil then
	  Name2 := PSearchRec(Key2)^.FullName^
	else Name2 := PSearchRec(Key2)^.Name;
	C := CompUCString(Name1, Name2);
      end
      else C := CompUCString(PSearchRec(Key1)^.Name, PSearchRec(Key2)^.Name)
    else if SortMode = fsExt then
    begin
      SortMode := fsName;
      Name1 := JustExtension(PSearchRec(Key1)^.Name);
      Name2 := JustExtension(PSearchRec(Key2)^.Name);
      C := CompUCString(Name1, Name2);
      if C = Equal then goto CompareByName;
    end
    else if SortMode = fsTime then
    begin
      SortMode := fsName;
      if PSearchRec(Key1)^.Time = PSearchRec(Key2)^.Time then
	goto CompareByName
      else if PSearchRec(Key1)^.Time < PSearchRec(Key2)^.Time then
	C := Greater
      else C := Less;
    end
    else
    begin
      SortMode := fsName;
      C := CompareType(lCompareSizes(
	lGetFileRealSize(PSearchRec(Key1)^.Attr, PSearchRec(Key1)^.Size),
	lGetFileRealSize(PSearchRec(Key2)^.Attr, PSearchRec(Key2)^.Size)));
      if C = Equal then goto CompareByName;
    end;

    if C = Equal then Compare := 0
    else if C = Greater then
      if FileSortDir = fsAscend then Compare := 1
      else Compare := -1
    else
      if FileSortDir = fsAscend then Compare := -1
      else Compare := 1;
  end;
end;

procedure TFileCollection.FreeItem(Item: Pointer);
begin
  if Item <> nil then
  begin
    DisposeStr(PSearchRec(Item)^.FullName);
    FreeMem(Item, SizeOf(TSearchRec));
  end;
end;

constructor TFileList.Init(var Bounds: TRect; ANumCols: Word;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TListBox.Init(Bounds, ANumCols, AVScrollBar);
  HScrollBar := AHScrollBar;
  GrowMode := gfGrowHiY;
end;

destructor TFileList.Done;
begin
  if List <> nil then Dispose(List, Done);
  TListBox.Done;
end;

function TFileList.DataSize: Word;
begin
  DataSize := 0;
end;

procedure TFileList.Draw;
begin
  TListBox.Draw;
  if SearchPos <> 0 then
  begin
    SetCursor(Cursor.X + SearchPos - HScrollBar^.Value, Cursor.Y);
    ShowCursor;
  end
  else HideCursor;
end;

procedure TFileList.FocusItem(Item: Integer);
begin
  SearchPos := 0;
  TListBox.FocusItem(Item);
  Message(Owner, evBroadcast, cmListItemSelected, List^.At(Focused));
end;

procedure TFileList.GetData(var Rec);
begin
end;

function TFileList.GetText(Item: Integer; MaxLen: Integer): String;
var
  SR: PSearchRec;
  S: String;
begin
  SR := List^.At(Item);
  if (NumCols = 1) and (SR^.FullName <> nil) then S := SR^.FullName^
  else S := SR^.Name;
  if SR^.Attr and Directory <> 0 then
  begin
    if (NumCols <> 1) or ((SR^.FullName = nil) and
       (LFNOptions and loShortNamesAsIs = 0)) or
       (LFNOptions and loConvertNames <> 0) then UpcaseSt(S);
    Inc(S[0]);
    S[Length(S)] := '\';
  end
  else if (NumCols <> 1) or ((SR^.FullName = nil) and
    (LFNOptions and loShortNamesAsIs = 0)) or
    (LFNOptions and loConvertNames <> 0) then LocaseSt(S);
  GetText := S;
end;

procedure TFileList.HandleEvent(var Event: TEvent);
var
  Value, OldValue, OldPos: Integer;
  SR: PSearchRec;
  R: TSearchRec;
  CurString, NewString, Name: String;

function Equal(var S1: String; var S2: String; Count: Word): Boolean;
var
  I: Word;
begin
  Equal := False;
  if (Length(S1) < Count) or (Length(S2) < Count) then Exit;
  for I := 1 to Count do
    if TPString.Upcase(S1[I]) <> TPString.Upcase(S2[I]) then Exit;
  Equal := True;
end;

procedure xSearch;
var
  xR: PSearchRec;
begin
  Value := 0;
  while Value < List^.Count do
  begin
    xR := List^.At(Value);
    if ((R.Attr = Directory) and (xR^.Attr and Directory <> 0)) or
       ((R.Attr <> Directory) and (xR^.Attr and Directory = 0)) then
    begin
      NewString := GetText(Value, 255);
      if Equal(NewString, CurString, SearchPos) then Exit;
    end;
    Inc(Value);
  end;
end;

procedure Popup(AnOrigin: TPoint);
var
  Mark: Array[False..True] of Char;
begin
  Mark[False] := ' ';
  Mark[True] := 'û';
  ShowPopup(AnOrigin, NewMenu(
    NewItem(Mark[FileSortMode = fsName] + ' ~N~ame', '', kbNoKey,
      cmfsName, hcFileDialog,
    NewItem(Mark[FileSortMode = fsExt] + ' E~x~tension', '', kbNoKey,
      cmfsExt, hcFileDialog,
    NewItem(Mark[FileSortMode = fsTime] + ' ~T~ime', '', kbNoKey,
      cmfsTime, hcFileDialog,
    NewItem(Mark[FileSortMode = fsSize] + ' ~S~ize', '', kbNoKey,
      cmfsSize, hcFileDialog,
    NewLine(
    NewItem(Mark[FileSortDir = fsAscend] + ' ~A~scending', '', kbNoKey,
      cmfsAscend, hcFileDialog,
    NewItem(Mark[FileSortDir = fsDescend] + ' ~D~escending', '', kbNoKey,
      cmfsDescend, hcFileDialog,
    nil)))))))));
end;

begin
  OldValue := Focused;
  if ((Event.What = evKeyDown) and (Event.KeyCode = kbAltF10)) or
     ((Event.What = evMouseDown) and (Event.Buttons = mbRightButton)) then
  begin
    Select;
    if Event.What = evMouseDown then
      repeat until not MouseEvent(Event, evMouseDown)
    else
    begin
      Event.Where.X := Owner^.Origin.X + Origin.X + 8;
      Event.Where.Y := Owner^.Origin.Y + Origin.Y + 1;
    end;
    Popup(Event.Where);
    Event.What := evNothing;
  end;
  if (Event.What = evKeyDown) and (NumCols <> 1) then
    if Event.KeyCode = kbHome then Event.KeyCode := kbCtrlPgUp
    else if Event.KeyCode = kbEnd then Event.KeyCode := kbCtrlPgDn;
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmOK;
    Event.What := evNothing;
  end
  else TListBox.HandleEvent(Event);
  if (Event.What = evKeyDown) and (Event.CharCode > ' ') and
     (Range <> 0) then
  begin
    SR := List^.At(Focused);
    if (NumCols = 1) and (SR^.FullName <> nil) then Name := SR^.FullName^
    else Name := SR^.Name;
    CurString := Name;
    OldPos := SearchPos;
    if Event.KeyCode = kbBack then
    begin
      if SearchPos <= 1 then
      begin
        SearchPos := 0;
        if NumCols = 1 then HScrollBar^.SetValue(0);
        DrawView;
        Event.What := evNothing;
        Exit;
      end;
      Dec(SearchPos);
    end
    else
    begin
      Inc(SearchPos);
      if SearchPos = 1 then ShiftStatus := GetShiftState;
      CurString[SearchPos] := TPString.Upcase(Event.CharCode);
    end;
    CurString[0] := Char(SearchPos);
    if ShiftStatus and (kbLeftShift + kbRightShift) <> 0 then
      R.Attr := Directory
    else R.Attr := 0;
    if NumCols = 1 then R.FullName := @CurString
    else R.Name := CurString;
    if FileSortMode <> fsName then xSearch
    else PSortedCollection(List)^.Search(@R, Value);
    if Value < Range then
    begin
      NewString := GetText(Value, 255);
      if Equal(NewString, CurString, SearchPos) then
        if Value <> OldValue then
        begin
          OldPos := SearchPos;
          FocusItem(Value);
          SearchPos := OldPos;
          if Event.CharCode = '.' then
          begin
            SR := List^.At(Focused);
            if (NumCols = 1) and (SR^.FullName <> nil) then
              Name := SR^.FullName^
            else Name := SR^.Name;
          end;
        end else
      else SearchPos := OldPos;
    end
    else SearchPos := OldPos;
    if Event.CharCode = '.' then
    begin
      if SR^.Attr and Directory <> 0 then ShiftStatus := kbLeftShift
      else ShiftStatus := 0;
      SearchPos := Pos('.', Name);
      if SearchPos = 0 then SearchPos := Length(Name);
    end;
    DrawView;
    if NumCols = 1 then
      if Cursor.X < 1 then
        HScrollBar^.SetValue(HScrollBar^.Value + Cursor.X - 1)
      else if Cursor.X >= Size.X then
        HScrollBar^.SetValue(HScrollBar^.Value + Cursor.X - Size.X + 1);
    Event.What := evNothing;
  end;
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmfsName: FileSortMode := fsName;
      cmfsExt: FileSortMode := fsExt;
      cmfsTime: FileSortMode := fsTime;
      cmfsSize: FileSortMode := fsSize;
      cmfsAscend: FileSortDir := fsAscend;
      cmfsDescend: FileSortDir := fsDescend;
      else Exit;
    end;
    SR := List^.At(Focused);
    if SR <> nil then
    begin
      R := SR^;
      if SR^.FullName <> nil then
      begin
        Name := SR^.FullName^;
        R.FullName := @Name;
      end
      else R.FullName := nil;
    end;
    Owner^.Lock;
    with PFileDialog(Owner)^ do Name := Concat(DirectoryStr^, WildCard);
    ReadDirectory(Name);
    if SR = nil then Value := 0
    else PSortedCollection(List)^.Search(@R, Value);
    FocusItem(Value);
    DrawView;
    Owner^.Unlock;
  end;
end;

procedure TFileList.ReadDirectory(AWildCard: FNameStr);
const
  FindAttr = ReadOnly + Archive;
  AllFiles = '*.*';
  PrevDir  = '..';
var
  P: PSearchRec;
  FileList: PFileCollection;
  Dir, Name, Ext, Tmp: String;
  SR: lSearchRec;
begin
  CancelSysErrors := False;
  AWildCard := lFExpand(AWildCard);
  if CancelSysErrors then Exit;
  lFSplit(AWildCard, Dir, Name, Ext);
  FileList := New(PFileCollection, Init(32, 16));
  P := @P;
  Tmp := Dir;
  while Tmp[Length(Tmp)] = '\' do Dec(Tmp[0]);
  LogEvent := lcDiskRead;
  DrawStatusLine(
    Concat('Reading the directory ', TrimmedName(Tmp, 45), '.'));
  lFindFirst(AWildCard, FindAttr, SR);
  while (P <> nil) and (DosError = 0) do
  begin
    if SR.SR.Attr and Directory = 0 then
    begin
      P := MemAlloc(SizeOf(TSearchRec));
      if P <> nil then
      begin
        Move(SR.SR.Attr, P^, SizeOf(TSearchRec) - SizeOf(PString));
        if SR.FullName <> '' then P^.FullName := NewStr(SR.FullName)
        else P^.FullName := nil;
        FileList^.Insert(P);
      end;
    end;
    lFindNext(SR);
  end;
  lFindClose(SR);
  Tmp := Concat(Dir, AllFiles);
  lFindFirst(Tmp, Directory, SR);
  while (P <> nil) and (DosError = 0) do
  begin
    if (SR.SR.Attr and Directory <> 0) and (SR.SR.Name[1] <> '.') then
    begin
      P := MemAlloc(SizeOf(TSearchRec));
      if P <> nil then
      begin
        Move(SR.SR.Attr, P^, SizeOf(TSearchRec) - SizeOf(PString));
        if SR.FullName <> '' then P^.FullName := NewStr(SR.FullName)
        else P^.FullName := nil;
        FileList^.Insert(P);
      end;
    end;
    lFindNext(SR);
  end;
  lFindClose(SR);
  if Length(Dir) > 4 then
  begin
    P := MemAlloc(SizeOf(TSearchRec));
    if P <> nil then
    begin
      lFindFirst(Tmp, Directory, SR);
      lFindNext(SR);
      lFindClose(SR);
      if (DosError = 0) and (SR.SR.Name = PrevDir) then
        Move(SR.SR.Attr, P^, SizeOf(TSearchRec) - SizeOf(PString))
      else
      begin
        P^.Name := PrevDir;
        P^.Size := 0;
        P^.Time := $210000;
        P^.Attr := Directory;
      end;
      P^.FullName := nil;
      FileList^.Insert(P);
    end;
  end;
  if P = nil then MessageBox(
    ^C'Too many files.', nil, mfWarning + mfOkButton);
  HScrollBar^.SetValue(0);
  SearchPos := 0;
  NewList(FileList);
{  if Range = 0 then SetCursor(1, 0);}
end;

procedure TFileList.SetData(var Rec);
begin
end;

procedure TFileList.SetState(AState: Word; Enable: Boolean);
begin
  TListBox.SetState(AState, Enable);
  if NumCols <> 1 then HScrollBar^.Hide;
end;

constructor TFileInfoPane.Init(var Bounds: TRect);
begin
  TView.Init(Bounds);
  EventMask := EventMask or evBroadcast;
  GrowMode := gfGrowLoY + gfGrowHiY;
end;

procedure TFileInfoPane.Draw;
var
  Color: Word;
  Params: Array[0..6] of LongInt;
  M: String[3];
  D: String[9];
  T: String[9];
  Time: DateTime;
  Str: String[79];
  B: TDrawBuffer;
  Path, FmtId: String;
const
  sDirectoryLine = ' %-12s %-9s %3s %2d, %4d  %s%c';
  sFileLine      = ' %-12s %-9d %3s %2d, %4d  %s%c';

procedure GetFirstLine;
var
  F: lText;
  Name: FNameStr;
begin
  Str := '';
  while (Path <> '') and (Path[Length(Path)] <> '\') do Dec(Path[0]);
  if SR.FullName <> nil then Name := SR.FullName^ else Name := SR.Name;
  lAssignText(F, Concat(Path, Name));
  Reset(F.T);
  if IOResult <> 0 then Exit;
  while (Str = '') and not Eof(F.T) do
  begin
    Readln(F.T, Str);
    TrimSt(Str);
  end;
  Close(F.T);
  InOutRes := 0;
end;

begin
  if PFileDialog(Owner)^.DirectoryStr = nil then
    Path := lFExpand(PFileDialog(Owner)^.WildCard)
  else Path := lFExpand(Concat(PFileDialog(Owner)^.DirectoryStr^,
    PFileDialog(Owner)^.WildCard));
  Color := GetColor($01);
  MoveChar(B, ' ', Color, Size.X);
  MoveStr(B[1], TrimmedName(Path, Size.X - 2), Color);
  WriteLine(0, 0, Size.X, 1, B);

  if (Owner^.Options and ofTileable <> 0) and
    Boolean(ViewLine) and (SR.Attr and Directory = 0) then GetFirstLine
  else if SR.Name = '' then Str := ''
  else
  begin
    MoveChar(B, ' ', Color, Size.X);
    Params[0] := Longint(@SR.Name);
    if SR.Attr and Directory <> 0 then
    begin
      FmtId := sDirectoryLine;
      D := 'Directory';
      Params[1] := Longint(@D);
    end else
    begin
      FmtId := sFileLine;
      if SR.Attr and faSizeInKB <> 0 then
      begin
        FmtId[10] := '8';
        System.Insert('K', FmtId, 12);
        System.Delete(FmtId, 9, 1);
      end;
      Params[1] := SR.Size;
    end;
    UnpackTime(SR.Time, Time);
    with Time do
    begin
      M := MonthStr(Month);
      Params[2] := Longint(@M);
      Params[3] := Day;
      Params[4] := Year;
      T := FormatTimeStr(Hour, Min, Sec);
    end;
    System.Delete(T, 6, 3);
    if T[1] = '0' then T[1] := ' ';
    Params[5] := Longint(@T);
    if T[Length(T)] = ' ' then Params[6] := Byte(' ')
    else Params[6] := Byte('m');
    FormatStr(Str, FmtId, Params);
  end;
  MoveChar(B, ' ', Color, Size.X);
  MoveStr(B, Str, Color);
  WriteLine(0, 1, Size.X, 1, B);
end;

function TFileInfoPane.GetPalette: PPalette;
const
  P: String[Length(CInfoPane)] = CInfoPane;
begin
  GetPalette := @P;
end;

procedure TFileInfoPane.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  if (Event.What = evBroadcast) and
     (Event.Command = cmListItemSelected) then
  begin
    if Event.InfoPtr = nil then FillChar(SR, SizeOf(TSearchRec), 0)
    else SR := PSearchRec(Event.InfoPtr)^;
    DrawView;
  end;
end;

function TViewCheck.DataSize: Word;
begin
  DataSize := 0;
end;

procedure TViewCheck.GetData(var Rec);
begin
end;

procedure TViewCheck.HandleEvent(var Event: TEvent);
var
  P: PFileList;
begin
  if (State and (sfSelected + sfFocused) = 0) and (Owner <> nil) and
     (Pointer(Owner^.Current) = PFileDialog(Owner)^.FileList) then
    P := PFileDialog(Owner)^.FileList
  else P := nil;
  TCheckBoxes.HandleEvent(Event);
  if (P <> nil) and (State and (sfSelected + sfFocused) <> 0) then
  begin
    P^.Select;
    P^.FocusItem(P^.Focused);
  end;
end;

procedure TViewCheck.Press(Item: Integer);
begin
  TCheckBoxes.Press(Item);
  ViewLine := Boolean(Value);
end;

procedure TViewCheck.SetData(var Rec);
begin
end;

procedure TToggleLabel.HandleEvent(var Event: TEvent);
begin
  if Event.What = evMouseDown then
  begin
    repeat until not MouseEvent(Event, evMouseMove);
    if MouseInView(Event.Where) then
      PFileDialog(Owner)^.ToggleListColumns;
    Event.What := evNothing;
  end
  else TLabel.HandleEvent(Event);
end;

procedure TToggleLabel.UpdateText;
begin
  if SingleColumn then Text^[2] := 'X'
  else Text^[2] := ' ';
  DrawView;
end;

function FileHistoryFunc(Link: PInputLine;
  const S: String): String;
var
  Name: String;
begin
  if (S = '') or ((S[0] > #1) and (S[2] = ':')) then Name := S
  else PFileDialog(Link^.Owner)^.GetFileName(Name);
  FileHistoryFunc := Name;
end;

constructor TFileDialog.Init(const AWildCard: TWildStr;
  const ATitle: String; const InputName: String;
  AOptions: Word; HistoryId: Word);
var
  Control: PView;
  HBar, VBar: PScrollBar;
  R: TRect;
  Opt: Word;

procedure IncRect;
begin
  Opt := bfNormal;
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
end;

begin
  Desktop^.GetExtent(R);
  R.A.X := 15; R.B.X := 64; Inc(R.A.Y); Dec(R.B.Y);
  TDialog.Init(R, ATitle);
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  DirectoryStr := nil;
  WildCard := AWildCard;
  HelpCtx := hcFileDialog;
  if lAPI = lDOS then SingleColumn := False;

  R.Assign(3, 2, 32, 3);
  FileName := New(PFileInputLine, Init(R, 255));
  FileName^.Data^ := WildCard;
  Insert(FileName);
  R.Assign(2, 1, 35, 2);
  Insert(New(PLabel, Init(R, InputName, FileName)));
  R.Assign(32, 2, 35, 3);
  Control := StandardHistory(FileName, HistoryId);
  PHistory(Control)^.HistoryPutFunc := FileHistoryFunc;

  R.Assign(3, Size.Y - 5, 34, Size.Y - 4);
  VBar := New(PScrollBar, Init(R));
  Insert(VBar);
  VBar^.Options := VBar^.Options or ofPostProcess;
  HBar := New(PScrollBar, Init(R));
  Insert(HBar);
  HBar^.Options := HBar^.Options or ofPostProcess;
  HBar^.SetRange(0, 255);
  HBar^.SetStep(31, 1);

  R.Assign(3, 5, 34, Size.Y - 5);
  FileList := New(PFileList, Init(R,
    1 + Byte(not SingleColumn), HBar, VBar));
  FileList^.Options := FileList^.Options or ofFramed;
  Insert(FileList);
  R.Assign(3, 4, 10, 5);
  Insert(New(PLabel, Init(R, '~F~iles', FileList)));

  if lAPI <> lDOS then
  begin
    R.Assign(19, 4, 34, 5);
    ToggleLabel := New(PToggleLabel, Init(R, '[ ] Long name', FileList));
    Insert(ToggleLabel);
    ToggleLabel^.UpdateText;
  end;

  if AOptions and fdView <> 0 then
  begin
    R.Assign(36, Size.Y - 5, Size.X - 3, Size.Y - 4);
    Control := New(PViewCheck, Init(R, NewSItem('~V~iew', nil)));
    PViewCheck(Control)^.Value := Word(ViewLine);
    Insert(Control);
    Options := Options or ofTileable;
  end;

  R.Assign(35, 2, 47, 4);
  Opt := bfDefault;
  if AOptions and fdOpenButton <> 0 then
  begin
    Insert(New(PButton, Init(R, '~O~pen', cmFileOpen, Opt)));
    IncRect;
  end;
  if AOptions and fdOkButton <> 0 then
  begin
    Insert(New(PButton, Init(R, 'O~K~', cmFileOpen, Opt)));
    IncRect;
  end;
  if AOptions and fdReplaceButton <> 0 then
  begin
    Insert(New(PButton, Init(R, '~R~eplace', cmFileReplace, Opt)));
    IncRect;
  end;
  if AOptions and fdClearButton <> 0 then
  begin
    Insert(New(PButton, Init(R, '~C~lear', cmFileClear, Opt)));
    IncRect;
  end;
  if AOptions and fdMaskButton <> 0 then
  begin
    Insert(New(PButton, Init(R, '~M~ask', cmFileMask, Opt)));
    IncRect;
  end;
  if AOptions and fdSelButton <> 0 then
  begin
    Insert(New(PButton, Init(R, '~S~elected', cmSelectedFiles, Opt)));
    IncRect;
  end;
  if AOptions and fdRunButton <> 0 then
  begin
    Insert(New(PButton, Init(R, '~R~un', cmOk, Opt)));
    IncRect;
  end;
  if AOptions and fdLoadButton <> 0 then
  begin
    Insert(New(PButton, Init(R, '~L~oad', cmFileOpen, Opt)));
    IncRect;
  end;
  if AOptions and fdStoreButton <> 0 then
  begin
    Insert(New(PButton, Init(R, '~S~tore', cmFileReplace, Opt)));
    IncRect;
  end;
  StandardCancelButton(R, @Self);
  if AOptions and fdHelpButton <> 0 then
  begin
    IncRect;
    StandardHelpButton(R, @Self);
  end;

  R.Assign(1, Size.Y - 3, 48, Size.Y - 1);
  Insert(New(PFileInfoPane, Init(R)));

  SelectNext(False);
end;

destructor TFileDialog.Done;
begin
  DisposeStr(DirectoryStr);
  TDialog.Done;
end;

procedure TFileDialog.GetData(var Rec);
begin
  TDialog.GetData(Rec);
  GetFileName(FNameStr(Rec));
end;

procedure TFileDialog.GetFileName(var S: FNameStr);
var
  Path, Name, Ext, TName, TExt: String;

function RelativePath(const S: FNameStr): Boolean;
begin
{  RelativePath := not ((S <> '') and ((S[1] = '\') or (S[2] = ':')));}
  RelativePath := not (((S <> '') and (S[1] = '\')) or
    ((Length(S) > 1) and (S[2] = ':')));
end;

(*
procedure NoWildChars(var S: String); assembler;
asm
        PUSH    DS
        LDS     SI,S
        LODSB
        XCHG    AL,CL
        XOR     CH,CH
        JCXZ    @@3
        PUSH    DS
        POP     ES
        MOV     DI,SI
@@1:    LODSB
        CMP     AL,'?'
        JE      @@2
        CMP     AL,'*'
        JE      @@2
        STOSB
@@2:    LOOP    @@1
        XCHG    AX,DI
        MOV     DI,WORD PTR S
        SUB     AX,DI
        DEC     AL
        STOSB
@@3:    POP     DS
end;
*)

begin
  S := FileName^.Data^;
  if (Length(S) > 1) and (S[1] = '"') and (S[Length(S)] = '"') then
    S := System.Copy(S, 2, Length(S) - 2);
  S := CNFileName(S);
  if RelativePath(S) and (DirectoryStr <> nil) then
    S := lFExpand(Concat(DirectoryStr^, S))
  else S := lFExpand(S);
  lFSplit(S, Path, Name, Ext);
  if (Name = '') and not IsDir(S) then
  begin
    lFSplit(WildCard, Path, TName, TExt);
    if Name = '' then S := Concat(S, TName);
    if Ext = '' then
    begin
{      NoWildChars(TExt);}
      S := Concat(S, TExt);
    end;
  end;
  lFSplit(S, Path, Name, Ext);
  S := Concat(Path, Name);
  if (Ext <> '.') or IsWild(Name) then S := Concat(S, Ext);
  if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
    lGetShortFileName(S, S);
end;

procedure TFileDialog.HandleEvent(var Event: TEvent);
var
  P: TPoint;
  S: FNameStr;
begin
  if (Event.What = evMouseDown) and (Event.Buttons = mbLeftButton) then
  begin
    MakeLocal(Event.Where, P);
    if (P.X >= 3) and (P.X <= 6) and (P.Y = 1) then
    begin
      Event.What := evKeyDown;
      Event.KeyCode := kbAltD;
    end;
  end;
  if Event.What = evKeyDown then
    if Event.KeyCode = kbAltD then
    begin
      SelectDriveDialog('Select ~new~ drive:', 0, DirectoryStr^[1], S);
      if S = '' then Event.What := evNothing
      else
      begin
        FileName^.Data^ := Concat(S, WildCard);
        Event.KeyCode := kbEnter;
      end;
    end
    else case Event.CharCode of
      ^F:
        begin
          ToggleListColumns;
          Event.What := evNothing;
        end;
      ^\:
        begin
          FileName^.Data^ := Concat('\', WildCard);
          if (DirectoryStr <> nil) and (DirectoryStr^[1] <> '\') then
            FileName^.Data^ := Concat(
              DirectoryStr^[1], ':', FileName^.Data^);
          Event.KeyCode := kbEnter;
        end;
    end;
  TDialog.HandleEvent(Event);
  if Event.What = evCommand then
    case Event.Command of
      cmFileOpen, cmFileReplace, cmFileClear, cmFileMask, cmSelectedFiles:
        begin
          EndModal(Event.Command);
          Event.What := evNothing;
        end;
    end;
end;

procedure TFileDialog.SetData(var Rec);
begin
  TDialog.SetData(Rec);
  if (FNameStr(Rec) <> '') and (IsWild(TWildStr(Rec))) then
    Valid(cmFileInit)
  else ReadDirectory;
end;

procedure TFileDialog.ReadDirectory;
begin
  FileList^.ReadDirectory(WildCard);
  DisposeStr(DirectoryStr);
  DirectoryStr := NewStr(GetCurDir);
end;

procedure TFileDialog.ToggleListColumns;
var
  I: Integer;
  P: PSearchRec;
  R: TSearchRec;
  S: FNameStr;
begin
  if lAPI <> lDOS then with FileList^ do
  begin
    NumCols := 1 + Byte(SingleColumn);
    SingleColumn := not SingleColumn;
    ToggleLabel^.UpdateText;
    P := List^.At(Focused);
    if P <> nil then
    begin
      R := P^;
      if P^.FullName <> nil then
      begin
        S := P^.FullName^;
        R.FullName := @S;
      end
      else R.FullName := nil;
    end;
    Lock;
    ReadDirectory(Concat(DirectoryStr^, WildCard));
    if SingleColumn then HScrollBar^.Show
    else HScrollBar^.Hide;
    if P = nil then I := 0
    else PSortedCollection(List)^.Search(@R, I);
    FocusItem(I);
    DrawView;
    Unlock;
  end;
end;

function TFileDialog.Valid(Command: Word): Boolean;
var
  B: Byte;
  C: Char;
  T: Boolean;
  R: Real;
  Dir, Name, Ext, DS, NS, FName: String;

function CheckDirectory(var S: FNameStr): Boolean;
begin
  CheckDirectory := True;
  if not DirPresent(S) then
  begin
    if Command = cmFileInit then S := GetCurDir
    else
    begin
      if CreateDirMsgBox(S) = cmOk then
      begin
        CreateDir(S);
        if DirPresent(S) then Exit;
        InvalidDirMsgBox(S);
      end;
      FileName^.Select;
      CheckDirectory := False;
    end;
  end;
end;

function NameIndex: Integer;
var
  Found: Boolean;
  I: Integer;
  P: PSearchRec;
begin
  Found := False;
  I := 0;
  while not Found and (I < FileList^.List^.Count) do
  begin
    P := FileList^.List^.At(I);
    if P^.Attr and Directory <> 0 then
    begin
      if P^.FullName <> nil then Found :=
        (CompUCString(P^.FullName^, NS) = Equal) and
        (CompUCString(Concat(DirectoryStr^, P^.FullName^), DS) = Equal);
      if not Found then Found :=
        (CompUCString(P^.Name, NS) = Equal) and
        (CompUCString(Concat(DirectoryStr^, P^.Name), DS) = Equal);
    end;
    if not Found then Inc(I);
  end;
  if Found then NameIndex := I else NameIndex := FileList^.Focused;
end;

begin
  if Command = cmValid then
  begin
    Valid := TDialog.Valid(Command);
    Exit;
  end
  else Valid := False;
  if TDialog.Valid(Command) then
  begin
    if (Command <> cmClose) and
       (Command <> cmCancel) and
       (Command <> cmFileClear) and
       (Command <> cmSelectedFiles) then
    begin
      C := Upcase(FileName^.Data^[1]);
      if (FileName^.Data^[0] > #1) and (FileName^.Data^[2] = ':') and
        DriveAvailable(C, sdAuto) and not DriveValid(C, R) then Exit;
      GetFileName(FName);
      B := ValidFileName(FName);
      if B = 1 then
      begin
        InvalidFileNameMsgBox(FName);
        Exit;
      end;
      if IsWild(FName) then
      begin
        lFSplit(FName, Dir, Name, Ext);
        if CheckDirectory(Dir) then
        begin
          if (DirectoryStr = nil) or (FileList^.State and sfSelected = 0) or
             (FileList^.List^.Count = 0) or (FileList^.Focused <> 0) or
             (FileName^.Data^ = '') or (FileName^.Data^[1] <> '.') then
            DS := ''
          else
          begin
            DS := DirectoryStr^;
            while DS[Length(DS)] = '\' do Dec(DS[0]);
            NS := JustFileName(DS);
          end;
          DisposeStr(DirectoryStr);
          DirectoryStr := NewStr(Dir);
          WildCard := Concat(Name, Ext);
          if Command <> cmFileInit then
          begin
            FileName^.Data^ := '';
            FileList^.Select;
          end;
          if Command = cmFileMask then
          begin
            FileName^.Data^ := Concat(DirectoryStr^, WildCard);
            Valid := True;
          end
          else
          begin
            Lock;
            FileList^.ReadDirectory(Concat(DirectoryStr^, WildCard));
            if DS <> '' then FileList^.FocusItem(NameIndex);
            Unlock;
          end;
        end;
      end
      else if IsDir(FName) then
      begin
        if CheckDirectory(FName) then
        begin
          DisposeStr(DirectoryStr);
          DirectoryStr := NewStr(AddBackSlash(FName));
          if Command <> cmFileInit then
          begin
            FileName^.Data^ := '';
            FileList^.Select;
          end;
          if Command = cmFileMask then
          begin
            FileName^.Data^ := Concat(DirectoryStr^, WildCard);
            Valid := True;
          end
          else FileList^.ReadDirectory(Concat(DirectoryStr^, WildCard));
        end
      end
      else
      begin
        B := ValidFileName(FName);
        if B = 0 then Valid := True
        else if B = 1 then InvalidFileNameMsgBox(FName)
        else
        begin
          Dir := FName;
          while (Dir <> '') and (Dir[Length(Dir)] <> '\') do Dec(Dir[0]);
          if CreateDirMsgBox(Dir) = cmOk then
          begin
            CreateDir(Dir);
            if ValidFileName(FName) = 0 then Valid := True
            else InvalidFileNameMsgBox(FName);
          end;
        end;
      end;
    end
    else Valid := True;
  end;
end;

procedure TDirInputLine.SetData(var Rec);
var
  S: FNameStr;
begin
  S := PString(@Rec)^;
  if S[Length(S)] = #255 then
  begin
    Dec(S[0], 3);
    S := JustPathName(S);
  end;
  TInputLine.SetData(S);
end;

procedure TDirCollection.FreeItem(Item: Pointer);
var
  DirItem: PDirEntry absolute Item;
begin
  if DirItem^.DisplayText <> nil then DisposeStr(DirItem^.DisplayText);
  if DirItem^.DirectoryStr <> nil then DisposeStr(DirItem^.DirectoryStr);
  if DirItem <> nil then Dispose(DirItem);
end;

const
  Drives = 'Drives';

constructor TDirListBox.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TListBox.Init(Bounds, 1, AVScrollBar);
  HScrollBar := AHScrollBar;
  GrowMode := gfGrowHiY;
  Dir := '';
end;

destructor TDirListBox.Done;
begin
  if List <> nil then Dispose(List, Done);
  TListBox.Done;
end;

function TDirListBox.GetText(Item: Integer; MaxLen: Integer): String;
begin
  GetText := PDirEntry(List^.At(Item))^.DisplayText^;
end;

procedure TDirListBox.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmChangeDir;
    Event.What := evNothing;
  end
  else TListBox.HandleEvent(Event);
end;

function TDirListBox.IsSelected(Item: Integer): Boolean;
begin
  IsSelected := Item = Cur;
end;

procedure TDirListBox.NewDirectory(var ADir: String);
const
  PathDir            = 'ÀÄÂ';
  FirstDir           =   'ÀÂÄ';
  MiddleDir          =   ' ÃÄ';
  LastDir            =   ' ÀÄ';
  IndentSize         = '  ';
var
  Mode: TSeekDrive;
  AList: PCollection;
  C, OldC: Char;
  P: PString;
  isFirst: Boolean;
  I: Integer;
  DirEntry: PDirEntry;
  Equipment: Word absolute $0:$410;
  NewDir, Dirct, S, Indent: String;
  SR: lSearchRec;

function NewDirEntry(const DisplayText, Directory: String): PDirEntry; near;
var
  DirEntry: PDirEntry;
begin
  New(DirEntry);
  DirEntry^.DisplayText := NewStr(DisplayText);
  DirEntry^.DirectoryStr := NewStr(Directory);
  NewDirEntry := DirEntry;
end;

function GetCurDrive: Char; assembler;
asm
        MOV     AH,19H
        INT     21H
        ADD     AL,'A'
end;

begin
  Dir := ADir;
  AList := New(PDirCollection, Init(16, 16));
  AList^.Insert(NewDirEntry(Drives, Drives));
  if Dir = Drives then
  begin
    isFirst := True;
    OldC := ' ';
    if UserDrivesEnabled <> 0 then Mode := sdUser
    else Mode := sdDisk;
    for C := 'A' to 'Z' do
    begin
      if (C < 'C') or DriveAvailable(C, Mode) then
      begin
        if OldC <> ' ' then
        begin
          if isFirst then
          begin
            S := Concat(FirstDir, OldC);
            isFirst := False;
          end
          else S := Concat(MiddleDir, OldC);
          AList^.Insert(NewDirEntry(S, Concat(OldC, ':\')));
        end;
        if C = GetCurDrive then Cur := AList^.Count;
        OldC := C;
      end;
    end;
    if OldC <> ' ' then AList^.Insert(
      NewDirEntry(Concat(LastDir, OldC), Concat(OldC, ':\')));
  end
  else
  begin
    Indent := IndentSize;
    NewDir := Dir;
    Dirct := Copy(NewDir, 1, 3);
    AList^.Insert(NewDirEntry(Concat(PathDir, Dirct), Dirct));
    NewDir := Copy(NewDir, 4, 255);
    while NewDir <> '' do
    begin
      I := Pos('\', NewDir);
      if I <> 0 then
      begin
        S := Copy(NewDir, 1, I - 1);
        Dirct := Concat(Dirct, S);
        AList^.Insert(NewDirEntry(Concat(Indent, PathDir, S), Dirct));
        NewDir := Copy(NewDir, I + 1, 255);
      end
      else
      begin
        Dirct := Concat(Dirct, NewDir);
        AList^.Insert(NewDirEntry(Concat(Indent, PathDir, NewDir), Dirct));
        NewDir := '';
      end;
      Indent := Concat(Indent, IndentSize);
      Dirct := Concat(Dirct, '\');
    end;
    Cur := AList^.Count - 1;
    isFirst := True;
    NewDir := Concat(Dirct, '*.*');
    lFindFirst(NewDir, Directory, SR);
    while DosError = 0 do
    begin
      if (SR.SR.Attr and Directory <> 0) and (SR.SR.Name[1] <> '.') then
      begin
        if isFirst then
        begin
          S := FirstDir;
          isFirst := False;
        end else S := MiddleDir;
        if SR.FullName <> '' then NewDir := SR.FullName
        else NewDir := SR.SR.Name;
        AList^.Insert(NewDirEntry(
          Concat(Indent, S, NewDir), Concat(Dirct, NewDir)));
      end;
      lFindNext(SR);
    end;
    lFindClose(SR);
    P := PDirEntry(AList^.At(AList^.Count - 1))^.DisplayText;
    I := Pos('À', P^);
    if I = 0 then
    begin
      I := Pos('Ã', P^);
      if I <> 0 then P^[I] := 'À';
    end else
    begin
      P^[I + 1] := 'Ä';
      P^[I + 2] := 'Ä';
    end;
  end;
  NewList(AList);
  FocusItem(Cur);
end;

procedure TDirListBox.SetState(AState: Word; Enable: Boolean);
begin
  TListBox.SetState(AState, Enable);
  if AState and sfFocused <> 0 then
    PChDirDialog(Owner)^.ChDirButton^.MakeDefault(Enable);
end;

function DirHistoryFunc(Link: PInputLine;
  const S: String): String;
begin
  if S = '' then DirHistoryFunc := ''
  else DirHistoryFunc := lFExpand(CNFileName(S));
end;

constructor TChDirDialog.Init(AOptions: Word; HistoryId: Word);
var
  R: TRect;
  Control: PView;
  HBar, VBar: PScrollBar;

procedure IncRect;
begin
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
end;

begin
  Desktop^.GetExtent(R);
  R.A.X := 16; R.B.X := 63; Inc(R.A.Y, 1); Dec(R.B.Y, 2);
  TDialog.Init(R, 'Change directory');
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcDirDialog;

  R.Assign(3, 3, 30, 4);
  DirInput := New(PDirInputLine, Init(R, 255));
  Insert(DirInput);
  R.Assign(2, 2, 33, 3);
  Insert(New(PLabel, Init(R, 'Directory ~n~ame', DirInput)));
  R.Assign(30, 3, 33, 4);
  Control := StandardHistory(DirInput, HistoryId);
  PHistory(Control)^.HistoryPutFunc := DirHistoryFunc;

  R.Assign(32, 6, 33, Size.Y - 3);
  VBar := New(PScrollBar, Init(R));
  Insert(VBar);

  R.Assign(3, Size.Y - 3, 32, Size.Y - 2);
  HBar := New(PScrollBar, Init(R));
  HBar^.Options := HBar^.Options or ofPostProcess;
  Insert(HBar);
  HBar^.SetRange(0, 255);
  HBar^.SetStep(29, 1);

  R.Assign(3, 6, 32, Size.Y - 3);
  DirList := New(PDirListBox, Init(R, HBar, VBar));
  Insert(DirList);
  R.Assign(2, 5, 33, 6);
  Insert(New(PLabel, Init(R, '~D~irectory tree', DirList)));

  R.Assign(34, 3, 44, 5);
  OkButton := StandardOkButton(R, @Self);
  IncRect;
  ChDirButton := New(PButton, Init(R, '~C~hange', cmChangeDir, bfNormal));
  Insert(ChDirButton);
  IncRect;
  Insert(New(PButton, Init(R, '~R~evert', cmRevert, bfNormal)));
  IncRect;
  StandardCancelButton(R, @Self);
  if AOptions and cdHelpButton <> 0 then
  begin
    IncRect;
    StandardHelpButton(R, @Self);
  end;

  if AOptions and cdNoLoadDir = 0 then SetUpDialog;

  SelectNext(False);
end;

function TChDirDialog.DataSize: Word;
begin
  DataSize := 0;
end;

procedure TChDirDialog.GetData(var Rec);
begin
end;

procedure TChDirDialog.HandleEvent(var Event: TEvent);
var
  P: PDirEntry;
  CurDir: String;
begin
  TDialog.HandleEvent(Event);
  case Event.What of
    evCommand:
      begin
        case Event.Command of
          cmRevert: lGetDir(0, CurDir);
          cmChangeDir:
            begin
              P := DirList^.List^.At(DirList^.Focused);
              if (P^.DirectoryStr^ = Drives) or
                DriveAvailable(P^.DirectoryStr^[1], sdAuto) then
                  CurDir := P^.DirectoryStr^
              else Exit;
            end;
          else Exit;
        end;
        if (Length(CurDir) > 3) and (CurDir[Length(CurDir)] = '\') then
          CurDir := Copy(CurDir, 1, Length(CurDir) - 1);
        Lock;
        DirList^.NewDirectory(CurDir);
        DirInput^.Data^ := CurDir;
        DirInput^.CurPos := Length(CurDir);
{        DirInput^.FirstPos := DirInput^.CurPos - DirInput^.Size.X + 2;
        if DirInput^.FirstPos < 0 then DirInput^.FirstPos := 0;}
        DirInput^.DrawView;
        DirList^.Select;
        Unlock;
        Event.What := evNothing;
      end;
  end;
end;

procedure TChDirDialog.SetData(var Rec);
begin
end;

procedure TChDirDialog.SetUpDialog;
var
  CurDir: String;
begin
  if DirList <> nil then
  begin
    CurDir := GetCurDir;
    DirList^.NewDirectory(CurDir);
    if (Length(CurDir) > 3) and (CurDir[Length(CurDir)] = '\') then
      CurDir := Copy(CurDir, 1, Length(CurDir) - 1);
    if DirInput <> nil then
    begin
      DirInput^.Data^ := CurDir;
      DirInput^.DrawView;
    end;
  end;
end;

function TChDirDialog.Valid(Command: Word): Boolean;
var
  R: Real;
  P: FNameStr;
begin
  Valid := True;
  if Command = cmOk then
  begin
    P := lFExpand(CNFileName(DirInput^.Data^));
    if (Length(P) > 3) and (P[Length(P)] = '\') then Dec(P[0]);
    if (Length(P) > 1) and (P[2] = ':') and
       DriveAvailable(P[1], sdAuto) and not DriveValid(P[1], R) then
    begin
      Valid := False;
      Exit;
    end;
    lChDir(P);
    if IOResult <> 0 then
    begin
      if CreateDirMsgBox(P) = cmOk then
      begin
        MkDirPrim(P, nil);
        Message(Desktop, evBroadcast, cmUpdateDisk, nil);
        lChDir(P);
        if IOResult = 0 then Exit;
        InvalidDirMsgBox(P);
      end;
      Valid := False;
    end;
  end;
end;

procedure ChangeDir;
begin
  Application^.ExecuteDialog(
    New(PChDirDialog, Init(cdNormal + cdHelpButton,
    DirHistoryID)), nil, False);
end;

end.