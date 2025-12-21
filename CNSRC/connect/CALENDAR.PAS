{************************************************}
{                                                }
{   Turbo Pascal 6.0                             }
{   Turbo Vision Demo                            }
{   Copyright (c) 1990 by Borland International  }
{                                                }
{************************************************}

unit Calendar;

{$F+,O+,X+}

{ Calendar object for viewing a month at a time. See TVDEMO.PAS
  for an example program that uses this unit.
}

interface

uses Drivers, Objects, App, Views, Dos, Dialogs;

type
  PCalendarView = ^TCalendarView;
  TCalendarView = object(TView)
    Year, Month, Days: Word;
    CurYear, CurMonth, CurDay: Word;
    ShowCurrent: Boolean;
    constructor Init(Bounds: TRect);
    constructor Load(var S: TStream);
    function GetHelpCtx: Word; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Draw; virtual;
    procedure Store(var S: TStream);
    function GetColor(Color: Word): Word;
  end;

  PCalendarWindow = ^TCalendarWindow;
  TCalendarWindow = object(TWindow)
    constructor Init;
    constructor Load(var S: TStream);
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

function MonthStr(Month: Byte): String;
function DayStr(Day: Byte): String;
function DayOfWeek(Day, Month, Year: Integer): Integer;
procedure TCalendar;
procedure ExecCalendar;

implementation

uses WinPos, CNWinPos, TPDate, Consts, Defaults;

const
  ModalInUse: Boolean = False;

function MonthStr(Month: Byte): String;
begin
  if CountryCalendar in [csRusHorCal, csRusVerCal] then
  case Month of
    1: MonthStr := 'Январь   ';
    2: MonthStr := 'Февраль  ';
    3: MonthStr := 'Март     ';
    4: MonthStr := 'Апрель   ';
    5: MonthStr := 'Май      ';
    6: MonthStr := 'Июнь     ';
    7: MonthStr := 'Июль     ';
    8: MonthStr := 'Август   ';
    9: MonthStr := 'Сентябрь ';
   10: MonthStr := 'Октябрь  ';
   11: MonthStr := 'Ноябрь   ';
  else MonthStr := 'Декабрь  ';
  end
  else case Month of
    1: MonthStr := 'January  ';
    2: MonthStr := 'February ';
    3: MonthStr := 'March    ';
    4: MonthStr := 'April    ';
    5: MonthStr := 'May      ';
    6: MonthStr := 'June     ';
    7: MonthStr := 'July     ';
    8: MonthStr := 'August   ';
    9: MonthStr := 'September';
   10: MonthStr := 'October  ';
   11: MonthStr := 'November ';
  else MonthStr := 'December ';
  end;
end;

function DayStr(Day: Byte): String;
begin
  if CountryCalendar in [csRusHorCal, csRusVerCal] then
  case Day of
    0: DayStr := 'Понедельник';
    1: DayStr := 'Вторник';
    2: DayStr := 'Среда';
    3: DayStr := 'Четверг';
    4: DayStr := 'Пятница';
    5: DayStr := 'Суббота';
  else DayStr := 'Воскресенье';
  end
  else case Day of
    0: DayStr := 'Sunday';
    1: DayStr := 'Monday';
    2: DayStr := 'Tuesday';
    3: DayStr := 'Wednesday';
    4: DayStr := 'Thursday';
    5: DayStr := 'Friday';
  else DayStr := 'Saturday';
  end;
end;

{ TCalendarWindow }
constructor TCalendarWindow.Init;
var
  R:TRect;
begin
  R.Assign(1, 1, 23, 11);
  TWindow.Init(R, 'Calendar', 0);
  Flags := Flags and not (wfZoom + wfGrow);    { Not resizeable }
  GrowMode := gfExplode;
  Palette := wpCyanWindow;

  GetExtent(R);
  R.Grow(-1, -1);
  Insert(New(PCalendarView, Init(R)));

  WinPos := @CalnWinPos;
end;

