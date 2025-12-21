/*
        NTVDM.H ([Guessed] functions prototypes + definitions for NTVDM.)

        Copyright (C) 1998-01-18 Claus André Färber
                created from the information available
                at <http://premium.microsoft.com/msdn/library/>

        This program is free software; you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation; either version 2 of the License, or
        (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program; if not, write to the Free Software
        Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#ifdef __cplusplus
extern "C"{
#endif

/*
        memory access
*/

BOOL WINAPI FlushVDMPointer(
IN ULONG  Addr,
IN USHORT  Size,
PBYTE  Buffer,
IN BOOL  ProtectedMode );

BOOL  WINAPI FreeVDMPointer(
IN ULONG  Address,
IN USHORT  Size,
PBYTE  Buffer,
IN BOOL  ProtectedMode);

PBYTE WINAPI  GetVDMPointer(
IN ULONG  Address,
IN ULONG  Size,
IN BOOL  ProtectedMode);

/*
        register manipulation
*/

ULONG  WINAPI getEAX(void);
VOID WINAPI  setEAX(ULONG);
USHORT  WINAPI getAX(void);
VOID WINAPI  setAX(USHORT);
UCHAR  WINAPI getAL(void);
VOID WINAPI  setAH(CHAR);
UCHAR  WINAPI getAH(void);
VOID WINAPI  setAL(UCHAR);
ULONG  WINAPI getEBX(void);
VOID  WINAPI setEBX(ULONG);
USHORT  WINAPI getBX(void);
VOID WINAPI  setBX(USHORT);
UCHAR WINAPI  getBL(void);
VOID WINAPI  setBH(UCHAR);
UCHAR WINAPI  getBH(void);
VOID  WINAPI setBL(UCHAR);
ULONG  WINAPI getECX(void);
VOID  WINAPI setECX(ULONG);
USHORT WINAPI  getCX(void);
VOID  WINAPI setCX(USHORT);
UCHAR  WINAPI getCL(void);
VOID  WINAPI setCH(UCHAR);
UCHAR  WINAPI getCH(void);
VOID  WINAPI setCL(UCHAR);
ULONG  WINAPI getEDX(void);
VOID  WINAPI setEDX(ULONG);
UCHAR  WINAPI getDH(void);
USHORT  WINAPI getDX(void);
VOID  WINAPI setDX(USHORT);
ULONG  WINAPI getESP(void);
VOID WINAPI  setDH(UCHAR);
USHORT WINAPI  getSP(void);
VOID  WINAPI setDL(UCHAR);
ULONG WINAPI  getEBP(void);
VOID WINAPI  setESP(ULONG);
USHORT WINAPI  getBP(void);
VOID WINAPI  setSP(USHORT);
ULONG WINAPI  getESI(void);
VOID WINAPI  setEBP(ULONG);
USHORT WINAPI  getSI(void);
VOID  WINAPI setBP(USHORT);
ULONG  WINAPI getEDI(void);
VOID  WINAPI setESI(ULONG);
USHORT WINAPI  getDI(void);
VOID WINAPI  setSI(USHORT);
ULONG  WINAPI getEIP(void);
VOID  WINAPI setEDI(ULONG);
USHORT  WINAPI getIP(void);
VOID  WINAPI setDI(USHORT);
USHORT WINAPI  getCS(void);
VOID WINAPI  setEIP(ULONG);
USHORT WINAPI  getSS(void);
VOID WINAPI  setIP(USHORT);
USHORT  WINAPI getDS(void);
VOID  WINAPI setCS(USHORT);
USHORT  WINAPI getES(void);
VOID WINAPI  setSS(USHORT);
USHORT WINAPI  getFS(void);
VOID  WINAPI setDS(USHORT);
USHORT WINAPI  getGS(void);
VOID  WINAPI setES(USHORT);
ULONG  WINAPI getCF(void);
VOID WINAPI  setFS(USHORT);
ULONG  WINAPI getPF(void);
VOID  WINAPI setGS(USHORT);
ULONG  WINAPI getAF(void);
VOID  WINAPI setCF(ULONG);
ULONG WINAPI  getZF(void);
VOID  WINAPI setPF(ULONG);
ULONG  WINAPI getSF(void);
VOID WINAPI  setPF(ULONG);
ULONG  WINAPI getIF(void);
VOID  WINAPI setAF(ULONG);
ULONG  WINAPI getDF(void);
VOID WINAPI  setZF(ULONG);
ULONG  WINAPI getOF(void);
VOID WINAPI  setSF(ULONG);
USHORT WINAPI  getMSW(void);
VOID WINAPI  setIF(ULONG);
VOID  WINAPI setDF(ULONG);
VOID  WINAPI setOF(ULONG);
VOID WINAPI  setMSW(USHORT);

/*
        x86 IO port hooking
*/

/* Basic typedefs of VDD IO hooks */

