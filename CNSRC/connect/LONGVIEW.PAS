{$F+,O+,X+}
unit LongView;

interface

uses Objects, Drivers, Views;

type
  PLongScrollBar = ^TLongScrollBar;
  TLongScrollBar = object(TView)
    Value: Longint;
    Min: Longint;
    Max: Longint;
    PgStep: Longint;
    ArStep: Longint;
    constructor Init(var Bounds: TRect);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure ScrollDraw; {virtual;}
    function ScrollStep(Part: Integer): Longint; {virtual;}
    procedure SetParams(AValue, AMin, AMax, APgStep, AArStep: Longint);
    procedure SetRange(AMin, AMax: Longint);
    procedure SetStep(APgStep, AArStep: Longint);
    procedure SetValue(AValue: Longint);
    procedure Store(var S: TStream);
  private
    Chars: TScrollChars;
    procedure DrawPos(Pos: Integer);
    function GetPos: Integer;
    function GetSize: Integer;
  end;

  PLongListViewer = ^TLongListViewer;
  TLongListViewer = object(TView)
    HScrollBar: PScrollBar;
    VScrollBar: PLongScrollBar;
    NumCols: Integer;
    TopItem: Longint;
    Focused: Longint;
    Range: Longint;
    constructor Init(var Bounds: TRect; ANumCols: Word;
      AHScrollBar: PScrollBar; AVScrollBar: PLongScrollBar);
    constructor Load(var S: TStream);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure CopyText; { Added 08.03.95 }
    procedure Draw; virtual;
    procedure FocusItem(Item: Longint); virtual;
    function GetPalette: PPalette; virtual;
    function GetCopyText(Item: Longint; MaxLen: Integer): String; virtual; { Added 08.03.95 }
    function GetText(Item: Longint; MaxLen: Integer): String; virtual;
    function IsSelected(Item: Longint): Boolean; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SelectItem(Item: Longint); virtual;
    procedure SetRange(ARange: Longint);
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
  private
    procedure FocusItemNum(Item: Longint); {virtual;}
  end;

const
  CLongListViewer = #26#26#27#28#29;

implementation

uses Dialogs, Defaults;

