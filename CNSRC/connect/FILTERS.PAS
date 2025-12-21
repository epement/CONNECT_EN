{$F+,O+,X+}
unit Filters;

interface

function PosWord(Const SubStr,Str: String ; Const Terminal) : Byte;
function RGSearch(const SubStr: String; const Strg : String) : String;
function StringFilter(const Strg: String; Flt: String): String;
procedure GetFilters(P1, P2: Pointer;
  var NameFilter, LineFilter, ColumnFilter: String);
procedure FilterDebugStrings(const SourceStr, NameStr, LineStr: String;
  var NameFilter, LineFilter, ColumnFilter: String);

implementation

uses Revpos,GetID,tpString,Objects,Memory,RegExp,HeapUMB;

type
 PSRec = ^TSRec;
 TSRec = record
  Ps : Byte;
  Ps2 : Byte;
  PSearch : Pstring;
 end;

 PColl = ^TColl;
 TColl = object(TCollection)
  procedure FreeItem(Item: Pointer); virtual;
 end;

 procedure TColl.FreeItem(Item : Pointer);
 begin
  if Item <> Nil then
   begin
{     DisposeStr(PSRec(Item)^.PSearch);}
     DisposeStrUMB(PSRec(Item)^.PSearch);
     FreeMem(Item,SizeOf(TSRec));
   end;
 end;

function RGSearch(const SubStr: String; const Strg : String) : String;
var
 RegExpr : Pointer;
 SS : String;
begin
 RegExpr := RegCompile(StUpcase(SubStr));
 if RegExpr <> nil then
 begin
   SS := RegSearch(RegExpr,StUpcase(Strg));
   if SS = '' then RGSearch := SubStr
   else RGSearch := SS;
   RegFree(RegExpr);
 end;
end;

function StringFilter(const Strg: String; Flt : String):String;
Label
 Error;
var
 SrcPs: byte;
 Ps1,Ps2,Ps3, len: Byte;
 Arg1,Arg2 : Byte;
 Code : Integer;
 Index : Word;
 SRec : PSRec;
 Coll : Pcoll;
 RegExpr : PRegExp;
 SStr, SS: String;
begin
 Coll := new(PColl, Init(10,10));
 StringFilter := 'Filter error';
 Ps1 := 1;
 SrcPs := 1;
 repeat
  SStr := GetLiterals(Flt,Ps1,Ps2);
  if Ps2 <> 0 then
   begin
    Delete(Flt,Ps1,Ps2-Ps1+1);
    SRec := MemAlloc(SizeOf(TSRec));
    if SRec <> nil then
     begin
      RegExpr := RegCompile(StUpcase(SStr));
      if RegExpr <> Nil then
       begin
	SS := RegSearch(RegExpr,StUpcase(Strg));
	if SS <> '' then
	 begin
         if (RegExpr^.startp[1] <> nil) and
            (RegExpr^.endp[1] <> nil) then
           begin
             len := RegExpr^.endp[1] - RegExpr^.startp[1];
             if (len <= 255) then
	      begin
	       move(RegExpr^.startp[1]^, SS[1], len);
               SS[0] := char(len);
	      end;
           end;
          SRec^.Ps := FIPos(SS,Strg, SrcPs);
          SRec^.Ps2 := SRec^.Ps + Length(SS);
{          SRec^.PSearch := NewStr(SS);}
	  SRec^.PSearch := NewStrUMB(SS);
          SrcPs := SRec^.Ps2;
         end
        else
         begin
          SRec^.Ps := 0;
          SRec^.Ps2 := 0;
          SRec^.PSearch := Nil;
         end;
       end
      else
       begin
        SRec^.Ps := Pos(SStr,Strg);
        SRec^.Ps2 := SRec^.Ps + Length(SStr);
{        if SRec^.Ps <> 0 then SRec^.PSearch := NewStr(SStr)}
	if SRec^.Ps <> 0 then SRec^.PSearch := NewStrUMB(SStr)
        else SRec^.PSearch := Nil;
       end;
      RegFree(RegExpr);
      Coll^.Insert(SRec);
      Str(Coll^.Count-1,SStr);
      Insert('$$' + SStr,Flt,Ps1);
     end;
   end;
 until Ps2 = 0;

 Ps1 := 0;
 repeat
  Ps1 := FIPos('$COPY(',StUpCase(Flt),Ps1);
  if Ps1 <> 0 then
   begin
    Ps2 := FIPos(',',Flt,Ps1+6);
    if Ps2 =  0 then GoTo Error;
    SStr := SCopy(Flt,Ps1+6,Ps2);
    if Pos('$$',SStr) <> 0 then
    begin
     Delete(SStr,1,2);
     Val(DelChar(' ',SStr),Index,Code);
     if Code <> 0 then GoTo Error;
     Arg1 := TSRec(Coll^.At(Index)^).Ps2;
    end
    else
     begin
      Val(DelChar(' ',SStr),Arg1,Code);
      if Code <> 0 then GoTo Error;
     end;
    Ps3 := FiPos(')',Flt,Ps2);
    SStr := SCopy(Flt,Ps2 + 1,Ps3);
    if Pos('$$',SStr) <> 0 then
    begin
     Delete(SStr,1,2);
     Val(DelChar(' ',SStr),Index,Code);
     if Code <> 0 then GoTo Error;
     Arg2 := TSRec(Coll^.At(Index)^).Ps;
    end
    else
     begin
      Val(DelChar(' ',SStr),Arg2,Code);
      if Code <> 0 then GoTo Error;
     end;
    Delete(Flt,Ps1,Ps3-Ps1+1);
    if (Arg1 <> 0) and (Arg2 <> 0) then
      Insert(SCopy(Strg,Arg1,Arg2),Flt,Ps1);
   end;
 until Ps1 = 0;

 Ps1 := 0;
 repeat
  Ps1 := FIPos('$SEARCH(',StUpCase(Flt),Ps1);
  if Ps1 <> 0 then
   begin
    Ps3 := FiPos(')',Flt,Ps1);
    SStr := SCopy(Flt,Ps1 + 8,Ps3);
    if Pos('$$',SStr) = 0 then GoTo Error;
    Delete(SStr,1,2);
    Val(DelChar(' ',SStr),Index,Code);
    if Code <> 0 then GoTo Error;
    Delete(Flt,Ps1,Ps3-Ps1+1);
    if TSRec(Coll^.At(Index)^).PSearch <> Nil then
     Insert(SRec^.PSearch^,Flt,Ps1);
   end;
 until Ps1 = 0;

 Ps1 := 0;
 repeat
  Ps1 := FIPos('$POS(',StUpCase(Flt),Ps1);
  if Ps1 <> 0 then
   begin
    Ps3 := FiPos(')',Flt,Ps1);
    SStr := SCopy(Flt,Ps1 + 5, Ps3);
    if Pos('$$',SStr) = 0 then GoTo Error;
    Delete(SStr,1,2);
    Val(DelChar(' ',SStr),Index,Code);
    if Code <> 0 then GoTo Error;
    Delete(Flt,Ps1,Ps3-Ps1+1);
    if TSRec(Coll^.At(Index)^).PSearch <> Nil then
     begin
      Str(Pos(SRec^.PSearch^, Strg), SStr);
      Insert(SStr, Flt,Ps1);
     end;
   end;
 until Ps1 = 0;

 StringFilter := Flt;
