{$I-,F+,O+,X+}
unit Terminal;

interface

uses Objects, Drivers, Views, FEditor, HEditor, EditFile, OutWin, StatWin,
  APPort, APUART, StrCol, Gauges, TPDate;

const
  IncomingSeqLen = 31;
  AutoDownloadMask: String[6] = '**B00';

  BackLineLen = 80;

type
  PCDClock = ^TCDClock;
  TCDClock = object(TClockView)
    InitTime: Time;
    PrevTime: Time;
    DropTime: Time;
    procedure UpdateTime;
  end;

  PTerminal = ^TTerminal;
  TTerminal = object(TOutput)
    BackLine: String[BackLineLen];
    ComPort: PortRecPtr;
    CurUART: UARTType;
    GraphChars: String[112];
    GraphMode: Byte;
    InXLATTable: ConvertTable;
    OutXLATTable: ConvertTable;
    CDClock: PCDClock;
    DialList: PStringsCollection;
    DialIndex: Integer;
    DialTime: Time;
    PrevDialTime: Time;
    DialPtr: PString;
    IncomingSeq: String[IncomingSeqLen];
    MacroList: PCollection;
    TermcapInUse: Boolean;
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function GetHelpCtx: Word; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure InitComPort;
    procedure DoneComPort;
    procedure InitXLAT;
    procedure InitTermcap;
    procedure DoneTermcap;
    procedure InitCDClock;
    procedure DoneCDClock;
    procedure CheckCDClock(LastStatus, NewStatus: Byte);
    procedure InitModem;
    procedure CheckDialList(GotThrough: Boolean);
    procedure AbortDialing(Cancel: Boolean);
    procedure CheckRS(var Event: TEvent);
    function GetRSChar(var C: Char): Boolean;
    function PutRSChar(C: Char): Boolean;
    procedure TMDelay(TickCount: Word);
    procedure SendString(const S: String);
    function SendCommandString(const S: String): Boolean;
    procedure EscSendPos; virtual;
    function CheckTermcap(AChar: Char): Boolean;
    procedure GetChar(AChar: Char); virtual;
    function GetWidth: Integer; virtual;
    function GetHeight: Integer; virtual;
    procedure Paste;
    procedure OptionsDialog; virtual;
    function ProtocolDialog: Word;
    procedure TransferFiles(ACommand: Word; AProtocol: Byte);
    procedure ManualDial;
    procedure Hangup;
    procedure Answer;
    procedure DownloadPath;
    procedure ModemSetup;
    procedure SetupDialog;
    procedure PopUp(AnOrigin: TPoint);
    procedure UpdateBackLine(AChar: Char);
    procedure UpdateHexBackLine(AChar: Char);
    procedure InitMacroList;
    procedure DoneMacroList;
    function PreprocessEnabled(var Event: TEvent): Boolean;
  end;

  PTerminalWindow = ^TTerminalWindow;
  TTerminalWindow = object(TOutputWindow)
    constructor Init;
    constructor Load(var S: TStream);
    procedure Close; virtual;
    function GetPalette: PPalette; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PBack = ^TBack;
  TBack = object(TFileEditor)
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PBackWindow = ^TBackWindow;
  TBackWindow = object(TEditorWindow)
    constructor Init(Bounds: TRect; var FileName: String);
    constructor Load(var S: TStream);
    procedure Close; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
  end;

  PHexBack = ^THexBack;
  THexBack = object(THexEditor)
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PHexBackWindow = ^THexBackWindow;
  THexBackWindow = object(THexEditorWindow)
    constructor Init(Bounds: TRect; var FileName: String);
    constructor Load(var S: TStream);
    procedure Close; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
  end;

const
  CTerminalColor      = #$07#$0F#$0A#$31#$31;
  CTerminalBlackWhite = #$07#$0F#$07#$70#$70;
  CTerminalMonochrome = #$07#$0F#$07#$70#$70;
  CTerminalWindow     = #160#161#162#163#164;

  sfPasting = $1000;
  sfDialing = $2000;
  sfNoCheck = $4000;
  sfDoorway = $8000;

  ofCalling  = $0800;
  ofDialList = $8000;

var
  CDClockOrigin: TPoint;

procedure RSRTerminalWindow(RSR: PResourceFile);
procedure OpenTerminal;
procedure PrepareBack;
procedure OpenBack;

implementation

uses CNCrt, Dos, Memory, WinIcons, Menus, Dialogs, App, MsgBox, StdDlg,
  Popups, CNInputs, Spooler, EditMsg, AsynPrim, APCom, APAbsPcl, ProtPrim,
  Compiler, HistList, History, TermComp, Keyboard, Swaps, ClipPrim, LogFile,
  DialDlg, Timer, WinPos, CNWinPos, DevLayer, CNMacros, MacroDlg, DirPrim,
  DosTools, TPString, Consts, Commands, Defaults;

const
  GraphCharTable =
{gt       Äþ³ÀÁÙÃÅ´ÚÂ¿}
    #$C4#$FE#$B3#$C0#$C1#$D9#$C3#$C5#$B4#$DA#$C2#$BF#$19#$18#$1B#$1A +
{g1       Ä³ÀÁÙÃÅ´ÚÂ¿}
    #$C4#$B3#$C0#$C1#$D9#$C3#$C5#$B4#$DA#$C2#$BF#$20#$20#$20#$20#$20 +
{g2       ÍºÈÊ¼ÌÎ¹ÉË»}
    #$CD#$BA#$C8#$CA#$BC#$CC#$CE#$B9#$C9#$CB#$BB#$20#$20#$20#$20#$20 +
{g3       Í³ÔÏ¾ÆØµÕÑ¸}
    #$CD#$B3#$D4#$CF#$BE#$C6#$D8#$B5#$D5#$D1#$B8#$20#$20#$20#$20#$20 +
{g4       ÄºÓÐ½Ç×¶ÖÒ·}
    #$C4#$BA#$D3#$D0#$BD#$C7#$D7#$B6#$D6#$D2#$B7#$20#$20#$20#$20#$20 +
{g5        }
    #$1A#$1B#$18#$19#$1D#$17#$10#$11#$1E#$1F#$20#$20#$20#$20#$20#$20 +
{g6       ßÜÝÞÛ°}
    #$DF#$DC#$DD#$DE#$DB#$B0#$20#$20#$20#$20#$20#$20#$20#$20#$20#$20;

procedure TCDClock.UpdateTime;
var
  H, M, S, SC: Byte;
  T: Time;
begin
  T := CurrentTime;
  if PrevTime = T then Exit;
  PrevTime := T;
  if T < InitTime then Inc(T, SecondsInDay);
  TimeDiff(T, InitTime, H, M, S);
  SC := CountryTime;
  CountryTime := cs24Hour;
  TimeStr := FormatTimeStr(H, M, S);
  CountryTime := SC;
  DrawView;
end;

function CannotCloseTerminal: Boolean;
var
  S: String[15];
begin
  if ProtInProg then
  begin
    ProtInProgMsgBox('close Terminal window');
    CannotCloseTerminal := True;
  end
  else
  begin
    if PView(TheTerminal)^.State and sfPasting <> 0 then S := 'pasting text'
    else if PView(TheTerminal)^.State and sfDialing <> 0 then S := 'dialing'
    else S := '';
    CannotCloseTerminal := (S <> '') and
      (ConfirmOptions and coCloseTerminal <> 0) and
      (TerminalStatusMsgBox(S) <> cmOk);
  end;
end;

constructor TTerminal.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
  State := State or sfCursorVis;
  GrowMode := gfGrowHiX + gfGrowHiY;
  OutputCollection := New(POutputCollection, Init(MaxOutputLines, 1));
  DialList := New(PStringsCollection, Init(8, 8));
  DialTime := -1;
  CurColor := $07;
  HiY := MaxOutputLines;
end;

constructor TTerminal.Load(var S: TStream);
begin
  TScroller.Load(S);
  OutputCollection := POutputCollection(S.Get);
  S.Read(CurColor,
    SizeOf(CurColor) + SizeOf(SaveDelta) + SizeOf(SaveCursor) +
    SizeOf(ReservedStr) + SizeOf(ReservedFlag) +
    SizeOf(LoY) + SizeOf(HiY) + SizeOf(BackLine));
  if (State and sfDialing <> 0) or
     (Options and ofDialList <> 0) then
  begin
    DialList := PStringsCollection(S.Get);
    S.Read(DialIndex, SizeOf(Integer));
    DialPtr := DialList^.At(DialIndex);
  end
  else DialList := New(PStringsCollection, Init(8, 8));
  if State and sfDefault <> 0 then
  begin
    S.Read(DialTime, SizeOf(Time) * 2);
    State := State and not sfDefault;
  end
  else DialTime := -1;
  InitMacroList;
  LastModemStatus := 0;
end;

destructor TTerminal.Done;
begin
  DoneMacroList;
  DoneCDClock;
  DoneTermcap;
  DoneComPort;
  if DialList <> nil then Dispose(DialList, Done);
  if OutputCollection <> nil then Dispose(OutputCollection, Done);
  TScroller.Done;
  TheTerminal := nil;
