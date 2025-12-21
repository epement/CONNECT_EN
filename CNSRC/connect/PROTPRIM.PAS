{$I-,F+,O+,X+}
unit ProtPrim;

interface

uses Objects, APPort;

type
  TransferModeType = (Transmit, Receive);

var
  TransferMode: TransferModeType;

procedure TransferFiles(ComPort: PortRecPtr;
  ACommand: Word; AProtocol: Byte; const Name: FNameStr);

implementation

uses Dos, Drivers, Views, App, HistList, History, MsgBox, StdDlg, StatWin,
  AsynPrim, ApMisc, ApTimer, ApUart, ApCom, ApAbsPcl, ApXmodem, ApYmodem,
  ApZmodem, ApKermit, ApAscii, APBPlus, EditMsg, LogFile, DirPrim, Swaps,
  ClipPrim, StrCol, HeapUMB, Timer, TPDate, LFN, TPString, Commands, Defaults;

const
  NextFileList: PStringsCollection = nil;
  NextFileIndex: Integer = -1;

var
  GotModem: Boolean;
  DropTime: Time;

procedure UpdateFiles;
var
  S: FNameStr;
begin
  S := CNFileName(DownloadDir);
  if S = '' then GetDir(0, S);
  while S[Length(S)] = '\' do Dec(S[0]);
  Message(Desktop, evBroadcast, cmReRead, @S);
  Message(Desktop, evBroadcast, cmUpdateTime, nil);
end;

function Long2StrBlank(L: Longint): String;
begin
  if L = 0 then Long2StrBlank := ''
  else Long2StrBlank := Long2Str(L);
end;

function FormatMinSec(TotalSecs: Longint): String;
var
  Min, Sec: Longint;
  S: String;
begin
  Min := TotalSecs div 60;
  Sec := TotalSecs mod 60;
  Str(Sec:2, S);
  if S[1] = ' ' then S[1] := '0';
  FormatMinSec := Long2Str(Min) + TimeSeparator + S;
end;

procedure WindowStatus(P: ProtocolRecPtr; Starting, Ending: Boolean);
const
  UpDownStr: Array[Boolean] of String[4] = ('Up',  'Down');
  OnOffStr:  Array[Boolean] of String[3] = ('Off', 'On'  );
const
  LastStatus: Word = 65535;
var
  B: Boolean;
  NewWidth, CurProtocol, Percent: Byte;
  CurBlock, CurBlockSize: Word;
  Blocks: Integer;
  I, CurFileSize, TotBlocks, CurBytesRemaining,
  CurBytesTransferred, CurElapsedTics: Longint;
  Eff, MaxCPS, ActualCPS, R: Real;
  S: String;
