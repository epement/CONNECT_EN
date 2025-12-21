{$I-,X+,O+,F+}
unit Alarm;

interface

uses Objects, Drivers, Views, Dialogs, Date, Calendar, CNInputs;

type
  PAlarmCalendar = ^TAlarmCalendar;
  TAlarmCalendar = object(TCalendarView)
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PInputMonth = ^TInputMonth;
  TInputMonth = object(TCInputLine)
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PInputDay = ^TInputDay;
  TInputDay = object(TCInputLine)
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PAlarmList = ^TAlarmList;
  TAlarmList = object(TListViewer)
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure NewItem;
    procedure ModifyItem;
    procedure DeleteItem;
    procedure NewItemPos;
    procedure Update;
  end;

  PAlarmDialog = ^TAlarmDialog;
  TAlarmDialog = object(TDialog)
    AlarmList: PAlarmList;
    constructor Init;
    constructor Load(var S: TStream);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
  end;

procedure PlayAlarm(P: PDate);
procedure RSRAlarmDialog(RSR: PResourceFile);
procedure AlarmDialog;

implementation

uses Dos, Memory, App, Gauges, MsgBox, EditMsg, ProgList, ExecPrim,
  HistList, History, KeyName, HeapUMB, Timer, TPString, Consts,
  Commands, Defaults;

procedure PlayAlarm(P: PDate);
var
  W: Word;
  Code: Integer;
  Item: PExecItem;
  V: PView;
  Stream: TDosStream;
  S: String;
