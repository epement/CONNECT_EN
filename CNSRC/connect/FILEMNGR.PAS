{$I-,X+,F+,O+}
unit FileMngr;

interface

uses Dos, Objects, Drivers, Views, Dialogs, PanelRec, Tags, FindFile,
  Archives, BBSStuff, TextRead, DirTree, ProgList, StrCol;

type
  PFilesBBSRec = ^TFilesBBSRec;
  TFilesBBSRec = record
    Text: PString;
    Num: Integer;
  end;

  PFilesBBSList = ^TFilesBBSList;
  TFilesBBSList = object(TStringsCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PPrompt = ^TPrompt;
  TPrompt = object(TLabel)
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PPromptLine = ^TPromptLine;
  TPromptLine = object(TInputLine)
    Main, Setup, Opt: Word;
    HistCount: Word;
    constructor Load(var S: TStream);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure GetExecRec(var Rec: TExecRec);
    procedure EnterPressed;
  private
    function CanScroll(Delta: Integer): Boolean;
  end;

  PPanel = ^TPanel;
  TPanel = object(TListBox)
    Files: PPanelCollection;
    TheTree: PTreeCollection;
    FilesBBS: PCollection;
    Dirinfo: PCollection;
    FoundFiles: PFindFileCollection;
    SelList: PTagList;
    CRCList: PTagList;
    Opposite: PPanel;
  { storable }
    ListDir: PString;
    FocusedName: PString;
    FileListName: PString;
    SaveListDir: PString;
    Which: Byte;
    Status: Byte;
    OldStatus: Byte;
    OldFocused: Integer;
    Indent: Integer;
    Settings: Word;
    SortDescrPos: Byte;
    SortCaseSens: Byte;
    FoundFocused: Integer;
    SortMode: Byte;
    SortDirection: Byte;
    SortPriority: Byte;
    GroupOptions: Byte;
    SortAction: Byte;
    ToggleMask: Byte;
    SortSel: Boolean;
    TimeMode: Byte;
    IgnoreListSpaces: Boolean;
    DrvSelAlignment: Byte;
    DrvSelSize: Byte;
    ColWidth: Byte;
    BarAlignment: Byte;
    Filter: String[12];
    Main: Word;
    Setup: Word;
    Opt: Word;
    AdvancedFilter: TFilterRec;
    Reserved1: Word;
    SortIndexStr: PString;
    Reserved2: Word;
  { non-storable }
    SelCount: Integer;
{    SelSize: Longint;}
    VolumeName: String[12];
    TotalBytes: Real;
    BytesFree: Real;
    FileCount: Longint;
    DirCount: Longint;
    ByteCount: Real;
    SelFileCount: Longint;
    SelDirCount: Longint;
    SelByteCount: Real;
    DirinfoWidth: Integer;
    EMSTotal: Longint;
    EMSAvail: Longint;
    XMSTotal: Longint;
    XMSAvail: Longint;
    SearchStr: String[63];
    SearchPos: Integer;
    CursorPos: Integer;
    DotPos: Integer;
    SearchLevel: Byte;
    DiskChanged: Boolean;
    SelChanged: Boolean;
    Empty: Boolean;
    Archiver: PArchiver;
    InArchive: Boolean;
    TextReader: PTextReader;
    QuickStatus: Byte;
    DescrData: PDescrData;
    UseFilter: Boolean;
    UnixStates: Pointer;
    LastTopItem: Integer;
    PointedItem: PPanelRec;
    AltHistoryIndex: Integer;
    DirinfoName: String[63];
    ExtDiskInfo: String[47];
    LongVolumeLabel: String[31];
{ Added 2005.12.31 }
    NT_DirCheckHandle: Longint;
    constructor Init(var Bounds: TRect);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure CalcBounds(var Bounds: TRect; Delta: TPoint); virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    function GetMouseShape(var Event: TEvent): Char; virtual;
    procedure InitLists;
    procedure DoneLists;
    procedure InitFiles;
    procedure DoneFiles;
    procedure InitFoundFiles;
    procedure DoneFoundFiles;
    procedure InitSelList;
    procedure DoneSelList;
    procedure InitCRCList;
    procedure DoneCRCList;
    procedure InitTextReader;
    procedure DoneTextReader;
    procedure InitDescrData;
    procedure DoneDescrData;
    procedure InitDriveSelector;
    procedure DoneDriveSelector;
    procedure InitPanelBar;
    procedure DonePanelBar;
    procedure SetColumns;
    procedure GetFullStr(Item: Integer; var AText: String);
    procedure GetBriefStr(Item: Integer; var AText: String);
    procedure GetInfoStr(Item: Integer; var AText: String; Sel: Boolean);
    procedure GetQuickInfoStr(var AText: String);
    procedure GetQuickDescrStr(var AText: String);
    procedure GetListDir(var ADir: String);
    procedure GetItemNum(const AName: FNameStr; var Index: Integer);
    procedure GetRecFullName(P: PPanelRec; var S: FNameStr);
    procedure GetItemStr(Index: Integer; var S: FNameStr);
    procedure GetRecStr(P: PPanelRec; var S: FNameStr);
    procedure Scroll(var Event: TEvent);
    procedure GoRight;
    procedure GoLeft;
    procedure GoWhileKeyDown(Key: Byte);
    procedure GoDown;
    procedure GoUp;
    procedure GoPgDn;
    procedure GoPgUp;
    procedure GoCtrlPgDn;
    procedure GoCtrlPgUp;
    procedure GoEnd;
    procedure GoHome;
    procedure FindFullName(const AName: FNameStr; var Index: Integer);
    procedure FindByName(const AName: String; var Index: Integer);
    procedure FocusFileName(const AName: FNameStr);
    function SearchDrive(ADrive: Char; var Index: Integer): Boolean;
    procedure ReadDirectory(UnfoldSel: Boolean);
    procedure UpdateDirinfoRanges;
    procedure NewDir(const ADir: FNameStr; DoFree: Boolean);
    procedure RootDir;
    procedure ReReadPrim(DoFree: Boolean);
    procedure ReRead(EraseTree: Boolean);
    procedure ReReadAll;
    procedure ReReadOnlAPIChange(FromAPI: Byte);
    procedure PrepareSwitch;
    procedure SwitchToDir(const ADir: FNameStr; DoFocus: Boolean);
    procedure AddFocused(Path, Long: Boolean);
    procedure SetSelect(Item: Pointer; On: Boolean);
    procedure SelectFocused;
    procedure SelectAll;
    procedure UnselectAll;
{    procedure CalcSelSize;}
    procedure RestoreTags(ATagList: PTagList);
    procedure NewStatus(AStatus: Byte);
    procedure FilePanel(AStatus: Byte; ForceLong: Boolean);
    procedure Brief;
    procedure Full;
    procedure Tree;
    procedure Info;
    procedure QuickView;
    procedure QuickDescr;
    procedure DrivePanel;
    procedure ToggleInfo(DoRead: Boolean);
    procedure ToggleQuickView;
    procedure ToggleQuickDescr;
    procedure ToggleHidden;
    procedure ToggleExOnly;
    procedure ToggleMiniStatus;
    procedure ToggleDrivePanel;
    procedure ToggleDriveSelector;
    procedure TogglePanelBar;
    procedure ToggleFilesBBS;
    procedure ToggleCalcDirSize;
    procedure ToggleIgnoreSelection;
    procedure ToggleSepSelInfo;
    procedure ClearSelectionList;
    procedure GetSource(var S: FNameStr);
    procedure ExtDialog(Viewer: Boolean);
    procedure ChangeDir;
    procedure GetTitle(var ATitle: String);
    procedure GetVolumeTitle(var ATitle: String; MaxLen: Integer);
    procedure GetDirCounts;
  end;

  PPanelFrame = ^TPanelFrame;
  TPanelFrame = object(TFrame)
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function GetMouseShape(var Event: TEvent): Char; virtual;
  end;

  PPanelWindow = ^TPanelWindow;
  TPanelWindow = object(TWindow)
    LeftPanel, RightPanel, CurrentPanel: PPanel;
    Prompt: PPrompt;
    PromptLine: PPromptLine;
    MacroList: PCollection;
    LeftSelector, RightSelector: PView;
    LeftBar, RightBar: PView;
    LeftZoomRect, RightZoomRect: TRect;
    LeftPanelSize: Real;
    LeftPanelRatio: Real;
    LeftTitlePos, LeftTitleLen, RightTitlePos, RightTitleLen: Byte;
    NoPromptOnClose: Boolean;
    DestName: PString;
    PrevAltCtrlDown: Boolean;
    MouseHintVisible: Boolean;
{Added 2005.12.31 }
    NT_DirCheckTicks: Word;
    constructor Init;
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Close; virtual;
    procedure Draw; virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitFrame; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
    procedure Zoom; virtual;
    procedure GetCurrentPanel;
    procedure SetCurrentPanel(APanel: PPanel);
    function GetTopPos(X: Integer): Byte;
    function GetBottomPos(X: Integer): Byte;
    procedure ReadDirectory;
    procedure UpdateFoundFiles;
    procedure ActivateSearching;
    procedure DeactivateSearching(APanel: PPanel);
    procedure InitMacroList;
    procedure DoneMacroList;
    function PreprocessEnabled(var Event: TEvent): Boolean;
  end;

const
  CPrompt          = #10;
  CPromptLine      = #10#10#7#10;
  CPanelFrame      = #1#2#3#2#3;
  CPanel           = #6#9#8#7#1#2#3;
  CPanelColor      = #$17#$1B#$1A#$71#$31#$1B#$1E#$30#$3E#$07#$5E#$70#$70#$7A#$7F#$0F;
  CPanelBlackWhite = #$07#$07#$07#$70#$70#$07#$0F#$70#$7F#$07#$70#$07#$0F#$07#$07#$70;
  CPanelMonochrome = #$07#$07#$07#$70#$70#$07#$0F#$70#$01#$07#$70#$07#$0F#$07#$07#$70;
  CPanelWindow     = #136#137#138#139#140#141#142#143#144#145#146#147#148#149#150#151;

  CInfoBoxColor    = #$3E#$E0;
  CInfoBoxBW       = #$07#$70;
  CInfoBoxMono     = #$07#$70;
  cHilitColor      = 134;
  cInfoBoxNormal   = 135;
  cInfoBoxHilit    = 203;
  cSelInfoBoxNormal= 204;
  cSelInfoBoxHilit = 252;
  cMouseHintText   = 253;

  pnLeft = 0;
  pnRight = 1;

  gmInitial = 0;
  gmLeft = 1;
  gmRight = 2;
  gmNone = 3;

  sfShowHidden = $1000;
  sfExOnly = $2000;
  sfMiniStatus = $4000;
  sfDrivePanel = $8000;
  sfSearching = $1000;

  stBrief = 0;
  stFull = 1;
  stTree = 2;
  stInfo = 3;
  stQuickView = 4;
  stQuickDescr = 5;

  ofFilesBBS = $0800;
  ofCurrent = $8000;

  seIgnoreSelection = $0001;
  seUnfold = $0002;
  seCalcDirSize = $0004;
  seList = $0008;
  seDriveSelector = $0010;
  seLongNames = $0020;
  seAdvancedFilter = $0040;
  seSepSelInfo = $0080;
  seUnfoldSel = $0100;
  seMaxi = $0200;
  seNewColumns = $0400;
  sePanelBar = $0800;
  seBarAlways = $1000;
  seBarMax = $2000;
  seOldInfoBox = $4000;
  seFullWide = $8000;

  qsPercent = 1;
  qsColor = 2;

  HalfScr = 40;
  MinPanelWidth = 5;
  MinPanelHeight = 4;
  MaxPromptLen = 67;

  dmMouseResize = $FF;

  tmVis = $00;
  tmByF = $01;
  tmByO = $02;
  tmSel = $04;

  tpNo = 0;
  tpLeftDrag = 1;
  tpLeftResize = 2;
  tpLeftColon = 3;
  tpLeftName = 4;
  tpLeftMiddleResize = 5;
  tpRightDrag = 6;
  tpRightResize = 7;
  tpRightColon = 8;
  tpRightName = 9;
  tpClose = 10;
  tpZoom = 11;
  tpMini = 12;
  tpRightMiddleResize = 13;

  bpNo = 0;
  bpLeftDrag = 1;
  bpLeftResize = 2;
  bpMiddleResize = 3;
  bpRightDrag = 4;
  bpRightResize = 5;

{ Added 04.29.03 to support directory size display on Space keystroke }
  kbSpaceSel = $9F00;

{ Added 05-07-03 to support drives/resources hints }
  MouseHintItem: PPanelRec = nil;

procedure FileManager;

implementation

uses CNCrt, Memory, HistList, App, MsgBox, Gauges, DirPrim, Disks, DiskBase,
  DiskPrim, FMAbort, FMAction, FMArcDlg, FMBars, FMBBS, FMClip, FMDialog,
  FMDrag, FMDrvSel, FMGroups, FMInfo, FMList, FMPrim, FMQuickV, FMQuickD,
  FMSecond, FMShift, FMWork, ExtList, ExecPrim, Trees, TreeDlg, Desktops,
  DosTools, UnixMask, Spooler, HeapUMB, UserScr, Timer, Keyboard, History,
  ArcV, ArcRec, ArcDlg, CNMacros, CNWinPos, LFN, TPString, Consts, Commands,
  Defaults;

procedure MovePipeStr(var Dest; const Str: String; Attrs: Word); assembler;
asm
        MOV     DX,DS
        LDS     SI,Str
        CLD
        LODSB
        MOV     CL,AL
        XOR     CH,CH
        JCXZ    @@3
        LES     DI,Dest
	MOV     BX,Attrs
        MOV     AH,BL
@@1:    LODSB
        CMP     AL,'|'
        JE      @@2
        STOSW
        LOOP    @@1
        JMP     @@3
@@2:    XCHG    AH,BH
        LOOP    @@1
@@3:    MOV     DS,DX
end;

function PipeStrLen(const S: String): Integer; assembler;
asm
        LES     DI,S
        MOV     CL,ES:[DI]
        INC     DI
        XOR     CH,CH
        MOV     BX,CX
	JCXZ    @@2
	MOV     AL,'|'
	CLD
@@1:    REPNE   SCASB
	JNE     @@2
	DEC     BX
	JMP     @@1
@@2:    MOV     AX,BX
end;

{ Added 2005.12.31 }
function NT_SetDirCheck(Dir: String; Subdirs: Byte): Longint; {Handle}
var
  Regs: Registers;
begin
  NT_SetDirCheck := 0;
  if Length(Dir) < 254 then with Regs do
  begin
    Dir[Length(Dir)+1] := #0;
    ax := $170d; {}
    bx := ofs(Dir[1]);
    es := seg(Dir[1]);
    cx := 0;
    dx := 0;
    si := Subdirs;
    Intr($2f, Regs);
    NT_SetDirCheck := Longint(dx) shl 16 + cx;
  end;
end;

function NT_DirCheck(var Handle: Longint): Boolean;
var
  Regs: Registers;
begin
  if Handle <= 0 then NT_DirCheck := False
  else with Regs do
  begin
    ax := $170d; {}
    bx := 0;
    es := 0;
    cx := Word(Handle);
    dx := Word(Handle shr 16);
    si := 1;
    Intr($2f, Regs);
    Handle := Longint(dx) shl 16 + cx;
    NT_DirCheck := Boolean(ax);
  end;
end;

procedure NT_FreeDirCheck(var Handle: Longint);
var
  Regs: Registers;
begin
  if Handle > 0 then with Regs do
  begin
    ax := $170d; {}
    bx := 0;
    es := 0;
    cx := Word(Handle);
    dx := Word(Handle shr 16);
    si := 2;
    Intr($2f, Regs);
  end;
  Handle := 0;
end;

procedure TFilesBBSList.FreeItem(Item: Pointer);
begin
  if Item <> nil then
  begin
{
    DisposeStr(PFilesBBSRec(Item)^.Text);
    FreeMem(Item, SizeOf(TFilesBBSRec));
}
    DisposeStrUMB(PFilesBBSRec(Item)^.Text);
    FreeMemUMB(Pointer(Item), SizeOf(TFilesBBSRec));
  end;
end;

procedure TPrompt.Draw;
var
  Color: Word;
  S: String[MaxPromptLen];
  B: TDrawBuffer;
begin
  Color := GetColor(1);
  MoveChar(B, ' ', Byte(Color), Size.X);
  if Text <> nil then
  begin
    S := TrimmedName(Text^, MaxPromptLen);
    MoveStr(B, S, Color);
  end;
  WriteLine(0, 0, Size.X, 1, B);
end;

function TPrompt.GetPalette: PPalette;
const
  P: String[Length(CPrompt)] = CPrompt;
begin
  GetPalette := @P;
end;

procedure TPrompt.HandleEvent(var Event: TEvent);
var
  R: TRect;
  S: String;
begin
  if (Event.What = evMouseDown) and MouseInView(Event.Where) then
  begin
    Pending.What := evCommand;
    if Event.Buttons = mbRightButton then
      Pending.Command := cmDirHistory
      else Pending.Command := cmPromptHistory;
    Event.What := evNothing;
  end;
  TLabel.HandleEvent(Event);
  if Event.What = evBroadcast then
  case Event.Command of
    cmNewPrompt: if Event.InfoPtr <> nil then
      begin
        S := PString(Event.InfoPtr)^;
        if S[0] = #2 then
        begin
          Inc(S[0]);
          S[Length(S)] := '\';
        end;
        if State and sfActive <> 0 then
        begin
          FailSysErrors := True;
          lChDir(S);
          FailSysErrors := False;
          InOutRes := 0;
        end;
        DisposeStr(Text);
        Text := NewStr(S);
        Owner^.GetExtent(R);
        R.A.Y := R.B.Y - 1;
        Inc(R.A.X, Length(TrimmedName(Text^, MaxPromptLen)));
        Link^.Locate(R);
        DrawView;
      end;
  end;
end;

constructor TPromptLine.Load(var S: TStream);
begin
  TInputLine.Load(S);
  S.Read(Main, SizeOf(Main) + SizeOf(Setup) + SizeOf(Opt));
  HistCount := $FF;
end;

procedure TPromptLine.ChangeBounds(var Bounds: TRect);
begin
  if Bounds.B.X < Bounds.A.X + 1 then Bounds.B.X := Bounds.A.X + 1;
  if (Bounds.A.X < Owner^.Origin.X + Owner^.Size.X) and
     (Bounds.B.X > Owner^.Origin.X + Owner^.Size.X) then
    Bounds.B.X := Owner^.Origin.X + Owner^.Size.X;
  TInputLine.ChangeBounds(Bounds);
end;

function TPromptLine.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else GetHelpCtx := hcPromptLine;
end;

function TPromptLine.GetPalette: PPalette;
const
  P: String[Length(CPromptLine)] = CPromptLine;
begin
  GetPalette := @P;
end;

procedure TPromptLine.Draw;
var
  Color, SelColor: Byte;
  L, R: Integer;
  B: TDrawBuffer;
begin
  if FirstPos > CurPos then FirstPos := CurPos;
  L := CurPos - Size.X + 2;
  if FirstPos < L then FirstPos := L;
  if FirstPos < 0 then FirstPos := 0;
  Color := GetColor(1);
  SelColor := Byte(Application^.GetPalette^[112]); { added 10.14.03 }
  MoveChar(B, ' ', Color, Size.X);
  MoveChar(B, '>', Color, 1);
  MoveStr(B[1], System.Copy(Data^, FirstPos + 1, Size.X - 2), Color);
  if CanScroll(1) then MoveChar(B[Size.X - 1], #16, Color, 1);
  if State and sfSelected <> 0 then
  begin
    if CanScroll(-1) then MoveChar(B[1], #17, Color, 1);
    L := SelStart - FirstPos;
    R := SelEnd - FirstPos;
    if L < 0 then L := 0;
    if R > Size.X - 2 then R := Size.X - 2;
    if L < R then MoveChar(B[L + 1], #0, SelColor, R - L);
  end;
  WriteLine(0, 0, Size.X, Size.Y, B);
  SetCursor(CurPos - FirstPos + 1, 0);
end;

procedure TPromptLine.HandleEvent(var Event: TEvent);
var
  ShiftDown: Boolean;
  I: Integer;
  Spot: TPoint;
  S, IS: String;
begin
{ Added 04.08.08 to support InputLine AutoComplete }
  HistoryId := FPromptHistoryID;
  if Event.What = evKeyDown then
    if Event.CharCode <> #0 then
      if (State and sfActive = 0) or (Event.CharCode = #8) or
         ((Event.CharCode in [^A..^Z]) and
          (GetShiftState and (kbLeftShift + kbRightShift) <> 0)) then
      begin
        TInputLine.HandleEvent(Event);
        Exit;
      end
      else case Event.CharCode of
        ^Y, #27:
          begin
            S := '';
            SetData(S);
            Event.What := evNothing;
          end;
        ^E, ^X:
          begin
            I := HistoryCount(FPromptHistoryID);
            if I = 0 then Exit
            else if I = 1 then HistCount := 0
            else if Event.CharCode = ^E then
            begin
              Inc(HistCount);
              if HistCount >= I then HistCount := 0;
            end
            else
            begin
              if HistCount > 0 then Dec(HistCount)
              else HistCount := I - 1;
            end;
            S := HistoryStr(FPromptHistoryID, HistCount);
            if S[0] > Chr(MaxLen) then S[0] := Chr(MaxLen);
            SetData(S);
            Event.What := evNothing;
          end;
        ^Q:
          begin
            GetHistoryStrPrim(@Self);
            Event.What := evNothing;
          end;
        ^M:
          begin
            if Trim(Data^) = '' then Exit;
            Event.What := evNothing;
            EnterPressed;
          end;
        '-', '+', '*': if (Event.ScanCode > $10) and (Data^ = '') then
          begin
            Event.What := evCommand;
            case Event.CharCode of
              '-': Event.Command := cmUnselectGroup;
              '+': Event.Command := cmSelectGroup;
              else
                begin
                  PPanelWindow(Owner)^.GetCurrentPanel;
                  if PPanelWindow(Owner)^.CurrentPanel^.Status = stTree then
                    Event.Command := cmChange
                  else Event.Command := cmInvert;
                end;
            end;
          end;
        ^A..^Z, ^\:
          begin
            PPanelWindow(Owner)^.GetCurrentPanel;
            PPanelWindow(Owner)^.CurrentPanel^.HandleEvent(Event);
          end;
      end
    else if Event.KeyCode = kbCtrlPgUp then
    begin
      PPanelWindow(Owner)^.GetCurrentPanel;
      PPanelWindow(Owner)^.CurrentPanel^.HandleEvent(Event);
    end
    else if CtrlToArrow(Event.KeyCode) = kbDown then
    begin
      GetHistoryStrPrim(@Self);
      Event.What := evNothing;
    end
    else if Event.KeyCode = kbAltBack then
    begin
      TInputLine.HandleEvent(Event);
      Exit;
    end
    else if (Event.KeyCode = kbAltIns) or
      ((Event.KeyCode = kbCtrlIns) and
       (GetShiftState and kbAltShift <> 0)) then Exit else
  else if (Event.What = evMouseDown) and MouseInView(Event.Where) then
    if Event.Buttons = mbRightButton then
    begin
      Select;
      repeat until not MouseEvent(Event, evMouseDown);
      PromptPopupPrim(Event.Where);
      Event.What := evNothing;
    end
    else if Event.Double then
    begin
      Event.What := evKeyDown;
      Event.KeyCode := kbEnter;
      HandleEvent(Event);
    end;
  TInputLine.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmPopUp:
        begin
          Spot.X := 39;
          Spot.Y := ScreenHeight - 2;
          PromptPopupPrim(Spot);
        end;
      cmExecOptions: ExecOptionsPrim(@Self);
      cmDirHistory: with PPanelWindow(Owner)^ do
        begin
          GetCurrentPanel;
          DirHistoryPrim(CurrentPanel);
        end;
      cmPromptHistory: GetHistoryStrPrim(@Self);
      else Exit;
    end;
    Event.What := evNothing;
  end
  else if Event.What = evBroadcast then
  case Event.Command of
    cmAddFileName:
      begin
        if SelStart <> SelEnd then
        begin
          Delete(Data^, SelStart + 1, SelEnd - SelStart);
          CurPos := SelStart;
          SelStart := 0;
          SelEnd := 0;
        end;
        S := Data^;
        ShiftDown := GetShiftState and (kbLeftShift + kbRightShift) <> 0;
        if ShiftDown then while S[Length(S)] = ' ' do Dec(S[0]);
        IS := PString(Event.InfoPtr)^;
        if not ShiftDown and (CurPos > 0) and (CurPos <= Length(S)) and
           not (S[CurPos] in [' ', '\']) then IS := ' ' + IS;
        if (CurPos >= Length(S)) or not (S[CurPos + 1] in [' ', '\']) then
        begin
          Inc(IS[0]);
          IS[Length(IS)] := ' ';
        end;
        System.Insert(IS, S, CurPos + 1);
        if S[0] > Chr(MaxLen) then S[0] := Chr(MaxLen)
        else Inc(CurPos, Length(IS));
        Data^ := S;
        DrawView;
        Event.What := evNothing;
      end;
    cmCancelExec:
      begin
        DrawView;
        Event.What := evNothing;
      end;
  end;
end;

procedure TPromptLine.SetData(var Rec);
begin
  Move(Rec, Data^, DataSize);
  CurPos := Length(Data^);
  FirstPos := 0;
  SelStart := 0;
  SelEnd := 0;
  DrawView;
end;

procedure TPromptLine.SetState(AState: Word; Enable: Boolean);
const
  FindFileCommands = [cmFind];
begin
  TView.SetState(AState, Enable);
  if Enable and (AState = sfFocused) then EnableCommands(
    BlockCommands + PasteCommands + MTCommands + FindFileCommands)
  else if not Enable and (((AState and (sfActive + sfSelected) <> 0) and
    GetState(sfExposed)) or (AState = sfExposed)) then
      DisableCommands(BlockCommands + PasteCommands + MTCommands +
        FindFileCommands + IncSearchCommands);
end;

procedure TPromptLine.Store(var S: TStream);
begin
  TInputLine.Store(S);
  S.Write(Main, SizeOf(Main) + SizeOf(Setup) + SizeOf(Opt));
end;

procedure TPromptLine.GetExecRec(var Rec: TExecRec);
var
  I: Integer;
begin
  I := Pos(' ', Data^);
  if I = 0 then I := Length(Data^) + 1;
  with Rec do
  begin
    Path := System.Copy(Data^, 1, I - 1);
    Params := System.Copy(Data^, I + 1, MaxLen);
    Move(Self.Main, Main, SizeOf(Word) * 3);
  end;
end;

procedure TPromptLine.EnterPressed;
var
  Len: Byte;
  S: FNameStr;

function IsPath: Boolean;
begin
  Len := Length(S);
  if Len = 1 then IsPath := S[1] in ['\', '.']
  else if Len = 2 then IsPath := (S[2] in ['\', ':']) or
    ((S[1] in ['\', '.']) and (S[2] in ['\', '.']))
  else if (S[1] = '\') and (S[2] = '\') then IsPath := (S[3] <> '\') and
    (((S[Len] = '\') and (S[Len - 1] <> '\')) or (RootName(S) = S))
  else IsPath := (S[Len] = '\') and (S[Len - 1] <> '\');
end;

label
  Exec;
begin
  TrimSt(Data^);
  HistoryAdd(FPromptHistoryID, Data^, True);
  HistCount := $FF;
  GetExecRec(ExecRec);
  Data^ := '';
  CurPos := 0;
  FirstPos := 0;
  SelStart := 0;
  SelEnd := 0;
  if ExecRec.Params = '' then S := CNFileName(ExecRec.Path)
  else if (Length(ExecRec.Path) = 2) and
    (CompUCString(ExecRec.Path, 'CD') = Equal) then
      S := AddedSlash(lFExpand(CNFileName(ExecRec.Params)))
  else Goto Exec;
  if IsPath then
  begin
    if (Length(S) = 2) and (S[2] = ':') then
      GetCurDir(Byte(Upcase(S[1])) - $40, S);
    if IsWild(S) or
      (not (S[1] in ['\', '.']) and not DirPresent(S)) then
        SearchDirDialog(S);
    if S <> '' then
    begin
      PPanelWindow(Owner)^.GetCurrentPanel;
      PPanelWindow(Owner)^.CurrentPanel^.SwitchToDir(AddedSlash(S), True);
    end;
    DrawView;
    Exit;
  end;
Exec:
  PrepareExecEvent;
end;

function TPromptLine.CanScroll(Delta: Integer): Boolean;
begin
  if Delta < 0 then CanScroll := FirstPos > 0
  else if Delta > 0 then
    CanScroll := Length(Data^) - FirstPos + 2 > Size.X
  else CanScroll := False;
end;

const
  SortIndexSign = $02EB;

constructor TPanel.Init(var Bounds: TRect);
var
  S: FNameStr;
begin
  TListBox.Init(Bounds, 3, nil);
  Options := Options and not ofFirstClick;
  State := State or sfMiniStatus;
  Settings := seNewColumns;
  ColWidth := 13;
  InitFoundFiles;
  InitLists;
  InitFiles;
  InitSelList;
  GetCurDir(0, S);
{  ListDir := NewStr(S);}
  ListDir := NewStrUMB(S);
  Filter := '*.*';
  SearchPos := 1;
  CursorPos := -1;
end;

constructor TPanel.Load(var S: TStream);
var
  I: Integer;
  SS: FNameStr;
begin
  TListBox.Load(S);
  FoundFiles := PFindFileCollection(List);
  I := FoundFiles^.Count;
  if (I <> 0) and (FoundFiles^.At(I - 1) = nil) then
  begin
    DoneFoundFiles;
    InitFoundFiles;
  end;
{  ListDir := S.ReadStr;}
  ListDir := ReadStrUMB(@S);
  if ListDir = nil then
  begin
    GetCurDir(0, SS);
{    ListDir := NewStr(SS);}
    ListDir := NewStrUMB(SS);
  end;
{  FocusedName := S.ReadStr;}
  FocusedName := ReadStrUMB(@S);
  S.Read(Which, SizeOf(Which) + SizeOf(Status) + SizeOf(OldStatus) +
    SizeOf(OldFocused) + SizeOf(Indent) + SizeOf(Settings) +
    SizeOf(SortDescrPos) + SizeOf(SortCaseSens) + SizeOf(FoundFocused) +
    SizeOf(SortMode) + SizeOf(SortDirection) + SizeOf(SortPriority) +
    SizeOf(GroupOptions) + SizeOf(SortAction) + SizeOf(ToggleMask) +
    SizeOf(SortSel) + SizeOf(TimeMode) + SizeOf(IgnoreListSpaces) +
    SizeOf(DrvSelAlignment) + SizeOf(DrvSelSize) + SizeOf(ColWidth) +
    SizeOf(BarAlignment) + SizeOf(Filter) + SizeOf(Main) * 3);
  if Settings and seList <> 0 then
  begin
{
    FileListName := S.ReadStr;
    SaveListDir := S.ReadStr;
}
    FileListName := ReadStrUMB(@S);
    SaveListDir := ReadStrUMB(@S);
  end;
  if Settings and seAdvancedFilter <> 0 then
  begin
{    AdvancedFilter.Text := S.ReadStr;}
    AdvancedFilter.Text := ReadStrUMB(@S);
    S.Read(AdvancedFilter.Unix, SizeOf(Boolean) +
      SizeOf(Longint) * 4 + SizeOf(Byte) + SizeOf(Pointer));
  end;
  S.Read(Reserved1, SizeOf(Word));
  if Reserved1 = SortIndexSign then
  begin
{    SortIndexStr := S.ReadStr;}
    SortIndexStr := ReadStrUMB(@S);
    S.Read(Reserved2, SizeOf(Word));
  end;
  if Settings and seNewColumns = 0 then
  begin
    Settings := Settings or seNewColumns;
    if (Status = stBrief) and (Settings and seLongNames <> 0) then
      ColWidth := 20
    else ColWidth := 13;
  end;
  InitLists;
  InitFiles;
  InitSelList;
  SearchPos := 1;
  if Status = stQuickView then InitTextReader
  else if Status = stQuickDescr then InitDescrData;
  LastTopItem := TopItem;
end;

destructor TPanel.Done;
begin
{ Added 2005.12.31 }
  NT_FreeDirCheck(NT_DirCheckHandle);

  if DescrData <> nil then DoneDescrData;
  if TextReader <> nil then DoneTextReader;
  if InArchive then Dispose(Archiver, Done);
{
  DisposeStr(AdvancedFilter.Text);
  DisposeStr(SaveListDir);
  DisposeStr(FileListName);
  DisposeStr(FocusedName);
  DisposeStr(ListDir);
  DisposeStr(SortIndexStr);
}
  DisposeStrUMB(AdvancedFilter.Text);
  DisposeStrUMB(SaveListDir);
  DisposeStrUMB(FileListName);
  DisposeStrUMB(FocusedName);
  DisposeStrUMB(ListDir);
  DisposeStrUMB(SortIndexStr);
  DoneSelList;
  DoneFiles;
  DoneLists;
  DoneFoundFiles;
  DoneCRCList;
  TListBox.Done;
end;

procedure TPanel.CalcBounds(var Bounds: TRect; Delta: TPoint);
var
  LeftSize, Y: Integer;
begin
  with PPanelWindow(Owner)^ do
  begin
    LeftPanelSize := (Size.X - 4) * LeftPanelRatio + 0.001;
    LeftSize := Trunc(LeftPanelSize);
    if LeftSize < MinPanelWidth then LeftSize := MinPanelWidth
    else if LeftSize > Size.X - MinPanelWidth - 4 then
      LeftSize := Size.X - MinPanelWidth - 4;
    Y := 1 + Self.Size.Y + Delta.Y;
    if Y < MinPanelHeight + 1 then Y := MinPanelHeight + 1
    else if Y > Size.Y - 2 then Y := Size.Y - 2;
    if Which = pnLeft then Bounds.Assign(1, 1, 1 + LeftSize, Y)
    else Bounds.Assign(
      LeftPanel^.Origin.X + LeftSize + 2, 1, Size.X - 1, Y);
  end;
end;

procedure TPanel.ChangeBounds(var Bounds: TRect);
var
  X: Integer;
  P: PDriveSelector;
  B: PPanelBar;
  R: TRect;
begin
  Owner^.Owner^.Lock;
  X := Size.X;
  SetBounds(Bounds);
  if (X <> Size.X) and (Status = stQuickDescr) and
     (BBSOptions and bbFormatData <> 0) then
    DescrDataToDirinfoPrim(@Self);
  if Settings and seDriveSelector <> 0 then
  begin
    if Which = pnLeft then
      P := PDriveSelector(PPanelWindow(Owner)^.LeftSelector)
    else P := PDriveSelector(PPanelWindow(Owner)^.RightSelector);
    if P <> nil then P^.AdjustBounds;
  end;
  if Settings and sePanelBar <> 0 then
  begin
    if Which = pnLeft then B := PPanelBar(PPanelWindow(Owner)^.LeftBar)
    else B := PPanelBar(PPanelWindow(Owner)^.RightBar);
    if B <> nil then B^.AdjustBounds;
  end;
  SetColumns;
  DrawView;
  Owner^.Owner^.Unlock;
end;

function TPanel.GetPalette: PPalette;
const
  P: String[Length(CPanel)] = CPanel;
begin
  GetPalette := @P;
end;

procedure TPanel.Draw;
var
  Mini, Maxi, Within, HiTree, SelInfo: Boolean;
  TagColor, TagPos: Byte;
  NormalColor, FocSelColor, SelectedColor, HilitColor, FocusedColor,
  LinesColor, InfoColor, InfoBoxColor, SelInfoBoxColor, Color: Word;
  CurCol, I, J, N, LoY, HiY, Item: Integer;
  P: PPanelRec;
  Params: Array[0..1] of Longint;
  AttrStr: String[13];
  B: TDrawBuffer;
  Text: String;

procedure DrawTextWithArrows(PS: PString);
begin
  if PS <> nil then
  begin
    Text := System.Copy(PS^, Indent + 1, Size.X + 1);
    MoveStr(B, Text, NormalColor);
    if Indent <> 0 then MoveChar(B[0], #27, HilitColor, 1);
    if Length(Text) > Size.X then
      MoveChar(B[Size.X - 1], #26, HilitColor, 1);
  end;
end;

procedure DrawInfo;
var
  I, Index, BufPos: Integer;
  P: PString;
  L: Longint;
  S, NS: String;

procedure DrawInfoLine;
begin
  MoveChar(B, ' ', NormalColor, Size.X);
  if Size.X < HalfScr then BufPos := (HalfScr - 1 - CStrLen(Text)) div 2
  else BufPos := Size.X div 2 - CStrLen(Text) div 2;
  if BufPos < 1 then BufPos := 1;
  if not Empty and not GlobalEmptyFlag then
    MoveCStr(B[BufPos], Text, InfoColor);
  WriteLine(0, I, Size.X, 1, B);
  Inc(I);
end;

(*
begin
  MoveChar(B, ' ', NormalColor, Size.X);
  Text := 'CONNECT File Manager, Version 7.5';
  if Size.X < HalfScr then BufPos := 3
  else BufPos := Size.X div 2 - Length(Text) div 2;
  MoveStr(B[BufPos], Text, NormalColor);
  WriteLine(0, 0, Size.X, 1, B);

  MoveChar(B, ' ', NormalColor, Size.X);
  Text := 'Copyright (C) 1991-2K by KHEMZ, Inc';
  if Size.X < HalfScr then BufPos := 2
  else BufPos := Size.X div 2 - Length(Text) div 2;
  MoveStr(B[BufPos], Text, NormalColor);
  WriteLine(0, 1, Size.X, 1, B);

  MoveChar(B, 'Ä', LinesColor, Size.X);
  WriteLine(0, 2, Size.X, 1, B);

  I := 3;

  L := Longint(Word(Ptr(0, $413)^)) shl 10;
  FormatBytes(Text, L, 1000000000);
  Text := '~' + Text + '~ Bytes Memory';
  DrawInfoLine;

  Dec(L, Longint(PrefixSeg) shl 4);
  FormatBytes(Text, L, 1000000000);
  Text := '~' + Text + '~ Bytes Free';
  DrawInfoLine;

  Text := ExtDiskInfo;
  DrawInfoLine;

  Opposite^.GetListDir(S);
  if S[1] = '\' then Text := '~?~ total bytes on network resource'
  else
  begin
    FormatFloatBytes(Text, TotalBytes, 1000000000);
    Text := '~' + Text + '~ total bytes on drive ~' + S[1] + ':~';
  end;
  DrawInfoLine;

  if S[1] = '\' then Text := '~?~ bytes free on network resource'
  else
  begin
    FormatFloatBytes(Text, BytesFree, 1000000000);
    Text := '~' + Text + '~ bytes free on drive ~' + S[1] + ':~';
  end;
  DrawInfoLine;

  FormatFloatBytes(Text, DirBytes, 1000000000);
  if NumFiles = 1 then Text := '~1~ file uses ~' + Text + '~ bytes in'
  else
  begin
    FormatBytes(NS, NumFiles, 1000000000);
    Text := '~' + NS + '~ files use ~' + Text + '~ bytes in';
  end;
  DrawInfoLine;

  if (S[0] = #2) and (S[2] = ':') then Text := AddedSlash(S)
  else Text := TrimmedName(S, Size.X - 2);
  MoveChar(B, ' ', NormalColor, Size.X);
  if Size.X < HalfScr then BufPos := (HalfScr - 1 - Length(Text)) div 2
  else BufPos := Size.X div 2 - Length(Text) div 2;
  if not Empty and not GlobalEmptyFlag then
    MoveStr(B[BufPos], Text, NormalColor);
  WriteLine(0, 9, Size.X, 1, B);

  MoveChar(B, 'Ä', LinesColor, Size.X);
  if DirinfoName <> '' then
  begin
    Text := ' ~' + DirinfoName + '~ ';
    BufPos := Size.X div 2;
    I := CStrLen(Text) div 2;
    if BufPos < I then BufPos := 0 else Dec(BufPos, I);
    MoveCStr(B[BufPos], Text, InfoColor);
  end;
  WriteLine(0, 10, Size.X, 1, B);

  if Size.Y < 12 then Exit;

  for I := 11 to Size.Y - 1 do
  begin
    MoveChar(B, ' ', NormalColor, Size.X);
    if not Empty and not GlobalEmptyFlag then
      if Dirinfo^.Count > 0 then
      begin
        Index := Focused + I - 11;
        P := Dirinfo^.At(Index);
        DrawTextWithArrows(P);
      end
      else if I = 12 then
      begin
        if Opposite^.InArchive then
          Text := 'No comments in this archive'
        else Text := 'No `dirinfo'' file in this directory';
        if Size.X < HalfScr then
          BufPos := (HalfScr - 1 - CStrLen(Text)) div 2
        else BufPos := Size.X div 2 - CStrLen(Text) div 2;
        MoveStr(B[BufPos], Text, NormalColor);
      end;
    WriteLine(0, I, Size.X, 1, B);
  end;
end;
*)

begin
  MoveChar(B, ' ', NormalColor, Size.X);
  Text := 'CONNECT File Manager, Version 8.0';
  if Size.X < HalfScr then BufPos := 3
  else BufPos := Size.X div 2 - Length(Text) div 2;
  MoveStr(B[BufPos], Text, NormalColor);
  WriteLine(0, 0, Size.X, 1, B);

  MoveChar(B, ' ', NormalColor, Size.X);
  Text := 'Copyright (C) 1991-06 by KHEMZ, Inc';
  if Size.X < HalfScr then BufPos := 2
  else BufPos := Size.X div 2 - Length(Text) div 2;
  MoveStr(B[BufPos], Text, NormalColor);
  WriteLine(0, 1, Size.X, 1, B);

  MoveChar(B, 'Ä', LinesColor, Size.X);
  if LongVolumeLabel <> '' then
  begin
    Text := ' ~' + LongVolumeLabel + '~ ';
    BufPos := Size.X div 2;
    I := CStrLen(Text) div 2;
    if BufPos < I then BufPos := 0 else Dec(BufPos, I);
    MoveCStr(B[BufPos], Text, InfoColor);
  end;
  WriteLine(0, 2, Size.X, 1, B);

  I := 3;

  L := Longint(Word(Ptr(0, $413)^)) shl 10;
  FormatBytes(Text, L, 1000000000);
  Dec(L, Longint(PrefixSeg) shl 4);
  FormatBytes(NS, L, 1000000000);
  Text := 'Memory: ~' + NS + '~ / ~' + Text + '~';
  DrawInfoLine;

  FormatBytes(Text, EMSTotal, 1000000000);
  FormatBytes(NS, EMSAvail, 1000000000);
  Text := 'EMS: ~' + NS + '~ / ~' + Text + '~';
  DrawInfoLine;

  FormatBytes(Text, XMSTotal, 1000000000);
  FormatBytes(NS, XMSAvail, 1000000000);
  Text := 'XMS: ~' + NS + '~ / ~' + Text + '~';
  DrawInfoLine;

  Text := ExtDiskInfo;
  DrawInfoLine;

  FormatFloatBytes(Text, TotalBytes, 1000000000);
  FormatFloatBytes(NS, BytesFree, 1000000000);
  Text := 'Space: ~' + NS + '~ / ~' + Text + '~';
  DrawInfoLine;

  FormatFloatBytes(Text, ByteCount, 1000000000);
  FormatBytes(NS, FileCount, 1000000000);
  Text := '~' + Text + '~ (~' + NS + '~) [~';
  FormatBytes(NS, DirCount, 1000000000);
  Text := Text + NS + '~] in';
  DrawInfoLine;

  Opposite^.GetListDir(S);
  if (S[0] = #2) and (S[2] = ':') then Text := AddedSlash(S)
  else Text := TrimmedName(S, Size.X - 2);
  MoveChar(B, ' ', NormalColor, Size.X);
  if Size.X < HalfScr then BufPos := (HalfScr - 1 - Length(Text)) div 2
  else BufPos := Size.X div 2 - Length(Text) div 2;
  if not Empty and not GlobalEmptyFlag then
    MoveStr(B[BufPos], Text, NormalColor);
  WriteLine(0, 9, Size.X, 1, B);

  MoveChar(B, 'Ä', LinesColor, Size.X);
  if DirinfoName <> '' then
  begin
    Text := ' ~' + DirinfoName + '~ ';
    BufPos := Size.X div 2;
    I := CStrLen(Text) div 2;
    if BufPos < I then BufPos := 0 else Dec(BufPos, I);
    MoveCStr(B[BufPos], Text, InfoColor);
  end;
  WriteLine(0, 10, Size.X, 1, B);

  if Size.Y < 12 then Exit;

  for I := 11 to Size.Y - 1 do
  begin
    MoveChar(B, ' ', NormalColor, Size.X);
    if not Empty and not GlobalEmptyFlag then
      if Dirinfo^.Count > 0 then
      begin
        Index := Focused + I - 11;
        P := Dirinfo^.At(Index);
        DrawTextWithArrows(P);
      end
      else if I = 12 then
      begin
        if Opposite^.InArchive then
          Text := 'No comments in this archive'
        else Text := 'No `dirinfo'' file in this directory';
        if Size.X < HalfScr then
          BufPos := (HalfScr - 1 - CStrLen(Text)) div 2
        else BufPos := Size.X div 2 - CStrLen(Text) div 2;
        MoveStr(B[BufPos], Text, NormalColor);
      end;
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure DrawQuickView;
var
  I, Index: Integer;
  P: PString;
  TB: Array[0..511] of Word;
begin
  for I := 0 to Size.Y - 1 - Byte(Mini) * 2 do
  begin
    MoveChar(B, ' ', NormalColor, Size.X);
    if not Empty and not GlobalEmptyFlag and (Dirinfo^.Count > 0) then
    begin
      Index := Focused + I;
      P := Dirinfo^.At(Index);
      if P <> nil then
        if QuickStatus and qsColor <> 0 then
        begin
          MoveChar(TB, ' ', NormalColor, 511);
          MovePipeStr(TB, P^, InfoColor);
          Move(TB[Indent], B, Size.X * 2);
        end
        else DrawTextWithArrows(P);
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
  if not Mini then Exit;
  MoveChar(B, 'Ä', LinesColor, Size.X);
  WriteLine(0, Size.Y - 2, Size.X, 1, B);
  MoveChar(B, ' ', NormalColor, Size.X);
  if Empty or GlobalEmptyFlag then Text := ''
  else GetQuickInfoStr(Text);
  MoveStr(B, Text, NormalColor);
  WriteLine(0, Size.Y - 1, Size.X, 1, B);
end;

procedure DrawQuickDescr;
var
  I, Index: Integer;
  P: PString;
begin
  for I := 0 to Size.Y - 1 - Byte(Mini) * 2 do
  begin
    MoveChar(B, ' ', NormalColor, Size.X);
    if not Empty and not GlobalEmptyFlag then
    begin
      Index := Focused + I;
      P := Dirinfo^.At(Index);
      DrawTextWithArrows(P);
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
  if not Mini then Exit;
  MoveChar(B, 'Ä', LinesColor, Size.X);
  WriteLine(0, Size.Y - 2, Size.X, 1, B);
  MoveChar(B, ' ', NormalColor, Size.X);
  if Empty or GlobalEmptyFlag then Text := ''
  else GetQuickDescrStr(Text);
  MoveStr(B, Text, NormalColor);
  WriteLine(0, Size.Y - 1, Size.X, 1, B);
end;

{
procedure SetDirCountsText(R: Real; var L: Longint);
var
  S: String;
begin
  FormatFloatBytes(S, R, 10000000);
  S := S + '~ bytes';
  if R = 1 then Dec(S[0]);
  FormatStr(Text, ' Files: ~%d~; Dirs: ~%d~; ~', L);
  Text := Text + S + ' ';
end;
}

procedure SetDirCountsText(R: Real; var L: Longint);
var
  S: String;
begin
  FormatFloatBytes(S, R, 1000000000);
  FormatStr(Text, '~ (~%d~) [~%d~] ', L);
  Text := ' ~' + S + Text;
end;

{
procedure DrawInfoBox(AColor: Word);
begin
  I := (Size.X + 1 - CStrLen(Text)) div 2;
  if I < 0 then I := 0;
  MoveCStr(B[I], Text, AColor);
end;
}

procedure DrawInfoBox(AColor: Word; NewStyle: Boolean);
begin
  if NewStyle then
  begin
    MoveChar(B, #0, AColor, Size.X);
    MoveCStr(B[0], AttrStr, AColor);
    I := Size.X - CStrLen(Text);
    if I < 10 then I := 0;
  end
  else
  begin
    I := (Size.X + 1 - CStrLen(Text)) div 2;
    if I < 0 then I := 0;
  end;
  MoveCStr(B[I], Text, AColor);
end;

begin
  AttrStr := '';
  NormalColor := GetColor(1);
  FocSelColor := GetColor(2);
  FocusedColor := GetColor(3);
  SelectedColor := GetColor(4);
  if State and sfActive = 0 then LinesColor := GetColor(5)
  else if State and sfDragging <> 0 then LinesColor := GetColor(7)
  else LinesColor := GetColor(6);
  InfoColor := NormalColor;
  HilitColor := Application^.GetColor(cHilitColor);
  InfoBoxColor := Application^.GetColor(cInfoBoxNormal);
  SelInfoBoxColor := Application^.GetColor(cSelInfoBoxNormal);
  WordRec(LinesColor).Hi := HilitColor;
  WordRec(InfoColor).Hi := HilitColor;
  WordRec(InfoBoxColor).Hi := Application^.GetColor(cInfoBoxHilit);
  WordRec(SelInfoBoxColor).Hi := Application^.GetColor(cSelInfoBoxHilit);
  Mini := State and sfMiniStatus <> 0;
  Maxi := Settings and seMaxi <> 0;
  if Status = stInfo then
  begin
    DrawInfo;
    Exit;
  end;
  if Status = stQuickView then
  begin
    DrawQuickView;
    Exit;
  end;
  if Status = stQuickDescr then
  begin
    DrawQuickDescr;
    Exit;
  end;
  if Maxi then LoY := 0 else LoY := 1;
  if Mini then HiY := Size.Y - 3 else HiY := Size.Y - 1;
  N := HiY - LoY + 1;
  if Empty or GlobalEmptyFlag then
  begin
    MoveChar(B, ' ', NormalColor, Size.X);
    WriteLine(0, LoY, Size.X, N, B);
  end
  else for I := LoY to HiY do
  begin
    for J := 0 to NumCols - 1 do
    begin
      Item := TopItem + J * N + I - LoY;
      CurCol := J * ColWidth;
      HiTree := False;
      P := List^.At(Item);
      if Focused = Item then
      begin
	AttrStr := ' <~DAHRSCE~> ';
	if P^.Attr and Directory = 0 then AttrStr[4] := '-';
	if P^.Attr and   Archive = 0 then AttrStr[5] := '-';
	if P^.Attr and    Hidden = 0 then AttrStr[6] := '-';
	if P^.Attr and  ReadOnly = 0 then AttrStr[7] := '-';
	if P^.Attr and   SysFile = 0 then AttrStr[8] := '-';
{ Added 2006.01.03 }
	if P^.HiAttr and haCompressed = 0 then AttrStr[9] := '-';
	if P^.HiAttr and haEncrypted = 0 then AttrStr[10] := '-';
      end;
      if (State and (sfSelected + sfActive) = (sfSelected + sfActive)) and
         (Range > 0) and (Focused = Item) then
      begin
        if P^.Selected then Color := FocSelColor
        else Color := FocusedColor;
        if CursorPos = -1 then Cursor.X := CurCol
        else if (Status = stFull) and (Settings and seLongNames <> 0) and
          not (P^.Name[1] in [':', '.']) then
            Cursor.X := CursorPos - Indent
        else Cursor.X := CurCol + CursorPos;
        SetCursor(Cursor.X, I);
      end
      else if (Item < Range) and P^.Selected then Color := SelectedColor
      else if (Status <= stTree) and
        (GroupOptions and fgGroupHighlight <> 0) and
        ((SelCount = 0) or (GroupOptions and fgSelectionTurnsOff = 0)) and
        (P <> nil) then
          if Status = stTree then
          begin
            Color := NormalColor;
            if (GroupOptions and fgGroupHighlight <> 0) and
               (PTreeRec(P)^.Color <> 0) then HiTree := True;
          end
          else Color := P^.Color
      else Color := NormalColor;
      if NumCols = 1 then MoveChar(B, ' ', Color, Size.X)
      else MoveChar(B[CurCol], ' ', Color, ColWidth);
      if Item < Range then
      begin
        Text := GetText(Item, ColWidth);
        if Status = stTree then
        begin
          if HiTree then WordRec(Color).Hi := PTreeRec(P)^.Color
          else WordRec(Color).Hi := WordRec(Color).Lo;
          MovePipeStr(B[CurCol], Text, Color);
        end
        else
        begin
          MoveStr(B[CurCol], Text, Color);
          if P^.Selected and not (TagChar in [#0, #32]) then
          begin
            if (State and (sfSelected + sfActive) =
               (sfSelected + sfActive)) and (Focused = Item) then
              TagColor := FocusedColor
            else if GroupOptions and fgGroupHighlight <> 0 then
              TagColor := P^.Color
            else TagColor := NormalColor;
            TagPos := CurCol + Pos(TagChar, Text);
            if TagPos <> 0 then WordRec(B[TagPos - 1]).Hi := TagColor;
          end;
        end;
      end;
      if (Status = stFull) and (Settings and seLongNames = 0) then
      begin
        if (Focused <> Item) or (State and (sfSelected + sfActive) <>
           (sfSelected + sfActive)) then Color := LinesColor;
	MoveChar(B[ColWidth - 1], '³', Color, 1);
        if Options and (ofValidate + ofFilesBBS) = 0 then
        begin
          if ColWidth + 9 < MaxViewWidth then
	    MoveChar(B[ColWidth + 9], '³', Color, 1);
          if ColWidth + 18 < MaxViewWidth then
	    MoveChar(B[ColWidth + 18], '³', Color, 1);
          if ColWidth + 25 < MaxViewWidth then
	    MoveChar(B[ColWidth + 25], '³', Color, 1);
          if InArchive and (ColWidth + 31 < MaxViewWidth) then
	    MoveChar(B[ColWidth + 31], '³', Color, 1);
        end;
      end
      else if Status = stBrief then
	MoveChar(B[CurCol + ColWidth - 1], '³', LinesColor, 1);
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;

  if not Maxi then
  begin
    MoveChar(B, ' ', NormalColor, Size.X);
    if Status = stBrief then for I := 0 to NumCols - 1 do
    begin
      MoveCStr(B[ColWidth * I + (ColWidth - 1) div 2 - 2],
        '~Name~', LinesColor);
      MoveChar(B[ColWidth * (I + 1) - 1], '³', LinesColor, 1);
    end
    else if Status = stFull then
      if Settings and seLongNames <> 0 then
        if Options and ofValidate <> 0 then
          MoveCStr(B[0], '~Drive list~', LinesColor)
        else MoveCStr(B[0], '~File name~', LinesColor)
      else
      begin
        MoveCStr(B[(ColWidth - 1) div 2 - 2], '~Name~', LinesColor);
	MoveChar(B[ColWidth - 1], '³', LinesColor, 1);
        if Options and (ofValidate + ofFilesBBS) <> 0 then
          MoveCStr(B[ColWidth + 7], '~Description~', LinesColor)
        else
        begin
	  Text := '   ~Size~  ³  ~Date~  ³ ~Time~ ³~Attr~';
	  if InArchive then Text := Text + ' ³ ~%~';
          while (Text <> '') and
            (ColWidth + Length(Text) >= MaxViewWidth) do Dec(Text[0]);
          MoveCStr(B[ColWidth], Text, LinesColor);
        end;
      end
    else if Status = stTree then
    begin
      Text := 'The directory structure of drive';
      if InArchive then
      begin
        Text[Length(Text) - 4] := 'a';
        System.Insert('ch', Text, Length(Text) - 2);
      end
      else if ListDir^[1] = '\' then
      begin
        Dec(Text[0], 5);
        Text := Text + 'resource';
      end
      else Text := Text + ' ' + ClearedSlash(TheTree^.GetBaseName);
      MoveStr(B[1], Text, HilitColor);
    end;
    WriteLine(0, 0, Size.X, 1, B);
  end;

  if Mini then
  begin
    MoveChar(B, 'Ä', LinesColor, Size.X);
    if Status = stBrief then for I := 0 to NumCols - 1 do
      Char(B[ColWidth * (I + 1) - 1]) := 'Á'
    else if (Status = stFull) and (Settings and seLongNames = 0) then
    begin
      Char(B[ColWidth - 1]) := 'Á';
      if Options and (ofValidate + ofFilesBBS) = 0 then
      begin
        if ColWidth + 9 < MaxViewWidth then
          Char(B[ColWidth + 9]) := 'Á';
        if ColWidth + 18 < MaxViewWidth then
          Char(B[ColWidth + 18]) := 'Á';
        if InArchive and (ColWidth + 25 < MaxViewWidth) then
          Char(B[ColWidth + 25]) := 'Á';
      end;
    end;
    if not Empty and not GlobalEmptyFlag and
      (Range > 0) and (Settings and seSepSelInfo <> 0) then
    begin
      if Settings and seOldInfoBox <> 0 then
        if SelCount > 0 then
        begin
          GetInfoStr(Focused, Text, True);
          DrawInfoBox(SelInfoBoxColor, False);
        end
        else {}
      else if (SelCount > 0) and (PointedItem = nil) then
      begin
        SetDirCountsText(SelByteCount, SelFileCount);
        if Settings and seIgnoreSelection <> 0 then
        begin
          Text[1] := '{';
          Text[Length(Text)] := '}';
        end;
        if not (TagChar in [#0, #32]) then
          Text := ' ~' + TagChar + '~' + Text;
        DrawInfoBox(SelInfoBoxColor, True);
      end
      else
      begin
        SetDirCountsText(ByteCount, FileCount);
        DrawInfoBox(InfoBoxColor, True);
      end;
    end;
    WriteLine(0, Size.Y - 2, Size.X, 1, B);

    MoveChar(B, ' ', NormalColor, Size.X);
    if not Empty and not GlobalEmptyFlag and (Range > 0) then
    begin
      SelInfo := (SelCount > 0) and
        (Settings and (seSepSelInfo + seIgnoreSelection) = 0);
      GetInfoStr(Focused, Text, SelInfo);
      if SelInfo then
      begin
        TrimSt(Text);
        I := (HalfScr - 1 - CStrLen(Text)) div 2;
        if I < 0 then I := 0;
      end
      else I := 0;
      if SelInfo or (Text[1] = #0) then MoveCStr(B[I], Text, InfoColor)
      else MoveStr(B[I], Text, NormalColor);
      I := Length(Text) + 2;
      if I < 40 then I := 40;
      Params[0] := Focused + 1;
      Params[1] := Range;
      FormatStr(Text, '%d/%d', Params);
      MoveStr(B[I], Text, NormalColor);
    end;
    WriteLine(0, Size.Y - 1, Size.X, 1, B);
  end;

  if CursorPos <> -1 then
    if Empty or GlobalEmptyFlag then HideCursor
    else
    begin
      Within := Focused < TopItem + N * NumCols;
      if not Within and (State and sfCursorVis <> 0) then HideCursor
      else if Within and (State and sfCursorVis = 0) then ShowCursor;
    end
  else HideCursor;
end;

function TPanel.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else if GetShiftState and kbAltShift <> 0 then GetHelpCtx := hcAltPanel
  else if GetShiftState and kbCtrlShift <> 0 then GetHelpCtx := hcCtrlPanel
  else if Owner^.State and sfSearching <> 0 then
    if InArchive then GetHelpCtx := hcArcIncrSearch
    else GetHelpCtx := hcIncrSearch
  else if InArchive then GetHelpCtx := hcArcPanel
  else GetHelpCtx := hcPanel;
end;

procedure TPanel.FocusItem(Item: Integer);
var
  I: Integer;
  B: PPanelBar;
begin
  if Status = stQuickView then UpdateTextReaderPrim(@Self, Item);
  if Item < 0 then Item := 0
  else if Range = 0 then Item := 0
  else if Item >= Range then Item := Range - 1;
  Focused := Item;
  I := (Size.Y - Byte(State and sfMiniStatus <> 0) * 2 -
    Byte(Settings and seMaxi = 0)) * NumCols;
  if Item < TopItem then TopItem := Item
  else if Item >= TopItem + I then TopItem := Item - I + 1;
  if TopItem + I > Range then TopItem := Range - I;
  if TopItem < 0 then TopItem := 0;
  if Settings and sePanelBar <> 0 then
  begin
    if Which = pnLeft then B := PPanelBar(PPanelWindow(Owner)^.LeftBar)
    else B := PPanelBar(PPanelWindow(Owner)^.RightBar);
    if B <> nil then
    begin
      B^.AdjustBounds;
      B^.SetParams(Focused, 0, Range - 1, I - 1, 1);
    end;
  end;
  if (Status = stTree) and (FMOptions and foAutoChangeDir <> 0) then
    InitTimer(FMAutoDelay div 55 + 1, evBroadcast, cmTreeItemSelected, False)
  else if (Opposite^.Status = stQuickView) and (Status <= stTree) then
    InitTimer(FMAutoDelay div 55 + 1, evBroadcast, cmQuickView, False)
  else if (Opposite^.Status = stQuickDescr) and (Status <= stTree) then
    InitTimer(FMAutoDelay div 55 + 1, evBroadcast, cmQuickDescr, False)
  else if (Settings and seUnfold <> 0) or (Options and ofValidate <> 0) then
    PWindow(Owner)^.Frame^.DrawView;
  if Owner^.State and sfSearching <> 0 then
    PPanelWindow(Owner)^.DeactivateSearching(Opposite)
  else DrawView;
end;

function GetDiskDescriptionStr(P: PPanelRec): String;
var
  S: String;
begin
  S := GetDiskDescription(DiskClass(P^.Percent));
  if (P^.ThePath <> nil) and (P^.ThePath^[1] = #$FF) then
    S := Concat(S, ' (', Copy(P^.ThePath^, 2, 8), ')');
  GetDiskDescriptionStr := S;
end;

procedure GetLFNPanelText(var AText: String; SR: PPanelRec; TC: Char);
begin
  AddNameExt('', SR, AText);
  if SR^.Attr and Directory <> 0 then
  begin
    AText := AddedSlash(AText);
    if SR^.Attr and VolumeID = 0 then
      if (LFNOptions and loConvertNames <> 0) or
	 (((LFNOptions and loShortNamesAsIs = 0) and
	  (not PanelRecHasPath(SR) or (SR^.ThePath^[1] <> #0)))) then
	UpcaseSt(AText);
  end
  else if (LFNOptions and loConvertNames <> 0) or
    (((LFNOptions and loShortNamesAsIs = 0) and
     (not PanelRecHasPath(SR) or (SR^.ThePath^[1] <> #0)))) then
       LocaseSt(AText);
  if SR^.Selected and not (TC in [#0, #32]) then AText := AText + ' ' + TC
  else if SR^.Attr and (Hidden + SysFile) <> 0 then AText := AText + ' °';
end;

procedure TPanel.GetFullStr(Item: Integer; var AText: String);
var
  LS, LA, RA: Boolean;
  P: PFilesBBSRec;
  SR: TPanelRec;
  Time: DateTime;
  Params: Array[0..3] of Longint;
  D: String[9];
  DS, TS: String[15];
  ParamLine: String[23];
  S: String;

{ Added 2006.02.03 }
procedure LeftArrowText(var SS: String; CheckDots: Boolean);
begin
  if (Indent <> 0) and (not CheckDots or not (SR.Name[1] in [':', '.'])) then
    if SS = '' then SS := '<' else SS[1] := '<';
end;

procedure RightArrowText;
begin
  if Length(AText) > Size.X then
  begin
    AText[0] := Char(Size.X);
    AText[Length(AText)] := '>';
  end;
end;

label
  Arrow;
begin
  LS := False;
  LA := False;
  RA := False;

  SR := PPanelRec(List^.At(Item))^;

  if Settings and seLongNames <> 0 then
  begin
    if Options and ofValidate <> 0 then AText :=
      Concat(SR.Name, '    ', GetDiskDescriptionStr(@SR))
    else if SR.Name[1] in [':', '.'] then AText := SR.Name
    else
    begin
      GetLFNPanelText(S, @SR, TagChar);
      AText := System.Copy(S, Indent + 1, 255);
      LA := True;
      RA := True;
    end;
    goto Arrow;
  end;

{  if ColWidth <> 13 then Settings := Settings or seLongNames;}
  if Options and ofValidate <> 0 then AText := SR.Name
  else GetBriefStr(Item, AText);
{  Settings := Settings and not seLongNames;}
  if Length(AText) < ColWidth then AText := Pad(AText, ColWidth)
  else if Length(AText) > ColWidth then AText[0] := Char(ColWidth);
  if Options and ofValidate <> 0 then
  begin
    AText := Concat(AText, GetDiskDescriptionStr(@SR));
    Exit;
  end;

  if Options and ofFilesBBS <> 0 then
  begin
    if SR.Name[1] = ':' then S := 'Drives'
    else
    begin
      P := FilesBBS^.At(Item);
      if (P = nil) or (P^.Text = nil) then S := ''
      else
      begin
	S := System.Copy(P^.Text^, Indent + 1, 255);
	LS := True;
	RA := True;
      end;
    end;
  end
  else
  begin
    LA := True;
    ParamLine := '%9d %s %s DAHRSCE %3d';
    if SR.Attr and Directory = 0 then ParamLine[11] := '-';
    if SR.Attr and   Archive = 0 then ParamLine[12] := '-';
    if SR.Attr and    Hidden = 0 then ParamLine[13] := '-';
    if SR.Attr and  ReadOnly = 0 then ParamLine[14] := '-';
    if SR.Attr and   SysFile = 0 then ParamLine[15] := '-';
{ Added 2006.01.03 }
    if SR.HiAttr and haCompressed = 0 then ParamLine[16] := '-';
    if SR.HiAttr and  haEncrypted = 0 then ParamLine[17] := '-';

    if (SR.Attr and Directory <> 0) and
{ Added 04.29.03 to support directory size display on Space keystroke }
      (SR.Attr and faDisplaySize = 0) and
      ((Settings and seCalcDirSize = 0) or
       (SR.Name[1] in [':', '.'])) then
    begin
      ParamLine[3] := 's';
      if SR.Name[1] = ':' then
      begin
	D := 'Drives ';
	ParamLine := '%s    ';
      end
      else if SR.Attr and VolumeID <> 0 then
	if InArchive then D := 'ARCHIVE'
	else D := 'QUIT LIST'
      else if SR.Name[1] = '.' then D := 'UP--DIR'
      else D := 'SUB-DIR';
      Params[0] := Longint(@D);
    end
{ Added 04.30.03 to support size in KB }
    else
    begin
      if SR.Attr and faSizeInKB <> 0 then
      begin
	ParamLine[2] := '8';
	System.Insert('K', ParamLine, 4);
      end;
      Params[0] := SR.Size;
    end;
    UnpackTime(SR.Time, Time);
    with Time do
    begin
      DS := FormatDateStr(Year, Month, Day);
      TS := FormatTimeStr(Hour, Min, Sec);
      System.Delete(TS, 6, 3);
    end;
    Params[1] := Longint(@DS);
    Params[2] := Longint(@TS);
    if InArchive and (SR.Attr and Directory = 0) then
      Params[3] := SR.Percent
    else {if Length(ParamLine) >= 4 then} Dec(ParamLine[0], 4);
    FormatStr(S, ParamLine, Params);
  end;

  if LS then LeftArrowText(S, False);
  AText := AText + S;
Arrow:
  if LA then LeftArrowText(AText, True);
  if RA then RightArrowText;
end;

procedure TPanel.GetBriefStr(Item: Integer; var AText: String);

{ Added 2006.01.19 }
procedure IndentText;
begin
  if (Status = stFull) and (Options and ofFilesBBS = 0) then
    AText := System.Copy(AText, Indent + 1, Size.X);
end;

var
  MaxLen, I, N: Integer;
  Params: Array[0..2] of Longint;
  SR: PPanelRec;
  Ext: String[3];
  Name: String[8];
begin
  SR := List^.At(Item);

  if (Settings and seLongNames <> 0) or (ColWidth <> 13) then
  begin
    if Options and ofValidate <> 0 then AText :=
      Concat(SR^.Name, '  ', GetDiskDescriptionStr(SR))
    else if SR^.Name[1] in [':', '.'] then AText := SR^.Name
    else
    begin
      GetLFNPanelText(AText, SR, TagChar);
      IndentText;
    end;

    Dec(Item, TopItem);
    N := Size.Y - Byte(State and sfMiniStatus <> 0) * 2 -
      Byte(Settings and seMaxi = 0);
    I := Item div N + 1;
    if I < NumCols then MaxLen := ColWidth - 1
    else MaxLen := Size.X - (I - 1) * ColWidth;
    if MaxLen <= 0 then MaxLen := 1
    else if MaxLen >= ColWidth then MaxLen := ColWidth - 1;
    if Length(AText) > MaxLen then
    begin
      AText[0] := Char(MaxLen);
      if SR^.Selected and not (TagChar in [#0, #32]) then
	AText[Length(AText)] := TagChar
      else if SR^.Attr and (Hidden + SysFile) <> 0 then
	AText[Length(AText)] := '°'
      else AText[Length(AText)] := '>';
    end;
    Exit;
  end;

  Name := SR^.Name;
  Ext := SR^.Ext;
  if SR^.Attr and Directory = 0 then
  begin
    LocaseSt(Name);
    LocaseSt(Ext);
  end
  else if SR^.Attr and VolumeID = 0 then
  begin
    UpcaseSt(Name);
    UpcaseSt(Ext);
  end;
  Params[0] := Longint(@Name);
  Params[2] := Longint(@Ext);
  if SR^.Selected and not (TagChar in [#0, #32]) then
    Params[1] := Byte(TagChar)
  else if SR^.Attr and (Hidden + SysFile) <> 0 then
    Params[1] := Byte('°')
  else Params[1] := Byte(' ');
  FormatStr(AText, '%-8s%c%-3s', Params);
  if SR^.Attr and (Hidden + SysFile) <> 0 then
    AText[1] := Upcase(AText[1]);
  if not (SR^.Name[1] in [':', '.']) then IndentText;
end;

procedure TPanel.GetInfoStr(Item: Integer; var AText: String; Sel: Boolean);
const
  sSelectedLine = '%c~%s~ byte%s in ~%d~ selected file%s%c';
  sDirSelectedLine = '%c~%d~ selected director%s%c';
var
  IgnoreSel: Boolean;
  Time: DateTime;
  SR: TPanelRec;
  Params: Array[0..5] of Longint;
  D: String[9];
  DS, TS: String[15];
  ParamLine, FmtId: String[63];
  FName: FNameStr;
  S: String;

procedure SetIgnoreSelChar(EndIndex: Byte; Ignore: Boolean);
begin
  if Ignore then
  begin
    Params[0] := Byte('[');
    Params[EndIndex] := Byte(']');
  end
  else
  begin
    Params[0] := Byte(' ');
    Params[EndIndex] := Byte(' ');
  end;
end;

begin
  if Sel then
  begin
    IgnoreSel := Settings and seIgnoreSelection <> 0;
    if Options and ofValidate <> 0 then
    begin
      FmtId := '%c~%d~ selected drive%s%c';
      SetIgnoreSelChar(3, IgnoreSel);
      Params[1] := SelCount;
      if SelCount = 1 then S := '' else S := 's';
      Params[2] := Longint(@S);
      FormatStr(AText, FmtId, Params);
      Exit;
    end;
    if Status = stTree then
    begin
      FmtId := sDirSelectedLine;
      SetIgnoreSelChar(3, IgnoreSel);
      Params[1] := SelCount;
      if SelCount > 1 then S := 'ies' else S := 'y';
      Params[2] := Longint(@S);
    end
    else
    begin
      FmtId := sSelectedLine;
      SetIgnoreSelChar(5, IgnoreSel);
      FormatFloatBytes(S, SelByteCount, 10000000);
      Params[1] := Longint(@S);
      if SelByteCount = 1 then D := '' else D := 's';
      Params[2] := Longint(@D);
      Params[3] := SelCount;
      if SelCount = 1 then DS := '' else DS := 's';
      Params[4] := Longint(@DS);
    end;
  end
  else
  begin
    if Status = stTree then
    begin
      if not InArchive and (Item = 0) then
        AText := AddedSlash(TheTree^.GetDirStr(0))
      else AText := TrimmedName(TheTree^.GetDirStr(Item), Size.X);
      Exit;
    end;
    if MouseHintItem <> nil then SR := MouseHintItem^
    else SR := PPanelRec(List^.At(Item))^;
    if SR.Name[1] = ':' then
    begin
      GetListDir(AText);
      if AText[1] = '\' then AText := ' Drives'
      else
      begin
        FormatFloatBytes(S, BytesFree, 1000000000);
        AText := #0'Drives  ~' + S + '~ bytes free on ' + AText[1] + ':';
      end;
      Exit;
    end;
    if Options and ofValidate <> 0 then
    begin
      if (SR.Name[0] = #2) and (SR.Name[2] = ':') then
        AText := ' Drive ' + SR.Name + '    '
      else if not PanelRecHasPath(@SR) then AText := ' '
      else AText := ' ' + Pad(PanelRecPath(@SR), 10) + '  ';
      AText := AText + GetDiskDescriptionStr(@SR);
      Exit;
    end;
    ParamLine := '%-12s %9d %s %s %3d'#0;
    if (Status <= stFull) and
       ((Settings and seLongNames <> 0) or (ColWidth <> 13)) and
       PanelRecHasPath(@SR) and (SR.ThePath^[1] = #0) then
    begin
      FName := SR.Name;
      if SR.Ext <> '' then FName := FName + '.' + SR.Ext;
    end
    else
    begin
      AddNameExt('', @SR, FName);
      if (Status = stFull) and (Settings and seLongNames = 0) and
         (ColWidth = 13) and (Options and ofFilesBBS = 0) and
         (Length(FName) > 12) then
      begin
        AText := TrimmedName(FName, Size.X);
	Exit;
      end;
    end;
    Params[0] := Longint(@FName);
    if (SR.Attr and Directory <> 0) and
{ Added 04.29.03 to support directory size display on Space keystroke }
       (SR.Attr and faDisplaySize = 0) and
       ((Settings and seCalcDirSize = 0) or
	(SR.Name[1] in ['.', ':'])) then
    begin
      ParamLine[9] := 's';
      if SR.Attr and VolumeID <> 0 then
	if InArchive then D := 'ARCHIVE'
	else D := 'QUIT LIST'
      else if SR.Name[1] = '.' then D := 'UP--DIR'
      else D := 'SUB-DIR';
      Params[1] := Longint(@D);
    end
{ Added 04.30.03 to support size in KB }
    else
    begin
      if SR.Attr and faSizeInKB <> 0 then
      begin
        ParamLine[8] := '8';
        System.Insert('K', ParamLine, 10);
      end;
      Params[1] := SR.Size;
    end;
    UnpackTime(SR.Time, Time);
    with Time do
    begin
      DS := FormatDateStr(Year, Month, Day);
      TS := FormatTimeStr(Hour, Min, Sec);
      System.Delete(TS, 6, 3);
    end;
    Params[2] := Longint(@DS);
    Params[3] := Longint(@TS);
    if InArchive and (SR.Attr and Directory = 0) then
      Params[4] := SR.Percent
    else Dec(ParamLine[0], 5);
    FmtId := ParamLine;
  end;
  FormatStr(AText, FmtId, Params);
  if SR.Attr and (Hidden + SysFile) <> 0 then
    AText[1] := Upcase(AText[1]);
  if InArchive and (SR.Attr and Directory = 0) and
    (AText[Length(AText)] = #0) then AText[Length(AText)] := '%';
end;

procedure TPanel.GetQuickInfoStr(var AText: String);
var
  L: Longint;
  SR: PPanelRec;
  R, S: Real;
  NS, SS, PS: FNameStr;
begin
  SR := Opposite^.List^.At(Opposite^.Focused);
  if (SR = nil) or (SR^.Attr and Directory <> 0) then AText := ''
  else
  begin
    AddNameExt('', SR, NS);
    NS := TrimmedName(NS, Size.X);
    FormatFloatBytes(SS, lGetFileRealSize(SR^.Attr, SR^.Size), 1000000000);
    if QuickStatus and qsPercent = 0 then PS := ''
    else
    begin
      L := TextReader^.SourceSize;
      if L = -1 then
        if (Range = 0) or ((Range = 1) and (Focused = 0)) then L := 100
        else if Focused = 0 then L := 0
        else
        begin
          S := Range;
          R := Focused + 1;
          R := R * 100 / S;
          L := Trunc(R);
        end
      else if (L = 0) or ((L = TextReader^.BufEnd) and
        (Focused >= TextReader^.Buffer^.Count - 1)) then L := 100
      else
      begin
        S := L;
        L := Longint(TextReader^.PosBuffer^.At(Focused));
        R := L;
        R := R * 100 / S;
        L := Trunc(R);
      end;
      FormatStr(PS, '%3d', L);
    end;
    PadSt(NS, 14);
    SS := LeftPad(SS, 12);
    PadSt(SS, 20);
    AText := NS + SS;
    if PS <> '' then AText := AText + PS + '%';
  end;
end;

procedure TPanel.GetQuickDescrStr(var AText: String);
var
  SR: PPanelRec;
begin
  SR := Opposite^.List^.At(Opposite^.Focused);
  if SR = nil then AText := ''
  else
  begin
    Opposite^.GetRecStr(SR, AText);
    AText := TrimmedName(AText, Size.X);
  end;
end;

procedure TPanel.GetListDir(var ADir: String);
begin
  if Status = stTree then ADir := TheTree^.GetDirStr(Focused)
  else if InArchive then ADir := Archiver^.ArcDir^
  else ADir := ListDir^;
end;

procedure TPanel.GetItemNum(const AName: FNameStr; var Index: Integer);
label
  FullName;
begin
  if Status >= stInfo then Index := 0
  else if Status = stTree then
    Index := TheTree^.GetDirNum(AName, 0, Focused)
  else if Options and ofValidate <> 0 then
    if (AName[0] = #2) and (AName[2] = ':') then
      SearchDrive(AName[1], Index)
    else Goto FullName
  else if (AName = ListDir^) or
    (UCPos(AddedSlash(ListDir^), AName) = 0) then Index := 0
  else
  begin
FullName:
    FindFullName(AName, Index);
    if Index = -1 then Index := Focused;
  end;
end;

procedure TPanel.GetRecFullName(P: PPanelRec; var S: FNameStr);
begin
  if Options and ofValidate <> 0 then
    if PanelRecHasPath(P) then S := PanelRecPath(P) else S := P^.Name
  else
  begin
    GetListDir(S);
    if P^.Name[1] in ['.', ':'] then Exit;
    if PanelRecHasPath(P) then
    begin
      S := S + '\' + PanelRecPath(P);
      if S[Length(S)] = '\' then Dec(S[0]);
    end;
    AddNameExt(S + '\', P, S);
  end;
end;

procedure TPanel.GetItemStr(Index: Integer; var S: FNameStr);
var
  P: PPanelRec;
begin
  if Status >= stInfo then S := ''
  else if Status = stTree then S := TheTree^.GetDirStr(Index)
  else if (Index < 0) or (Index > List^.Count - 1) then S := ''
  else
  begin
    P := List^.At(Index);
    GetRecFullName(P, S);
  end;
end;

procedure TPanel.GetRecStr(P: PPanelRec; var S: FNameStr);
begin
  if Status >= stInfo then S := ''
  else if Status = stTree then S := TheTree^.GetRecStr(P)
  else GetRecFullName(P, S);
end;

function TPanel.GetText(Item: Integer; MaxLen: Integer): String;
var
  S: String;
begin
  if Status = stFull then GetFullStr(Item, S)
  else if Status = stBrief then GetBriefStr(Item, S)
  else if Status = stTree then S := TheTree^.GetItemStr(
    Item, ClearedSlash(PPanelWindow(Owner)^.Prompt^.Text^), True);
  GetText := S;
end;

procedure TPanel.HandleEvent(var Event: TEvent);
var
  B: Boolean;
  I: Integer;
  Mouse: TPoint;
  P: PPanelRec;
  S: String;

function PathWithin(const APath: FNameStr): Boolean;
begin
  if InArchive then PathWithin := False
  else if Status = stTree then PathWithin := APath[1] = ListDir^[1]
  else PathWithin := (CompUCString(APath, ListDir^) = Equal) or
    ((Settings and seUnfold <> 0) and
     (UCPos(AddedSlash(ListDir^), AddedSlash(APath)) <> 0));
end;

function HandleKey: Boolean;
begin
  HandleKey := False;
  case Event.KeyCode of
    kbBack:
      begin
        HandleKey := Owner^.State and sfSearching = 0;
        Exit;
      end;
    kbAltParen, kbCtrlEnter, $240A {^J    Fixed 11.03.93 }:
      AddFocused(Event.KeyCode = kbAltParen, Event.KeyCode = $240A);
    kbShiftF2: EditFilesBBSPrim(@Self);
    kbAltI: ToggleIgnoreSelection;
    kbAltColon: ToggleDrivePanel;
    kbAltQuote: ToggleSepSelInfo;
    kbAltB: PanelPerformPrim(@Self, paToggleUnfold);
    kbAltA: NewArchiverPrim(@Self);
    kbAltV: ReadFileListPrim(@Self, '');
    kbCtrlUp:
      if InArchive then OutOfArchive(@Self)
      else if Settings and seList <> 0 then OutOfFileListPrim(@Self);
    kbAltH: SaveFocusedNamePrim(@Self);
    kbCtrlDel: FMDeleteItemsPrim(@Self);
    kbCtrl2: if Status = stQuickView then ToggleQuickView
      else Opposite^.ToggleQuickView;
    kbAltG: FMSetIndexAndColorPrim(@Self);
    kbAltJ: ToggleDriveSelector;
    kbDel: if FMOptions and foDelErasesFiles <> 0 then
      FMDeletePrim(@Self, False);
    kbShiftF11: if Status < stTree then
      begin
        SortSel := not SortSel;
        SortSelPrim(@Self);
      end;
    else Exit;
  end;
  Event.What := evNothing;
  HandleKey := True;
end;

begin
  TView.HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    if HandleKey then Exit;
    if Event.CharCode = #0 then
    begin
      Scroll(Event);
      if Event.What = evNothing then Exit;
    end;
    if (Event.ScanCode = 0) and (Event.CharCode in [#1..#9]) then
    begin
      AltNumpadHistoryPrim(@Self, Byte(Event.CharCode) + $30);
      Event.What := evNothing;
      Exit;
    end;
    if (FMOptions and foCapsLockSearch <> 0) and
       (Mem[Seg0040:$18] and kbCapsState <> 0) and
       (Event.CharCode in [#32..#42, #44..#255]) then
    begin
      if Owner^.State and sfSearching = 0 then
      begin
        Mem[Seg0040:$17] := Mem[Seg0040:$17] xor kbCapsState;
        PPanelWindow(Owner)^.ActivateSearching;
      end;
      if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
        Event.CharCode := Upcase(Event.CharCode)
      else Event.CharCode := Locase(Event.CharCode);
    end;
    if (Owner^.State and sfSearching <> 0) and
       (Event.CharCode in [^B, ^L, #8, #32..#42, #44..#255]) then
      FocusCharPrim(@Self, Event.CharCode)
    else case Event.CharCode of
      ^A: FileAttributesPrim(@Self);
      ^B: Brief;
      ^C: CompareDirsPrim(@Self);
      ^D: QuickDescr;
      ^F: Full;
      ^G: SelectGroupPrim(@Self, True);
      ^H: ToggleHidden;
      ^I: Info;
      ^K: ToggleMiniStatus;
      ^L: if Status = stInfo then ToggleInfo(True)
          else Opposite^.ToggleInfo(True);
      ^M: ItemSelectedPrim(@Self, Focused);
      ^N: FilterDialogPrim(@Self);
      ^P: ToggleFilesBBS;
      ^R: if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
            ReReadAll
          else ReRead(True);
      ^S: SortDialogPrim(@Self);
      ^T: Tree;
      ^U: SwapPanelsPrim(@Self);
      ^V: ExtDialog(True);
      ^W: DirHistoryPrim(@Self);
      ^X: ExtDialog(False);
      ^Z: ToggleExOnly;
      ^\: RootDir;
     '': ToggleCalcDirSize;
     '': QuickView;
      else Exit;
    end;
    Event.What := evNothing;
    Exit;
  end;
  if (Event.What = evMouseMove) and (Status <= stTree) then
  begin
    B := GetShiftState and (kbAltShift + kbCtrlShift) =
      kbAltShift + kbCtrlShift;
    if B then
    begin
      MakeLocal(Event.Where, Mouse);
      P := GetPointedItemPrim(@Self, Mouse);
    end
    else P := nil;
    if B or PPanelWindow(Owner)^.MouseHintVisible or (P <> PointedItem) then
    begin
      PointedItem := P;
      DrawView;
      PPanelWindow(Owner)^.DrawView;
    end;
  end;
  if Event.What = evMouseDown then
    PanelHandleMouseDownEventPrim(@Self, Event);
  if Event.What = evCommand then
  begin
    CopyLeft := (Which = pnRight) and (FMOptions and foCopyLeft <> 0);
    case Event.Command of
      cmFind, cmFindFileDlg: FindFileDlgPrim(@Self);
      cmSelectGroup: SelectGroupPrim(@Self, True);
      cmUnselectGroup:
        if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
           (GetShiftState and (kbAltShift + kbCtrlShift) = 0) then
          ClearSelectionList
        else SelectGroupPrim(@Self, False);
      cmChange: ChangeTreeLevelPrim(@Self, False, True);
      cmInvert: InvertPrim(@Self);
      cmRestoreSelection: RestoreSelectionPrim(@Self);
      cmReRead:
        if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
          ReReadAll
        else ReRead(True);
      cmFSort: SortDialogPrim(@Self);
      cmFilter: FilterDialogPrim(@Self);
      cmSwapPanels: SwapPanelsPrim(@Self);
      cmFAttributes: FileAttributesPrim(@Self);
      cmCompareDirs: CompareDirsPrim(@Self);
      cmBrief: Brief;
      cmFull: Full;
      cmTree: Tree;
      cmInfo: Info;
      cmQuickView: QuickView;
      cmQuickDescr: QuickDescr;
      cmExecOptions: ExecOptionsPrim(@Self);
      cmDirHistory: DirHistoryPrim(@Self);
      cmPromptHistory: GetHistoryStrPrim(PPanelWindow(Owner)^.PromptLine);
      cmPanelSettings: SettingsDialogPrim(@Self);
      cmExtensions: ExtDialog(False);
      cmViewers: ExtDialog(True);
      cmZip..cmRaW: ArchiverDialog(
        ConfigPath + ArchiverName, Event.Command - cmNoArc - 1);
      cmUserArchivers: UserArchiverDialog(ConfigPath + UserArchiverName);
      cmFView, cmFAltView,
      cmFShiftView, cmFCtrlView: FMViewPrim(@Self, Event.Command);
      cmToggleHidden: ToggleHidden;
      cmToggleExOnly: ToggleExOnly;
      cmToggleMiniStatus: ToggleMiniStatus;
      cmToggleDrivePanel: ToggleDrivePanel;
      cmDriveSelector: ToggleDriveSelector;
      cmFilesBBS: ToggleFilesBBS;
      cmCalcDirSize: ToggleCalcDirSize;
      cmIgnoreSelection: ToggleIgnoreSelection;
      cmSepSelInfo: ToggleSepSelInfo;
      cmToggleUnfold: PanelPerformPrim(@Self, paToggleUnfold);
      cmSaveFocusedName: SaveFocusedNamePrim(@Self);
      cmClearSelection: ClearSelectionList;
      cmIsASCII, cmIsHex: FMOpenPrim(@Self, Event.Command);
      cmCopy: ClipCopyPrim(@Self);
      cmPaste: ClipPastePrim(@Self, False);
      cmCut: ClipPastePrim(@Self, True);
      cmClear: FMDeleteItemsPrim(@Self);
      cmFCopy, cmFCtrlCopy:
        FMCopyPrim(@Self, '', Event.Command = cmFCtrlCopy);
      cmArcCopyDlg: CopyToArcDlg(@Self, Event.InfoPtr);
      cmFRenMov, cmFCtrlRenMov: FMRenMovPrim(@Self, '',
        Event.Command = cmFCtrlRenMov);
      cmFMkDir, cmShiftMkDir:
        FMMkDirPrim(@Self, Event.Command = cmShiftMkDir);
      cmFDelete, cmFCtrlDelete: FMDeletePrim(@Self,
        Event.Command = cmFCtrlDelete);
      cmShiftCopy: ShiftCopyPrim(@Self);
      cmShiftRenMov: ShiftRenMovPrim(@Self);
      cmShiftDelete: ShiftDeletePrim(@Self);
      cmChangeDirectory: ChangeDir;
      cmOpenArchive: NewArchiverPrim(@Self);
      cmPassword: if InArchive then Archiver^.SetPassword;
      cmTest: if InArchive then Archiver^.TestPrim;
      cmExtract: if InArchive then Archiver^.ExtractPrim;
      cmReadFileList:
        begin
          if Event.InfoPtr = nil then S := ''
          else S := PString(Event.InfoPtr)^;
          ReadFileListPrim(@Self, S);
        end;
      cmPopUp:
        begin
          if Which = pnLeft then Mouse.X := 1 else Mouse.X := 70;
          Mouse.Y := 2;
          PopupPrim(@Self, Mouse);
        end;
      else Exit;
    end;
    Event.What := evNothing;
    Exit;
  end;
  if Event.What = evBroadcast then
  case Event.Command of
    cmGetSource, cmGetLine: if (Owner^.State and sfVisible <> 0) and
      (State and sfSelected <> 0) and (Status <> stInfo) then
      begin
        Event.What := evNothing;
        GetSource(S);
        Event.InfoPtr := @S;
      end;
    cmGetOppSource: if (Owner^.State and sfVisible <> 0) and
      (State and sfSelected <> 0) and
      (Opposite^.State and sfVisible <> 0) and
      (Opposite^.Status <> stInfo) then
      begin
        Event.What := evNothing;
        Opposite^.GetSource(S);
        Event.InfoPtr := @S;
      end;
    cmGetDest: if (Owner^.State and sfVisible <> 0) and
      (State and sfVisible <> 0) and (Status < stInfo) and
      (MouseInView(PPoint(Event.InfoPtr)^) or
       MouseInViewPrim(@Self, PPoint(Event.InfoPtr)^)) then
      begin
        GetDestPrim(@Self, S, PPoint(Event.InfoPtr)^);
        Event.What := evNothing;
        Event.InfoPtr := @S;
      end;
    cmGetLeftPath: if (Owner^.State and sfVisible <> 0) and
      (Which = pnLeft) then
      begin
        Event.What := evNothing;
        Event.InfoPtr := ListDir;
      end;
    cmGetRightPath: if (Owner^.State and sfVisible <> 0) and
      (Which = pnRight) then
      begin
        Event.What := evNothing;
        Event.InfoPtr := ListDir;
      end;
    cmGetOppositePath: if (Owner^.State and sfVisible <> 0) and
      (State and sfSelected <> 0) then
      begin
        Event.What := evNothing;
        Event.InfoPtr := Opposite^.ListDir;
      end;
    cmGetArcDir: if (Owner^.State and sfVisible <> 0) and
      (Status < stInfo) and InArchive then
      begin
        Event.What := evNothing;
        S := System.Copy(
          Archiver^.ArcDir^, Length(Archiver^.ArcName^) + 2, 255);
        Event.InfoPtr := @S;
      end;
    cmReRead:
      if ((Status <> stInfo) or (Opposite^.Status = stInfo)) and
         ((Event.InfoPtr = nil) or PathWithin(PString(Event.InfoPtr)^)) then
        ReReadPrim(False);
    cmSwitchToDir:
      begin
        S := Char(Event.InfoPtr^) + ':';
        SwitchToDir(S, True);
        Event.What := evNothing;
      end;
    cmReopen: if (Event.InfoPtr <> nil) and (State and sfSelected <> 0) and
      (State and sfVisible <> 0) and (Owner^.State and sfVisible <> 0) then
      begin
        S := lFExpand(PString(Event.InfoPtr)^);
        if (Status > stTree) or (CompUCString(
          ClearedSlash(JustPathName(S)), ListDir^) <> Equal) then
            SwitchToDir(JustPathName(S), False);
        if Status < stTree then GetItemNum(S, I)
        else GetItemNum(JustPathName(S), I);
        FocusItem(I);
        Owner^.Select;
        ClearEvent(Event);
      end;
    cmGroups: ReReadPrim(True);
    cmDiskChanged: if not DiskChanged then
      begin
        S := PString(Event.InfoPtr)^;
        while (S <> '') and (S[Length(S)] <> '\') do Dec(S[0]);
        if S <> '' then Dec(S[0]);
        if PathWithin(S) then DiskChanged := True;
      end;
    cmUpdateDisk:
      begin
        if DiskChanged or (FMAutoRereadOptions = faAlways) then
          ReReadPrim(False)
        else if Status < stTree then FocusItem(Focused);
        LastDiskName := '';
        LastRenMovName := '';
      end;
    cmSaveSelected, cmLSaveSelected:
      if (Owner^.State and sfVisible <> 0) and
         (Status < stInfo) and (SelCount > 0) and
         (Settings and seIgnoreSelection = 0) and
         (Event.InfoPtr <> nil) then
        AppendSelListPrim(@Self, PString(Event.InfoPtr)^, '', '',
          Event.Command = cmLSaveSelected, False, True);
    cmNoArc: if InArchive then
      if Archiver^.ArcId >= avUsr then ReReadPrim(False)
      else
      begin
        if Archiver^.Prev <> nil then Archiver^.Prev^.GetArchiveRec;
        Archiver^.GetArchiveRec;
        PWindow(Owner)^.Frame^.DrawView;
      end;
    cmUserArchivers: if (Owner^.State and sfVisible <> 0) and
      (State and sfSelected <> 0) and InArchive and
      (Archiver^.ArcId >= avUsr) then
      begin
        Event.What := evNothing;
        Event.InfoPtr := Archiver^.ArcName;
      end;
    cmTreeItemSelected: if Status = stTree then
      begin
        TreeItemSelectedPrim(@Self, Focused);
        Event.What := evNothing;
      end;
    cmQuickView: if (Status = stQuickView) and
      (Opposite^.Status <= stTree) then
      begin
        NewDir(ListDir^, True);
        Event.What := evNothing;
      end;
    cmQuickDescr: if (Status = stQuickDescr) and
      (Opposite^.Status <= stTree) then
      begin
        NewDir(ListDir^, True);
        Event.What := evNothing;
      end;
    cmBBSOptChanged: if Opposite^.Status = stQuickDescr then
      begin
        FocusItem(Focused);
        Event.What := evNothing;
      end;
    cmGetWord:
      if (AltHelpName <> '') and (Owner^.State and sfVisible <> 0) and
         (Status < stTree) and (State and sfSelected <> 0) and
         (Options and ofValidate = 0) and (List^.Count <> 0) then
      begin
        Event.What := evNothing;
        S := PPanelRec(List^.At(Focused))^.Name;
        if (S = '') or (S[1] in ['\', ':', '.']) then Event.InfoPtr := nil
        else Event.InfoPtr := @S;
      end;
    cmClearSelection:
      begin
        UnselectAll;
        FocusItem(Focused);
      end;
    cmFilter: if (Owner^.State and sfVisible <> 0) and
      (State and sfSelected <> 0) then
      begin
        S := PString(Event.InfoPtr)^;
        ReadAdvancedFilterPrim(@Self, S);
        Event.What := evNothing;
      end;
    cmFMViewPrev, cmFMViewNext: if (Event.InfoPtr <> nil) and
      (State and sfSelected <> 0) and (State and sfVisible <> 0) and
      (Owner^.State and sfVisible <> 0) and (Status <= stFull) then
        FMViewNextPrim(@Self, Event);
    cmExtractByName: if (Event.InfoPtr <> nil) and
      (State and sfSelected <> 0) and (State and sfVisible <> 0) and
      (Owner^.State and sfVisible <> 0) and InArchive then
      begin
        Event.What := evNothing;
        Event.InfoPtr := Archiver^.ExtractByName(PString(Event.InfoPtr)^);
      end;
    cmTagChar: if (Status < stTree) and (SelCount <> 0) then
      FocusItem(Focused);
    cmlAPIChanged: ReReadOnlAPIChange(Event.InfoByte);
  end;
end;

procedure TPanel.SetState(AState: Word; Enable: Boolean);
const
  FMCommands = [cmCut, cmCopy, cmPaste, cmClear, cmFind, cmIncSearch];
var
  B: PPanelBar;
  S: String;
begin
  TView.SetState(AState, Enable);
  if AState and (sfActive + sfSelected + sfDragging) <> 0 then DrawView;
  if Settings and sePanelBar <> 0 then
    if Which = pnLeft then B := PPanelBar(PPanelWindow(Owner)^.LeftBar)
    else B := PPanelBar(PPanelWindow(Owner)^.RightBar)
  else B := nil;
  if Enable then
    if AState and (sfFocused + sfSelected) <> 0 then
    begin
      PPanelWindow(Owner)^.SetCurrentPanel(@Self);
      if B <> nil then B^.Show;
      if AState = sfFocused then
        if Status < stInfo then EnableCommands(FMCommands + MTCommands)
        else EnableCommands(CopyCommands + MTCopyCommands);
    end
    else if (AState = sfExposed) and (Settings and seBarAlways <> 0) and
      (B <> nil) then B^.Show else
  else if ((AState and (sfActive + sfSelected) <> 0) and
    GetState(sfExposed)) or (AState = sfExposed) then
  begin
    if ((AState = sfExposed) or (Settings and seBarAlways = 0)) and
       (B <> nil) then B^.Hide;
    if AState <> sfActive then DisableCommands(FMCommands + MTCommands);
  end;
  if GetState(sfVisible) then ToggleMask := tmVis;
  if Enable and GetState(sfExposed) and (AState = sfSelected) then
    if Status < stTree then
    begin
      S := ListDir^;
      Message(Owner, evBroadcast, cmNewPrompt, @S);
    end
    else PWindow(Owner)^.Frame^.DrawView;
end;

procedure TPanel.Store(var S: TStream);

function IsFileManager(P: PView): Boolean; far;
begin
  IsFileManager := (P^.State and sfVisible <> 0) and
    (TypeOf(P^) = TypeOf(TPanelWindow));
end;

var
  SaveList: PCollection;
  Name: FNameStr;
begin
  SaveList := List;
  List := FoundFiles;
  TListBox.Store(S);
  List := SaveList;
  if (FMOptions and foLoadCurDir <> 0) and
     ((Owner^.State and (sfActive + sfSelected) = sfActive + sfSelected) or
      (Desktop^.FirstThat(@IsFileManager) = Pointer(Owner))) then
  begin
    PPanelWindow(Owner)^.GetCurrentPanel;
    if PPanelWindow(Owner)^.CurrentPanel = @Self then S.WriteStr(nil)
    else S.WriteStr(ListDir);
  end
  else S.WriteStr(ListDir);
  if InArchive then Name := Archiver^.GetTopName
  else GetItemStr(Focused, Name);
{
  DisposeStr(FocusedName);
  FocusedName := NewStr(Name);
}
  DisposeStrUMB(FocusedName);
  FocusedName := NewStrUMB(Name);
  S.WriteStr(FocusedName);
  S.Write(Which, SizeOf(Which) + SizeOf(Status) + SizeOf(OldStatus) +
    SizeOf(OldFocused) + SizeOf(Indent) + SizeOf(Settings) +
    SizeOf(SortDescrPos) + SizeOf(SortCaseSens) + SizeOf(FoundFocused) +
    SizeOf(SortMode) + SizeOf(SortDirection) + SizeOf(SortPriority) +
    SizeOf(GroupOptions) + SizeOf(SortAction) + SizeOf(ToggleMask) +
    SizeOf(SortSel) + SizeOf(TimeMode) + SizeOf(IgnoreListSpaces) +
    SizeOf(DrvSelAlignment) + SizeOf(DrvSelSize) + SizeOf(ColWidth) +
    SizeOf(BarAlignment) + SizeOf(Filter) + SizeOf(Main) * 3);
  if Settings and seList <> 0 then
  begin
    S.WriteStr(FileListName);
    S.WriteStr(SaveListDir);
  end;
  if Settings and seAdvancedFilter <> 0 then
  begin
    S.WriteStr(AdvancedFilter.Text);
    S.Write(AdvancedFilter.Unix, SizeOf(Boolean) +
      SizeOf(Longint) * 4 + SizeOf(Byte) + SizeOf(Pointer));
  end;
  Reserved1 := SortIndexSign;
  S.Write(Reserved1, SizeOf(Word));
  S.WriteStr(SortIndexStr);
  S.Write(Reserved2, SizeOf(Word));
end;

function TPanel.GetMouseShape(var Event: TEvent): Char;
var
  Mini, Maxi: Boolean;
  C: Char;
  P: TPoint;
begin
  C := Inherited GetMouseShape(Event);
  if (State and (sfActive + sfSelected) = sfActive + sfSelected) and
     (State and sfFocused <> 0) then
  begin
    Mini := State and sfMiniStatus <> 0;
    Maxi := Settings and seMaxi <> 0;
    MakeLocal(Event.Where, P);
    if (P.Y < Size.Y - Byte(Mini) * 2) and
       (((Status = stBrief) and ((P.X + 1) mod ColWidth = 0)) or
        ((Status = stFull) and (Settings and seLongNames = 0) and
         (P.X + 1 = ColWidth))) then C := ''
    else if Status <> stInfo then
      if not Maxi and (P.Y < 1) and (Focused > 0) then C := ''
      else if Mini and (P.Y >= Size.Y - 2) and
        (Focused < Range - 1) then C := '';
  end;
  GetMouseShape := C;
end;

procedure TPanel.InitLists;
begin
  TheTree := New(PTreeCollection, Init(64, 64));
  Dirinfo := New(PStringsCollection, Init(16, 16));
  FilesBBS := New(PFilesBBSList, Init(16, 16));
end;

procedure TPanel.DoneLists;
begin
  if FilesBBS <> nil then Dispose(FilesBBS, Done);
  if Dirinfo <> nil then Dispose(Dirinfo, Done);
  if TheTree <> nil then Dispose(TheTree, Done);
end;

procedure TPanel.InitFiles;
begin
  Files := New(PPanelCollection, Init(16, 16, @Self));
  if Status = stTree then List := TheTree else List := Files;
end;

procedure TPanel.DoneFiles;
begin
  if Files <> nil then Dispose(Files, Done);
end;

procedure TPanel.InitFoundFiles;
begin
  FoundFiles := New(PFindFileCollection, Init(16, 16));
end;

procedure TPanel.DoneFoundFiles;
begin
  if FoundFiles <> nil then Dispose(FoundFiles, Done);
end;

procedure TPanel.InitSelList;
begin
  SelList := New(PTagList, Init(16, 16));
end;

procedure TPanel.DoneSelList;
begin
  if SelList <> nil then Dispose(SelList, Done);
end;

procedure TPanel.InitCRCList;
begin
  CRCList := New(PTagList, Init(16, 16));
end;

procedure TPanel.DoneCRCList;
begin
  if CRCList <> nil then
  begin
    Dispose(CRCList, Done);
    CRCList := nil;
  end;
end;

procedure TPanel.InitTextReader;
begin
  New(TextReader, Init);
end;

procedure TPanel.DoneTextReader;
begin
  Dispose(TextReader, Done);
  TextReader := nil;
end;

procedure TPanel.InitDescrData;
begin
  GetMem(DescrData, SizeOf(TDescrData));
end;

procedure TPanel.DoneDescrData;
begin
  FreeMem(DescrData, SizeOf(TDescrData));
  DescrData := nil;
end;

procedure TPanel.InitDriveSelector;
var
  P: PDriveSelector;
  R: TRect;
begin
  GetBounds(R);
  Inc(R.B.Y); R.A.Y := R.B.Y - 1;
  P := New(PDriveSelector, Init(R, @Self));
  Owner^.Insert(P);
  if Which = pnLeft then PPanelWindow(Owner)^.LeftSelector := P
  else PPanelWindow(Owner)^.RightSelector := P;
end;

procedure TPanel.DoneDriveSelector;
begin
  if Which = pnLeft then
    if PPanelWindow(Owner)^.LeftSelector <> nil then
    begin
      Dispose(PPanelWindow(Owner)^.LeftSelector, Done);
      PPanelWindow(Owner)^.LeftSelector := nil;
    end else
  else
    if PPanelWindow(Owner)^.RightSelector <> nil then
    begin
      Dispose(PPanelWindow(Owner)^.RightSelector, Done);
      PPanelWindow(Owner)^.RightSelector := nil;
    end;
end;

procedure TPanel.InitPanelBar;
var
  P: PPanelBar;
  R: TRect;
begin
  GetBounds(R);
  R.B.X := R.A.X + 1;
  P := New(PPanelBar, Init(R));
  P^.Panel := @Self;
  P^.AdjustBounds;
  Owner^.Insert(P);
  if Which = pnLeft then PPanelWindow(Owner)^.LeftBar := P
  else PPanelWindow(Owner)^.RightBar := P;
end;

procedure TPanel.DonePanelBar;
begin
  if Which = pnLeft then
    if PPanelWindow(Owner)^.LeftBar <> nil then
    begin
      Dispose(PPanelWindow(Owner)^.LeftBar, Done);
      PPanelWindow(Owner)^.LeftBar := nil;
    end else
  else
    if PPanelWindow(Owner)^.RightBar <> nil then
    begin
      Dispose(PPanelWindow(Owner)^.RightBar, Done);
      PPanelWindow(Owner)^.RightBar := nil;
    end;
end;

procedure TPanel.SetColumns;
begin
  if Status <> stBrief then NumCols := 1
  else NumCols := (Size.X - 1) div ColWidth + 1;
end;

procedure TPanel.Scroll(var Event: TEvent);
begin
  case CtrlToArrow(Event.KeyCode) of
    kbDown:      GoDown;
    kbUp:        GoUp;
    kbRight:     GoRight;
    kbLeft:      GoLeft;
    kbPgDn:      GoPgDn;
    kbPgUp:      GoPgUp;
    kbCtrlPgDn:  GoCtrlPgDn;
    kbCtrlPgUp:  GoCtrlPgUp;
    kbHome:      GoHome;
    kbEnd:       GoEnd;
    kbCtrlHome:  PanelPerformPrim(@Self, paGoCtrlHome);
    kbCtrlEnd:   PanelPerformPrim(@Self, paGoCtrlEnd);
    kbIns:       SelectFocused;
{ Added 04.29.03 to support directory size display on Space keystroke }
    kbSpaceSel:  SpaceSelectFocusedPrim(@Self);
    kbCtrlLeft,
    kbCtrlRight: Opposite^.Select;
    else Exit;
  end;
  Event.What := evNothing;
end;

procedure TPanel.GoRight;
var
  I, N: Integer;
begin
  if Status = stBrief then
  begin
    N := Focused + (Size.Y - Byte(State and sfMiniStatus <> 0) * 2 -
      Byte(Settings and seMaxi = 0));
    if N >= Range then N := Range - 1;
    if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
      for I := Focused to N - 1 do SetSelect(List^.At(I), True);
    FocusItem(N);
  end
  else PanelPerformPrim(@Self, paGoRight);
end;

procedure TPanel.GoLeft;
var
  I, N: Integer;
begin
  if Status = stBrief then
  begin
    N := Focused - (Size.Y - Byte(State and sfMiniStatus <> 0) * 2 -
      Byte(Settings and seMaxi = 0));
    if N < 0 then N := -1;
    if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
      for I := N + 1 to Focused do SetSelect(List^.At(I), False);
    FocusItem(N);
  end
  else PanelPerformPrim(@Self, paGoLeft);
end;

procedure TPanel.GoWhileKeyDown(Key: Byte);
var
  N: Integer;
begin
  repeat
    if (KbdStatus <> Key) and (KbdStatus <> 224) then Exit;
  until KeyPressed;
  repeat
    ClearKbd;
    if (KbdStatus <> Key) and (KbdStatus <> 224) then Exit;
    case Key of
      72: FocusItem(Focused - 1);
      73:
        begin
          N := Focused - (Size.Y - Byte(State and sfMiniStatus <> 0) * 2 -
            Byte(Settings and seMaxi = 0)) * NumCols;
          FocusItem(N);
        end;
      80: FocusItem(Focused + 1);
      81:
        begin
          N := Focused + (Size.Y - Byte(State and sfMiniStatus <> 0) * 2 -
            Byte(Settings and seMaxi = 0)) * NumCols;
          FocusItem(N);
        end;
    end;
    if KbdDelay <> 0 then Delay(KbdDelay);
  until False;
end;

procedure TPanel.GoDown;
begin
  if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
     (Status < stInfo) then
  begin
    SetSelect(List^.At(Focused), True);
    FocusItem(Focused + 1);
    Exit;
  end;
  FocusItem(Focused + 1);
  if (KbdStatus = 80) or (KbdStatus = 224) then GoWhileKeyDown(80);
end;

procedure TPanel.GoUp;
begin
  if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
     (Status < stInfo) then
  begin
    SetSelect(List^.At(Focused), False);
    FocusItem(Focused - 1);
    Exit;
  end;
  FocusItem(Focused - 1);
  if (KbdStatus = 72) or (KbdStatus = 224) then GoWhileKeyDown(72);
end;

procedure TPanel.GoPgDn;
var
  I, N: Integer;
begin
  N := Focused + (Size.Y - Byte(State and sfMiniStatus <> 0) * 2 -
    Byte(Settings and seMaxi = 0)) * NumCols;
  if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
     (Status < stInfo) then
  begin
    for I := Focused to N - 1 do SetSelect(List^.At(I), True);
    FocusItem(N);
    Exit;
  end;
  FocusItem(N);
  if (KbdStatus = 81) or (KbdStatus = 224) then GoWhileKeyDown(81);
end;

procedure TPanel.GoPgUp;
var
  I, N: Integer;
begin
  N := Focused - (Size.Y - Byte(State and sfMiniStatus <> 0) * 2 -
    Byte(Settings and seMaxi = 0)) * NumCols;
  if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
     (Status < stInfo) then
  begin
    for I := N + 1 to Focused do SetSelect(List^.At(I), False);
    FocusItem(N);
    Exit;
  end;
  FocusItem(N);
  if (KbdStatus = 73) or (KbdStatus = 224) then GoWhileKeyDown(73);
end;

procedure TPanel.GoCtrlPgDn;
begin
  if Status = stQuickDescr then FocusItem(
    Range - Size.Y + Byte(State and sfMiniStatus <> 0) * 2)
  else if Status = stQuickView then TextReaderGoBottomPrim(@Self)
  else if Status = stInfo then FocusItem(Range - (Size.Y - 11))
  else if Status >= stTree then FocusItem(Range - 1)
  else if PPanelRec(List^.At(Focused))^.Attr and Directory <> 0 then
    ItemSelectedPrim(@Self, Focused)
  else NewArchiverPrim(@Self);
end;

procedure TPanel.GoCtrlPgUp;
begin
  if Status = stQuickView then TextReaderGoTopPrim(@Self)
  else if (Status >= stTree) or
    (Options and ofValidate <> 0) then FocusItem(0)
  else if Status < stTree then
    if (ListDir^[0] = #2) and not InArchive then
      if Settings and seList <> 0 then OutOfFileListPrim(@Self)
      else DrivePanel
    else ItemSelectedPrim(@Self, 0);
end;

procedure TPanel.GoHome;
var
  I: Integer;
begin
  if Status >= stInfo then
  begin
    Indent := 0;
    FocusItem(Focused);
  end
  else
  begin
    if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
       (Status < stInfo) then
      for I := 0 to Focused do SetSelect(List^.At(I), False);
    FocusItem(0);
  end;
end;

procedure TPanel.GoEnd;
var
  I: Integer;
begin
  if Status >= stInfo then
  begin
    Indent := DirinfoWidth - Size.X + 1;
    if Indent < 0 then Indent := 0;
    FocusItem(Focused);
  end
  else
  begin
    if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
       (Status < stInfo) then
      for I := Focused to Range - 1 do SetSelect(List^.At(I), True);
    FocusItem(Range - 1);
  end;
end;

procedure TPanel.FindFullName(const AName: FNameStr; var Index: Integer);
var
  S: FNameStr;
begin
  Index := 0;
  repeat
    GetItemStr(Index, S);
    if S = '' then Break;
    if CompUCString(S, AName) = Equal then Exit;
    Inc(Index);
  until Index >= List^.Count;
  Index := -1;
end;

procedure TPanel.FindByName(const AName: String; var Index: Integer);
var
  P: PPanelRec;
  Name, Ext, LName: String;
begin
  lFSplit(AName, LName, Name, Ext);
  if Ext <> '' then System.Delete(Ext, 1, 1);
  repeat
    P := List^.At(Index);
    if P = nil then Break;
    if (Options and ofValidate <> 0) and
       (P^.Name[0] = #2) and (P^.Name[2] = ':') and
       (TPString.Upcase(P^.Name[1]) = TPString.Upcase(AName[1])) then Exit;
    if PanelRecHasPath(P) and (P^.ThePath^[1] = #0) then
    begin
      AddNameExt('', P, LName);
      if CompUCString(LName, JustFileName(AName)) = Equal then Exit;
    end;
    if (CompUCString(P^.Name, Name) = Equal) and
       (CompUCString(P^.Ext, Ext) = Equal) then Exit;
    Inc(Index);
  until Index >= List^.Count;
  Index := -1;
end;

procedure TPanel.FocusFileName(const AName: FNameStr);
var
  I: Integer;
begin
  if not InArchive and (State and sfVisible <> 0) and
    (Status <= stFull) and (CompUCString(ClearedSlash(
    JustPathName(AName)), ListDir^) = Equal) then
  begin
    GetItemNum(ClearedSlash(AName), I);
    FocusItem(I);
  end;
end;

function TPanel.SearchDrive(ADrive: Char; var Index: Integer): Boolean;
var
  I: Integer;
begin
  SearchDrive := True;
  for I := 0 to List^.Count - 1 do
    if TPString.Upcase(PPanelRec(List^.At(I))^.Name[1]) =
       TPString.Upcase(ADrive) then
    begin
      Index := I;
      Exit;
    end;
  Index := 0;
  SearchDrive := False;
end;

procedure TPanel.ReadDirectory(UnfoldSel: Boolean);
var
  Unfold, Abort, Process, IsRoot: Boolean;
  B, FindAttr, PathPos, UnfoldLevel: Byte;
  DirIndex, SaveFocused: Integer;
  P: PPanelRec;
  D: PDriveSelector;
  T: PTreeCollection;
  Drives: TDrivesArray;
  SR: lSearchRec;
  FindPath, CurPath: FNameStr;

function IsExecutable(const AName: FNameStr): Boolean;
var
  I: Integer;
  S: String[3];
begin
  I := Pos('.', AName);
  if I <> 0 then S := System.Copy(AName, I + 1, 3);
  IsExecutable := (I <> 0) and ((S = 'BAT') or (S = 'COM') or (S = 'EXE'));
end;

procedure ReadDrives;
var
  A: Boolean;
  C: Char;
  I: Integer;
  L: PStringsCollection;
  PS: PString;
  R: TExtDiskInfoRec;
begin
  A := GetShiftState and (kbLeftShift + kbRightShift) = 0;
  if Settings and seList <> 0 then
    GetListDrivesPrim(FileListName^, ListDir^[1], B, Drives)
  else GetDrives(B, Drives);
  SR.SR.Attr := Directory;
  SR.SR.Time := 0;
  SR.SR.Size := 0;
  for C := 'A' to 'Z' do
  begin
    if Drives[C] = 1 then
    begin
      SR.SR.Name := C + ':';
      P := NewPanelRec(SR, @Self);
      ClassifyDrive(C, DiskClass(P^.Percent));
      if DisableSysInfo or (A and (DiskClass(P^.Percent) <= OtherFloppy)) then {}
      else if GetExtDiskInfo(C, R) and (Trim(R.FileSystem) <> '') then
{       P^.ThePath := NewStr(#$FF + Trim(R.FileSystem));}
        P^.ThePath := NewStrUMB(#$FF + Trim(R.FileSystem));
      List^.Insert(P);
    end;
  end;
  L := New(PStringsCollection, Init(8, 8));
  GetRedirDevices(L);
  for I := 0 to L^.Count - 1 do
  begin
    PS := L^.At(I);
    if PS = nil then Continue;
    SR.SR.Name := PS^;
    P := NewPanelRec(SR, @Self);
{    P^.ThePath := NewStr(PS^);}
    P^.ThePath := NewStrUMB(PS^);
    P^.Ext := '<->';
    DiskClass(P^.Percent) := NetResource;
    List^.Insert(P);
  end;
  Dispose(L, Done);
end;

procedure SetFindPath(const ADir, AMask: FNameStr);
begin
  FindPath := Concat(ADir, '\', AMask);
end;

procedure SetCurPath(const ADir, AName: FNameStr);
begin
  CurPath := Concat(ADir, '\', AName);
end;

procedure UpdateStatusLine;
begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Unfolding the directory ' + TrimmedName(CurPath, 44));
end;

procedure CalcDirSize(const Name: FNameStr);
var
  I: Integer;
  NumF, NumSel, NumSD: Longint;
  NumS, NumB, SelS, SelB, Cmpr, SelC: Real;
begin
  if T <> nil then
  begin
    I := T^.GetDirNum(Name, DirIndex, MaxInt);
    if I < T^.Count then
    begin
      SR.SR.Size := PTreeRec(T^.At(I))^.Size;
{ Added 04.30.03 to support size in KB }
      if SR.SR.Size >= SizeInKB then
      begin
        SR.SR.Size := Trunc(SR.SR.Size / OneKB);
        SR.SR.Attr := SR.SR.Attr or faSizeInKB;
      end;
      Exit;
    end;
  end;
  if GetDirInfo(Name, NumF, NumSel, NumSD, NumS, NumB, SelS, SelB, Cmpr, SelC,
    False, Settings and seList = 0, False) then
{ Added 04.30.03 to support size in KB }
      if NumS >= SizeInKB then
      begin
        SR.SR.Size := Trunc(NumS / OneKB);
        SR.SR.Attr := SR.SR.Attr or faSizeInKB;
      end
      else SR.SR.Size := Trunc(NumS)
  else Abort := True;
end;

procedure ScanDir(const ADir: FNameStr; SkipDirs, SetPath: Boolean);
var
  IsDir: Boolean;
begin
  SetFindPath(ADir, Filter);
  FailSysErrors := True;
  lFindFirst(FindPath, FindAttr, SR);
  FailSysErrors := False;
  while (DosError = 0) and not Abort do
  begin
    if SR.SR.Name[1] <> '.' then
    begin
      IsDir := SR.SR.Attr and Directory <> 0;
      if IsDir then
        if SkipDirs then Process := False
        else if UseFilter and (AdvancedFilter.Attr <> AnyFile) and
          (AdvancedFilter.Attr and Directory = 0) then Process := False
        else
        begin
          if Settings and seCalcDirSize <> 0 then
            CalcDirSize(AddedSlash(ADir) + SR.SR.Name);
          Process := True;
        end
      else
        if State and sfExOnly <> 0 then
          Process := IsExecutable(SR.SR.Name)
        else if UseFilter then
          Process := AdvancedFilterPassed(
            @AdvancedFilter, UnixStates, SR.SR, SR.FullName)
        else Process := True;
      if Process then
      begin
	P := NewPanelRec(SR, @Self);
{
        if SR.FullName <> '' then
          if SetPath then P^.ThePath := NewStr(#0 +
            System.Copy(ADir, PathPos, 255) + '\' + SR.FullName)
          else P^.ThePath := NewStr(#0 + SR.FullName)
        else if SetPath then P^.ThePath :=
          NewStr(System.Copy(ADir, PathPos, 255));
}
        if SR.FullName <> '' then
          if SetPath then P^.ThePath := NewStrUMB(#0 +
            System.Copy(ADir, PathPos, 255) + '\' + SR.FullName)
          else P^.ThePath := NewStrUMB(#0 + SR.FullName)
        else if SetPath then P^.ThePath :=
          NewStrUMB(System.Copy(ADir, PathPos, 255));
        List^.Insert(P);
      end;
    end;
    lFindNext(SR);
    if (KbdStatus = 1) and FMAbortAction then Abort := True;
  end;
  lFindClose(SR);
end;

procedure UnfoldDir(ADir: PString);
var
  CSR: ^lSearchRec;
  Dir: PString;
begin
  if StackOverflow then
  begin
    Abort := True;
    Exit;
  end;
  Dir := NewStr(ADir^);
  GetMem(CSR, SizeOf(lSearchRec));
  GiveTicks;
  if Clock <> nil then Clock^.Update;
  if TheSpooler <> nil then TheSpooler^.ProcessItems;
  UpdateRoller;
  SetFindPath(Dir^, '*.*');
  FailSysErrors := True;
  lFindFirst(FindPath, $17, CSR^);
  FailSysErrors := False;
  while (DosError = 0) and not Abort and
    not PPanelCollection(List)^.Full do
  begin
    if (CSR^.SR.Name[1] <> '.') and (CSR^.SR.Attr and Directory <> 0) then
    begin
      if CSR^.FullName <> '' then SetCurPath(Dir^, CSR^.FullName)
      else SetCurPath(Dir^, CSR^.SR.Name);
      if UnfoldSel and (UnfoldLevel = 0) and
        (TagList^.Count <> 0) and not TagList^.NameFound(CurPath) then {}
      else
      begin
        UpdateStatusLine;
        ScanDir(CurPath, True, True);
        Inc(UnfoldLevel);
        UnfoldDir(@CurPath);
        Dec(UnfoldLevel);
      end;
    end;
    lFindNext(CSR^);
    if (KbdStatus = 1) and FMAbortAction then Abort := True;
  end;
  lFindClose(CSR^);
  FreeMem(CSR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

procedure GetVolumeLabel;
var
  I: Integer;
begin
  if DisableSysInfo {or (ListDir^[1] = '\')} then Exit;
  FailSysErrors := True;
  FindFirst(RootName(ListDir^) + '\*.*', VolumeID, SR.SR);
  FailSysErrors := False;
  if DosError = 0 then VolumeName := Trim(SR.SR.Name);
  I := Pos('.', VolumeName);
  if I <> 0 then Delete(VolumeName, I, 1);
end;

label
  Quit;
begin
  VolumeName := '';
  if Status = stQuickDescr then
  begin
    QuickDescrPrim(@Self);
    goto Quit;
  end;
  if Status = stQuickView then
  begin
    QuickViewPrim(@Self);
    goto Quit;
  end;
  if Status = stInfo then
  begin
    ReadInfoPrim(@Self, False);
    goto Quit;
  end;
  if GroupOptions and (fgGroupHighlight + fgSortByIndex) <> 0 then
    InitTempGroups;
  if Options and ofValidate <> 0 then
  begin
    ReadDrives;
    SetRange(List^.Count);
  end
  else if Status = stTree then
  begin
    if InArchive then
    begin
      List := TheTree;
      ReadArchiveTreePrim(@Self);
      if not InArchive then goto Quit;
    end
    else if Settings and seList <> 0 then
    begin
      List := TheTree;
      ReadListTreePrim(@Self, FileListName^);
    end
    else
    begin
      NewTree(RootName(ListDir^), TheTree);
      List := TheTree;
    end;
    SetRange(TheTree^.Count);
    GetVolumeLabel;
  end
  else
  begin
    UseFilter := (State and sfExOnly = 0) and
      (Settings and seAdvancedFilter <> 0);
    if UseFilter and AdvancedFilter.Unix then
    begin
{      GetMem(UnixStates, SizeOf(TState));}
      GetMemUMB(UnixStates, SizeOf(TState));
      MakeAutomaton(AdvancedFilter.Text^, PState(UnixStates)^);
    end;
    if InArchive then
    begin
      ReadArchivePrim(@Self, UnfoldSel);
      if not InArchive then
      begin
        if UseFilter and AdvancedFilter.Unix then
          FreeMem(UnixStates, SizeOf(TState));
        if GroupOptions and (fgGroupHighlight + fgSortByIndex) <> 0 then
          DoneTempGroups;
        goto Quit;
      end;
    end
    else if Settings and seList <> 0 then
      ReadListPrim(@Self, FileListName^, UnfoldSel)
    else
    begin
      if Settings and seCalcDirSize <> 0 then
      begin
        LoadTree(RootName(ListDir^), T);
        if T <> nil then
          DirIndex := T^.GetDirNum(ListDir^, 0, MaxInt - 1) + 1;
      end
      else T := nil;
      Unfold := Settings and seUnfold <> 0;
      if State and sfShowHidden = 0 then
        FindAttr := AnyFile and not (Hidden + SysFile + VolumeID)
      else FindAttr := AnyFile and not VolumeID;
      Abort := False;
      if not UnfoldSel then ScanDir(ListDir^, Unfold, False);
      if Unfold then
      begin
        PathPos := Length(ListDir^) + 2;
        UnfoldLevel := 0;
        InitRoller;
        UnfoldDir(ListDir);
        DoneRoller;
      end;
      SetFindPath(ListDir^, '*.*');
      if (Filter <> '*.*') and not Unfold then
      begin
        FailSysErrors := True;
        lFindFirst(FindPath, FindAttr, SR);
        FailSysErrors := False;
        while DosError = 0 do
        begin
          if (SR.SR.Attr and Directory <> 0) and
             (SR.SR.Name[1] <> '.') then
          begin
            if Settings and seCalcDirSize <> 0 then
              CalcDirSize(AddedSlash(ListDir^) + SR.SR.Name);
	    P := NewPanelRec(SR, @Self);
            List^.Insert(P);
          end;
          lFindNext(SR);
        end;
        lFindClose(SR);
      end;
      if T <> nil then Dispose(T, Done);
    end;
    if PPanelCollection(List)^.Full and (List^.Count <> 0) then
      List^.AtFree(List^.Count - 1);
    IsRoot := ((ListDir^[1] <> '\') and (ListDir^[0] <= #3)) or
      ((ListDir^[1] = '\') and (RootName(ListDir^) = ListDir^));
    if not IsRoot or InArchive then
    begin
      if InArchive then Archiver^.SetFieldsForDots(SR)
      else
      begin
	if Settings and seList <> 0 then SetFindPath(ListDir^, '*.*');
	FailSysErrors := True;
	lFindFirst(FindPath, Directory, SR);
	lFindNext(SR);
	lFindClose(SR);
	FailSysErrors := False;
	if (DosError <> 0) or (SR.SR.Name <> '..') then
	begin
	  SR.SR.Name := '..';
	  SR.SR.Size := 0;
	  SR.SR.Time := $210000;
	  SR.SR.Attr := Directory;
{ Added 2006.01.03 }
	  SR.HiAttr := 0;
	end;
      end;
      P := NewPanelRec(SR, @Self);
      List^.Insert(P);
    end;
    if (State and sfDrivePanel <> 0) and IsRoot and not InArchive then
    begin
      SR.SR.Name := ':';
      SR.SR.Size := 0;
      SR.SR.Time := $210000;
      SR.SR.Attr := Directory;
      P := NewPanelRec(SR, @Self);
      List^.Insert(P);
    end;
    if PPanelCollection(List)^.Full then
    begin
      MessageBox(^C'Too many files.', nil, mfWarning + mfOkButton);
      PPanelCollection(List)^.Full := False;
    end;
    SetRange(List^.Count);
    HistoryAdd(DirHistoryID, ListDir^, True);
    GetVolumeLabel;
    if UseFilter and AdvancedFilter.Unix then
{      FreeMem(UnixStates, SizeOf(TState));}
      FreeMemUMB(UnixStates, SizeOf(TState));
  end;
  if GroupOptions and (fgGroupHighlight + fgSortByIndex) <> 0 then
    DoneTempGroups;
  PPanelWindow(Owner)^.GetCurrentPanel;
  if (Options and ofValidate = 0) and
     ((State and (sfSelected + sfActive) = (sfSelected + sfActive)) or
      (PPanelWindow(Owner)^.CurrentPanel = @Self)) then
    Message(Owner, evBroadcast, cmNewPrompt, ListDir)
  else
  begin
    SaveFocused := Focused;
    if Options and ofValidate <> 0 then Focused := -1;
    PWindow(Owner)^.Frame^.DrawView;
    Focused := SaveFocused;
  end;
  if Settings and seDriveSelector <> 0 then
  begin
    if Which = pnLeft then
      D := PDriveSelector(PPanelWindow(Owner)^.LeftSelector)
    else D := PDriveSelector(PPanelWindow(Owner)^.RightSelector);
    if D <> nil then
    begin
      D^.GetDrives(ListDir^[1]);
      D^.AdjustBounds;
      D^.DrawView;
    end;
  end;
  if Opposite^.Status = stInfo then Opposite^.Info;
Quit:
{ Added 08.11.99 to support SetApplicationTitle under Win95 }
  if Owner^.State and sfFocused <> 0 then
    Owner^.SetState(sfFocused, True);
end;

procedure TPanel.UpdateDirinfoRanges;
var
  UsePipes, EmptyStr: Boolean;
  I: Integer;
  PS: PString;
begin
  DirinfoWidth := 0;
  UsePipes := (Status = stQuickView) and (QuickStatus = qsColor);
  I := Dirinfo^.Count - 1;
  EmptyStr := True;
  while I >= 0 do
  begin
    PS := Dirinfo^.At(I);
    if PS = nil then
      if EmptyStr then Dirinfo^.AtFree(I) else
    else
    begin
      if UsePipes and (PipeStrLen(PS^) > DirinfoWidth) then
        DirinfoWidth := PipeStrLen(PS^)
      else if not UsePipes and (Length(PS^) > DirinfoWidth) then
        DirinfoWidth := Length(PS^);
      EmptyStr := False;
    end;
    Dec(I);
  end;
  SetRange(Dirinfo^.Count);
end;

procedure TPanel.AddFocused(Path, Long: Boolean);
var
  SR: PPanelRec;
  S: FNameStr;
begin
  if (Status >= stInfo) or (List^.Count = 0) then Exit;
  SR := List^.At(Focused);
  if (Status = stTree) and (Focused = 0) then
    S := TheTree^.GetBaseName
  else if Path or (Options and ofValidate <> 0) or
    (SR^.Name[1] in [':', '.']) then GetRecStr(SR, S)
  else AddNameExt('', SR, S);
  if Path then
    if GetShiftState and (kbLeftShift + kbRightShift) = 0 then
      lGetShortFileName(S, S) else
  else if not Long and not (SR^.Name[1] in [':', '.']) then
  begin
    lGetShortFileName(S, S);
    if Length(S) > 3 then S := JustFileName(S);
    if SR^.Attr and Directory = 0 then LocaseSt(S);
  end;
  if Pos(' ', S) <> 0 then S := '"' + S + '"';
  Message(Owner, evBroadcast, cmAddFileName, @S);
end;

procedure TPanel.SetSelect(Item: Pointer; On: Boolean);
var
  S: FNameStr;
begin
  if Item = nil then Exit;
  with PPanelRec(Item)^ do
  begin
    if (Selected = On) or (Attr and VolumeID <> 0) or
       (Name[1] in ['.', ':']) then Exit;
    Selected := On;
    if On then
    begin
      Inc(SelCount);
{      Inc(SelSize, Size);}
      if Attr and Directory <> 0 then Inc(SelDirCount)
      else Inc(SelFileCount);
{ Added 04.30.03 to support size in KB }
      SelByteCount := SelByteCount + lGetFileRealSize(Attr, Size);
      if SelList^.Count <> 0 then
      begin
        DoneSelList;
        InitSelList;
      end;
{      if FMOptions and foSaveSelection <> 0 then} {removed 2005.07.25}
      begin
        GetRecStr(PPanelRec(Item), S);
        TagList^.InsertName(S);
      end;
    end
    else
    begin
      Dec(SelCount);
{      Dec(SelSize, Size);}
      if Attr and Directory <> 0 then Dec(SelDirCount)
      else Dec(SelFileCount);
{ Added 04.30.03 to support size in KB }
      SelByteCount := SelByteCount - lGetFileRealSize(Attr, Size);
      GetRecStr(PPanelRec(Item), S);
      SelList^.InsertName(S);
{      if FMOptions and foSaveSelection <> 0 then} {removed 2005.07.25}
        TagList^.DeleteName(S);
    end;
  end;
  SelChanged := True;
end;

(*
procedure TPanel.SelectFocused;
var
  AutoIns: Boolean;
  C: Byte;
  SR: PPanelRec;
begin
  if (List^.Count = 0) or (Status > stTree) then Exit;
  AutoIns := False;
  repeat
    SR := List^.At(Focused);
    if (SR^.Attr and VolumeID <> 0) or (SR^.Name[1] = '.') then Exit;
    SetSelect(SR, not SR^.Selected);
    if FMOptions and foInsMovesDown <> 0 then FocusItem(Focused + 1)
    else FocusItem(Focused);
    for C := 0 to 5 do
    begin
      ClearKbd;
      if (KbdStatus <> 82) and (KbdStatus <> 224) then Exit;
      if AutoIns then Break;
      Delay(50);
    end;
    if KbdDelay <> 0 then Delay(KbdDelay);
    AutoIns := True;
  until False;
end;
*)

procedure TPanel.SelectFocused;
var
  SR: PPanelRec;
begin
  if (List^.Count = 0) or (Status > stTree) then Exit;
  SR := List^.At(Focused);
  if (SR^.Attr and VolumeID <> 0) or (SR^.Name[1] = '.') then {Exit;}
  else SetSelect(SR, not SR^.Selected);
  if FMOptions and foInsMovesDown <> 0 then FocusItem(Focused + 1)
  else FocusItem(Focused);
end;

procedure TPanel.SelectAll;
var
  I: Integer;
  SR: PPanelRec;
begin
  if Status < stTree then for I := 0 to List^.Count - 1 do
  begin
    SR := List^.At(I);
    if not SR^.Selected and (SR^.Attr and VolumeID = 0) and
      (SR^.Name[1] <> '.') then SetSelect(SR, True);
  end;
end;

procedure TPanel.UnselectAll;
var
  I: Integer;
  SR: PPanelRec;
begin
  if (Status >= stInfo) or (SelCount = 0) then Exit;
  for I := 0 to List^.Count - 1 do
  begin
    SR := List^.At(I);
    if SR^.Selected then SetSelect(SR, False);
  end;
{
  SelCount := 0;
  SelSize := 0;
}
end;

{
procedure TPanel.CalcSelSize;
var
  I: Integer;
  SR: PPanelRec;
begin
  I := SelCount;
  SelCount := 0;
  SelSize := 0;
  if (List^.Count = 0) or (I = 0) then Exit;
  for I := 0 to List^.Count - 1 do
  begin
    SR := List^.At(I);
    if SR^.Selected then
    begin
      Inc(SelCount);
      Inc(SelSize, SR^.Size);
    end;
  end;
end;
}

procedure TPanel.RestoreTags(ATagList: PTagList);
var
  B: Boolean;
  I: Integer;
  SR: PPanelRec;
  S: FNameStr;
begin
  if (ATagList = nil) or (ATagList^.Count = 0) then Exit;
  B := {(FMOptions and foSaveSelection <> 0) and} (ATagList <> TagList); {removed 2005.07.25}
  for I := 0 to List^.Count - 1 do
  begin
    SR := List^.At(I);
    if (SR^.Attr and VolumeID <> 0) or (SR^.Name[1] = '.') then
      Continue;
    GetRecStr(SR, S);
    if ATagList^.NameFound(S) then
    begin
      SR^.Selected := True;
      Inc(SelCount);
      if SR^.Attr and Directory <> 0 then Inc(SelDirCount)
      else Inc(SelFileCount);
{      Inc(SelSize, SR^.Size);}
{ Added 04.30.03 to support size in KB }
      SelByteCount := SelByteCount + lGetFileRealSize(SR^.Attr, SR^.Size);
      if B then TagList^.InsertName(S);
      SelChanged := True;
    end;
  end;
end;

procedure TPanel.NewDir(const ADir: FNameStr; DoFree: Boolean);
var
  UnfoldSel, UseLastTop: Boolean;
  LastTop: Integer;
  Tags: PTagList;
  S, SS: FNameStr;

procedure ConcatStatusStr;
begin
  SS := 'Reading the directory ' + TrimmedName(S, 45) + '.';
end;

procedure FillTagList;
var
  I: Integer;
  SR: PPanelRec;
begin
  if (SelCount = 0) or (MaxAvail <= LongMul(SelCount, 4) + $2000) then
  begin
    Tags := nil;
    Exit;
  end;
  Tags := New(PTagList, Init(SelCount, 16));
  for I := List^.Count - 1 downto 0 do
  begin
    SR := List^.At(I);
    if SR^.Selected then
    begin
      GetRecStr(SR, SS);
      Tags^.InsertName(SS);
    end;
    List^.AtFree(I);
  end;
end;

begin
  DiskChanged := False;
{added 2005.07.25}
  if FMOptions and foSaveSelection = 0 then
  begin
    DoneTagList;
    InitTagList;
  end;
  if InArchive and (ADir <> ListDir^) then
  begin
    Dispose(Archiver, Done);
    InArchive := False;
    DoFree := True;
  end;
  if (Status <> stQuickView) and (TextReader <> nil) then DoneTextReader;
  if (Status <> stQuickDescr) and (DescrData <> nil) then DoneDescrData;
  SetColumns;
  if (FMAutoRereadOptions = faNever) and
    not DoFree and (ADir = ListDir^) then
  begin
    Empty := False;
    PWindow(Owner)^.Frame^.DrawView;
    DrawView;
    Exit;
  end;
  if FMOptions and foDrawEmpty <> 0 then
  begin
    Empty := True;
    PWindow(Owner)^.Frame^.DrawView;
    DrawView;
    Empty := False;
  end;
  LastTop := LastTopItem;
  if Owner^.Owner = nil then LastTopItem := 0
  else LastTopItem := TopItem;
  UseLastTop := False;
  if Status < stInfo then
  begin
    S := ADir;
    if (Options and ofValidate = 0) and (Settings and seList = 0) then
    begin
      ValidDir(S, BytesFree);
      if S = '' then
      begin
        S := ListDir^;
        ValidDir(S, BytesFree);
        if S = '' then
        begin
	  S := ListDir^;
	  BytesFree := 0;
	end;
      end;
      if (Opposite^.ListDir <> nil) and
	 (RootName(Opposite^.ListDir^) = RootName(S)) and
	 (Opposite^.BytesFree <> BytesFree) then
      begin
	Opposite^.BytesFree := BytesFree;
	Opposite^.FocusItem(Opposite^.Focused);
      end;
    end;
    if CompUCString(S, ADir) <> Equal then DoFree := True;
    if not DoFree then FillTagList
    else if FMOptions and foSaveSelection <> 0 then Tags := TagList
    else Tags := nil;
    if (Settings and seUnfold <> 0) and
       (FMOptions and foResetUnfoldFlag <> 0) and
       (CompUCString(S, ListDir^) <> Equal) then
      Settings := Settings and not seUnfold;
    if Settings and seUnfold <> 0 then
      UnfoldSel := Settings and seUnfoldSel <> 0
    else UnfoldSel := False;
    if Pos(S, ListDir^) = 1 then UseLastTop := True;
{
    DisposeStr(ListDir);
    ListDir := NewStr(S);
}
    DisposeStrUMB(ListDir);
    ListDir := NewStrUMB(S);
  end;

{ Added 2005.12.31 }
  if CN_NT then
  begin
    NT_FreeDirCheck(NT_DirCheckHandle);
    if (FMAutoRereadOptions <> faNever) and (Status < stTree) then
      NT_DirCheckHandle := NT_SetDirCheck(AddedSlash(ListDir^),
	3 * Byte(Settings and seUnfold <> 0));
  end;

  DoneLists;
  InitLists;
  DoneFiles;
  InitFiles;
  if DoFree then
  begin
    DoneSelList;
    InitSelList;
    Focused := 0;
    TopItem := 0;
    Indent := 0;
  end;
  Range := 0;
  SelCount := 0;
{  SelSize := 0;}
  SelChanged := False;
  SearchStr := '';
  SearchPos := 1;
  CursorPos := -1;
  DotPos := -1;
  SearchLevel := $FF;
  AltHistoryIndex := 0;
  if not (Status in [stTree, stQuickView, stQuickDescr]) and
     not InArchive and (Settings and seList = 0) then
  begin
    LogEvent := lcDiskRead;
    if Options and ofValidate <> 0 then SS := 'Detecting available drives.'
    else if Status = stInfo then SS := 'Reading directory information.'
    else ConcatStatusStr;
    DrawStatusLine(SS);
  end;
  Owner^.Lock;
  LFNTimes := TimeMode;
  ReadDirectory(UnfoldSel);
  LFNTimes := ltMod;
  if Status < stInfo then
  begin
    RestoreTags(Tags);
    if (Tags <> nil) and (Tags <> TagList) then Dispose(Tags, Done);
    GetDirCounts;
  end;
  if Status = stFull then
  begin
    DirinfoWidth := 255;
    if (Settings and seLongNames = 0) and (Options and ofFilesBBS <> 0) then
      ReadFilesBBSPrim(@Self, ListDir^, UnfoldSel);
  end;
  if UseLastTop then TopItem := LastTop;
  Owner^.Unlock;
end;

procedure TPanel.RootDir;

procedure ArcRootDir;
var
  A: PArchiver;
begin
  while Archiver^.Prev <> nil do
  begin
    A := Archiver;
    Archiver := A^.Prev;
    A^.Prev := nil;
    Dispose(A, Done);
  end;
  with Archiver^ do NewArcDir(ArcName^);
  NewDir(ListDir^, True);
end;

begin
  if List^.Count = 0 then Exit;
  if Status >= stTree then Exit;
  Options := Options and not ofValidate;
  if InArchive then ArcRootDir
  else NewDir(RootName(ListDir^), True);
  FocusItem(0);
end;

{
procedure TPanel.ReReadPrim(DoFree: Boolean);
var
  I: Integer;
  S: FNameStr;
begin
  if Status in [stQuickView, stQuickDescr] then Exit;
  LastTopItem := TopItem;
  GetItemStr(Focused, S);
  NewDir(ListDir^, DoFree);
  GetItemNum(S, I);
  FocusItem(I);
end;
}

procedure TPanel.ReReadPrim(DoFree: Boolean);
var
  I: Integer;
  P: PPanelRec;
  R: TPanelRec;
  S: FNameStr;
begin
  if Status in [stQuickView, stQuickDescr] then Exit;
  LastTopItem := TopItem;
  if (Status <= stFull) and (SortMode <> smDisk) then
  begin
    P := Files^.At(Focused);
    if P = nil then I := 0
    else
    begin
      R := P^;
      R.ThePath := nil;
      if PanelRecHasPath(P) then
      begin
        S := P^.ThePath^;
        R.ThePath := @S;
      end;
      I := -1;
    end;
    NewDir(ListDir^, DoFree);
    if I = -1 then Files^.Search(@R, I);
  end
  else
  begin
    GetItemStr(Focused, S);
    NewDir(ListDir^, DoFree);
    GetItemNum(S, I);
  end;
  FocusItem(I);
end;

procedure TPanel.ReRead(EraseTree: Boolean);
var
  SaveOpt: Byte;
begin
  if (Status = stTree) and EraseTree then
    EraseTreeInfo(RootName(ListDir^));
  if FMOptions and foRereadUnselects <> 0 then UnselectAll;
  SaveOpt := FMAutoRereadOptions;
  FMAutoRereadOptions := faAlways;
  ReReadPrim(False);
  FMAutoRereadOptions := SaveOpt;
end;

procedure TPanel.ReReadAll;
begin
  Message(Desktop, evBroadcast, cmReRead, nil);
  Message(Desktop, evBroadcast, cmUpdateTime, nil);
end;

procedure TPanel.ReReadOnlAPIChange(FromAPI: Byte);
var
  S: FNameStr;
begin
  lGetFileNameForChangedAPI(lAPIType(FromAPI), ListDir^, S);
{
  DisposeStr(ListDir);
  ListDir := NewStr(S);
}
  DisposeStrUMB(ListDir);
  ListDir := NewStrUMB(S);
  if (lAPI <> lDOS) and (Status <= stFull) then
    Settings := Settings or seLongNames;
  ReRead(False);
end;

procedure TPanel.PrepareSwitch;
begin
  if InArchive then
  begin
    Dispose(Archiver, Done);
    InArchive := False;
  end;
  if Status >= stInfo then ToggleInfo(False);
  Options := Options and not ofValidate;
end;

procedure TPanel.SwitchToDir(const ADir: FNameStr; DoFocus: Boolean);
var
  S: FNameStr;
begin
  PrepareSwitch;
  FailSysErrors := True;
  S := ClearedSlash(lFExpand(ADir));
  FailSysErrors := False;
  NewDir(S, True);
  if DoFocus then FocusItem(0);
end;

{
procedure TPanel.NewStatus(AStatus: Byte);
begin
  if Status <> AStatus then
  begin
    OldStatus := Status;
    Status := AStatus;
    if Options and ofValidate <> 0 then OldFocused := 0
    else OldFocused := Focused;
    TopItem := 0;
    LastTopItem := 0;
  end
  else LastTopItem := TopItem;
end;
}

procedure TPanel.NewStatus(AStatus: Byte);
begin
  if Status <> AStatus then
  begin
    OldStatus := Status;
    if Options and ofValidate <> 0 then OldFocused := 0
    else OldFocused := Focused;
    Status := AStatus;
    TopItem := 0;
    LastTopItem := 0;
  end
  else LastTopItem := TopItem;
end;

{
procedure TPanel.Brief;
var
  I: Integer;
  S: FNameStr;
begin
  if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
    Settings := Settings or seLongNames
  else Settings := Settings and not seLongNames;
  if Status > stFull then S := ''
  else GetItemStr(Focused, S);
  NewStatus(stBrief);
  List := Files;
  NewDir(ListDir^, True);
  if S = '' then I := 0
  else GetItemNum(S, I);
  FocusItem(I);
end;

procedure TPanel.Full;
var
  I: Integer;
  S: FNameStr;
begin
  if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
    Settings := Settings or seLongNames
  else Settings := Settings and not seLongNames;
  if Status > stFull then S := ''
  else GetItemStr(Focused, S);
  NewStatus(stFull);
  List := Files;
  NewDir(ListDir^, True);
  if S = '' then I := 0
  else GetItemNum(S, I);
  FocusItem(I);
end;
}

procedure TPanel.FilePanel(AStatus: Byte; ForceLong: Boolean);
begin
  if ForceLong or
    (GetShiftState and (kbLeftShift + kbRightShift) <> 0) then
      Settings := Settings or seLongNames
  else Settings := Settings and not seLongNames;
  if (Status <= stFull) and (AStatus = stBrief) then
    if Settings and seLongNames <> 0 then ColWidth := 20
    else ColWidth := 13
  else if (AStatus = stFull) and (Settings and seLongNames = 0) then
    if Settings and seFullWide <> 0 then ColWidth := 14
    else if Status = stFull then ColWidth := 13;
  NewStatus(AStatus);
  List := Files;
  ReReadPrim(True);
end;

procedure TPanel.Brief;
begin
  FilePanel(stBrief, False);
end;

procedure TPanel.Full;
begin
  FilePanel(stFull, False);
end;

procedure TPanel.Tree;
var
  I: Integer;
  S: FNameStr;
begin
  GetListDir(S);
  NewStatus(stTree);
  Options := Options and not ofValidate;
  NewDir(ListDir^, True);
  GetItemNum(S, I);
  FocusItem(I);
end;

procedure TPanel.Info;
begin
  NewStatus(stInfo);
  Options := Options and not ofValidate;
  NewDir(ListDir^, True);
  FocusItem(0);
end;

procedure TPanel.QuickView;
begin
  NewStatus(stQuickView);
  if TextReader = nil then InitTextReader;
  Options := Options and not ofValidate;
  if Opposite^.Status <= stTree then
    Opposite^.FocusItem(Opposite^.Focused)
  else NewDir(ListDir^, True);
end;

procedure TPanel.QuickDescr;
begin
  NewStatus(stQuickDescr);
  if DescrData = nil then InitDescrData;
  Options := Options and not ofValidate;
  if Opposite^.Status <= stTree then
    Opposite^.FocusItem(Opposite^.Focused)
  else NewDir(ListDir^, True);
end;

procedure TPanel.DrivePanel;
var
  I: Integer;
begin
  Options := Options or ofValidate;
  NewDir(ListDir^, True);
  if ListDir^[1] = '\' then GetItemNum(ListDir^, I)
  else SearchDrive(ListDir^[1], I);
  FocusItem(I);
end;

procedure TPanel.ToggleInfo(DoRead: Boolean);
var
  I: Integer;
begin
  if (Status <> stInfo) and (OldStatus <> stInfo) and DoRead then
  begin
    OldStatus := stInfo;
    OldFocused := 0;
  end
  else if (Status >= stInfo) and (OldStatus >= stInfo) then
  begin
    OldStatus := stBrief;
    OldFocused := 0;
  end;
  I := OldFocused;
  NewStatus(OldStatus);
  if DoRead then
  begin
    Options := Options and not ofValidate;
    NewDir(ListDir^, True);
    FocusItem(I);
  end;
  if State and sfVisible = 0 then
    TogglePanelPrim(PPanelWindow(Owner), @Self, tmByF);
end;

procedure TPanel.ToggleQuickView;
var
  I: Integer;
begin
  if Status <> stQuickView then QuickView
  else
  begin
    if OldStatus >= stInfo then
    begin
      OldStatus := stBrief;
      OldFocused := 0;
    end;
    I := OldFocused;
    NewStatus(OldStatus);
    NewDir(ListDir^, True);
    FocusItem(I);
  end;
  if State and sfVisible = 0 then
    TogglePanelPrim(PPanelWindow(Owner), @Self, tmByF);
end;

procedure TPanel.ToggleQuickDescr;
var
  I: Integer;
begin
  if Status <> stQuickDescr then QuickDescr
  else
  begin
    if OldStatus >= stInfo then
    begin
      OldStatus := stBrief;
      OldFocused := 0;
    end;
    I := OldFocused;
    NewStatus(OldStatus);
    NewDir(ListDir^, True);
    FocusItem(I);
  end;
  if State and sfVisible = 0 then
    TogglePanelPrim(PPanelWindow(Owner), @Self, tmByF);
end;

procedure TPanel.ToggleHidden;
begin
  State := State xor sfShowHidden;
  if (Status < stTree) and (Options and ofValidate = 0) then
    ReReadPrim(False);
end;

procedure TPanel.ToggleExOnly;
begin
  State := State xor sfExOnly;
  if (Status < stTree) and (Options and ofValidate = 0) then
    ReReadPrim(False);
end;

procedure TPanel.ToggleMiniStatus;
begin
  State := State xor sfMiniStatus;
  if State and sfMiniStatus <> 0 then
    Settings := Settings and not seMaxi
  else Settings := Settings or seMaxi;
  if Status = stInfo then Exit;
  FocusItem(Focused);
  PWindow(Owner)^.Frame^.DrawView;
end;

procedure TPanel.ToggleDrivePanel;
var
  I: Integer;
begin
  if (State and sfDrivePanel = 0) or (Focused = 0) then I := 0
  else I := Focused - 1;
  State := State xor sfDrivePanel;
  if (Status >= stTree) or (Length(ListDir^) > 2) or
     (Options and ofValidate <> 0) or InArchive then Exit;
  NewDir(ListDir^, True);
  FocusItem(I);
end;

procedure TPanel.ToggleDriveSelector;
begin
  Settings := Settings xor seDriveSelector;
  if Settings and seDriveSelector <> 0 then InitDriveSelector
  else DoneDriveSelector;
  FocusItem(Focused);
  PWindow(Owner)^.Frame^.DrawView;
end;

procedure TPanel.TogglePanelBar;
begin
  Settings := Settings xor sePanelBar;
  if Settings and sePanelBar <> 0 then InitPanelBar
  else DonePanelBar;
  FocusItem(Focused);
end;

{
procedure TPanel.ToggleFilesBBS;
var
  I: Integer;
  S: FNameStr;
begin
  Options := Options xor ofFilesBBS;
  if (Status <> stFull) or (Options and ofValidate <> 0) or
     (Settings and seLongNames <> 0) then Exit;
  GetItemStr(Focused, S);
  NewDir(ListDir^, True);
  GetItemNum(S, I);
  FocusItem(I);
end;
}

procedure TPanel.ToggleFilesBBS;
begin
{
  Options := Options xor ofFilesBBS;
  if (Status = stFull) and (Options and ofValidate = 0) and
     (Settings and seLongNames = 0) then ReReadPrim(True);
}
  if (Status = stFull) and (Settings and seLongNames = 0) then
    Options := Options xor ofFilesBBS
  else Options := Options or ofFilesBBS;
  if Options and ofValidate = 0 then
    if (Options and ofFilesBBS = 0) and (OldStatus = stBrief) then
      FilePanel(stBrief, False)
    else FilePanel(stFull, False);
end;

procedure TPanel.ToggleCalcDirSize;
begin
  Settings := Settings xor seCalcDirSize;
  if (Status < stTree) and (Options and ofValidate = 0) and
     (Settings and seUnfold = 0) then ReReadPrim(False);
end;

procedure TPanel.ToggleIgnoreSelection;
begin
  Settings := Settings xor seIgnoreSelection;
  FocusItem(Focused);
end;

procedure TPanel.ToggleSepSelInfo;
begin
  Settings := Settings xor seSepSelInfo;
  FocusItem(Focused);
end;

procedure TPanel.ClearSelectionList;
var
  L: Longint;
  S: String;
begin
  L := TagList^.Count;
  S := ^C'Clear selection list (%d items) ?';
  if L = 1 then System.Delete(S, Length(S) - 3, 1);
  if MessageBox(S, @L, mfConfirmation + mfOkCancel) <> cmOk then Exit;
  DoneTagList;
  InitTagList;
  Message(Desktop, evBroadcast, cmClearSelection, nil);
end;

procedure TPanel.GetSource(var S: FNameStr);
begin
  if InArchive then Archiver^.PrepareSource(S)
  else if (Status in [stQuickView, stQuickDescr]) and
    not (Opposite^.Status in [stQuickView, stQuickDescr]) then
      Opposite^.GetSource(S)
  else GetItemStr(Focused, S);
end;

procedure TPanel.ExtDialog(Viewer: Boolean);
var
  SR: PPanelRec;
  S: FNameStr;
begin
  if (Status < stTree) and (Options and ofValidate = 0) and
     (List^.Count <> 0) then
  begin
    SR := List^.At(Focused);
    if SR^.Attr and Directory = 0 then AddNameExt('', SR, S)
    else S := '';
  end;
  if Viewer then ViewDlg(S) else ExtDlg(S);
end;

procedure TPanel.ChangeDir;
var
  I: Integer;
  S: FNameStr;
begin
  GetListDir(S);
  TreeDialog(S);
  if S = '' then Exit;
  SwitchToDir(AddedSlash(S), False);
  if Status = stTree then I := TheTree^.GetDirNum(S, 0, Focused)
  else I := 0;
  FocusItem(I);
end;

procedure TPanel.GetTitle(var ATitle: String);
var
  MinX: Integer;
  S: String[7];
begin
  MinX := MinPanelWidth + 3;
  if Opposite^.State and sfVisible = 0 then Inc(MinX, 3);
  if Empty or GlobalEmptyFlag or (Size.X <= MinX) then ATitle := ''
  else if Options and ofValidate <> 0 then ATitle := 'Drives'
  else if Status = stTree then ATitle := 'Tree'
  else if Status = stInfo then ATitle := 'Info'
  else if Status = stQuickView then ATitle := 'View'
  else if Status = stQuickDescr then ATitle := 'Description'
  else if (Settings and seUnfold <> 0) and
    not ((Focused = 0) and (ListDir^[0] > #2)) then
  begin
    GetItemStr(Focused, ATitle);
    ATitle := TrimmedName(ATitle, Size.X - (MinX + 1));
  end
  else
  begin
    GetListDir(ATitle);
    if State and sfExOnly <> 0 then ATitle :=
      TrimmedName(ATitle + '\executable', Size.X - MinX)
    else if Settings and seAdvancedFilter <> 0 then ATitle :=
      TrimmedName(ATitle + '\filtered', Size.X - MinX)
    else if Filter <> '*.*' then ATitle :=
      TrimmedName(ATitle + '\' + Filter, Size.X - MinX)
    else ATitle := TrimmedName(ATitle, Size.X - MinX);
  end;
  if (ATitle[0] = #2) and (ATitle[2] = ':') then ATitle := ATitle + '\';
  if (Size.X > MinX) and (Byte(ATitle[0]) > Size.X - MinX) then
    Dec(ATitle[0], Byte(ATitle[0]) - (Size.X - MinX))
  else if not Empty and not GlobalEmptyFlag then
  begin
    if InArchive and (Archiver^.ArchiveRec^.Extension <> nil) and
       (Status < stInfo) then
      S := StUpcase(Archiver^.ArchiveRec^.Extension^) + ':'
    else if Opposite^.InArchive and
      (Opposite^.Archiver^.ArchiveRec^.Extension <> nil) and
      (Status >= stInfo) then
	S := StUpcase(Opposite^.Archiver^.ArchiveRec^.Extension^) + ':'
    else if ((Settings and seList <> 0) and (Status < stInfo)) or
      ((Opposite^.Settings and seList <> 0) and (Status >= stInfo)) then
	S := 'LIST-'
    else if Settings and seUnfold <> 0 then S := 'UNFOLD-'
    else S := '';
    if (S <> '') and (Byte(ATitle[0]) + Byte(S[0]) <= Size.X - MinX) then
      ATitle := S + ATitle;
  end;
  if ATitle <> '' then ATitle := ' ' + ATitle + ' ';
end;

(*
procedure TPanel.GetVolumeTitle(var ATitle: String; MaxLen: Integer);
begin
  if Empty or GlobalEmptyFlag or (MaxLen <= 4) then ATitle := ''
  else if (Status >= stQuickView) and (Opposite^.Status < stQuickView) then
    Opposite^.GetVolumeTitle(ATitle, MaxLen)
  else
  begin
    if ListDir^[1] = '\' then ATitle := '?'
    else FormatFloatBytes(ATitle, BytesFree, 1000000000);
    ATitle := ATitle + ' bytes free';
    if ListDir^[1] = '\' then
      ATitle := ' Network resource (' + ATitle + ') '
    else
    begin
      if VolumeName <> '' then ATitle := ' (' + ATitle + ')';
      ATitle := ' ' + VolumeName + ATitle + ' ';
    end;
    if Length(ATitle) > MaxLen then
    begin
      ATitle[0] := Char(MaxLen);
      while ATitle[Length(ATitle) - 1] = ' ' do Dec(ATitle[0]);
      ATitle[Length(ATitle)] := ' ';
    end;
  end;
end;
*)

procedure TPanel.GetVolumeTitle(var ATitle: String; MaxLen: Integer);
var
  C: DiskClass;
  I: Integer;
  P: PPanelRec;
  S: String[11];
  R: TExtDiskInfoRec;
  SR: SearchRec;
begin
  if Empty or GlobalEmptyFlag or (MaxLen <= 4) then ATitle := ''
  else if (Status >= stQuickView) and (Opposite^.Status < stQuickView) then
    Opposite^.GetVolumeTitle(ATitle, MaxLen)
  else
  begin
    if Options and ofValidate <> 0 then
    begin
      ATitle := '';
      if (List^.Count <> 0) and (Focused >= 0) and
         (Focused < List^.Count) then
      begin
        if MouseHintItem <> nil then P := MouseHintItem
        else P := PPanelRec(List^.At(Focused));
	C := DiskClass(P^.Percent);
	if (C > OtherFloppy) or (GetShiftState and
	   (kbLeftShift + kbRightShift) <> 0) then
	begin
	  FailSysErrors := True;
	  BytesFree := FDiskFree(P^.Name);
	  if BytesFree >= 0 then
	  begin
	    FormatFloatBytes(ATitle, BytesFree, 1000000000);
	    ATitle := ATitle + ' bytes free';
	    FindFirst(P^.Name + '\*.*', VolumeID, SR);
	    if DosError = 0 then
	    begin
	      S := Trim(SR.Name);
	      I := Pos('.', S);
	      if I <> 0 then Delete(S, I, 1);
	      if S <> '' then ATitle := S + ' (' + ATitle + ')';
	    end;
	    ATitle := ' ' + ATitle + ' ';
	  end;
	  FailSysErrors := False;
	  if (C <= OtherFloppy) and GetExtDiskInfo(P^.Name[1], R) and
	     (Trim(R.FileSystem) <> '') then
	  begin
{             DisposeStr(P^.ThePath);}
	    DisposeStrUMB(P^.ThePath);
{             P^.ThePath := NewStr(#$FF + Trim(R.FileSystem));}
	    P^.ThePath := NewStrUMB(#$FF + Trim(R.FileSystem));
	  end;
	end;
      end;
    end
    else
    begin
      FormatFloatBytes(ATitle, BytesFree, 1000000000);
      ATitle := ATitle + ' bytes free';
      if VolumeName <> '' then ATitle := ' (' + ATitle + ')';
      ATitle := ' ' + VolumeName + ATitle + ' ';
    end;
    if Length(ATitle) > MaxLen then
    begin
      ATitle[0] := Char(MaxLen);
      while ATitle[Length(ATitle) - 1] = ' ' do Dec(ATitle[0]);
      ATitle[Length(ATitle)] := ' ';
    end;
  end;
end;

procedure TPanel.GetDirCounts;
var
  I: Integer;
  SR: PPanelRec;
begin
  FileCount := 0;
  DirCount := 0;
  ByteCount := 0;
  SelFileCount := 0;
  SelDirCount := 0;
  SelByteCount := 0;
  for I := 0 to List^.Count - 1 do
  begin
    SR := List^.At(I);
    if (SR^.Name[1] in [':', '.']) or (SR^.Attr and VolumeID <> 0) then
      Continue;
    if SR^.Attr and Directory <> 0 then Inc(DirCount)
    else Inc(FileCount);
{ Added 04.30.03 to support size in KB }
    ByteCount := ByteCount + lGetFileRealSize(SR^.Attr, SR^.Size);
    if SR^.Selected then
    begin
      if SR^.Attr and Directory <> 0 then Inc(SelDirCount)
      else Inc(SelFileCount);
      SelByteCount := SelByteCount + lGetFileRealSize(SR^.Attr, SR^.Size);
    end;
  end;
end;

procedure TPanelFrame.Draw;
const
  Chars: Array[0..19] of Char = 'ÄÚÂ¿³Ã´ÀÙÁÍÉÑ»ºÇ¶È¼Ï';
var
  LeftHidden, RightHidden, NewIcons: Boolean;
  Base: Byte;
  NumChar: Char;
  PanelHeight, LeftSize, RightSize: Integer;
  Color, DragColor, TitleColor: Word;
  I, W: Integer;
  PanelTitle: String;
  B: TDrawBuffer;

procedure MoveDots(Shift: Byte);
var
  C: Char;
  II: Integer;
begin
  with PPanelWindow(Owner)^ do
  begin
    C := Chars[Base + Shift];

    if (Shift = 2) or (LeftPanel^.State and sfMiniStatus = 0) then
      if (LeftPanel^.Status = stFull) and
         (LeftPanel^.Settings and seLongNames = 0) then
      begin
        Char(B[LeftPanel^.ColWidth]) := C;
        if LeftPanel^.Options and (ofValidate + ofFilesBBS) = 0 then
        begin
          if LeftPanel^.Size.X >= LeftPanel^.ColWidth + 10 then
            Char(B[LeftPanel^.ColWidth + 10]) := C;
          if LeftPanel^.Size.X >= LeftPanel^.ColWidth + 19 then
            Char(B[LeftPanel^.ColWidth + 19]) := C;
          if LeftPanel^.Size.X >= LeftPanel^.ColWidth + 26 then
            Char(B[LeftPanel^.ColWidth + 26]) := C;
          if LeftPanel^.InArchive and
            (LeftPanel^.Size.X >= LeftPanel^.ColWidth + 32) then
              Char(B[LeftPanel^.ColWidth + 32]) := C;
        end;
      end
      else if LeftPanel^.Status = stBrief then
        for II := 0 to LeftPanel^.NumCols - 1 do
        begin
          I := LeftPanel^.ColWidth * (II + 1);
          if LeftPanel^.Size.X >= I then Char(B[I]) := C;
        end;

    if (Shift = 2) or (RightPanel^.State and sfMiniStatus = 0) then
      if (RightPanel^.Status = stFull) and
         (RightPanel^.Settings and seLongNames = 0) then
      begin
        Char(B[LeftPanel^.Size.X + 2 + RightPanel^.ColWidth]) := C;
        if RightPanel^.Options and (ofValidate + ofFilesBBS) = 0 then
        begin
          if RightPanel^.Size.X >= RightPanel^.ColWidth + 10 then
            Char(B[LeftPanel^.Size.X + 2 +
              RightPanel^.ColWidth + 10]) := C;
          if RightPanel^.Size.X >= RightPanel^.ColWidth + 19 then
            Char(B[LeftPanel^.Size.X + 2 +
              RightPanel^.ColWidth + 19]) := C;
          if RightPanel^.Size.X >= RightPanel^.ColWidth + 26 then
            Char(B[LeftPanel^.Size.X + 2 +
              RightPanel^.ColWidth + 26]) := C;
          if RightPanel^.InArchive and
            (RightPanel^.Size.X >= RightPanel^.ColWidth + 39) then
              Char(B[LeftPanel^.Size.X + 2 +
                RightPanel^.ColWidth + 32]) := C;
        end;
      end
      else if RightPanel^.Status = stBrief then
        for II := 0 to RightPanel^.NumCols - 1 do
        begin
          I := LeftPanel^.Size.X + 2 + RightPanel^.ColWidth * (II + 1);
          if LeftPanel^.Size.X + 2 + RightPanel^.Size.X >= I then
            Char(B[I]) := C;
        end;
  end;
end;

procedure UserScreenLine(Index, Org, Len, Pos: Integer);
begin
  MoveChar(B[Pos], ' ', $07, Len);
  while Org + Len > UserScreenCols do Dec(Len);
  Inc(Index, UserScreenRows - Size.Y -
    Byte(HideOptions and hvStatusLine = 0) - 1);
  if (UserScreenBuffer <> nil) and
     (Org < UserScreenCols) and (Len > 0) and
     (Index >= 0) and (Index < UserScreenRows) then
    Move(UserScreenBuffer^[Index * UserScreenCols + Org],
      B[Pos], Len shl 1);
end;

begin
  with PPanelWindow(Owner)^ do
  begin
    PanelHeight := LeftPanel^.Size.Y;
    LeftHidden := LeftPanel^.State and sfVisible = 0;
    RightHidden := RightPanel^.State and sfVisible = 0;
    LeftSize := LeftPanel^.Size.X + 2;
    RightSize := RightPanel^.Size.X + 2;
    if (Number <> wnNoNumber) and (Number < 10) then
      NumChar := Char(Number + $30)
    else NumChar := wnNoNumberChar;
  end;

  DragColor := GetColor(3);
  if State and sfActive = 0 then
  begin
    Color := GetColor(1);
    DragColor := Color;
    Base := 0;
  end
  else if State and sfDragging <> 0 then
  begin
    Color := GetColor(3);
    Base := 0;
  end
  else
  begin
    Color := GetColor(2);
    Base := 10;
  end;

  MoveChar(B, Chars[Base], Color, Size.X);
  Char(B[0]) := Chars[Base + 1];
  MoveDots(2);
  with PPanelWindow(Owner)^ do
  begin
    Char(B[LeftPanel^.Size.X + 1]) := Chars[Base + 3];
    Char(B[LeftPanel^.Size.X + 2]) := Chars[Base + 1];
    if LeftPanel = CurrentPanel then TitleColor := GetColor(8)
    else TitleColor := Color;
    LeftPanel^.GetTitle(PanelTitle);
    LeftTitleLen := Length(PanelTitle);
    LeftTitlePos := (LeftPanel^.Size.X - LeftTitleLen) div 2 + 1;
    if LeftTitlePos < 6 then LeftTitlePos := 6;
    MoveStr(B[LeftTitlePos], PanelTitle, TitleColor);
    if RightPanel = CurrentPanel then TitleColor := GetColor(8)
    else TitleColor := Color;
    RightPanel^.GetTitle(PanelTitle);
    RightTitleLen := Length(PanelTitle);
    RightTitlePos := LeftPanel^.Size.X + 2 +
      (RightPanel^.Size.X - RightTitleLen) div 2 + 1;
    if RightTitlePos + RightTitleLen > Size.X - 6 then
      Dec(RightTitlePos, RightTitlePos + RightTitleLen - (Size.X - 6));
    MoveStr(B[RightTitlePos], PanelTitle, TitleColor);
  end;

  NewIcons := WinPosMask and wpIcons <> 0;
  if NewIcons or (State and sfActive <> 0) then
  begin
    if not LeftHidden then
    begin
      Char(B[1]) := '[';
      MoveChar(B[2], 'þ', DragColor, 1);
      if NewIcons then MoveChar(B[3], NumChar, DragColor, 1);
      Char(B[3 + Byte(NewIcons)]) := ']';
    end
    else if not RightHidden and (RightSize > 9) then
    begin
      Char(B[LeftSize + 1]) := '[';
      MoveChar(B[LeftSize + 2], 'þ', DragColor, 1);
      if NewIcons then MoveChar(B[LeftSize + 3], NumChar, DragColor, 1);
      Char(B[LeftSize + 3 + Byte(NewIcons)]) := ']';
    end;

    if not RightHidden then
    begin
      Char(B[Size.X - 5]) := '[';
      if Longint(Owner^.Size) = Longint(Owner^.Owner^.Size) then
        MoveChar(B[Size.X - 4], '', DragColor, 1)
      else MoveChar(B[Size.X - 4], '', DragColor, 1);
      MoveChar(B[Size.X - 3], '', DragColor, 1);
      Char(B[Size.X - 2]) := ']';
    end
    else if not LeftHidden and (LeftSize > 8) then
    begin
      Char(B[LeftSize - 5]) := '[';
      if Longint(Owner^.Size) = Longint(Owner^.Owner^.Size) then
        MoveChar(B[LeftSize - 4], '', DragColor, 1)
      else MoveChar(B[LeftSize - 4], '', DragColor, 1);
      MoveChar(B[LeftSize - 3], '', DragColor, 1);
      Char(B[LeftSize - 2]) := ']';
    end;
  end;
  Char(B[Size.X - 1]) := Chars[Base + 3];

  if LeftHidden then UserScreenLine(0, 0, LeftSize, 0);
  if RightHidden then UserScreenLine(0, LeftSize, RightSize, LeftSize);
  WriteLine(0, 0, Size.X, 1, B);

  for I := 1 to PanelHeight do
  begin
    MoveChar(B, Chars[Base + 4], Color, Size.X);
    if (I = 3) or (I = 11) then with PPanelWindow(Owner)^ do
    begin
      if LeftPanel^.Status = stInfo then
      begin
        Char(B[0]) := Chars[Base + 5];
        Char(B[LeftPanel^.Size.X + 1]) := Chars[Base + 6];
      end;
      if RightPanel^.Status = stInfo then
      begin
        Char(B[LeftPanel^.Size.X + 2]) := Chars[Base + 5];
        Char(B[Size.X - 1]) := Chars[Base + 6];
      end;
    end;
    if I = PanelHeight - 1 then with PPanelWindow(Owner)^ do
    begin
      if (LeftPanel^.Status <> stInfo) and
         (LeftPanel^.State and sfMiniStatus <> 0) then
      begin
        Char(B[0]) := Chars[Base + 5];
        Char(B[LeftPanel^.Size.X + 1]) := Chars[Base + 6];
      end;
      if (RightPanel^.Status <> stInfo) and
         (RightPanel^.State and sfMiniStatus <> 0) then
      begin
        Char(B[LeftPanel^.Size.X + 2]) := Chars[Base + 5];
        Char(B[Size.X - 1]) := Chars[Base + 6];
      end;
    end;

    if LeftHidden then UserScreenLine(I, 0, LeftSize, 0);
    if RightHidden then UserScreenLine(I, LeftSize, RightSize, LeftSize);
    WriteLine(0, I, Size.X, 1, B);
  end;

  MoveChar(B, Chars[Base], Color, Size.X);
  Char(B[0]) := Chars[Base + 7];
  Char(B[Size.X - 1]) := Chars[Base + 8];
  MoveDots(9);
  with PPanelWindow(Owner)^ do
  begin
    Char(B[LeftPanel^.Size.X + 1]) := Chars[Base + 8];
    Char(B[LeftPanel^.Size.X + 2]) := Chars[Base + 7];
    if LeftSelector <> nil then
      if LeftPanel^.DrvSelAlignment = daCenter then W := -1
      else W := LeftPanel^.Size.X - LeftSelector^.Size.X - 3
    else if LeftPanel^.DrvSelAlignment = daCenter then W := -1
    else W := LeftPanel^.Size.X - 2;
    LeftPanel^.GetVolumeTitle(PanelTitle, W);
    if PanelTitle <> '' then
    begin
      if LeftSelector <> nil then
        if LeftPanel^.DrvSelAlignment = daRight then I := 2
        else I := LeftSelector^.Size.X + 3
      else I := LeftPanel^.Size.X div 2 - Length(PanelTitle) div 2 + 1;
      MoveStr(B[I], PanelTitle, Color);
    end;
    if RightSelector <> nil then
      if RightPanel^.DrvSelAlignment = daCenter then W := -1
      else W := RightPanel^.Size.X - RightSelector^.Size.X - 3
    else if RightPanel^.DrvSelAlignment = daCenter then W := -1
    else W := RightPanel^.Size.X - 2;
    RightPanel^.GetVolumeTitle(PanelTitle, W);
    if PanelTitle <> '' then
    begin
      if RightSelector <> nil then
        if RightPanel^.DrvSelAlignment = daRight then I := 2
        else I := RightSelector^.Size.X + 3
      else I := RightPanel^.Size.X div 2 - Length(PanelTitle) div 2 + 1;
      MoveStr(B[LeftPanel^.Size.X + 2 + I], PanelTitle, Color);
    end;
  end;

  if LeftHidden then UserScreenLine(PanelHeight + 1, 0, LeftSize, 0);
  if RightHidden then UserScreenLine(
    PanelHeight + 1, LeftSize, RightSize, LeftSize);
  WriteLine(0, PanelHeight + 1, Size.X, 1, B);

  for I := PanelHeight + 2 to Size.Y - 1 do
  begin
    UserScreenLine(I, 0, LeftSize, 0);
    UserScreenLine(I, LeftSize, RightSize, LeftSize);
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

function TPanelFrame.GetPalette: PPalette;
const
  P: String[Length(CPanelFrame)] = CPanelFrame;
begin
  GetPalette := @P;
end;

procedure TPanelFrame.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evMouseMove) and
     ((GetShiftState and (kbAltShift + kbCtrlShift) =
       kbAltShift + kbCtrlShift) or PPanelWindow(Owner)^.MouseHintVisible) then
    PPanelWindow(Owner)^.DrawView;
  if (Event.What = evMouseDown) and (State and sfActive <> 0) then
    PanelFrameHandleMouseDownEventPrim(@Self, Event);
  inherited HandleEvent(Event);
end;

function TPanelFrame.GetMouseShape(var Event: TEvent): Char;
var
  C: Char;
  DMode: Byte;
  P: TPoint;
begin
  C := #0;
  if (State and sfActive <> 0) and
     (Owner^.State and sfFocused <> 0) then with PPanelWindow(Owner)^ do
  begin
    MakeLocal(Event.Where, P);
    if P.Y = 0 then
    begin
      DMode := GetTopPos(P.X);
      case DMode of
        tpLeftDrag, tpRightDrag,
        tpLeftMiddleResize, tpRightMiddleResize: C := '';
        tpLeftResize, tpRightResize: C := '';
        tpLeftColon, tpRightColon: C := ':';
        tpLeftName, tpRightName: C := '\';
      end;
    end
    else if P.Y = LeftPanel^.Size.Y + 1 then
    begin
      DMode := GetBottomPos(P.X);
      case DMode of
        bpLeftDrag, bpRightDrag: C := '';
        bpLeftResize, bpRightResize: C := '';
        bpMiddleResize: C := '';
      end;
    end
    else if P.Y <> Size.Y - 2 then
      C := Inherited GetMouseShape(Event);
  end;
  GetMouseShape := C;
end;

procedure SetPromptLineOptions(P: PPanelWindow; APromptLine: PPromptLine);
begin
  if P = nil then
  begin
    APromptLine^.Main := mnUnload;
    APromptLine^.Setup := suSaveEditorFiles + suSaveDesktop + suLoadSnipper;
    APromptLine^.Opt := opLoadCOMMANDCOM;
  end
  else
  begin
    APromptLine^.Main := P^.PromptLine^.Main;
    APromptLine^.Setup := P^.PromptLine^.Setup;
    APromptLine^.Opt := P^.PromptLine^.Opt;
  end;
end;

procedure SetPanelOptions(P, APanel: PPanel);
begin
{
  DisposeStr(APanel^.ListDir);
  APanel^.ListDir := NewStr(P^.ListDir^);
}
  DisposeStrUMB(APanel^.ListDir);
  APanel^.ListDir := NewStrUMB(P^.ListDir^);

  APanel^.Status := P^.Status;
  APanel^.OldStatus := P^.OldStatus;
  APanel^.OldFocused := P^.OldFocused;

  APanel^.Options := P^.Options and not ofValidate;
  APanel^.State := P^.State or sfVisible;
  APanel^.Settings := P^.Settings;
  APanel^.SortDescrPos := P^.SortDescrPos;
  APanel^.SortCaseSens := P^.SortCaseSens;
  APanel^.SortMode := P^.SortMode;
  APanel^.SortDirection := P^.SortDirection;
  APanel^.SortPriority := P^.SortPriority;
  APanel^.GroupOptions := P^.GroupOptions;
  APanel^.SortAction := P^.SortAction;
  APanel^.Main := P^.Main;
  APanel^.Setup := P^.Setup;
  APanel^.Opt := P^.Opt;
  APanel^.SortSel := P^.SortSel;
  APanel^.TimeMode := P^.TimeMode;
  APanel^.IgnoreListSpaces := P^.IgnoreListSpaces;
  APanel^.DrvSelAlignment := P^.DrvSelAlignment;
  APanel^.DrvSelSize := P^.DrvSelSize;
  APanel^.ColWidth := P^.ColWidth;
  APanel^.BarAlignment := P^.BarAlignment;
end;

constructor TPanelWindow.Init;
var
  P: PPanelWindow;
  R: TRect;

function IsFileManager(P: PView): Boolean; far;
begin
  IsFileManager := (P^.State and sfVisible <> 0) and
    (TypeOf(P^) = TypeOf(TPanelWindow));
end;

begin
  if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then P := nil
  else P := PPanelWindow(Desktop^.FirstThat(@IsFileManager));

  Desktop^.GetExtent(R);
{ Added 04.02.18 to support File Manager window number }
  if WinPosMask and wpIcons = 0 then
    TWindow.Init(R, 'File Manager', wnNoNumber)
  else TWindow.Init(R, 'File Manager', WindowNumAvail);

  GetExtent(R); R.A.Y := R.B.Y - 1;
  PromptLine := New(PPromptLine, Init(R, 128));
  PromptLine^.EventMask := PromptLine^.EventMask or evBroadcast;
  PromptLine^.GrowMode := gfGrowHiX + gfGrowLoY + gfGrowHiY;
  SetPromptLineOptions(P, PromptLine);
  PromptLine^.HistCount := $FF;
  Prompt := New(PPrompt, Init(R, '', PromptLine));
  Prompt^.GrowMode := gfGrowLoY + gfGrowHiY + gfGrowHiX;
  Insert(Prompt);
  Insert(PromptLine);

  R.Assign(1, 1, Size.X div 2 - 1, Size.Y - 2);
  LeftPanel := New(PPanel, Init(R));
  LeftPanel^.Which := pnLeft;
  LeftPanel^.GetBounds(LeftZoomRect);
  if P <> nil then SetPanelOptions(P^.LeftPanel, LeftPanel);
  Insert(LeftPanel);
  if LeftPanel^.Settings and seDriveSelector <> 0 then
    LeftPanel^.InitDriveSelector;
  if LeftPanel^.Settings and sePanelBar <> 0 then
    LeftPanel^.InitPanelBar;

  R.Assign(Size.X div 2 + 1, 1, Size.X - 1, Size.Y - 2);
  RightPanel := New(PPanel, Init(R));
  RightPanel^.Which := pnRight;
  RightPanel^.GetBounds(RightZoomRect);
  if P <> nil then SetPanelOptions(P^.RightPanel, RightPanel);
  Insert(RightPanel);
  if RightPanel^.Settings and seDriveSelector <> 0 then
    RightPanel^.InitDriveSelector;
  if RightPanel^.Settings and sePanelBar <> 0 then
    RightPanel^.InitPanelBar;

  LeftPanel^.Opposite := RightPanel;
  RightPanel^.Opposite := LeftPanel;

  if P = nil then LeftPanel^.Select
  else if P^.LeftPanel^.State and sfSelected <> 0 then LeftPanel^.Select
  else if P^.RightPanel^.State and sfSelected <> 0 then RightPanel^.Select
  else PromptLine^.Select;

  ReadDirectory;
  InitMacroList;
end;

procedure SetDriveSelector(Selector: PDriveSelector; Panel: PPanel);
begin
  Selector^.Panel := Panel;
  Selector^.GetDrives(' ');
  Selector^.AdjustBounds;
end;

constructor TPanelWindow.Load(var S: TStream);
begin
  TWindow.Load(S);
  GetSubViewPtr(S, Prompt);
  GetSubViewPtr(S, PromptLine);
  GetSubViewPtr(S, LeftPanel);
  GetSubViewPtr(S, RightPanel);
  if LeftPanel^.Settings and seDriveSelector <> 0 then
  begin
    GetSubViewPtr(S, LeftSelector);
    SetDriveSelector(PDriveSelector(LeftSelector), LeftPanel);
  end;
  if RightPanel^.Settings and seDriveSelector <> 0 then
  begin
    GetSubViewPtr(S, RightSelector);
    SetDriveSelector(PDriveSelector(RightSelector), RightPanel);
  end;
  if LeftPanel^.Settings and sePanelBar <> 0 then
  begin
    GetSubViewPtr(S, LeftBar);
    PPanelBar(LeftBar)^.Panel := LeftPanel;
  end;
  if RightPanel^.Settings and sePanelBar <> 0 then
  begin
    GetSubViewPtr(S, RightBar);
    PPanelBar(RightBar)^.Panel := RightPanel;
  end;
  S.Read(LeftZoomRect, SizeOf(TRect) * 2);
  LeftPanel^.Opposite := RightPanel;
  RightPanel^.Opposite := LeftPanel;
  ReadDirectory;
  InitMacroList;
end;

destructor TPanelWindow.Done;
begin
  DoneMacroList;
  if RightPanel^.FoundFiles = LeftPanel^.FoundFiles then
    RightPanel^.FoundFiles := nil;
  TWindow.Done;
end;

procedure TPanelWindow.ChangeBounds(var Bounds: TRect);
begin
  if LeftPanelSize = 0 then LeftPanelSize := LeftPanel^.Size.X;
  LeftPanelRatio := LeftPanelSize / (Size.X - 4);
  TWindow.ChangeBounds(Bounds);
end;

procedure TPanelWindow.Close;
begin
  if NoPromptOnClose or (ConfirmOptions and coCloseFileManager = 0) or
    (MessageBox(^C'Close the File Manager window ?',
      nil, mfConfirmation + mfOkCancel) = cmOk) then TWindow.Close;
end;

procedure TPanelWindow.Draw;
var
  T: Byte;
  Color: Word;
  P: TPoint;
  Panel: PPanel;
  S, SS: String;
  B: TDrawBuffer;
begin
  inherited Draw;
  MouseHintVisible := False;
  if (State and sfFocused = 0) or (FMOptions and foAltCtrlNames = 0) or
     (GetShiftState and (kbAltShift + kbCtrlShift) <>
      kbAltShift + kbCtrlShift) then Exit;
  MakeLocal(MouseWhere, P);
  if P.Y = 0 then T := GetTopPos(P.X) else T := tpNo;
  if T in [tpLeftColon, tpLeftName] then Longint(MouseHintItem) := 1
  else if T in [tpRightColon, tpRightName] then Longint(MouseHintItem) := 2
  else if ((LeftPanel^.State and sfVisible <> 0) and
    (LeftSelector <> nil) and LeftSelector^.MouseInView(MouseWhere)) or
    ((RightPanel^.State and sfVisible <> 0) and
     (RightSelector <> nil) and RightSelector^.MouseInView(MouseWhere)) then
       Longint(MouseHintItem) := 3
  else
  begin
    if LeftPanel^.MouseInView(MouseWhere) and
      (LeftPanel^.PointedItem <> nil) and
      (LeftPanel^.PointedItem <> PPanelRec(LeftPanel)) then
        Panel := LeftPanel
    else if RightPanel^.MouseInView(MouseWhere) and
      (RightPanel^.PointedItem <> nil) and
      (RightPanel^.PointedItem <> PPanelRec(RightPanel)) then
        Panel := RightPanel
    else Exit;
    MouseHintItem := Panel^.PointedItem;
  end;
  SetPanelWindowHintStr(@Self, Panel, S);
  MouseHintItem := nil;
  Inc(P.X);
  if P.X + Length(S) >= Size.X then P.X := Size.X - Length(S);
  if P.X < 0 then P.X := 0;
  Color := Application^.GetColor(cMouseHintText);
  repeat
    MoveChar(B, ' ', Byte(Color), Size.X);
    SS := System.Copy(S, 1, Size.X);
    System.Delete(S, 1, Size.X);
    MoveStr(B, SS, Color);
    WriteLine(P.X, P.Y, Length(SS), 1, B);
    Inc(P.Y);
  until S = '';
  MouseHintVisible := True;
end;

function TPanelWindow.GetHelpCtx: Word;
var
  AltCtrlDown: Boolean;
  W: Word;
  E: TEvent;
begin
  W := TWindow.GetHelpCtx;
  GetHelpCtx := W;
  if (W = hcDragging) or (W = hcPromptLine) then Exit;
  if (((FMSearchOptions and fsAltActivates <> 0) and AltStroke) or
     ((FMSearchOptions and fsCtrlActivates <> 0) and CtrlStroke)) then
  begin
    AltStroke := False;
    CtrlStroke := False;
    if State and sfSearching = 0 then ActivateSearching
    else DeactivateSearching(nil);
  end;
  W := GetShiftState;
  AltCtrlDown := W and (kbAltShift + kbCtrlShift) = kbAltShift + kbCtrlShift;
  if AltCtrlDown <> PrevAltCtrlDown then
  begin
    PrevAltCtrlDown := AltCtrlDown;
    if MouseHintVisible then
    begin
      E.What := evMouseMove;
      E.Where := MouseWhere;
      LeftPanel^.HandleEvent(E);
      RightPanel^.HandleEvent(E);
    end;
  end;
  if (W and (kbLeftShift + kbRightShift) <> 0) or
     (KbdStatus in [57, 224]) or (MouseButtons <> 0) then Exit;
  if LeftPanel^.SortSel and LeftPanel^.SelChanged then
    SortSelPrim(LeftPanel);
  if RightPanel^.SortSel and RightPanel^.SelChanged then
    SortSelPrim(RightPanel);

{Added 2005.12.31 }
  if CN_NT and (MemW[$40:$6C] - NT_DirCheckTicks >= 50) then
  begin
    NT_DirCheckTicks := MemW[$40:$6C];
    if NT_DirCheck(LeftPanel^.NT_DirCheckHandle) then
      LeftPanel^.ReReadPrim(False);
    if NT_DirCheck(RightPanel^.NT_DirCheckHandle) then
      RightPanel^.ReReadPrim(False);
  end;
end;

function TPanelWindow.GetPalette: PPalette;
const
  P: String[Length(CPanelWindow)] = CPanelWindow;
begin
  GetPalette := @P;
end;

function TPanelWindow.GetTitle(MaxSize: Integer): TTitleStr;

function GetPanelTitle(Panel: PPanel): String;
var
  X: Integer;
  T: String;
begin
  X := Panel^.Size.X;
  Panel^.Size.X := 255;
  Panel^.GetTitle(T);
  Panel^.Size.X := X;
  GetPanelTitle := Trim(T);
end;

begin
  GetTitle := Title^ + ': [' +
    GetPanelTitle(LeftPanel) + ']-[' +
    GetPanelTitle(RightPanel) + ']'; ;
end;

procedure TPanelWindow.HandleEvent(var Event: TEvent);
var
  DMode: Byte;
  SaveState: Word;
  Limits: TRect;
  Min, Max: TPoint;
  S: String;
begin
  if (Event.What = evKeyDown) and (MacroList <> nil) and
    PreprocessEnabled(Event) then
      PreprocessKeyEvent(MacroList, Event);
  if (Event.What = evCommand) and (Event.Command = cmResize) then
  begin
    Owner^.GetExtent(Limits);
    SizeLimits(Min, Max);
    DMode := DragMode or (Flags and (wfMove + wfGrow));
    DragPanelsPrim(@Self, Event, DMode, Limits, Min, Max);
    Event.What := evNothing;
  end;
  if (Event.What = evMouseDown) and (State and sfActive <> 0) then
    PanelWindowHandleMouseDownEventPrim(@Self, Event);
  if Event.What = evKeyDown then
    if (Event.KeyCode = kbEsc) and
       (GetShiftState and (kbLeftShift + kbRightShift) <> 0) then
    begin
      Event.What := evCommand;
      Event.Command := cmClose;
      Event.InfoPtr := @Self;
    end
    else if (Event.KeyCode = kbEsc) and (State and sfSearching <> 0) then
    begin
      DeactivateSearching(nil);
      Event.What := evNothing;
    end
    else if Event.CharCode = ^O then
    begin
      ToggleBothPanelsPrim(@Self);
      Event.What := evNothing;
    end
    else case Event.KeyCode of
      kbEnter: PromptLine^.HandleEvent(Event);
      kbTab, kbShiftTab:
        if (LeftPanel^.State and sfVisible = 0) or
           (RightPanel^.State and sfVisible = 0) then
          Event.What := evNothing
        else if PView(PromptLine) = Current then
        begin
          Owner^.Lock;
          GetCurrentPanel;
          CurrentPanel^.Opposite^.Select;
          PromptLine^.Select;
          Owner^.Unlock;
          Event.What := evNothing;
        end
        else
        begin
          PPanel(Current)^.Opposite^.Select;
          Event.What := evNothing;
        end;
      kbCtrlUp, kbCtrlDn, kbCtrlLeft, kbCtrlRight,
      $1A1B, $1B1D {Ctrl+[, Ctrl+]}, kbSpace:
        PanelWindowHandleCtrlKeyEventPrim(@Self, Event);
      kbF2, kbShiftF9:
        begin
          UserMenuDlg(nil, Event.KeyCode = kbShiftF9);
          Event.What := evNothing;
        end;
{ Added 04.08.08 to support InputLine AutoComplete }
      kbDel:
        if (PromptLine^.State and sfSelected = 0) and
           (PromptLine^.Data^ <> '') then
        begin
          SaveState := PromptLine^.State;
          PromptLine^.State := PromptLine^.State or sfSelected;
          PromptLine^.HandleEvent(Event);
          PromptLine^.State := SaveState;
        end;
      kbBack:
        if (State and sfSearching = 0) and
           (FMOptions and foBackGoesPrev <> 0) and
           (PromptLine^.Data^ = '') then Event.KeyCode := kbCtrlPgUp;
      kbEsc:
        if (FMOptions and foEscTogglesPanels <> 0) and
           (PromptLine^.Data^ = '') then
        begin
          Event.KeyCode := $180F; {^O}
          HandleEvent(Event);
        end
        else PromptLine^.HandleEvent(Event);
{ Added 2005.09.26 }
      kbLeft, kbRight:
        if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
           (PromptLine^.Data^ <> '') then
        begin
          SaveState := PromptLine^.State;
          PromptLine^.State := PromptLine^.State or sfSelected;
          PromptLine^.HandleEvent(Event);
          PromptLine^.State := SaveState;
        end;
    end;
  TWindow.HandleEvent(Event);
  if (Event.What = evKeyDown) and
     (Event.CharCode <> #0) and
     (PromptLine^.State and sfSelected = 0) then
  begin
    SaveState := PromptLine^.State;
    PromptLine^.State := PromptLine^.State or sfSelected;
    PromptLine^.HandleEvent(Event);
    PromptLine^.State := SaveState;
  end;
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmIncSearch: ActivateSearching;
      cmSelectLeftDrive: SelectDrivePrim(LeftPanel, #0, True);
      cmSelectRightDrive: SelectDrivePrim(RightPanel, #0, True);
      cmFind, cmFindFileDlg, cmShiftCopy, cmShiftRenMov, cmFMkDir,
      cmShiftMkDir, cmShiftDelete, cmChangeDirectory,
      cmSelectGroup, cmUnselectGroup, cmChange, cmInvert,
      cmRestoreSelection:
        begin
          GetCurrentPanel;
          CurrentPanel^.HandleEvent(Event);
        end;
      cmTogglePanels: ToggleBothPanelsPrim(@Self);
      cmToggleLeftPanel: TogglePanelPrim(@Self, LeftPanel, tmByF);
      cmToggleRightPanel: TogglePanelPrim(@Self, RightPanel, tmByF);
      else Exit;
    end;
    Event.What := evNothing;
  end;
  if Event.What = evBroadcast then
    case Event.Command of
      cmFileManager:
        if (State and sfActive <> 0) and (State and sfSelected <> 0) then
        begin
          Event.What := evNothing;
          Event.InfoPtr := nil;
        end
        else if State and (sfActive + sfSelected) = 0 then
        begin
          Deiconize;
          Show;
          Select;
          ClearEvent(Event);
        end;
      cmNewPrompt: if Event.InfoPtr <> nil then Frame^.DrawView;
      cmGetSource: if State and sfVisible <> 0 then
        begin
          Event.What := evNothing;
          GetCurrentPanel;
          CurrentPanel^.GetSource(S);
          Event.InfoPtr := @S;
        end;
      cmGetOppositePath: if State and sfVisible <> 0 then
        begin
          Event.What := evNothing;
          GetCurrentPanel;
          Event.InfoPtr := CurrentPanel^.Opposite^.ListDir;
        end;
      cmFindFileDlg: if Event.InfoPtr = Desktop then
        begin
          GetCurrentPanel;
          FindFileDlgPrim(CurrentPanel);
          Event.What := evNothing;
        end
        else UpdateFoundFiles;
      cmReloadMacroList: InitMacroList;
      cmUserMacros: if (MacroList <> nil) and
        (CompUCString(PString(Event.InfoPtr)^,
          CNFileName(FMMacroName)) = Equal) then InitMacroList;
      cmGetMacroName: if (State and sfActive <> 0) and
        (State and sfSelected <> 0) and (MacroList <> nil) then
        begin
          Event.What := evNothing;
          Event.InfoPtr := @FMMacroName;
        end;
      cmQuit: if Event.InfoPtr <> nil then NoPromptOnClose := True;
      cmReRead: if DestName <> nil then
        begin
          GetCurrentPanel;
          CurrentPanel^.FocusFileName(DestName^);
          CurrentPanel^.Opposite^.FocusFileName(DestName^);
          DisposeStr(DestName);
          DestName := nil;
        end;
      cmCDFM:
        begin
          Event.What := evNothing;
          S := AddedSlash(lFExpand(CNFileName(ExecRec.Params)));
          GetCurrentPanel;
          CurrentPanel^.SwitchToDir(AddedSlash(S), True);
        end;
    end;
end;

procedure TPanelWindow.InitFrame;
var
  R: TRect;
begin
  GetExtent(R);
  Dec(R.B.Y);
  Frame := New(PPanelFrame, Init(R));
end;

procedure TPanelWindow.SetState(AState: Word; Enable: Boolean);
var
  S: FNameStr;

procedure SendPromptMsg(P: PPanel);
begin
  if P^.Status < stTree then
  begin
    S := P^.ListDir^;
    Message(@Self, evBroadcast, cmNewPrompt, @S);
  end;
end;

begin
  TWindow.SetState(AState, Enable);
  if (AState = sfSelected) and Enable then
  begin
    GetCurrentPanel;
    SendPromptMsg(CurrentPanel^.Opposite);
    SendPromptMsg(CurrentPanel);
  end;
  if AltStroke or CtrlStroke then
  begin
    AltStroke := False;
    CtrlStroke := False;
  end;
end;

procedure TPanelWindow.SizeLimits(var Min, Max: TPoint);
begin
  TWindow.SizeLimits(Min, Max);
  Min.X := MinPanelWidth * 2 + 4;
  Min.Y := 7;
end;

procedure TPanelWindow.Store(var S: TStream);
var
  Same: Boolean;
  List: PFindFileCollection;
begin
  if RightPanel^.FoundFiles = LeftPanel^.FoundFiles then
  begin
    GetCurrentPanel;
    List := New(PFindFileCollection, Init(32, 16));
    CurrentPanel^.Opposite^.FoundFiles := List;
    Same := True;
  end
  else Same := False;
  TWindow.Store(S);
  PutSubViewPtr(S, Prompt);
  PutSubViewPtr(S, PromptLine);
  PutSubViewPtr(S, LeftPanel);
  PutSubViewPtr(S, RightPanel);
  if LeftSelector <> nil then PutSubViewPtr(S, LeftSelector);
  if RightSelector <> nil then PutSubViewPtr(S, RightSelector);
  if LeftBar <> nil then PutSubViewPtr(S, LeftBar);
  if RightBar <> nil then PutSubViewPtr(S, RightBar);
  S.Write(LeftZoomRect, SizeOf(TRect) * 2);
  if Same then
  begin
    Dispose(List, Done);
    CurrentPanel^.Opposite^.FoundFiles := CurrentPanel^.FoundFiles;
  end;
end;

procedure TPanelWindow.Zoom;
begin
  ZoomPrim(@Self);
end;

procedure TPanelWindow.GetCurrentPanel;
var
  S: FNameStr;
begin
  if CurrentPanel <> nil then Exit;
  if LeftPanel^.Options and ofCurrent <> 0 then
    SetCurrentPanel(LeftPanel)
  else if RightPanel^.Options and ofCurrent <> 0 then
    SetCurrentPanel(RightPanel)
  else
  begin
    RightPanel^.GetListDir(S);
    if ClearedSlash(Prompt^.Text^) = S then
      SetCurrentPanel(RightPanel)
    else SetCurrentPanel(LeftPanel);
  end;
end;

procedure TPanelWindow.SetCurrentPanel(APanel: PPanel);
begin
  CurrentPanel := APanel;
  CurrentPanel^.Options := CurrentPanel^.Options or ofCurrent;
  CurrentPanel^.Opposite^.Options :=
    CurrentPanel^.Opposite^.Options and not ofCurrent;
end;

function TPanelWindow.GetTopPos(X: Integer): Byte;
var
  LeftHidden, RightHidden: Boolean;
  LeftSize, RightSize: Integer;
begin
  LeftHidden := LeftPanel^.State and sfVisible = 0;
  RightHidden := RightPanel^.State and sfVisible = 0;
  LeftSize := LeftPanel^.Size.X;
  RightSize := RightPanel^.Size.X;
  if (LeftHidden and (X <= LeftPanel^.Size.X + 1)) or
     (RightHidden and (X > LeftPanel^.Size.X + 1)) then
    GetTopPos := tpNo
  else if X = 0 then GetTopPos := tpLeftResize
  else if (X > 0) and (X < 5) then GetTopPos := tpClose
  else if (LeftTitleLen <> 0) and (X >= LeftTitlePos) and
    (X < LeftTitlePos + 2 + Byte(LeftTitleLen > 4)) then
      GetTopPos := tpLeftColon
  else if (LeftTitleLen <> 0) and (X >= LeftTitlePos) and
    (X < LeftTitlePos + LeftTitleLen) then
      GetTopPos := tpLeftName
  else if RightHidden and (LeftSize > 6) and
    (X > LeftSize - 4) and (X < LeftSize + 1) then
      if X < LeftSize - 1 then GetTopPos := tpZoom
      else GetTopPos := tpMini
  else if X < LeftSize + 1 then GetTopPos := tpLeftDrag
  else if X = LeftSize + 1 then GetTopPos := tpLeftMiddleResize
  else if X = LeftSize + 2 then GetTopPos := tpRightMiddleResize
  else if LeftHidden and (RightSize > 6) and
    (X > LeftSize + 2) and (X < LeftSize + 7) then
      GetTopPos := tpClose
  else if (RightTitleLen <> 0) and (X >= RightTitlePos) and
    (X < RightTitlePos + 2 + Byte(RightTitleLen > 4)) then
      GetTopPos := tpRightColon
  else if (RightTitleLen <> 0) and (X >= RightTitlePos) and
    (X < RightTitlePos + RightTitleLen) then
      GetTopPos := tpRightName
  else if X > Size.X - 6 then
    if X < Size.X - 3 then GetTopPos := tpZoom
    else if X < Size.X - 1 then GetTopPos := tpMini
    else GetTopPos := tpRightResize
  else GetTopPos := tpRightDrag;
end;

function TPanelWindow.GetBottomPos(X: Integer): Byte;
begin
  if ((LeftPanel^.State and sfVisible = 0) and
      (X <= LeftPanel^.Size.X + 1)) or
     ((RightPanel^.State and sfVisible = 0) and
      (X > LeftPanel^.Size.X + 1)) then GetBottomPos := bpNo
  else if X = 0 then GetBottomPos := bpLeftResize
  else if (X < LeftPanel^.Size.X + 1) and not
    ((LeftSelector <> nil) and (X >= LeftSelector^.Origin.X) and
     (X < LeftSelector^.Origin.X + LeftSelector^.Size.X)) then
       GetBottomPos := bpLeftDrag
  else if (X = LeftPanel^.Size.X + 1) or
    (X = LeftPanel^.Size.X + 2) then GetBottomPos := bpMiddleResize
  else if X >= Size.X - 2 then GetBottomPos := bpRightResize
  else if (X > LeftPanel^.Size.X + 2) and not
    ((RightSelector <> nil) and (X >= RightSelector^.Origin.X) and
     (X < RightSelector^.Origin.X + RightSelector^.Size.X)) then
       GetBottomPos := bpRightDrag
  else GetBottomPos := bpNo;
end;

procedure TPanelWindow.ReadDirectory;
var
  I: Integer;
begin
  if (LeftPanel^.Status < stInfo) and
     (RightPanel^.Status >= stInfo) then
    LeftPanel^.NewDir(LeftPanel^.ListDir^, True)
  else
  if (LeftPanel^.Status >= stInfo) and
     (RightPanel^.Status < stInfo) then
    RightPanel^.NewDir(RightPanel^.ListDir^, True)
  else
  begin
    LeftPanel^.NewDir(LeftPanel^.ListDir^, True);
    RightPanel^.NewDir(RightPanel^.ListDir^, True);
  end;
  with LeftPanel^ do
  begin
    GetItemNum(FocusedName^, I);
    FocusItem(I);
  end;
  with RightPanel^ do
  begin
    GetItemNum(FocusedName^, I);
    FocusItem(I);
  end;
  UpdateFoundFiles;
end;

procedure TPanelWindow.UpdateFoundFiles;
begin
  if FMOptions and foSameList <> 0 then
  begin
    if RightPanel^.FoundFiles = LeftPanel^.FoundFiles then Exit;
    GetCurrentPanel;
    if CurrentPanel^.Opposite^.FoundFiles <> nil then
      Dispose(CurrentPanel^.Opposite^.FoundFiles, Done);
    CurrentPanel^.Opposite^.FoundFiles := CurrentPanel^.FoundFiles;
  end
  else
  begin
    if RightPanel^.FoundFiles <> LeftPanel^.FoundFiles then Exit;
    GetCurrentPanel;
    CurrentPanel^.Opposite^.FoundFiles :=
      New(PFindFileCollection, Init(32, 16));
  end;
end;

procedure TPanelWindow.ActivateSearching;

procedure CalcCursorPos(P: PPanel);
begin
  with P^ do
  begin
    if Status = stTree then
      if Focused = 0 then CursorPos := 1
      else CursorPos :=
        (PTreeRec(TheTree^.At(Focused))^.Info and $7F + 1) * 3 + 1
    else CursorPos := 0;
    DrawView;
  end;
end;

begin
  if State and sfSearching <> 0 then Exit;
  GetCurrentPanel;
  if CurrentPanel^.Status >= stInfo then Exit;
  State := State or sfSearching;
  CalcCursorPos(LeftPanel);
  CalcCursorPos(RightPanel);
end;

procedure TPanelWindow.DeactivateSearching(APanel: PPanel);

procedure ResetCursorPos(P: PPanel);
begin
  with P^ do
  begin
    SearchStr := '';
    SearchPos := 1;
    CursorPos := -1;
    DotPos := -1;
    SearchLevel := $FF;
    HideCursor;
    if P <> APanel then DrawView;
  end;
end;

begin
  State := State and not sfSearching;
  ResetCursorPos(LeftPanel);
  ResetCursorPos(RightPanel);
end;

procedure TPanelWindow.InitMacroList;
begin
  DoneMacroList;
  if FMMacroName <> '' then
  begin
    ReadMacros(FMMacroName, MacroList);
    EventMask := EventMask and not emHiBit;
  end;
end;

procedure TPanelWindow.DoneMacroList;
begin
  EventMask := EventMask or emHiBit;
  if MacroList <> nil then
  begin
    Dispose(MacroList, Done);
    MacroList := nil;
  end;
end;

function TPanelWindow.PreprocessEnabled(var Event: TEvent): Boolean;
begin
  PreprocessEnabled :=
    (PromptLine^.State and sfSelected <> 0) or
    (State and sfSearching = 0) or
    not (Event.CharCode in [^B, ^L, #8, #32..#42, #44..#255]);
end;

procedure FileManager;
begin
  if Message(Desktop, evBroadcast, cmFileManager, nil) = nil then
    Application^.InsertWindow(New(PPanelWindow, Init));
end;

end.