constructor TCalendarWindow.Load(var S: TStream);
begin
  TWindow.Load(S);
  WinPos := @CalnWinPos;
end;

procedure TCalendarWindow.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evCommand) and (Event.Command = cmCancel) and
     (State and sfModal <> 0) then
  begin
    EndModal(cmCancel);
    Event.What := evNothing;
  end
  else TWindow.HandleEvent(Event);
end;

{ TCalendarView }
constructor TCalendarView.Init(Bounds: TRect);
var
  H: Word;
begin
  TView.Init(Bounds);
  Options := Options or ofSelectable;
  EventMask := EventMask or evMouseAuto;
  GetDate(CurYear, CurMonth, CurDay, H);
  Year := CurYear;
  Month := CurMonth;
end;

constructor TCalendarView.Load(var S: TStream);
var
  H: Word;
begin
  TView.Load(S);
  GetDate(CurYear, CurMonth, CurDay, H);
  S.Read(Year, SizeOf(Year));
  S.Read(Month, SizeOf(Month));
end;

function TCalendarView.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else GetHelpCtx := hcCalendar;
end;

function DayOfWeek(Day, Month, Year: Integer): Integer;
var
  century, yr, dw: Integer;
begin
  if Month < 3 then
  begin
    Inc(Month, 10);
    Dec(Year);
  end
  else Dec(Month, 2);
  century := Year div 100;
  yr := year mod 100;
  dw := (((26 * month - 2) div 10) + day + yr + (yr div 4) +
    (century div 4) - (2 * century)) mod 7 -
    Byte(CountryCalendar in [csRusHorCal, csRusVerCal]);
  if dw < 0 then Inc(dw, 7);
  DayOfWeek := dw;
end;

procedure TCalendarView.Draw;
const
  Width = 20;
var
  i, j, DayOf, CurDays: Integer;
  B: array[0..Width] of Word;
  Color, TodayColor, WeekendColor: Byte;
  S: String;

function Num2Str(I: Integer): String;
var
  S:String;
begin
  Str(i:2, S);
  Num2Str := S;
end;

