{$I-,X+,O+,F+}
unit ExtList;

interface

uses Dos, Objects, Drivers, Views, Dialogs, ProgList, HotKeys;

const
  ExecTitleLen = 31;
  ConditionLen = 127;

type
  PExtList = ^TExtList;
  TExtList = object(TProgList)
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure FocusMask; virtual;
    function GetNewItem(const Header: String): PExecItem; virtual;
    procedure CheckDuplicates(AKey: Word;
      ASequence: PHotKeySequence; ACount: Word); virtual;
    procedure GetExtStr(P: Pointer; var S: String;
      ForList: Boolean); virtual;
  end;

  PExtInfoPane = ^TExtInfoPane;
  TExtInfoPane = object(TView)
    Name: String[ExecTitleLen];
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PAssocDialog = ^TAssocDialog;
  TAssocDialog = object(TProgDialog)
    constructor Init(const AName, AFocusName: FNameStr; View: Boolean);
  end;

  PViewList = ^TViewList;
  TViewList = object(TExtList)
    procedure GetExtStr(P: Pointer; var S: String;
      ForList: Boolean); virtual;
  end;

procedure SplitExecTitle(P: PExecItem;
  var Mask, Title, Condition: String);

implementation

uses App, DirPrim, StdDlg, CNInputs, History, Filters, TPString,
  Consts, Commands;

procedure SplitExecTitle(P: PExecItem;
  var Mask, Title, Condition: String);
var
  I: Integer;
begin
  if (P = nil) or (P^.Title = nil) then
  begin
    Mask := '';
    Title := '';
    Condition := '';
  end
  else
  begin
    I := Pos(';', P^.Title^);
    if I = 0 then
    begin
      Mask := P^.Title^;
      TrimSt(Mask);
      Title := '';
      Condition := '';
    end
    else
    begin
      Mask := Copy(P^.Title^, 1, I - 1);
      Title := Copy(P^.Title^, I + 1, 255);
      I := Pos(';', Title);
      if I = 0 then Condition := ''
      else
      begin
	Condition := Copy(Title, I + 1, 255);
	Title[0] := Char(I - 1);
      end;
      TrimSt(Mask);
      TrimSt(Title);
      TrimSt(Condition);
    end;
  end;
end;

procedure TExtList.FocusItem(Item: Integer);
var
  PS: PString;
  Mask, Title, Condition: String;
begin
  TProgList.FocusItem(Item);
  SplitExecTitle(List^.At(Focused), Mask, Title, Condition);
  if Title = '' then PS := nil else PS := @Title;
  Message(Owner, evBroadcast, cmListItemSelected, PS);
end;

function TExtList.GetText(Item: Integer; MaxLen: Integer): String;
var
  S: String;
begin
  if Item > Range - 2 then S := ''
  else GetExtStr(List^.At(Item), S, True);
  GetText := S;
end;

procedure TExtList.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  if Focused <> Range - 1 then
  begin
    Pending.What := evCommand;
    Pending.Command := cmModifyItem;
    Event.What := evNothing;
  end else Event.What := evNothing;
  TListBox.HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbCtrlUp: if not MoveListItem(@Self, List, True) then Exit;
      kbCtrlDn: if not MoveListItem(@Self, List, False) then Exit;
      else Exit;
    end;
    SaveList(FileName^);
    Event.What := evNothing;
  end;
end;

procedure TExtList.FocusMask;
var
  I: Integer;
  P: PExecItem;
  Mask, Title, Condition: String;
begin
  if FocusName <> nil then for I := 0 to List^.Count - 1 do
  begin
    P := List^.At(I);
    SplitExecTitle(P, Mask, Title, Condition);
    if WildCardMatch(FocusName^, Mask) then
    begin
      FocusItem(I);
      Exit;
    end;
  end;
  FocusItem(0);
end;

procedure FilterDebugProc(V: PView; var Event: TEvent);
var
  X, Y: Integer;
  I1, I2, I3, I4, I5, I6: PInputLine;
  NameFilter, LineFilter, ColumnFilter: String;

function IsI(P: PView): Boolean; far;
begin
  IsI := (TypeOf(P^) = TypeOf(TInputLine)) and
    (P^.Origin.X = X) and (P^.Origin.Y = Y);
end;

function GetInputLineStr(P: PInputLine): String;
var
  S: String;
begin
  with P^ do
    if SelStart <> SelEnd then GetInputLineStr :=
      System.Copy(Data^, SelStart + 1, SelEnd - SelStart)
    else GetInputLineStr := Data^;
