// WNetSampleDlg.cpp : implementation file
//

#include "stdafx.h"
#include "WNetSample.h"
#include "WNetSampleDlg.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CWNetSampleDlg dialog

CWNetSampleDlg::CWNetSampleDlg(CWnd* pParent /*=NULL*/)
: CDialog(CWNetSampleDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(CWNetSampleDlg)
	m_EditName = _T("\\\\someresource");
	m_sRemoteName = _T("");
	//}}AFX_DATA_INIT
	// Note that LoadIcon does not require a subsequent DestroyIcon in Win32
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CWNetSampleDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CWNetSampleDlg)
	DDX_Control(pDX, IDC_LIST1, m_ResList);
	DDX_Text(pDX, IDC_EDIT1, m_EditName);
	DDX_LBString(pDX, IDC_LIST1, m_sRemoteName);
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CWNetSampleDlg, CDialog)
//{{AFX_MSG_MAP(CWNetSampleDlg)
ON_BN_CLICKED(IDC_BUTTON_ENUM_SHARES, OnButtonEnumShares)
	ON_BN_CLICKED(IDC_BUTTON_PRINT, OnButtonPrint)
	ON_BN_CLICKED(IDC_BUTTON_ADD, OnButtonAdd)
	ON_BN_CLICKED(IDC_BUTTON_ADD2, OnButtonAdd3)
	ON_BN_CLICKED(IDC_BUTTON_DISC, OnButtonDisc)
	ON_BN_CLICKED(IDC_BUTTON_DISC1, OnButtonDisc1)
	ON_BN_CLICKED(IDC_BUTTON_CANCEL2, OnButtonCancel2)
	ON_BN_CLICKED(IDC_BUTTON_PRINT2, OnButtonPrintCopy)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CWNetSampleDlg message handlers

BOOL CWNetSampleDlg::OnInitDialog()
{
	CDialog::OnInitDialog();
	
	// Set the icon for this dialog.  The framework does this automatically
	//  when the application's main window is not a dialog
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon
	
	CenterWindow(GetDesktopWindow());	// center to the hpc screen
	
	// TODO: Add extra initialization here
	
	return TRUE;  // return TRUE  unless you set the focus to a control
}

BOOL EnumerateDomainResources(LPNETRESOURCE lpnrStartFrom, CListBox& ListBox)
{
	DWORD dwResult, dwResultEnum, i;
	LPNETRESOURCE lpNRBuffer;
	DWORD dwBufferSize = 16384;
	DWORD dwNumEntries = 0xFFFFFFFF;
	HANDLE hEnum;
	CString sErr;

	dwResult = WNetOpenEnum(RESOURCE_GLOBALNET, RESOURCETYPE_ANY, 
			0, lpnrStartFrom, &hEnum);
	if(dwResult != NO_ERROR)
	{
		sErr.Format(L"WNetOpenEnum err = %d",dwResult);
		AfxMessageBox(sErr);
		return FALSE;
	}

	// allocate a buffer
	lpNRBuffer = (LPNETRESOURCE) new BYTE[dwBufferSize];

	// loop through all the stuff
	do
	{
		dwBufferSize = 16384;
		dwNumEntries = 0xFFFFFFFF;
		// Get resources
		dwResultEnum = WNetEnumResource(hEnum, &dwNumEntries, lpNRBuffer, &dwBufferSize);
		if(dwResultEnum == NO_ERROR)
		{
			// loop through each of the entries
			for(i = 0; i < dwNumEntries; i++)
			{
				sErr.Format(L"%s",lpNRBuffer[i].lpRemoteName);
				ListBox.AddString(sErr);
			}
		}
		else if(dwResultEnum != ERROR_NO_MORE_ITEMS)
		{
			sErr.Format(L"WNetEnumResource err = %d",dwResultEnum);
			AfxMessageBox(sErr);
			break;
		}
	}
	while(dwResultEnum != ERROR_NO_MORE_ITEMS);

	delete lpNRBuffer;

	dwResult = WNetCloseEnum(hEnum);
	if(dwResult != NO_ERROR)
	{
		sErr.Format(L"WNetCloseEnum err = %d",dwResult);
		AfxMessageBox(sErr);
		return FALSE;
	}

	return TRUE;
}

