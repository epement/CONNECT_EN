{$F+,O+,X+}
unit ArcDlg;

interface

uses Objects, Drivers, Views, Dialogs, ArcRec;

const
  aNameLen = 255;
  aExtLen = 3;
  aOptLen = 255;
  aCharLen = 1;
  aMaskLen = 12;
  aTMLen = 31;
  aEnvLen = 127;

type
  TDataRec = record
    PackerName: String[aNameLen];
    UnpackerName: String[aNameLen];
    Extract: String[aOptLen];
    ExWithDirs: String[aOptLen];
    Add: String[aOptLen];
    AddWithDirs: String[aOptLen];
    Move: String[aOptLen];
    MoveWithDirs: String[aOptLen];
    Del: String[aOptLen];
    Test: String[aOptLen];
    Password: String[aOptLen];
    ListChar: String[aCharLen];
    Extension: String[aExtLen];
    Main: Word;
  end;

  TUserDataRec = record
    TradeMark: String[aTMLen];
    ViewCommand: String[aNameLen];
    DirViewCommand: String[aNameLen];
    DataRec: TDataRec;
    Mask: String[aMaskLen];
    EnvCondition: String[aEnvLen];
  end;

  PArchiveList = ^TArchiveList;
  TArchiveList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PUserArchiveList = ^TUserArchiveList;
  TUserArchiveList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PUserArchiveViewer = ^TUserArchiveViewer;
  TUserArchiveViewer = object(TListBox)
    Name: FNameStr;
    destructor Done; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure FillList;
    procedure SaveList;
    function ModifyItem: Boolean;
    function NewItem: Boolean;
    function DeleteItem: Boolean;
    procedure FocusMask;
    procedure NewItemPos;
  end;

  PUserArchiveDialog = ^TUserArchiveDialog;
  TUserArchiveDialog = object(TDialog)
    UserArchiveViewer: PUserArchiveViewer;
    constructor Init(const Name: FNameStr);
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

function ArchiverDialog(const Name: FNameStr; Id: Byte): Word;
function GetNewUserArchiveItem(const Header: String;
  P: PUserArchiveRec): PUserArchiveRec;
function UserArchiverDialog(const Name: FNameStr): Word;

implementation

uses Dos, App, MsgBox, EditMsg, DirPrim, CNInputs, History, HeapUMB, LFN,
  TPString, Consts, Commands, Defaults;

procedure InsertArchiverInputs(D: PDialog; var R: TRect);
var
  Control: PView;
  RR: TRect;

procedure GrowRects;
begin
  Inc(R.A.Y); Inc(R.B.Y); Inc(RR.A.Y); Inc(RR.B.Y);
end;

begin
  RR.Assign(2, R.A.Y, 21, R.B.Y);
  with D^ do
  begin
    Control := New(PFInputLine, Init(R, aNameLen));
    Insert(Control);
    Insert(New(PLabel, Init(RR, '~P~acker name', Control)));
    GrowRects;

    Control := New(PFInputLine, Init(R, aNameLen));
    Insert(Control);
    Insert(New(PLabel, Init(RR, '~U~npacker name', Control)));
    GrowRects;

    Control := New(PInputLine, Init(R, aOptLen));
    Insert(Control);
    Insert(New(PLabel, Init(RR, '~E~xtract', Control)));
    GrowRects;

    Control := New(PInputLine, Init(R, aOptLen));
    Insert(Control);
    Insert(New(PLabel, Init(RR, 'E~x~tract with dirs', Control)));
    GrowRects;

    Control := New(PInputLine, Init(R, aOptLen));
    Insert(Control);
    Insert(New(PLabel, Init(RR, '~A~dd', Control)));
    GrowRects;

    Control := New(PInputLine, Init(R, aOptLen));
    Insert(Control);
    Insert(New(PLabel, Init(RR, 'Add w~i~th dirs', Control)));
    GrowRects;

    Control := New(PInputLine, Init(R, aOptLen));
    Insert(Control);
    Insert(New(PLabel, Init(RR, '~M~ove', Control)));
    GrowRects;

    Control := New(PInputLine, Init(R, aOptLen));
    Insert(Control);
    Insert(New(PLabel, Init(RR, 'Move wit~h~ dirs', Control)));
    GrowRects;

    Control := New(PInputLine, Init(R, aOptLen));
    Insert(Control);
    Insert(New(PLabel, Init(RR, '~D~elete', Control)));
    GrowRects;

    Control := New(PInputLine, Init(R, aOptLen));
    Insert(Control);
    Insert(New(PLabel, Init(RR, '~T~est', Control)));
    GrowRects;

    Control := New(PInputLine, Init(R, aOptLen));
    Insert(Control);
    Insert(New(PLabel, Init(RR, 'Pass~w~ord', Control)));
    GrowRects;

    R.Assign(Size.X - 8, 2, Size.X - 3, 3);
    Control := New(PInputLine, Init(R, aCharLen));
    Insert(Control);
    RR.Assign(Size.X - 31, 2, Size.X - 8, 3);
    Insert(New(PLabel, Init(RR, '~L~ist character', Control)));

    R.Assign(Size.X - 8, 3, Size.X - 3, 4);
    Control := New(PInputLine, Init(R, aExtLen));
    Insert(Control);
    RR.Assign(Size.X - 31, 3, Size.X - 8, 4);
    Insert(New(PLabel, Init(RR, 'De~f~ault extension', Control)));

    R.Assign(Size.X - 30, 6, Size.X - 3, 11);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Swap main ~b~ody',
      NewSItem('~S~witch to user screen',
      NewSItem('Load COMMAND~.~COM',
      NewSItem('Enable Win9~5~ LFN',
      NewSItem('Prompt on overwrite', nil)))))));
    Insert(Control);
    RR.Assign(Size.X - 31, 5, Size.X - 3, 6);
    Insert(New(PLabel, Init(RR, 'Exec options', Control)));
  end;
