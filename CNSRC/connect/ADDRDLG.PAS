{$I-,X+,O+,F+}
unit AddrDlg;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PInputValue = ^TInputValue;
  TInputValue = object(TInputLine)
    IsDeselect: Boolean;
    constructor Init(var Bounds: TRect; AMaxLen: Integer;
      Deselect: Boolean);
    procedure SetState(AState: Word; Enable: Boolean); virtual;
  end;

function GetValue(var W: Word; var Initial: String;
  Deselect: Boolean; const ATitle, ALabel: String): Boolean;
function GetAddress(var Segment, Offset: Word;
  MakeCurrent: Boolean; CurrentPtr: Pointer;
  const ATitle, ALabel: String; AHelpCtx: Word): Boolean;

implementation

uses HistList, History, App, MsgBox, Disasm, Compiler, TPString, Consts;

const
  MaxRegisters = 13;

procedure InvalidNumberMsgBox;
begin
  MessageBox(^C'Invalid number. Valid range is'#13 +
    ^C'0 thru $FFFF.', nil, mfError + mfOkButton);
end;

constructor TInputValue.Init(var Bounds: TRect; AMaxLen: Integer;
  Deselect: Boolean);
begin
  TInputLine.Init(Bounds, AMaxLen);
  IsDeselect := Deselect;
end;

procedure TInputValue.SetState(AState: Word; Enable: Boolean);
begin
  TInputLine.SetState(AState, Enable);
  if IsDeselect then
  begin
    SelectAll(False);
    CurPos := Length(Data^);
  end;
end;

procedure Regs2Str(var Source: String);
const
  RegNames: Array[0..MaxRegisters - 1] of String[2] =
    ('AX', 'BX', 'CX', 'DX', 'SI', 'DI',
     'BP', 'SP', 'DS', 'ES', 'SS', 'CS', 'IP');
var
  I: Integer;
begin
  for I := 0 to MaxRegisters - 1 do
    if Trim(Source) = RegNames[I] then
    begin
      Source := '$' + HexW(PWordArray(@CPUStatus)^[I]);
      Exit;
    end;
end;

function GetValue(var W: Word; var Initial: String;
  Deselect: Boolean; const ATitle, ALabel: String): Boolean;
var
  Success: Boolean;
  C: Word;
  D: PDialog;
  Control: PInputValue;
  R: TRect;
  S: String;
begin
  C := cmCancel;
  Success := True;
  R.Assign(0, 0, 29, 7);
  R.Move((Desktop^.Size.X - R.B.X) div 2, (Desktop^.Size.Y - R.B.Y) div 2);
  D := New(PDialog, Init(R, ATitle));
  with D^ do
  begin
    HelpCtx := hcChange;
    R.Assign(4 + CStrLen(ALabel), 2, Size.X - 3, 3);
    Control := New(PInputValue, Init(R, 5, Deselect));
    Insert(Control);
    R.Assign(2, 2, 3 + CStrLen(ALabel), 3);
    Insert(New(PLabel, Init(R, ALabel, Control)));
    R.Assign(3, Size.Y - 3, 13, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardCancelButton(R, D);
    SetData(Initial);
    SelectNext(False);
  end;
  S := Initial;
  if Application^.ExecuteDialog(D, @S, False) <> cmCancel then
  begin
    UpcaseSt(S);
    Regs2Str(S);
    if not Str2Word(S, W) then Success := False;
    if not Success then InvalidNumberMsgBox;
  end
  else Success := False;
  GetValue := Success;
end;

function GetAddress(var Segment, Offset: Word;
  MakeCurrent: Boolean; CurrentPtr: Pointer;
  const ATitle, ALabel: String; AHelpCtx: Word): Boolean;
var
  Success: Boolean;
  P: Byte;
  C: Word;
  L: Longint;
  D: PDialog;
  Control: PInputLine;
  R: TRect;
  S, SegS, OffS: String;
begin
  C := cmCancel;
  Success := True;
  R.Assign(0, 0, 32, 7);
  R.Move((Desktop^.Size.X - R.B.X) div 2, (Desktop^.Size.Y - R.B.Y) div 2);
  D := New(PDialog, Init(R, ATitle));
  with D^ do
  begin
    HelpCtx := AHelpCtx;
    R.Assign(4 + CStrLen(ALabel), 2, Size.X - 6, 3);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    R.Assign(2, 2, 3 + CStrLen(ALabel), 3);
    Insert(New(PLabel, Init(R, ALabel, Control)));
    StandardHistory(Control, GetAddrHistoryId);
    R.Assign(3, Size.Y - 3, 13, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  S := HistoryStr(GetAddrHistoryID, 0);
  if Application^.ExecuteDialog(D, @S, False) <> cmCancel then
  begin
    UpcaseSt(S);
    P := Pos(':', S);
    if P <> 0 then
    begin
      SegS := Copy(S, 1, Pred(P));
      OffS := Copy(S, Succ(P), Length(S) - P);
      Regs2Str(SegS);
      if SegS[1] <> '$' then SegS := '$' + SegS;
      Regs2Str(OffS);
      if OffS[1] <> '$' then OffS := '$' + OffS;
      if not Str2Word(SegS, Segment) or not Str2Word(OffS, Offset) then
	Success := False;
    end
    else
    begin
      Regs2Str(S);
      if not Str2Word(S, Offset) then Success := False
      else if MakeCurrent and (CurrentPtr <> nil) then
	Segment := PtrRec(CurrentPtr).Seg
      else Segment := 0;
    end;
    if not Success and Debugging and GetParameter(S, L) then
    begin
      Success := True;
      Segment := LongRec(L).Hi;
      Offset := LongRec(L).Lo;
    end;
    if not Success then InvalidNumberMsgBox;
  end
  else Success := False;
  GetAddress := Success;
end;

end.