{$F+,O+}
unit FMAbort;

interface

function FMAbortAction: Boolean;
function StackOverflow: Boolean;

implementation

uses CNCrt, Drivers, Views, MsgBox, EditMsg, App, Keyboard, DosTools,
  Defaults;

function FMAbortAction: Boolean;
var
  B: Boolean;
begin
  FMAbortAction := False;
  repeat until KeyPressed or (KbdStatus <> 1);
  if not EscPressed then Exit;
  ClearKbd;
  B := (ConfirmOptions and coAbortFileManager = 0) or (AbortMsgBox = cmYes);
  if B then DrawStatusLine('Aborting current File Manager operation.')
  else DrawStatusLine('');
  FMAbortAction := B;
end;

function StackOverflow: Boolean;
const
  StackSafetyPool = $800;
begin
 if SPtr < StackSafetyPool then
 begin
   MessageBox(
     ^C'Program stack overflow.'#13 +
     ^C'Too many recursive calls.'#13 +
     ^C'Unable to complete operation.',
     nil, mfError + mfOkButton);
   StackOverflow := True;
 end
 else StackOverflow := False;
end;

end.