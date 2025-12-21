////////////////////////////////////////////////////////////////
// MSDN -- April 2001
// If this code works, it was written by Paul DiLascia.
// If not, I don't know who wrote it.
// Compiles with Visual C++ 6.0. Runs on Win 98 and probably Win 2000 too.
//
#pragma once
#pragma warning(disable:4786)				 // disable annoying C4786
#define VC_EXTRALEAN							 // Exclude rarely-used stuff from headers
#include <windows.h>
#include <stdio.h>
#include <direct.h>							 // getcwd
#include <conio.h>							 // getche
#include <tchar.h>
#include <assert.h>
#include <string>								 // STL string class
#include <list>								 // STL list class
#include <sys/stat.h>						 // stat function
#include "RecycFile.h"

using namespace std;							 // use STL
typedef list<string> CStringList;		 // like MFC

// I'm really roughing it here--need my own TRACE and ASSERT!
#define ASSERT assert
#ifdef _DEBUG
#define TRACE _tprintf
#else
#define TRACE 1 ? (void)0 : ::_tprintf
#endif

// pre-declare functions
void    usage();
void	  help();
string  GetCurrentDir();
string  MakeAbsolute(const string& relname);
BOOL    confirm(LPCTSTR pFileName);
LPCTSTR GetErrorMsg(int err);

// global command-line switches
BOOL bPrompt=FALSE;			// prompt each file
BOOL bQuiet=FALSE;			// don't display messages
BOOL bDisplayOnly=FALSE;	// display results only; don't actually recycle
BOOL bZap=FALSE;				// really delete (don't recycle)

// test if file exists
inline fileexists(LPCTSTR pFilename)
{
	struct stat st;
	return stat(pFilename, &st)==0;
}

// check for switch: / or -
inline BOOL isswitch(TCHAR c)
{
	return c==L'/' || c==L'-';
}

//////////////////
// Main function expects argv already expanded for wildcards. You must link
// with setargv.obj!!
//
int main(int argc, TCHAR* argv[], TCHAR* envp[])
{
	// Parse command line, building list of filenames.
	// Switches can come in any order.
	//
	CStringList files;
	for (int i=1; i<argc; i++) {
		if (isswitch(argv[i][0])) {
			switch(tolower(argv[i][1])) {
			case 'q':
				bQuiet=TRUE;
				break;
			case 'n':
				bDisplayOnly=TRUE;
				break;
			case 'p':
				bPrompt=TRUE;
				break;
			case 'z':
				bZap=TRUE;
				break;
			case '?':
				help();
				return 0;
			default:
				usage();
				return 0;
			}
		} else {
			// Got a filename. Make it absolute and add to list.
			files.push_back(MakeAbsolute(argv[i]));
		}
	}

	if (files.empty()) {
		// No files specified: tell bozo user how to use this command.
		usage();
		return 0;
	}

	// Delete (recycle) all the files in the list
	int nDel=0;
	CStringList::iterator it;

	// loop over list of files and recycle each one 
	for (it=files.begin(); it!=files.end(); it++) {
		const string& filename = *it;
		LPCTSTR pFileName = filename.c_str();

		// Only recycle if file exists. If the user types a wildcard--eg:
		//			recycle foo.*
		// and there are no files that match "foo.*", then setargv passes the
		// wildcard expression unexpanded--but obviously there is no such file.
		//
		if (fileexists(pFileName)) {

			if (!bQuiet && !bPrompt) {
				// tell user I'm recycling this file
				_ftprintf(stderr,_T("%s %s\n"),
					bZap ? _T("Deleting") : _T("Recycling"), pFileName);
			}

			if (!bDisplayOnly) {
				if (!bPrompt || confirm(pFileName)) {
					// Finally! Recycle the file. Use CRecycleFile.
					CRecycleFile rf;
					int err = rf.Recycle(pFileName,bZap);
					if (err==0) {
						nDel++;
					} else {
						// Can't recycle: display error message
						_ftprintf(stderr,_T("Error %d: %s"), err, GetErrorMsg(err));
					}
				}
			}
		} else {
			_ftprintf(stderr,_T("File not found \"%s\"\n"), pFileName);
		}
	}
	if (!bQuiet) {
		_ftprintf(stderr,_T("%d files recycled\n"),nDel);
	}
	return 0;
}

////////////////
// Duh.
//
void usage()
{
	_tprintf(_T("Usage: RECYCLE [/QNPZ?] file...\n"));
}

////////////////
// Ditto duh.
//
void help()
{
   _tprintf(_T("Purpose:  Send one or more files to the recycle bin.\n"));
   _tprintf(_T("Format:   RECYCLE [/Q /N /P /Z] file....\n"));
   _tprintf(_T("          /Q(uiet)     no messages\n"));
   _tprintf(_T("          /N(othing)   don't delete, just show files\n"));
   _tprintf(_T("          /P(rompt)    confirm each file\n"));
   _tprintf(_T("          /Z(ap)       really delete--same as del\n"));
}

//////////////////
// Make a filename absolute with respect to current directory.
//
string MakeAbsolute(const string& relname)
{
	// Get current directory. Since cwd is static this happens only once.
	static const string cwd = GetCurrentDir();

	string absname;
	if (relname[0] && relname[1] && relname[1]==':') {
		// relname is already absolute
		absname = relname;

	} else if (relname[0]=='\\') {
		// relname begins with \ -- add drive letter and colon
		absname = string(cwd,0,2);
		absname += relname;

	} else {										 // filename begins with letter:
		// relname begins with a letter -- prepend cwd
		absname = cwd;
		absname += relname;
	}
	return absname;
}

//////////////////
// Get current directory. For some reason unknown to mankind, getcwd returns
// "C:\FOO" (no \ at end) if dir is NOT root; yet it returns "C:\" (with \)
// if cwd is root. Go figure. To make the result consistent for appending a
// filename, GetCurrentDir adds the missing \ if needed. Result always has
// final \.
//
string GetCurrentDir()
{
	TCHAR dir[MAX_PATH];
	_tgetcwd(dir, sizeof(dir)/sizeof(TCHAR));

	// Append '\' if needed
	int lastchar = _tcslen(dir)-1;
	if (lastchar>0 && dir[lastchar] != '\\') // if last char isn't \ ..
		_tcscat(dir,_T("\\"));						  // ..add one

	return dir;										  // compiler will convert to string!
}

//////////////////
// Get user confirmation to recycle/delete a file
//
BOOL confirm(LPCTSTR pFileName)
{
	while (TRUE) {
		_tprintf(_T("Recycle %s (Y/N/All)? "), pFileName);
		char c = _getche();
		if (c=='') {
			_tprintf(_T("^C\n"));
			exit(0);
		}
		_tprintf(_T("\n"));
		switch (tolower(c)) {
		case 'a':
			bPrompt=FALSE;
			// fall through
		case 'y':
			return TRUE;
		case 'n':
			return FALSE;
		}
	}
}

//////////////////
// Get Windows system error message
//
LPCTSTR GetErrorMsg(int err)
{
	const BUFSIZE = 512;
	static TCHAR buf[BUFSIZE];
	buf[0]=0;

	// Only Windows could have a function this confusing to get a simple error
	// message.
	FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
		NULL,		// source
		err,		// error code
		0,			// language ID
		buf,		// buffer to receive message
		BUFSIZE,	// size of buf
		NULL);	// arguments
	return buf;
}

