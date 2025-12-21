{$I-,X+,O+,F+}
unit ViewList;

interface

uses Dos, Objects, Drivers, Views, Dialogs, ProgList, ExtList;

type
  PViewList = ^TViewList;
  TViewList = object(TExtList)
    procedure GetExtStr(P: Pointer; var S: String;
      ForList: Boolean); virtual;
  end;

  PViewDialog = ^TViewDialog;
  TViewDialog = object(TExtDialog)
    constructor Init(const AName, AFocusName: FNameStr);
  end;

implementation

uses App, TPString, History, CNInputs, Consts, Commands;

procedure TViewList.GetExtStr(P: Pointer; var S: String;
  ForList: Boolean);
var
  HKS: String[15];
  Mask, Title, Condition: String;
begin
  FillChar(S, SizeOf(FNameStr), 0);
  if P = nil then Exit;
  SplitExecTitle(P, Mask, Title, Condition);
  if Mask <> '' then S := Mask;
  if not ForList then Exit;
  S[0] := #25;
  case PExecItem(P)^.HotKey of
    0: HKS := ' F3';
    1: HKS := ' Alt+F3';
    2: HKS := ' Shift+F3';
    else HKS := '';
  end;
  Move(HKS[1], S[26 - Length(HKS)], Length(HKS));
end;

constructor TViewDialog.Init(const AName, AFocusName: FNameStr);
var
  R: TRect;
  Control, Subview: PView;
begin
  R.Assign(0, 0, 78, ScreenHeight - 7);
  TDialog.Init(R, 'Viewer list³' + TrimmedName(AName, 51));
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcViewDlg;

  R.Assign(33, 3, Size.X - 14, 4);
  ProgName := New(PProgInputLine, Init(R, 255));
  Insert(ProgName);
  R.Assign(32, 2, Size.X - 14, 3);
  Insert(New(PLabel, Init(R, 'P~a~th to viewer', ProgName)));

  R.Assign(33, 6, Size.X - 14, 7);
  Control := New(PInputLine, Init(R, 255));
  Insert(Control);
  R.Assign(32, 5, Size.X - 14, 6);
  Insert(New(PLabel, Init(R, '~C~ommand line', Control)));

  R.Assign(33, 9, Size.X - 14, 10);
  Control := New(PInputLine, Init(R, 255));
  Insert(Control);
  Control^.Hide;

  R.Assign(33, 12, Size.X - 14, 13);
  Control := New(PInputLine, Init(R, 255));
  Insert(Control);
  Control^.Hide;

  R.Assign(3, Size.Y - 5, 15, Size.Y - 2);
  Control := MainControl(R);
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Control);
  R.Assign(2, Size.Y - 6, 15, Size.Y - 5);
  Subview := New(PLabel, Init(R, 'Main', Control));
  Subview^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Subview);

  R.Assign(17, Size.Y - 5, 40, Size.Y - 2);
  Control := SetupControl(R);
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Control);
  R.Assign(16, Size.Y - 6, 40, Size.Y - 5);
  Subview := New(PLabel, Init(R, 'Setup', Control));
  Subview^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Subview);

  R.Assign(42, Size.Y - 5, 64, Size.Y - 2);
  Control := OptionsControl(R, True);
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Control);
  R.Assign(41, Size.Y - 6, 64, Size.Y - 5);
  Subview := New(PLabel, Init(R, 'Options', Control));
  Subview^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Subview);

  R.Assign(30, 3, 31, Size.Y - 7);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3, 3, 30, Size.Y - 7);
  ProgList := New(PViewList, Init(R, PScrollBar(Control),
    AName, AFocusName));
  ProgList^.GrowMode := gfGrowHiY;
  ProgList^.StatusWord := 'Viewer';
  Insert(ProgList);
  R.Assign(2, 2, 31, 3);
  Insert(New(PLabel, Init(R, ' ~F~ile names            Key', ProgList)));
  R.Assign(3, Size.Y - 7, 30, Size.Y - 6);
  Control := New(PExtInfoPane, Init(R));
  Control^.GrowMode := gfGrowLoY + gfGrowHiY;
  Control^.EventMask := Control^.EventMask or evBroadcast;
  Insert(Control);

  R.Assign(Size.X - 13, 3, Size.X - 3, 5);
  Insert(New(PButton, Init(R, '~M~odify', cmModifyItem, bfDefault)));
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
  Insert(New(PButton, Init(R, '~N~ew', cmNewItem, bfNormal)));
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
  Insert(New(PButton, Init(R, 'Ad~j~ust', cmNewItemPos, bfNormal)));
  Inc(R.A.Y, 3); Inc(R.B.Y, 3);
  StandardCancelButton(R, @Self);
end;

end.
