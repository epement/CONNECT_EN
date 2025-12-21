{$F+,O+,X+}
unit FMDrvSel;

interface

uses Objects, Drivers, Views;

type
  PDriveSelector = ^TDriveSelector;
  TDriveSelector = object(TView)
    Panel: PView;
    Drives: PString;
    Sel: Byte;
    Delta: Byte;
    Wide: Boolean;
    constructor Init(var Bounds: TRect; APanel: PView);
    destructor Done; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure AdjustBounds;
    procedure GetDrives(Default: Char);
  end;

const
  CDrvSelNormal  = 207;
  CDrvSelColored = 208;
  CDrvSelColor   = #$1B#$1E;
  CDrvSelBW      = #$07#$0F;
  CDrvSelMono    = #$07#$0F;

  daLeft = 0;
  daCenter = 1;
  daRight = 2;

  dsDisableDoubleSpacing = 1;

implementation

uses App, FileMngr, FMDialog, FMDrag, FMSecond, DiskBase, DirPrim, DrvList,
  HeapUMB, Commands;

constructor TDriveSelector.Init(var Bounds: TRect; APanel: PView);
var
  R: TRect;
begin
  Inherited Init(Bounds);
  GrowMode := gfGrowLoY + gfGrowHiY;
  EventMask := EventMask or evBroadcast;
  Panel := APanel;
  GetDrives(' ');
  AdjustBounds;
end;

destructor TDriveSelector.Done;
begin
{  DisposeStr(Drives);}
  DisposeStrUMB(Drives);
  Inherited Done;
end;

procedure TDriveSelector.ChangeBounds(var Bounds: TRect);
var
  DoubleSpacing, Alignment: Byte;
  I, L: Integer;
  R: TRect;
begin
  Panel^.GetBounds(R);
  Bounds.A.X := R.A.X + 1;
  Bounds.B.X := R.B.X - 1;
  Bounds.A.Y := R.B.Y;
  Bounds.B.Y := R.B.Y + 1;
  with PPanel(Panel)^ do
  begin
    DoubleSpacing := DrvSelSize;
    Alignment := DrvSelAlignment;
  end;
  Wide := (DoubleSpacing and dsDisableDoubleSpacing = 0) and
    (Length(Drives^) shl 1 + 3 <= Bounds.B.X - Bounds.A.X);
  L := Length(Drives^);
  if Wide then L := L shl 1 + 1;
  Inc(L, 2);
  repeat
    I := Bounds.B.X - Bounds.A.X - L;
    if I <= 0 then Break;
    if Alignment <> daRight then Dec(Bounds.B.X);
    if (Alignment = daRight) or
       ((Alignment = daCenter) and (I > 1)) then Inc(Bounds.A.X);
  until False;
  Inherited ChangeBounds(Bounds);
  Delta := 0;
end;

procedure TDriveSelector.Draw;
var
  Color, C, I: Byte;
  B: TDrawBuffer;
begin
  MoveChar(B, ' ', Byte(Application^.GetPalette^[CDrvSelNormal]), Size.X);
  if State and sfActive = 0 then Color := GetColor(1)
  else if State and sfDragging <> 0 then Color := GetColor(3)
  else Color := GetColor(2);
  MoveChar(B[0], '[', Color, 1);
  MoveChar(B[Size.X - 1], ']', Color, 1);
  for C := Delta + 1 to Length(Drives^) do
  begin
    I := C - Delta;
    if Wide then I := I shl 1;
    if I >= Size.X - 1 then Break;
    Char(B[I]) := Drives^[C];
    if C = Sel then WordRec(B[I]).Hi :=
      Byte(Application^.GetPalette^[CDrvSelColored]);
  end;
  WriteLine(0, 0, Size.X, 1, B);
end;

function TDriveSelector.GetPalette: PPalette;
const
  P: String[3] = #1#2#3;
begin
  GetPalette := @P;
end;

procedure TDriveSelector.HandleEvent(var Event: TEvent);
var
  Esc: Boolean;
  SaveSel, B: Byte;
  Mouse: TPoint;
  S: FNameStr;

procedure AdjustSel;
begin
  while (Delta > 0) and (Sel <= Delta) do Dec(Delta);
  while Sel - Delta >= Size.X - 1 do Inc(Delta);
  DrawView;
end;

procedure NextSel;
begin
  if Sel = Length(Drives^) then Sel := 1 else Inc(Sel);
  AdjustSel;
end;

procedure PrevSel;
begin
  if Sel = 1 then Sel := Length(Drives^) else Dec(Sel);
  AdjustSel;
end;

procedure Press;
var
  C: Char;
