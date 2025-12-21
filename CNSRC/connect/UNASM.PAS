{$F+,O+,X+}
UNIT UnAsm;
INTERFACE
USES TpString;
type
 OprStr	= String[32];
 CpuGate = (C086,C186,C286,C386);
const
 SegDBit : Boolean = FALSE; { Assume 16-Bit Addressing }
 EmuFlag : Byte	= 0;
 var
  CpuAuth : CpuGate;
 function UnAssemble(var U : Pointer) :	String;

IMPLEMENTATION
type	{ Types	Below Used For Quick Classification of Op-Codes	}

 PtrRec	= record
     Ofs, Seg: Word;
 end;

 Gating	= (G_RM1, G_RM2, G_RM3,	 G_RM4,	 G_RM5,
	   G_RM6, G_RM7, G_RM8,	 G_RM9,	 { modR/M Has op bits }
	   G_Hit,    { defined operation }
	   G_0Fx,    { 0F-type operation }
	   G_387,    { escapes to 80387	 }
	   G_Pfx,    { prefix  operation }
	   G_ooo);   { invalid operation }

 Gate_2	= (Row_0,   { 2nd-level	gates for G_0Fx	Operations }
	   Row_2,
	   Row_8,
	   Row_9,
	   Row_A,
	   Row_B,
	   Row_X);   { invalid otherwise }


 TAdr =	(Adr16,Adr32);	{16-bit	or 32-bit Addressing}
 WBitStatus = (W0,W1);	{W1 = W-bit ON,	else W0}
 REGString = String[3];
 TagRec	= record
  A : Char;	{tells type of operand}
  V : Byte	{gives width/value etc}
 end;
 TagGrp	= array[1..3] of TagRec;
 CpuVec	= record
  F,	{Bit Flags for Processing Options}
	{1xxx xxxx = alternate Mnemonic	at M+1	}
	{x1xx xxxx = 32-bit if OpSiz Prefix	}
	{xx1x xxxx = 16-bit normally		}
	{xxx1 xxxx = sign-extend immediates	}
	{xxxx 1xxx = Op	has modR/M field	}
	{---- -ccc = Cpu Required for Op	}
  M,	{8086  Mnemonic	Index}
  T	{Operand Format	Index} : Byte
 end;

 MpuVec	= record
  F,	{ Flag Bits (see below)
	0000 0000 = INVALID operation
	0010 xxxx = Entire modR/M byte defines op-code
	0001 xxxx = modR/M REG field defines op-code
	xxxx 0000 = no explicit	operand(s) coded
	xxxx 0001 = operand is "AX"
	xxxx 0010 = operand is "Bcd80"
	xxxx 0011 = operand is "Ea" (no	size implied)
	xxxx 0100 = operand is "Ew" (16-bit word)
	xxxx 0101 = operand is "Int16"
	xxxx 0110 = operand is "Int32"
	xxxx 0111 = operand is "Int64"
	xxxx 1000 = operand is "Real32"
	xxxx 1001 = operand is "Real64"
	xxxx 1010 = operand is "Real80"
	xxxx 1011 = operand is "ST(i)"
	xxxx 1100 = operand is "ST(i),ST"
	xxxx 1101 = operand is "ST,ST(i)"
	xxxx 1110 = reserved
	xxxx 1111 = reserved}
  M	{ index	to mnemonic table }: Byte
 end;
 TMrm =	record
  D,	   { Size in Bytes of Displacement Field}
  SIB,	   { 1 -> SIB field present, else no SIB}
  rS,	   { index to Segment Register String	}
  rB,	   { index to  Base   Register String	}
  rX	   { index to  Index  Register String	}: Byte
 end;

 SibRec	= record
  D,	  { displacement width (bytes) }
  rS,	  { default segment register   }
  rB	  { default base register      }: Byte
 end;

 sxRec = record
  rX,  { to index reg name }
  sF   { multiplier; if	0, ss must be too or illegal}: Byte
 end;

{$I UNA.INC}