begin
  if P^.Message = nil then S := 'Alarm !'
  else S := P^.Message^;
  if (S <> '') and (S[1] = '>') then
  begin
    V := Desktop^.Current;
    if (V <> nil) and (V^.State and sfModal <> 0) then
    begin
      if not DisableSounds then Write(^G);
      if MessageBox(
	^C'Cannot execute user program while a modal window is active. ' +
	'Cancel all dialogs and run the program ?',
	nil, mfConfirmation + mfYesNo) <> cmYes then Exit;
      repeat
	V^.EndModal(cmCancel);
	V := V^.Next;
      until (V = nil) or (V^.State and sfModal = 0);
    end;
    Delete(S, 1, 1);
    TrimSt(S);    
    Stream.Init(S, stOpenRead);
    Item := PExecItem(Stream.Get);
    Stream.Done;
    if Item <> nil then
    begin
      Item^.GetData(ExecRec, W);
      Dispose(Item, Done);
      PrepareExecEvent;
    end
    else InvalidProgFileMsgBox(S);
  end
  else if (S[0] = #5) and (S[1] = '$') then
  begin
    Val(S, W, Code);
    Message(Application, evCommand, cmMacro, nil);
    Message(Application, evKeyDown, W, nil);
  end
  else
  begin
    if not DisableSounds then Write(^G);
    if P^.Options and dtAutoClose <> 0 then
      InitTimer(50, evCommand, cmOk, True);
    MessageBox(S, nil, mfWarning + mfOkButton);
  end;
end;

procedure UpdateCommands;
begin
  with Application^ do
  begin
    EnableCommands(NewCommands);
    if Dates^.Count > 1 then
      EnableCommands(ModifyCommands + DeleteCommands + NewItemPosCommands)
    else DisableCommands(ModifyCommands + DeleteCommands + NewItemPosCommands);
  end;
end;

function FormatItemStr(Item: Pointer): String;
var
  Y, W: Word;
  DS, TS: String[15];
begin
  with PDate(Item)^.DateAndTime do
  begin
    if PDate(Item)^.Options and dtEveryday <> 0 then DS := 'Every day'
    else
    begin
      GetDate(Y, W, W, W);
      DS := ' ' + FormatDateStr(Y, Month, Day);
    end;
    TS := FormatTimeStr(Hour, Min, Sec);
  end;
  FormatItemStr := DS + ' at ' + TS;
end;

procedure TAlarmCalendar.HandleEvent(var Event: TEvent);
const
  kbUpKey = $FF00;
  kbDnKey = $FF01;
var
  SpaceHit, Vert: Boolean;
  OldMonth, OldYear: Word;
  NewCur: Integer;
  Point: TPoint;
begin
  SpaceHit := False;
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbUp: Event.KeyCode := kbUpKey;
      kbDown: Event.KeyCode := kbDnKey;
      kbSpace: SpaceHit := True;
    end;
  OldMonth := Month;
  OldYear := Year;
  TCalendarView.HandleEvent(Event);
  if not SpaceHit and ((Month <> OldMonth) or (Year <> OldYear)) then
  begin
    CurDay := 1;
    DrawView;
  end;
  if State and sfSelected <> 0 then
  begin
    Vert := CountryCalendar in [csRusVerCal, csEngVerCal];
    if (Event.What = evMouseDown) and MouseInView(Event.Where) then
    begin
      MakeLocal(Event.Where, Point);
      if (Vert and (Point.X > 2) and (Point.Y > 0)) or
	 (not Vert and (Point.Y > 1)) then
      begin
	if CountryCalendar in [csRusVerCal, csEngVerCal] then
	  NewCur := ((Point.X - 3) div 3) * 7 + Point.Y -
	    DayOfWeek(1, Month, Year)
	else
	  NewCur := (Point.Y - 2) * 7 + Point.X div 3 + 1 -
	    DayOfWeek(1, Month, Year);
	if NewCur < 1 then NewCur := 1
	else if NewCur > Days then NewCur := Days;
	CurDay := NewCur;
	DrawView;
	if Event.Double then
	  Message(Owner, evBroadcast, cmCalendar, @Self);
	Event.What := evNothing;
      end;
    end
    else if Event.What = evKeyDown then
    begin
      if Vert then
      case Event.KeyCode of
	kbLeft:  Event.KeyCode := kbUpKey;
	kbRight: Event.KeyCode := kbDnKey;
	kbUpKey: Event.KeyCode := kbLeft;
	kbDnKey: Event.KeyCode := kbRight;
      end;
      case Event.KeyCode of
	kbLeft:  if CurDay = 1 then CurDay := Days else Dec(CurDay);
	kbRight: if CurDay = Days then CurDay := 1 else Inc(CurDay);
	kbUpKey: if CurDay <= 7 then CurDay := 1 else Dec(CurDay, 7);
	kbDnKey:
	  begin
	    Inc(CurDay, 7);
	    if CurDay > Days then CurDay := Days;
	  end;
	kbEnter: Message(Owner, evBroadcast, cmCalendar, @Self);
	else Exit;
      end;
      DrawView;
      Event.What := evNothing;
    end;
  end;
end;

procedure SetInputData(I: PInputLine; W: Word);
begin
  Str(W:2, I^.Data^);
  I^.DrawView;
end;

procedure TInputMonth.HandleEvent(var Event: TEvent);
begin
  TInputLine.HandleEvent(Event);
  if (Event.What = evBroadcast) and
     (Event.Command = cmCalendar) and
     (State and sfSelected = 0) then
    SetInputData(@Self, PAlarmCalendar(Event.InfoPtr)^.Month);
end;

procedure TInputDay.HandleEvent(var Event: TEvent);
begin
  TInputLine.HandleEvent(Event);
  if (Event.What = evBroadcast) and
     (Event.Command = cmCalendar) and
     (State and sfSelected = 0) then
    SetInputData(@Self, PAlarmCalendar(Event.InfoPtr)^.CurDay);
end;

function TAlarmList.GetText(Item: Integer; MaxLen: Integer): String;
var
  W: Word;
  Code: Integer;
  P: Pointer;
  S: String;
begin
  P := Dates^.At(Item);
  if P <> nil then
  begin
    if PDate(P)^.Message = nil then S := 'Alarm !'
    else S := PDate(P)^.Message^;
    if (S <> '') and (S[1] = '>') then
    begin
      Delete(S, 1, 1);
      S := 'Execute program ' + Trim(S);
    end
    else if (S[0] = #5) and (S[1] = '$') then
    begin
      Val(S, W, Code);
      S := 'Execute macro with a hot key ' + GetKeyName(W);
    end;
    GetText := Pad(FormatItemStr(P), 23) + S;
  end
  else GetText := '';
end;

procedure TAlarmList.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmModifyItem;
    Event.What := evNothing;
  end
  else TListViewer.HandleEvent(Event);

  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbCtrlUp: if not MoveListItem(@Self, Dates, True) then Exit;
      kbCtrlDn: if not MoveListItem(@Self, Dates, False) then Exit;
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

function GetNewItem(Header: String; var Item: Pointer): Boolean;
type
  DialogData = record
    Month, Day, Hour, Minute, Second: String[2];
    Message: String[255];
    Options: Word;
  end;
var
  C: Word;
  R: TRect;
  D: PDialog;
  Control: PView;
  S: String;
  AData: DialogData;

procedure Item2Data;
var
  S: String[2];
begin
  if Pos('N', Header) = 1 then
    FillChar(AData, SizeOf(DialogData), #0)
  else
  begin
    Str(PDate(Item)^.DateAndTime.Month : 2, S);
    if S = '0' then S := '';
    AData.Month := S;
    Str(PDate(Item)^.DateAndTime.Day : 2, S);
    if S = '0' then S := '';
    AData.Day := S;
    Str(PDate(Item)^.DateAndTime.Hour : 2, S);
    if S = '0' then S := '';
    AData.Hour := S;
    Str(PDate(Item)^.DateAndTime.Min : 2, S);
    if S = '0' then S := '';
    AData.Minute := S;
    Str(PDate(Item)^.DateAndTime.Sec : 2, S);
    if S = '0' then S := '';
    AData.Second := S;
    if PDate(Item)^.Message = nil then AData.Message := ''
      else AData.Message := PDate(Item)^.Message^;
    AData.Options := PDate(Item)^.Options;
  end;
end;

procedure Data2Item;
var
  Code: Integer;
  Hour, Minute, Second, Sec100: Word;
begin
  Val(AData.Month, PDate(Item)^.DateAndTime.Month, Code);
  if PDate(Item)^.DateAndTime.Month = 0 then
    PDate(Item)^.DateAndTime.Month := InitPoint.Month;
  Val(AData.Day, PDate(Item)^.DateAndTime.Day, Code);
  if PDate(Item)^.DateAndTime.Day = 0 then
    PDate(Item)^.DateAndTime.Day := InitPoint.Day;
  Val(AData.Hour, PDate(Item)^.DateAndTime.Hour, Code);
  Val(AData.Minute, PDate(Item)^.DateAndTime.Min, Code);
  Val(AData.Second, PDate(Item)^.DateAndTime.Sec, Code);
{  PDate(Item)^.Message := NewStr(AData.Message);}
  PDate(Item)^.Message := NewStrUMB(AData.Message);
  PDate(Item)^.Options := AData.Options;
  GetTime(Hour, Minute, Second, Sec100);
  PDate(Item)^.Worked := False;
end;

begin
  R.Assign(0, 0, 60, 17);
  D := New(PDialog, Init(R, Header));
  with D^ do
  begin
    HelpCtx := hcNewItem;
    Options := Options or ofCentered;
    R.Assign(9, 2, 13, 3);
    Control := New(PInputMonth, Init(R, 2, 0, 12));
    Control^.EventMask := Control^.EventMask or evBroadcast;
    Insert(Control);
    R.Assign(2, 2, 9, 3);
    Insert(New(PLabel, Init(R, '~M~onth', Control)));

    R.Assign(19, 2, 23, 3);
    Control := New(PInputDay, Init(R, 2, 0, 31));
    Control^.EventMask := Control^.EventMask or evBroadcast;
    Insert(Control);
    R.Assign(14, 2, 19, 3);
    Insert(New(PLabel, Init(R, '~D~ay', Control)));

    R.Assign(33, 2, 37, 3);
    Control := New(PCInputLine, Init(R, 2, 0, 24));
    Insert(Control);
    R.Assign(27, 2, 33, 3);
    Insert(New(PLabel, Init(R, 'Hou~r~', Control)));

    R.Assign(43, 2, 47, 3);
    Control := New(PCInputLine, Init(R, 2, 0, 60));
    Insert(Control);
    R.Assign(38, 2, 43, 3);
    Insert(New(PLabel, Init(R, 'M~i~n', Control)));

    R.Assign(53, 2, 57, 3);
    Control := New(PCInputLine, Init(R, 2, 0, 60));
    Insert(Control);
    R.Assign(48, 2, 53, 3);
    Insert(New(PLabel, Init(R, '~S~ec', Control)));

    R.Assign(11, 4, Size.X - 6, 5);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, AlarmMsgHistoryID);
    R.Assign(2, 4, 11, 5);
    Insert(New(PLabel, Init(R, 'M~e~ssage', Control)));

    R.Assign(3, 7, 34, 12);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Ever~y~day',
      NewSItem('Every ~w~eek',
      NewSItem('Exec~u~te if overdue',
      NewSItem('Dele~t~e after execution',
      NewSItem('Auto-c~l~osing message box', nil)))))));
    Insert(Control);
    R.Assign(2, 6, 31, 7);
    Insert(New(PLabel, Init(R, 'Options', Control)));

    R.Assign(Size.X - 23, 7, Size.X - 3, 15);
    Control := New(PAlarmCalendar, Init(R));
    Control^.Options := Control^.Options or ofFramed;
    PAlarmCalendar(Control)^.ShowCurrent := True;
    Insert(Control);
    R.Assign(42, 6, 52, 7);
    Insert(New(PLabel, Init(R, '~C~alendar', Control)));

    R.Assign(2, 14, 12, 16);
    StandardOkButton(R, D);
    Inc(R.A.X, 11); Inc(R.B.X, 11);
    StandardCancelButton(R, D);
    Inc(R.A.X, 11); Inc(R.B.X, 11);
    StandardHelpButton(R, D);
    SelectNext(False);
  end;

  Item2Data;
  C := Application^.ExecuteDialog(D, @AData, False);
  if C <> cmCancel then Data2Item;
  GetNewItem := C <> cmCancel;
