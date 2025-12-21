{$I-,X+,O+,F+}
unit ProgList;

interface

uses Objects, Drivers, Views, Dialogs, HotKeys;

type
  TExecStr = String[255];

  PExecRec = ^TExecRec;
  TExecRec = record
    Path, Params, FileMask, LineMask: TExecStr;
    Main, Setup, Options: Word;
  end;

  PExecItem = ^TExecItem;
  TExecItem = object(TObject)
    Title, Path, Params, FileMask, LineMask: PString;
    Main, Setup, Options, HotKey: Word;
    HotKeyCount: Word;
    HotKeySequence: PHotKeySequence;
    HotKeyOpt: Word;
    HotKeyReserved: Pointer;
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Store(var S: TStream); virtual;
    procedure GetData(var AData: TExecRec; var AHotKey: Word);
    procedure SetData(const ATitle: String;
      const AData: TExecRec; AHotKey: Word);
  end;

  PProgInputLine = ^TProgInputLine;
  TProgInputLine = object(TInputLine)
    function Valid(Command: Word): Boolean; virtual;
  end;

  PProgList = ^TProgList;
  TProgList = object(TListBox)
    FileName, FocusName: PString;
    LockData: Boolean;
    LockFocus: Boolean;
    StatusWord: String[15];
    SequenceText: PStaticText;
    constructor Init(var Bounds: TRect; AScrollBar: PScrollBar;
      const AName, AFocusName: FNameStr);
    destructor Done; virtual;
    function DataSize: Word; virtual;
    procedure FocusItem(Item: Integer); virtual;
    procedure GetData(var Rec); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure FocusMask; virtual;
    procedure SaveList(const FName: FNameStr); virtual;
    function GetNewItem(const Header: String): PExecItem; virtual;
    procedure CheckDuplicates(AKey: Word;
      ASequence: PHotKeySequence; ACount: Word); virtual;
    procedure ModifyProg;
    procedure NewProg;
    procedure ProgIcon;
    procedure EditIcon;
    procedure DeleteProg;
    procedure NewItemPos;
    function ExecFile: Boolean;
    procedure ReloadList(P: PString);
    procedure UpdateCommands;
  end;

  PProgDialog = ^TProgDialog;
  TProgDialog = object(TDialog)
    ProgName: PProgInputLine;
    ProgList: PProgList;
    constructor Init(const AName, AFocusName: FNameStr);
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

function MainControl(var R: TRect): PView;
function SetupControl(var R: TRect): PView;
function OptionsControl(var R: TRect; HotI: Boolean): PView;

procedure GetProgDlgTitle(StatusChar: Char;
  const AName: FNameStr; var S: TTitleStr);

implementation

uses Memory, App, MsgBox, StdDlg, ExecPrim, KeyDlg, KeyName, EditMsg,
  EditFile, CNInputs, History, DirPrim, HeapUMB, Filters, TPString,
  Consts, Commands, Defaults;

function MainControl(var R: TRect): PView;
begin
  MainControl := New(PRadioButtons, Init(R,
    NewSItem('S~w~ap',
    NewSItem('~U~nload',
    NewSItem('Non~e~', nil)))));
end;

function SetupControl(var R: TRect): PView;
begin
  SetupControl := New(PCheckBoxes, Init(R,
    NewSItem('Sa~v~e editor files',
    NewSItem('Save deskt~o~p',
    NewSItem('Load ~S~nipper', nil)))));
end;

function OptionsControl(var R: TRect; HotI: Boolean): PView;
var
  S: String[7];
begin
  if HotI then S := 'd~i~sk' else S := 'disk';
  OptionsControl := New(PCheckBoxes, Init(R,
    NewSItem('Messa~g~e',
    NewSItem('~L~oad COMMAND.COM',
    NewSItem('Swap to ' + S, nil)))));
end;

procedure GetTitleStr(P: Pointer; var S: String; ForList: Boolean);
var
  HKS: String;
begin
  FillChar(S, SizeOf(FNameStr), 0);
  if P = nil then Exit;
  if PExecItem(P)^.Title <> nil then S := PExecItem(P)^.Title^;
  if S = '' then S := 'Untitled';
  if not ForList then Exit;
  S[0] := #58;
  HKS := ' ' + GetKeyName(PExecItem(P)^.HotKey);
  Move(HKS[1], S[59 - Length(HKS)], Length(HKS));
