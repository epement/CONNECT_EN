{$F+,O+,X+}
unit MenuBox;

interface

uses Objects, Drivers, Views, Menus;

type
  PMenuBox = ^TMenuBox;
  TMenuBox = object(TMenuView)
    constructor Init(var Bounds: TRect; AMenu: PMenu;
      AParentMenu: PMenuView);
    procedure Draw; virtual;
    procedure GetEvent(var Event: TEvent); virtual;
    procedure GetItemRect(Item: PMenuItem; var R: TRect); virtual;
    function GetMouseShape(var Event: TEvent): Char; virtual;
  end;

  PToggleMenuBox = ^TToggleMenuBox;
  TToggleMenuBox = object(TMenuBox)
    Flags: Pointer;
    constructor Init(var Bounds: TRect; AMenu: PMenu;
      AParentMenu: PMenuView; AFlags: Pointer);
    procedure GetEvent(var Event: TEvent); virtual;
    function GetItemNum(Item: PMenuItem): Integer;
  end;

function NewToggleSubMenu(Name: TMenuStr; AHelpCtx: Word; SubMenu: PMenu;
  Next: PMenuItem; Flags: Pointer): PMenuItem;
function MenuExecute(MenuView: PMenuView): Word;

implementation

procedure MenuMoveCStr(var Dest; const Str: String; Attrs: Word); assembler;
asm
	push	ds
	xor  	dx, dx
	LDS     SI,Str
	CLD
	LODSB
	MOV     CL,AL
	XOR     CH,CH
	JCXZ    @@3
	LES     DI,Dest
	MOV     BX,Attrs
	MOV     AH,BL
@@1:    LODSB
	cmp 	dl, 1
	ja	@@4
	CMP     AL,'~'
	JE      @@2
@@4:    STOSW
	LOOP    @@1
	JMP     @@3
@@2:    inc	dx
	XCHG    AH,BH
	LOOP    @@1
@@3:    pop     ds
end;

function MenuCStrLen(const S: String): Integer; assembler;
asm
        LES     DI,S
        MOV     CL,ES:[DI]
        INC     DI
        XOR     CH,CH
        MOV     BX,CX
        JCXZ    @@2
	MOV     AL,'~'
	xor	dx,dx
	CLD
@@1:    REPNE   SCASB
	JNE     @@2
	DEC     BX
	inc	dx
	cmp	dx,2
	je	@@2
        JMP     @@1
@@2:    MOV     AX,BX
end;

constructor TMenuBox.Init(var Bounds: TRect; AMenu: PMenu;
  AParentMenu: PMenuView);
var
  W, H, L: Integer;
  P: PMenuItem;
  R: TRect;
begin
  W := 10;
  H := 2;
  if AMenu <> nil then
  begin
    P := AMenu^.Items;
    while P <> nil do
    begin
      if P^.Name <> nil then
      begin
	L := MenuCStrLen(P^.Name^) + 6;
	if P^.Command = 0 then Inc(L, 3) else
	  if P^.Param <> nil then Inc(L, MenuCStrLen(P^.Param^) + 2);
	if L > W then W := L;
      end;
      Inc(H);
      P := P^.Next;
    end;
  end;
  R.Copy(Bounds);
  if R.A.X + W < R.B.X then R.B.X := R.A.X + W else R.A.X := R.B.X - W;
  if R.A.Y + H < R.B.Y then R.B.Y := R.A.Y + H else R.A.Y := R.B.Y - H;
  TMenuView.Init(R);
  State := State or sfShadow;
  Options := Options or ofPreProcess;
  Menu := AMenu;
  ParentMenu := AParentMenu;
end;

procedure TMenuBox.Draw;
var
  CNormal, CSelect, CNormDisabled, CSelDisabled, Color: Word;
  Y: Integer;
  P: PMenuItem;
  B: TDrawBuffer;

procedure FrameLine(N: Integer);
const
  FrameChars: Array[0..19] of Char = ' ÚÄ¿  ÀÄÙ  ³ ³  ÃÄ´ ';
begin
  MoveBuf(B[0], FrameChars[N], Byte(CNormal), 2);
  MoveChar(B[2], FrameChars[N + 2], Byte(Color), Size.X - 4);
  MoveBuf(B[Size.X - 2], FrameChars[N + 3], Byte(CNormal), 2);
end;

procedure DrawLine;
begin
  WriteBuf(0, Y, Size.X, 1, B);
  Inc(Y);
end;

