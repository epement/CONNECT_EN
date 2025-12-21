{$F+,O+,X+}
unit Spooler;

interface

uses Objects, CmntList, LFN, EditFile;

type
  PSpoolerRec = ^TSpoolerRec;
  TSpoolerRec = record
    FromDisk: Boolean;
    case Boolean of
      False: (
        Editor: Pointer;
        Lo, Hi: Integer);
      True: (
        Source: ^lText;
        SourceSize: Longint;
        Binary, Unix, XLAT: Boolean;
        XLATTable: ^ConvertTable);
  end;

  PSpooler = ^TSpooler;
  TSpooler = object(TCollection)
    Printer: lText;
    Current: PSpoolerRec;
    FontBuffer: PByteArray;
    PrintBuffer: PByteArray;
    FontBufSize: Word;
    PrintBufSize: Word;
    PrnRec: PPrnRec;
    Options: Word;
    CharsPerCycle: Word;
    InitString: PString;
    LeftMargin: Byte;
    TopMargin: Byte;
    BottomMargin: Byte;
    LinesPerPage: Byte;
    Interval: Real;
    LineString: PString;
    Index: Integer;
    TopIndex: Integer;
    PageIndex: Integer;
    LinePos: Integer;
    PrintBufLen: Integer;
    PortNumber: Byte;
    FontNumber: Byte;
    InitFlag: Boolean;
    DoUpdate: Boolean;
    procedure FreeItem(Item: Pointer); virtual;
    function NewEditor(P: Pointer; Lo, Hi: Integer): PSpoolerRec;
    function NewSource(const Name: String): PSpoolerRec;
    procedure DeleteItem(Item: Integer);
    function InQueue(P: Pointer): Boolean;
    procedure Update;
    function LoadFont(Num: Byte): Boolean;
    function InitPrinter(P: PSpoolerRec): Boolean;
    procedure DonePrinter;
    procedure SetInitString(const S: String);
    procedure SetLineString(const S: String);
    procedure ProcessItems;
    procedure PrintLine;
    procedure Abort;
  end;

  PFont = ^TFont;
  TFont = Array[1..12, 0..2] of Byte;

  PFontArray = ^TFontArray;
  TFontArray = Array[0..255] of TFont;

const
  TheSpooler: PSpooler = nil;

procedure SetSpoolerXLAT(P: PSpoolerRec; T: ConvertTable);
procedure GetPrnValues(PrnRec: PPrnRec;
  var LeftMargin, TopMargin, BottomMargin,
  LinesPerPage, Interval: Byte; var CharsPerCycle: Word);

implementation

uses Dos, Strings, Views, Drivers, Memory, App, EditMsg, DirPrim, DiskBase,
  DosTools, HeapUMB, TPString, Commands, Defaults;

procedure SetSpoolerXLAT(P: PSpoolerRec; T: ConvertTable);
begin
{  GetMem(P^.XLATTable, SizeOf(ConvertTable));}
  GetMemUMB(P^.XLATTable, SizeOf(ConvertTable));
  P^.XLATTable^ := T;
  P^.XLAT := True;
end;

const
  prnOk = $90;
  prnOutOfPaper = $38;

function PrnStatus(PortNumber: Byte): Byte; assembler;
asm
        MOV     AH,prnOk
        CMP     PortNumber,2
        JA      @@1
        MOV     AH,2
        XOR     DH,DH
        MOV     DL,PortNumber
        INT     17H
@@1:
        MOV     AL,AH
end;

