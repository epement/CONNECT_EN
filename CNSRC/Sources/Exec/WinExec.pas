 
procedure ExecConsoleApp(CommandLine: AnsiString;
    Output: TStringList;
    Errors: TStringList);
var
   sa: TSECURITYATTRIBUTES;
   si: TSTARTUPINFO;
   pi: TPROCESSINFORMATION;
   hPipeOutputRead: THANDLE;
   hPipeOutputWrite: THANDLE;
   hPipeErrorsRead: THANDLE;
   hPipeErrorsWrite: THANDLE;
   Res, bTest: Boolean;
   env: array[0..100] of Char;
   szBuffer: array[0..256] of Char;
   dwNumberOfBytesRead: DWORD;
   Stream: TMemoryStream;
begin
   sa.nLength := sizeof(sa);
   sa.bInheritHandle := true;
   sa.lpSecurityDescriptor := nil;
   CreatePipe(hPipeOutputRead, hPipeOutputWrite, @sa, 0);
   CreatePipe(hPipeErrorsRead, hPipeErrorsWrite, @sa, 0);
   ZeroMemory(@env, SizeOf(env));
   ZeroMemory(@si, SizeOf(si));
   ZeroMemory(@pi, SizeOf(pi));
   si.cb := SizeOf(si);
   si.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
   si.wShowWindow := SW_HIDE;
   si.hStdInput := 0;
   si.hStdOutput := hPipeOutputWrite;
   si.hStdError := hPipeErrorsWrite;
 
(* Remember that if you want to execute an
app with no parameters you nil the
second parameter and use the first, you
can also leave it as is with no
problems.         *)
 
   Res := CreateProcess(nil, pchar(CommandLine), nil, nil, true,
     CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, nil, si, pi);
 
   // Procedure will exit if CreateProcess fail
   if not Res then
   begin
     CloseHandle(hPipeOutputRead);
     CloseHandle(hPipeOutputWrite);
     CloseHandle(hPipeErrorsRead);
     CloseHandle(hPipeErrorsWrite);
     Exit;
   end;
   CloseHandle(hPipeOutputWrite);
   CloseHandle(hPipeErrorsWrite);
 
   //Read output pipe
   Stream := TMemoryStream.Create;
   try
     while true do
     begin
       bTest := ReadFile(hPipeOutputRead, szBuffer, 256,
       dwNumberOfBytesRead, nil);
       if not bTest then
       begin
         break;
       end;
       Stream.Write(szBuffer, dwNumberOfBytesRead);
     end;
     Stream.Position := 0;
     Output.LoadFromStream(Stream);
   finally
     Stream.Free;
   end;
 
   //Read error pipe
   Stream := TMemoryStream.Create;
   try
     while true do
     begin
       bTest := ReadFile(hPipeErrorsRead, szBuffer, 256,
       dwNumberOfBytesRead, nil);
       if not bTest then
       begin
         break;
       end;
       Stream.Write(szBuffer, dwNumberOfBytesRead);
     end;
     Stream.Position := 0;
     Errors.LoadFromStream(Stream);
   finally
     Stream.Free;
   end;
 
   WaitForSingleObject(pi.hProcess, INFINITE);
   CloseHandle(pi.hProcess);
   CloseHandle(hPipeOutputRead);
   CloseHandle(hPipeErrorsRead);
end;

 
function DoRun(CommandLine: string; var ErrCode : integer) : boolean;
var
  i : integer;
  tRead, cWrite: cardinal;
  SA: TSecurityAttributes;
  PI: TProcessInformation;
  SI: TStartupInfo;
  sBuff: THandleStream;
  Str,
  StringBuf: TStringList;
  ret : Cardinal;
  m : TMemoryStream;
  fla : boolean;
  ss, ss1 : string;
begin
  Result := false;
  //Initialization
  SA.nLength:=SizeOf(SECURITY_ATTRIBUTES);
  SA.bInheritHandle:=True;
  SA.lpSecurityDescriptor:=nil;
  if not CreatePipe(tRead, cWrite, @SA, 0) then Exit;
  ZeroMemory(@SI, SizeOf(TStartupInfo));
  SI.cb:=SizeOf(TStartupInfo);
  SI.dwFlags:=STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
  SI.wShowWindow:=SW_HIDE;
  SI.hStdOutput:=cWrite;
  //SI.hStdError:=cWrite; // для суммирования обоих стдов в один 
  //Process Startup...
  Str := TStringList.Create;
  if CreateProcess(nil, PChar('rasdial.exe ' + CommandLine), nil, nil,
True, 0, nil, nil, SI, PI) then 
  begin
    sBuff := THandleStream.Create(tRead);
    StringBuf := TStringList.Create();
    m := TMemoryStream.Create;
    repeat
      //ждем какое-то время, к примеру полсекунды
      Ret := WaitForSingleObject(PI.hProcess, 500);
      StringBuf.Clear();
      if sBuff.Size > 0 then
      begin
        fla := (m.Size > 0) and not (PByteArray(m.Memory)^[m.Size - 1]
in [13, 10]);
        m.Size := 0;
        m.LoadFromStream(sBuff);
        m.Position := 0;
        StringBuf.LoadFromStream(m);
        if StringBuf.Count > 0 then
        begin
          if (Str.Count > 0) and fla then
          begin
            StringBuf.Strings[0] :=
Str.Strings[Str.Count-1]+StringBuf.Strings[0];
            Str.Delete(Str.Count-1);
          end;
        end;
        Str.AddStrings(StringBuf);
      end;
    until (Ret <> WAIT_TIMEOUT);
    m.Free;
    sBuff.Free;
    CloseHandle(PI.hProcess);
    CloseHandle(PI.hThread);
    //
    // здесь имеем результат
    //
    Str.SaveToFile('mylog.log');
    //
  end else
  begin
    // ошибка при запуске
  end;
  CloseHandle(tRead);
  CloseHandle(cWrite);
  Str.Free;
end;
