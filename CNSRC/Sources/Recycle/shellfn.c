#include <Windows.h>
#include <Shellapi.h>

bool PutFileToRecycle(AnsiString filename)
{
SHFILEOPSTRUCT SHF;
SHF.hwnd = Application->Handle;
SHF.wFunc = FO_DELETE;
SHF.pFrom = filename.c_str();
SHF.fFlags = FOF_SILENT + FOF_ALLOWUNDO;
return (SHFileOperation(SHF) == 0);
}
