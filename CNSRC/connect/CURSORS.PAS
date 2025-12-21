{$F+,O+}
unit Cursors;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PCursorView = ^TCursorView;
  TCursorView = object(TView)
    CursorPtr: Pointer;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure CursorGrow(Key: Word);  virtual;
  end;

procedure CursorDialog;

implementation

uses App, TPString, Defaults, Consts, Commands;

procedure TCursorView.Draw;
var
  C, D: Word;
  B: TDrawBuffer;
begin
  C := GetColor(19);
  D := GetColor(21);

  MoveChar(B, ' ', C, Size.X);
  MoveChar(B, '', D, 1);
  MoveStr(B[2], HexB(WordRec(CursorPtr^).Hi), C);
  MoveChar(B[5], '', D, 1);
  WriteLine(0, 0, Size.X, 1, B);

  MoveChar(B, ' ', C, Size.X);
  WriteLine(0, 1, Size.X, 1, B);

  MoveChar(B, ' ', C, Size.X);
  MoveChar(B, '', D, 1);
  MoveStr(B[2], HexB(WordRec(CursorPtr^).Lo), C);
  MoveChar(B[5], '', D, 1);
  WriteLine(0, 2, Size.X, 1, B);
end;

procedure TCursorView.HandleEvent(var Event: TEvent);
var
  Key: Word;
  Spot: TPoint;
begin
  TView.HandleEvent(Event);
  Key := 0;
  if Event.What = evKeyDown then Key := CtrlToArrow(Event.KeyCode)
  else if Event.What and (evMouseDown + evMouseAuto) <> 0 then
  begin
    MakeLocal(Event.Where, Spot);
    if Spot.Y = 0 then
      if Spot.X = 0 then Key := kbUp
      else if Spot.X = 5 then Key := kbDown else
    else if Spot.Y = 2 then
      if Spot.X = 0 then Key := kbLeft
      else if Spot.X = 5 then Key := kbRight;
  end
  else if (Event.What = evCommand) and (Event.Command = cmCursor) then
  begin
    CursorLines := DefaultCursor;
    BlockCursorLines := $0007;
    DrawView;
  end;
  case Key of
    kbUp, kbDown, kbLeft, kbRight:
      begin
	CursorGrow(Key);
	Event.What := evNothing;
      end;
  end;
end;

procedure TCursorView.CursorGrow(Key: Word);
begin
  case Key of
    kbDown:
      if WordRec(CursorPtr^).Hi < $FF then Inc(WordRec(CursorPtr^).Hi);
    kbUp:
      if WordRec(CursorPtr^).Hi > 0 then Dec(WordRec(CursorPtr^).Hi);
    kbRight:
      if WordRec(CursorPtr^).Lo < $FF then Inc(WordRec(CursorPtr^).Lo);
    kbLeft:
      if WordRec(CursorPtr^).Lo > 0 then Dec(WordRec(CursorPtr^).Lo);
  end;
  DrawView;
end;

procedure CursorDialog;
var
  SaveCursor, SaveBlockCursor: Word;
  Control: PView;
  D: PDialog;
  R: TRect;
begin
  SaveCursor := CursorLines;
  SaveBlockCursor := BlockCursorLines;
  R.Assign(0, 0, 40, 12);
  D := New(PDialog, Init(R, 'Cursor size'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcOCursor;

    R.Assign(4, 2, 37, 3);
    Insert(New(PStaticText, Init(R,
      #24#25' change top   '#27#26' change bottom')));

    R.Assign(9, 5, 15, 8);
    Control := New(PCursorView, Init(R));
    Control^.Options := Control^.Options or (ofSelectable + ofPostProcess);
    Control^.EventMask := Control^.EventMask or evMouseAuto;
    PCursorView(Control)^.CursorPtr := @CursorLines;
    Insert(Control);
    Control^.ShowCursor;
    Control^.SetCursor(2, 1);
    R.Assign(8, 4, 15, 5);
    Insert(New(PLabel, Init(R, '~N~ormal', Control)));

    R.Assign(24, 5, 30, 8);
    Control := New(PCursorView, Init(R));
    Control^.Options := Control^.Options or (ofSelectable + ofPostProcess);
    Control^.EventMask := Control^.EventMask or evMouseAuto;
    PCursorView(Control)^.CursorPtr := @BlockCursorLines;
    Insert(Control);
    Control^.BlockCursor;
    Control^.ShowCursor;
    Control^.SetCursor(2, 1);
    R.Assign(23, 4, 30, 5);
    Insert(New(PLabel, Init(R, '~B~lock', Control)));

    R.Assign(2, Size.Y - 3, 12, Size.Y - 1);
    StandardOkButton(R, D);
    Inc(R.A.X, 12); Inc(R.B.X, 13);
    Insert(New(PButton, Init(R, '~D~efault', cmCursor, bfNormal)));
    Inc(R.A.X, 13); Inc(R.B.X, 12);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  if Application^.ExecuteDialog(D, nil, False) = cmCancel then
  begin
    CursorLines := SaveCursor;
    BlockCursorLines := SaveBlockCursor;
  end
  else
  begin
    PtrRec(Control).Ofs := CursorLines;
    PtrRec(Control).Seg := BlockCursorLines;
    Message(Desktop, evBroadcast, cmCursor, Control);
  end;
  Application^.Redraw;
end;

end.
