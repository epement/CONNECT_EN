Uses
 Windows, VpSysLow, SysUtils, Strings, Dos;

Var
 lpMsgBuf: Pchar;
 ErrorCode: Longint;
 c: Longint;
begin
Val(ParamStr(1), ErrorCode, C);
FormatMessage( FORMAT_MESSAGE_ALLOCATE_BUFFER OR
               FORMAT_MESSAGE_FROM_SYSTEM,
               Nil,
               ErrorCode, //GetLastError(),
               1024, // Default language
               @lpMsgBuf,
               0,
               Nil
);
Write(lpMsgBuf);
LocalFree(HLocal(lpMsgBuf));
end.