end;

procedure UpdateStatus;
begin
  LogEvent := lcDiskWrite;
  DrawStatusLine('Updating Alarm list file.');
end;

procedure TAlarmList.NewItem;
var
  Item: Pointer;
begin
  GetMem(Item, SizeOf(TDate));
  if GetNewItem('New item', Item) then
  begin
    Dates^.AtInsert(Focused, Item);
    SetRange(Dates^.Count);
    UpdateStatus;
    StoreDates;
    UpdateCommands;
    DrawView;
  end
  else FreeMem(Item, SizeOf(TDate));
  Select;
end;

procedure TAlarmList.ModifyItem;
var
  Item: Pointer;
begin
  if Focused = Dates^.Count - 1 then
  begin
    NewItem;
    Exit;
  end;
  GetMem(Item, SizeOf(TDate));
  Move(Dates^.At(Focused)^, Item^, SizeOf(TDate));
  if GetNewItem('Modify item', Item) then
  begin
    Dates^.AtFree(Focused);
    Dates^.AtInsert(Focused, Item);
    UpdateStatus;
    StoreDates;
    DrawView;
  end
  else FreeMem(Item, SizeOf(TDate));
  Select;
end;

procedure TAlarmList.DeleteItem;
begin
  if (Focused < Dates^.Count - 1) and (DeleteItemMsgBox = cmOk) then
  begin
    Dates^.AtFree(Focused);
    SetRange(Dates^.Count);
    UpdateStatus;
    StoreDates;
    UpdateCommands;
  end;
  Select;
  DrawView;
