{$I-,F+,O+,X+}
unit FMDrag;

interface

uses Objects, Drivers, FileMngr, PanelRec;

type
  TPanelAction = (paToggleUnfold, paGoRight, paGoLeft,
    paGoCtrlHome, paGoCtrlEnd);

const
  DragWindowInUse: Boolean = False;

procedure GetDestPrim(FManager: PPanel; var S: FNameStr; Where: TPoint);
procedure DragDropPrim(FManager: PPanel; Where: TPoint);
function MouseInViewPrim(FManager: PPanel; Where: TPoint): Boolean;
function GetPointedItemPrim(FManager: PPanel; Where: TPoint): PPanelRec;
procedure PanelHandleMouseDownEventPrim(FManager: PPanel; var Event: TEvent);
procedure PanelFrameHandleMouseDownEventPrim(Frame: PPanelFrame; var Event: TEvent);
procedure PanelWindowHandleMouseDownEventPrim(FManager: PPanelWindow; var Event: TEvent);
procedure PanelWindowHandleCtrlKeyEventPrim(FManager: PPanelWindow; var Event: TEvent);
procedure PanelPerformPrim(FManager: PPanel; Action: TPanelAction);
procedure SetPanelWindowHintStr(FManager: PPanelWindow; Panel: PPanel;
  var S: String);

implementation

uses Dos, CNCrt, Views, App, FMPrim, FMSecond, FMAction, FMDialog,
  DirPrim, DiskBase, DiskPrim, DirTree, DragDrop, Archives, FMDrvSel,
  LFN, TPString, CNWinPos, Consts, Commands, Defaults;

procedure GetDestPrim(FManager: PPanel; var S: FNameStr; Where: TPoint);
var
  Mini, Maxi: Boolean;
  C: Char;
  I, N: Integer;
  SR: PPanelRec;
label
  DriveDest;
begin
  with FManager^ do
  begin
    Mini := State and sfMiniStatus <> 0;
    Maxi := Settings and seMaxi <> 0;
    MakeLocal(Where, Where);
    if (not Maxi and (Where.Y = 0)) or
       ((Where.Y < 0) and (Options and ofValidate <> 0)) then
DriveDest:
      if DragWindowInUse then S := '[drive]'
      else SelectDriveDialog(
	'Select ~destination~ drive:', Which, ListDir^[1], S)
    else if Status = stTree then
    begin
      if InArchive then with Archiver^ do
      begin
	S := GetTopName;
	if ArchiveRec^.Extension <> nil then
	  S := ArchiveRec^.Extension^ + ':' + S;
	Exit;
      end;
      if Where.Y < 0 then I := 0
      else if Mini and (Where.Y >= Size.Y - 2) then I := Focused
      else I := TopItem + Where.Y - Byte(not Maxi);
      S := TheTree^.GetDirStr(I);
    end
    else if Options and ofValidate <> 0 then
    begin
      if Mini and (Where.Y >= Size.Y - 2) then I := Focused
      else if Status = stFull then I := TopItem + Where.Y - Byte(not Maxi)
      else
      begin
	N := Size.Y - Byte(Mini) * 2 - Byte(not Maxi);
	I := Where.Y - Byte(not Maxi) +
	  (N * (Where.X div ColWidth)) + TopItem;
      end;
      GetItemStr(I, S);
      if S = '' then goto DriveDest;
    end
    else
    begin
      if Where.Y < 0 then I := -1
      else if Mini and (Where.Y >= Size.Y - 2) then I := Focused
      else if Status = stFull then I := TopItem + Where.Y - Byte(not Maxi)
      else
      begin
	N := Size.Y - Byte(Mini) * 2 - Byte(not Maxi);
	I := Where.Y - Byte(not Maxi) +
	  (N * (Where.X div ColWidth)) + TopItem;
      end;
      if (I < 0) or (I >= List^.Count) then GetListDir(S)
      else
      begin
	SR := List^.At(I);
	if SR^.Name = '..' then
	begin
	  GetListDir(S);
	  S := PrevDir(S);
	end
	else if InArchive then with Archiver^ do
	begin
	  S := GetTopName;
	  if ArchiveRec^.Extension <> nil then
	    S := ArchiveRec^.Extension^ + ':' + S;
	  Exit;
	end
	else if SR^.Name = ':' then goto DriveDest
	else if (SR^.Attr and $10 <> 0) and (SR^.Attr and $08 = 0) and
	  not (SR^.Name[1] in [':', '.']) then GetItemStr(I, S)
	else GetListDir(S);
      end;
    end;
    if S = '' then S := #0 else S := AddedSlash(S);
  end;
