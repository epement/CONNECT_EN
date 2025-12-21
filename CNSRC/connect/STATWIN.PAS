{$I-,X+,O+,F+}
unit StatWin;

interface

uses Objects, Drivers, Views, Dialogs, BarWin;

type
  PStatusText = ^TStatusText;
  TStatusText = object(TStaticText)
    function GetPalette: PPalette; virtual;
    procedure NewText(const AText: String);
  end;

  PLineText = ^TLineText;
  TLineText = object(TStaticText)
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    function GetMouseShape(var Event: TEvent): Char; virtual;
  end;

  PStatusWindow = ^TStatusWindow;
  TStatusWindow = object(TBarWindow)
    Protocol, BlockCheck, FileName, FileSize, BlockSize, TotalBlocks,
    BytesTransferred, BytesRemaining, BlocksTransferred, BlocksRemaining,
    BlockErrors, TotalErrors, EstimatedTime, ElapsedTime, RemainingTime,
    Throughput, Efficiency, Percent, Status, Baud, DataBits, StopBits,
    Parity, SoftwareFlow, HardwareFlow: PStatusText;
    constructor Init(const ATitle: TTitleStr; ALeft: Boolean);
    constructor Load(var S: TStream);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
  end;

const
  StatusWindow: PStatusWindow = nil;

procedure RSRStatusWindow(RSR: PResourceFile);
procedure OpenStatusWindow(ATitle: TTitleStr; ALeft: Boolean);

implementation

uses App, MsgBox, EditMsg, AsynPrim, Consts;

function TStatusText.GetPalette: PPalette;
const
  P: String[1] = #1;
begin
  GetPalette := @P;
end;

procedure TStatusText.NewText(const AText: String);
begin
  DisposeStr(Text);
  Text := NewStr(AText);
  DrawView;
end;

procedure TLineText.Draw;
var
  C: Byte;
  C1, C2: Char;
  B: TDrawBuffer;
begin
  if State and sfDragging = 0 then
  begin
    C := GetColor(1);
    C1 := 'Ç';
    C2 := '¶';
  end
  else
  begin
    C := GetColor(2);
    C1 := 'Ã';
    C2 := '´';
  end;
  MoveChar(B, 'Ä', C, Size.X);
  MoveChar(B[0], C1, C, 1);
  MoveChar(B[Size.X - 1], C2, C, 1);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TLineText.GetPalette: PPalette;
const
  P: String[2] = #2#3;
begin
  GetPalette := @P;
end;

procedure TLineText.SetState(AState: Word; Enable: Boolean);
begin
  TStaticText.SetState(AState, Enable);
  DrawView;
end;

function TLineText.GetMouseShape(var Event: TEvent): Char;
begin
  GetMouseShape := PWindow(Owner)^.Frame^.GetMouseShape(Event);
end;

constructor TStatusWindow.Init(const ATitle: TTitleStr; ALeft: Boolean);
const
  ModeStr: Array[Boolean] of String[8] =
    ('sent', 'received');
var
  R: TRect;
