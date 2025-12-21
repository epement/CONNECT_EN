{$F+,O+,X+}
unit RegExDlg;

interface

uses Drivers, Objects, Views, Dialogs;

type
  PRegExpInputLine = ^TRegExpInputLine;
  TRegExpInputLine = object(TInputLine)
    PrevSelStart, PrevSelEnd: Integer;
    PrevData: String;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
  end;

  PRegExpDialog = ^TRegExpDialog;
  TRegExpDialog = object(TDialog)
    SourceInputLine: PRegExpInputLine;
    SearchInputLine: PRegExpInputLine;
    ReplaceInputLine: PRegExpInputLine;
    CaseCheckBox: PCheckBoxes;
    SInputLine: PInputLine;
    S0InputLine: PInputLine;
    S1InputLine: PInputLine;
    S2InputLine: PInputLine;
    S3InputLine: PInputLine;
    S4InputLine: PInputLine;
    S5InputLine: PInputLine;
    S6InputLine: PInputLine;
    S7InputLine: PInputLine;
    S8InputLine: PInputLine;
    S9InputLine: PInputLine;
    constructor Init;
    constructor Load(var S: TStream);
    procedure Store(var S: TStream);
    procedure UpdateLines;
  end;

procedure RSRRegExpDialog(RSR: PResourceFile);
procedure RegExpDialog;
procedure AutoRegExp;

implementation

uses Strings, App, RegExp, FindDlg, EditMsg, FEditor, EditFind, FileMngr,
  FMPrim, Filters, HistList, History, TPString, Consts, Commands, Defaults;

const
  RegExpDialogCheck: Byte = 0;

procedure RegExpDebugStrings(const SourceStr, SearchStr, ReplaceStr: String;
  var S, S0, S1, S2, S3, S4, S5, S6, S7, S8, S9: String);
var
  I: Integer;
  X: PRegExp;
  A: Array[0..255] of Char;
begin
  S  := '';
  S0 := '';
  S1 := '';
  S2 := '';
  S3 := '';
  S4 := '';
  S5 := '';
  S6 := '';
  S7 := '';
  S8 := '';
  S9 := '';
  if RegExpDialogCheck = 0 then X := RegCompile(StUpcase(SearchStr))
  else X := RegCompile(SearchStr);
  if X = nil then S := RegError
  else
  begin
    I := Length(SourceStr);
    Move(SourceStr[1], A[0], I);
    A[I] := #0;
    if RegExpDialogCheck = 0 then StrUpper(A);
    if RegExec(X, A) <> 0 then
    begin
      Move(SourceStr[1], A[0], I);
      regsub(X, ReplaceStr, S);
      regsub(X, '\0', S0);
      regsub(X, '\1', S1);
      regsub(X, '\2', S2);
      regsub(X, '\3', S3);
      regsub(X, '\4', S4);
      regsub(X, '\5', S5);
      regsub(X, '\6', S6);
      regsub(X, '\7', S7);
      regsub(X, '\8', S8);
      regsub(X, '\9', S9);
    end
    else S := 'Search text not found';
    RegFree(X);
  end;
end;

procedure TRegExpInputLine.HandleEvent(var Event: TEvent);
begin
  Inherited HandleEvent(Event);
  if (PrevSelStart <> SelStart) or (PrevSelEnd <> SelEnd) or
     (PrevData <> Data^) then
  begin
    PrevSelStart := SelStart;
    PrevSelEnd := SelEnd;
    PrevData := Data^;
    PRegExpDialog(Owner)^.UpdateLines;
  end;
end;

procedure TRegExpInputLine.SetData(var Rec);
begin
  Inherited SetData(Rec);
  HandleEvent(Pending);
end;

constructor TRegExpDialog.Init;
var
  R: TRect;
