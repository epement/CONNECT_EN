{$I-,F+,O+,X+}
unit Decoders;

interface

uses Objects, Drivers, Views, Dialogs;

type
  TCNView =
    (vtNo, vtEditor, vtTextViewer, vtHTMLViewer, vtdBASEViewer,
     vtTerminal, vtPanel);

  PDecoderRec = ^TDecoderRec;
  TDecoderRec = record
    Title: PString;
    InName: PString;
    OutName: PString;
    Reserved: Pointer;
  end;

  PDecoderList = ^TDecoderList;
  TDecoderList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
    procedure LoadFromFile(const Name: FNameStr);
    procedure StoreToFile(const Name: FNameStr);
    function GetField(Index, Code: Integer): String;
    function Titles(Index: Integer): String;
    function InNames(Index: Integer): String;
    function OutNames(Index: Integer): String;
  end;

  PDecoderListViewer = ^TDecoderListViewer;
  TDecoderListViewer = object(TListViewer)
    ViewType: TCNView;
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure UpdateCommands;
  end;

  PDecoderInfoPane = ^TDecoderInfoPane;
  TDecoderInfoPane = object(TView)
    Index: Integer;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure UserDefinedDecoderList(Dialog: Boolean);

implementation

uses Menus, Popups, App, MsgBox, EditMsg, FEditor, TxtView, HTMLView,
  DataBase, DataView, Terminal, FileMngr, FMInfo, HistList, History,
  CNInputs, HeapUMB, ProgPath, TPString, Consts, Commands, Defaults;

const
  dfTitle = 1;
  dfInName = 2;
  dfOutName = 3;

  DecoderList: PDecoderList = nil;

  MaxDecoders = 16;

function DecoderListName: FNameStr;
begin
  DecoderListName := ProgramPath + 'CONNECT.UDD';
end;

procedure TDecoderList.FreeItem(Item: Pointer);
begin
  if Item <> nil then with PDecoderRec(Item)^ do
  begin
{
    DisposeStr(OutName);
    DisposeStr(InName);
    DisposeStr(Title);
    FreeMem(Item, SizeOf(TDecoderRec));
}
    DisposeStrUMB(OutName);
    DisposeStrUMB(InName);
    DisposeStrUMB(Title);
    FreeMemUMB(Item, SizeOf(TDecoderRec));
  end;
end;

procedure TDecoderList.LoadFromFile(const Name: FNameStr);
var
  P: PDecoderRec;
  S: TDosStream;
begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Loading user defined decoder list from ' +
    TrimmedName(Name, 28) + '.');
  S.Init(Name, stOpenRead);
  repeat
{    GetMem(P, SizeOf(TDecoderRec));}
    GetMemUMB(P, SizeOf(TDecoderRec));
    with P^ do
    begin
{
      Title := S.ReadStr;
      InName := S.ReadStr;
      OutName := S.ReadStr;
}
      Title := ReadStrUMB(@S);
      InName := ReadStrUMB(@S);
      OutName := ReadStrUMB(@S);
      S.Read(Reserved, SizeOf(Pointer));
    end;
    if S.Status = stOk then Insert(P)
    else
    begin
      FreeItem(P);
      Break;
    end;
  until False;
  S.Done;
end;

procedure TDecoderList.StoreToFile(const Name: FNameStr);
var
  I: Integer;
  P: PDecoderRec;
  S: TDosStream;
  F: File;
begin
  if Count = 0 then
  begin
    Assign(F, Name);
    Erase(F);
    InOutRes := 0;
    Exit;
  end;
  LogEvent := lcDiskWrite;
  DrawStatusLine('Storing user defined decoder list to ' +
    TrimmedName(Name, 31) + '.');
  S.Init(Name, stCreate);
  for I := 0 to Count - 1 do
  begin
    P := At(I);
    if P <> nil then with P^, S do
    begin
      WriteStr(Title);
      WriteStr(InName);
      WriteStr(OutName);
      S.Write(Reserved, SizeOf(Pointer));
    end;
  end;
  S.Done;
end;

function TDecoderList.GetField(Index, Code: Integer): String;
var
  P: PDecoderRec;
begin
  GetField := '';
  P := At(Index);
  if P <> nil then with P^ do
    if Code = dfTitle then
      if Title = nil then GetField := 'Untitled'
      else GetField := Title^
    else if Code = dfInName then
      if InName = nil then GetField := ''
      else GetField := InName^
    else if Code = dfOutName then
      if OutName = nil then GetField := ''
      else GetField := OutName^;