begin
  R.Assign(0, 0, 62, 19);
  TWindow.Init(R, ATitle, wnNoNumber);
  HelpCtx := hcStatusWindow;
  Flags := wfMove;
  GrowMode := gfExplode;
  Options := Options or (ofCentered + ofNotStorable);

  R.Assign(3, 1, 19, 2);
  Insert(New(PStaticText, Init(R, 'Protocol:')));
  R.Assign(19, 1, Size.X div 2, 2);
  Protocol := New(PStatusText, Init(R, ''));
  Insert(Protocol);

  R.Assign(3, 2, 19, 3);
  Insert(New(PStaticText, Init(R, 'Block check:')));
  R.Assign(19, 2, Size.X div 2, 3);
  BlockCheck := New(PStatusText, Init(R, ''));
  Insert(BlockCheck);

  R.Assign(3, 3, 19, 4);
  Insert(New(PStaticText, Init(R, 'File name:')));
  R.Assign(19, 3, Size.X div 2, 4);
  FileName := New(PStatusText, Init(R, ''));
  Insert(FileName);

  R.Assign(3, 4, 19, 5);
  Insert(New(PStaticText, Init(R, 'File size:')));
  R.Assign(19, 4, Size.X div 2, 5);
  FileSize := New(PStatusText, Init(R, ''));
  Insert(FileSize);

  R.Assign(3, 5, 19, 6);
  Insert(New(PStaticText, Init(R, 'Block size:')));
  R.Assign(19, 5, Size.X div 2, 6);
  BlockSize := New(PStatusText, Init(R, ''));
  Insert(BlockSize);

  R.Assign(3, 6, 19, 7);
  Insert(New(PStaticText, Init(R, 'Total blocks:')));
  R.Assign(19, 6, Size.X div 2, 7);
  TotalBlocks := New(PStatusText, Init(R, ''));
  Insert(TotalBlocks);

  R.Assign(34, 1, 51, 2);
  Insert(New(PStaticText, Init(R, 'Bytes ' + ModeStr[ALeft] + ':')));
  R.Assign(51, 1, Size.X - 3, 2);
  BytesTransferred := New(PStatusText, Init(R, ''));
  Insert(BytesTransferred);

  R.Assign(34, 2, 51, 3);
  Insert(New(PStaticText, Init(R, 'Bytes remaining:')));
  R.Assign(51, 2, Size.X - 3, 3);
  BytesRemaining := New(PStatusText, Init(R, ''));
  Insert(BytesRemaining);

  R.Assign(34, 3, 51, 4);
  Insert(New(PStaticText, Init(R, 'Blocks ' + ModeStr[ALeft] + ':')));
  R.Assign(51, 3, Size.X - 3, 4);
  BlocksTransferred := New(PStatusText, Init(R, ''));
  Insert(BlocksTransferred);

  R.Assign(34, 4, 51, 5);
  Insert(New(PStaticText, Init(R, 'Blocks remaining:')));
  R.Assign(51, 4, Size.X - 3, 5);
  BlocksRemaining := New(PStatusText, Init(R, ''));
  Insert(BlocksRemaining);

  R.Assign(34, 5, 51, 6);
  Insert(New(PStaticText, Init(R, 'Block errors:')));
  R.Assign(51, 5, Size.X - 3, 6);
  BlockErrors := New(PStatusText, Init(R, ''));
  Insert(BlockErrors);

  R.Assign(34, 6, 51, 7);
  Insert(New(PStaticText, Init(R, 'Total errors:')));
  R.Assign(51, 6, Size.X - 3, 7);
  TotalErrors := New(PStatusText, Init(R, ''));
  Insert(TotalErrors);

  R.Assign(3, 8, 19, 9);
  Insert(New(PStaticText, Init(R, 'Estimated time:')));
  R.Assign(19, 8, Size.X div 2, 9);
  EstimatedTime := New(PStatusText, Init(R, ''));
  Insert(EstimatedTime);

  R.Assign(3, 9, 19, 10);
  Insert(New(PStaticText, Init(R, 'Elapsed time:')));
  R.Assign(19, 9, Size.X div 2, 10);
  ElapsedTime := New(PStatusText, Init(R, ''));
  Insert(ElapsedTime);

  R.Assign(3, 10, 19, 11);
  Insert(New(PStaticText, Init(R, 'Remaining time:')));
  R.Assign(19, 10, Size.X div 2, 11);
  RemainingTime := New(PStatusText, Init(R, ''));
  Insert(RemainingTime);

  R.Assign(34, 8, 51, 9);
  Insert(New(PStaticText, Init(R, 'Throughput:')));
  R.Assign(51, 8, Size.X - 3, 9);
  Throughput := New(PStatusText, Init(R, ''));
  Insert(Throughput);

  R.Assign(34, 9, 51, 10);
  Insert(New(PStaticText, Init(R, 'Efficiency:')));
  R.Assign(51, 9, Size.X - 3, 10);
  Efficiency := New(PStatusText, Init(R, ''));
  Insert(Efficiency);

  R.Assign(0, 11, Size.X, 12);
  Insert(New(PLineText, Init(R, '')));

  R.Assign(3, 12, 19, 13);
  Insert(New(PStaticText, Init(R, 'Progress:')));

  R.Assign(19, 12, Size.X - 8, 13);
  Bar := New(PBarView, Init(R, 1, ALeft));
  Insert(Bar);

  R.Assign(Size.X - 7, 12, Size.X - 3, 13);
  Percent := New(PStatusText, Init(R, ''));
  Insert(Percent);

  R.Assign(3, 13, 19, 14);
  Insert(New(PStaticText, Init(R, 'Status:')));
  R.Assign(19, 13, Size.X - 3, 14);
  Status := New(PStatusText, Init(R, ''));
  Insert(Status);

  R.Assign(0, 14, Size.X, 15);
  Insert(New(PLineText, Init(R, '')));

  R.Assign(3, 15, 19, 16);
  Insert(New(PStaticText, Init(R, 'Baud:')));
  R.Assign(19, 15, Size.X div 2, 16);
  Baud := New(PStatusText, Init(R, ''));
  Insert(Baud);

  R.Assign(3, 16, 19, 17);
  Insert(New(PStaticText, Init(R, 'Data bits:')));
  R.Assign(19, 16, Size.X div 2, 17);
  DataBits := New(PStatusText, Init(R, ''));
  Insert(DataBits);

  R.Assign(3, 17, 19, 18);
  Insert(New(PStaticText, Init(R, 'Software flow:')));
  R.Assign(19, 17, Size.X div 2, 18);
  SoftwareFlow := New(PStatusText, Init(R, ''));
  Insert(SoftwareFlow);

  R.Assign(34, 15, 51, 16);
  Insert(New(PStaticText, Init(R, 'Stop bits:')));
  R.Assign(51, 15, Size.X - 3, 16);
  StopBits := New(PStatusText, Init(R, ''));
  Insert(StopBits);

  R.Assign(34, 16, 51, 17);
  Insert(New(PStaticText, Init(R, 'Parity')));
  R.Assign(51, 16, Size.X - 3, 17);
  Parity := New(PStatusText, Init(R, ''));
  Insert(Parity);

  R.Assign(34, 17, 51, 18);
  Insert(New(PStaticText, Init(R, 'Hardware flow')));
  R.Assign(51, 17, Size.X - 3, 18);
  HardwareFlow := New(PStatusText, Init(R, ''));
  Insert(HardwareFlow);
