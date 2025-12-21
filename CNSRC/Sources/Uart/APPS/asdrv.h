/* asdrv.h */

#define ASC_NO_ERROR            0
#define ASC_NOT_ACTIVE_ERROR   -700
#define ASC_CANNOT_OPEN_ERROR  -701
#define ASC_DISK_READ_ERROR    -702
#define ASC_INTERNAL_ERROR     -705
#define ASC_NOT_OPEN_ERROR     -706

NoMangle int ascAbort(void);
NoMangle int ascGetErrorCode(void);
NoMangle int ascGetErrorState(void);
NoMangle LPSTR ascGetFilename(void);
NoMangle int ascGetState(void);
NoMangle long ascGetFileLength(void);
NoMangle long ascGetCharCount(void);
NoMangle void ascInit(int,int,int);
NoMangle void ascStartTx(LPSTR,int,char,int);
NoMangle void ascStartRx(LPSTR,char,int,int,int);
NoMangle int ascDriver(void);

