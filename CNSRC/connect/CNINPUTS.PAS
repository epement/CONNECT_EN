{$X+,O+,F+}
unit CNInputs;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PCInputLine = ^TCInputLine;
  TCInputLine = object(TInputLine)
    Min, Max: Longint;
    constructor Init(var Bounds: TRect; AMaxLen: Integer;
      AMin, AMax: Longint);
    constructor Load(var S: TStream);
    procedure Store(var S: TStream);
    function Valid(Command: Word): Boolean; virtual;
  end;

  PFInputLine = ^TFInputLine;
  TFInputLine = object(TInputLine)
    function Valid(Command: Word): Boolean; virtual;
  end;

  PDInputLine = ^TDInputLine;
  TDInputLine = object(TInputLine)
    function Valid(Command: Word): Boolean; virtual;
  end;

implementation

uses App, MsgBox, StdDlg, DirPrim, DiskPrim, History,
  TPString, Commands;

{
function TCRadioButtons.GetHelpCtx: Word;
begin
  if Owner^.State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else GetHelpCtx := HelpCtx;
end;

function TCCheckBoxes.GetHelpCtx: Word;
begin
  if Owner^.State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else GetHelpCtx := HelpCtx;
end;

function TCMultiCheckBoxes.GetHelpCtx: Word;
begin
  if Owner^.State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else GetHelpCtx := HelpCtx;
end;
}

constructor TCInputLine.Init(var Bounds: TRect; AMaxLen: Integer;
  AMin, AMax: Longint);
begin
  TInputLine.Init(Bounds, AMaxLen);
  Min := AMin;
  Max := AMax;
end;

constructor TCInputLine.Load(var S: TStream);
begin
  TInputLine.Load(S);
  S.Read(Min, SizeOf(Longint) * 2);
end;

procedure TCInputLine.Store(var S: TStream);
begin
  TInputLine.Store(S);
  S.Write(Min, SizeOf(Longint) * 2);
end;

function TCInputLine.Valid(Command: Word): Boolean;
var
  Code: Integer;
  L: Longint;
  S: String;
begin
  if Command = cmOk then
  begin
    S := StUpcase(Data^);
    if (S = '') or (S = 'NO') then S := '0';
    Val(S, L, Code);
    if (Code <> 0) and (S[1] <> '$') then
    begin
      Val('$' + S, L, Code);
      if Code > 1 then Dec(Code);
    end;
    if (Code <> 0) or (L < Min) or (L > Max) then
    begin
      Select;
      if Code > 0 then CurPos := Code - 1;
      DrawView;
      MessageBox(^C'Value not within the valid range.'#13 +
	^C'Valid range is: %d..%d', @Min, mfError + mfOkButton);
      Valid := False;
      Exit;
    end;
  end;
  Valid := TInputLine.Valid(Command);
end;

function TFInputLine.Valid(Command: Word): Boolean;
var
  S: FNameStr;
begin
  if (Command = cmOk) and
     (GetShiftState and (kbLeftShift + kbRightShift) = 0) and
     ((Pos('*', Data^) <> 0) or (Pos('?', Data^) <> 0)) then
  begin
    Select;
    S := Data^;
    if Application^.ExecuteDialog(
      New(PFileDialog, Init('*.*', 'Select a file name', '~N~ame',
      fdOkButton + fdHelpButton, HistoryID)), @S, False) <> cmCancel then
	SetData(S)
    else DrawView;
    Valid := False;
  end
  else Valid := TInputLine.Valid(Command);
end;

function TDInputLine.Valid(Command: Word): Boolean;
var
  B: Byte;
  S: FNameStr;
begin
  if (Command = cmOk) and (Trim(Data^) <> '') then
  begin
    S := CNFileName(Data^);
    if (S <> '') and not DirPresent(S) then
    begin
      if CreateDirMsgBox(S) = cmOk then CreateDir(S);
      if not DirPresent(S) then
      begin
	Select;
	Valid := False;
	Exit;
      end;
    end;
  end;
  Valid := TInputLine.Valid(Command);
end;

end.