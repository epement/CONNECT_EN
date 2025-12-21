{$A+,B-,D+,E+,F+,G-,I-,L+,N+,O-,P-,Q-,R-,S-,T-,V-,X+,Y-}
{$M 16384,0,655360}

uses
 Dos, Crt, Win,	TpString, Consts, ApPrim, apPort, apCom, apMisc,
 Revpos, GetID,	Objects;

type

  TMode	= (mError, mOk,	mHandshake, mWrite, mRead, mErase_verify,
	   mWrite_verify, mErase, mUErase, mVerify, mSet_Upr, mReset_Upr,
	   mLock_Read, mLock_Write, mLock_Ex, mUWrite, mLoad, mRun,
	   mReadRAM, mExec, mHelp);

  TError = (erOk, erCfgNotFound, erCfgLine, erNoPort, erNoChip,
	    erPort, erNoHandshake, erFileNotFound, erFileNotCreate,
	    erFile, erEsc, erUnknownChip, erSwOff, erMode, erRead,
	    erWrite, erNoWrite,	erBadAddr, erVerify, erErase);

  TAns = (anError, anOk);


  TCommand = record
    mode: TMode;			 { Programming mode }
    chip: Byte;				 { Chip	type code }
    info: Byte;
    address: Longint;			 { Programming address }
    length: Longint;			 { Block length	}
    voltage: Byte;			 { Programming voltage }
    count: Byte;			 { Repetition count }
  end;

  TAnswer = record
    ans: TAns;				 { Programming mode }
    err: TError;			 { Chip	type code }
    info: Byte;
    address: Longint;			 { Programming address }
    length: Longint;			 { Block length	}
    voltage: Byte;			 { Programming voltage }
    count: Byte;			 { Repetition count }
  end;

  TMessage = record
   case	boolean	of
    true:  (cmd: TCommand);
    false: (ans: TAnswer);
  end;

const
 ModeStr = 'W|R|E|V|U|UE|EU|EV|VE|WV|VW|RU|LR|LW|LE|UW|WU|LD|RR|EX|RUN|?';
 Modes : Array[0.. Length(ModeStr)] of TMode =
   (mError, mWrite, mError, mRead, mError, mErase, mError, mVerify,
    mError, mSet_Upr, mError, mUErase, mError, mError, mUErase,	mError,
    mError, mErase_verify, mError, mError, mErase_verify, mError, mError,
    mWrite_verify, mError, mError, mWrite_verify, mError, mError,
    mReset_Upr,	mError,	mError,	mLock_read, mError, mError, mLock_write,
    mError, mError, mLock_write, mError, mError, mUWrite, mError, mError,
    mUWrite, mError, mError, mLoad, mError, mError, mReadRAM, mError, mError,
    mExec, mError, mError, mRun, mError, mError, mError, mHelp);

 Digits: Set of	char = ['0'..'9', 'A' .. 'F'];

 Chip: String[12] = '';
 FileName: String[80] =	'';
 DrvName: String[80] =	'';
 ComPort: ComNameType =	COM1;
 P: PortRecPtr = Nil;
 Beep: Boolean = True;

 DLE = #16;
 ACK = #6;
 NAK = #21;
 XBufSize = 24;

var
 Mode, SaveMode: TMode;
 Error:	TError;
 Msg, SaveMsg: TMessage;
 SWin: WinState;
 SWinBuf : Array[0..700] of byte;
 Upr: Byte;
 ErrAddr: Longint;
 SaveCursor: Word;

function GetCursorState: Word; assembler;
asm
	MOV	 AH,3
	XOR	 BH,BH
	INT	 10H
	MOV	 AX,CX
end;

procedure SetCursorState(State:	Word); assembler;
asm
	MOV	 AH,1
	XOR	 BH,BH
	MOV	 CX,State
	INT	 10H
end;

function L2L(L:	Longint): Longint;
type
 TLong = array[0..3] of	byte;
var
 LL: Longint;
begin
 TLong(LL)[0] := TLong(L)[3];
 TLong(LL)[1] := TLong(L)[2];
 TLong(LL)[2] := TLong(L)[1];
 TLong(LL)[3] := TLong(L)[0];
 L2L :=	LL;
