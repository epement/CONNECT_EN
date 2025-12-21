unit CPUIDS;
interface

 procedure CPU_PRT;
implementation


Uses
 tpString, DOS, Strings;

var
  f: Text;


{$L cpuid.obj}
procedure cpuid(i: longint; var eax; var ebx;
                 var ecx; var edx); Far; External;
function cpuidtst: Boolean; Far; External;

procedure PutNewStr(const SO: String);
begin
 WriteLn(SO);
end;



const
 MAXBRANDS = 9;

function Brands(i: Byte): String;
begin
 case i of
  0: Brands := 'brand 0';
  1: Brands := 'Celeron processor';
  2: Brands := 'Pentium III processor';
  3: Brands := 'Intel Pentium III Xeon processor';
  4: Brands := 'brand 4';
  5: Brands := 'brand 5';
  6: Brands := 'brand 6';
  7: Brands := 'brand 7';
  8: Brands := 'Intel Pentium 4 processor';
 end;
end;

function Intel_feature_flags(i: byte): String;
begin
 case i of
    0: Intel_feature_flags := 'FPU    Floating Point Unit';
    1: Intel_feature_flags := 'VME    Virtual 8086 Mode Enhancements';
    2: Intel_feature_flags := 'DE     Debugging Extensions';
    3: Intel_feature_flags := 'PSE    Page Size Extensions';
    4: Intel_feature_flags := 'TSC    Time Stamp Counter';
    5: Intel_feature_flags := 'MSR    Model Specific Registers';
    6: Intel_feature_flags := 'PAE    Physical Address Extension';
    7: Intel_feature_flags := 'MCE    Machine Check Exception';
    8: Intel_feature_flags := 'CX8    COMPXCHG8B Instruction';
    9: Intel_feature_flags := 'APIC   On-chip Advanced Programmable Interrupt Controller present and enabled';
   10: Intel_feature_flags := '10     Reserved';
   11: Intel_feature_flags := 'SEP    Fast System Call';
   12: Intel_feature_flags := 'MTRR   Memory Type Range Registers';
   13: Intel_feature_flags := 'PGE    PTE Global Flag';
   14: Intel_feature_flags := 'MCA    Machine Check Architecture';
   15: Intel_feature_flags := 'CMOV   Conditional Move and Compare Instructions';
   16: Intel_feature_flags := 'FGPAT  Page Attribute Table';
   17: Intel_feature_flags := 'PSE-36 36-bit Page Size Extension';
   18: Intel_feature_flags := 'PN     Processor Serial Number present and enabled';
   19: Intel_feature_flags := 'CLFSH  CFLUSH instruction';
   20: Intel_feature_flags := '20     reserved';
   21: Intel_feature_flags := 'DS     Debug store';
   22: Intel_feature_flags := 'ACPI   Thermal Monitor and Clock Ctrl';
   23: Intel_feature_flags := 'MMX    MMX instruction set';
   24: Intel_feature_flags := 'FXSR   Fast FP/MMX Streaming SIMD Extensions save/restore';
   25: Intel_feature_flags := 'SSE    Streaming SIMD Extensions instruction set';
   26: Intel_feature_flags := 'SSE2   SSE2 extensions';
   27: Intel_feature_flags := 'SS     Self Snoop';
   28: Intel_feature_flags := 'HT     Hyper Threading';
   29: Intel_feature_flags := 'TM     Thermal monitor';
   30: Intel_feature_flags := '30     reserved';
   31: Intel_feature_flags := '31     reserved';
 end;
end;