begin
  Color:= GetColor(6);
  TodayColor:= GetColor(7);
  WeekendColor:= GetColor(8);
  DayOf := DayOfWeek(1, Month, Year);
  Days := DaysInMonth(Month, Year);
  Str(Year:5, S);
  MoveChar(B, ' ', Color, Width);
  MoveStr(B, MonthStr(Month) + S + ' '#31'  '#30, Color);
  WriteLine(0, 0, Width, 1, B);
  MoveChar(B, ' ', Color, Width);
  if CountryCalendar in [csRusHorCal, csRusVerCal] then
  begin
    MoveStr(B, 'Пн Вт Ср Чт Пт ', Color);
    MoveStr(B[15], 'Сб Вс ', WeekendColor);
  end
  else
  begin
    MoveStr(B, 'Su ', WeekendColor);
    MoveStr(B[3], 'Mo Tu We Th Fr ', Color);
    MoveStr(B[18], 'Sa ', WeekendColor);
  end;
  if CountryCalendar in [csRusVerCal, csEngVerCal] then
    WriteBuf(0, 1, 3, 7, B)
  else WriteLine(0, 1, Width, 1, B);
  CurDays := 1 - DayOf;
  for i := 1 to 6 do
  begin
    MoveChar(B, ' ', Color, Width);
    for j := 0 to 6 do
    begin
      if (CurDays < 1) or (CurDays > Days) then
	MoveStr(B[J * 3], '   ', Color)
      else
	{ if it is the current day }
	if (((Year = CurYear) and (Month = CurMonth)) or
	   ShowCurrent) and (CurDays = CurDay) then
	  MoveStr(B[J * 3], Num2Str(CurDays), TodayColor)
	else if (J = 6) or
	  ((CountryCalendar in [csRusHorCal, csRusVerCal]) and (J = 5)) or
	  ((CountryCalendar in [csEngHorCal, csEngVerCal]) and (J = 0)) then
	    MoveStr(B[J * 3], Num2Str(CurDays), WeekendColor)
	else MoveStr(B[J * 3], Num2Str(CurDays), Color);
      Inc(CurDays);
    end;
    if CountryCalendar in [csRusVerCal, csEngVerCal] then
      WriteBuf(i * 3, 1, 3, 7, B)
    else WriteLine(0, i + 1, Width, 1, B);
  end;
end;

procedure TCalendarView.HandleEvent(var Event: TEvent);
var
  Point: TPoint;
begin
  TView.HandleEvent(Event);
  if (State and sfSelected <> 0) then
  begin
    if Event.What and (evMouseDown + evMouseAuto) <> 0 then
    begin
      MakeLocal(Event.Where, Point);
      if ((Point.X = 15) and (Point.Y = 0)) then
      begin
	Inc(Month);
	if Month > 12 then
	begin
	  Inc(Year);
	  Month := 1;
	end;
	DrawView;
      end
      else if ((Point.X = 18) and (Point.Y = 0)) then
      begin
	Dec(Month);
	if Month < 1 then
	begin
	  Dec(Year);
	  Month := 12;
	end;
	DrawView;
      end;
    end
    else if Event.What = evKeyDown then
    begin
      if (Lo(Event.KeyCode) = Byte('+')) or
	 (Event.KeyCode = kbDown) or
	 (Event.KeyCode = kbCtrlDn) then
      begin
	Inc(Month);
	if Month > 12 then
	begin
	  Inc(Year);
	  Month := 1;
	end;
      end else
      if (Lo(Event.KeyCode) = Byte('-')) or
	 (Event.KeyCode = kbUp) or
	 (Event.KeyCode = kbCtrlUp) then
      begin
	Dec(Month);
	if Month < 1 then
	begin
	  Dec(Year);
	  Month := 12;
	end;
      end else
      case Event.KeyCode of
	kbCtrlLeft: Dec(Year);
	kbCtrlRight: Inc(Year);
	kbSpace:
	  begin
	    GetDate(CurYear, CurMonth, CurDay, Event.InfoWord);
	    Year := CurYear;
	    Month := CurMonth;
	  end;
	kbEsc:
	  begin
	    Pending.What := evCommand;
	    Pending.Command := cmClose;
	    Pending.InfoPtr := Owner;
	  end;
	else Exit;
      end;
      DrawView;
      Event.What := evNothing;
    end;
  end;
end;

procedure TCalendarView.Store(var S: TStream);
begin
  TView.Store(S);
  S.Write(Year, SizeOf(Year));
  S.Write(Month, SizeOf(Month));
end;

function TCalendarView.GetColor(Color: Word): Word;
begin
  GetColor := Byte(Application^.GetPalette^[Byte(Color) + 15]);
end;

procedure TCalendar;
var
  R: TRect;
  P: PCalendarWindow;
begin
  P := New(PCalendarWindow, Init);
  if (WinPosMask and wpCaln <> 0) and ValidWinPos(CalnWinPos) then
  begin
    SetWinPos(Desktop, CalnWinPos, R);
    P^.MoveTo(R.A.X, R.A.Y);
  end;
  Application^.InsertWindow(P);
end;

procedure ExecCalendar;
var
  R: TRect;
  P: PCalendarWindow;
  O: PGroup;
begin
  if ModalInUse then Exit;
  P := New(PCalendarWindow, Init);
  if Application^.ValidView(P) <> nil then
  begin
    ModalInUse := True;
    if Desktop = Pointer(Application^.Current) then O := Desktop
    else O := Application;
    if (WinPosMask and wpCaln <> 0) and ValidWinPos(CalnWinPos) then
    begin
      SetWinPos(O, CalnWinPos, R);
      P^.MoveTo(R.A.X, R.A.Y);
    end
    else if Pointer(O) = Application then
      P^.MoveTo(1, Desktop^.Origin.Y + 2);
    O^.ExecView(P);
    Dispose(P, Done);
    ModalInUse := False;
  end;
end;

end.
