{************************************************}
{                                                }
{   Turbo Pascal 6.0                             }
{   Turbo Vision Demo                            }
{   Copyright (c) 1990 by Borland International  }
{                                                }
{************************************************}

{$F+,O-}
unit Gauges;

{ Useful gauges: clock and heap available viewer }

interface

uses Dos, Objects, Drivers, Views;

type
  PGaugeView = ^TGaugeView;
  TGaugeView = object(TView)
    Command: Word;
    AltCtrlDown: Boolean;
    ShiftDown: Boolean;
    procedure HandleEvent(var Event: TEvent); virtual;
    function GetMouseShape(var Event: TEvent): Char; virtual;
  end;

  PHeapView = ^THeapView;
  THeapView = object(TGaugeView)
    OldMem: Longint;
    procedure Draw; virtual;
    procedure Update;
  end;

  PClockView = ^TClockView;
  TClockView = object(TGaugeView)
    LastTime: DateTime;
    TimeStr: String[10];
    procedure Draw; virtual;
    procedure Update;
  end;

const
  Heap: PHeapView = nil;
  Clock: PClockView = nil;

  hgHeap = 1;
  hgClock = 2;
  HideGauges: Byte = 0;

  CClockTime    = 244;
  CClockDate    = 245;
  CClockDay     = 246;

  CHeapMem      = 247;
  CHeapMax      = 248;
  CHeapUMB      = 249;

  CClockColor   = #$70#$74#$74;
  CClockBW      = #$70#$7F#$7F;
  CClockMono    = #$70#$7F#$7F;

  CHeapColor    = #$70#$74#$74;
  CHeapBW       = #$70#$7F#$7F;
  CHeapMono     = #$70#$7F#$7F;

function FormatDateStr(Y, M, D: Word): String;
function FormatTimeStr(H, M, S: Word): String;

procedure InitHeap;
procedure InitClock;

function ValidGaugeOrigin(P: TPoint): Boolean;

implementation

uses App, Calendar, HeapUMB, Commands, Defaults;

procedure TGaugeView.HandleEvent(var Event: TEvent);
var
  Limits: TRect;
begin
  TView.HandleEvent(Event);
  if Event.What = evMouseDown then
  begin
    if Event.Double then
    begin
      Pending.What := evCommand;
      Pending.Command := Command;
    end
    else
    begin
      Application^.GetExtent(Limits);
      DragView(Event, dmDragMove, Limits, Size, Size);
    end;
    Event.What := evNothing;
  end;
end;

function TGaugeView.GetMouseShape(var Event: TEvent): Char;
begin
  GetMouseShape := '';
end;

{------ Heap Window object ----------}

procedure THeapView.Draw;
var
  C, D: Byte;
  B: TDrawBuffer;
  S: String;
