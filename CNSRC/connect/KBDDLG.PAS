{$F+,O+}
unit KbdDlg;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PScrollTester = ^TScrollTester;
  TScrollTester = object(TView)
    TopLine: Integer;
    constructor Init(var Bounds: TRect);
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure GoWhileKeyDown(Key: Byte);
    procedure GoUpPrim;
    procedure GoDownPrim;
    procedure GoUp;
    procedure GoDown;
  end;

  PKbdDialog = ^TKbdDialog;
  TKbdDialog = object(TDialog)
    KbdScrollBar: PScrollBar;
    Int09Check: PCheckBoxes;
    constructor Init;
  end;

procedure KbdDialog;

implementation

uses CNCrt, App, Keyboard, Consts;

const
  NumLines = 4;
  CScrollTester = #26;

constructor TScrollTester.Init(var Bounds: TRect);
begin
  TView.Init(Bounds);
  Options := Options or ofPreProcess;
  GrowMode := gfGrowHiY;
end;

function TScrollTester.GetPalette: PPalette;
const
  P: String[Length(CScrollTester)] = CScrollTester;
begin
  GetPalette := @P;
end;

procedure TScrollTester.Draw;
const
  Lines: Array[0..NumLines - 1] of String[28] =
    ('Press Up and Down arrow keys', 'to test vertical scroll rate',
     'Press Left and Right keys to', 'speed it up, or slow it down');
var
  C: Word;
  Count, I, R: Integer;
  B: TDrawBuffer;
begin
  C := GetColor(1);
  for R := 0 to 10 do
  begin
    I := TopLine;
    for Count := 0 to Size.Y - 1 do
    begin
      MoveChar(B, ' ', C, Size.X);
      MoveStr(B, Lines[I], C);
      Inc(I);
      if I > NumLines - 1 then I := 0;
      WriteLine(0, Count, Size.X, 1, B);
    end;
  end;
end;

procedure TScrollTester.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    case CtrlToArrow(Event.KeyCode) of
      kbUp: GoUp;
      kbDown: GoDown;
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

procedure TScrollTester.GoDownPrim;
begin
  Inc(TopLine);
  if TopLine > NumLines - 1 then TopLine := 0;
  DrawView;
end;

procedure TScrollTester.GoUpPrim;
begin
  Dec(TopLine);
  if TopLine < 0 then TopLine := NumLines - 1;
  DrawView;
end;

procedure TScrollTester.GoWhileKeyDown(Key: Byte);
begin
  repeat
    if (KbdStatus <> Key) and (KbdStatus <> 224) then Exit;
  until KeyPressed;
  repeat
    ClearKbd;
    if (KbdStatus <> Key) and (KbdStatus <> 224) then Exit;
    case Key of
      72: GoUpPrim;
      80: GoDownPrim;
    end;
    with PKbdDialog(Owner)^ do
      if KbdScrollBar^.Value <> 0 then
	Delay(Word(KbdScrollBar^.Value) shl 3);
  until False;
end;

procedure TScrollTester.GoDown;
begin
  GoDownPrim;
  if PKbdDialog(Owner)^.Int09Check^.Value <> 0 then Exit;
  if ((KbdStatus = 80) or (KbdStatus = 224)) then GoWhileKeyDown(80);
end;

procedure TScrollTester.GoUp;
begin
  GoUpPrim;
  if PKbdDialog(Owner)^.Int09Check^.Value <> 0 then Exit;
  if ((KbdStatus = 72) or (KbdStatus = 224)) then GoWhileKeyDown(72);
end;

constructor TKbdDialog.Init;
var
  R: TRect;
  Control: PView;
begin
  R.Assign(0, 0, 34, ScreenHeight - 2);
  TDialog.Init(R, 'Keyboard options');
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;

  R.Assign(3, 4, 31, 5);
  KbdScrollBar := New(PScrollBar, Init(R));
  KbdScrollBar^.SetParams(KbdDelay shr 3, 0, KbdScrollBar^.Size.X - 1, 1, 1);
  KbdScrollBar^.Options := KbdScrollBar^.Options or ofPreProcess;
  KbdScrollBar^.GrowMode := gfGrowHiX;
  Insert(KbdScrollBar);
  R.Assign(3, 3, 32, 4);
  Insert(New(PStaticText, Init(R, 'Fast       Medium       Slow')));
  R.Assign(2, 2, 32, 3);
  Insert(New(PLabel, Init(R, 'Vertical scroll speed', KbdScrollbar)));

  R.Assign(3, 7, Size.X - 3, Size.Y - 8);
  Control := New(PScrollTester, Init(R));
  Insert(Control);
  R.Assign(2, 6, 31, 7);
  Insert(New(PLabel, Init(R, 'Speed tester', Control)));

  R.Assign(3, Size.Y - 7, Size.X - 3, Size.Y - 4);
  Int09Check := New(PCheckBoxes, Init(R,
    NewSItem('Use INT 0~9~ key handler',
    NewSItem('Disable ~e~nhanced keys',
    NewSItem('Disable ~m~ultiscrolling', nil)))));
  Int09Check^.Options := Int09Check^.Options and not ofPreProcess;
  Int09Check^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Int09Check);

  R.Assign(2, Size.Y - 3, 12, Size.Y - 1);
  Control := StandardOkButton(R, @Self);
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Inc(R.A.X, 20); Inc(R.B.X, 20);
  Control := StandardCancelButton(R, @Self);
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;

  HelpCtx := hcKbdDialog;
  SelectNext(False);
end;

procedure KbdDialog;
var
  W: Word;
  D: PKbdDialog;
begin
  D := New(PKbdDialog, Init);
  if Application^.ValidView(D) <> nil then
  begin
    W := KeyboardOptions;
    D^.SetData(W);
    if Desktop^.ExecView(D) <> cmCancel then
    begin
      D^.GetData(W);
      KeyboardOptions := W;
      KbdDelay := Word(D^.KbdScrollBar^.Value) shl 3;
      DelayInit;
    end;
    Dispose(D, Done);
  end;
end;

end.
