{
 From: Dmitry Orloff <do@kpi.kharkov.ua>
 Date:   Tue, 16 Jul 1996 22:46:57 EET

 А  ты  не  мог  бы поделиться сорцами, или сделать такую же программу, но
 чтобы она выдавала список файлов в stdout в виде:
  \DOC\NEW\PAPER.DOC  156711  05.21.95  14:36:22
}

{*********************************************************}
{*                                                       *}
{*       TDR lister 1.0                                  *}
{*                                                       *}
{*       Copyright (c) 1996 Alexander Petrosyan          *}
{*       Portions copyright (C) 1997 Dmitry Orlov        *}
{*                                                       *}
{*********************************************************}

uses
    DOS, Objects, TPString;

procedure FailProg (const S: string);
begin
  WriteLn (S);
  Halt (1);
end;

procedure Usage;
begin
  FailProg(' Usage:'^M^J'  TDR fileName[.TDR]'^M^J^M^J+
           '  Lists last written files');
end;

function PathLevel(const Name: String): Byte;
var
 i, l: Byte;
begin
 l := 0;
 for i := 1 to Length(Name) do
  if Name[i] = '\' then Inc(l);
 PathLevel := l;
end;

function TwoDigits(W: Word): string;
begin
  TwoDigits :=
    Char(Byte('0')+(W div 10 mod 10)) +
    Char(Byte('0')+(W mod 10))
end;

var
  LastRecordSector: Longint;
  UsedKiloBytes: Longint;
  TotalSeconds,
  UsedSeconds,
  FreeSeconds: Word;
  FreeKiloBytes: Longint;
  Descriptions, DescrOfs: Longint;
  DirsOffset: Longint;
  DirsCount: Word;
  FirstFile: Longint;
  FileCount: Word;
  FirstDir: Word;

procedure Init;

const
  stDenyNone = $40;
  ValidSignature = $00000074;
var
  TDRFileSpec: PathStr;
  TDR: TBufStream;
  D: DirStr;
  N: NameStr;
  E: ExtStr;
  W: Word;
  Signature: Longint;
  L: Longint;
  Bytes, FSize: Longint;
  TapeFormat: Word;
  NominalTapeDensity, TapeDensity: Word;
const
  Name: string [8] = '12345678';
  Ext: string [3] = '123';
var
  ListDir, FileName, S, Descr: string;
  DescrLen: Word;
  Level: Word;
  Path: array[1..100] of string[8+3];
  FullPath: string;
  I: Integer;
  PackedDT: Longint;
  DT: DateTime;
  DummyWord: Word;
  FileSize: Longint;
begin
  WriteLn (' TDR lister  Version 1.0');
  WriteLn (' Copyright (c) 1996 Alexander Petrosyan (535-2222 paf@fbit.msk.su 2:5020/468.8)');
  WriteLn;

  if ParamCount = 0 then Usage;

  TDRFileSpec := ParamStr(1);
  ListDir := StUpCase(ParamStr(2));

  TDR.Init (TDRFileSpec, stOpenRead or stDenyNone, $400);
  if TDR.Status <> 0 then
    FailProg (' Can''t open ' + TDRFileSpec);

  TDR.Read (Signature, SizeOf (Signature));
  if Signature <> ValidSignature then FailProg (' Invalid file format');
  with TDR do
  begin
    Seek(36);
    Read (Descriptions, SizeOf(Descriptions));
    Seek (4);
    Read (DirsOffset, SizeOf(DirsOffset));

    Seek ($10);
    Read (DirsCount, SizeOf(DirsCount));
    DirsCount := DirsCount div $28;
    FirstFile := 0;
    for W := 0 to DirsCount - 1 do
    begin
      Seek (DirsOffset + W*$28);
      Read (Level, SizeOf (Level));
      if Level <> 0 then
      begin
        Read(Name [1], SizeOf(Name)-1);
        Read(Ext [1], SizeOf(Ext)-1);
        FileName := TrimTrail(Name);
        S := TrimTrail(Ext);
        if S <> '' then FileName := FileName + '.' + S;
        Path[Level] := FileName;
      end;

      Seek(DirsOffset + W*$28 + $28-2);
      Read(FileCount, SizeOf(FileCount));

      FullPath := '\';
      for I := 1 to Level do
        FullPath := FullPath + Path[I] + '\';

     if (ListDir = '') or (ListDir = FullPath) then
      begin
       for L := FirstFile to FirstFile + FileCount - 1 do
       begin
         Seek ($74+L*$20);
         Read (Name [1], SizeOf (Name)-1);
         Read (Ext [1], SizeOf (Ext)-1);

         if (Ext = 'LOG') and (Copy(Name, 1, 3) = 'AVD') then
           Continue;

         Seek ($74+L*$20+8+3+1+4);
         Read (DescrOfs, 4);
         Descr := '';
         if DescrOfs <> 0 then
          begin
           Seek(Descriptions + DescrOfs - 1);
           Read(DescrLen, 2);
           Read(Descr[1], DescrLen);
           Descr[0] := Char(DescrLen);
          end;

         Seek ({ $74+L*$20+8+3+1+4+4+2} 138 + L * $20);
         Read(PackedDT, SizeOf(PackedDT));
         Read(DummyWord, SizeOf(DummyWord));
         Read(FileSize, SizeOf(FileSize));

         FileName := TrimTrail (Name);
         S := TrimTrail (Ext);
         if S <> '' then FileName := FileName + '.' + S;
         UnpackTime(PackedDT, DT);
         {\DOC\NEW\PAPER.DOC  156711  05.21.95  14:36:22}
         with DT do
           WriteLn (FullPath, FileName, '  ',
             FileSize, '  ',
             TwoDigits(Month), '-', TwoDigits(Day), '-', TwoDigits(Year), '  ',
             TwoDigits(Hour), ':', TwoDigits(Min), ':', TwoDigits(Sec),
             ' ', Descr);
       end;
      end
     else
      begin
       if (Pos(ListDir, FullPath) = 1) and
          (PathLevel(ListDir) + 1 = PathLevel(FullPath)) then
           WriteLn(FullPath)
      end;

      Inc (FirstFile, FileCount);
    end;
  end;
end;

begin
  Init;
end.
