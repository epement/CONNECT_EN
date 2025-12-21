////////////////////////////////////////////////////////////////
// MSDN -- April 2001
// If this code works, it was written by Paul DiLascia.
// If not, I don't know who wrote it.
// Compiles with Visual C++ 6.0. Runs on Win 98 and probably Win 2000 too.
//
#include <windows.h>
#include <tchar.h>
#include "RecycFile.h"

//////////////////
// Constructor initializes SHFILEOPSTRUCT with reasonable
// defaults. You can override if you like. Go ahead, make my day.
//
CRecycleFile::CRecycleFile()
{
	memset((SHFILEOPSTRUCT*)this,0,sizeof(SHFILEOPSTRUCT));
	fFlags |= FOF_SILENT;					 // don't report progress
	fFlags |= FOF_NOERRORUI;				 // don't report errors
	fFlags |= FOF_NOCONFIRMATION;			 // don't confirm delete
}

//////////////////
// Send a file to the recycle bin. Args:
//  - full pathname of file.
//  - bDelete: if TRUE, really delete file (no recycle bin)
//
int CRecycleFile::Recycle(LPCTSTR pszPath, BOOL bDelete)
{
	// Copy pathname to double-NULL-terminated string.
	//
	TCHAR buf[_MAX_PATH + 1]; // allow one more character
	_tcscpy(buf, pszPath);	  // copy caller's pathname
	buf[_tcslen(buf)+1]=0;	  // need two NULLs at end

	// Set SHFILEOPSTRUCT params for delete operation
	//
	wFunc = FO_DELETE;						 // REQUIRED: delete operation
	pFrom = buf;								 // REQUIRED: which file(s)
	pTo = NULL;									 // MUST be NULL
	if (bDelete) {								 // if delete requested..
		fFlags &= ~FOF_ALLOWUNDO;			 // ..don't use Recycle Bin
	} else {										 // otherwise..
		fFlags |= FOF_ALLOWUNDO;			 // ..send to Recycle Bin
	}
	return SHFileOperation(this);			 // do it!
}

