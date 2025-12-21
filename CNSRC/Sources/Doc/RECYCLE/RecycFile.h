////////////////////////////////////////////////////////////////
// MSDN -- April 2001
// If this code works, it was written by Paul DiLascia.
// If not, I don't know who wrote it.
// Compiles with Visual C++ 6.0. Runs on Win 98 and probably Win 2000 too.
//
#include <shellapi.h>

//////////////////
// CRecycleFile -- sends a file to the Recycle Bin.
// Note derived from SHFILEOPSTRUCT.
//
class CRecycleFile : public SHFILEOPSTRUCT {
protected:
public:
	CRecycleFile();
	~CRecycleFile() { }
	int Recycle(LPCTSTR pszPath, BOOL bDelete=FALSE);
};
