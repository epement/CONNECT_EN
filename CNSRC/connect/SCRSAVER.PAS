{$X+,F+,O+}
unit ScrSaver;

interface

uses Objects, Drivers, Views;

type
  PSky = ^TSky;
  TSky = object(TView)
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
  end;

  PStar = ^TStar;
  TStar = object(TView)
    Index: Byte;
    constructor Init;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure Update(DoShoot: Boolean);
  private
    SaveTicks: Word;
    Skip: Byte;
    Shooting: Boolean;
  end;

  PScreenSaver = ^TScreenSaver;
  TScreenSaver = object(TGroup)
    Sky: PView;
    NumStars: Byte;
    SaveTicks: Word;
    constructor Init(var Bounds: TRect);
    destructor Done; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

const
  MaxStars = 6;
  Stars: Array[1..MaxStars] of Char = ('ú', 'ù', '', '', 'þ', '');
  MaxNumStars: Byte = 50;

  CSky                   = #1;
  CStar                  = #2#3#4#5#6#7;
  CScreenSaverColor      = #$08#$0B#$0E#$0D#$0C#$0A#$0F;
  CScreenSaverBlackWhite = #$08#$0F#$0F#$0F#$0F#$0F#$0F;
  CScreenSaverMonochrome = #$08#$0F#$0F#$0F#$0F#$0F#$0F;
  CScreenSaver           = #152#153#154#155#156#157#158;

procedure DrawScreenSaver;

implementation

uses CNCrt, App, Desktops, DosTools, RGBDlg, Defaults;

var
  Ticks: Word absolute $40:$6C;

procedure TSky.Draw;
var
  B: TDrawBuffer;
begin
  MoveChar(B, ' ', GetColor(1), Size.X);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

function TSky.GetPalette: PPalette;
const
  P: String[Length(CSky)] = CSky;
begin
  GetPalette := @P;
end;

constructor TStar.Init;
var
  R: TRect;
  B: Byte;
begin
  R.A.X := Random(ScreenWidth);
  R.A.Y := Random(ScreenHeight);
  R.B.X := R.A.X + 1;
  R.B.Y := R.A.Y + 1;
  TView.Init(R);
  B := Random(MaxNumStars);
  if B = 0 then Index := 3
  else if B = 1 then Index := 2
  else Index := 1;
  SaveTicks := Ticks;
end;

procedure TStar.Draw;
var
  B: TDrawBuffer;
begin
  WordRec(B[0]).Hi := GetColor(Index);
  Char(B[0]) := Stars[Index];
  WriteLine(0, 0, 1, 1, B);
end;

function TStar.GetPalette: PPalette;
const
  P: String[Length(CStar)] = CStar;
begin
  GetPalette := @P;
end;

procedure TStar.Update(DoShoot: Boolean);
begin
  if SaveTicks = Ticks then Exit;
  SaveTicks := Ticks;
  if Shooting then
  begin
    if (Index < MaxStars) and
       (Owner^.Size.Y - Origin.Y - 1 <= MaxStars - Index) then
     Inc(Index);
    MoveTo(Origin.X, Origin.Y + 1);
    Shooting := Origin.Y + 1 < Owner^.Size.Y;
    Exit;
  end;
  Inc(Skip);
  if Skip = 1 then Exit;
  Skip := 0;
  if DoShoot then Shooting := True
  else if (Index = 2) and (Random(MaxStars) <> 0) then
    Index := MaxStars + 1
  else Inc(Index);
  if Index <= MaxStars then DrawView;
end;

constructor TScreenSaver.Init(var Bounds: TRect);
begin
  TGroup.Init(Bounds);
  Options := Options and not ofSelectable;
  State := State or sfFocused;
  GrowMode := gfExplode;
  Sky := New(PSky, Init(Bounds));
  Sky^.Options := Sky^.Options or ofSelectable;
  Insert(Sky);
  SaveTicks := Ticks;
  Randomize;
  HideMouse;
end;

destructor TScreenSaver.Done;
begin
  UpdateMouseShape := True;
  ShowMouse;
  IdleSeconds := 0;
  ScreenSaver := nil;
  Sky^.Options := Sky^.Options and not ofSelectable;
  TGroup.Done;
  Application^.DrawView;
end;

procedure TScreenSaver.HandleEvent(var Event: TEvent);
var
  P, Q: PStar;
begin
  if (@Self = Application^.First) and
     ((Event.What and (PositionalEvents + FocusedEvents) <> 0) or
      (GetShiftState and (kbLeftShift + kbRightShift +
       kbAltShift + kbCtrlShift) <> 0)) then
  begin
    Event.What := evNothing;
    Free;
  end
  else
  begin
    if WordRec(Ticks).Hi = 0 then MaxNumStars := 250
    else if WordRec(Ticks).Hi = 128 then MaxNumStars := 5
    else MaxNumStars := 50;
    if NumStars >= MaxNumStars then
    begin
      P := PStar(Sky^.Prev);
      Q := PStar(P^.Prev);
      P^.Update(P^.Shooting or (Byte(Ticks) = 0));
      Q^.Update(not P^.Shooting and (Byte(Ticks) = 0));
      if P^.Index > MaxStars then
      begin
	Dispose(P, Done);
	Dec(NumStars);
      end;
      if Q^.Index > MaxStars then
      begin
	Dispose(Q, Done);
	Dec(NumStars);
      end;
    end;
    if (NumStars >= MaxNumStars) or (SaveTicks = Ticks) then Exit;
    SaveTicks := Ticks;
    Insert(New(PStar, Init));
    Inc(NumStars);
    if OS2Installed and
      (TimeSliceType and (ttInt28 + ttInt2F) <> 0) then
asm
	MOV	AX,55
	MOV	DX,0
	HLT
	DB 	35H,0CAH
end;
  end;
end;

function TScreenSaver.GetPalette: PPalette;
const
  P: String[Length(CScreenSaver)] = CScreenSaver;
begin
  GetPalette := @P;
end;

procedure DrawScreenSaver;
var
  HotSpot {, DoDie}: Boolean;
  Count: Byte;
  SaveTicks: Word;
  R: TRect;
  Event: TEvent;

{
function GetTickCount: Longint;
var
  B: Byte;
  L: Longint;
begin
  L := 0;
  B := Mem[$40:$6C];
  repeat until (B <> Mem[$40:$6C]) or KeyPressed;
  B := Mem[$40:$6C];
  repeat
    Inc(L);
  until (B <> Mem[$40:$6C]) or KeyPressed;
  if KeyPressed then L := 0;
  GetTickCount := L;
end;
}

begin
  if (ScreenSaver <> nil) or
     ((MouseWhere.Y = ScreenHeight - 1) and
      (DesktopData^.SaverDelay <> '') and
      (DesktopData^.SaverDelay[1] <> '+')) then Exit;
  Count := 0;
  repeat
    Application^.GetEvent(Event);
    if Event.What <> evNothing then
    begin
      SetMouseShape(#0);
      Exit;
    end;
    if Ticks <> SaveTicks then
    begin
      SaveTicks := Ticks;
      Inc(Count);
      if Count < MaxStars then SetMouseShape(Stars[Count + 1]);
    end;
  until Count > 8;
{  DoDie := GetTickCount > $1D0;
  if DoDie then} FadeRGB;
  Application^.GetExtent(R);
  New(PScreenSaver(ScreenSaver), Init(R));
  Application^.Insert(Application^.ValidView(PGroup(ScreenSaver)));
  {if DoDie then} RestoreRGB;
end;

end.