end;

constructor TExecItem.Load(var S: TStream);
begin
  TObject.Init;
{
  Title := S.ReadStr;
  Path := S.ReadStr;
  Params := S.ReadStr;
  FileMask := S.ReadStr;
  LineMask := S.ReadStr;
}
  Title := ReadStrUMB(@S);
  Path := ReadStrUMB(@S);
  Params := ReadStrUMB(@S);
  FileMask := ReadStrUMB(@S);
  LineMask := ReadStrUMB(@S);
  S.Read(Main, SizeOf(Main) + SizeOf(Setup) +
    SizeOf(Options) + SizeOf(HotKey));
  if HotKey = hkSeq then
  begin
    S.Read(HotKeyCount, SizeOf(Word));
{    GetMem(HotKeySequence, HotKeyCount * SizeOf(Word));}
    GetMemUMB(HotKeySequence, HotKeyCount * SizeOf(Word));
    S.Read(HotKeySequence^, HotKeyCount * SizeOf(Word));
    S.Read(HotKeyOpt, SizeOf(Word));
    S.Read(HotKeyReserved, SizeOf(Pointer));
  end;
end;

destructor TExecItem.Done;
begin
{
  if HotKey = hkSeq then
    FreeMem(HotKeySequence, HotKeyCount * SizeOf(Word));
  DisposeStr(LineMask);
  DisposeStr(FileMask);
  DisposeStr(Params);
  DisposeStr(Path);
  DisposeStr(Title);
}
  if HotKey = hkSeq then
    FreeMemUMB(HotKeySequence, HotKeyCount * SizeOf(Word));
  DisposeStrUMB(LineMask);
  DisposeStrUMB(FileMask);
  DisposeStrUMB(Params);
  DisposeStrUMB(Path);
  DisposeStrUMB(Title);
  TObject.Done;
end;

procedure TExecItem.Store(var S: TStream);
begin
  S.WriteStr(Title);
  S.WriteStr(Path);
  S.WriteStr(Params);
  S.WriteStr(FileMask);
  S.WriteStr(LineMask);
  S.Write(Main, SizeOf(Main) + SizeOf(Setup) +
    SizeOf(Options) + SizeOf(HotKey));
  if HotKey = hkSeq then
  begin
    S.Write(HotKeyCount, SizeOf(Word));
    S.Write(HotKeySequence^, HotKeyCount * SizeOf(Word));
    S.Write(HotKeyOpt, SizeOf(Word));
    S.Write(HotKeyReserved, SizeOf(Pointer));
  end;
end;

procedure TExecItem.GetData(var AData: TExecRec; var AHotKey: Word);

procedure SetRecField(P: PString; var S: TExecStr);
begin
  if P = nil then S := '' else S := P^;
end;

begin
  SetRecField(Path, AData.Path);
  SetRecField(Params, AData.Params);
  SetRecField(FileMask, AData.FileMask);
  SetRecField(LineMask, AData.LineMask);
  Move(Main, AData.Main, SizeOf(Word) * 3);
  AHotKey := HotKey;
end;

procedure TExecItem.SetData(const ATitle: String;
  const AData: TExecRec; AHotKey: Word);

procedure SetNewStrItem(var P: PString; const S: String);
begin
{
  DisposeStr(P);
  P := NewStr(S);
}
  DisposeStrUMB(P);
  P := NewStrUMB(S);
end;

begin
  SetNewStrItem(Title, ATitle);
  SetNewStrItem(Path, AData.Path);
  SetNewStrItem(Params, AData.Params);
  SetNewStrItem(FileMask, AData.FileMask);
  SetNewStrItem(LineMask, AData.LineMask);
  Move(AData.Main, Main, SizeOf(Word) * 3);
  HotKey := AHotkey;
end;

function TProgInputLine.Valid(Command: Word): Boolean;
begin
  if Command = cmOk then
    if Trim(Data^) = '' then
    begin
      Select;
      Valid := False;
    end
    else if (Data^[1] = '$') and
      (Pos('PRG(', StUpcase(Data^)) = 2) then
    begin
      Owner^.GetData(ExecRec);
      PrepareExecEvent;
      Valid := False;
    end else
  else Valid := TInputLine.Valid(Command);
end;

constructor TProgList.Init(var Bounds: TRect; AScrollBar: PScrollBar;
  const AName, AFocusName: FNameStr);
