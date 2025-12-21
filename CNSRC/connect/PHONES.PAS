{$I-,X+,O+,F+}
unit Phones;

interface

uses Objects, Views, Drivers, Dialogs;

type
  PPhoneEntry = ^TPhoneEntry;
  TPhoneEntry = object(TSortedCollection)
    Name: PString;
    Phone: PString;
    Notes: PString;
    Owner: PPhoneEntry;
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure Insert(Item: Pointer); virtual;
    procedure Store(var S: TStream); virtual;
  end;

  PPhoneList = ^TPhoneList;
  TPhoneList = object(TListViewer)
    DrawFlag: Boolean;
    function DataSize: Word; virtual;
    procedure Draw; virtual;
    procedure FocusItem(Item: Integer); virtual;
    procedure GetData(var Rec); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    function IsSelected(Item: Integer): Boolean; virtual;
    procedure SetData(var Rec); virtual;
    procedure Dial;
    function GetNewEntry(ANew: Boolean): PPhoneEntry;
    procedure OpenEntry(P: PPhoneEntry);
    procedure NewEntry(ANew: Boolean);
    procedure DeleteEntry;
    procedure FocusEntry(P: PPhoneEntry);
    procedure NewItemPos;
    procedure SetRealRange;
    procedure Search(Again: Boolean);
    procedure ImportPhones;
    procedure ExportPhones;
    procedure SelectHistory;
  end;

  PPhoneInfoPane = ^TPhoneInfoPane;
  TPhoneInfoPane = object(TView)
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PPhoneDialog = ^TPhoneDialog;
  TPhoneDialog = object(TDialog)
    PhoneList: PPhoneList;
    constructor Init;
    procedure EndModal(Command: Word); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

const
  PhoneName = 'CONNECT.PHN';
  PhoneDelta = 4;

procedure InitPhones;
procedure DonePhones;
procedure SavePhones;
procedure PhoneBook;

implementation

uses Dos, App, MsgBox, StdDlg, HistList, History, FindDlg, RegExp,
  Terminal, EditFile, EditMsg, HeapUMB, LFN, DosTools, TPString, Consts,
  Commands, Defaults;

const
  PhoneEntry: PPhoneEntry = nil;
  CurPhoneEntry: PPhoneEntry = nil;
  CurPhoneItem: PPhoneEntry = nil;

  NameLen = 255;
  PhoneLen = 255;
  NotesLen = 63;

  MaxEntryLevel = 32;

function Dialing: Boolean;
begin
  Dialing := (TheTerminal <> nil) and
    (PView(TheTerminal)^.State and sfDialing <> 0);
end;

procedure GetCurItem(Index: Integer);
var
  Sub: Boolean;
begin
  Sub := CurPhoneEntry <> PhoneEntry;
  if (CurPhoneEntry = nil) or (Sub and (Index = 0)) then
    CurPhoneItem := nil
  else CurPhoneItem := CurPhoneEntry^.At(Index - Byte(Sub));
end;

function GetEntryLevel(Item: PPhoneEntry): Byte;
var
  B: Byte;
begin
  B := 0;
  repeat
    if Item = nil then Break;
    Item := Item^.Owner;
    Inc(B);
  until False;
  GetEntryLevel := B;
end;

constructor TPhoneEntry.Load(var S: TStream);
begin
  Inherited Load(S);
{
  Name := S.ReadStr;
  Phone := S.ReadStr;
  Notes := S.ReadStr;
}
  Name := ReadStrUMB(@S);
  Phone := ReadStrUMB(@S);
  Notes := ReadStrUMB(@S);
end;

destructor TPhoneEntry.Done;
begin
{
  DisposeStr(Notes);
  DisposeStr(Phone);
  DisposeStr(Name);
}
  DisposeStrUMB(Notes);
  DisposeStrUMB(Phone);
  DisposeStrUMB(Name);
  Inherited Done;
end;

function TPhoneEntry.Compare(Key1, Key2: Pointer): Integer;
var
  S1, S2: String;
begin
  if PPhoneEntry(Key1)^.Name = nil then S1 := ''
  else S1 := PPhoneEntry(Key1)^.Name^;
  if PPhoneEntry(Key2)^.Name = nil then S2 := ''
  else S2 := PPhoneEntry(Key2)^.Name^;
  if CompUCString(S1, S2) = Less then Compare := -1
  else Compare := 1;
end;

function TPhoneEntry.GetItem(var S: TStream): Pointer;
var
  Item: PPhoneEntry;
begin
  Item := Inherited GetItem(S);
  if Item <> nil then Item^.Owner := @Self;
  GetItem := Item;
