program madli_tst;

{$APPTYPE CONSOLE}

Uses Windows, SysUtils,  UMadli;

function Progress(i: byte; count: byte): bool; stdcall;
begin
 Write(i, ' of ', count, #13);
 Progress := True;
end;

function Leds(L: byte): bool; stdcall;
begin
 case L of
  0: {RxLed_Off, TxLed_Off};
  1: {TxLed_On};
  2: {RxLed_On};
 end;
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
 port := OpenComPort(1, 4800, 8, 'N', 1, mError, @Leds);
 if port <> -1 then
  begin
   Addr := 4;

   WriteLn('Get Ram block:');
   GetRamBlock(port, Addr, 50, state, @Ram, mError, @Progress);
   WriteLn(ErrorStr(mError));

   WriteLn('Get EE block:');
   GetEEBlock(port, Addr, 50, @EE, mError, @Progress);
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

   until false;

   CloseComPort(port);
  end
 else WriteLn(ErrorStr(mError));
end.
