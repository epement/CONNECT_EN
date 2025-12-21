Uses int2f, CRT;

const

  Copy_File_Fail_If_Exists = $00000001;
  Copy_File_Restartable = $00000002;
  Copy_File_ClearRO = $00000004;

  {CopyProgressRoutine return value}
  Progress_Continue = 0;  {Continue the copy operation.}
  Progress_Cancel = 1;    {Cancel the copy operation and delete the destination file.}
  Progress_Stop = 2;      {Stop the copy operation. It can be restarted at a later time.}
  Progress_Quiet = 3;     {Continue the copy operation, but stop invoking CopyProgressRoutine to report progress.}

function WriteProgress(LowLowCopy, LowHighCopy,
                       HighLowCopy, HighHighCopy,
                       LowLowSize, LowHighSize,
                       HighLowSize, HighHighSize: Word): Longint;
var
 Result: Longint; {Low = 0 - continue copy, Low = 1 - cancel copy}
                  {High = CopyProgressRoutine return value}
 Copy, Size: Real;
 Key: Char;


begin
 Copy := LowLowCopy + LowHighCopy * 65536.0 +
         HighLowCopy * 4294967296.0;

 Size := LowLowSize + LowHighSize * 65536.0 +
         HighLowSize * 4294967296.0;

 Write(Copy:10:0, ' of ', Size:10:0, ' ', 100*Copy/Size:4:1, '%'#13);
 if KeyPressed then
  begin
   Key := ReadKey;
   case Key of
    #27:  Result := 1; {Cancel}
    ' ', 'Q', 'q':  Result := $00030000;{Quiet}
    'S', 's': Result := $00020000;{Stop}
    'C', 'c': Result := $00010000;{Cancel}
   else Result := 0 {Continue}
   end;
  end
 else Result := 0; {Continue}
 if Result <> 0 then
  begin
   WriteLn('Are you shure? (Y/N)               ');
   if not (ReadKey in ['Y','y']) then Result := 0;
  end;
 WriteProgress := Result;
end;

procedure progress; far; assembler;
asm
 push ax
 push bx
 push cx
 push dx
 push si
 push di
 push es
 push ds
 mov ax, SEG @Data
 mov ds, ax
 call WriteProgress
 dw $0C4C4 {VDDUnSimulate16}
 db $0FE
end;

begin
 Inst_CN_NT;
 WriteLn(SysCopy(ParamStr(1), ParamStr(2), Copy_File_Restartable, @progress));
end.