end;

procedure TPhoneEntry.Insert(Item: Pointer);
begin
  if Item <> nil then PPhoneEntry(Item)^.Owner := @Self;
  Inherited Insert(Item);
end;

procedure TPhoneEntry.Store(var S: TStream);
begin
  Inherited Store(S);
  S.WriteStr(Name);
  S.WriteStr(Phone);
  S.WriteStr(Notes);
end;

function TPhoneList.DataSize: Word;
begin
  DataSize := SizeOf(String);
end;

procedure TPhoneList.Draw;
begin
  if not DrawFlag then Inherited Draw;
end;

procedure TPhoneList.FocusItem(Item: Integer);
begin
  Inherited FocusItem(Item);
  GetCurItem(Item);
  Message(Owner, evBroadcast, cmNewItem, nil);
  EnableCommands(NewCommands + ImportCommands);
  if PhoneEntry^.Count = 0 then
    DisableCommands(SeekCommands + SeekAgainCommands)
  else EnableCommands(SeekCommands + SeekAgainCommands);
  if CurPhoneEntry^.Count = 0 then DisableCommands(ExportCommands)
  else EnableCommands(ExportCommands);
  if Dialing then EnableCommands(AbortCommands)
  else DisableCommands(AbortCommands);
  if CurPhoneItem = nil then
  begin
    DisableCommands(RunItemCommands + ModifyCommands + DeleteCommands);
    if Owner^.HelpCtx <> hcNewPhonePos then
      DisableCommands(NewItemPosCommands)
    else EnableCommands(NewItemPosCommands)
  end
  else
  begin
    if CurPhoneItem^.Phone = nil then DisableCommands(RunItemCommands)
    else EnableCommands(RunItemCommands);
    EnableCommands(ModifyCommands + NewItemPosCommands);
    if Owner^.HelpCtx = hcNewPhonePos then DisableCommands(DeleteCommands)
    else EnableCommands(DeleteCommands)
  end;
end;

procedure TPhoneList.GetData(var Rec);
var
  P: PPhoneEntry;
  CurEntryName: String;
