Unit DisAsm;
{$F+,O+,S-,I-,R-,N-,E-,X+}
interface
type
 TStatus = Record
	     ax_,bx_,cx_,dx_,si_,
	     di_,bp_,sp_,ds_,es_,
	     ss_,cs_,fs_,ip_,fl_ : Word;
	  end;

 var
  CPUStatus : TStatus;

 function DisasmCom(var PMemoryBuf : Pointer;DrawCS: Boolean) : String;
 function DisasmBack(Var P : Pointer;DrawCS: Boolean) : String;
 function GetMemValue(PMemoryBuf : Pointer) : String;
 procedure StringConvert( Var SStr,DStr; Count : Word);
 procedure CPU_Test;

implementation

uses UnAsm, TPString, CPUType, Defaults;

type
 PType          = record
		    Offset,
		    Segment : Word;
		  end;
 ComStr         = String[26];
 RegStr         = String[2];
 ByteArray      = Array[0 .. 5] of Byte;
 TByteArray     = ^ByteArray;
 Byte2Type      =
  (R8_M8__Reg8,             R16_M16__Reg16,          Reg8__R8_M8,
   Reg16__R16_M16,          al_Data_8,               ax_Data_16,
   None,                    IP__Inc8,                IP__Inc16,
   IP__New,                 POP__Val,                N__Proc,
   al_Port,                 ax_Port,                 Port_al,
   Port_ax,                 R16_M16__SR,             SR__R16_M16,
   Reg16__Mem,              R16_M16,                 Addr16_AL,
   Addr16_AX,               AL_Addr16,               AX_Addr16,
   Pop_Val,                 Data8,                   Data16,
   _Data16,                 Data16_Data8,            Reg16__Data16,
   Reg16_Reg16__Data16,     Reg16_Reg16__Data8,      Reg16__M32,
   M8__Data8,               M16__Data16,             Cod_R8_M8__Data8,
   Cod_R16_M16__Data16,     Cod_R16_M16__Data_S,     Shift_R8_M8__Val1,
   Shift_R16_M16__Val1,     Shift_R8_M8__Data8,      Shift_R16_M16__Data16,
   Shift_R8_M8__CL,         Shift_R16_M16__CL,       OpCode__R_M,
   Test_R8_M8__Data8,       Test_R16_M16__Data16,    Inc_R8_M8__Data8,
   Inc_R16_M16__Data16);

procedure StringConvert( Var SStr,DStr; Count : Word);
begin
  asm
	     jmp @Start

@Conv:       db '0123456789ABCDEF'

@Str:        mov ah,al
	     and al,0fh
	     SEGCS
	     xlat
	     xchg ah,al
	     and al,0f0h
	     shr al,1
	     shr al,1
	     shr al,1
	     shr al,1
	     SEGCS
	     xlat
	     retn

@Start:      push ds
	     lds si,SStr
	     les di,DStr

	     mov ax,Count
	     shl ax,1
	     shl ax,1
	     add ax,5
	     mov byte ptr es:[di],al {Length}

	     inc di
	     mov bx, OFFSET @Conv

	     mov ax,si
	     xchg ah,al
	     push ax
	     call @Str
	     stosw
	     pop ax
	     mov al,ah
	     call @Str
	     stosw

	     mov al,20h {' '}
	     stosb

             mov cx,Count
@l0:         lodsb
             call @Str
             stosw
             mov al,20h {' '}
             stosb
             loop @l0

	     sub si,Count
	     mov cx,Count
	     rep movsb
	     pop ds
  end;
end;
{
procedure CPU_Test;
var
  CPU: Word;
begin
 if DisableSysInfo then CPU := i386dxr
 else CPU := CPU_Type;
 case CPU of
   i88, i86, V20, V30: CpuAuth := C086;
   i188, i186: CpuAuth := C186;
   i286: CpuAuth := C286;
   else CpuAuth := C386;
 end;
end;
}
procedure CPU_Test;
begin
 if DisableSysInfo then CPU := i80386dx
 else CPU_Type;
 case CPU of
   i8088, i8086, necV20, necV30: CpuAuth := C086;
   i80188, i80186: CpuAuth := C186;
   i80286: CpuAuth := C286;
   else CpuAuth := C386;
 end;
end;

  function HexSI(B : Byte) : string;
  begin
    if ShortInt(B) < 0 then HexSI := '-'+HexB(Byte(abs(ShortInt(B))))
		       else HexSI := '+'+HexB(B);
  end;

  function HexI(W : Word) : string;
  begin
    if Integer(W) < 0 then HexI := '-'+HexW(Word(abs(Integer(W))))
		      else HexI := '+'+HexW(W);
  end;

function DisasmCom(var PMemoryBuf : Pointer;DrawCS: Boolean) : String;
type
 ControlFlagsType = record
  OF_, CF_, ZF_, SF_, PF_ : Boolean;
 end;

var
 TByte2         : Byte2Type;
 CountPref,
 Index,I        : Byte;
 Address        : Word absolute PMemoryBuf;
 SavePtr        : Pointer;
 PByte          : TByteArray;
 SubStr,Prefix,
 PrefSeg,Com    : ComStr;
 Command        : String[80];

function SegmentAnalise(B : Byte) : RegStr;
begin
 case B and $07 of
  0     : SegmentAnalise := 'es';
  1     : SegmentAnalise := 'cs';
  2     : SegmentAnalise := 'ss';
  3     : SegmentAnalise := 'ds';
  4 .. 7: SegmentAnalise := '??';
 end;{case}
end;

