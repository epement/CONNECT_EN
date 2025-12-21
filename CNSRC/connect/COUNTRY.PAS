{$I-,X+,O+,F+}
unit Country;

interface

uses Objects, Drivers, Views, Dialogs;

type
  TCountryData = record
    Date, Time: Word;
    DateSep, TimeSep, ThouSep: String[1];
    Calendar, UseDOSInfo: Word;
  end;

  PCountryDialog = ^TCountryDialog;
  TCountryDialog = object(TDialog)
    DateClusters: PRadioButtons;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure CountryDlg;

implementation

uses Dos, App, DosCase, UserScr, TPString, Consts, Commands, Defaults;

procedure TCountryDialog.HandleEvent(var Event: TEvent);

var
  UpdateSep: Boolean;
  C: Char;
  PS: PString;
  Data: TCountryData;

procedure UpdateButtons;
var
  I: Integer;
begin
  GetData(Data);
  if Data.DateSep = '' then C := ' '
  else C := Data.DateSep[1];
  with DateClusters^.Strings do
    for I := 0 to Count - 1 do
    begin
      PS := At(I);
      PS^[3] := C;
      PS^[6] := C;
    end;
  DateClusters^.DrawView;
end;

begin
  UpdateSep := Event.What = evKeyDown;
  Inherited HandleEvent(Event);
  if UpdateSep then UpdateButtons;
end;

procedure CountryDlg;
var
  DateSep, TimeSep: Char;
  ThouSep: String[3];
  D: PCountryDialog;
  Control: PView;
  R: TRect;
  Data: TCountryData;
  Info: TCountryInfo;
  DateStr, TimeStr: String[15];
begin
  if Lo(DosVersion) >= 3 then GetCountrySpecificInfo(Info)
  else FillChar(Info, SizeOf(TCountryInfo), 0);
  case Info.DateFormat of
    0: DateStr := 'mmddyy';
    1: DateStr := 'ddmmyy';
    2: DateStr := 'yymmdd';
  else DateStr := 'yyddmm';
  end;
  if Info.TimeFormat and 1 <> 0 then TimeStr := '24-hour clock'
  else TimeStr := '12-hour clock';
  DateSep := Info.DateSeparator[0];
  TimeSep := Info.TimeSeparator[0];
  if Info.ThousandsSeparator[0] = #0 then ThouSep := 'No'
  else ThouSep := '(' + Info.ThousandsSeparator[0] + ')';
  Insert(DateSep, DateStr, 5);
  Insert(DateSep, DateStr, 3);

  R.Assign(0, 0, 55, 23);
  D := New(PCountryDialog, Init(R, 'Country settings'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcOCountry;

    R.Assign(3, 3, 26, 7);
    DateClusters := New(PRadioButtons, Init(R,
      NewSItem('mm-dd-yy (~U~SA)',
      NewSItem('dd-mm-yy (~E~urope)',
      NewSItem('yy-mm-dd (~J~apan)',
      NewSItem('yy-dd-mm (~O~ther)', nil))))));
    Insert(DateClusters);
    R.Assign(2, 2, 26, 3);
    Insert(New(PLabel, Init(R, 'Date format', DateClusters)));

    R.Assign(28, 3, 52, 5);
    Control := New(PRadioButtons, Init(R,
      NewSItem('1~2~-hour clock',
      NewSItem('2~4~-hour clock', nil))));
    Insert(Control);
    R.Assign(27, 2, 52, 3);
    Insert(New(PLabel, Init(R, 'Time format', Control)));

    R.Assign(23, 8, 26, 9);
    Control := New(PInputLine, Init(R, 1));
    Insert(Control);
    R.Assign(7, 8, 23, 9);
    Insert(New(PLabel, Init(R, '~D~ate separator', Control)));

    R.Assign(23, 9, 26, 10);
    Control := New(PInputLine, Init(R, 1));
    Insert(Control);
    R.Assign(7, 9, 23, 10);
    Insert(New(PLabel, Init(R, '~T~ime separator', Control)));

    R.Assign(23, 10, 26, 11);
    Control := New(PInputLine, Init(R, 1));
    Insert(Control);
    R.Assign(2, 10, 23, 11);
    Insert(New(PLabel, Init(R, 'T~h~ousands separator', Control)));

    R.Assign(28, 7, 52, 11);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~R~ussian horizontal',
      NewSItem('Russian ~v~ertical',
      NewSItem('English hori~z~ontal',
      NewSItem('En~g~lish vertical', nil))))));
    Insert(Control);
    R.Assign(27, 6, 52, 7);
    Insert(New(PLabel, Init(R, 'Calendar type', Control)));

    R.Assign(3, 13, 52, 19);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('D~a~te format' + LeftPad('(' + DateStr + ')', 32),
      NewSItem('T~i~me format' + LeftPad('(' + TimeStr + ')', 32),
      NewSItem('Date ~s~eparator' + LeftPad('(' + DateSep + ')', 29),
      NewSItem('Time se~p~arator' + LeftPad('(' + TimeSep + ')', 29),
      NewSItem('Thousa~n~ds separator' + LeftPad(ThouSep, 24),
      NewSItem('Upper~c~ase/lowercase character map', nil))))))));
    Insert(Control);
    R.Assign(2, 12, 52, 13);
    Insert(New(PLabel, Init(R,
      'Use DOS country-specific information', Control)));

    StandardButtonRow(D, True);
  end;
  with Data do
  begin
    Date := CountryDate;
    Time := CountryTime;
    Calendar := CountryCalendar;
    DateSep := DateSeparator;
    TimeSep := TimeSeparator;
    if ThousandsSeparator = #0 then ThouSep := ''
    else ThouSep := ThousandsSeparator;
    UseDOSInfo := UseDOSCountryInfo;
  end;
  Pending.What := evKeyDown;
  Pending.KeyCode := 0;
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  with Data do
  begin
    CountryDate := Date;
    CountryTime := Time;
    CountryCalendar := Calendar;
    if DateSep = '' then DateSeparator := ' '
    else DateSeparator := DateSep[1];
    if TimeSep = '' then TimeSeparator := ' '
    else TimeSeparator := TimeSep[1];
    if ThouSep = '' then ThousandsSeparator := #0
    else ThousandsSeparator := ThouSep[1];
    UseDOSCountryInfo := UseDOSInfo;
    if UseDOSCountryInfo and
      (ciDate + ciTime + ciDateSep + ciTimeSep + ciThouSep +
       ciCharMap) <> 0 then SetCountrySpecificInfo
    else SetAltCase;
    RefreshDisplay;
    Message(Application, evBroadcast, cmCountry, nil);
  end;
end;

end.
