{$F+,I-,O+,X+}
unit CDCtl;

interface

type
  PCDDeviceHeader = ^TCDDeviceHeader;
  TCDDeviceHeader = record
    NextDriver: Pointer;
    DeviceAttributes: Word;
    DeviceStrategyEntryPoint: Word;
    DeviceInterruptEntryPoint: Word;
    CharacterDeviceName: Array[0..7] of Char;
    Reserved: Word;
    DriveLetter: Byte;
    NumUnits: Byte;
  end;

  TCDDevice = record
    Subunit: Byte;
    Header: PCDDeviceHeader;
  end;

  TRequestHeader = record
    RequestLen: Byte;
    Subunit: Byte;
    Command: Byte;
    Status: Word;
    Reserved: Array[0..7] of Byte;
  end;

  TIOCTLRequest = record
    RequestHeader: TRequestHeader;
    MediaDescriptor: Byte;
    TransferAddress: Pointer;
    NumBytesToTransfer: Word;
    StartingSector: Word;
    PtrToRequestedVol: Pointer;
  end;

  TAudioDiskInfo = record
    LoTrack: Byte;
    HiTrack: Byte;
    LeadOutAddr: Longint;
  end;

  TAudioTrackInfo = record
    TrackNumber: Byte;
    StartingPoint: Longint;
    TrackControlInfo: Byte;
  end;

  TAudioQChannelInfo = record
    CntAdr: Byte;
    TrackNum: Byte;
    Index: Byte;
    TrackMinute: Byte;
    TrackSecond: Byte;
    TrackFrame: Byte;
    Zero: Byte;
    DiskMinute: Byte;
    DiskSecond: Byte;
    DiskFrame: Byte;
  end;

  TUPCCodeInfo = record
    CtrAdr: Byte;
    UPCCode: Array[0..6] of Char;
    Zero: Byte;
    AFrame: Byte;
  end;

  TAudioStatusInfo = record
    Status: Word;
    ResumeStart: Longint;
    ResumeEnd: Longint;
  end;

  TRedBook = record
    Frame: Byte;
    Second: Byte;
    Minute: Byte;
    Unused: Byte;
  end;

const
  cd_Max                        = 25;

  cd_ValidMSCDEXVersion         = $020A;

  cd_GetNumDrives               = $1500;
  cd_GetDriveDeviceList         = $1501;
  cd_DriveCheck                 = $150B;
  cd_GetMSCDEXVersion           = $150C;
  cd_GetDriveLetterList         = $150D;
  cd_DeviceDriverRequest        = $1510;

  cd_IOCTLI                     = $03;
  cd_IOCTLO                     = $0C;

  cd_DeviceParams               = $06;
  cd_MediaChanged               = $09;
  cd_AudioDiskInfo              = $0A;
  cd_AudioTrackInfo             = $0B;
  cd_AudioQChannelInfo          = $0C;
  cd_UPCCode                    = $0E;
  cd_AudioStatusInfo            = $0F;

  cd_EjectDisk                  = $00;
  cd_CloseTray                  = $05;
  cd_LockDoor                   = $01;
  cd_UnlockDoor                 = $01;
  cd_LockFunc                   = $01;
  cd_UnlockFunc                 = $00;
  cd_ResetDrive                 = $02;

  cd_Seek                       = $83;
  cd_PlayAudio                  = $84;
  cd_StopAudio                  = $85;
  cd_ResumeAudio                = $88;
  cd_DeviceStatus               = $06;

  cd_DoorOpen                   = $0001;
  cd_DoorUnlocked               = $0002;
  cd_DiskNotPresent             = $0800;

  cd_Paused                     = $0001;

  cd_Done                       = $0100;
  cd_Busy                       = $0200;
  cd_Error                      = $8000;

var
  CDNumDrives: Byte;
  CDDriveLetterList: Array[0..cd_Max] of Byte;
  CDDriveDeviceList: Array[0..cd_Max] of TCDDevice;

procedure CDGetNumDrives;
procedure CDGetDriveDeviceList;
function CDDriveCheck(Drive: Byte): Boolean;
function CDGetMSCDEXVersion: Word;
procedure CDGetDriveLetterList;
procedure CDDeviceDriverRequest(Drive: Byte; var Header);

function CDAccessible: Boolean;

function CDGetDeviceParams(ADrive: Byte): Word;
function CDGetMediaChanged(ADrive: Byte): Boolean;
function CDGetAudioDiskInfo(ADrive: Byte;
  var Info: TAudioDiskInfo): Boolean;