var
 Is_386Xtnsn, Is_32BitMax, Is_16BitMin,	Is_SignXtnd,
  Is_MODrmFld, HaveSizePfx, HaveAddrPfx, HaveMRM,
  HaveSIB, FetchFailure, DSiz32, ASiz32, HaveSegPfx,
  HaveInstPfx, HaveMemOprnd : Boolean;

  CodeByte, PfxMax, OprBytes, DataByte,	DLoc, mrmMOD, mrmREG, mrmRM,
  IPfx,	sibSS, sibNDX, sibBAS, SPfx : Byte;
  BytesFetched,	BytesRemaining,	PrefixBytes, CodeSeg,CodeOfs,
  VirtualIP : Word;
  REGOperand, REGSeg, REGBase, REGIndex, REGSegOvr : REGString;
  EAOperand, CodeText, Mnemonic	: OprStr;
  CodeStack : array[1..16] of Byte;
  Opnd : array[1..3]  of OprStr;
  ActGroup : CpuVec;
  OpTags : TagGrp;
  NdxSF	: String[2];
  ByteGate : Gating;
  AddrMode : TAdr;
  WBitMode : WBitStatus;

function FetchByte : Byte;
begin
  FetchFailure := BytesRemaining = 0;
  if not FetchFailure then
   begin
    Inc(BytesFetched);
    CodeStack[BytesFetched] := Mem[CodeSeg:CodeOfs];
    Dec(BytesRemaining);
    Inc(CodeOfs);
   end;
  FetchByte := CodeStack[BytesFetched];
end;

procedure UnFetchCodeByte;
begin
 if BytesFetched > 0 then
  begin
   Dec(BytesFetched);
   Inc(BytesRemaining);
   Dec(CodeOfs);
  end;
end;

procedure FormatText(Locn, SLen	: Byte);
var
 i : Byte;
 W : OprStr;
begin
 W := '';
 for i := Locn to Locn+SLen-1 do W := HexB(CodeStack[i]) + W;
 CodeText := CodeText +	W ;
end;

procedure UnPackModRM(modRM : Byte);
begin
 HaveMRM := True;
 mrmMOD	:= (modRM shr 6) and $03;
 mrmREG	:= (modRM shr 3) and $07;
 mrmRM	:=  modRM and $07;
end;


procedure UnPackSIB(sib	: Byte);
begin
 HaveSIB := True;
 sibSS	 := (sib shr 6)	and $03;
 sibNDX	 := (sib shr 3)	and $07;
 sibBAS	 :=  sib and $07;
end;

procedure MergeActGrp(var Z : CpuVec);
var
 I,J : Byte;
begin
 ActGroup.M := Z.M;
 if Z.T	<> 0 then ActGroup.T :=	Z.T;
 I := ActGroup.F and $7;
 J := Z.F and $7;
 if I <	J then I := J;
 ActGroup.F := ((ActGroup.F or Z.F) and	$F8) or	I;
end;

	{ ------------------------------------------------- }
	{ Formats a Sequence of	Stacked	Bytes as printable  }
	{ Hex in "logical" order - not processor order for  }
	{ use in Operand Expressions.  Lead zero suppressed }
	{ May be SIGNED	or UN-SIGNED			    }
	{ ------------------------------------------------- }

procedure FormatDispl(var Sx:OprStr; Locn, SLen:Byte; Signed:Boolean);
type
  MyWord = record
   case	Byte of
    0: (Ds : ShortInt);
    1: (Db : Byte);
    2: (Dw : Word);
    3: (Di : Integer);
    4: (Dd : LongInt);
    5: (Dv : array[1..4] of Byte);
   end;
var
 W, X :	MyWord;
 I : Byte;
 P : ^MyWord;
 Signit	: Char;
begin
 Sx := '';
 if SLen IN [1,2,4] then
  begin
   P :=	@CodeStack[Locn];
   W.Dd	:= 0; X	:= W;
   with	P^ do
    if Signed then
     begin	{ sign extend for next step }
      case SLen	of
	1: W.Dd	:= Ds;
	2: W.Dd	:= Di;
	4: W.Dd	:= Dd
      end;
      X.Dd := Abs(W.Dd)
     end
    else
     begin	{ zero extend for next step }
      case SLen	of
	1: W.Dd	:= Db;
	2: W.Dd	:= Dw;
	4: W.Dd	:= Dd
      end;
      X.Dd := W.Dd
     end;
   for i := 1 to SLen do Sx := HexB(X.Dv[i]) + Sx;
   if Signed then if X.Dd <> W.Dd then Sx := '-' + Sx
		  else	Sx := '+' + Sx;