end;

procedure TArchiveList.FreeItem(Item: Pointer);
begin
  DisposeArchiveRec(PArchiveRec(Item));
end;

procedure TUserArchiveList.FreeItem(Item: Pointer);
begin
  DisposeUserArchiveRec(PUserArchiveRec(Item));
end;

procedure Rec2Data(P: PArchiveRec; var Data: TDataRec);
begin
  FillChar(Data, SizeOf(TDataRec), 0);
  if P = nil then Exit;
  if P^.PackerName <> nil then Data.PackerName := P^.PackerName^;
  if P^.UnpackerName <> nil then Data.UnpackerName := P^.UnpackerName^;
  if P^.Extension <> nil then Data.Extension := P^.Extension^;
  if P^.Extract <> nil then Data.Extract := P^.Extract^;
  if P^.ExWithDirs <> nil then Data.ExWithDirs := P^.ExWithDirs^;
  if P^.Add <> nil then Data.Add := P^.Add^;
  if P^.AddWithDirs <> nil then Data.AddWithDirs := P^.AddWithDirs^;
  if P^.Move <> nil then Data.Move := P^.Move^;
  if P^.MoveWithDirs <> nil then Data.MoveWithDirs := P^.MoveWithDirs^;
  if P^.Del <> nil then Data.Del := P^.Del^;
  if P^.Test <> nil then Data.Test := P^.Test^;
  if P^.Password <> nil then Data.Password := P^.Password^;
  if P^.ListChar <> #0 then Data.ListChar := P^.ListChar;
  Data.Main := P^.Main;
end;

procedure Data2Rec(P: PArchiveRec; Data: TDataRec);
begin
{
  P^.PackerName := NewStr(Data.PackerName);
  P^.UnpackerName := NewStr(Data.UnpackerName);
  P^.Extension := NewStr(Data.Extension);
  P^.Extract := NewStr(Data.Extract);
  P^.ExWithDirs := NewStr(Data.ExWithDirs);
  P^.Add := NewStr(Data.Add);
  P^.AddWithDirs := NewStr(Data.AddWithDirs);
  P^.Move := NewStr(Data.Move);
  P^.MoveWithDirs := NewStr(Data.MoveWithDirs);
  P^.Del := NewStr(Data.Del);
  P^.Test := NewStr(Data.Test);
  P^.Password := NewStr(Data.Password);
}
  P^.PackerName := NewStrUMB(Data.PackerName);
  P^.UnpackerName := NewStrUMB(Data.UnpackerName);
  P^.Extension := NewStrUMB(Data.Extension);
  P^.Extract := NewStrUMB(Data.Extract);
  P^.ExWithDirs := NewStrUMB(Data.ExWithDirs);
  P^.Add := NewStrUMB(Data.Add);
  P^.AddWithDirs := NewStrUMB(Data.AddWithDirs);
  P^.Move := NewStrUMB(Data.Move);
  P^.MoveWithDirs := NewStrUMB(Data.MoveWithDirs);
  P^.Del := NewStrUMB(Data.Del);
  P^.Test := NewStrUMB(Data.Test);
  P^.Password := NewStrUMB(Data.Password);
  if Data.ListChar = '' then P^.ListChar := #0
  else P^.ListChar := Data.ListChar[1];
  P^.Main := Data.Main;