begin
  if Starting then
  begin
    if ProtOptions and poRTSLowForWrite <> 0 then
      apOptionsOn(P, apRTSLowForWrite)
    else apOptionsOff(P, apRTSLowForWrite);
    ProtInProg := True;
    CancelReq := False;
    GotModem := True;
    LastStatus := 65535;
    B := (TransferMode = Transmit) and (ReverseBar and pbUpload <> 0) or
         (TransferMode = Receive) and (ReverseBar and pbDownload <> 0);
    OpenStatusWindow('Protocol ' +
      UpDownStr[TransferMode = Receive] + 'load', B);
    LogEvent := lcCommun;
    DrawStatusLine('Protocol handshake in progress. Esc aborts.');
    if StatusWindow = nil then Exit;
    DisableAsyncErrors;

    StatusWindow^.Baud^.NewText(Long2Str(P^.PData^.PR^.CurBaud));
    StatusWindow^.DataBits^.NewText(Long2Str(P^.PData^.PR^.CurDataBits));
    B := SWFlowState(P^.PData^.PR) <> fsOff;
    StatusWindow^.SoftwareFlow^.NewText(OnOffStr[B]);
    StatusWindow^.StopBits^.NewText(
      LeftPad(Long2Str(P^.PData^.PR^.CurStopBits), 8));
    StatusWindow^.Parity^.NewText(
      LeftPad(ParityString[P^.PData^.PR^.CurParity], 8));
    B := HWFlowState(P^.PData^.PR) <> fsOff;
    StatusWindow^.HardwareFlow^.NewText(LeftPad(OnOffStr[B], 8));
  end
  else if StatusWindow = nil then Exit;

  if ProtOptions and poRequireCD <> 0 then
    if P^.PData^.PR^.ModemStatus and DCDMask <> 0 then
      DropTime := -1
    else
    begin
      if DropTime = -1 then DropTime := CurrentTime
      else if CurrentTime - DropTime > 1 then
      begin
	GotError(P^.PData^.PR, epFatal + ecNoCD);
        CancelReq := True;
      end;
    end;

  CurBlockSize := GetBlockSize(P);
  CurFileSize := GetFileSize(P);
  CurBytesRemaining := GetBytesRemaining(P);
  CurBytesTransferred := GetBytesTransferred(P);
  CurProtocol := GetProtocol(P);
  CurElapsedTics := GetElapsedTics(P);
  CurBlock := GetBlockNum(P);

  StatusWindow^.Protocol^.NewText(ProtocolTypeString[CurProtocol]);
  case GetCheckType(P) of
    bcNone      : S := bcsNone;
    bcChecksum1 : S := bcsChecksum1;
    bcChecksum2 : S := bcsChecksum2;
    bcCrc16     : S := bcsCrc16;
    bcCrc32     : S := bcsCrc32;
    bcCrcK      : S := bcsCrcK;
  end;

  if CurElapsedTics > 0 then
  begin
    R := CurBytesTransferred - GetInitialFilePos(P);
    ActualCPS := R / (CurElapsedTics / 18.2);
  end
  else ActualCPS := 0.0;
  if (ActualCPS < -MaxLongint) or (ActualCPS > MaxLongint) then
    ActualCPS := 0.0;

  StatusWindow^.BlockCheck^.NewText(S);
  StatusWindow^.FileName^.NewText(Pad(StUpcase(GetFileName(P)), 12));
  StatusWindow^.FileSize^.NewText(Long2StrBlank(CurFileSize));
  StatusWindow^.BlockSize^.NewText(Long2Str(CurBlockSize));
  if CurFileSize <> 0 then I := Succ(CurFileSize div CurBlockSize)
  else I := 0;
  StatusWindow^.TotalBlocks^.NewText(Long2StrBlank(I));

  if ActualCPS >= 1 then I := Trunc(
    (CurFileSize - GetInitialFilePos(P)) / ActualCPS)
  else I := 0;
  if I > 0 then StatusWindow^.EstimatedTime^.NewText(FormatMinSec(I))
  else StatusWindow^.EstimatedTime^.NewText('');

  StatusWindow^.ElapsedTime^.NewText(
    FormatMinSec(Tics2Secs(CurElapsedTics)));

  if ActualCPS >= 1 then I := Trunc(CurBytesRemaining / ActualCPS)
  else I := 0;
  if I > 0 then StatusWindow^.RemainingTime^.NewText(FormatMinSec(I))
  else StatusWindow^.RemainingTime^.NewText('');

  StatusWindow^.BytesTransferred^.NewText(LeftPad(Long2Str(CurBytesTransferred), 8));
  StatusWindow^.BytesRemaining^.NewText(LeftPad(Long2StrBlank(CurBytesRemaining), 8));
  StatusWindow^.BlocksTransferred^.NewText(
    LeftPad(Long2Str(CurBlock), 8));
  Blocks := (CurBytesRemaining + Pred(CurBlockSize)) div CurBlockSize;
  StatusWindow^.BlocksRemaining^.NewText(
    LeftPad(Long2StrBlank(Blocks), 8));
  StatusWindow^.BlockErrors^.NewText(
    LeftPad(Long2Str(GetBlockErrors(P)), 8));
  StatusWindow^.TotalErrors^.NewText(
    LeftPad(Long2Str(GetTotalErrors(P)), 8));

  if CurBytesTransferred = 0 then
  begin
    Message(StatusWindow, evBroadcast, cmResetBar, nil);
    Message(StatusWindow, evBroadcast, cmBarVolume, Pointer(CurFileSize));
  end
  else with StatusWindow^.Bar^ do
  begin
    if Volume = 0 then NewWidth := Size.X
    else
    begin
      R := Size.X / (Volume / CurBytesTransferred);
      if (R < -MaxLongint) or (R > MaxLongint) then NewWidth := Size.X
      else NewWidth := Trunc(R);
    end;
    if NewWidth > Size.X then NewWidth := Size.X;
    if NewWidth <> Width then
    begin
      Width := NewWidth;
      DrawView;
    end;
  end;

  if CurFileSize = 0 then Percent := 0
  else
  begin
    R := (CurBytesTransferred / CurFileSize) * 100;
    Percent := Trunc(R);
    if Percent > 100 then Percent := 100;
  end;
  StatusWindow^.Percent^.NewText(LeftPad(Long2Str(Percent), 3) + '%');

  if LastStatus <> AsyncStatus then
  begin
    S := AsyncStatusString(AsyncStatus);
    StatusWindow^.Status^.NewText(S);
    LastStatus := AsyncStatus;
  end;

  StatusWindow^.Throughput^.NewText(
    LeftPad(Long2Str(Trunc(ActualCPS)) + ' CPS', 8));
  MaxCPS := P^.PData^.PR^.CurBaud div 10;
  if MaxCPS > 0 then Eff := (ActualCPS / MaxCPS) * 100.0
  else Eff := 0.0;
  StatusWindow^.Efficiency^.NewText(Real2Str(Eff, 7, 0) + '%');

  if Ending then
  begin
    EnableAsyncErrors;
    StatusWindow^.Deiconize;
    StatusWindow^.Show;
    StatusWindow^.Select;
    if (AsyncStatus = ecOk) or (AsyncStatus mod 10000 = ecEndFile) then
    begin
      PlayEndingSignal;
      InitTimer(50, evCommand, cmOk, True);
      MessageBox(^C'File transfer complete.',
        nil, mfInformation + mfOkButton);
    end
    else AsyncErrorProc(nil, AsyncStatus);
    Message(StatusWindow, evBroadcast, cmCloseBar, nil);
    StatusWindow := nil;
    if TransferMode = Receive then UpdateFiles;
    ProtInProg := False;
  end;
