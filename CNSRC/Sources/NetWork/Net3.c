BOOL EnumerateDomainResources(LPNETRESOURCE lpnrStartFrom,
                              CListBox& ListBox)
{
   DWORD dwResult, dwResultEnum, i;
   LPNETRESOURCE lpNRBuffer;
   DWORD dwBufferSize = 16384;
   DWORD dwNumEntries = (DWORD)-1;
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
      dwNumEntries = (DWORD)-1;
      // Get resources
      dwResultEnum = WNetEnumResource(hEnum, &dwNumEntries,
                                      lpNRBuffer, &dwBufferSize);
      if(dwResultEnum == NO_ERROR)
      {
         // loop through each of the entries
         for(i = 0; i < dwNumEntries; i++)
         {
            sErr.Format(L"%s",lpNRBuffer[i].lpRemoteName);
            ListBox.AddString(sErr);
            if( (lpNRBuffer[i].dwUsage & RESOURCEUSAGE_CONTAINER)
               == RESOURCEUSAGE_CONTAINER )
            {
               if( !EnumerateDomainResources(&lpNRBuffer[i],
                   ListBox) )
               {
                  AfxMessageBox(L"Enumeration Failed");
                  continue;
               }
            }
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
