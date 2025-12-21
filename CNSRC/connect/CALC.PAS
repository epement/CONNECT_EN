{$F+,O+,X+}
unit Calc;

interface

uses Drivers, Objects, Views, Dialogs, App, TPString;

type
  TCalcState = (csFirst, csValid, csError);
  THexState = (csHex, csOctal, csBinary);

  PHexDisplay = ^THexDisplay;
  THexDisplay = object(TView)
    Status: THexState;
    Number: String[16];
    constructor Init(var Bounds: TRect);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure Update(const S: String);
    procedure NewStatus(Up: Boolean);
    procedure NewRange(Up: Boolean);
  end;

  PCalcDisplay = ^TCalcDisplay;
  TCalcDisplay = object(TView)
    Status: TCalcState;
    Number: String[16];
    Operator: Char;
    Operand: Real;
    constructor Init(var Bounds: TRect);
    constructor Load(var S: TStream);
    procedure CalcKey(Key: Char);
    procedure Clear;
    procedure Draw; virtual;
    procedure GetNumberStr(const ANumber: String; var S: String);
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure Copy;
    procedure Cut;
    procedure Paste;
    procedure Push;
    procedure Pop;
    procedure Normalize;
  end;

  PCalcButton = ^TCalcButton;
  TCalcButton = object(TButton)
    Lock: Boolean;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Update(AState: Word);
  end;

  PCalculator = ^TCalculator;
  TCalculator = object(TDialog)
    CalcDisplay: PCalcDisplay;
    HexDisplay: PHexDisplay;
    HexLabel: PLabel;
    DownButton: PCalcButton;
    InHex: Boolean;
    What: Byte;
    constructor Init;
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    function GetHelpCtx: Word; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure PopUp(AnOrigin: TPoint);
  end;

procedure RSRCalculator(RSR: PResourceFile);
procedure Calculator;
procedure LoadCalculator;
procedure ExecCalculator;

implementation

uses CNCrt, Menus, MsgBox, EditMsg, StrCalc, Popups, HistList, History,
  Keyboard, WinPos, CNWinPos, Consts, Commands, Defaults;

const
  cmCalcButton  = 11000;
  cmPressButton = 11001;

  cmMakeHex     = 11010;
  cmMakeDecimal = 11011;

  cmHex         = 11020;
  cmOctal       = 11021;
  cmBinary      = 11022;

  cmToggleHex   = 11030;

  cmToggleCalc  = 11040;

  cmPush        = 11050;
  cmPop         = 11051;

  csReal        = 0;
  csShort       = 1;
  csInt         = 2;
  csLong        = 3;
  csByte        = 4;
  csWord        = 5;

  sfPushing     = $1000;
  sfMissing     = $2000;
  sfPressing    = $3000;

  NOTChar = '!';
  ANDChar = '&';
  ORChar  = '|';
  XORChar = '^';

  DigitChars = ['0'..'9', 'A'..'F', '.', '_'];
  HexChars = ['0'..'9', 'A'..'F'];
  DecimalChars = ['0'..'9', 'E', '.', '_'];
  OctalChars = ['0'..'7'];
  BinaryChars = ['0'..'1'];
  ActionChars = ['+', '-', '*', '/', ANDChar, ORChar, XORChar];

  MaxReal = 1.7E38;

  OutOfRangeStr = 'Out of range';
  ErrorStr = 'Error';

  States: Array[cmHex..cmBinary] of String[6] =
    ('Hex', 'Octal', 'Binary');

  Ranges: Array[csReal..csWord] of String[8] =
    ('Real', 'Shortint', 'Integer', 'Longint', 'Byte', 'Word');

  ModalInUse: Boolean = False;
  SolveInUse: Boolean = False;

function Power(X, Y: Real): Real;
begin
  Power := Exp(Y * Ln(X));
end;

function Str2Oct(const S: String; var L: Longint; What: Byte): Boolean;
var
  B: Byte;
  Ch: Char;
  R: Real;
begin
  Str2Oct := False;
  if S[0] > #10 then Exit;
  L := 0;
  R := Length(S) - 1;
  for B := 1 to Byte(S[0]) do
  begin
    if not (S[B] in OctalChars) then Exit;
    L := L + (Byte(S[B]) - $30) * Trunc(Power(8, R));
    R := R - 1;
  end;
  case What of
    csShort: if (L < -128) or (L > 127) then Exit;
    csInt: if (L < -32768) or (L > 32767) then Exit;
    csLong: if (L < -2147483647) or (L > 2147483647) then Exit;
    csByte: if (L < 0) or (L > 255) then Exit;
    csWord: if (L < 0) or (L > 65535) then Exit;
  end;
  Str2Oct := True;
end;

function Str2Bin(const S: String; var L: Longint; What: Byte): Boolean;
var
  B: Byte;
  Ch: Char;
  R: Real;
begin
  Str2Bin := False;
  if S[0] > #16 then Exit;
  L := 0;
  R := Length(S) - 1;
  for B := 1 to Byte(S[0]) do
  begin
    if not (S[B] in BinaryChars) then Exit;
    L := L + (Byte(S[B]) - $30) * Trunc(Power(2, R));
    R := R - 1;
  end;
  case What of
    csShort: if (L < -128) or (L > 127) then Exit;
    csInt: if (L < -32768) or (L > 32767) then Exit;
    csLong: if (L < -2147483647) or (L > 2147483647) then Exit;
    csByte: if (L < 0) or (L > 255) then Exit;
    csWord: if (L < 0) or (L > 65535) then Exit;
  end;
  Str2Bin := True;
end;

function Str2Longint(const S: String; var L: Longint; What: Byte): Boolean;
var
  B: Boolean;
begin
  Str2Longint := False;
  B := Str2Long(S, L);
  case What of
    csShort: if (L < -128) or (L > 127) then Exit;
    csInt: if (L < -32768) or (L > 32767) then Exit;
    csLong: if (L < -2147483647) or (L > 2147483647) then Exit;
    csByte: if (L < 0) or (L > 255) then Exit;
    csWord: if (L < 0) or (L > 65535) then Exit;
  end;
  Str2Longint := B;