begin
  R.Assign(0, 0, 67, 21);
  Inherited Init(R, 'Regular expression debugger');
  HelpCtx := hcRegExpDlg;
  Options := Options or ofCentered;

  R.Assign(11, 2, 61, 3);
  SourceInputLine := New(PRegExpInputLine, Init(R, 255));
  Insert(SourceInputLine);
  StandardHistory(SourceInputLine, RegExpDlgHistoryId);
  R.Assign(3, 2, 11, 3);
  Insert(New(PLabel, Init(R, 'S~o~urce', SourceInputLine)));

  R.Assign(11, 3, 61, 4);
  SearchInputLine := New(PRegExpInputLine, Init(R, 255));
  Insert(SearchInputLine);
  StandardHistory(SearchInputLine, FindHistoryId);
  R.Assign(3, 3, 11, 4);
  Insert(New(PLabel, Init(R, '~S~earch', SearchInputLine)));

  R.Assign(11, 4, 61, 5);
  ReplaceInputLine := New(PRegExpInputLine, Init(R, 255));
  Insert(ReplaceInputLine);
  StandardHistory(ReplaceInputLine, ReplaceHistoryId);
  R.Assign(2, 4, 11, 5);
  Insert(New(PLabel, Init(R, '~R~eplace', ReplaceInputLine)));

  R.Assign(11, 6, 64, 7);
  SInputLine := New(PInputLine, Init(R, 255));
  Insert(SInputLine);
  R.Assign(3, 6, 11, 7);
  Insert(New(PLabel, Init(R, 'Res~u~lt', SInputLine)));

  R.Assign(11, 7, 64, 8);
  S0InputLine := New(PInputLine, Init(R, 255));
  Insert(S0InputLine);
  R.Assign(2, 7, 11, 8);
  Insert(New(PLabel, Init(R, 'Group ~0~', S0InputLine)));

  R.Assign(11, 8, 64, 9);
  S1InputLine := New(PInputLine, Init(R, 255));
  Insert(S1InputLine);
  R.Assign(2, 8, 11, 9);
  Insert(New(PLabel, Init(R, 'Group ~1~', S1InputLine)));

  R.Assign(11, 9, 64, 10);
  S2InputLine := New(PInputLine, Init(R, 255));
  Insert(S2InputLine);
  R.Assign(2, 9, 11, 10);
  Insert(New(PLabel, Init(R, 'Group ~2~', S2InputLine)));

  R.Assign(11, 10, 64, 11);
  S3InputLine := New(PInputLine, Init(R, 255));
  Insert(S3InputLine);
  R.Assign(2, 10, 11, 11);
  Insert(New(PLabel, Init(R, 'Group ~3~', S3InputLine)));

  R.Assign(11, 11, 64, 12);
  S4InputLine := New(PInputLine, Init(R, 255));
  Insert(S4InputLine);
  R.Assign(2, 11, 11, 12);
  Insert(New(PLabel, Init(R, 'Group ~4~', S4InputLine)));

  R.Assign(11, 12, 64, 13);
  S5InputLine := New(PInputLine, Init(R, 255));
  Insert(S5InputLine);
  R.Assign(2, 12, 11, 13);
  Insert(New(PLabel, Init(R, 'Group ~5~', S5InputLine)));

  R.Assign(11, 13, 64, 14);
  S6InputLine := New(PInputLine, Init(R, 255));
  Insert(S6InputLine);
  R.Assign(2, 13, 11, 14);
  Insert(New(PLabel, Init(R, 'Group ~6~', S6InputLine)));

  R.Assign(11, 14, 64, 15);
  S7InputLine := New(PInputLine, Init(R, 255));
  Insert(S7InputLine);
  R.Assign(2, 14, 11, 15);
  Insert(New(PLabel, Init(R, 'Group ~7~', S7InputLine)));

  R.Assign(11, 15, 64, 16);
  S8InputLine := New(PInputLine, Init(R, 255));
  Insert(S8InputLine);
  R.Assign(2, 15, 11, 16);
  Insert(New(PLabel, Init(R, 'Group ~8~', S8InputLine)));

  R.Assign(11, 16, 64, 17);
  S9InputLine := New(PInputLine, Init(R, 255));
  Insert(S9InputLine);
  R.Assign(2, 16, 11, 17);
  Insert(New(PLabel, Init(R, 'Group ~9~', S9InputLine)));

  R.Assign(11, 18, 31, 19);
  CaseCheckBox := New(PCheckBoxes, Init(R, NewSItem('~C~ase sensitive', nil)));
  Insert(CaseCheckBox);
  R.Assign(2, 18, 11, 19);
  Insert(New(PLabel, Init(R, 'Options', CaseCheckBox)));

  R.Assign(32, 18, 42, 20);
  StandardOkButton(R, @Self);
  R.Assign(43, 18, 53, 20);
  StandardCancelButton(R, @Self);
  R.Assign(54, 18, 64, 20);
  StandardHelpButton(R, @Self);

  SelectNext(False);