end;

function TTerminal.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else if State and sfDialing <> 0 then GetHelpCtx := hcDialing
  else GetHelpCtx := hcTerminal;
end;

procedure TTerminal.HandleEvent(var Event: TEvent);
var
  C: Char;
  W: Word;
  I: Integer;
  Spot: TPoint;
  S: String;
label
  HandleKey;
begin
  if (Event.What = evKeyDown) and (MacroList <> nil) and
    PreprocessEnabled(Event) then
      PreprocessKeyEvent(MacroList, Event);
  if Event.What = evKeyDown then
    if (Event.KeyCode = kbCtrlHome) or (Event.KeyCode = kbCtrlEnd) or
       (Event.KeyCode = kbCtrlPgUp) or (Event.KeyCode = kbCtrlPgDn) or
       (Event.CharCode in WordStarChars) then
      if PreprocessEnabled(Event) then ConvertWSKey(WordStarKeys and not
	(wsA + wsD + wsE + wsF + wsR + wsS + wsW + wsX + wsZ), Event);
  if Event.What = evKeyDown then
    if ((Event.CharCode in [#27, #32]) or
        (Event.KeyCode = kbGrayPlus) or (Event.KeyCode = kbGrayMinus)) and
       (State and sfDialing <> 0) and (DialList <> nil) then
    begin
      if Event.CharCode = #27 then AbortDialing(True)
      else if Event.CharCode = #32 then
      begin
        if GetShiftState and kbCtrlShift <> 0 then
        begin
          DialIndex := DialList^.IndexOf(DialPtr) - 1;
          if DialIndex < 0 then DialIndex := DialList^.Count - 1;
          DialPtr := DialList^.At(DialIndex);
        end;
        DialTime := -1;
        SendCommandString(ModemCancelStr);
      end
      else if (Event.KeyCode = kbGrayPlus) and
        (DialTime < CurrentTime) then Inc(DialTime)
      else if (Event.KeyCode = kbGrayMinus) and
        (DialTime > 0) then Dec(DialTime);
      Event.What := evNothing;
    end
    else if (State and (sfPasting + sfDialing) <> 0) or
      ProtInProg then Goto HandleKey
    else
    begin
      if State and sfDoorway <> 0 then
      begin
        S[0] := #1;
        S[1] := Event.CharCode;
        if Event.CharCode = #0 then
        begin
          Inc(S[0]);
          S[2] := Char(Event.ScanCode);
        end;
      end
      else if TermColl <> nil then S := KeyCodeStr(Event.KeyCode)
      else
      begin
        C := #0;
        case Event.KeyCode of
          kbUp: C := 'A';
          kbDown: C := 'B';
          kbRight: C := 'C';
          kbLeft: C := 'D';
          kbHome: C := 'H';
          kbDel: Event.CharCode := #127;
        end;
        if C = #0 then S := '' else S := #27'[' + C;
      end;
      if S <> '' then
      begin
        SendString(S);
        Event.What := evNothing;
        Exit;
      end;
      if Event.CharCode <> #0 then
      begin
        PutRSChar(Event.CharCode);
        Event.What := evNothing;
      end
      else
      begin
HandleKey:
        W := 0;
        case Event.KeyCode of
          kbPgUp: W := cmUpload;
          kbPgDn: W := cmDownload;
          kbAltF3: W := cmClose;
          kbAltF10: W := cmPopup;
          kbAltA: W := cmDial;
          kbAltB: W := cmBack;
          kbAltG: W := cmFlushBuffers;
          kbAltH: W := cmHangup;
          kbAltI: W := cmDialer;
          kbAltJ: W := cmAnswer;
          kbAltX: W := cmQuit;
          kbAltV: W := cmSerialBreak;
          kbCtrlDel: W := cmFileClear;
        end;
        if W <> 0 then
        begin
          Event.What := evCommand;
          Event.Command := W;
        end;
      end;
    end;
  TScroller.HandleEvent(Event);
  if (Event.What = evMouseDown) and (Event.Buttons = mbRightButton) and
    MouseInView(Event.Where) then
  begin
    repeat until not MouseEvent(Event, evMouseDown);
    PopUp(Event.Where);
    Event.What := evNothing;
  end
  else if Event.What = evCommand then
  begin
    case Event.Command of
      cmProtocol: ProtocolDialog;
      cmUpload, cmDownload: TransferFiles(Event.Command, ModemProtocol);
      cmDial: ManualDial;
      cmFlushBuffers:
        begin
          DoneComPort;
          InitComPort;
        end;
      cmHangup: Hangup;
      cmAnswer: Answer;
      cmSerialBreak: if ComPort <> nil then SendBreak(ComPort);
      cmDownloadPath: DownloadPath;
      cmModemSetup: ModemSetup;
      cmTransferSetup: SetupDialog;
      cmCopy: ClipCopy;
      cmPaste: Paste;
      cmExecOptions: OptionsDialog;
      cmFileClear:
        begin
          CurColor := $07;
          Clear;
        end;
      cmPopup:
        begin
          Spot.X := Size.X div 2;
          Spot.Y := 0;
          MakeGlobal(Spot, Spot);
          PopUp(Spot);
        end;
      else Exit;
    end;
    Event.What := evNothing;
  end
  else if Event.What = evBroadcast then
    case Event.Command of
      cmTerminal:
        begin
          PWindow(Owner)^.Deiconize;
          Owner^.Show;
          Owner^.Select;
          ClearEvent(Event);
        end;
      cmDial, cmDialQueue:
        if (Event.InfoPtr <> nil) and (DialList <> nil) then
        begin
          if (Event.Command = cmDial) and
             (State and sfDialing <> 0) then AbortDialing(True);
          S := PString(Event.InfoPtr)^;
          if Event.Command = cmDial then I := 0
          else I := DialList^.Count;
          if AddDialStr(I, S) then
          begin
            if DialPtr = nil then DialPtr := DialList^.At(I);
            if Event.Command = cmDial then
              Options := Options or ofCalling;
            State := State or sfDialing;
          end;
          ClearEvent(Event);
        end;
      cmUserMacros: if (MacroList <> nil) and
        (CompUCString(PString(Event.InfoPtr)^,
          CNFileName(TermMacroName)) = Equal) then InitMacroList;
      cmGetMacroName: if (Owner^.State and sfActive <> 0) and
        (Owner^.State and sfSelected <> 0) and (MacroList <> nil) then
        begin
          Event.What := evNothing;
          Event.InfoPtr := @TermMacroName;
        end;
    end;
end;

procedure TTerminal.SetState(AState: Word; Enable: Boolean);
begin
  TScroller.SetState(AState, Enable);
  if (AState = sfFocused) and Enable then
    EnableCommands(CopyCommands + PasteCommands + MTCommands)
  else if not Enable and
    (((AState and (sfActive + sfSelected) <> 0) and GetState(sfExposed)) or
    (AState = sfExposed)) then DisableCommands(
      CopyCommands + PasteCommands + MTCommands);
end;

procedure TTerminal.Store(var S: TStream);
var
  ClockOn: Boolean;
  SaveState: Word;
begin
  ClockOn := (CDClock <> nil) and (CDClock^.State and sfVisible <> 0);
  SaveState := State;
  State := State and not sfPasting;
  if ClockOn then State := State or sfDefault;
  if DialList^.Count <> 0 then Options := Options or ofDialList
  else Options := Options and not ofDialList;
  TScroller.Store(S);
  State := SaveState;
  S.Put(OutputCollection);
  S.Write(CurColor,
    SizeOf(CurColor) + SizeOf(SaveDelta) + SizeOf(SaveCursor) +
    SizeOf(ReservedStr) + SizeOf(ReservedFlag) +
    SizeOf(LoY) + SizeOf(HiY) + SizeOf(BackLine));
  if (State and sfDialing <> 0) or (Options and ofDialList <> 0) then
  begin
    S.Put(DialList);
    DialIndex := DialList^.IndexOf(DialPtr);
    S.Write(DialIndex, SizeOf(Integer));
  end;
  if ClockOn then S.Write(CDClock^.InitTime, SizeOf(Time) * 2);
end;

procedure TTerminal.InitComPort;
begin
  InitPortPrim(ComPort, ComName, Baud, Parity, DataBits, StopBits,
    InBufSize, OutBufSize, PortOptions);
  if (ComPort <> nil) and (DeviceLayer = dlUART) then
    CurUART := ClassifyUart(ComPort^.BaseAddr, False)
  else CurUART := NoUART;
end;

procedure TTerminal.DoneComPort;
begin
  DonePortPrim(ComPort);
end;

procedure TTerminal.InitXLAT;
var
  C: Boolean;
begin
  ReadConvertTable(InXLATTable, InputXLATName, C);
  ReadConvertTable(OutXLATTable, OutputXLATName, C);
end;

procedure TTerminal.InitTermcap;
var
  Name: FNameStr;
begin
  LoY := 0;
  HiY := MaxOutputLines;
  TerminalOptions := (TerminalOptions or ooDestructiveBS) and not
    (toInsMode + ooAutoWrap);
  FillChar(GraphChars[1], SizeOf(GraphChars), 0);
  GraphChars[0] := #112;
  DoneTermColl;
  TermcapInUse := False;
  if (TermcapName = '') or (TermcapIden = '') then Exit;
  InitTermColl;
  SetCNConfigName(Name, 'TRM');
  ReadTermcap(Name, 'STANDARD');
  TermcapInUse := ReadTermcap(TermcapName, TermcapIden);
  if TermColl^.Count = 0 then DoneTermColl;
end;

procedure TTerminal.DoneTermcap;
begin
  DoneTermColl;
end;

procedure TTerminal.InitCDClock;
var
  R: TRect;
begin
  if ValidGaugeOrigin(CDClockOrigin) then
    R.Assign(CDClockOrigin.X, CDClockOrigin.Y,
      CDClockOrigin.X + 9, CDClockOrigin.Y + 1)
  else
  begin
    Application^.GetExtent(R);
    R.A.X := R.B.X - 9; R.A.Y := R.B.Y - 1;
  end;
  CDClock := New(PCDClock, Init(R));
  CDClock^.GrowMode := gfGrowLoY + gfGrowHiY;
  CDClock^.DropTime := -1;
  CDClock^.Hide;
  Application^.Insert(CDClock);
end;

procedure TTerminal.DoneCDClock;
begin
  if CDClock <> nil then
  begin
    if CDClock^.Exposed then
    begin
      CDClock^.DropTime := -MaxInt;
      CheckCDClock(LastModemStatus, 0);
    end;
    CDClockOrigin := CDClock^.Origin;
    Dispose(CDClock, Done);
  end;
end;

procedure TTerminal.CheckCDClock(LastStatus, NewStatus: Byte);
begin
  if ((LastStatus and DCDMask) = (NewStatus and DCDMask)) and
     (CDClock^.DropTime = -1) then Exit;
  if NewStatus and DCDMask <> 0 then
  begin
    if CDClock^.DropTime <> -1 then
    begin
      CDClock^.DropTime := -1;
      Exit;
    end;
    CDClock^.InitTime := CurrentTime;
    CDClock^.TimeStr := '00:00:00';
    CDClock^.Show;
  end
  else
  begin
    if CDClock^.DropTime = -1 then
    begin
      CDClock^.DropTime := CurrentTime;
      Exit;
    end;
    if CurrentTime - CDClock^.DropTime <= 1 then Exit;
    CDClock^.DropTime := -1;
    CDClock^.Hide;
    if EnableLog and loEnable <> 0 then
    begin
      LogEvent := lcCommun;
      WriteToLog('CD was active for ' + CDClock^.TimeStr + '.');
      LogEvent := lcOther;
    end;
  end;
end;

procedure TTerminal.InitModem;
begin
  if ComPort^.ModemStatus and DCDMask <> 0 then Exit;
  LogEvent := lcCommun;
  DrawStatusLine('Initializing modem.');
  SendCommandString(ModemInitStr);
end;

procedure TTerminal.CheckDialList(GotThrough: Boolean);
var
  I: Integer;
  DelaySec: Word;
  Code: Integer;
  T: Time;
  S: String;
begin
  DialIndex := DialList^.IndexOf(DialPtr);
  if (DialList^.Count = 0) or (DialIndex = -1) then AbortDialing(True)
  else if GotThrough or (ComPort^.ModemStatus and DCDMask <> 0) then
  begin
    if DialTime <> -1 then S := ^C + GetDialStr + ' answered.'
    else S := ^C + 'Carrier detected.';
    AbortDialing(False);
    if not ProgRunning then
    begin
      PlayEndingSignal;
      InitTimer(50, evCommand, cmOk, False);
      MessageBox(S, nil, mfInformation + mfOkButton);
    end;
  end
  else
  begin
    if DialTime <> -1 then
    begin
      Val(RedialDelay, DelaySec, Code);
      Dec(DelaySec);
      T := CurrentTime;
      if T < DialTime then Inc(T, SecondsInDay);
      if T - DialTime <= DelaySec then
      begin
        if T <> PrevDialTime then
        begin
          PrevDialTime := T;
          StatusLine^.DrawView;
        end;
        Exit;
      end;
      SendCommandString(ModemCancelStr);
      LogEvent := lcCommun;
      DrawStatusLine('Getting ready for the next phone dial attempt.');
      TMDelay(18);
    end;
    if Options and ofCalling = 0 then
    begin
      Inc(DialIndex);
      if DialIndex >= DialList^.Count then DialIndex := 0;
      DialPtr := DialList^.At(DialIndex);
    end;
    S := DialPtr^;
    DialTime := -1;
    LogEvent := lcCommun;
    DrawStatusLine('Dialing ' + S + '.');
    I := 1;
    while I <= Length(S) do
      if (S[I] = ';') and (I > 1) and (S[I - 1] <> '\') then
        S[0] := Char(I - 1)
      else Inc(I);      
    if (S <> '') and (S[1] = '>') then
      System.Delete(S, 1, 1)
    else S := DialPrefix + S + DialSuffix;
    if not SendCommandString(S) then AbortDialing(True)
    else DialTime := CurrentTime;
  end;
  Message(Application, evBroadcast, cmUpdateViews, nil);
end;

procedure TTerminal.AbortDialing(Cancel: Boolean);
var
  I: Integer;
begin
  if Cancel then SendCommandString(ModemCancelStr);
  if (Options and ofCalling <> 0) and (DialList <> nil) then
  begin
    I := DialList^.IndexOf(DialPtr);
    if I <> -1 then DialList^.AtFree(I);
  end;
  Options := Options and not ofCalling;
  State := State and not sfDialing;
  DialPtr := nil;
  DialIndex := -1;
  DialTime := -1;
  IncomingSeq := '';
end;

procedure TTerminal.CheckRS(var Event: TEvent);
var
  F: Boolean;
  B: Byte;
  C: Char;
begin
  if not TerminalDisabled then
  begin
    F := (Event.What = evKeyDown) and (Event.CharCode = #0);
    repeat
      if not GetRSChar(C) then Break;
      GetChar(C);
    until F or (KbdHead <> KbdTail);
  end;
  if ComPort <> nil then
  begin
    B := ((ComPort^.ModemStatus) and $FC) or
         ((ComPort^.ModemControl) and $3);
    if CDClock <> nil then CheckCDClock(LastModemStatus, B);
    if LastModemStatus <> B then
    begin
      LastModemStatus := B;
      PWindow(Owner)^.Frame^.DrawView;
      if PWindow(Owner)^.Icon <> nil then
        PWinIcon(PWindow(Owner)^.Icon)^.Update;
    end;
    if (B and DCDMask <> 0) and (CDClock <> nil) then CDClock^.UpdateTime;
    if (State and sfDialing <> 0) and (State and sfPasting = 0) and
       (DialList <> nil) and not ProtInProg then CheckDialList(False);
  end;
  if GetShiftState and kbScrollState <> 0 then State := State or sfDoorway
  else State := State and not sfDoorway;
end;

function TTerminal.GetRSChar(var C: Char): Boolean;
begin
  if ComPort = nil then GetRSChar := False
  else GetRSChar := GetCharPrim(ComPort, C);
end;

function TTerminal.PutRSChar(C: Char): Boolean;
var
  B: Boolean;
begin
  if ComPort = nil then
  begin
    PutRSChar := False;
    Exit;
  end;
  if State and sfDoorway = 0 then C := OutXLATTable[C];
  if TerminalOptions and toStripHighBit <> 0 then Byte(C) := Byte(C) and $7F;
  B := PutCharPrim(ComPort, C);
  PutRSChar := B;
  if B and (TerminalOptions and toLocalEcho <> 0) then GetChar(C);
end;

procedure TTerminal.TMDelay(TickCount: Word);
var
  SaveState: Word;
  E: TEvent;
begin
  E.What := evNothing;
  E.InfoWord := MemW[$40:$6C];
  SaveState := State;
  State := State and not sfDialing;
  repeat
    CheckRS(E);
  until (MemW[$40:$6C] - TickCount > E.InfoWord) or KeyPressed;
  State := SaveState;
end;

procedure TTerminal.SendString(const S: String);
var
  B: Byte;
begin
  for B := 1 to Length(S) do if not PutRSChar(S[B]) then Exit;
end;

function TTerminal.SendCommandString(const S: String): Boolean;
var
  I: Integer;
  SaveOpt: Word;
label
  Quit;
begin
  SendCommandString := False;
  if ComPort = nil then Exit;
  SaveOpt := TerminalOptions;
  TerminalOptions := TerminalOptions and not toLocalEcho;
  I := 1;
  while I <= Length(S) do
  begin
    case S[I] of
      '~': TMDelay(9);
      '^': SetDTR(ComPort, True);
      'v': SetDTR(ComPort, False);
      '|': if not PutRSChar(#13) then Goto Quit;
      '\':
        begin
          Inc(I);
          if I <= Length(S) then PutRSChar(S[I]);
        end;
      else if not PutRSChar(S[I]) then Goto Quit;
    end;
    Inc(I);
  end;
  SendCommandString := True;
Quit:
  TerminalOptions := SaveOpt;
end;

procedure TTerminal.EscSendPos;
var
  Params: Array[0..1] of Longint;
  S: String;
begin
  if EscSeq = '[6n' then
  begin
    EscSeq := '';
    Params[0] := Delta.Y + Cursor.Y + 1;
    Params[1] := Delta.X + Cursor.X + 1;
    FormatStr(S, #27'[%d:%dR', Params);
    SendString(S);
  end;
end;

function TTerminal.CheckTermcap(AChar: Char): Boolean;
var
  B: TTermResult;
  Len: Byte absolute EscSeq;
  C: Word;
  I: Integer;
  A: TArg;
begin
  CheckTermcap := False;
  if (Len = 0) and (AChar >= ' ') and (AChar <> '~') then Exit;
  Inc(Len);
  EscSeq[Len] := AChar;
  if Len > MaxEscLen then B := trUnknown
  else if (Word((@EscSeq)^) = $1B01) or
    ((Len = 2) and (EscSeq[1] = #27) and (EscSeq[2] = '[')) or
    ((Len > 2) and (EscSeq[1] = #27) and (EscSeq[2] = '[') and
     (EscSeq[Len] in ['0'..'9', ';', '?'])) then B := trIncomplete
  else B := InputControl(EscSeq, C, A, I);
  if B = trComplete then DoCmd(C, A, I)
  else if B = trUnknown then
  begin
    State := State or sfNoCheck;
    for I := 1 to Len - 1 do GetChar(EscSeq[I]);
    State := State and not sfNoCheck;
    EscSeq := '';
  end;
  CheckTermcap := B <> trUnknown;
end;

procedure TTerminal.GetChar(AChar: Char);
var
  I: Integer;
  P: ^TDrawBuffer;

function IncomingSeqContains(const ModemStr: String): Boolean;
var
  Beyond: Boolean;
  B: Byte;
  S: String;
begin
  IncomingSeqContains := False;
  S := '';
  B := 1;
  repeat
    Beyond := B > Length(ModemStr);
    if Beyond or (ModemStr[B] in [';', ',']) then
    begin
      if Pos(S, IncomingSeq) <> 0 then
      begin
        IncomingSeqContains := True;
        Exit;
      end;
      if Beyond then Exit;
      S := '';
    end
    else
    begin
      Inc(S[0]);
      if ModemStr[B] = '|' then S[Length(S)] := #13
      else S[Length(S)] := TPString.Upcase(ModemStr[B]);
    end;
    Inc(B);
  until False;
end;

procedure CheckModemResponce;
begin
  if Length(IncomingSeq) = IncomingSeqLen then
    System.Delete(IncomingSeq, 1, 1);
  Inc(IncomingSeq[0]);
  IncomingSeq[Length(IncomingSeq)] := TPString.Upcase(AChar);
  if IncomingSeqContains(ModemConnectStr) then I := 2
  else if IncomingSeqContains(ModemBusyStr) then I := 1
  else if IncomingSeqContains(ModemRingStr) or
    (LastModemStatus and DeltaRIMask <> 0) then I := 0
  else I := -1;
  if I >= 0 then
  begin
    IncomingSeq := '';
    DrawView;
    if I = 2 then CheckDialList(True)
    else if I = 1 then Message(@Self, evKeyDown, kbSpace, nil)
    else
    begin
      ComPort^.ModemStatus := ComPort^.ModemStatus and not DeltaRIMask;
      LastModemStatus := LastModemStatus and not DeltaRIMask;
      SendCommandString(ModemBreakStr);
    end;
  end;
end;

begin
  with OutputCollection^ do
  begin
    if Count = 0 then Clear;
    UpdateLimit;
    if Self.Delta.X + Cursor.X >= Self.Limit.X then
      SetCursor(Self.Limit.X - Self.Delta.X - 1, Cursor.Y);
    if Cursor.X < 0 then
      ScrollTo(Self.Delta.X + Cursor.X, Self.Delta.Y)
    else if Cursor.X >= Size.X then
      ScrollTo(Self.Delta.X + Cursor.X - Size.X + 1, Self.Delta.Y);
    if (Cursor.Y < 0) or (Cursor.Y >= Size.Y) then
      ScrollTo(Self.Delta.X, Self.Delta.Y + Cursor.Y - Size.Y div 2);
    if TerminalOptions and
      (toUseBack + toHexBack) = toUseBack + toHexBack then
        UpdateHexBackLine(AChar);
    if State and sfNoCheck = 0 then
      if TermColl <> nil then
        if CheckTermcap(AChar) then Exit else
      else if CheckEsc(AChar) then Exit;
    AChar := InXLATTable[AChar];
    if GraphMode <> 0 then
    begin
      I := Pos(AChar, GraphChars);
      if I <> 0 then AChar := PString(GetStrAddr(GraphCharTable))^[I];
    end;
    if TerminalOptions and (toUseBack + toHexBack) = toUseBack then
      UpdateBackLine(AChar);
    P := At(Self.Delta.Y + Cursor.Y);
    if P = nil then Exit;
    case AChar of
      #7:
        begin
          if not DisableSounds then Write(^G);
          Exit;
        end;
      #8: if Self.Delta.X + Cursor.X > 0 then
        begin
          SetCursor(Cursor.X - 1, Cursor.Y);
          if Cursor.X < 0 then
            ScrollTo(Self.Delta.X - 1, Self.Delta.Y);
          if TerminalOptions and ooDestructiveBS <> 0 then
            WordRec(P^[Self.Delta.X + Cursor.X]).Lo := 0;
        end;
      #9:
        begin
          I := 9 - ((Self.Delta.X + Cursor.X + 1) mod 8);
          if I = 9 then I := 1;
          SetCursor(Cursor.X + I, Cursor.Y);
          if Cursor.X >= Size.X then
            ScrollTo(Self.Delta.X + Cursor.X - Size.X + 1, Self.Delta.Y);
          if Cursor.X >= Size.X then SetCursor(Size.X - 1, Cursor.Y);
        end;
      #10:
        begin
          if TerminalOptions and ooAddReturn <> 0 then
          begin
            ScrollTo(0, Self.Delta.Y);
            SetCursor(0, Cursor.Y);
          end;
          Enter;
          if State and sfDialing <> 0 then CheckModemResponce;
        end;
      #12:
        begin
          Clear;
          Exit;
        end;
      #13:
        begin
          ScrollTo(0, Self.Delta.Y);
          SetCursor(0, Cursor.Y);
          if TerminalOptions and ooAddLineFeed <> 0 then Enter;
          if State and sfDialing <> 0 then CheckModemResponce;
        end;
      else
      begin
        if CurColor = 0 then AChar := ' ';
        if (TerminalOptions and toInsMode <> 0) and
           (Self.Delta.X + Cursor.X < GetWidth - 1) then Move(
          P^[Self.Delta.X + Cursor.X], P^[Self.Delta.X + Cursor.X + 1],
          (GetWidth - Self.Delta.X - Cursor.X - 1) * 2);
        WordRec(P^[Self.Delta.X + Cursor.X]).Lo := Byte(AChar);
        WordRec(P^[Self.Delta.X + Cursor.X]).Hi := CurColor;
        SetCursor(Cursor.X + 1, Cursor.Y);
        if Cursor.X >= Size.X then
          if Self.Limit.X = Size.X then DrawView
          else ScrollTo(Self.Delta.X + 1, Self.Delta.Y);
        if Self.Delta.X + Cursor.X >= Self.Limit.X then
          if TerminalOptions and ooAutoWrap <> 0 then
          begin
            Enter;
            ScrollTo(0, Self.Delta.Y);
            SetCursor(0, Cursor.Y);
          end
          else SetCursor(Cursor.X - 1, Cursor.Y);

        if State and sfDialing <> 0 then CheckModemResponce
        else if (ZmodemOptions and zmAutoDownload <> 0) and
          NoModalWindows then
        begin
          if (IncomingSeq = '') and (AChar = AutoDownloadMask[1]) then
            IncomingSeq := AutoDownloadMask[1]
          else if IncomingSeq <> '' then
          begin
            if AChar = AutoDownloadMask[Length(IncomingSeq) + 1] then
              IncomingSeq := IncomingSeq + AChar
            else IncomingSeq := '';
            if IncomingSeq = AutoDownloadMask then
            begin
              IncomingSeq := '';
              DrawView;
              TransferFiles(cmDownload, Zmodem);
              Exit;
            end;
          end;
        end;
      end;
    end;
  end;
  DrawFlag := True;
  DrawView;
  DrawFlag := False;
end;

function TTerminal.GetWidth: Integer;
begin
  GetWidth := TerminalWidth;
end;

function TTerminal.GetHeight: Integer;
begin
  GetHeight := TerminalHeight;
end;

procedure TTerminal.TransferFiles(ACommand: Word; AProtocol: Byte);
begin
  if State and (sfPasting + sfDialing) = 0 then
  begin
    if ProtocolPrompt and (ProtocolDialog = cmCancel) then Exit;
    ProtPrim.TransferFiles(ComPort, ACommand, AProtocol, '');
    if ProtOptions and poHangupAfter <> 0 then Hangup;
  end;
end;

procedure TTerminal.ManualDial;
var
  S: String;
begin
  S := EnterDialStr;
  if S <> '' then Message(@Self, evBroadcast, cmDial, @S);
end;

procedure TTerminal.Hangup;
begin
  if ComPort <> nil then
  begin
    LogEvent := lcCommun;
    DrawStatusLine('Sending Hangup modem string.');
    DoneComPort;
    InitComPort;
    SendCommandString(ModemHangupStr);
  end;
end;

procedure TTerminal.Answer;
begin
  if ComPort <> nil then
  begin
    LogEvent := lcCommun;
    DrawStatusLine('Sending Answer modem string.');
    SendCommandString(ModemAnswerStr);
  end;
end;

function ProtocolDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 27, 19);
  D := New(PDialog, Init(R, 'Protocol'));
  with D^ do
  begin
    HelpCtx := hcProtocol;
    Options := Options or ofCentered;

    R.Assign(3, 3, 24, 13);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~X~modem',
      NewSItem('Xmodem~C~RC',
      NewSItem('Xmodem~1~K',
      NewSItem('Xmodem1K~G~',
      NewSItem('~Y~modem',
      NewSItem('Y~m~odemG',
      NewSItem('~Z~modem',
      NewSItem('~K~ermit',
      NewSItem('~A~SCII',
      NewSItem('~B~Plus', nil))))))))))));
    Insert(Control);
    R.Assign(2, 2, 24, 3);
    Insert(New(PLabel, Init(R, 'Transfer protocol', Control)));

    R.Assign(3, 14, 24, 15);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~P~rompt on start', nil)));
    Insert(Control);

    R.Assign(2, Size.Y - 3, 12, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  ProtocolDialog := PDialog(Application^.ValidView(D));
end;

function TTerminal.ProtocolDialog: Word;
type
  TData = record
    Kind: Word;
    Prompt: Word;
  end;
var
  C: Word;
  D: PDialog;
  Data: TData;
begin
  C := cmCancel;
  D := PDialog(Resource^.Get('PROTOCOLDIALOG'));
  if D = nil then ResourceNotFoundMsgBox('Protocol dialog')
  else
  begin
    Data.Kind := ModemProtocol;
    Data.Prompt := Byte(ProtocolPrompt);
    C := Application^.ExecuteDialog(D, @Data, False);
    if C <> cmCancel then
    begin
      ModemProtocol := Data.Kind;
      ProtocolPrompt := Data.Prompt and 1 <> 0;
    end;
  end;
  ProtocolDialog := C;
end;

procedure TTerminal.DownloadPath;
var
  D: PDialog;
  Control: PInputLine;
  R: TRect;
begin
  R.Assign(0, 0, 60, 7);
  D := New(PDialog, Init(R, 'Download directory'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcDownloadPath;
    R.Assign(17, 2, Size.X - 6, 3);
    Control := New(PDInputLine, Init(R, 67));
    Insert(Control);
    StandardHistory(Control, DirHistoryId);
    R.Assign(2, 2, 17, 3);
    Insert(New(PLabel, Init(R, '~D~ownload path', Control)));
    R.Assign(16, Size.Y - 3, 26, Size.Y - 1);
    StandardOkButton(R, D);
    Inc(R.A.X, 31); Inc(R.B.X, 31);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  if Application^.ExecuteDialog(D, @DownloadDir, False) <> cmCancel then
  begin
    DownloadDir := StUpcase(Trim(DownloadDir));
    if DownloadDir <> '' then
    begin
      while DownloadDir[Length(DownloadDir)] = '\' do Dec(DownloadDir[0]);
      DownloadDir := DownloadDir + '\';
    end;
  end;
end;

function ModemSetupDialog: PDialog;
var
  D: PDialog;
  Control: PInputLine;
  R: TRect;
begin
  R.Assign(0, 0, 54, 18);
  D := New(PDialog, Init(R, 'Modem setup'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcModemSetup;

    R.Assign(18, 2, Size.X - 6, 3);
    Control := New(PInputLine, Init(R, ModemInitLen));
    Insert(Control);
    StandardHistory(Control, ModemSetupHistoryID);
    R.Assign(2, 2, 18, 3);
    Insert(New(PLabel, Init(R, '~I~nit string', Control)));

    R.Assign(18, 3, Size.X - 6, 4);
    Control := New(PInputLine, Init(R, ModemHangupLen));
    Insert(Control);
    StandardHistory(Control, ModemSetupHistoryID);
    R.Assign(2, 3, 18, 4);
    Insert(New(PLabel, Init(R, '~H~angup string', Control)));

    R.Assign(18, 4, Size.X - 6, 5);
    Control := New(PInputLine, Init(R, ModemAnswerLen));
    Insert(Control);
    StandardHistory(Control, ModemSetupHistoryID);
    R.Assign(2, 4, 18, 5);
    Insert(New(PLabel, Init(R, '~A~nswer string', Control)));

    R.Assign(18, 5, Size.X - 6, 6);
    Control := New(PInputLine, Init(R, ModemCancelLen));
    Insert(Control);
    StandardHistory(Control, ModemSetupHistoryID);
    R.Assign(2, 5, 18, 6);
    Insert(New(PLabel, Init(R, '~C~ancel string', Control)));

    R.Assign(18, 6, Size.X - 6, 7);
    Control := New(PInputLine, Init(R, ModemConnectLen));
    Insert(Control);
    StandardHistory(Control, ModemSetupHistoryID);
    R.Assign(2, 6, 18, 7);
    Insert(New(PLabel, Init(R, 'C~o~nnect string', Control)));

    R.Assign(18, 7, Size.X - 6, 8);
    Control := New(PInputLine, Init(R, ModemBusyLen));
    Insert(Control);
    StandardHistory(Control, ModemSetupHistoryID);
    R.Assign(2, 7, 18, 8);
    Insert(New(PLabel, Init(R, '~B~usy string', Control)));

    R.Assign(18, 8, Size.X - 6, 9);
    Control := New(PInputLine, Init(R, ModemRingLen));
    Insert(Control);
    StandardHistory(Control, ModemSetupHistoryID);
    R.Assign(2, 8, 18, 9);
    Insert(New(PLabel, Init(R, '~R~ing string', Control)));

    R.Assign(18, 9, Size.X - 6, 10);
    Control := New(PInputLine, Init(R, ModemBreakLen));
    Insert(Control);
    StandardHistory(Control, ModemSetupHistoryID);
    R.Assign(2, 9, 18, 10);
    Insert(New(PLabel, Init(R, 'Br~e~ak string', Control)));

    R.Assign(18, 10, Size.X - 6, 11);
    Control := New(PInputLine, Init(R, PrefLen));
    Insert(Control);
    StandardHistory(Control, ModemSetupHistoryID);
    R.Assign(2, 10, 18, 11);
    Insert(New(PLabel, Init(R, 'Dial ~p~refix', Control)));

    R.Assign(18, 11, Size.X - 6, 12);
    Control := New(PInputLine, Init(R, SuffLen));
    Insert(Control);
    StandardHistory(Control, ModemSetupHistoryID);
    R.Assign(2, 11, 18, 12);
    Insert(New(PLabel, Init(R, 'Dial ~s~uffix', Control)));

    R.Assign(Size.X - 10, 13, Size.X - 3, 14);
    Control := New(PCInputLine, Init(R, RedialDelayLen, 0, 65535));
    Insert(Control);
    R.Assign(2, 13, Size.X - 10, 14);
    Insert(New(PLabel, Init(R, 'Redial ~d~elay, sec', Control)));

    StandardButtonRow(D, True);
  end;
  ModemSetupDialog := PDialog(Application^.ValidView(D));
end;

procedure TTerminal.ModemSetup;
var
  D: PDialog;
begin
  D := PDialog(Resource^.Get('MODEMSETUPDIALOG'));
  if D = nil then ResourceNotFoundMsgBox('Modem setup dialog')
  else Application^.ExecuteDialog(D, @ModemInitStr, False);
end;

function SetupDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 40, 23);
  D := New(PDialog, Init(R, 'Transfer setup'));
  with D^ do
  begin
    HelpCtx := hcTransferSetup;
    Options := Options or ofCentered;

    R.Assign(3, 2, Size.X - 3, 5);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~C~D required for transfer',
      NewSItem('~L~ower RTS during disk writes',
      NewSItem('Han~g~up after transfer', nil)))));
    Insert(Control);
    R.Assign(2, 1, Size.X - 3, 2);
    Insert(New(PLabel, Init(R, 'General protocol options', Control)));

    R.Assign(3, 6, Size.X - 3, 8);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~A~uto download',
      NewSItem('~R~esume interrupted transfer', nil))));
    Insert(Control);
    R.Assign(2, 5, Size.X - 3, 6);
    Insert(New(PLabel, Init(R, 'Zmodem options', Control)));

    R.Assign(3, 9, Size.X - 3, 12);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~A~lways',
      NewSItem('~N~ever',
      NewSItem('~P~rompt (Zmodem only)', nil)))));
    Insert(Control);
    R.Assign(2, 8, Size.X - 3, 9);
    Insert(New(PLabel, Init(R, 'Overwrite existing files', Control)));

    R.Assign(3, 13, Size.X - 3, 15);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~U~pload',
      NewSItem('~D~ownload', nil))));
    Insert(Control);
    R.Assign(2, 12, Size.X - 3, 13);
    Insert(New(PLabel, Init(R, 'Reverse progress bar', Control)));

    R.Assign(27, 17, 34, 18);
    Control := New(PCInputLine, Init(R, 5, 0, 65535));
    Insert(Control);
    R.Assign(2, 17, 27, 18);
    Insert(New(PLabel, Init(R, 'Delay between c~h~ars, ms', Control)));
    R.Assign(2, 16, Size.X - 3, 17);
    Insert(New(PLabel, Init(R, 'Paste and ASCII protocol delays', Control)));

    R.Assign(27, 18, 34, 19);
    Control := New(PCInputLine, Init(R, 5, 0, 65535));
    Insert(Control);
    R.Assign(2, 18, 27, 19);
    Insert(New(PLabel, Init(R, 'Delay between l~i~nes, ms', Control)));

    StandardButtonRow(D, True);
  end;
  SetupDialog := PDialog(Application^.ValidView(D));
