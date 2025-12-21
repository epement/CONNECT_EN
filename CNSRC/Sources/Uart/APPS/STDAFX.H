// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#if _MSC_VER < 1300

  // MSVC: 4.0, 5.0, 6.0

  #define VC_EXTRALEAN
  #include <afxwin.h>

#else

  // MSVC.Net

  #pragma once

  #define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers
  // Windows Header Files:
  #include <windows.h>
  // C RunTime Header Files
  #include <stdlib.h>
  #include <malloc.h>
  #include <memory.h>
  #include <tchar.h>

  // TODO: reference additional headers your program requires here

#endif
