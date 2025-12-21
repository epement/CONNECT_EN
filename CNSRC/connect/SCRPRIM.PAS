{$F+,O+,X+}
unit ScrPrim;

interface

procedure UserScreenPrim;

implementation

uses Drivers, Memory, Views, App, UserScr, Commands, Defaults;

procedure UserScreenPrim;
var
  Event: TEvent;
  SaveMode, SaveCursor: Word;
  Copied: Boolean;
begin
  SaveMode := ScreenMode;
  SaveCursor := GetCursorState;
  Copied := False;
  HideMouse;
  RestoreUserScreen;
  repeat
    GiveTicks;
    GetMouseEvent(Event);
    if Event.What = evMouseDown then Break;
    GetKeyEvent(Event);
    if Event.What = evKeyDown then
      if (Event.KeyCode = kbCtrlIns) and (UserScreenBuffer <> nil) then
      begin
	Message(Desktop, evBroadcast, cmUserScreen, nil);
	Copied := True;
      end
      else if (Event.KeyCode = kbDel) and (UserScreenBuffer <> nil) then
      begin
	DoneMemory;
	DoneUserScreenBuffer;
	SaveCursorPos.X := 0;
	SaveCursorPos.Y := 0;
	RestoreUserScreen;
      end
      else Break;
  until False;
  LastIdleTime := 0;
  if CustomVideoMode <> 0 then SetCustomVideoMode(CustomVideoMode)
  else if ScreenMode <> SaveMode then SetVideoMode(SaveMode);
  FixPalette;
  SetCursorState(SaveCursor);
  ShowMouse;
  Application^.Redraw;
  if Copied then
  begin
    Message(Desktop, evBroadcast, cmUpdateViews, nil);
    Application^.Current^.SetState(sfFocused, True);
  end;
end;

end.