typedef VOID ( WINAPI *PFNVDD_INB) (WORD iport,BYTE * data);
typedef VOID ( WINAPI *PFNVDD_INW) (WORD iport,WORD * data);
typedef VOID ( WINAPI *PFNVDD_INSB) (WORD iport,BYTE * data,WORD count);
typedef VOID ( WINAPI *PFNVDD_INSW) (WORD iport,WORD * data,WORD count);
typedef VOID ( WINAPI *PFNVDD_OUTB) (WORD iport,BYTE data);
typedef VOID ( WINAPI *PFNVDD_OUTW) (WORD iport,WORD data);
typedef VOID ( WINAPI *PFNVDD_OUTSB) (WORD iport,BYTE * data,WORD count);
typedef VOID ( WINAPI *PFNVDD_OUTSW) (WORD iport,WORD * data,WORD count);

typedef struct _VDD_IO_HANDLERS {
        PFNVDD_INB inb_handler;
        PFNVDD_INW inw_handler;
        PFNVDD_INSB insb_handler;
        PFNVDD_INSW insw_handler;
        PFNVDD_OUTB outb_handler;
        PFNVDD_OUTW outw_handler;
        PFNVDD_OUTSB outsb_handler;
        PFNVDD_OUTSW outsw_handler;
} VDD_IO_HANDLERS, *PVDD_IO_HANDLERS;

typedef struct _VDD_IO_PORTRANGE {
   WORD First;
   WORD Last;
} VDD_IO_PORTRANGE, *PVDD_IO_PORTRANGE;

BOOL  WINAPI VDDInstallIOHook(
IN HANDLE  hVDD,
IN WORD  cPortRange,
IN PVDD_IO_PORTRANGE  pPortRange,
IN PVDD_IO_HANDLERS  IOhandler);

VOID WINAPI  WINAPI VDDDeInstallIOHook(
IN HANDLE  hVdd,
IN WORD  cPortRange,
IN PVDD_IO_PORTRANGE  pPortRange);

/*
        memory access hooking
*/

/* don't know the prototype for
        hook function :-( */

/* BOOL  WINAPI VDDInstallMemoryHook(
IN HANDLE  hVdd,
IN PVOID  pStart,
IN DWORD  count,
IN PVDD_MEMORY_HANDLER  MemoryHandler ); */

BOOL  WINAPI VDDDeInstallMemoryHook(
IN HANDLE  hVdd,
IN PVOID  pStart,
IN DWORD  count);

/*
        VDM event hooking
*/

/* don't know the prototype for
        hook function :-( */

/* BOOL  WINAPI VDDInstallUserHook(
IN HANDLE  hVDD,
IN PFNVDD_UCREATE  Ucr_Handler,
IN PFNVDD_UTERMINATE  Uterm_Handler,
IN PFNVDD_UBLOCK  Ublock_handler,
IN PFNVDD_URESUME  Uresume_handler ); */

BOOL  WINAPI VDDDeInstallUserHook(
IN HANDLE  hVDD);

/*
        DMA transfer support
*/

typedef struct _VDD_DMA_INFO {
   WORD addr;
   WORD count;
   WORD page;
   BYTE status;
   BYTE mode;
   BYTE mask;
} VDD_DMA_INFO, *PVDD_DMA_INFO;

/* flags for mask member */
/* !! guessed !! */
#define VDD_DMA_ADDR    0x1
#define VDD_DMA_COUNT   0x2
#define VDD_DMA_PAGE    0x4
#define VDD_DMA_STATUS  0x8
#define VDD_DMA_ALL     0xF

BOOL WINAPI  VDDQueryDMA(
IN HANDLE  hVdd,
IN WORD  iChannel,
IN PVDD_DMA_INFO  pDmaInfo );

DWORD WINAPI  VDDRequestDMA(
IN HANDLE  hVDD,
WORD  iChannel,
PVOID  Buffer,
DWORD  length);

BOOL  WINAPI VDDSetDMA(
IN HANDLE  hVdd,
IN WORD  iChannel,
IN WORD  fDMA,
IN PVDD_DMA_INFO  Buffer);

/*
        VM memory
*/

BOOL  WINAPI VDDAllocMem(
IN HANDLE  hVdd,
IN PVOID  Address,
IN DWORD  Size);

BOOL WINAPI  VDDFreeMem(
IN HANDLE  hVdd,
IN PVOID  Address,
IN DWORD  Size);

BOOL  WINAPI VDDIncludeMem(
IN HANDLE  hVDD,
IN PVOID  Address,
DWORD  Size);

/*
        VM calls
*/

VOID WINAPI  VDDSimulate16(void);

VOID  WINAPI VDDSimulateInterrupt(
IN INT  ms,
IN BYTE  line,
IN INT  count);

/* VOID  WINAPI VDDUnSimulate16(void); 16 bit assembly interface ?! */

/*
        VM calls
*/

VOID  WINAPI VDDTerminateVDM(void);

/*
        WOW32
*/

BOOL  WINAPI WOW32DriverCallback(
DWORD  dwCallback,
DWORD  dwFlags,
WORD  wDeviceHandle,
WORD  wMsg,
DWORD  dwUser,
DWORD  dwParam1,
DWORD  dwParam2);

/*
unknown :-(

DCB_FUNCTION
DCB_WINDOW
DCB_TASK
*/

BOOL  WINAPI WOW32ResolveHandle(
UINT  uHandleType,
UINT  uMappingDirection,
WORD  wHandle16_In,
LPWORD  lpwHandle16_Out,
DWORD  dwHandle32_In,
LPDWORD  lpdwHandle32_Out);

#ifdef __cplusplus
} //extern "C"
#endif

