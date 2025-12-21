{$X+,F+,O+}
unit MsgBox;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PMsgBoxButton = ^TMsgBoxButton;
  TMsgBoxButton = object(TButton)
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

const

{ Message box classes }

  mfWarning      = $0000;       { Display a Warning box }
  mfError        = $0001;       { Dispaly a Error box }
  mfInformation  = $0002;       { Display an Information Box }
  mfConfirmation = $0003;       { Display a Confirmation Box }
{ Added 2005.12.30 }
  mfDelTrashConf = $0004;       { Display a Confirmation Box with Recycle checkbox }

{ Message box button flags }

  mfYesButton    = $0100;       { Put a Yes button into the dialog }
  mfNoButton     = $0200;       { Put a No button into the dialog }
  mfOKButton     = $0400;       { Put an OK button into the dialog }
  mfCancelButton = $0800;       { Put a Cancel button into the dialog }
  mfAllButton    = $1000;       { Put an All button into the dialog }

{ Added 2005.07.29 to support autotrimming file names }
  mfNoAdjust     = $8000;       { Do not perform adjustment }
{ Added 2005.11.16 to optionally disable Cancel by Esc }
  mfNoEsc        = $4000;       { Do not cancel by Esc }

  mfYesNo           = mfYesButton + mfNoButton;
				{ Standard Yes, No dialog }
  mfYesNoCancel     = mfYesButton + mfNoButton + mfCancelButton;
				{ Standard Yes, No, Cancel dialog }
  mfYesAllCancel    = mfYesButton + mfAllButton + mfCancelButton;
				{ Standard Yes, All, Cancel dialog }
  mfYesAllNoCancel  = mfYesButton + mfAllButton + mfNoButton + mfCancelButton;
				{ Standard Yes, All, No, Cancel dialog }
  mfOKCancel        = mfOKButton + mfCancelButton;
				{ Standard OK, Cancel dialog }

{ MessageBox displays the given string in a standard sized      }
{ dialog box. Before the dialog is displayed the Msg and Params }
{ are passed to FormatStr.  The resulting string is displayed   }
{ as a TStaticText view in the dialog.                          }

function MessageBox(const Msg: String;
  Params: Pointer; AOptions: Word): Word;

{ MessageBoxRec allows the specification of a TRect for the     }
{ message box to occupy.                                        }

function MessageBoxRect(var R: TRect; const Msg: String; Params: Pointer;
  AOptions: Word): Word;

{ InputBox displays a simple dialog that allows the user to     }
{ type in a string.                                             }

(*
function InputBox(const Title: String; const ALabel: String; var S: String;
  Limit: Byte): Word;

{ InputBoxRect is like InputBox but allows the specification of }
{ a rectangle.                                                  }

function InputBoxRect(var Bounds: TRect;
  const Title: String; const ALabel: String;
  var S: String;  Limit: Byte): Word;
*)

function CtxMessageBox(const Msg: String; Params: Pointer;
  AOptions, AHelpCtx: Word): Word;

function CtxMessageBoxRect(var R: TRect;
  const Msg: String; Params: Pointer;
  AOptions, AHelpCtx: Word): Word;

implementation

uses App, LogFile, TPString, Consts, Defaults;

function ClearedMsg(const Msg: String): String;
var
  B: Byte;
  S: String;
begin
  S := Msg;
  B := 1;
  while B <= Length(S) do
  begin
    if S[B] = ^C then Delete(S, B, 1)
    else
    begin
      if S[B] = ^M then S[B] := ' ';
      Inc(B);
    end;
  end;
  ClearedMsg := S;
end;

procedure TMsgBoxButton.HandleEvent(var Event: TEvent);
begin
  if Event.What = evKeyDown then
    case CtrlToArrow(Event.KeyCode) of
      kbRight: Event.KeyCode := kbTab;
      kbLeft: Event.KeyCode := kbShiftTab;
    end;
  TButton.HandleEvent(Event);
end;

const
  ButtonName: Array[0..3] of String[6] =
    ('~Y~es', '~N~o', 'O~K~', 'Cancel');
  Commands: Array[0..3] of Word =
    (cmYes, cmNo, cmOK, cmCancel);
  Titles: Array[0..3] of String[11] =
    ('Warning','Error','Information','Confirm');

{ Added 2005.07.29 to support autotrimming file names }
procedure AdjustMsgBoxArgs(var R: TRect; var S: String);
var
  I, J, K, L: Integer;
  SS: String;