function Reg16Analise(B : Byte): RegStr;
begin
 case B and $07 of
  0     : Reg16Analise := 'ax';
  1     : Reg16Analise := 'cx';
  2     : Reg16Analise := 'dx';
  3     : Reg16Analise := 'bx';
  4     : Reg16Analise := 'sp';
  5     : Reg16Analise := 'bp';
  6     : Reg16Analise := 'si';
  7     : Reg16Analise := 'di';
 end;{case}
end;

function Reg8Analise(B : Byte): RegStr;
begin
 case B and $07 of
  0     : Reg8Analise := 'al';
  1     : Reg8Analise := 'cl';
  2     : Reg8Analise := 'dl';
  3     : Reg8Analise := 'bl';
  4     : Reg8Analise := 'ah';
  5     : Reg8Analise := 'ch';
  6     : Reg8Analise := 'dh';
  7     : Reg8Analise := 'bh';
 end;{case}
end;

function P_T : ComStr;
begin
 if PByte^[0] in [$FE,$FF,$F6,$F7,$C7,$C6] then
  begin
   case PByte^[1] and $38 of
    0,8,$30 : if PByte^[0] and $01 = 1 then P_T := 'word ptr '+ PrefSeg
                                       else P_T := 'byte ptr '+ PrefSeg;
   else P_T := PrefSeg;
   end;
  end
 else P_T := PrefSeg;
end;

function R_M : ComStr;
begin
 case PByte^[1] and $07 of
   0     : R_M := P_T + '[bx+si';
   1     : R_M := P_T + '[bx+di';
   2     : R_M := P_T + '[bp+si';
   3     : R_M := P_T + '[bp+di';
   4     : R_M := P_T + '[si';
   5     : R_M := P_T + '[di';
   6     : if (PByte^[1] and $C0) = 0 then
            begin
             R_M := P_T + '['+ HexW(PByte^[2]+$100*PByte^[3]);
            end
           else R_M := P_T + '[bp';
   7     : R_M := P_T + '[bx';
 end;{case}
end;

function Mode__R_M : ComStr;
begin
 case PByte^[1] and $C0 of
  $0    : begin
           if (PByte^[1] and $07) = 6 then Index := 4
                                      else Index := 2;
           Mode__R_M := R_M +']';
          end;
  $40   : begin
           Index := 3;
           Mode__R_M := R_M + HexSI(PByte^[2])+']';
          end;
  $80   : begin
           Index := 4;
           Mode__R_M := R_M + HexI(PByte^[2]+$100*PByte^[3])+']';
          end;
  $C0   : begin
           Index := 2;
	   if (PByte^[0] and 01) = 0 then Mode__R_M := Reg8Analise(PByte^[1])
                                     else Mode__R_M := Reg16Analise(PByte^[1]);
          end;
 end;{case}
end;

function Byte2Detect : Byte2Type;
begin
 case PByte^[0] and $07 of
  0     : Byte2Detect := R8_M8__Reg8;
  1     : Byte2Detect := R16_M16__Reg16;
  2     : Byte2Detect := Reg8__R8_M8;
  3     : Byte2Detect := Reg16__R16_M16;
  4     : Byte2Detect := al_Data_8;
  5     : Byte2Detect := ax_Data_16;
  6,7   : Byte2Detect := None;
 end;{case}
end;

function Byte2DetectTest : Byte2Type;
begin
 case PByte^[0] and $03 of
  0     : Byte2DetectTest := R8_M8__Reg8;
  1     : Byte2DetectTest := R16_M16__Reg16;
  2     : Byte2DetectTest := Reg8__R8_M8;
  3     : Byte2DetectTest := Reg16__R16_M16;
 end;{case}
end;

function Code_ : ComStr;
begin
 case PByte^[1] and $38 of
  $00 : Code_ := 'add ';
  $08 : Code_ := 'or ';
  $10 : Code_ := 'adc ';
  $18 : Code_ := 'sbb ';
  $20 : Code_ := 'and ';
  $28 : Code_ := 'sub ';
  $30 : Code_ := 'xor ';
  $38 : Code_ := 'cmp ';
 end;{case}
end;

function Shift_ : ComStr;
begin
 case PByte^[1] and $38 of
  $00 : Shift_ := 'rol ';
  $08 : Shift_ := 'ror ';
  $10 : Shift_ := 'rcl ';
  $18 : Shift_ := 'rcr ';
  $20 : Shift_ := 'shl ';
  $28 : Shift_ := 'shr ';
  $30 : Shift_ := '???';
  $38 : Shift_ := 'sar ';
 end;{case}
end;

function Test_ : ComStr;
begin
 case PByte^[1] and $38 of
  $00 : Test_ := 'test ';
  $08 : Test_ := '???';
  $10 : Test_ := 'not ';
  $18 : Test_ := 'neg ';
  $20 : Test_ := 'mul ';
  $28 : Test_ := 'imul ';
  $30 : Test_ := 'div ';
  $38 : Test_ := 'idiv ';
 end;{case}
end;

function OpCode_ : ComStr;
begin
 OpCode_ := HexB(((PByte^[1] shr 3) and $07) or ((PByte^[0] shl 3) and $38));
end;

function Inc_ : ComStr;
begin
 case PByte^[1] and $38 of
  $00 : Inc_ := 'inc ';
  $08 : Inc_ := 'dec ';
  $10 : Inc_ := 'call word ptr ';
  $18 : Inc_ := 'call dword ptr ';
  $20 : Inc_ := 'jmp word ptr ';
  $28 : Inc_ := 'jmp dword ptr ';
  $30 : Inc_ := 'push ';
  $38 : Inc_ := '???';
 end;{case}
end;

procedure PrefixAnalise(var Prefix,PrefSeg : ComStr);
Const
 SegSet  = [$26,$2E,$36,$3E];
 RepSet  = [$F2,$F3];
 LockSet = [$F0];
var
 PrefSet  : Set of Byte;
 PrefRep,
 PrefLock : ComStr;
