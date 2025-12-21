// WNetSampleDlg.h : header file
//

#if !defined(AFX_WNETSAMPLEDLG_H__09B47768_2214_4C52_B97E_479C1D4822DC__INCLUDED_)
#define AFX_WNETSAMPLEDLG_H__09B47768_2214_4C52_B97E_479C1D4822DC__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

/////////////////////////////////////////////////////////////////////////////
// CWNetSampleDlg dialog

class CWNetSampleDlg : public CDialog
{
// Construction
public:
	CWNetSampleDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CWNetSampleDlg)
	enum { IDD = IDD_WNETSAMPLE_DIALOG };
	CListBox	m_ResList;
	CString	m_EditName;
	CString	m_sRemoteName;
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CWNetSampleDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	HICON m_hIcon;

	// Generated message map functions
	//{{AFX_MSG(CWNetSampleDlg)
	virtual BOOL OnInitDialog();
	afx_msg void OnButtonEnumShares();
	afx_msg void OnButtonPrint();
	afx_msg void OnButtonAdd();
	afx_msg void OnButtonAdd3();
	afx_msg void OnButtonDisc();
	afx_msg void OnButtonDisc1();
	afx_msg void OnButtonCancel2();
	afx_msg void OnButtonPrintCopy();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

//{{AFX_INSERT_LOCATION}}
// Microsoft eMbedded Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_WNETSAMPLEDLG_H__09B47768_2214_4C52_B97E_479C1D4822DC__INCLUDED_)
