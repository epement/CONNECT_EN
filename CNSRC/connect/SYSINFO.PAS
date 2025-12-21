{$F+,O+,X+}
unit SysInfo;

Interface

type
  TSysinfoRec = record
    CPUS, CoCPUS : String[63];
    CPURate: String[15];
    Memory: String[12];
    ExMemory, EMS_Total, EMS_Available,
    XMS_Total, XMS_Available: String[15];
    Video: String[23];
    DOS_: String[39];
    NetWare: String[15];
    Shell: String[31];
    EnhKbd: String[3];
    InfoCount, InfoLen: Byte;
  end;

{
  LinuxVersion = record
    SubLevel,
    Version : Byte;
    PatchLevel : Word;
  end;


function LinuxPresent: Longint;
}

const
  MaxInfoWidth = 36;

procedure GetSysInfo(var Rec: TSysinfoRec);

implementation

uses Dos, Detect, OpXms, DosTools, TPString, OPEnhKbd, CPUType;
{
function LinuxPresent: Longint; assembler;
}

(*

#define DOS_HELPER_INT           0xE6
#define DOS_HELPER_DOSEMU_CHECK  0x00

/* returns non-zero version number if DOSEMU is loaded */
main(void)
{
    unsigned int version, sublevel, patchlevel;

    _AL = DOS_HELPER_DOSEMU_CHECK;
    geninterrupt(DOS_HELPER_INT);

    /* check for signature in AX */
    if (_AX == 0xaa55) {
         version = _BX / 0x100;
         sublevel = _BX % 0x100;
         patchlevel = _CX;
         printf("Detected: Dosemu %d.%d.%d\n", version, sublevel, patchlevel);
         return (version * 100 + sublevel);
    }
    else {
         printf("Dosemu not detected\n");
         return (0);
    }

*)

{
asm
        XOR     AX,AX
        XOR     DX,DX
        MOV     ES,AX
        MOV     AX,ES:[4*0E6H]
        OR      AX,ES:[4*0E6H+2]
        JE      @@1
        INT     0E6H
        XOR     DX,DX
        CMP     AX,0AA55H
        MOV     AX,0
        JNE     @@1
        MOV     AX,BX
        MOV     DX,CX
@@1:
end;
}

type
  VgaInfoBlock = record
    VESASignature: array[0..3] of Byte;
    VESAVersion: Word;
    OEMStringPtr: Pointer;
    Capabilities: array[0..3] of Byte;
    VideoModePtr: Pointer;
  end;

const
  VESA16Modes: array[0..2] of Word = ($0102, $0104, $0106);

function EmsInstalled : boolean; assembler;
asm
        jmp @1
@4:     db 'EMMXXXX0'
@1:     mov     ax, 3567H  { Get 67h vector}
        int     21H
        mov     cx, 8
        mov     si, offset @4
        mov     di, 0aH
        push    ds
        push    cs
        pop     ds
        cld
        repe    cmpsb
        pop     ds
        mov     al,1
        je      @3
        xor     al,al
@3:
end;

function GetHighestCap(Table: Pointer; Modes: Word; Size: Integer): Integer;
  near; assembler;
asm
        XOR     AX,AX
        LES     DI, Table
@@1:
        MOV     SI, Modes
        ADD     SI, Size
        ADD     SI, Size
        MOV     BX, ES:[DI]
        CMP     BX, 0FFFFH
        JE      @@4
        INC     DI
        INC     DI
        MOV     CX,Size
@@2:
        CMP     BX,[SI]
        JZ      @@3
        DEC     SI
        DEC     SI
        LOOP    @@2
@@3:
        CMP     AX,CX
        JA      @@1
        MOV     AX,CX
        JMP     @@1
@@4:
end;

function DetectVesa16: Integer; far; assembler;
var
  VesaInfo: array[0..255] of Byte;
asm
        MOV     AX,SS
        MOV     ES,AX
        LEA     DI,VesaInfo
        MOV     AX,4F00H
        INT     10H
        CMP     AX,004FH
        MOV     AX,grError
        JNZ     @@Exit
        CMP     ES:[DI].VgaInfoBlock.VESASignature.Word[0], 'EV'
        JNZ     @@Exit
        CMP     ES:[DI].VgaInfoBlock.VESASignature.Word[2], 'AS'
        JNZ     @@Exit
        LES     DI,ES:[DI].VgaInfoBlock.VideoModePtr
        PUSH    ES
        PUSH    DI
        MOV     AX, OFFSET Vesa16Modes
        PUSH    AX
        MOV     AX,3
        PUSH    AX
        CALL    GetHighestCap
@@Exit:
end;

Procedure GetSysInfo(var Rec: TSysinfoRec);
 type
  WordRec = record
   Lo,Hi : Byte;
  end;
 var
  B: Boolean;
  Test,Mode : Byte;
  CPU,TestW,Size : Word;
  GraphDriver, GraphMode, Vesa16: Integer;
  SubStr : String;
begin
 with Rec do
 begin
   B := InfoCount = $FF;
   FillChar(Rec, SizeOf(TSysinfoRec), 0);
   InfoCount := 4;
   InfoLen := 18;

if B then CPU := MaxCPU
else
begin
{
   CPU := CPU_Type;
   CPUS := CPU_TypeStr;
   if CPU > $100 then CPUS := CPUS + ' VM';
   CoCPUS := CoPro_TypeStr;
   if Length(CPUS) > InfoLen then InfoLen := Length(CPUS);
   if Length(CoCPUS) > InfoLen then InfoLen := Length(CoCPUS);
   Str(CPUSpeed:6:2,CPURate);
   TrimSt(CPURate);
   CPURate := CPURate + ' MHz';
}
   {CPU := CPU_Type;}
   CPUS := CPU_Type{Str};
   {if CPU > $100 then CPUS := CPUS + ' VM';}
   CoCPUS := {CoPro_TypeStr} fpu_Type;
   if Length(CPUS) > InfoLen then InfoLen := Length(CPUS);
   if Length(CoCPUS) > InfoLen then InfoLen := Length(CoCPUS);
   if Length(CPUS) > MaxInfoWidth then Inc(InfoCount);
   if Length(CoCPUS) > MaxInfoWidth then Inc(InfoCount);

   Str(fCPU_Speed:6:2,CPURate);
   TrimSt(CPURate);
   CPURate := CPURate + ' MHz';
end;

   asm
    int 12h
    mov TestW,ax
   end;
   Memory := Long2Str(Longint(TestW) * 1024) + ' Bytes';

{
   EMS_Total := '';
   EMS_Available := '';
   XMS_Total := '';
   XMS_Available := '';
   ExMemory := '';
}
   if EmsInstalled then
   begin
     asm
      mov ah,42h
      int 67h
      mov Test,ah
      mov Size,dx
      mov TestW,bx
     end;
     if Test = 0 then
      if Size <> 0 then
       begin
        EMS_Total := Long2Str(Longint(Size) * 16384) + ' Bytes';
        EMS_Available := Long2Str(Longint(TestW) * 16384) + ' Bytes';
        inc(InfoCount,2);
        if Length(EMS_Total) > InfoLen then
          InfoLen := Length(EMS_Total);
        if Length(EMS_Available) > InfoLen then
          InfoLen := Length(EMS_Available);
       end;
   end;
   if CPU > {i186} i80186 then
    begin
     asm
      mov ah,88h
      int 15h
      mov TestW,0
      jc @@2
      mov TestW,ax
     @@2:
     end;
     if TestW = 0 then
     begin
       asm
          mov     al,17H
          out     70H,al
          jmp     @@1
  @@1:    in      al,71H
          mov     bl,al
          mov     al,18H
          out     70H,al
          jmp     @@2
  @@2:    in      al,71H
          mov     bh,al
          mov     TestW,bx
       end;
     end;
     if TestW <> 0 then
      begin
       ExMemory := Long2Str(Longint(TestW) * 1024) + ' Bytes';
       inc(InfoCount);
       if Length(ExMemory) > InfoLen then InfoLen := Length(ExMemory);
      end;
     if XmsInstalled then
       if QueryFreeExtMem(Size,TestW) = 0 then
        begin
         XMS_Total := Long2Str(Longint(Size) * 1024) + ' Bytes';
         XMS_Available := Long2Str(Longint(TestW) * 1024) + ' Bytes';
         inc(InfoCount, 2);
         if Length(XMS_Total) > InfoLen then
           InfoLen := Length(XMS_Total);
         if Length(XMS_Available) > InfoLen then
           InfoLen := Length(XMS_Available);
        end;
    end;

    if B then Exit;

    DetectGraph(GraphDriver, GraphMode);
    case GraphDriver of
       1: case GraphMode of
           0..3 : Video := 'CGA 320 x 200';
           4    : Video := 'CGA 640 x 200';
          else Video := 'CGA';
          end;
       2: case GraphMode of
           0..3 : Video := 'MCGA 320 x 200';
           4    : Video := 'MCGA 640 x 200';
           5    : Video := 'MCGA 640 x 480';
          else Video := 'MCGA';
          end;
     3,4: case GraphMode of
           0    : Video := 'EGA 640 x 200';
           1    : Video := 'EGA 640 x 350';
          else Video := 'EGA';
          end;
       5: Video := 'EGA Mono 640 x 350';
       6: case GraphMode of
           0    : Video := 'IBM8514 640 x 480';
           1    : Video := 'IBM8514 1024 x 768';
          else Video := 'IBM8514';
          end;
       7: Video := 'Herc Mono 720 x 348';
       8: case GraphMode of
           0..3 : Video := 'ATT400 320 x 200';
           4    : Video := 'ATT400 640 x 200';
           5    : Video := 'ATT400 640 x 400';
          else Video := 'ATT400';
          end;
       9: begin
           Vesa16 := DetectVesa16;
           if Vesa16 <> grError then
            case Vesa16 of
             0 : Video := 'SVGA 800 x 600';
             1 : Video := 'SVGA 1024 x 768';
            else Video := 'SVGA';
            end
           else
            case GraphMode of
             0    : Video := 'VGA 640 x 200';
             1    : Video := 'VGA 640 x 350';
             2    : Video := 'VGA 640 x 480';
            else Video := 'VGA';
            end;
          end;
      10: Video := 'PC3270 720 x 350';
    else Video := ''
    end;
    if Video <> '' then Inc(InfoCount);
    if Length(Video) > InfoLen then InfoLen := Length(Video);

   asm
    mov ax,4452h
    int 21h
    jc @@30
    mov TestW,ax
    mov Test,'D'
    jmp @@20
   @@30:
    mov  ax,3306h
    xor bx,bx
    int  21h
    or bx,bx
    je @@10
    xchg bh, bl
    mov Test,dh
    mov TestW, bx
    jmp @@20
   @@10:
    mov ax,3000h
    int 21h
    xchg ah,al
    mov TestW ,ax
    mov Test,0ffh
   @@20:
   end;
   if Char(Test) = 'D' then
    case TestW of
      $1060 : DOS_ := 'DOS Plus';
      $1063 : DOS_ := 'DR-DOS 3.41';
      $1064 : DOS_ := 'DR-DOS 3.42';
      $1065 : DOS_ := 'DR-DOS 5.00';
      $1067 : DOS_ := 'DR-DOS 6.00';
      $1070 : DOS_ := 'PalmDOS';
      $1071 : DOS_ := 'DR DOS 6.0 March 1993';
      $1072 : DOS_ := 'Novell DOS 7.0';
      $1432 : DOS_ := 'Concurrent PC DOS 3.2';
      $1441 : DOS_ := 'Concurrent DOS 4.1';
      $1450 : DOS_ := 'Concurrent DOS/XM 5.0 or 386 1.1';
      $1460 : DOS_ := 'Concurrent DOS/XM 6.0 or 386 2.0';
      $1462 : DOS_ := 'Concurrent DOS/XM 6.2 or 386 3.0';
      $1466 : DOS_ := 'DR Multiuser DOS 5.1';
      $1467 : DOS_ := 'Concurrent DOS 5.1';
    else
      begin
        TestW := DosVersion;
        DOS_ := 'Unknown version ' +
          Long2Str(Lo(TestW)) + '.' + Long2Str(Hi(TestW));
      end;
    end
   else
   begin
     DOS_ := Long2Str(Hi(TestW)) + '.' + Long2Str(Lo(TestW));
     if (Test <> $ff) and (Test and $10 <> 0) then DOS_ := DOS_ + ' in HMA';
   end;
   inc(InfoCount);
   if Length(DOS_) > InfoLen then InfoLen := Length(DOS_);

   asm
    mov ax,7A00h
    int 2Fh
    mov Test,0
    cmp al,0FFh
    jnz @@4
    mov Test,1
   @@4:
   end;
   if Test <> 0 then
    begin
     NetWare := 'Novell NetWare';
     inc(InfoCount);
     if Length(Netware) > InfoLen then InfoLen := Length(Netware);
    end
   else NetWare := '';

   asm
    mov ax, 2B01h
    mov cx, 4445h
    mov dx, 5351h
    int 21h
    mov Test,0
    cmp al, 0FFh
    jz  @@3
    mov Test,1
    mov TestW,bx
   @@3:
   end;
   if Test <> 0 then Shell :=
     'DESQ View ' + Long2Str(Hi(TestW)) + '.' + Long2Str(Lo(TestW))
   else
    begin
     asm
      mov ax,160ah
      int 2fh
      mov Test,0
      or ax,ax
      jne @@6
      mov Test,1
      mov TestW,bx
      mov Mode,cl
     @@6:
     end;
     if Test <> 0 then
      begin
       Shell := 'MS Windows ' +
         Long2Str(Hi(TestW)) + '.' + Long2Str(Lo(TestW));
       case Mode of
        2 : Shell := Shell + ' Standart mode';
        3 : Shell := Shell + ' Enhanced mode';
       else;
       end;
      end
     else
      begin
       asm
        mov ax,4680h
        int 2Fh
        or ax,ax
        mov Test,0
        jnz @@5
        mov Test,1
       @@5:
       end;
       if Test <> 0 then Shell := 'MS Windows 3.0 Standart mode'
       else
        begin
         asm
          mov ax,1600h
          int 2fh
          mov Test,al
          mov TestW,ax
         end;
         if TestW <> $1600 then
          case Test of
             0 : Shell := 'MS Windows 3.x Enhanced mode';
           $80 : Shell := 'MS Windows 3.x Enhanced mode';
             1 : Shell := 'MS Windows/386 2.x';
           $FF : Shell := 'MS Windows/386 2.x';
            else Shell := 'MS Windows ' +
              Long2Str(Hi(TestW)) + '.' + Long2Str(Lo(TestW));
          end {case};
        end;
       end;
     end;
     if Shell <> '' then inc(InfoCount);
     if Length(Shell) > InfoLen then InfoLen := Length(Shell);

     if HasEnhancedKbd then EnhKbd := 'Yes' else EnhKbd := 'No';
     Inc(InfoCount);
    end;
  end;
end.