end;

function BiggerThanLong(R: Extended): Boolean;
begin
  BiggerThanLong := (R > $7FFFFFFF) or (R < $80000000);
end;

procedure SetOutOfRangeStr(var S: String);
begin
  S := OutOfRangeStr;
end;

{ Solve expressions dialog }

type
  PExprInput = ^TExprInput;
  TExprInput = object(TInputLine)
    Panel: PRadioButtons;
    PrevSelStart, PrevSelEnd: Integer;
    PrevData: String;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure UpdatePanel;
    procedure Evaluate;
    procedure CopyAs;
  end;

procedure TExprInput.HandleEvent(var Event: TEvent);
begin
  if Event.What = evCommand then
    if Event.Command = cmZero then
    begin
      Evaluate;
      Event.What := evNothing;
    end
    else if Event.Command = cmFCopy then
    begin
      CopyAs;
      Event.What := evNothing;
    end
    else if Event.Command = cmCalculator then
    begin
      ExecCalculator;
      Event.What := evNothing;
    end;
  Inherited HandleEvent(Event);
  if (PrevSelStart <> SelStart) or
     (PrevSelEnd <> SelEnd) or
     (PrevData <> Data^) then
  begin
    PrevSelStart := SelStart;
    PrevSelEnd := SelEnd;
    PrevData := Data^;
    UpdatePanel;
  end;
end;

procedure TExprInput.SetData(var Rec);
begin
  Inherited SetData(Rec);
  HandleEvent(Pending);
end;

procedure SetPanelText(Panel: PRadioButtons; Index: Integer;
  const S: String);
var
  P: PString;
  C: String[15];
begin
  with Panel^ do
  begin
    P := Strings.At(Index);
    if P = nil then Exit;
    C := Copy(P^, 1, 13);
    Strings.AtFree(Index);
    Strings.AtInsert(Index, NewStr(
      Pad(C, 13) + LeftPad(S, Size.X - 17)));
    DrawView;
  end;
end;

procedure TExprInput.UpdatePanel;
var
  Code: Integer;
  R: Extended;
  C: String;
begin
  if SelStart <> SelEnd then C :=
    System.Copy(Data^, SelStart + 1, SelEnd - SelStart)
  else C := Data^;
  while C[Length(C)] in [' ', '+', '-', '*', '/', '%', '^', '='] do
    Dec(C[0]);
  ErrorCode := 0;
  if C = '' then
  begin
    C := '0';
    R := 0;
  end
  else
  begin
    Val(C, R, Code);
    if Code <> 0 then
    begin
      C := CalcStr(C, fDec);
      Val(C, R, Code);
    end
    else Str(R:0:10, C);
  end;

  if (Pos('E', C) = 0) and (Pos('.', C) <> 0) then
  begin
    while C[Length(C)] = '0' do Dec(C[0]);
    if C[Length(C)] = '.' then Dec(C[0]);
  end;
  SetPanelText(Panel, crDEC, C);

  if ErrorCode <> 0 then C := ''
  else if BiggerThanLong(R) then SetOutOfRangeStr(C)
  else C := HexL(Longint(Trunc(R)));
  SetPanelText(Panel, crHEX, C);

  if ErrorCode <> 0 then C := ''
  else if BiggerThanLong(R) then SetOutOfRangeStr(C)
  else C := BinaryL(Longint(Trunc(R)));
  SetPanelText(Panel, crBIN, C);

  if ErrorCode <> 0 then C := ''
  else if BiggerThanLong(R) then SetOutOfRangeStr(C)
  else C := OctalL(Longint(Trunc(R)));
  SetPanelText(Panel, crOCT, C);

  if ErrorCode <> 0 then C := ''
  else GetExpStr(R, C);
  SetPanelText(Panel, crEXP, C);

  if ErrorCode <> 0 then C := ''
  else GetSciStr(R, C);
  SetPanelText(Panel, crSci, C);

  if ErrorCode <> 0 then C := ''
  else GetBytesStr(R, C);
  SetPanelText(Panel, crBYT, C);
end;

procedure TExprInput.Evaluate;
var
  P: PString;
  S: String;
begin
  P := Panel^.Strings.At(crDEC);
  if P <> nil then
  begin
    S := Trim(System.Copy(P^, 14, 255));
    SetData(S);
    Select;
  end;
end;

procedure TExprInput.CopyAs;
var
  P: PString;
  S: String;
begin
  P := Panel^.Strings.At(Panel^.Value);
  if P <> nil then
  begin
    S := Trim(System.Copy(P^, 14, 255));
    Message(Application, evBroadcast, cmCopy, @S);
  end;
end;

type
  PExprRadio = ^TExprRadio;
  TExprRadio = object(TRadioButtons)
    DataPtr: ^Byte;
    procedure Press(Item: Integer); virtual;
  end;

  PExprCheck = ^TExprCheck;
  TExprCheck = object(TCheckBoxes)
    DataPtr: ^Byte;
    procedure Press(Item: Integer); virtual;
  end;

procedure TExprRadio.Press(Item: Integer);
begin
  Inherited Press(Item);
  DataPtr^ := Value;
end;

procedure TExprCheck.Press(Item: Integer);
begin
  Inherited Press(Item);
  DataPtr^ := Value;
end;

procedure ExprDlg;
type
  TData = record
    Expr: String[255];
    CopyAs: Word;
    Opt: Word;
  end;
var
  D: PDialog;
  Input: PExprInput;
  Control: PView;
  R: TRect;
  Data: TData;
