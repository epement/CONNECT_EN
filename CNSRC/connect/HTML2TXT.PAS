uses HtmlPrim, CRT, Objects;
var
 i: Byte;
 VideoSeg: Word;
 AHtml: PHtml;
 T: Text;
 S : String;

function IsDev: Boolean; assembler;
asm
        MOV     AX,4400H
        MOV     BX,1
        INT     21H
        MOV     AX,DX
        AND     AL,80H
end;

function Video: Word; assembler;
asm
        MOV     AH,0fh
        INT     10H
        CMP     AL,7
        MOV     AX,0B000h
        JE      @@1
        MOV     AX,0B800h
@@1:
end;

begin
 if ParamCount = 0 then
  begin
   WriteLn('Html2Txt HtmlName > TxtName');
   Halt;
  end;
 AHtml := New(PHtml, Init(77, True));
 with AHtml^ do
  begin
   if not InitStream(ParamStr(1), False) then
    begin
     WriteLn('File ', ParamStr(1), ' not found.');
     Halt;
    end;
  if IsDev then
   begin
    VideoSeg := Video;
{    ClrScr;}
    asm
     mov ax, 1003h
     mov bx, 0
     int 10h
    end;
    while FHtml^.Status = stOk  do
     begin
      S := GetLine;
      if not FirstLine then Continue;
      GoToXY(1,25);
      Move(S[1], Ptr(VideoSeg,$F00)^, Length(S));
      GoToXY(80,25);
      WriteLn;
      if Line mod 23 = 0 then
       if ReadKey = #27 then Break;
      end;
   end
  else
   begin
    Assign(T, '');
    ReWrite(T);
    while FHtml^.Status = stOk  do
     begin
      S := GetLine;
      if not FirstLine then Continue;
      i :=  1;
      while i < Length(S) do
       begin
        Write(T, S[i]);
        Inc(I, 2);
       end;
      WriteLn(T);
     end;
    Close(T);
   end;
   DoneStream;
  end;
 Dispose(AHtml, Done);
end.
D:\HTML\DOC\HTML3\CONTENTS.HTM
D:\3\1.HTM
D:\3\HTML\CAT\FAQLIST.HTM
D:\3\HTML\CAT\PUTI\CUSTOMS.HTM