end;

procedure UserRec2Data(P: PUserArchiveRec; var Data: TUserDataRec);
begin
  FillChar(Data, SizeOf(TUserDataRec), 0);
  if P = nil then Exit;
  if P^.Mask <> nil then Data.Mask := P^.Mask^;
  if P^.TradeMark <> nil then Data.TradeMark := P^.TradeMark^;
  if P^.ViewCommand <> nil then Data.ViewCommand := P^.ViewCommand^;
  if P^.DirViewCommand <> nil then Data.DirViewCommand := P^.DirViewCommand^;
  if P^.EnvCondition <> nil then Data.EnvCondition := P^.EnvCondition^;
  Rec2Data(P^.ArchiveRec, Data.DataRec);
end;

procedure UserData2Rec(P: PUserArchiveRec; Data: TUserDataRec);
begin
{
  P^.Mask := NewStr(Data.Mask);
  P^.TradeMark := NewStr(Data.TradeMark);
  P^.ViewCommand := NewStr(Data.ViewCommand);
  P^.DirViewCommand := NewStr(Data.DirViewCommand);
  P^.EnvCondition := NewStr(Data.EnvCondition);
}
  P^.Mask := NewStrUMB(Data.Mask);
  P^.TradeMark := NewStrUMB(Data.TradeMark);
  P^.ViewCommand := NewStrUMB(Data.ViewCommand);
  P^.DirViewCommand := NewStrUMB(Data.DirViewCommand);
  P^.EnvCondition := NewStrUMB(Data.EnvCondition);
  Data2Rec(P^.ArchiveRec, Data.DataRec);
end;

function ArchiverDialog(const Name: FNameStr; Id: Byte): Word;
var
  C: Word;
  I: Integer;
  P: PArchiveRec;
  List: PArchiveList;
  D: PDialog;
  Control: PView;
  R: TRect;
  Stream: TDosStream;
  Data: TDataRec;
  Header: String[4];

procedure FillArchiveList;
var
  I: Integer;
begin
  Stream.Init(Name, stOpenRead);
  for I := 0 to NumArchives - 1 do
  begin
    P := NewArchiveRec;
    ReadArchiveRec(@Stream, P);
    List^.Insert(P);
  end;
  Stream.Done;
end;

procedure SaveArchiveList;
var
  I: Integer;
begin
  LogEvent := lcDiskWrite;
  DrawStatusLine('Updating Archiver setup file.');
  Stream.Init(Name, stCreate);
  for I := 0 to NumArchives - 1 do
  begin
    P := List^.At(I);
    WriteArchiveRec(@Stream, P);
  end;
  Stream.Done;
  Message(Desktop, evBroadcast, cmNoArc, nil);
end;