end;

function TDecoderList.Titles(Index: Integer): String;
begin
  Titles := GetField(Index, dfTitle);
end;

function TDecoderList.InNames(Index: Integer): String;
begin
  InNames := GetField(Index, dfInName);
end;

function TDecoderList.OutNames(Index: Integer): String;
begin
  OutNames := GetField(Index, dfOutName);
end;

function GetCurViewType: TCNView;
var
  P: PView;
begin
  GetCurViewType := vtNo;
  if Application^.Current = PView(Desktop) then
    P := Desktop^.Current
  else P := Application^.Current;
  if P <> nil then
    if P^.Options and ofASCII <> 0 then
      GetCurViewType := vtEditor
    else if TypeOf(P^) = TypeOf(TTextWindow) then
      GetCurViewType := vtTextViewer
    else if TypeOf(P^) = TypeOf(THTMLWindow) then
      GetCurViewType := vtHTMLViewer
    else if (TypeOf(P^) = TypeOf(TDataWindow)) and
      (PDataWindow(P)^.Viewer^.EditMode = emNo) then
        GetCurViewType := vtdBASEViewer
    else if TypeOf(P^) = TypeOf(TTerminalWindow) then
      GetCurViewType := vtTerminal
    else if TypeOf(P^) = TypeOf(TPanelWindow) then
      GetCurViewType := vtPanel;
end;

procedure ApplyDecoder(Index: Integer; ViewType: TCNView);
var
  P: PView;
  InName, OutName: FNameStr;
begin
  InName := DecoderList^.InNames(Index);
  OutName := DecoderList^.OutNames(Index);
  if ViewType = vtNo then ViewType := GetCurViewType;
  if Application^.Current = PView(Desktop) then
    P := Desktop^.Current
  else P := Application^.Current;
  if P <> nil then case ViewType of
    vtEditor: if P^.Options and ofASCII <> 0 then
      with PFileEditor(PEditorWindow(P)^.Editor)^ do
      begin
        if DisposeXLATNames then
        begin
{
          DisposeStr(INXLATName);
          DisposeStr(OUTXLATName);
}
          DisposeStrUMB(INXLATName);
          DisposeStrUMB(OUTXLATName);
        end
        else DisposeXLATNames := True;
        if (Index < MaxDecoders) and (InName <> '') then
{         INXLATName := NewStr(InName)}
          INXLATName := NewStrUMB(InName)
        else INXLATName := nil;
        if (Index < MaxDecoders) and (OutName <> '') then
{         OUTXLATName := NewStr(OutName)}
          OUTXLATName := NewStrUMB(OutName)
        else OUTXLATName := nil;
        IsReloading := True;
        UpdateLines('');
        IsReloading := False;
      end;
    vtTextViewer: if TypeOf(P^) = TypeOf(TTextWindow) then
      if (Index < MaxDecoders) and (InName <> '') then
        PTextWindow(P)^.Viewer^.SetXLATTable(InName, False)
        else PTextWindow(P)^.Viewer^.ClearXLATTable;
    vtHTMLViewer: if TypeOf(P^) = TypeOf(THTMLWindow) then
      begin
        if (Index < MaxDecoders) and (InName <> '') then
          PHTMLWindow(P)^.Viewer^.SetXLATTable(InName, False)
        else PHTMLWindow(P)^.Viewer^.ClearXLATTable;
        PHTMLWindow(P)^.Viewer^.DrawView;
      end;
    vtdBASEViewer: if TypeOf(P^) = TypeOf(TDataWindow) then
      begin
        if (Index < MaxDecoders) and (InName <> '') then
          PDataWindow(P)^.Viewer^.SetXLATTable(InName, dcXLATIN)
        else PDataWindow(P)^.Viewer^.ClearXLATTable(dcXLATIN);
        if (Index < MaxDecoders) and (OutName <> '') then
          PDataWindow(P)^.Viewer^.SetXLATTable(OutName, dcXLATOUT)
        else PDataWindow(P)^.Viewer^.ClearXLATTable(dcXLATOUT);
      end;
    vtTerminal: if (TypeOf(P^) = TypeOf(TTerminalWindow)) and
      (TheTerminal <> nil) then
      begin
        if Index < MaxDecoders then InputXLATName := InName
        else InputXLATName := '';
        if Index < MaxDecoders then OutputXLATName := OutName
        else OutputXLATName := '';
        PTerminal(TheTerminal)^.InitXLAT;
      end;
    vtPanel: if TypeOf(P^) = TypeOf(TPanelWindow) then
      DecodePanelPrim(PPanelWindow(P), InName);
  end;