end;

begin
  X := 17; Y := 10;
  I1 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  Y := 12;
  I2 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  X := 51; Y := 10;
  I3 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  Y := 12;
  I4 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  X := 66;
  I5 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  X := 73;
  I6 := PInputLine(PDialog(V)^.FirstThat(@IsI));
  if (I1 = nil) or (I2 = nil) or (I3 = nil) or
     (I4 = nil) or (I5 = nil) or (I6 = nil) then Exit;
  FilterDebugStrings(I3^.GetText, I1^.GetText, I2^.GetText,
    NameFilter, LineFilter, ColumnFilter);
  if NameFilter <> I4^.Data^ then I4^.SetData(NameFilter);
  if LineFilter <> I5^.Data^ then I5^.SetData(LineFilter);
  if ColumnFilter <> I6^.Data^ then I6^.SetData(ColumnFilter);
end;

function TExtList.GetNewItem(const Header: String): PExecItem;
type
  DialogData = record
    Ext: String[12];
    Title: String[ExecTitleLen];
    Condition: String[ConditionLen];
    Rec: TExecRec;
    HotKey: Word;
    SourceStr: String;
    ResultStr1: String;
    ResultStr2: String;
    ResultStr3: String;
  end;
var
  Viewers: Boolean;
  P: PExecItem;
  D: PDialog;
  Control: PView;
  R: TRect;
  AData: DialogData;
  MS, TS, CS: String;
begin
  GetNewItem := nil;
  Viewers := StatusWord[1] = 'V';
  if Viewers then TS := 'viewer' else TS := 'association';
  if Header[1] = 'N' then TS := 'New ' + TS
  else TS := 'Modify ' + TS;
  R.Assign(0, 0, 80, 22 - Byte(Viewers) * 4);
  D := New(PDialog, Init(R, TS));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcNewExt;
    if not Viewers then PostProcessEvent := FilterDebugProc;

    R.Assign(17, 2, 31, 3);
    Control := New(PInputLine, Init(R, 12));
    Insert(Control);
    R.Assign(2, 2, 17, 3);
    Insert(New(PLabel, Init(R, '~F~ile name', Control)));

    R.Assign(41, 2, Size.X - 6, 3);
    Control := New(PInputLine, Init(R, ExecTitleLen));
    Insert(Control);
    R.Assign(34, 2, 41, 3);
    Insert(New(PLabel, Init(R, '~T~itle', Control)));
    StandardHistory(Control, TitleHistoryId);

    R.Assign(17, 4, Size.X - 6, 5);
    Control := New(PInputLine, Init(R, ConditionLen));
    Insert(Control);
    R.Assign(2, 4, 17, 5);
    Insert(New(PLabel, Init(R, 'Env con~d~ition', Control)));
    StandardHistory(Control, EnvHistoryId);

    R.Assign(17, 6, Size.X - 6, 7);
    Control := New(PFInputLine, Init(R, 255));
    Insert(Control);
    R.Assign(2, 6, 17, 7);
    if Viewers then TS := 'Viewer ~p~ath'
    else TS := '~P~rogram path';
    Insert(New(PLabel, Init(R, TS, Control)));
    StandardHistory(Control, PathHistoryId);

    R.Assign(17, 8, Size.X - 6, 9);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    R.Assign(2, 8, 17, 9);
    Insert(New(PLabel, Init(R, '~C~ommand line', Control)));
    StandardHistory(Control, ParamsHistoryId);

    if Viewers then
    begin
      R.Assign(17, 10, 20, 11);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      Control^.Hide;

      R.Assign(17, 12, 20, 13);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      Control^.Hide;
    end
    else
    begin
      R.Assign(17, 10, 40, 11);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      R.Assign(2, 10, 17, 11);
      Insert(New(PLabel, Init(R, 'File~n~ame mask', Control)));
      StandardHistory(Control, FiltersHistoryId);

      R.Assign(17, 12, 40, 13);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      R.Assign(2, 12, 17, 13);
      Insert(New(PLabel, Init(R, 'Line num ~m~ask', Control)));
      StandardHistory(Control, FiltersHistoryId);
    end;

    R.Assign(3, Size.Y - 7, 15, Size.Y - 4);
    Control := MainControl(R);
    Insert(Control);
    R.Assign(2, Size.Y - 8, 15, Size.Y - 7);
    Insert(New(PLabel, Init(R, 'Main', Control)));

    R.Assign(17, Size.Y - 7, 40, Size.Y - 4);
    Control := SetupControl(R);
    Insert(Control);
    R.Assign(16, Size.Y - 8, 40, Size.Y - 7);
    Insert(New(PLabel, Init(R, 'Setup', Control)));

    R.Assign(42, Size.Y - 7, 64, Size.Y - 4);
    Control := OptionsControl(R, True);
    Insert(Control);
    R.Assign(41, Size.Y - 8, 64, Size.Y - 7);
    Insert(New(PLabel, Init(R, 'Options', Control)));

    if Viewers then TS := 'F~3~' else TS := 'Ente~r~';
    R.Assign(66, Size.Y - 7, 77, Size.Y - 4);
    Control := New(PRadioButtons, Init(R,
      NewSItem(TS,
      NewSItem('~A~lt',
      NewSItem('S~h~ift', nil)))));
    Insert(Control);
    R.Assign(65, Size.Y - 8, 77, Size.Y - 7);
    Insert(New(PLabel, Init(R, 'Key', Control)));

    if Viewers then
    begin
      R.Assign(51, 10, 74, 11);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      Control^.Hide;

      R.Assign(51, 12, 65, 13);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      Control^.Hide;

      R.Assign(66, 12, 72, 13);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      Control^.Hide;

      R.Assign(73, 12, 77, 13);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      Control^.Hide;
    end
    else
    begin
      R.Assign(51, 10, 74, 11);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      R.Assign(43, 10, 51, 11);
      Insert(New(PLabel, Init(R, 'Source', Control)));
      StandardHistory(Control, FilterSourceHistoryId);

      R.Assign(51, 12, 65, 13);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      R.Assign(43, 12, 51, 13);
      Insert(New(PLabel, Init(R, 'Result', Control)));

      R.Assign(71, 12, 73, 13);
      Insert(New(PLabel, Init(R, ':', nil)));

      R.Assign(66, 12, 72, 13);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);

      R.Assign(73, 12, 77, 13);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
    end;

    StandardButtonRow(D, True);
  end;

  FillChar(AData, SizeOf(DialogData), 0);
  P := List^.At(Focused);
  if P <> nil then
  begin
    SplitExecTitle(P, MS, TS, CS);
    AData.Ext := MS;
    AData.Title := TS;
    AData.Condition := CS;
    P^.GetData(AData.Rec, AData.HotKey);
  end;
  if Application^.ExecuteDialog(D, @AData, False) <> cmCancel then
  begin
    P := New(PExecItem, Init);
    if P <> nil then
    begin
      TrimSt(AData.Ext);
      TrimSt(AData.Title);
      TrimSt(AData.Condition);
      MS := AData.Ext;
      if (AData.Title <> '') or (AData.Condition <> '') then
	MS := MS + ';' + AData.Title;
      if AData.Condition <> '' then MS := MS + ';' + AData.Condition;
      P^.SetData(MS, AData.Rec, AData.HotKey);
      GetNewItem := P;
    end;
  end;