end;

procedure LogFileProc(P: ProtocolRecPtr; LogFileStatus: LogFileType);
var
  CurBytesTransferred, CurElapsedTics, InitPos: Longint;
  ActualCPS, R: Real;
  ProtStr, TransferStr, NameStr, ByteStr, CPSStr: String[15];
  S: String;
begin
  if EnableLog and loEnable = 0 then Exit;

  ProtStr := ProtocolTypeString[GetProtocol(P)];
  if TransferMode = Transmit then TransferStr := 'Uploading'
  else TransferStr := 'Downloading';
  NameStr := GetFileName(P);
  TrimSt(NameStr);

  CurBytesTransferred := GetBytesTransferred(P);
  CurElapsedTics := GetElapsedTics(P);
  InitPos := GetInitialFilePos(P);
  if CurElapsedTics > 0 then
  begin
    R := CurBytesTransferred - InitPos;
    ActualCPS := R / (CurElapsedTics / 18.2);
  end
  else
  begin
    R := 0.0;
    ActualCPS := 0.0;
  end;

  if (R < -MaxLongint) or (R > MaxLongint) then R := MaxLongint;
  if (ActualCPS < -MaxLongint) or (ActualCPS > MaxLongint) then
    ActualCPS := MaxLongint;
  ByteStr := Long2Str(Trunc(R));
  CPSStr := Long2Str(Trunc(ActualCPS));

  S := ProtStr + ' ' + TransferStr + ' ' + NameStr + ': ';
  case LogFileStatus of
    lfReceiveStart, lfTransmitStart: S := S + 'starting.';
    lfReceiveOk, lfTransmitOk, lfReceiveFail, lfTransmitFail:
      begin
        if LogFileStatus in [lfReceiveOk, lfTransmitOk] then
          S := S + 'complete'
        else S := S + 'failed';
        S := S + ' (' + ByteStr + ' bytes from offset ' +
          Long2Str(InitPos) + ', ' + CPSStr + ' CPS).';
      end;
    lfReceiveSkip, lfTransmitSkip: S := S + 'skipped.';
    else Exit;
  end;
  LogEvent := lcCommun;
  WriteToLog(S);
  LogEvent := lcOther;
end;

procedure InitNextFileList;
var
  I: Integer;
  S: String;
begin
  NextFileList := New(PStringsCollection, Init(32, 32));
  NextFileIndex := 0;
  if (DiskClipStream <> nil) and ClipAreaSelected then
  begin
    Message(Desktop, evBroadcast, cmUpdateViews, nil);
    for I := ClipArea^.KB to ClipArea^.KK do
    begin
      GetClipLine(I, S);
      TrimSt(S);
      UpcaseSt(S);
{      if S <> '' then NextFileList^.Insert(NewStr(S));}
      if S <> '' then NextFileList^.Insert(NewStrUMB(S));
    end;
  end;
end;

procedure DoneNextFileList;
begin
  if NextFileList <> nil then
  begin
    Dispose(NextFileList, Done);
    NextFileList := nil;
  end;
  NextFileIndex := -1;
end;

function NextFileFunc(P: ProtocolRecPtr; var FName: PathStr): Boolean;
var
  PS: PString;
begin
  SetAsyncStatus(ecOk);
  PS := NextFileList^.At(NextFileIndex);
  if PS = nil then
  begin
    if NextFileList^.Count = 0 then
      GotError(P^.PData^.PR, epFatal + ecNoMatchingFiles);
    NextFileFunc := False;
  end
  else
  begin
    FName := PS^;
    Inc(NextFileIndex);
    NextFileFunc := True;
  end;
