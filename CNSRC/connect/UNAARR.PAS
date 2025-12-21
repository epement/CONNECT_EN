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

const
  AMnem386 : ARRAY[1..170] OF STRING[6] = (		{.CP32}

	{001}  'aaa',	 'aad',	   'aam',    'aas',    'adc',	 'add',
	{007}  'and',	 'arpl',   'bound',  'bsf',    'bsr',	 'bt',
	{013}  'btc',	 'btr',	   'bts',    'call',   'cbw',	 'cwde',
	{019}  'clc',	 'cld',	   'cli',    'clts',   'cmc',	 'cmp',
	{025}  'cmpsb',	 'cmpsw',  'cmpsd',  'cwd',    'cdq',	 'daa',
	{031}  'das',	 'dec',	   'div',    'enter',  'hlt',	 'idiv',
	{037}  'imul',	 'in',	   'inc',    'insb',   'insw',	 'insd',
	{043}  'int',	 'into',   'iret',   'jb',     'jbe',	 'jcxz',
	{049}  'jecxz',	 'jle',	   'jmp',    'jnb',    'jnbe',	 'jnl',
	{055}  'jnle',	 'jno',	   'jnp',    'jns',    'jnz',	 'jo',
	{061}  'jp',	 'js',	   'jz',     'lahf',   'lar',	 'lds',
	{067}  'lea',	 'leave',  'les',    'lfs',    'lgdt',	 'lgs',
	{073}  'lidt',	 'lldt',   'lmsw',   'lock',   'lodsb',	 'lodsw',
	{079}  'lodsd',	 'loop',   'loope',  'loopne', 'lsl',	 'lss',
	{085}  'ltr',	 'mov',	   'movsb',  'movsw',  'movsd',	 'movsx',
	{091}  'movzx',	 'mul',	   'neg',    'nop',    'not',	 'or',
	{097}  'out',	 'outsb',  'outsw',  'outsd',  'pop',	 'popa',
	{103}  'popad',	 'popf',   'popfd',  'push',   'pusha',	 'pushad',
	{109}  'pushf',	 'pushfd', 'rcl',    'rcr',    'rep',	 'repne',
	{115}  'ret',	 'retf',   'rol',    'ror',    'sahf',	 'sar',
	{121}  'sbb',	 'scasb',  'scasw',  'scasd',  'segcs',	 'segds',
	{127}  'seges',	 'segfs',  'seggs',  'segss',  'setb',	 'setbe',
	{133}  'setl',	 'setle',  'setnb',  'setnbe', 'setnl',	 'setnle',
	{139}  'setno',	 'setnp',  'setns',  'setnz',  'seto',	 'setp',
	{145}  'sets',	 'setz',   'sgdt',   'shl',    'shld',	 'shr',
	{151}  'shrd',	 'sidt',   'sldt',   'smsw',   'stc',	 'std',
	{157}  'sti',	 'stosb',  'stosw',  'stosd',  'str',	 'sub',
	{163}  'test',	 'verr',   'verw',   'wait',   'xchg',	 'xlatb',
	{169}  'xor',	 'jl');

   AMnem387 : ARRAY[1..76] OF STRING[7] = (			{.CP15}

	{01}  'f2xm1',	'fabs',	  'fadd',   'faddp',   'fbld',	 'fbstp',
	{07}  'fchs',	'fclex',  'fcom',   'fcomp',   'fcompp', 'fcos',
	{13}  'fdecstp','fdisi',  'fdiv',   'fdivp',   'fdivr',	 'fdivrp',
	{19}  'feni',	'ffree',  'fiadd',  'ficom',   'ficomp', 'fidiv',
	{25}  'fidivr',	'fild',	  'fimul',  'fincstp', 'finit',	 'fist',
	{31}  'fistp',	'fisub',  'fisubr', 'fld',     'fld1',	 'fldcw',
	{37}  'fldenv',	'fldg2',  'fldl2e', 'fldl2t',  'fldn2',	 'fldpi',
	{43}  'fldz',	'fmul',	  'fmulp',  'fnop',    'fpatan', 'fprem',
	{49}  'fprem1',	'fptan',  'frndint','frstor',  'fsave',	 'fscale',
	{55}  'fsetpm',	'fsin',	  'fsincos','fsqrt',   'fst',	 'fstcw',
	{61}  'fstenv',	'fstp',	  'fstsw',  'fsub',    'fsubp',	 'fsubr',
	{67}  'fsubrp',	'ftst',	  'fucom',  'fucomp',  'fucompp','fxam',
	{73}  'fxch',	'fxtract','fyl2x',  'fyl2xp1');

  AGateLvl1 : ARRAY[0..255] of Gating = (
	{00}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{08}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_0Fx,
	{10}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{18}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{20}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Pfx, G_Hit,
	{28}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Pfx, G_Hit,
	{30}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Pfx, G_Hit,
	{38}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Pfx, G_Hit,
	{40}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{48}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{50}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{58}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{60}	G_Hit, G_Hit, G_Hit, G_Hit, G_Pfx, G_Pfx, G_Pfx, G_Pfx,
	{68}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{70}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{78}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{80}	G_RM1, G_RM1, G_ooo, G_RM1, G_Hit, G_Hit, G_Hit, G_Hit,
	{88}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{90}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{98}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{A0}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{A8}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{B0}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{B8}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{C0}	G_RM2, G_RM2, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{C8}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{D0}	G_RM2, G_RM2, G_RM2, G_RM2, G_Hit, G_Hit, G_ooo, G_Hit,
	{D8}	G_387, G_387, G_387, G_387, G_387, G_387, G_387, G_387,
	{E0}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{E8}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit,
	{F0}	G_Pfx, G_ooo, G_Pfx, G_Pfx, G_Hit, G_Hit, G_RM3, G_RM9,
	{F8}	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_Hit, G_RM4, G_RM5);

   AGateLvl2 :	ARRAY[Row_0..Row_X] OF
		ARRAY[0..15] OF	Gating = (

	{[_0,0]} (G_RM6,G_RM7,G_Hit,G_Hit,G_ooo,G_ooo,G_Hit,G_ooo,
	{[_0,8]}  G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo),

	{[_2,0]} (G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_ooo,G_Hit,G_ooo,
	{[_2,8]}  G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo),

	{[_8,0]} (G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,
	{[_8,8]}  G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit),

	{[_9,0]} (G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,
	{[_9,8]}  G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit),

	{[_A,0]} (G_Hit,G_Hit,G_ooo,G_Hit,G_Hit,G_Hit,G_ooo,G_ooo,
	{[_A,8]}  G_Hit,G_Hit,G_ooo,G_Hit,G_Hit,G_Hit,G_ooo,G_Hit),

	{[_B,0]} (G_ooo,G_ooo,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit,
	{[_B,8]}  G_ooo,G_ooo,G_RM8,G_Hit,G_Hit,G_Hit,G_Hit,G_Hit),

	{[_X,0]} (G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,
	{[_X,8]}  G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo,G_ooo));

   AGateLvl3 :	ARRAY[G_RM1..G_RM9] OF
		ARRAY[0..7] OF Gating =	(

	{[_1,0]}  (G_Hit, G_Hit, G_Hit,	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit),
	{[_2,0]}  (G_Hit, G_Hit, G_Hit,	G_Hit, G_Hit, G_Hit, G_ooo, G_Hit),
	{[_3,0]}  (G_Hit, G_ooo, G_Hit,	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit),
	{[_4,0]}  (G_Hit, G_Hit, G_ooo,	G_ooo, G_ooo, G_ooo, G_ooo, G_ooo),
	{[_5,0]}  (G_Hit, G_Hit, G_Hit,	G_Hit, G_Hit, G_Hit, G_Hit, G_ooo),
	{[_6,0]}  (G_Hit, G_Hit, G_Hit,	G_Hit, G_Hit, G_Hit, G_ooo, G_ooo),
	{[_7,0]}  (G_Hit, G_Hit, G_Hit,	G_Hit, G_Hit, G_ooo, G_Hit, G_ooo),
	{[_8,0]}  (G_ooo, G_ooo, G_ooo,	G_ooo, G_Hit, G_Hit, G_Hit, G_Hit),
	{[_9,0]}  (G_Hit, G_ooo, G_Hit,	G_Hit, G_Hit, G_Hit, G_Hit, G_Hit));

  ARegList : ARRAY[00..41] OF STRING[3]	= (			{.CP12}

	{00}  'al',	{01}  'cl',	{02}  'dl',	{03}  'bl',
	{04}  'ah',	{05}  'ch',	{06}  'dh',	{07}  'bh',
	{08}  'ax',	{09}  'cx',	{10}  'dx',	{11}  'bx',
	{12}  'sp',	{13}  'bp',	{14}  'si',	{15}  'di',
	{16}  'eax',	{17}  'ecx',	{18}  'edx',	{19}  'ebx',
	{20}  'esp',	{21}  'ebp',	{22}  'esi',	{23}  'edi',
	{24}  'es',	{25}  'cs',	{26}  'ss',	{27}  'ds',
	{28}  'fs',	{29}  'gs',	{30}  '',	{31}  '1',
	{32}  '3',	{33}  'a',	{34}  'b',	{35}  'd',
	{36}  'p',	{37}  's',	{38}  'v',	{39}  'w',
	{40}  'q',	{41}  't');

