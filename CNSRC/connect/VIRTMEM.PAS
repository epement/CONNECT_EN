{$S-,R-,V-,I-,B-,F+}
{$IFNDEF Ver40}
{$S-,O-}
{$ENDIF}
{$I TADEFINE.INC}

{.$DEFINE TakeStats}

{*********************************************************}
{*                   VIRTMEM.PAS 7.00                    *}
{*     Copyright (c) TurboPower Software 1990, 1993.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit VirtMem;
  {-Virtual memory heap interface}

interface

uses
  Dos;

var
  {Function pointers redirected for current virtual memory device}
  GetVirtFunc : Pointer;
  FreeVirtProc : Pointer;
  DerefFunc : Pointer;
  MemAvailFunc : Pointer;
  MaxAvailFunc : Pointer;
  ReleaseProc : Pointer;

type
  VirtMemType = (NoVirtMem, EmsVirtMem, XmsVirtMem, DiskVirtMem
                 {$IFDEF Debug}
                 , DebugVirtMem
                 {$ENDIF}
                 );

{$IFDEF TakeStats}
const
  Merges : LongInt = 0; {New free list item merged with an existing one}
  Splits : LongInt = 0; {Part of a free list item taken for a getmem request}
  Kills  : LongInt = 0; {Free list record removed from free list}
  Adds   : LongInt = 0; {New free list record added to list}
  Loads  : LongInt = 0; {Page had to be loaded into RAM from virtual memory}
  Scans  : LongInt = 0; {Scanned existing pages to see if one was loaded}
{$ENDIF}

{$IFDEF Debug}
procedure InitDebugVirtMem;
  {-Use special routines that aid in debugging}
{$ENDIF}

function InitEmsVirtMem(EmsPages : Word;
                        FreeRecs : Word) : Word;
  {-Initialize to use EMS for virtual memory}

function InitDiskVirtMem(FileName : string;
                         RamPages : Word;
                         PageSize : Word;
                         FreeRecs : Word) : Word;
  {-Initialize to use disk space for virtual memory}

function InitXmsVirtMem(KBytesInXms : Word;
                        RamPages : Word;
                        PageSize : Word;
                        FreeRecs : Word) : Word;
  {-Initialize to use XMS for virtual memory}

procedure ReleaseVirtMem;
  {-Release the current virtual memory space}
inline($FF/$1E/>ReleaseProc);

function VirtMemDevice : VirtMemType;
  {-Return the current category of virtual memory device}

function GetMemCheck(var P; Bytes : Word) : Boolean;
  {-Allocate bytes on normal heap, returning True if successful}

procedure FreeMemCheck(var P; Bytes : Word);
  {-Deallocate P and set to nil unless P is outside of normal heap}

function GetVirtCheck(var P; Bytes : Word) : Boolean;
  {-Allocate bytes from current virtual heap (normal heap if NoVirtMem)}
inline($FF/$1E/>GetVirtFunc);

procedure FreeVirtCheck(var P; Bytes : Word);
  {-Free memory on virtual heap}
inline($FF/$1E/>FreeVirtProc);

function Deref(P : Pointer) : Pointer;
  {-Dereference virtual pointer P, returning a physical pointer.
    Call only for pointers allocated via GetVirtCheck.}
inline($FF/$1E/>DerefFunc);

function VirtMemAvail : LongInt;
  {-Return total free bytes of virtual memory}
inline($FF/$1E/>MemAvailFunc);

function VirtMaxAvail : LongInt;
  {-Return maximum available single block of virtual memory}
inline($FF/$1E/>MaxAvailFunc);

function VirtFreeCount : Word;
  {-Return number of free list elements}

procedure DumpFreeList;
  {-Write a dump of the free list}

  {=======================================================================}

implementation

const
  VirtM : VirtMemType = NoVirtMem;

const
  {$IFNDEF Ver40}
  MaxPages = (65520 div SizeOf(Pointer));
  {$ELSE}
  MaxPages = 16380;
  {$ENDIF}

type
  OS =
    record
      O, S : Word;
    end;

  Page = array[0..65520] of Byte;
  PagePtr = ^Page;
  PageArray = array[1..MaxPages] of PagePtr;
  PageArrayPtr = ^PageArray;
  WordArray = array[1..MaxPages] of Word;
  WordArrayPtr = ^WordArray;

  PagedMemPtr =
    record
      PageOfs : Word;               {Offset within page}
      PageNum : Word;               {Logical page number}
    end;

  FreeListRec =
    record
      FreePtr  : PagedMemPtr;       {Block that is free}
      FreeSize : LongInt;           {Size of the free block}
    end;
  FreeListArray = array[1..8191] of FreeListRec;
  FreeListArrayPtr = ^FreeListArray;

var
  gPages : PageArrayPtr;            {Pointer to array of RAM pages}
  gPageLoaded : WordArrayPtr;       {Which logical page in each RAM page}
  gPageUsed : WordArrayPtr;         {When each RAM page was last used}

  gAllocPageLoaded : Pointer;       {Allocated block for page loaded}
  gAllocPageLoadedSize : Word;      {Size of allocated block}
  gTestPages : Word;                {Equals gRamPageCount+1}

  gPageSize : Word;                 {Size of each page}
  gRamPageCount : Word;             {Number of pages in RAM}
  gLogPageCount : Word;             {Maximum number of logical pages}
  gAccessCount : Word;              {Counter for each page access}
  gNextFreePage : Word;             {Next free page to allocate from}
  gReservedPage : Word;             {Highest page reserved}
  gNextFreeOfst : Word;             {Next free offset within next free page}
  gFreeRecsPerPage : Word;          {Number of free records that fit on a page}
  gFreeCount : Word;                {Maximum number of free list records}
  gFreeUsed : Word;                 {Number of free list records used}
  gFreePagesUsed : Word;            {Number of pages containing used free recs}
  gFile : File;                     {File variable to access DOS file}
  gHandle : Word absolute gFile;    {Handle to access EMS, XMS, File}

  gDrive : Byte;                    {Drive number of disk file}
  gAllocated : Boolean;             {True when EMS, XMS, or file allocated}

  SaveExit : pointer;               {Previous exit chain pointer}
  ReserveFunc : pointer;            {Routine that reserves allocated space}
  SwapFunc : pointer;               {Routine that swaps two logical pages}
  FreeActFunc : pointer;            {Routine that acts on free list items}

  procedure CriticalError(Number : Word);
    {-Called when a critical error occurs}
  begin
    WriteLn(^M^J'VirtMem Critical Error: ', Number);
    Halt;
  end;

  {----------------------------- normal memory ------------------------------}

{$IFDEF DPMI}
  function NormalDeref(P : Pointer) : Pointer; far; assembler;
  asm
    mov ax,word ptr P;
    mov dx,word ptr P+2;
  end;
{$ELSE}
const
  NormalDeref : array[1..13] of Byte =
    ($89, $E3,           {mov bx,sp}
     $36, $8B, $47, $04, {mov ax, ss:[bx+4]}
     $36, $8B, $57, $06, {mov dx, ss:[bx+6]}
     $CA, $04, $00);     {retf 4}
{$ENDIF}

  function HeapFunc(Size : Word) : Integer;
    {-Return nil pointer if insufficient memory}
  begin
    HeapFunc := 1;
  end;

  function GetMemCheck(var P; Bytes : Word) : Boolean;
    {-Allocate heap space, returning true if successful}
  var
    Pt : Pointer absolute P;
  begin
    GetMem(Pt, Bytes);
    GetMemCheck := (Pt <> nil);
  end;

  procedure FreeMemCheck(var P; Bytes : Word);
    {-Deallocate heap space on normal heap}
  var
    Pt : Pointer absolute P;
  begin
{$IFDEF Dpmi}
    if Pt <> nil then begin
{$ELSE}
    if (OS(Pt).S >= OS(HeapOrg).S) and
  {$IFDEF Heap6}
       (OS(Pt).S <= OS(HeapEnd).S) then begin
  {$ELSE}
       (OS(Pt).S <= OS(FreePtr).S+$1000) then begin
  {$ENDIF}
{$ENDIF}
      FreeMem(Pt, Bytes);
      Pt := nil;
    end;
  end;

  procedure NormalRelease;
    {-Release for normal heap does nothing}
  begin
    VirtM := NoVirtMem;
  end;

  function NormalMemAvail : LongInt;
    {-MemAvail for normal heap}
  begin
    NormalMemAvail := MemAvail;
  end;

  function NormalMaxAvail : LongInt;
    {-MaxAvail for normal heap}
  begin
    NormalMaxAvail := MaxAvail;
  end;

  procedure InitNoVirtMem;
    {-Set function pointers for no virtual memory}
  begin
    GetVirtFunc := @GetMemCheck;
    FreeVirtProc := @FreeMemCheck;
    DerefFunc := @NormalDeref;
    MemAvailFunc := @NormalMemAvail;
    MaxAvailFunc := @NormalMaxAvail;
    ReleaseProc := @NormalRelease;
    VirtM := NoVirtMem;
  end;

  {----------------------------- debug memory ------------------------------}

  {$IFDEF Debug}
  function GetDebug(var P; Bytes : Word) : Boolean;
  var
    TP : ^Pointer absolute P;
  begin
    GetDebug := False;
    if GetMemCheck(TP, SizeOf(Pointer)) then
      if GetMemCheck(TP^, Bytes) then
        GetDebug := True;
  end;

  procedure FreeDebug(var P; Bytes : Word);
  var
    TP : ^Pointer absolute P;
  begin
    if TP <> nil then begin
      if TP^ <> nil then
        FreeMem(TP^, Bytes);
      FreeMem(TP, SizeOf(Pointer));
      TP := nil;
    end;
  end;

  function DerefDebug(P : Pointer) : Pointer;
  var
    TP : ^Pointer absolute P;
  begin
    {Validate the pointers when debugging}
    if (OS(P).S < OS(HeapOrg).S) or
       (OS(P).S > OS(HeapEnd).S) then
      {Invalid pointer}
      CriticalError(204)
    else begin
      TP := TP^;
      if (OS(TP).S < OS(HeapOrg).S) or
         (OS(TP).S > OS(HeapEnd).S) then
        {Invalid pointer}
        CriticalError(204)
      else
        DerefDebug := TP;
    end;
  end;

  procedure InitDebugVirtMem;
    {-Use special routines that aid in debugging}
  begin
    if VirtM <> NoVirtMem then
      ReleaseVirtMem;
    GetVirtFunc := @GetDebug;
    FreeVirtProc := @FreeDebug;
    DerefFunc := @DerefDebug;
    MemAvailFunc := @NormalMemAvail;
    MaxAvailFunc := @NormalMaxAvail;
    ReleaseProc := @NormalRelease;
    VirtM := DebugVirtMem;
  end;
  {$ENDIF}

  {----------------------- general virtual routines ------------------------}

  function VirtMemDevice : VirtMemType;
    {-Return the current category of virtual memory device}
  begin
    VirtMemDevice := VirtM;
  end;

  function VirtFreeCount : Word;
    {-Return number of free list elements}
  begin
    VirtFreeCount := gFreeUsed;
  end;

  procedure ShutDown;
    {-Called when program halts}
  begin
    ExitProc := SaveExit;
    if VirtM <> NoVirtMem then
      ReleaseVirtMem;
  end;

  procedure InitNoPages;
    {-Initialize to prepare for error}
  begin
    gPages := nil;
    gAllocPageLoaded := nil;
    gAllocPageLoadedSize := 0;
    gPageUsed := nil;
    gRamPageCount := 0;
    gAllocated := False;
    {$IFDEF TakeStats}
    Merges := 0;
    Splits := 0;
    Kills  := 0;
    Adds   := 0;
    Loads  := 0;
    Scans  := 0;
    {$ENDIF}
  end;

  function AllocAndZero(var P; Bytes : Word) : Boolean;
    {-Allocate normal memory and fill it with zeros}
  var
    Pt : pointer absolute P;
  begin
    if GetMemCheck(P, Bytes) then begin
      FillChar(Pt^, Bytes, 0);
      AllocAndZero := True;
    end else
      AllocAndZero := False;
  end;

  function AllocPages(RamPages : Word; PageSize : Word;
                      GetPageBuffers : Boolean) : Word;
    {-Allocate RAM pages}
  var
    I : Word;
  begin
    {Assume insufficient memory}
    AllocPages := 203;

    {Allocate page arrays}
    if not AllocAndZero(gPages, RamPages*SizeOf(PagePtr)) then
      Exit;

    {Various optimizations are applied to gPageLoaded because
     it is searched so frequently. gTestPages defines an extra
     sentinel element for faster searching}
    gTestPages := RamPages+1;
    gAllocPageLoadedSize := (gTestPages*SizeOf(Word))+15;
    if not AllocAndZero(gAllocPageLoaded, gAllocPageLoadedSize) then
      Exit;
    {Assure gPageLoaded^ is on a paragraph boundary}
    if OS(gAllocPageLoaded).O = 0 then
      gPageLoaded := gAllocPageLoaded
    else
      gPageLoaded := Ptr(OS(gAllocPageLoaded).S+1, 0);

    if not AllocAndZero(gPageUsed, RamPages*SizeOf(Word)) then
      Exit;

    {Allocate pages}
    if GetPageBuffers then
      for I := 1 to RamPages do
        if not AllocAndZero(gPages^[I], PageSize) then
          Exit;

    {Initialize global variables for managing the pages}
    gAccessCount := 0;
    gPageSize := PageSize;
    gRamPageCount := RamPages;

    {Success}
    AllocPages := 0;
  end;

  function ReserveLogicalPage(LogPage : Word) : Word;
    {-Reserve space for specified logical page}
  inline($FF/$1E/>ReserveFunc);

  function InitFreeList(FreeRecs : Word) : Word;
    {-Set up free list}
  var
    Status : Word;
    Done : Boolean;
  begin
    {Compute number of free recs per page (always an integral quantity)}
    gFreeRecsPerPage := gPageSize div SizeOf(FreeListRec);

    {Assure free recs fit into no more than half of virtual memory}
    if LongInt(2)*(FreeRecs+gFreeRecsPerPage-1) div gFreeRecsPerPage >
       gLogPageCount then begin
      InitFreeList := 204;
      Exit;
    end;

    {Initialize globals}
    gFreeCount := FreeRecs;
    gFreeUsed := 0;
    gFreePagesUsed := 0;
    gNextFreePage := 0;
    gReservedPage := 0;
    gNextFreeOfst := 0;

    {Reserve space for free records}
    Done := False;
    while not Done do begin
      {Reserve some portion of next disk page for free records}
      inc(gNextFreePage);
      Status := ReserveLogicalPage(gNextFreePage);
      if Status <> 0 then begin
        InitFreeList := Status;
        Exit;
      end;
      if FreeRecs >= gFreeRecsPerPage then
        {Continue to get another page}
        dec(FreeRecs, gFreeRecsPerPage)
      else begin
        {Adjust next free offset and force exit from loop}
        gNextFreeOfst := FreeRecs*SizeOf(FreeListRec);
        Done := True;
      end;
    end;

    InitFreeList := 0;
  end;

  function InitPages(RamPages, PageSize, FreeRecs : Word) : Word;
    {-Allocate RAM buffers, set up free list, prepare first data page}
  var
    Status : Word;
  begin
    {Allocate RAM buffers}
    Status := AllocPages(RamPages, PageSize, True);
    if Status <> 0 then begin
      InitPages := Status;
      Exit;
    end;

    {Initialize the free list}
    Status := InitFreeList(FreeRecs);
    if Status <> 0 then begin
      InitPages := Status;
      Exit;
    end;

    InitPages := 0;
  end;

  procedure FreePages(FreePageBuffers : Boolean);
    {-Release page buffers, if allocated}
  var
    I : Word;
  begin
    if FreePageBuffers and (gPages <> nil) then
      for I := gRamPageCount downto 1 do
        FreeMemCheck(gPages^[I], gPageSize);
    FreeMemCheck(gPageUsed, gRamPageCount*SizeOf(Word));
    FreeMemCheck(gAllocPageLoaded, gAllocPageLoadedSize);
    FreeMemCheck(gPages, gRamPageCount*SizeOf(PagePtr));
  end;

  function ScanForPage(LogPage : Word) : Word;
    {-Return physical page for logical page,
      >gRamPageCount if not in any physical page}
  Inline(
    $58/                   {pop ax                  ;ax = page to scan for}
    $C4/$3E/>gPageLoaded/  {les di,[>gPageLoaded]   ;es:di -> pageloaded array (di=0)}
    $8B/$0E/>gTestPages/   {mov cx,[>gTestPages]    ;cx = number of pages to scan}
    $FC/                   {cld                     ;forward}
    $F2/                   {repne                   ;repeat while not equal}
    $AF/                   {scasw                   ;scan words}
    $89/$F8/               {mov ax,di               ;get result into ax}
    $D1/$E8);              {shr ax,1                ;return index into array}

  function ScanForOldestPage : Word;
    {-Return the index of the oldest page, or an unused page}
  Inline(
    $1E/                   {  push ds                       ;save ds}
    $BA/$FF/$FF/           {  mov dx,$FFFF                  ;dx = OldestAccess}
    $B8/$01/$00/           {  mov ax,1                      ;ax = Page}
    $8B/$0E/>gRamPageCount/{  mov cx,[>gRamPageCount]       ;cx = loop count}
    $C4/$3E/>gPageLoaded/  {  les di,[>gPageLoaded]         ;es:di -> gPageLoaded array}
    $C5/$36/>gPageUsed/    {  lds si,[>gPageUsed]           ;ds:si -> gPageUsed array}
                           {next:}
    $26/                   {  es:}
    $83/$3D/$00/           {  cmp word ptr [di],0           ;is page unused?}
    $74/$13/               {  jz  done                      ;done if so (page in ax)}
    $39/$14/               {  cmp [si],dx                   ;is page older than oldest so far?}
    $73/$04/               {  jae nextpage                  ;jump if not}
    $8B/$14/               {  mov dx,[si]                   ;save oldest counter}
    $89/$C3/               {  mov bx,ax                     ;save corresponding page}
                           {nextpage:}
    $40/                   {  inc ax                        ;next page}
    $83/$C7/$02/           {  add di,2                      ;next gPageLoaded index}
    $83/$C6/$02/           {  add si,2                      ;next gPageUsed index}
    $E2/$E9/               {  loop next                     ;loop over all pages}
    $89/$D8/               {  mov ax,bx                     ;return oldest page}
                           {done:}
    $1F);                  {  pop ds                        ;restore ds}

  procedure UpdateUsed(PhysPage : Word);
    {-Update the usage counter for PhysPage}
  begin
    if gAccessCount = $FFFF then begin
      {Ready for wraparound, reset all pages}
      FillChar(gPageUsed^, gRamPageCount*SizeOf(Word), 0);
      gAccessCount := 0;
    end;
    inc(gAccessCount);
    gPageUsed^[PhysPage] := gAccessCount;
  end;

  function SwapPages(PhysPage : Word;
                     var OldLogPage : Word;
                     NewLogPage : Word) : Word;
    {-Write out old logical page, read in new logical page}
  inline($FF/$1E/>SwapFunc);

  function LoadPage(LogPage : Word) : Word;
    {-Find logical page in memory, or load it if required}
  var
    PhysPage : Word;
    Status : Word;
  begin
    {See if PhysPage is already in memory}
    PhysPage := ScanForPage(LogPage);

    {$IFDEF TakeStats}
    inc(Scans);
    {$ENDIF}

    if PhysPage > gRamPageCount then begin
      {Page not in RAM already, find oldest available page buffer}
      PhysPage := ScanForOldestPage;

      {$IFDEF TakeStats}
      inc(Loads);
      {$ENDIF}

      {Save the current page contents and read the new logical page}
      Status := SwapPages(PhysPage, gPageLoaded^[PhysPage], LogPage);
      if Status <> 0 then begin
        gPageLoaded^[PhysPage] := 0;
        CriticalError(Status);
        LoadPage := 0;
        Exit;
      end;
    end;

    {Update the access counter}
    UpdateUsed(PhysPage);

    LoadPage := PhysPage;
  end;

  function ActOnFreeItem(FItem : Word; var FRec : FreeListRec; var D) : Word;
    {-Called for each free record}
    {Result =0:Continue scanning
            =1:Stop scanning now
           >=2:Error}
  inline($FF/$1E/>FreeActFunc);

  function ScanFreeList(ActionFunc: Pointer; var D) : Word;
    {-Scan the free list in physical order, calling ActionFunc for each item}
    {Result =0:Scanned all items successfully,
            =1:Scanned items successfully until ActionFunc said to stop,
           >=2:Error}
  var
    Page : Word;
    FPage : Word;
    FUsed : Word;
    FItem : Word;
    FLoop : Word;
    Status : Word;
    FLP : FreeListArrayPtr;
  begin
    {Store the global function pointer}
    FreeActFunc := ActionFunc;

    {FUsed will be the number of remaining free recs to check}
    FUsed := gFreeUsed;

    {Scan the pages of free records}
    for FPage := 1 to gFreePagesUsed do begin
      {Load next page of free records}
      Page := LoadPage(FPage);
      if Page = 0 then begin
        {Error loading free list page}
        ScanFreeList := 2;
        Exit;
      end;

      {Scan the free records on this page}
      FLP := FreeListArrayPtr(gPages^[Page]);
      if FUsed > gFreeRecsPerPage then
        FLoop := gFreeRecsPerPage
      else
        FLoop := FUsed;
      for FItem := 1 to FLoop do begin
        Status := ActOnFreeItem(FItem, FLP^[FItem], D);
        if Status <> 0 then begin
          ScanFreeList := Status;
          Exit;
        end;
      end;

      {Now have scanned all the records on this page}
      dec(FUsed, gFreeRecsPerPage);
    end;

    {Scanned all items successfully}
    ScanFreeList := 0;
  end;

  function KillFreeItem(FItem : Word; var FGiven : FreeListRec) : Word;
    {-Reduce free items by one by pulling last item into FItem's slot}
    {Return 1 for success, 2 for error}
  var
    LPage : Word;
    LItem : Word;
  begin
    {Pull the last free list item into this spot}
    if FItem < gFreeUsed then begin
      {Load the last free list page}
      LPage := LoadPage(gFreePagesUsed);
      if LPage = 0 then begin
        {Error loading free list page}
        KillFreeItem := 2;
        Exit;
      end;
      LItem := ((gFreeUsed-1) mod gFreeRecsPerPage)+1;
      FGiven := FreeListArrayPtr(gPages^[LPage])^[LItem];
    end;

    {Reduce the number of free list items}
    dec(gFreeUsed);
    gFreePagesUsed := (gFreeUsed+gFreeRecsPerPage-1) div gFreeRecsPerPage;

    {$IFDEF TakeStats}
    inc(Kills);
    {$ENDIF}

    {Success}
    KillFreeItem := 1;
  end;

  function MergeTopPage(FItem : Word; var FRec : FreeListRec; var D) : Word;
    {-Merge FRec into gNextFreePage if possible}
  begin
    if (FRec.FreePtr.PageNum = gNextFreePage-1) and (FRec.FreeSize = gPageSize)
    then begin
      {This free record is the entire previous page}
      dec(gNextFreePage);
      {KillFreeItem returns 1 or 2}
      MergeTopPage := KillFreeItem(FItem, FRec);
    end else
      MergeTopPage :=0;
  end;

  function AddFreeItem(FLR : FreeListRec) : Word;
    {-Add a new record to free list, returning 0 for success or an error code}
  var
    FPage : Word;
    FItem : Word;
    Status : Word;
    MergedAtTop : Boolean;
  begin
    MergedAtTop := False;

    {See if FLR merges with next free area}
    if FLR.FreePtr.PageNum = gNextFreePage then begin
       if FLR.FreePtr.PageOfs+FLR.FreeSize = gNextFreeOfst then begin
         {Free record merges into high water free level}
         gNextFreeOfst := FLR.FreePtr.PageOfs;
         MergedAtTop := True;
       end;
    end else if gNextFreeOfst = 0 then
      {Next page is unused}
      if (FLR.FreePtr.PageNum = gNextFreePage-1) and (FLR.FreeSize = gPageSize)
      then begin
        {This free record is the entire previous page}
        dec(gNextFreePage);
        MergedAtTop := True;
      end;

    if MergedAtTop then begin
      {No need to add a new free record, may be able to reduce them}
      if gNextFreeOfst = 0 then begin
        repeat
          Status := ScanFreeList(@MergeTopPage, MergedAtTop);
        until Status <> 1;
        AddFreeItem := Status;
      end else
        AddFreeItem := 0;

    end else if gFreeUsed < gFreeCount then begin
      {Increment the number of free records}
      inc(gFreeUsed);
      gFreePagesUsed := (gFreeUsed+gFreeRecsPerPage-1) div gFreeRecsPerPage;

      {Load last page of free records}
      FPage := LoadPage(gFreePagesUsed);
      if FPage = 0 then begin
        AddFreeItem := 204;
        Exit;
      end;

      {Initialize the item}
      FItem := ((gFreeUsed-1) mod gFreeRecsPerPage)+1;
      FreeListArrayPtr(gPages^[FPage])^[FItem] := FLR;

      {$IFDEF TakeStats}
      inc(Adds);
      {$ENDIF}

      {Success}
      AddFreeItem := 0;

    end else
      {Out of free records}
      AddFreeItem := 204;
  end;

  function GetFreeItem(FItem : Word; var FGiven : FreeListRec; var D) : Word;
    {-Find first free record that's big enough to hold D.FreeSize bytes}
  var
    FReturn : FreeListRec absolute D;
  begin
    if FGiven.FreeSize >= FReturn.FreeSize then begin
      {This free item will fulfill the size request}
      FReturn.FreePtr := FGiven.FreePtr;
      if FGiven.FreeSize > FReturn.FreeSize then begin
        {Part of free item will remain, adjust the given one}
        inc(FGiven.FreePtr.PageOfs, FReturn.FreeSize);
        dec(FGiven.FreeSize, FReturn.FreeSize);
        {$IFDEF TakeStats}
        inc(Splits);
        {$ENDIF}
        GetFreeItem := 1;
      end else
        {Reduce free items by one by pulling last item into FItem's slot}
        GetFreeItem := KillFreeItem(FItem, FGiven);
    end else
      {Keep scanning}
      GetFreeItem := 0;
  end;

  function GetFromFreeList(var P; Bytes : Word) : Word;
    {-Search the free list for a matching item}
    {Result =0:Did not find block, =1:Met request, >=2:Error}
  var
    PMP : PagedMemPtr absolute P;
    FLR : FreeListRec;
    Status : Word;
  begin
    FLR.FreeSize := Bytes;
    Status := ScanFreeList(@GetFreeItem, FLR);
    if Status = 1 then
      PMP := FLR.FreePtr;
    GetFromFreeList := Status;
  end;

  function MergeFreeItem(FItem : Word; var FGiven : FreeListRec; var D) : Word;
    {-Merge FNew with given free rec if they are adjacent}
  var
    FNew : FreeListRec absolute D;
  begin
    if FGiven.FreePtr.PageNum <> FNew.FreePtr.PageNum then
      {No merge, continue scanning}
      MergeFreeItem := 0

    else if FGiven.FreePtr.PageOfs+FGiven.FreeSize = FNew.FreePtr.PageOfs
    then begin
      {New item merges after given one}
      inc(FGiven.FreeSize, FNew.FreeSize);
      FNew := FGiven;
      {Reduce free items by one by pulling last item into FItem's slot}
      MergeFreeItem := KillFreeItem(FItem, FGiven);
      {$IFDEF TakeStats}
      inc(Merges);
      {$ENDIF}
      {Return value of 1 or 2 stops scan and indicates that merge occurred}

    end else if FNew.FreePtr.PageOfs+FNew.FreeSize = FGiven.FreePtr.PageOfs
    then begin
      {New item merges before given one}
      inc(FNew.FreeSize, FGiven.FreeSize);
      {Reduce free items by one by pulling last item into FItem's slot}
      MergeFreeItem := KillFreeItem(FItem, FGiven);
      {$IFDEF TakeStats}
      inc(Merges);
      {$ENDIF}
      {Return value of 1 or 2 stops scan and indicates that merge occurred}

    end else
      {No merge, continue scanning}
      MergeFreeItem := 0
  end;

  function AddToFreeList(LogPage, LogOfst, Size : Word) : Word;
    {-Add indicated block to free list, returning status}
  var
    FLR : FreeListRec;
    Done : Boolean;
  begin
    {Initialize the free list record}
    FLR.FreePtr.PageNum := LogPage;
    FLR.FreePtr.PageOfs := LogOfst;
    FLR.FreeSize := Size;

    {See if new block merges with any older block on free list}
    repeat
      case ScanFreeList(@MergeFreeItem, FLR) of
        0 : Done := True;
        1 : Done := False; {If one merge occurred, another may follow}
      else
        {Error}
        AddToFreeList := 204;
        Exit;
      end;
    until Done;

    {Add new free record to the free list}
    AddToFreeList := AddFreeItem(FLR);
  end;

  function DumpFreeItem(FItem : Word; var FGiven : FreeListRec; var D) : Word;
    {-Merge FNew with given free rec if they are adjacent}
  begin
    with FGiven do
      Write(FreePtr.PageNum,':', FreePtr.PageOfs, '-', FreeSize, ' ');
    DumpFreeItem := 0;
  end;

  procedure DumpFreeList;
    {-Write a dump of the free list}
  var
    Status : Word;
  begin
    Status := ScanFreeList(@DumpFreeItem, Status);
    WriteLn;
  end;

  function GetVirtPrim(var P; Bytes : Word) : Boolean;
    {-Allocate memory from virtual storage}
  var
    PMP : PagedMemPtr absolute P;
    Page : Word;
    Status : Word;
  begin
    {Validate the request}
    if (Bytes = 0) or (Bytes > gPageSize) then begin
      GetVirtPrim := False;
      Exit;
    end;

    {Check free list for available space}
    if gFreeUsed > 0 then
      case GetFromFreeList(P, Bytes) of
        0 : ; {Did not find an adequate free block}
        1 : {Met request}
          begin
            GetVirtPrim := True;
            Exit;
          end;
      else
        {Error during free list scan}
        GetVirtPrim := False;
        Exit;
      end;

    if gPageSize-gNextFreeOfst >= Bytes then begin
      {Space on this page will fulfill the request}
      PMP.PageOfs := gNextFreeOfst;
      PMP.PageNum := gNextFreePage;
      {Mark space used}
      inc(gNextFreeOfst, Bytes);
      GetVirtPrim := True;
      Exit;
    end;

    if (gFreeUsed < gFreeCount) and (gNextFreeOfst < gPageSize) then begin
      {Add remainder of current page to the free list}
      Status := AddToFreeList(gNextFreePage, gNextFreeOfst,
                              gPageSize-gNextFreeOfst);
      if Status <> 0 then begin
        GetVirtPrim := False;
        Exit;
      end;
    end;

    {Allocate the next page}
    if gNextFreePage >= gLogPageCount then begin
      {All virtual memory is used}
      GetVirtPrim := False;
      Exit;
    end;
    inc(gNextFreePage);
    gNextFreeOfst := 0;
    Status := ReserveLogicalPage(gNextFreePage);
    if Status <> 0 then begin
      GetVirtPrim := False;
      Exit;
    end;

    {Return the pointer}
    PMP.PageOfs := gNextFreeOfst;
    PMP.PageNum := gNextFreePage;
    inc(gNextFreeOfst, Bytes);
    GetVirtPrim := True;
  end;

  function DerefVirt(P : Pointer) : Pointer;
    {-Dereference a virtual memory pointer}
  var
    PMP : PagedMemPtr absolute P;
  begin
    {Nil always maps to nil}
    if P = nil then
      DerefVirt := nil
    else
      {Find the page in memory, or load it if needed}
      DerefVirt := @gPages^[LoadPage(PMP.PageNum)]^[PMP.PageOfs];
      {If a critical error occurred, it was already reported}
  end;

  procedure FreeVirtPrim(var P; Bytes : Word);
    {-Free virtual memory}
  var
    Pt : Pointer absolute P;
    PMP : PagedMemPtr absolute P;
    Status : Word;
  begin
    {Update free list}
    if gFreeCount > 0 then begin
      Status := AddToFreeList(PMP.PageNum, PMP.PageOfs, Bytes);
      if Status <> 0 then
        CriticalError(Status);
    end;
    Pt := nil;
  end;

  type
    TotalRec =
      record
        TotalFree : LongInt;
        MaxFree : LongInt;
      end;

  function TotalFreeItem(FItem : Word; var FGiven : FreeListRec; var D) : Word;
    {-Merge FNew with given free rec if they are adjacent}
  var
    TR : TotalRec absolute D;
  begin
    inc(TR.TotalFree, FGiven.FreeSize);
    if FGiven.FreeSize > TR.MaxFree then
      TR.MaxFree := FGiven.FreeSize;
    TotalFreeItem := 0;
  end;

  function FreeListSpace(var TotalFree, MaxFree : LongInt) : Word;
    {-Scan the free list to get total space and largest block}
  var
    TR : TotalRec;
  begin
    TR.TotalFree := 0;
    TR.MaxFree := 0;
    FreeListSpace := ScanFreeList(@TotalFreeItem, TR);
    TotalFree := TR.TotalFree;
    MaxFree := TR.MaxFree;
  end;

  {----------------------------- EMS memory ------------------------------}

  const
    EmsErrorCode = $0FFFF;     {Used by several functions to signal an error}

  function EmsInstalled : Boolean;
    {-Returns true if the EMM is installed}
  var
    F : file;
  begin
    Assign(F, 'EMMXXXX0');
    Reset(F);
    if IoResult = 0 then begin
      EmsInstalled := True;
      Close(F);
    end
    else
      EmsInstalled := False;
  end;

  function EmsPagesAvail : Word;
   {-Returns the number of available pages from the expanded memory manager,
     or EmsErrorCode in case of error.}
  {$IFDEF Ver40}
  var
    Result : word;
  {$ENDIF}
  begin
    Inline(
      $B4/$42/               {mov ah,$42                  ;get pages function}
      $CD/$67/               {int $67                     ;call EMM}
      $08/$E4/               {or ah,ah                    ;check status}
      $89/$D8/               {mov ax,bx                   ;assume success}
      $74/$03/               {jz exit                     ;jump if success}
      $B8/>EMSERRORCODE/     {mov ax,>EmsErrorCode        ;else return error code}
                             {exit:}
      {$IFDEF Ver40}
      $89/$46/<RESULT);       {mov [bp+<Result],ax        ;return function result}
      {$ELSE}
      $89/$46/<EMSPAGESAVAIL);{mov [bp+<EmsPagesAvail],ax ;return function result}
      {$ENDIF}
    {$IFDEF Ver40}
    EmsPagesAvail := Result;
    {$ENDIF}
  end;

  function EmsPageFrameSeg : Word;
    {-Returns the page frame base segment}
  {$IFDEF Ver40}
  var
    Result : word;
  {$ENDIF}
  begin
    Inline(
      $B4/$41/               {mov ah,$41                  ;get page frame segment}
      $CD/$67/               {int $67                     ;call EMM}
      $08/$E4/               {or ah,ah                    ;check status}
      $89/$D8/               {mov ax,bx                   ;assume success}
      $74/$03/               {jz exit                     ;jump if success}
      $B8/>EMSERRORCODE/     {mov ax,>EmsErrorCode        ;else return error code}
                             {exit:}
      {$IFDEF Ver40}
      $89/$46/<RESULT);       {mov [bp+<Result],ax        ;return function result}
      {$ELSE}
      $89/$46/<EMSPAGEFRAMESEG);{mov [bp+<EmsPageFrameSeg],ax ;return function result}
      {$ENDIF}
    {$IFDEF Ver40}
    EmsPageFrameSeg := Result;
    {$ENDIF}
  end;

  function AllocateEmsPages(NumPages : Word) : Word;
   {-Allocates the indicated number of pages and returns a handle.
     Returns EmsErrorCode in case of error.}
  {$IFDEF Ver40}
  var
    Result : word;
  {$ENDIF}
  begin
    Inline(
      $8B/$5E/<NUMPAGES/     {mov bx,[bp+<NumPages]       ;get number of pages}
      $B4/$43/               {mov ah,$43                  ;get page frame segment}
      $CD/$67/               {int $67                     ;call EMM}
      $08/$E4/               {or ah,ah                    ;check status}
      $89/$D0/               {mov ax,dx                   ;assume success}
      $74/$03/               {jz exit                     ;jump if success}
      $B8/>EMSERRORCODE/     {mov ax,>EmsErrorCode        ;else return error code}
                             {exit:}
      {$IFDEF Ver40}
      $89/$46/<RESULT);       {mov [bp+<Result],ax        ;return function result}
      {$ELSE}
      $89/$46/<ALLOCATEEMSPAGES);{mov [bp+<AllocateEmsPages],ax ;return function result}
      {$ENDIF}
    {$IFDEF Ver40}
    AllocateEmsPages := Result;
    {$ENDIF}
  end;

  function MapEmsPage(Handle, LogicalPage : Word; PhysicalPage : Byte) : Boolean;
   {-Maps the specified LogicalPage associated with Handle into PhysicalPage
     (0-3). Returns true if successful.}
  {$IFDEF Ver40}
  var
    Result : boolean;
  {$ENDIF}
  begin
    Inline(
      $8A/$46/<PHYSICALPAGE/ {mov al,[bp+<PhysicalPage]   ;get physical page number}
      $8B/$56/<HANDLE/       {mov dx,[bp+<Handle]         ;get ems handle}
      $8B/$5E/<LOGICALPAGE/  {mov bx,[bp+<LogicalPage]    ;get number of pages}
      $B4/$44/               {mov ah,$44                  ;map pages}
      $CD/$67/               {int $67                     ;call EMM}
      $08/$E4/               {or ah,ah                    ;check status}
      $B8/$01/$00/           {mov ax,1                    ;assume success}
      $74/$01/               {jz exit                     ;jump if success}
      $48/                   {dec ax                      ;0 for failure}
                             {exit:}
      {$IFDEF Ver40}
      $88/$46/<RESULT);      {mov [bp+<Result],al         ;return function result}
      {$ELSE}
      $88/$46/<MAPEMSPAGE);  {mov [bp+<MapEmsPage],al     ;return function result}
      {$ENDIF}
    {$IFDEF Ver40}
    MapEmsPage := Result;
    {$ENDIF}
  end;

  function DeallocateEmsHandle(Handle : Word) : Boolean;
    {-Deallocates the indicated handle and the memory associated with it.}
  {$IFDEF Ver40}
  var
    Result : boolean;
  {$ENDIF}
  begin
    Inline(
      $8B/$56/<HANDLE/       {mov dx,[bp+<Handle]         ;get ems handle}
      $B4/$45/               {mov ah,$45                  ;deallocate handle}
      $CD/$67/               {int $67                     ;call EMM}
      $08/$E4/               {or ah,ah                    ;check status}
      $B8/$01/$00/           {mov ax,1                    ;assume success}
      $74/$01/               {jz exit                     ;jump if success}
      $48/                   {dec ax                      ;0 for failure}
                             {exit:}
      {$IFDEF Ver40}
      $88/$46/<RESULT);      {mov [bp+<Result],al        ;return function result}
      {$ELSE}
      $88/$46/<DEALLOCATEEMSHANDLE);{mov [bp+<DeallocateEmsHandle],al ;return function result}
      {$ENDIF}
    {$IFDEF Ver40}
    DeallocateEmsHandle := Result;
    {$ENDIF}
  end;

  function EmsReserve(LogPage : Word) : Word;
    {-Reserve EMS space for specified logical page}
  begin
    gReservedPage := LogPage;
    {No need to do anything}
    EmsReserve := 0;
  end;

  function EmsSwapPages(PhysPage : Word; var OldLogPage : Word;
                        NewLogPage : Word) : Word;
    {-Swap out old logical page, swap in new logical page}
  begin
    if MapEmsPage(gHandle, NewLogPage-1, PhysPage-1) then begin
      OldLogPage := NewLogPage;
      EmsSwapPages := 0;
    end else begin
(*
      writeln('physpage:', PhysPage, ' logpage:', NewLogPage);
*)
      EmsSwapPages := 160; {"Device write fault"}
    end;
  end;

  function EmsMemAvail : LongInt;
    {-Return total free virtual memory space}
  var
    TotalFree : LongInt;
    MaxFree : LongInt;
    Free : LongInt;
    Status : Word;
  begin
    {Check free list}
    Status := FreeListSpace(TotalFree, MaxFree);
    if Status <> 0 then
      EmsMemAvail := 0
    else
      EmsMemAvail := LongInt(gPageSize)*(gLogPageCount-gNextFreePage)+
                     (gPageSize-gNextFreeOfst)+TotalFree;
  end;

  function EmsMaxAvail : LongInt;
    {-Return largest single block of virtual memory space}
  var
    TotalFree : LongInt;
    MaxFree : LongInt;
    Free : LongInt;
    Status : Word;
  begin
    if gNextFreePage < gLogPageCount then
      {There is at least one completely free page}
      EmsMaxAvail := gPageSize
    else begin
      {Part of the last page is available}
      Free := gPageSize-gNextFreeOfst;
      {Check the free list}
      Status := FreeListSpace(TotalFree, MaxFree);
      if Status <> 0 then
        EmsMaxAvail := 0
      else if MaxFree > Free then
        EmsMaxAvail := MaxFree
      else
        EmsMaxAvail := Free;
    end;
  end;

  procedure EmsRelease;
    {-Release EMS-based virtual memory resources}
  var
    Status : Boolean;
  begin
    if gAllocated then begin
      {Close and erase the disk file}
      Status := DeallocateEmsHandle(gHandle);
      gAllocated := False;

      {Release page buffers}
      FreePages(False);
    end;
  end;

  function InitEmsVirtMem(EmsPages : Word;
                          FreeRecs : Word) : Word;
    {-Initialize to use EMS for virtual memory}
  var
    PagesA : Word;
    Status : Word;
    I : Word;
    PSeg : Word;
  begin
    if VirtM <> NoVirtMem then
      ReleaseVirtMem;

    {Initialize in case of error}
    InitNoPages;

    {Allocate EMS space}
    if not EmsInstalled then begin
      {Return "unknown unit"}
      InitEmsVirtMem := 151;
      Exit;
    end;
    PagesA := EmsPagesAvail;
    if (PagesA = EmsErrorCode) or (PagesA = 0) then begin
      {Return "drive not ready"}
      InitEmsVirtMem := 152;
      Exit;
    end;
    if EmsPages > PagesA then
      EmsPages := PagesA;
    gHandle := AllocateEmsPages(EmsPages);
    if gHandle = EmsErrorCode then begin
      {Return "drive not ready"}
      InitEmsVirtMem := 152;
      Exit;
    end;
    gAllocated := True;
    gLogPageCount := EmsPages;

    GetVirtFunc := @GetVirtPrim;
    FreeVirtProc := @FreeVirtPrim;
    DerefFunc := @DerefVirt;
    MemAvailFunc := @EmsMemAvail;
    MaxAvailFunc := @EmsMaxAvail;
    ReleaseProc := @EmsRelease;
    ReserveFunc := @EmsReserve;
    SwapFunc := @EmsSwapPages;

    {We're set up for EMS-based memory now}
    VirtM := EmsVirtMem;

    {Allocate RAM buffers}
    Status := AllocPages(4, 16384, False);
    if Status <> 0 then begin
      InitEmsVirtMem := Status;
      Exit;
    end;

    {Set pointers for EMS page windows}
    PSeg := EmsPageFrameSeg;
    for I := 1 to 4 do begin
      gPages^[I] := Ptr(PSeg, 0);
      inc(PSeg, $400);
    end;

    {Initialize free list}
    Status := InitFreeList(FreeRecs);
    if Status <> 0 then begin
      InitEmsVirtMem := Status;
      Exit;
    end;

    InitEmsVirtMem := 0;
  end;

  {----------------------------- disk memory ------------------------------}

  function DiskReserve(LogPage : Word) : Word;
    {-Reserve disk space for specified logical page}
  begin
    Seek(gFile, LongInt(gPageSize)*(LogPage-1));
    {Write whatever happens to be in page 1 to the disk to reserve space}
    BlockWrite(gFile, gPages^[1]^, gPageSize);
    gReservedPage := LogPage;
    DiskReserve := IoResult;
  end;

  function DiskSwapPages(PhysPage : Word; var OldLogPage : Word;
                         NewLogPage : Word) : Word;
    {-Write out old logical page, read in new logical page}
  var
    Status : Word;
  begin
    if OldLogPage <> 0 then begin
      {Write out old contents}
      Seek(gFile, LongInt(gPageSize)*(OldLogPage-1));
      BlockWrite(gFile, gPages^[PhysPage]^, gPageSize);
      Status := IoResult;
      if Status <> 0 then begin
        DiskSwapPages := Status;
        Exit;
      end;
    end;
    {Read in new contents}
    Seek(gFile, LongInt(gPageSize)*(NewLogPage-1));
    BlockRead(gFile, gPages^[PhysPage]^, gPageSize);
    OldLogPage := NewLogPage;
    DiskSwapPages := IoResult;
  end;

  function DiskMemAvail : LongInt;
    {-Return total free virtual memory space}
  var
    TotalFree : LongInt;
    MaxFree : LongInt;
    Free : LongInt;
    Status : Word;
  begin
    {Check free list}
    Status := FreeListSpace(TotalFree, MaxFree);
    if Status < 0 then
      DiskMemAvail := 0
    else begin
      {Free disk space plus space reserved but given back}
      Free := LDiskFree(gDrive)+LongInt(gPageSize)*(gReservedPage-gNextFreePage);
      if Free < 0 then
        DiskMemAvail := 0
      else
        DiskMemAvail := (gPageSize-gNextFreeOfst)+ {Space available in next free page}
                        Free+                      {Free disk space}
                        TotalFree;                 {Space on free list}
    end;
  end;

  function DiskMaxAvail : LongInt;
    {-Return largest single block of virtual memory space}
  var
    TotalFree : LongInt;
    MaxFree : LongInt;
    Free : LongInt;
    Status : Word;
  begin
    {Free disk space plus space reserved but given back}
    Free := LDiskFree(gDrive)+LongInt(gPageSize)*(gReservedPage-gNextFreePage);
    if Free < 0 then
      DiskMaxAvail := 0
    else if Free >= gPageSize then
      DiskMaxAvail := gPageSize
    else begin
      {Check free list}
      Status := FreeListSpace(TotalFree, MaxFree);
      if Status < 0 then
        DiskMaxAvail := 0
      else if MaxFree > Free then
        DiskMaxAvail := MaxFree
      else
        DiskMaxAvail := Free;
    end;
  end;

  procedure DiskRelease;
    {-Release disk-based virtual memory resources}
  var
    Status : Word;
  begin
    if gAllocated then begin
      {Close and erase the disk file}
      Close(gFile);
      Status := IoResult;
      Erase(gFile);
      Status := IoResult;
      gAllocated := False;

      {Release page buffers}
      FreePages(True);
    end;
  end;

  function DefaultDrive : Char;
    {-Returns the default drive as an uppercase letter}
  Inline(
    $B4/$19/               {mov ah,$19}
    $CD/$21/               {int $21}
    $04/$41);              {add al,$41}

  function InitDiskVirtMem(FileName : string;
                           RamPages : Word;
                           PageSize : Word;
                           FreeRecs : Word) : Word;
    {-Initialize to use disk space for virtual memory}
  var
    Status : Word;
    DriveChar : Char;
  begin
    if VirtM <> NoVirtMem then
      ReleaseVirtMem;

    {Initialize in case of error}
    InitNoPages;

    {Assure reasonable input parameters}
    if (RamPages < 2) or (PageSize = 0) then begin
      InitDiskVirtMem := 106;
      Exit;
    end;

    {Assure PageSize is a multiple of FreeRec size, which is 8}
    PageSize := (PageSize+7) and $FFF8;

    {Create the virtual memory file}
    Assign(gFile, FileName);
    Rewrite(gFile, 1);
    Status := IoResult;
    if Status <> 0 then begin
      InitDiskVirtMem := Status;
      Exit;
    end;
    gAllocated := True;
    gLogPageCount := $FFFF;   {Logical pages allocated as needed}

    {Save its drive number}
    if Pos(':', FileName) = 2 then
      DriveChar := UpCase(FileName[1])
    else
      DriveChar := DefaultDrive;
    gDrive := Pos(DriveChar, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');

    {Set up function pointers}
    GetVirtFunc := @GetVirtPrim;
    FreeVirtProc := @FreeVirtPrim;
    DerefFunc := @DerefVirt;
    MemAvailFunc := @DiskMemAvail;
    MaxAvailFunc := @DiskMaxAvail;
    ReleaseProc := @DiskRelease;
    ReserveFunc := @DiskReserve;
    SwapFunc := @DiskSwapPages;

    {We're set up for disk-based memory now}
    VirtM := DiskVirtMem;

    {Allocate RAM buffers, set up free list, prepare first data page}
    Status := InitPages(RamPages, PageSize, FreeRecs);
    if Status <> 0 then begin
      ReleaseVirtMem;
      InitDiskVirtMem := Status;
      Exit;
    end;

    {Success}
    InitDiskVirtMem := 0;
  end;

  {----------------------------- xms memory ------------------------------}

  type
    {pointers in XMS are segm:ofs for < 1 meg, and linear for > 1 meg}
    ExtMemPtr      =
      record
        case Boolean of
          False : (RealPtr : Pointer);
          True  : (ProtectedPtr : LongInt);
      end;

    {the record structure used internally by MoveExtMemBlock}
    ExtMemMoveStruct =
      record
        Len        : LongInt;
        SrcHand    : Word;
        SrcOffs    : ExtMemPtr;
        DestHand   : Word;
        DestOffs   : ExtMemPtr;
      end;

  var
    XmsControl     : Pointer;          {ptr to XMS control procedure}

  function MoveExtMemBlockPrim(ParamBlock : Pointer) : Byte;
    {-Call XMS function $0B to move extended memory}
  Inline(
    $8C/$D8/               {  MOV    AX,DS}
    $8E/$C0/               {  MOV    ES,AX}
    $5E/                   {  POP    SI}
    $1F/                   {  POP    DS}
    $50/                   {  PUSH   AX}
    $B4/$0B/               {  MOV    AH,$0B}
    $26/                   {ES:}
    $FF/$1E/>XMSCONTROL/   {  CALL   DWORD PTR [>XmsControl]}
    $1F/                   {  POP    DS}
    $A9/$01/$00/           {  TEST   AX,1}
    $75/$04/               {  JNZ    Success}
    $88/$D8/               {  MOV    AL,BL}
    $EB/$02/               {  JMP    SHORT ExitPoint}
                           {Success:}
    $30/$C0);              {  XOR    AL,AL}
                           {ExitPoint:}

  function MoveExtMemBlock(BlockLength : LongInt;
                           SourceHandle : Word;
                           SourcePtr : ExtMemPtr;
                           DestHandle : Word;
                           DestPtr : ExtMemPtr) : Byte;
  var
    ControlBlock : ExtMemMoveStruct;
  begin
    with ControlBlock do begin
      Len := BlockLength;
      SrcHand   := SourceHandle;
      SrcOffs   := SourcePtr;
      DestHand  := DestHandle;
      DestOffs  := DestPtr;
    end;
    MoveExtMemBlock := MoveExtMemBlockPrim(@ControlBlock);
  end;

  function FreeExtMem(XmsHandle : Word) : Byte;
  {$IFDEF Ver40}
  var
    Result : byte;
  {$ENDIF}
  begin
    Inline(
      $B4/$0A/               {  MOV    AH,$0A   ;XMS function 0Ah - Free ext memory block}
      $8B/$96/>XMSHANDLE/    {  MOV    DX,>XmsHandle[BP]}
      $FF/$1E/>XMSCONTROL/   {  CALL   DWORD PTR [>XmsControl]}
      $A9/$01/$00/           {  TEST   AX,1}
      $74/$02/               {  JZ     SetError}
      $30/$DB/               {  XOR    BL,BL}
                             {SetError:}
      {$IFDEF Ver40}
      $88/$5E/<RESULT);      {  MOV    <Result[BP],BL}
      {$ELSE}
      $88/$5E/<FREEEXTMEM);  {  MOV    <FreeExtMem[BP],BL}
      {$ENDIF}
    {$IFDEF Ver40}
    FreeExtMem := Result;
    {$ENDIF}
  end;

  function XmsInstalledPrim : Boolean;
    {-Returns TRUE is an XMS memory manager is installed}
  Inline(
    $B8/$00/$43/     {   MOV     AX,$4300           ; XMS Installed function}
    $CD/$2F/         {   INT     $2F                ; DOS Multiplex int}
    $3C/$80/         {   CMP     AL,$80             ; is it there?}
    $75/$04/         {   JNE     NoXmsDriver}
    $B0/$01/         {   MOV     AL,1               ; return True}
    $EB/$02/         {   JMP     SHORT XIExit}
                     {NoXmsDriver:}
    $30/$C0);        {   XOR     AL,AL              ; return False}
                     {XIExit:}

  function XmsControlAddr : Pointer;
    {-Return address of XMS control function.}
  Inline(
    $B8/$10/$43/     {   MOV     AX,$4310           ; XMS control func addr}
    $CD/$2F/         {   INT     $2F}
    $89/$D8/         {   MOV     AX,BX              ; ptr in ES:BX to DX:AX}
    $8C/$C2);        {   MOV     DX,ES}

  function XmsInstalled : Boolean;
    {-Returns TRUE is an XMS memory manager is installed}
  begin
    if XmsInstalledPrim then begin
      XmsControl := XmsControlAddr;
      XmsInstalled := True;
    end else
      XmsInstalled := False;
  end;

  function QueryFreeExtMem(var TotalFree, LargestBlock : Word) : Byte;
  {$IFDEF Ver40}
  var
    Result : byte;
  {$ENDIF}
  begin
    Inline(
      $B4/$08/               {  MOV    AH,$08   ;XMS function 08h - Query Free ext memory}
      $FF/$1E/>XMSCONTROL/   {  CALL   DWORD PTR [>XmsControl]}
      $09/$C0/               {  OR     AX,AX}
      $74/$10/               {  JZ     SetError}
      $30/$DB/               {  XOR    BL,BL}
      $C4/$BE/>TOTALFREE/    {  LES    DI,>TotalFree[BP]}
      $26/                   {ES:}
      $89/$15/               {  MOV    [DI],DX}
      $C4/$BE/>LARGESTBLOCK/ {  LES    DI,>LargestBlock[BP]}
      $26/                   {ES:}
      $89/$05/               {  MOV    [DI],AX}
                             {SetError:}
      {$IFDEF Ver40}
      $88/$5E/<RESULT);      {  MOV    <Result[BP],BL}
      {$ELSE}
      $88/$5E/<QueryFreeExtMem);{  MOV    <QueryFreeExtMem[BP],BL}
      {$ENDIF}
    {$IFDEF Ver40}
    QueryFreeExtMem := Result;
    {$ENDIF}
  end;

  function AllocateExtMem(SizeInK : Word; var XmsHandle : Word) : Byte;
  {$IFDEF Ver40}
  var
    Result : byte;
  {$ENDIF}
  begin
    Inline(
      $B4/$09/               {  MOV    AH,$09   ;XMS function 09h - Alloc ext memory block}
      $8B/$96/>SIZEINK/      {  MOV    DX,>SizeInK[BP]}
      $FF/$1E/>XMSCONTROL/   {  CALL   DWORD PTR [>XmsControl]}
      $A9/$01/$00/           {  TEST   AX,1}
      $74/$09/               {  JZ     SetError}
      $30/$DB/               {  XOR    BL,BL}
      $C4/$BE/>XMSHANDLE/    {  LES    DI,>XmsHandle[BP]}
      $26/                   {ES:}
      $89/$15/               {  MOV    [DI],DX  ;return XMS handle}
                             {SetError:}
      {$IFDEF Ver40}
      $88/$5E/<RESULT);      {  MOV    <Result[BP],BL}
      {$ELSE}
      $88/$5E/<AllocateExtMem); {  MOV    <AllocateExtMem[BP],BL}
      {$ENDIF}
    {$IFDEF Ver40}
    AllocateExtMem := Result;
    {$ENDIF}
  end;

  function XmsReserve(LogPage : Word) : Word;
    {-Reserve XMS space for specified logical page}
  begin
    gReservedPage := LogPage;
    {No need to do anything else}
    XmsReserve := 0;
  end;

  function XmsSwapPages(PhysPage : Word; var OldLogPage : Word;
                        NewLogPage : Word) : Word;
    {-Write out old logical page, read in new logical page}
  var
    SrcPtr : ExtMemPtr;
    DesPtr : ExtMemPtr;
    Status : Word;
  begin
    if OldLogPage <> 0 then begin
      {Swap old page back to XMS}
      SrcPtr.RealPtr := gPages^[PhysPage];
      DesPtr.ProtectedPtr := LongInt(gPageSize)*(OldLogPage-1);
      Status := MoveExtMemBlock(gPageSize, 0, SrcPtr, gHandle, DesPtr);
      if Status <> 0 then begin
        XmsSwapPages := Status;
        Exit;
      end;
    end;
    {Swap new page into real memory}
    SrcPtr.ProtectedPtr := LongInt(gPageSize)*(NewLogPage-1);
    DesPtr.RealPtr := gPages^[PhysPage];
    XmsSwapPages := MoveExtMemBlock(gPageSize, gHandle, SrcPtr, 0, DesPtr);
    OldLogPage := NewLogPage;
  end;

  function XmsMemAvail : LongInt;
    {-Return total free virtual memory space}
  var
    TotalFree : LongInt;
    MaxFree : LongInt;
    Free : LongInt;
    Status : Word;
  begin
    {Check free list}
    Status := FreeListSpace(TotalFree, MaxFree);
    if Status <> 0 then
      XmsMemAvail := 0
    else
      XmsMemAvail := LongInt(gPageSize)*(gLogPageCount-gNextFreePage)+
                     (gPageSize-gNextFreeOfst)+TotalFree;
  end;

  function XmsMaxAvail : LongInt;
    {-Return largest single block of virtual memory space}
  var
    TotalFree : LongInt;
    MaxFree : LongInt;
    Free : LongInt;
    Status : Word;
  begin
    if gNextFreePage < gLogPageCount then
      {There is at least one completely free page}
      XmsMaxAvail := gPageSize
    else begin
      {Part of the last page is available}
      Free := gPageSize-gNextFreeOfst;
      {Check the free list}
      Status := FreeListSpace(TotalFree, MaxFree);
      if Status <> 0 then
        XmsMaxAvail := 0
      else if MaxFree > Free then
        XmsMaxAvail := MaxFree
      else
        XmsMaxAvail := Free;
    end;
  end;

  procedure XmsRelease;
    {-Release XMS-based virtual memory resources}
  var
    Status : Word;
  begin
    if gAllocated then begin
      {Release the XMS space}
      Status := FreeExtMem(gHandle);
      gAllocated := False;

      {Release page buffers}
      FreePages(True);
    end;
  end;

  function InitXmsVirtMem(KBytesInXms : Word;
                          RamPages : Word;
                          PageSize : Word;
                          FreeRecs : Word) : Word;
    {-Initialize to use XMS for virtual memory}
  var
    Status : Word;
    MemA : Word;
    MaxA : Word;
  begin
    if VirtM <> NoVirtMem then
      ReleaseVirtMem;

    {Initialize in case of error}
    InitNoPages;

    {Assure reasonable input parameters}
    if (RamPages < 2) or (PageSize = 0) then begin
      InitXmsVirtMem := 106;
      Exit;
    end;

    {Assure PageSize is a multiple of FreeRec size, which is 8}
    PageSize := (PageSize+7) and $FFF8;

    {Allocate Xms space}
    if not XmsInstalled then begin
      {Return "unknown unit"}
      InitXmsVirtMem := 151;
      Exit;
    end;
    Status := QueryFreeExtMem(MemA, MaxA);
    if (Status <> 0) or (MaxA = 0) then begin
      {Return "drive not ready"}
      InitXmsVirtMem := 152;
      Exit;
    end;
    {Use the largest block up to KBytesInXms in size}
    if KBytesInXms > MaxA then
      KBytesInXms := MaxA;
    Status := AllocateExtMem(KBytesInXms, gHandle);
    if Status <> 0 then begin
      {Return "bad structure length"}
      InitXmsVirtMem := 155;
      Exit;
    end;
    gAllocated := True;
    gLogPageCount := (LongInt(1024)*KBytesInXms) div PageSize;

    {Set up function pointers}
    GetVirtFunc := @GetVirtPrim;
    FreeVirtProc := @FreeVirtPrim;
    DerefFunc := @DerefVirt;
    MemAvailFunc := @XmsMemAvail;
    MaxAvailFunc := @XmsMaxAvail;
    ReleaseProc := @XmsRelease;
    ReserveFunc := @XmsReserve;
    SwapFunc := @XmsSwapPages;

    {We're set up for XMS-based memory now}
    VirtM := XmsVirtMem;

    {Allocate RAM buffers, set up free list, prepare first data page}
    Status := InitPages(RamPages, PageSize, FreeRecs);
    if Status <> 0 then begin
      ReleaseVirtMem;
      InitXmsVirtMem := Status;
      Exit;
    end;

    {Success}
    InitXmsVirtMem := 0;
  end;

begin
  HeapError := @HeapFunc;

  {$IFDEF DPMI}
  {Assure all blocks are part of HeapList chain}
  HeapBlock := 65532;
  HeapLimit := 65520;
  {$ENDIF}

  {$IFDEF Debug}
  InitDebugVirtMem;
  {$ELSE}
  InitNoVirtMem;
  {$ENDIF}

  SaveExit := ExitProc;
  ExitProc := @ShutDown;
end.
