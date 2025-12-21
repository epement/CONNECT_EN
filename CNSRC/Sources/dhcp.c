BOOL
RetrieveHostName(
    IN LPCWSTR    pszAdapterName,
    IN OUT CHAR[] pszHostNameBuf, // must be large enough buffer
    IN DWORD      dwHostNameBufSize
)
/*++

Routine returns TRUE on success and FALSE on failure.

--*/
{
    DWORD dwError, dwSize;
    CHAR TmpBuffer[1000]; // host name won't be larger than this
    DHCPCAPI_PARAMS DhcpApiHostNameParams = {
            0,                // Flags
            OPTION_HOST_NAME, // OptionId
            FALSE,            // vendor specific?
            NULL,             // data filled in on return
            0                 // nBytes
        };
    DHCPCAPI_PARAMS_ARRAY RequestParams = {
            1,  // only one option to request
            &DhcpApiHostNameParams
        };

    DHCPCAPI_PARAMS_ARRAY SendParams = {
            0,
            NULL
        };

    dwSize = sizeof(TmpBuffer);
    dwError = DhcpRequestParams(
            DHCPCAPI_REQUEST_SYNCHRONOUS, // Flags
            NULL,                         // Reserved
            pszAdapterName,               // Adapter Name
            NULL,                         // not using class id
                   &SendParams,                         // sent parameters
            RequestParams,                // requesting params
            (PBYTE) TmpBuffer,            // buffer
            &dwSize,                      // buffer size
            NULL                          // Request ID
        );

    if( ERROR_MORE_DATA == dwError )
    {
            //
            // dwSize is not large enough.
            //
    }

    if( NO_ERROR == dwError )
    {

            // Check if the requested option was obtained.

            if( DhcpApiHostNameParams.nBytesData )
            {

                // Check size with dwHostNameBufSize.

                CopyMemory(
                     pszHostNameBuf, DhcpApiHostNameParams.Data,
                     DhcpApiHostNameParams.nBytesData
                     );
                pszHostNameBuf[DhcpApiHostNameParams.nBytesData] = '\0';
                return TRUE;
            }
    }

    return FALSE;
}

Example 2: Using the DhcpRegisterParamChange function

The following code illustrates how the DhcpRegisterParamChange function can be used to keep track of host name changes:

ULONG
UpdateHostNameLoop(
    IN LPCWSTR    pszAdapterName,
    IN CHAR       pszHostNameBuf[],
    IN ULONG      dwHostBufSize
)
{
    DWORD dwError;
    HANDLE hEvent;
    DHCPCAPI_PARAMS DhcpApiHostNameParams = {
            0,                 // Flags
            OPTION_HOST_NAME,  // OptionId
            FALSE,             // vendor specific?
            NULL,              // data filled in on return
            0                  // nBytes
        };
    DHCPCAPI_PARAMS_ARRAY DhcpApiParamsArray = {
        1,         // only one option to request
        &DhcpApiHostNameParams
        };

    dwError = DhcpRegisterParamChange(
        DHCPCAPI_REGISTER_HANDLE_EVENT, // Flags
        NULL,                           // Reserved
        pszAdapterName,                 // adapter name
        NULL,                           // no class ID
        &DhcpApiHostNameParams,         // params of interest
        (LPVOID)&hEvent                 // event handle
        );

    if( NO_ERROR != dwError ) return dwError;

    // Wait on event all the time.

    while( WAIT_OBJECT_0 == WaitForSingleObject(hEvent, INFINITE) )
    {

        // Get host name and update it.

        ResetEvent(hEvent);
        dwError = RetrieveHostName(pszAdapterName, pszHostNameBuf, dwHostBufSize );

        // Ignore this error.

        break;
    }


    // Wait failed or retrieve failed? De-register the event handle.

    (void)DhcpDeRegisterParamChange(
        DHCPCAPI_REGISTER_HANDLE_EVENT, // Flags
        NULL,                           // Reserved
        (LPVOID) hEvent                 // event
        );

    return dwError;
}
