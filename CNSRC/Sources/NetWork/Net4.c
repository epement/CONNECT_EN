void CWNetSampleDlg::OnButtonAdd()
{
   UpdateData();

   NETRESOURCE nr;
   memset(&nr,0,sizeof(nr));
   nr.lpRemoteName = (LPTSTR)(LPCTSTR)m_sRemoteName;
   nr.dwType = RESOURCETYPE_DISK;

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
   nr.lpLocalName  = L"MyShareTmp";
   nr.dwType       = RESOURCETYPE_DISK;

   DWORD dwRes = WNetAddConnection3(
      m_hWnd,&nr,
      NULL,
      NULL,
      CONNECT_UPDATE_PROFILE);

   CString sErr;
   sErr.Format(L"Error = %d",dwRes);
   AfxMessageBox(sErr);
}