begin
 CountPref := 0;
 PrefRep := '';
 PrefLock :='';
 PrefSeg :='';
 PByte := PMemoryBuf;
 PrefSet := [$26,$2E,$36,$3E,$F0,$F2,$F3];
 while PByte^[0] in PrefSet do
   begin
     case PByte^[0] of
      $26       : PrefSeg  := 'es:';
      $2E       : PrefSeg  := 'cs:';
      $36       : PrefSeg  := 'ss:';
      $3E       : PrefSeg  := 'ds:';
      $F0       : PrefLock := 'lock ';
      $F2       : PrefRep  := 'repne ';
      $F3       : begin
		    if PByte^[1] in
                     [$A6,$A7,$AE,$AF] then PrefRep  := 'repe '
                    else PrefRep  := 'rep ';
                  end;
     end;{case}
     if PByte^[0] in SegSet then PrefSet := PrefSet - SegSet
     else if PByte^[0] in RepSet then PrefSet := PrefSet - RepSet
          else if PByte^[0] in LockSet then PrefSet := PrefSet - LockSet;
     Inc(Address);
     Inc(CountPref);
     PByte := PMemoryBuf;
   end;
  Prefix := PrefLock + PrefRep;
end;

procedure GetControlFlags(Var ControlFlags : ControlFlagsType);
begin
 with CPUStatus,ControlFlags do
  begin
   OF_ := (fl_ and $800) = $800;
   CF_ := (fl_ and $1) = $1;
   ZF_ := (fl_ and $40) = $40;
   SF_ := (fl_ and $80) = 80;
   PF_ := (fl_ and $4) = $4;
  end;
end;

function JumpDirection : Char;
var
 Condition,
 Direction : Boolean;
 ControlFlags : ControlFlagsType;
begin
 if PByte^[0] in [$70 .. $7F, $E0 .. $E3, $E8, $E9, $EB] then
  begin
    GetControlFlags(ControlFlags);
    with ControlFlags do
     case PByte^[0] of
      $70, $71 : Condition := OF_;
      $72, $73 : Condition := CF_;
      $74, $75 : Condition := ZF_;
      $76, $77 : Condition := CF_ or ZF_;
      $78, $79 : Condition := SF_;
      $7A, $7B : Condition := PF_;
      $7C, $7D : Condition := SF_ <> OF_;
      $7E, $7F : Condition := (SF_ <> OF_) or ZF_;
      $E0      : Condition := not ZF_ and (CPUStatus.cx_ <> 1);
      $E1      : Condition := ZF_ and (CPUStatus.cx_ <> 1);
      $E2      : Condition := CPUStatus.cx_ <> 1;
      $E3      : Condition := CPUStatus.cx_ = 0;
     else Condition := True;
     end {case};
    if PByte^[0] in [$70 .. $7F] then
     Condition := Condition xor ((PByte^[0] and 1) = 1);
    case PByte^[0] of
     $70 .. $7F,
     $E0 .. $E3,
     $EB      :  Direction := (PByte^[1] and $80) = $80;
     $E8, $E9 :  Direction := (PByte^[2] and $80) = $80;
    else;
    end {case};
    if Condition then
     begin
      if Direction then JumpDirection := ''
                   else JumpDirection := '';
     end
    else JumpDirection := ' ';
  end
 else JumpDirection := ' ';
end;

procedure Byte1Analise( var Command : ComStr;
                        var TByte2  : Byte2Type );
