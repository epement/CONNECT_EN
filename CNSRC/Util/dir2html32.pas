{$B-,D+,H-,I-,J+,P-,Q-,R-,S-,T-,V+,W-,X+,Z-}
{&AlignCode+,AlignData+,AlignRec-,Asm-,Cdecl-,Comments-,Delphi+,Frame+,G5+}
{&LocInfo+,Open32-,Optimise+,OrgName-,SmartLink+,Speed+,Use32-,ZD-}
{$M 32768}

Program Dir2html32;

uses
 Use32, SysUtils, VpSysLow, Objects, Memory, Dos,  StrCol, TxtTools;

type
 TCode = (tAlt, tWin, tKoi);
 PSearchStrColl =  ^TSearchStrColl;
 TSearchStrColl = object(TStringsCollection)
  Code: TCode;
  function Find(Key: Pointer; var Index : Integer): Boolean;
 end;

 tXlat = array[#0..#255] of char;
 pXlat = ^tXlat;

 TMode = (mList, mTree);

const
 Files : PSearchStrColl = Nil;        {Files.Bbs}
 FNameSet : Set Of Char =
  ['!','#'..')','-','_','0'..'9','^','{','}',
   '~','','`','@'..'Z','a'..'z',':','\','.'];
 NumSet : Set Of Char = ['0'..'9'];
 AltSet = [#160 .. #175, #224 .. #239];
 KoiSet = [#193 .. #208, #210 .. #213, #198, #195, #219 .. #223, #217, #216, #192, #209];
 WinSet = [#224 .. #239, #240 .. #255];
 URL: String = '';
 OutOfMemory : Boolean = False;
 Count: Longint = 0;
 Size: Real = 0;
 Mode: TMode = mList;
 Ps: Byte = 0;


var
 FromDir: String;
 HtmlOut: Text;

{$L ALT2WIN.OBJ}

procedure alt2win; external;

{$L KOI82WIN.OBJ}

procedure koi82win; external;


function TSearchStrColl.Find(Key: Pointer; var Index : Integer): Boolean;
var
 RSearch : Boolean;
begin
 RSearch := False;
 Index := 0;
 if Count <> 0 then
 While (Index < Count) and not RSearch do
  begin
   RSearch := Pos(PString(Key)^, PString(At(Index))^) = 1;
   if not RSearch then Inc(Index);
  end;
 Find := RSearch;
end;

function GetLastName(const Dir: String): String;
var
 i, j: Byte;
begin
 j := Length(Dir);
 if Dir[j] = '\' then Dec(j);
 for i := j downto 1 do
  if Dir[i] = '\' then Break;
 GetLastName := Copy(Dir, i+1, j-i);
end;

function Space(Count : Byte) : String;
var
 SSS : String;
begin
 SSS[0] := Char(Count);
 FillChar(SSS[1],Count,' ');
 Space := SSS;
end;

function DeSpace(SS : String; B: Byte) : String;
begin
 while B < Length(SS) do
  begin
   if (SS[B] = ' ') and (SS[B+1] = ' ') then Delete(SS, B, 1)
   else inc(B);
  end;
 DeSpace := SS;
end;


Procedure MultiLine(Var T : Text; Const SS : String; Ps1, Ps2 : Byte);
{                                                    32   78         }
var
 B : Byte;
 I, J : Integer;
begin
 if Length(SS) < Ps2 then
  begin
   WriteLn(T,SS);
   Exit;
  end;
 for B := Ps2 DownTo Ps1 do
  if SS[B] = ' ' then Break;
 if B = Ps1 then B := Ps2;
 WriteLn(T, Copy(SS,1,B));
 repeat
  I := B; J := I + Ps2 - Ps1 - 1;
  if J < Length(SS) then
   begin
    for  B := J DownTo I do
     if SS[B] = ' ' then Break;
    if B = I then B := J;
    WriteLn(T,Space(Ps1 - 1),Copy(SS, I, B-I+1));
   end
  else
   begin
    J := Length(SS);
    WriteLn(T,Space(Ps1 - 1),Copy(SS, I, J-I+1));
   end;
 until J = Length(SS);
end;


function GetCurDate : String;
var
 Year, Month, Day, DayOfWeek : Word;
 SS, SSS : String;
begin
 SS := 'Created ';
 GetDate(Year, Month, Day, DayOfWeek);
 Str(Month, SSS);
 if Month > 9 then SS := SS + SSS
 else SS := SS + '0'+ SSS;
 Str(Day, SSS);
 if Day > 9 then SS := SS + '-'+ SSS
 else SS := SS + '-0'+ SSS;
 Str(Year, SSS);
 SS := SS + '-'+ Copy(SSS,3,2);
 GetCurDate := SS;
end;

Function MultiRead(Var T : Text; Ps : Byte) : String;
var
 TxtPos : Longint;
 ReadOther, ReadOne : Boolean;
 SStr, LStr : String;
 i: Byte;
begin
 ReadOther := False;
 ReadOne := False;
 LStr := '';
 While Not Eof(T) do
  begin
   TxtPos := TextPos(T);
   ReadLn(T,SStr);
   {SStr := DeTab(SStr, 8);}
   for i := 1 to Length(SStr) do
    if SStr[i] = #9 then SStr[i] := ' ';
   if ReadOther and (Pos(Space(Ps),SStr) = 1) then
    begin
     LStr := LStr + ' ' + DeSpace(Trim(SStr),1);
     MultiRead := LStr;
     Continue;
    end;
   if ReadOne then
    begin
     TextSeek(T,TxtPos);
     Exit;
    end;
   ReadOther := (SStr <> '') and (SStr[1] in (FNameSet-['-','\',':']));
   if SStr = '' then SStr := ' ';
   for i := 1 to byte(SStr[0]) do
     if SStr[i] = ' ' then Break
     else SStr[i] := UpCase(SStr[i]);
   LStr := DeSpace(SStr,Ps);
   ReadOne := True;
   MultiRead := LStr;
  end {while}
end;

procedure ReadBBS(const Dir: String);
var
 Cnt, I : Integer;
 FilesBbs : Text;       {Files.Bbs}
 SStr : String;
 Alt, Koi, Win: Integer;

begin
 Alt := 0; Koi := 0; Win := 0;
 Assign(FilesBbs, Concat(Dir, 'FILES.BBS'));
 Reset(FilesBbs);
 if IOResult = 0 then
  While Not Eof(FilesBbs) do
   begin
    SStr := MultiRead(FilesBBS, 1);
    {
    for I := 1 to Length(SStr) do
     SStr[I] := pXlat(@alt2win)^[SStr[I]];
    }
    for I := 1 to Length(SStr) do
     begin
      if SStr[I] in AltSet then Inc(Alt);
      if SStr[I] in KoiSet then Inc(Koi);
      if SStr[I] in WinSet then Inc(Win);
     end;
    Cnt := Files^.Count;
    Files^.Insert(NewStr(SStr));
    OutOfMemory := Cnt = Files^.Count;
    if OutOfMemory then Break;
   end; {while}
 Close(FilesBbs);
 InOutRes := 0;
 Files^.Code := tAlt;
 if (Koi > Alt) and (Koi > Win) then Files^.Code := tKoi;
 if (Win > Alt) and (Win > Koi) then Files^.Code := tWin;
end;

Procedure WriteHDR(const Title: String);
begin
   WriteLn(HtmlOut, '<html><head><meta http-equiv="Content-Language" content="ru">');
   WriteLn(HtmlOut, '<meta http-equiv="Content-Type" content="text/html; charset=windows-1251">');
   WriteLn(HtmlOut, '<title>',Title ,'</title></head><body>');
   Write(HtmlOut, '<table><th>',Title ,'/files</th><tr><td><b>name</b></td>');
   Write(HtmlOut, '<td align=right><b>size</b></td>');
   Write(HtmlOut, '<td align=center><b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;date&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</b></td>');
   Write(HtmlOut, '<td align=center><b>description</b></td></tr>');
end;

Procedure WriteFTR;
begin
   WriteLn(HtmlOut, '</table>');
   WriteLn(HtmlOut, '<b>', Size:10:0, ' bytes in ', Count, ' files.</b><br>');
   WriteLn(HtmlOut, '<i>', GetCurDate, '.</i>');
   WriteLn(HtmlOut, '</body></html>');
end;

Procedure WriteFName(const Dir: String; var SR : SearchRec);
var
 LStr: String;
 LDir: String;
 SS: String[5];
 DT : DateTime;
 I: Integer;
 begin
  if SR.Name = 'FILES.BBS' then Exit;
  if SR.Name = 'FILES.HTM' then Exit;
  if (SR.Attr and Directory <> 0) and (Mode = mList) then Exit;
  if (SR.Attr and Directory <> 0) and (SR.Name[1] <> '.') then
     LStr := Concat(SR.Name, '\FILES.HTM')
  else
    begin
     inc(Count);
     Size := Size + SR.Size;

     if URL <> '' then
      begin
       LDir := Concat(URL, Copy(Dir, Length(FromDir)+1, 255));
       for I := 1 to Length(LDir) do
        if LDir[I] = '\' then LDir[I] := '/'
        else LDir[I] := pXlat(@alt2win)^[LDir[I]];
      end
     else LDir := '';

     if Mode = mList then
       LStr := Concat(URL, Copy(Dir, Length(FromDir)+1, 255), SR.Name)
     else
       LStr := Concat(LDir, SR.Name);
    end;
  for I := 1 to Length(LStr) do
   if LStr[I] = '\' then LStr[I] := '/'
   else LStr[I] := pXlat(@alt2win)^[LStr[I]];
  Write(HtmlOut, '<tr><td><a href="', LStr, '">');
  LStr := SR.Name;
  for I := 1 to Length(LStr) do
   LStr[I] := pXlat(@alt2win)^[LStr[I]];
  if (SR.Attr and Directory <> 0) then
   Write(HtmlOut, '<b>',LStr, '</b></a></td>')
  else
   Write(HtmlOut, LStr, '</a></td>');
  if (SR.Attr and Directory <> 0) then
    Write(HtmlOut, '<td align=center><b>DIR</b></td>')
  else
    begin
     Str(SR.Size, LStr);
     Write(HtmlOut, '<td align=right>', LStr, ' </td>');
    end;
  LStr := '';
  UnpackTime(SR.Time, DT);
  Str(DT.Month, SS);
  if DT.Month > 9 then LStr :=  Concat(' ', SS)
  else LStr :=  Concat('0', SS);
  Str(DT.Day, SS);
  if DT.Day > 9 then LStr :=  Concat(LStr,'-', SS)
  else LStr :=  Concat(LStr,'-0', SS);
  Str(DT.Year, SS);
  LStr :=  Concat(LStr,'-', Copy(SS, 3, 2));
  Write(HtmlOut, '<td>', LStr, '</td>');
  LStr := AnsiUpperCase(SR.Name);
  if Files^.Find(@LStr, I) then
   begin
    LStr := Trim(Copy(Pstring(Files^.At(i))^, Length(SR.Name)+1, 255));
    for i := 1 to Length(LStr) do
     if Files^.Code = tAlt then LStr[I] := pXlat(@alt2win)^[LStr[I]]
     else
     if Files^.Code = tKoi then LStr[I] := pXlat(@koi82win)^[LStr[I]];
    WriteLn(HtmlOut, '<td> ',LStr,'</td></tr>');
   end
  else WriteLn(HtmlOut, '<td></td></tr>');
 end;

Procedure SearchDir(const Dir : String);
 Var
    SR : SearchRec;
 begin
   Files := New(PSearchStrColl, Init(10,10));
   if Mode = mTree then
    begin
     Assign(HtmlOut, Concat(Dir, 'FILES.HTM'));
     {Assign(HtmlOut, '');}
     ReWrite(HtmlOut);
     WriteHDR(GetLastName(Dir));
     Count := 0;
     Size := 0;
    end;
   ReadBBS(Dir);
   FindFirst(concat(Dir, '*.*'), AnyFile, SR);
   While DosError = 0 do
     begin
       With SR do
        {if Attr and (VolumeID + Directory) = 0 then}
        if (Name[1] <> '.') then
          WriteFName(Dir, SR);
       FindNext(SR);
     end;
   FindClose(SR);
   if Mode = mTree then
    begin
     WriteFTR;
     Close(HtmlOut);
    end;
   Dispose(Files, Done);

   FindFirst(concat(Dir, '*.*'), AnyFile, SR);
   While DosError = 0 do
     begin
       With SR do
        if (Attr and Directory <> 0) and (Name[1] <> '.') then
          SearchDir(concat(Dir, SR.Name, '\'));
       FindNext(SR);
     end;
   FindClose(SR);
 end;

Var
 pc: PChar;

begin
 InitMemory;
 WriteLn('Dir2Html [FromDir] [URL] [/t]');
 Writeln('Copyright (C) 2002, by Orlov D. http://www.orlov.wapil.com');
 pc := StrPos(CmdLine, '/t');
 if pc = Nil then pc := StrPos(CmdLine, '/T');
 if pc <> Nil then
  begin
   Mode := mTree;
   pc^ := #0;
  end;

 if ParamCount = 0 then GetDir(0, FromDir)
 else FromDir := ParamStr(1);
 if ParamCount >= 1 then URL := ParamStr(2);
 if FromDir[byte(FromDir[0])] <> '\' then
  begin
   inc(FromDir[0]);
   FromDir[byte(FromDir[0])] := '\';
  end;
 if Mode = mList then
  begin
   Assign(HtmlOut, Concat(FromDir, 'FILES.HTM'));
   {Assign(HtmlOut, '');}
   ReWrite(HtmlOut);
  end;
 if IOResult = 0 then
  begin
   if Mode = mList then WriteHDR(GetLastName(FromDir));
   SearchDir(FromDir);
   if Mode = mList then WriteFTR;
  end;
 if Mode = mList then Close(HtmlOut);
end.
