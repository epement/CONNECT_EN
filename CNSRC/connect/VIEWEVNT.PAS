{$F+,O+,X+}
unit ViewEvnt;

interface

uses Objects, Drivers, Views;

procedure ViewDragView(View: PView; Event: TEvent; Mode: Byte;
  var Limits: TRect; MinSize, MaxSize: TPoint);
procedure FrameHandleMouse(Frame: PFrame; var Event: TEvent);
function FrameGetMouseShape(Frame: PFrame; var Event: TEvent): Char;
procedure ScrollBarHandleKeyMouse(Bar: PScrollBar; var Event: TEvent);

implementation

uses UserScr, CNWinPos;

procedure ViewDragView(View: PView; Event: TEvent; Mode: Byte;
  var Limits: TRect; MinSize, MaxSize: TPoint);
var
  O, P, S: TPoint;
  SaveBounds: TRect;

function Min(I, J: Integer): Integer;
begin
  if I < J then Min := I else Min := J;
end;

function Max(I, J: Integer): Integer;
begin
  if I > J then Max := I else Max := J;
end;

procedure MoveGrow(P, S: TPoint);
var
  R: TRect;
begin
  S.X := Min(Max(S.X, MinSize.X), MaxSize.X);
  S.Y := Min(Max(S.Y, MinSize.Y), MaxSize.Y);
  P.X := Min(Max(P.X, Limits.A.X - S.X + 1), Limits.B.X - 1);
  P.Y := Min(Max(P.Y, Limits.A.Y - S.Y + 1), Limits.B.Y - 1);
  if Mode and dmLimitLoX <> 0 then P.X := Max(P.X, Limits.A.X);
  if Mode and dmLimitLoY <> 0 then P.Y := Max(P.Y, Limits.A.Y);
  if Mode and dmLimitHiX <> 0 then P.X := Min(P.X, Limits.B.X - S.X);
  if Mode and dmLimitHiY <> 0 then P.Y := Min(P.Y, Limits.B.Y - S.Y);
  R.Assign(P.X, P.Y, P.X + S.X, P.Y + S.Y);
  View^.Locate(R);
end;

procedure Change(DX, DY: Integer);
begin
  if (Mode and dmDragMove <> 0) and (GetShiftState and $03 = 0) then
  begin
    Inc(P.X, DX);
    Inc(P.Y, DY);
  end else
  if (Mode and dmDragGrow <> 0) and (GetShiftState and $03 <> 0) then
  begin
    Inc(S.X, DX);
    Inc(S.Y, DY);
  end;
end;

procedure Update(X, Y: Integer);
begin
  if Mode and dmDragMove <> 0 then
  begin
    P.X := X;
    P.Y := Y;
  end;
end;

