void CWNetSampleDlg::OnButtonPrint()
{
   UpdateData();
   HANDLE hFile = CreateFile(m_sRemoteName,GENERIC_WRITE,0,0,
                             OPEN_EXISTING,0,0);
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
         WriteFile(hFile,baFile.GetData(),baFile.GetSize()
                   - 1,&wb,0);

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

void CWNetSampleDlg::OnButtonPrintCopy()
{
   UpdateData();
   CopyFile(L"\\Sample.txt",m_sRemoteName,FALSE);
}