end;

function NewDecoderListItem(Index: Integer; Edit: Boolean): Integer;
type
  TData = record
    Title: String[38];
    InName: FNameStr;
    OutName: FNameStr;
  end;
var
  C: Char;
  P: PDecoderRec;
  D: PDialog;
  Control: PView;
  R: TRect;
  S: String[7];
  Data: TData;
begin
  NewDecoderListItem := -1;
  P := DecoderList^.At(Index);
  if P = nil then Edit := False;
  if Edit then S := 'Modify' else
  begin
    if DecoderList^.Count >= MaxDecoders then
    begin
      MessageBox(
        ^C'Can''t add more items to User defined decoder list ' +
        'because they won''t fit into the pop-up menu box.',
        nil, mfInformation + mfOkButton);
      Exit;
    end;
    S := 'New';
  end;
  R.Assign(0, 0, 63, 11);
  D := New(PDialog, Init(R, S + ' User defined decoder item'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcDecoderListItem;

    R.Assign(17, 2, Size.X - 6, 3);
    Control := New(PInputLine, Init(R, 38));
    Insert(Control);
    StandardHistory(Control, DecoderTitleHistoryID);
    R.Assign(2, 2, 17, 3);
    Insert(New(PLabel, Init(R, '~D~ecoder title', Control)));

    R.Assign(17, 4, Size.X - 6, 5);
    Control := New(PFInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, XLATNameHistoryID);
    R.Assign(2, 4, 17, 5);
    Insert(New(PLabel, Init(R, '~I~n XLAT file', Control)));

    R.Assign(17, 6, Size.X - 6, 7);
    Control := New(PFInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, XLATNameHistoryID);
    R.Assign(2, 6, 17, 7);
    Insert(New(PLabel, Init(R, '~O~ut XLAT file', Control)));

    StandardButtonRow(D, True);
  end;

  if Edit then
    if P^.Title = nil then Data.Title := ''
    else Data.Title := DecoderList^.Titles(Index)
  else Data.Title := HistoryStr(DecoderTitleHistoryId, 0);
  if Edit then Data.InName := DecoderList^.InNames(Index)
  else Data.InName := HistoryStr(XLATNameHistoryId, 0);
  if Edit then Data.OutName := DecoderList^.OutNames(Index)
  else Data.OutName := HistoryStr(XLATNameHistoryId, 0);
  if Application^.ExecuteDialog(D, @Data, True) = cmCancel then Exit;

{  GetMem(P, SizeOf(TDecoderRec));}
  GetMemUMB(P, SizeOf(TDecoderRec));
  with P^ do
  begin
{
    Title := NewStr(Trim(Data.Title));
    InName := NewStr(StUpcase(Trim(Data.InName)));
    OutName := NewStr(StUpcase(Trim(Data.OutName)));
}
    Title := NewStrUMB(Trim(Data.Title));
    InName := NewStrUMB(StUpcase(Trim(Data.InName)));
    OutName := NewStrUMB(StUpcase(Trim(Data.OutName)));
    Reserved := nil;
    if Edit then
    begin
      DecoderList^.AtFree(Index);
      DecoderList^.AtInsert(Index, P);
      NewDecoderListItem := Index;
    end
    else
    begin
      DecoderList^.Insert(P);
      NewDecoderListItem := DecoderList^.Count - 1;
    end;
    DecoderList^.StoreToFile(DecoderListName);
  end;
end;

procedure TDecoderListViewer.FocusItem(Item: Integer);
begin
  Inherited FocusItem(Item);
  Message(Owner, evBroadcast, cmDecoderList, Pointer(Focused));
  UpdateCommands;
end;

function TDecoderListViewer.GetText(Item: Integer; MaxLen: Integer): String;
begin
  GetText := DecoderList^.Titles(Item);
end;

procedure TDecoderListViewer.HandleEvent(var Event: TEvent);
var
  P: PDecoderRec;

procedure MoveItem(Up: Boolean);
begin
  P := DecoderList^.At(Focused);
  if P = nil then Exit;
  if Up and (Focused <> 0) then
  begin
    DecoderList^.Items^[Focused] := DecoderList^.Items^[Focused - 1];
    DecoderList^.Items^[Focused - 1] := P;
    FocusItem(Focused - 1);
    DecoderList^.StoreToFile(DecoderListName);
  end
  else if not Up and (Focused < Range - 1) then
  begin
    DecoderList^.Items^[Focused] := DecoderList^.Items^[Focused + 1];
    DecoderList^.Items^[Focused + 1] := P;
    FocusItem(Focused + 1);
    DecoderList^.StoreToFile(DecoderListName);
  end;
end;

begin
  if Event.What = evKeyDown then
    if ((Event.KeyCode = kbEnter) and not CommandEnabled(cmRunItem)) or
       (Event.KeyCode = kbCtrlEnter) then
    begin
      Event.What := evBroadcast;
      Event.Command := cmModifyItem;
    end
    else if Event.KeyCode = kbIns then
    begin
      Event.What := evBroadcast;
      Event.Command := cmNewItem;
    end
    else if Event.KeyCode = kbDel then
    begin
      Event.What := evBroadcast;
      Event.Command := cmDeleteItem;
    end
    else if Event.KeyCode = kbCtrlUp then
    begin
      Event.What := evBroadcast;
      Event.Command := cmHotKeyUp;
    end
    else if Event.KeyCode = kbCtrlDn then
    begin
      Event.What := evBroadcast;
      Event.Command := cmHotKeyDown;
    end;
  Inherited HandleEvent(Event);
  if Event.What = evBroadcast then
  begin
    if (Event.Command = cmRunItem) or
       (Event.Command = cmListItemSelected) then
    begin
      if CommandEnabled(cmRunItem) then
      begin
        Pending.What := evCommand;
        Pending.Command := cmDecoders + Focused;
        EndModal(cmOk);
      end
      else
      begin
        Pending.What := evBroadcast;
        Pending.Command := cmModifyItem;
      end;
    end
    else if (Event.Command = cmModifyItem) or
       (Event.Command = cmNewItem) then
    begin
      Event.InfoInt := NewDecoderListItem(
        Focused, Event.Command = cmModifyItem);
      if Event.InfoInt <> -1 then
      begin
        SetRange(DecoderList^.Count);
        FocusItem(Event.InfoInt);
      end;
    end
    else if (Event.Command = cmDeleteItem) and
      (Focused < Range) and (DeleteItemMsgBox = cmOk) then
    begin
      DecoderList^.AtFree(Focused);
      SetRange(DecoderList^.Count);
      FocusItem(Focused);
      DecoderList^.StoreToFile(DecoderListName);
    end
    else if (Event.Command = cmHotKeyUp) or
      (Event.Command = cmHotKeyDown) then
        MoveItem(Event.Command = cmHotKeyUp)
    else Exit;
    DrawView;
    UpdateCommands;
    Event.What := evNothing;
  end;
end;

procedure TDecoderListViewer.UpdateCommands;
const
  UpCommands = [cmHotKeyUp];
  DownCommands = [cmHotKeyDown];
begin
  if Range <> 0 then
  begin
    EnableCommands(ModifyCommands + DeleteCommands);
    if ViewType <> vtNo then EnableCommands(RunItemCommands)
    else DisableCommands(RunItemCommands);
  end
  else DisableCommands(ModifyCommands + DeleteCommands + RunItemCommands);
  if Focused <> 0 then EnableCommands(UpCommands)
  else DisableCommands(UpCommands);
  if Focused < Range - 1 then EnableCommands(DownCommands)
  else DisableCommands(DownCommands);
end;

procedure TDecoderInfoPane.Draw;
var
  C: Byte;
  S: String[79];
  B: TDrawBuffer;
begin
  C := GetColor(1);
  MoveChar(B, ' ', C, Size.X);
  S := DecoderList^.InNames(Index);
  MoveStr(B[1], ' In XLAT file: ' + TrimmedName(S, Size.X - 17), C);
  WriteLine(0, 0, Size.X, 1, B);
  MoveChar(B, ' ', C, Size.X);
  S := DecoderList^.OutNames(Index);
  MoveStr(B[1], 'Out XLAT file: ' + TrimmedName(S, Size.X - 17), C);
  WriteLine(0, 1, Size.X, 1, B);
end;

function TDecoderInfoPane.GetPalette: PPalette;
const
  P: String[1] = #30;
begin
  GetPalette := @P;
end;

procedure TDecoderInfoPane.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  if (Event.What = evBroadcast) and (Event.Command = cmDecoderList) then
  begin
    Index := Event.InfoInt;
    DrawView;
  end;
end;

procedure UserDefinedDecoderList(Dialog: Boolean);
var
  ViewType: TCNView;
  I: Integer;
  D: PDialog;
  DV: PDecoderListViewer;
  Control: PView;
  P: PDecoderRec;
  Item: PMenuItem;
  R: TRect;
  S: String[7];
begin
  ViewType := GetCurViewType;
  if ViewType = vtNo then Dialog := True;

  DecoderList := New(PDecoderList, Init(8, 8));
  DecoderList^.LoadFromFile(DecoderListName);
  if DecoderList^.Count = 0 then Dialog := True;

  if Dialog then
  begin
    R.Assign(0, 0, 57, ScreenHeight - 4);
    D := New(PDialog, Init(R, 'User defined decoder list'));
    with D^ do
    begin
      HelpCtx := hcDecoderList;
      Options := Options or ofCentered;
      GrowMode := GrowMode + gfGrowHiY;

      R.Assign(Size.X - 15, 2, Size.X - 14, Size.Y - 4);
      Control := New(PScrollBar, Init(R));
      Insert(Control);
      R.Assign(2, 2, Size.X - 15, Size.Y - 4);
      DV := New(PDecoderListViewer, Init(R, 1, nil, PScrollBar(Control)));
      DV^.GrowMode := gfGrowHiY;
      DV^.SetRange(DecoderList^.Count);
      DV^.ViewType := ViewType;
      Insert(DV);
      R.Assign(1, 1, Size.X - 14, 2);
      Insert(New(PLabel, Init(R, '~D~ecoders', DV)));

      R.Assign(2, Size.Y - 3, Size.X - 2, Size.Y - 1);
      Control := New(PDecoderInfoPane, Init(R));
      Control^.GrowMode := gfGrowLoY + gfGrowHiY;
      Control^.EventMask := Control^.EventMask or evBroadcast;
      Insert(Control);

      R.Assign(Size.X - 13, 2, Size.X - 3, 4);
      Insert(New(PButton, Init(R, '~A~pply',
        cmRunItem, bfDefault + bfBroadcast)));
      Inc(R.A.Y, 2); Inc(R.B.Y, 2);
      Insert(New(PButton, Init(R, '~M~odify',
        cmModifyItem, bfNormal + bfBroadcast)));
      Inc(R.A.Y, 2); Inc(R.B.Y, 2);
      Insert(New(PButton, Init(R, '~N~ew',
        cmNewItem, bfNormal + bfBroadcast)));
      Inc(R.A.Y, 2); Inc(R.B.Y, 2);
      Insert(New(PButton, Init(R, '~D~elete',
        cmDeleteItem, bfNormal + bfBroadcast)));
      Inc(R.A.Y, 2); Inc(R.B.Y, 2);
      Insert(New(PButton, Init(R, ' ~U~p',
        cmHotKeyUp, bfNormal + bfBroadcast)));
      Inc(R.A.Y, 2); Inc(R.B.Y, 2);
      Insert(New(PButton, Init(R, ' Do~w~n',
        cmHotKeyDown, bfNormal + bfBroadcast)));
      Inc(R.A.Y, 2); Inc(R.B.Y, 2);
      StandardCancelButton(R, D);
      Inc(R.A.Y, 2); Inc(R.B.Y, 2);
      StandardHelpButton(R, D);

      SelectNext(False);
      DV^.FocusItem(0);
    end;

    Application^.ExecuteDialog(D, nil, False);
  end
  else
  begin
    Item :=
      NewLine(
      NewItem('~R~eset', '', kbNoKey,
        cmDecoders + MaxDecoders, hcResetDecoder,
      NewLine(
      NewItem('~C~onfigure...', '', kbNoKey,
        cmDecoderList, hcDecoderList, nil))));
    for I := DecoderList^.Count - 1 downto 0 do
    begin
      Str(I + 1, S);
      if I < 9 then S := '~' + S + '~'
      else if I = 9 then S := '1~0~';
      Item := NewItem(S + '. ' + DecoderList^.Titles(I),
        '', kbNoKey, cmDecoders + I, hcSelectDecoder, Item);
    end;
    R.A.X := ScreenWidth div 2;
    R.A.Y := ScreenHeight div 2 - DecoderList^.Count div 2 - 2;
    ShowPopup(R.A, NewMenu(Item));
  end;

  if (Pending.What = evCommand) and
     (Pending.Command >= cmDecoders) and
     (Pending.Command <= cmDecoders + MaxDecoders) then
  begin
    Pending.What := evNothing;
    ApplyDecoder(Pending.Command - cmDecoders, vtNo);
  end;

  Dispose(DecoderList, Done);
end;

end.