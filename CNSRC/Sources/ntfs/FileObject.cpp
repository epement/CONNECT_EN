// FileObject.cpp : Implementation of CFileObject
#include "stdafx.h"
#include "NTFSOM.h"
#include "FileObject.h"

// Necessary for FSCTL_SET_SPARSE

void SysMsg(DWORD dwRC);



/////////////////////////////////////////////////////////////////////////////
// CFileObject


STDMETHODIMP CFileObject::get_Compressed(long *pVal)
{
	// check the file
	if (!lstrlen(m_szFile))
		return E_FAIL;

	// Use GetFileAttributes to read the compression attribute
	DWORD dwAttrib = GetFileAttributes(m_szFile);
	*pVal = (dwAttrib & FILE_ATTRIBUTE_COMPRESSED ?1 :0);

	return S_OK;
}

STDMETHODIMP CFileObject::put_Compressed(long newVal)
{
	// check the file
	if (!lstrlen(m_szFile))
		return E_FAIL;

	// open the file
	HANDLE hFile = CreateFile(m_szFile, 
		GENERIC_READ|GENERIC_WRITE, 0, NULL, OPEN_EXISTING,
		FILE_ATTRIBUTE_ARCHIVE, NULL);
	if (hFile == INVALID_HANDLE_VALUE) 
		return E_FAIL;

	// set the compression flag
	unsigned short uCompType;
	if (newVal >0)
		uCompType = COMPRESSION_FORMAT_DEFAULT;
	else
		uCompType = COMPRESSION_FORMAT_NONE;

	DWORD dwReturnedBytes=0;
	BOOL b = DeviceIoControl(hFile, FSCTL_SET_COMPRESSION, 
		(LPVOID) &uCompType, sizeof(unsigned short), 
		NULL, 0, &dwReturnedBytes, NULL);
	if (!b) {
		CloseHandle(hFile);
		return E_FAIL;
	}

	// close the file
	CloseHandle(hFile);

	return S_OK;
}


STDMETHODIMP CFileObject::SetFile(BSTR bstrFile)
{
	USES_CONVERSION;

	// Store the file name
	lstrcpy(m_szFile, OLE2T(bstrFile));	
	return S_OK;
}

STDMETHODIMP CFileObject::get_Encrypted(long *pVal)
{
	// check the file
	if (!lstrlen(m_szFile))
		return E_FAIL;

	// Use GetFileAttributes to read the compression attribute
	DWORD dwAttrib = GetFileAttributes(m_szFile);
	*pVal = (dwAttrib & FILE_ATTRIBUTE_ENCRYPTED ?1 :0);

	return S_OK;
}

STDMETHODIMP CFileObject::put_Encrypted(long newVal)
{
	// check the file
	if (!lstrlen(m_szFile))
		return E_FAIL;

	// check the operation required
	if (newVal >0)
		EncryptFile(m_szFile);
	else
		DecryptFile(m_szFile, 0);
	
	return S_OK;
}

STDMETHODIMP CFileObject::get_EncryptionStatus(long *pVal)
{
	// check the file
	if (!lstrlen(m_szFile))
		return E_FAIL;

	DWORD dwVal;
	FileEncryptionStatus(m_szFile, &dwVal);
	
	return S_OK;
}


STDMETHODIMP CFileObject::get_CompressedSize(long *pVal)
{
	// check the file
	if (!lstrlen(m_szFile))
		return E_FAIL;

	*pVal = 0;
	DWORD dwHigh;
	DWORD dwLow = GetCompressedFileSize(m_szFile, &dwHigh);
	if (dwLow != -1)
		*pVal = MAKELONG(dwLow, dwHigh);
		
	return S_OK;
}


/*---------------------------------------------------------------*/
// Procedure...: SysMsg()
// Description.: Shows a system message
// INPUT.......: DWORD
// OUTPUT......: void
/*---------------------------------------------------------------*/
void SysMsg(DWORD dwRC)
{
	LPVOID lpMsgBuf;
	DWORD rc;

	rc = FormatMessage( 
			FORMAT_MESSAGE_ALLOCATE_BUFFER | 
			FORMAT_MESSAGE_FROM_SYSTEM |     
			FORMAT_MESSAGE_IGNORE_INSERTS,    
			NULL, dwRC,    
			MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), 
			(LPTSTR) &lpMsgBuf, 0, NULL );

    TCHAR s[1024];
	wsprintf(s, _T("%s:  %ld.\n\n\n%s:\n\n%s"),
	     _T("This is the error code"), dwRC,
	     _T("This is the system's explanation"), 
	     (rc==0 ?_T("<unknown>") :lpMsgBuf) );
	MessageBox(0,s,0,0);
    LocalFree(lpMsgBuf);

	return;
} 