end;
end; {FormatDispl}

	{ ------------------------------------ }  {.CP24}
	{ ERROR	- Stacked Code printed as DB's }
	{ ------------------------------------ }

procedure EmitConstants;
begin
 while BytesFetched > 1	do UnFetchCodeByte;
 Mnemonic := 'db';
 CodeText := '';
 HaveInstPfx :=	False;
 CodeText := HexB(CodeStack[1]);
 Opnd[1] := '0'	+ CodeText;
 Opnd[2] := '';
 Opnd[3] := '';
 { Ready to Build and Print Line }
end;

	{ ---------------------	} {.CP08}
	{ Returns Register Name	}
	{ ---------------------	}

function ExtractReg(Am : TAdr; Wbit : WBitStatus; Arg :	Byte) :	RegString;
begin
 ExtractReg := RegList(RegDecode[Am,Wbit,Arg]);
end;

	{ ----------------------------------- }	{.CP12}
	{ Fetches Displacement/Immediate Data }
	{ ----------------------------------- }

function FetchDispl(Width:Byte)	: Byte;	{ Index	to LSB of Displ	}
var
 i, j :	Byte;
begin
 for i := 1 to Width do	j := FetchByte;
 if FetchFailure then FetchDispl := 0
 else FetchDispl := BytesFetched + 1 - Width;
end;

	{ ------------------------------- } {.CP05}
	{ Decodes and Stacks Prefix Bytes }
	{ ------------------------------- }

procedure HandlePrefix;

 procedure StowPrefix;				   {.CP45}
 var
 PfxCls	: 1..4;
 i : Byte;
 begin
  case CodeByte	of
    $F0,$F2..$F3: begin	{LOCK/REPE/REPNE}
		   PfxCls := 1;
		   IPfx	:= CodeByte;
		   HaveInstPfx := True;
		  end;
    $67:	  begin	  {Address Size	Prefix}
		   PfxCls := 2;
		   ASiz32 := not SegDBit;
		   HaveAddrPfx := True;
		  end;
    $66:	  begin	  {Operand Size	Prefix}
		   PfxCls := 3;
		   DSiz32 := not SegDBit;
		   HaveSizePfx := True;
		  end;
    $26,$2E,
    $36,$3E:	  begin	  {Segment Prefix ES,CS,SS,DS}
		   PfxCls := 4;
		   SPfx	:= BytesFetched;
		   HaveSegPfx := True;
		   i :=	CodeByte shr 3 and $03;
		   REGSegOvr :=	RegList(i + 24);
		  end;
    $64,$65:	  begin	  {Segment Prefix FS,GS}
		   PfxCls := 4;
		   SPfx	:= BytesFetched;
		   HaveSegPfx := True;
		   i :=	CodeByte and $07;
		   REGSegOvr :=	RegList(i + 24);
		  end;
  end;
  if PfxCls > PfxMax then
   begin
    Inc(PrefixBytes);
    PfxMax := PfxCls;
    FormatText(BytesFetched,1);
   end
  else
   begin
    UnFetchCodeByte;   { will fetch again later	 }
    EmitConstants;     { emit code stack as DB's }
    PrefixBytes	:= 0; PfxMax :=	0;
    HaveAddrPfx	:= False; HaveSizePfx := False;
   end;
 end; {StowPrefix}

begin {HandlePrefix}				{.CP05}
 if not	FetchFailure then
  if (ActLvl1[CodeByte].F and $7) > Ord(CpuAuth) then
   begin
    EmitConstants; ByteGate := G_ooo
   end
  else
   begin
    StowPrefix;
    CodeByte :=	FetchByte;
    if not FetchFailure	then ByteGate := GateLvl1(CodeByte)
    else ByteGate := G_ooo;
   end;
end; {HandlePrefix}

	{ -------------------------------------- } {.CP44}
	{ Interprets modR/M and	optional SIB to	 }
	{ get operand strings.	Fetches	required }
	{ displacement fields if any.		 }
	{ -------------------------------------- }

procedure DecodeModRM(W	:WBitStatus);
var
 wmrm :	TMrm;
 wsib :	SibRec;
 wsx : sxRec;
 Sx : OprStr;
begin
 if mrmMOD = 3 then EAOperand := ExtractReg(AddrMode,W,mrmRM)
 else
  begin
   wmrm	:= MrmTab[AddrMode,mrmMOD,mrmRM];
   if wmrm.SIB = 1 then
    begin
     DataByte := FetchByte;
     FormatText(BytesFetched,1);
     UnPackSIB(DataByte);
     wsib := SibTab[mrmMOD,sibBAS];
     wsx  := sxTAB[sibSS,sibNDX];
     wmrm.D := wsib.D;
     wmrm.rS :=	wsib.rS;
     wmrm.rB :=	wsib.rB;
     wmrm.rX :=	wsx.rX;
     if	wsx.SF = 0 then
      begin
       NdxSF :=	'';
       wmrm.rX := 30	 { null	register string	}
      end
     else NdxSF	:= '*'+Chr(Ord('0')+wsx.SF);
    end;
   DLoc	:= FetchDispl(wmrm.D);
   FormatText(DLoc,wmrm.D);
   FormatDispl(Sx,DLoc,wmrm.D,True);
   REGSeg   := RegList(wmrm.rS);
   REGBase  := RegList(wmrm.rB);
   REGIndex := RegList(wmrm.rX);
   EAOperand :=	REGBase;
   if Length(REGIndex) > 0 then
    EAOperand := EAOperand + '+' + REGIndex + NdxSF;
   if wmrm.D > 0 then  EAOperand := EAOperand +	Sx;
  end;
 REGOperand := ExtractReg(AddrMode,W,mrmREG);
end;

	{ ---------------------------------- }			{.CP08}
	{ Main Driver for 80386	Operand	Edit }
	{ ---------------------------------- }

procedure Edit386Ops;
var
 i : Byte;
 OpEdit	: TagRec;
 Sx : OprStr;

	procedure EditSplRegs(j	: Byte); { CRx,DRx,TRx }	{.CP04}
	begin
	 Opnd[j] := OpEdit.A + 'r' + Chr(Ord('0')+mrmREG);
	end;

	procedure EditDblRegs(j	: Byte); { EAX..EDI }		{.CP04}
	begin
	 Opnd[j] := RegList(16+mrmREG);
	end;

	procedure EditSegRegs(j	: Byte); { ES:..GS: }		{.CP04}
	begin
	 Opnd[j] := RegList(24+mrmREG);
	end;

	procedure EditLiteral(j	: Byte); { literal data	}	{.CP04}
	begin
	 Opnd[j] := RegList(OpEdit.V);
	end;

	procedure EditGprRegs(j	: Byte); { Gb,Gw,Gd,Gv }	{.CP04}
	begin
	 Opnd[j] := REGOperand;
	end;

	procedure EditJmpDspl(j	: Byte); { Jb, Jv }		{.CP17}
	type
	  MyWord = record
		case Byte of
		0: (Ds : ShortInt);
		1: (Db : Byte);
		2: (Dw : Word);
		3: (Di : Integer);
		4: (Dd : LongInt);
		5: (Dv : array[1..4] of	Byte);
		end;

	var
	 P : ^MyWord;
	 i,k : Byte;
	 l : LongInt;
	 rls: String[3];
	begin
	 rls := RegList(OpEdit.V);
	 if rls[1] = 'b' then
	  begin
	   i :=	FetchDispl(1);
	   FormatText(i,1);
	   P :=	@CodeStack[i];
	   l :=	CodeOfs	+ P^.Ds;
	   P :=	@l;
	   Opnd[j] := HexB(Hi(P^.Dw))+HexB(Lo(P^.Dw));
	  end
	 else
	  begin
	   if ASiz32 then k := 4 else k	:= 2;
	   i :=	FetchDispl(k);		{ Displacement }
	   FormatText(i,k);
	   P :=	@CodeStack[i];
	   if ASiz32 then l := CodeOfs + P^.Dd
		     else l := CodeOfs + P^.Di;
	   P :=	@l;
	   Opnd[j] := '';
	   for i := 1 to k do Opnd[j] := HexB(P^.Dv[i])	+ Opnd[j]
	  end;
	end;

	procedure EditPointer(j	: Byte); { Ap }			{.CP13}
	var
	 i,k : Byte;
	begin
	 if ASiz32 then	k := 4 else k := 2;
	 i := FetchDispl(k);			{ Displacement }
	 FormatText(i,k);
	 FormatDispl(Sx,i,k,False);
	 k := 2;
	 i := FetchDispl(k);			{ Selector }
	 FormatText(i,k);
	 FormatDispl(Opnd[j],i,k,False);
	 Opnd[j] := Opnd[j] + ':' + Sx;
	end;

	procedure EditImmData(j	: Byte);  { Ib,	Iv, Iw }	{.CP17}
	var
	 i,k : Byte;
	 rls: String[3];
	begin
	 rls := RegList(OpEdit.V);
	 case rls[1] of
	   'b':	k := 1;
	   'w':	k := 2;
	   'v':	if DSiz32 then k := 4 else k :=	2;
			  else k := 0
	 end; {case}
	 if k >	0 then
	  begin
	   i :=	FetchDispl(k);
	   FormatText(i,k);
	   FormatDispl(Sx,i,k,Is_SignXtnd);
	   Opnd[j] := Sx;
	  end;
	end;

	procedure EditMemAddr(j	: Byte);			{.CP04}
	begin
	 Opnd[j] := '';
	 if HaveSegPfx	 then Opnd[j] := REGSegOvr + ': ';
	 Opnd[j] := Opnd[j] +'['+ EAOperand + ']';
	 HaveMemOprnd := True;
	end;

	procedure EditOfsDspl(j	: Byte); { Ob, Ov }		{.CP16}
	var
	 i,k : Byte;
	 rls: String[3];
	begin
	 rls := RegList(OpEdit.V);
	 case rls[1] of
	   'b':	k := 2;
	   'v':	if ASiz32 then k := 4 else k :=	2;
			  else k := 0
	 end; {case}
	if k > 0 then
	 begin
	  i := FetchDispl(k);		{ Offset }
	  FormatText(i,k);
	  FormatDispl(Sx,i,k,False);
	  if HaveSegPfx	and (mrmMOD <> 3) then
	    Opnd[j] := REGSegOvr + ':['	+ Sx + ']'
	  else Opnd[j] := '[' +	Sx + ']';
	  HaveMemOprnd := True;
	 end;
	end;

	procedure EditEffAddr(j	: Byte); { Eb, Ew, Ev, Ep }	{.CP22}
	var
	 rls: String[3];
	begin
	 Sx := '';
	 if mrmMOD <> 3	then
	  if j = 1 then
	  begin
	   rls := RegList(OpEdit.V);
	   case	rls[1] of
	     'b': Sx :=	'byte ptr ';
	     'w': Sx :=	'word ptr ';
	     'v': if DSiz32 then Sx := 'dword ptr '
			    else Sx := 'word ptr ';
	     'p': if ASiz32 then Sx := 'fword ptr '
			    else Sx := 'dword ptr ';
	     'q': Sx :=	'qword ptr ';
	     't': Sx :=	'tbyte ptr ';
	     'd': Sx :=	'dword ptr ';
	   end;	{case}
	  end;
	  if HaveSegPfx	and (mrmMOD <> 3) then Sx := REGSegOvr + ':' + Sx;
	  if mrmMOD <> 3 then
	   begin
	    Opnd[j] := Sx + '['+ EAOperand +']';
	    HaveMemOprnd := True;
	   end
	  else Opnd[j] := Sx + EAOperand;
	end;

	procedure EditVarRegs(j	: Byte); { eAX..eDI }		{.CP04}
	begin
	 Opnd[j] := RegList(OpEdit.V+(Ord(DSiz32) shl 3));
	end;

begin	{Edit386Ops}						{.CP22}
 for i := 1 to 3 do
  begin
   OpEdit := OpTags[i];
   Opnd[i] := '';
   case	OpEdit.A of
     'C', 'D',
     'T': EditSplRegs(i);
     'A': EditPointer(i);
     'R': EditDblRegs(i);
     'S': EditSegRegs(i);
     'G': EditGprRegs(i);
     'J': EditJmpDspl(i);
     'I': EditImmData(i);
     'M': EditMemAddr(i);
     'O': EditOfsDspl(i);
     'E': EditEffAddr(i);
     'e': EditVarRegs(i);
     'r': EditLiteral(i);
   end;	{case}
  end;
end; {Edit386Ops}

procedure RemovePrefix;
begin
 while BytesFetched > SPfx do UnFetchCodeByte;
 if SPfx <> 1 then
  begin
   UnFetchCodeByte;
   EmitConstants;
  end
 else
  begin
   CodeByte := CodeStack[SPfx];
   CodeText := '';
   FormatText(SPfx,1);
   ActGroup := ActLvl1[CodeByte];
   Opnd[1] := '';
   Opnd[2] := '';
   Opnd[3] := '';
   Mnemonic := Mnem386(ActGroup.M);
  end;
end;

	{ ---------------------------------- } {.CP05}
	{ Main Driver for 80386	Instructions }
	{ ---------------------------------- }

procedure Handle386Op;
var
 i : Byte;
 OGate : Gating;
	procedure UpdateTags(n : Byte);
	var
	 i : Byte;
	begin
	  for i	:= 1 to	3 do
	   if OpType386[n,i].A <> ' ' then OpTags[i] :=	OpType386[n,i];
	end;

	procedure HandleOpMRM;				{.CP17}
	begin
	 DataByte := FetchByte;
	 if not	FetchFailure then
	  begin
	   FormatText(BytesFetched,1);
	   UnPackModRM(DataByte);
	   OGate := ByteGate;
	   ByteGate := GateLvl3(ByteGate,mrmREG);
	   if ByteGate = G_Hit then
	    begin
	     MergeActGrp(ActLvl3[OGate,mrmREG]);
	     UpdateTags(ActGroup.T);
	    end;
	  end;
	end; {HandleOpMRM}

	procedure HandleOp0Fx;				{.CP19}
	var
	 RowNdx	: Gate_2;
	 ColNdx	: $0..$F;
	begin
	 CodeByte := FetchByte;
	 if not	FetchFailure then
	  begin
	   FormatText(BytesFetched,1);
	   RowNdx := GateLvX2[(CodeByte	shr 4) and $0F];
	   ColNdx := CodeByte and $0F;
	   ByteGate := GateLvl2(RowNdx,ColNdx);
	   case	ByteGate of
	     G_Hit: begin
		     MergeActGrp(ActLvl2[RowNdx,ColNdx]);
		     UpdateTags(ActGroup.T);
		    end;
	     G_RM6..G_RM8: HandleOpMRM;
	   end;	{case}
	  end;
	end; {HandleOp0FX}

begin  {Handle386Op}				{.CP34}
 FormatText(BytesFetched,1);
 with ActLvl1[CodeByte]	do
  begin
   ActGroup.F := F;
   ActGroup.M := M;
   ActGroup.T := T;
   OpTags := OpType386[ActGroup.T];
  end;
 case ByteGate of
   G_RM1..G_RM9: HandleOpMRM;
   G_0Fx: HandleOp0Fx;
   G_Hit:;
 end;
 if (ActGroup.F	and $7)	> Ord(CpuAuth) then ByteGate :=	G_ooo;
 if not	FetchFailure and (ByteGate <> G_ooo) then
  begin
   Is_386Xtnsn := (ActGroup.F and _386Xtnsn) = _386Xtnsn;
   Is_32BitMax := (ActGroup.F and _32BitMax) = _32BitMax;
   Is_16BitMin := (ActGroup.F and _16BitMin) = _16BitMin;
   Is_SignXtnd := (ActGroup.F and _SignXtnd) = _SignXtnd;
   Is_MODrmFld := (ActGroup.F and _MODrmFld) = _MODrmFld;
   if Is_MODrmFld and not HaveMRM then
    begin
     CodeByte := FetchByte;
     if	not FetchFailure then UnPackModRM(CodeByte);
     FormatText(BytesFetched,1);
    end;
   if Is_32BitMax or Is_16BitMin then WBitMode := W1;
  end;
 if FetchFailure or (ByteGate =	G_ooo) or (ActGroup.M =	0) then
  EmitConstants
 else
  begin
   if DSiz32 and Is_386Xtnsn then Mnemonic := Mnem386(ActGroup.M+1)
			     else Mnemonic := Mnem386(ActGroup.M);
   if HaveMRM then DecodeModRM(WBitMode);
   Edit386Ops;
   if HaveSegPfx and (not HaveMemOprnd)	then RemovePrefix
   else
    begin
     EmuFlag :=	0;
     if	(BytesFetched =	2) and (CodeStack[1] = $CD) then
      case CodeStack[2]	of
	$34..$3B,
	$3E: begin
	      EmuFlag := CodeStack[2];
	      Opnd[3] := ' F-P Emulator';
	     end;
	$3C: begin
	      EmuFlag := CodeStack[2];
	      Opnd[3] := ' Emulated SEG Prefix';
	     end;
	$3D: Opnd[3] :=	' Emulated FWAIT ';
       end;
    end;
    { emit instruction }
end;
end; {Handle386Op}

	{ ----------------------------------------- }		{.CP50}
	{ Main driver for Co-Processor Instructions }
	{ ----------------------------------------- }

procedure Handle387Op(Emulation	: Boolean);
const T	: array[2..10] of Byte = (41,37,39,39,35,40,35,40,41);
var
 esc,flaga,flagop :byte;
 MpuAux	: MpuVec;
 stkr :	char;
begin
 esc :=	CodeByte and $07;
 if not	Emulation then FormatText(BytesFetched,1);
 CodeByte := FetchByte;
 if not	FetchFailure then UnPackModRM(CodeByte);
 FormatText(BytesFetched,1);
 if mrmMOD = 3 then
  begin
   MpuAux   := MpuM11[esc,mrmREG];    {flags,link}
   MpuAux.M := MpuOv[MpuAux.M,mrmRM]  {	mnemonic }
  end
 else MpuAux   := MpuEA[esc,mrmREG];	 {flags,mnemonic}
 flaga	:= MpuAux.F shr	4;
 if flaga = 0 then EmitConstants
 else
  begin
   flagop := MpuAux.F and $0F;
   stkr	  := Chr(Ord('0')+mrmRM);
   case	flagop of
     0:	    Opnd[1] := '';
     1:	    Opnd[1] := 'ax';
     2..10: begin
	     DecodeModRM(W0);
	     OpTags := OpType386[96];
	     OpTags[1].V := T[flagop];
	     Edit386Ops;
	    end;
     11:     Opnd[1] :=	'st('+stkr+')';
     12:     Opnd[1] :=	'st('+stkr+'),st';
     13:     Opnd[1] :=	'st,st('+stkr+')';
   end;
   Mnemonic := Mnem387(MpuAux.M);
   Opnd[2] := '';
   Opnd[3] := '';
   { Emit Instruction Here }
  end;
end; {Handle387Op}

	{ ----------------------------------------- }	{.CP17}
	{ Main Driver for ALL Instruction Sequences }
	{ ----------------------------------------- }

procedure HandleInstruction;
var
  HandleCount: Byte;
begin
 ByteGate := GateLvl1(CodeByte);
 HandleCount := 0;
 while (ByteGate = G_Pfx) and (HandleCount < 32) do
 begin
   HandlePrefix;
   Inc(HandleCount);
 end;
 if ASiz32 then	AddrMode := Adr32 else AddrMode	:= Adr16;
 if not	FetchFailure	then
  case ByteGate	of
    G_RM1..G_0Fx: Handle386Op;	{Get Op	and modR/M}
    G_387: Handle387Op(False); { Ndp Ops   }
  else	EmitConstants {Invalid Op Codes	}
  end;
end;

	{ -------------------------------- }		{.CP34}
	{ Initialize for Instruction Fetch }
	{ -------------------------------- }

procedure StartOpFetch;	{ Initializes for next Instruction }
begin
 Is_386Xtnsn :=	False;
 Is_32BitMax :=	False;
 Is_16BitMin :=	False;
 Is_SignXtnd :=	False;
 Is_MODrmFld :=	False;
 HaveSizePfx :=	False;
 HaveAddrPfx :=	False;
 HaveMRM := False;
 HaveSIB := False;
 FetchFailure := False;
 HaveMemOprnd := False;
 HaveInstPfx :=	False;
 HaveSegPfx := False;
 ASiz32	:= SegDBit;
 DSiz32	:= SegDBit;
 CodeByte := 0;
 OprBytes := 0;
 BytesFetched := 0;
 mrmMOD	:= 0;
 mrmREG	:= 0;
 mrmRM := 0;
 sibSS := 0;
 sibNDX	:= 0;
 sibBAS	:= 0;
 PfxMax	:= 0;
 PrefixBytes :=	0;
 DLoc := 0;
 SPfx := 0;
 CodeText := '';
 NdxSF := '';
 EAOperand := '';
 REGSeg	:= '';
 REGBase := '';
 REGIndex := '';
 REGOperand := '';
 REGSegOvr := '';
 WBitMode := W0;
 AddrMode := Adr16;
 ActGroup.F := 0;
 ActGroup.M := 0;
 ActGroup.T := 0;
 VirtualIP := CodeOfs;
 CodeByte := FetchByte;
end;

	{ -------------------------------------	}	{.CP11}
	{ Prototype For	Disassembly of One Line	}
	{ -------------------------------------	}

procedure DisassembleLine;
begin
 StartOpFetch;
 case EmuFlag of	   {Handle Turbo F-P Emulator Expansions}
   $34..$3B : begin
	       UnFetchCodeByte;
	       CodeByte	:= EmuFlag + $A4;
	       Handle387Op(True);
	       Mnemonic	:= 'EMU_'+Mnemonic;
	       EmuFlag := 0;
	       Opnd[3] := '';
	      end;
   $3C:	begin
	 HaveSegPfx := True;
	 REGSegOvr := RegList(24+(CodeByte shr 6 xor 3));
	 Handle387Op(False);
	 Mnemonic := 'EMU_'+Mnemonic;
	 EmuFlag := 0;
	 Opnd[3] := '';
	end;
   $3E:	begin  { DB xxH	for parameters }
	 EmitConstants;
	 Opnd[3] := 'Fast Path Emulations';
	 EmuFlag := 0;
	end;
 else
  begin
   HandleInstruction;
   if HaveInstPfx then
     Mnemonic := Mnem386(ActLvl1[IPfx].M) + ' '	+ Mnemonic;
  end;
 end; {case}
end;


function UnAssemble(var	U : Pointer) : String;
var
 SubStr:String;
begin
 IF NOT	(CpuAuth IN [C086..C386]) THEN CpuAuth := C086;
 CodeSeg := PtrRec(U).Seg;
 CodeOfs := PtrRec(U).Ofs;
 BytesRemaining	:= 32;
 VirtualIP := PtrRec(U).Ofs;
 DisAssembleLine;
 PtrRec(U).Ofs := PtrRec(U).Ofs	+ BytesFetched;
 SubStr	:= #32#32#32#32#32#32#32#32#32#32#32#32#32#32#32 + Mnemonic;
 if Opnd[1] <> '' then SubStr := SubStr	+ ' '+ Opnd[1];
 if Opnd[2] <> '' then SubStr := SubStr	+ ','+ Opnd[2];
 if Opnd[3] <> '' then SubStr := SubStr	+ ','+ Opnd[3];
 if CodeText[0]	> #14 then
 begin
  CodeText[0] := #15;
  CodeText[15] := '+';
 end;
 Move(CodeText[1],SubStr[1],Byte(CodeText[0]));
 UnAssemble := SubStr;
end;
end.