begin
  C := Drives^[Sel];
{ Added 2005.09.20 to support '\' in drive selector }
  if C = '\' then
  begin
    C := #0;
    Pending.What := evKeyDown;
    Pending.CharCode := '\';
    SelectDrivePrim(PPanel(Panel), C, True);
    GetDrives(PPanel(Panel)^.ListDir^[1]);
    AdjustBounds;
    AdjustSel;
  end;
  if C = '.' then
  begin
    C := #0;
    DriveListDlg(C);
    if Pending.What = evKeyDown then
    begin
      Pending.What := evNothing;
      C := Pending.CharCode;
    end
    else
    begin
      Sel := SaveSel;
      AdjustSel;
    end;
  end;
  if C in ['A'..'Z'] then
    Message(Panel, evBroadcast, cmSwitchToDir, @C);
end;

begin
  Inherited HandleEvent(Event);
  SaveSel := Sel;
  Esc := False;
  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbCtrlLeft, kbCtrlRight:
	begin
	  repeat
	    if Event.What = evKeyDown then
	      case Event.KeyCode of
		kbCtrlLeft: PrevSel;
		kbCtrlRight: NextSel;
		kbEsc: Esc := True;
	      end;
	    if GetShiftState and kbCtrlShift = 0 then Break;
	    GetEvent(Event);
	  until Esc;
	  if Esc then
	  begin
	    Sel := SaveSel;
	    AdjustSel;
	  end
	  else Press;
	end;
      else Exit;
    end;
    Event.What := evNothing;
  end
  else if (Event.What = evMouseMove) and
    ((GetShiftState and (kbAltShift + kbCtrlShift) =
      kbAltShift + kbCtrlShift) or PPanelWindow(Owner)^.MouseHintVisible) then
	PPanelWindow(Owner)^.DrawView
  else if Event.What = evMouseDown then
  begin
    repeat
      MakeLocal(Event.Where, Mouse);
      if Mouse.X <= 0 then
	if Event.Buttons = mbRightButton then
	begin
	  TogglePanelPrim(PPanelWindow(Owner),
	    PPanelWindow(Owner)^.LeftPanel, tmByF);
	  Exit;
	end
	else if Sel > 1 then PrevSel else
      else if Mouse.X >= Size.X - 1 - Byte(Wide) then
	if Event.Buttons = mbRightButton then
	begin
	  TogglePanelPrim(PPanelWindow(Owner),
	    PPanelWindow(Owner)^.RightPanel, tmByF);
	  Exit;
	end
	else if Sel < Length(Drives^) then NextSel else
      else
      begin
	B := Delta + Mouse.X;
	if Wide then B := (B + 1) shr 1;
	if Sel <> B then
	begin
	  Sel := B;
	  DrawView;
	end;
      end;
    until not MouseEvent(Event, evMouseMove + evMouseAuto);
    if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
      Panel^.Select;
    Press;
  end
  else if (Event.What = evBroadcast) and
    (Event.Command = cmGetDest) and
    (Owner^.State and sfVisible <> 0) and
    MouseInView(PPoint(Event.InfoPtr)^) then
    begin
      MakeLocal(PPoint(Event.InfoPtr)^, Mouse);
      B := Delta + Mouse.X;
      if Wide then B := (B + 1) shr 1;
      Event.What := evNothing;
      if (B <= 0) or (B > Length(Drives^)) or
	not (Drives^[B] in ['A'..'Z']) then
	  if DragWindowInUse then S := '[drive]'
	  else with PPanel(Panel)^ do SelectDriveDialog(
	    'Select ~destination~ drive:', Which, ListDir^[1], S)
      else S := Drives^[B] + ':';
      if S = '' then S := #0 else S := AddedSlash(S);
      Event.InfoPtr := @S;
    end;
end;

procedure TDriveSelector.SetState(AState: Word; Enable: Boolean);
begin
  Inherited SetState(AState, Enable);
  DrawView;
end;

procedure TDriveSelector.AdjustBounds;
var
  R: TRect;
begin
  GetBounds(R);
  Dec(R.A.X);
  Locate(R);
end;

procedure TDriveSelector.GetDrives(Default: Char);
var
  B: Byte;
  C: Char;
  A: TDrivesArray;
  S: String[31];
begin
  DirPrim.GetDrives(B, A);
  S := '';
  for C := 'A' to 'Z' do
    if A[C] = 1 then
    begin
      Inc(S[0]);
      S[Length(S)] := C;
    end;
{ Added 2005.09.20 to support '\' in drive selector }
  Inc(S[0]);
  S[Length(S)] := '\';
  Inc(S[0]);
  S[Length(S)] := '.';

{
  DisposeStr(Drives);
  Drives := NewStr(S);
}
  DisposeStrUMB(Drives);
  Drives := NewStrUMB(S);
  Sel := Pos(Default, Drives^);
  if Sel = 0 then
  begin
    C := DirPrim.GetCurDrive;
    Sel := Pos(C, Drives^);
  end;
end;

end.