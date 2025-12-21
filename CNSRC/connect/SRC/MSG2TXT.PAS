Program Pkt2Txt;
Uses
 Memory, Objects, Strings;
{$i fdmsg.inc}  {This is from the Front Door Developers Kit}

var
 Msg : TBufStream;


function MSGAttr(Attr : Word) : String;
var
 S : String;
begin
 S := '';
 if (Attr and MSGPRIVATE) <> 0 then S := S + 'Private ';
 if (Attr and MSGCRASH) <> 0 then S := S + 'Crash ';
 if (Attr and MSGREAD) <> 0 then S := S + 'Read ';
 if (Attr and MSGSENT) <> 0 then S := S + 'Sent ';
 if (Attr and MSGFILE) <> 0 then S := S + 'File ';
 if (Attr and MSGTRANSIT) <> 0 then S := S + 'Transit ';
 if (Attr and MSGORPHAN) <> 0 then S := S + 'Orphan ';
 if (Attr and MSGKILL) <> 0 then S := S + 'Kill ';
 if (Attr and MSGLOCAL) <> 0 then S := S + 'Local ';
 if (Attr and MSGHOLD) <> 0 then S := S + 'Hold ';
 if (Attr and MSGUNUSED) <> 0 then S := S + 'Unused ';
 if (Attr and MSGFREQ) <> 0 then S := S + 'Freq ';
 if (Attr and MSGRRREQ) <> 0 then S := S + 'Rrreq ';
 if (Attr and MSGISRR) <> 0 then S := S + 'Isrr ';
 if (Attr and MSGAREQ) <> 0 then S := S + 'Areq ';
 if (Attr and MSGFUPDREQ) <> 0 then S := S + 'Fupdreq';
 MSGAttr := S;
end;


Procedure ReadStrz(Var Pkt : TBufStream; Strz : PChar; Len : Word);
var
 i : Word;
begin
 i := 0;
 while Msg.Status = stOk do
  begin
   Msg.Read(Strz[i], 1);
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
 while Msg.Status = stOk do
  begin
   Msg.Read(Strz[i], 1);
   if (Strz[i] in [#0, #13]) or (i = Len) then Break;
   Inc(i);
  end;
 if (Strz[i] = #13) or (i = Len) then Strz[i] := #0;
end;

Function ReadString(var Pkt : TBufStream; Var S : String) : Boolean;
var
 i,j : Word;
 Ps : Longint;
begin
 i := 1;
 while Msg.Status = stOk do
  begin
   Msg.Read(S[i], 1);
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
         Msg.Seek(Msg.GetPos - i + j + 1);
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

Procedure WriteMsgHdr(Var Msg : TBufStream);
 var
  I : Integer;
  S : String;
  MsgHdr : FidoMSG;
begin
 Msg.Read(MsgHdr, SizeOf(FidoMSG));
 if Msg.Status = stOk  then
  begin
   with MsgHdr do
    begin
     WriteLn('Date:     ', Date);
     WriteLn('From:     ', FromUser,', ',OrigNet,'/',OrigNode);
     WriteLn('To:       ', ToUser,', ',DestNet,'/',DestNode);
     WriteLn('Subj:     ', Subject);
     WriteLn(MSGAttr(Attr));
    end;
   WriteLn('------------------------------------------------------------------------------');
   While not ReadString(Msg, S) do WriteLn(S);
   WriteLn('------------------------------------------------------------------------------');
  end;
end;

begin
 if ParamCount = 0 then
  begin
   WriteLn('Msg2Txt MsgName > TxtName');
   Halt;
  end;
 InitMemory;
 Msg.Init(ParamStr(1), stOpenRead, 4096);
 if Msg.Status <> stOk then
  begin
   WriteLn('File ', ParamStr(1), ' not found.');
   Halt;
  end;
 WriteMsgHdr(Msg);
 Msg.Done;
end.
