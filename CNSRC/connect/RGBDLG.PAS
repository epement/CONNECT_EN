{$X+,O+,F+}
unit RGBDlg;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PColorList = ^TColorList;
  TColorList = object(TListViewer)
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
  end;

  PColorView = ^TColorView;
  TColorView = object(TView)
    Color: Integer;
    procedure Draw; virtual;
  end;

  PRGBDialog = ^TRGBDialog;
  TRGBDialog = object(TDialog)
    List: PColorList;
    RedBar: PScrollBar;
    GreenBar: PScrollBar;
    BlueBar: PScrollBar;
    RedLabel: PLabel;
    GreenLabel: PLabel;
    BlueLabel: PLabel;
    View: PColorView;
    Flag: Boolean;
    constructor Init;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

const
  InitRGB =
    #0#0#0#0#0#42#0#42#0#0#42#42#42#0#0#42#0#42#42#21#0#42#42#42#21#21#21 +
    #21#21#63#21#63#21#21#63#63#63#21#21#63#21#63#63#63#21#63#63#63;
  SaveRGB: String[48] = '';

procedure GetRGB;
procedure SetRGB;
procedure StoreRGB;
procedure FadeRGB;
procedure RestoreRGB;
procedure RGBDialog;

implementation

uses App, MsgBox, RGBColor, Defaults, Consts;

const
  TempRGB: String[48] = '';

procedure TColorList.FocusItem(Item: Integer);
begin
  TListViewer.FocusItem(Item);
  Message(Owner, evBroadcast, cmYes, Pointer(Focused));
end;

function TColorList.GetText(Item: Integer; MaxLen: Integer): String;
const
  ColorNames: Array[0..15] of String[13] = (
    'Black', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Brown',
    'Light Gray', 'Dark Gray', 'Light Blue', 'Light Green',
    'Light Cyan', 'Light Red', 'Light Magenta', 'Yellow', 'White');
begin
  if Item > 15 then GetText := ''
  else GetText := ColorNames[Item];
end;

procedure TColorView.Draw;
var
  B: TDrawBuffer;
begin
  MoveChar(B, 'Û', Color, Size.X);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

constructor TRGBDialog.Init;
var
  R: TRect;
  Control: PView;
begin
  R.Assign(0, 0, 46, 23);
  TDialog.Init(R, 'VGA Color registers');
  Options := Options or ofCentered;
  HelpCtx := hcRGBDialog;

  R.Assign(Size.X div 2 - 5, 3, Size.X div 2 - 4, Size.Y - 4);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3, 3, Size.X div 2 - 5, Size.Y - 4);
  List := New(PColorList, Init(R, 1, nil, PScrollBar(Control)));
  Insert(List);
  R.Assign(2, 2, Size.X div 2, 3);
  Insert(New(PLabel, Init(R, '~C~olors', List)));

  R.Assign(Size.X div 2 - 2, 3, Size.X - 3, 4);
  RedBar := New(PScrollBar, Init(R));
  RedBar^.Options := RedBar^.Options or ofSelectable;
  Insert(RedBar);
  R.Assign(Size.X div 2 - 3, 2, Size.X - 3, 3);
  RedLabel := New(PLabel, Init(R, '~R~ed:     ', RedBar));
  Insert(RedLabel);

  R.Assign(Size.X div 2 - 2, 5, Size.X - 3, 6);
  GreenBar := New(PScrollBar, Init(R));
  GreenBar^.Options := GreenBar^.Options or ofSelectable;
  Insert(GreenBar);
  R.Assign(Size.X div 2 - 3, 4, Size.X - 3, 5);
  GreenLabel := New(PLabel, Init(R, '~G~reen:   ', GreenBar));
  Insert(GreenLabel);

  R.Assign(Size.X div 2 - 2, 7, Size.X - 3, 8);
  BlueBar := New(PScrollBar, Init(R));
  BlueBar^.Options := BlueBar^.Options or ofSelectable;
  Insert(BlueBar);
  R.Assign(Size.X div 2 - 3, 6, Size.X - 3, 7);
  BlueLabel := New(PLabel, Init(R, '~B~lue:    ', BlueBar));
  Insert(BlueLabel);

  R.Assign(Size.X div 2 - 2, 10, Size.X - 3, Size.Y - 6);
  View := New(PColorView, Init(R));
  Insert(View);
  R.Assign(Size.X div 2 - 3, 9, Size.X - 3, 10);
  Insert(New(PLabel, Init(R, 'View', View)));

  R.Assign(Size.X div 2 - 2, Size.Y - 5, Size.X - 3, Size.Y - 4);
  Insert(New(PCheckBoxes, Init(R, NewSItem('~S~ave and restore', nil))));

  R.Assign(2, Size.Y - 3, 12, Size.Y - 1);
  StandardOkButton(R, @Self);
  R.Assign(Size.X div 2 - 6, Size.Y - 3, Size.X div 2 + 5, Size.Y - 1);
  Insert(New(PButton, Init(R, '~D~efault', cmDefault, bfNormal)));
  R.Assign(Size.X - 12, Size.Y - 3, Size.X - 2, Size.Y - 1);
  StandardCancelButton(R, @Self);
  BlueBar^.Value := -1;
  List^.SetRange(16);
  List^.Select;
  List^.FocusItem(0);
