extern  BOOL SetFAttr(char *fName, DWORD fAttr);

extern
BOOL SetFTime(
      char *fName,
      DWORD dwLowDateTime,
      DWORD dwHighDateTime,
      DWORD tTime);

extern
BOOL GetFTime(
      char *fName,
      LPDWORD dwLowDateTime,
      LPDWORD dwHighDateTime,
      DWORD tTime);

