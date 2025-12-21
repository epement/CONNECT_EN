function ExecuteFile(FileName,StdInput: string;
                     TimeOut: integer;
                     var StdOutput:string) : boolean;

label Error;

type
  TPipeHandles = (IN_WRITE,  IN_READ,
                  OUT_WRITE, OUT_READ,
                  ERR_WRITE, ERR_READ);

type
  TPipeArray = array [TPipeHandles] of THandle;

var
  i         : integer;
  ph        : TPipeHandles;
  sa        : TSecurityAttributes;
  Pipes     : TPipeArray;
  StartInf  : TStartupInfo;
  ProcInf   : TProcessInformation;
  Buf       : array[0..1024] of byte;
  TimeStart : TDateTime;


function ReadOutput : string;
var
  i : integer;
  s : string;
  BytesRead : longint;

begin
  Result := '';
  repeat

    Buf[0]:=26;
    WriteFile(Pipes[OUT_WRITE],Buf,1,BytesRead,nil);
    if ReadFile(Pipes[OUT_READ],Buf,1024,BytesRead,nil) then
    begin
      if BytesRead>0 then
      begin
        buf[BytesRead]:=0;
        s := StrPas(@Buf[0]);
        i := Pos(#26,s);
        if i>0 then s := copy(s,1,i-1);
        Result := Result + s;
      end;
    end;

    if BytesRead <> 1024 then break;
  until false;
end;


begin
  Result := false;
  for ph := Low(TPipeHandles) to High(TPipeHandles) do
    Pipes[ph] := INVALID_HANDLE_VALUE;


  // Создаем пайпы
  sa.nLength := sizeof(sa);
  sa.bInheritHandle := TRUE;
  sa.lpSecurityDescriptor := nil;


  if not CreatePipe(Pipes[IN_READ],Pipes[IN_WRITE], @sa, 0 ) then
    goto Error;
  if not CreatePipe(Pipes[OUT_READ],Pipes[OUT_WRITE], @sa, 0 ) then
    goto Error;
  if not CreatePipe(Pipes[ERR_READ],Pipes[ERR_WRITE], @sa, 0 ) then
    goto Error;



  // Пишем StdIn
  StrPCopy(@Buf[0],stdInput+^Z);
  WriteFile(Pipes[IN_WRITE],Buf,Length(stdInput),i,nil);


  // Хендл записи в StdIn надо закрыть - иначе выполняемая программа
  // может не прочитать или прочитать не весь StdIn.

  CloseHandle(Pipes[IN_WRITE]);

  Pipes[IN_WRITE] := INVALID_HANDLE_VALUE;


  FillChar(StartInf,sizeof(TStartupInfo),0);
  StartInf.cb := sizeof(TStartupInfo);
  StartInf.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;


  StartInf.wShowWindow := SW_SHOW; // SW_HIDE если надо запустить невидимо


  StartInf.hStdInput := Pipes[IN_READ];
  StartInf.hStdOutput := Pipes[OUT_WRITE];
  StartInf.hStdError := Pipes[ERR_WRITE];


  if not CreateProcess(nil, PChar(FileName), nil,
                       nil, True, NORMAL_PRIORITY_CLASS,
                       nil, nil, StartInf, ProcInf) then goto Error;

  TimeStart := Now;

  repeat
    Application.ProcessMessages;
    i := WaitForSingleObject(ProcInf.hProcess,100);
    if i = WAIT_OBJECT_0 then break;
    if (Now-TimeStart)*SecsPerDay>TimeOut then break;
  until false;


  if iWAIT_OBJECT_0 then goto Error;
  StdOutput := ReadOutput;

  for ph := Low(TPipeHandles) to High(TPipeHandles) do
    if Pipes[ph] <> INVALID_HANDLE_VALUE then
      CloseHandle(Pipes[ph]);


  CloseHandle(ProcInf.hProcess);
  CloseHandle(ProcInf.hThread);
  Result := true;
  Exit;


Error:

  if ProcInf.hProcessINVALID_HANDLE_VALUE then

  begin
    CloseHandle(ProcInf.hThread);
    i := WaitForSingleObject(ProcInf.hProcess, 1000);
    CloseHandle(ProcInf.hProcess);
    if iWAIT_OBJECT_0 then

    begin
      ProcInf.hProcess := OpenProcess(PROCESS_TERMINATE,
                                      FALSE,
                                      ProcInf.dwProcessId);

      if ProcInf.hProcess  0 then
      begin
        TerminateProcess(ProcInf.hProcess, 0);
        CloseHandle(ProcInf.hProcess);
      end;
    end;
  end;

  for ph := Low(TPipeHandles) to High(TPipeHandles) do
    if Pipes[ph]INVALID_HANDLE_VALUE then
      CloseHandle(Pipes[ph]);

end;