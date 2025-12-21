{************************************************}
{                                                }
{   Turbo Pascal 6.0                             }
{   Turbo Vision Demo                            }
{   Copyright (c) 1990 by Borland International  }
{                                                }
{************************************************}

unit Mouse;

{$F+,O+}

interface

uses Drivers, Objects, Views, Dialogs, App;

const
  CClickTester = #7#8;

type

  { TClickTester }

  {Palette layout}
  { 0 = Unclicked }
  { 1 = Clicked }

  PClickTester = ^TClickTester;
  TClickTester = object(TStaticText)
    Clicked: Boolean;
    constructor Init(var Bounds: TRect; AText: String);
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Draw; virtual;
  end;

  { TMouseDialog }

  PMouseDialog = ^TMouseDialog;
  TMouseDialog = object(TDialog)
    MouseScrollBar: PScrollBar;
    MouseCheckBoxes: PCheckBoxes;
    FMCheckBoxes: PCheckBoxes;
    constructor Init;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure ResetMouse;
procedure MouseDlg;

implementation

uses Consts;

{ TClickTester }

constructor TClickTester.Init(var Bounds: TRect; AText: String);
begin
  TStaticText.Init(Bounds, AText);
  Clicked := False;
end;

function TClickTester.GetPalette: PPalette;
const
  P: String[Length(CClickTester)] = CClickTester;
begin
  GetPalette := @P;
end;

procedure TClickTester.HandleEvent(var Event: TEvent);
begin
  TStaticText.HandleEvent(Event);
  if (Event.What = evMouseDown) then
  begin
    if Event.Double then
    begin
      Clicked := not Clicked;
      DrawView;
    end;
    Event.What := evNothing;
  end;
end;

procedure TClickTester.Draw;
var
  C: Byte;
  B: TDrawBuffer;
begin
  if Clicked then C := GetColor(2)
  else C := GetColor(1);
  MoveChar(B, ' ', C, Size.X);
  MoveStr(B, Text^, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

{ TMouseDialog }

constructor TMouseDialog.Init;
var
  R: TRect;
begin
  R.Assign(0, 0, 33, 21);
  TDialog.Init(R, 'Mouse options');
  Options := Options or ofCentered;
  HelpCtx := hcMouse;

  R.Assign(3, 7, 30, 13);
  MouseCheckBoxes := New(PCheckBoxes, Init(R,
    NewSItem('~R~everse mouse buttons',
    NewSItem('Save/Restore ~p~osition',
    NewSItem('~F~ast mouse reset',
    NewSItem('~T~rack mouse in menus',
    NewSItem('Disable cursor ~m~asks',
    NewSItem('~D~isable mouse usage', nil))))))));
  Insert(MouseCheckBoxes);
  R.Assign(2, 6, 30, 7);
  Insert(New(PLabel, Init(R, 'Options', MouseCheckBoxes)));

  R.Assign(3, 15, 30, 17);
  FMCheckBoxes := New(PCheckBoxes, Init(R,
    NewSItem('L~e~ft click drags',
    NewSItem('R~i~ght click tags', nil))));
  Insert(FMCheckBoxes);
  R.Assign(2, 14, 30, 15);
  Insert(New(PLabel, Init(R, 'File Manager', FMCheckBoxes)));

  R.Assign(3, 4, 30, 5);
  MouseScrollBar := New(PScrollBar, Init(R));
  MouseScrollBar^.SetParams(DoubleDelay, 1, 20, 1, 1);
  MouseScrollBar^.Options := MouseScrollBar^.Options or ofPreProcess;
  Insert(MouseScrollBar);
  R.Assign(2, 2, 30, 3);
  Insert(New(PLabel, Init(R, 'Mouse double click', MouseScrollBar)));

  R.Assign(3, 3, 30, 4);
  Insert(New(PClickTester, Init(R, 'Fast       Medium      Slow')));

  R.Assign(2, Size.Y - 3, 10, Size.Y - 1);
  StandardOkButton(R, @Self);
  R.Assign(11, Size.Y - 3, 20, Size.Y - 1);
  Insert(New(PButton, Init(R, 'Re~s~et', cmDefault, bfNormal)));
  R.Assign(Size.X - 12, Size.Y - 3, Size.X - 2, Size.Y - 1);
  StandardCancelButton(R, @Self);
  SelectNext(False);
end;

procedure ResetMouse;
begin
  DoneEvents;
  DetectMouse;
  InitEvents;
end;

procedure TMouseDialog.HandleEvent(var Event: TEvent);
var
  SaveOpt: Byte;
begin
  TDialog.HandleEvent(Event);
  DoubleDelay := MouseScrollBar^.Value;
  if (Event.What = evCommand) and (Event.Command = cmDefault) then
  begin
    SaveOpt := MouseOptions;
    MouseOptions := MouseCheckBoxes^.Value;
    ResetMouse;
    MouseOptions := SaveOpt;
    Event.What := evNothing;
  end;
end;

procedure MouseDlg;
type
  TMouseDataRec = record
    Options: Word;
    FMOptions: Word;
  end;
var
  SaveDelay, SaveOpt: Word;
  R: TMouseDataRec;
begin
  SaveDelay := DoubleDelay;
  SaveOpt := MouseOptions;
  R.Options := MouseOptions and not (moFMLDrag + moFMRTags);
  R.FMOptions := 0;
  if MouseOptions and moFMLDrag <> 0 then R.FMOptions := 1;
  if MouseOptions and moFMRTags <> 0 then R.FMOptions := R.FMOptions or 2;
  if Application^.ExecuteDialog(
    New(PMouseDialog, Init), @R, False) = cmCancel then
      DoubleDelay := SaveDelay
  else
  begin
    MouseOptions := R.Options;
    if R.FMOptions and 1 <> 0 then MouseOptions := MouseOptions or moFMLDrag;
    if R.FMOptions and 2 <> 0 then MouseOptions := MouseOptions or moFMRTags;
    if MouseOptions and moDisable <> 0 then
    begin
      DoneEvents;
      ButtonCount := 0;
    end
    else if (SaveOpt and moDisable <> 0) and
      (MouseOptions and moDisable = 0) then ResetMouse;
  end;
end;

end.