begin
 Index := 1;
 PByte := PMemoryBuf;
 case PByte^[0] of
   $0 .. $5     : begin
                    Command := 'add ';
                    TByte2 := Byte2Detect;
                  end;
   $6           : begin
		    Command := 'push es';
		    TByte2 := None;
		  end;
   $7           : begin
		    Command := 'pop es';
		    TByte2 := None;
		  end;
   $8 .. $0D    : begin
                    Command := 'or ';
                    TByte2 := Byte2Detect;
                  end;
   $0E          : begin
                    Command := 'push cs';
		    TByte2 := None;
                  end;
   $0F          : begin
                    Command := '???';
		    TByte2 := None;
                  end;
   $10..$15     : begin
                    Command := 'adc ';
                    TByte2 := Byte2Detect;
                  end;
   $16          : begin
                    Command := 'push ss';
		    TByte2 := None;
                  end;
   $17          : begin
                    Command := 'pop ss';
		    TByte2 := None;
                  end;
   $18 .. $1D   : begin
                    Command := 'sbb ';
                    TByte2 := Byte2Detect;
                  end;
   $1E          : begin
		    Command := 'push ds';
		    TByte2 := None;
		  end;
   $1F          : begin
		    Command := 'pop ds';
		    TByte2 := None;
		  end;
   $20 .. $25   : begin
                    Command := 'and ';
                    TByte2 := Byte2Detect;
                  end;
   $26          : begin
		    Command := 'seg es';
		    TByte2 := None;
		  end;
   $27          : begin
                    Command := 'daa';
                    TByte2 := Byte2Detect;
                  end;
   $28 .. $2D   : begin
                    Command := 'sub ';
                    TByte2 := Byte2Detect;
                  end;
   $2E          : begin
		    Command := 'seg cs';
		    TByte2 := None;
		  end;
   $2F          : begin
                    Command := 'das';
                    TByte2 := Byte2Detect;
                  end;
   $30 .. $35   : begin
                    Command := 'xor ';
                    TByte2 := Byte2Detect;
                  end;
   $36          : begin
                    Command := 'seg ss';
		    TByte2 := None;
		  end;
   $37          : begin
                    Command := 'aaa';
                    TByte2 := Byte2Detect;
                  end;
   $38 ..$3D    : begin
		    Command := 'cmp ';
                    TByte2 := Byte2Detect;
                  end;
   $3E          : begin
                    Command := 'seg ds';
		    TByte2 := None;
		  end;
   $3F          : begin
                    Command := 'aas';
                    TByte2 := Byte2Detect;
                  end;
   $40 .. $47   : begin
                    Command := 'inc ' + Reg16Analise(PByte^[0]);
		    TByte2 := None;
                  end;
   $48 .. $4F   : begin
                    Command := 'dec ' + Reg16Analise(PByte^[0]);
		    TByte2 := None;
                  end;
   $50 .. $57   : begin
                    Command := 'push ' + Reg16Analise(PByte^[0]);
		    TByte2 := None;
                  end;
   $58 .. $5F   : begin
                    Command := 'pop ' + Reg16Analise(PByte^[0]);
		    TByte2 := None;
                  end;
   $60 .. $6F   : begin
                    Command := '???';
		    TByte2 := None;
                  end;
   $70          : begin
                    Command := 'jo ';
                    TByte2 := IP__Inc8;
                  end;
   $71          : begin
                    Command := 'jno ';
                    TByte2 := IP__Inc8;
		  end;
   $72          : begin
                    Command := 'jb ';
                    TByte2 := IP__Inc8;
                  end;
   $73          : begin
                    Command := 'jnb ';
                    TByte2 := IP__Inc8;
                  end;
   $74          : begin
                    Command := 'je ';
                    TByte2 := IP__Inc8;
                  end;
   $75          : begin
                    Command := 'jne ';
                    TByte2 := IP__Inc8;
                  end;
   $76          : begin
                    Command := 'jbe ';
		    TByte2 := IP__Inc8;
                  end;
   $77          : begin
                    Command := 'jnbe ';
                    TByte2 := IP__Inc8;
                  end;
   $78          : begin
                    Command := 'js ';
                    TByte2 := IP__Inc8;
                  end;
   $79          : begin
                    Command := 'jns ';
                    TByte2 := IP__Inc8;
                  end;
   $7A          : begin
                    Command := 'jp ';
                    TByte2 := IP__Inc8;
                  end;
   $7B          : begin
		    Command := 'jnp ';
                    TByte2 := IP__Inc8;
                  end;
   $7C          : begin
                    Command := 'jl ';
                    TByte2 := IP__Inc8;
                  end;
   $7D          : begin
                    Command := 'jnl ';
                    TByte2 := IP__Inc8;
                  end;
   $7E          : begin
                    Command := 'jle ';
                    TByte2 := IP__Inc8;
                  end;
   $7F          : begin
                    Command := 'jnle ';
                    TByte2 := IP__Inc8;
                  end;
   $80          : begin
                    Command := '';
                    TByte2 := Cod_R8_M8__Data8;
                  end;
   $81          : begin
                    Command := '';
                    TByte2 := Cod_R16_M16__Data16;
                  end;
   $82          : begin
                    Command := '';
                    TByte2 := Cod_R8_M8__Data8;
                  end;
   $83          : begin
                    Command := '';
                    TByte2 := Cod_R16_M16__Data_S;
                  end;
   $84, $85     : begin
                    Command := 'test ';
		    TByte2 := Byte2DetectTest;
		  end;
   $86, $87     : begin
                    Command := 'xchg ';
		    TByte2 := Byte2DetectTest;
                  end;
   $88 .. $8B   : begin
                    Command := 'mov ';
                    TByte2 := Byte2Detect;
                  end;
   $8C          : begin
                    Command := 'mov ';
                    TByte2 := R16_M16__SR;
                  end;
   $8D          : begin
                    Command := 'lea ';
                    TByte2 := Reg16__Mem;
                  end;
   $8E          : begin
                    Command := 'mov ';
		    TByte2 := SR__R16_M16;
                  end;
   $8F          : begin
                    Command := 'pop ';
                    TByte2 := R16_M16;
                  end;
   $90          : begin
                    Command := 'nop';
		    TByte2 := None;
                  end;
   $91 .. $97   : begin
                    Command := 'xchg ax,' + Reg16Analise(PByte^[0]);
		    TByte2 := None;
                  end;
   $98          : begin
                    Command := 'cbw';
		    TByte2 := None;
                  end;
   $99          : begin
		    Command := 'cwd';
		    TByte2 := None;
                  end;
   $9A          : begin
                    Command := 'call ';
                    TByte2 := IP__New;
                  end;
   $9B          : begin
                    Command := 'wait';
		    TByte2 := None;
                  end;
   $9C          : begin
                    Command := 'pushf';
		    TByte2 := None;
                  end;
   $9D          : begin
                    Command := 'popf';
		    TByte2 := None;
                  end;
   $9E          : begin
                    Command := 'sahf';
		    TByte2 := None;
                  end;
   $9F          : begin
                    Command := 'lahf';
		    TByte2 := None;
                  end;
   $A0          : begin
                    Command := 'mov ';
                    TByte2 := AL_Addr16;
                  end;
   $A1          : begin
                    Command := 'mov ';
                    TByte2 := AX_Addr16;
                  end;
   $A2          : begin
                    Command := 'mov ';
                    TByte2 := Addr16_AL;
		  end;
   $A3          : begin
                    Command := 'mov ';
                    TByte2 := Addr16_AX;
                  end;
   $A4          : begin
                    Command := 'movsb';
		    TByte2 := None;
                  end;
   $A5          : begin
                    Command := 'movsw';
		    TByte2 := None;
                  end;
   $A6          : begin
                    Command := 'cmpsb';
                    TByte2 := None;
                  end;
   $A7          : begin
                    Command := 'cmpsw';
		    TByte2 := None;
                  end;
   $A8          : begin
                    Command := 'test al';
                    TByte2 := Data8;
                  end;
   $A9          : begin
                    Command := 'test ax';
                    TByte2 := Data16;
                  end;
   $AA          : begin
                    Command := 'stosb';
                    TByte2 := None;
                  end;
   $AB          : begin
                    Command := 'stosw';
                    TByte2 := None;
                  end;
   $AC          : begin
		    Command := 'lodsb';
                    TByte2 := None;
                  end;
   $AD          : begin
                    Command := 'lodsw';
                    TByte2 := None;
                  end;
   $AE          : begin
                    Command := 'scasb';
                    TByte2 := None;
                  end;
   $AF          : begin
                    Command := 'scasw';
                    TByte2 := None;
                  end;
   $B0 .. $B7   : begin
                    Command := 'mov '+ Reg8Analise(PByte^[0]);
                    TByte2 := Data8;
                  end;
   $B8 .. $BF   : begin
                    Command := 'mov '+ Reg16Analise(PByte^[0]);
                    TByte2 := Data16;
                  end;
   $C2          : begin
                    Command := 'ret';
                    TByte2 := _Data16;
                  end;
   $C3          : begin
                    Command := 'ret ';
                    TByte2 := None;
                  end;
   $C4          : begin
                    Command := 'les ';
                    TByte2 := Reg16__M32;
                  end;
   $C5          : begin
                    Command := 'lds ';
                    TByte2 := Reg16__M32;
		  end;
   $C6          : begin
                    Command := 'mov ';
                    TByte2 := M8__Data8;
                  end;
   $C7          : begin
                    Command := 'mov ';
                    TByte2 := M16__Data16;
                  end;
   $C8,$C9,
   $C0,$C1      : begin
                     Command := '???';
                     TByte2 := None;
                  end;
   $CA          : begin
                    Command := 'retf';
                    TByte2 := _Data16;
                  end;
   $CB          : begin
		    Command := 'retf ';
                    TByte2 := None;
                  end;
   $CC          : begin
                    Command := 'int 3';
                    TByte2 := None;
                  end;
   $CD          : if PByte^[1] in [$34..$3E] then
                   begin
                    Command := '???';
                    TByte2 := None;
                   end
                  else
                   begin
                    Command := 'int';
                    TByte2 := Pop_Val;
                   end;
   $CE          : begin
                    Command := 'into';
		    TByte2 := None;
                  end;
   $CF          : begin
                    Command := 'iret';
                    TByte2 := None;
                  end;
   $D0          : begin
                    Command := '';
                    TByte2 := Shift_R8_M8__Val1;
                  end;
   $D1          : begin
                    Command := '';
                    TByte2 := Shift_R16_M16__Val1;
                  end;
   $D2          : begin
                    Command := '';
                    TByte2 := Shift_R8_M8__CL;
                  end;
   $D3          : begin
		    Command := '';
                    TByte2 := Shift_R16_M16__CL;
                  end;
   $D4          : begin
                    Command := 'aam';
                    TByte2 := None;
                  end;
   $D5          : begin
                    Command := 'aad';
                    TByte2 := None;
                  end;
   $D6          : begin
                    Command := '???';
                    TByte2 := None;
                  end;
   $D7          : begin
                    Command := 'xlat ';
                    TByte2 := None;
                  end;
   $D8 .. $DF   : begin
                    {Command := 'esc ';
                    TByte2 := OpCode__R_M;}
                    Command := '???';
                    TByte2 := None;
                  end;
   $E0          : begin
                    Command := 'loopne ';
                    TByte2 := IP__Inc8;
                  end;
   $E1          : begin
                    Command := 'loope ';
                    TByte2 := IP__Inc8;
                  end;
   $E2          : begin
                    Command := 'loop ';
                    TByte2 := IP__Inc8;
                  end;
   $E3          : begin
		    Command := 'jcxz ';
                    TByte2 := IP__Inc8;
                  end;
   $E4          : begin
                    Command := 'in ';
                    TByte2 := al_Port;
                  end;
   $E5          : begin
                    Command := 'in ';
                    TByte2 := ax_Port;
                  end;
   $E6          : begin
                    Command := 'out ';
                    TByte2 := Port_al;
                  end;
   $E7          : begin
                    Command := 'out ';
                    TByte2 := Port_ax;
                  end;
   $E8          : begin
                    Command := 'call ';
                    TByte2 := IP__Inc16;
                  end;
   $E9          : begin
                    Command := 'jmp ';
                    TByte2 := IP__Inc16;
                  end;
   $EA          : begin
                    Command := 'jmp ';
                    TByte2 := IP__New;
                  end;
   $EB          : begin
                    Command := 'jmp ';
                    TByte2 := IP__Inc8;
                  end;
   $EC          : begin
                    Command := 'in al,dx';
                    TByte2 := None;
		  end;
   $ED          : begin
                    Command := 'in ax,dx';
                    TByte2 := None;
                  end;
   $EE          : begin
                    Command := 'out dx,al';
                    TByte2 := None;
                  end;
   $EF          : begin
                    Command := 'out dx,ax';
                    TByte2 := None;
                  end;
   $F0          : begin
                    Command := 'lock';
                    TByte2 := None;
                  end;
   $F1          : begin
                    Command := '???';
		    TByte2 := None;
                  end;
   $F2          : begin
                    Command := 'repne';
                    TByte2 := None;
                  end;
   $F3          : begin
                    Command := 'rep';
                    TByte2 := None;
                  end;
   $F4          : begin
                    Command := 'hlt';
                    TByte2 := None;
                  end;
   $F5          : begin
                    Command := 'cmc';
                    TByte2 := None;
                  end;
   $F6          : begin
		    Command := '';
                    TByte2 := Test_R8_M8__Data8;
                  end;
   $F7          : begin
                    Command := '';
                    TByte2 := Test_R16_M16__Data16;
                  end;
   $F8          : begin
                    Command := 'clc';
                    TByte2 := None;
                  end;
   $F9          : begin
                    Command := 'stc';
                    TByte2 := None;
                  end;
   $FA          : begin
                    Command := 'cli';
                    TByte2 := None;
                  end;
   $FB          : begin
                    Command := 'sti';
                    TByte2 := None;
                  end;
   $FC          : begin
                    Command := 'cld';
                    TByte2 := None;
                  end;
   $FD          : begin
                    Command := 'std';
                    TByte2 := None;
                  end;
   $FE          : begin
                    Command := '';
                    TByte2 := Inc_R8_M8__Data8;
                  end;
   $FF          : begin
                    Command := '';
                    TByte2 := Inc_R16_M16__Data16;
		  end;
   else;
 end;{case}