end;

constructor TRegExpDialog.Load(var S: TStream);
begin
  Inherited Load(S);
  GetSubViewPtr(S, SourceInputLine);
  GetSubViewPtr(S, SearchInputLine);
  GetSubViewPtr(S, ReplaceInputLine);
  GetSubViewPtr(S, SInputLine);
  GetSubViewPtr(S, S0InputLine);
  GetSubViewPtr(S, S1InputLine);
  GetSubViewPtr(S, S2InputLine);
  GetSubViewPtr(S, S3InputLine);
  GetSubViewPtr(S, S4InputLine);
  GetSubViewPtr(S, S5InputLine);
  GetSubViewPtr(S, S6InputLine);
  GetSubViewPtr(S, S7InputLine);
  GetSubViewPtr(S, S8InputLine);
  GetSubViewPtr(S, S9InputLine);
  GetSubViewPtr(S, CaseCheckBox);
end;

procedure TRegExpDialog.Store(var S: TStream);
begin
  Inherited Store(S);
  PutSubViewPtr(S, SourceInputLine);
  PutSubViewPtr(S, SearchInputLine);
  PutSubViewPtr(S, ReplaceInputLine);
  PutSubViewPtr(S, SInputLine);
  PutSubViewPtr(S, S0InputLine);
  PutSubViewPtr(S, S1InputLine);
  PutSubViewPtr(S, S2InputLine);
  PutSubViewPtr(S, S3InputLine);
  PutSubViewPtr(S, S4InputLine);
  PutSubViewPtr(S, S5InputLine);
  PutSubViewPtr(S, S6InputLine);
  PutSubViewPtr(S, S7InputLine);
  PutSubViewPtr(S, S8InputLine);
  PutSubViewPtr(S, S9InputLine);
  PutSubViewPtr(S, CaseCheckBox);
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

procedure TRegExpDialog.UpdateLines;
var
  S, S0, S1, S2, S3, S4, S5, S6, S7, S8, S9: String;
begin
  RegExpDebugStrings(
    GetInputLineStr(SourceInputLine),
    GetInputLineStr(SearchInputLine),
    GetInputLineStr(ReplaceInputLine),
    S, S0, S1, S2, S3, S4, S5, S6, S7, S8, S9);
  SInputLine^.SetData(S);
  S0InputLine^.SetData(S0);
  S1InputLine^.SetData(S1);
  S2InputLine^.SetData(S2);
  S3InputLine^.SetData(S3);
  S4InputLine^.SetData(S4);
  S5InputLine^.SetData(S5);
  S6InputLine^.SetData(S6);
  S7InputLine^.SetData(S7);
  S8InputLine^.SetData(S8);
  S9InputLine^.SetData(S9);
end;

procedure RSRRegExpDialog(RSR: PResourceFile);
var
  D: PRegExpDialog;
begin
  D := New(PRegExpDialog, Init);
  RSR^.Put(D, 'REGEXPDIALOG');
  Dispose(D, Done);
end;