begin
  CurEntryName := '';
  GetCurItem(Focused);
  P := CurPhoneItem;
  if P = nil then
  begin
    P := CurPhoneEntry;
    CurEntryName := #$FF;
  end;
  while P <> nil do
  begin
    if P^.Name <> nil then
      CurEntryName := Concat(P^.Name^, '\', CurEntryName);
    P := P^.Owner;
  end;
  if CurEntryName[Length(CurEntryName)] = '\' then Dec(CurEntryName[0]);
  HistoryAdd(PhoneEntryHistoryId, CurEntryName, True);
end;

function TPhoneList.GetText(Item: Integer; MaxLen: Integer): String;
var
  I, L: Integer;
  S, C: String;
begin
  GetCurItem(Item);
  if (CurPhoneEntry <> PhoneEntry) and (Item = 0) then S := ':'
  else if CurPhoneItem = nil then S := ''
  else
  begin
    FillChar(S, SizeOf(String), ' ');
    if CurPhoneItem^.Name <> nil then S := CurPhoneItem^.Name^
    else S := '';
    if CurPhoneItem^.Phone <> nil then C := CurPhoneItem^.Phone^
    else C := '';
    L := Size.X - 2;
    if Byte(C[0]) > L div 2 - 8 then Byte(C[0]) := L div 2 - 8;
    I := L - Length(C) + 1;
    FillChar(S[I - 2], 2, ' ');
    Move(C[1], S[I], Length(C));
    S[0] := Char(L);
  end;
  GetText := S;
end;

function TPhoneList.IsSelected(Item: Integer): Boolean;
begin
  if Owner^.HelpCtx = hcNewPhonePos then IsSelected := True
  else IsSelected := Inherited IsSelected(Item);
end;

procedure TPhoneList.SetData(var Rec);
var
  Found: Boolean;
  I: Integer;
  P, Item: PPhoneEntry;
  CurEntryName, S: String;
begin
  Move(Rec, CurEntryName, DataSize);
  Found := False;
  Item := CurPhoneEntry;
  if Item <> nil then
  repeat
    I := Pos('\', CurEntryName);
    if I = 0 then
    begin
      S := CurEntryName;
      CurEntryName := '';
    end
    else
    begin
      S := Copy(CurEntryName, 1, I - 1);
      Delete(CurEntryName, 1, I);
    end;
    Found := False;
    if S <> '' then
    begin
      P := Item;
      for I := 0 to P^.Count - 1 do
      begin
	Item := P^.At(I);
	if (Item^.Name <> nil) and (Item^.Name^ = S) then
	begin
	  Found := True;
	  Break;
	end;
	Item := P;
      end;
    end;
  until not Found or (CurEntryName = '');
  if Found then
  begin
    OpenEntry(Item^.Owner);
    FocusEntry(Item);
  end
  else OpenEntry(Item);
end;

procedure TPhoneList.Dial;
var
  B: Boolean;
  C: Word;
  S: String[PhoneLen];
begin
  C := GetShiftState;
  B := C and kbCtrlShift <> 0;
  if C and (kbLeftShift + kbRightShift) <> 0 then C := cmDialQueue
  else C := cmDial;
  GetCurItem(Focused);
  if (CurPhoneItem = nil) or (CurPhoneItem^.Phone = nil) then Exit;
  S := CurPhoneItem^.Phone^;
  if CurPhoneItem^.Name <> nil then S := S + '; ' + CurPhoneItem^.Name^;
  Message(Application, evCommand, cmTerminal, nil);
  Message(Desktop, evBroadcast, C, @S);
  if B then EndModal(cmCancel)
  else
  begin
    FocusItem(Focused);
    Select;
  end;
end;

procedure TPhoneList.OpenEntry(P: PPhoneEntry);
var
  S: String;
begin
  if P = nil then Exit;
  if GetEntryLevel(P) > MaxEntryLevel then
  begin
    MessageBox(^C'Entry level is limited to 32.',
      nil, mfError + mfOkButton);
    Exit;
  end;
  CurPhoneEntry := P;
  S := '';
  while P <> nil do
  begin
    if P^.Name <> nil then S := Concat(P^.Name^, '\', S);
    P := P^.Owner;
  end;
  if S[Length(S)] = '\' then Dec(S[0]);
  HistoryAdd(PhoneEntryHistoryId, S, True);
  SetRealRange;
  Select;
  FocusItem(0);
  DrawView;
end;

function TPhoneList.GetNewEntry(ANew: Boolean): PPhoneEntry;
type
  DialogData = record
    Name: String[NameLen];
    Phone: String[PhoneLen];
    Notes: String[NotesLen];
  end;
var
  D: PDialog;
  Control: PView;
  R: TRect;
  P: PPhoneEntry;
  AData: DialogData;
begin
  GetNewEntry := nil;
  R.Assign(0, 0, ScreenWidth, 11);
  if ANew then D := New(PDialog, Init(R, 'New phone entry'))
  else D := New(PDialog, Init(R, 'Modify phone entry'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcNewPhone;
    R.Assign(9, 2, Size.X - 6, 3);
    Control := New(PInputLine, Init(R, NameLen));
    Insert(Control);
    R.Assign(2, 2, 9, 3);
    Insert(New(PLabel, Init(R, '~N~ame', Control)));
    StandardHistory(Control, PhoneNameHistoryId);

    R.Assign(9, 4, Size.X - 6, 5);
    Control := New(PInputLine, Init(R, PhoneLen));
    Insert(Control);
    R.Assign(2, 4, 9, 5);
    Insert(New(PLabel, Init(R, 'P~h~one', Control)));
    StandardHistory(Control, PhoneHistoryId);

    R.Assign(9, 6, Size.X - 6, 7);
    Control := New(PInputLine, Init(R, NotesLen));
    Insert(Control);
    R.Assign(2, 6, 9, 7);
    Insert(New(PLabel, Init(R, 'N~o~tes', Control)));
    StandardHistory(Control, PhoneNotesHistoryId);

    StandardButtonRow(D, True);
  end;

  GetCurItem(Focused);
  if CurPhoneItem <> nil then
  begin
    if CurPhoneItem^.Name = nil then AData.Name := ''
    else AData.Name := CurPhoneItem^.Name^;
    if CurPhoneItem^.Phone = nil then AData.Phone := ''
    else AData.Phone := CurPhoneItem^.Phone^;
    if CurPhoneItem^.Notes = nil then AData.Notes := ''
    else AData.Notes := CurPhoneItem^.Notes^;
  end
  else FillChar(AData, SizeOf(DialogData), 0);

  if Application^.ExecuteDialog(D, @AData, True) <> cmCancel then
  begin
    if not ANew and (CurPhoneItem <> nil) then
    begin
      P := CurPhoneItem;
{
      DisposeStr(P^.Notes);
      DisposeStr(P^.Phone);
      DisposeStr(P^.Name);
}
      DisposeStrUMB(P^.Notes);
      DisposeStrUMB(P^.Phone);
      DisposeStrUMB(P^.Name);
    end
    else P := New(PPhoneEntry, Init(PhoneDelta, PhoneDelta));
{
    P^.Name := NewStr(Trim(AData.Name));
    P^.Phone := NewStr(Trim(AData.Phone));
    P^.Notes := NewStr(Trim(AData.Notes));
}
    P^.Name := NewStrUMB(Trim(AData.Name));
    P^.Phone := NewStrUMB(Trim(AData.Phone));
    P^.Notes := NewStrUMB(Trim(AData.Notes));
    GetNewEntry := P;
  end;
end;

procedure TPhoneList.NewEntry(ANew: Boolean);
var
  P: PPhoneEntry;
begin
  P := GetNewEntry(ANew);
  if P <> nil then
  begin
    if not ANew then CurPhoneEntry^.AtDelete(
      Focused - Byte(CurPhoneEntry <> PhoneEntry));
    CurPhoneEntry^.Insert(P);
    SavePhones;
    SetRealRange;
    FocusEntry(P);
    DrawView;
  end;
  Select;
end;

procedure TPhoneList.DeleteEntry;
begin
  GetCurItem(Focused);
  if CurPhoneItem = nil then Exit;
  if (DeleteItemMsgBox = cmOk) and
     ((CurPhoneItem^.Count = 0) or (MessageBox(
       ^C'Current phone entry is not empty. Delete still ?',
       nil, mfConfirmation + mfOkCancel) = cmOk)) then
  begin
    CurPhoneEntry^.AtFree(
      Focused - Byte(CurPhoneEntry <> PhoneEntry));
    SavePhones;
    SetRealRange;
    FocusItem(Focused);
    DrawView;
  end;
  Select;
end;

procedure TPhoneList.FocusEntry(P: PPhoneEntry);
var
  I: Integer;
begin
  I := 0;
  repeat
    if CurPhoneEntry^.At(I) = P then Break;
    Inc(I);
  until I >= CurPhoneEntry^.Count;
  if I >= CurPhoneEntry^.Count then I := 0
  else if CurPhoneEntry <> PhoneEntry then Inc(I);
  DrawFlag := False;
  FocusItem(I);
  DrawView;
end;

procedure TPhoneList.NewItemPos;
var
  SaveCtx: Word;
  P: PPhoneEntry;
  Event: TEvent;
begin
  GetCurItem(Focused);
  if CurPhoneItem = nil then Exit;
  SaveCtx := Owner^.HelpCtx;
  Owner^.HelpCtx := hcNewPhonePos;
  P := CurPhoneItem;
  CurPhoneEntry^.AtDelete(Focused - Byte(CurPhoneEntry <> PhoneEntry));
  SetRealRange;
  FocusItem(Focused);
  DrawView;
  repeat
    Owner^.GetEvent(Event);
    if (Event.What = evCommand) and
       (Event.Command = cmNewItemPos) then Break;
    if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
    begin
      DrawFlag := True;
      OpenEntry(P^.Owner);
      Break;
    end;
    Owner^.HandleEvent(Event);
    if Owner^.EndState <> 0 then
    begin
      P^.Owner^.Insert(P);
      Exit;
    end;
  until False;
  Owner^.HelpCtx := SaveCtx;
  CurPhoneEntry^.Insert(P);
  if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
  else SavePhones;
  SetRealRange;
  Select;
  FocusEntry(P);
end;

procedure TPhoneList.SetRealRange;
var
  I: Integer;
begin
  I := CurPhoneEntry^.Count;
  if CurPhoneEntry <> PhoneEntry then Inc(I);
  SetRange(I);
end;

procedure TPhoneList.Search(Again: Boolean);
type
  FindData = record
    S: String[255];
    Opt: Word;
  end;
const
  FindOpt: Word = 0;
var
  Found, Abort, Passed: Boolean;
  RegExpr: Pointer;
  Data: FindData;
  Item, CurItem: PPhoneEntry;
  S, SS: String;

function PhoneFindDialog: PDialog;
var
  D: PDialog;
  H: PHistory;

function IsHistory(P: PView): Boolean; far;
begin
  IsHistory := TypeOf(P^) = TypeOf(THistory);
end;

begin
  D := LoadFindDialog(False, True, frSelectedText + frBackward);
  if D <> nil then
  begin
    H := PHistory(D^.FirstThat(@IsHistory));
    if H <> nil then H^.HistoryId := FindPhoneHistoryID;
  end;
  PhoneFindDialog := D;
end;

procedure FindPos;

procedure DoFind;
begin
  if Data.Opt and frCaseSensitive = 0 then UpcaseSt(S);
  if (Data.Opt and frRegExp <> 0) and (RegExpr <> nil) then
  begin
    SS := RegSearch(RegExpr, S);
    if SS <> '' then Data.S := SS;
  end;
  if Data.Opt and frWholeWordsOnly <> 0 then
    Found := WordPos(Data.S, S, WordDelims, False) <> 0
  else Found := Pos(Data.S, S) <> 0;
end;

begin
  if Item^.Name <> nil then
  begin
    S := Item^.Name^;
    DoFind;
    if Found then Exit;
  end;
  if Item^.Phone <> nil then
  begin
    S := Item^.Phone^;
    DoFind;
    if Found then Exit;
  end;
  if Item^.Notes <> nil then
  begin
    S := Item^.Notes^;
    DoFind;
  end;
end;

{$S+}
procedure ScanEntry(P: PPhoneEntry);
var
  I: Integer;
begin
  if EscPressed then
  begin
    Abort := True;
    Exit;
  end;
  for I := 0 to P^.Count - 1 do
  begin
    Item := P^.At(I);
    if Item = nil then Exit;
    if not Passed then Passed := Item = CurItem
    else FindPos;
    if Found then Exit;
    if Item^.Count <> 0 then
    begin
      ScanEntry(Item);
      if Found or Abort then Exit;
    end;
  end;
end;
{$S-}

begin
  Data.S := HistoryStr(FindPhoneHistoryID, 0);
  Data.Opt := FindOpt;
  if Again then Data.Opt := Data.Opt or frFromCursor
  else
  begin
    if Application^.ExecuteDialog(PhoneFindDialog,
      @Data, True) = cmCancel then Exit;
    FindOpt := Data.Opt;
  end;
  if Data.S = '' then Exit;
  DrawStatusLine(SearchMsg);
  if Data.Opt and frCaseSensitive = 0 then UpcaseSt(Data.S);
  if Data.Opt and frRegExp <> 0 then RegExpr := RegCompile(Data.S)
  else RegExpr := nil;
  Found := False;
  Abort := False;
  Passed := True;
  if Data.Opt and frFromCursor <> 0 then
  begin
    Passed := False;
    GetCurItem(Focused);
    if CurPhoneItem = nil then CurItem := CurPhoneEntry
    else CurItem := CurPhoneItem;
  end;
  ScanEntry(PhoneEntry);
  if Data.Opt and frRegExp <> 0 then RegFree(RegExpr);
  if Abort then Exit;
  if Found then
  begin
    if CurPhoneEntry <> Item^.Owner then
    begin
      DrawFlag := True;
      OpenEntry(Item^.Owner);
    end;
    FocusEntry(Item);
  end
  else SearchStringNotFoundMsgBox;
end;

procedure TPhoneList.ImportPhones;
var
  EndOfFile: Boolean;
  Item: PPhoneEntry;
  F: lText;
  S, NameStr, PhoneStr, NotesStr: String;

procedure AddItem;
var
  Found: Boolean;
  Level: Byte;
  I: Integer;
  PP: PPhoneEntry;
begin
  PP := CurPhoneEntry;
  Level := GetEntryLevel(PP);
  repeat
    Inc(Level);
    if Level > MaxEntryLevel then
    begin
      MessageBox(^C'Too many entries in line, skipping:'#13^C + NameStr,
	nil, mfError + mfOkButton);
      Break;
    end;
    I := Pos('\', NameStr);
    if I = 0 then
    begin
      S := NameStr;
      NameStr := '';
    end
    else
    begin
      S := Copy(NameStr, 1, I - 1);
      Delete(NameStr, 1, I);
    end;
    if S <> '' then
    begin
      Found := False;
      if NameStr <> '' then for I := 0 to PP^.Count - 1 do
      begin
	Item := PP^.At(I);
	if (Item^.Name <> nil) and
	   (CompUCString(Item^.Name^, S) = Equal) then
	begin
	  PP := Item;
	  Found := True;
	  Break;
	end;
      end;
      if not Found then
      begin
	Item := New(PPhoneEntry, Init(PhoneDelta, PhoneDelta));
{	Item^.Name := NewStr(S);}
	Item^.Name := NewStrUMB(S);
	PP^.Insert(Item);
	PP := Item;
      end;
    end;
  until NameStr = '';
  if PP <> CurPhoneEntry then
  begin
{
    DisposeStr(PP^.Phone);
    PP^.Phone := NewStr(PhoneStr);
    DisposeStr(PP^.Notes);
    PP^.Notes := NewStr(NotesStr);
}
    DisposeStrUMB(PP^.Phone);
    PP^.Phone := NewStrUMB(PhoneStr);
    DisposeStrUMB(PP^.Notes);
    PP^.Notes := NewStrUMB(NotesStr);
  end;
end;

procedure ReadEntries;
begin
  EndOfFile := False;
  repeat
    repeat
      Readln(F.T, S);
      TrimSt(S);
      if CompUCString(Copy(S, 1, 4), 'NAME') = Equal then Break;
      EndOfFile := Eof(F.T);
    until EndOfFile;
    if EndOfFile then Exit;
    NameStr := Copy(S, 6, 255);
    repeat
      Readln(F.T, S);
      TrimSt(S);
      if CompUCString(Copy(S, 1, 5), 'PHONE') = Equal then Break;
      EndOfFile := Eof(F.T);
    until EndOfFile;
    if EndOfFile then Break;
    PhoneStr := Copy(S, 7, 255);
    repeat
      Readln(F.T, S);
      TrimSt(S);
      if CompUCString(Copy(S, 1, 5), 'NOTES') = Equal then Break;
      EndOfFile := Eof(F.T);
    until EndOfFile;
    if EndOfFile then Break;
    NotesStr := Copy(S, 7, 255);
    AddItem;
  until False;
  if EndOfFile then MessageBox(^C'Unexpected end of source file.',
    nil, mfError + mfOkButton);
end;

begin
  S := '';
  if Application^.ExecuteDialog(New(PFileDialog, Init('*.TXT',
    'Read phones from text file', '~N~ame', fdOkButton + fdHelpButton,
    HistoryID)), @S, True) = cmCancel then Exit;
  LogEvent := lcDiskRead;
  DrawStatusLine('Importing phones from ' + TrimmedName(S, 45) + '.');
  lAssignText(F, S);
  Reset(F.T);
  if IOResult <> 0 then
  begin
    CouldNotOpenMsgBox(S);
    Exit;
  end;
  if IsDevice(TextRec(F.T).Handle) then
  begin
    Close(F.T);
    InOutRes := 0;
    FileIsDeviceMsgBox(S);
    Exit;
  end;
  ReadEntries;
  Close(F.T);
  InOutRes := 0;
  SavePhones;
  SetRealRange;
  Select;
  DrawView;
end;

procedure TPhoneList.ExportPhones;
var
  Item: PPhoneEntry;
  F: lText;
  Name: FNameStr;
  S: String;

function GetFullName(CurEntry: PPhoneEntry): String;
var
  PP: PPhoneEntry;
  SS: String;
begin
  SS := '';
  PP := CurEntry;
  repeat
    if PP^.Name <> nil then SS := Concat(PP^.Name^, '\', SS);
    PP := PP^.Owner;
  until PP = CurPhoneEntry;
  if SS[Length(SS)] = '\' then Dec(SS[0]);
  GetFullName := SS;
end;

{$S+}
procedure ScanEntry(P: PPhoneEntry);
var
  I: Integer;
begin
  for I := 0 to P^.Count - 1 do
  begin
    Item := P^.At(I);
    S := 'NAME';
    if Item^.Name <> nil then S := S + ' ' + GetFullName(Item);
    Writeln(F.T, S);
    S := 'PHONE';
    if Item^.Phone <> nil then S := S + ' ' + Item^.Phone^;
    Writeln(F.T, S);
    S := 'NOTES';
    if Item^.Notes <> nil then S := S + ' ' + Item^.Notes^;
    Writeln(F.T, S);
    Writeln(F.T);
    if Item^.Count <> 0 then ScanEntry(Item);
  end;
end;
{$S-}

begin
  Name := '';
  if Application^.ExecuteDialog(New(PFileDialog, Init('*.TXT',
    'Write phones to text file', '~N~ame', fdOkButton + fdHelpButton,
    HistoryID)), @Name, True) = cmCancel then Exit;
  LogEvent := lcDiskWrite;
  DrawStatusLine('Exporting phones to ' + TrimmedName(Name, 47) + '.');
  lAssignText(F, Name);
  Rewrite(F.T);
  if IOResult <> 0 then
  begin
    CouldNotCreateMsgBox(Name);
    Exit;
  end;
  if NotAccessible(TextRec(F.T).Handle) then
  begin
    Close(F.T);
    InOutRes := 0;
    FileIsDeviceMsgBox(Name);
    Exit;
  end;
  ScanEntry(CurPhoneEntry);
  Close(F.T);
  InOutRes := 0;
  UpdateFiles(Name);
end;

procedure TPhoneList.SelectHistory;
var
  X, Y: Integer;
  C: Word;
  W: PHistoryWindow;
  R: TRect;
  S: String;
begin
  X := HistoryWidth(PhoneEntryHistoryID) + 6;
  if X < 19 then X := 19;
  Y := HistoryCount(PhoneEntryHistoryID) + 3;
  GetBounds(R);
  while R.B.X - R.A.X > X do Dec(R.B.X);
  while R.B.Y - R.A.Y > Y do Dec(R.B.Y);
  W := New(PHistoryWindow, Init(R, PhoneEntryHistoryID));
  if Application^.ValidView(W) <> nil then
  begin
    W^.HelpCtx := hcPromptHistory;
    C := Owner^.ExecView(W);
    if C = cmOk then S := W^.GetSelection;
    Dispose(W, Done);
    if C = cmOk then
    begin
      CurPhoneEntry := PhoneEntry;
      DrawFlag := True;
      SetData(S);
      DrawFlag := False;
      DrawView;
    end;
  end;
end;

procedure TPhoneInfoPane.Draw;
var
  Color: Word;
  S: String[NotesLen];
  B: TDrawBuffer;

procedure FullName;
var
  I: Integer;
  P: PPhoneEntry;
  SS: String;
begin
  SS := '';
  P := CurPhoneEntry;
  repeat
    if P^.Name <> nil then
    begin
      if Length(P^.Name^) + 1 + Length(SS) > 255 then
      begin
	while (SS <> '') and (Length(P^.Name^) + 1 + Length(SS) > 255) do
	  Delete(SS, 1, 1);
	while (SS <> '') and (SS[1] <> '\') do Delete(SS, 1, 1);
	if SS <> '' then Delete(SS, 1, 1);
      end;
      SS := Concat(P^.Name^, '\', SS);
    end;
    P := P^.Owner;
  until P = nil;
  if SS[Length(SS)] = '\' then Dec(SS[0]);
  if Length(SS) > NotesLen then
  begin
    I := Pos('\', SS);
    if I <> 0 then
    begin
      Inc(I);
      while Length(SS) > NotesLen - 3 do Delete(SS, I, 1);
      while (I <= Length(SS)) and (SS[I] <> '\') do Delete(SS, I, 1);
      Insert('...', SS, I);
    end;
  end;
  S := SS;
end;

begin
  Color := GetColor(1);

  MoveChar(B, ' ', Color, Size.X);
  FullName;
  MoveStr(B[1], 'Path:  ' + S, Color);
  WriteLine(0, 0, Size.X, 1, B);

  MoveChar(B, ' ', Color, Size.X);
  if CurPhoneItem = nil then
  begin
    WriteLine(0, 1, Size.X, Size.Y - 1, B);
    Exit;
  end;

  MoveChar(B, ' ', Color, Size.X);
  if CurPhoneItem^.Name = nil then S := ''
  else S := CurPhoneItem^.Name^;
  MoveStr(B[1], 'Name:  ' + S, Color);
  WriteLine(0, 1, Size.X, 1, B);

  MoveChar(B, ' ', Color, Size.X);
  if CurPhoneItem^.Phone = nil then S := ''
  else S := CurPhoneItem^.Phone^;
  MoveStr(B[1], 'Phone: ' + S, Color);
  WriteLine(0, 2, Size.X, 1, B);

  MoveChar(B, ' ', Color, Size.X);
  if CurPhoneItem^.Notes = nil then S := ''
  else S := CurPhoneItem^.Notes^;
  MoveStr(B[1], 'Notes: ' + S, Color);
  WriteLine(0, 3, Size.X, 1, B);
end;

function TPhoneInfoPane.GetPalette: PPalette;
const
  P: String[1] = #30;
begin
  GetPalette := @P;
end;

procedure TPhoneInfoPane.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  if (Event.What = evBroadcast) and (Event.Command = cmNewItem) then
    DrawView;
end;

constructor TPhoneDialog.Init;
var
  R: TRect;
  VBar: PScrollBar;
  Control: PView;
begin
  R.Assign(0, 0, ScreenWidth - 4, ScreenHeight - 4);
  Inherited Init(R, 'Phone list');
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcPhoneBook;

  R.Assign(Size.X - 15, 2, Size.X - 14, Size.Y - 6);
  VBar := New(PScrollBar, Init(R));
  VBar^.Options := VBar^.Options or ofPostProcess;
  Insert(VBar);

  R.Assign(2, 2, Size.X - 15, Size.Y - 6);
  PhoneList := New(PPhoneList, Init(R, 1, nil, VBar));
  PhoneList^.GrowMode := gfGrowHiY;
  Insert(PhoneList);
  R.Assign(2, 1, Size.X - 14, 2);
  Insert(New(PLabel, Init(R, Pad('Name', 52) + 'P~h~one',
    PhoneList)));

  R.Assign(2, Size.Y - 5, Size.X - 2, Size.Y - 1);
  Control := New(PPhoneInfoPane, Init(R));
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Control^.EventMask := Control^.EventMask or evBroadcast;
  Insert(Control);

  R.Assign(Size.X - 13, 2, Size.X - 3, 4);
  Insert(New(PButton, Init(R, 'Di~a~l', cmRunItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~M~odify', cmModifyItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~N~ew', cmNewItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~F~ind', cmSeek, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'Ad~j~ust', cmNewItemPos, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardCancelButton(R, @Self);
end;

procedure TPhoneDialog.EndModal(Command: Word);
begin
  if Command = cmCancel then Command := cmOk;
  Inherited EndModal(Command);
end;

procedure TPhoneDialog.HandleEvent(var Event: TEvent);
var
  P: PPhoneEntry;
begin
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbEnter: if PhoneList^.State and sfSelected <> 0 then
        begin
          Event.What := evCommand;
          Event.Command := cmShow;
        end;
      kbCtrlPgDn:
        begin
          Event.What := evCommand;
	  Event.Command := cmShow;
        end;
      kbDel:
        begin
          Event.What := evCommand;
          Event.Command := cmDeleteItem;
        end;
      kbIns:
        begin
          Event.What := evCommand;
          Event.Command := cmNewItem;
        end;
      kbCtrlPgUp:
        begin
          Event.What := evCommand;
          Event.Command := cmHide;
	end;
{
      kbLeft, kbHome: Event.KeyCode := kbCtrlHome;
      kbRight, kbEnd: Event.KeyCode := kbCtrlEnd;
}
      else case Event.CharCode of
        ^W:
          begin
            Event.What := evCommand;
            Event.Command := cmChange;
          end;
        ^\:
          begin
            Event.What := evCommand;
            Event.Command := cmZero;
          end;
       ^L:
         begin
            Event.What := evCommand;
            Event.Command := cmSeekAgain;
          end;
      end;
    end;
  if (Event.What = evBroadcast) and (Event.Command = cmListItemSelected) then
  begin
    Event.What := evCommand;
    Event.Command := cmShow;
  end;
  Inherited HandleEvent(Event);
  if Event.What = evCommand then with PhoneList^ do
  begin
    if (Event.Command = cmShow) and
       (CurPhoneEntry <> PhoneEntry) and (Focused = 0) then
      Event.Command := cmHide;
    case Event.Command of
      cmShow:
        begin
          GetCurItem(Focused);
          OpenEntry(CurPhoneItem);
        end;
      cmHide:
        begin
          P := CurPhoneEntry;
          DrawFlag := True;
          OpenEntry(P^.Owner);
          FocusEntry(P);
        end;
      cmChange: SelectHistory;
      cmZero: OpenEntry(PhoneEntry);
      cmSeek: Search(False);
      cmSeekAgain: Search(True);
      cmRunItem: if HelpCtx <> hcNewPhonePos then Dial;
      cmModifyItem: NewEntry(False);
      cmNewItem: NewEntry(True);
      cmDeleteItem: if HelpCtx <> hcNewPhonePos then DeleteEntry;
      cmNewItemPos: if HelpCtx <> hcNewPhonePos then NewItemPos else Exit;
      cmImport: ImportPhones;
      cmExport: ExportPhones;
      cmAbort: if Dialing then
        begin
          PTerminal(TheTerminal)^.AbortDialing(True);
          FocusItem(Focused);
        end;
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

procedure InitPhones;
var
  S: TDosStream;
begin
  S.Init(ConfigPath + PhoneName, stOpenRead);
  PhoneEntry := PPhoneEntry(S.Get);
  if (S.Status <> stOk) or (PhoneEntry = nil) then
    New(PhoneEntry, Init(PhoneDelta, PhoneDelta));
  S.Done;
  CurPhoneEntry := PhoneEntry;
end;

procedure DonePhones;
begin
  if PhoneEntry <> nil then Dispose(PhoneEntry, Done);
  PhoneEntry := nil;
end;

procedure SavePhones;
var
  S: TDosStream;
begin
  LogEvent := lcDiskWrite;
  DrawStatusLine('Updating Phone Book file.');
  S.Init(ConfigPath + PhoneName, stCreate);
  S.Put(PhoneEntry);
  S.Done;
end;

procedure PhoneBook;
var
  S: String;
begin
  S := HistoryStr(PhoneEntryHistoryId, 0);
  HistoryDelete(PhoneEntryHistoryId, 0);
  InitPhones;
  Application^.ExecuteDialog(New(PPhoneDialog, Init), @S, True);
  DonePhones;
end;

end.
