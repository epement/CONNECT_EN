Uses int2f;

type
  Long =
    record
      LowWord, HighWord : Word;
    end;
const
  Digits : array[0..$F] of Char = '0123456789ABCDEF';

var
 SN: Longint;
 FileSystemFlags: Longint;

  function HexW(W : Word) : string;
    {-Return hex string for word}
  begin
    HexW[0] := #4;
    HexW[1] := Digits[hi(W) shr 4];
    HexW[2] := Digits[hi(W) and $F];
    HexW[3] := Digits[lo(W) shr 4];
    HexW[4] := Digits[lo(W) and $F];
  end;

  function HexL(L : LongInt) : string;
    {-Return hex string for LongInt}
  begin
    with Long(L) do
      HexL := HexW(HighWord)+HexW(LowWord);
  end;


begin
 Inst_CN_NT;
 if ParamCount = 0 then WriteLn(ParamStr(0), 'RootName [Label]');
 if ParamStr(2) = '' then
  begin
   WriteLn('Label: ', GetLabel(ParamStr(1)));
   GetVolumeInfo(ParamStr(1), SN, FileSystemFlags);
   if FileSystemFlags and fs_Vol_is_Compressed <> 0 then
    WriteLn('Compressed volume.');
   if FileSystemFlags and fs_File_Compression <> 0 then
    WriteLn('File compression allowed.');
   WriteLn('S/N:', HexL(SN));
   WriteLn('Flags:', HexL(FileSystemFlags));
  end
 else WriteLn('Set label ',SetLabel(ParamStr(1), ParamStr(2)));
end.