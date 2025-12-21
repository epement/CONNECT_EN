{$I-,X+,O+,F+}
unit GroupDlg;

interface

uses Objects, Drivers, Views, Dialogs, ColorSel, FMGroups;

type
  PGroupViewer = ^TGroupViewer;
  TGroupViewer = object(TListBox)
    SelList: PCollection;
    LockFocus: Boolean;
    constructor Init(var Bounds: TRect; ANumCols: Integer;
      AScrollBar: PScrollBar);
    destructor Done; virtual;
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function IsSelected(Item: Integer): Boolean; virtual;
    procedure SelectFocused(Down: Boolean);
    procedure Invert;
    procedure Unselect;
    procedure SaveList;
    function GetNewItem(const Header: String;
      ChangeGroup: Boolean): PGroupRec;
    procedure ModifyItem;
    procedure NewItem;
    procedure DeleteItem;
    procedure FocusMask;
    procedure NewItemPos;
  end;

  PGroupInfoPane = ^TGroupInfoPane;
  TGroupInfoPane = object(TView)
    Mask: String[12];
    Color: Byte;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PDirCheckBox = ^TDirCheckBox;
  TDirCheckBox = object(TCheckBoxes)
    procedure Press(Item: Integer); virtual;
  end;

  PGroupDisplay = ^TGroupDisplay;
  TGroupDisplay = object(TColorDisplay)
    procedure Draw; virtual;
  end;

  PNewGroupDialog = ^TNewGroupDialog;
  TNewGroupDialog = object(TDialog)
    DirCheckBox: PCheckBoxes;
    GrpCheckBox: PCheckBoxes;
  end;

  PGroupDialog = ^TGroupDialog;
  TGroupDialog = object(TDialog)
    GroupViewer: PGroupViewer;
    constructor Init;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure GroupDialog;

implementation

uses Dos, App, MsgBox, Swaps, EditMsg, DirPrim, StrCol, HeapUMB,
  CNInputs, LFN, TPString, Consts, Commands, Defaults;

type
  PSelList = ^TSelList;
  TSelList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

procedure TSelList.FreeItem(Item: Pointer);
begin
end;

constructor TGroupViewer.Init(var Bounds: TRect; ANumCols: Integer;
  AScrollBar: PScrollBar);
begin
  Inherited Init(Bounds, 1, AScrollBar);
  SelList := New(PSelList, Init(8, 8));
end;

destructor TGroupViewer.Done;
begin
  Dispose(SelList, Done);
  Inherited Done;
end;

procedure TGroupViewer.FocusItem(Item: Integer);
begin
  Inherited FocusItem(Item);
  if not LockFocus then
    Message(Owner, evBroadcast, cmListItemSelected, Groups^.At(Focused));
end;

function TGroupViewer.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: PGroupRec;
  C: String[3];
  S: String;
begin
  P := Groups^.At(Item);
  if P = nil then S := ''
  else
  begin
    FillChar(S, SizeOf(String), #32);
    S[0] := Char(Size.X);
    Move(P^.Mask[1], S[1], Byte(P^.Mask[0]) and not $80);
    if Byte(P^.Mask[0]) and $80 <> 0 then
    begin
      S[14] := '[';
      S[15] := 'D';
      S[16] := 'i';
      S[17] := 'r';
      S[18] := ']';
    end;
    Str(P^.Index, C);
    Move(C[1], S[Size.X - Length(C) - 1], Length(C));
  end;
  GetText := S;
end;

procedure TGroupViewer.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evKeyDown) and (Event.KeyCode = kbIns) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmNewItem;
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and (Event.CharCode = ' ') then
  begin
    SelectFocused(True);
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and (Event.KeyCode = kbGrayMul) then
  begin
    Invert;
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and (Event.KeyCode = kbGrayMinus) then
  begin
    Unselect;
    Event.What := evNothing;
  end
  else if (Event.What = evMouseDown) and
    (Event.Buttons = mbRightButton) then
  begin
    Inherited HandleEvent(Event);
    SelectFocused(True);
  end
  else if (Event.What = evMouseDown) and Event.Double then
  begin
    Pending.What := evCommand;
    Pending.Command := cmModifyItem;
    Event.What := evNothing;
  end
  else Inherited HandleEvent(Event);

  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbCtrlUp: if not MoveListItem(@Self, Groups, True) then Exit;
      kbCtrlDn: if not MoveListItem(@Self, Groups, False) then Exit;
      else Exit;
    end;
    SaveList;
    Event.What := evNothing;
  end;