procedure decode_intel_tlb(x: Byte);
begin
  if x <> 0 then
   begin
    Write(HexB(x), ' ');
    case x of
      0:;
      1: WriteLn(f, 'Instruction TLB: 4KB pages, 4-way set assoc, 32 entries');
      2: WriteLn(f, 'Instruction TLB: 4MB pages, 4-way set assoc, 2 entries');
      3: WriteLn(f, 'Data TLB: 4KB pages, 4-way set assoc, 64 entries');
      4: WriteLn(f, 'Data TLB: 4MB pages, 4-way set assoc, 8 entries');
      6: WriteLn(f, '1st-level instruction cache: 8KB, 4-way set assoc, 32 byte line size');
      8: WriteLn(f, '1st-level instruction cache: 16KB, 4-way set assoc, 32 byte line size');
     $a: WriteLn(f, '1st-level data cache: 8KB, 2-way set assoc, 32 byte line size');
     $c: WriteLn(f, '1st-level data cache: 16KB, 4-way set assoc, 32 byte line size');
    $40: WriteLn(f, 'No 2nd-level cache, or if 2nd-level cache exists, no 3rd-level cache');
    $41: WriteLn(f, '2nd-level cache: 128KB, 4-way set assoc, 32 byte line size');
    $42: WriteLn(f, '2nd-level cache: 256KB, 4-way set assoc, 32 byte line size');
    $43: WriteLn(f, '2nd-level cache: 512KB, 4-way set assoc, 32 byte line size');
    $44: WriteLn(f, '2nd-level cache: 1MB, 4-way set assoc, 32 byte line size');
    $45: WriteLn(f, '2nd-level cache: 2MB, 4-way set assoc, 32 byte line size');
    $50: WriteLn(f, 'Instruction TLB: 4KB and 2MB or 4MB pages, 64 entries');
    $51: WriteLn(f, 'Instruction TLB: 4KB and 2MB or 4MB pages, 128 entries');
    $52: WriteLn(f, 'Instruction TLB: 4KB and 2MB or 4MB pages, 256 entries');
    $5b: WriteLn(f, 'Data TLB: 4KB and 4MB pages, 64 entries');
    $5c: WriteLn(f, 'Data TLB: 4KB and 4MB pages, 128 entries');
    $5d: WriteLn(f, 'Data TLB: 4KB and 4MB pages, 256 entries');
    $66: WriteLn(f, '1st-level data cache: 8KB, 4-way set assoc, 64 byte line size');
    $67: WriteLn(f, '1st-level data cache: 16KB, 4-way set assoc, 64 byte line size');
    $68: WriteLn(f, '1st-level data cache: 32KB, 4-way set assoc, 64 byte line size');
    $70: WriteLn(f, 'Trace cache: 12K-micro-op, 4-way set assoc');
    $71: WriteLn(f, 'Trace cache: 16K-micro-op, 4-way set assoc');
    $72: WriteLn(f, 'Trace cache: 32K-micro-op, 4-way set assoc');
    $79: WriteLn(f, '2nd-level cache: 128KB, 8-way set assoc, sectored, 64 byte line size');
    $7a: WriteLn(f, '2nd-level cache: 256KB, 8-way set assoc, sectored, 64 byte line size');
    $7b: WriteLn(f, '2nd-level cache: 512KB, 8-way set assoc, sectored, 64 byte line size');
    $7c: WriteLn(f, '2nd-level cache: 1MB, 8-way set assoc, sectored, 64 byte line size');
    $82: WriteLn(f, '2nd-level cache: 256KB, 8-way set assoc, 32 byte line size');
    $83: WriteLn(f, '2nd-level cache: 512KB, 8-way set assoc 32 byte line size');
    $84: WriteLn(f, '2nd-level cache: 1MB, 8-way set assoc, 32 byte line size');
    $85: WriteLn(f, '2nd-level cache: 2MB, 8-way set assoc, 32 byte line size');
   else  WriteLn(f, 'unknown TLB/cache descriptor');
    end;
   end;
end;

procedure dointel(maxi: Longint);
var
 feature_flags, signature,
 eax, ebx, ecx, edx, unused: Longint;

 brand, clf, apic_id, stepping,
 model, family, ctype, ntlb,
 siblings, extended_family,
 extended_model, maxe : Byte;

 reserved, i: Longint;
 S: String[16];

