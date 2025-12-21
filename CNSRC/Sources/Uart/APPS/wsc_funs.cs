// C# Declarations for WSC4C
//
// Add the contents of this file to the C# source code
// after the statement
//
//     public class XXX : System.Windows.Forms.Form
//
// where XXX = the name of the class.
//
        

 [DllImport("wsc32.dll")]
 public static extern int SioKeyCode(unsigned long KeyCode);
 [DllImport("wsc32.dll")]
 public static extern int SioGetReg(string Buffer, int Size);
 [DllImport("wsc32.dll")]
 public static extern int SioReset(int Port, int InQueue, int OutQueue);
 [DllImport("wsc32.dll")]
 public static extern int SioDone(int Port);
 [DllImport("wsc32.dll")]
 public static extern int SioBaud(int Port, unsigned BaudRate);
 [DllImport("wsc32.dll")]
 public static extern int SioPutc(int Port, char Byte);
 [DllImport("wsc32.dll")]
 public static extern int SioPuts(int Port, string Buffer, unsigned Size);
 [DllImport("wsc32.dll")]
 public static extern int SioGetc(int Port);
 [DllImport("wsc32.dll")]
 public static extern int SioGets(int Port,string Buffer,unsigned Size);
 [DllImport("wsc32.dll")]
 public static extern int SioDTR(int Port,char Cmd);
 [DllImport("wsc32.dll")]
 public static extern int SioRTS(int Port,char Cmd);
 [DllImport("wsc32.dll")]
 public static extern int SioTxClear(int Port); 
 [DllImport("wsc32.dll")]
 public static extern int SioRxClear(int Port); 
 [DllImport("wsc32.dll")]
 public static extern int SioTxQue(int Port);
 [DllImport("wsc32.dll")]
 public static extern int SioRxQue(int Port); 
 [DllImport("wsc32.dll")]
 public static extern int SioStatus(int Port, unsigned Mask);
 [DllImport("wsc32.dll")]
 public static extern int SioFlow(int Port,char Cmd); 
 [DllImport("wsc32.dll")]
 public static extern int SioParms(int Port,int Parity,int StopBits,int DataBits);
 [DllImport("wsc32.dll")]
 public static extern int SioCTS(int Port);
 [DllImport("wsc32.dll")]
 public static extern int SioDSR(int Port);
 [DllImport("wsc32.dll")]
 public static extern int SioRI(int Port);
 [DllImport("wsc32.dll")]
 public static extern int SioDebug(int Parm);
 [DllImport("wsc32.dll")]
 public static extern int SioSetInteger(int Port, int ParmName, LONG ParmValue); 
 [DllImport("wsc32.dll")]
 public static extern int SioInfo(char Parm);
 [DllImport("wsc32.dll")]
 public static extern int SioDCD(int Port);
 [DllImport("wsc32.dll")]
 public static extern int SioBrkSig(int Port,char Cmd); 
 [DllImport("wsc32.dll")]
 public static extern int SioUnGetc(int Port,char Chr);
 [DllImport("wsc32.dll")]
 public static extern int SioWinError(string Buffer, int Size);
 [DllImport("wsc32.dll")]
 public static extern int SioRead(int Port, int Reg);
 [DllImport("wsc32.dll")]
 public static extern int SioEvent(int Port, DWORD MaskArg);
 [DllImport("wsc32.dll")]
 public static extern int SioMessage(int Port, HWND hMsgWnd, WORD MsgCode, DWORD Mask);

 
 