function CDGetTrackStart(ADrive, ATrack: Byte): Longint;
function CDGetAudioQChannelInfo(ADrive: Byte;
  var Info: TAudioQChannelInfo): Boolean;
function CDGetUPCCode(ADrive: Byte): String;
function CDGetAudioStatusInfo(ADrive: Byte;
  var Info: TAudioStatusInfo; var PlayingStatus: Word): Boolean;

procedure CDEjectDisk(ADrive: Byte);
procedure CDCloseTray(ADrive: Byte);
procedure CDLockDoor(ADrive: Byte);
procedure CDUnlockDoor(ADrive: Byte);
procedure CDResetDrive(ADrive: Byte);

procedure CDSeek(ADrive: Byte; ASector: Longint);
function CDPlayAudio(ADrive: Byte; ASector, ANumSectors: Longint): Boolean;
procedure CDStopAudio(ADrive: Byte);
procedure CDResumeAudio(ADrive: Byte);
function CDGetDeviceStatus(ADrive: Byte): Word;

function RedBookToHSG(RedBook: TRedBook): Longint;
procedure HSGToRedBook(HSG: Longint; var RedBook: TRedBook);

implementation

procedure CDGetNumDrives; assembler;
asm
        MOV     AX,cd_GetNumDrives
        XOR     BX,BX
        INT     2FH
        MOV     CDNumDrives,BL
end;

procedure CDGetDriveDeviceList; assembler;
asm
        MOV     AX,cd_GetDriveDeviceList
        MOV     BX,OFFSET CDDriveDeviceList
        MOV     DX,SEG CDDriveDeviceList
        MOV     ES,DX
        INT     2FH
end;

function CDDriveCheck(Drive: Byte): Boolean; assembler;
asm
        MOV     AX,cd_DriveCheck
        XOR     CH,CH
        MOV     CL,Drive
        INT     2FH
        OR      AX,AX
        JZ      @@1
        XOR     AL,AL
        CMP     BX,0ADADH
        JNE     @@1
        MOV     AL,1
@@1:
end;

function CDGetMSCDEXVersion: Word; assembler;
asm
        MOV     AX,cd_GetMSCDEXVersion
        INT     2FH
        MOV     AX,BX
end;

procedure CDGetDriveLetterList; assembler;
asm
        MOV     AX,cd_GetDriveLetterList
        MOV     BX,OFFSET CDDriveLetterList
        MOV     DX,SEG CDDriveLetterList
        MOV     ES,DX
        INT     2FH
end;

procedure CDDeviceDriverRequest(Drive: Byte; var Header); assembler;
asm
        MOV     AX,cd_DeviceDriverRequest
        XOR     CH,CH
        MOV     CL,Drive
        LES     BX,Header
        INT     2FH
end;

function CDAccessible: Boolean;
begin
  CDGetNumDrives;
  CDAccessible := (CDNumDrives <> 0) and
    (CDGetMSCDEXVersion >= cd_ValidMSCDEXVersion);
end;

procedure CDIOCTLRequest(ACommand, ADrive: Byte;
  ABuffer: Pointer; ABufSize: Word; var Status: Word);
var
  R: TIOCTLRequest;
begin
  FillChar(R, SizeOf(TIOCTLRequest), 0);
  with R, R.RequestHeader do
  begin
    RequestLen := SizeOf(TIOCTLRequest);
    Command := ACommand;
    TransferAddress := ABuffer;
    NumBytesToTransfer := ABufSize;
  end;
  CDDeviceDriverRequest(ADrive, R);
  Status := R.RequestHeader.Status;
end;

function CDGetDeviceParams(ADrive: Byte): Word;
type
  TDeviceParamsRec = record
    ControlBlockCode: Byte;
    DeviceParameters: Longint;
  end;
var
  Status: Word;
  R: TDeviceParamsRec;
begin
  R.ControlBlockCode := cd_DeviceParams;
  CDIOCTLRequest(cd_IOCTLI, ADrive, @R,
    SizeOf(TDeviceParamsRec), Status);
  CDGetDeviceParams := R.DeviceParameters;
end;

function CDGetMediaChanged(ADrive: Byte): Boolean;
type
  TMediaChangedRec = record
    ControlBlockCode: Byte;
    MediaChanged: Byte;
  end;
var
  Status: Word;
  R: TMediaChangedRec;