begin
  CNormal := GetColor($0301);
  CSelect := GetColor($0604);
  CNormDisabled := GetColor($0202);
  CSelDisabled := GetColor($0505);
  Y := 0;
  Color := CNormal;
  FrameLine(0);
  DrawLine;
  if Menu <> nil then
  begin
    P := Menu^.Items;
    while P <> nil do
    begin
      Color := CNormal;
      if P^.Name = nil then FrameLine(15) else
      begin
        if P^.Disabled then
          if P = Current then
            Color := CSelDisabled else
            Color := CNormDisabled else
          if P = Current then Color := CSelect;
        FrameLine(10);
	MenuMoveCStr(B[3], P^.Name^, Color);
        if P^.Command = 0 then
          MoveChar(B[Size.X - 4], #16, Byte(Color), 1) else
          if P^.Param <> nil then
            MoveStr(B[Size.X - 3 - Length(P^.Param^)],
              P^.Param^, Byte(Color));
      end;
      DrawLine;
      P := P^.Next;
    end;
  end;
  Color := CNormal;
  FrameLine(5);
  DrawLine;
end;

procedure TMenuBox.GetEvent(var Event: TEvent);
var
  ShiftDown: Boolean;
  Delta: Integer;
  Spot: TPoint;
  Bounds: TRect;
begin
  Inherited GetEvent(Event);
  if Event.What = evKeyDown then
  begin
    ShiftDown := GetShiftState and (kbLeftShift + kbRightShift) <> 0;
    if ShiftDown and (Event.KeyCode = kbRight) then
    begin
      GetBounds(Bounds);
      if Bounds.A.X < ScreenWidth - 1 then Bounds.Move(1, 0);
    end
    else if ShiftDown and (Event.KeyCode = kbLeft) then
    begin
      GetBounds(Bounds);
      if Bounds.B.X > 1 then Bounds.Move(-1, 0);
    end
    else if Event.KeyCode = kbCtrlRight then
    begin
      GetBounds(Bounds);
      if Bounds.A.X < ScreenWidth - 8 then Delta := 8
      else Delta := ScreenWidth - Bounds.A.X - 1;
      Bounds.Move(Delta, 0);
    end
    else if Event.KeyCode = kbCtrlLeft then
    begin
      GetBounds(Bounds);
      if Bounds.B.X > 8 then Delta := 8
      else Delta := Bounds.B.X - 1;
      Bounds.Move(-Delta, 0);
    end
    else if (ShiftDown and (Event.KeyCode = kbDown)) or
      (Event.KeyCode = kbCtrlDn) then
    begin
      GetBounds(Bounds);
      if Bounds.A.Y < ScreenHeight - 1 then Bounds.Move(0, 1);
    end
    else if (ShiftDown and (Event.KeyCode = kbUp)) or
      (Event.KeyCode = kbCtrlUp) then
    begin
      GetBounds(Bounds);
      if Bounds.B.Y > 1 then Bounds.Move(0, -1);
    end
    else Exit;
    Locate(Bounds);
    Event.What := evNothing;
  end
  else if (Event.What = evMouseDown) and MouseInView(Event.Where) then
  begin
    MakeLocal(Event.Where, Spot);
    if (Spot.X <= 1) or (Spot.X >= Size.X - 2) or
       (Spot.Y = 0) or (Spot.Y = Size.Y - 1) then
    begin
      Owner^.GetExtent(Bounds);
      DragView(Event, dmDragMove, Bounds, Size, Size);
      Event.What := evNothing;
    end;
  end;
end;

procedure TMenuBox.GetItemRect(Item: PMenuItem; var R: TRect);
var
  Y: Integer;
  P: PMenuItem;
begin
  Y := 1;
  P := Menu^.Items;
  while P <> Item do
  begin
    Inc(Y);
    P := P^.Next;
  end;
  R.Assign(2, Y, Size.X - 2, Y + 1);
end;

function TMenuBox.GetMouseShape(var Event: TEvent): Char;
var
  B: Boolean;
  P: TPoint;
begin
  B := MouseInView(Event.Where);
  MakeLocal(Event.Where, P);
  if B and ((P.X <= 1) or (P.X >= Size.X - 2)) then GetMouseShape := ''
  else if B and ((P.Y = 0) or (P.Y = Size.Y - 1)) then GetMouseShape := ''
  else GetMouseShape := Inherited GetMouseShape(Event);
end;

function NewToggleSubMenu(Name: TMenuStr; AHelpCtx: Word; SubMenu: PMenu;
  Next: PMenuItem; Flags: Pointer): PMenuItem;
var
  P: PMenuItem;
begin
  P := NewSubMenu(Name, AHelpCtx, SubMenu, Next);
  P^.Info := Flags;
  NewToggleSubMenu := P;
end;

constructor TToggleMenuBox.Init(var Bounds: TRect; AMenu: PMenu;
  AParentMenu: PMenuView; AFlags: Pointer);
begin
  TMenuBox.Init(Bounds, AMenu, AParentMenu);
  Flags := AFlags;
end;

procedure TToggleMenuBox.GetEvent(var Event: TEvent);
var
  L: Longint;
begin
  TMenuBox.GetEvent(Event);
  if (Event.What = evKeyDown) and (Event.KeyCode = kbIns) and
     (Current <> nil) and (Current^.Name <> nil) then
  begin
    L := GetItemNum(Current);
    if (L < 0) or (L > 31) then Exit;
    Longint(Flags^) := Longint(Flags^) xor (1 shl L);
    if (Longint(Flags^) and (1 shl L)) = 0 then
      Current^.Name^[1] := 'û'
    else Current^.Name^[1] := ' ';
    Event.KeyCode := kbDown;
  end;
end;

function TToggleMenuBox.GetItemNum(Item: PMenuItem): Integer;
var
  P: PMenuItem;
  I: Integer;
begin
  I := 0;
  P := Menu^.Items;
  while (P <> nil) and (P <> Item) do
  begin
    if P^.Name <> nil then Inc(I);
    P := P^.Next;
  end;
  if P = nil then I := -1;
  GetItemNum := I;
end;

function MenuExecute(MenuView: PMenuView): Word;
type
  MenuAction = (DoNothing, DoSelect, DoReturn);
var
  AutoSelect, RightClick: Boolean;
  Action: MenuAction;
  Ch: Char;
  Result: Word;
  ItemShown, P: PMenuItem;
  Target: PMenuView;
  R: TRect;
  E: TEvent;
  MouseActive: Boolean;

procedure TrackMouse;
var
  Mouse: TPoint;
  R: TRect;
begin
  with MenuView^ do
  begin
    MakeLocal(E.Where, Mouse);
    Current := Menu^.Items;
    while Current <> nil do
    begin
      GetItemRect(Current, R);
      if R.Contains(Mouse) then
      begin
	MouseActive := True;
	Exit;
      end;
      Current := Current^.Next;
    end;
  end;
end;

procedure TrackKey(FindNext: Boolean);

procedure NextItem;
begin
  with MenuView^ do
  begin
    Current := Current^.Next;
    if Current = nil then Current := Menu^.Items;
  end;
end;

procedure PrevItem;
var
  P: PMenuItem;
begin
  with MenuView^ do
  begin
    P := Current;
    if P = Menu^.Items then P := nil;
    repeat NextItem until Current^.Next = P;
  end;
end;

begin
  with MenuView^ do
    if Current <> nil then
    repeat
      if FindNext then NextItem else PrevItem;
    until (Current^.Name <> nil) and (Current^.Name^ <> ' ');
end;

function MouseInOwner: Boolean;
var
  Mouse: TPoint;
  R: TRect;
begin
  with MenuView^ do
  begin
    MouseInOwner := False;
    if (ParentMenu <> nil) and (ParentMenu^.Size.Y = 1) then
    begin
      ParentMenu^.MakeLocal(E.Where, Mouse);
      ParentMenu^.GetItemRect(ParentMenu^.Current, R);
      MouseInOwner := R.Contains(Mouse);
    end;
  end;
end;

function MouseInMenus: Boolean;
var
  P: PMenuView;
begin
  with MenuView^ do
  begin
    P := ParentMenu;
    while (P <> nil) and not P^.MouseInView(E.Where) do
      P := P^.ParentMenu;
    MouseInMenus := P <> nil;
  end;
end;

function TopMenu: PMenuView;
var
  P: PMenuView;
begin
  P := MenuView;
  while P^.ParentMenu <> nil do P := P^.ParentMenu;
  TopMenu := P;
end;

begin
  with MenuView^ do
  begin
    AutoSelect := False;
{ Added 2005.11.17 }
    MenuItemRightClicked := False;
    Result := 0;
    ItemShown := nil;
    Current := Menu^.Default;
    MouseActive := False;
    repeat
      Action := DoNothing;
      GetEvent(E);
      case E.What of
	evMouseDown:
	  if MouseInView(E.Where) or MouseInOwner then
	  begin
	    TrackMouse;
	    if Size.Y = 1 then AutoSelect := True
{ Added 2005.11.17 }
	    else if (E.Buttons = mbRightButton) and
	      (Current <> nil) and (Current^.Name <> nil) then
		MenuItemRightClicked := True;
	  end else Action := DoReturn;
	evMouseUp:
	  begin
	    TrackMouse;
	    if MouseInOwner then Current := Menu^.Default
	    else
	      if (Current <> nil) and (Current^.Name <> nil) then
		Action := DoSelect
	      else if MouseActive or MouseInView(E.Where) then
		Action := DoReturn
	      else
	      begin
		Current := Menu^.Default;
		if Current = nil then Current := Menu^.Items;
		Action := DoNothing;
	      end;
	  end;
	evMouseMove:
	  begin
	    HandleEvent(E);
	    if UpdateMouseShape then {}
	    else if (MouseOptions and moTrackIn <> 0) or
	      (E.Buttons <> 0) then
	    begin
	      TrackMouse;
	      if not (MouseInView(E.Where) or MouseInOwner) and
		MouseInMenus then Action := DoReturn;
	    end;
	  end;
	evKeyDown: if E.KeyCode <> kbNoKey then
	  case CtrlToArrow(E.KeyCode) of
	    kbUp, kbDown:
	      if Size.Y <> 1 then
		TrackKey(CtrlToArrow(E.KeyCode) = kbDown) else
		if E.KeyCode = kbDown then AutoSelect := True;
	    kbLeft, kbRight:
	      if ParentMenu = nil then
		TrackKey(CtrlToArrow(E.KeyCode) = kbRight) else
		Action := DoReturn;
	    kbHome, kbEnd:
	      if Size.Y <> 1 then
	      begin
		Current := Menu^.Items;
		if E.KeyCode = kbEnd then TrackKey(False);
	      end;
	    kbEnter:
	      begin
		if Size.Y = 1 then AutoSelect := True;
		Action := DoSelect;
	      end;
	    kbEsc:
	      begin
		Action := DoReturn;
		if (ParentMenu = nil) or (ParentMenu^.Size.Y <> 1) then
		  E.What := evNothing;
	      end;
	    else
	      begin
		Target := MenuView;
		Ch := GetAltChar(E.KeyCode);
		if Ch = #0 then Ch := E.CharCode else Target := TopMenu;
		P := Target^.FindItem(Ch);
		if P = nil then
		begin
		  P := TopMenu^.HotKey(E.KeyCode);
		  if (P <> nil) and CommandEnabled(P^.Command) then
		  begin
		    Result := P^.Command;
		    Action := DoReturn;
		  end
		end
		else if Target = MenuView then
		begin
		  if Size.Y = 1 then AutoSelect := True;
		  Action := DoSelect;
		  Current := P;
		end
		else if (ParentMenu <> Target) or
		  (ParentMenu^.Current <> P) then Action := DoReturn;
	      end;
	  end;
	evCommand:
	  if E.Command = cmMenu then
	  begin
	    AutoSelect := False;
	    if ParentMenu <> nil then Action := DoReturn;
	  end else Action := DoReturn;
      end;
      if ItemShown <> Current then
      begin
	ItemShown := Current;
	DrawView;
      end;
      if (Action = DoSelect) or ((Action = DoNothing) and AutoSelect) then
	if Current <> nil then with Current^ do if Name <> nil then
	  if Command = 0 then
	  begin
	    if E.What and (evMouseDown + evMouseMove) <> 0 then PutEvent(E);
	    GetItemRect(Current, R);
	    R.A.X := R.A.X + Origin.X;
	    R.A.Y := R.B.Y + Origin.Y;
	    R.B := Owner^.Size;
	    if Size.Y = 1 then Dec(R.A.X);
	    Dec(R.B.Y);
	    Target := TopMenu^.NewSubView(R, SubMenu, MenuView);
	    Result := Owner^.ExecView(Target);
	    Dispose(Target, Done);
	  end else if Action = DoSelect then Result := Command;
      if (Result <> 0) and CommandEnabled(Result) then
      begin
	Action := DoReturn;
	E.What := evNothing;
      end
      else Result := 0;
    until Action = DoReturn;
    if E.What <> evNothing then
      if (ParentMenu <> nil) or (E.What = evCommand) then PutEvent(E);
    if (Current <> nil) and (Current^.Name^ <> ' ') then
    begin
      Menu^.Default := Current;
      Current := nil;
      DrawView;
    end;
  end;
  MenuExecute := Result;
end;

end.
