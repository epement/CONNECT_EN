{$I-,F+,O+,X+}
unit CompPrim;

interface

uses Objects, Compiler, StrCol, Procs;

type
  TSeg = (CS_,DS_,SS_,ES_);

  TOpAddr = record
   OpSeg : TSeg;
   A1 : Byte;
   OpAddr : Word;
  end;

  PLabelValue = ^TLabelValue;
  TLabelValue = record
   PLabel : Pstring;
   Value : Word;
  end;

  PFixLabelColl = ^TFixLabelColl;
  TFixLabelColl = object(TCollection)
   procedure Error(Code, Info: Integer); virtual;
   procedure FreeItem(Item: Pointer); virtual;
  end;

  PLabValColl = ^TLabValColl;
  TLabValColl = object(TSortedCollection)
   procedure Error(Code, Info: Integer); virtual;
   function Compare(Key1, Key2: Pointer): Integer; virtual;
   procedure FreeItem(Item: Pointer); virtual;
  end;

  TStartCode = record
   Signature : array [0..3] of char;
   LibFnAddr : Longint;
   DataSize : Word;
   ErrArg : Longint;
   ErrAddr : Array [0..12] of byte;
   StartAddr : Array[0..3] of byte;
  end;

  TFn = record
   FnName : String[7];
   FnArgs : Byte;
   FnAddr : Pointer;
  end;

  PIdColl = ^TIdColl;
  TIdColl = object(TStringsCollection)
   procedure Error(Code, Info: Integer); virtual;
   function Search(Key: Pointer; var Index: Integer): Boolean; virtual;
  end;

  TLineInfo = record
   Addr : Word;
   LineNum : Integer;
  end;

  PLineColl = ^TLineColl;
  TLineColl = object(TSortedCollection)
   procedure Error(Code, Info: Integer); virtual;
   function Compare(Key1, Key2: Pointer): Integer; virtual;
   procedure FreeItem(Item: Pointer); virtual;
  end;