end;

procedure TTerminal.SetupDialog;
type
  TData = record
    PO: Word;
    ZM: Word;
    ZO: Word;
    RB: Word;
    CH: String[5];
    LN: String[5];
  end;
var
  Code: Integer;
  D: PDialog;
  Data: TData;
begin
  D := PDialog(Resource^.Get('TRANSFERSETUPDIALOG'));
  if D = nil then
  begin
    ResourceNotFoundMsgBox('Transfer setup dialog');
    Exit;
  end;
  Data.PO := ProtOptions;
  Data.ZM := ZmodemOptions;
  Data.ZO := ZmodemOverwrite;
  Data.RB := ReverseBar;
  if ASCIICharDelay = 0 then Data.CH := ''
  else Str(ASCIICharDelay, Data.CH);
  if ASCIILineDelay = 0 then Data.LN := ''
  else Str(ASCIILineDelay, Data.LN);
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    ProtOptions := Data.PO;
    ZmodemOptions := Data.ZM;
    ZmodemOverwrite := Data.ZO;
    ReverseBar := Data.RB;
    Val(Data.CH, ASCIICharDelay, Code);
    Val(Data.LN, ASCIILineDelay, Code);
  end;
end;

function TerminalOptionsDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 63, 21);
  D := New(PDialog, Init(R, 'Terminal options'));
  with D^ do
  begin
    HelpCtx := hcTerminalOptions;
    Options := Options or ofCentered;

    R.Assign(3, 3, 30, 10);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Add ~L~ine Feed',
      NewSItem('Add ~R~eturn',
      NewSItem('Auto ~w~rap',
      NewSItem('Destructive ~B~ackspace',
      NewSItem('Local ~e~cho',
      NewSItem('Strip ~h~igh bit',
      NewSItem('Store lines in B~a~ck', nil)))))))));
    Insert(Control);
    R.Assign(2, 2, 30, 3);
    Insert(New(PLabel, Init(R, 'Terminal options', Control)));

    R.Assign(32, 3, 60, 7);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Restore ~U~ART on close',
      NewSItem('~D~rop modem on exit',
      NewSItem('Raise modem on o~p~en',
      NewSItem('I~g~nore transfer errors',
      nil))))));
    Insert(Control);
    R.Assign(31, 2, 60, 3);
    Insert(New(PLabel, Init(R, 'Port options', Control)));

    R.Assign(40, 9, 45, 10);
    Control := New(PCInputLine, Init(R, 3, 1, MaxViewWidth));
    Insert(Control);
    R.Assign(31, 9, 40, 10);
    Insert(New(PLabel, Init(R, '~C~olumns', Control)));

    R.Assign(56, 9, 60, 10);
    Control := New(PCInputLine, Init(R, 2, 1, MaxOutputLines));
    Insert(Control);
    R.Assign(50, 9, 56, 10);
    Insert(New(PLabel, Init(R, 'Row~s~', Control)));

    R.Assign(17, Size.Y - 10, Size.X - 6, Size.Y - 9);
    Control := New(PFInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, TermcapNameHistoryId);
    R.Assign(2, Size.Y - 10, 17, Size.Y - 9);
    Insert(New(PLabel, Init(R, 'Termcap ~n~ame', Control)));

    R.Assign(17, Size.Y - 9, Size.X - 6, Size.Y - 8);
    Control := New(PInputLine, Init(R, 127));
    Insert(Control);
    StandardHistory(Control, TermcapIdenHistoryId);
    R.Assign(2, Size.Y - 9, 17, Size.Y - 8);
    Insert(New(PLabel, Init(R, '~T~erminal type', Control)));

    R.Assign(17, Size.Y - 8, Size.X - 6, Size.Y - 7);
    Control := New(PFInputLine, Init(R, 79));
    Insert(Control);
    StandardHistory(Control, XLATNameHistoryId);
    R.Assign(2, Size.Y - 8, 17, Size.Y - 7);
    Insert(New(PLabel, Init(R, '~I~n XLAT file', Control)));

    R.Assign(17, Size.Y - 7, Size.X - 6, Size.Y - 6);
    Control := New(PFInputLine, Init(R, 79));
    Insert(Control);
    StandardHistory(Control, XLATNameHistoryId);
    R.Assign(2, Size.Y - 7, 17, Size.Y - 6);
    Insert(New(PLabel, Init(R, '~O~ut XLAT file', Control)));

    R.Assign(17, Size.Y - 5, Size.X - 17, Size.Y - 4);
    Control := New(PFInputLine, Init(R, 79));
    Insert(Control);
    StandardHistory(Control, MacroNameHistoryID);
    R.Assign(2, Size.Y - 5, 17, Size.Y - 4);
    Insert(New(PLabel, Init(R, '~M~acro file', Control)));

    R.Assign(Size.X - 14, Size.Y - 5, Size.X - 3, Size.Y - 3);
    Insert(New(PButton, Init(R, 'Open~.~..', cmUserMacros, bfNormal)));

    StandardButtonRow(D, True);
  end;
  TerminalOptionsDialog := PDialog(Application^.ValidView(D));