var
  F: File;
begin
  Assign(F, 'D:\WORK\CONNECT\MNEM386.BIN');
  Rewrite(F, 1);
  BlockWrite(F, AMnem386, SizeOf(AMnem386));
  Close(F);

  Assign(F, 'D:\WORK\CONNECT\MNEM387.BIN');
  Rewrite(F, 1);
  BlockWrite(F, AMnem387, SizeOf(AMnem387));
  Close(F);

  Assign(F, 'D:\WORK\CONNECT\GATELVL1.BIN');
  Rewrite(F, 1);
  BlockWrite(F, AGateLvl1, SizeOf(AGateLvl1));
  Close(F);

  Assign(F, 'D:\WORK\CONNECT\GATELVL2.BIN');
  Rewrite(F, 1);
  BlockWrite(F, AGateLvl2, SizeOf(AGateLvl2));
  Close(F);

  Assign(F, 'D:\WORK\CONNECT\GATELVL3.BIN');
  Rewrite(F, 1);
  BlockWrite(F, AGateLvl3, SizeOf(AGateLvl3));
  Close(F);

  Assign(F, 'D:\WORK\CONNECT\REGLIST.BIN');
  Rewrite(F, 1);
  BlockWrite(F, ARegList, SizeOf(ARegList));
  Close(F);
end.