end;

function TGroupViewer.IsSelected(Item: Integer): Boolean;
begin
  IsSelected := ((SelList^.Count = 0) and (Item = Focused)) or
    ((SelList^.Count > 0) and (SelList^.IndexOf(Groups^.At(Item)) <> -1));
end;

procedure TGroupViewer.SelectFocused(Down: Boolean);
var
  I: Integer;
  P: Pointer;
begin
  P := Groups^.At(Focused);
  if P = nil then Exit;
  I := SelList^.IndexOf(P);
  if I = -1 then SelList^.Insert(P)
  else SelList^.AtFree(I);
  if Down and (Focused < Range - 1) then FocusItem(Focused + 1)
  else DrawView;
end;

procedure TGroupViewer.Invert;
var
  I, N: Integer;
  P: Pointer;
begin
  for N := 0 to Groups^.Count - 1 do
  begin
    P := Groups^.At(N);
    I := SelList^.IndexOf(P);
    if I = -1 then SelList^.Insert(P)
    else SelList^.AtFree(I);
  end;
  DrawView;
end;

procedure TGroupViewer.Unselect;
begin
  SelList^.FreeAll;
  DrawView;
end;

procedure TGroupViewer.SaveList;
var
  I: Integer;
  P: PGroupRec;
  S: TDosStream;
  Name: FNameStr;
begin
  LogEvent := lcDiskWrite;
  DrawStatusLine('Updating File Manager Group list file.');
  SetCNConfigName(Name, 'GRP');
  S.Init(Name, stCreate);
  for I := 0 to Groups^.Count - 2 do
  begin
    if S.Status <> stOk then Break;
    P := Groups^.At(I);
    S.Write(P^, SizeOf(TGroupRec));
  end;
  S.Done;
  SetRange(Groups^.Count);
  FocusItem(Focused);
  DrawView;
  Select;
  if Groups^.Count > 1 then
    EnableCommands(ModifyCommands + DeleteCommands + NewItemPosCommands)
  else DisableCommands(ModifyCommands + DeleteCommands + NewItemPosCommands);
  Message(Desktop, evBroadcast, cmGroups, nil);
end;

procedure TDirCheckBox.Press(Item: Integer);
begin
  Inherited Press(Item);
  if Owner <> nil then Owner^.Redraw;
end;

const
  goIndex = $0001;
  goFore  = $0002;
  goBack  = $0004;
  GroupOptions: Word = goIndex + goFore + goBack;

function TGroupViewer.GetNewItem(const Header: String;
  ChangeGroup: Boolean): PGroupRec;
var
  IsNew, Dir: Boolean;
  Color: Byte;
  C: Word;
  Code: Integer;
  R: TRect;
  D: PNewGroupDialog;
  MaskInput, IndexInput: PInputLine;
  ForLabel: PLabel;
  ForSel: PColorSelector;
  BakLabel: PLabel;
  BakSel: PColorSelector;
  MonoForeLabel: PLabel;
  MonoForeSel: PMonoSelector;
  MonoBackLabel: PLabel;
  MonoBackSel: PMonoSelector;
  Display: PGroupDisplay;
  P: PGroupRec;