begin
 extended_model := $ff;
 extended_family := $ff;
 WriteLn(f, 'Intel-specific functions:');
  if maxi >= 1 then
   begin
     {Family/model/type etc}
     cpuid(1, eax, ebx, unused, edx);
     WriteLn(f, 'Version: ',HexL(eax));
     stepping := eax and  $0f;
     model := (eax shr 4) and $0f;
     family := (eax shr  8) and $0f;
     ctype := (eax shr 12) and $03;
     reserved := eax shr 14;
     clf := (ebx shr 8) and $ff;
     apic_id := (ebx shr 24) and $ff;
     siblings := (ebx shr 16) and $ff;
     feature_flags := edx;

     Write('Type ', ctype, ' - ');
     case ctype of
       0: Write('Original OEM');
       1: Write('Overdrive');
       2: Write('Dual-capable');
       3: Write('Reserved');
     end;
     WriteLn(f);

     Write('Family ', family, ' - ');
     case family of
       3: Write('i386');
       4: Write('i486');
       5: Write('Pentium');
       6: Write('Pentium Pro');
      15: Write('Pentium IV');
     end;
     if family = 15 then
      begin
       extended_family := (eax shr 20) and $ff;
       Write('Extended family: ', extended_family);
      end;
     WriteLn(f);

     Write('Model ', model, ' - ');
     case family of
       3:;
       4: case model of
           0, 1: Write('DX');
              2: Write('SX');
              3: Write('487/DX2');
              4: Write('SL');
              5: Write('SX2');
              7: Write('write-back enhanced DX2');
              8: Write('DX4');
          end;
       5: case model of
              1: Write('60/66');
              2: Write('75-200');
              3: Write('for 486 system');
              4: Write('MMX');
          end;
       6: case model of
              1: Write('Pentium Pro');
              3: Write('Pentium II Model 3');
              5: Write('Pentium II Model 5/Xeon/Celeron');
              6: Write('Celeron');
              7: Write('Pentium III/Pentium III Xeon - external L2 cache');
              8: Write('Pentium III/Pentium III Xeon - internal L2 cache');
             13: Write('Intel(R) Pentium(R) M');
          end;
     end;
     WriteLn(f);
     if model = 15 then
      begin
       extended_model := (eax shr 16) and  $0f;
       WriteLn(f, 'Extended model ',extended_model);
      end;
     WriteLn(f, 'Stepping ',stepping);

     WriteLn(f, 'Reserved ',reserved);

     brand := ebx and $ff;
     if brand > 0 then
      begin
       Write('Brand index: ', brand, ' [');
       if brand  < MAXBRANDS then WriteLn(f, Brands(brand), ']')
       else WriteLn(f, 'not in table]');
      end;

     cpuid($80000000, eax, ebx, unused, edx);
     if eax and $80000000 <> 0 then
      begin
       (* Extended feature/signature bits supported *)
       maxe := eax and $f;
       if maxe >= 4 then
        begin
         Write('Extended brand string: ');
         for i := $80000002 to $80000004 do
          begin
           cpuid(i, S[1], S[5], S[9], S[13]);
           S[0] := #16;
           Write(Trim(S));
          end;
        end;
       WriteLn(f);
      end;

     if clf <> 0 then
      WriteLn(f, 'CLFLUSH instruction cache line size: ', clf);

     if apic_id <> 0 then
      WriteLn(f, 'Initial APIC ID: ', apic_id);

     if (feature_flags and (1 shl 28)) <> 0 then
      WriteLn(f, 'Hyper threading siblings: ', siblings);

     WriteLn(f, 'Feature flags: ',HexL(feature_flags));
     for i := 0 to 31 do
      begin
       if (feature_flags and  (1 shl i)) <> 0 then
        WriteLn(f, Intel_feature_flags(i));
      end;
     WriteLn(f);

     if maxi >= 2 then
      begin
        {Decode TLB and cache info}
        ntlb := 255;
        WriteLn(f, 'TLB and cache info:');
        while i < ntlb do
         begin
          inc(i);
          cpuid(2, eax, ebx, ecx, edx);
          ntlb :=  eax and $ff;
          decode_intel_tlb(eax shr 8);
          decode_intel_tlb(eax shr 16);
          decode_intel_tlb(eax shr 24);

          if (ebx and $80000000) = 0 then
           begin
            decode_intel_tlb(ebx);
            decode_intel_tlb(ebx shr 8);
            decode_intel_tlb(ebx shr 16);
            decode_intel_tlb(ebx shr 24);
           end;

          if (ecx and $80000000) = 0 then
           begin
            decode_intel_tlb(ecx);
            decode_intel_tlb(ecx shr 8);
            decode_intel_tlb(ecx shr 16);
            decode_intel_tlb(ecx shr 24);
           end;

          if (edx and $80000000) = 0 then
           begin
            decode_intel_tlb(edx);
            decode_intel_tlb(edx shr 8);
            decode_intel_tlb(edx shr 16);
            decode_intel_tlb(edx shr 24);
           end;
        end;
      end;
      WriteLn(f);
      if maxi >= 3 then
       begin
        {Pentium III CPU serial number}

        cpuid(1, signature, unused, unused, unused);
        cpuid(3, unused, unused, ecx, edx);
        Write('Processor serial: ');
        Write(HexW(signature shr 16));
        Write('-', HexW(signature and $ffff));
        Write('-', HexW(edx shr 16));
        Write('-', HexW(edx and $ffff));
        Write('-', HexW(ecx shr 16));
        Write('-', HexW(ecx and $ffff));
        WriteLn(f);
       end;
   end;
end;

function AMD_feature_flags(i: byte): String;
begin
 case i of
    0: AMD_feature_flags := 'Floating Point Unit';
    1: AMD_feature_flags := 'Virtual Mode Extensions';
    2: AMD_feature_flags := 'Debugging Extensions';
    3: AMD_feature_flags := 'Page Size Extensions';
    4: AMD_feature_flags := 'Time Stamp Counter (with RDTSC and CR4 disable bit)';
    5: AMD_feature_flags := 'Model Specific Registers with RDMSR & WRMSR';
    6: AMD_feature_flags := 'PAE - Page Address Extensions';
    7: AMD_feature_flags := 'Machine Check Exception';
    8: AMD_feature_flags := 'COMPXCHG8B Instruction';
    9: AMD_feature_flags := 'APIC';
   10: AMD_feature_flags := '10 - Reserved';
   11: AMD_feature_flags := 'SYSCALL/SYSRET or SYSENTER/SYSEXIT instructions';
   12: AMD_feature_flags := 'MTRR - Memory Type Range Registers';
   13: AMD_feature_flags := 'Global paging extension';
   14: AMD_feature_flags := 'Machine Check Architecture';
   15: AMD_feature_flags := 'Conditional Move Instruction';
   16: AMD_feature_flags := 'PAT - Page Attribute Table';
   17: AMD_feature_flags := 'PSE-36 - Page Size Extensions';
   18: AMD_feature_flags := '18 - reserved';
   19: AMD_feature_flags := '19 - reserved';
   20: AMD_feature_flags := '20 - reserved';
   21: AMD_feature_flags := '21 - reserved';
   22: AMD_feature_flags := 'AMD MMX Instruction Extensions';
   23: AMD_feature_flags := 'MMX instructions';
   24: AMD_feature_flags := 'FXSAVE/FXRSTOR';
   25: AMD_feature_flags := '25 - reserved';
   26: AMD_feature_flags := '26 - reserved';
   27: AMD_feature_flags := '27 - reserved';
   28: AMD_feature_flags := '28 - reserved';
   29: AMD_feature_flags := '29 - reserved';
   30: AMD_feature_flags := '3DNow! Instruction Extensions';
   31: AMD_feature_flags := '3DNow instructions';
 end;
