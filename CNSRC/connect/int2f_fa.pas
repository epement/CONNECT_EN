Uses int2f;

var
 fAttr: Longint;
 sAttr : String;

begin
 Inst_CN_NT;
 if ParamCount = 1 then
  begin
   fAttr := ntGetFAttr(ParamStr(1));
   Write(ParamStr(1), ' ');
   if (fAttr and $00000001) <> 0 then Write('Readonly ');
   if (fAttr and $00000002) <> 0 then Write('Hidden ');
   if (fAttr and $00000004) <> 0 then Write('System ');
   if (fAttr and $00000010) <> 0 then Write('Directory ');
   if (fAttr and $00000020) <> 0 then Write('Archive ');
   if (fAttr and $00000040) <> 0 then Write('Device ');
   if (fAttr and $00000080) <> 0 then Write('Normal ');
   if (fAttr and $00000100) <> 0 then Write('Temporary ');
   if (fAttr and $00000200) <> 0 then Write('Sparse_File ');
   if (fAttr and $00000400) <> 0 then Write('Reparse_Point ');
   if (fAttr and $00000800) <> 0 then Write('Compressed ');
   if (fAttr and $00001000) <> 0 then Write('Offline ');
   if (fAttr and $00002000) <> 0 then Write('Not_Content_Indexed ');
   if (fAttr and $00004000) <> 0 then Write('Encrypted ');
   WriteLn;
  end;
 if ParamCount = 2 then

(*
R  Readonly             = $00000001; {*}
H  Hidden               = $00000002; {*}
S  System               = $00000004; {*}
A  Archive              = $00000020; {*}
C  Compressed           = $00000800; {*}
E  Encrypted            = $00004000; {*}
*)
  begin
   sAttr := ParamStr(2);
   fAttr := ntGetFAttr(ParamStr(1));
   if Pos('+R', sAttr) <> 0 then fAttr := fAttr OR $00000001;
   if Pos('-R', sAttr) <> 0 then fAttr := fAttr AND NOT $00000001;
   if Pos('+H', sAttr) <> 0 then fAttr := fAttr OR $00000002;
   if Pos('-H', sAttr) <> 0 then fAttr := fAttr AND NOT $00000002;
   if Pos('+S', sAttr) <> 0 then fAttr := fAttr OR $00000004;
   if Pos('-S', sAttr) <> 0 then fAttr := fAttr AND NOT $00000004;
   if Pos('+A', sAttr) <> 0 then fAttr := fAttr OR $00000020;
   if Pos('-A', sAttr) <> 0 then fAttr := fAttr AND NOT $00000020;
   if Pos('+C', sAttr) <> 0 then fAttr := fAttr OR $00000800;
   if Pos('-C', sAttr) <> 0 then fAttr := fAttr AND NOT $00000800;
   if Pos('+E', sAttr) <> 0 then fAttr := fAttr OR $00004000;
   if Pos('-E', sAttr) <> 0 then fAttr := fAttr AND NOT $00004000;
   ntSetFAttr(ParamStr(1), fAttr);
  end;
end.