end;{Byte1Analise}

begin {Command}
 SavePtr := PMemoryBuf;
 if  EmuFlag = 0 then
  begin
   PrefixAnalise(Prefix,PrefSeg);
   Byte1Analise( Com,TByte2);
   case TByte2 of
     R8_M8__Reg8          :
      Command := Com + Mode__R_M +','+ Reg8Analise(PByte^[1] shr 3);
     R16_M16__Reg16       :
      Command := Com + Mode__R_M +','+ Reg16Analise(PByte^[1] shr 3);
     Reg8__R8_M8          :
      Command := Com + Reg8Analise(PByte^[1] shr 3) +','+ Mode__R_M;
     Reg16__R16_M16       :
      Command := Com + Reg16Analise(PByte^[1] shr 3) +','+ Mode__R_M;
     al_Data_8            :
      begin
        Command := Com + 'al,'+ HexB(PByte^[1]);
        Index := 2;
      end;
     ax_Data_16           :
      begin
	Command := Com + 'ax,'+ HexW(PByte^[1]+$100*PByte^[2]);
        Index:=3;
      end;
     None                 :
      begin
        Command := Com + ' '+ PrefSeg;
        Index := 1;
      end;
     IP__Inc8             :
      begin
        Command := Com + HexW(Address+ Shortint(PByte^[1])+2);
	Index := 2;
      end;
     IP__Inc16            :
      begin
        Command := Com + HexW(Address+ Integer(PByte^[1]+$100*PByte^[2])+3);
        Index := 3;
      end;
     IP__New              :
      begin
	Command := Com + HexW(PByte^[3]+$100*PByte^[4]) + ':'+
                         HexW(PByte^[1]+$100*PByte^[2]);
        Index := 5;
      end;
     POP__Val             :
      begin
        Command := Com + HexB(PByte^[1]);
        Index := 2;
      end;
     N__Proc              :
      begin
        Command := Com + HexB(PByte^[1]);
        Index := 2;
      end;
     al_Port              :
      begin
        Command := Com +'al,'+ HexB(PByte^[1]);
        Index := 2;
      end;
     ax_Port              :
      begin
        Command := Com +'ax,'+ HexB(PByte^[1]);
        Index := 2;
      end;
     Port_al              :
      begin
        Command := Com + HexB(PByte^[1]) + ',al';
        Index := 2;
      end;
     Port_ax              :
      begin
        Command := Com + HexB(PByte^[1]) + ',ax';
        Index := 2;
      end;
     R16_M16__SR          :
      if (PByte^[1] and $20) = 0 then
       begin
        if PByte^[1] and $C0 =$C0 then
         begin
          Command := Com + Reg16Analise(PByte^[1]) + ','
				    + SegmentAnalise(PByte^[1] shr 3);
          Index := 2;
         end
        else Command := Com +Mode__R_M  +',' + SegmentAnalise(PByte^[1] shr 3);
       end
      else Command := '???';
     SR__R16_M16          :
      if (PByte^[1] and $20) = 0 then
       begin
        if PByte^[1] and $C0 =$C0 then
         begin
          Command := Com + SegmentAnalise(PByte^[1] shr 3) + ','
                                            + Reg16Analise(PByte^[1]);
          Index := 2;
         end
        else Command := Com + SegmentAnalise(PByte^[1] shr 3) + ','+ Mode__R_M ;
       end
      else Command := '???';
     Reg16__Mem           :
      Command := Com + Reg16Analise(PByte^[1] shr 3) +','+ Mode__R_M;
     R16_M16              :
      if (PByte^[1] and $38) = 0 then Command := Com + Mode__R_M
                                 else Command := '???';
     Addr16_AL            :
      begin
        Command := Com + PrefSeg + '['+ HexW(PByte^[1]+$100*PByte^[2])+ '],al';
        Index := 3;
      end;
     Addr16_AX            :
      begin
        Command := Com + PrefSeg + '['+ HexW(PByte^[1]+$100*PByte^[2])+ '],ax';
        Index := 3;
      end;
     AL_Addr16            :
      begin
        Command := Com +'al,'+ PrefSeg +'['+ HexW(PByte^[1]+$100*PByte^[2])+ ']';
        Index := 3;
      end;
     AX_Addr16            :
      begin
	Command := Com +'ax,'+ PrefSeg +'['+ HexW(PByte^[1]+$100*PByte^[2]) +']';
        Index := 3;
      end;
     Pop_Val              :
      begin
        Command := Com +' '+ HexB(PByte^[1]);
	Index := 2;
      end;
     Data8                :
      begin
        Command := Com + ','+ HexB(PByte^[1]);
        Index := 2;
      end;
     Data16               :
      begin
        Command := Com + ','+ HexW(PByte^[1]+$100*PByte^[2]);
        Index := 3;
      end;
     _Data16              :
      begin
	Command := Com + ' '+ HexW(PByte^[1]+$100*PByte^[2]);
        Index := 3;
      end;
     Data16_Data8         :
      begin
	Command := Com + HexW(PByte^[1]+$100*PByte^[2])+','+
         HexB(PByte^[3]);
        Index := 4;
      end;
     Reg16__Data16  :
      begin
        Command :=  Com + Mode__R_M + ',' +  HexW(PByte^[Index] +
         $100 * PByte^[Index+1]);
        Inc(Index,2);
      end;
     Reg16_Reg16__Data16  :
      begin
        Command :=  Com + Reg16Analise(PByte^[1] shr 3) +','+
         Mode__R_M + ',' +  HexW(PByte^[Index] +
         $100 * PByte^[Index+1]);
	Inc(Index,2);
      end;
     Reg16_Reg16__Data8   :
      begin
	Command :=  Com + Reg16Analise(PByte^[1] shr 3) +','+
        Mode__R_M + ',' +  HexB(PByte^[Index]);
        Inc(Index,1);
      end;
     Reg16__M32           :
      Command := Com + Reg16Analise(PByte^[1] shr 3)+',dword ptr '+Mode__R_M ;
     M8__Data8            :
      if (PByte^[1] and $38) = 0 then
        begin
          Command := Com + Mode__R_M + ',' + HexB(PByte^[Index]);
          Inc(Index);
        end
      else Command := '???';
     M16__Data16          :
        if (PByte^[1] and $38) = 0 then
         begin
	  Command := Com + Mode__R_M + ',' + HexW(PByte^[Index]+
                                             $100 * PByte^[Index+1]);
          Inc(Index,2);
	 end
        else Command := '???';
     Cod_R8_M8__Data8     :
      begin
        Command := Code_ + Mode__R_M + ',' + HexB(PByte^[Index]);
        Inc(Index);
      end;
     Cod_R16_M16__Data16  :
      begin
        Command := Code_ + Mode__R_M + ',' +
         HexW(PByte^[Index] + $100 * PByte^[Index+1]);
        Inc(Index,2);
      end;
     Cod_R16_M16__Data_S  :
       begin
        Command := Code_ + Mode__R_M + ',' + HexW(PByte^[Index]);
        Inc(Index,1);
       end;
     Shift_R8_M8__Val1    :
      Command := Shift_ + Mode__R_M +',1';
     Shift_R16_M16__Val1  :
      Command := Shift_ + Mode__R_M +',1';
     Shift_R8_M8__Data8   :
      begin
       Command := Shift_ + Mode__R_M +','+ HexB(PByte^[Index]);
       Inc(Index,1);
      end;
     Shift_R16_M16__Data16:
      begin
       Command := Shift_ + Mode__R_M +','+ HexW(PByte^[Index]+
        $100 * PByte^[Index+1]);
       Inc(Index,2);
      end;
     Shift_R8_M8__CL      :
      Command := Shift_ + Mode__R_M +',cl';
     Shift_R16_M16__CL    :
      Command := Shift_ + Mode__R_M +',cl';
     OpCode__R_M          :
      Command := Com + OpCode_ +', '+ Mode__R_M;
     Test_R8_M8__Data8    :
      if (PByte^[1] and $38) = 0 then
        begin
         Command := Test_+ Mode__R_M + ','+ HexB(PByte^[Index]);
         Inc(Index);
        end
      else Command := Test_+ Mode__R_M;
     Test_R16_M16__Data16 :
      if (PByte^[1] and $38) = 0 then
        begin
         Command := Test_+ Mode__R_M +
          HexW(PByte^[Index] + $100 * PByte^[Index+1]);
         Inc(Index,2);
        end
      else Command := Test_+ Mode__R_M;
     Inc_R8_M8__Data8     :
      if (PByte^[1] and $38) in [$0,$8] then Command := Inc_ + Mode__R_M
                                        else Command := '???';
     Inc_R16_M16__Data16  :
      Command := Inc_ + Mode__R_M;
    end;{case}

    if Pos('???', Command) = 0 then
     begin
      Command := #32#32#32#32#32#32#32#32#32#32#32#32#32#32#32 +
		 Prefix + Command;
      SubStr :='';
      Address := Address - CountPref;
      Index := Index + CountPref;
      PByte := PMemoryBuf;
      for I := 0 to Index-1 do
       SubStr := SubStr + HexB(PByte^[I]);
      if Byte(SubStr[0]) > 14 then
       begin
	Byte(SubStr[0]) := 15;
	SubStr[15] := '+';
       end;
      Move(SubStr[1],Command[1],Byte(SubStr[0]));
      Address := Address + Index;
     end
    else Command := UnAssemble(PMemoryBuf);
  end
 else Command := UnAssemble(PMemoryBuf);
 if SavePtr = Ptr(CPUStatus.cs_, CPUStatus.ip_) then
  Command := Command +  ' ' + JumpDirection;
 if DrawCS and (PType(SavePtr).Segment = CPUStatus.cs_) then
  DisasmCom := 'cs:'+ HexW(PType(SavePtr).Offset) + ' '+ Command
 else DisasmCom := HexW(PType(SavePtr).Segment) + ':'+
		   HexW(PType(SavePtr).Offset)+ ' '+ Command;