end;

procedure DragDropPrim(FManager: PPanel; Where: TPoint);
var
  ForceSel: Boolean;
  Action: Byte;
  SW: Word;
  X: Integer;
  W: PDragWindow;
  SR: PPanelRec;
  P: PString;
  E: TEvent;
  L: Longint;
  Title: String[4];
  R: TRect;
  Text: String;
begin
  SW := GetShiftState;
  with FManager^ do
  begin
    SR := List^.At(Focused);
    ForceSel := (SR^.Selected and (SW and kbCtrlShift = 0)) or
      ((SelCount <> 0) and (SW and (kbLeftShift + kbRightShift) <> 0));
    if not ForceSel and (SR^.Attr and $08 <> 0) and (SR^.Name[1] <> '.') then
      Exit;

    if InArchive then Action := 0
    else if SW and kbAltShift <> 0 then Action := 1
    else if SW and kbCtrlShift <> 0 then
      if SR^.Selected then Action := 0 else Action := 1
    else Action := 0;
    if Action = 1 then Title := 'Move' else Title := 'Copy';

    if ForceSel then
      if SelCount = 1 then Text := '1 file'
      else
      begin
	L := SelCount;
	FormatStr(Text, '%d files', L);
      end
    else if SR^.Name = ':' then Text := RootName(ListDir^)
    else AddNameExt('', SR, Text);

    if Length(Text) <= 12 then X := 16
    else
    begin
      X := Length(Text) + 4;
      if X > ScreenWidth then X := ScreenWidth;
    end;

    DragWindowInUse := True;

    R.Assign(Where.X, Where.Y, Where.X + X, Where.Y + 4);
    W := New(PDragWindow, Init(R, Title, Owner, hcDragAndDrop, Text));
    Application^.Insert(W);

    Application^.GetExtent(R);
    E.What := evMouseDown;
    E.Where := Where;

    W^.DragView(E, dmDragMove, R, W^.Size, W^.Size);
    if W^.Cancel then
    begin
      DragWindowInUse := False;
      W^.Close;
      Exit;
    end;
    DragWindowInUse := False;

    P := Message(Desktop, evBroadcast, cmGetDest, @W^.Origin);
    if P = nil then Text := '' else Text := P^;
    W^.Close;
    if Text = #0 then Exit;
    CopyLeft := (Which = pnRight) and (FMOptions and foCopyLeft <> 0);
    if Text = '' then FMDeletePrim(FManager, not ForceSel)
    else if Action = 0 then FMCopyPrim(FManager, Text, not ForceSel)
    else FMRenMovPrim(FManager, Text, not ForceSel);
  end;
end;

function MouseInViewPrim(FManager: PPanel; Where: TPoint): Boolean;
begin
  with FManager^, PPanelWindow(Owner)^ do
  begin
    MakeLocal(Where, Where);
    if Where.Y <> 0 then MouseInViewPrim := False
    else if Which = pnLeft then MouseInViewPrim :=
      (Where.X >= LeftTitlePos) and
      (Where.X < LeftTitlePos + LeftTitleLen)
    else MouseInViewPrim :=
      (Where.X >= RightTitlePos) and
      (Where.X < RightTitlePos + RightTitleLen);
{      (Where.X > 4) and (Where.X < Size.X - 1)}
{    else MouseInViewPrim := (Where.X > 0) and (Where.X < Size.X - 5);}
  end;
end;

function GetPointedItemPrim(FManager: PPanel; Where: TPoint): PPanelRec;
var
  Mini, Maxi: Boolean;
  I, N: Integer;
begin
  GetPointedItemPrim := PPanelRec(FManager);
  with FManager^ do
  begin
    if (Where.X < 0) or (Where.X >= Size.X) then Exit;
    Mini := State and sfMiniStatus <> 0;
    if Mini and (Where.Y >= Size.Y - 2) then Exit;
    Maxi := Settings and seMaxi <> 0;
    if not Maxi and (Where.Y = 0) then Exit;
    if NumCols = 1 then I := TopItem + Where.Y - Byte(not Maxi)
    else
    begin
      N := Size.Y - Byte(Mini) * 2 - Byte(not Maxi);
      I := Where.Y - Byte(not Maxi) + (N * (Where.X div ColWidth)) + TopItem;
    end;
    if (I >= 0) and (I < List^.Count) then GetPointedItemPrim := List^.At(I);
  end;
end;

procedure PanelHandleMouseDownEventPrim(FManager: PPanel; var Event: TEvent);
type
  TVideoArray =	Array[0..24, 0..79] of Word;