{
 INT 21h  AH=3F
 INT 21 - DOS 2+ - "READ" - READ FROM FILE OR DEVICE
         AH = 3Fh
         BX = file handle
	 CX = number of bytes to read
	 DS:DX -> buffer for data
 Return: CF clear if successful
	     AX = number of bytes actually read (0 if at EOF before call)
	 CF set on error
	     AX = error code (05h,06h) (see #1332 at AH=59h/BX=0000h)
 Notes:  data is read beginning at current file position, and the file position
	   is updated after a successful read
	 the returned AX may be smaller than the request in CX if a partial
	   read occurred
	 if reading from CON, read stops at first CR
	 under the FlashTek X-32 DOS extender, the pointer is in DS:EDX
 BUG:    Novell NETX.EXE v3.26 and 3.31 do not set CF if the read fails due to
	   a record lock (see AH=5Ch), though it does return AX=0005h; this
	   has been documented by Novell
}

function DOSBlockRead(Handle: Word; var Buf; Count: Word): Word; assembler;
asm
	MOV	AH,3FH
	MOV     BX,Handle
	MOV	CX,Count
	PUSH	DS
	LDS	DX,Buf
	INT	21H
	POP	DS
	JNC	@@1
	XOR	AX,AX
@@1:
end;

const
  IntervalStr =
{     0   1   2   3   4   5   6   7   8   9   }
{1.0} #024#025#025#025#025#026#026#026#027#027 +
{1.1} #027#028#028#028#028#029#029#029#029#030 +
{1.2} #030#030#030#031#031#031#032#032#032#032 +
{1.3} #032#032#032#034#034#034#034#035#035#035 +
{1.4} #036#036#036#037#037#038#038#038#039#039 +
{1.5} #040#040#040#041#041#042#042#043#043#043 +
{1.6} #044#044#044#045#045#045#046#046#046#046 +
{1.7} #047#047#048#048#048#049#049#049#050#050 +
{1.8} #051#051#052#052#052#053#053#053#054#054 +
{1.9} #055#055#055#056#056#056#056#057#058#058 +
{2.0} #059#059#060#060#060#061#061#062#062#063 +
{2.1} #063#063#064#064#065#066#066#066#067#067 +
{2.2} #068#068#069#069#070#070#071#071#072#072 +
{2.3} #073#073#073#074#074#075#075#076#076#077 +
{2.4} #077#078#078#079#079#080#080#081#081#082 +
{2.5} #083#083#084#084#085#085#086#086#087#087 +
{2.6} #088#088#089#089#090#090#091#091#092#092 +
{2.7} #093#094#094#095#095#096#096#097#098#099 +
{2.8} #100#100#101#101#102#103#104#104#105#105 +
{2.9} #106#107#108#109#109#110#110#111#111#112 +
{3.0} #113#113#114#114#115#116#117#117#118#119 +
{3.1} #120#120#121#122#122#123#123#124#125#126 +
{3.2} #127#127#128#129#129#130#130#131#132#133 +
{3.3} #134#135#136#136#137#138#139#140#140#141 +
{3.4} #142#143#144#145#146#147#148#149#150#151 +
{3.5} #152#153#154#155#156#156;

  LinesStr =
{     0  1  2  3  4  5  6  7  8  9  }
{020}             #65#63#62#60#59#55 +
{030} #54#53#51#50#49#47#46#46#45#44 +
{040} #43#42#41#41#40#39#39#38#38#37 +
{050} #37#36#35#35#35#34#33#33#33#32 +
{060} #32#31#31#30#30#30#29#29#29#29 +
{070} #28#28#28#28#28#27#27#27#27#27 +
{080} #26#26#26#26#26#25#25#25#25#25 +
{090} #24#24#24#24#24#23#23#23#23#23 +
{100} #23#23#22#22#22#22#22#22#22#22 +
{110} #22#22#22#21#21#21#21#21#21#21 +
{120} #20#20#20#20#20#20#20#20#20#20 +
{130} #20#20#20#20#20#19#19#19#19#19 +
{140} #19#19#19#19#19#19#19#19#19#19 +
{150} #19#19#18#18#18#18#18;

procedure GetPrnStrValue(PrnRec: PPrnRec; PrnRecStr: PString;
  const PrnStr: String; var Value: Byte);
var
  Code: Integer;
begin
  if (PrnRec <> nil) and (PrnRecStr <> nil) then
    Val(PrnRecStr^, Value, Code)
  else if (PrnRec = nil) and (PrnStr <> '') then
    Val(PrnStr, Value, Code)
  else Value := 0;
end;

procedure GetPrnValues(PrnRec: PPrnRec;
  var LeftMargin, TopMargin, BottomMargin,
  LinesPerPage, Interval: Byte; var CharsPerCycle: Word);
var
  Code: Integer;
  Options: Word;
  R: Real;
  S: String;
begin
  GetPrnStrValue(PrnRec, PrnRec^.PrnLeftMargin,
    PrnLeftMargin, LeftMargin);
  GetPrnStrValue(PrnRec, PrnRec^.PrnTopMargin,
    PrnTopMargin, TopMargin);
  GetPrnStrValue(PrnRec, PrnRec^.PrnBottomMargin,
    PrnBottomMargin, BottomMargin);
  GetPrnStrValue(PrnRec, PrnRec^.PrnLinesPerPage,
    PrnLinesPerPage, LinesPerPage);
  if (PrnRec <> nil) and (PrnRec^.PrnCharsPerCycle <> nil) then
    Val(PrnRec^.PrnCharsPerCycle^, CharsPerCycle, Code)
  else if (PrnRec = nil) and (PrnCharsPerCycle <> '') then
    Val(PrnCharsPerCycle, CharsPerCycle, Code)
  else CharsPerCycle := 0;
  if CharsPerCycle = 0 then CharsPerCycle := 1;
  if (PrnRec <> nil) and (PrnRec^.PrnInterval <> nil) then
    Val(PrnRec^.PrnInterval^, R, Code)
  else if (PrnRec = nil) and (PrnInterval <> '') then
    Val(PrnInterval, R, Code)
  else R := 0;
  if R < 1.0 then R := 1.0
  else if R > 3.54 then R := 3.54;
  S := IntervalStr;
  Interval := Byte(S[Trunc((R - 1) * 100 + 1)]);
  if PrnRec <> nil then Options := PrnRec^.PrnOptions
  else Options := PrnOptions;
  if LinesPerPage = 0 then
  begin
    if Options and poFont <> 0 then
    begin
      S := LinesStr;
      LinesPerPage := Byte(S[Interval - 23]);
    end
    else LinesPerPage := 65;
    if LinesPerPage > TopMargin then Dec(LinesPerPage, TopMargin);
    if LinesPerPage > BottomMargin then Dec(LinesPerPage, BottomMargin);
  end;
end;

function GetPrnName(PrnRec: PPrnRec): FNameStr;
var
  Name: FNameStr;
begin
  if (PrnRec <> nil) and (PrnRec^.PrnDeviceName <> nil) then
    Name := PrnRec^.PrnDeviceName^
  else if (PrnRec = nil) and (Trim(PrnDeviceName) <> '') then
    Name := PrnDeviceName
  else Name := 'PRN';
  GetPrnName := CNFileName(Name);
end;

function GetFontName(PrnRec: PPrnRec; Options: Word): FNameStr;
var
  Name: FNameStr;
begin
  if Options and poFont = 0 then Name := ''
  else if (PrnRec <> nil) and (PrnRec^.PrnFontName <> nil) then
    Name := PrnRec^.PrnFontName^
  else if (PrnRec = nil) and (PrnFontName <> '') then
    Name := PrnFontName
  else Name := '';
  GetFontName := CNFileName(Name);
end;

procedure TSpooler.FreeItem(Item: Pointer);
begin
  if Item <> nil then
  begin
    if PSpoolerRec(Item)^.FromDisk then
    begin
      if PSpoolerRec(Item)^.XLAT then
{        FreeMem(PSpoolerRec(Item)^.XLATTable, SizeOf(ConvertTable));}
        FreeMemUMB(PSpoolerRec(Item)^.XLATTable, SizeOf(ConvertTable));
      Close(PSpoolerRec(Item)^.Source^.T);
      InOutRes := 0;
{      FreeMem(PSpoolerRec(Item)^.Source, SizeOf(lText));}
      FreeMemUMB(PSpoolerRec(Item)^.Source, SizeOf(lText));
    end;
{    FreeMem(Item, SizeOf(TSpoolerRec));}
    FreeMemUMB(Item, SizeOf(TSpoolerRec));
  end;
end;

function TSpooler.NewEditor(P: Pointer; Lo, Hi: Integer): PSpoolerRec;
var
  Item: PSpoolerRec;
begin
  NewEditor := nil;
  if (P <> nil) and not LowMemory then
  begin
{    GetMem(Item, SizeOf(TSpoolerRec));}
    GetMemUMB(Item, SizeOf(TSpoolerRec));
    Item^.FromDisk := False;
    Item^.Editor := P;
    Item^.Lo := Lo;
    Item^.Hi := Hi;
    Insert(Item);
    NewEditor := Item;
  end;
end;

function TSpooler.NewSource(const Name: String): PSpoolerRec;
var
  Item: PSpoolerRec;
  S: String;
begin
  NewSource := nil;
  if (Name <> '') and not LowMemory then
  begin
{
    GetMem(Item, SizeOf(TSpoolerRec));
    GetMem(Item^.Source, SizeOf(lText));
}
    GetMemUMB(Item, SizeOf(TSpoolerRec));
    GetMemUMB(Item^.Source, SizeOf(lText));
    Item^.FromDisk := True;
    Item^.Binary := BinaryPrinting;
    Item^.XLAT := False;
    lAssignText(Item^.Source^, Name);
    Reset(Item^.Source^.T);
    if IOResult <> 0 then
    begin
      FreeItem(Item);
      CouldNotOpenMsgBox(Name);
      Exit;
    end;
    if IsDevice(TextRec(Item^.Source^.T).Handle) then
    begin
      Close(Item^.Source^.T);
      InOutRes := 0;
      FreeItem(Item);
      FileIsDeviceMsgBox(Name);
      Exit;
    end;
    Item^.SourceSize := TextFileSize(Item^.Source^.T);
    if (TextReadMode = trAuto) and not Item^.Binary and
      not Eof(Item^.Source^.T) then
    begin
      SetUNIXTextMode;
      Readln(Item^.Source^.T, S);
      SetDOSTextMode;
      Item^.Unix := S[Length(S)] <> #13;
    end
    else Item^.Unix := TextReadMode = trUnix;
    Close(Item^.Source^.T);
    InOutRes := 0;
    Insert(Item);
    NewSource := Item;
  end;
end;

procedure TSpooler.DeleteItem(Item: Integer);
begin
  AtFree(Item);
  if Item = 0 then DonePrinter;
  Message(Application, evBroadcast, cmUpdateViews, nil);
end;

function TSpooler.InQueue(P: Pointer): Boolean;
var
  I: Integer;
  Item: PSpoolerRec;
begin
  for I := 0 to Count - 1 do
  begin
    Item := At(I);
    if not Item^.FromDisk and (Item^.Editor = P) then
    begin
      InQueue := True;
      Exit;
    end;
  end;
  InQueue := False;
end;

procedure TSpooler.Update;
var
  I: Integer;
  Item: PSpoolerRec;
begin
  I := 0;
  while I < Count do
  begin
    Item := At(I);
    if not Item^.FromDisk and (Message(Application, evBroadcast,
      cmIsPrintable, Item^.Editor) <> Item^.Editor) then DeleteItem(I)
    else Inc(I);
  end;
  DoUpdate := False;
end;

function TSpooler.LoadFont(Num: Byte): Boolean;
var
  L: Longint;
  Name: FNameStr;
  F: lFile;
begin
  LoadFont := False;
  if FontNumber = Num then Exit;
  Name := GetFontName(PrnRec, Options);
  if Name <> '' then
  begin
    lAssignFile(F, Name);
    lResetReadOnly(F, 1);
    if IOResult <> 0 then Exit;
    if IsDevice(FileRec(F.F).Handle) then
    begin
      Close(F.F);
      InOutRes := 0;
      Exit;
    end;
    FillChar(FontBuffer^, FontBufSize, 0);
    L := Num * FontBufSize;
    if L < FileSize(F.F) then
    begin
      FontNumber := Num;
      Seek(F.F, L);
      BlockRead(F.F, FontBuffer^, FontBufSize);
      LoadFont := IOResult = 0;
    end;
    Close(F.F);
    InOutRes := 0;
  end;
end;

function TSpooler.InitPrinter(P: PSpoolerRec): Boolean;
var
  B: Byte;
  Code: Integer;
  RV: Real;
  F: File;
  Name: FNameStr;
  S: String;
label
  Quit;
begin
  InitPrinter := False;
  InitFlag := True;
  if P^.FromDisk then PrnRec := nil
  else PrnRec := Message(P^.Editor, evBroadcast, cmPrinterSetup, nil);
  if PrnRec <> nil then Options := PrnRec^.PrnOptions
  else Options := PrnOptions;
  Name := GetPrnName(PrnRec);
  if P^.FromDisk and
    (CompUCString(StrPas(P^.Source^.FullName), Name) = Equal) then
  begin
    CannotWriteToItselfMsgBox;
    Goto Quit;
  end;
  lAssignText(Printer, Name);
  Rewrite(Printer.T);
  if IOResult <> 0 then
  begin
    CouldNotOpenMsgBox(Name);
    Goto Quit;
  end;
  PortNumber := $FF;
  Name := DeviceDest(Name);
  if Name <> '' then
  begin
    if Name[1] = 'P' then PortNumber := 0
    else if (Name[1] = 'L') and (Name[Length(Name)] in ['1'..'3']) then
      PortNumber := Byte(Name[Length(Name)]) - $31;
    DeviceBinaryMode(TextRec(Printer.T).Handle);
  end;
  GetPrnValues(PrnRec, LeftMargin, TopMargin, BottomMargin, LinesPerPage,
    B, CharsPerCycle);
  if (PrnRec <> nil) and (PrnRec^.PrnInitString <> nil) then
    S := PrnRec^.PrnInitString^
  else if (PrnRec = nil) and (PrnInitString <> '') then
    S := PrnInitString
  else S := '';
  Name := GetFontName(PrnRec, Options);
  if (Name <> '') and not (P^.FromDisk and P^.Binary) then
  begin
    FontBufSize := $2400;
    FontBuffer := MemAlloc(FontBufSize);
    if FontBuffer = nil then
    begin
      DonePrinter;
      Application^.OutOfMemory;
      Goto Quit;
    end;
    if Options and poBold <> 0 then PrintBufSize := $4B00
    else PrintBufSize := $2580;
    PrintBuffer := MemAlloc(PrintBufSize);
    if PrintBuffer = nil then
    begin
      DonePrinter;
      Application^.OutOfMemory;
      Goto Quit;
    end;
    LogEvent := lcDiskRead;
    DrawStatusLine('Loading Graphics Font from ' +
      TrimmedName(Name, 40) + '.');
    FontNumber := $FF;
    if not LoadFont(0) then
    begin
      DonePrinter;
      CouldNotOpenMsgBox(Name);
      Goto Quit;
    end;
    S := S + #$0D'@J'#1'3' + Char(B);
  end;
  SetInitString(S);
  if P^.FromDisk then Reset(P^.Source^.T);
  Index := 0;
  TopIndex := 0;
  PageIndex := 1;
  LinePos := 0;
  PrintBufLen := 0;
  Current := P;
  InitPrinter := True;
Quit:
  InitFlag := False;
end;

procedure TSpooler.DonePrinter;
begin
  Close(Printer.T);
  InOutRes := 0;
  SetInitString('');
  SetLineString('');
  if PrintBuffer <> nil then
  begin
    FreeMem(PrintBuffer, PrintBufSize);
    PrintBuffer := nil;
  end;
  if FontBuffer <> nil then
  begin
    FreeMem(FontBuffer, FontBufSize);
    FontBuffer := nil;
  end;
  Index := 0;
  TopIndex := 0;
  PageIndex := 1;
  LinePos := 0;
  PrintBufLen := 0;
  Current := nil;
end;

procedure TSpooler.SetInitString(const S: String);
begin
{
  DisposeStr(InitString);
  InitString := NewStr(S);
}
  DisposeStrUMB(InitString);
  InitString := NewStrUMB(S);
end;

procedure TSpooler.SetLineString(const S: String);
begin
{
  DisposeStr(LineString);
  LineString := NewStr(S);
}
  DisposeStrUMB(LineString);
  LineString := NewStrUMB(S);
end;

function GetNextSourceLine(P: PSpoolerRec): PString;
var
  B: Byte;
  S: String;
begin
  GetNextSourceLine := nil;
  if P^.Binary then
  begin
    B := DOSBlockRead(TextRec(P^.Source^.T).Handle, S[1], 255);
    if B <> 0 then
    begin
      S[0] := Char(B);
      GetNextSourceLine := @S;
    end;
  end
  else
  begin
    if Eof(P^.Source^.T) then Exit;
    if P^.Unix then SetUNIXTextMode;
    Readln(P^.Source^.T, S);
    SetDOSTextMode;
    if P^.XLAT then for B := 1 to Length(S) do
      S[B] := P^.XLATTable^[S[B]];
    if IOResult = 0 then GetNextSourceLine := @S;
  end;
end;

procedure TSpooler.ProcessItems;
var
  P: PSpoolerRec;
  PS: PString;
  S: String;
begin
  if DoUpdate then Update;
  if (Count = 0) or InitFlag then Exit;
  if InitString <> nil then
  begin
    if PrnStatus(PortNumber) = prnOk then
    begin
      Write(Printer.T, InitString^);
      SetInitString('');
    end;
    Exit;
  end;
  if LinePos = 0 then
  begin
    if PageIndex > LinesPerPage then
    begin
      if PrnStatus(PortNumber) = prnOk then
      begin
	if not (Current^.FromDisk and Current^.Binary) then
	  Write(Printer.T, ^L);
        PageIndex := 1;
      end;
      Exit;
    end;
    P := At(0);
    if Current <> P then
    begin
      if not InitPrinter(P) then DeleteItem(0);
      Exit;
    end;
    if P^.FromDisk or (Message(Application, evBroadcast,
      cmIsPrintable, P^.Editor) = P^.Editor) then
    begin
      if P^.FromDisk then PS := GetNextSourceLine(P)
      else if P^.Lo >= 0 then
      begin
        if Index < P^.Lo then Index := P^.Lo;
        if Index > P^.Hi then PS := P^.Editor
        else PS := Message(P^.Editor, evBroadcast,
          cmGetSelPrintLine, Pointer(Index));
      end
      else PS := Message(P^.Editor, evBroadcast,
        cmGetPrintLine, Pointer(Index));
      if (P^.FromDisk and (PS = nil)) or
         (not P^.FromDisk and (PS = P^.Editor)) then DeleteItem(0)
      else
      begin
        if PS = nil then S := ''
        else
        begin
          S := PS^;
	  if not (P^.FromDisk and P^.Binary) then
          begin
            if S[Length(S)] = ^L then
            begin
              Dec(S[0]);
              PageIndex := LinesPerPage + 1;
            end;
            if LeftMargin <> 0 then S := Pad('', LeftMargin) + S;
          end;
        end;
        SetLineString(S);
        Inc(Index);
        if Options and poPage <> 0 then
        begin
          if (PageIndex = 1) and (TopMargin <> 0) then
            TopIndex := TopMargin;
          Inc(PageIndex);
        end;
        LinePos := 1;
      end;
    end
    else DeleteItem(0);
  end;
  if (LinePos <> 0) and (PrnStatus(PortNumber) = prnOk) then PrintLine;
end;

procedure TSpooler.PrintLine;

function LShl(L : Longint; B : Word) : Byte;
 inline(
  $59/              {      POP CX       }
  $58/              {      POP AX       }
  $5A/              {      POP DX       }
  $E3/$06/          {      JCXZ @@3     }
  $D1/$E0/          { @@2: SHL AX,1     }
  $D1/$D2/          {      RCL DX,1     }
  $E2/$FA/          {      LOOP @@2     }
  $88/$D0);         { @@3: MOV AL,DL    }

{
function LShl(L : Longint; b : Byte) : Byte;
type
 TLong = record
  B0, B1, B2, B3 : Byte;
 end;
begin
 L := L shl b;
 LShl := TLong(L).B2;
end;
}

function IsZero(Buf : PByteArray; Len : Word) : Boolean;
var
 i : Word;
 B : Boolean;
begin
 for i := 0 to Len - 1 do
  begin
   B := Buf^[i] = 0;
   if not B then Break;
  end;
 IsZero := B;
end;

procedure StrToBuf(const AString: String);
var
  S: String;
begin
  S := AString;
  Move(S[1], PrintBuffer^[PrintBufLen], Length(S));
  Inc(PrintBufLen, Length(S));
end;

procedure ByteToBuf(AByte: Byte);
begin
  PrintBuffer^[PrintBufLen] := AByte;
  Inc(PrintBufLen);
end;

procedure FillPrintBuffer(Font: PFontArray; PS: PString; Mode: Byte);
var
 B, Strike, Pass, FontNum, CurNum : Byte;
 Sym, Col, m, i : Word;
 Len : Integer;
 L : Longint;
 PBuf : PByteArray;
 SS : String[10];
 S : String;
begin
 PrintBufLen := 1;
 FontNum := FontNumber;
 StrToBuf('8');
 if PS = nil then S := '' else S := PS^;
 if S[0] > #132 then S[0] := #132;
 if S = '' then StrToBuf('J'#11)
 else
 begin
   Len := Length(S) * 12;
{   GetMem(PBuf, Len);}
   GetMemUMB(PBuf, Len);
   for Pass := 0 to 5 do
    begin
     m := 0;
     Fillchar(PBuf^, Len, 0);
     LoadFont(FontNum);
     Sym := 1;
     while Sym <= Length(S) do
      begin
        if (S[Sym] = #27) and (Length(S) > Sym) and
           (S[Sym+1] in ['0' .. '9']) then
        begin
         CurNum := Byte(S[Sym+1]) - $30;
         LoadFont(CurNum);
         Inc(Sym, 2);
        end;
       if Sym <= Length(S) then for Col := 1 to 12 do
        begin
         L := 0;
         move(Font^[Byte(S[Sym]), Col, 0], L, 3);
         case Pass of
          0: B := LShl(L, 0) and $c0;
          1: B := LShl(L, 2) and $c0;
          2: B := LShl(L, 4);
          3: B := LShl(L, 12);
          4: B := LShl(L, 14) and $03;
          5: B := LShl(L, 16) and $03;
         end {case};
         PBuf^[m] := B;
         Inc(m);
        end;
       Inc(Sym);
      end;
     for Strike := 1 to Mode do
      begin
       if not IsZero(PBuf, Len) then
        begin
         StrToBuf('L');
         ByteToBuf(Lo(Len));
         ByteToBuf(Hi(Len));
         for i := 0 to Len - 1 do ByteToBuf(PBuf^[i]);
        end;
        ByteToBuf($0d);
      end;
     case Pass of
      0,2,4: SS := 'J'#1;
      1,3 : SS := 'J'#4;
     end {case};
     StrToBuf(SS);
    end;
{    FreeMem(PBuf, len);}
    FreeMemUMB(PBuf, len);
  end;
  FontNumber := CurNum;
  StrToBuf('9'#$0a#$0d);
  Dec(PrintBufLen);
end;

var
  Top: Boolean;
  CharCount: Word;
  PS: PString;
begin
  Top := TopIndex <> 0;
  if (FontBuffer = nil) or (Current^.FromDisk and Current^.Binary) then
  begin
    if Top or (LineString = nil) or (LinePos > Length(LineString^)) then
    begin
      if not (Current^.FromDisk and Current^.Binary) then
	Writeln(Printer.T);
      if Top then Dec(TopIndex);
      LinePos := Byte(Top);
    end
    else for CharCount := 1 to CharsPerCycle do
    begin
      if (LinePos > Length(LineString^)) or
         (PrnStatus(PortNumber) <> prnOk) then Exit;
      Write(Printer.T, LineString^[LinePos]);
      Inc(LinePos);
    end;
  end
  else
  begin
    if PrintBufLen = 0 then
    begin
      if Top then PS := nil else PS := LineString;
      FillPrintBuffer(PFontArray(FontBuffer), PS,
        1 + Byte(Options and poBold <> 0));
    end
    else if LinePos > PrintBufLen then
    begin
      if Top then Dec(TopIndex);
      LinePos := Byte(Top);
      PrintBufLen := 0;
    end
    else for CharCount := 1 to CharsPerCycle do
    begin
      if (LinePos > PrintBufLen) or
         (PrnStatus(PortNumber) <> prnOk) then Exit;
      Write(Printer.T, Char(PrintBuffer^[LinePos]));
      Inc(LinePos);
    end;
  end;
end;

procedure TSpooler.Abort;
var
  W: Word;
begin
  while Count <> 0 do DeleteItem(Count - 1);
  W := PortNumber;
  if W < 3 then
asm
        MOV     AH,1
        MOV     DX,W
        INT     17H
end;
end;

end.