Error:
 Dispose(Coll,Done);
end;

function PosWord(Const SubStr,Str: String ; Const Terminal) : Byte;
var
 Find : Boolean;
 Ps, Ps1, SS0, S0 : Byte;
begin
 PosWord := 0;
 Ps1 := 0;
 SS0 := Byte(SubStr[0]);
 S0 := Byte(Str[0]);
 repeat
  Ps := FIPos(SubStr,Str,Ps1);
  if Ps = 0 then Exit;
  Find := (Ps = 0) or ((Ps = 1) or (Str[Ps-1] in CharSet(Terminal))) and
   ((Ps + SS0 - 1 = S0) or (Str[Ps + SS0] in CharSet(Terminal)));
  Ps1 := Ps;
 until  Find;
 PosWord := Ps;
end;

procedure GetFilters(P1, P2: Pointer;
  var NameFilter, LineFilter, ColumnFilter: String);
var
  Ps: Byte;
  P: PString;
  S: String;
label
  Loop;
begin
  if P1 = nil then NameFilter := '' else NameFilter := PString(P1)^;
  if P2 = nil then S := '' else S := PString(P2)^;
  Ps := Pos(':', S);
Loop:
  if (Ps <> 0) and (Ps < Length(S)) and (S[Ps + 1] = ':') then
  begin
    Delete(S, Ps, 1);
    Ps := FIPos(':', S, Ps + 1);
    Goto Loop;
  end;
  if Ps = 0 then ColumnFilter := ''
  else
  begin
    ColumnFilter := Copy(S, Ps + 1, 255);
    S[0] := Char(Ps - 1);
  end;
  LineFilter := S;
end;

procedure FilterDebugStrings(const SourceStr, NameStr, LineStr: String;
  var NameFilter, LineFilter, ColumnFilter: String);

procedure RemoveSubStr(const SS: String; var S: String);
var
  I, J: Byte;
begin
  repeat
    I := Pos(SS, StUpcase(S));
    if I = 0 then Exit;
    J := FIPos(')', S, I);
    if J <> 0 then Delete(S, I, J - I + 1);
  until False;
end;

begin
  GetFilters(@NameStr, @LineStr, NameFilter, LineFilter, ColumnFilter);
  RemoveSubStr('$DOWN(', NameFilter);
  RemoveSubStr('$DOWN(', LineFilter);
  RemoveSubStr('$DOWN(', ColumnFilter);
  RemoveSubStr('$UP(', NameFilter);
  RemoveSubStr('$UP(', LineFilter);
  RemoveSubStr('$UP(', ColumnFilter);
  NameFilter := Trim(StringFilter(SourceStr, NameFilter));
  LineFilter := Trim(StringFilter(SourceStr, LineFilter));
  ColumnFilter := Trim(StringFilter(SourceStr, ColumnFilter));
end;

end.