begin
  with View^ do
  begin
    SetState(sfDragging, True);
    if Event.What = evMouseDown then
    begin
      if Mode and dmDragMove <> 0 then
      begin
        P.X := Origin.X - Event.Where.X;
        P.Y := Origin.Y - Event.Where.Y;
        repeat
          Inc(Event.Where.X, P.X);
          Inc(Event.Where.Y, P.Y);
          MoveGrow(Event.Where, Size);
        until not MouseEvent(Event, evMouseMove);
      end else if Mode and dmLimitLoX <> 0 then
      begin
        Mode := Mode and not dmLimitLoX;
        P.X := Origin.X + Size.X;
        P.Y := Origin.Y + Size.Y;
        repeat
          Owner^.MakeLocal(Event.Where, S);
          if S.X < 0 then S.X := 0;
          if S.X < P.X - MaxSize.X then S.X := P.X - MaxSize.X;
          if S.X > P.X - MinSize.X then S.X := P.X - MinSize.X;
          if S.Y < 0 then S.Y := 0;
          if S.Y < P.Y - MaxSize.Y then S.Y := P.Y - MaxSize.Y;
          if S.Y > P.Y - MinSize.Y then S.Y := P.Y - MinSize.Y;
          O.X := P.X - S.X;
          O.Y := P.Y - S.Y;
          MoveGrow(S, O);
        until not MouseEvent(Event, evMouseMove);
      end else if Mode and dmLimitHiX <> 0 then
      begin
        Mode := Mode and not dmLimitHiX;
        P.X := Origin.X;
        P.Y := Origin.Y + Size.Y;
        repeat
          Owner^.MakeLocal(Event.Where, S);
          S.X := P.X;
          if S.Y < 0 then S.Y := 0;
          if S.Y < P.Y - MaxSize.Y then S.Y := P.Y - MaxSize.Y;
          if S.Y > P.Y - MinSize.Y then S.Y := P.Y - MinSize.Y;
          Owner^.MakeLocal(Event.Where, O);
          if O.X < P.X + MinSize.X - 1 then O.X := P.X + MinSize.X - 1;
          if O.X > P.X + MaxSize.X then O.X := P.X + MaxSize.X;
          if O.Y < P.Y - MaxSize.Y then O.Y := P.Y - MaxSize.Y;
          if O.Y > P.Y - MinSize.Y then O.Y := P.Y - MinSize.Y;
          O.X := O.X - P.X + 1;
          O.Y := P.Y - S.Y;
          MoveGrow(S, O);
        until not MouseEvent(Event, evMouseMove);
      end else if Mode and dmLimitHiY <> 0 then
      begin
        Mode := Mode and not dmLimitHiY;
        P.X := Origin.X + Size.X;
        P.Y := Origin.Y;
        repeat
          Owner^.MakeLocal(Event.Where, S);
          if S.X < 0 then S.X := 0;
          if S.X < P.X - MaxSize.X then S.X := P.X - MaxSize.X;
          if S.X > P.X - MinSize.X then S.X := P.X - MinSize.X;
          S.Y := P.Y;
          Owner^.MakeLocal(Event.Where, O);
          if O.X < 0 then O.X := 0;
          if O.X < P.X - MaxSize.X then O.X := P.X - MaxSize.X;
          if O.X > P.X - MinSize.X then O.X := P.X - MinSize.X;
          if O.Y < P.Y + MinSize.Y - 1 then O.Y := P.Y + MinSize.Y - 1;
          if O.Y > P.Y + MaxSize.Y then O.Y := P.Y + MaxSize.Y;
          O.X := P.X - O.X;
          O.Y := O.Y - P.Y + 1;
          MoveGrow(S, O);
        until not MouseEvent(Event, evMouseMove);
      end else
      begin
        P.X := Size.X - Event.Where.X;
        P.Y := Size.Y - Event.Where.Y;
        repeat
          Inc(Event.Where.X, P.X);
          Inc(Event.Where.Y, P.Y);
          MoveGrow(Origin, Event.Where);
        until not MouseEvent(Event, evMouseMove);
      end;
    end else
    begin
      GetBounds(SaveBounds);
      repeat
        P := Origin;
        S := Size;
        KeyEvent(Event);
        case Event.KeyCode and $FF00 of
          kbLeft: Change(-1, 0);
          kbRight: Change(1, 0);
          kbUp: Change(0, -1);
          kbDown: Change(0, 1);
          kbCtrlLeft: Change(-8, 0);
          kbCtrlRight: Change(8, 0);
          kbHome: Update(Limits.A.X, P.Y);
          kbEnd: Update(Limits.B.X - S.X, P.Y);
          kbPgUp: Update(P.X, Limits.A.Y);
          kbPgDn: Update(P.X, Limits.B.Y - S.Y);
        end;
        MoveGrow(P, S);
      until (Event.KeyCode = kbEnter) or (Event.KeyCode = kbEsc);
      if Event.KeyCode = kbEsc then Locate(SaveBounds);
    end;
    SetState(sfDragging, False);
  end;
end;

procedure FrameHandleMouse(Frame: PFrame; var Event: TEvent);
var
  ZoomIcon, MiniIcon: Boolean;
  MouseButton: Byte;
  Mouse: TPoint;

