Unit UMadli;
interface

type
 mcommands = (mcmOn, mcmOff, mcmGetRam, mcmGetEE, mcmSetAddr,
              mcmSetGrp0, mcmSetGrp1, mcmSetGrp2, mcmSetGrp3,
              mcmLock, mcmWriteAddr, mcmSetEEaddr, mcmSetEEdata,
              mcmTest, mcmPrefix, mcm_num);

 merrors = (meOk, meEchoTimeout, meEchoMismatch, meReplyTimeout,
            meChecksumMismatch, meEE_Mismatch, meCommErr, meCollision,
            merr_num);

 bool = boolean;
 dword = longint;
 THandle = longint;
 TProgrFunc = function(current, max: byte): bool;
 TLedFunc = procedure(led: byte);
 TWordArray = Array[0..1] of word;
 PWordArray = ^TWordArray;
 TByteArray = Array[0..1] of byte;
 PByteArray = ^TByteArray;

{ Return error message string }
function ErrorStr(i: byte): pchar; stdcall;

{ Delay in milliseconds }
procedure Delay(ms: Dword);

{ Open COM port. parity = 'N', 'O', 'E'. stopbits = 1 - 1, 2 - 1.5, 3 - 2 }
function OpenComPort(port: Word; baud: DWord; bits: byte; parity: char;
                     stopbits: byte; var mError: byte;
                     led_fn: TLedFunc): THandle; stdcall;

{ Close COM port }
procedure CloseComPort(port: THandle); stdcall;

{ Read RAM value from the ballast }
function GetRam(port: THandle; bAddr: word; ram: byte; var state: byte;
                var data: word; var mError: byte): bool; stdcall;

{ Read EE value from the ballast }
function GetEE(port: THandle; bAddr: word; ee: byte;
               var data: word; var mError: byte): bool; stdcall;

{ Write EE value to the ballast }
function SetEE(port: THandle; Group: byte; bAddr: word; ee: byte;
            data: byte; var mError: byte): bool; stdcall;

{ Set ballast address }
function SetBallAddr(port: THandle; bAddr: word;
                     var mError: byte): bool; stdcall;

{ Set ballast group address }
function SetBallGroup(port: THandle; bAddr: word; GrNum: byte;
                  GrAddr: byte; var mError: byte): bool; stdcall;

{ Read RAM parameters block from the ballast }
function GetRamBlock(port: THandle; bAddr: word; count: byte;
                     var state: byte; data: PWordArray; var mError: byte;
                     pr_fn: TProgrFunc): bool; stdcall;

{ Read EE parameters block from the ballast }
function GetEEBlock(port: THandle; bAddr: word; count: byte;
                    data: PByteArray; var mError: byte;
                    pr_fn: TProgrFunc): bool; stdcall;

{ Write EE parameters block to the ballast }
function SetEEBlock(port: THandle; Group: byte; bAddr: word; count: byte;
                    data: PByteArray; var mError: byte;
                    pr_fn: TProgrFunc): bool; stdcall;

{ Send Switch On; Off and Test commands }
function bSwitch(port: THandle; Group: byte; bAddr: word; cmd: byte;
                 dimm: byte; var mError: byte): bool; stdcall;

{ Send MADLI packet }
function mSendPkt(port: THandle; Cmd: byte; Group: byte;
                  bAddr: word; data: byte; var mError: byte): bool; stdcall;

{ Receive MADLI packet }
function mReceivePkt(port: THandle; timeout_ms: DWord; var state: byte;
                 var data: word; var mError: byte): bool; stdcall;


implementation

{ Return error message string }
function ErrorStr(i: byte): pchar;  external 'madli.dll';

{ Delay in milliseconds }
procedure Delay(ms: Dword); external 'madli.dll';

{ Open COM port. parity = 'N', 'O', 'E'. stopbits = 1 - 1, 2 - 1.5, 3 - 2 }
function OpenComPort(port: Word; baud: DWord; bits: byte; parity: char;
                     stopbits: byte; var mError: byte;
                     led_fn: TLedFunc): THandle; external 'madli.dll';

{ Close COM port }
procedure CloseComPort(port: THandle); external 'madli.dll';

{ Read RAM value from the ballast }
function GetRam(port: THandle; bAddr: word; ram: byte; var state: byte;
                var data: word; var mError: byte): bool; external 'madli.dll';

{ Read EE value from the ballast }
function GetEE(port: THandle; bAddr: word; ee: byte;
               var data: word; var mError: byte): bool; external 'madli.dll';

{ Write EE value to the ballast }
function SetEE(port: THandle; Group: byte; bAddr: word; ee: byte;
            data: byte; var mError: byte): bool; external 'madli.dll';

{ Set ballast address }
function SetBallAddr(port: THandle; bAddr: word;
                     var mError: byte): bool; external 'madli.dll';

{ Set ballast group address }
function SetBallGroup(port: THandle; bAddr: word; GrNum: byte;
                  GrAddr: byte; var mError: byte): bool; external 'madli.dll';

{ Read RAM parameters block from the ballast }
function GetRamBlock(port: THandle; bAddr: word; count: byte;
                     var state: byte; data: PWordArray; var mError: byte;
                     pr_fn: TProgrFunc): bool; external 'madli.dll';

{ Read EE parameters block from the ballast }
function GetEEBlock(port: THandle; bAddr: word; count: byte;
                    data: PByteArray; var mError: byte;
                    pr_fn: TProgrFunc): bool; external 'madli.dll';

{ Write EE parameters block to the ballast }
function SetEEBlock(port: THandle; Group: byte; bAddr: word; count: byte;
                    data: PByteArray; var mError: byte;
                    pr_fn: TProgrFunc): bool; external 'madli.dll';

{ Send Switch On; Off and Test commands }
function bSwitch(port: THandle; Group: byte; bAddr: word; cmd: byte;
                 dimm: byte; var mError: byte): bool; external 'madli.dll';

{ Send MADLI packet }
function mSendPkt(port: THandle; Cmd: byte; Group: byte;
                  bAddr: word; data: byte; var mError: byte): bool; external 'madli.dll';

{ Receive MADLI packet }
function mReceivePkt(port: THandle; timeout_ms: DWord; var state: byte;
                 var data: word; var mError: byte): bool; external 'madli.dll';

end.