end;

procedure TAlarmList.NewItemPos;
var
  SaveFocused, LastFocused: Integer;
  SaveCtx: Word;
  P: Pointer;
  Event: TEvent;
begin
  with Dates^ do
  begin
    if Focused >= Count - 1 then Exit;
    P := At(Focused);
    SaveFocused := Focused;
    SaveCtx := Owner^.HelpCtx;
    Owner^.HelpCtx := hcNewItemPos;
    repeat
      GetEvent(Event);
      HandleEvent(Event);
      LastFocused := IndexOf(P);
      if (Focused < Count - 1) and
	 (LastFocused <> -1) and (LastFocused <> Focused) then
      begin
	AtDelete(LastFocused);
	AtInsert(Focused, P);
	FocusItem(Focused);
	DrawView;
      end;
      if ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) or
	 ((Event.What = evCommand) and (Event.Command = cmOk)) then
      begin
	StoreDates;
	Break;
      end
      else if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
      begin
	AtDelete(LastFocused);
	AtInsert(SaveFocused, P);
	FocusItem(SaveFocused);
	DrawView;
	Break;
      end;
    until False;
    Owner^.HelpCtx := SaveCtx;
  end;
  Select;
end;

procedure TAlarmList.Update;
begin
  SetRange(Dates^.Count);
  UpdateCommands;
  DrawView;