end;

procedure TRGBDialog.HandleEvent(var Event: TEvent);
var
  L: Longint;
  B: Byte;
  S: String;
begin
  TDialog.HandleEvent(Event);
  if Event.What = evBroadcast then
  begin
    case Event.Command of
      cmScrollBarChanged, cmScrollBarClicked:
	if (Event.InfoPtr = RedBar) or
	   (Event.InfoPtr = GreenBar) or
	   (Event.InfoPtr = BlueBar) then
	begin
	  if not Flag then
	  begin
	    SetRGBColor(List^.Focused,
	      RedBar^.Value, GreenBar^.Value, BlueBar^.Value);
	    B := List^.Focused * 3;
	    TempRGB[B + 1] := Char(RedBar^.Value);
	    TempRGB[B + 2] := Char(GreenBar^.Value);
	    TempRGB[B + 3] := Char(BlueBar^.Value);
	  end;
	  L := RedBar^.Value;
	  FormatStr(S, '%2d', L);
	  Move(S[1], RedLabel^.Text^[10], 2);
	  L := GreenBar^.Value;
	  FormatStr(S, '%2d', L);
	  Move(S[1], GreenLabel^.Text^[10], 2);
	  L := BlueBar^.Value;
	  FormatStr(S, '%2d', L);
	  Move(S[1], BlueLabel^.Text^[10], 2);
	  RedLabel^.DrawView;
	  GreenLabel^.DrawView;
	  BlueLabel^.DrawView;
	end;
      cmYes:
	begin
	  B := Event.InfoInt * 3;
	  Flag := True;
	  RedBar^.SetParams(Byte(TempRGB[B + 1]), 0, 63, 1, 1);
	  GreenBar^.SetParams(Byte(TempRGB[B + 2]), 0, 63, 1, 1);
	  BlueBar^.SetParams(Byte(TempRGB[B + 3]), 0, 63, 1, 1);
	  Flag := False;
	  View^.Color := $70 or Event.InfoInt;
	  View^.DrawView;
	end;
      else Exit;
    end;
    Event.What := evNothing;
  end
  else if (Event.What = evCommand) and (Event.Command = cmDefault) then
  begin
    TempRGB := SaveRGB;
    SaveRGB := InitRGB;
    SetRGB;
    SaveRGB := TempRGB;
    TempRGB := InitRGB;
    BlueBar^.Value := -1;
    List^.FocusItem(List^.Focused);
    Event.What := evNothing;
  end;
end;

procedure GetRGB;
var
  B: Byte;
begin
  SaveRGB[0] := #48;
  for B := 0 to 15 do GetRGBColor(B,
    Byte(SaveRGB[B * 3 + 1]),
    Byte(SaveRGB[B * 3 + 2]),
    Byte(SaveRGB[B * 3 + 3]));
end;

procedure SetRGB;
var
  B: Byte;
begin
  for B := 0 to 15 do SetRGBColor(B,
    Byte(SaveRGB[B * 3 + 1]),
    Byte(SaveRGB[B * 3 + 2]),
    Byte(SaveRGB[B * 3 + 3]));
end;

var
  FullRGB, SaveFullRGB: String;

procedure StoreRGB;
begin
  if not IsVGA then Exit;
  FullRGB[0] := #255;
  SaveFullRGB[0] := #255;
  GetRGBPalette(@FullRGB[1], 64);
  SaveFullRGB := FullRGB;
end;

procedure FadeRGB;
var
  B, C: Byte;
begin
  if not IsVGA then Exit;
  StoreRGB;
  for C := 0 to 63 do
  begin
    for B := 0 to 63 do
    begin
      if FullRGB[B * 3 + 1] > #0 then Dec(FullRGB[B * 3 + 1]);
      if FullRGB[B * 3 + 2] > #0 then Dec(FullRGB[B * 3 + 2]);
      if FullRGB[B * 3 + 3] > #0 then Dec(FullRGB[B * 3 + 3]);
    end;
    SetRGBPalette(@FullRGB[1], 64);
  end;
end;

procedure RestoreRGB;
begin
  if not IsVGA then Exit;
  SetRGBPalette(@SaveFullRGB[1], 64);
end;

procedure RGBDialog;
begin
  if not IsVGA then
  begin
    MessageBox(
      ^C'VGA palette functions are not enabled ' +
      'under current system configuration.',
      nil, mfError + mfOkButton);
    Exit;
  end;
  GetRGB;
  TempRGB := SaveRGB;
  if Application^.ExecuteDialog(New(PRGBDialog, Init),
    @RGBOptions, False) <> cmCancel then GetRGB
  else SetRGB;
end;

end.
