Uses
  int2f, DOS;

var
 dt: DateTime;
 fTime: Longint;

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
 Inst_CN_NT;
{ if ParamCount = 1 then}
  with dt do
   begin
     Year := 2005;
     Month := 2;
     Day := 6;
     Hour := 3;
     Min := 30;
     Sec := 10;
     PackTime(dt,fTime);
     WriteLn('Set time is ', ntSetFTime(ParamStr(0), fTime, 1));
     if ntGetFTime(ParamStr(0), fTime, 1) then
      begin
       UnpackTime(ftime,dt);
       Writeln('File timestamp is ',
                LeadingZero(Month),'-',
                LeadingZero(Day),'-',
                LeadingZero(Year), ' ',
                LeadingZero(Hour),':',
                LeadingZero(Min),':',
                LeadingZero(Sec));
      end;
   end;
end.