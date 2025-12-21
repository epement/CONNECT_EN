{$I-,X+,O+,F+}
unit PopUps;

interface

uses Objects, Drivers, Views, Menus, MenuBox;

type
  PLocalMenu = ^TLocalMenu;
  TLocalMenu = object(TMenuBox)
    constructor Init(var Bounds: TRect; AMenu: PMenu;
      AParentMenu: PMenuView);
    destructor Done; virtual;
    function Execute: Word; virtual;
  end;

procedure ShowPopup(AnOrigin: TPoint; AList: PMenu);

implementation

uses App;

constructor TLocalMenu.Init(var Bounds: TRect; AMenu: PMenu;
  AParentMenu: PMenuView);
begin  
  TMenuBox.Init(Bounds, AMenu, AParentMenu);
  GrowMode := gfExplode;
  GetBounds(Bounds);
  if Bounds.A.X < 0 then Bounds.Move(-Bounds.A.X, 0);
  if Bounds.B.X > 80 then Bounds.Move(80 - Bounds.B.X, 0);
  if Bounds.A.Y < 1 then Bounds.Move(0, 1 - Bounds.A.Y);
  if Bounds.B.Y > ScreenHeight - 1 then
     Bounds.Move(0, ScreenHeight - 1 - Bounds.B.Y);
  Locate(Bounds);
end;

destructor TLocalMenu.Done;
begin
  DisposeMenu(Menu);
  TMenuBox.Done;
end;

function TLocalMenu.Execute: Word;
var
  Event: TEvent;
begin
  Event.Command := TMenuBox.Execute;
  Execute := Event.Command;
  if Event.Command <> 0 then
  begin
    Event.What := evCommand;
    Event.InfoPtr := nil;
    PutEvent(Event);
  end;
end;

procedure ShowPopup(AnOrigin: TPoint; AList: PMenu);
var
  R: TRect;
  MB: PLocalMenu;
  C: Word;
begin
  R.Assign(AnOrigin.X, AnOrigin.Y, AnOrigin.X + 10, AnOrigin.Y + 10);
  MB := New(PLocalMenu, Init(R, AList, nil));
  if Application^.ValidView(MB) <> nil then
  begin
    C := Application^.ExecView(MB);
    Dispose(MB, Done);
  end;
end;

end.