end;

constructor TStatusWindow.Load(var S: TStream);
begin
  TBarWindow.Load(S);
  GetSubViewPtr(S, Bar);
  GetSubViewPtr(S, Protocol);
  GetSubViewPtr(S, BlockCheck);
  GetSubViewPtr(S, FileName);
  GetSubViewPtr(S, FileSize);
  GetSubViewPtr(S, BlockSize);
  GetSubViewPtr(S, TotalBlocks);
  GetSubViewPtr(S, BytesTransferred);
  GetSubViewPtr(S, BytesRemaining);
  GetSubViewPtr(S, BlocksTransferred);
  GetSubViewPtr(S, BlocksRemaining);
  GetSubViewPtr(S, BlockErrors);
  GetSubViewPtr(S, TotalErrors);
  GetSubViewPtr(S, EstimatedTime);
  GetSubViewPtr(S, ElapsedTime);
  GetSubViewPtr(S, RemainingTime);
  GetSubViewPtr(S, Throughput);
  GetSubViewPtr(S, Efficiency);
  GetSubViewPtr(S, Percent);
  GetSubViewPtr(S, Status);
  GetSubViewPtr(S, Baud);
  GetSubViewPtr(S, DataBits);
  GetSubViewPtr(S, StopBits);
  GetSubViewPtr(S, Parity);
  GetSubViewPtr(S, SoftwareFlow);
  GetSubViewPtr(S, HardwareFlow);
  Frame^.State := Frame^.State or sfActive;
end;

procedure TStatusWindow.HandleEvent(var Event: TEvent);
begin
  TBarWindow.HandleEvent(Event);
  if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
  begin
    CancelReq := True;
    Event.What := evNothing;
  end;
  if (Event.What = evCommand) and (Event.Command = cmClose) then
  begin
    ProtInProgMsgBox('close protocol status window');
    Event.What := evNothing;
  end;
end;

procedure TStatusWindow.SetState(AState: Word; Enable: Boolean);
const
  WindowCommands = [cmResize, cmNext, cmPrev];
begin
  TBarWindow.SetState(AState, Enable);
  if (AState = sfSelected) or
     ((AState = sfExposed) and (State and sfSelected <> 0)) then
    if Enable then EnableCommands(WindowCommands)
    else DisableCommands(WindowCommands);
end;

procedure TStatusWindow.Store(var S: TStream);
begin
  TBarWindow.Store(S);
  PutSubViewPtr(S, Bar);
  PutSubViewPtr(S, Protocol);
  PutSubViewPtr(S, BlockCheck);
  PutSubViewPtr(S, FileName);
  PutSubViewPtr(S, FileSize);
  PutSubViewPtr(S, BlockSize);
  PutSubViewPtr(S, TotalBlocks);
  PutSubViewPtr(S, BytesTransferred);
  PutSubViewPtr(S, BytesRemaining);
  PutSubViewPtr(S, BlocksTransferred);
  PutSubViewPtr(S, BlocksRemaining);
  PutSubViewPtr(S, BlockErrors);
  PutSubViewPtr(S, TotalErrors);
  PutSubViewPtr(S, EstimatedTime);
  PutSubViewPtr(S, ElapsedTime);
  PutSubViewPtr(S, RemainingTime);
  PutSubViewPtr(S, Throughput);
  PutSubViewPtr(S, Efficiency);
  PutSubViewPtr(S, Percent);
  PutSubViewPtr(S, Status);
  PutSubViewPtr(S, Baud);
  PutSubViewPtr(S, DataBits);
  PutSubViewPtr(S, StopBits);
  PutSubViewPtr(S, Parity);
  PutSubViewPtr(S, SoftwareFlow);
  PutSubViewPtr(S, HardwareFlow);
end;

procedure RSRStatusWindow(RSR: PResourceFile);
var
  W: PStatusWindow;
begin
  W := New(PStatusWindow, Init('', False));
  RSR^.Put(W, 'STATUSWINDOW');
  Dispose(W, Done);
end;

procedure OpenStatusWindow(ATitle: TTitleStr; ALeft: Boolean);
var
  B: Boolean;
begin
  B := StatusWindow <> nil;
  if not B then StatusWindow := PStatusWindow(Resource^.Get('STATUSWINDOW'));
  if StatusWindow <> nil then
  begin
    StatusWindow := PStatusWindow(Application^.ValidView(StatusWindow));
    if StatusWindow = nil then Exit;
    DisposeStr(StatusWindow^.Title);
    StatusWindow^.Title := NewStr(ATitle);
    StatusWindow^.Bar^.Left := ALeft;
    if not B then Desktop^.Insert(StatusWindow)
    else StatusWindow^.Frame^.DrawView;
  end
  else ResourceNotFoundMsgBox('Status window');
end;

end.
