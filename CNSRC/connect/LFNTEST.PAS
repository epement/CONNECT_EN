{$D+,L+}
uses Dos, Objects, LFN, TPString, Disks, CRC32, Strings;

var
  Class: DiskClass;
  Attr: Word;
  DT: DateTime;
  lSR: lSearchRec;
  SR: SearchRec;
  S,SS, Dir, Name, Ext: String;
  lF: lFile;
  lT: lText;
  c: Char;
  b: Byte;
  Stream: TDosStream;

function CRCShortName(const Name: String): String;
var
  Slash: Boolean;
  ColonPos: Byte;
  C: Char;
  I, L, Len: Integer;
  CRC: Longint;
  S: String;
begin
  Slash := False;
  L := 0;
  Len := Length(Name);
  if (Len > 1) and (Name[1] = '\') and (Name[2] = '\') then
    ColonPos := 1
  else ColonPos := Pos(':', Name);
  for I := 1 to Len do
  begin
    if Slash then
    begin
      C := TPString.Upcase(Name[I]);
      IncCRC(C, 1, CRC);
    end
    else
    begin
      Inc(L);
      S[L] := Name[I];
      S[0] := Char(L);
    end;
    if (I > ColonPos) and (Name[I] = '\') then
    begin
      if Slash then
      begin
	S := Concat(S, HexL(CRC), '\');
	L := Length(S);
      end;
      CRC := -1;
      Slash := True;
    end;
  end;
  if Slash and (CRC <> -1) then	S := Concat(S, HexL(CRC));
  CRCShortName := S;
end;

{
begin
 S := '\\Work.12345\1234567890.123.45\daksjfhdskjf.as\dsad.adsasd\asdjfahskdjshdj.ii';
 WriteLn(S);
 WriteLn(CRCShortName(S));
end.
}

{
begin
  lAPI := lWIN95;

  writeln(WildCardMatch('abcdef.a.b', 'abcdef.*.*'));

end.
}
(*
  WriteLn;
  WriteLn('DIR:');
  WriteLn;
  FindFirst('*.*', $3f, SR); { $00ef - files only}
			     { $10ff - dirs only}
			     { $00ff - all}
  while DosError = 0 do
  begin
    UnpackTime(SR.Time, DT);
    Writeln(Pad(SR.Name, 14),
      DT.Day:2, '-', DT.Month:2, '-', DT.Year, '  ',
      DT.Hour:2, ':', DT.Min:2, ':', DT.Sec:2, '  ',
      SR.Size:8, '  ', HexB(SR.Attr));

    FindNext(SR);
  end;

  Readln;
*)
(*
  lFindFirst('*.*', AnyFile, lSR); { $00ef - files only}
				 { $10ff - dirs only}
				 { $00ff - all}
  while DosError = 0 do
  begin
    UnpackTime(lSR.SR.Time, DT);
    Write(Pad(lSR.SR.Name, 14),
      DT.Day:2, '-', DT.Month:2, '-', DT.Year, '  ',
      DT.Hour:2, ':', DT.Min:2, ':', DT.Sec:2, '  ',
      lSR.SR.Size:8, '  ', HexB(lSR.SR.Attr));
    Writeln(' ', lSR.FullName:30);

    lFindNext(lSR);
  end;
  lFindClose(lSR);
  Readln;
*)
{
  S := 'e:\1\My_Long_Long_File.Name';
  S := '\\My_Long_Long_File\1.2';
}

{
S := '0123456789001234567890012345678900123456'+
     '78900123456789001234567890012345678900123456789001234'+
     '56789001234567890012345678900123456789001234567890012345678'+
     '9001234567890012345678901234567890012345678900123456'+
     '7890678900123456789001234567890123456789012345675abc';
}
{S := 'e:\1\ddsaljlaksj';
S := 'ddsaljlaksj';}
{SS := lFExpand(S);}

{
    S := 'E:\1';
    lGetShortFileName(S, S);
    Writeln(S);
}

begin
    lAPI := lWIN95;
{
    S := 'K:\2\qqqqqqqqqqqqqqqqq';
    lTrueName(S, S);
    Writeln(S);
}

    Writeln('lFExpand: ', lFExpand('\\ken_c\1'));

    lFSplit('\\A', Dir, Name, Ext);
    Writeln('Dir: ', Dir);
    Writeln('Name: ',Name);
    Writeln('Ext: ', Ext);Readln;

end.
{  S := '.';
  WriteLn(lFexpand(S));
  lGetDir(3, S);       }

{
  S := 'E:\1\qwer.ty\';

  lFSplit(S, Dir, Name, Ext);
  writeln(Dir);
  writeln(Name);
  writeln(Ext);Readln;
}

{
  lAssignText(lT, S);
  Rewrite(lT.T);
  WriteLn(lT.T, S);
  Close(lT.T);
}
{
  S := 'e:\1\My_Long_Long_File.Name';
  lAssignFile(lF, S);
  LRewriteFile(lF, 1);
  BlockWrite(lF.F, S, Length(S)+1);
  Close(lF.F);
}

{
  repeat
    Readln(S);
    if S = '' then Break;
    lGetShortFileName(S, S);
    Writeln(S);
  until False;
}


{
  fAPI := fWIN95;
  S := 'e:\1\LongStreamName.Stream';
  Stream.Init(S, stOpenWrite);
  Stream.WriteStr(@S);
  Stream.Done;
}

end.