var
  RightBtnDown, RightBtnSel, Mini, Maxi,
  MouseDown, MouseMoved, CanDragColumns: Boolean;
  W: Word;
  NewItem, I, N: Integer;
{  Ticks: Word;}
  SaveOpt: Longint;
  Where, Mouse: TPoint;
  P: PPanelRec;

function CanExpandSelection: Boolean;
begin
  CanExpandSelection := RightBtnDown = RightBtnSel;
end;

begin
  with FManager^ do
  begin
    if PPanelWindow(Owner)^.MouseHintVisible then
    begin
      SaveOpt := FMOptions;
      FMOptions := FMOptions and not foAltCtrlNames;
      PPanelWindow(Owner)^.DrawView;
      FMOptions := SaveOpt;
    end;
    RightBtnDown := Event.Buttons = mbRightButton;
    RightBtnSel := MouseOptions and moFMRTags <> 0;
    if RightBtnDown and
      (not RightBtnSel or (Status > stTree) or
      (GetShiftState and (kbAltShift + kbCtrlShift +
       kbLeftShift + kbRightShift) = kbAltShift)) then
    begin
      repeat until not MouseEvent(Event, evMouseDown);
      PopupPrim(FManager, Event.Where);
      Event.What := evNothing;
      Exit;
    end;
    if (Status >= stInfo) and Event.Double and not RightBtnDown then
    begin
      Event.What := evCommand;
      Event.Command := cmIsASCII;
    end
    else
    begin
      Mini := State and sfMiniStatus <> 0;
      Maxi := Settings and seMaxi <> 0;
      N := Size.Y - Byte(Mini) * 2 - Byte(not Maxi);
      MouseDown	:= False;
      MouseMoved := False;
      Where := MouseWhere;
      CanDragColumns := not RightBtnDown;
{      Ticks := MemW[$40:$6C];}
      repeat
	MouseMoved := (MouseWhere.X <> Where.X) or (MouseWhere.Y <> Where.Y);
	MakeLocal(Event.Where, Mouse);
	if MouseInView(Event.Where) then
	begin
	  if CanDragColumns and
	    (Mouse.Y < Size.Y - Byte(Mini) * 2) and
	    (((Status = stBrief) and ((Mouse.X + 1) mod ColWidth = 0)) or
	     ((Status = stFull) and (Settings and seLongNames = 0) and
	      (Mouse.X + 1 = ColWidth))) then
	  begin
	    DragColumnsPrim(FManager, Event);
	    Break;
	  end;
	  if Status <> stInfo then
	  begin
	    if not Maxi and (Mouse.Y < 1) then
	    begin
	      NewItem := Focused - 1;
	      Event.Double := False;
	    end
	    else if Mini and (Mouse.Y >= Size.Y - 2) then
	    begin
	      NewItem := Focused + 1;
	      Event.Double := False;
	    end
	    else if NumCols = 1 then
	      NewItem := TopItem + Mouse.Y - Byte(not Maxi)
	    else NewItem := TopItem + Mouse.Y - Byte(not Maxi) +
	      (N * (Mouse.X div	ColWidth));
	    if Event.Double and not RightBtnDown and
	      (NewItem >= TopItem) and (NewItem < Range) then
	    begin
	      W := GetShiftState;
	      if (W and kbCtrlShift <> 0) and
		 (W and (kbAltShift + kbLeftShift + kbRightShift) = 0) then
	      begin
		FocusItem(NewItem);
		AddFocused(False, False);
		Event.What := evNothing;
		Exit;
	      end;
	      Byte(TVideoArray(ScreenBuffer^)
		[Event.Where.Y,	Event.Where.X])	:= Byte('û');
	      Delay(50);
	      FocusItem(NewItem);
	      Event.What := evNothing;
	      ItemSelectedPrim(FManager, Focused);
	    end
	    else if (MouseButtons = mbLeftButton) and
	      (MouseOptions and moFMLDrag <> 0) and MouseDown and MouseMoved and
{	      (MouseMoved or (MemW[$40:$6C] - Ticks > 12)) and}
	      (NewItem >= TopItem) and (NewItem < Range) then
	    begin
	      DragDropPrim(FManager, Event.Where);
	      Event.What := evNothing;
	    end
	    else if (MouseButtons = mbLeftButton + mbRightButton) and
	      (NewItem >= TopItem) and (NewItem	< Range) then
	    begin
	      FocusItem(NewItem);
	      DragDropPrim(FManager, Event.Where);
	      Event.What := evNothing;
	    end
	    else
	    begin
	      if RightBtnDown and RightBtnSel and not MouseDown and
		(Status < stInfo) and (NewItem >= 0) and
		(NewItem < List^.Count) then
	      begin
		P := List^.At(NewItem);
		SetSelect(P, not P^.Selected);
		DrawView;
	      end;
	      if NewItem <> Focused then
	      begin
		if (Status < stInfo) and MouseDown and CanExpandSelection then
		  if NewItem > Focused then
		    for I := Focused to NewItem - 1 do
		      SetSelect(List^.At(I), True)
		  else for I := NewItem + 1 to Focused do
		    SetSelect(List^.At(I), False);
		FocusItem(NewItem);
	      end;
	    end;
	  end;
	  MouseDown := MouseDown or
	    ((Mouse.Y >= Byte(not Maxi)) and
	     (Mouse.Y < Size.Y - Byte(Mini) * 2));
	end
	else
	begin
	  if Mouse.Y < 0 then NewItem := Focused - 1
	  else NewItem := Focused + 1;
	  if (Status < stInfo) and MouseDown and CanExpandSelection then
	    SetSelect(List^.At(Focused), NewItem > Focused);
	  FocusItem(NewItem);
	end;
	CanDragColumns := False;
      until (Event.What	= evNothing) or
	not MouseEvent(Event, evMouseMove + evMouseAuto);
    end;
  end;