STDMETHODIMP CFileObject::get_Size(long *pVal)
{
	// check the file
	if (!lstrlen(m_szFile))
		return E_FAIL;

	*pVal = 0;

	// open the file
	HANDLE hFile = CreateFile(m_szFile, 
		GENERIC_READ, 0, NULL, OPEN_EXISTING,
		FILE_ATTRIBUTE_ARCHIVE, NULL);
	if (hFile == INVALID_HANDLE_VALUE) 
		return E_FAIL;

	DWORD dwHigh;
	DWORD dwLow = GetFileSize(hFile, &dwHigh);
	if (dwLow != -1)
		*pVal = MAKELONG(dwLow, dwHigh);

	CloseHandle(hFile);

	return S_OK;
}

STDMETHODIMP CFileObject::MakeSparse()
{
	// check the file
	if (!lstrlen(m_szFile))
		return E_FAIL;

	// open the file or the stream
	HANDLE hFile = CreateFile(m_szFile, 
		GENERIC_READ|GENERIC_WRITE, 0, NULL, OPEN_EXISTING,
		FILE_ATTRIBUTE_ARCHIVE, NULL);
	if (hFile == INVALID_HANDLE_VALUE) 
		return E_FAIL;
	
	DWORD dwReturnedBytes=0;
	BOOL b = DeviceIoControl(hFile, FSCTL_SET_SPARSE, 
		NULL, 0, NULL, 0, &dwReturnedBytes, NULL);
	if (!b) {
		CloseHandle(hFile);
		return E_FAIL;
	}

	CloseHandle(hFile);

	return S_OK;
}


STDMETHODIMP CFileObject::get_Sparse(long *pVal)
{
	// check the file
	if (!lstrlen(m_szFile))
		return E_FAIL;

	// Use GetFileAttributes to read the compression attribute
	DWORD dwAttrib = GetFileAttributes(m_szFile);
	*pVal = (dwAttrib & FILE_ATTRIBUTE_SPARSE_FILE ?1 :0);

	return S_OK;
}


STDMETHODIMP CFileObject::Zero(long lFrom, long lTo)
{
	// check the file
	if (!lstrlen(m_szFile))
		return E_FAIL;

	// check it is a sparse file
	DWORD dwAttrib = GetFileAttributes(m_szFile);
	if (!(dwAttrib & FILE_ATTRIBUTE_SPARSE_FILE))
		return E_FAIL;	

	HANDLE hFile = CreateFile(m_szFile, 
		GENERIC_READ|GENERIC_WRITE, 0, NULL, OPEN_EXISTING,
		FILE_ATTRIBUTE_ARCHIVE, NULL);
	if (hFile == INVALID_HANDLE_VALUE) 
		return E_FAIL;
	
	// prepare the call
	DWORD dwReturnedBytes=0;
	FILE_ZERO_DATA_INFORMATION fzdi;
	fzdi.FileOffset.QuadPart = lFrom;
	fzdi.BeyondFinalZero.QuadPart = lTo;
	
	// zero the data
	BOOL b = DeviceIoControl(hFile, FSCTL_SET_ZERO_DATA, 
		(LPVOID) &fzdi, sizeof(fzdi), NULL, 0, 
		&dwReturnedBytes, NULL);
	if (!b) {
		CloseHandle(hFile);
		return E_FAIL;
	}

	CloseHandle(hFile);
	
	return S_OK;
}

STDMETHODIMP CFileObject::Test()
{
	HANDLE h = CreateFile("foo1.txt", GENERIC_READ|GENERIC_WRITE, 0, NULL, 
		OPEN_EXISTING, 0, NULL);
	DWORD dw;
	FILE_ALLOCATED_RANGE_BUFFER farb;
	farb.FileOffset.QuadPart = 0;
	farb.Length.QuadPart = GetFileSize(h, (PDWORD)&farb.Length.HighPart);

	DeviceIoControl(h, FSCTL_QUERY_ALLOCATED_RANGES, &farb, 
		sizeof(farb), NULL, 0, &dw, NULL);

	CloseHandle(h);

	return S_OK;
}

STDMETHODIMP CFileObject::MountVolume(BSTR bstrMountName, BSTR bstrVolume)
{
	USES_CONVERSION;

	TCHAR szBuf[1024];
	BOOL bFlag = GetVolumeNameForVolumeMountPoint(
		OLE2T(bstrVolume), szBuf, 1024);

	if (!bFlag)
		SysMsg(GetLastError());


	bFlag = SetVolumeMountPoint(OLE2T(bstrMountName), szBuf); 
	if (!bFlag)
		SysMsg(GetLastError());

	return S_OK;
}

STDMETHODIMP CFileObject::DeleteMountVolume(BSTR bstrVolume)
{
	USES_CONVERSION;

	DeleteVolumeMountPoint(OLE2T(bstrVolume));
	return S_OK;
}
