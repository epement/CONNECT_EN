{$I-,F+,O+,X+}
unit FindAll;

interface

uses Objects, Drivers, Views, Dialogs;

type
  TInitViewerFunc = function(var R: TRect; HBar, VBar: PScrollBar;
    InfoPtr: Pointer): PView;

function FoundLinesCountStr(Count: Integer): String;
function CustomFindAllDialog(var R: TRect; const ALabel: String;
  InitViewerFunc: TInitViewerFunc; AInfoPtr: Pointer): PDialog;

implementation

uses Consts, Commands;

function FoundLinesCountStr(Count: Integer): String;
var
  S: String[5];
begin
  Str(Count, S);
  FoundLinesCountStr := ' lines (' + S + ')';
end;

procedure FindAllKeysProc(V: PView; var Event: TEvent);

function IsCaller(P: PView): Boolean; far;
begin
  IsCaller := P <> V;
end;

var
  C: PView;
begin
  if (Event.What = evKeyDown) and
     ((Event.KeyCode = kbCtrlUp) or (Event.KeyCode = kbCtrlDn)) then
  begin
    C := V^.Owner^.FirstThat(@IsCaller);
    Message(C, evKeyDown, Event.KeyCode, nil);
    Event.What := evNothing;
  end;
end;

function CustomFindAllDialog(var R: TRect; const ALabel: String;
  InitViewerFunc: TInitViewerFunc; AInfoPtr: Pointer): PDialog;
var
  D: PDialog;
  VBar, HBar: PScrollBar;
  Control: PView;
begin
  D := New(PDialog, Init(R, 'Found occurences'));
  with D^ do
  begin
    Options := Options or ofCentered;
    GrowMode := GrowMode + gfGrowHiY;
    HelpCtx := hcSHShowAllFound;
    PostProcessEvent := FindAllKeysProc;

    R.Assign(3, Size.Y - 2, Size.X - 15, Size.Y - 1);
    HBar := New(PScrollBar, Init(R));
    HBar^.Options := HBar^.Options or ofPostProcess;
    Insert(HBar);
    R.Assign(Size.X - 15, 2, Size.X - 14, Size.Y - 2);
    VBar := New(PScrollBar, Init(R));
    VBar^.Options := VBar^.Options or ofPostProcess;
    Insert(VBar);

    R.Assign(3, 2, Size.X - 15, Size.Y - 2);
    Control := InitViewerFunc(R, HBar, VBar, AInfoPtr);
    Control^.Options := Control^.Options or ofPostProcess;
    Insert(Control);
    R.Assign(2, 1, Size.X - 14, 2);
    Insert(New(PLabel, Init(R, ALabel, Control)));

    R.Assign(Size.X - 13, 2, Size.X - 3, 4);
    Insert(New(PButton, Init(R, '~G~o to', cmNewItem, bfDefault)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    Insert(New(PButton, Init(R, '~T~rack', cmModifyItem, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    StandardCancelButton(R, D);
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    StandardHelpButton(R, D);

    Control^.Select;
  end;

  CustomFindAllDialog := D;
end;

end.