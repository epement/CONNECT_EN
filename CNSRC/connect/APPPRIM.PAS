{$F+,O+,X+}
unit AppPrim;

interface

uses Drivers, Views, Dialogs;

function ExecuteDialogPrim(P: PDialog; Data: Pointer; Top: Boolean): Word;
procedure SetScreenModePrim(Mode: Word);
procedure EmulateAutoIns(var Event: TEvent);

implementation

uses Objects, Memory, App, RGBDlg, CNCrt, Keyboard;

function ExecuteDialogPrim(P: PDialog; Data: Pointer; Top: Boolean): Word;
var
  C: Word;
begin
  ExecuteDialogPrim := cmCancel;
  if SPtr < $1000 then Application^.OutOfMemory
  else if Application^.ValidView(P) <> nil then
  begin
    if Data <> nil then P^.SetData(Data^);
    if Application^.ValidView(P) <> nil then
    begin
      if Top or (Desktop <> Pointer(Application^.Current)) then
	C := Application^.ExecView(P)
      else C := Desktop^.ExecView(P);
      if (C <> cmCancel) and (Data <> nil) then P^.GetData(Data^);
      Dispose(P, Done);
      ExecuteDialogPrim := C;
    end;
  end;
end;

procedure SetScreenModePrim(Mode: Word);
var
  R: TRect;
begin
  with Application^ do
  begin
    HideMouse;
    StoreRGB;
    if CustomVideoMode <> 0 then
      SetCustomVideoMode(CustomVideoMode)
    else SetVideoMode(Mode);
    RestoreRGB;
    DoneMemory;
    InitScreen;
    Buffer := ScreenBuffer;
    R.Assign(0, 0, ScreenWidth, ScreenHeight);
    ChangeBounds(R);
    ShowMouse;
  end;
end;

procedure EmulateAutoIns(var Event: TEvent);
var
  AutoIns: Boolean;
  C: Byte;
begin
  AutoIns := False;
  repeat
    Event.What := evKeyDown;
    Event.KeyCode := kbIns;
    Application^.HandleEvent(Event);
    for C := 0 to 5 do
    begin
      ClearKbd;
      if (KbdStatus <> 82) and (KbdStatus <> 224) then Exit;
      if AutoIns then Break;
      Delay(50);
    end;
    if KbdDelay <> 0 then Delay(KbdDelay);
    AutoIns := True;
  until False;
end;

end.