end;

procedure SetNextFileFunction(P: ProtocolRecPtr; const S: PathStr);
begin
  if S <> '' then SetFileMask(P, S)
  else
  begin
    InitNextFileList;
    SetNextFileFunc(P, NextFileFunc);
  end;
end;

function GetReceivedName(var FName: FNameStr): Boolean;
var
  SaveAPI: lAPIType;
begin
  SaveAPI := lAPI;
  lAPI := lDOS;
  GetReceivedName := Application^.ExecuteDialog(
    New(PFileDialog, Init('*.*', 'New file name',
      '~N~ame', fdOkButton + fdHelpButton,
      HistoryID)), @FName, True) <> cmCancel;
  lAPI := SaveAPI;
end;

function AcceptFileFunc(P: ProtocolRecPtr): Boolean;
var
  YMTime: Longint;
  SR: SearchRec;
begin
  FindFirst(P^.PData^.Pathname, AnyFile and not (Directory + VolumeID), SR);
  if DosError = 0 then
  begin
    AcceptFileFunc := False;
    if ZmodemOverwrite = zoNever then Exit;
    YMTime := PackToYMTimeStamp(SR.Time);
    if (YMTime = P^.PData^.SrcFileDate) and
       (SR.Size = P^.PData^.SrcFileLen) then Exit;
    if (ZmodemOverwrite = zoAlways) or
       ((YMTime = P^.PData^.SrcFileDate) and
        (SR.Size < P^.PData^.SrcFileLen)) then
    begin
      AcceptFileFunc := True;
      Exit;
    end;
    if GetReceivedName(P^.PData^.Pathname) then AcceptFileFunc := True;
  end
  else AcceptFileFunc := True;
end;

procedure BackgroundProc(P: ProtocolRecPtr); far;
var
  Event: TEvent;
begin
  NestedEventCount := 0;
  Application^.GetEvent(Event);
  Application^.HandleEvent(Event);
end;

procedure TransferFiles(ComPort: PortRecPtr;
  ACommand: Word; AProtocol: Byte; const Name: FNameStr);
var
  SaveAPI: lAPIType;
  ET: EventTimer;
  Start: Boolean;
  Upload: Boolean;
  C: Char;
  Command: Word;
  Overwrite: WriteFailOptions;
  PP: ProtocolRecPtr;
  SrcFileName: FNameStr;