end;


function Assocs(i: Byte): String;
begin
 case i of
     0: Assocs := 'L2 off';
     1: Assocs := 'Direct mapped';
     2: Assocs := '2-way';
     3: Assocs := 'reserved';
     4: Assocs := '4-way';
     5: Assocs := 'reserved';
     6: Assocs := '8-way';
     7: Assocs := 'reserved';
     8: Assocs := '16-way';
     9: Assocs := 'reserved';
    10: Assocs := 'reserved';
    11: Assocs := 'reserved';
    12: Assocs := 'reserved';
    13: Assocs := 'reserved';
    14: Assocs := 'reserved';
    15: Assocs := 'full';
 end;
end;

procedure doamd(maxi: Longint);
var
 feature_flags, signature, lmaxei,
 eax, ebx, ecx, edx, unused: Longint;

 brand, clf, apic_id, stepping,
 generation, model, family,
 ctype, ntlb, siblings,
 extended_family, extended_model,
 maxei, assoc : Byte;

 reserved, i: Longint;
 S: String[16];

begin
  WriteLn(f, 'AMD-specific functions:');

  if maxi >= 1 then
   begin
    cpuid(1, eax, ebx, unused, edx);
    stepping := eax and $0f;
    model := (eax shr 4) and $0f;
    family := (eax shr 8) and $0f;
    reserved := eax shr 12;

    WriteLn(f, 'Version: ', HexL(eax));
    WriteLn(f, 'Family: ', family, ' Model: ' ,model, ' [');
    case family of
      4: Write('486 Model ',model);
      5: case model of
          0, 1, 2, 3, 6, 7: Write('K6 Model ',model);
          8: Write('K6-2 Model 8');
          9: Write('K6-III Model 9');
          else Write('K5/K6 Model ',model);
         end;
      6: case model of
          1, 2, 4: Write('Athlon Model ', model);
          3: Write('Duron model 3');
          6: Write('Athlon MP/Mobile Athlon model 6');
          7: Write('Mobile Duron Model 7');
          else Write('Duron/Athlon model ', model);
         end;
    end;
    WriteLn(f, ']');

    WriteLn(f, 'Standard feature flags: ', HexL(ebx));
    for i := 0 to 31 do
     begin
      if (family = 5) and (model = 0) then
       begin
        if i = 9 then WriteLn(f, 'Global Paging Extensions')
        else
         begin
          if i = 13 then WriteLn(f, '13 - reserved')
          else
           begin
            if (edx and (1 shl i)) <> 0 then
             WriteLn(f, AMD_feature_flags(i));
           end;
         end;
       end;
     end;

    {Check for presence of extended info}
    cpuid($80000000, lmaxei, unused, unused, unused);
    maxei := lmaxei and $ff;
    if maxei <> 0 then
     begin

      if maxei >= 1 then
       begin
        cpuid($80000001, eax, ebx, ecx, edx);
        stepping := eax and $0f;
        model := (eax shr 4) and  $0f;
        generation := (eax shr 8) and $0f;
        reserved := eax shr 12;

        WriteLn(f, 'Generation: ', generation, ' Model: ', model);
        WriteLn(f, 'Extended feature flags: ', HexL(edx));
        for i := 0 to 31 do
         begin
          if (family = 5) and (model = 0) and (i = 9) then
            WriteLn(f, 'Global Paging Extensions')
          else if (edx and (1 shr i)) <> 0 then
                Write(AMD_feature_flags(i));
         end;
       end;
      WriteLn(f);
      if maxei >= 2 then
       begin
        {Processor identification string}
        Write('Processor name string: ');
        for i := $80000002 to $80000004 do
         begin
          cpuid(i, S[1], S[5], S[9], S[13]);
          S[0] := #16;
          Write(Trim(S));
         end;
        WriteLn(f);
       end;

      if maxei >= 5 then
       begin
        {TLB and cache info}
        cpuid($80000005, eax, ebx, ecx, edx);
        WriteLn(f, 'L1 Cache Information:');
        if family >= 6 then
         begin
          WriteLn(f, '2/4-MB Pages:');
          WriteLn(f, '   Data TLB: associativity ', (eax shr 24) and $ff,
                  '-way #entries ', (eax shr 16) and $ff);

          WriteLn(f, '   Instruction TLB: associativity ', (eax shr 8) and $ff,
                  '-way #entries ', eax and $ff);
         end;
        WriteLn(f, '4-KB Pages:');
        WriteLn(f, '   Data TLB: associativity ', (ebx shr 24) and $ff,
                '-way #entries ', (ebx shr 16) and $ff);
        WriteLn(f, '   Instruction TLB: associativity ', (ebx shr 8) and $ff,
                '-way #entries ', ebx and $ff);

        WriteLn(f, 'L1 Data cache:');
        WriteLn(f, '   size ', ecx shr 24,
                ' KB associativity ', (ecx shr 16) and $ff,
                '-way lines per tag ', (ecx shr 8) and $ff,
                ' line size ', ecx and $ff);

        WriteLn(f, 'L1 Instruction cache:');
        WriteLn(f, '   size ', edx shr 24,
                ' KB associativity ', (edx shr 16) and $ff,
                '-way lines per tag ', (edx shr 8) and $ff,
                ' line size ', edx and $ff);
        WriteLn(f);
       end;

       {check K6-III (and later?) on-chip L2 cache size}
       if maxei >= 6 then
        begin
         cpuid($80000006, eax, ebx, ecx, unused);
         WriteLn(f, 'L2 Cache Information:');
         if family >= 6 then
          begin
           WriteLn(f, '2/4-MB Pages:');
           assoc := (eax shr 24) and $ff;
           if assoc = 6 then assoc := 8;
           WriteLn(f, '   Data TLB: associativity ',
                   Assocs((eax shr 24) and $f),
                   ' #entries ', (eax shr 16) and $ff);
           assoc := (eax shr 16) and $ff;
           WriteLn(f, '   Instruction TLB: associativity ',
                   Assocs((eax shr 8) and $0f),
                   ' #entries ', eax and $ff);

           WriteLn(f, '4-KB Pages:');
           WriteLn(f, '   Data TLB: associativity ',
                   Assocs((ebx shr 24) and $0f),
                   ' #entries ', (ebx shr 16) and $ff);
           WriteLn(f, '   Instruction TLB: associativity',
                   Assocs((ebx shr 8) and $0f),
                   ' #entries ', ebx and $ff);
          end;
         WriteLn(f, '   size ', ecx shr 24,
                 ' KB associativity ',
                 Assocs((ecx shr 16) and $0f),
                 ' lines per tag ', (ecx shr 8) and $ff,
                 ' line size ', ecx and $ff);

         WriteLn(f);
        end;

       {Check power management feature flags}
       if maxei >= 7 then
        begin
         WriteLn(f, 'Advanced Power Management Feature Flags');
         cpuid($80000007, unused, unused, unused, edx);
         if (edx and 1) <> 0 then
           WriteLn(f, 'Has temperature sensing diode');
         if (edx and 2) <> 0 then
           WriteLn(f, 'Supports Frequency ID control');
         if (edx and 4) <> 0 then
           WriteLn(f, 'Supports Voltage ID control');
        end;

       {Check phys address & linear address size}
       if maxei >= 8 then
        begin
         cpuid($80000008, eax, unused, unused, unused);
         WriteLn(f, 'Maximum linear address: ', (eax shr 8) and $ff,
                 ' maximum phys address ', eax and $ff);
        end;
     end;
   end;
