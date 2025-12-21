/*
Declared in Winnetwk.h.
Library

Link to Mpr.lib.
DLL     Requires Mpr.dll.
*/

BOOL WINAPI EnumerateFunc(HWND hwnd,
                          HDC hdc,
                          LPNETRESOURCE lpnr)
{
  DWORD dwResult, dwResultEnum;
  HANDLE hEnum;
  DWORD cbBuffer = 16384;      // 16K is a good size
  DWORD cEntries = -1;         // enumerate all possible entries
  LPNETRESOURCE lpnrLocal;     // pointer to enumerated structures
  DWORD i;
  //
  // Call the WNetOpenEnum function to begin the enumeration.
  //
  dwResult = WNetOpenEnum(RESOURCE_GLOBALNET, // all network resources
                          RESOURCETYPE_ANY,   // all resources
                          0,        // enumerate all resources
                          lpnr,     // NULL first time the function is called
                          &hEnum);  // handle to the resource

  if (dwResult != NO_ERROR)
  {
    //
    // Process errors with an application-defined error handler.
    //
    NetErrorHandler(hwnd, dwResult, (LPSTR)"WNetOpenEnum");
    return FALSE;
  }
  //
  // Call the GlobalAlloc function to allocate resources.
  //
  lpnrLocal = (LPNETRESOURCE) GlobalAlloc(GPTR, cbBuffer);
  if (lpnrLocal == NULL)
      return FALSE;

  do
  {
    //
    // Initialize the buffer.
    //
    ZeroMemory(lpnrLocal, cbBuffer);
    //
    // Call the WNetEnumResource function to continue
    //  the enumeration.
    //
    dwResultEnum = WNetEnumResource(hEnum,      // resource handle
                                    &cEntries,  // defined locally as -1
                                    lpnrLocal,  // LPNETRESOURCE
                                    &cbBuffer); // buffer size
    //
    // If the call succeeds, loop through the structures.
    //
    if (dwResultEnum == NO_ERROR)
    {
      for(i = 0; i < cEntries; i++)
      {
        // Call an application-defined function to
        //  display the contents of the NETRESOURCE structures.
        //
        DisplayStruct(hdc, &lpnrLocal[i]);

        // If the NETRESOURCE structure represents a container resource,
        //  call the EnumerateFunc function recursively.

        if(RESOURCEUSAGE_CONTAINER == (lpnrLocal[i].dwUsage
                                       & RESOURCEUSAGE_CONTAINER))
          if(!EnumerateFunc(hwnd, hdc, &lpnrLocal[i]))
            TextOut(hdc, 10, 10, "EnumerateFunc returned FALSE.", 29);
      }
    }
    // Process errors.
    //
    else if (dwResultEnum != ERROR_NO_MORE_ITEMS)
    {
      NetErrorHandler(hwnd, dwResultEnum, (LPSTR)"WNetEnumResource");
      break;
    }
  }
  //
  // End do.
  //
  while(dwResultEnum != ERROR_NO_MORE_ITEMS);
  //
  // Call the GlobalFree function to free the memory.
  //
  GlobalFree((HGLOBAL)lpnrLocal);
  //
  // Call WNetCloseEnum to end the enumeration.
  //
  dwResult = WNetCloseEnum(hEnum);

  if(dwResult != NO_ERROR)
  {
    //
    // Process errors.
    //
    NetErrorHandler(hwnd, dwResult, (LPSTR)"WNetCloseEnum");
    return FALSE;
  }

  return TRUE;
}

BOOL WINAPI NetErrorHandler(HWND hwnd,
                            DWORD dwErrorCode,
                            LPSTR lpszFunction)
{
    DWORD dwWNetResult, dwLastError;
    CHAR szError[256];
    CHAR szCaption[256];
    CHAR szDescription[256];
    CHAR szProvider[256];

    // The following code performs standard error-handling.

    if (dwErrorCode != ERROR_EXTENDED_ERROR)
    {
        wsprintf((LPSTR) szError, "%s failed; \nResult is %ld",
            lpszFunction, dwErrorCode);
        wsprintf((LPSTR) szCaption, "%s error", lpszFunction);
        MessageBox(hwnd, (LPSTR) szError, (LPSTR) szCaption, MB_OK);
        return TRUE;
    }

    // The following code performs error-handling when the
    //  ERROR_EXTENDED_ERROR return value indicates that the
    //  WNetGetLastError function can retrieve additional information.

    else
    {
        dwWNetResult = WNetGetLastError(&dwLastError, // error code
            (LPSTR) szDescription,  // buffer for error description
            sizeof(szDescription),  // size of error buffer
            (LPSTR) szProvider,     // buffer for provider name
            sizeof(szProvider));    // size of name buffer

        //
        // Process errors.
        //
        if(dwWNetResult != NO_ERROR) {
            wsprintf((LPSTR) szError,
                "WNetGetLastError failed; error %ld", dwWNetResult);
            MessageBox(hwnd, (LPSTR) szError,
                "WNetGetLastError", MB_OK);
            return FALSE;
        }

        //
        // Otherwise, print the additional error information.
        //
        wsprintf((LPSTR) szError,
            "%s failed with code %ld;\n%s",
            (LPSTR) szProvider, dwLastError, (LPSTR) szDescription);
        wsprintf((LPSTR) szCaption, "%s error", lpszFunction);
        MessageBox(hwnd, (LPSTR) szError, (LPSTR) szCaption, MB_OK);
        return TRUE;
    }
}