begin
  I := Pos('|', S);
  if I = 0 then Exit;
  J := I;
  while (J < Length(S)) and (S[J + 1] <> '|') do Inc(J);
  if (J >= Length(S)) and (Length(S) < 255) then Exit;
  Delete(S, J + 1, 1);
  Delete(S, I, 1);
  L := 0;
  K := I;
  while (K > 0) and not (S[K] in [^C, #13]) do
  begin
    Dec(K);
    Inc(L);
  end;
  K := J;
  while (K <= Length(S)) and not (S[K] in [^C, #13]) do
  begin
    Inc(K);
    Inc(L);
  end;
  if L > 32 then L := 32;
  SS := TrimmedName(Copy(S, I, J - I), ScreenWidth - 16 - L);
  Delete(S, I, J - I);
  Insert(SS, S, I);
  I := Length(SS) + L + 8;
  if I < 40 then I := 40;
  R.A.X := ScreenWidth div 2 - I div 2;
  R.B.X := ScreenWidth div 2 + I div 2;
end;

procedure MsgBoxEventProc(V: PView; var Event: TEvent);
begin
  if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
    Event.What := evNothing;
end;

function MessageBoxRectPrim(var R: TRect;
  const Msg: String; Params: Pointer;
  AOptions, AHelpCtx: Word): Word;
var
  Trash: Boolean;
  BF: Byte;
  I, X, ButtonCount: Integer;
  Dialog: PDialog;
  Control: PView;
  TrashCheckBox: PCheckBoxes;
  T: TRect;
  ButtonList: Array[0..4] of PView;
  S, C: String;
begin
{ Added 04.17.03 to support Ignore All SysErrors }
  if IgnoreAllSysErrors then
  begin
    MessageBoxRectPrim := cmOk;
    Exit;
  end;
  C := Msg;
{ Added 2005.07.29 to support autotrimming file names }
  if AOptions and mfNoAdjust = 0 then AdjustMsgBoxArgs(R, C);

{ Added 2005.12.30 }
  if AOptions and 7 = mfDelTrashConf then
  begin
    AOptions := (AOptions and not 7) or mfConfirmation;
    Trash := True;
    while R.B.X - R.A.X < 44 do
    begin
      Dec(R.A.X);
      Inc(R.B.X);
    end;
  end
  else Trash := False;

  Dialog := New(PDialog, Init(R, Titles[AOptions and $3]));
  with Dialog^ do
  begin
{ Added 2005.11.16 to optionally disable Cancel by Esc }
    if AOptions and mfNoEsc <> 0 then PreProcessEvent := MsgBoxEventProc;
    R.Assign(3, 2, Size.X - 2, Size.Y - 3);
    if Params = nil then S := C
    else FormatStr(S, C, Params^);
    Control := New(PStaticText, Init(R, S));
    Insert(Control);
    X := -2;
    ButtonCount := 0;
    for I := 0 to 3 do
      if AOptions and (mfYesButton shl I) <> 0 then
      begin
	R.Assign(0, 0, 10, 2);
	if (AOptions and mfAllButton <> 0) and
	   (AOptions and mfNoButton <> 0) then
	  R.B.X := CStrLen(ButtonName[I]) + 4;
{ Added 2005.12.30 }
	if Trash and (Commands[I] = cmOk) then BF := bfDefault
	else BF := bfNormal;
	Control := New(PMsgBoxButton, Init(R, ButtonName[I], Commands[I], BF));
	Inc(X, Control^.Size.X + 2);
	if AHelpCtx = hcNoContext then
	  Control^.HelpCtx := hcYesButton + I
	else Control^.HelpCtx := AHelpCtx;
	ButtonList[ButtonCount] := Control;
	Inc(ButtonCount);
      end;

    if AOptions and mfAllButton <> 0 then
    begin
      R.Assign(0, 0, 7, 2);
      Control := New(PMsgBoxButton, Init(R, '~A~ll', cmOk, bfNormal));
      if AHelpCtx = hcNoContext then
	Control^.HelpCtx := hcOkButton
      else Control^.HelpCtx := AHelpCtx;
      ButtonList[4] := ButtonList[3];
      ButtonList[3] := ButtonList[2];
      ButtonList[2] := ButtonList[1];
      ButtonList[1] := Control;
      Inc(X, Control^.Size.X + 2);
      Inc(ButtonCount);
    end; { Added 11.30.95 }

    X := (Size.X - X) shr 1;
{ Added 2005.12.30 }
    if Trash then while X < 19 do Inc(X);
    for I := 0 to ButtonCount - 1 do
    begin
      Control := ButtonList[I];
      Insert(Control);
      Control^.MoveTo(X, Size.Y - 3);
      Inc(X, Control^.Size.X + 2);
    end;

{ Added 2005.12.30 }
    if Trash then
    begin
      R.Assign(3, Size.Y - 3, 16, Size.Y - 2);
      TrashCheckBox := New(PCheckBoxes, Init(R, NewSItem('~R~ecycle', nil)));
      TrashCheckBox^.HelpCtx := hcNT_Recycle;
      TrashCheckBox^.Value := Byte(FileCopyOptions and fsDelToTrash <> 0);
      if not CN_NT then TrashCheckBox^.SetButtonState($01, False);
      Insert(TrashCheckBox);
    end;

    SelectNext(False);
  end;
  Desktop^.Unlock;
  MessageBoxRectPrim := Application^.ExecView(Dialog);

{ Added 2005.12.30 }
  if Trash then
    if TrashCheckBox^.Value = 0 then FileCopyOptions :=
      FileCopyOptions and not fsDelToTrash
    else FileCopyOptions := FileCopyOptions or fsDelToTrash;

  Dispose(Dialog, Done);
  if EnableLog and loEnable <> 0 then
  begin
    case AOptions and $FF of
      1: LogEvent := lcError;
      0: LogEvent := lcWarning;
      3: LogEvent := lcConfirm;
      else LogEvent := lcInfo;
    end;
    case LogEvent of
      lcError: C := Titles[1];
      lcWarning: C := Titles[0];
      lcConfirm: C := Titles[3];
      else C := Titles[2];
    end;
    WriteToLog(C + '. ' + ClearedMsg(S));
    LogEvent := lcOther;
  end;
end;

function MessageBoxRect(var R: TRect;
  const Msg: String; Params: Pointer; AOptions: Word): Word;
begin
  MessageBoxRect := MessageBoxRectPrim(
    R, Msg, Params, AOptions, hcNoContext);
end;

function MessageBoxPrim(const Msg: String; Params: Pointer;
  AOptions, AHelpCtx: Word): Word;
var
  R: TRect;
begin
  R.Assign(
    ScreenWidth div 2 - 20, ScreenHeight div 2 - 5,
    ScreenWidth div 2 + 20, ScreenHeight div 2 + 4);
  MessageBoxPrim := MessageBoxRectPrim(R, Msg, Params, AOptions, AHelpCtx);
end;

function MessageBox(const Msg: String; Params: Pointer;
  AOptions: Word): Word;
begin
  MessageBox := MessageBoxPrim(Msg, Params, AOptions, hcNoContext);
end;

function CtxMessageBoxRect(var R: TRect;
  const Msg: String; Params: Pointer;
  AOptions, AHelpCtx: Word): Word;
begin
  CtxMessageBoxRect := MessageBoxRectPrim(
    R, Msg, Params, AOptions, AHelpCtx);
end;

function CtxMessageBox(const Msg: String; Params: Pointer;
  AOptions, AHelpCtx: Word): Word;
begin
  CtxMessageBox := MessageBoxPrim(Msg, Params, AOptions, AHelpCtx);
end;

(*
function InputBox(const Title: String; const ALabel: String; var S: String;
  Limit: Byte): Word;
var
  R: TRect;
begin
  R.Assign(0, 0, 60, 8);
  R.Move((Desktop^.Size.X - R.B.X) div 2, (Desktop^.Size.Y - R.B.Y) div 2);
  InputBox := InputBoxRect(R, Title, ALabel, S, Limit);
end;

function InputBoxRect(var Bounds: TRect;
  const Title: String; const ALabel: String;
  var S: String; Limit: Byte): Word;
var
  Dialog: PDialog;
  Control: PView;
  R: TRect;
  C: Word;
begin
  Dialog := New(PDialog, Init(Bounds, Title));
  with Dialog^ do
  begin
    R.Assign(4 + CStrLen(ALabel), 2, Size.X - 3, 3);
    Control := New(PInputLine, Init(R, Limit));
    Insert(Control);
    R.Assign(2, 2, 3 + CStrLen(ALabel), 3);
    Insert(New(PLabel, Init(R, ALabel, Control)));
    R.Assign(Size.X - 24, Size.Y - 4, Size.X - 14, Size.Y - 2);
    Insert(New(PMsgBoxButton, Init(R, ButtonName[2], cmOk, bfDefault)));
    Inc(R.A.X, 12); Inc(R.B.X, 12);
    Insert(New(PMsgBoxButton, Init(R, ButtonName[3], cmCancel, bfNormal)));
    Inc(R.A.X, 12); Inc(R.B.X, 12);
    SelectNext(False);
  end;
  Desktop^.Unlock;
  InputBoxRect := Application^.ExecuteDialog(Dialog, @S, True);
end;
*)

end.