end;

function Cyrix_standard_feature_flags_5(i: byte): String;
begin
 case i of
     0: Cyrix_standard_feature_flags_5 := 'FPU   Floating Point Unit';
     1: Cyrix_standard_feature_flags_5 := 'V86   Virtual Mode Extensions';
     2: Cyrix_standard_feature_flags_5 := 'Debug Extension';
     3: Cyrix_standard_feature_flags_5 := '4MB Page Size';
     4: Cyrix_standard_feature_flags_5 := 'Time Stamp Counter';
     5: Cyrix_standard_feature_flags_5 := 'RDMSR/WRMSR (Model Specific Registers)';
     6: Cyrix_standard_feature_flags_5 := 'PAE';
     7: Cyrix_standard_feature_flags_5 := 'Machine Check Exception';
     8: Cyrix_standard_feature_flags_5 := 'COMPXCHG8B Instruction';
     9: Cyrix_standard_feature_flags_5 := 'APIC - On-chip Advanced Programmable Interrupt Controller present and enabled';
    10: Cyrix_standard_feature_flags_5 := '10 - Reserved';
    11: Cyrix_standard_feature_flags_5 := '11 - Reserved';
    12: Cyrix_standard_feature_flags_5 := 'MTRR  Memory Type Range Registers';
    13: Cyrix_standard_feature_flags_5 := '13 - reserved';
    14: Cyrix_standard_feature_flags_5 := 'Machine Check';
    15: Cyrix_standard_feature_flags_5 := 'CMOV  Conditional Move Instruction';
    16: Cyrix_standard_feature_flags_5 := '16 - reserved';
    17: Cyrix_standard_feature_flags_5 := '17 - reserved';
    18: Cyrix_standard_feature_flags_5 := '18 - reserved';
    19: Cyrix_standard_feature_flags_5 := '19 - reserved';
    20: Cyrix_standard_feature_flags_5 := '20 - reserved';
    21: Cyrix_standard_feature_flags_5 := '21 - reserved';
    22: Cyrix_standard_feature_flags_5 := '22 - reserved';
    23: Cyrix_standard_feature_flags_5 := 'MMX instructions';
    24: Cyrix_standard_feature_flags_5 := '24 - reserved';
    25: Cyrix_standard_feature_flags_5 := '25 - reserved';
    26: Cyrix_standard_feature_flags_5 := '26 - reserved';
    27: Cyrix_standard_feature_flags_5 := '27 - reserved';
    28: Cyrix_standard_feature_flags_5 := '28 - reserved';
    29: Cyrix_standard_feature_flags_5 := '29 - reserved';
    30: Cyrix_standard_feature_flags_5 := '30 - reserved';
 end;