begin
  TListBox.Init(Bounds, 1, AScrollBar);
{
  FileName := NewStr(AName);
  FocusName := NewStr(AFocusName);
}
  FileName := NewStrUMB(AName);
  FocusName := NewStrUMB(AFocusName);
  StatusWord := 'Program';
end;

destructor TProgList.Done;
begin
  LastProgIndex := Focused;
  if List <> nil then Dispose(List, Done);
{
  DisposeStr(FocusName);
  DisposeStr(FileName);
}
  DisposeStrUMB(FocusName);
  DisposeStrUMB(FileName);
  TListBox.Done;
end;

function TProgList.DataSize: Word;
begin
  DataSize := 0;
end;

procedure TProgList.FocusItem(Item: Integer);
var
  W: Word;
  P: PExecItem;
  S: String[79];
  R: TExecRec;
begin
  TListBox.FocusItem(Item);
  if LockFocus then Exit;
  P := List^.At(Focused);
  if P = nil then FillChar(R, SizeOf(TExecRec), 0)
  else P^.GetData(R, W);
  Owner^.SetData(R);
  if SequenceText <> nil then with SequenceText^ do
  begin
    if (P = nil) or (P^.HotKey <> hkSeq) then S := ''
    else S := 'Sequence:' + GetSequenceStr(
      P^.HotKeySequence, P^.HotKeyCount - 1, Size.X - 9, False);
    DisposeStr(Text);
    Text := NewStr(S);
    DrawView;
  end;
end;

procedure TProgList.GetData(var Rec);
begin
end;

function TProgList.GetText(Item: Integer; MaxLen: Integer): String;
var
  S: String;
begin
  if Item > Range - 2 then S := ''
  else GetTitleStr(List^.At(Item), S, True);
  GetText := S;
end;

procedure TProgList.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  if Focused <> Range - 1 then
  begin
    Pending.What := evCommand;
    Pending.Command := cmOk;
    Event.What := evNothing;
  end else Event.What := evNothing;
  TListBox.HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbCtrlUp: if not MoveListItem(@Self, List, True) then Exit;
      kbCtrlDn: if not MoveListItem(@Self, List, False) then Exit;
      else Exit;
    end;
    SaveList(FileName^);
    Event.What := evNothing;
  end;
end;

procedure TProgList.SetData(var Rec);
var
  Progs: PCollection;
  Item: Pointer;
  S: TDosStream;
  SS: FNameStr;
begin
  if LockData then Exit;
  LockData := True;
  if StatusWord[1] = 'P' then
  begin
    if FileName = nil then SS := '' else SS := FileName^;
    LogEvent := lcDiskRead;
    DrawStatusLine('Loading ' + StatusWord + ' list file ' +
      TrimmedName(SS, 41) + '.');
  end;
  Progs := New(PCollection, Init(8, 8));
  S.Init(FileName^, stOpenRead);
  if S.Status = stOk then
  begin
    Item := @Item;
    while (Item <> nil) and not LowMemory do
    begin
      Item := PExecItem(S.Get);
      if S.Status <> stOk then
      begin
        CouldNotReadMsgBox(FileName^);
        Item := nil;
      end
      else if Item <> nil then Progs^.Insert(Item);
    end;
  end;
  S.Done;
  Progs^.Insert(nil);
  NewList(Progs);
  Select;
  FocusMask;
  UpdateCommands;
end;

procedure TProgList.FocusMask;
begin
  if (LastProgIndex < 0) or (LastProgIndex >= Range) then
    LastProgIndex := 0;
  FocusItem(LastProgIndex);
end;

procedure TProgList.SaveList(const FName: FNameStr);
var
  I: Integer;
  P: PExecItem;
  S: TDosStream;
  SS: FNameStr;
  F: File;
begin
  LogEvent := lcDiskWrite;
  if StatusWord[1] = 'P' then
  begin
    if FileName = nil then SS := '' else SS := FileName^;
    DrawStatusLine('Saving ' + StatusWord + ' list file ' +
      TrimmedName(SS, 42) + '.');
  end
  else DrawStatusLine('Updating ' + StatusWord + ' list file.');
  if List^.Count = 1 then
  begin
    Assign(F, FName);
    Erase(F);
    InOutRes := 0;
    Exit;
  end;
  S.Init(FName, stCreate);
  I := 0;
  while (I < List^.Count) and (S.Status = stOk) do
  begin
    P := List^.At(I);
    S.Put(P);
    Inc(I);
  end;
  S.Done;
  UpdateFiles(FName);