begin
  GetNewItem := nil;
  IsNew := Header[1] = 'N';
  R.Assign(0, 0, 48, 20 + Byte(ChangeGroup) * 3);
  D := New(PNewGroupDialog, Init(R, Header));
  with D^ do
  begin
    HelpCtx := hcNewGroup;
    Options := Options or ofCentered;

    R.Assign(15, 2, 29, 3);
    MaskInput := New(PInputLine, Init(R, 12));
    Insert(MaskInput);
    R.Assign(2, 2, 15, 3);
    Insert(New(PLabel, Init(R, 'File ~n~ame', MaskInput)));

    R.Assign(15, 4, 29, 5);
    IndexInput := New(PCInputLine, Init(R, 3, 0, 255));
    Insert(IndexInput);
    R.Assign(2, 4, 15, 5);
    Insert(New(PLabel, Init(R, 'Group ~i~ndex', IndexInput)));

    R.Assign(30, 2, 45, 3);
    DirCheckBox := New(PDirCheckBox, Init(R,
      NewSItem('~D~irectory', nil)));
    if ChangeGroup then
    begin
      DirCheckBox^.EnableMask := 0;
      DirCheckBox^.State := DirCheckBox^.State or sfDisabled;
    end;
    Insert(DirCheckBox);

    if not ShowMarkers then
    begin
      R.Assign(32, 5, 44, 9);
      ForSel := New(PColorSelector, Init(R, csForeground));
      Insert(ForSel);
      Dec(R.A.Y); R.B.Y := R.A.Y + 1;
      ForLabel := New(PLabel, Init(R, '~F~oreground', ForSel));
      Insert(ForLabel);

      Inc(R.A.Y, 7); Inc(R.B.Y, 10);
      BakSel := New(PColorSelector, Init(R, csBackground));
      Insert(BakSel);
      Dec(R.A.Y); R.B.Y := R.A.Y + 1;
      BakLabel := New(PLabel, Init(R, '~B~ackground', BakSel));
      Insert(BakLabel);
    end
    else
    begin
      R.Assign(31, 5, 44, 10);
      MonoForeSel := New(PMonoSelector, Init(R, csForeground));
      Insert(MonoForeSel);
      R.Assign(30, 4, 44, 5);
      MonoForeLabel := New(PLabel, Init(R, '~F~oreground', MonoForeSel));
      Insert(MonoForeLabel);

      R.Assign(31, 12, 44, 15);
      MonoBackSel := New(PMonoSelector, Init(R, csBackground));
      Insert(MonoBackSel);
      R.Assign(30, 11, 44, 12);
      MonoBackLabel := New(PLabel, Init(R, '~B~ackground', MonoBackSel));
      Insert(MonoBackLabel);
    end;

    R.Assign(3, 7, 29, 16);
    Display := New(PGroupDisplay, Init(R, nil));
    Insert(Display);
    R.Assign(3, 6, 11, 7);
    Insert(New(PStaticText, Init(R, 'Preview')));

    if ChangeGroup then
    begin
      R.Assign(2, 18, 46, 19);
      GrpCheckBox := New(PCheckBoxes, Init(R,
	NewSItem('Inde~x~',
	NewSItem('F~o~reground',
	NewSItem('B~a~ckground', nil)))));
      GrpCheckBox^.Value := GroupOptions;
      Insert(GrpCheckBox);
      R.Assign(2, 17, 46, 18);
      Insert(New(PLabel, Init(R,
	'Apply changes to all selected items', GrpCheckBox)));
    end;

    StandardButtonRow(D, True);
  end;
  P := Groups^.At(Focused);
  if P <> nil then
  begin
    Dir := Byte(P^.Mask[0]) and $80 <> 0;
    if Dir then Byte(P^.Mask[0]) := Byte(P^.Mask[0]) and not $80;
    MaskInput^.Data^ := P^.Mask;
    if Dir then Byte(P^.Mask[0]) := Byte(P^.Mask[0]) or $80;
    Str(P^.Index, IndexInput^.Data^);
    Color := P^.Color;
    if Dir then D^.DirCheckBox^.Value := 1;
  end
  else
  begin
    MaskInput^.Data^ := '';
    IndexInput^.Data^ := '';
    Color := Application^.GetColor(141);
  end;
  if Header[Length(Header)] = 's' then
    MaskInput^.Data^ := 'Selected';
  Display^.SetColor(Color);
  C := Desktop^.ExecView(D);
  if C <> cmCancel then
  begin
{    GetMem(P, SizeOf(TGroupRec));}
    GetMemUMB(P, SizeOf(TGroupRec));
    P^.Mask := Trim(MaskInput^.Data^);
    if D^.DirCheckBox^.Value <> 0 then
      Byte(P^.Mask[0]) := Byte(P^.Mask[0]) or $80;
    Val(Trim(IndexInput^.Data^), P^.Index, Code);
    P^.Color := Color;
    if ChangeGroup then GroupOptions := D^.GrpCheckBox^.Value;
    GetNewItem := P;
  end;
  Dispose(D, Done);
end;

procedure TGroupViewer.ModifyItem;
var
  I: Integer;
  Item, P: PGroupRec;
  S: String[15];