void CWNetSampleDlg::OnButtonEnumShares() 
{
	UpdateData();
	BeginWaitCursor();
	//Listing3_7(m_EditName,m_ResList);
	NETRESOURCE nr;
	memset(&nr, 0, sizeof(nr));
	nr.lpRemoteName = (LPTSTR)(LPCTSTR)m_EditName;
	nr.dwUsage = RESOURCEUSAGE_CONTAINER;
	nr.dwType = RESOURCETYPE_DISK;
	EnumerateDomainResources(&nr, m_ResList);
	EndWaitCursor();
}

void CWNetSampleDlg::OnButtonPrint() 
{
	UpdateData();
	HANDLE hFile = CreateFile(m_sRemoteName,GENERIC_WRITE,0,0,OPEN_EXISTING,0,0);
	if ( hFile != INVALID_HANDLE_VALUE )
	{
		CFile f;
		if ( f.Open(L"\\Sample.txt",CFile::modeRead) )
		{
			CByteArray baFile;
			baFile.SetSize(f.GetLength() + 1);
			f.Read(baFile.GetData(),f.GetLength());
			f.Close();

			DWORD wb;
			WriteFile(hFile,baFile.GetData(),baFile.GetSize() - 1,&wb,0);

			AfxMessageBox(L"Sent data to " + m_sRemoteName);
		}
		else
		{
			AfxMessageBox(L"Failed to open local file");
		}

		CloseHandle(hFile);
	}
	else
	{
		AfxMessageBox(L"Failed to open " + m_sRemoteName);
	}
}

void CWNetSampleDlg::OnButtonAdd() 
{
	UpdateData();

	NETRESOURCE nr;
	memset(&nr,0,sizeof(nr));
	//nr.lpRemoteName = (LPTSTR)(LPCTSTR)m_sRemoteName;
	//nr.dwType = RESOURCETYPE_DISK;

	CONNECTDLGSTRUCT c;
	memset(&c,0,sizeof(c));
	c.cbStructure = sizeof(CONNECTDLGSTRUCT);
	c.hwndOwner = m_hWnd;
	c.lpConnRes = &nr;

	DWORD dwRes = WNetConnectionDialog1(&c);
	CString sErr;
	sErr.Format(L"Error = %d",dwRes);
	AfxMessageBox(sErr);
}

void CWNetSampleDlg::OnButtonAdd3() 
{
	UpdateData();

	NETRESOURCE nr;
	memset(&nr,0,sizeof(nr));
	nr.lpRemoteName = (LPTSTR)(LPCTSTR)m_sRemoteName;
	nr.lpLocalName = L"MyShareTmp";
	nr.dwType = RESOURCETYPE_DISK;

	DWORD dwRes = WNetAddConnection3(
		m_hWnd,&nr, 
		NULL,
		NULL,
		0);//CONNECT_UPDATE_PROFILE);

	CString sErr;
	sErr.Format(L"Error = %d",dwRes);
	AfxMessageBox(sErr);
}

void CWNetSampleDlg::OnButtonDisc() 
{
	DWORD dwRes = WNetDisconnectDialog(m_hWnd,0);
	CString sErr;
	sErr.Format(L"Error = %d",dwRes);
	AfxMessageBox(sErr);
}

void CWNetSampleDlg::OnButtonDisc1() 
{
	DISCDLGSTRUCT d;
	d.cbStructure = sizeof(DISCDLGSTRUCT);
	memset(&d,0,sizeof(d));
	d.hwndOwner = m_hWnd;
	d.lpLocalName = L"MyShare";
	DWORD dwRes = WNetDisconnectDialog1(&d);
	CString sErr;
	sErr.Format(L"Error = %d",dwRes);
	AfxMessageBox(sErr);
}

void CWNetSampleDlg::OnButtonCancel2() 
{
	DWORD dwRes = WNetCancelConnection2(L"MyShare",CONNECT_UPDATE_PROFILE,TRUE);
	CString sErr;
	sErr.Format(L"Error = %d",dwRes);
	AfxMessageBox(sErr);
}

void CWNetSampleDlg::OnButtonPrintCopy() 
{
	UpdateData();
	CopyFile(L"\\Sample.txt",m_sRemoteName,FALSE);
}
