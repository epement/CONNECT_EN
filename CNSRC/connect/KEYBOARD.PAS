unit Keyboard;

interface

const
  kbdDelay: Word = 0;

  PrevShiftState: Byte = 0;
  AltCtrlEvent: Boolean = False;
  AltStroke: Boolean = False;
  CtrlStroke: Boolean = False;

var
  KbdStatus: Byte;
  KbdHead: Byte absolute $40:$1A;
  KbdTail: Byte absolute $40:$1C;

procedure InitKbd;
procedure DoneKbd;
procedure ClearKbd;
procedure CheckAltCtrlStroke;

implementation

uses Dos, Drivers;

var
  KbdIntVec: procedure;

procedure KeyClick; interrupt;
begin
  KbdStatus := Port[$60];
  if (KeyboardOptions and koUseINT09 <> 0) and
     (KbdStatus <> 1) then KbdStatus := 0;
  inline($9C);
  KbdIntVec;
end;

procedure InitKbd;
begin
  GetIntVec(9, @KbdIntVec);
  SetIntVec(9, Addr(KeyClick));
  KbdStatus := 0;
end;

procedure DoneKbd;
begin
  SetIntVec(9, @KbdIntVec);
end;

procedure ClearKbd;
begin
  KbdHead := KbdTail;
end;

procedure CheckAltCtrlStroke;
var
  ShiftState: Byte absolute $40:$17;
begin
  AltStroke := not AltCtrlEvent and
    (PrevShiftState and 8 <> 0) and (ShiftState and 8 = 0);
  CtrlStroke := not AltCtrlEvent and
    (PrevShiftState and 4 <> 0) and (ShiftState and 4 = 0);
  if ShiftState and 12 = 0 then AltCtrlEvent := False;
  PrevShiftState := ShiftState;
end;

end.