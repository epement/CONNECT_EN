{$F+,O+,X+}
unit Timer;

interface

{ Event timer }

const
  TimerTicks: Word = 0;
  TimerCount: Word = 0;
  TimerWhat: Word = 0;
  TimerCommand: Word = 0;
  TimerActionClears: Boolean = False;
  TimerInUse: Boolean = False;

procedure InitTimer(Count, What, Command: Word; ActionClears: Boolean);
procedure ExecTimer;

{ Mouse cursor roller }

const
  RollerTicks: Word = 0;
  RollerCount: Byte = 0;
  RollerIndex: Byte = 0;
  RollerChars: Array[0..3] of Char = ('-', '\', '|', '/');
  RollerBack:  Boolean = False;
  RollerInUse: Boolean = False;

procedure InitRoller;
procedure UpdateRoller;
procedure DoneRoller;

implementation

uses Objects, Drivers, Views, App;

{ Event timer }

procedure InitTimer(Count, What, Command: Word; ActionClears: Boolean);
begin
  TimerTicks := MemW[$40:$6C];
  TimerCount := Count;
  TimerWhat := What;
  TimerCommand := Command;
  TimerActionClears := ActionClears;  
  TimerInUse := True;
end;

procedure ExecTimer;
begin
  if not TimerInUse then Exit;
  if MemW[$40:$6C] - TimerTicks < TimerCount then Exit;
  TimerInUse := False;
  Message(Application, TimerWhat, TimerCommand, nil);
end;

{ Mouse cursor roller }

procedure InitRoller;
begin
  RollerTicks := MemW[$40:$6C];
  RollerCount := 0;
  RollerIndex := 0;
  RollerBack  := False;
  RollerInUse := True;
  SetMouseShape(#0);
end;

procedure UpdateRoller;
var
  W: Word;
begin
  if not RollerInUse then Exit;
  if RollerCount < 8 then Inc(RollerCount)
  else
  begin
    W := MemW[$40:$6C] - RollerTicks;
    if (RollerCount = 8) and (W > 32) then DoneRoller
    else
    begin
      RollerCount := $FF;
      if W >= 2 then
      begin
	RollerTicks := MemW[$40:$6C];
	SetMouseShape(RollerChars[RollerIndex]);
	if RollerBack then
	  if RollerIndex = 0 then RollerIndex := 3
	  else Dec(RollerIndex)
	else
	  if RollerIndex = 3 then RollerIndex := 0
	  else Inc(RollerIndex);
      end;
    end;
  end;
end;

procedure DoneRoller;
begin
  SetMouseShape(#0);
  RollerInUse := False;
end;

end.