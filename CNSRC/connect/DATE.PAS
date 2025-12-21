{$I-,O-,X+}
unit Date;

interface

uses Dos, Objects;

type
  TDateTime  = record
    Month, Day, Hour, Min, Sec: Byte;
  end;

  PDate = ^TDate;
  TDate = record
    DateAndTime: TDateTime;
    Message: PString;
    Options: Word;
    Worked: Boolean;
  end;

  PDates = ^TDates;
  TDates = object(TCollection)
    DateCount: Integer;
    FileName: PString;
    destructor Done; virtual;
    procedure FreeItem(Item: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
    procedure ProcessItems;
  end;

const
  DaysInMonth: Array[1..12] of Byte =
    (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

  dtEveryday = 1;
  dtEveryWeek = 2;
  dtOverdue = 4;
  dtDeleteAfter = 8;
  dtAutoClose = $10;
  cmUpdateAlarm = 8080;

var
  Dates: PDates;
  InitPoint: TDateTime;

procedure LoadDates(const FName: FNameStr);
procedure StoreDates;

implementation

uses Drivers, Views, Memory, App, Alarm, HeapUMB, TPString, Defaults;

function TimePassed(P: PDate; Hour, Min, Sec: Word): Boolean;
begin
  TimePassed :=
    (P^.DateAndTime.Hour < Hour) or
    ((P^.DateAndTime.Hour = Hour) and (P^.DateAndTime.Min < Min)) or
    ((P^.DateAndTime.Hour = Hour) and (P^.DateAndTime.Min = Min) and
     (P^.DateAndTime.Sec <= Sec));
end;

function DayPassed(P: PDate; Month, Day, Hour, Min, Sec: Word): Boolean;
begin
  DayPassed :=
    (P^.DateAndTime.Month < Month) or
    ((P^.DateAndTime.Month = Month) and (P^.DateAndTime.Day < Day)) or
    ((P^.DateAndTime.Month = Month) and (P^.DateAndTime.Day = Day) and
      TimePassed(P, Hour, Min, Sec));
end;

procedure SetNextWeek(P: PDate; Month, Day, Hour, Minute, Second: Word);
var
  SafetyCount: Integer;
begin
  SafetyCount := 0;
  while DayPassed(P, Month, Day, Hour, Minute, Second) do
  begin
    Inc(P^.DateAndTime.Day, 7);
    if P^.DateAndTime.Day > DaysInMonth[P^.DateAndTime.Month] then
    begin
      Dec(P^.DateAndTime.Day, DaysInMonth[P^.DateAndTime.Month]);
      if P^.DateAndTime.Month = 12 then P^.DateAndTime.Month := 1
      else Inc(P^.DateAndTime.Month);
    end;
    Inc(SafetyCount);
    if SafetyCount > 365 div 7 then Break;
  end;
end;

procedure SetWorked(var P: PDate);
begin
  if P^.Options and dtEveryday = 0 then
  begin
    if not DayPassed(P, InitPoint.Month, InitPoint.Day,
      InitPoint.Hour, InitPoint.Min, InitPoint.Sec) then P^.Worked := False
    else if (P^.Options and dtEveryWeek <> 0) and
      (P^.Options and dtOverdue = 0) then
    begin
      SetNextWeek(P, InitPoint.Month, InitPoint.Day,
	InitPoint.Hour, InitPoint.Min, InitPoint.Sec);
      P^.Worked := False;
    end
    else P^.Worked := P^.Worked or (P^.Options and dtOverdue = 0);
  end
  else
  begin
    if not TimePassed(P, InitPoint.Hour, InitPoint.Min, InitPoint.Sec) then
      P^.Worked := False
    else P^.Worked :=
      ((InitPoint.Month = P^.DateAndTime.Month) and
      (InitPoint.Day = P^.DateAndTime.Day) and P^.Worked) or
      (P^.Options and dtOverdue = 0);
  end;
end;

destructor TDates.Done;
begin
{  DisposeStr(FileName);}
  DisposeStrUMB(FileName);
  TCollection.Done;
end;

procedure TDates.FreeItem(Item: Pointer);
begin
  if Item <> nil then
  begin
{    DisposeStr(PDate(Item)^.Message);}
    DisposeStrUMB(PDate(Item)^.Message);
    FreeMem(Item, SizeOf(TDate));
  end;
end;

function TDates.GetItem(var S: TStream): Pointer;
var
  P: PDate;
begin
  P := MemAlloc(SizeOf(TDate));
  if P <> nil then
  begin
    S.Read(P^.DateAndTime, SizeOf(TDateTime));
{    P^.Message := S.ReadStr;}
    P^.Message := ReadStrUMB(@S);
    S.Read(P^.Options, SizeOf(Word));
    S.Read(P^.Worked, SizeOf(Boolean));
    SetWorked(P);
  end;
  GetItem := P;
end;

procedure TDates.PutItem(var S: TStream; Item: Pointer);
begin
  S.Write(PDate(Item)^.DateAndTime, SizeOf(TDateTime));
  S.WriteStr(PDate(Item)^.Message);
  S.Write(PDate(Item)^.Options, SizeOf(Word));
  S.Write(PDate(Item)^.Worked, SizeOf(Boolean));
end;

procedure TDates.ProcessItems;
var
  Checked: Boolean;
  Index: Integer;
  Year, Month, Day, DayOfWeek, Hour, Minute, Second, Sec100: Word;
  P: PDate;
begin
  if Dates^.Count <> 1 then
  begin
    Checked := False;
    GetDate(Year, Month, Day, DayOfWeek);
    GetTime(Hour, Minute, Second, Sec100);
    P := At(DateCount);
    if P^.Options and dtEveryday <> 0 then Checked := not (P^.Worked) and
      TimePassed(P, Hour, Minute, Second)
    else Checked := not (P^.Worked) and
      DayPassed(P, Month, Day, Hour, Minute, Second);
    Inc(DateCount);
    if DateCount >= Count - 1 then DateCount := 0;
    if Checked then
    begin
      if DateCount = 0 then Index := Count - 2
      else Index := DateCount - 1;
      P^.Worked := True;
      PlayAlarm(P);
      if P^.Options and dtDeleteAfter <> 0 then AtFree(Index)
      else if P^.Options and dtEveryday <> 0 then
      begin
	P^.DateAndTime.Month := Month;
	P^.DateAndTime.Day := Day;
      end
      else if P^.Options and dtEveryWeek <> 0 then
	SetNextWeek(P, Month, Day, Hour, Minute, Second);
      StoreDates;
      Message(Application, evBroadcast, cmUpdateAlarm, nil);
    end;
  end;
end;

procedure LoadDates(const FName: FNameStr);
var
  Year, Month, Day, DayOfWeek,
  Hour, Minute, Second, Sec100: Word;
  S: TDosStream;
begin
  GetDate(Year, Month, Day, DayOfWeek);
  GetTime(Hour, Minute, Second, Sec100);
  if (Year mod 4 = 0) and (Year mod 4000 <> 0) and
     ((Year mod 100 <> 0) or (Year mod 400 = 0)) then
    DaysInMonth[2] := 29 else DaysInMonth[2] := 28;
  InitPoint.Month := Month;
  InitPoint.Day := Day;
  InitPoint.Hour := Hour;
  InitPoint.Min := Minute;
  InitPoint.Sec := Second;
  S.Init(FName, stOpenRead);
  if S.Status = stOk then
  begin
    Dates := PDates(S.Get);
    if Dates = nil then Dates := New(PDates, Init(4, 4))
  end
  else Dates := New(PDates, Init(4, 4));
  S.Done;
{  Dates^.FileName := NewStr(FName);}
  Dates^.FileName := NewStrUMB(FName);
  Dates^.Insert(nil);
  Dates^.DateCount := 0;
end;

procedure StoreDates;
var
  S: TDosStream;
  F: File;
begin
  if Dates^.Count = 1 then
  begin
    Assign(F, Dates^.FileName^);
    Erase(F);
    InOutRes := 0;
  end
  else
  begin
    Dates^.AtFree(Dates^.Count - 1);
    S.Init(Dates^.FileName^, stCreate);
    S.Put(Dates);
    S.Done;
    Dates^.Insert(nil);
  end;
end;

end.