end;

function Cyrix_standard_feature_flags_not5(i: byte): String;
begin
 case i of
     0: Cyrix_standard_feature_flags_not5 := 'FPU   Floating Point Unit';
     1: Cyrix_standard_feature_flags_not5 := 'V86   Virtual Mode Extensions';
     2: Cyrix_standard_feature_flags_not5 := 'Debug Extension';
     3: Cyrix_standard_feature_flags_not5 := '4MB Page Size';
     4: Cyrix_standard_feature_flags_not5 := 'Time Stamp Counter';
     5: Cyrix_standard_feature_flags_not5 := 'RDMSR/WRMSR (Model Specific Registers)';
     6: Cyrix_standard_feature_flags_not5 := 'PAE';
     7: Cyrix_standard_feature_flags_not5 := 'Machine Check Exception';
     8: Cyrix_standard_feature_flags_not5 := 'COMPXCHG8B Instruction';
     9: Cyrix_standard_feature_flags_not5 := 'APIC - On-chip Advanced Programmable Interrupt Controller present and enabled';
    10: Cyrix_standard_feature_flags_not5 := '10 - Reserved';
    11: Cyrix_standard_feature_flags_not5 := '11 - Reserved';
    12: Cyrix_standard_feature_flags_not5 := 'MTRR  Memory Type Range Registers';
    13: Cyrix_standard_feature_flags_not5 := 'Global Paging Extension';
    14: Cyrix_standard_feature_flags_not5 := 'Machine Check';
    15: Cyrix_standard_feature_flags_not5 := 'CMOV  Conditional Move Instruction';
    16: Cyrix_standard_feature_flags_not5 := '16 - reserved';
    17: Cyrix_standard_feature_flags_not5 := '17 - reserved';
    18: Cyrix_standard_feature_flags_not5 := '18 - reserved';
    19: Cyrix_standard_feature_flags_not5 := '19 - reserved';
    20: Cyrix_standard_feature_flags_not5 := '20 - reserved';
    21: Cyrix_standard_feature_flags_not5 := '21 - reserved';
    22: Cyrix_standard_feature_flags_not5 := '22 - reserved';
    23: Cyrix_standard_feature_flags_not5 := 'MMX instructions';
    24: Cyrix_standard_feature_flags_not5 := '24 - reserved';
    25: Cyrix_standard_feature_flags_not5 := '25 - reserved';
    26: Cyrix_standard_feature_flags_not5 := '26 - reserved';
    27: Cyrix_standard_feature_flags_not5 := '27 - reserved';
    28: Cyrix_standard_feature_flags_not5 := '28 - reserved';
    29: Cyrix_standard_feature_flags_not5 := '29 - reserved';
    30: Cyrix_standard_feature_flags_not5 := '30 - reserved';
 end;
end;


