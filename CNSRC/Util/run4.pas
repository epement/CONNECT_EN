{$I-}
Program Run;

Uses
 Windows, VpSysLow, SysUtils, Strings, Dos;

type
 chars = array[0..1] of char;
 tStates = (Copy, Space, Tab, cr_lf, slash);

 TPipeHandles = (OUT_WRITE, OUT_READ,
                 ERR_WRITE, ERR_READ);

 TPipeArray = array [TPipeHandles] of THandle;

var
 terr, tout: Text;
 fall: File;
 ferr_name, fout_name, fall_name: String;
 State: tStates;
 Params: file;
 PrgName, ParamName, PrgPath, S: String;
 pComStr, pPath, pCmdLine, pc: pchar;
 i, j, l, ParamSize, CmdSize, CmdLen: Longint;
 c: char;
 OutHandle, ErrHandle: Longint;
 ExCode: Longint;
 ph: TPipeHandles;
 sa: TSecurityAttributes;
 Pipes: TPipeArray;
 StartInf: TStartupInfo;
 ProcInf: TProcessInformation;


threadvar
  ProcessInfo: TProcessInformation;
  LastAsync: Boolean;

function SetResult(Success: Boolean): Longint;
begin
  Result := 0;
  if not Success then
    Result := GetLastError;
end;

function SysExec(Path, Cmd, Env: PChar;
                 Async: Boolean;
                 PID: PLongint;
                 StdIn, StdOut, StdErr: Longint): Longint;
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
  StrCopy(P, Cmd);           // 'Path CommandLine'#0
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
  Flags := normal_Priority_Class+CREATE_SEPARATE_WOW_VDM{+CREATE_NEW_CONSOLE};
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

function GetEnvStr(const EnvVar: String): PChar;
var
  P: PChar;
  L: Word;
  EnvVarBuf: array [0..255] of Char;
begin
  StrPCopy(EnvVarBuf, EnvVar);
  L := Length(EnvVar);
  P := SysGetEnvironment;
  while P^ <> #0 do
  begin
    if (StrLIComp(P, EnvVarBuf, L) = 0) and (P[L] = '=') then
    begin
      Result := P + L + 1;
      Exit;
    end;
    Inc(P, StrLen(P) + 1);
  end;
  Result := nil;
end;

function GetPathStr(const pPath: Pchar; var i: longint): String;
var
 j: byte;
 SSS:String;