begin
  List := New(PArchiveList, Init(NumArchives, 4));
  FillArchiveList;
  P := List^.At(Id);
  Rec2Data(P, Data);
  if Data.Extension = '' then Header := ''
  else Header := StUpcase(Trim(Data.Extension)) + ' ';
  R.Assign(0, 0, 80, 15);
  D := New(PDialog, Init(R, Header + 'Archiver setup'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcArchivers;

    R.Assign(21, 2, Size.X - 32, 3);
    InsertArchiverInputs(D, R);

    R.Assign(Size.X - 31, Size.Y - 3, Size.X - 25, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(Size.X - 24, Size.Y - 3, Size.X - 14, Size.Y - 1);
    StandardCancelButton(R, D);
    R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardHelpButton(R, D);

    SelectNext(False);
  end;
  C := Application^.ExecuteDialog(D, @Data, False);
  if C <> cmCancel then
  begin
    List^.AtFree(Id);
    P := NewArchiveRec;
    Data2Rec(P, Data);
    List^.AtInsert(Id, P);
    SaveArchiveList;
  end;
  Dispose(List, Done);
  ArchiverDialog := C;
end;

function GetNewUserArchiveItem(const Header: String;
  P: PUserArchiveRec): PUserArchiveRec;
var
  I: Integer;
  R: TRect;
  D: PDialog;
  Control: PView;
  Data: TUserDataRec;
begin
  GetNewUserArchiveItem := nil;
  R.Assign(0, 0, 80, 20);
  D := New(PDialog, Init(R, Header + ' user defined Archiver setup'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcUserArchivers;

    R.Assign(21, 2, Size.X - 32, 3);
    Control := New(PInputLine, Init(R, aTMLen));
    Insert(Control);
    R.Assign(2, 2, 21, 3);
    Insert(New(PLabel, Init(R, 'T~r~ademark', Control)));

    R.Assign(21, 3, Size.X - 32, 4);
    Control := New(PInputLine, Init(R, aNameLen));
    Insert(Control);
    R.Assign(2, 3, 21, 4);
    Insert(New(PLabel, Init(R, '~V~iew command', Control)));

    R.Assign(21, 4, Size.X - 32, 5);
    Control := New(PInputLine, Init(R, aNameLen));
    Insert(Control);
    R.Assign(2, 4, 21, 5);
    Insert(New(PLabel, Init(R, 'View dir ~c~ommand', Control)));

    R.Assign(21, 5, Size.X - 32, 6);
    InsertArchiverInputs(D, R);

    R.Assign(Size.X - 20, 12, Size.X - 3, 13);
    Control := New(PInputLine, Init(R, aMaskLen));
    Insert(Control);
    R.Assign(Size.X - 31, 12, Size.X - 20, 13);
    Insert(New(PLabel, Init(R, '~N~ame mask', Control)));

    R.Assign(Size.X - 30, 15, Size.X - 6, 16);
    Control := New(PInputLine, Init(R, aEnvLen));
    Insert(Control);
    StandardHistory(Control, EnvHistoryId);
    R.Assign(Size.X - 31, 14, Size.X - 3, 15);
    Insert(New(PLabel, Init(R, 'Environment c~o~ndition', Control)));

    StandardButtonRow(D, True);
  end;

  UserRec2Data(P, Data);
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    P := NewUserArchiveRec;
    UserData2Rec(P, Data);
    GetNewUserArchiveItem := P;
  end;
end;

destructor TUserArchiveViewer.Done;
begin
  Dispose(List, Done);
  Inherited Done;
end;

function TUserArchiveViewer.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: PUserArchiveRec;
  S: String;
begin
  P := List^.At(Item);
  if P = nil then GetText := ''
  else
  begin
    if P^.Mask = nil then S := '' else S := P^.Mask^;
    if P^.TradeMark <> nil then S := Pad(S, aMaskLen + 2) + P^.TradeMark^;
    GetText := S;
  end;
end;

procedure TUserArchiveViewer.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmModifyItem;
    Event.What := evNothing;
  end
  else Inherited HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbCtrlUp: if not MoveListItem(@Self, List, True) then Exit;
      kbCtrlDn: if not MoveListItem(@Self, List, False) then Exit;
      else Exit;
    end;
    SaveList;
    Event.What := evNothing;
  end;
end;

procedure TUserArchiveViewer.FillList;
var
  L: PUserArchiveList;
  P: PUserArchiveRec;
  Stream: TDosStream;
begin
  L := New(PUserArchiveList, Init(8, 8));
  Stream.Init(Name, stOpenRead);
  while Stream.Status = stOk do
  begin
    P := NewUserArchiveRec;
    ReadUserArchiveRec(@Stream, P);
    if Stream.Status <> stOk then DisposeUserArchiveRec(P)
    else L^.Insert(P);
  end;
  Stream.Done;
  L^.Insert(nil);
  NewList(L);
end;

procedure TUserArchiveViewer.SaveList;
var
  I: Integer;
  P: PUserArchiveRec;
  Stream: TDosStream;
begin
  LogEvent := lcDiskWrite;
  DrawStatusLine('Updating user defined Archiver setup file.');
  Stream.Init(Name, stCreate);
  for I := 0 to List^.Count - 2 do
  begin
    if Stream.Status <> stOk then Break;
    P := List^.At(I);
    WriteUserArchiveRec(@Stream, P);
  end;
  Stream.Done;
  SetRange(List^.Count);
  FocusItem(Focused);
  DrawView;
  Select;
  if List^.Count > 1 then
    EnableCommands(ModifyCommands + DeleteCommands + NewItemPosCommands)
  else DisableCommands(ModifyCommands + DeleteCommands + NewItemPosCommands);
  Message(Desktop, evBroadcast, cmNoArc, nil);
end;

function TUserArchiveViewer.ModifyItem: Boolean;
var
  Item: PUserArchiveRec;
begin
  if Focused = Range - 1 then
  begin
    ModifyItem := NewItem;
    Exit;
  end;
  Item := GetNewUserArchiveItem('Modify', List^.At(Focused));
  if Item <> nil then
  begin
    List^.AtFree(Focused);
    List^.AtInsert(Focused, Item);
    SaveList;
    ModifyItem := True;
  end
  else ModifyItem := False;
end;

function TUserArchiveViewer.NewItem: Boolean;
var
  Item: PUserArchiveRec;
begin
  Item := GetNewUserArchiveItem('New', List^.At(Focused));
  if Item <> nil then
  begin
    List^.AtInsert(Focused, Item);
    SaveList;
    NewItem := True;
  end
  else NewItem := False;
end;

function TUserArchiveViewer.DeleteItem: Boolean;
begin
  with List^ do
    if (Focused < Count - 1) and (DeleteItemMsgBox = cmOk) then
  begin
    AtFree(Focused);
    SaveList;
    DeleteItem := True;
  end
  else DeleteItem := False;
end;

procedure TUserArchiveViewer.FocusMask;
var
  I: Integer;
  PS: PString;
  P: PUserArchiveRec;
  N: String;
begin
  PS := Message(Desktop, evBroadcast, cmUserArchivers, nil);
  if PS = nil then
    PS := Message(Desktop, evBroadcast, cmGetSource, nil);
  if PS = nil then Exit;
  N := JustFileName(PS^);
  if N <> '' then for I := 0 to List^.Count - 2 do
  begin
    P := List^.At(I);
    if (P^.Mask <> nil) and WildCardMatch(N, P^.Mask^) then
    begin
      FocusItem(I);
      Exit;
    end;
  end;
end;

procedure TUserArchiveViewer.NewItemPos;
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
      GetEvent(Event);
      HandleEvent(Event);
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
        SaveList;
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

constructor TUserArchiveDialog.Init;
var
  R: TRect;
  Control: PView;
begin
  R.Assign(0, 0, 65, 16);
  Inherited Init(R, 'User defined Archiver list');
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcUserArchivers;

  R.Assign(Size.X - 15, 3, Size.X - 14, Size.Y - 2);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3, 3, Size.X - 15, Size.Y - 2);
  UserArchiveViewer := New(
    PUserArchiveViewer, Init(R, 1, PScrollBar(Control)));
  UserArchiveViewer^.GrowMode := gfGrowHiY;
  UserArchiveViewer^.Name := Name;
  Insert(UserArchiveViewer);
  UserArchiveViewer^.FillList;
  UserArchiveViewer^.FocusMask;
  R.Assign(2, 2, Size.X - 14, 3);
  Insert(New(PLabel, Init(
    R, ' ~F~ile names    Archiver title and trademark',
    UserArchiveViewer)));

  R.Assign(Size.X - 13, 3, Size.X - 3, 5);
  Insert(New(PButton, Init(R, '~M~odify', cmModifyItem, bfDefault)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~N~ew', cmNewItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'Ad~j~ust', cmNewItemPos, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardCancelButton(R, @Self);
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardHelpButton(R, @Self);
  SelectNext(False);
  EnableCommands(NewCommands);
  if UserArchiveViewer^.List^.Count > 1 then
    EnableCommands(ModifyCommands + DeleteCommands + NewItemPosCommands)
  else DisableCommands(ModifyCommands + DeleteCommands + NewItemPosCommands);
end;

procedure TUserArchiveDialog.HandleEvent(var Event: TEvent);
begin
  Inherited HandleEvent(Event);
  if Event.What = evKeyDown then
    case Event.KeyCode of
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
    end;
  if Event.What = evCommand then with UserArchiveViewer^ do
  begin
    case Event.Command of
      cmModifyItem: ModifyItem;
      cmNewItem: NewItem;
      cmDeleteItem: DeleteItem;
      cmNewItemPos: NewItemPos;
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

function UserArchiverDialog(const Name: FNameStr): Word;
begin
  UserArchiverDialog := Application^.ExecuteDialog(
    New(PUserArchiveDialog, Init(Name)), nil, False);
end;

end.