begin
  if SolveInUse then Exit;

  CalcStrInit;

  R.Assign(0, 0, 71, 19);
  D := New(PDialog, Init(R, 'Solve expressions'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcSolveExprDlg;

    R.Assign(14, 2, Size.X - 6, 3);
    Input := New(PExprInput, Init(R, 255));
    Input^.Options := Input^.Options or ofPostProcess;
    Insert(Input);
    StandardHistory(Input, ExprHistoryId);
    R.Assign(2, 2, 14, 3);
    Insert(New(PLabel, Init(R, 'E~x~pression', Input)));

    R.Assign(3, 5, Size.X - 3, 12);
    Input^.Panel := New(PExprRadio, Init(R,
      NewSItem('~D~ecimal',
      NewSItem('~H~ex',
      NewSItem('~B~inary',
      NewSItem('~O~ctal',
      NewSItem('~E~xponential',
      NewSItem('Sc~i~entific',
      NewSItem('B~y~tes', nil)))))))));
    PExprRadio(Input^.Panel)^.DataPtr := @CopyResultAs;
    Insert(Input^.Panel);
    R.Assign(2, 4, Size.X - 3, 5);
    Insert(New(PLabel, Init(R, 'Copy as', Input^.Panel)));
    R.Assign(Size.X - 11, 4, Size.X - 3, 5);
    Insert(New(PLabel, Init(R, 'Result', Input^.Panel)));

    R.Assign(3, 14, Size.X - 3, 15);
    Control := New(PExprCheck, Init(R,
      NewSItem('~A~lways open this dialog box rather than Calculator window',
	nil)));
    PExprCheck(Control)^.DataPtr := @SolveExprOpt;
    Insert(Control);
    R.Assign(2, 13, Size.X - 3, 14);
    Insert(New(PLabel, Init(R, 'Options', Control)));

    R.Assign(2, Size.Y - 3, 14, Size.Y - 1);
    Insert(New(PButton, Init(R, 'E~v~aluate', cmZero, bfDefault)));
    R.Assign(14, Size.Y - 3, 24, Size.Y - 1);
    Insert(New(PButton, Init(R, '~C~opy', cmFCopy, bfNormal)));
    R.Assign(24, Size.Y - 3, 38, Size.Y - 1);
    Insert(New(PButton, Init(R, 'Ca~l~culator', cmCalculator, bfNormal)));
    R.Assign(38, Size.Y - 3, 48, Size.Y - 1);
    Insert(New(PButton, Init(R, 'O~K~', cmOk, bfNormal)));
    R.Assign(48, Size.Y - 3, 58, Size.Y - 1);
    StandardCancelButton(R, D);
    R.Assign(58, Size.Y - 3, 68, Size.Y - 1);
    StandardHelpButton(R, D);

    SelectNext(False);
{    Input^.UpdatePanel;}
  end;

  FillChar(Data, SizeOf(TData), 0);
  Data.Expr := HistoryStr(ExprHistoryId, 0);
  Data.CopyAs := CopyResultAs;
  Data.Opt := SolveExprOpt;
  SolveInUse := True;
  Application^.ExecuteDialog(D, @Data, False);
  SolveInUse := False;

  CalcStrDone;
end;

constructor THexDisplay.Init(var Bounds: TRect);
begin
  TView.Init(Bounds);
  Options := Options or ofSelectable;
  EventMask := evKeyDown + evMouseDown + evCommand + evBroadcast;
  Status := csHex;
  Number := '0';
end;

constructor THexDisplay.Load(var S: TStream);
begin
  TView.Load(S);
  S.Read(Status, SizeOf(Status));
end;

procedure THexDisplay.Draw;
var
  Color: Byte;
  Ch: Char;
  B: TDrawBuffer;
begin
  while (Number[0] > #1) and (Number[1] = '0') do Delete(Number, 1, 1);
  Color := GetColor(1);
  MoveChar(B, ' ', Color, Size.X);
  with PCalculator(Owner)^ do
  if InHex then
  begin
    if (CalcDisplay^.Status = csFirst) and
       (CalcDisplay^.Operator in ActionChars) then
      Ch := CalcDisplay^.Operator
    else Ch := #16;
    MoveChar(B[0], Ch, Color, 1);
  end;
  MoveStr(B[Size.X - Length(Number) - 1], Number, Color);
  WriteBuf(0, 0, Size.X, 1, B);
end;

function THexDisplay.GetPalette: PPalette;
const
  P: String[1] = #19;
begin
  GetPalette := @P;
end;

procedure THexDisplay.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  case Event.What of
    evKeyDown:
      case Event.KeyCode of
        kbTab, kbShiftTab: Exit;
        kbUp, kbDown:
          begin
            NewStatus(Event.KeyCode = kbUp);
            Event.What := evNothing;
          end;
        kbLeft, kbRight:
          begin
            NewRange(Event.KeyCode = kbRight);
            Event.What := evNothing;
          end;
        else
        begin
          Message(Owner, evBroadcast, cmPressButton,
            Pointer(Event.CharCode));
          Event.What := evNothing;
        end;
      end;
    evMouseDown: if Event.Double then
      begin
        NewStatus(False);
        Event.What := evNothing;
      end;
  end;
end;

procedure THexDisplay.SetState(AState: Word; Enable: Boolean);
begin
  TView.SetState(AState, Enable);
  if (AState = sfSelected) and Enable and GetState(sfExposed) then
    Message(Owner, evBroadcast, cmMakeHex, nil);
end;

procedure THexDisplay.Store(var S: TStream);
begin
  TView.Store(S);
  S.Write(Status, SizeOf(Status));
end;

procedure THexDisplay.Update(const S: String);
var
  Code: Integer;
  L: Longint;
  R: Real;
begin
  with PCalculator(Owner)^.CalcDisplay^ do
  begin
    if S = ErrorStr then SetOutOfRangeStr(Self.Number)
    else
    begin
      if (S[Length(S)] = 'E') or
         ((S[Length(S)] = '-') and (S[Length(S) - 1] = 'E')) then
        Val(S + '1', R, Code)
      else Val(S, R, Code);
      if BiggerThanLong(R) then SetOutOfRangeStr(Self.Number)
      else case Self.Status of
        csHex:
          case PCalculator(Owner)^.What of
	    csShort, csByte: Self.Number := HexB(Byte(Trunc(R)));
	    csInt, csWord: Self.Number := HexW(Word(Trunc(R)));
	    else Self.Number := HexL(Longint(Trunc(R)));
          end;
        csOctal:
          case PCalculator(Owner)^.What of
	    csShort, csByte: Self.Number := OctalB(Shortint(Trunc(R)));
	    csInt, csWord: Self.Number := OctalW(Word(Trunc(R)));
	    else Self.Number := OctalL(Longint(Trunc(R)));
          end;
        csBinary: if Abs(R) > $FFFF then SetOutOfRangeStr(Self.Number)
          else case PCalculator(Owner)^.What of
	    csShort, csByte: Self.Number := BinaryB(Shortint(Trunc(R)));
	    csInt, csWord: Self.Number := BinaryW(Word(Trunc(R)));
	    else Self.Number := BinaryW(Longint(Trunc(R)));
          end;
      end;
    end;
  end;
  DrawView;
end;

procedure THexDisplay.NewStatus(Up: Boolean);
var
  C: Word;
begin
  if Up then
    case Status of
      csHex: Status := csBinary;
      csOctal: Status := csHex;
      csBinary: Status := csOctal;
    end
  else
    case Status of
      csHex: Status := csOctal;
      csOctal: Status := csBinary;
      csBinary: Status := csHex;
    end;
  case Status of
    csHex: C := cmHex;
    csOctal: C := cmOctal;
    csBinary: C := cmBinary;
  end;
  Message(Owner, evBroadcast, C, nil);
end;

procedure THexDisplay.NewRange(Up: Boolean);
var
  I: Integer;
  C: Word;
begin
  I := PCalculator(Owner)^.What;
  if Up then Inc(I) else Dec(I);
  if I < csReal then I := csWord
  else if I > csWord then I := csReal;
  C := cmToggleCalc + I;
  Message(Owner, evCommand, C, nil);
end;

constructor TCalcDisplay.Init(var Bounds: TRect);
var
  R: TRect;
begin
  TView.Init(Bounds);
  Options := Options or ofSelectable;
  EventMask := evKeyDown + evMouseDown + evCommand + evBroadcast;
  Clear;
end;

constructor TCalcDisplay.Load(var S: TStream);
begin
  TView.Load(S);
  S.Read(Status, SizeOf(Status) + SizeOf(Number) +
    SizeOf(Operator) + SizeOf(Operand));
end;

procedure TCalcDisplay.CalcKey(Key: Char);
var
  Code: Integer;
  L: Longint;
  R: Real;
  ER: Extended;
  S: String;

procedure Error;
begin
  Status := csError;
  Number := ErrorStr;
end;

procedure SetDisplay;
begin
  case Operator of
    '+': ER := Operand + R;
    '-': ER := Operand - R;
    '*': ER := Operand * R;
    '/': if R = 0 then ER := MaxReal else ER := Operand / R;
    '&': if BiggerThanLong(Operand) or BiggerThanLong(R) then ER := MaxReal
	 else ER := Trunc(Operand) and Trunc(R);
    '|': if BiggerThanLong(Operand) or BiggerThanLong(R) then ER := MaxReal
	 else ER := Trunc(Operand) or Trunc(R);
    '^': if BiggerThanLong(Operand) or BiggerThanLong(R) then ER := MaxReal
	 else ER := Trunc(Operand) xor Trunc(R);
  end;
  case Key of
    'Q': if R < 0 then ER := MaxReal else ER := Sqrt(R);
    'S': ER := Sqr(R);
    #18: if R = 0 then ER := MaxReal else ER := 1 / R;
    NOTChar: if BiggerThanLong(R) then ER := MaxReal
      else ER := not Trunc(R);
  end;
  if ER >= MaxReal then
  begin
    Error;
    Exit;
  end;
  Str(ER:0:10, S);
  while S[Length(S)] = '0' do Dec(S[0]);
  if S[Length(S)] = '.' then Dec(S[0]);
  if Length(S) > 15 + Byte(S[1] = '-') then GetExpStr(ER, S);
  Number := S;
end;

procedure GetDisplay(var R: Real);
begin
  Val(Number, R, Code);
end;

procedure CheckFirst;
begin
  if Status = csFirst then
  begin
    Status := csValid;
    Number := '0';
    PCalculator(Owner)^.HexDisplay^.Number := '0';
  end;
end;

begin
  Key := UpCase(Key);
  if (Status = csError) and not (Key in [#27, 'R']) then Key := ' ';
  GetNumberStr(Number, Number);
  case Key of
    '0'..'9', 'A'..'F':
      begin
        CheckFirst;
        if Number = '0' then Number := '';
        if PCalculator(Owner)^.InHex then
          case PCalculator(Owner)^.HexDisplay^.Status of
            csHex:
              begin
                S := '$' + PCalculator(Owner)^.HexDisplay^.Number + Key;
                if Str2Longint(S, L, PCalculator(Owner)^.What) then
                  Str(L, Number);
              end;
            csOctal:
              begin
                S := PCalculator(Owner)^.HexDisplay^.Number + Key;
                if Str2Oct(S, L, PCalculator(Owner)^.What) then
                  Str(L, Number);
              end;
            csBinary:
              begin
                S := PCalculator(Owner)^.HexDisplay^.Number + Key;
                if Str2Bin(S, L, PCalculator(Owner)^.What) then
                  Str(L, Number);
              end;
          end
        else if (not (Key in ['A'..'D' ,'F'])) and
          (15 + Byte(Number[1] = '-') > Length(Number)) then
        begin
          S := Number + Key;
          if PCalculator(Owner)^.What = csReal then
          begin
            if Key = 'E' then Val(S + '1', ER, Code)
            else Val(S, ER, Code);
            if (Code = 0) and (Abs(ER) < MaxReal) then Number := S;
          end
          else if Str2Longint(S, L, PCalculator(Owner)^.What) then
            Number := S;
        end;
        if Number = '' then Number := '0';
      end;
    '.':
      begin
        CheckFirst;
        if Pos('.', Number) = 0 then Number := Number + '.';
      end;
    #27:
      begin
        CheckFirst;
        if Status = csError then Clear
        else if PCalculator(Owner)^.InHex then
        begin
          if Length(PCalculator(Owner)^.HexDisplay^.Number) = 1 then
            Number := '0'
          else case PCalculator(Owner)^.HexDisplay^.Status of
            csHex:
              begin
                S := '$' + PCalculator(Owner)^.HexDisplay^.Number;
                Dec(S[0]);
                if Str2Long(S, L) then Str(L, Number);
              end;
            csOctal:
              begin
                S := PCalculator(Owner)^.HexDisplay^.Number;
                Dec(S[0]);
                if Str2Oct(S, L, 255) then Str(L, Number);
              end;
            csBinary:
              begin
                S := PCalculator(Owner)^.HexDisplay^.Number;
                Dec(S[0]);
                if Str2Bin(S, L, 255) then Str(L, Number);
              end;
            end;
        end
        else
        begin
          Dec(Number[0]);
          if (Number = '') or (Number = '-') or (Number = '-0') then
            Number := '0';
        end;
      end;
    '_': if Number[Length(Number)] = 'E' then Number := Number + '-'
         else if Number[1] = '-' then Delete(Number, 1, 1)
         else if Number <> '0' then Number := '-' + Number;
    '+', '-', '*', '/', '=', #13, #18, 'S', 'Q',
      NOTChar, ANDChar, ORChar, XORChar:
      begin
        GetDisplay(R);
        Status := csFirst;
        if Operator in ['+', '-', '*', '/', ANDChar, ORChar, XORChar] then
          SetDisplay;
        GetDisplay(R);
        if Key in ['Q', 'S', #18, NOTChar] then SetDisplay;
        Operator := Key;
        GetDisplay(Operand);
      end;
    'R': Clear;
  end;
  DrawView;
end;

procedure TCalcDisplay.Clear;
begin
  Status := csFirst;
  Number := '0';
  Operator := '=';
  DrawView;
end;

procedure TCalcDisplay.Draw;
var
  Color: Byte;
  Ch: Char;
  B: TDrawBuffer;
  S: String;
begin
  GetNumberStr(Number, S);
  Color := GetColor(1);
  MoveChar(B, ' ', Color, Size.X);
  if not PCalculator(Owner)^.InHex then
  begin
    if (Status = csFirst) and
       (Operator in ActionChars) then Ch := Operator
    else Ch := #16;
    MoveChar(B[0], Ch, Color, 1);
  end;
  MoveStr(B[Size.X - Length(S) - 1], S, Color);
  WriteBuf(0, 0, Size.X, 1, B);
  PCalculator(Owner)^.HexDisplay^.Update(S);
end;

procedure TCalcDisplay.GetNumberStr(const ANumber: String; var S: String);
var
  BV: Byte;
  SV: Shortint;
  WV: Word;
  IV, Code: Integer;
  LV: Longint;
  RV: Real;
begin
  S := ANumber;
  if (Status = csError) or
     (PCalculator(Owner)^.What = csReal) then Exit;
  if (S[Length(S)] = 'E') or
     ((S[Length(S)] = '-') and (S[Length(S) - 1] = 'E')) then
    Val(S + '1', RV, Code)
  else Val(S, RV, Code);
  if BiggerThanLong(RV) then S := '0'
  else Str(Trunc(RV), S);
  case PCalculator(Owner)^.What of
    csShort:
       begin
        Val(S, SV, Code);
        Str(SV, S);
      end;
    csInt:
      begin
        Val(S, IV, Code);
        Str(IV, S);
      end;
    csLong:
      begin
        Val(S, LV, Code);
        Str(LV, S);
      end;
    csByte:
      begin
        Val(S, BV, Code);
        Str(BV, S);
      end;
    csWord:
      begin
        Val(S, WV, Code);
        Str(WV, S);
      end;
  end;
end;

function TCalcDisplay.GetPalette: PPalette;
const
  P: string[1] = #19;
begin
  GetPalette := @P;
end;

procedure TCalcDisplay.HandleEvent(var Event: TEvent);
var
  S: THexState;
begin
  TView.HandleEvent(Event);
  case Event.What of
    evKeyDown:
      begin
        case Event.KeyCode of
          kbTab, kbShiftTab: Exit;
          kbCtrlIns: Copy;
          kbShiftDel: Cut;
          kbShiftIns: Paste;
          kbCtrlDel: Clear;
          else if Event.CharCode = ^N then Normalize
          else Message(Owner, evBroadcast, cmPressButton,
            Pointer(Event.CharCode));
        end;
        Event.What := evNothing;
      end;
    evBroadcast:
      if Event.Command = cmCalcButton then
      begin
        CalcKey(PButton(Event.InfoPtr)^.Title^[1]);
        Event.What := evNothing;
      end;
    evCommand:
      begin
        case Event.Command of
          cmCopy: Copy;
          cmCut: Cut;
          cmPaste: Paste;
          cmClear: Clear;
          cmToggleHex..cmToggleHex + 2:
            begin
              case Event.Command of
                cmToggleHex: S := csHex;
                cmToggleHex + 1: S := csOctal;
                cmToggleHex + 2: S := csBinary;
              end;
              PCalculator(Owner)^.HexDisplay^.Status := S;
              Message(Owner, evBroadcast,
                cmHex + Event.Command - cmToggleHex, nil);
            end;
          cmToggleCalc..cmToggleCalc + csWord:
            begin
              PCalculator(Owner)^.What := Event.Command - cmToggleCalc;
              if PCalculator(Owner)^.InHex then Event.Command := cmMakeHex
              else Event.Command := cmMakeDecimal;
              Message(Owner, evBroadcast, Event.Command, nil);
              case PCalculator(Owner)^.HexDisplay^.Status of
                csHex: Event.Command := cmHex;
                csOctal: Event.Command := cmOctal;
                csBinary: Event.Command := cmBinary;
              end;
              Message(Owner, evBroadcast, Event.Command, nil);
            end;
            cmPush: Push;
            cmPop: Pop;
          else Exit;
        end;
        Event.What := evNothing;
      end;
  end;
end;

procedure TCalcDisplay.SetState(AState: Word; Enable: Boolean);
begin
  TView.SetState(AState, Enable);
  if (AState = sfSelected) and Enable and GetState(sfExposed) then
    Message(Owner, evBroadcast, cmMakeDecimal, nil);
end;

procedure TCalcDisplay.Store(var S: TStream);
begin
  TView.Store(S);
  S.Write(Status, SizeOf(Status) + SizeOf(Number) +
    SizeOf(Operator) + SizeOf(Operand));
end;

procedure TCalcDisplay.Copy;
var
  S: String;
begin
  if PCalculator(Owner)^.InHex then
    S := PCalculator(Owner)^.HexDisplay^.Number
  else GetNumberStr(Number, S);
  Message(Application, evBroadcast, cmCopy, @S);
end;

procedure TCalcDisplay.Cut;
begin
  Copy;
  Clear;
end;

procedure TCalcDisplay.Paste;
var
  Code: Integer;
  L: Longint;
  P: Pointer;
  ER: Extended;
  S: String;
begin
  Message(Application, evBroadcast, cmUpdateViews, nil);
  S := PString(Message(Application, evBroadcast, cmPaste, nil))^;
  while (S[0] > #0) and (S[1] = '0') do Delete(S, 1, 1);
  while (S[0] > #1) and (S[1] = '-') and (S[2] = '0') do Delete(S, 2, 1);
  if S = '' then Exit;
  UpcaseSt(S);
  Number := '0';
  if PCalculator(Owner)^.InHex then
    case PCalculator(Owner)^.HexDisplay^.Status of
      csHex: if Str2Longint('$' + S, L, PCalculator(Owner)^.What) then
        Str(L, Number);
      csOctal: if Str2Oct(S, L, PCalculator(Owner)^.What) then
        Str(L, Number);
      csBinary: if Str2Bin(S, L, PCalculator(Owner)^.What) then
        Str(L, Number);
    end
  else
  begin
    if PCalculator(Owner)^.What = csReal then
    begin
      Val(S, ER, Code);
      if (Code = 0) and (Abs(ER) < MaxReal) then Number := S;
    end
    else if Str2Longint(S, L, PCalculator(Owner)^.What) then
      Number := S;
  end;
  Status := csValid;
  DrawView;
end;

procedure TCalcDisplay.Push;
var
  S: String;
begin
  GetNumberStr(Number, S);
  HistoryAdd(CalcHistoryID, S, True);
end;

procedure TCalcDisplay.Pop;
var
  C: Word;
  W: PHistoryWindow;
  R: TRect;
begin
  GetBounds(R);
  Dec(R.A.X); Inc(R.B.X); Dec(R.A.Y);
  Inc(R.B.Y, HistoryCount(CalcHistoryID) + 1);
  if R.B.Y >= Owner^.Size.Y then R.B.Y := Owner^.Size.Y - 1;
  W := New(PHistoryWindow, Init(R, CalcHistoryID));
  W^.HelpCtx := hcCalcPop;
  W^.Viewer^.FocusItem(0);
  if Application^.ValidView(W) <> nil then
  begin
    C := Owner^.ExecView(W);
    if C = cmOk then Number := W^.GetSelection;
    Dispose(W, Done);
    if C = cmOk then
    begin
      if Number = '' then Number := '0';
      Status := csValid;
      DrawView;
    end;
  end;
end;

procedure TCalcDisplay.Normalize;
var
  I, Code: Integer;
  R: Real;
  S: String;
begin
  GetNumberStr(Number, S);
  if (S[Length(S)] = 'E') or
     ((S[Length(S)] = '-') and (S[Length(S) - 1] = 'E')) then
    Val(S + '1', R, Code)
  else Val(S, R, Code);
  I := Pos('E', S);
  if I = 0 then GetExpStr(R, S)
  else
  begin
    Str(R:0:10, S);
    while S[Length(S)] = '0' do Dec(S[0]);
    if S[Length(S)] = '.' then Dec(S[0]);
    if Length(S) > 15 + Byte(S[1] = '-') then Exit;
  end;
  Number := S;
  DrawView;
end;

procedure TCalcButton.HandleEvent(var Event: TEvent);
begin
  TButton.HandleEvent(Event);
  if Event.What = evBroadcast then
    case Event.Command of
      cmPressButton:
        if (Upcase(Event.InfoChar) = Title^[1]) and
           (State and sfDisabled = 0) then with PCalculator(Owner)^ do
        begin
          if (DownButton <> nil) and (DownButton <> @Self) then
            DownButton^.DrawState(False);
          DrawState(True);
          Press;
          DownButton := @Self;
          Pending.What := evCommand;
          Pending.Command := cmPressButton;
          Event.What := evNothing;
        end;
      cmMakeDecimal, cmMakeHex, cmHex, cmOctal, cmBinary:
        Update(Event.Command);
   end;
end;

procedure TCalcButton.SetState(AState: Word; Enable: Boolean);
begin
  if (AState = sfDisabled) and not Lock then Exit;
  TButton.SetState(AState, Enable);
end;

procedure TCalcButton.Update(AState: Word);
begin
  if Title^[1] in DigitChars then
  begin
    Lock := True;
    case AState of
      cmMakeDecimal:
        begin
          if Title^[1] in DecimalChars then SetState(sfDisabled, False)
          else SetState(sfDisabled, True);
          if (Title^[1] in ['E', '.']) and
             (PCalculator(Owner)^.What <> csReal) then
            SetState(sfDisabled, True);
        end;
      cmMakeHex:
        begin
          case PCalculator(Owner)^.HexDisplay^.Status of
            csHex: AState := cmHex;
            csOctal: AState := cmOctal;
            csBinary: AState := cmBinary;
          end;
          Update(AState);
        end;
      cmHex:
        if PCalculator(Owner)^.HexDisplay^.State and sfSelected <> 0 then
          if Title^[1] in HexChars then SetState(sfDisabled, False)
          else SetState(sfDisabled, True);
      cmOctal:
        if PCalculator(Owner)^.HexDisplay^.State and sfSelected <> 0 then
          if Title^[1] in OctalChars then SetState(sfDisabled, False)
          else SetState(sfDisabled, True);
      cmBinary:
        if PCalculator(Owner)^.HexDisplay^.State and sfSelected <> 0 then
          if Title^[1] in BinaryChars then SetState(sfDisabled, False)
          else SetState(sfDisabled, True);
    end;
    Lock := False;
    DrawView;
  end;
end;

{ TCalculator }

constructor TCalculator.Init;
const
  KeyChar: array[0..31] of Char = 'R'#27'SQ!&|^789/456*123-0.=+DEF_ABC'#18'';
var
  I: Integer;
  P: PView;
  R: TRect;
begin
  R.Assign(5, 0, 30, 23);
  TDialog.Init(R, 'Calculator');
  for I := 0 to 31 do
  begin
    R.A.X := (I mod 4) * 5 + 2;
    R.A.Y := (I div 4) * 2 + 6;
    R.B.X := R.A.X + 5;
    R.B.Y := R.A.Y + 2;
    P := New(PCalcButton, Init(R, KeyChar[I], cmCalcButton,
      bfNormal + bfBroadcast));
    P^.Options := P^.Options and not ofSelectable;
    Insert(P);
  end;

  R.Assign(3, 2, 22, 3);
  CalcDisplay := New(PCalcDisplay, Init(R));
  Insert(CalcDisplay);
  R.Assign(2, 1, 22, 2);
  Insert(New(PLabel, Init(R, LeftPad('Decimal', 19), CalcDisplay)));

  R.Assign(3, 4, 22, 5);
  HexDisplay := New(PHexDisplay, Init(R));
  Insert(HexDisplay);
  R.Assign(2, 3, 22, 4);
  HexLabel := New(PLabel, Init(R, Pad('Real', 16) + 'Hex', HexDisplay));
  Insert(HexLabel);

  SelectNext(False);
  WinPos := @CalcWinPos;
end;

constructor TCalculator.Load(var S: TStream);
begin
  TDialog.Load(S);
  GetSubViewPtr(S, CalcDisplay);
  GetSubViewPtr(S, HexDisplay);
  GetSubViewPtr(S, HexLabel);
  S.Read(InHex, SizeOf(InHex) + SizeOf(What));
  WinPos := @CalcWinPos;
end;

procedure TCalculator.Draw;
var
  C: Word;
  B: TDrawBuffer;
begin
  if State and sfPressing = 0 then TDialog.Draw;
  if TypeOf(Current^) = TypeOf(THistoryWindow) then Exit;
  C := GetColor(9);
  if State and sfPushing <> 0 then MoveChar(B, '', C, 1)
  else MoveChar(B, #24, C, 1);
  WriteLine(2, 2, 1, 1, B);
  MoveChar(B, #25, C, 1);
  WriteLine(22, 2, 1, 1, B);
end;

function TCalculator.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else GetHelpCtx := hcCalculator;
end;

procedure TCalculator.HandleEvent(var Event: TEvent);
var
  Spot: TPoint;
  S: String;
begin
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbEsc:
        begin
          Event.What := evCommand;
          Event.Command := cmClose;
          Event.InfoPtr := @Self;
        end;
      kbEnter, kbSpace: Event.CharCode := '=';
      kbBack: Event.CharCode := #27;
      kbCtrlIns, kbShiftDel, kbShiftIns, kbCtrlDel:
        CalcDisplay^.HandleEvent(Event);
      kbUp, kbDown, kbLeft, kbRight:
        HexDisplay^.HandleEvent(Event);
      kbCtrlUp, kbCtrlDn:
        begin
          Event.What := evCommand;
          Event.Command := cmPush + Byte(Event.KeyCode = kbCtrlDn);
        end;
      kbCtrlEnter: ExprDlg;
      else if Event.CharCode = ^N then CalcDisplay^.HandleEvent(Event);
    end
  else if (Event.What = evMouseDown) and MouseInView(Event.Where) then
    if (Event.Buttons = mbRightButton) then
    begin
      repeat until not MouseEvent(Event, evMouseDown);
      PopUp(Event.Where);
      Event.What := evNothing;
    end
    else
    begin
      MakeLocal(Event.Where, Spot);
      if Spot.Y = 2 then
        if Spot.X = 2 then
        begin
          repeat
            MakeLocal(Event.Where, Spot);
            if (Spot.X = 2) and (Spot.Y = 2) then
              State := (State and not sfPressing) or sfPushing
            else State := (State and not sfPressing) or sfMissing;
            DrawView;
          until not MouseEvent(Event, evMouseMove);
          if State and sfPushing <> 0 then
          begin
            Event.What := evCommand;
            Event.Command := cmPush;
          end;
          State := State and not sfPressing;
          DrawView;
        end
        else if Spot.X = 22 then
        begin
          Event.What := evCommand;
          Event.Command := cmPop;
        end;
    end;
  if (Event.What = evCommand) and
     (State and sfVisible <> 0) then
    CalcDisplay^.HandleEvent(Event);
  TDialog.HandleEvent(Event);
  if Event.What = evBroadcast then
  begin
    case Event.Command of
      cmMakeHex: InHex := True;
      cmMakeDecimal: InHex := False;
      cmHex, cmOctal, cmBinary:
        begin
          FillChar(S, SizeOf(String), ' ');
          Move(Ranges[What][1], S[1], Length(Ranges[What]));
          Move(States[Event.Command][1],
            S[20 - Length(States[Event.Command])],
            Length(States[Event.Command]));
          S[0] := #19;
          DisposeStr(HexLabel^.Text);
          HexLabel^.Text := NewStr(S);
          HexLabel^.DrawView;
        end;
      cmCalculator:
        if (State and sfActive <> 0) and
           (State and sfSelected <> 0) and
           (State and sfModal = 0) then
        begin
          Event.What := evNothing;
          Event.InfoPtr := nil;
        end
        else if State and (sfActive + sfSelected + sfModal) = 0 then
        begin
          Deiconize;
          Show;
          Select;
          ClearEvent(Event);
        end;
      else Exit;
    end;
    CalcDisplay^.DrawView;
  end
  else if Event.What = evCommand then
  begin
    case Event.Command of
      cmZero: ExprDlg;
      cmPressButton: if (DownButton <> nil) and
        ((KbdStatus = 0) or (KbdStatus > $80)) then
        begin
          DownButton^.DrawState(False);
          DownButton := nil;
        end
        else if not KeyPressed then PutEvent(Event);
      cmPopUp:
        begin
          Spot.X := Size.X;
          Spot.Y := 0;
          MakeGlobal(Spot, Spot);
          PopUp(Spot);
        end;
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

procedure TCalculator.SetState(AState: Word; Enable: Boolean);
var
  C: Word;
begin
  TDialog.SetState(AState, Enable);
  if (AState = sfFocused) and Enable and GetState(sfVisible) then
  begin
    if InHex then C := cmMakeHex
    else C := cmMakeDecimal;
    Message(@Self, evBroadcast, C, nil);
    EnableCommands(BlockCommands + PasteCommands + MTCommands);
  end
  else if not Enable and
    ((AState = sfExposed) or
    ((AState and (sfActive + sfSelected) <> 0) and
      GetState(sfExposed))) then DisableCommands(
        BlockCommands + PasteCommands + MTCommands);
end;

procedure TCalculator.Store(var S: TStream);
begin
  TDialog.Store(S);
  PutSubViewPtr(S, CalcDisplay);
  PutSubViewPtr(S, HexDisplay);
  PutSubViewPtr(S, HexLabel);
  S.Write(InHex, SizeOf(InHex) + SizeOf(What));
end;

procedure TCalculator.PopUp(AnOrigin: TPoint);
const
  Mark: Array[False..True] of Char = (' ', 'û');
begin
  ShowPopup(AnOrigin, NewMenu(
    NewItem(Mark[HexDisplay^.Status = csHex] + ' ~H~ex', '', kbNoKey, cmToggleHex, hcToggleHex,
    NewItem(Mark[HexDisplay^.Status = csOctal] + ' ~O~ctal', '', kbNoKey, cmToggleHex + 1, hcToggleHex,
    NewItem(Mark[HexDisplay^.Status = csBinary] + ' ~B~inary', '', kbNoKey, cmToggleHex + 2, hcToggleHex,
    NewLine(
    NewItem(Mark[What = csReal] + ' ~R~eal', '', kbNoKey, cmToggleCalc, hcToggleCalc,
    NewItem(Mark[What = csShort] + ' ~S~hortint', '', kbNoKey, cmToggleCalc + 1, hcToggleCalc,
    NewItem(Mark[What = csInt] + ' ~I~nteger', '', kbNoKey, cmToggleCalc + 2, hcToggleCalc,
    NewItem(Mark[What = csLong] + ' ~L~ongint', '', kbNoKey, cmToggleCalc + 3, hcToggleCalc,
    NewItem(Mark[What = csByte] + ' B~y~te', '', kbNoKey, cmToggleCalc + 4, hcToggleCalc,
    NewItem(Mark[What = csWord] + ' ~W~ord', '', kbNoKey, cmToggleCalc + 5, hcToggleCalc,
    NewLine(
    NewItem('~C~opy', 'Ctrl+Ins', kbCtrlIns, cmCopy, hcECopy,
    NewItem('~P~aste', 'Shift+Ins', kbShiftIns, cmPaste, hcEPaste,
    NewItem('Cl~e~ar', 'Ctrl+Del', kbCtrlDel, cmClear, hcEClear,
    NewLine(
    NewItem('P~u~sh to memory', 'Ctrl+'#24, kbCtrlUp, cmPush, hcCalcPush,
    NewItem('Pop ~f~rom memory...', 'Ctrl+'#25, kbCtrlDn, cmPop, hcCalcPop,
    NewLine(
    NewItem('E~x~pressions...', 'Ctrl+Enter', kbCtrlEnter, cmZero, hcExpressions,
      nil)))))))))))))))))))));
end;

procedure RSRCalculator(RSR: PResourceFile);
var
  P: PCalculator;
begin
  P := New(PCalculator, Init);
  RSR^.Put(P, 'CALCULATOR');
  Dispose(P, Done);
end;

procedure Calculator;
begin
  Application^.InsertWindow(New(PCalculator, Init));
end;

procedure LoadCalculator;
var
  R: TRect;
  P: PCalculator;
begin
  if not SolveInUse and (SolveExprOpt and seAlwaysDialog <> 0) then
  begin
    ExprDlg;
    Exit;
  end;
  if Message(Desktop, evBroadcast, cmCalculator, nil) <> nil then Exit;
  P := PCalculator(Resource^.Get('CALCULATOR'));
  if P <> nil then
  begin
    if (WinPosMask and wpCalc <> 0) and ValidWinPos(CalcWinPos) then
    begin
      SetWinPos(Desktop, CalcWinPos, R);
      P^.MoveTo(R.A.X, R.A.Y);
    end;
    Application^.InsertWindow(P)
  end
  else ResourceNotFoundMsgBox('Calculator');
end;

procedure ExecCalculator;
var
  R: TRect;
  P: PCalculator;
  O: PGroup;
begin
  if ModalInUse then Exit;
  if not SolveInUse and (SolveExprOpt and seAlwaysDialog <> 0) then
  begin
    ExprDlg;
    Exit;
  end;
  P := PCalculator(Resource^.Get('CALCULATOR'));
  if Application^.ValidView(P) <> nil then
  begin
    ModalInUse := True;
    if Desktop = Pointer(Application^.Current) then O := Desktop
    else O := Application;
    if (WinPosMask and wpCalc <> 0) and ValidWinPos(CalcWinPos) then
    begin
      SetWinPos(O, CalcWinPos, R);
      P^.MoveTo(R.A.X, R.A.Y);
    end
    else if Pointer(O) = Application then
      P^.MoveTo(5, Desktop^.Origin.Y + 1);
    O^.ExecView(P);
    Dispose(P, Done);
    ModalInUse := False;
  end;
end;

end.
