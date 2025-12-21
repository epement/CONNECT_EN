// WNetSample.h : main header file for the WNETSAMPLE application
//

#if !defined(AFX_WNETSAMPLE_H__AFCE8BA6_A7DD_49C7_996C_8A8FBFE5D3C4__INCLUDED_)
#define AFX_WNETSAMPLE_H__AFCE8BA6_A7DD_49C7_996C_8A8FBFE5D3C4__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"		// main symbols

/////////////////////////////////////////////////////////////////////////////
// CWNetSampleApp:
// See WNetSample.cpp for the implementation of this class
//

class CWNetSampleApp : public CWinApp
{
public:
	CWNetSampleApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CWNetSampleApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation

	//{{AFX_MSG(CWNetSampleApp)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft eMbedded Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_WNETSAMPLE_H__AFCE8BA6_A7DD_49C7_996C_8A8FBFE5D3C4__INCLUDED_)