begin
  R.ControlBlockCode := cd_MediaChanged;
  CDIOCTLRequest(cd_IOCTLI, ADrive, @R,
    SizeOf(TMediaChangedRec), Status);
  CDGetMediaChanged := R.MediaChanged = $FF;
end;

function CDGetAudioDiskInfo(ADrive: Byte;
  var Info: TAudioDiskInfo): Boolean;
type
  TAudioDiskInfoRec = record
    ControlBlockCode: Byte;
    AudioDiskInfo: TAudioDiskInfo;
  end;
var
  Status: Word;
  R: TAudioDiskInfoRec;
begin
  R.ControlBlockCode := cd_AudioDiskInfo;
  CDIOCTLRequest(cd_IOCTLI, ADrive, @R,
    SizeOf(TAudioDiskInfoRec), Status);
  Info := R.AudioDiskInfo;
  CDGetAudioDiskInfo := Status and cd_Error = 0;
end;

function CDGetTrackStart(ADrive, ATrack: Byte): Longint;
type
  TAudioTrackInfoRec = record
    ControlBlockCode: Byte;
    AudioTrackInfo: TAudioTrackInfo;
  end;
var
  Status: Word;
  R: TAudioTrackInfoRec;
begin
  R.ControlBlockCode := cd_AudioTrackInfo;
  R.AudioTrackInfo.TrackNumber := ATrack;
  CDIOCTLRequest(cd_IOCTLI, ADrive, @R,
    SizeOf(TAudioTrackInfoRec), Status);
  CDGetTrackStart := R.AudioTrackInfo.StartingPoint;
end;

function CDGetAudioQChannelInfo(ADrive: Byte;
  var Info: TAudioQChannelInfo): Boolean;
type
  TAudioQChannelInfoRec = record
    ControlBlockCode: Byte;
    AudioQChannelInfo: TAudioQChannelInfo;
  end;
var
  Status: Word;
  R: TAudioQChannelInfoRec;
begin
  R.ControlBlockCode := cd_AudioQChannelInfo;
  CDIOCTLRequest(cd_IOCTLI, ADrive, @R,
    SizeOf(TAudioQChannelInfoRec), Status);
  Info := R.AudioQChannelInfo;
  CDGetAudioQChannelInfo := Status and cd_Error = 0;
end;

function CDGetUPCCode(ADrive: Byte): String;
type
  TUPCCodeRec = record
    ControlBlockCode: Byte;
    UPCCodeInfo: TUPCCodeInfo;
  end;
var
  Status: Word;
  R: TUPCCodeRec;
begin
  FillChar(R, SizeOf(TUPCCodeRec), 0);
  R.ControlBlockCode := cd_UPCCode;
  CDIOCTLRequest(cd_IOCTLI, ADrive, @R,
    SizeOf(TUPCCodeRec), Status);
  with R.UPCCodeInfo do
    if (Status and cd_Error <> 0) or (CtrAdr = 0) then
      CDGetUPCCode := ''
    else CDGetUPCCode := UPCCode;
end;

function CDGetAudioStatusInfo(ADrive: Byte;
  var Info: TAudioStatusInfo; var PlayingStatus: Word): Boolean;
type
  TAudioStatusInfoRec = record
    ControlBlockCode: Byte;
    AudioStatusInfo: TAudioStatusInfo;
  end;
var
  R: TAudioStatusInfoRec;
begin
  R.ControlBlockCode := cd_AudioStatusInfo;
  CDIOCTLRequest(cd_IOCTLI, ADrive, @R,
    SizeOf(TAudioStatusInfoRec), PlayingStatus);
  Info := R.AudioStatusInfo;
  CDGetAudioStatusInfo := PlayingStatus and cd_Error = 0;
end;

procedure CDEjectDisk(ADrive: Byte);
type
  TEjectDiskRec = record
    ControlBlockCode: Byte;
  end;
var
  Status: Word;
  R: TEjectDiskRec;
begin
  R.ControlBlockCode := cd_EjectDisk;
  CDIOCTLRequest(cd_IOCTLO, ADrive, @R,
    SizeOf(TEjectDiskRec), Status);
end;

procedure CDCloseTray(ADrive: Byte);
type
  TCloseTrayRec = record
    ControlBlockCode: Byte;
  end;
var
  Status: Word;
  R: TCloseTrayRec;
begin
  R.ControlBlockCode := cd_CloseTray;
  CDIOCTLRequest(cd_IOCTLO, ADrive, @R,
    SizeOf(TCloseTrayRec), Status);
