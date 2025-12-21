#include <stdio.h>
#include <string.h>
#include <windows.h>

#pragma comment(lib, "advapi32.lib")
#pragma comment(lib, "user32.lib")


static int
read_ProductName(HKEY rootkey, char *path, char *buf)
{
	HKEY	key;
	LONG	rc;
	DWORD	vtype, bsize = 256;

	rc = RegOpenKeyEx(HKEY_LOCAL_MACHINE, path, 0, KEY_READ, &key);
	if (rc != ERROR_SUCCESS) {
		printf("Error opening key (code: %u)\n", rc);
		rc = 1;
	} else {
		rc = RegQueryValueEx(key, "ProductName", NULL, &vtype, buf, &bsize);
		if (rc != ERROR_SUCCESS) {
			printf("Error reading value (code: %u)\n", rc);
			strcpy(buf, "No ProductName");
			rc = 2;
		} else {
			rc = 0;
		}
		RegCloseKey(key);
	}
	return rc;
}

static char *
win_err_message(char *buf, int bufsz, int rc)
{
	FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, NULL, rc, 0, buf, bufsz, NULL);
	CharToOem(buf, buf);
	return buf;
}

extern int
main(int argc, char *argv[])
{
	OSVERSIONINFO	os_ver_inf;
	MEMORYSTATUS	mem_stat;
	char			buf[1024] = "", drvsbuf[1024], volname[32], fsname[32];
	char			*s;
	int				i, rc;
	HANDLE			h;
	DWORD			drives, spc, bps, nfc, tnc, volsn, maxclen, fsflags, lasterr;
	unsigned __int64	fbytes, tbytes;
	BOOL			(*pGetDiskFreeSpaceEx)(LPCTSTR, PULARGE_INTEGER, PULARGE_INTEGER, PULARGE_INTEGER);

	/* Windows version */
	memset(&os_ver_inf, 0, sizeof(OSVERSIONINFO));
	os_ver_inf.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	if (!GetVersionEx(&os_ver_inf)) {
		printf("Error calling GetVersionEx()\n");
	} else {
		switch (os_ver_inf.dwPlatformId) {
		case VER_PLATFORM_WIN32s:
			printf("Win32s %d.%d build %d\n",
				os_ver_inf.dwMajorVersion, os_ver_inf.dwMinorVersion,
				LOWORD(os_ver_inf.dwBuildNumber));
			break;

		case VER_PLATFORM_WIN32_WINDOWS:
			printf("Windows 9x %d.%d build %d, %s\n",
				os_ver_inf.dwMajorVersion, os_ver_inf.dwMinorVersion,
				LOWORD(os_ver_inf.dwBuildNumber), os_ver_inf.szCSDVersion);

			if (read_ProductName(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows\\CurrentVersion", buf)) {
				printf("Can not get ProductName\n");
			} else {
				printf("ProductName: %s\n", buf);
			}
			break;

		case VER_PLATFORM_WIN32_NT:
			printf("Windows NT %d.%d build %d, %s\n",
				os_ver_inf.dwMajorVersion, os_ver_inf.dwMinorVersion,
				LOWORD(os_ver_inf.dwBuildNumber), os_ver_inf.szCSDVersion);

			if (read_ProductName(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion", buf)) {
				printf("Can not get ProductName\n");
			} else {
				printf("ProductName: %s\n", buf);
			}
			break;

		default:
			printf("Unknown Windows version\n");
			break;
		}
	}

	/* Is function GetDiskFreeSpaceEx() exists? */
	printf("Function GetDiskFreeSpaceEx() ");
	if (!(h = LoadLibrary("KERNEL32.DLL")))
		printf(" - can not load KERNEL32.DLL - ");
	if (pGetDiskFreeSpaceEx = (void *) GetProcAddress(h, "GetDiskFreeSpaceExA")) {
		printf("exists");
	} else {
		lasterr = GetLastError();
		printf("NOT exists, err: %u (%X)", lasterr, lasterr);
	}

	puts("");

	/* Directories */
	GetWindowsDirectory(buf, sizeof(buf));
	printf("Win dir: %s", buf);
	GetSystemDirectory(buf, sizeof(buf));
	printf(", sys dir: %s", buf);
	GetTempPath(sizeof(buf), buf);
	printf(", temp dir: %s\n", buf);

	/* Name of computer and user */
	rc = sizeof(buf);
	GetComputerName(buf, &rc);
	printf("Computer: %s, ", buf);
	rc = sizeof(buf);
	GetUserName(buf, &rc);
	printf("user: %s\n", buf);

	/* Logical drives info 1 */
	printf("\nDrives: ");
	drives = GetLogicalDrives();
	for (i = 0; i < 32; ++i) {
		if (drives & (1 << i)) printf("%c ", 'A'+i);
	}
	printf("\n");

	/* Logical drives info 2 */
	GetLogicalDriveStrings(sizeof(drvsbuf), drvsbuf);
	for (s = drvsbuf; strlen(s); ) {
		printf("%.2s - ", s);
		rc = GetDriveType(s);
		switch (rc) {
		case DRIVE_REMOVABLE:
			printf("removable\n");
			break;

		case DRIVE_FIXED:
			printf("fixed\n");
			break;

		case DRIVE_CDROM:
			printf("CD-ROM\n");
			break;

		case DRIVE_REMOTE:
			printf("network\n");
			break;

		case DRIVE_RAMDISK:
			printf("RAM disk\n");
			break;

		case 1:
			printf("The root directory does not exist.\n");
			break;

		case 0:
		default:
			printf("The drive type cannot be determined.\n");
			break;
		}
		{
			UINT	o_SEM;
			char	buf[1024];

			o_SEM = SetErrorMode(SEM_FAILCRITICALERRORS);
			rc = !GetVolumeInformation(s, volname, sizeof(volname), &volsn, &maxclen, &fsflags, fsname, sizeof(fsname));
			if (rc) rc = GetLastError();
			if (rc) {
				printf("    GetVolumeInformation() error (%d): %s", rc, win_err_message(buf, sizeof(buf), rc));
			} else {
				printf("    Label: %s, serial: %04X:%04X, %s\n", *volname ? volname : "**none**",
					HIWORD(volsn), LOWORD(volsn), fsname);
				GetDiskFreeSpace(s, &spc, &bps, &nfc, &tnc);
				fbytes = (unsigned __int64) nfc*spc*bps;
				tbytes = (unsigned __int64) tnc*spc*bps;
				printf("    Cluster size: %u bytes, %u of %u free clusters (%I64u k of %I64u k)\n", spc*bps, nfc, tnc, fbytes/1024, tbytes/1024);
				if (pGetDiskFreeSpaceEx) {
					ULARGE_INTEGER	caller_free, total, total_free;

					GetDiskFreeSpaceEx(s, &caller_free, &total, &total_free);
					printf("    %I64u k (%I64u k for caller) of %I64u k free\n",
						total_free.QuadPart/1024, caller_free.QuadPart/1024, total.QuadPart/1024);
				}
			}
			SetErrorMode(o_SEM);
		}
		while (*s) ++s;
		++s;
	}
	printf("\n");

	/* Memory info */
	printf("Memory ");
	memset(&mem_stat, 0, sizeof(MEMORYSTATUS));
	mem_stat.dwLength = sizeof(MEMORYSTATUS);
	GlobalMemoryStatus(&mem_stat);
	printf("used %u%%,\n"
			"Total phis: %u Kb, free: %u Kb\n"
			"Max page file: %u Mb, free: %u Mb\n"
			"Total virt: %u Mb, free: %u Mb\n",
			mem_stat.dwMemoryLoad,
			mem_stat.dwTotalPhys/1024, mem_stat.dwAvailPhys/1024,
			mem_stat.dwTotalPageFile/1024/1024, mem_stat.dwAvailPageFile/1024/1024,
			mem_stat.dwTotalVirtual/1024/1024, mem_stat.dwAvailVirtual/1024/1024);

	printf("sizeof(size_t) = %u, sizeof(unsigned long) = %u\n", sizeof(size_t), sizeof(unsigned long));

//	  printf("Press Enter");
//	  gets(buf);
	return 0;
}
