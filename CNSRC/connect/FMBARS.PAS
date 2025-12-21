{$F+,O+,X+}
unit FMBars;

interface

uses Objects, Drivers, Views;

type
  PPanelBar = ^TPanelBar;
  TPanelBar = object(TScrollBar)
    Panel: PView;
    procedure Draw; virtual;
    procedure ScrollDraw; virtual;
    procedure AdjustBounds;
  end;

const
  baRight = 0;
  baLeft = 1;

  CPanelNormal     = 139;
  CPanelFocused    = 140;
  CPanelBarPage    = 250;
  CPanelBarIcons   = 251;
  CPanelBarColor   = #$31#$31;
  CPanelBarBW      = #$70#$70;
  CPanelBarMono    = #$70#$70;

implementation

uses App, FileMngr;

procedure TPanelBar.Draw;
var
  Normal, Focused: Char;
  P: PPalette;
begin
  P := Application^.GetPalette;
  Normal := P^[CPanelNormal];
  Focused := P^[CPanelFocused];
  P^[CPanelNormal] := P^[CPanelBarPage];
  P^[CPanelFocused] := P^[CPanelBarIcons];

  Inherited Draw;

  P^[CPanelNormal] := Normal;
  P^[CPanelFocused] := Focused;
end;

procedure TPanelBar.ScrollDraw;
var
  SaveSettings: Word;
begin
  with PPanel(Panel)^ do if Focused <> Value then
  begin
    SaveSettings := Settings;
    Settings := Settings and not sePanelBar;
    FocusItem(Value);
    Settings := SaveSettings;
  end;
end;

procedure TPanelBar.AdjustBounds;
var
  R: TRect;
begin
  with PPanel(Panel)^ do
  begin
    GetBounds(R);
    if BarAlignment = baLeft then Dec(R.A.X)
    else R.A.X := R.B.X;
    R.B.X := R.A.X + 1;

    if Settings and seBarMax = 0 then
      if Status = stInfo then
	if Size.Y <= 13 then R.A.Y := R.B.Y
	else Inc(R.A.Y, 11)
      else
      begin
	Dec(R.B.Y, Byte(State and sfMiniStatus <> 0) * 2);
	if Status <= stTree then
	  Inc(R.A.Y, Byte(Settings and seMaxi = 0));
	if R.B.Y - R.A.Y < 3 then R.A.Y := R.B.Y;
      end;
  end;

  Locate(R);
end;

end.