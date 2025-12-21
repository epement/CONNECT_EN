{$F+,O+,X+}
unit HTMLHist;

interface

uses Objects, Drivers, Views, Dialogs, HistWin;

type
  PHTMLHistViewer = ^THTMLHistViewer;
  THTMLHistViewer = object(TSpecialHistViewer)
    List: PCollection;
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar;
      AHistoryId: Word);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    function GetCopyText(Item: Integer; MaxLen: Integer): String; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PHTMLHistWindow = ^THTMLHistWindow;
  THTMLHistWindow = object(TSpecialHistWindow)
    function GetSelection: String; virtual;
    procedure InitViewer(HistoryId: Word); virtual;
  end;

function GetHTMLHistIndex(AList: PCollection; ACurIndex: Integer): Integer;

implementation

uses App, HTMLView, TPString, Consts;

procedure HTMLHistText(P: PHTMLItem; var S: String);
begin
  S := '';
  if P <> nil then
    if P^.PFName <> nil then
      if P^.PRefName <> nil then S := Concat(
        P^.PRefName^, ' (', P^.PFName^, ')')
      else S := P^.PFName^
    else if P^.PRefName <> nil then S := P^.PRefName^;
end;

constructor THTMLHistViewer.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar; AHistoryId: Word);
begin
  TListViewer.Init(Bounds, 1, AHScrollBar, AVScrollBar);
  GrowMode := gfGrowHiX + gfGrowHiY;
  HistoryId := AHistoryId;
  HScrollBar^.SetRange(0, 255);
  IncrPos := 1;
end;

procedure THTMLHistViewer.ChangeBounds(var Bounds: TRect);
begin
  TListViewer.ChangeBounds(Bounds);
  SetRange(Range);
  HScrollBar^.SetRange(0, 255);
end;

function THTMLHistViewer.GetCopyText(Item: Integer; MaxLen: Integer): String;
var
  S: String;
begin
  HTMLHistText(List^.At(Item), S);
  GetCopyText := S;
end;

function THTMLHistViewer.GetText(Item: Integer; MaxLen: Integer): String;
var
  S: String;
begin
  HTMLHistText(List^.At(Item), S);
  S := '  ' + S;
  if Item = HistoryID then S[1] := '';
  GetText := S;
end;

procedure THTMLHistViewer.HandleEvent(var Event: TEvent);

procedure FindMatch;
var
  C: Char;
  Offset, CurOfs: Byte;
  Index: Integer;
  SearchStr, S: String;
begin
  C := Upcase(Event.CharCode);
  HTMLHistText(PHTMLItem(List^.At(Focused)), SearchStr);
  UpcaseSt(SearchStr);
  Offset := 1;
  if IncrPos < Offset then CurOfs := 0
  else CurOfs := IncrPos - Offset;
  SearchStr[0] := Char(CurOfs);
  Index := 0;
  if C = ^L then Index := Focused + 1
  else if C = #8 then
  begin
    if IncrPos <= Offset + 1 then
    begin
      FocusItem(Focused);
      if HScrollBar <> nil then HScrollBar^.SetValue(0);
      Exit;
    end;
    Dec(SearchStr[0]);
  end
  else
  begin
    Inc(SearchStr[0]);
    SearchStr[Length(SearchStr)] := C;
  end;
  if SearchStr = '' then Exit;
  while Index < Range do
  begin
    HTMLHistText(PHTMLItem(List^.At(Index)), S);
    UpcaseSt(S);
    if Pos(SearchStr, S) = 1 then
    begin
      Inc(Offset, CurOfs);
      if C = #8 then Dec(Offset)
      else if C <> ^L then Inc(Offset);
      FocusItem(Index);
      IncrPos := Offset;
      DrawView;
      ShowCursor;
      if HScrollBar <> nil then
        if Cursor.X < 1 then
          HScrollBar^.SetValue(HScrollBar^.Value + Cursor.X - 1)
        else if Cursor.X >= Size.X then
          HScrollBar^.SetValue(HScrollBar^.Value + Cursor.X - Size.X + 1);
      Break;
    end;
    Inc(Index);
  end;
end;

begin
  if (Range <> 0) and (Event.What = evKeyDown) and
     (Event.CharCode in [^L, #8, #33..#255]) then
  begin
    FindMatch;
    Event.What := evNothing;
  end;
  if ((Event.What = evMouseDown) and (Event.Double)) or
     ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    EndModal(cmOk);
    Event.What := evNothing;
  end else if ((Event.What = evKeyDown) and (Event.KeyCode = kbEsc)) or
    ((Event.What = evCommand) and (Event.Command = cmCancel)) then
  begin
    EndModal(cmCancel);
    Event.What := evNothing;
  end else if (Event.What = evKeyDown) and (Event.KeyCode = kbDel) then
  begin
    List^.AtFree(Focused);
    if (HistoryId > 0) and (Focused <= HistoryId) then Dec(HistoryId);
    SetRange(List^.Count);
    HScrollBar^.SetRange(0, 255);
    FocusItem(Focused);
    DrawView;
    Event.What := evNothing;
  end else TListViewer.HandleEvent(Event);
end;

function THTMLHistWindow.GetSelection: String;
begin
end;

procedure THTMLHistWindow.InitViewer(HistoryId: Word);
var
  R: TRect;
begin
  GetExtent(R);
  R.Grow(-1, -1);
  Viewer := New(PHTMLHistViewer, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard), HistoryId));
  Insert(Viewer);
end;

function GetHTMLHistIndex(AList: PCollection; ACurIndex: Integer): Integer;
var
  I, Count: Integer;
  W: PHTMLHistWindow;
  R: TRect;
begin
  GetHTMLHistIndex := -1;
  Count := AList^.Count;
  if Count <= Desktop^.Size.Y - MinWinSize.Y - 2 then
    I := Count + MinWinSize.Y
  else I := Desktop^.Size.Y - 2;
  if ACurIndex > 0 then Dec(ACurIndex);
  R.Assign(0, 0, 51, I);
  W := New(PHTMLHistWindow, Init(R, ACurIndex));
  DisposeStr(W^.Title);
  W^.Title := NewStr('HTML history');
  W^.Options := W^.Options or ofCentered;
  W^.HelpCtx := hcHTMLHistory;
  PHTMLHistViewer(W^.Viewer)^.List := AList;
  W^.Viewer^.SetRange(AList^.Count);
  W^.Viewer^.FocusItem(ACurIndex);
  if Application^.ValidView(W) <> nil then
  begin
    if Desktop^.ExecView(W) = cmOk then
      GetHTMLHistIndex := W^.Viewer^.Focused;
    Dispose(W, Done);
  end;
end;

end.