end;

procedure FilterDebugProc(V: PView; var Event: TEvent);
var
  X, Y: Integer;
  I1, I2, I3, I4, I5, I6: PInputLine;
  NameFilter, LineFilter, ColumnFilter: String;

function IsI(P: PView): Boolean; far;
begin
  IsI := (TypeOf(P^) = TypeOf(TInputLine)) and
    (P^.Origin.X = X) and (P^.Origin.Y = Y);
end;

function GetInputLineStr(P: PInputLine): String;
var
  S: String;
begin
  with P^ do
    if SelStart <> SelEnd then GetInputLineStr :=
      System.Copy(Data^, SelStart + 1, SelEnd - SelStart)
    else GetInputLineStr := Data^;
end;

begin
  X := 17; Y := 8;
  I1 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  Y := 10;
  I2 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  X := 51; Y := 8;
  I3 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  Y := 10;
  I4 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  X := 66;
  I5 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  X := 73;
  I6 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  if (I1 = nil) or (I2 = nil) or (I3 = nil) or
     (I4 = nil) or (I5 = nil) or (I6 = nil) then Exit;
  FilterDebugStrings(I3^.GetText, I1^.GetText, I2^.GetText,
    NameFilter, LineFilter, ColumnFilter);
  if NameFilter <> I4^.Data^ then I4^.SetData(NameFilter);
  if LineFilter <> I5^.Data^ then I5^.SetData(LineFilter);
  if ColumnFilter <> I6^.Data^ then I6^.SetData(ColumnFilter);
end;

function TProgList.GetNewItem(const Header: String): PExecItem;
type
  DialogData = record
    Title: TExecStr;
    Rec: TExecRec;
    HotKey: Word;
    SourceStr: String;
    ResultStr1: String;
    ResultStr2: String;
    ResultStr3: String;
  end;
var
  C: Word;
  R: TRect;
  D: PHotKeySeqDialog;
  Control: PView;
  P: PExecItem;
  IsNew: Boolean;
  AData: DialogData;