end;

procedure TExtList.CheckDuplicates(AKey: Word;
  ASequence: PHotKeySequence; ACount: Word);
begin
end;

procedure TExtList.GetExtStr(P: Pointer; var S: String; ForList: Boolean);
var
  HKS: String[15];
  Mask, Title, Condition: String;
begin
  FillChar(S, SizeOf(FNameStr), 0);
  if P = nil then Exit;
  SplitExecTitle(P, Mask, Title, Condition);
  if Mask <> '' then S := Mask;
  if not ForList then Exit;
  S[0] := #25;
  case PExecItem(P)^.HotKey of
    0: HKS := ' Enter';
    1: HKS := ' Alt+Enter';
    2: HKS := ' Shift+Enter';
    else HKS := '';
  end;
  Move(HKS[1], S[26 - Length(HKS)], Length(HKS));
end;

procedure TExtInfoPane.Draw;
var
  C: Word;
  B: TDrawBuffer;
begin
  C := GetColor(1);
  MoveChar(B, ' ', C, Size.X);
  if Name <> '' then MoveStr(B[1], Name, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TExtInfoPane.GetPalette: PPalette;
const
  P: String[1] = #7;
begin
  GetPalette := @P;
end;

procedure TExtInfoPane.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  if (Event.What = evBroadcast) and
     (Event.Command = cmListItemSelected) then
  begin
    if Event.InfoPtr = nil then Name := ''
    else Name := PString(Event.InfoPtr)^;
    DrawView;
  end;
end;

procedure TViewList.GetExtStr(P: Pointer; var S: String;
  ForList: Boolean);
var
  HKS: String[15];
  Mask, Title, Condition: String;
begin
  FillChar(S, SizeOf(FNameStr), 0);
  if P = nil then Exit;
  SplitExecTitle(P, Mask, Title, Condition);
  if Mask <> '' then S := Mask;
  if not ForList then Exit;
  S[0] := #25;
  case PExecItem(P)^.HotKey of
    0: HKS := ' F3';
    1: HKS := ' Alt+F3';
    2: HKS := ' Shift+F3';
    else HKS := '';
  end;
  Move(HKS[1], S[26 - Length(HKS)], Length(HKS));
end;

constructor TAssocDialog.Init(const AName, AFocusName: FNameStr;
  View: Boolean);
var
  C: Char;
  D: PProgDialog;
  Control, Subview: PView;
  R: TRect;
  S: TTitleStr;
begin
  if View then C := 'V' else C := 'F';
  GetProgDlgTitle(C, AName, S);
  R.Assign(0, 0, 78, ScreenHeight - 5 - Byte(View) * 2);
  TDialog.Init(R, S);

  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  if View then HelpCtx := hcViewDlg else HelpCtx := hcExtDlg;

  R.Assign(33, 3, Size.X - 14, 4);
  ProgName := New(PProgInputLine, Init(R, 255));
  Insert(ProgName);
  R.Assign(32, 2, Size.X - 14, 3);
  if View then S := 'P~a~th to viewer' else S := '~P~rogram path';
  Insert(New(PLabel, Init(R, S, ProgName)));

  R.Assign(33, 6, Size.X - 14, 7);
  Control := New(PInputLine, Init(R, 255));
  Insert(Control);
  R.Assign(32, 5, Size.X - 14, 6);
  Insert(New(PLabel, Init(R, '~C~ommand line', Control)));

  R.Assign(33, 9, Size.X - 14, 10);
  Control := New(PInputLine, Init(R, 255));
  Insert(Control);
  if View then Control^.Hide
  else
  begin
    R.Assign(32, 8, Size.X - 14, 9);
    Insert(New(PLabel, Init(R, 'Filename mask', Control)));
  end;

  R.Assign(33, 12, Size.X - 14, 13);
  Control := New(PInputLine, Init(R, 255));
  Insert(Control);
  if View then Control^.Hide
  else
  begin
    R.Assign(32, 11, Size.X - 14, 12);
    Insert(New(PLabel, Init(R, 'Line num mask', Control)));
  end;

  R.Assign(3, Size.Y - 5, 15, Size.Y - 2);
  Control := MainControl(R);
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Control);
  R.Assign(2, Size.Y - 6, 15, Size.Y - 5);
  Subview := New(PLabel, Init(R, 'Main', Control));
  Subview^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Subview);

  R.Assign(17, Size.Y - 5, 40, Size.Y - 2);
  Control := SetupControl(R);
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Control);
  R.Assign(16, Size.Y - 6, 40, Size.Y - 5);
  Subview := New(PLabel, Init(R, 'Setup', Control));
  Subview^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Subview);

  R.Assign(42, Size.Y - 5, 64, Size.Y - 2);
  Control := OptionsControl(R, True);
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Control);
  R.Assign(41, Size.Y - 6, 64, Size.Y - 5);
  Subview := New(PLabel, Init(R, 'Options', Control));
  Subview^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Subview);

  R.Assign(30, 3, 31, Size.Y - 7);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3, 3, 30, Size.Y - 7);
  if View then ProgList := New(PViewList, Init(R, PScrollBar(Control),
    AName, AFocusName))
  else ProgList := New(PExtList, Init(R, PScrollBar(Control),
    AName, AFocusName));
  ProgList^.GrowMode := gfGrowHiY;
  if View then ProgList^.StatusWord := 'Viewer'
  else ProgList^.StatusWord := 'Association';
  Insert(ProgList);
  R.Assign(2, 2, 31, 3);
  Insert(New(PLabel, Init(R, ' ~F~ile names            Key', ProgList)));
  R.Assign(3, Size.Y - 7, 30, Size.Y - 6);
  Control := New(PExtInfoPane, Init(R));
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Control^.EventMask := Control^.EventMask or evBroadcast;
  Insert(Control);

  R.Assign(Size.X - 13, 3, Size.X - 3, 5);
  Insert(New(PButton, Init(R, '~M~odify', cmModifyItem, bfDefault)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~N~ew', cmNewItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~F~ile', cmFileOpen, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'Ad~j~ust', cmNewItemPos, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardCancelButton(R, @Self);
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardHelpButton(R, @Self);
end;

end.