end;

procedure TMMacroProc(V: PView; var Event: TEvent);

function IsMacroInput(P: PView): Boolean; far;
begin
  IsMacroInput := (TypeOf(P^) = TypeOf(TFInputLine)) and
    (P^.Origin.Y = 16);
end;

var
  P: PFInputLine;
  S: FNameStr;
begin
  if (Event.What = evCommand) and (Event.Command = cmUserMacros) then
  begin
    Event.What := evNothing;
    P := PFInputLine(PDialog(V)^.FirstThat(@IsMacroInput));
    if (P <> nil) and (P^.Data^ <> '') then
    begin
      S := CNFileName(P^.Data^);
      Event.InfoPtr := @S;
    end
    else Event.InfoPtr := nil;
    UserMacros(Event.InfoPtr);
  end
  else if (Event.What = evBroadcast) and
    (Event.Command = cmGetMacroName) then
  begin
    Event.What := evNothing;
    Event.InfoPtr := nil;
  end;
end;

procedure TTerminal.OptionsDialog;
type
  TDialogData = record
    Opt: Word;
    PortOpt: Word;
    Col: String[3];
    Row: String[2];
    TermName: FNameStr;
    TermIden: String[127];
    InXLATName: String[79];
    OutXLATName: String[79];
    MacroName: String[79];
  end;
