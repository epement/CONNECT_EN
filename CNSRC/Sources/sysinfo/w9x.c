#include <stdio.h>
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#define VWIN32_DIOC_DOS_IOCTL 1

typedef struct _DIOC_REGISTERS {
    DWORD reg_EBX;
    DWORD reg_EDX;
    DWORD reg_ECX;
    DWORD reg_EAX;
    DWORD reg_EDI;
    DWORD reg_ESI;
    DWORD reg_Flags;
} DIOC_REGISTERS, *PDIOC_REGISTERS;

// Important: All MS_DOS data structures must be packed on a
// one-byte boundary.

#pragma pack(1)
typedef struct _MID {
    WORD  midInfoLevel;
    DWORD midSerialNum;
    BYTE  midVolLabel[11];
    BYTE  midFileSysType[8];
} MID, *PMID;
#pragma pack()


void
main()
{
	HANDLE hDevice = NULL;
	DIOC_REGISTERS reg;
	MID mid;
	BOOL fResult;
	DWORD cb;
	int nDrive = 3;  // Drive C:

	hDevice = CreateFile("\\\\.\\vwin32", 0, 0, NULL, 0, FILE_FLAG_DELETE_ON_CLOSE, NULL);
	if (INVALID_HANDLE_VALUE == hDevice) {
		printf("CreateFile() error\n");
		hDevice = NULL;
		goto stop;
	}

	reg.reg_EAX = 0x440D;       // IOCTL for block devices
	reg.reg_EBX = nDrive;       // zero-based drive identifier
	reg.reg_ECX = 0x4866;       // Get Media ID command
	reg.reg_EDX = (DWORD) &mid; // receives media identifier information
	reg.reg_Flags = 0x0001;     // assume error (carry flag is set)

	fResult = DeviceIoControl(hDevice,
	    VWIN32_DIOC_DOS_IOCTL,
	    &reg, sizeof(reg),
	    &reg, sizeof(reg),
	    &cb, 0);

	if (!fResult || (reg.reg_Flags & 0x0001)) {
	    // error if carry flag is set
		printf("DeviceIoControl() error\n");
	} else {
		printf("Serial: %04X-%04X, label: %.11s, type: %.8s\n",
			HIWORD(mid.midSerialNum), LOWORD(mid.midSerialNum), mid.midVolLabel, mid.midFileSysType);
	}

stop:
	if (hDevice) CloseHandle(hDevice);
}