function RegExpDlgPutHistoryFunc(Link: PInputLine;
  const S: String): String;
begin
  RegExpDlgPutHistoryFunc := S + REGEXPHistStr;
end;

function RegExpDlgGetHistoryFunc(Link: PInputLine;
  const S: String): String;
var
  I: Integer;
begin
  I := Pos(REGEXPHistStr, S);
  if I <> 0 then RegExpDlgGetHistoryFunc := Copy(S, 1, I - 1)
  else RegExpDlgGetHistoryFunc := S;
end;

procedure RegExpDialogProc(V: PView; var Event: TEvent);
var
  P: PCheckBoxes;
begin
  with PRegExpDialog(V)^ do
    if CaseCheckBox^.Value <> RegExpDialogCheck then
    begin
      RegExpDialogCheck := CaseCheckBox^.Value;
      UpdateLines;
    end;
end;

procedure RegExpDialog;
const
  RegExpDialogInUse: Boolean = False;
var
  D: PRegExpDialog;
  H: PHistory;
  P: PString;
  S: String;

function IsSearchHistory(P: PView): Boolean; far;
begin
  IsSearchHistory := (TypeOf(P^) = TypeOf(THistory)) and (P^.Origin.Y = 3);
end;

begin
  if RegExpDialogInUse then Exit;
  RegExpDialogInUse := True;
  D := PRegExpDialog(Resource^.Get('REGEXPDIALOG'));
  if D <> nil then with D^ do
  begin
    CaseCheckBox^.Value := RegExpDialogCheck;
    H := PHistory(FirstThat(@IsSearchHistory));
    if H <> nil then
    begin
      H^.HistoryPutFunc := RegExpDlgPutHistoryFunc;
      H^.HistoryGetFunc := RegExpDlgGetHistoryFunc;
    end;
    D^.PostProcessEvent := RegExpDialogProc;
    if NoModalWindows then P :=
      Message(Application, evBroadcast, cmGetLine, Application)
    else P := nil;
    if P <> nil then SourceInputLine^.Data^ := Trim(P^)
    else SourceInputLine^.Data^ := HistoryStr(RegExpDlgHistoryId, 0);
    ReplaceInputLine^.Data^ := HistoryStr(ReplaceHistoryId, 0);
    S := HistoryStr(FindHistoryId, 0);
    SearchInputLine^.SetData(S);
    if Application^.ExecuteDialog(D, nil, False) = cmOk then
    begin
      Pending.What := evCommand;
      Pending.Command := cmAutoRegExp;
    end;
  end
  else ResourceNotFoundMsgBox('Regexp debugger dialog');
  RegExpDialogInUse := False;
end;

procedure AutoRegExp;
var
  L: Longint;
  W: PView;
  E: PFileEditor;
  S: String;
begin
  if NoModalWindows then
  begin
    W := Desktop^.Current;
    if W = nil then Exit;
    if TypeOf(W^) = TypeOf(TPanelWindow) then
    begin
      S := '>' + RegExpDlgGetHistoryFunc(nil, HistoryStr(FindHistoryId, 0)) +
           '>' + HistoryStr(ReplaceHistoryId, 0);
      PPanelWindow(W)^.GetCurrentPanel;
      L := FMOptions;
      FMOptions := FMOptions or foDragPrompt;
      if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
        FMCopyPrim(PPanelWindow(W)^.CurrentPanel, S, False)
      else FMrenMovPrim(PPanelWindow(W)^.CurrentPanel, S, False);
      FMOptions := L;
    end
    else if W^.Options and ofASCII <> 0 then
    begin
      E := PFileEditor(PEditorWindow(W)^.Editor);
      L := E^.LocalEditOptions;
      E^.LocalEditOptions := E^.LocalEditOptions and not eoFindTextAtCursor;
      if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
        FindPrim(E, False)
      else ReplacePrim(E, True);
      E^.LocalEditOptions := L;
    end;
  end;
end;

end.