begin
  GetNewItem := nil;
  IsNew := Header[1] = 'N';
  R.Assign(0, 0, 80, 20);
  D := New(PHotKeySeqDialog, Init(R, Header));
  with D^ do
  begin
    HelpCtx := hcNewProg;
    Options := Options or ofCentered;
    SeqTitle := 'Program';
    PostProcessEvent := FilterDebugProc;

    R.Assign(17, 2, Size.X - 6, 3);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    R.Assign(2, 2, 17, 3);
    Insert(New(PLabel, Init(R, 'Program ~t~itle', Control)));
    StandardHistory(Control, TitleHistoryId);

    R.Assign(17, 4, Size.X - 6, 5);
    Control := New(PFInputLine, Init(R, 255));
    Insert(Control);
    R.Assign(2, 4, 17, 5);
    Insert(New(PLabel, Init(R, '~P~rogram path', Control)));
    StandardHistory(Control, PathHistoryId);

    R.Assign(17, 6, Size.X - 6, 7);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    R.Assign(2, 6, 17, 7);
    Insert(New(PLabel, Init(R, '~C~ommand line', Control)));
    StandardHistory(Control, ParamsHistoryId);

    R.Assign(17, 8, 40, 9);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    R.Assign(2, 8, 17, 9);
    Insert(New(PLabel, Init(R, 'File~n~ame mask', Control)));
    StandardHistory(Control, FiltersHistoryId);

    R.Assign(17, 10, 40, 11);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    R.Assign(2, 10, 17, 11);
    Insert(New(PLabel, Init(R, 'Line num ~m~ask', Control)));
    StandardHistory(Control, FiltersHistoryId);

    R.Assign(3, 13, 15, 16);
    Control := MainControl(R);
    Insert(Control);
    R.Assign(2, 12, 15, 13);
    Insert(New(PLabel, Init(R, 'Main', Control)));

    R.Assign(17, 13, 40, 16);
    Control := SetupControl(R);
    Insert(Control);
    R.Assign(16, 12, 40, 13);
    Insert(New(PLabel, Init(R, 'Setup', Control)));

    R.Assign(42, 13, 64, 16);
    Control := OptionsControl(R, True);
    Insert(Control);
    R.Assign(41, 12, 64, 13);
    Insert(New(PLabel, Init(R, 'Options', Control)));

    R.Assign(67, 13, 77, 14);
    KeyView := New(PKeyView, Init(R));
    Insert(KeyView);
    R.Assign(66, 12, 77, 13);
    Insert(New(PLabel, Init(R, 'Hot ke~y~', KeyView)));

    R.Assign(65, 15, 77, 17);
    Insert(New(PButton, Init(R, '~H~ot keys', cmKeySequence, bfNormal)));

    R.Assign(51, 8, 74, 9);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    R.Assign(43, 8, 51, 9);
    Insert(New(PLabel, Init(R, 'Source', Control)));
    StandardHistory(Control, FilterSourceHistoryId);

    R.Assign(51, 10, 65, 11);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    R.Assign(43, 10, 51, 11);
    Insert(New(PLabel, Init(R, 'Result', Control)));

    R.Assign(71, 10, 73, 11);
    Insert(New(PLabel, Init(R, ':', nil)));

    R.Assign(66, 10, 72, 11);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);

    R.Assign(73, 10, 77, 11);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);

    StandardButtonRow(D, True);
  end;

  FillChar(AData, SizeOf(DialogData), 0);
  P := List^.At(Focused);
  if P <> nil then
  begin
    GetTitleStr(P, AData.Title, False);
    P^.GetData(AData.Rec, AData.HotKey);
    if P^.HotKey = hkSeq then
    begin
      D^.HotKeyCount := P^.HotKeyCount;
      Move(P^.HotKeySequence^, D^.HotKeySequence,
        P^.HotKeyCount * SizeOf(Word));
      D^.HotKeyOpt := P^.HotKeyOpt;
    end;
  end;
  if Application^.ValidView(D) <> nil then
  begin
    D^.SetData(AData);
    C := Application^.ExecView(D);
    if C <> cmCancel then
    begin
      D^.GetData(AData);
      P := New(PExecItem, Init);
      if P <> nil then
      begin
        P^.SetData(AData.Title, AData.Rec, AData.HotKey);
        if D^.HotKeyCount <> 0 then
        begin
          P^.HotKey := hkSeq;
          P^.HotKeyCount := D^.HotKeyCount;
{          GetMem(P^.HotKeySequence, P^.HotKeyCount * SizeOf(Word));}
          GetMemUMB(P^.HotKeySequence, P^.HotKeyCount * SizeOf(Word));
          Move(D^.HotKeySequence, P^.HotKeySequence^,
            P^.HotKeyCount * SizeOf(Word));
          P^.HotKeyOpt := D^.HotKeyOpt;
        end;
        GetNewItem := P;
      end;
    end;
    Dispose(D, Done);
  end;
end;

procedure TProgList.CheckDuplicates(AKey: Word;
  ASequence: PHotKeySequence; ACount: Word);
var
  I: Integer;
  P: PExecItem;
  C: String[31];
  S: String;
begin
  for I := 0 to List^.Count - 1 do
    if I <> Focused then
    begin
      P := List^.At(I);
      if (P <> nil) and
        ((P^.HotKey <> hkSeq) and SameKey(AKey, P^.HotKey)) or
        ((P^.HotKey = hkSeq) and (AKey = hkSeq) and
         (ACount = P^.HotKeyCount) and
          SameSequence(ASequence^, P^.HotKeySequence^, ACount)) then
      begin
        if AKey = hkSeq then C := 'sequence' +
          GetSequenceStr(ASequence, ACount - 1, 14, False)
        else C := GetKeyName(AKey);
        GetTitleStr(P, S, False);
        if S[0] > #33 then S[0] := #33;
        DupHotKeyMsgBox(C, S);
      end;
  end;
end;

procedure TProgList.ModifyProg;
var
  Item: PExecItem;
begin
  if Focused = Range - 1 then
  begin
    NewProg;
    Exit;
  end;
  Item := GetNewItem('Modify program');
  if Item <> nil then with List^ do
  begin
    AtFree(Focused);
    AtInsert(Focused, Item);
    SaveList(FileName^);
    FocusItem(Focused);
    DrawView;
    if Item^.HotKey <> 0 then CheckDuplicates(
      Item^.HotKey, Item^.HotKeySequence, Item^.HotKeyCount);
  end;
  Select;