end;

function GetMemValue(PMemoryBuf : Pointer) : String;
type
 RegStr         = String[2];
 ByteArray      = Array[0 .. 5] of Byte;
 TByteArray     = ^ByteArray;

var
 Segm,Offs : Word;
 Address   : Word absolute PMemoryBuf;
 P         : Pointer;
 PByte     : TByteArray;
 Pref      : RegStr;
 Com       : String;

function R_M : Word;
begin
with CPUStatus do
 case PByte^[1] and $07 of
   0     : R_M :=  bx_ + si_;
   1     : R_M :=  bx_ + di_;
   2     : R_M :=  bp_ + si_;
   3     : R_M :=  bp_ + di_;
   4     : R_M :=  si_;
   5     : R_M :=  di_;
   6     : if (PByte^[1] and $C0) = 0 then
            begin
             R_M := Word(PByte^[2]+$100*PByte^[3]);
            end
	   else R_M := bp_;
   7     : R_M := bx_;
 end;{case}
end;

function Mode__R_M : Word;
begin
 case PByte^[1] and $C0 of
  $0    : Mode__R_M := R_M ;
  $40   : Mode__R_M := Word(Integer(R_M) + ShortInt(PByte^[2]));
  $80   : Mode__R_M := Word(Integer(R_M) + Integer(PByte^[2]+$100*PByte^[3]));
  else    Mode__R_M := 0;
 end;{case}
