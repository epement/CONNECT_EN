{$I-,O+,F+,X+}
unit OpenPrim;

interface

uses Objects;

procedure GetBoundsForNewWindow(var R: TRect);
procedure OpenFile(Hex: Boolean);
procedure LoadFile(const FileName: String;
  InfoPtr: Pointer; View, Hex: Boolean);
procedure Reopen(Index: Integer);
procedure Update(Hex: Boolean);
procedure LoadIcon(NamePtr: PString);
procedure FillStartOpenList(Names: PCollection;
  var Mask: FNameStr; var DoOpen: Boolean);
procedure ProcessStartOpenList(Names: PCollection);

implementation

uses Dos, Drivers, Views, App, StdDlg, HistList, History,
  FEditor, HEditor, TxtView, HexView, HTMLView, Terminal,
  Icons, ExecPrim, DirPrim, LFN, HeapUMB, TPString, Consts,
  Commands, Defaults;

procedure GetBoundsForNewWindow(var R: TRect);
var
  V: PView;
  Min, Max: TPoint;
  VR: TRect;
begin
  HistOpenWide := False;
  if HistOpenSize <> 0 then
  begin
    if HistOpenSize = OpenWideSign then
    begin
      Desktop^.GetExtent(R);
      HistOpenWide := True;
    end
    else
    begin
      Move(HistOpenOrg, R.A.X, SizeOf(TPoint));
      R.B.X := R.A.X + TPoint(HistOpenSize).X;
      R.B.Y := R.A.Y + TPoint(HistOpenSize).Y;
    end;
    HistOpenSize := 0;
    Exit;
  end;
  Desktop^.GetExtent(R);
  if EditOptions and eoCascade = 0 then Exit;
  V := Desktop^.Current;
  if V = nil then Exit;
  if V^.Options and ofTileable <> 0 then
  begin
    V^.SizeLimits(Min, Max);
    if (V^.Size.X > Min.X) and (V^.Size.Y > Min.Y) then
    begin
      V^.GetBounds(R);
      Inc(R.A.X); Inc(R.A.Y);
      Inc(R.B.Y, Byte(R.B.Y < Desktop^.Size.Y));
    end;
  end
  else if (V^.Options and ofValidate <> 0) and
    (PWindow(V)^.Flags and wfGrow <> 0) then
  begin
    V^.GetBounds(VR);
    if (V^.Owner^.Size.Y - VR.B.Y < VR.A.Y) and
       (VR.A.Y >= MinWinSize.Y) then R.B.Y := VR.A.Y
    else if V^.Owner^.Size.Y - VR.B.Y >= MinWinSize.Y then
      R.A.Y := VR.B.Y;
  end;
end;

procedure ZoomWide(W: PWindow);
var
  SaveShift: Byte;
begin
  HistOpenWide := False;
  SaveShift := GetShiftState;
  Mem[Seg0040:$17] := SaveShift or kbCtrlShift;
  Message(W, evCommand, cmZoom, nil);
  Mem[Seg0040:$17] := SaveShift;
end;

procedure LoadFile(const FileName: String;
  InfoPtr: Pointer; View, Hex: Boolean);
var
  Noname, HTML: Boolean;
  Ch: Char;
  C: Word;
  I: Integer;
  P: PView;
  Q: Pointer;
  W: PWindow;
  R: TRect;
  Name: String;

procedure SetTextViewParams(V: PView);
begin
  repeat
    I := Pos('/', ExecRec.Params);
    if (I = 0) or (I >= Length(ExecRec.Params)) then Break;
    begin
      Ch := Upcase(ExecRec.Params[I + 1]);
      if ((Ch = 'D') and PTextViewer(V)^.UnixMode) or
	 ((Ch = 'U') and not PTextViewer(V)^.UnixMode) then
	Message(V, evCommand, cmSetTextMode, nil)
      else if Ch = 'T' then PTextViewer(V)^.GoCtrlPgUp;
      Delete(ExecRec.Params, I, 2);
      TrimSt(ExecRec.Params);
    end;
  until False;
  if ExecRec.Params <> '' then
    PTextViewer(V)^.SetXLATTable(lFExpand(ExecRec.Params), False);
end;

begin
  Noname := FileName = '';
  HTML := False;
  if Noname then
    if View then HTML := True
    else Name := 'NONAME'
  else Name := FileName;
  if View then
    if HTML then C := cmOpenHTML
    else if Hex then C := cmOpenHexViewer
    else C := cmOpenTextViewer
  else
    if Hex then C := cmHexOpened
    else C := cmASCIIOpened;
  if HTML then Q := InfoPtr else Q := @Name;
  SameWinFlag := (InfoPtr = @ExecRec) and
    (ExecRec.Options and opInfoBit <> 0);
  P := Message(Desktop, evBroadcast, C, Q);
  if P = nil then
  begin
    GetBoundsForNewWindow(R);
    if Noname then Name := '';
    if View then
      if HTML then
      begin
	W := New(PHTMLWindow, Init(R, ExecRec.Path));
	PHTMLWindow(W)^.Viewer^.FindRef(ExecRec.Params);
      end
      else if Hex then W := New(PHexWindow, Init(R, Name))
      else
      begin
	W := New(PTextWindow, Init(R, Name));
	if InfoPtr = @ExecRec then
	  SetTextViewParams(PTextWindow(W)^.Viewer);
      end
    else
      if Hex then W := New(PHexEditorWindow, Init(R, Name))
      else W := New(PEditorWindow, Init(R, Name));
    W := Application^.InsertWindow(W);
    if HistOpenWide then ZoomWide(W);
  end
  else if View and not Hex and not HTML and (InfoPtr = @ExecRec) then
    SetTextViewParams(P);
  SameWinFlag := False;