end;

procedure AddStr(var S:	String;	C: Char; Count:	Byte); assembler;
asm
 mov cl, Count
 xor ch, ch
 jcxz @@1
@@0:
 les di, S
 inc byte ptr es:[di]
 mov al, byte ptr es:[di]
 xor ah, ah
 add di, ax
 mov al, C
 mov byte ptr es:[di], al
 loop @@0
@@1:
end;

function HexL(L: Longint): String;
var
 S: String;
begin
 if L >= $10000	then S := tpString.HexL(L)
 else S	:= tpString.HexW(L);
 while (S[1] = '0') and	(Length(S) > 4)	do Delete(S, 1,	1);
 HexL := S;
end;

Procedure MoveBar(Max, Current:	Longint);
const
 BarLength = 40;
var
 Width:	Byte;
 SBar: String[BarLength	+ 2];
begin
 SBar := '';
 if Max	= -1 then AddStr(SBar, ' ', BarLength)
 else
  begin
   if Current <> 0 then
     Width := Byte(Trunc(BarLength / (Max / (Current+1))))
   else	Width := 0;
   if Width > BarLength	then Width := BarLength;
   AddStr(SBar,	'Û', Width);
   AddStr(SBar,	'°', BarLength - Width);
  end;
 WriteStr(3, 3,	SBar, TextAttr);
 if Current > 0	then
  WriteStr(3, 4, Long2Str(Current) + '           ', $7e)
 else WriteStr(3, 4, '           ', $7e)
end;

function ErrMes(Error:TError): String;
begin
 if CancelReq then ErrMes := 'Cancel requested.'
 else case Error of
  erOk:
   ErrMes := 'OK.';
  erCfgNotFound:
   ErrMes := 'Config file not found.';
  erCfgLine:
   ErrMes := 'Config file syntax error.';
  erNoPort:
   ErrMes := 'Undefined COM port.' ;
  erNoChip:
   ErrMes := 'Undefined chip.';
  erPort:
   ErrMes := 'Can''t open COM port.';
  erNoHandshake:
    ErrMes := 'Handshake failure.';
  erFileNotFound:
   ErrMes := 'File not found.';
  erFileNotCreate:
   ErrMes := 'Can''t create file.';
  erEsc:
   ErrMes := 'Cancel requested.';
  erWrite:
   ErrMes := 'Write error at address '+	HexL(ErrAddr) +'H.';
  erNoWrite:
   ErrMes := 'Can''t write at address '+ HexL(ErrAddr) +'H.';
  erSwOff:
   ErrMes := 'Upp switch is turned off.';
  erMode:
   ErrMes := 'Mode not supported.';
  erRead:
   ErrMes := 'Can''t read at address '+	HexL(ErrAddr) +'H.';
  erVerify:
   ErrMes := 'Verify failure at address ' + HexL(ErrAddr) +'H.';
  erUnknownChip:
   ErrMes := 'Unknown chip type.';
  erBadAddr:
   ErrMes := 'Invalid address: ' + HexW(ErrAddr) +'H.';
  erErase:
   ErrMes := 'Can''t erase at address '	+ HexL(ErrAddr)	+'H.';
  else ErrMes := '';
 end;
end;

function SUpr(const S: String):	Byte;
var
 R: Real;
 Code: Integer;
begin
 Val(S,	R, Code);
 if R <	10 then	SUpr :=	100
 else if R > 25.5 then SUpr := 255
 else SUpr := Trunc(R *	10);
end;

procedure ComString;
var
 PComString: ^String;
 i, j :	Byte;
 Ch: Char;
 State:	(NoOpt,	Opt, Ok);
 MStr: String[12];