var
  Code: Integer;
  D: PDialog;
  Data: TDialogData;

procedure SetOrClearFlag(Test, Mask: Word; var Opt: Word);
begin
  if Test and Mask <> 0 then Opt := Opt or Mask
  else Opt := Opt and not Mask;
end;

begin
  D := PDialog(Resource^.Get('TERMINALDIALOG'));
  if D = nil then
  begin
    ResourceNotFoundMsgBox('Terminal options dialog');
    Exit;
  end;
  D^.PostProcessEvent := TMMacroProc;
  Data.Opt := TerminalOptions;
  Data.PortOpt := PortOptions shr 4;
  Str(TerminalWidth, Data.Col);
  Str(TerminalHeight, Data.Row);
  Data.TermName := TermcapName;
  Data.TermIden := TermcapIden;
  Data.InXLATName := InputXLATName;
  Data.OutXLATName := OutputXLATName;
  Data.MacroName := TermMacroName;
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    TerminalOptions := Data.Opt;
    Data.PortOpt := Data.PortOpt shl 4;
    SetOrClearFlag(Data.PortOpt, ptRestoreOnClose, PortOptions);
    SetOrClearFlag(Data.PortOpt, ptDropModemOnClose, PortOptions);
    SetOrClearFlag(Data.PortOpt, ptRaiseModemOnOpen, PortOptions);
    SetOrClearFlag(Data.PortOpt, ptIgnoreBufferErrors, PortOptions);
    if ComPort <> nil then
      if ComPort^.Flags and ptHiIrq <> 0 then
        ComPort^.Flags := PortOptions or ptHiIrq
      else ComPort^.Flags := PortOptions;
    Val(Data.Col, TerminalWidth, Code);
    Val(Data.Row, TerminalHeight, Code);
    if (Data.InXLATName <> InputXLATName) or
       (Data.OutXLATName <> OutputXLATName) then
    begin
      InputXLATName := StUpcase(Trim(Data.InXLATName));
      OutputXLATName := StUpcase(Trim(Data.OutXLATName));
      InitXLAT;
    end;
    if Data.MacroName <> TermMacroName then
    begin
      TermMacroName := StUpcase(Trim(Data.MacroName));
      InitMacroList;
    end;
    if (Data.TermName <> TermcapName) or
       (Data.TermIden <> TermcapIden) then
    begin
      TermcapName := StUpcase(Trim(Data.TermName));
      TermcapIden := Data.TermIden;
      InitTermcap;
      PWindow(Owner)^.Frame^.DrawView;
    end;
    if TerminalOptions and toUseBack <> 0 then PrepareBack;
  end;