end;

procedure TProgList.NewProg;
var
  Item: PExecItem;
begin
  Item := GetNewItem('New program');
  if Item <> nil then with List^ do
  begin
    AtInsert(Focused, Item);
    SetRange(Count);
    SaveList(FileName^);
    UpdateCommands;
    FocusItem(Focused);
    DrawView;
    if Item^.HotKey <> 0 then CheckDuplicates(
      Item^.HotKey, Item^.HotKeySequence, Item^.HotKeyCount);
  end;
  Select;
end;

procedure TProgList.ProgIcon;
var
  B: Boolean;
  C: Word;
  S: TDosStream;
  Name: FNameStr;
begin
  Name := '';
  C := Application^.ExecuteDialog(
    New(PFileDialog, Init('*.PRG', 'Create a program icon', '~N~ame',
    fdOkButton + fdReplaceButton + fdHelpButton, HistoryID)), @Name, False);
  if C = cmCancel then Exit;
  Name := ForceExtension(Name, 'PRG');
  if (C <> cmFileReplace) and ThisFileExists(Name) and
    (MessageBox(^C'File |' + Name + '|'#13^C'already exists. Overwrite ?',
      nil, mfConfirmation + mfOkCancel) = cmCancel) then Exit;
  LogEvent := lcDiskWrite;
  DrawStatusLine('Creating the program icon file ' +
    TrimmedName(Name, 36) + '.');
  S.Init(Name, stCreate);
  S.Put(PExecItem(List^.At(Focused)));
  S.Put(nil);
  B := S.Status <> stOk;
  S.Done;
  UpdateFiles(Name);
  if B then CouldNotCreateMsgBox(Name)
  else Message(Application, evCommand, cmLoadIcon, @Name);
end;

procedure TProgList.EditIcon;
var
  B: Boolean;
  Item: PExecItem;
  S: TDosStream;
  Name: FNameStr;
begin
  Name := '';
  if Application^.ExecuteDialog(
    New(PFileDialog, Init('*.PRG', 'Edit a program icon', '~N~ame',
    fdOkButton + fdHelpButton, HistoryID)),
    @Name, False) = cmCancel then Exit;
  S.Init(Name, stOpenRead);
  if S.Status <> stOk then
  begin
    CouldNotOpenMsgBox(Name);
    S.Done;
    Exit;
  end;
  Item := PExecItem(S.Get);
  S.Done;
  if Item = nil then
  begin
    InvalidProgFileMsgBox(Name);
    Exit;
  end;
  List^.AtInsert(Focused, Item);
  Item := GetNewItem('Modify program');
  List^.AtFree(Focused);
  if Item = nil then Exit;
  S.Init(Name, stCreate);
  S.Put(Item);
  B := S.Status <> stOk;
  S.Done;
  Dispose(Item, Done);
  UpdateFiles(Name);
  if B then CouldNotCreateMsgBox(Name)
  else Message(Desktop, evBroadcast, cmUpload, @Name);
end;

procedure TProgList.DeleteProg;
begin
  with List^ do
    if (Focused < Count - 1) and (DeleteItemMsgBox = cmOk) then
  begin
    AtFree(Focused);
    SetRange(Count);
    SaveList(FileName^);
    UpdateCommands;
    FocusItem(Focused);
    DrawView;
  end;
  Select;
end;

procedure TProgList.NewItemPos;
var
  SaveFocused, LastFocused: Integer;
  SaveCtx: Word;
  P: Pointer;
  Event: TEvent;
begin
  with List^ do
  begin
    if Focused >= Count - 1 then Exit;
    P := At(Focused);
    SaveFocused := Focused;
    SaveCtx := Owner^.HelpCtx;
    Owner^.HelpCtx := hcNewItemPos;
    repeat
      LockFocus := True;
      GetEvent(Event);
      HandleEvent(Event);
      LockFocus := False;
      LastFocused := IndexOf(P);
      if (Focused < Count - 1) and
         (LastFocused <> -1) and (LastFocused <> Focused) then
      begin
        AtDelete(LastFocused);
        AtInsert(Focused, P);
        FocusItem(Focused);
        DrawView;
      end;
      if ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) or
         ((Event.What = evCommand) and (Event.Command = cmOk)) then
      begin
        SaveList(FileName^);
        Break;
      end
      else if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
      begin
        AtDelete(LastFocused);
        AtInsert(SaveFocused, P);
        FocusItem(SaveFocused);
        DrawView;
        Break;
      end;
    until False;
    Owner^.HelpCtx := SaveCtx;
  end;
  Select;