end;

procedure CDLockDoor(ADrive: Byte);
type
  TLockDoorRec = record
    ControlBlockCode: Byte;
    LockFunction: Byte;
  end;
var
  Status: Word;
  R: TLockDoorRec;
begin
  R.ControlBlockCode := cd_LockDoor;
  R.LockFunction := cd_LockFunc;
  CDIOCTLRequest(cd_IOCTLO, ADrive, @R,
    SizeOf(TLockDoorRec), Status);
end;

procedure CDUnlockDoor(ADrive: Byte);
type
  TUnlockDoorRec = record
    ControlBlockCode: Byte;
    UnlockFunction: Byte;
  end;
var
  Status: Word;
  R: TUnlockDoorRec;
begin
  R.ControlBlockCode := cd_UnlockDoor;
  R.UnlockFunction := cd_UnlockFunc;
  CDIOCTLRequest(cd_IOCTLO, ADrive, @R,
    SizeOf(TUnlockDoorRec), Status);
end;

procedure CDResetDrive(ADrive: Byte);
type
  TResetDriveRec = record
    ControlBlockCode: Byte;
  end;
var
  Status: Word;
  R: TResetDriveRec;
begin
  R.ControlBlockCode := cd_ResetDrive;
  CDIOCTLRequest(cd_IOCTLO, ADrive, @R,
    SizeOf(TResetDriveRec), Status);
end;

procedure CDSeek(ADrive: Byte; ASector: Longint);
type
  TSeekRec = record
    RequestHeader: TRequestHeader;
    AddressingMode: Byte;
    TransferAddress: Longint;
    NumSectorsToRead: Word;
    StartingSector: Longint;
  end;
var
  R: TSeekRec;
begin
  FillChar(R, SizeOf(TSeekRec), 0);
  with R, R.RequestHeader do
  begin
    RequestLen := SizeOf(TSeekRec);
    Command := cd_Seek;
    StartingSector := ASector;
  end;
  CDDeviceDriverRequest(ADrive, R);
end;

function CDPlayAudio(ADrive: Byte; ASector, ANumSectors: Longint): Boolean;
type
  TPlayAudioRec = record
    RequestHeader: TRequestHeader;
    AddressingMode: Byte;
    StartingSector: Longint;
    NumSectorsToRead: Longint;
  end;
var
  R: TPlayAudioRec;
begin
  FillChar(R, SizeOf(TPlayAudioRec), 0);
  with R, R.RequestHeader do
  begin
    RequestLen := SizeOf(TPlayAudioRec);
    Command := cd_PlayAudio;
    StartingSector := ASector;
    NumSectorsToRead := ANumSectors;
  end;
  CDDeviceDriverRequest(ADrive, R);
  CDPlayAudio := R.RequestHeader.Status and cd_Error = 0;
end;

procedure CDStopAudio(ADrive: Byte);
var
  R: TRequestHeader;
begin
  FillChar(R, SizeOf(TRequestHeader), 0);
  with R do
  begin
    RequestLen := SizeOf(TRequestHeader);
    Command := cd_StopAudio;
  end;
  CDDeviceDriverRequest(ADrive, R);
end;

procedure CDResumeAudio(ADrive: Byte);
var
  R: TRequestHeader;
begin
  FillChar(R, SizeOf(TRequestHeader), 0);
  with R do
  begin
    RequestLen := SizeOf(TRequestHeader);
    Command := cd_ResumeAudio;
  end;
  CDDeviceDriverRequest(ADrive, R);
end;

function CDGetDeviceStatus(ADrive: Byte): Word;
var
  R: TRequestHeader;
begin
  FillChar(R, SizeOf(TRequestHeader), 0);
  with R do
  begin
    RequestLen := SizeOf(TRequestHeader);
    Command := cd_DeviceStatus;
  end;
  CDDeviceDriverRequest(ADrive, R);
  CDGetDeviceStatus := R.Status;
end;

function RedBookToHSG(RedBook: TRedBook): Longint;
begin
  with RedBook do
    RedBookToHSG :=
      Longint(Minute) * 4500 + Longint(Second) * 75 + Frame - 150;
end;

procedure HSGToRedBook(HSG: Longint; var RedBook: TRedBook);
begin
  Inc(HSG, 150);
  with RedBook do
  begin
    Minute := HSG div 4500;
    Second := HSG div 75 mod 60;
    Frame := HSG mod 75;
  end;
end;

end.