begin
  if (Focused = Range - 1) and (SelList^.Count = 0) then
  begin
    NewItem;
    Exit;
  end;
  S := 'Modify items';
  if SelList^.Count = 0 then Dec(S[0]);
  Item := GetNewItem(S, SelList^.Count <> 0);
  if Item <> nil then
  begin
    if SelList^.Count <> 0 then
    begin
      for I := 0 to SelList^.Count - 1 do
      begin
	P := SelList^.At(I);
	if GroupOptions and goIndex <> 0 then
	  P^.Index := Item^.Index;
	if GroupOptions and goFore <> 0 then
	  P^.Color := (P^.Color and $F0) or (Item^.Color and $0F);
	if GroupOptions and goBack <> 0 then
	  P^.Color := (P^.Color and $0F) or (Item^.Color and $F0);
      end;
{      FreeMem(Item, SizeOf(TGroupRec));}
      FreeMemUMB(Item, SizeOf(TGroupRec));
    end
    else
    begin
      Groups^.AtFree(Focused);
      Groups^.AtInsert(Focused, Item);
    end;
    SaveList;
    Unselect;
  end;
end;

procedure TGroupViewer.NewItem;
var
  Item: PGroupRec;
begin
  Item := GetNewItem('New item', False);
  if Item <> nil then
  begin
    Groups^.AtInsert(Focused, Item);
    SaveList;
  end;
end;

procedure TGroupViewer.DeleteItem;
var
  I, N: Integer;
begin
  if SelList^.Count <> 0 then
  begin
    if DeleteItemsMsgBox(SelList^.Count) <> cmOk then Exit;
    for I := 0 to SelList^.Count - 1 do
    begin
      N := Groups^.IndexOf(SelList^.At(I));
      if N <> -1 then Groups^.AtFree(N);
    end;
    SaveList;
    Unselect;
  end
  else with Groups^ do
    if (Focused < Count - 1) and (DeleteItemMsgBox = cmOk) then
  begin
    AtFree(Focused);
    SaveList;
  end;
end;

procedure TGroupViewer.FocusMask;
var
  Dir: Boolean;
  I: Integer;
  PS: PString;
  P: PGroupRec;
  D, N, E: String;
begin
  PS := Message(Desktop, evBroadcast, cmGetSource, nil);
  if PS = nil then Exit;
  lFSplit(PS^, D, N, E);
  if Length(N) > 8 then N[0] := #8;
  if Length(E) > 4 then E[0] := #4;
  N := Concat(N, E);
  if N <> '' then for I := 0 to Groups^.Count - 2 do
  begin
    P := Groups^.At(I);
    Dir := Byte(P^.Mask[0]) and $80 <> 0;
    if Dir then Byte(P^.Mask[0]) := Byte(P^.Mask[0]) and not $80;
    D := P^.Mask;
    if Dir then Byte(P^.Mask[0]) := Byte(P^.Mask[0]) or $80;
    if WildCardMatch(N, D) then
    begin
      FocusItem(I);
      Exit;
    end;
  end;
  FocusItem(0);
end;

procedure TGroupViewer.NewItemPos;
var
  SaveFocused, LastFocused: Integer;
  SaveCtx: Word;
  P: Pointer;
  Event: TEvent;
begin
  with Groups^ do
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

procedure TGroupInfoPane.Draw;
var
  B: TDrawBuffer;
begin
  MoveChar(B, ' ', Color, Size.X);
  MoveStr(B[1], Mask, Color);
  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TGroupInfoPane.HandleEvent(var Event: TEvent);
var
  Dir: Boolean;
  P: PGroupRec;
begin
  TView.HandleEvent(Event);
  if (Event.What = evBroadcast) and
     (Event.Command = cmListItemSelected) then
  begin
    if Event.InfoPtr = nil then
    begin
      Mask := '';
      Color := Application^.GetColor(33);
    end
    else
    begin
      P := Event.InfoPtr;
      Dir := Byte(P^.Mask[0]) and $80 <> 0;
      if Dir then Byte(P^.Mask[0]) := Byte(P^.Mask[0]) and not $80;
      Mask := P^.Mask;
      if Dir then Byte(P^.Mask[0]) := Byte(P^.Mask[0]) or $80;
      Color := P^.Color;
      if Color = 0 then
      begin
	Mask := '';
	Color := Application^.GetColor(33);
      end;
    end;
    DrawView;
  end;
end;

procedure TGroupDisplay.Draw;
var
  Dir: Boolean;
  DC, FC, NC, UC, C: Byte;
  I, J, Item, CurCol: Integer;
  List: PStringsCollection;
  S: String[15];
  B: TDrawBuffer;

procedure AddStr(const AS: String; AC: Byte);
begin
{  List^.Insert(NewStr(AS + Char(AC)));}
  List^.Insert(NewStrUMB(AS + Char(AC)));