function Cyrix_extended_feature_flags(i: byte): String;
begin
 case i of
     0: Cyrix_extended_feature_flags := 'FPU   Floating Point Unit';
     1: Cyrix_extended_feature_flags := 'V86   Virtual Mode Extensions';
     2: Cyrix_extended_feature_flags := 'Debug Extension';
     3: Cyrix_extended_feature_flags := 'Page Size Extensions';
     4: Cyrix_extended_feature_flags := 'Time Stamp Counter';
     5: Cyrix_extended_feature_flags := 'Cyrix MSR';
     6: Cyrix_extended_feature_flags := 'PAE';
     7: Cyrix_extended_feature_flags := 'MC Exception';
     8: Cyrix_extended_feature_flags := 'COMPXCHG8B';
     9: Cyrix_extended_feature_flags := 'APIC on chip';
    10: Cyrix_extended_feature_flags := 'SYSCALL/SYSRET';
    11: Cyrix_extended_feature_flags := '11 - reserved';
    12: Cyrix_extended_feature_flags := 'MTRR';
    13: Cyrix_extended_feature_flags := 'Global bit';
    14: Cyrix_extended_feature_flags := 'Machine Check';
    15: Cyrix_extended_feature_flags := 'CMOV';
    16: Cyrix_extended_feature_flags := 'FPU CMOV';
    17: Cyrix_extended_feature_flags := '17 - reserved';
    18: Cyrix_extended_feature_flags := '18 - reserved';
    19: Cyrix_extended_feature_flags := '19 - reserved';
    20: Cyrix_extended_feature_flags := '20 - reserved';
    21: Cyrix_extended_feature_flags := '21 - reserved';
    22: Cyrix_extended_feature_flags := '22 - reserved';
    23: Cyrix_extended_feature_flags := 'MMX';
    24: Cyrix_extended_feature_flags := 'Extended MMX';
    25: Cyrix_extended_feature_flags := '25 - reserved';
    26: Cyrix_extended_feature_flags := '26 - reserved';
    27: Cyrix_extended_feature_flags := '27 - reserved';
    28: Cyrix_extended_feature_flags := '28 - reserved';
    29: Cyrix_extended_feature_flags := '29 - reserved';
    30: Cyrix_extended_feature_flags := '30 - reserved';
    31: Cyrix_extended_feature_flags := '3DNow instructions';
 end;
end;


{Decode Cyrix TLB and cache info descriptors}
procedure decode_cyrix_tlb(i: byte);
begin
 case i of
    0:;
  $70: WriteLn(f, 'TLB: 32 entries 4-way associative 4KB pages');
  $80: WriteLn(f, 'L1 Cache: 16KB 4-way associative 16 bytes/line');
 end;
end;


procedure docyrix(maxi: Longint);
var
 feature_flags, signature, lmaxei,
 eax, ebx, ecx, edx, unused: Longint;

 brand, clf, apic_id, stepping,
 generation, model, family,
 ctype, ntlb, siblings,
 extended_family, extended_model,
 maxei, assoc : Byte;

 reserved, i: Longint;
 S: String[16];

begin
  {Cyrix-specific information}
  WriteLn(f, 'Cyrix-specific functions');
  cpuid($80000000, lmaxei, unused, unused, unused);
  maxei := lmaxei and $ff;
  {Do standard stuff}
  if maxi >= 1 then
   begin
    cpuid(1, eax, unused, unused, edx);
    stepping := eax and $0f;
    model := (eax shr 4) and $0f;
    family := (eax shr 8) and $0f;
    reserved := eax shr 12;
    WriteLn(f, 'Family: ', family,
            ' Model: ', model, ' [');
    case family of
     4:
      case model of
       4: Write('MediaGX');
      end;
     5:
      case model of
       2: Write('6x86');
       4: Write('BXm');
      end;
     6:
      case model of
       0: Write('6x86/MX');
      end;
    end;
    WriteLn(f, ']');
    WriteLn(f);
    if (family = 5) and (model = 0) then
     begin
      for i := 0 to 31 do
       begin
        if (edx and (1 shl i)) <> 0 then
          WriteLn(f, Cyrix_standard_feature_flags_5(i));
       end;
     end
    else
     begin
      for i := 0 to 31 do
       begin
        if (edx and (1 shl i)) <> 0 then
          WriteLn(f, Cyrix_standard_feature_flags_not5(i));
       end;
     end;
   end;

  if maxi >= 2 then
   begin
    {TLB and L1 Cache info}
    ntlb := 255;
    i := 0;
    while i < ntlb do
     begin
      inc(i);
      cpuid(2, eax, unused, unused, edx);
      ntlb :=  eax and $ff;
      decode_cyrix_tlb((eax shr 8) and $ff);
      decode_cyrix_tlb((eax shr 16) and $ff);
      decode_cyrix_tlb((eax shr 24) and $ff);

      if (edx and $80000000) = 0 then
       begin
        decode_cyrix_tlb(edx and $ff);
        decode_cyrix_tlb((edx shr 8) and $ff);
        decode_cyrix_tlb((edx shr 16) and $ff);
        decode_cyrix_tlb((edx shr 24) and $ff);
       end;
     end;
    WriteLn(f);
   end;

  if maxei > 0 then
   begin
    WriteLn(f, 'Extended info:');
    if maxei >= 1 then
     begin
      cpuid($80000001, eax, ebx, ecx, edx);
      stepping := eax and $0f;
      model := (eax shr 4) and $0f;
      family := (eax shr 8) and $0f;
      reserved := eax shr 12;
      Write('Family: ', family,
            ' Model: ', model, ' [');
      case family of
       4: Write('MediaGX');
       5: Write('6x86/GXm');
       6: Write('6x86/MX');
      end;
      WriteLn(f, ']');

      WriteLn(f, 'Extended feature flags:');
      for i:= 0 to 31 do
        if (edx and (1 shl i)) <> 0 then
          WriteLn(f, Cyrix_extended_feature_flags(i));
     end;
    WriteLn(f);

    if maxei >= 2 then
     begin
      {Processor identification string}
      Write('Processor name string: ');
      for i := $80000002 to $80000004 do
       begin
        cpuid(i, S[1], S[5], S[9], S[13]);
        S[0] := #16;
        Write(Trim(S));
       end;
      WriteLn(f);
     end;

    if maxei >= 5 then
     begin
      {TLB and L1 Cache info}
      ntlb := 255;
      i := 0;
      while i < ntlb do
       begin
        inc(i);
        cpuid($80000005, eax, ebx, ecx, unused);
        ntlb :=  eax and $ff;
        decode_cyrix_tlb((ebx shr 8) and $ff);
        decode_cyrix_tlb((ebx shr 16) and $ff);
        decode_cyrix_tlb((ebx shr 24) and $ff);

        if ((ecx and $80000000) = 0) then
         begin
          decode_cyrix_tlb(ecx and $ff);
          decode_cyrix_tlb((ecx shr 8) and $ff);
          decode_cyrix_tlb((ecx shr 16) and $ff);
          decode_cyrix_tlb((ecx shr 24) and $ff);
         end;
       end;
     end;
   end;