begin
 j := 0;
 while ((pPath+i)^ <> #0) do
  begin
   if ((pPath+i)^ <> ';') then
    begin
     inc(j);
     SSS[j] := (pPath+i)^;
     inc(i);
    end
   else
    begin
     inc(i);
     Break;
    end;
  end;
  if (j > 1) and (SSS[j] <> '\') then
   begin
    inc(j);
    SSS[j] := '\';
   end;
  SSS[0] := char(j);
  GetPathStr := SSS;
end;

function GetName(pc: pchar; var l: integer): String;
Var
 S: String;
 i: Byte;
begin
 i := 1;
 if pc^ = '"' then inc(pc);
 while not (pc^ in [#0, #9, #10, #13,' ', '"', '/']) do
  begin
   S[i] := pc^;
   inc(i); inc(pc);
  end;
 S[0] := Char(i-1);
 l := i;
 GetName := S;
end;

procedure MergePipes;
var
  Buf: Array[0..1023] of char;
  i : integer;
  BytesRead : longint;
begin
  {FileModeReadWrite := open_access_ReadWrite OR open_share_DenyNone;}
  if fall_name <> '' then
   begin
    if fall_name[1] = '+' then
     begin
      Delete(fall_name, 1, 1);
      Assign(fall, fall_name);
      Reset(fall, 1);
      if IOResult = 0 then Seek(fall, FileSize(fall))
      else ReWrite(fall, 1);
     end
    else
     begin
      Assign(fall, fall_name);
      InOutRes := 0;
      ReWrite(fall, 1);
     end;
    if IOResult = 0 then
     begin
       repeat
        ReadFile(Pipes[OUT_READ],Buf,1024,BytesRead,nil);
        BlockWrite(fall, Buf,  BytesRead);
       until  BytesRead <> 1024;

       repeat
        ReadFile(Pipes[ERR_READ],Buf,1024,BytesRead,nil);
        BlockWrite(fall, Buf,  BytesRead);
       until  BytesRead <> 1024;
       Close(fall);
       for ph := Low(TPipeHandles) to High(TPipeHandles) do
         if Pipes[ph] <> INVALID_HANDLE_VALUE then
           CloseHandle(Pipes[ph]);
     end;
   end;

end;


function GetNextParam(var p_next_ch: PChar): PChar;
const
  cmdidx: Longint = 0;
var
  next_ch: char;
  Res: PChar;
begin
 if p_next_ch <> Nil then
  begin
   while p_next_ch^ = ' ' do inc(p_next_ch);
   Res := p_next_ch;
   if p_next_ch^ = '"' then next_ch := '"'
   else next_ch := ' ';
   p_next_ch := StrScan(p_next_ch, next_ch);
   if p_next_ch <> Nil then
    begin
     p_next_ch^ := #0;
     inc(p_next_ch);
    end;
  end
 else Res := Nil;
 GetNextParam := Res;
end;

var
 NextParam, p_next_ch: PChar;
 Buf: array[0..1] of char;
 BytesRead: Longint;

begin
  ferr_name := '';
  fout_name := '';
  fall_name := '';

  p_next_ch := CmdLine;
  GetNextParam(p_next_ch); {dumb read (ParamStr(0)}
  {process command line from the beginning}
  repeat
   NextParam := GetNextParam(p_next_ch);
   if (NextParam^ = '/') then
    begin
     case (NextParam+1)^ of
      'a' : fall_name := GetName(NextParam+2,l);
      'o' : fout_name := GetName(NextParam+2,l);
      'e' : ferr_name := GetName(NextParam+2,l);
     end; {case}
    end
   else break;
  until false;

  ExCode := 1;
  PrgName := '';
  if (NextParam = Nil) or (NextParam^ = #0) then
   begin
    WriteLn('Win32 big command line programs runner. (C) Dmitry Orlov, 2005',
            #13#10'Run ([/o[+]outredir] [/e[+]errorredir])|([/a[+]allredir])',
            #13#10'[ProgramName] {ParamFile [params]})'
           );
    Halt(1);
   end;

  OutHandle := -1;
  ErrHandle := -1;

  if fall_name <> '' then
   begin
    ferr_name := '';
    fout_name := '';
    sa.nLength := sizeof(sa);
    sa.bInheritHandle := TRUE;
    sa.lpSecurityDescriptor := nil;

    Buf[0] := #13;
    Buf[1] := #10;
    if not CreatePipe(Pipes[OUT_READ], Pipes[OUT_WRITE], @sa, $8000) then
     begin
      Pipes[OUT_READ] := INVALID_HANDLE_VALUE;
      Pipes[OUT_WRITE] := INVALID_HANDLE_VALUE;
     end
    else WriteFile(Pipes[OUT_WRITE],Buf,2,BytesRead,nil);
    if not CreatePipe(Pipes[ERR_READ],Pipes[ERR_WRITE], @sa, $8000) then
     begin
      Pipes[ERR_READ] := INVALID_HANDLE_VALUE;
      Pipes[ERR_WRITE] := INVALID_HANDLE_VALUE;
     end
    else WriteFile(Pipes[ERR_WRITE],Buf,2,BytesRead,nil);

     OutHandle := Pipes[OUT_WRITE];
     ErrHandle := Pipes[ERR_WRITE];
   end;

  if ferr_name <> '' then
   begin
    if ferr_name[1] = '+' then
     begin
      Delete(ferr_name, 1, 1);
      Assign(terr, ferr_name);
      Append(terr);
      if IOResult <> 0 then ReWrite(terr);
     end
    else
     begin
      Assign(terr, ferr_name);
      ReWrite(terr);
     end;
    if IOResult = 0 then ErrHandle :=  TextRec(terr).Handle;
   end;

  if fout_name <> '' then
   begin
    if fout_name[1] = '+' then
     begin
      Delete(fout_name, 1, 1);
      Assign(tout, fout_name);
      Append(tout);
      if IOResult <> 0 then ReWrite(tout);
     end
    else
     begin
      Assign(tout, fout_name);
      ReWrite(tout);
     end;
    if IOResult = 0 then OutHandle :=  TextRec(tout).Handle;
   end;

  ParamName :=  StrPas(NextParam);
  NextParam := GetNextParam(p_next_ch);
  if (NextParam <> Nil) and (NextParam^ <> #0) then
   begin
    PrgName := ParamName;
    ParamName := StrPas(NextParam);
    if ExtractFileExt(PrgName) = '' then PrgName := Concat(PrgName, '.exe');
    if ExtractFileDir(PrgName) = '' then
     begin
      PrgPath := '';
      i := 0;
      pPath := GetEnvStr('PATH');

     { Executable file searching }
      while not FileExists(Concat(PrgPath, PrgName)) do
       begin
        PrgPath := GetPathStr(pPath, i);
        if PrgPath = '' then Break;
       end;
        PrgName := Concat(PrgPath, PrgName);
      end;
   end;

  if (PrgName = '') or FileExists(PrgName) then
   begin
    if FileExists(ParamName) then
    begin
      Assign(Params, ParamName);
      Reset(Params,1);
      if p_next_ch <> Nil then CmdSize := StrLen(p_next_ch)
      else CmdSize := 0;
      ParamSize := FileSize(Params)+CmdSize;
      if ParamSize < MaxAvail then
       begin
        GetMem(pComStr, ParamSize+2);
        BlockRead(Params, pComStr^, ParamSize);
        Close(Params);
        { Parameters processing }
        i := 0; j := 0;
        State := Copy;
        repeat
         c := (pComStr+j)^;
         if (c = #9) or (c = #10) or (c = #13) then
          begin
           (pComStr+j)^ := ' ';
           c := ' ';
          end;
         case State of
          Copy:  begin
                  if c >= ' ' then
                   begin
                    if i <> j then (pComStr+i)^ := (pComStr+j)^;
                    inc(i);
                   end;
                  inc(j);
                 end;
          Space: begin
                  while ((pComStr+j)^ <= ' ') or
                        ((pComStr+j)^ = '\') do inc(j);
                  State := Copy;
                 end;
         end;
         if (c = ' ') then State := Space;
        until j >= ParamSize;
        {Add command line}
        (pComStr+i)^ := ' ';
        inc(i);
        { Command line processing }

        if (p_next_ch <> Nil) and (p_next_ch^ <> #0) then
         begin
           pc := StrECopy(pComStr+i, p_next_ch);
           (pc + 1)^ := #0;
           (pc + 2)^ := #0;
         end
        else
         begin
          (pComStr+i)^ := #0;
          inc(i);
          (pComStr+i)^ := #0;
         end;

        Execute(PrgName, pComStr);
        FreeMem(pComStr);
        Close(terr);
        InOutRes := 0;
        Close(tout);
        InOutRes := 0;
        MergePipes;
       end;
    end;
   end;
  Halt(ExCode);
end.
