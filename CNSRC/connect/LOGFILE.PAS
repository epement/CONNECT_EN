{$F+,I-,O-,X+}
unit LogFile;

interface

procedure InitLog;
procedure WriteToLog(const Line: String);

implementation

uses Dos, Drivers, Gauges, DosTools, DirPrim, Defaults;

var
  Log: Text;
  LogReady: Boolean;

procedure InitLog;
var
  Fresh: Boolean;
  Year, Month, Day, DW, Hour, Min, Sec, SH: Word;
  S: String;
begin
  LogReady := False;
  if (EnableLog and loEnable = 0) or (LogName = '') then Exit;
  Fresh := False;
  Assign(Log, CNFileName(LogName));
  GetFAttr(Log, DW);
  Fresh := (DosError <> 0) or (DW and Directory <> 0);
  if Fresh then Rewrite(Log)
  else Append(Log);
  if IOResult <> 0 then Exit;
  if not NotAccessible(TextRec(Log).Handle) then
  begin
    LogReady := True;
    GetDate(Year, Month, Day, DW);
    GetTime(Hour, Min, Sec, SH);
    S := '----------  ' +
      FormatDateStr(Year, Month, Day) + ', ' +
      FormatTimeStr(Hour, Min, Sec);
    if not Fresh then Writeln(Log);
    Writeln(Log, S);
  end;
  Close(Log);
  InOutRes := 0;
end;

procedure WriteToLog(const Line: String);
var
  Tried: Boolean;
  C: Char;
  Hour, Min, Sec, SH: Word;
  S: String;
label
  Try;
begin
  Tried := False;
Try:
  if not LogReady or (EnableLog and loEnable = 0) or
    (LogClass and LogEvent = 0) then Exit;
  Append(Log);
  if IOResult <> 0 then
    if Tried then Exit
    else
    begin
      Tried := True;
      InitLog;
      Goto Try;
    end;
  GetTime(Hour, Min, Sec, SH);
  S := '  ' + FormatTimeStr(Hour, Min, Sec) + ' ';
  case LogEvent of
    lcDiskRead: C := '-';
    lcDiskWrite: C := '+';
    lcExec: C := '>';
    lcCommun: C := '';
    lcError: C := '!';
    lcWarning: C := '#';
    lcConfirm: C := '?';
    lcInfo: C := '^';
    lcConfig: C := '$';
    else C := ' ';
  end;
  S[1] := C;
  Writeln(Log, S + Line);
  Close(Log);
  InOutRes := 0;
end;

end.