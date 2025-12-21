{$F+,O+,X+}
unit FMQuickD;

interface

uses Objects, FileMngr, BBSStuff, StrCol;

procedure QuickDescrPrim(FManager: PPanel);
procedure DescrDataToDirinfoPrim(FManager: PPanel);

implementation

uses Dos, Views, PanelRec, DirPrim, LFN, HeapUMB, TPString, Defaults;

procedure QuickDescrPrim(FManager: PPanel);
var
  Len, CRLF: Word;
  Pos: Longint;
  SR: PPanelRec;
  Name, DName, SName: FNameStr;
  F: lFile;
begin
  with FManager^ do
  begin
    FillChar(DescrData^, SizeOf(TDescrData), 0);
    SR := Opposite^.List^.At(Opposite^.Focused);
    if SR <> nil then
    begin
      Opposite^.GetRecStr(SR, Name);
      if SR^.Name[1] = '.' then DName := AddedSlash(Name)
      else DName := AddedSlash(JustPathName(Name));
      SetFirstFoundName(BBSNames, DName);
      if (DName <> '') and OpenBBSFile(DName, F, True) then
      begin
	if SR^.Name[1] = '.' then FindDescription(F.F, SR^.Name,
	  DescrData, Pos, Len, CRLF)
	else FindDescription(F.F, StUpcase(JustFileName(Name)),
	  DescrData, Pos, Len, CRLF);
	if (Pos = -1) and (SR^.Name[1] <> '.') then
	begin
	  lGetShortFileName(Name, SName);
	  if CompUCString(Name, SName) <> Equal then
	    FindDescription(F.F, StUpcase(JustFileName(SName)),
	      DescrData, Pos, Len, CRLF);
	end;
	Close(F.F);
	InOutRes := 0;
      end;
    end;
    DescrDataToDirinfoPrim(FManager);
    FocusItem(0);
    PWindow(Owner)^.Frame^.DrawView;
  end;
end;

procedure DescrDataToDirinfoPrim(FManager: PPanel);
var
  Ch: Char;
  B: Byte;
  Len, Idx, SpIdx: Integer;
  S: String;

procedure AddLine;
begin
{  FManager^.Dirinfo^.Insert(NewStr(Trim(S)));}
  FManager^.Dirinfo^.Insert(NewStrUMB(Trim(S)));
  S := '';
end;

begin
  with FManager^ do
  begin
    Dirinfo^.FreeAll;
    if BBSOptions and bbFormatData <> 0 then Len := Size.X
    else Len := 255;
    S := '';
    Idx := 1;
    SpIdx := 0;
    if Len <> 255 then
      while Idx <= DescrData^.Len do
       begin
	 Ch := DescrData^.Data[Idx];
	 if Ch in [' ', #13, #10] then
	  begin
	   if (Length(S) < Len) or (SpIdx = 0) then SpIdx := Idx;
	   Ch := ' ';
	  end;
	 if (Length(S) < 255) and ((Length(S) < Len) or (SpIdx = 0)) then
	  begin
	   if (S[Length(S)] <> ' ') or (Ch <> ' ') then
	    begin
	      Inc(S[0]);
	      S[Length(S)] := Ch;
	    end;
	  end
	 else
	  begin
	   if SpIdx <> 0 then
	    begin
	     B := Length(S);
	     while (B <> 0) and (S[B] <> ' ') do Dec(B);
	     if B <> 0 then S[0] := Char(B);
	     Idx := SpIdx;
	     SpIdx := 0;
	    end;
	   AddLine;
	  end;
	Inc(Idx);
       end
     else
      while (Idx <= DescrData^.Len) do
       begin
	 Ch := DescrData^.Data[Idx];
	 if Ch in [#13, #10] then
	  begin
	   while (Idx <= DescrData^.Len) and
	     (DescrData^.Data[Idx] in [#13, #10]) do Inc(Idx);
	   AddLine;
	  end
	 else
	  begin
	   if Length(S) < Len then
	    begin
	      Inc(S[0]);
	      S[Length(S)] := Ch;
	    end;
	   Inc(Idx);
	  end;
       end;
    if S <> '' then AddLine;
    UpdateDirinfoRanges;
  end;
end;

end.