end;

procedure OpenFile(Hex: Boolean);
var
  C: Word;
  V: PView;
  R: TRect;
  S: String[6];
  Name: FNameStr;
begin
  Name := HistoryStr(HistoryID, 0);
  if Hex then S := 'binary' else S := 'text';
  C := Application^.ExecuteDialog(
    New(PFileDialog, Init('*.*', 'Open a ' + S + ' file',
    '~N~ame', fdOpenButton + fdReplaceButton + fdHelpButton + fdView,
    HistoryID)), @Name, False);
  if C = cmFileReplace then
  begin
    if ViewLine then
      if Hex then C := cmOpenHexViewer else C := cmOpenTextViewer
    else
      if Hex then C := cmHexOpened else C := cmASCIIOpened;
    if Message(Desktop, evBroadcast, C, @Name) <> nil then Exit;
    if ViewLine then
      if Hex then C := cmIsHexViewer else C := cmIsTextViewer
    else
      if Hex then C := cmIsHex else C := cmIsASCII;
    V := Message(Desktop, evBroadcast, C, nil);
    if V <> nil then
    begin
      V^.Owner^.Select;
      if TypeOf(V^) = TypeOf(TTextViewer) then
	PTextViewer(V)^.ReRead(Name)
      else if TypeOf(V^) = TypeOf(THexViewer) then
	PHexViewer(V)^.ReRead(Name)
      else PFileEditor(V)^.UpdateLines(Name);
      Exit;
    end;
  end;
  if C <> cmCancel then LoadFile(Name, nil, ViewLine, Hex);
end;

procedure Reopen(Index: Integer);
var
  B, P: Integer;
  C: Word;
  S: String;