const
 IdChars : Set of char = ['!','#','_','0'..'9','$','A'..'Z','a'..'z'];
 TerminalChars : Set of char = [#$0..#$2F,#$3A..#$3F,'[','\',']','`',#$7B..#$ff];
 Tabs = #$20#$20#$20#$20#$20#$20#$20#$20#$20#$20#$20#$20#$20#$20#$20#$20;
 CStartCode : TStartCode =
  (Signature : 'CBPR';
   LibFnAddr : 0;
   DataSize : 0;
   ErrArg : 8;
   ErrAddr :($0E,$B8,$0A,$00,$50,$B8,$00,$00,$2E,$FF,$1E,$04,$00);
   StartAddr :($B8,$0E,$00,$50));
   {            db 'CBPR'
     LibFnAddr  dd ?
     DataSize   dw ?
     ErrArg     dd 8   ; RET without GOSUB
     ErrAddr:   push   cs
                mov    ax,offset ErrArg
                push   ax
                mov    ax,0 ;Stop
                call dword ptr cs:LibFnAddr
     StartAddr: mov ax,offset ErrAddr
		push ax}

 OpCount = 14;
 Operators : Array [0 .. OpCount] of String[5] =
  ('/','*','-','+',' AND ',' XOR ',' OR ',
  '<=','>=','<>','==','<','>','=','|');
 OpsAddr : array[0..OpCount] of Pointer =
  (@DivL,@MulL,@SubL,@AddL,@ANDL,@XORL,@ORL,
  @LE,@GE,@NE,@EQ,@LS,@GR,@Let,@Empty);
 FnCount = 70;
 Functions : Array[0..FnCount] of TFn =
 ((FnName: 'STOP(';   FnArgs : 1; FnAddr : @Stop),
  (FnName: '@(';      FnArgs : 0; FnAddr : @GetData),
  (FnName: '&(';      FnArgs : 0; FnAddr : @GetCommon),
  (FnName: 'INITRS('; FnArgs : 1; FnAddr : @Init_RS),
  (FnName: 'MENU(';   FnArgs : 2; FnAddr : @Menu),
  (FnName: 'SEND(';   FnArgs : 3; FnAddr : @Send),
  (FnName: 'CHKRS(';  FnArgs : 1; FnAddr : @CheckRS),
  (FnName: 'RECEIV('; FnArgs : 4; FnAddr : @Receive),
  (FnName: 'SNDBLK('; FnArgs : 4; FnAddr : @SendBlock),
  (FnName: 'RECBLK('; FnArgs : 5; FnAddr : @ReceiveBlock),
  (FnName: 'GETBUF('; FnArgs : 2; FnAddr : @GetBuff),
  (FnName: 'RDBUF(';  FnArgs : 3; FnAddr : @ReadBuff),
  (FnName: 'WRBUF(';  FnArgs : 4; FnAddr : @WriteBuff),
  (FnName: 'KEYPRS('; FnArgs : 1; FnAddr : @KeyPrs),
  (FnName: 'OPEN(';   FnArgs : 3; FnAddr : @FOpen),
  (FnName: 'CLOSE(';  FnArgs : 1; FnAddr : @FClose),
  (FnName: 'RDBLK(';  FnArgs : 3; FnAddr : @RdBlk),
  (FnName: 'WRBLK(';  FnArgs : 3; FnAddr : @WrBlk),
  (FnName: 'PRINTS('; FnArgs : 3; FnAddr : @PrintS),
  (FnName: 'INPUTS('; FnArgs : 1; FnAddr : @InputS),
  (FnName: 'PRINTV('; FnArgs : 4; FnAddr : @PrintV),
  (FnName: 'INPUTV('; FnArgs : 1; FnAddr : @InputV),
  (FnName: 'RTS(';    FnArgs : 2; FnAddr : @RTS),
  (FnName: 'CTS(';    FnArgs : 1; FnAddr : @CTS),
  (FnName: 'DTR(';    FnArgs : 2; FnAddr : @DTR),
  (FnName: 'DSR(';    FnArgs : 1; FnAddr : @DSR),
  (FnName: 'INDBAR('; FnArgs : 3; FnAddr : @IndBar),
  (FnName: 'NOT(';    FnArgs : 1; FnAddr : @NotL),
  (FnName: 'DISBUF('; FnArgs : 1; FnAddr : @DispBuff),
  (FnName: 'USER(';   FnArgs : 3; FnAddr : @User),
  (FnName: 'LODUSR('; FnArgs : 2; FnAddr : @LoadUser),
  (FnName: 'CRC32(' ; FnArgs : 2; FnAddr : @GetCRC32),
  (FnName: 'BEEP(';   FnArgs : 2; FnAddr : @Beep),
  (FnName: 'IDLE(';   FnArgs : 1; FnAddr : @Idle),
  (FnName: 'NEWWIN('; FnArgs : 1; FnAddr : @NewWin),
  (FnName: 'PUTSTR('; FnArgs : 1; FnAddr : @PutStr),
  (FnName: 'PUTKEY('; FnArgs : 1; FnAddr : @PutKey),
  (FnName: 'LODBLK('; FnArgs : 1; FnAddr : @LoadBlock),
  (FnName: 'STOBLK('; FnArgs : 1; FnAddr : @StoreBlock),
  (FnName: 'GOTOXY('; FnArgs : 2; FnAddr : @GotoXY),
  (FnName: 'WHEREX('; FnArgs : 0; FnAddr : @WhereCurX),
  (FnName: 'WHEREY('; FnArgs : 0; FnAddr : @WhereCurY),
  (FnName: 'MAXY(';   FnArgs : 0; FnAddr : @MaxY),
  (FnName: 'FIND(';   FnArgs : 2; FnAddr : @Find),
  (FnName: 'REPLAC('; FnArgs : 3; FnAddr : @Replace),
  (FnName: 'GETSTR('; FnArgs : 0; FnAddr : @GetStr),
  (FnName: 'GETWRD('; FnArgs : 0; FnAddr : @GetWrd),
  (FnName: 'GETCHR('; FnArgs : 0; FnAddr : @GetChr),
  (FnName: 'SETINS('; FnArgs : 1; FnAddr : @SetIns),
  (FnName: 'CMPSTR('; FnArgs : 3; FnAddr : @StrCompare),
  (FnName: 'CONCAT('; FnArgs : 2; FnAddr : @StrConcat),
  (FnName: 'POS(';    FnArgs : 5; FnAddr : @StrPos),
  (FnName: 'COPY(';   FnArgs : 3; FnAddr : @StrCopy),
  (FnName: 'DELETE('; FnArgs : 3; FnAddr : @StrDelete),
  (FnName: 'INSERT('; FnArgs : 3; FnAddr : @StrInsert),
  (FnName: 'UPCASE('; FnArgs : 1; FnAddr : @StrUpcase),
  (FnName: 'LOCASE('; FnArgs : 1; FnAddr : @StrLocase),
  (FnName: 'FMTSTR('; FnArgs : 2; FnAddr : @FrmtStr),
  (FnName: 'UPLOAD('; FnArgs : 3; FnAddr : @Upload),
  (FnName: 'DNLOAD('; FnArgs : 3; FnAddr : @Download),
  (FnName: 'SEEK(';   FnArgs : 2; FnAddr : @FSeek),
  (FnName: 'DCD(';    FnArgs : 1; FnAddr : @DCD),
  (FnName: 'SNDSTR('; FnArgs : 2; FnAddr : @SendString),
  (FnName: 'WAIT(';   FnArgs : 4; FnAddr : @WaitForString),
  (FnName: 'DIAL(';   FnArgs : 1; FnAddr : @Dial),
  (FnName: 'RING(';   FnArgs : 1; FnAddr : @Ring),
  (FnName: 'WRSTAT('; FnArgs : 2; FnAddr : @WriteStatus),
  (FnName: 'MARK(';   FnArgs : 0; FnAddr : @MarkFunc),
  (FnName: 'RELEAS('; FnArgs : 1; FnAddr : @ReleaseFunc),
  (FnName: 'DONERS('; FnArgs : 1; FnAddr : @Done_RS),
  (FnName: 'PARAMS('; FnArgs : 0; FnAddr : @GetProgParams)
 );

  LabValColl: PLabValColl = nil;
  FixLabelColl: PFixLabelColl = nil;
  IdColl: PIdColl = nil;
  LineColl: PLineColl = nil;

function PosWord(Const SubStr,Str: String) : Byte;
procedure CompileString(Str : String);
procedure FixUp;
function DebugMsgBox: Word;
function RunMsgBox: Word;

implementation

uses Drivers, Memory, MsgBox, DirPrim, RevPos, GetId, LFN,
  TPString, Defaults;

procedure Warning(Code : Byte; Num: Integer);
var
 WarnStr : String[30];
begin
 case Code of
  1 : WarnStr := 'Argument expected.';
  2 : WarnStr := 'Too many arguments.';
 else;
 end;
 if LstFlag then WriteLn(LstFile,'WARNING: ',WarnStr);
end;

procedure TIdColl.Error(Code, Info: Integer);
begin
 Compiler.Error(4,-1);
end;

function TIdColl.Search(Key: Pointer; var Index: Integer): Boolean;
var
 Cmp : Boolean;
begin
 Index := 0;
 Cmp := False;
 if Count > 0 then
   repeat
    Cmp := (PString(Key)^ = PString(At(Index))^);
    inc(Index);
   until (Index = Count) or Cmp;
 if Cmp then Dec(Index);
 Search := Cmp;
end;

procedure TLabValColl.Error(Code, Info: Integer);
begin
 Compiler.Error(4,-1);
end;

function TLabValColl.Compare(Key1, Key2: Pointer): Integer;
begin
  if PLabelValue(Key1)^.PLabel^ =
    PLabelValue(Key2)^.PLabel^ then Compare := 0
  else if PLabelValue(Key1)^.PLabel^ >
    PLabelValue(Key2)^.PLabel^ then Compare := 1
  else Compare := -1;
end;

procedure TLabValColl.FreeItem(Item : Pointer);
begin
 if Item <> Nil then
 begin
   if PLabelValue(Item)^.PLabel <> Nil then
    DisposeStr(PLabelValue(Item)^.PLabel);
   FreeMem(Item,SizeOf(TLabelValue));
 end;
end;

procedure TFixLabelColl.Error(Code, Info: Integer);
begin
  Compiler.Error(4,-1);
end;

procedure TFixLabelColl.FreeItem(Item : Pointer);
begin
 if Item <> Nil then
  begin
   if PLabelValue(Item)^.PLabel <> Nil then
    DisposeStr(PLabelValue(Item)^.PLabel);
   FreeMem(Item,SizeOf(TLabelValue));
  end;
end;

procedure TLineColl.Error(Code, Info: Integer);
begin
  Compiler.Error(4,-1);
end;

function TLineColl.Compare(Key1, Key2: Pointer): Integer;
begin
  if TLineInfo(Key1).Addr = TLineInfo(Key2).Addr then Compare := 0
  else if TLineInfo(Key1).Addr > TLineInfo(Key2).Addr then Compare := 1
  else Compare := -1;
end;

procedure TLineColl.FreeItem(Item : Pointer);
begin
end;

Procedure CodeGen(Const Code : String);
begin
 Move(Code[1],PProgr^[InstrPtr],Byte(Code[0]));
 Inc(InstrPtr,Byte(Code[0]));
 if InstrPtr > $ffe0 then Compiler.Error(2,LineNumber)
 else if InstrPtr > ProgrSize - 10 then Compiler.Error(1,LineNumber);
end;

function Word2Str(W : Word) : String;
var
 Str : String[2];
begin
 Str[0] := #2;
 Str[1] := Char(Lo(W));
 Str[2] := Char(Hi(W));
 Word2Str := Str;
end;

function Byte2Str(B : Byte) : String;
var
 Str : String[1];
begin
 Str[0] := #1;
 Str[1] := Char(B);
 Byte2Str := Str;
end;

procedure PushVar(Addr : Longint);
begin
 with TOpAddr(Addr) do
  begin
   case OpSeg of
    DS_: begin
          CodeGen(#$1E                 {     push ds}
                 +#$B8);               {     mov ax,OpAddr}
          CodeGen(Word2Str(OpAddr));
          CodeGen(#$50);               {     push ax}
          if LstFlag then
           WriteLn(LstFile,Tabs,'push ds: ',HexW(OpAddr),'H');
         end;
    CS_: begin
          CodeGen(#$0E                 {     push cs}
                 +#$B8);               {     mov ax,OpAddr}
          CodeGen(Word2Str(OpAddr));
          CodeGen(#$50);               {     push ax}
          if LstFlag then
           WriteLn(LstFile,Tabs,'push cs: ',HexW(OpAddr),'H');
         end;
    SS_: begin
          CodeGen(#$16);               {     push ss}
          if OpAddr < $100 then
           begin
            CodeGen(#$8D#$46);         {     lea ax,[bp - OpAddr]}
            CodeGen(Byte2Str(-OpAddr));
           end
          else
           begin
            CodeGen(#$8D#$86);         {     lea ax,[bp - OpAddr]}
            CodeGen(Word2Str(-OpAddr));
           end;
          CodeGen(#$50);               {     push ax}
          if LstFlag then
           WriteLn(LstFile,Tabs,'push ss: ',HexW(OpAddr),'H');
         end;
   else Compiler.Error($ff,LineNumber);
   end;
  end;
end;

procedure CallOp(OpCode : Byte);
begin
 CodeGen(#$B0);
 CodeGen(Byte2Str(OpCode+$80));        {     mov al,OpCode}
 CodeGen(#$2E#$FF#$1E#$04#$00          {     call dword ptr cs:LibFnAddr}
        +#$83#$C4#$08                  {     add sp,8}
        +#$52                          {     push dx}
        +#$50);                        {     push ax}
 Inc(TempIndex);
 if LstFlag then WriteLn(LstFile,Tabs,'call ',Operators[OpCode]);
end;

procedure CallFn(FnIndex,Args : Byte);
begin
 CodeGen(#$B0);
 CodeGen(Byte2Str(FnIndex));           {     mov al,FnIndex}
 CodeGen(#$2E#$FF#$1E#$04#$00);        {     call dword ptr cs:LibFnAddr}
 if Args > 0 then
  begin
   CodeGen(#$83#$C4);                  {     add sp,Args * 4}
   CodeGen(Byte2Str(Args shl 2));
  end;
 CodeGen(#$52                          {     push dx}
        +#$50);                        {     push ax}
 Inc(TempIndex);
 if LstFlag then
  WriteLn(LstFile,Tabs,'call ',Functions[FnIndex].FnName,')');
end;

function GetConstAddr(Result : Longint) : Longint;
var
 Res : Longint;
begin
 if Result = 0 then
  begin
   CodeGen(#$33#$C0                    {     xor ax,ax}
          +#$50                        {     push ax}
          +#$50);                      {     push ax}
  end
 else if Result < $10000 then
       begin
        CodeGen(#$33#$C0                {     xor ax,ax}
               +#$50                    {     push ax}
               +#$B8);                  {     mov ax,',Result.Lo}
        CodeGen(Word2Str(LongRec(Result).Lo));
        CodeGen(#$50);                  {     push ax}
       end
      else
       begin
        CodeGen(#$B8);                 {     mov ax,',Result.Hi}
        CodeGen(Word2Str(LongRec(Result).Hi));
        CodeGen(#$50                   {     push ax}
               +#$B8);                 {     mov ax,',Result.Lo}
        CodeGen(Word2Str(LongRec(Result).Lo));
        CodeGen(#$50);                 {     push ax}
       end;
 Inc(TempIndex);
 if LstFlag then
  WriteLn(LstFile,Tabs,'push ',HexW(LongRec(Result).Hi),
                              HexW(LongRec(Result).Lo),'H');
 with TOpAddr(Res) do
  begin
   OpSeg := SS_;
   OpAddr := TempIndex shl 2;
  end;
 GetConstAddr := Res;
end;


function CompileLiterals(Const SubStr: String) : String;
begin
 CodeGen(#$EB);
 CodeGen(Char(Length(SubStr)+5));      {     jmp short @1}
 CodeGen(Char(Length(SubStr)));
 CodeGen(SubStr);                      {Str  db SubStr}
 CodeGen(Word2Str(InstrPtr -
              Length(SubStr) - 1));    {OStr db offset Str}
 CodeGen(Word2Str(0));                 {SStr db 0 }
 CodeGen(#$2E#$8C#$0E);                {@1:  mov cs: word ptr SStr,cs}
 CodeGen(Word2Str(InstrPtr-5));
 CompileLiterals := '##$' + HexW(InstrPtr-9);
 if LstFlag then WriteLn(LstFile,Tabs,'db ',SubStr);
end;

function CompileLink(Const SubStr: String) :    String;
var
 Align  : Byte;
 Fix : Word;
 Size : Word;
 Buff : Pointer;
 F : lFile;
begin
 Align  := 16 - (InstrPtr +3) mod 16;
 if Align = 16  then Align := 0;
 lAssignFile(F,SubStr);
 lResetReadOnly(F,1);
 if IOResult <> 0 then Compiler.Error(21,LineNumber);
 Size := FileSize(F.F);
 if InstrPtr +  Size > $FFF0 then Compiler.Error(2,LineNumber);
 CodeGen(#$E9);                 {     jmp $+Size}
 CodeGen(Word2Str(Size  + 4 + Align));
 BlockRead(F.F,PProgr^[InstrPtr + Align], Size);
 if IOResult <> 0 then  Compiler.Error(21,LineNumber);
 Close(F.F);
 Fix := (InstrPtr + Align) div 16;
 inc(InstrPtr,  Size + Align);
 CodeGen(Word2Str(0));                  {OBuf db 0}
 CodeGen(Word2Str(0));                  {SBuf db 0}
 CodeGen(#$8C#$C8                       {@1:  mov ax,cs}
	+#$05);                 {     add ax,Fix}
 CodeGen(Word2Str(Fix));
 CodeGen(#$2E#$A3);                     {@1:  mov cs: word ptr SBuf,ax}
 CodeGen(Word2Str(InstrPtr - 9));
 CompileLink := '##$' + HexW(InstrPtr - 13);
end;

function GetOperandAddr(Const Str : String): Longint;
 var
  Ps : Byte;
  Index, Code : Integer;
  PStr : PString;
  Result : TOpAddr;
begin
 if Pos('!!',Str) <> 0 then
   With Result do
    begin
     Val(Copy(Str,3,5),OpAddr,Code);
     if Code <> 0 then Compiler.Error($ff,LineNumber);
     OpSeg := SS_;
    end
 else if Pos('##',Str) <> 0 then
       With Result do
	begin
	 Val(Copy(Str,3,5),OpAddr,Code);
	 if Code <> 0 then Compiler.Error($ff,LineNumber);
	 OpSeg := CS_;
	end
      else
       begin
	PStr := NewStr(Str);
	if PStr <> Nil then
	 begin
	  if IdColl^.Search(PStr,Index) then DisposeStr(PStr)
	  else IdColl^.Insert(PStr);
	 end
	else Compiler.Error(1,-1);
	With Result    do
	 begin
	  OpAddr := Index shl 2;
	  OpSeg := DS_;
	 end
       end;
 GetOperandAddr := Longint(Result);
end;

function TempVar(TempIndex : Byte) : String;
begin
 TempVar := ' !!$' + HexW(Word(TempIndex) shl 2)+' ';
end;

procedure LVal(Const Str : String; var Result : Longint; var Code : Integer);
var
FResult : Real;
begin
 {}
 if Pos('##', Str) = 0 then
  begin
   if Str[1] = '#' then
    begin
     Result := Byte(Str[2]);
     Code := 0;
     Exit;
    end;
  end;
 {}
 Val(Str,Result,Code);
 if Code <> 0 then
  begin
   if Str[1] = '$' then Val(Copy(Str, 2, 255), FResult, Code)
   else Val(Str, FResult, Code);
   if Code = 0 then Compiler.Error(23,LineNumber);
  end;
end;

procedure CompileStr(var Str : String);
var
 OpIndex,Ps,Lps,Rps : Byte;
 Code : Integer;
 Result, LAddr,RAddr : Longint;
 LSubStr,RSubStr : String[20];
begin
 for OpIndex := 0 to OpCount do
  repeat
   if OpIndex = 13 then Ps := RPos(Operators[OpIndex],Str)
   else Ps := Pos(Operators[OpIndex],Str);
   if Ps <> 0 then
    begin
     RPs := Ps + Length(Operators[OpIndex]) - 1;
     RSubStr := GetRightId(Str,IdChars,RPs);
     if RSubStr = '' then Compiler.Error(5,LineNumber);
     if Pos(RSubStr,Str) = 0 then Compiler.Error(11,LineNumber);
     LVal(RSubStr, Result, Code);
     if Code <> 0 then RAddr := GetOperandAddr(RSubStr)
     else RAddr := GetConstAddr(Result);
     Lps := Ps;
     LSubStr := GetLeftId(Str,IdChars,LPs);
     if LSubStr = '' then LSubStr := '0'
     else if Pos(RSubStr,Str) = 0 then  Compiler.Error(11,LineNumber);
     LVal(LSubStr, Result, Code);
     if Code <> 0 then LAddr := GetOperandAddr(LSubStr)
     else LAddr := GetConstAddr(Result);
     PushVar(RAddr);
     PushVar(LAddr);
     CallOp(OpIndex);
     Delete(Str,LPs,RPs-LPs + 1);
     Insert(TempVar(TempIndex),Str,LPs);
    end;
  until Ps = 0;
end;

Procedure BrackMax(Var Str : String);
 var
  Index,OBr,Cbr : Byte;
  SubStr : String;
  begin
   OBr:=0; CBr:=0; Index:=1;
   while (CBr = 0) and (Index <= Length(Str)) do
    begin
     if Str[Index] = '(' then OBr := Index;
     if Str[Index] = ')' then CBr := Index+1;
     Inc(Index);
    end;
    if (CBr <> 0) and (OBr <> 0) and (CBr > OBr) then
       begin
         SubStr := Copy(Str,OBr,CBr-OBr);
         Delete(SubStr,1,1);
         Dec(SubStr[0]);
         CompileStr(SubStr);
         Delete(Str,OBr,CBr-OBr);
         Insert(SubStr,Str,Obr);
         BrackMax(Str);
       end
    else if (CBr = 0) and (OBr = 0) then CompileStr(Str)
         else if CBr < OBr then Compiler.Error(6,LineNumber)
              else if CBr <> 0 then Compiler.Error(7,LineNumber)
                   else Compiler.Error(8,LineNumber);
  end;
{
function findCBr(Var Str : String; OBr : Byte) : Byte;
var
 Ps, Opend, Closed : Byte;
begin
 Ps := Obr;
 Opend := 0; Closed := 0;
  repeat
   if Str[Ps] = '(' then Inc(Opend);
   if Str[Ps] = ')' then Inc(Closed);
   Inc(Ps);
  until (Ps > Length(Str)) or (Opend = Closed);
 if Opend <> Closed then Compiler.Error(6,LineNumber);
 findCBr := Ps-1;
end;
}

Procedure CompileFn(Var Str : String);
type
 TArgsArray = Array[0..$ff] of TOpAddr;
var
 FnIndex, FnMIndex, FnPos, Ps,
 FnMPos, OBr, CBr, Args, N: Byte;
 Code : Integer;
 Result : Longint;
 PArgsArray : ^TArgsArray;
 SubStr,RSubStr : String[128];
begin
 repeat
  {Найдем первую с конца функцию}
  FnMpos := 0;
  for FnIndex := 0 to FnCount do
   begin
    FnPos := RPos(Functions[FnIndex].FnName,Str);
    if FnPos > FnMPos then
     begin
      FnMPos := FnPos;
      FnMIndex := FnIndex;
     end;
   end;
  if FnMPos <> 0 then
   begin
    OBr := FIPos('(',Str,FnMPos);
    if OBr = 0 then Compiler.Error(7,LineNumber); { "(" expected}
    CBr := findCBr(Str,OBr);
    if Cbr = 0 then Compiler.Error(8,LineNumber); { ")" expected}
    SubStr := Copy(Str,Obr + 1,Cbr - Obr-1);
    if DelChar(' ',SubStr) = '' then Args := 0
    else Args := Count(',',SubStr) + 1;
    if Args > Functions[FnMIndex].FnArgs then Warning(2,0);{ Too many args }
    if Args < Functions[FnMIndex].FnArgs then Warning(1,0);{ Args expected }
    while Args < Functions[FnMIndex].FnArgs do
     begin
      if DelChar(' ',SubStr) = '' then SubStr := '0'
      else SubStr := SubStr + ',0';
      Inc(Args);
     end;
    if Args <> 0 then
     begin
      BrackMax(SubStr);
      PArgsArray := MemAlloc(SizeOf(TOpAddr)*Args);
      if PArgsArray = Nil then Compiler.Error(1,-1);
      Ps := 0;
      for N := Args -1 downto 0 do
       begin
        RSubStr := GetRightId(SubStr,IdChars,Ps);
        if RSubStr = '' then Compiler.Error(5,LineNumber);
        if Pos(RSubStr,SubStr) = 0 then Compiler.Error(11,LineNumber);
        LVal(RSubStr, Result, Code);
        if Code <> 0 then Longint(PArgsArray^[N]) := GetOperandAddr(RSubStr)
        else Longint(PArgsArray^[N]) := GetConstAddr(Result);
        Ps := FIPos(',',SubStr,Ps);
       end;
      for N := 0 to Args - 1 do
        PushVar(Longint(PArgsArray^[N]));
      FreeMem(PArgsArray,SizeOf(TOpAddr)*Args);
    end;
    CallFn(FnMIndex,Args);
    Delete(Str,FnMPos,CBr-FnMPos + 1);
    Insert(TempVar(TempIndex),Str,FnMPos);
   end;
 until FnMPos = 0;
 BrackMax(Str);
 repeat
  Ps := Pos('!!',Str);
  if Ps <> 0 then Delete(Str,Ps,7);
 until Ps = 0;
 if DelChar(';',DelChar(' ',Str)) <> '' then Compiler.Error(5,LineNumber);
end;

Procedure Rem( Var Str : String);
var
 Ps, Ps1, Ps2 : Byte;
 SubStr : String;
begin
   if StUpcase(Trim(Str)) = 'REM' then
    begin
     Str := '';
     Exit;
    end;
   Ps1 := Pos('REM ',StUpCase(Str));
   Ps2 := Pos('"',Str);
   if (Ps2 <> 0) and (Ps2 < Ps1) then
   begin
     {Трассируем литералы}
     Ps := 1;
     repeat
      Ps := FIPos('"',Str,Ps);
      if Ps <> 0 then
       begin
        if Ps = Length(Str) then Compiler.Error(3,LineNumber);
        Ps := FIPos('"',Str,Ps);
        if Ps = 0 then Compiler.Error(3,LineNumber);
       end;
      Ps1 := FIPos('REM ',StUpCase(Str),Ps);
      if (Ps1 <> 0) or (Ps1 = 1) and (Str[Ps1 - 1] in TerminalChars) and
         ((Ps1+3 >=Length(Str)) or (Str[Ps1 + 3] in TerminalChars)) then
       Delete(Str,Ps1,255);
     until Ps = 0;
   end
  else if (Ps1 <> 0) or (Ps1 = 1) and (Str[Ps1 - 1] in TerminalChars) and
         ((Ps1+3 >=Length(Str)) or (Str[Ps1 + 3] in TerminalChars)) then
       Delete(Str,Ps1,255);
end;

function CStr2Str(S : String) : String;
var
 i, j : Integer;
 C : Word;
 SS : String;
begin
 i := 1;
 while i <= Length(S) do
  begin
   if S[i] = '\' then
    begin
     Delete(S, i, 1);
     case S[i] of
      'a' : S[i] := #7;   {BEL     Звуковой сигнал}
      'b' : S[i] := #8;   {BS      Забой}
      'f' : S[i] := #$0C; {FF      Перевод бланка}
      'n' : S[i] := #$0A; {LF      Новая строка (перевод строки)}
      'r' : S[i] := #$0D; {CR      Возврат каретки}
      't' : S[i] := #$09; {HT      Табуляция (горизонтальная)}
      'v' : S[i] := #$0B; {VT      Вертикальная табуляция}
      'e', 'E' : S[i] := #27;
      '\' : Inc(i);       {\       Обратная наклонная черта}
      'o', 'O' : S[i] := '\';
      '0'..'7' : begin
                  C := 0; j := 0;
                  while (j < 3) and (i <= Length(S)) and (S[i] in ['0'..'7']) do
                   begin
                    C := (C shl 3) + Byte(S[i]) - Byte('0');
                    Delete(S, i, 1);
                    Inc(j);
                   end;
                  Insert(Char(C), S, i);
                 end;
       'x', 'X': begin
                  C := 0; j := 0;
                  Delete(S, i, 1);
                  while (j < 2) and (i <= Length(S)) and (S[i] in ['0'..'9',
                                              'a'..'f', 'A'..'F']) do
                   begin
                    if S[i] in ['a'..'f', 'A'..'F'] then
                     C := (C shl 4) + Byte(UpCase(S[i])) + (10 - Byte('A'))
                    else C := (C shl 4) + Byte(S[i]) - Byte('0');
                    Delete(S, i, 1);
                    Inc(j);
                   end;
                  Insert(Char(C), S, i);
                 end;
     end {case}
    end
   else Inc(i);
  end;
 CStr2Str := S;
end;

Procedure Literals(Var Str : String);
var
 Ps1, Ps2 : Byte;
 SubStr : String[80];
begin
 repeat
  Ps1 := Pos('"',Str);
  if Ps1 <> 0 then
   begin
    Ps2 := FIPos('"',Str,Ps1);
    if (Ps2 <> 0) and (Ps1 <> Ps2) then
     begin
      SubStr := Copy(Str,Ps1 + 1,Ps2-Ps1 -1);
      Delete(Str,Ps1,Ps2-Ps1+1);
      Insert(CompileLiterals(CStr2Str(SubStr)),Str,Ps1);
     end
    else Compiler.Error(3,LineNumber);
   end;
 until Ps1 = 0;
end;

procedure Link(var Str : String);
var
 Ps1, Ps2 : Byte;
 SubStr : String[80];
{
function findfCBr(Var Str : String; OBr : Byte) : Byte;
var
 Ps, Opend, Closed : Byte;
begin
 Ps := Obr;
 Opend := 0; Closed := 0;
  repeat
   if Str[Ps] = #$7b then Inc(Opend);
   if Str[Ps] = #$7d then Inc(Closed);
   Inc(Ps);
  until (Ps > Length(Str)) or (Opend = Closed);
 if Opend <> Closed then Compiler.Error(22,LineNumber);
 findfCBr := Ps-1;
end;
}
begin
 repeat
  Ps1 := Pos(#$7b'L',Str);
  if Ps1 <> 0 then
   begin
    Ps2 := findfCBr(Str,Ps1);
    if (Ps2 <> 0) and (Ps1 <> Ps2) then
     begin
      SubStr := Copy(Str,Ps1 + 2,Ps2-Ps1 -2);
      Delete(Str,Ps1,Ps2-Ps1+1);
      Insert(CompileLink(CNFileName(CStr2Str(SubStr))),Str,Ps1);
     end
    else Compiler.Error(22,LineNumber);
   end;
 until Ps1 = 0;
end;

procedure Labels(Var Str : String);
var
 Ps, Ps1 : Byte;
 Index : Integer;
 PItem : PLabelValue;
 SubStr : String;
begin
 Ps := Pos(':',Str);
 if Ps <> 0 then
  begin
   if RIPos('"',Str,Ps) <> 0 then Exit;
   if RIPos('{L',Str,Ps) <> 0 then Exit;
   Ps1 := Ps;
   SubStr := GetLeftId(StUpCase(Str),IdChars,Ps1);
   if SubStr = '' then Compiler.Error(10,LineNumber);
   if Pos(SubStr,StUpCase(Str)) = 0 then Compiler.Error(10,LineNumber);
   if Ps1 > 1 then Compiler.Error(13,LineNumber);
   PItem := MemAlloc(SizeOf(TLabelValue));
   if PItem = Nil then Compiler.Error(1,LineNumber);
   PItem^.PLabel := NewStr(SubStr);
   PItem^.Value := InstrPtr;
   if LabValColl^.Search(PItem,Index) then
    begin
     DisposeStr(PItem^.PLabel);
     FreeMem(PItem,SizeOf(TLabelValue));
     Compiler.Error(12,LineNumber);
    end
   else
    begin
     LabValColl^.AtInsert(Index,PItem);
     Delete(Str,1,Ps);
    end
  end;
end;

Procedure ExCompile(var Str : String);
var
 Ps1, Ps2 : Byte;
 SubStr : String;
begin
 TempIndex := 0;
 CodeGen(#$55                   {     push bp}
        +#$8B#$EC);                     {     mov bp,sp}
 Ps1 := 1;
 repeat
  Ps2 := FIPos(';',Str,Ps1);
  if Ps2 = 0 then SubStr := Copy(Str,Ps1,Length(Str) - Ps1 + 1)
  else SubStr := Copy(Str,Ps1,Ps2 - Ps1);
  SubStr := DelChar(';',SubStr);
  if DelChar(' ',SubStr) <> '' then  CompileFn(SubStr);
  Ps1 := Ps2;
 until Ps2 = 0;
 CodeGen(#$8B#$E5                       {     mov sp,bp}
        +#$5D);                 {     pop bp}
end;

function PosWord(Const SubStr,Str: String) : Byte;
var
 Left, Right : Boolean;
 Ps,Ps1 : Byte;
begin
 PosWord := 0;
 Ps1 := 0;
 repeat
  Ps := FIPos(SubStr,Str,Ps1);
  if Ps = 0 then Exit;
  Left := (Ps = 1) or (Str[Ps-1] in TerminalChars);
  Right := (Ps + Byte(SubStr[0]) - 1 = Byte(Str[0])) or
           (Str[Ps + Byte(SubStr[0])] in TerminalChars);
  if Left and Right then PosWord := Ps;
  Ps1 := Ps;
 until Left and Right;
end;

procedure LineCompile(var Str : String);
var
 Ps1, Ps2, Ps3, Ps4 : Byte;
 PItem : PLabelValue;
 LabelStr, SubStr : String;
begin
 repeat
   Ps1 := PosWord('GOTO',Str);
   Ps4 := PosWord('RET',Str);
   if (Ps4 <> 0) and (Ps1 <> 0) then
    if Ps1 > Ps4 then Delete(Str,Ps1,255)
    else Delete(Str,Ps4,255);
   Ps1 := PosWord('GOTO',Str);
   if (Ps1 <> 0) then
    begin
     Ps2 := Ps1 + 4;
     LabelStr := GetRightId(Str,IdChars,Ps2);
     if LabelStr = '' then Compiler.Error(16,LineNumber);
     Delete(Str,Ps1,255);
     if DelChar(' ',DelChar(';',Str)) <> '' then LineCompile(Str);
     if not WriteToDisk then
     begin
       CodeGen(#$B8);
       CodeGen(Word2Str(255));         {     mov ax,255}
       CodeGen(#$2E#$FF#$1E#$04#$00);  {     call dword ptr cs:LibFnAddr}
     end;
     CodeGen(#$E9#$00#$00);            {     jmp LabelStr}
     if LstFlag then WriteLn(LstFile,Tabs,'jmp ',LabelStr);
     PItem := MemAlloc(SizeOf(TLabelValue));
     if PItem = Nil then Compiler.Error(1,LineNumber);
     PItem^.PLabel := NewStr(LabelStr);
     PItem^.Value := InstrPtr-2;
     FixLabelColl^.Insert(PItem);
     Delete(Str,Ps1,Ps2 - Ps1+1);
    end;
   Ps3 := PosWord('GOSUB',Str);
   if (Ps3 <> 0) then
    begin
     Ps2 := Ps3 + 5;
     LabelStr := GetRightId(Str,IdChars,Ps2);
     if LabelStr = '' then Compiler.Error(16,LineNumber);
     SubStr := Copy(Str,1,Ps3-1);
     if DelChar(' ',DelChar(';',SubStr)) <> '' then ExCompile(SubStr);
     Delete(Str,1,Ps2);
     if not WriteToDisk then
     begin
       CodeGen(#$B0
	      +#255                    {     mov al,255}
	      +#$2E#$FF#$1E#$04#$00);  {     call dword ptr cs:LibFnAddr}
     end;
     CodeGen(#$E8#$00#$00);            {     call LabelStr}
     if LstFlag then WriteLn(LstFile,Tabs,'call ',LabelStr);
     PItem := MemAlloc(SizeOf(TLabelValue));
     if PItem = Nil then Compiler.Error(1,LineNumber);
     PItem^.PLabel := NewStr(LabelStr);
     PItem^.Value := InstrPtr-2;
     FixLabelColl^.Insert(PItem);
    end;
   Ps4 := PosWord('RET',Str);
   if (Ps4 <> 0) then
    begin
     Delete(Str,Ps4,255);
     if DelChar(' ',DelChar(';',Str)) <> '' then LineCompile(Str);
     if not WriteToDisk then
     begin
       CodeGen(#$B0
              +#255                    {     mov ax,255}
              +#$2E#$FF#$1E#$04#$00);  {     call dword ptr cs:LibFnAddr}
     end;
     CodeGen(#$C3);                    {     ret}
     if LstFlag then WriteLn(LstFile,Tabs,'ret');
    end;
 until Ps1 + Ps3 + Ps4 = 0;
 if DelChar(' ',DelChar(';',Str)) <> '' then ExCompile(Str);
end;

Procedure IFCompile(var Str : String);
var
 Ps, PsIF, PsTHEN, PsELSE : Byte;
 FixELSE, FixENDIF : Word;
 SubStr : String;
begin
 PsIF := PosWord('IF',Str);
  if PsIF <> 0 then
   begin
    if PsIF > 1 then
     begin
      SubStr := Copy(Str,1,PsIF-1);
       if SubStr <> '' then
        begin
         LineCompile(SubStr);
         Delete(Str,1,PsIF-1);
        end;
     end;
    PsIF := Pos('IF ',Str);
    if PsIF <> 0 then
     begin
       PsTHEN := Pos(' THEN ',Str);
       if PsTHEN < PsIF then Compiler.Error(15,LineNumber);
       SubStr := Copy(Str,PsIF + 2, PsTHEN - PsIF - 2);
       {Компилируем условие}
       ExCompile(SubStr);
       CodeGen(#$0B#$C2                {     or ax,dx}
              +#$75#$03                {     jnz $+5}
              +#$E9#$00#$00);  {     jmp @@ELSE}
       if LstFlag then WriteLn(LstFile,Tabs,'jnz @@ELSE');
       FixELSE := InstrPtr-2;
       PsELSE := Pos(' ELSE ',Str);
       if PsELSE <> 0 then
        begin
         if PsELSE <   PsTHEN then Compiler.Error(15,LineNumber);
         SubStr := Copy(Str,PsTHEN + 6,PsELSE - PsTHEN - 6);
         {Компилируем 'then'   }
         IFCompile(SubStr);
         CodeGen(#$E9#$00#$00);        {     jmp @@ENDIF}
         if LstFlag then WriteLn(LstFile,Tabs,'jmp @@ENDIF');
         FixENDIF :=   InstrPtr-2;
         Integer(Addr(PProgr^[FixELSE])^) :=   InstrPtr - FixELSE - 2;
         {Компилируем 'else'   }
         if LstFlag then WriteLn(LstFile,'@@ELSE:');
         SubStr :=  Copy(Str,PsELSE + 6, 255);
         IFCompile(SubStr);
         Integer(Addr(PProgr^[FixENDIF])^) := InstrPtr - FixENDIF - 2;
         if LstFlag then WriteLn(LstFile,'@@ENDIF:');
        end
       else
        begin
         {Компилируем 'then'   если нет 'else'}
         SubStr := Copy(Str,PsTHEN + 6, 255);
         IFCompile(SubStr);
         Integer(Addr(PProgr^[FixELSE])^) := InstrPtr - FixELSE - 2;
         if LstFlag then WriteLn(LstFile,'@@ENDIF:');
        end;
     end
    else Compiler.Error($ff,LineNumber);
   end
  else LineCompile(Str);
end;

procedure FixUp;
var
 FixIndex, LabIndex, InfIndex : Integer;
 PFixLabel : PLabelValue;
 LineInfo : TLineInfo;
begin
if FixLabelColl^.Count > 0 then
 begin
  for FixIndex := 0 to FixLabelColl^.Count - 1 do
   begin
    PFixLabel := FixLabelColl^.At(FixIndex);
    if LabValColl^.Search(PFixLabel, LabIndex) then
      Integer(Addr(PProgr^[PFixLabel^.Value])^) :=
       TLabelValue(LabValColl^.At(LabIndex)^).Value - PFixLabel^.Value - 2
    else
     begin
      LineInfo.Addr := PFixLabel^.Value;
      LineColl^.Search(Pointer(LineInfo),InfIndex);
      Pointer(LineInfo) := LineColl^.At(InfIndex-1);
      Compiler.Error(19,LineInfo.LineNum);
     end;
    if Integer(Addr(PProgr^[PFixLabel^.Value])^) = -3 then
     begin
      LineInfo.Addr := PFixLabel^.Value;
      LineColl^.Search(Pointer(LineInfo),InfIndex);
      Pointer(LineInfo) := LineColl^.At(InfIndex-1);
      Compiler.Error(20,LineInfo.LineNum);
     end;
   end;
 end;
end;

procedure CompileString(Str : String);
var
 LineInfo : TLineInfo;
 S : String;
begin
 LineInfo.Addr := InstrPtr;
 LineInfo.LineNum := LineNumber;
 Rem(Str);
 S := Str;
 if (S = '') or (DelChar(' ',DelChar(';',S)) = '') then exit;
 Labels(Str);
 S := Str;
 if (S = '') or (DelChar(' ',DelChar(';',S)) = '') then exit;
 Literals(Str);
 if Str = '' then exit;
 Str := StUpCase(Str);
 Link(Str);
 if Str = '' then exit;
 IFCompile(Str);
 LineColl^.Insert(Pointer(LineInfo));
end;

function DebugMsgBox: Word;
begin
  DebugMsgBox := MessageBox(
    ^C'This will end your debugging session.', nil, mfWarning + mfOkCancel);
end;

function RunMsgBox: Word;
begin
  RunMsgBox := MessageBox(
    ^C'This command will terminate user program execution.' +
    ' Do you wish to restart the program afterwards ?',
    nil, mfConfirmation + mfYesNoCancel);
end;

end.
