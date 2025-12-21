enum mcommands {mcmOn, mcmOff, mcmGetRam, mcmGetEE, mcmSetAddr,
                mcmSetGrp0, mcmSetGrp1, mcmSetGrp2, mcmSetGrp3,
                mcmLock, mcmWriteAddr, mcmSetEEaddr, mcmSetEEdata,
                mcmTest, mcmPrefix, mcm_num};

enum merrors {meOk, meEchoTimeout, meEchoMismatch, meReplyTimeout,
              meChecksumMismatch, meEE_Mismatch, meCommErr, meCollision,
              merr_num};

#define PKT_EE_DELAY    200
#define PKT_EE_TIMEOUT  200
#define PKT_DELAY       15
#define PKT_TIMEOUT     40

#ifdef _MADLI_DLL_
#define DLL_FUNC extern __export WINAPI
#else
#define DLL_FUNC __declspec(dllimport) __stdcall
#endif /* _MADLI_DLL_*/

/* Return error message string */
DLL_FUNC
LPCTSTR ErrorStr(byte i);

/* Delay in milliseconds */
DLL_FUNC
void Delay(DWORD ms);

/* Open COM port. parity = 'N', 'O', 'E'. stopbits = 1 - 1, 2 - 1.5, 3 - 2 */
DLL_FUNC
HANDLE OpenComPort(word port, DWORD baud, byte bits,
                   char parity, byte stopbits, byte* mError,
                   leds led_fn);

/* Close COM port */
DLL_FUNC
void CloseComPort(HANDLE port);

/* Read RAM value from the ballast */
DLL_FUNC
bool GetRam(HANDLE port, word bAddr, byte ram, byte* state,
            word* data, byte* mError);

/* Read EE value from the ballast */
DLL_FUNC
bool GetEE(HANDLE port, word bAddr, byte ee, word* data, byte* mError);

/* Write EE value to the ballast */
DLL_FUNC
bool SetEE(HANDLE port, byte Group, word bAddr, byte ee,
            byte data, byte* mError);

/* Set ballast address */
DLL_FUNC
bool SetBallAddr(HANDLE port, word bAddr, byte* mError);

/* Set ballast group address */
DLL_FUNC
bool SetBallGroup(HANDLE port, word bAddr, byte GrNum,
                  byte GrAddr, byte* mError);

/* Read RAM parameters block from the ballast */
DLL_FUNC
bool GetRamBlock(HANDLE port, word bAddr, byte count, byte* state,
                 word data[], byte* mError, progress pr_fn);

/* Read EE parameters block from the ballast */
DLL_FUNC
bool GetEEBlock(HANDLE port, word bAddr, byte count,
                byte data[], byte* mError, progress pr_fn);

/* Write EE parameters block to the ballast */
DLL_FUNC
bool SetEEBlock(HANDLE port, byte Group, word bAddr, byte count,
                 byte data[], byte* mError, progress pr_fn);

/* Send Switch On, Off and Test commands */
DLL_FUNC
bool bSwitch(HANDLE port, byte Group, word bAddr, byte cmd,
             byte dimm, byte* mError);

/* Send MADLI packet */
DLL_FUNC
bool mSendPkt(HANDLE port, byte Cmd, byte Group,
              word bAddr, byte data, byte* mError);

/* Receive MADLI packet */
DLL_FUNC
bool mReceivePkt(HANDLE port, DWORD timeout_ms, byte* state,
                 word* data, byte* mError);

