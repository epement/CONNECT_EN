Program Pkt2Txt;

Uses
 Objects, Strings;
{$i fdpkt.inc}  {This is from the Front Door Developers Kit}

var
 Pkt : TBufStream;

Procedure WritePktHdr(Var Pkt : TBufStream);
 var
  I : Integer;
  PktHdr : FTS1PKTHDR;
begin
 Pkt.Read(PktHdr, SizeOf(FTS1PKTHDR));
 if Pkt.Status = stOk  then
  begin
   with PktHdr do
    begin
     WriteLn('Date:     ', Month, '.', Day:2, '.', Year - 1993, ' ', Hour:2, ':',
             Minute:2, ':', Second:2);
     WriteLn('From:     ',QMOrigZone,':',OrigNet,'/',OrigNode,'.',OrigPoint);
     WriteLn('To:       ',QMDestZone,':',DestNet,'/',DestNode,'.',DestPoint);
     Write  ('Password: ');
     i := 1;
     while (i <= 8) and (Password[i] <> #0) do
      begin
       Write(Password[i]);
       Inc(i);
      end;
     WriteLn;
    end;
  end;
end;

Procedure ReadStrz(Var Pkt : TBufStream; Strz : PChar; Len : Word);
var
 i : Word;
begin
 i := 0;
 while Pkt.Status = stOk do
  begin
   Pkt.Read(Strz[i], 1);
   if (Strz[i] = #0) or (i = Len) then Break;
   Inc(i);
  end;
 if i = Len then Strz[i] := #0;
end;

Procedure ReadStrzn(var Pkt : TBufStream; Strz : PChar; Len : Word);
var
 i : Word;
begin
 i := 0;
 while Pkt.Status = stOk do
  begin
   Pkt.Read(Strz[i], 1);
   if (Strz[i] in [#0, #13]) or (i = Len) then Break;
   Inc(i);
  end;
 if (Strz[i] = #13) or (i = Len) then Strz[i] := #0;
end;

Function ReadString(var Pkt : TBufStream; Var S : String) : Boolean;
var
 i,j : Word;
begin
 i := 1;
 while Pkt.Status = stOk do
  begin
   Pkt.Read(S[i], 1);
   if (S[i] in [#0, #13]) then Break;
   if S[i] = #10 then Continue;
   if S[i] = ^A then
    begin
     S[i] := '^';
     Inc(i);
     S[i] := 'A';
    end;
   Inc(i);
   if i = 79 then
    begin
     j := i;
     while j > 1 do
      begin
       if S[j] = ' ' then
        begin
         Pkt.Seek(Pkt.GetPos - i + j + 1);
         S[0] := Char(j-1);
         ReadString := False;
         Exit;
        end;
       Dec(j);
      end;
     if j = 1 then Break;
    end;
  end;
 ReadString := S[i] = #0;
 S[0] := Char(i-1);
end;


Procedure WriteMsgHdr(Var Pkt : TBufStream);
var
 ReadBytes : Word;
 MsgHdr : FTS1PKTMSG;
 AsciiDate,
 ToUser,
 FromUser,
 Subject,
 AreaTag: array[0..78] of char;
 MsgText : PChar;
 S : String;
begin
 Pkt.Read(MsgHdr, SizeOf(FTS1PKTMSG));
 if Pkt.Status = stOk then
  begin
   ReadStrz(Pkt, AsciiDate, 78);
   ReadStrz(Pkt, ToUser, 78);
   ReadStrz(Pkt, FromUser, 78);
   ReadStrz(Pkt, Subject, 78);
   ReadStrzn(Pkt, Areatag, 78);
   if Pos('AREA:', StrPas(Areatag)) <> 0 then WriteLn(Areatag)
   else WriteLn('Netmail');
   WriteLn('Date: ', AsciiDate);
   with MsgHdr do
    begin
     WriteLn('From: ', FromUser);
     WriteLn('To:   ', ToUser);
    end;
   WriteLn('Subj: ', Subject);
   WriteLn('------------------------------------------------------------------------------');
   if Areatag[0] = #1 then WriteLn('^A',Areatag+1);
   While not ReadString(Pkt, S) do WriteLn(S);
   WriteLn('------------------------------------------------------------------------------');
  end;
end;

begin
 if ParamCount = 0 then
  begin
   WriteLn('Pkt2Txt PktName > TxtName');
   Halt;
  end;
 Pkt.Init(ParamStr(1), stOpenRead, 4096);
 if Pkt.Status <> stOk then
  begin
   WriteLn('File ', ParamStr(1), ' not found.');
   Halt;
  end;
 WritePktHdr(Pkt);
 WriteLn('------------------------------------------------------------------------------');
 while Pkt.Status = stOk  do  WriteMsgHdr(Pkt);
 Pkt.Done;
end.