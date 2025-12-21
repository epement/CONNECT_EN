Uses int2f;
const
  ver_Platform_Win32s = 0;
  ver_Platform_Win32_Windows = 1;
  ver_Platform_Win32_NT = 2;
  PROCESSOR_INTEL_386     = 386;
  PROCESSOR_INTEL_486     = 486;
  PROCESSOR_INTEL_PENTIUM = 586;

  PROCESSOR_ARCHITECTURE_INTEL   = 0;

  PROCESSOR_ARCHITECTURE_UNKNOWN = $ffff;


type
 TSysInfo = record
    dwOSVersionInfoSize: Longint;
    dwMajorVersion: Longint;
    dwMinorVersion: Longint;
    dwBuildNumber: Longint;
    dwPlatformId: Longint;
    szCSDVersion: array[0 .. 127] of char;

    dwLength: Longint;        {// sizeof(MEMORYSTATUS)}
    dwMemoryLoad: Longint;    {// percent of memory in use}
    dwTotalPhys: Longint;     {// bytes of physical memory}
    dwAvailPhys: Longint;     {// free physical memory bytes}
    dwTotalPageFile: Longint; {// bytes of paging file}
    dwAvailPageFile: Longint; {// free bytes of paging file}
    dwTotalVirtual: Longint;  {// user bytes of address space}
    dwAvailVirtual: Longint;  {// free user bytes}

    wProcessorArchitecture: Word;
    wReserved: Word;
    dwPageSize : Longint;
    lpMinimumApplicationAddress: Longint;
    lpMaximumApplicationAddress: Longint;
    dwActiveProcessorMask: Longint;
    dwNumberOfProcessors: Longint;
    dwProcessorType: Longint;
    dwAllocationGranularity: Longint;
    wProcessorLevel: Word;
    wProcessorRevision: Word;
    ComputerName: Array[0..127] of char;
    UserName: Array[0..127] of char;
 end;
var
 Result: Longint;
 cmd, redir: PChar;
 SI: TSysInfo;
 CPUSpeed: Longint;
begin
 Inst_CN_NT;
 CPUSpeed := SysInfo(SI);
 with SI do
  begin
   WriteLn('Computer name: ', ComputerName);
   WriteLn('User name: ', UserName);
   WriteLn;
   WriteLn('CPU speed :', CPUSpeed, 'MHz');
   if wProcessorArchitecture = PROCESSOR_ARCHITECTURE_INTEL then
    begin
     Write(dwNumberOfProcessors,' CPUs: Intel ');
     case wProcessorLevel of
      3: Write('80386 ');
      4: Write('80486 ');
      5: Write('Pentium ');
      else Write('Type ', wProcessorLevel);
     end;
     case wProcessorLevel of
      3, 4: if Hi(wProcessorRevision) = $ff then
            Write(' Rev ', Lo(wProcessorRevision));
      5: Write(' model ', Hi(wProcessorRevision),
               ' step ', Lo(wProcessorRevision));
     end;
    WriteLn;
    end;

   case dwPlatformId of
    VER_PLATFORM_WIN32s:
     WriteLn('Win32s ',dwMajorVersion, '.', dwMinorVersion,
             ' build ', Word(dwBuildNumber));

    VER_PLATFORM_WIN32_WINDOWS:
     WriteLn('Windows 9x ',dwMajorVersion, '.', dwMinorVersion,
             ' build ', Word(dwBuildNumber), ' ', szCSDVersion);

    VER_PLATFORM_WIN32_NT:
     WriteLn('Windows NT ',dwMajorVersion, '.', dwMinorVersion,
             ' build ', Word(dwBuildNumber), ' ', szCSDVersion);
   end;

   WriteLn('used:          ', dwMemoryLoad:5, '%'#13#10,
           'Total phys:    ', dwTotalPhys/1024:5:3, ' Kb, ',
           'free: ', dwAvailPhys/1024:5:3, ' Kb'#13#10,
           'Max page file: ', dwTotalPageFile/1048576:5:3, ' Mb, ',
           'free: ', dwAvailPhys/1048576:5:3, ' Mb'#13#10,
           'Total virt:    ', dwTotalVirtual/1048576:5:3, ' Mb, ',
           'free: ', dwAvailVirtual/1048576:5:3, ' Mb'#13#10);

  end;
end.