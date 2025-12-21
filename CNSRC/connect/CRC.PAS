uses Objects, CRC32, tpString, Dos;

var
 F: PBufStream;
 Ch, PrevCh: Char;
 L: Longint;
 dt: DateTime; { For Pack/UnpackTime }
 SR: SearchRec;

 function LeadingZero(w : Word) : String;
 var
   s : String;
 begin
   Str(w:0,s);
   if Length(s) = 1 then
     s := '0' + s;
   LeadingZero := s;
 end;

begin
 F := New(PBufStream, Init(ParamStr(1), stOpenRead, 2048));
 Ch := #0;
 L := -1;
  while F^.Status = stOk do
    begin
     PrevCh := Ch;
     F^.Read(Ch, 1);
     if Ch < #32 then Ch := #32;
     if (Ch = #32) and (PrevCh = #32) then Continue;
     IncCRCUC(Ch, 1, L);
    end;
 Dispose(F, Done);
 Write(Pad(ParamStr(1),15),  HexL(L));
 FindFirst(ParamStr(1), $3f, SR);
 if DosError = 0 then
  begin
   UnpackTime(SR.time,dt);
   with dt do WriteLn(' ',
                      LeadingZero(Year),'-',
                      LeadingZero(Month),'-',
                      LeadingZero(Day),' ',
                      LeadingZero(hour),':',
                      LeadingZero(min),':',
                      LeadingZero(sec));
  end;
end.