end;

procedure PanelFrameHandleMouseDownEventPrim(Frame: PPanelFrame; var Event: TEvent);
var
  LeftHidden, RightHidden: Boolean;
  MouseButton: Byte;
  PanelHeight, LeftSize, RightSize, CloseX, ZoomX: Integer;
  Mouse: TPoint;
  S: String;

procedure DrawCloseIconState(Contains: Boolean);
var
  C: Byte;
  B: TDrawBuffer;
begin
  with Frame^ do
  begin
    C := GetColor(5);
    if Contains then
      if (MouseButtons = mbRightButton) and
	 (WinPosMask and wpIcons <> 0) then MoveChar(B, '\', C, 1)
      else MoveChar(B, '', C, 1)
    else MoveChar(B, 'þ', C, 1);
    WriteLine(CloseX + 1, 0, 1, 1, B);
  end;
end;

procedure DrawZoomMiniIconState(Contains: Boolean);
var
  C: Byte;
  C1, C2: Char;
  B: TDrawBuffer;
begin
  with Frame^ do
  begin
    C := GetColor(5);
    if Longint(Owner^.Size) = Longint(Owner^.Owner^.Size) then C1 := ''
    else C1 := '';
    C2 := '';
    if Contains then
      if (MouseButtons = mbRightButton) and
	 (WinPosMask and wpIcons <> 0) then
	if Mouse.X >= ZoomX + 2 then C2 := '' else C1 := '\'
      else
	if Mouse.X >= ZoomX + 2 then C2 := '' else C1 := '';
    MoveChar(B, C1, C, 1);
    MoveChar(B[1], C2, C, 1);
    WriteLine(ZoomX + 1, 0, 2, 1, B);
  end;
end;

procedure DrawNumberIconState(Contains: Boolean);
var
  C: Char;
  B: TDrawBuffer;
begin
  with Frame^ do
  begin
    if Contains then
      if MouseButtons = mbRightButton then C := #24
      else if WinPosMask and wpLeftClickCloses <> 0 then C := ''
      else if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then C := #27
      else C := #26
    else if (PWindow(Owner)^.Number <> wnNoNumber) and
      (PWindow(Owner)^.Number < 10) then
	C := Char(PWindow(Owner)^.Number + $30)
    else C := wnNoNumberChar;
    MoveChar(B, C, GetColor(5), 1);
    WriteLine(CloseX + 2, 0, 1, 1, B);
  end;
end;

begin
  with Frame^ do
  begin
    with PPanelWindow(Owner)^ do
    begin
      PanelHeight := LeftPanel^.Size.Y;
      LeftHidden := LeftPanel^.State and sfVisible = 0;
      RightHidden := RightPanel^.State and sfVisible = 0;
      LeftSize := LeftPanel^.Size.X + 2;
      RightSize	:= RightPanel^.Size.X +	2;
    end;

    MakeLocal(Event.Where, Mouse);
    if Mouse.Y = 0 then
    begin
      if not LeftHidden	then CloseX := 1
      else if not RightHidden and (RightSize > 8) then
	CloseX := LeftSize + 1
      else CloseX := MaxInt;
      if not RightHidden then ZoomX := Size.X -	5
      else if not LeftHidden and (LeftSize > 8)	then
	ZoomX := LeftSize - 5
      else ZoomX := MaxInt;

      if (WinPosMask and wpIcons <> 0) and
	 (Mouse.X >= CloseX + 2) and (Mouse.X <= CloseX + 3) then
      begin
	repeat
	  MakeLocal(Event.Where, Mouse);
	  DrawNumberIconState((Mouse.Y = 0) and
	    (Mouse.X >=	CloseX + 2) and (Mouse.X <= CloseX + 3));
	  MouseButton := MouseButtons;
	until not MouseEvent(Event, evMouseMove);
	DrawNumberIconState(False);
	if (Mouse.Y = 0) and
	   (Mouse.X >= CloseX + 2) and (Mouse.X <= CloseX + 3) then
	begin
	  if MouseButton = mbRightButton then
	    if LeftHidden then PPanelWindow(Owner)^.RightPanel^.GoCtrlPgUp
	    else PPanelWindow(Owner)^.LeftPanel^.GoCtrlPgUp
	  else
	  begin
	    Event.What := evCommand;
	    if WinPosMask and wpLeftClickCloses <> 0 then
	      Event.Command := cmClose
	    else if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
	      Event.Command := cmNext
	    else Event.Command := cmPrev;
	    Event.InfoPtr := Owner;
	    PutEvent(Event);
	  end;
	  Event.What :=	evNothing;
	end;
      end
      else if (Mouse.X >= CloseX) and (Mouse.X <= CloseX + 2) then
      begin
	repeat
	  MakeLocal(Event.Where, Mouse);
	  DrawCloseIconState((Mouse.Y =	0) and
	    (Mouse.X >=	CloseX)	and (Mouse.X <=	CloseX + 2));
	  MouseButton := MouseButtons;
	until not MouseEvent(Event, evMouseMove);
	DrawCloseIconState(False);
	if (Mouse.Y = 0) and
	   (Mouse.X >= CloseX) and (Mouse.X <= CloseX +	2) then
	begin
	  if (MouseButton = mbRightButton) and
	     (WinPosMask and wpIcons <> 0) then
	    if LeftHidden then PPanelWindow(Owner)^.RightPanel^.RootDir
	    else PPanelWindow(Owner)^.LeftPanel^.RootDir
	  else
	  begin
	    Event.What := evCommand;
	    Event.Command := cmClose;
	    Event.InfoPtr := Owner;
	    PutEvent(Event);
	  end;
	  Event.What :=	evNothing;
	end;
      end
      else if (Mouse.X >= ZoomX) and (Mouse.X <= ZoomX + 3) then
      begin
	repeat
	  MakeLocal(Event.Where, Mouse);
	  DrawZoomMiniIconState((Mouse.Y = 0) and
	    (Mouse.X >=	ZoomX) and (Mouse.X <= ZoomX + 3));
	  MouseButton := MouseButtons;
	until not MouseEvent(Event, evMouseMove);
	DrawZoomMiniIconState(False);
	if (Mouse.Y = 0) and
	   (Mouse.X >= ZoomX) and (Mouse.X <= ZoomX + 3) then
	begin
	  if Mouse.X >=	ZoomX +	2 then
	  begin
	    if (MouseButton = mbRightButton) and
	       (WinPosMask and wpIcons <> 0) then
	      if RightHidden then PPanelWindow(Owner)^.LeftPanel^.GoCtrlPgUp
	      else PPanelWindow(Owner)^.RightPanel^.GoCtrlPgUp
	    else
	    begin
	      Event.What := evKeyDown;
	      Event.KeyCode := kbAltM;
	      PutEvent(Event);
	    end;
	  end
	  else
	  begin
	    if (MouseButton = mbRightButton) and
	       (WinPosMask and wpIcons <> 0) then
	      if RightHidden then PPanelWindow(Owner)^.LeftPanel^.RootDir
	      else PPanelWindow(Owner)^.RightPanel^.RootDir
	    else
	    begin
	      Event.What := evCommand;
	      Event.Command := cmZoom;
	      Event.InfoPtr := Owner;
	      PutEvent(Event);
	    end;
	  end;
	  Event.What := evNothing;
	end;
      end;
    end;

    if (Event.What <> evNothing) and
       (((LeftHidden and (Mouse.X < LeftSize)) or
	 (RightHidden and (Mouse.X >= LeftSize)) or
	 (Mouse.Y > PanelHeight	+ 1))) then
      Event.What := evNothing;

    if (Event.What = evMouseDown) and
       (Mouse.Y > 0) and (Mouse.Y <= PanelHeight) then
      with PPanelWindow(Owner)^ do
	if Mouse.X = LeftSize - 1 then LeftPanel^.Select
	else if Mouse.X = LeftSize then RightPanel^.Select;
  end;
end;

procedure PanelWindowHandleMouseDownEventPrim(FManager: PPanelWindow; var Event: TEvent);
var
  DMode: Byte;
  Min, Max, Mouse: TPoint;
  Limits: TRect;
begin
  with FManager^ do
  begin
    MakeLocal(Event.Where, Mouse);
    if (Event.Buttons = mbRightButton) and
       (GetShiftState and (kbLeftShift + kbRightShift) = 0) and
       ((Mouse.X = 0) or (Mouse.X = Size.X - 1)) and
       (Mouse.Y > 0) and (Mouse.Y < Size.Y - 2) and
       ((RightBar = nil) or not
	((Mouse.X = RightBar^.Origin.X) and
	 (Mouse.Y = RightBar^.Origin.Y) or
	 (Mouse.Y = RightBar^.Origin.Y + RightBar^.Size.Y - 1))) then
    begin
      ToggleBothPanelsPrim(FManager);
      Event.What := evNothing;
      Exit;
    end;
    if Mouse.Y = 0 then
    begin
      DMode := GetTopPos(Mouse.X);
      if DMode in [tpLeftColon, tpLeftName, tpRightColon, tpRightName] then
      begin
	if Event.Buttons = mbRightButton then
	  if DMode in [tpRightColon, tpRightName] then
	    DirHistoryPrim(RightPanel)
	  else DirHistoryPrim(LeftPanel)
	else case DMode of
	  tpLeftColon: SelectDrivePrim(LeftPanel, #0, True);
	  tpLeftName: LeftPanel^.ChangeDir;
	  tpRightColon: SelectDrivePrim(RightPanel, #0, True);
	  tpRightName: RightPanel^.ChangeDir;
	end;
	Event.What := evNothing;
      end
{ Added 2005.11.21 }
      else if (Event.Buttons = mbRightButton) and
	(DMode in [tpLeftMiddleResize, tpRightMiddleResize]) then
	begin
	  if DMode = tpRightMiddleResize then RightPanel^.Select
	  else LeftPanel^.Select;
	  Event.What := evCommand;
	  Event.Command := cmPopup;
	end;
    end
    else if Mouse.Y = LeftPanel^.Size.Y + 1 then
    begin
      DMode := GetBottomPos(Mouse.X);
      if DMode <> bpNo then
      begin
	case DMode of
	  bpMiddleResize: DMode := dmMouseResize;
	  bpLeftResize:
	    begin
	      Inc(Event.Where.Y, Size.Y - (LeftPanel^.Size.Y + 2));
	      DMode := dmDragGrow or dmLimitHiY;
	    end;
	  bpRightResize: DMode := dmDragGrow;
	  else DMode := dmDragMove;
	end;
	DMode := DragMode or DMode;
	Owner^.GetExtent(Limits);
	SizeLimits(Min, Max);
	if (DMode <> dmMouseResize) and (DMode and dmLimitHiY <> 0) then
	  DragView(Event, DMode, Limits, Min, Max)
	else DragPanelsPrim(FManager, Event, DMode, Limits, Min, Max);
	Event.What := evNothing;
      end;
    end;
  end;
end;

procedure PanelWindowHandleCtrlKeyEventPrim(FManager: PPanelWindow; var Event: TEvent);
var
  Sens: Boolean;
  P: PDriveSelector;
  S: String;
begin
  with FManager^ do
  begin
    case Event.KeyCode of
      kbCtrlUp:
	begin
	  GetCurrentPanel;
	  if GetShiftState and kbAltShift <> 0 then
	  begin
	    AltCtrlPgUpHistoryPrim(CurrentPanel, False);
	    Event.What := evNothing;
	  end
	  else if PView(PromptLine) = Current then
	  begin
	    if CurrentPanel^.State and sfVisible <> 0 then
	      CurrentPanel^.Select
	    else if CurrentPanel^.Opposite^.State and sfVisible <> 0 then
	      CurrentPanel^.Opposite^.Select;
	    Event.What := evNothing;
	  end;
	end;
      kbCtrlDn:
	if GetShiftState and kbAltShift <> 0 then
	begin
	  GetCurrentPanel;
	  AltCtrlPgUpHistoryPrim(CurrentPanel, True);
	  Event.What := evNothing;
	end
	else if PView(PromptLine) <> Current then
	begin
	  PromptLine^.Select;
	  Event.What := evNothing;
	end;
      kbCtrlLeft, kbCtrlRight:
	if (PView(PromptLine) <> Current) or (PromptLine^.Data^ = '') then
	begin
	  Sens := FMOptions and foDrvSelDifCtrl <> 0;
	  if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
	    Sens := not Sens;
	  if not Sens then
	  begin
	    GetCurrentPanel;
	    if CurrentPanel^.Which = pnLeft then
	      P := PDriveSelector(LeftSelector)
	    else P := PDriveSelector(RightSelector);
	  end
	  else if (GetShiftState and kbCtrlShift <> 0) and
	    (Mem[$40:$18] and 1 <> 0) then
	      P := PDriveSelector(LeftSelector)
	  else P := PDriveSelector(RightSelector);
	  if (P <> nil) and (P^.State and sfVisible <> 0) then
	    P^.HandleEvent(Event);
	end;
      $1A1B, $1B1D {Ctrl+[, Ctrl+]}:
	begin
	  if Event.KeyCode = $1A1B then LeftPanel^.GetListDir(S)
	  else RightPanel^.GetListDir(S);
	  S := AddedSlash(S);
	  if GetShiftState and (kbLeftShift + kbRightShift) = 0 then
	    lGetShortFileName(S, S);
	  if Pos(' ', S) <> 0 then S := '"' + S + '"';
	  Message(PromptLine, evBroadcast, cmAddFileName, @S);
	  Event.KeyCode := kbBack;
	  PromptLine^.HandleEvent(Event);
	end;
      kbSpace:
	if GetShiftState and kbCtrlShift <> 0 then
	begin
	  GetCurrentPanel;
	  with CurrentPanel^ do
	    if Status = stQuickView then ToggleQuickDescr
	    else Opposite^.ToggleQuickDescr;
	  Event.What := evNothing;
	end
	else if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
	begin
	  GetCurrentPanel;
	  with CurrentPanel^ do if Status < stTree then
	  begin
	    if SelCount = 0 then SelectAll else UnselectAll;
	    DrawView;
	  end;
	  Event.What := evNothing;
	end
{ Changed 04.29.03 to support directory size display on Space keystroke }
	else if (State and sfSearching = 0) and
{         (FMOptions and foSpaceSelects <> 0) and }
	  (PromptLine^.State and sfSelected = 0) and
	  (PromptLine^.Data^ = '') then Event.KeyCode := {kbIns} kbSpaceSel;
    end;
  end;
end;

procedure PanelPerformPrim(FManager: PPanel; Action: TPanelAction);
var
  I, N: Integer;
  SaveOpt: Longint;
  P: PTreeRec;
  SR: PPanelRec;
  S, DS: FNameStr;
begin
  with FManager^ do
  begin
    case Action of
      paToggleUnfold:
	begin
	  if (Settings and seUnfold = 0) and (SelDirCount <> 0) then
	    Settings := Settings or seUnfoldSel
	  else Settings := Settings and not seUnfoldSel;
	  Settings := Settings xor seUnfold;
	  if Status >= stTree then Exit;
	  DS := ListDir^;
	  GetItemStr(Focused, S);
	  if Settings and seUnfold = 0 then
	  begin
	    SR := List^.At(Focused);
	    if (SR <> nil) and (SR^.Name[1] <> '.') then
	      if InArchive then Archiver^.NewArcDir(PrevDir(S))
	      else DS := PrevDir(S);
	  end;
	  SaveOpt := FMOptions;
	  FMOptions := FMOptions and not foResetUnfoldFlag;
	  NewDir(DS, True);
	  FMOptions := SaveOpt;
	  GetItemNum(S, I);
	  FocusItem(I);
	end;
      paGoRight:
	begin
	  if (Status = stTree) and (Focused < Range - 1) then
	  begin
	    I := Focused;
	    if I = 0 then N := -1
	    else N := PTreeRec(TheTree^.At(I))^.Info and $7F;
	    repeat
	      Inc(I);
	      if I = Range then Break;
	      P := TheTree^.At(I);
	      if (P^.Info and $7F < N) or (P^.Info and $7F = N + 2) then Break;
	    until False;
	    if P^.Info and $7F = N + 2 then Dec(I)
	    else I := Focused + 1;
	    if PTreeRec(TheTree^.At(I))^.Info and $7F >= N then FocusItem(I);
	  end
{ Added 05-05-03 to support Name column resize by arrows }
	  else if (Status = stFull) or (Status >= stInfo) then
	    if (Status = stFull) and
	       (GetShiftState and (kbLeftShift + kbRightShift) <> 0) then
	      SetColumnWidthPrim(FManager, ColWidth + 1)
	    else if Indent < DirinfoWidth then
	    begin
	      Inc(Indent);
	      DrawView;
	    end;
	end;
      paGoLeft:
	begin
	  if (Status = stTree) and (Focused > 0) then
	  begin
	    I := Focused;
	    N := PTreeRec(TheTree^.At(I))^.Info and $7F;
	    repeat
	      Dec(I);
	      if (I = 0) or (PTreeRec(TheTree^.At(I))^.Info and $7F < N) then Break;
	    until False;
	    FocusItem(I);
	  end
{ Added 05-05-03 to support Name column resize by arrows }
	  else if (Status = stFull) or (Status >= stInfo) then
	    if (Status = stFull) and
	       (GetShiftState and (kbLeftShift + kbRightShift) <> 0) then
	      SetColumnWidthPrim(FManager, ColWidth - 1)
	    else if Indent > 0 then
	    begin
	      Dec(Indent);
	      DrawView;
	    end;
	end;
      paGoCtrlHome:
	begin
	  if (Status >= stInfo) or
	     ((Status = stFull) and
	      ((Options and ofFilesBBS <> 0) or
	       (Settings and seLongNames <> 0))) then
	  begin
	    Indent := 0;
	    FocusItem(Focused);
	  end
	  else
	  begin
	    if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
	       (Status < stInfo) then
	      for I := TopItem + 1 to Focused do SetSelect(List^.At(I), False);
	    FocusItem(TopItem);
	  end;
	end;
      paGoCtrlEnd:
	begin
	  if (Status >= stInfo) or
	     ((Status = stFull) and
	      ((Options and ofFilesBBS <> 0) or
	       (Settings and seLongNames <> 0))) then
	  begin
	    if Status = stFull then
	    begin
	      I := Size.X;
	      Size.X := 255;
	      Indent := Length(GetText(Focused, 255)) - I + 1;
	      Size.X := I;
	    end
	    else Indent := DirinfoWidth - Size.X + 1;
	    if Indent < 0 then Indent := 0;
	    FocusItem(Focused);
	  end
	  else
	  begin
	    N := TopItem + (Size.Y - Byte(State and sfMiniStatus <> 0) * 2 -
	      Byte(Settings and seMaxi = 0)) * NumCols - 1;
	    if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
	       (Status < stInfo) then
	      for I := Focused to N - 1 do SetSelect(List^.At(I), True);
	    FocusItem(N);
	  end;
	end;
    end;
  end;
end;

procedure SetPanelWindowHintStr(FManager: PPanelWindow; Panel: PPanel;
  var S: String);
var
  B: Byte;
  C: Char;
  I: Integer;
  P: PFilesBBSRec;
  A: TDrivesArray;
  SS: String;
begin
  with FManager^ do
    if (Longint(MouseHintItem) = 1) or (Longint(MouseHintItem) = 2) then
    begin
      if Longint(MouseHintItem) = 1 then LeftPanel^.GetListDir(S)
      else RightPanel^.GetListDir(S);
    end
    else if Longint(MouseHintItem) = 3 then
    begin
      GetDrives(B, A);
      S := '';
      for C := 'A' to 'Z' do
	if A[C] = 1 then
	  if S = '' then S := C
	  else S := S + ' ' + C;
    end
    else if (Panel^.Options and ofFilesBBS <> 0) and
       (GetShiftState and (kbLeftShift + kbRightShift) <> 0) then
    begin
      if MouseHintItem^.Name[1] = ':' then S := 'Drives'
      else
      begin
	I := Panel^.List^.IndexOf(MouseHintItem);
	P := Panel^.FilesBBS^.At(I);
	if (P = nil) or (P^.Text = nil) then S := ''
	else S := P^.Text^;
      end;
    end
    else if Panel^.Options and ofValidate <> 0 then
    begin
      Panel^.GetInfoStr(0, S, False);
      I := Pos('    ', S);
      if I <> 0 then System.Delete(S, I, 3);
      Panel^.GetVolumeTitle(SS, Size.X - Length(S));
      S := S + SS;
      TrimSt(S);
    end
    else
    begin
      if MouseHintItem^.Name = ':' then S := 'Drives'
      else if not Panel^.InArchive and
	(MouseHintItem^.Attr and VolumeID <> 0) then S := 'Quit list'
      else
      begin
	Panel^.GetRecStr(MouseHintItem, S);
	S := JustFileName(S);
	if not Panel^.InArchive and
	  (MouseHintItem^.Attr and Directory <> 0) then S := AddedSlash(S);
      end;
    end;
end;

end.