end;

constructor TAlarmDialog.Init;
var
  VBar, HBar: PScrollBar;
  R: TRect;
begin
  R.Assign(5, 3, 75, 20);
  TDialog.Init(R, 'Alarm list');
  Options := Options or ofCentered;
  HelpCtx := hcAlarm;

  R.Assign(3, 13, 55, 14);
  HBar := New(PScrollBar, Init(R));
  HBar^.Options := HBar^.Options or ofPostProcess;
  HBar^.SetRange(0, 255);
  Insert(HBar);
  R.Assign(55, 3, 56, 13);
  VBar := New(PScrollBar, Init(R));
  VBar^.Options := VBar^.Options or ofPostProcess;
  Insert(VBar);

  R.Assign(3, 3, 55, 13);
  AlarmList := New(PAlarmList, Init(R, 1, HBar, VBar));
  Insert(AlarmList);
  R.Assign(2, 2, 56, 3);
  Insert(New(PLabel, Init(R, '~I~tems', AlarmList)));

  R.Assign(57, 3, 67, 5);
  Insert(New(PButton, Init(R, '~M~odify', cmModifyItem, bfDefault)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~N~ew', cmNewItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'Ad~j~ust', cmNewItemPos, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardCancelButton(R, @Self);
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardHelpButton(R, @Self);

  AlarmList^.Select;
  AlarmList^.FocusItem(0);
end;

constructor TAlarmDialog.Load(var S: TStream);
begin
  TDialog.Load(S);
  GetSubViewPtr(S, AlarmList);
  AlarmList^.SetRange(Dates^.Count);
  UpdateCommands;
end;

procedure TAlarmDialog.HandleEvent(var Event: TEvent);
begin
  TDialog.HandleEvent(Event);
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbDel:
	begin
	  Event.What := evCommand;
	  Event.Command := cmDeleteItem;
	end;
      kbIns:
	begin
	  Event.What := evCommand;
	  Event.Command := cmNewItem;
	end;
    end;
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmNewItem: AlarmList^.NewItem;
      cmModifyItem: AlarmList^.ModifyItem;
      cmDeleteItem: AlarmList^.DeleteItem;
      cmNewItemPos: AlarmList^.NewItemPos;
      else Exit;
    end;
    Event.What := evNothing;
  end
  else if Event.What = evBroadcast then
    case Event.Command of
      cmUpdateAlarm:
	begin
	  AlarmList^.Update;
	  Event.What := evNothing;
	end;
    end;
end;

procedure TAlarmDialog.Store(var S: TStream);
begin
  TDialog.Store(S);
  PutSubViewPtr(S, AlarmList);
end;

procedure RSRAlarmDialog(RSR: PResourceFile);
var
  D: PAlarmDialog;
begin
  D := New(PAlarmDialog, Init);
  RSR^.Put(D, 'ALARMDIALOG');
  Dispose(D, Done);
end;

procedure AlarmDialog;
var
  D: PAlarmDialog;
begin
  D := PAlarmDialog(Resource^.Get('ALARMDIALOG'));
  if D <> nil then Application^.ExecuteDialog(D, nil, False)
  else ResourceNotFoundMsgBox('Alarm dialog');
end;

end.
