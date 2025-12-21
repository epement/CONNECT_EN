{$A+,B-,D+,E+,F+,G-,I-,L+,N+,O-,P-,Q-,R-,S-,T-,V-,X+,Y-}
{$M $4000,0,0 }   { 16K stack, no heap }

uses Dos, TPString;
var
  I : Byte;
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
  SS, CmdLine, ParamLine: string;
  T : Text;

procedure Macro(Const Key, Value : String; Var Line : String);
var
 Ps : Byte;
begin
repeat
 Ps := Pos(Key,StUpCase(Line));
 if Ps <> 0 then
  begin
   Delete(Line,Ps,Length(Key));
   Insert(Value,Line,Ps);
  end;
until Ps = 0;
end;

begin
  Writeln('LISTER Copyright (C) by Orlov D., 2:461/27, 1994');
  ParamLine := String(Ptr(PrefixSeg,$80)^);
  if ParamCount = 0 then
  begin
   Writeln('type filelist | lister program params !path!name!ext');
   Halt;
  end;
  Assign(T,'');
  Reset(T);
  if IOResult <> 0 then Halt;
  while not eof(T) do
   begin
    ReadLn(T,SS);
    CmdLine := ParamLine;
    FSplit(SS, Dir, Name, Ext);
    Macro('!PATH', Dir, CmdLine);
    Macro('!NAME', Name, CmdLine);
    Macro('!EXT', Ext, CmdLine);
    WriteLn(CmdLine);
    SwapVectors;
    Exec(GetEnv('COMSPEC'),'/C '+ CmdLine);
    SwapVectors;
   end;
  Close(T);
end.
