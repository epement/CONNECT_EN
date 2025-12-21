{$F+,O+,X+}
unit FMUsrMnu;

interface

uses Objects, Drivers, Views, Dialogs, ProgList;

type
  PUserMenuDialog = ^TUserMenuDialog;
  TUserMenuDialog = object(TProgDialog)
    constructor Init(const AName, AFocusName: FNameStr);
    procedure GetDlgTitle(const AName: FNameStr; var S: TTitleStr); virtual;
  end;

implementation

uses TPString, Consts;

constructor TUserMenuDialog.Init(const AName, AFocusName: FNameStr);
var
  I: Integer;
  R: TRect;
  Control, Subview: PView;
  S: TTitleStr;

procedure InsertNonSelControl;
begin
  Control^.Options := Control^.Options and not ofSelectable;
  Insert(Control);
end;

procedure InsertInputLine;
begin
  Inc(R.A.Y); Inc(R.B.Y);
  Control := New(PInputLine, Init(R, 255));
  InsertNonSelControl;
end;

procedure InsertClusters(Radio: Boolean);
var
  P: PSItem;
begin
  Inc(R.A.Y); Inc(R.B.Y);
  P := NewSItem('', NewSItem('', NewSItem('', nil)));
  if Radio then Control := New(PRadioButtons, Init(R, P))
  else Control := New(PCheckBoxes, Init(R, P));
  InsertNonSelControl;
end;

begin
  GetDlgTitle(AName, S);
  R.Assign(0, 0, 62, ScreenHeight - 8);
  TDialog.Init(R, S);
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcUserMenuDlg;

  R.Assign(1, 1, Size.X - 1, 2);
  ProgName := New(PProgInputLine, Init(R, 255));
  ProgName^.Options := ProgName^.Options and not ofSelectable;
  Insert(ProgName);

  for I := 1 to 3 do InsertInputLine;
  for I := 1 to 3 do InsertClusters(I = 1);

  R.Assign(1, 1, Size.X - 1, Size.Y - 1);
  ProgList := New(PProgList, Init(R,
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    AName, AFocusName));
  ProgList^.GrowMode := gfGrowHiY;
  Insert(ProgList);
end;

procedure TUserMenuDialog.GetDlgTitle(const AName: FNameStr;
  var S: TTitleStr);
begin
  S := 'User menu';
  if AName <> '' then S := S + ': ' + TrimmedName(AName, 40);
end;

end.