begin
  if (ComPort = nil) or ProtInProg then Exit;
  SrcFileName := HistoryStr(HistoryID, 0);
  if ACommand = cmUpload then
  begin
    if Name <> '' then SrcFileName := Name
    else if AProtocol = BPlus then SrcFileName := ''
    else
    begin
      SaveAPI := lAPI;
      lAPI := lDOS;
      Command := Application^.ExecuteDialog(
        New(PFileDialog, Init('*.*', 'Upload file(s)',
          '~N~ame', fdOkButton + fdMaskButton + fdSelButton + fdHelpButton,
          HistoryID)), @SrcFileName, False);
      lAPI := SaveAPI;
      if Command = cmCancel then Exit;
      if Command = cmSelectedFiles then SrcFileName := '';
    end;
  end
  else if AProtocol in
    [Ascii, Xmodem, XmodemCRC, Xmodem1K, Xmodem1KG] then
  begin
    if Name <> '' then SrcFileName := Name
    else if not GetReceivedName(SrcFileName) then Exit;
  end
  else SrcFileName := '';

  if ACommand = cmUpload then TransferMode := Transmit
  else TransferMode := Receive;
  if ZModemOverwrite = zoAlways then Overwrite := WriteAnyway
  else Overwrite := WriteFail;
  GotModem := False;
  DropTime := -1;

  case AProtocol of
    Ascii:
      begin
        InitAscii(PP, ComPort);
        if AsyncStatus = ecOk then
        begin
          SetShowStatusProc(PP, WindowStatus);
          SetLogFileProc(PP, LogFileProc);
          SetBackgroundProc(PP, BackgroundProc);
          SetOverwriteOption(PP, Overwrite);
          case TransferMode of
            Transmit:
              begin
                SetDelays(PP, ASCIICharDelay, ASCIILineDelay);
                SetNextFileFunction(PP, SrcFileName);
                ProtocolTransmitAS(PP);
              end;
            Receive:
              begin
                SetReceiveFileName(PP, SrcFileName);
                ProtocolReceiveAS(PP);
              end;
          end;
          DoneAscii(PP);
        end;
      end;

    Xmodem, XmodemCRC, Xmodem1K, Xmodem1KG:
      begin
        InitXmodem(PP, ComPort,
          (AProtocol = Xmodem1K), AProtocol = Xmodem1KG);
        if AsyncStatus = ecOk then
        begin
          SetShowStatusProc(PP, WindowStatus);
          SetLogFileProc(PP, LogFileProc);
          SetBackgroundProc(PP, BackgroundProc);
          SetBlockWait(PP, RelaxedBlockWait);
          SetHandshakeWait(PP, Secs2Tics(10), 5);
          SetOverwriteOption(PP, Overwrite);
          case TransferMode of
            Transmit:
              begin
                SetNextFileFunction(PP, SrcFileName);
                ProtocolTransmitXM(PP);
              end;
            Receive:
              begin
                SetReceiveFileName(PP, SrcFileName);
                ProtocolReceiveXM(PP);
              end;
          end;
          DoneXmodem(PP);
        end;
      end;

    Ymodem, YmodemG:
      begin
        InitYmodem(PP, ComPort, True, (AProtocol = YmodemG));
        if AsyncStatus = ecOk then
        begin
          SetShowStatusProc(PP, WindowStatus);
          SetLogFileProc(PP, LogFileProc);
          SetBackgroundProc(PP, BackgroundProc);
          SetBlockWait(PP, RelaxedBlockWait);
          SetHandshakeWait(PP, Secs2Tics(10), 5);
          SetOverwriteOption(PP, Overwrite);
          case TransferMode of
            Transmit:
              begin
                SetNextFileFunction(PP, SrcFileName);
                ProtocolTransmitYM(PP);
              end;
            Receive:
              begin
                SetDestinationDirectory(PP, CNFileName(DownloadDir));
                ProtocolReceiveYM(PP);
              end;
          end;
          DoneYmodem(PP);
        end;
      end;

    Zmodem:
      begin
        InitZmodem(PP, ComPort);
        if AsyncStatus = ecOk then
        begin
          SetShowStatusProc(PP, WindowStatus);
          SetLogFileProc(PP, LogFileProc);
          SetBackgroundProc(PP, BackgroundProc);
          SetHandshakeWait(PP, Secs2Tics(10), 5);
          SetFileMgmtOptions(PP, True, False, WriteClobber);
          SetRecoverOption(PP, ZmodemOptions and zmResume <> 0);
          SetAcceptFileFunc(PP, AcceptFileFunc);

          case TransferMode of
            Transmit:
              begin
                SetNextFileFunction(PP, SrcFileName);
                ProtocolTransmitZM(PP);
              end;
            Receive:
              begin
                SetDestinationDirectory(PP, CNFileName(DownloadDir));
                ProtocolReceiveZM(PP);
              end;
          end;
          DoneZmodem(PP);
        end;
      end;

    Kermit:
      begin
        InitKermit(PP, ComPort);
        if AsyncStatus = ecOk then
        begin
          SetShowStatusProc(PP, WindowStatus);
          SetLogFileProc(PP, LogFileProc);
          SetBackgroundProc(PP, BackgroundProc);
          SetOverwriteOption(PP, Overwrite);
          SetMaxLongPacketLen(PP, 1024);
          SetMaxWindows(PP, 15);
          case TransferMode of
            Transmit:
              begin
                SetNextFileFunction(PP, SrcFileName);
                ProtocolTransmitKM(PP);
              end;
            Receive:
              begin
                SetDestinationDirectory(PP, CNFileName(DownloadDir));
                ProtocolReceiveKM(PP);
              end;
          end;
          DoneKermit(PP);
        end;
      end;

    BPlus:
      begin
        LogEvent := lcCommun;
        DrawStatusLine('Starting BPlus protocol handshake.');
        InitBPlus(PP, ComPort);
        if AsyncStatus = ecOk then
        begin
          SetShowStatusProc(PP, WindowStatus);
          SetLogFileProc(PP, LogFileProc);
          SetBackgroundProc(PP, BackgroundProc);
          SetOverwriteOption(PP, Overwrite);
          NewTimerSecs(ET, 10);
          Start := False;
          ProcessENQ(PP);
          repeat
            if CharReady(ComPort) then
            begin
              GetChar(ComPort, C);
              if C = cDLE then ProcessDLE(PP, Start, Upload);
            end;
          until Start or KbdAbort or TimerExpired(ET);
          if Start then
            if Upload then ProtocolTransmitBP(PP)
            else ProtocolReceiveBP(PP);
          DoneBPlus(PP);
        end;
      end;
  end;

  DoneNextFileList;
  if not GotModem then AsyncErrorProc(nil, AsyncStatus);
end;

end.
