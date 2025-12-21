{$IFDEF Open32}
  {&cdecl+}
{$ELSE}
  {&StdCall+}
{$ENDIF Open32}
{&AlignRec+,SmartLink+,OrgName+,X+,Z+,Delphi+,Use32-}

Program m_tst;

Uses Windows, SysUtils, VpSysLow, CRT, UMadli;

function Progress(i: byte; count: byte): bool;
begin
 Write(i, ' of ', count, #13);
 if KeyPressed and (ReadKey = #27) then Progress := False
 else Progress := True;
end;

var
 cc, ccc: char;
 port: THandle;
 res: byte;
 data: word;
 state: byte;
 mError: byte;
 Ram: array[0..255] of word;
 EE: array[0..255] of byte;
 P: Pchar;
 Addr: Word;


begin
 port := OpenComPort(1, 4800, 8, 'N', 1, mError, Nil);
 if port <> INVALID_HANDLE_VALUE then
  begin
   Addr := 841;

   SetBallAddr(port, 1023, mError);
   WriteLn(ErrorStr(mError));

   SetBallAddr(port, Addr, mError);
   WriteLn(ErrorStr(mError));

   WriteLn('Get Ram block:');
   GetRamBlock(port, Addr, 50, state, @Ram, mError, Progress);
   WriteLn(ErrorStr(mError));

   WriteLn('Get EE block:');
   GetEEBlock(port, Addr, 50, @EE, mError, Progress);
   WriteLn(ErrorStr(mError));

   WriteLn('Set EE block:');
   SetEEBlock(port, 0, Addr, 50, @EE, mError, Progress);
   WriteLn(ErrorStr(mError));


   if not SetEE(port, 0, Addr, 0, 100, mError) then
     WriteLn(ErrorStr(mError));
   repeat
     if GetRam(port, Addr, 21, state, data, mError) then
      Write('State ', state, ' Tout ', data)
     else  WriteLn(ErrorStr(mError));

     Delay(15);

     if GetEE(port, Addr, 0, data, mError) then
      Write(' Pref ', data, #13)
     else WriteLn(ErrorStr(mError));
     Delay(15);

     if KeyPressed then cc := ReadKey;
     case cc of
      'O': bSwitch(port, 0, Addr, byte(mcmOn), 255, mError);
      'F': bSwitch(port, 0, Addr, byte(mcmOff), 255, mError);
     end;
   until cc = #27;

   CloseComPort(port);
  end
 else WriteLn(ErrorStr(mError));
end.