constructor TLongScrollBar.Init(var Bounds: TRect);
const
  VChars: TScrollChars = (#30, #31, #177, #254, #178);
  HChars: TScrollChars = (#17, #16, #177, #254, #178);
begin
  TView.Init(Bounds);
  Value := 0;
  Min := 0;
  Max := 0;
  PgStep := 1;
  ArStep := 1;
  if Size.X = 1 then
  begin
    GrowMode := gfGrowLoX + gfGrowHiX + gfGrowHiY;
    Chars := VChars;
  end else
  begin
    GrowMode := gfGrowLoY + gfGrowHiX + gfGrowHiY;
    Chars := HChars;
  end;
end;

constructor TLongScrollBar.Load(var S: TStream);
begin
  TView.Load(S);
  S.Read(Value, SizeOf(Longint) * 5 + SizeOf(TScrollChars));
end;

procedure TLongScrollBar.Draw;
begin
  DrawPos(GetPos);
end;

procedure TLongScrollBar.DrawPos(Pos: Integer);
var
  S: Integer;
  B: TDrawBuffer;
begin
  S := GetSize - 1;
  MoveChar(B[0], Chars[0], GetColor(2), 1);
  if Max = Min then
    MoveChar(B[1], Chars[4], GetColor(1), S - 1)
  else
  begin
    MoveChar(B[1], Chars[2], GetColor(1), S - 1);
    MoveChar(B[Pos], Chars[3], GetColor(3), 1);
  end;
  MoveChar(B[S], Chars[1], GetColor(2), 1);
  WriteBuf(0, 0, Size.X, Size.Y, B);
end;

function TLongScrollBar.GetPalette: PPalette;
const
  P: String[Length(CScrollBar)] = CScrollBar;
begin
  GetPalette := @P;
end;

function TLongScrollBar.GetPos: Integer;
var
  R: Longint;
begin
  R := Max - Min;
  if R = 0 then GetPos := 1
  else GetPos := ((Value - Min) * (GetSize - 3) + R shr 1) div R + 1;
end;

function TLongScrollBar.GetSize: Integer;
var
  S: Integer;
begin
  if Size.X = 1 then S := Size.Y else S := Size.X;
  if S < 3 then GetSize := 3 else GetSize := S;
end;

procedure TLongScrollBar.HandleEvent(var Event: TEvent);
var
  Tracking: Boolean;
  I, SaveValue: Longint;
  P, S, ClickPart: Integer;
  Mouse: TPoint;
  Extent: TRect;

function GetPartCode: Integer;
var
  Mark, Part: Integer;
begin
  Part := -1;
  if Extent.Contains(Mouse) then
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
  Message(Owner, evBroadcast, cmScrollBarClicked, @Self);
end;

begin
  TView.HandleEvent(Event);
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
                SetValue(((P - 1) * (Max - Min) + S shr 1) div S + Min);
                Inc(S, 2);
              end; {Added 08.28.97 to support immediate text tracking}
            end;
          until not MouseEvent(Event, evMouseMove);

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

procedure TLongScrollBar.ScrollDraw;
begin
  Message(Owner, evBroadcast, cmScrollBarChanged, @Self);
end;

function TLongScrollBar.ScrollStep(Part: Integer): Longint;
var
  Step: Longint;
begin
  if Part and 2 = 0 then Step := ArStep else Step := PgStep;
  if Part and 1 = 0 then ScrollStep := -Step else ScrollStep := Step;
end;

procedure TLongScrollBar.SetParams(AValue, AMin, AMax, APgStep,
  AArStep: Longint);
var
  SValue: Longint;
begin
  if AMax < AMin then AMax := AMin;
  if AValue < AMin then AValue := AMin;
  if AValue > AMax then AValue := AMax;
  SValue := Value;
  if (SValue <> AValue) or (Min <> AMin) or (Max <> AMax) then
  begin
    Value := AValue;
    Min := AMin;
    Max := AMax;
    DrawView;
    if SValue <> AValue then ScrollDraw;
  end;
  PgStep := APgStep;
  ArStep := AArStep;
end;

procedure TLongScrollBar.SetRange(AMin, AMax: Longint);
begin
  SetParams(Value, AMin, AMax, PgStep, ArStep);
end;

procedure TLongScrollBar.SetStep(APgStep, AArStep: Longint);
begin
  SetParams(Value, Min, Max, APgStep, AArStep);
end;

procedure TLongScrollBar.SetValue(AValue: Longint);
begin
  SetParams(AValue, Min, Max, PgStep, ArStep);
end;

procedure TLongScrollBar.Store(var S: TStream);
begin
  TView.Store(S);
  S.Write(Value, SizeOf(Longint) * 5 + SizeOf(TScrollChars));
end;

constructor TLongListViewer.Init(var Bounds: TRect; ANumCols: Word;
  AHScrollBar: PScrollBar; AVScrollBar: PLongScrollBar);
var
  ArStep, PgStep: Longint;
begin
  TView.Init(Bounds);
  Options := Options or (ofFirstClick + ofSelectable);
  EventMask := EventMask or evBroadcast;
  NumCols := ANumCols;
  if AVScrollBar <> nil then
  begin
    if NumCols = 1 then
    begin
      PgStep := Size.Y - 1;
      ArStep := 1;
    end else
    begin
      PgStep := Size.Y * NumCols;
      ArStep := Size.Y;
    end;
    AVScrollBar^.SetStep(PgStep, ArStep);
  end;
  if AHScrollBar <> nil then AHScrollBar^.SetStep(Size.X div NumCols, 1);
  HScrollBar := AHScrollBar;
  VScrollBar := AVScrollBar;
end;

constructor TLongListViewer.Load(var S: TStream);
begin
  TView.Load(S);
  GetPeerViewPtr(S, HScrollBar);
  GetPeerViewPtr(S, VScrollBar);
  S.Read(NumCols, SizeOf(Integer) + SizeOf(Longint) * 4);
end;

procedure TLongListViewer.ChangeBounds(var Bounds: TRect);
begin
  TView.ChangeBounds(Bounds);
  if HScrollBar <> nil then
    HScrollBar^.SetStep(Size.X div NumCols, HScrollBar^.ArStep);
  if VScrollBar <> nil then
    VScrollBar^.SetStep(Size.Y, VScrollBar^.ArStep);
end;

procedure TLongListViewer.CopyText;
var
  P: PView;
  S: String;
begin
  if Owner = nil then Exit;
  S := GetCopyText(Focused, Size.X);
  if S = '' then Exit;
  P := Owner;
  while P^.Owner <> nil do P := P^.Owner;
  Message(P, evBroadcast, cmCopy, @S);
end;

procedure TLongListViewer.Draw;
var
  SCOff: Byte;
  NormalColor, SelectedColor, FocusedColor, Color: Word;
  I, J, ColWidth, CurCol, Indent: Integer;
  Item: Longint;
  B: TDrawBuffer;
begin
  if State and (sfSelected + sfActive) = (sfSelected + sfActive) then
  begin
    NormalColor := GetColor(1);
    FocusedColor := GetColor(3);
    SelectedColor := GetColor(4);
  end else
  begin
    NormalColor := GetColor(2);
    SelectedColor := GetColor(4);
  end;
  if HScrollBar <> nil then Indent := HScrollBar^.Value + 1
  else Indent := 0;
  ColWidth := Size.X div NumCols + 1;
  for I := 0 to Size.Y - 1 do
  begin
    for J := 0 to NumCols-1 do
    begin
      Item := J*Size.Y + I + TopItem;
      CurCol := J*ColWidth;
      if (State and (sfSelected + sfActive) = (sfSelected + sfActive)) and
        (Focused = Item) and (Range > 0) then
      begin
        Color := FocusedColor;
        SetCursor(CurCol+1,I);
        SCOff := 0;
      end
      else if (Item < Range) and IsSelected(Item) then
      begin
        Color := SelectedColor;
        SCOff := 2;
      end
      else
      begin
        Color := NormalColor;
        SCOff := 4;
      end;
      MoveChar(B[CurCol], ' ', Color, ColWidth);
      if Item < Range then
      begin
        MoveStr(B[CurCol+1],
          Copy(GetText(Item, ColWidth + Indent), Indent, ColWidth), Color);
        if ShowMarkers then
        begin
          Char(B[CurCol]) := SpecialChars[SCOff];
          Char(B[CurCol+ColWidth-2]) := SpecialChars[SCOff+1];
        end;
      end;
      MoveChar(B[CurCol+ColWidth-1], #179, GetColor(5), 1);
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure TLongListViewer.FocusItem(Item: Longint);
begin
  Focused := Item;
  if VScrollBar <> nil then VScrollBar^.SetValue(Item);
  if Item < TopItem then
    if NumCols = 1 then TopItem := Item
    else TopItem := Item - Item mod Size.Y
  else if Item >= TopItem + (Size.Y * NumCols) then
    if NumCols = 1 then TopItem := Item - Size.Y + 1
    else TopItem := Item - Item mod Size.Y - (Size.Y * (NumCols - 1));
end;

procedure TLongListViewer.FocusItemNum(Item: Longint);
var
  SaveMask: Word;
begin
  if Item < 0 then Item := 0
  else if (Item >= Range) and (Range > 0) then Item := Range - 1;
  if Range <> 0 then
  begin { Fixed 11.10.93 }
    SaveMask := EventMask;
    EventMask := EventMask and not evBroadcast;
    FocusItem(Item);
    EventMask := SaveMask;
  end;
  DrawView;
end;

function TLongListViewer.GetPalette: PPalette;
const
  P: String[Length(CLongListViewer)] = CLongListViewer;
begin
  GetPalette := @P;
end;

function TLongListViewer.GetCopyText(Item: Longint; MaxLen: Integer): String;
begin
  GetCopyText := GetText(Item, MaxLen);
end;

function TLongListViewer.GetText(Item: Longint; MaxLen: Integer): String;
begin
  Abstract;
end;

function TLongListViewer.IsSelected(Item: Longint): Boolean;
begin
  IsSelected := Item = Focused;
end;

procedure TLongListViewer.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  ColWidth: Word;
  OldItem, NewItem: Longint;
begin
  if Event.What = evKeyDown then
    if (Event.KeyCode = kbCtrlHome) or (Event.KeyCode = kbCtrlEnd) or
       (Event.KeyCode = kbCtrlPgUp) or (Event.KeyCode = kbCtrlPgDn) or
       (Event.CharCode in WordStarChars) then
      ConvertWSKey(WordStarKeys, Event);
  TView.HandleEvent(Event);
  if Event.What = evMouseDown then
  begin
    ColWidth := Size.X div NumCols + 1;
    OldItem := Focused;
    MakeLocal(Event.Where, Mouse);
    if MouseInView(Event.Where) then
      NewItem := Mouse.Y + (Size.Y * (Mouse.X div ColWidth)) + TopItem
    else NewItem := OldItem;
    repeat
      if NewItem <> OldItem then FocusItemNum(NewItem);
      OldItem := NewItem;
      MakeLocal(Event.Where, Mouse);
      if MouseInView(Event.Where) then
        NewItem := Mouse.Y + (Size.Y * (Mouse.X div ColWidth)) + TopItem
      else
      begin
        if NumCols = 1 then
        begin
          if Event.What = evMouseAuto then
          begin
            if Mouse.Y < 0 then NewItem := Focused-1
            else if Mouse.Y >= Size.Y then NewItem := Focused+1;
          end;
        end
        else
        begin
          if Event.What = evMouseAuto then
          begin
            if Mouse.X < 0 then NewItem := Focused-Size.Y
            else if Mouse.X >= Size.X then NewItem := Focused+Size.Y
            else if Mouse.Y < 0 then
              NewItem := Focused - Focused mod Size.Y
            else if Mouse.Y > Size.Y then
              NewItem := Focused - Focused mod Size.Y + Size.Y - 1;
          end
        end;
      end;
    until not MouseEvent(Event, evMouseMove + evMouseAuto);
    FocusItemNum(NewItem);
    if Event.Double and (Range > Focused) then SelectItem(Focused);
    Event.What := evNothing;
  end
  else if Event.What = evKeyDown then
  begin
    if (Event.CharCode = ' ') and (Focused < Range) then
    begin
      SelectItem(Focused);
      NewItem := Focused;
    end
    else case CtrlToArrow(Event.KeyCode) of
      kbUp: NewItem := Focused - 1;
      kbDown: NewItem := Focused + 1;
      kbRight: if NumCols > 1 then NewItem := Focused + Size.Y else Exit;
      kbLeft: if NumCols > 1 then NewItem := Focused - Size.Y else Exit;
      kbPgDn: NewItem := Focused + Size.Y * NumCols;
      kbPgUp: NewItem := Focused - Size.Y * NumCols;
      kbCtrlHome: NewItem := TopItem;
      kbCtrlEnd: NewItem := TopItem + (Size.Y * NumCols) - 1;
      kbCtrlPgDn: NewItem := Range - 1;
      kbCtrlPgUp: NewItem := 0;
      kbCtrlIns: { Added 08.03.95 }
        begin
          CopyText;
          Event.What := evNothing;
          Exit;
        end;
    else
      Exit;
    end;
    FocusItemNum(NewItem);
    Event.What := evNothing;
  end else if (Event.What = evCommand) and (Event.Command = cmCopy) then
  begin  { Added 08.29.96 }
    CopyText;
    Event.What := evNothing;
  end else if Event.What = evBroadcast then
    if Options and ofSelectable <> 0 then
      if (Event.Command = cmScrollBarClicked) and
         ((Event.InfoPtr = HScrollBar) or (Event.InfoPtr = VScrollBar)) then
        Select
      else if (Event.Command = cmScrollBarChanged) then
      begin
        if (VScrollBar = Event.InfoPtr) then
          FocusItemNum(VScrollBar^.Value)
        else if (HScrollBar = Event.InfoPtr) then DrawView;
      end;
end;

procedure TLongListViewer.SelectItem(Item: Longint);
begin
  Message(Owner, evBroadcast, cmListItemSelected, @Self);
end;

procedure TLongListViewer.SetRange(ARange: Longint);
begin
  Range := ARange;
  if VScrollBar <> nil then
  begin
    if Focused > ARange then Focused := {0} ARange; { Fixed 12.08.94 }
    VScrollbar^.SetParams(Focused, 0, ARange-1, VScrollBar^.PgStep,
      VScrollBar^.ArStep);
  end;
end;

procedure TLongListViewer.SetState(AState: Word; Enable: Boolean);

procedure ShowSBar(SBar: PScrollBar);
begin
  if (SBar <> nil) then
    if GetState(sfActive) and GetState(sfVisible) then SBar^.Show
    else SBar^.Hide;
end;

begin
  TView.SetState(AState, Enable);
  if AState and (sfSelected + sfActive + sfVisible) <> 0 then
  begin
    ShowSBar(HScrollBar);
    ShowSBar(PScrollBar(VScrollBar));
    if Enable and (State and sfExposed <> 0) then
      FocusItemNum(Focused)
    else DrawView;
  end;
end;

procedure TLongListViewer.Store(var S: TStream);
begin
  TView.Store(S);
  PutPeerViewPtr(S, HScrollBar);
  PutPeerViewPtr(S, VScrollBar);
  S.Write(NumCols, SizeOf(Integer) + SizeOf(Longint) * 4);
end;

end.