end;

procedure TTerminal.Paste;
var
  Event: TEvent;
  I: Integer;
  C: Char;
  P: Byte;
  S, SS: String;
begin
  if (ComPort = nil) or (DiskClipStream = nil) or not ClipAreaSelected or
     ProtInProg or (State and (sfPasting + sfDialing) <> 0) then Exit;
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
  I := ClipArea^.KB;
  while I <= ClipArea^.KK do
  begin
    GetClipLine(I, S);
    SS := KeyCodeStr($1C0D);
    if I < ClipArea^.KK then S := S + SS;
    P := 1;
    while (P > 0) and (P <= Length(S)) do
    begin
      if not PutRSChar(S[P]) then Exit;
      if ASCIICharDelay <> 0 then Pause(ASCIICharDelay);
      State := State or sfPasting;
      NestedEventCount := 0;
      Application^.GetEvent(Event);
      Application^.HandleEvent(Event);
      State := State and not sfPasting;
      if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then Exit;
      Inc(P);
    end;
    if I < ClipArea^.KK then
    begin
      if SS = '' then
      begin
        if not PutRSChar(#13) then Exit;
        if (TerminalOptions and ooAddReturn <> 0) and
           not PutRSChar(#10) then Exit;
        if ASCIILineDelay <> 0 then Pause(ASCIILineDelay);
      end;
    end;
    State := State or sfPasting;
    NestedEventCount := 0;
    Application^.GetEvent(Event);
    Application^.HandleEvent(Event);
    State := State and not sfPasting;
    Inc(I);
  end;
end;

procedure TTerminal.PopUp(AnOrigin: TPoint);
begin
  ShowPopup(AnOrigin, NewMenu(
    NewItem('~C~opy', 'Ctrl+Ins', kbCtrlIns, cmCopy, hcCopyTerminal,
    NewItem('~P~aste', 'Shift+Ins', kbShiftIns, cmPaste, hcPasteTerminal,
    NewItem('C~l~ear', 'Ctrl+Del', kbCtrlDel, cmFileClear, hcClearTerminal,
    Menus.NewLine(
    NewItem('~U~pload...', 'PgUp', kbNoKey, cmUpload, hcUpload,
    NewItem('~D~ownload', 'PgDn', kbNoKey, cmDownload, hcDownload,
    NewItem('Di~a~l...', 'Alt+A', kbNoKey, cmDial, hcDial,
    NewItem('D~i~aler queue...', 'Alt+I', kbNoKey, cmDialer, hcSDialer,
    NewItem('~F~lush buffers', 'Alt+G', kbNoKey, cmFlushBuffers, hcFlushBuffers,
    NewItem('~H~angup', 'Alt+H', kbNoKey, cmHangup, hcHangup,
    NewItem('A~n~swer', 'Alt+J', kbNoKey, cmAnswer, hcAnswer,
    NewItem('Br~e~ak', 'Alt+V', kbNoKey, cmSerialBreak, hcSerialBreak,
    Menus.NewLine(
    NewItem('~B~ack', 'Alt+B', kbNoKey, cmBack, hcWBack,
    Menus.NewLine(
    NewItem('P~r~otocol...', '', kbNoKey, cmProtocol, hcProtocol,
    NewItem('Do~w~nload path...', '', kbNoKey, cmDownloadPath, hcDownloadPath,
    NewItem('~T~ransfer setup...', '', kbNoKey, cmTransferSetup, hcTransferSetup,
    NewItem('~M~odem setup...', '', kbNoKey, cmModemSetup, hcModemSetup,
    NewItem('~O~ptions...', '', kbNoKey, cmExecOptions, hcTOptions,
     nil))))))))))))))))))))));
end;

procedure TTerminal.UpdateBackLine(AChar: Char);

procedure SaveBackLine;
begin
  if not OutOfMemInUse and
    (TheBack <> nil) then with PBack(TheBack)^ do
  begin
    TrailTrim(BackLine);
    NewLine(FileLines^.Count, BackLine);
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    IsModified := True;
    DebugModified := True;
    DrawView;
    Indicator^.DrawView;
  end;
  BackLine := '';
end;

begin
  case AChar of
    #8: if (TerminalOptions and ooDestructiveBS <> 0) and
           (BackLine[0] > #0) then Dec(BackLine[0]);
    #10: if BackLine <> '' then SaveBackLine;
    #13: SaveBackLine;
    else
    begin
      if (Length(BackLine) >= TerminalWidth) or
         (Length(BackLine) = BackLineLen) then SaveBackLine;
      Inc(BackLine[0]);
      BackLine[Length(BackLine)] := AChar;
    end;
  end;
end;

procedure TTerminal.UpdateHexBackLine(AChar: Char);
var
  SaveHexy: Boolean;
  B: Byte;
begin
  if not OutOfMemInUse and
    (TheBack <> nil) then with PHexBack(TheBack)^ do
    if NumBytes < MaxHexEditBytes then
    begin
      SaveHexy := IsHexy;
      IsHexy := False;
      for B := 1 to Length(BackLine) do ReplaceChar(
        BackLine[B], NumLines - 1, 62 + NumBytes mod 16, False);
      ReplaceChar(AChar, NumLines - 1, 62 + NumBytes mod 16, False);
      IsHexy := SaveHexy;
    end;
  BackLine := '';
end;

procedure TTerminal.InitMacroList;
begin
  DoneMacroList;
  if TermMacroName <> '' then
  begin
    ReadMacros(TermMacroName, MacroList);
    Owner^.EventMask := Owner^.EventMask and not emHiBit;
  end;
end;

procedure TTerminal.DoneMacroList;
begin
  Owner^.EventMask := Owner^.EventMask or emHiBit;
  if MacroList <> nil then
  begin
    Dispose(MacroList, Done);
    MacroList := nil;
  end;
end;

function TTerminal.PreprocessEnabled(var Event: TEvent): Boolean;
begin
  PreprocessEnabled := State and sfDoorway = 0;
end;

constructor TTerminalWindow.Init;
var
  R: TRect;
begin
  Desktop^.GetExtent(R); R.A.Y := R.B.Y - 8;
  TWindow.Init(R, 'Terminal', wnNoNumber);
  Options := Options or ofValidate;
  GetExtent(R);
  R.Grow(-1, -1);
  Scroller := New(PTerminal, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard)));
  Insert(Scroller);
  WinPos := @TermWinPos;
end;

constructor TTerminalWindow.Load(var S: TStream);
begin
  TWindow.Load(S);
  GetSubViewPtr(S, Scroller);
  WinPos := @TermWinPos;
  TheTerminal := Scroller;
  TerminalDisabled := True;
  with PTerminal(Scroller)^ do
  begin
    InitXLAT;
    InitComPort;
    if ComPort <> nil then
    begin
      InitTermcap;
      InitModem;
      InitCDClock;
    end;
    if DialTime <> -1 then
    begin
      if (ComPort <> nil) and (ComPort^.ModemStatus and DCDMask <> 0) and
         (CDClock <> nil) then
      begin
        CDClock^.InitTime := DialTime;
        CDClock^.PrevTime := PrevDialTime;
        CDClock^.DropTime := CurrentTime;
        CDClock^.UpdateTime;
        CDClock^.Show;
      end;
      DialTime := -1;
      PrevDialTime := 0;
    end;
  end;
  TerminalDisabled := False;
end;

procedure TTerminalWindow.Close;
begin
  if CannotCloseTerminal then Exit;
  if PTerminal(TheTerminal)^.ComPort <> nil then
    SetDTR(PTerminal(TheTerminal)^.ComPort, False);
  TWindow.Close;
end;

function TTerminalWindow.GetPalette: PPalette;
const
  P: String[Length(CTerminalWindow)] = CTerminalWindow;
begin
  GetPalette := @P;
end;

function TTerminalWindow.GetTitle(MaxSize: Integer): TTitleStr;
var
  UART: UARTType;
  S: TTitleStr;
begin
  S := Title^;
  if PTerminal(TheTerminal)^.TermcapInUse and
    (TermColl <> nil) then S := S + ' ' + TermcapIden;
  UART := PTerminal(TheTerminal)^.CurUART;
  if (DeviceLayer = dlUART) or
     (LastModemStatus and
       (CTSMask + DSRMask + RIMask + DCDMask + DTRMask + RTSMask) <> 0) then
  begin
    S := S + ' [';
    if DeviceLayer = dlUART then
    begin
      if UART <> NoUART then S := S + ' UART:';
      S := S + ' ' + UartTypeString[UART];
    end;
    if LastModemStatus and CTSMask <> 0 then S := S + ' CTS';
    if LastModemStatus and DSRMask <> 0 then S := S + ' DSR';
    if LastModemStatus and RIMask <> 0 then S := S + ' RI';
    if LastModemStatus and DCDMask <> 0 then S := S + ' CD';
    if LastModemStatus and DTRMask <> 0 then S := S + ' DTR';
    if LastModemStatus and RTSMask <> 0 then S := S + ' RTS';
    S := S + ' ]';
  end;
  GetTitle := S;
end;

procedure TTerminalWindow.HandleEvent(var Event: TEvent);
begin
  TWindow.HandleEvent(Event);
end;

procedure HandleBackBroadcast(var Event: TEvent; P: PWindow);
begin
  P^.Deiconize;
  P^.Show;
  P^.Select;
  P^.ClearEvent(Event);
end;

procedure CloseBack(P: PWindow; E: Pointer);
begin
  if TheSpooler^.InQueue(E) then
    if PrinterQueueMsgBox <> cmOk then Exit
    else TheSpooler^.DoUpdate := True;
  if P^.Icon <> nil then
  begin
    PWinIcon(P^.Icon)^.Window := nil;
    P^.Icon := nil;
    P^.Flags := P^.Flags and not wfMini;
  end
  else if P^.Owner <> nil then P^.Owner^.Delete(P);
end;

constructor TBack.Load(var S: TStream);
begin
  TFileEditor.Load(S);
  TheBack := @Self;
end;

destructor TBack.Done;
begin
  TFileEditor.Done;
  TheBack := nil;
end;

procedure TBack.HandleEvent(var Event: TEvent);
begin
  TFileEditor.HandleEvent(Event);
  if (Event.What = evBroadcast) and (Event.Command = cmBack) then
    HandleBackBroadcast(Event, PWindow(Owner));
end;

constructor TBackWindow.Init(Bounds: TRect; var FileName: String);
var
  Control, IControl: PView;
  R: TRect;
begin
  TWindow.Init(Bounds, FileName, wnNoNumber);
  Options := Options or (ofTileable + ofASCII + ofNewSize);

  GetExtent(R);
  Inc(R.A.X, 30); Dec(R.B.X, 2); R.A.Y := Pred(R.B.Y);
  Control := New(PScrollBar, Init(R));
  Insert(Control);

  GetExtent(R);
  Inc(R.A.X, 2); R.A.Y := Pred(R.B.Y); R.B.X := R.A.X + 27;
  IControl := New(PIndicator, Init(R));
  IControl^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(IControl);

  GetExtent(R);
  R.Grow(-1, -1);
  Editor := New(PBack, Init(R, PScrollBar(Control),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    PIndicator(IControl)));
  Insert(Editor);
  PBack(Editor)^.ReadFile(FileName);

  WinPos := @BackWinPos;
  TheBack := Editor;
end;

constructor TBackWindow.Load(var S: TStream);
begin
  TEditorWindow.Load(S);
  WinPos := @BackWinPos;
end;

procedure TBackWindow.Close;
begin
  CloseBack(@Self, Editor);
end;

function TBackWindow.GetTitle(MaxSize: Integer): TTitleStr;
begin
  GetTitle := Trim(Concat('Back ', TEditorWindow.GetTitle(MaxSize)));
end;

constructor THexBack.Load(var S: TStream);
begin
  THexEditor.Load(S);
  TheBack := @Self;
end;

destructor THexBack.Done;
begin
  THexEditor.Done;
  TheBack := nil;
end;

procedure THexBack.HandleEvent(var Event: TEvent);
begin
  THexEditor.HandleEvent(Event);
  if (Event.What = evBroadcast) and (Event.Command = cmBack) then
    HandleBackBroadcast(Event, PWindow(Owner));
end;

constructor THexBackWindow.Init(Bounds: TRect; var FileName: String);
var
  Control, IControl: PView;
  R: TRect;
begin
  TWindow.Init(Bounds, FileName, WindowNumAvail);
  Options := Options or (ofTileable + ofHex);

  GetExtent(R);
  Inc(R.A.X, 14); Dec(R.B.X, 2); R.A.Y := Pred(R.B.Y);
  Control := New(PScrollBar, Init(R));
  Insert(Control);

  GetExtent(R);
  Inc(R.A.X, 2); R.A.Y := Pred(R.B.Y); R.B.X := R.A.X + 11;
  IControl := New(PHexIndicator, Init(R));
  IControl^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(IControl);

  GetExtent(R);
  R.Grow(-1, -1);
  Editor := New(PHexBack, Init(R, PScrollBar(Control),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    PHexIndicator(IControl)));
  Insert(Editor);
  PHexBack(Editor)^.ReadFile(FileName);

  WinPos := @BackWinPos;
  TheBack := Editor;
end;

constructor THexBackWindow.Load(var S: TStream);
begin
  THexEditorWindow.Load(S);
  WinPos := @BackWinPos;
end;

procedure THexBackWindow.Close;
begin
  CloseBack(@Self, Editor);
end;

function THexBackWindow.GetTitle(MaxSize: Integer): TTitleStr;
begin
  GetTitle := Trim(Concat('Hex Back ', THexEditorWindow.GetTitle(MaxSize)));
end;

procedure RSRTerminalWindow(RSR: PResourceFile);
var
  W: PTerminalWindow;
  D: PDialog;
begin
  W := New(PTerminalWindow, Init);
  RSR^.Put(W, 'TERMINALWINDOW');
  Dispose(W, Done);
  D := TerminalOptionsDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'TERMINALDIALOG');
    Dispose(D, Done);
  end;
  D := ProtocolDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'PROTOCOLDIALOG');
    Dispose(D, Done);
  end;
  D := ModemSetupDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'MODEMSETUPDIALOG');
    Dispose(D, Done);
  end;
  D := SetupDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'TRANSFERSETUPDIALOG');
    Dispose(D, Done);
  end;