procedure DragWindow(Mode: Byte);
var
  Limits: TRect;
  Min, Max: TPoint;
begin
  with Frame^ do
  begin
    Owner^.Owner^.GetExtent(Limits);
    Owner^.SizeLimits(Min, Max);
    Owner^.DragView(Event, Owner^.DragMode or Mode, Limits, Min, Max);
    Event.What := evNothing;
  end;
end;

procedure DrawCloseIconState(Contains: Boolean);
var
  C: Byte;
  B: TDrawBuffer;
begin
  with Frame^ do
  begin
    C := GetColor(5);
    if Contains then
      if MiniIcon and (MouseButtons = mbRightButton) and
        (WinPosMask and wpIcons <> 0) then MoveChar(B, '^', C, 1)
      else MoveChar(B, '', C, 1)
    else MoveChar(B, 'þ', C, 1);
    WriteLine(2, 0, 1, 1, B);
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
        if Mouse.X >= Size.X - 3 then C2 := '' else C1 := '_'
      else
        if Mouse.X >= Size.X - 3 then C2 := '' else C1 := '';
    MoveChar(B, C1, C, 1);
    MoveChar(B[1], C2, C, 1);
    WriteLine(Size.X - 4, 0, 2, 1, B);
  end;
end;

procedure DrawZoomIconState(Contains: Boolean);
var
  C: Char;
  B: TDrawBuffer;
begin
  with Frame^ do
  begin
    if Contains then
      if (MouseButtons = mbRightButton) and
         (WinPosMask and wpIcons <> 0) then C := '_'
      else C := ''
    else if Longint(Owner^.Size) = Longint(Owner^.Owner^.Size) then
      C := ''
    else C := '';
    MoveChar(B, C, GetColor(5), 1);
    WriteLine(Size.X - 3, 0, 1, 1, B);
  end;
end;

procedure DrawMiniIconState(Contains: Boolean);
var
  C: Char;
  B: TDrawBuffer;
begin
  with Frame^ do
  begin
    if Contains then
      if (MouseButtons = mbRightButton) and
         (WinPosMask and wpIcons <> 0) then C := ''
      else C := ''
    else C := '';
    MoveChar(B, C, GetColor(5), 1);
    WriteLine(Size.X - 3, 0, 1, 1, B);
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
      if MouseButtons = mbRightButton then C := ''
      else if WinPosMask and wpLeftClickCloses <> 0 then C := ''
      else if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
        C := #27
      else C := #26
    else if (PWindow(Owner)^.Number <> wnNoNumber) and
      (PWindow(Owner)^.Number < 10) then
        C := Char(PWindow(Owner)^.Number + $30)
    else C := wnNoNumberChar;
    MoveChar(B, C, GetColor(5), 1);
    WriteLine(3, 0, 1, 1, B);
  end;
end;