begin
 State := NoOpt;
 PComString := Ptr(PrefixSeg, $80);
 i := 1; MStr := '';
 while i <= Length(PComString^)	 do
  begin
   Ch := PComString^[i];
   case	State of
    NoOpt: if (Ch in ['/', '-']) then
	    begin
	     State := Opt;
	     j := i;
	    end;
    Opt: if Ch in ['?','A'..'Z', 'a'..'z'] then	AddStr(MStr, UpCase(Ch), 1)
	 else State := Ok;
   end {case};
   Inc(i);
  end;
 Delete(PComString^, j,	Length(MStr) + 1);
 Mode := Modes[Pos(MStr, ModeStr)];
 if ParamCount = 1 then
  begin
   FileName := ParamStr(1);
   Chip	:= StUpCase(ParamStr(1));
  end
 else
  begin
   Chip	:= StUpCase(ParamStr(1));
   FileName := ParamStr(2);
  end;
 UPr :=	SUpr(FileName);
end;

procedure Config;
const
 stPort	= 1;
 stChip	= 2;
var
 Ps, Ps1 : Byte;
 stCfg:	Byte;
 Code: Integer;
 T: Text;
 CfgName: String[80];
 S, SS : String;
begin
 if Mode in [mSet_Upr, mReset_Upr, mRun, mLoad, mExec, mReadRAM] then
   stCfg := stChip
 else stCfg := 0;
 CfgName := ParamStr(0);
 CfgName := Copy(CfgName, 1, Pos('.', CfgName))	+ 'CFG';
 Assign(T, CfgName);
 Reset(T);
 if IOresult <>	0 then
  begin
   Mode	:= mError;
   Error := erCfgNotFound;
   Exit;
  end;
 while not Eof(T) and (stCfg <>	stChip + stPort) do
  begin
   ReadLn(T, S);
   Ps := Pos(';', S);
   if Ps <> 0 then Delete(S, Ps, 255);
   if S	= '' then Continue;
   S :=	StUpCase(S);
   S :=	DelChar(' ', S);
   S :=	DelChar(#8, S);

   Ps := Pos('PORT=', S);
   if Ps <> 0 then
    begin
     Inc(Ps, 5);
     if	S[Ps] in ['1'..'4'] then
      begin
       ComPort := ComNameType(Byte(S[Ps]) - Byte('1'));
       stCfg :=	stCfg or stPort;
      end;
    end;

   Ps := Pos('BEEP=', S);
   if Ps <> 0 then
    begin
     Inc(Ps, 5);
     if	S[Ps] = '0' then Beep := False;
    end;

   Ps := Pos(',', S);
   if Ps <> 0 then SS := SCopy(S, 1, Ps)
   else	SS := '';

   if (Chip <> '') and (Chip = SS) then
    begin
     stCfg := stCfg or stChip;
     Ps1 := FIPos(',', S, Ps);
     SS	:= SCopy(S, Ps + 1, Ps1);
     Val(SS, Msg.cmd.Chip, Code);
     if	Code <>	0 then Error :=	erCfgLine;

     Ps	:= Ps1;
     Ps1 := FIPos(',', S, Ps);
     SS	:= SCopy(S, Ps + 1, Ps1);
     Val(SS, Msg.cmd.info, Code);
     if	Code <>	0 then Error :=	erCfgLine;

     Ps	:= Ps1;
     Ps1 := FIPos(',', S, Ps);
     SS	:= SCopy(S, Ps + 1, Ps1);
     Msg.cmd.voltage :=	SUpr(SS);
     if	Msg.cmd.voltage	= 0 then Error := erCfgLine;
     Upr := Msg.cmd.voltage;

     Ps	:= Ps1;
     Ps1 := FIPos(',', S, Ps);
     if Ps1 = 0 then Ps1 := 255;
     SS	:= SCopy(S, Ps + 1, Ps1);
     Val(SS, Msg.cmd.length, Code);
     Msg.cmd.length := L2L(Msg.cmd.length);
     if	Code <>	0 then Error :=	erCfgLine;

     if Ps1 < 255 then
      begin
       Ps := Ps1;
       Ps1 := FIPos(',', S, Ps);
       if Ps1 = 0 then Ps1 := 255;
       DrvName := SCopy(S, Ps + 1, Ps1);
      end;
     if (Msg.cmd.Chip = 0) and (DrvName = '') then Error := erCfgLine;
    end;
  end;
 Close(T);

 if (stCfg and stChip) = 0 then	Error := erNoChip;
 if (stCfg and stPort) = 0 then	Error := erNoPort;
 if Error <> erOk then Mode := mError;
end;

{
function C2S(C:	Char):String;
begin
 case C	of
  DLE: C2S := 'DLE';
  ACK: C2S := 'ACK';
  NAK: C2S := 'NAK';
 else C2S := C;
 end;
end;
}

function send_pkt(var Msg; length, address: Byte): integer;
var
  c: Char;
  chk, i: Byte;
begin
{
  repeat
   GetCharTimeOut(P, C,	1);
  until	AsyncStatus <> ecOK;
}
  BufferFlush(P, True, False);

  PutCharPrim(P, DLE);
  PutCharPrim(P, Char(length));
  PutCharPrim(P, Char(address));
  chk := 0;
  if length <> 0 then for i := 0 to length - 1 do
  begin
    c := Char(TByteArray(Msg)[i]);
    PutCharPrim(P, C);
    Inc(chk, Byte(C));
  end;
  PutCharPrim(P, Char(chk));
  repeat
    C := NAK;
    GetCharTimeOut(P, C, TryTimeout);
    if (AsyncStatus = ecOK) or CancelReq then Break;
    if Mode = mHandshake then Break;
    PutCharPrim(P, #0);
  until	False;
  if C = ACK then send_pkt := length
  else send_pkt	:= -1;
end;

function receive_pkt(var Msg; length: Byte): integer;
var
  c: Char;
  chk, len, addr, i: Byte;
begin
  C := #0;
  if Mode = mHandshake then GetCharTimeOut(P, C, TryTimeOut)
  else GetCharTimeOut(P, C, FullTimeout);
  if (AsyncStatus = ecOK) and (C = DLE)	and not CancelReq then
  begin
    GetCharTimeOut(P, Char(len), TryTimeout);
    if (AsyncStatus = ecOK) and	(len <=	length)	and not CancelReq then
    begin
      GetCharTimeOut(P,	Char(addr), TryTimeout);
      if (AsyncStatus = ecOK) and not CancelReq then
      begin
	chk := 0;
	if len <> 0 then for i := 0 to len - 1 do
	begin
	  GetCharTimeOut(P, C, TryTimeout);
	  if (AsyncStatus = ecOK) and not CancelReq then
	  begin
	    TByteArray(Msg)[i] := Byte(C);
	    Inc(chk, Byte(C));
	  end;
	end;
	GetCharTimeOut(P, C, TryTimeout);
	if (AsyncStatus	= ecOK)	and (Byte(C) = chk) and not CancelReq then
	begin
	  PutCharPrim(P, ACK);
	  receive_pkt := len;
	  Exit;
	end;
      end;
    end;
  end;
  PutCharPrim(P, NAK);
  receive_pkt := -1;
end;

function HandShake: Boolean;
var
  B: Boolean;
  Try: Word;
  Msg: TMessage;
begin
  InitRoller;
  Try := 50;
  WriteStr(3, 1, 'Waiting for a handshake...', TextAttr);
  repeat
    FillChar(Msg, SizeOf(Msg), 0);
    Msg.cmd.mode := mHandshake;
    SaveMode := Mode;
    Mode := mHandshake;
    CancelNow := True;
    B := (send_pkt(Msg,	SizeOf(Msg), 0)	> 0) and not CancelReq and
	 (receive_pkt(Msg, SizeOf(Msg))	> 0) and
	 (Msg.ans.ans =	anOk) and not CancelReq;
    CancelNow := False;
    Mode := SaveMode;
    if B or CancelReq then Break;
    Delay(100);
    MoveBar(50,	Try);
    Dec(Try);
  until	Try = 0;
  while	KeyPressed do ReadKey;
  if not B then
  begin
    Mode := mError;
    Error := erNoHandshake;
  end;
  WriteStr(3, 1, '                          ', TextAttr);
  MoveBar(-1, 0);
  DoneRoller;
  HandShake := B;
end;

procedure WriteBin(Addr: Longint; const FName: String);
var
 Ans: TAnswer;
 Size, Len: Longint;
 BufSize: Byte;
 F: PBufStream;
 Buf: Array[0..63] of byte;
 S: String[8];
begin
 WriteStr(3, 2, 'File:', $7e);
 WriteStr(9, 2, Pad(TrimmedName(FExpand(FName), 34), 34), TextAttr);
 F := New(PBufStream, Init(FName, stOpenRead, 4096));
 if F^.Status =	stOk then
  begin
   Size	:= F^.GetSize;
   Msg.cmd.mode	:= Mode;
   Msg.cmd.address := L2L(Addr);
   Len := L2L(Msg.cmd.length);
   if Len > Size then Len := Size;
   Str(Len:8, S);
   WriteStr(29,	1, S + ' bytes', $7e);

   if Len = 0 then
   begin
     Dispose(F, Done);
     Exit;
   end;

   Ans.err := erNoHandshake;

   if (send_pkt(Msg, SizeOf(Msg), 0) > 0) and
      (receive_pkt(Ans,	SizeOf(Ans)) > 0) and
      (Ans.ans = anOk) then
    begin
      {WriteStr(3, 5, 'Ok    ',	TextAttr);ReadKey;}
      if Mode <> mLoad then Delay(500);
      while (F^.Status = stOk) and
	    (F^.GetPos < Len) and
	    (Mode <> mError) and not CancelReq do
       begin
	if Len - F^.GetPos >= XBufSize then BufSize := XBufSize
	else BufSize :=	Len - F^.GetPos;
	F^.Read(Buf, BufSize);
	if F^.Status = stOk then
	 begin
	  if send_pkt(Buf, BufSize, 0) >= 0 then
	   begin
	    if (receive_pkt(Ans, SizeOf(Ans)) >	0) and
	       (Ans.ans	= anOk)	then
	     begin
	      MoveBar(len, F^.GetPos);
	     end
	    else
	     begin
	       Mode := mError;
	       Error :=	Ans.err;
	       ErrAddr := L2L(Ans.address);
	     end;
	   end
	  else
	   begin
	    Mode := mError;
	    Error := erNoHandshake;
	   end;
	 end
	else
	 begin
	  Mode := mError;
	  Error	:= erFile;
	 end;
       end;
      if Mode <> mError	then
       begin
	if (send_pkt(Msg, 0, 0)	< 0) then
	 begin
	  Mode := mError;
	  Error	:= erNoHandshake;
	 end;
	if (Mode <> mError) and
	   (receive_pkt(Ans, SizeOf(Ans)) > 0) and
	   (Ans.ans = anOk) then
	  if CancelReq then
	  begin
	    Mode := mError;
	    Error := Ans.err;
	  end else
	else
	 begin
	  Mode := mError;
	  Error	:= Ans.err;
	 end;
       end;
    end
   else
    begin
     Mode := mError;
     Error := Ans.err;
    end;
  end
 else
  begin
   Mode	:= mError;
   Error := erFileNotFound;
  end;
 Dispose(F, Done);
end;

procedure ReadBin(Addr: Longint; const FName: String);
var
 Ans: TAnswer;
 Size: Longint;
 BufSize: Integer;
 F: PBufStream;
 Buf: Array[0..63] of byte;
 S: String[8];
begin
 RollerBack := True;
 WriteStr(3, 2, 'File:', $7e);
 WriteStr(9, 2, Pad(TrimmedName(FExpand(FName), 34), 34), TextAttr);
 F := New(PBufStream,Init(FName, stCreate, 4096));
 if F^.Status =	stOk then
 begin
   Msg.cmd.mode	:= Mode;
   Msg.cmd.address := L2L(Addr);
   Size	:= L2L(Msg.cmd.length) - Addr;
   Str(Size:8, S);
   WriteStr(29,	1, S + ' bytes', $7e);

   Ans.err := erNoHandshake;

   if (send_pkt(Msg, SizeOf(Msg), 0) > 0) and
      (receive_pkt(Ans,	SizeOf(Ans)) > 0) and
      (Ans.ans = anOk) then
   begin
     while (Mode <> mError) and not CancelReq do
     begin
       BufSize := receive_pkt(Buf, SizeOf(Buf));
       if BufSize = 0 then Break;
       if BufSize > 0 then
       begin
	 F^.Write(Buf, BufSize);
	 if F^.Status = stOk then
	 begin
	   Ans.ans := anOk;
	   MoveBar(Size, F^.GetPos);
	 end
	 else
	 begin
	   Ans.ans := anError;
	   Mode := mError;
	   Error := erFile;
	 end;
	 if (send_pkt(Ans, SizeOf(Msg), 0) < 0) then
	 begin
	   Mode := mError;
	   Error := erNoHandshake;
	 end;
       end
       else
       begin
	 Mode := mError;
	 Error	:= erNoHandshake;
       end;
     end;
     if (Mode <> mError) and
	(receive_pkt(Ans, SizeOf(Ans)) > 0) and
	(Ans.ans = anOk) then
     else
     begin
       Mode := mError;
       Error := Ans.err;
       ErrAddr := L2L(Ans.address);
     end;
   end
   else
   begin
     Mode := mError;
     Error := Ans.err;
   end;
 end
 else
 begin
   Mode	:= mError;
   Error := erFileNotCreate;
 end;
 Dispose(F, Done);
end;

procedure SendCmd;
var
 Ans: TAnswer;
begin
   Msg.cmd.mode	:= Mode;
   Msg.cmd.voltage := Upr;
   Ans.err := erNoHandshake;

   if (send_pkt(Msg, SizeOf(Msg), 0) > 0) and
      (receive_pkt(Ans,	SizeOf(Ans)) > 0) and
      (Ans.ans = anOk) then
    begin
      if (receive_pkt(Ans, SizeOf(Ans))	> 0) and
	 (Ans.ans = anOk) then
      else
       begin
	Mode :=	mError;
	Error := Ans.err;
	ErrAddr	:= L2L(Ans.address);
       end;
    end
   else
    begin
     Mode := mError;
     Error := erNoHandshake;
    end;
   Delay(500);
end;

begin
 CheckBreak := False;
 ComString;
  if (Mode in [mError, mHelp]) or
     ((ParamCount = 0) and
      (Mode <> mReset_Upr)) then
   begin
    Writeln;
    WriteLn('PRGMTR {Chip} {FileName|Upr|None}');
    Writeln('Options:  -|/{', ModeStr,'}');
    WriteLn('  W       Write.');
    WriteLn('  R       Read.');
    WriteLn('  E       Erase.');
    WriteLn('  UE, EU  Unconditional erase.');
    WriteLn('  V       Verify.');
    WriteLn('  EV, VE  Erase verify.');
    WriteLn('  WV, VW  Write verify.');
    WriteLn('  U       Set Upp.');
    WriteLn('  RU      Reset Upp.');
    WriteLn('  LR      Lock read.');
    WriteLn('  LW      Lock write.');
    WriteLn('  LE      Lock exec.');
    WriteLn('  UW, WU  Unconditional write.');
    WriteLn('  RR      Read RAM.');
    WriteLn('  LD      Load.');
    WriteLn('  EX      Load and run.');
    WriteLn('  RUN     Run.');
    WriteLn('');
    Halt(1);
   end;

 Config;
 if Mode <> mError then
  begin
   InitPortPrim(P, ComPort, 57600, NoParity, 8,	1, $1000, $1000, PortOptions);
   if (P = nil)	or (AsyncStatus	<> ecOK) then Error := erPort;
  end;

 SaveWin(SWin);
 Window(18, 10,	63, 16);
 ReadWin(SWinBuf);
 FrameWin(' Programmator ', DoubleFrame, $7f, $7f);
 TextColor(0);
 TextBackground(7);
 ClrScr;
 SaveCursor := GetCursorState;
 SetCursorState($2000);
 if Mode <> mError then	HandShake;
 InitRoller;
 if (Msg.cmd.Chip = 0) and (Mode in [mWrite, mRead, mErase_verify,
     mWrite_verify, mErase, mUErase, mVerify, mLock_Read, mLock_Write,
     mLock_Ex, mUWrite]) then
   begin
    WriteStr(3,	1, 'Loading...', TextAttr);
    SaveMode := Mode;
    SaveMsg := Msg;
    Mode := mLoad;
    Msg.cmd.length := L2L($ffff);
    WriteBin($E000, DrvName);
    if Mode <> mError then Mode := SaveMode;
    Msg := SaveMsg;
    MoveBar(-1, 0);
   end;
 case Mode of
  mWrite,
  mUWrite,
  mWrite_verify,
  mVerify:
   begin
    case Mode of
     mWrite,
     mUWrite:
      WriteStr(3, 1, 'Writing '	+ Chip + '...',	TextAttr);
     mWrite_verify:
      WriteStr(3, 1, 'Verifying for write ' + Chip + '...', TextAttr);
     mVerify:
      WriteStr(3, 1, 'Verifying ' + Chip + '...', TextAttr);
    end;
    WriteBin(0, FileName);
{
    SaveMode := Mode;
    repeat
     Mode := SaveMode;
     WriteBin(0, FileName);
    until CancelReq or KeyPressed;
}
   end;
  mRead:
   begin

    WriteStr(3,	1, 'Reading ' +	Chip + '...', TextAttr);
    ReadBin(0, FileName);
{
    repeat
    ReadBin(0, FileName);
    until Mode = mError;
}
   end;
  mReadRAM:
   begin
    Msg.cmd.chip := 1;
    Msg.cmd.length := L2L($10000);
    WriteStr(3,	1, 'Reading RAM...', TextAttr);
    ReadBin($E000, FileName);
   end;
  mErase,
  mUErase,
  mErase_verify,
  mLock_read,
  mLock_write,
  mLock_Ex,
  mRun:
   begin
    case Mode of
     mErase, mUErase:
      WriteStr(3, 1, 'Erasing '	+ Chip + '...',	TextAttr);
     mErase_verify:
      WriteStr(3, 1, 'Erase verifying '	+ Chip + '...',	TextAttr);
     mLock_read:
      WriteStr(3, 1, 'Locking read ' + Chip + '...', TextAttr);
     mLock_write:
      WriteStr(3, 1, 'Locking write ' +	Chip + '...', TextAttr);
     mLock_Ex:
      WriteStr(3, 1, 'Locking exec ' + Chip + '...', TextAttr);
     mRun:
      WriteStr(3, 1, 'Running...', TextAttr);
    end;
{    repeat}
    SendCmd;
{    until Mode = mError;}
   end;

  mSet_Upr:
   begin
    WriteStr(3,	1, 'Setting ' +	ParamStr(1) + 'V Upr.',	TextAttr);
    Msg.cmd.chip := 2;
    SendCmd;
   end;
  mReset_Upr:
   begin
    WriteStr(3,	1, 'Setting 5V Upr.', TextAttr);
    Msg.cmd.chip := 2;
    SendCmd;
   end;
  mExec:
   begin
    WriteStr(3,	1, 'Running...', TextAttr);
    Mode := mLoad;
    Msg.cmd.length := L2L($ffff);
    WriteBin($E000, FileName);
    Mode := mRun;
    SendCmd;
   end;
  mLoad:
   begin
    WriteStr(3,	1, 'Loading...', TextAttr);
    Mode := mLoad;
    Msg.cmd.length := L2L($ffff);
    WriteBin($E000, FileName);
   end;

 end;
 DoneRoller;
 MoveBar(-1, 0);
 if Error <> erOk then
  begin
   if Beep then Write(^G);
   if CancelReq then WriteStr(3, 4, 'ABORT:', $74)
   else WriteStr(3, 4, 'ERROR:', $74);
   WriteStr(10,	4, ErrMes(Error), TextAttr);
   WriteStr(3, 5, 'Press any key to continue.',	TextAttr);
   ReadKey;
  end
 else
  begin
   Byte(Error) := 0;
   WriteStr(3, 4, 'Operation complete.', TextAttr);
   Delay(700);
  end;

 SetCursorState(SaveCursor);
 UnFrameWin;
 WriteWin(SWinBuf);
 RestoreWin(SWin);
 DonePortPrim(P);
 Halt(Ord(Error));
end.