end;

function TProgList.ExecFile: Boolean;
var
  C: Word;
  R: TExecRec;
  S: FNameStr;
begin
  ExecFile := False;
  if StatusWord[1] = 'P' then
  begin
    S := '';
    C := Application^.ExecuteDialog(
      New(PFileDialog, Init('*.*',
      'Execute a file; load/store program list', '~N~ame',
      fdRunButton + fdLoadButton + fdStoreButton + fdHelpButton,
      HistoryID)), @S, False);
  end
  else
  begin
    if FileName = nil then S := '' else S := FileName^;
    C := Application^.ExecuteDialog(
      New(PFileDialog, Init('*.' + JustExtension(S),
      'Load/store ' + StLocase(StatusWord) + ' list', '~N~ame',
      fdLoadButton + fdStoreButton + fdHelpButton,
      HistoryID)), @S, False);
  end;
  if C = cmOk then
  begin
    FillChar(R, SizeOf(TExecRec), 0);
    R.Path := S;
    Owner^.SetData(R);
    ExecFile := True;
  end
  else if C = cmFileOpen then ReloadList(@S)
  else if C = cmFileReplace then SaveList(S);
end;

procedure TProgList.ReloadList(P: PString);
var
  S: FNameStr;
  TS: TTitleStr;
begin
  SetPrgName(P, S);
  GetProgDlgTitle(PProgDialog(Owner)^.ProgList^.StatusWord[1], S, TS);
  DisposeStr(PProgDialog(Owner)^.Title);
  PProgDialog(Owner)^.Title := NewStr(TS);
  PProgDialog(Owner)^.Frame^.DrawView;
{
  DisposeStr(FileName);
  FileName := NewStr(AName);
}
  DisposeStrUMB(FileName);
  FileName := NewStrUMB(S);
  LockData := False;
  Owner^.Lock;
  SetData(S);
  Owner^.Unlock;
end;

procedure TProgList.UpdateCommands;
begin
  EnableCommands(NewCommands);
  if List^.Count > 1 then EnableCommands(
    ModifyCommands + RunItemCommands + DeleteCommands + NewItemPosCommands)
  else DisableCommands(
    ModifyCommands + RunItemCommands + DeleteCommands + NewItemPosCommands);
end;

constructor TProgDialog.Init(const AName, AFocusName: FNameStr);
var
  R: TRect;
  Control, Subview: PView;
  S: TTitleStr;