end;

procedure PrefixAnalise(var Pref : RegStr;
                        var Segm : Word);
begin
 Pref := '';
 Segm := 0;
 PByte := PMemoryBuf;
 with CPUStatus do
  while PByte^[0] in [$26,$2E,$36,$3E,$F0,$F2,$F3] do
  begin
     case PByte^[0] of
      $26       : begin
                   Segm := es_;
                   Pref := 'es';
                  end;
      $2E       : begin
                   Segm := cs_;
                   Pref := 'cs';
                  end;
      $36       : begin
                   Segm := ss_;
                   Pref := 'ss';
                  end;
      $3E       : begin
		   Segm := ds_;
                   Pref := 'ds';
                  end;
      else;
     end;{case}
     Inc(Address);
     PByte := PMemoryBuf;
   end;
end;

Procedure SegmDetect(var Pref : RegStr;
                     var Segm : Word);
begin
with CPUStatus do
 case PByte^[1] and $07 of
   0     : begin
            Segm :=  ds_;
            Pref := 'ds';
           end;
   1     : begin
            Segm :=  ds_;
            Pref := 'ds';
           end;
   2     : begin
            Segm :=  ss_;
            Pref := 'ss';
           end;
   3     : begin
            Segm :=  ss_;
            Pref := 'ss';
           end;
   4     : begin
            Segm :=  ds_;
            Pref := 'ds';
           end;
   5     : begin
            Segm :=  ds_;
            Pref := 'ds';
	   end;
   6     : if (PByte^[1] and $C0) = 0 then
            begin
             Segm :=  ds_;
             Pref := 'ds';
            end
           else
            begin
             Segm :=  ss_;
             Pref := 'ss'
            end;
   7     : begin
            Segm :=  ds_;
            Pref := 'ds';
           end;
 end;{case}