end;


Type
  pString = ^String;
  UData = Record  { typecasted over device's UserData (16 bytes) }
            PStr : pString; { 4 bytes, string to use }
            fill : array[1..12] of byte;
          End;




Function WindowWrite(var F: TextRec): Integer; far;
var
 ch: Char;
Begin
  With F, UData(UserData)  do
  Begin
    ch := pchar(BufPtr)^;
    if ch = #13 then
     begin
      PutNewStr(pStr^);
      pStr^ := '';
     end
    else
    if ch <> #10 then
     begin
      inc(pStr^[0]);
      pStr^[Length(pStr^)] := ch;
     end;
    BufPos := 0;
  End;
  WindowWrite := 0;
End;

Function WindowOpen(var F: TextRec): Integer; far;
{}
Begin
  WindowOpen := 0;
  With F, UData(UserData)  do
  Begin
    InOutFunc  := @WindowWrite;
    FlushFunc  := nil;
    pStr^ := '';
  End;
End;

Function WindowClose(var F: TextRec): Integer; far;
{}
Begin
  WindowClose := 0;
End;

Procedure AssignStrDevice(var T: Text; pout: pString);
{}
Begin
  With TextRec(T), UData(UserData) do
  Begin
    Handle := $FFFF;
    Mode := fmClosed;
    BufSize := 1;
    BufPtr := @Buffer;
    OpenFunc := @WindowOpen;
    CloseFunc := @WindowClose;
    pStr := pOut;
  End;
End;

procedure CPU_PRT;
var
  i, li, lmaxi, maxei, unused, eax, ebx, ecx, edx: longint;
  maxi: Word;
  S, SO: String[80];

 begin
  {Insert code here to test if CPUID instruction is available}

  AssignStrDevice(f, @SO);
  if cpuidtst then
   begin
    ReWrite(f);
    {Dump all the CPUID results in raw hex}
    cpuid(0, lmaxi, unused, unused, unused);
    maxi := Word(lmaxi);
    WriteLn(f, 'eax in   eax      ebx      ecx      edx');
    for i := 0 to maxi do
     begin
      cpuid(i, eax, ebx, ecx, edx);
      WriteLn(f, HexL(i), ' ', HexL(eax), ' ', HexL(ebx), ' ',
                            HexL(ecx), ' ', HexL(edx));
     end;
    cpuid($80000000, maxei, unused, unused, unused);
    for li := $80000000 to maxei do
     begin
      cpuid(li, eax, ebx, ecx, edx);
      WriteLn(f, HexL(li), ' ', HexL(eax), ' ', HexL(ebx), ' ',
                             HexL(ecx), ' ', HexL(edx));
     end;

    {Vendor ID and max CPUID level supported}
    cpuid($0, eax, S[1], S[9], S[5]);
    S[0] := #12;
    WriteLn(f, #13#10'Vendor ID: ', S,' CPUID level: ', maxi);
    cpuid(0, eax, ebx, ecx, edx);
    if ebx = $756e6547 then dointel(lmaxi)
    else
    if ebx = $68747541 then doamd(lmaxi)
    else
    if ebx = $69727943 then docyrix(lmaxi)
    else WriteLn(f, 'Unknown vendor.');
   end
  else WriteLn(f, 'CPUID not supported');
  Close(f);
 end;
end.