begin
  S := HistoryStr(ReopenHistoryID, Index);
  P := Pos(#$FF, S);
  if P < 10 then Exit;
  B := Pos(#$FF#$FF, S);
  if B >= P then Move(S[B + 2], HistOpenOrg, SizeOf(Longint) * 2);
  if S[1] = 'V' then C := cmOpenTextViewer
  else if S[1] = 'X' then C := cmOpenHexViewer
  else if S[1] = 'A' then C := cmOpenASCII
  else if S[1] = 'd' then C := cmOpenDataViewer
  else if (S[1] = 'H') and (S[2] = 'T') then C := cmOpenHTML
  else C := cmOpenHex;
  S := Copy(S, 7, P - 7);
  if C = cmOpenHTML then
  begin
    FillChar(ExecRec, SizeOf(ExecRec), 0);
    ExecRec.Path := S;
    Message(Application, evCommand, C, @ExecRec);
  end
  else Message(Application, evCommand, C, @S);
end;

procedure Update(Hex: Boolean);
const
  vtEditor = 0;
  vtTextViewer = 1;
  vtHexViewer = 2;
var
  Noname, SaveExplode, WasBack: Boolean;
  ViewType: Byte;
  C: Word;
  L: Longint;
  W: PView;
  R: TRect;
  Name: String;
begin
  W := Desktop^.Current;
  if W = nil then Exit;
  if W^.Options and (ofASCII + ofHex) <> 0 then
    ViewType := vtEditor
  else if TypeOf(W^) = TypeOf(TTextWindow) then
    ViewType := vtTextViewer
  else if TypeOf(W^) = TypeOf(THexWindow) then
    ViewType := vtHexViewer
  else Exit;
  if Hex then
    if Message(W, evCommand, cmUpdateHex, nil) <> nil then Exit else
  else if Message(W, evCommand, cmUpdateASCII, nil) <> nil then Exit;
  W^.GetBounds(R);
  L := 0;
  WasBack := False;
  if ViewType = vtEditor then with PEditorWindow(W)^ do
  begin
    C := PFileEditor(Editor)^.SaveOrCancel;
    if C = cmCancel then Exit;
    Name := PFileEditor(Editor)^.FileName^;
    if C = cmYes then
    begin
      if not PFileEditor(Editor)^.Save(Name, False) then Exit;
      Name := PFileEditor(Editor)^.FileName^;
    end;
    PFileEditor(Editor)^.IsModified := False;
    Noname := Editor^.State and sfNoname <> 0;
    if Editor = TheBack then WasBack := True;
  end
  else if ViewType = vtTextViewer then with PTextWindow(W)^ do
  begin
    Name := Viewer^.SourceName^;
    if Hex then
    begin
      L := Viewer^.CurPos.FilePos;
      if Viewer^.CurPos.LinePos > Viewer^.CurPos.LineLen then
	Inc(L, Viewer^.CurPos.LineLen)
      else Inc(L, Viewer^.CurPos.LinePos - 1);
    end
    else
    begin
      LongRec(L).Hi := Viewer^.GetCurLineNum;
      LongRec(L).Lo := Viewer^.CurPos.LinePos - 1;
    end;
  end
  else with PHexWindow(W)^ do
  begin
    C := Viewer^.SaveOnExit;
    if C = cmCancel then Exit;
    Name := Viewer^.SourceName^;
    if Hex then
    begin
      LongRec(L).Hi := Viewer^.CurPos shr 4;
      LongRec(L).Lo := Viewer^.CurPos mod 16;
    end
    else L := Viewer^.CurPos;
    if C = cmYes then Viewer^.Save;
    Viewer^.Status := Viewer^.Status and not $0020; {HexView.sfModified}
  end;
  SaveExplode := DoExplode;
  DoExplode := False;
  Desktop^.Lock;
  Message(W, evCommand, cmClose, nil);
  if WasBack then Dispose(W, Done);
  if ViewType = vtEditor then
    if Hex then C := cmHexOpened else C := cmASCIIOpened
  else if ViewType = vtTextViewer then
    if Hex then C := cmOpenHexViewer else C := cmASCIIOpened
  else
    if Hex then C := cmHexOpened else C := cmOpenTextViewer;
  if WasBack or (Message(Desktop, evBroadcast, C, @Name) = nil) then
  begin
    if ViewType = vtEditor then
    begin
      if Noname then Name := '';
      if Hex then
	if WasBack then
	begin
	  W := New(PHexBackWindow, Init(R, Name));
	  TerminalOptions := TerminalOptions or toHexBack;
	end
	else W := New(PHexEditorWindow, Init(R, Name))
      else
	if WasBack then
	begin
	  W := New(PBackWindow, Init(R, Name));
	  TerminalOptions := TerminalOptions and not toHexBack;
	end
	else W := New(PEditorWindow, Init(R, Name));
    end
    else if ViewType = vtTextViewer then
      if Hex then
      begin
	W := New(PHexWindow, Init(R, Name));
	PHexWindow(W)^.Viewer^.GoToPosition(L);
	PHexWindow(W)^.Viewer^.UpdatePosition;
      end
      else
      begin
	W := New(PEditorWindow, Init(R, Name));
	Message(W, evBroadcast, cmGoToLine, Pointer(L));
      end
    else
      if Hex then
      begin
	W := New(PHexEditorWindow, Init(R, Name));
	Message(W, evBroadcast, cmGoToLine, Pointer(L));
      end
      else
      begin
	W := New(PTextWindow, Init(R, Name));
	PTextWindow(W)^.Viewer^.GoToPosition(L, 1);
	PTextWindow(W)^.Viewer^.UpdatePosition;
      end;
    W^.Locate(R);
    Application^.InsertWindow(PWindow(W));
  end;
  Desktop^.Unlock;
  DoExplode := SaveExplode;
end;

procedure LoadIcon(NamePtr: PString);
var
  FileName: FNameStr;
begin
  if NamePtr = nil then
  begin
    FileName := HistoryStr(HistoryID, 0);
    if Application^.ExecuteDialog(
      New(PFileDialog, Init('*.*', 'Load a program icon',
      '~N~ame', fdOkButton + fdHelpButton, HistoryID)),
      @FileName, False) = cmCancel then Exit;
  end
  else FileName := NamePtr^;
  Application^.InsertWindow(New(PIcon, Init(FileName)));
end;

procedure FillStartOpenList(Names: PCollection;
  var Mask: FNameStr; var DoOpen: Boolean);
var
  I: Integer;
  Name: FNameStr;
begin
  for I := 1 to ParamCount do
  begin
    Name := ParamStr(I);
{ Added 20.09.2002 to support quoted LFNs }
    if (Length(Name) > 2) and (Name[1] = '"') and
       (Name[Length(Name)] = '"') then
    begin
      Dec(Name[0]);
      Delete(Name, 1, 1);
    end;
    if Name[Length(Name)] = '\' then Name := Name + '*.*';
{    if Pos('/', Name) <> 1 then Names^.Insert(NewStr(lFExpand(Name)))}
    if Pos('/', Name) <> 1 then Names^.Insert(NewStrUMB(lFExpand(Name)))
    else if (Length(Name) > 1) and (Upcase(Name[2]) = 'C') then
    begin
      Mask := Copy(Name, 3, 255);
      if Mask <> '' then Mask := lFExpand(Mask);
      DoOpen := (Mask = '') or IsWild(Mask);
      if not DoOpen then while Pos('.', Mask) <> 0 do Dec(Mask[0]);
    end;
  end;
end;

procedure ProcessStartOpenList(Names: PCollection);
var
  I: Integer;
  Name: FNameStr;
begin
  for I := 0 to Names^.Count - 1 do
  begin
    Name := PString(Names^.At(I))^;
    if not IsWild(Name) then LoadFile(Name, nil, False, False)
    else
    begin
      HistoryAdd(HistoryID, Name, True);
      OpenFile(False);
    end;
  end;
end;

end.