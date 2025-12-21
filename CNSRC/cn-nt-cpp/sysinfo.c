#include <string.h>
#include <windows.h>

#pragma pack(1)
typedef struct _ASI{
 OSVERSIONINFO   os_ver_inf;
 MEMORYSTATUS    mem_stat;
 SYSTEM_INFO     si;
 char ComputerName[128];
 char UserName[128];
} ASI, *PASI;

void asysinfo(void * asi)
{
 int rc;
 int name_size;

 /* Windows version */
 memset((PASI)asi, 0, sizeof(ASI));
 ((PASI)asi) -> os_ver_inf.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
 GetVersionEx(&((PASI)asi) -> os_ver_inf);
 /* Name of computer and user */
 rc = sizeof(((PASI)asi) -> ComputerName);
 GetComputerName(&((PASI)asi) -> ComputerName, &rc);
 name_size = strlen((LPCSTR)(((PASI)asi) -> ComputerName));
 CharToOemBuff((LPCSTR)(LPCSTR)(((PASI)asi) -> ComputerName),
               (LPTSTR)(LPCSTR)(((PASI)asi) -> ComputerName), name_size);
 rc = sizeof(((PASI)asi) -> UserName);
 GetUserName(&((PASI)asi) -> UserName, &rc);
 name_size = strlen((LPCSTR)(((PASI)asi) -> UserName));
 CharToOemBuff((LPCSTR)(LPCSTR)(((PASI)asi) -> UserName),
               (LPTSTR)(LPCSTR)(((PASI)asi) -> UserName), name_size);
 /* Memory info */
 ((PASI)asi) -> mem_stat.dwLength = sizeof(MEMORYSTATUS);
 GlobalMemoryStatus(&((PASI)asi) -> mem_stat);
 /* SysInfo*/
 GetSystemInfo(&((PASI)asi) -> si);
 return;
}
