enum mcommands {mcmOn, mcmOff, mcmGetRam, mcmGetEE, mcmSetAddr,
                mcmSetGrp0, mcmSetGrp1, mcmSetGrp2, mcmSetGrp3,
                mcmLock, mcmWriteAddr, mcmSetEEaddr, mcmSetEEdata,
                mcmTest, mcmPrefix, mcm_num};

enum merrors {meOk, meEchoTimeout, meEchoMismatch, meReplyTimeout,
              meChecksumMismatch, meEE_Mismatch, meCommErr, meCollision,
              merr_num};

extern const char * const mErr_str[];

void Delay(DWORD ms);

HANDLE OpenComPort(word port, USHORT baud, byte bits,
                        char parity, byte stopbits, pbyte res);

void CloseComPort(HANDLE port);

bool GetRam(HANDLE port, word bAddr, byte ram, byte* state,
            word* data, byte* mError);

bool GetEE(HANDLE port, word bAddr, byte ram, word* data, byte* mError);


bool SetEE(HANDLE port, byte Group, word bAddr, byte ee,
            byte data, byte* mError);

bool SetBallAddr(HANDLE port, word bAddr, byte* mError);

bool SetBallGroup(HANDLE port, word bAddr, byte GrNum,
                  byte GrAddr, byte* mError);

bool GetRamBlock(HANDLE port, word bAddr, byte count, byte* state,
                 word data[], byte* mError, progress pr_fn);

bool GetEEBlock(HANDLE port, word bAddr, byte count,
                word data[], byte* mError, progress pr_fn);

bool SetEEBlock(HANDLE port, byte Group, word bAddr, byte count,
                 byte data[], byte* mError, progress pr_fn);

bool bSwitch(HANDLE port, byte Group, word bAddr, byte cmd,
             byte dimm, byte* mError);

bool SetBallAddr(HANDLE port, word bAddr, byte* mError);

bool SetBallGroup(HANDLE port, word bAddr, byte GrNum,
                  byte GrAddr, byte* mError);


