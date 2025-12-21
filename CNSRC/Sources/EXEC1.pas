threadvar
  ProcessInfo: TProcessInformation;
  LastAsync: Boolean;

function SetResult(Success: Boolean): Longint;
begin
  Result := 0;
  if not Success then
    Result := GetLastError;
end;

function SysExec(Path,CmdLine,Env: PChar; Async: Boolean; PID: PLongint; StdIn,StdOut,StdErr: Longint): Longint;
var
  P: PChar;
  Flags: Longint;
  StartupInfo: TStartupInfo;
  CmdLineBuf: array [0..8191] of Char;
begin
  if (Path <> Nil) and (Path^ = #0) then Path := Nil;
  P := CmdLineBuf;
  if (Path <> Nil) and (Path^ <> '"') then
   begin
    P^ := '"';                   // Quotes to support spaces
    inc(P);
    P := StrECopy(P, Path);      // 'Path'#0
    P^ := '"';
    inc(P);
    P^ := ' ';
    inc(P);
   end;
  StrCopy(P, CmdLine);           // 'Path CommandLine'#0
  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  with StartupInfo do
  begin
    cb := SizeOf(TStartupInfo);
    dwFlags := startf_UseShowWindow;
    wShowWindow := sw_ShowNormal;
    if StdIn = -1 then hStdInput := SysFileStdIn
    else hStdInput := StdIn;
    if StdOut = -1 then hStdOutput := SysFileStdOut
    else hStdOutput := StdOut;
    if StdErr = -1 then hStdError := SysFileStdErr
    else hStdError := StdErr;
    if (StdIn <> - 1) or (StdOut <> -1) or (StdErr <> -1) then
      Inc(dwFlags, startf_UseStdHandles);
  end;
  Flags := normal_Priority_Class;
  LastAsync := Async;
  Result := SetResult(CreateProcess(Path, CmdLineBuf, nil, nil, True, Flags, Env, nil, StartupInfo, ProcessInfo));
  if Result = 0 then
    if Async then
      begin
        if PID <> nil then PID^ := ProcessInfo.hProcess;
      end
    else WaitForSingleObject(ProcessInfo.hProcess, Infinite);
end;

procedure Execute(const Path: PathStr; const ComLine: pchar);
var
  PathBuf: array[0..255] of Char;
begin
  ExCode := SysExec(StrPCopy(PathBuf, Path),
    ComLine, nil, ExecFlags = efAsync, nil, -1, OutHandle, ErrHandle);
end;