begin
  with Frame^ do if State and sfActive <> 0 then
  begin
    MakeLocal(Event.Where, Mouse);
{ Added 04.01.09 to display User Screen on right click }
    if ((Mouse.X = 0) or (Mouse.X = Size.X - 1)) and
       (Mouse.Y > 0) and (Mouse.Y < Size.Y - 1) and
       (Event.Buttons = mbRightButton) and
       (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
    begin
      Event.What := evNothing;
      UserScreen;
      Exit;
    end;

    if Mouse.Y = 0 then
    begin
      ZoomIcon := PWindow(Owner)^.Flags and wfZoom <> 0;
      MiniIcon := (Owner^.State and sfModal = 0) and
        (Owner^.Options and ofSelectable <> 0);
{ Added 04.02.18 to toggle between windows by clicking on window number }
      if MiniIcon and (PWindow(Owner)^.Flags and wfClose <> 0) and
         (WinPosMask and wpIcons <> 0) and
         (Mouse.X >= 3) and (Mouse.X <= 4) then
      begin
        repeat
          MakeLocal(Event.Where, Mouse);
          DrawNumberIconState((Mouse.Y = 0) and
            (Mouse.X >= 3) and (Mouse.X <= 4));
          MouseButton := MouseButtons;
        until not MouseEvent(Event, evMouseMove);
        DrawView;
        if (Mouse.Y = 0) and (Mouse.X >= 3) and (Mouse.X <= 4) then
        begin
          Event.What := evCommand;
          if MouseButton = mbRightButton then
          begin
            Event.What := evKeyDown;
            Event.KeyCode := kbPgUp;
          end
          else
          begin
            if WinPosMask and wpLeftClickCloses <> 0 then
              Event.Command := cmClose
            else if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
              Event.Command := cmNext
            else Event.Command := cmPrev;
            Event.InfoPtr := Owner;
          end;
          PutEvent(Event);
        end;
        Event.What := evNothing;
      end else
      if (Mouse.X >= 1) and (Mouse.X <= 3) and
         (PWindow(Owner)^.Flags and wfClose <> 0) then
      begin
        repeat
          MakeLocal(Event.Where, Mouse);
          DrawCloseIconState(
            (Mouse.Y = 0) and (Mouse.X >= 1) and (Mouse.X <= 3));
          MouseButton := MouseButtons;
        until not MouseEvent(Event, evMouseMove);
        DrawCloseIconState(False);
        if (Mouse.Y = 0) and (Mouse.X >= 1) and (Mouse.X <= 3) then
        begin
          if MiniIcon and (MouseButton = mbRightButton) and
            (WinPosMask and wpIcons <> 0) then
          begin
            Event.What := evKeyDown;
            Event.KeyCode := kbCtrlPgUp;
          end
          else
          begin
            Event.What := evCommand;
            Event.Command := cmClose;
            Event.InfoPtr := Owner;
          end;
          PutEvent(Event);
        end;
        Event.What := evNothing;
      end else
      if (ZoomIcon or MiniIcon) and
         ((Event.Double and (Event.Buttons = mbLeftButton)) or
          ((Mouse.X >= Size.X - 4 - Byte(ZoomIcon and MiniIcon)) and
          (Mouse.X <= Size.X - 2))) then
      begin
        if not (Event.Double and (Event.Buttons = mbLeftButton)) then
        repeat
          MakeLocal(Event.Where, Mouse);
          if ZoomIcon and MiniIcon then DrawZoomMiniIconState(
            (Mouse.Y = 0) and (Mouse.X >= Size.X - 5) and
            (Mouse.X <= Size.X - 2))
          else if ZoomIcon then DrawZoomIconState(
            (Mouse.Y = 0) and (Mouse.X >= Size.X - 4) and
            (Mouse.X <= Size.X - 2))
          else DrawMiniIconState(
            (Mouse.Y = 0) and (Mouse.X >= Size.X - 4) and
            (Mouse.X <= Size.X - 2));
          MouseButton := MouseButtons;
        until not MouseEvent(Event, evMouseMove);
        if ZoomIcon and MiniIcon then DrawZoomMiniIconState(False)
        else if ZoomIcon then DrawZoomIconState(False)
        else DrawMiniIconState(False);
        if (Event.Double and (Event.Buttons = mbLeftButton)) or
           ((Mouse.Y = 0) and
           (Mouse.X >= Size.X - 4 - Byte(ZoomIcon and MiniIcon)) and
           (Mouse.X <= Size.X - 2)) then
        begin
          if (MouseButton = mbRightButton) and
             (WinPosMask and wpIcons <> 0) then
          begin
            Event.What := evKeyDown;
            if MiniIcon and (Mouse.X >= Size.X - 4 + Byte(ZoomIcon)) then
              Event.KeyCode := kbPgDn
            else Event.KeyCode := kbCtrlPgDn;
          end
          else
          begin
            if MiniIcon and (Mouse.X >= Size.X - 4 + Byte(ZoomIcon)) then
            begin { Added 07.31.96 to support iconizable windows }
              Event.What := evKeyDown;
              Event.KeyCode := kbAltM;
            end
            else
            begin
              Event.What := evCommand;
              Event.Command := cmZoom;
              Event.InfoPtr := Owner;
            end;
          end;
          PutEvent(Event);
        end;
        Event.What := evNothing;
      end else
      if (PWindow(Owner)^.Flags and wfGrow <> 0) and
         (Mouse.X = 0) then
        DragWindow(dmDragGrow or dmLimitLoX) else
      if (PWindow(Owner)^.Flags and wfGrow <> 0) and
         (Mouse.X = Size.X - 1) then
        DragWindow(dmDragGrow or dmLimitHiX) else
      if PWindow(Owner)^.Flags and wfMove <> 0 then
        DragWindow(dmDragMove);
    end else
    if Mouse.Y >= Size.Y - 1 then
      if (PWindow(Owner)^.Flags and wfGrow <> 0) and (Mouse.X = 0) then
        DragWindow(dmDragGrow or dmLimitHiY) else
      if (PWindow(Owner)^.Flags and wfGrow <> 0) and
         (Mouse.X >= Size.X - 2) then
        DragWindow(dmDragGrow) else
      if PWindow(Owner)^.Flags and wfMove <> 0 then
        DragWindow(dmDragMove) else else
    if (PWindow(Owner)^.Flags and wfMove <> 0) and
      ((Mouse.X = 0) or (Mouse.X = Size.X - 1)) then
        DragWindow(dmDragMove);
  end;
end;

function FrameGetMouseShape(Frame: PFrame; var Event: TEvent): Char;
var
  C: Char;
  CloseIcon, ZoomIcon, MiniIcon, GrowIcon: Boolean;
  P: TPoint;
begin
  C := #0;
  with Frame^ do
  if (State and sfActive <> 0) and
     (Owner^.State and sfFocused <> 0) and
     (PWindow(Owner)^.Flags and wfMove <> 0) then
  begin
    CloseIcon := PWindow(Owner)^.Flags and wfClose <> 0;
    ZoomIcon := PWindow(Owner)^.Flags and wfZoom <> 0;
    MiniIcon := (Owner^.State and sfModal = 0) and
      (Owner^.Options and ofSelectable <> 0);
    GrowIcon := PWindow(Owner)^.Flags and wfGrow <> 0;
    MakeLocal(Event.Where, P);
    if (P.X > 0) and (P.X < Size.X - 1) and
       (P.Y > 0) and (P.Y < Size.Y - 1) then
    else if P.Y = 0 then
{ Added 04.02.18 to toggle between windows by clicking on window number }
      if (CloseIcon and MiniIcon and (P.X >= 1) and (P.X <= 4)) or
         (CloseIcon and (P.X >= 1) and (P.X <= 3)) or
         (ZoomIcon and MiniIcon and
           (P.X >= Size.X - 5) and (P.X <= Size.X - 2)) or
         (ZoomIcon and not MiniIcon and
           (P.X >= Size.X - 4) and (P.X <= Size.X - 2)) or
         (not ZoomIcon and MiniIcon and
           (P.X >= Size.X - 4) and (P.X <= Size.X - 2)) then
      else if (P.X = 0) or (P.X = Size.X - 1) then C := ''
      else C := ''
    else if P.Y = Size.Y - 1 then
      if (P.X = 0) or (P.X >= Size.X - 1 - Byte(GrowIcon)) then C := ''
      else C := ''
    else C := '';
  end;
  FrameGetMouseShape := C;
end;

procedure ScrollBarHandleKeyMouse(Bar: PScrollBar; var Event: TEvent);
var
  Tracking: Boolean;
  I, P, S, ClickPart, SaveValue: Integer;
  Mouse: TPoint;
  Extent: TRect;

function GetPartCode: Integer;
var
  Mark, Part: Integer;
begin
  Part := -1;
  if Extent.Contains(Mouse) then with Bar^ do
  begin
    if Size.X = 1 then Mark := Mouse.Y else Mark := Mouse.X;
    if Mark = P then Part := sbIndicator else
    begin
      if Mark < 1 then Part := sbLeftArrow else
        if Mark < P then Part := sbPageLeft else
          if Mark < S then Part := sbPageRight else
            Part := sbRightArrow;
      if Size.X = 1 then Inc(Part, 4);
    end;
  end;
  GetPartCode := Part;
end;

procedure Clicked;
begin
  Message(Bar^.Owner, evBroadcast, cmScrollBarClicked, Bar);
end;

begin
  with Bar^ do
  case Event.What of
    evMouseDown:
      begin
        Clicked;
        MakeLocal(Event.Where, Mouse);
        GetExtent(Extent);
        Extent.Grow(1, 1);
        P := GetPos;
        S := GetSize - 1;
        ClickPart := GetPartCode;
        if ClickPart <> sbIndicator then
        begin
          repeat
            MakeLocal(Event.Where, Mouse);
            if GetPartCode = ClickPart then
            begin
              if Options and ofBuffered <> 0 then       { Fixed 05.10.95 }
                Options := Options or ofTileable;       { to support smooth redraw }
{ Added 04.07.31 to support Home/End right clicks }
              if (Event.Buttons = mbRightButton) and
                 ((ClickPart = sbLeftArrow) or
                  (ClickPart = sbUpArrow)) then SetValue(Min)
              else if (Event.Buttons = mbRightButton) and
                 ((ClickPart = sbRightArrow) or
                  (ClickPart = sbDownArrow)) then SetValue(Max)
              else SetValue(Value + ScrollStep(ClickPart));
            end;
          until not MouseEvent(Event, evMouseAuto);
        end else
        begin
          SaveValue := Value;
          repeat
            MakeLocal(Event.Where, Mouse);
            Tracking := Extent.Contains(Mouse);
            if Tracking then
            begin
              if Size.X = 1 then I := Mouse.Y else I := Mouse.X;
              if I <= 0 then I := 1;
              if I >= S then I := S - 1;
            end else I := GetPos;
            if I <> P then
            begin
              {DrawPos(I);} {Removed 11.20.97}
              P := I;

              if Tracking and (S > 2) then
              begin
                Dec(S, 2);
                SetValue(LongDiv(LongMul(
                  P - 1, Max - Min) + S shr 1, S) + Min);
                Inc(S, 2);
              end; {Added 08.28.97 to support immediate text tracking}
            end;
          until not MouseEvent(Event, evMouseMove);
{
          if Tracking and (S > 2) then
          begin
            Dec(S, 2);
            SetValue(LongDiv(LongMul(P - 1, Max - Min) + S shr 1, S) + Min);
          end;
}
          if not Tracking then SetValue(SaveValue); {Fixed 08.28.97}
        end;
        Event.What := evNothing;
      end;
    evKeyDown:
      if (State and sfVisible <> 0) or MultiScrolling then
      begin
        ClickPart := sbIndicator;
        if (Size.Y = 1) and (Size.X <> 1) then
          case CtrlToArrow(Event.KeyCode) of
            kbLeft: ClickPart := sbLeftArrow;
            kbRight: ClickPart := sbRightArrow;
            kbCtrlLeft: ClickPart := sbPageLeft;
            kbCtrlRight: ClickPart := sbPageRight;
            kbHome: I := Min;
            kbEnd: I := Max;
          else
            Exit;
          end
        else
          case CtrlToArrow(Event.KeyCode) of
            kbUp: ClickPart := sbUpArrow;
            kbDown: ClickPart := sbDownArrow;
            kbPgUp: ClickPart := sbPageUp;
            kbPgDn: ClickPart := sbPageDown;
            kbCtrlPgUp: I := Min;
            kbCtrlPgDn: I := Max;
          else
            Exit;
          end;
        Clicked;
        if ClickPart <> sbIndicator then I := Value + ScrollStep(ClickPart);
        SetValue(I);
        Event.What := evNothing;
      end;
  end;
end;

end.