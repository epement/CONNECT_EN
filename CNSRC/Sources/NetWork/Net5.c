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
   d.hwndOwner   = m_hWnd;
   d.lpLocalName = L"MyShare";
   DWORD dwRes   = WNetDisconnectDialog1(&d);
   CString sErr;
   sErr.Format(L"Error = %d",dwRes);
   AfxMessageBox(sErr);
}

void CWNetSampleDlg::OnButtonCancel2()
{
   DWORD dwRes = WNetCancelConnection2(L"MyShare",
                                       CONNECT_UPDATE_PROFILE,TRUE);
   CString sErr;
   sErr.Format(L"Error = %d",dwRes);
   AfxMessageBox(sErr);
}
