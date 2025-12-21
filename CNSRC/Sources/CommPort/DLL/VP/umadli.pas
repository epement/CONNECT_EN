Unit UMadli;
{$IFDEF Open32}
  {&cdecl+}
{$ELSE}
  {&StdCall+}
{$ENDIF Open32}
{&AlignRec+,SmartLink+,OrgName+,X+,Z+,Delphi+,Use32-}

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
function ErrorStr(i: byte): pchar;

{ Delay in milliseconds }
procedure Delay(ms: Dword);

{ Open COM port. parity = 'N', 'O', 'E'. stopbits = 1 - 1, 2 - 1.5, 3 - 2 }
function OpenComPort(port: Word; baud: DWord; bits: byte; parity: char;
                     stopbits: byte; var mError: byte;
                     led_fn: TLedFunc): THandle;

{ Close COM port }
procedure CloseComPort(port: THandle);

{ Read RAM value from the ballast }
function GetRam(port: THandle; bAddr: word; ram: byte; var state: byte;
                var data: word; var mError: byte): bool;

{ Read EE value from the ballast }
function GetEE(port: THandle; bAddr: word; ee: byte;
               var data: word; var mError: byte): bool;

{ Write EE value to the ballast }
function SetEE(port: THandle; Group: byte; bAddr: word; ee: byte;
            data: byte; var mError: byte): bool;

{ Set ballast address }
function SetBallAddr(port: THandle; bAddr: word;
                     var mError: byte): bool;

{ Set ballast group address }
function SetBallGroup(port: THandle; bAddr: word; GrNum: byte;
                  GrAddr: byte; var mError: byte): bool;

{ Read RAM parameters block from the ballast }
function GetRamBlock(port: THandle; bAddr: word; count: byte;
                     var state: byte; data: PWordArray; var mError: byte;
                     pr_fn: TProgrFunc): bool;

{ Read EE parameters block from the ballast }
function GetEEBlock(port: THandle; bAddr: word; count: byte;
                    data: PByteArray; var mError: byte;
                    pr_fn: TProgrFunc): bool;

{ Write EE parameters block to the ballast }
function SetEEBlock(port: THandle; Group: byte; bAddr: word; count: byte;
                    data: PByteArray; var mError: byte;
                    pr_fn: TProgrFunc): bool;

{ Send Switch On; Off and Test commands }
function bSwitch(port: THandle; Group: byte; bAddr: word; cmd: byte;
                 dimm: byte; var mError: byte): bool;

{ Send MADLI packet }
function mSendPkt(port: THandle; Cmd: byte; Group: byte;
                  bAddr: word; data: byte; var mError: byte): bool;

{ Receive MADLI packet }
function mReceivePkt(port: THandle; timeout_ms: DWord; var state: byte;
                 var data: word; var mError: byte): bool;


implementation

{$L MADLI.LIB}

{ Return error message string }
function ErrorStr(i: byte): pchar;  external;

{ Delay in milliseconds }
procedure Delay(ms: Dword); external;

{ Open COM port. parity = 'N', 'O', 'E'. stopbits = 1 - 1, 2 - 1.5, 3 - 2 }
function OpenComPort(port: Word; baud: DWord; bits: byte; parity: char;
                     stopbits: byte; var mError: byte;
                     led_fn: TLedFunc): THandle; external;

{ Close COM port }
procedure CloseComPort(port: THandle); external;

{ Read RAM value from the ballast }
function GetRam(port: THandle; bAddr: word; ram: byte; var state: byte;
                var data: word; var mError: byte): bool; external;

{ Read EE value from the ballast }
function GetEE(port: THandle; bAddr: word; ee: byte;
               var data: word; var mError: byte): bool; external;

{ Write EE value to the ballast }
function SetEE(port: THandle; Group: byte; bAddr: word; ee: byte;
            data: byte; var mError: byte): bool; external;

{ Set ballast address }
function SetBallAddr(port: THandle; bAddr: word;
                     var mError: byte): bool; external;

{ Set ballast group address }
function SetBallGroup(port: THandle; bAddr: word; GrNum: byte;
                  GrAddr: byte; var mError: byte): bool; external;

{ Read RAM parameters block from the ballast }
function GetRamBlock(port: THandle; bAddr: word; count: byte;
                     var state: byte; data: PWordArray; var mError: byte;
                     pr_fn: TProgrFunc): bool; external;

{ Read EE parameters block from the ballast }
function GetEEBlock(port: THandle; bAddr: word; count: byte;
                    data: PByteArray; var mError: byte;
                    pr_fn: TProgrFunc): bool; external;

{ Write EE parameters block to the ballast }
function SetEEBlock(port: THandle; Group: byte; bAddr: word; count: byte;
                    data: PByteArray; var mError: byte;
                    pr_fn: TProgrFunc): bool; external;

{ Send Switch On; Off and Test commands }
function bSwitch(port: THandle; Group: byte; bAddr: word; cmd: byte;
                 dimm: byte; var mError: byte): bool; external;

{ Send MADLI packet }
function mSendPkt(port: THandle; Cmd: byte; Group: byte;
                  bAddr: word; data: byte; var mError: byte): bool; external;

{ Receive MADLI packet }
function mReceivePkt(port: THandle; timeout_ms: DWord; var state: byte;
                 var data: word; var mError: byte): bool; external;

end.