end;

procedure OpenTerminal;
var
  Wide: Boolean;
  W: PWindow;
  R: TRect;
begin
  if Message(Desktop, evBroadcast, cmTerminal, nil) = nil then
  begin
    if TerminalOptions and toUseBack <> 0 then PrepareBack;
    W := PTerminalWindow(Resource^.Get('TERMINALWINDOW'));
    if W <> nil then
    begin
      Wide := TermWinPos.AX = -1;
      if not Wide and (WinPosMask and wpTerm <> 0) and
        ValidWinPos(TermWinPos) then
          SetWinPos(Desktop, TermWinPos, R)
      else
      begin
        Desktop^.GetExtent(R);
        if not Wide then R.A.Y := R.B.Y - 8;
      end;
      W^.Locate(R);
      if Wide then
      begin
        W^.GetExtent(R);
        PTerminalWindow(W)^.Scroller^.Locate(R);
      end;
      Application^.InsertWindow(W);
    end
    else ResourceNotFoundMsgBox('Terminal window');
  end;
end;

procedure PrepareBack;
var
  W: PWindow;
  R: TRect;
  S: FNameStr;
begin
  if TheBack <> nil then Exit;
  if (WinPosMask and wpBack <> 0) and ValidWinPos(BackWinPos) then
    SetWinPos(Desktop, BackWinPos, R)
  else
  begin
    Desktop^.GetExtent(R);
    R.A.Y := R.B.Y - 8;
  end;
  S := '';
  if TerminalOptions and toHexBack <> 0 then
    W := New(PHexBackWindow, Init(R, S))
  else W := New(PBackWindow, Init(R, S));
end;

procedure OpenBack;
begin
  if Message(Desktop, evBroadcast, cmBack, nil) = nil then
  begin
    PrepareBack;
    if TheBack <> nil then Application^.InsertWindow(
      PWindow(PView(TheBack)^.Owner));
  end;
end;

end.