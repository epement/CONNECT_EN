{$F+,O+,X+}
unit Exploder;

interface

uses Objects, Drivers, Views, Dialogs, App;

type
  PExplodeDialog = ^TExplodeDialog;
  TExplodeDialog = object(TDialog)
    PosCheck: PCheckBoxes;
    ExpCheck: PCheckBoxes;
    ScrollBar: PScrollBar;
    constructor Init;
    constructor Load(var S: TStream);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
  end;

procedure RSRExplodeDialog(RSR: PResourceFile);
procedure ExplodeDialog;

implementation

uses CNWinPos, EditMsg, UserScr, Consts;

constructor TExplodeDialog.Init;
var
  R: TRect;
begin
  R.Assign(0, 0, 49, 21);
  TDialog.Init(R, 'Window settings');
  Options := Options or ofCentered;
  HelpCtx := hcOExplode;

  R.Assign(3, 3, 35, 10);
  PosCheck := New(PCheckBoxes, Init(R,
    NewSItem('~M~emory map',
    NewSItem('~C~ode',
    NewSItem('~D~ump',
    NewSItem('~A~SCII table',
    NewSItem('Ca~l~culator',
    NewSItem('Cale~n~dar',
    NewSItem('CD ~P~layer',
    NewSItem('Cl~i~pboard',
    NewSItem('~W~atch',
    NewSItem('~O~utput',
    NewSItem('Messa~g~e',
    NewSItem('Te~r~minal',
    NewSItem('~B~ack',
    NewSItem('~H~elp', nil))))))))))))))));
  Insert(PosCheck);
  R.Assign(2, 2, 35, 3);
  Insert(New(PLabel, Init(R, 'Restore window position and size', PosCheck)));

  R.Assign(3, 12, 35, 15);
  ExpCheck := New(PCheckBoxes, Init(R,
    NewSItem('~E~xplode/Implode windows',
    NewSItem('New-~s~tyle icons and number',
    NewSItem('Le~f~t click always closes', nil)))));
  Insert(ExpCheck);
  R.Assign(2, 11, 35, 12);
  Insert(New(PLabel, Init(R, 'Window behaviour and style', ExpCheck)));

  R.Assign(3, 18, 35, 19);
  ScrollBar := New(PScrollBar, Init(R));
  ScrollBar^.Options := ScrollBar^.Options or ofSelectable;
  Insert(ScrollBar);
  R.Assign(2, 16, 35, 17);
  Insert(New(PLabel, Init(R, 'E~x~plode/Implode rate', ScrollBar)));
  R.Assign(2, 17, 35, 18);
  Insert(New(PLabel, Init(
    R, 'Fast         Medium         Slow', ScrollBar)));

  R.Assign(36, 3, 46, 5);
  StandardOkButton(R, @Self);
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
  StandardCancelButton(R, @Self);
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
  StandardHelpButton(R, @Self);
  Inc(R.A.Y, 9); Inc(R.B.Y, 9);
  Insert(New(PButton, Init(R, '~T~est', cmYes, bfNormal)));

  SelectNext(False);
end;

constructor TExplodeDialog.Load(var S: TStream);
begin
  TDialog.Load(S);
  GetSubViewPtr(S, PosCheck);
  GetSubViewPtr(S, ExpCheck);
  GetSubViewPtr(S, ScrollBar);
end;

procedure TExplodeDialog.HandleEvent(var Event: TEvent);
begin
  DoExplode := ExpCheck^.Value and 1 <> 0;
  ExplodeDelay := ScrollBar^.Value;
  TDialog.HandleEvent(Event);
end;

procedure TExplodeDialog.Store(var S: TStream);
begin
  TDialog.Store(S);
  PutSubViewPtr(S, PosCheck);
  PutSubViewPtr(S, ExpCheck);
  PutSubViewPtr(S, ScrollBar);
end;

procedure RSRExplodeDialog(RSR: PResourceFile);
var
  D: PExplodeDialog;
begin
  D := New(PExplodeDialog, Init);
  RSR^.Put(D, 'WINDOWSETTINGSDIALOG');
  Dispose(D, Done);
end;

procedure ExplodeDialog;
var
  SaveExplode, DoRedraw: Boolean;
  SaveDelay: Byte;
  C, W: Word;
  D: PExplodeDialog;
begin
  D := PExplodeDialog(Resource^.Get('WINDOWSETTINGSDIALOG'));
  if D <> nil then
  begin
    D^.PosCheck^.Value := WinPosMask and not (wpLeftClickCloses + wpIcons);
    if Byte(DoExplode) > 1 then Byte(DoExplode) := 1;
    D^.ExpCheck^.Value := Byte(DoExplode);
    if WinPosMask and wpIcons <> 0 then
      D^.ExpCheck^.Value := D^.ExpCheck^.Value or 2;
    if WinPosMask and wpLeftClickCloses <> 0 then
      D^.ExpCheck^.Value := D^.ExpCheck^.Value or 4;
    D^.ScrollBar^.SetParams(ExplodeDelay, 0, 15, 1, 1);
    SaveExplode := DoExplode;
    SaveDelay := ExplodeDelay;
    repeat
      C := Desktop^.ExecView(D);
    until C <> cmYes;
    W := D^.PosCheck^.Value;
    if D^.ExpCheck^.Value and 2 <> 0 then W := W or wpIcons;
    if D^.ExpCheck^.Value and 4 <> 0 then W := W or wpLeftClickCloses;
    Dispose(D, Done);
    if C = cmCancel then
    begin
      DoExplode := SaveExplode;
      ExplodeDelay := SaveDelay;
    end
    else
    begin
      DoRedraw := (WinPosMask and wpIcons) <> (W and wpIcons);
      WinPosMask := W;
      if DoRedraw then RefreshDisplay;
    end;
  end
  else ResourceNotFoundMsgBox('Window settings dialog');
end;

end.