end;

begin
 GetMemValue :='';
 PrefixAnalise(Pref,Segm);
 if (PByte^[0] in [$00..$03, $08..$0B, $18..$1B, $20..$23, $28..$2B,
                   $30..$33, $38..$3A, $80..$8F, $A0..$A3, $C4..$C7,
                   $D0..$D3, $D8..$DF, $F6..$F7, $FE..$FF]) and
    (PByte^[1] and $C0 in [$00,$40,$80]) then
  begin
   if PByte^[0] in [$A0..$A3] then
    begin
     if Pref = '' then
       begin
        Pref := 'ds';
        Segm := CPUStatus.ds_;
       end;
     Offs := PByte^[1]+$100*PByte^[2];
    end
   else
    begin
     if Pref = '' then SegmDetect(Pref,Segm);
     Offs :=  Mode__R_M;
    end;
   if PByte^[0] in [$8C,$8E] then
     GetMemValue := Pref+ ':' + HexW(Offs) + '=' +
                        HexW(Word(Ptr(Segm,Offs)^))
   else if PByte^[0] and $01 = 1 then
          GetMemValue := Pref + ':' + HexW(Offs) + '=' +
                              HexW(Word(Ptr(Segm,Offs)^))
        else
          GetMemValue := Pref + ':' + HexW(Offs) + '=' +
                              HexB(Byte(Ptr(Segm,Offs)^));
  end;
end;

Function DisasmBack(Var P : Pointer; DrawCS: Boolean) : String;
Const
 SegSet  = [$26,$2E,$36,$3E];
 RepSet  = [$F2,$F3];
 LockSet = [$F0];
var
 PrefSet  	: Set of Byte;
 ComPtr		: Pointer;
 ComAddr 	: Word absolute ComPtr;
 TestPtr 	: Pointer;
 TestAddr 	: Word absolute TestPtr;
 TempPtr 	: Pointer;
 TempAddr 	: Word absolute TempPtr;
 Com    	: String;
 TestStr 	: String;
begin
 TestStr := '';
 ComPtr := P;
 TestPtr := ComPtr;
 if ComAddr = 0 Then Exit;
 if TestAddr >= 6 then TestAddr := TestAddr - 7
		  else TestAddr := 1;
 PrefSet := [$26,$2E,$36,$3E,$F0,$F2,$F3];
 while (Byte(TestPtr^) in PrefSet) and (TestAddr > 0) do
 begin
  if Byte(TestPtr^) in SegSet then PrefSet := PrefSet - SegSet
  else if Byte(TestPtr^) in RepSet then PrefSet := PrefSet - RepSet
       else if Byte(TestPtr^) in LockSet then PrefSet := PrefSet - LockSet;
  Dec(TestAddr);
 end;
 repeat
  TempPtr := TestPtr;
  while TempAddr < ComAddr do
   begin
    P := TempPtr;
    TestStr := DisasmCom(TempPtr, DrawCS);
    if Word(TempPtr) < Word(P) then Exit;
   end;
  if TempAddr <> ComAddr then Inc(TestAddr);
 until TempPtr = ComPtr;
 DisasmBack := TestStr;
end;
end.

