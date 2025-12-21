extern "C" BOOL SetFAttr(char *fName, DWORD fAttr);

extern "C"
BOOL SetFTime(
      char *fName,
      DWORD dwLowDateTime,
      DWORD dwHighDateTime,
      DWORD tTime);

extern "C"
BOOL GetFTime(
      char *fName,
      LPDWORD dwLowDateTime,
      LPDWORD dwHighDateTime,
      DWORD tTime);