begin
  GetProgDlgTitle('P', AName, S);
  R.Assign(0, 0, 78, ScreenHeight - 3);
  TDialog.Init(R, S);
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcProgList;

  R.Assign(17, 2, Size.X - 17, 3);
  ProgName := New(PProgInputLine, Init(R, 255));
  Insert(ProgName);
  R.Assign(2, 2, 17, 3);
  Insert(New(PLabel, Init(R, '~P~rogram path', ProgName)));
  StandardHistory(ProgName, PathHistoryId);

  R.Assign(17, 3, Size.X - 17, 4);
  Control := New(PInputLine, Init(R, 255));
  Insert(Control);
  R.Assign(2, 3, 17, 4);
  Insert(New(PLabel, Init(R, '~C~ommand line', Control)));
  StandardHistory(Control, ParamsHistoryId);

  R.Assign(17, 4, Size.X - 17, 5);
  Control := New(PInputLine, Init(R, 255));
  Insert(Control);
  R.Assign(2, 4, 17, 5);
  Insert(New(PLabel, Init(R, 'Filename mask', Control)));
  StandardHistory(Control, FiltersHistoryId);

  R.Assign(17, 5, Size.X - 17, 6);
  Control := New(PInputLine, Init(R, 255));
  Insert(Control);
  R.Assign(2, 5, 17, 6);
  Insert(New(PLabel, Init(R, 'Line num mask', Control)));
  StandardHistory(Control, FiltersHistoryId);

  R.Assign(3, Size.Y - 5, 15, Size.Y - 2);
  Control := MainControl(R);
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Control);
  R.Assign(2, Size.Y - 6, 15, Size.Y - 5);
  Subview := New(PLabel, Init(R, 'Main', Control));
  Subview^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Subview);

  R.Assign(17, Size.Y - 5, 40, Size.Y - 2);
  Control := SetupControl(R);
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Control);
  R.Assign(16, Size.Y - 6, 40, Size.Y - 5);
  Subview := New(PLabel, Init(R, 'Setup', Control));
  Subview^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Subview);

  R.Assign(42, Size.Y - 5, 64, Size.Y - 2);
  Control := OptionsControl(R, False);
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Control);
  R.Assign(41, Size.Y - 6, 64, Size.Y - 5);
  Subview := New(PLabel, Init(R, 'Options', Control));
  Subview^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Subview);

  R.Assign(Size.X - 15, 7, Size.X - 14, Size.Y - 6);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3, 7, Size.X - 15, Size.Y - 6);
  ProgList := New(PProgList, Init(R, PScrollBar(Control),
    AName, AFocusName));
  ProgList^.GrowMode := gfGrowHiY;
  Insert(ProgList);
  R.Assign(2, 6, Size.X - 14, 7);
  Insert(New(PLabel, Init(R,
    ' Progr~a~ms                                           hot key',
    ProgList)));

  R.Assign(17, 6, 53, 7);
  ProgList^.SequenceText := New(PStaticText, Init(R, ''));
  ProgList^.SequenceText^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(ProgList^.SequenceText);

  R.Assign(Size.X - 13, 2, Size.X - 3, 4);
  Insert(New(PButton, Init(R, '~R~un', cmOk, bfDefault)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~F~ile', cmFileOpen, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~M~odify', cmModifyItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~N~ew', cmNewItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~I~con', cmRunItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'Edi~t~', cmUpload, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'Ad~j~ust', cmNewItemPos, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardCancelButton(R, @Self);
end;

procedure TProgDialog.HandleEvent(var Event: TEvent);

function HotKeyFound: Boolean;
var
  I: Integer;
  P: PExecItem;
begin
  with ProgList^ do for I := 0 to List^.Count - 2 do
  begin
    P := List^.At(I);
    if (P <> nil) and (P^.HotKey <> hkSeq) and
      SameKey(Event.KeyCode, P^.HotKey) then
    begin
      if I <> Focused then FocusItem(I);
      Event.What := evNothing;
      HotKeyFound := True;
      Exit;
    end;
  end;
  HotKeyFound := False;
end;

begin
  if (Event.What = evKeyDown) and
     (ProgList^.State and sfSelected <> 0) then
    case Event.KeyCode of
      kbCtrlEnter:
        begin
          Event.What := evCommand;
          Event.Command := cmModifyItem;
        end;
      kbIns:
        begin
          Event.What := evCommand;
          Event.Command := cmNewItem;
        end;
      kbDel:
        begin
          Event.What := evCommand;
          Event.Command := cmDeleteItem;
        end;
      kbUp, kbDown, kbPgUp, kbPgDn, kbCtrlPgUp, kbCtrlPgDn,
      kbCtrlHome, kbCtrlEnd, kbAltRight, kbAltLeft, kbAltUp, kbAltDn,
      kbTab, kbShiftTab, kbCtrlIns, kbEnter, kbSpace: ;
      else if (TypeOf(ProgList^) = TypeOf(TProgList)) and HotKeyFound then
        EndModal(cmOk);
    end;
  TDialog.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmModifyItem: ProgList^.ModifyProg;
      cmNewItem: ProgList^.NewProg;
      cmRunItem: ProgList^.ProgIcon;
      cmUpload: ProgList^.EditIcon;
      cmDeleteItem: ProgList^.DeleteProg;
      cmNewItemPos: ProgList^.NewItemPos;
      cmUserPrograms: ProgList^.ReloadList(PString(Event.InfoPtr));
      cmFileOpen: if ProgList^.ExecFile then ProgName^.Select
        else ProgList^.Select;
      cmMenu: Message(@Self, evKeyDown, kbF10, nil);
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

procedure GetProgDlgTitle(StatusChar: Char;
  const AName: FNameStr; var S: TTitleStr);
begin
  if StatusChar = 'V' then S := 'Viewer list'
  else if StatusChar = 'P' then S := 'Program list'
  else S := 'File associations';
  if AName <> '' then S := S + ': ' + TrimmedName(AName, 62 - Length(S));
end;

end.