end;

begin
  Dir := PNewGroupDialog(Owner)^.DirCheckBox^.Value <> 0;
  NC := Application^.GetColor(141);
  UC := Application^.GetColor(143);
  if Dir then
  begin
    DC := Color^;
    FC := NC;
  end
  else
  begin
    DC := NC;
    FC := Color^;
  end;
  List := New(PStringsCollection, Init(18, 1));
  AddStr('..', UC);
  AddStr('BACKUP', NC);
  AddStr('BIN', NC);
  if not Dir or (DC <> 0) then AddStr('EXAMPLES', DC);
  AddStr('PAS', NC);
  if Dir or (FC <> 0) then
  begin
    AddStr('arrays   asm', FC);
    AddStr('bounds   asm', FC);
    AddStr('cputype  asm', FC);
    AddStr('crc32    asm', FC);
    AddStr('diskinfo asm', FC);
    AddStr('jump     asm', FC);
    AddStr('strchar  asm', FC);
    AddStr('strlen   asm', FC);
    AddStr('sysint   asm', FC);
    AddStr('wrap     asm', FC);
  end;
  AddStr('fixes    txt', NC);
  AddStr('bugs', NC);
  AddStr('wishes', NC);
  for I := 0 to Size.Y - 1 do
  begin
    for J := 0 to 1 do
    begin
      Item := J * Size.Y + I;
      CurCol := J * 12 + J;
      MoveChar(B[CurCol], ' ', NC, 12);
      if Item < List^.Count then
      begin
	S := PString(List^.At(Item))^;
	C := Byte(S[Length(S)]);
	Dec(S[0]);
	MoveStr(B[CurCol], Pad(S, 12), C);
      end;
      MoveChar(B[CurCol + 12], '³', NC, 1);
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
  Dispose(List, Done);
end;

constructor TGroupDialog.Init;
var
  R: TRect;
  Control: PView;
begin
  R.Assign(0, 0, 46, ScreenHeight - 4);
  Inherited Init(R, 'File group list');
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcGroupDlg;

  R.Assign(Size.X - 15, 3, Size.X - 14, Size.Y - 4);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3, 3, Size.X - 15, Size.Y - 4);
  GroupViewer := New(PGroupViewer, Init(R, 1, PScrollBar(Control)));
  GroupViewer^.GrowMode := gfGrowHiY;
  GroupViewer^.SetRange(Groups^.Count);
  Insert(GroupViewer);
  R.Assign(2, 2, Size.X - 14, 3);
  Insert(New(PLabel, Init(R, ' ~F~ile names     Group index', GroupViewer)));

  R.Assign(3, Size.Y - 3, Size.X - 14, Size.Y - 2);
  Control := New(PGroupInfoPane, Init(R));
  Control^.Options := Control^.Options or ofFramed;
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Control^.EventMask := Control^.EventMask or evBroadcast;
  Insert(Control);
  R.Assign(14, Size.Y - 4, 21, Size.Y - 3);
  Control := New(PStaticText, Init(R, ' Color '));
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Control);

  R.Assign(Size.X - 13, 3, Size.X - 3, 5);
  Insert(New(PButton, Init(R, '~M~odify', cmModifyItem, bfDefault)));
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
  Insert(New(PButton, Init(R, '~N~ew', cmNewItem, bfNormal)));
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
  Insert(New(PButton, Init(R, 'Ad~j~ust', cmNewItemPos, bfNormal)));
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
  StandardCancelButton(R, @Self);
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
  StandardHelpButton(R, @Self);

  SelectNext(False);
  EnableCommands(NewCommands);
  if Groups^.Count > 1 then
    EnableCommands(ModifyCommands + DeleteCommands + NewItemPosCommands)
  else DisableCommands(ModifyCommands + DeleteCommands + NewItemPosCommands);
  GroupViewer^.FocusMask;
end;

procedure TGroupDialog.HandleEvent(var Event: TEvent);
begin
  Inherited HandleEvent(Event);
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbDel:
	begin
	  Event.What := evCommand;
	  Event.Command := cmDeleteItem;
	end;
      kbShiftIns:
	begin
	  Event.What := evCommand;
	  Event.Command := cmNewItem;
	end;
    end;
  if Event.What = evCommand then with GroupViewer^ do
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

procedure GroupDialog;
begin
  Application^.ExecuteDialog(New(PGroupDialog, Init), nil, False);
end;

end.