begin
  if AltCtrlDown then
    if ShiftDown then D := CHeapUMB
    else D := CHeapMax
  else D := CHeapMem;
  C := Byte(Application^.GetPalette^[D]);
  FormatStr(S, '%d', OldMem);
  MoveChar(B, ' ', C, Size.X);
  MoveStr(B, S, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

procedure THeapView.Update;
var
  B, C: Boolean;
  S: Byte;
  L: Longint;
begin
  B := AltCtrlDown;
  S := GetShiftState;
  AltCtrlDown := S and (kbAltShift + kbCtrlShift) = kbAltShift + kbCtrlShift;
  if AltCtrlDown then
  begin
    C := ShiftDown;
    ShiftDown := S and (kbLeftShift + kbRightShift) <> 0;
    if ShiftDown then
{ Added 2004.09.16 to display Stack Pointer when right Shift is down }
      if S and kbRightShift <> 0 then L := SPtr else L := MemAvailUMB
    else L := MaxAvail
  end
  else L := MemAvail;
  if (AltCtrlDown <> B) or
     (AltCtrlDown and (ShiftDown <> C)) or
     (OldMem <> L) then
  begin
    OldMem := L;
    DrawView;
  end;
end;

{-------- ClockView Object --------}

function FormatDateStr(Y, M, D: Word): String;
var
  Params: Array[0..4] of Longint;
  FS: String;
begin
  case CountryDate of
    csMMDDYY:
      begin
	Params[0] := M;
	Params[2] := D;
	Params[4] := Y;
      end;
    csDDMMYY:
      begin
	Params[0] := D;
	Params[2] := M;
	Params[4] := Y;
      end;
    csYYMMDD:
      begin
	Params[0] := Y;
	Params[2] := M;
	Params[4] := D;
      end;
    else
      begin
	Params[0] := Y;
	Params[2] := D;
	Params[4] := M;
      end;
  end;
  Params[1] := Byte(DateSeparator);
  Params[3] := Byte(DateSeparator);
  FormatStr(FS, '%02d%c%02d%c%02d', Params);
  FormatDateStr := FS;
end;

function FormatTimeStr(H, M, S: Word): String;
var
  PM: Boolean;
  Params: Array[0..5] of Longint;
  FS: String;
begin
  Params[0] := H;
  Params[1] := Byte(TimeSeparator);
  Params[2] := M;
  Params[3] := Byte(TimeSeparator);
  Params[4] := S;
  if CountryTime = cs12Hour then
  begin
    PM := Params[0] >= 12;
    Params[0] := Params[0] mod 12;
    if Params[0] = 0 then Params[0] := 12;
    if PM then Params[5] := Byte('p')
    else Params[5] := Byte('a');
  end
  else Params[5] := Byte(' ');
  FormatStr(FS, '%02d%c%02d%c%02d%c', Params);
  FormatTimeStr := FS;
end;

procedure TClockView.Draw;
var
  C, D: Byte;
  B: TDrawBuffer;
begin
  if AltCtrlDown then
    if Odd(LastTime.Hour) then D := CClockDay
    else D := CClockDate
  else D := CClockTime;
  C := Byte(Application^.GetPalette^[D]);
  MoveChar(B, ' ', C, Size.X);
  MoveStr(B, TimeStr, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TClockView.Update;
var
  B: Boolean;
  H, M, S, HS: Word;
begin
  B := AltCtrlDown;
  AltCtrlDown := GetShiftState and (kbAltShift + kbCtrlShift) =
    kbAltShift + kbCtrlShift;
  GetTime(H, M, S, HS);
  with LastTime do if (AltCtrlDown <> B) or (S <> Sec) then
  begin
    if AltCtrlDown then
      if not B then Hour := 0 else Inc(Hour)
    else Hour := H;
    Min := M;
    Sec := S;
    if AltCtrlDown then
    begin
      GetDate(H, M, S, HS);
      if Odd(Hour) then TimeStr := DayStr(DayOfWeek(S, M, H))
      else TimeStr := FormatDateStr(H, M, S);
    end
    else TimeStr := FormatTimeStr(H, M, S);
    DrawView;
  end;
end;

procedure InitHeap;
var
  R: TRect;
begin
  Application^.GetExtent(R);
  R.A.X := R.B.X - 7; R.A.Y := R.B.Y - 1;
  Heap := New(PHeapView, Init(R));
  with Heap^ do
  begin
    GrowMode := gfGrowLoY + gfGrowHiY;
    Command := cmMap;
    Update;
    if HideGauges and hgHeap <> 0 then Hide;
  end;
  Application^.Insert(Heap);
end;

procedure InitClock;
var
  R: TRect;
begin
  Application^.GetExtent(R);
  R.A.X := R.B.X - 9; R.B.Y := R.A.Y + 1;
  Clock := New(PClockView, Init(R));
  with Clock^ do
  begin
    LastTime.Sec := $FF;
    Command := cmAlarm;
    Update;
    if HideGauges and hgClock <> 0 then Hide;
  end;
  Application^.Insert(Clock);
end;

function ValidGaugeOrigin(P: TPoint): Boolean;
begin
  ValidGaugeOrigin := (Longint(P) <> -1) and
    (P.X >= 0) and (P.X < ScreenWidth) and
    (P.Y >= 0) and (P.Y < ScreenHeight);
end;

end.