unit Defaults;

interface

const
  NameLen = 79;
  ParamLen = 127;

var
  ConfigPath: String[67];
  ConfigMask: String[8];
  ReportFile: String[NameLen];

  DefaultPalette: String;

const
  eoBackupFiles = $00001;
  eoInsertMode = $00002;
  eoAutoIndentMode = $00004;
  eoUseTabs = $00008;
  eoEscCloses = $00010;
  eoUseEMS = $00020;
  eoSyntax = $00040;
  eoPromptOnNew = $00080;
  eoChangeDirOnOpen = $00100;
  eoCascade = $00200;
  eoFindTextAtCursor = $00400;
  eoEnableUndo = $00800;
  eoEnableWrap = $01000;
  eoWordDivision = $02000;
  eoExpandLine = $04000;
  eoLiteralInput = $08000;
  eoInsertPairs = $10000;
  eoHilitCurLine = $20000;
  eoHilitCurColumn = $40000;
  eoHilitPageBreak = $80000;
  eoHilitBounds = $100000;
  eoAutoSpaces = $200000;
  eoNonPersistent = $400000;
  eoOverwriteBlocks = $800000;
  eoWrapLinesOnLoad = $1000000;
  eoUnwrapLinesOnSave = $2000000;
  eoWriteCRLF = $4000000;
  eoWriteEOF = $8000000;
  eoHomeToggles = $10000000;
  eoPasteGoesToEnd = $20000000;
  eoSmartTabs = $40000000;
  eoTrailingBlanks = $80000000;

  neoWriteCRLF = $04;
  neoWriteEOF = $08;
  neoHomeToggles = $10;
  neoPasteGoesToEnd = $20;
  neoSmartTabs = $40;
  neoTrailingBlanks = $80;

  DefEditOptions = eoInsertMode + eoAutoIndentMode + eoEscCloses +
    eoSyntax + eoPromptOnNew + eoCascade + eoFindTextAtCursor +
    eoEnableUndo;

  EditOptions: Longint = DefEditOptions;

  EditOptMask = $83FFFFFF;

  NewEditOptions: Word = 0;

  TabSize: Byte = 8;
  MaxLineWidth: Byte = 64;

  DefWordDelims =
    [#32, #34, #39..#45, #47, #58..#63, #91..#94, #123..#126];
  WordDelims: Set of Char = DefWordDelims;

  MarkColumns: Boolean = False;

  SameWinFlag: Boolean = False;

  HistOpenOrg: Longint = 0;
  HistOpenSize: Longint = 0;
  HistOpenWide: Boolean = False;
  OpenWideFiller = $4F;     {'O'}
  OpenWideSign = $4F4F4F4F; {'O' 'O' 'O' 'O'}

  foInsMovesDown = 1;
  foAutoChangeDir = 2;
  foCopyLeft = 4;
  foUnsel = $8;
  foDragPrompt = $10;
  foDirDelPrompt = $20;
  foSameList = $40;
  foCheckFreeSpace = $80;
  foRereadUnselects = $100;
  foDrawEmpty = $200;
  foCopyDescriptions = $400;
  foSaveSelection = $800;
  foLoadCurDir = $1000;
  foAltTreeinfo = $2000;
  foNoAutoUpdateTree = $4000;
  foNoMaskDescriptions = $8000;
  foResetUnfoldFlag = $10000;
  foBackGoesPrev = $20000;
  foEscTogglesPanels = $40000;
  foDelErasesFiles = $80000;
  foSpaceSelects = $100000;
  foForceUpperDirs = $200000;
  foDrvSelDifCtrl = $400000;
  foOpenFocused = $800000;
  foAltCtrlNames = $1000000;
  foSpaceSizes = $2000000;
  foSpaceMovesDown = $4000000;
  foAltF3MovesDown = $8000000;
  foCapsLockSearch = $10000000;
  foXPanel = $20000000;

  DefFMOptions = foInsMovesDown + foCopyLeft + foUnsel + foDirDelPrompt;
  FMOptions: Longint = DefFMOptions;

  fsSearchCaseSensitive = 1;
  fsIgnoreInterChar = 2;
  fsAltActivates = 4;
  fsCtrlActivates = 8;
  DefFMSearchOptions = fsIgnoreInterChar;
  FMSearchOptions: Byte = DefFMSearchOptions;

  dcSize = 1;
  dcTime = 2;
  dcAttr = 4;
  dcBoth = 8;
  dcUnselSame = $10;
  dcPrompt = $20;
  DefCompareOptions = dcSize + dcTime + dcAttr + dcBoth;
  CompareOptions: Byte = DefCompareOptions;

  caNo = 0;
  caGreater = 2;
  caLess = 1;
  caCompareContents = $0001;
  caDoNotSelectMissing = $0002;
  CmpAdvOpt: Longint = 0;
  AddCmpOpt: Word = 0;

  faModifiedOnly = 0;
  faAlways = 1;
  faNever = 2;
  DefFMAutoRereadOptions = faModifiedOnly;
  FMAutoRereadOptions: Byte = DefFMAutoRereadOptions;

  TagChar: Char = #0;

  fePrompt = 0;
  feOverwrite = 1;
  feSkip = 2;
  feCompare = 3;

  fcNewerLonger = 0;
  fcNewerShorter = 1;
  fcNewerSame = 2;
  fcOlderLonger = 3;
  fcOlderShorter = 4;
  fcOlderSame = 5;
  fcSameLonger = 6;
  fcSameShorter = 7;
  fcSame = 8;

  faPrompt = 0;
  faResume = 5;
  faOverwrite = 4;
  faAppend = 3;
  faNew = 2;
  faSkip = 1;

  fsCheckFreeSpace = $01;
  fsCopyDescriptions = $02;
  fsClearReadOnly = $04;
  fsUnselectSkipped = $08;
  fsDisableCopyBar = $10;
  fsDisableCopyStat = $20;
  fsEnableRecursive = $40;
  fsSkipEmptyDirs = $80;
{ Added 2006.01.17 to support NT_SysCopy }
  fsNT_SysCopy = $2000;
{ Added 2005.12.30 to support NT delete to recycle bin }
  fsDelToTrash = $4000;
{ Added 2005.09.16 to support prompt before file operation }
  fsConfirmFileOperation = $8000;

  frRestoreCopySettings = $01;
  frRestoreFMOptions = $02;

  FileExistsAction: Word = 0;
  FileCompareAction: Longint = 0;
  FileCopyOptions: Word = 0;
  FMCopySettings: Word = 0;

  SaveFileExistsAction: Word = 0;
  SaveFileCompareAction: Longint = 0;
  SaveFileCopyOptions: Word = 0;
  SaveFMCopySettings: Word = 0;
  SaveFMOptions: Longint = 0;

  MultitaskerDetected: Boolean = False;

{ Added 2005.12.25 }
  CN_NT: Boolean = False;

  UnixFlag: Boolean = False;

  GlobalEmptyFlag: Boolean = False;
  GlobalRedrawLock: Boolean = False;
  GlobalQuietExec: Boolean = False;

  DefDirinfoNames = 'DIRINFO';
  DirinfoNames: String[NameLen] = DefDirinfoNames;

  DefBBSNames = 'FILES.BBS';
  BBSNames: String[NameLen] = DefBBSNames;

  FMMacroName: String[NameLen] = '';

  DefBBSSpaces = 1;
  BBSSpaces: Byte = DefBBSSpaces;

  bbFormatData = 1;
  BBSOptions: Byte = 0;

  DefFMAutoDelay = 320;
  FMAutoDelay: Word = DefFMAutoDelay;

  ooAddLineFeed = 1;
  ooAddReturn = 2;
  ooAutoWrap = 4;
  ooDestructiveBS = 8;
  toLocalEcho = $10;
  toStripHighBit = $20;
  toUseBack = $40;
  toHexBack = $80;
  toInsMode = $8000;

  OutputWidth: Integer = 80;
  OutputHeight: Integer = 24;
  MaxOutputLines = 80;
  DefOutputOptions = ooAutoWrap + ooDestructiveBS;
  OutputOptions: Word = DefOutputOptions;

  TerminalWidth: Integer = 80;
  TerminalHeight: Integer = 24;
  DefTerminalOptions = ooAutoWrap + ooDestructiveBS + toLocalEcho;
  TerminalOptions: Word = DefTerminalOptions;

  TermcapName: String[NameLen] = '';
  TermcapIden: String[ParamLen] = '';
  InputXLATName: String[NameLen] = '';
  OutputXLATName: String[NameLen] = '';
  TermMacroName: String[NameLen] = '';

  TheTerminal: Pointer = nil;
  TheBack: Pointer = nil;

  TerminalDisabled: Boolean = False;

  auYesAndDo = 0;
  auYesAndDoNot = 1;
  auNo = 2;
  auPrompt = 3;
  DefAbortUser = auPrompt;
  AbortUser: Byte = DefAbortUser;

  ddButtonDown = 0;
  ddButtonUp = 1;
  DefddMode = ddButtonDown;
  ddMode: Byte = DefddMode;

  Auto: Boolean = True;

  AutoSaveTime: Word = 0;

  EndingBeepTime: Word = 0;

  ScreenSaver: Pointer = nil;
  SaverDelay: Integer = 2;
  IdleSeconds: Word = 0;
  NowSecond: Byte = 0;

  AnimateDelay: Word = 0;

  OpenCPUWindow: Boolean = False;

  LstFlag: Boolean = False;

  RGBOptions: Word = 0;

  ModemInitLen = 127;
  ModemHangupLen = 31;
  ModemAnswerLen = 31;
  ModemCancelLen = 31;
  ModemConnectLen = 31;
  ModemBusyLen = 31;
  ModemRingLen = 31;
  ModemBreakLen = 31;
  PrefLen = 31;
  SuffLen = 31;
  RedialDelayLen = 5;
  ModemInitStr: String[ModemInitLen] = '';
  ModemHangupStr: String[ModemHangupLen] = '';
  ModemAnswerStr: String[ModemAnswerLen] = '';
  ModemCancelStr: String[ModemCancelLen] = '';
  ModemConnectStr: String[ModemConnectLen] = '';
  ModemBusyStr: String[ModemBusyLen] = '';
  ModemRingStr: String[ModemRingLen] = '';
  ModemBreakStr: String[ModemBreakLen] = '';
  DialPrefix: String[PrefLen] = '';
  DialSuffix: String[SuffLen] = '';
  RedialDelay: String[RedialDelayLen] = '';

  ModemProtocol: Byte = 0;
  DownloadDir: String[67] = '';

  poRequireCD = 1;
  poRTSLowForWrite = 2;
  poHangupAfter = 4;
  ProtOptions: Byte = 0;

  zmAutoDownload = 1;
  zmResume = 2;
  DefZmodemOptions = zmAutoDownload + zmResume;
  ZmodemOptions: Byte = DefZmodemOptions;

  zoAlways = 0;
  zoNever = 1;
  zoPrompt = 2;
  DefZmodemOverwrite = zoPrompt;
  ZmodemOverwrite: Byte = DefZmodemOverwrite;

  pbUpload = 1;
  pbDownload = 2;
  DefReverseBar = pbDownload;
  ReverseBar: Byte = DefReverseBar;
  ProtInProg: Boolean = False;

  ASCIICharDelay: Word = 0;
  ASCIILineDelay: Word = 0;

  ProtocolPrompt: Boolean = False;

  loEnable = 1;
  DefEnableLog = 0;
  EnableLog: Byte = DefEnableLog;

  lcDiskRead = 1;
  lcDiskWrite = 2;
  lcExec = 4;
  lcCommun = 8;
  lcError = $10;
  lcWarning = $20;
  lcConfirm = $40;
  lcInfo = $80;
  lcConfig = $100;
  lcOther = $200;
  DefLogClass = lcDiskRead + lcDiskWrite + lcExec + lcCommun + lcConfig +
    lcError + lcWarning + lcConfirm + lcInfo + lcOther;
  LogClass: Word = defLogClass;
  LogEvent: Word = lcOther;

  DefLogName = 'CONNECT.LOG';
  LogName: String[NameLen] = DefLogName;

  hvMenuBar = 1;
  hvStatusLine = 2;
  hvClock = 4;
  hvHeap = 8;
  HideOptions: Byte = hvMenuBar + hvClock + hvHeap;

  trAuto = 0;
  trDOS = 1;
  trUNIX = 2;
  TextReadMode: Byte = trAuto;

  adText = 1;
  adHTML = 2;
{ Added 04.08.08 to support InputLine AutoComplete }
  adAutoComplete = $80;
  AutoDecode: Byte = 0;

  LastIdleTime: Longint = 0;

  DisableSysInfo: Boolean = False;
  DisableSounds: Boolean = False;
  LocalAssocs: Boolean = False;

  PrnInitLen = 31;
  PrnMarginLen = 3;
  PrnLinesLen = 3;
  PrnIntervalLen = 5;
  PrnCycleLen = 5;
  poFont = 1;
  poBold = 2;
  poPage = 4;
  PrnDeviceName: String[NameLen] = '';
  PrnFontName: String[NameLen] = '';
  PrnOptions: Word = 0;
  PrnInitString: String[PrnInitLen] = '';
  PrnLeftMargin: String[PrnMarginLen] = '';
  PrnTopMargin: String[PrnMarginLen] = '';
  PrnBottomMargin: String[PrnMarginLen] = '';
  PrnLinesPerPage: String[PrnLinesLen] = '';
  PrnInterval: String[PrnIntervalLen] = '';
  PrnCharsPerCycle: String[PrnCycleLen] = '';

  BinaryPrinting: Boolean = False;

  AltHelpName: String[NameLen] = '';

  csMMDDYY = 0;
  csDDMMYY = 1;
  csYYMMDD = 2;
  csYYDDMM = 3;

  cs12Hour = 0;
  cs24Hour = 1;

  csRusHorCal = 0;
  csRusVerCal = 1;
  csEngHorCal = 2;
  csEngVerCal = 3;

  CountryDate: Byte = csMMDDYY;
  CountryTime: Byte = cs12Hour;
  CountryCalendar: Byte = csRusVerCal;
  DateSeparator: Char = '-';
  TimeSeparator: Char = ':';
  ThousandsSeparator: Char = ',';

  ciDate = 1;
  ciTime = 2;
  ciDateSep = 4;
  ciTimeSep = 8;
  ciThouSep = $10;
  ciCharMap = $20;
  UseDOSCountryInfo: Byte = 0;

  FieldSeparator: Char = ':';

  imJustifyNum = 1;
  exTrimLead = 2;
  exTrimTrail = 4;
  dbConvertDates = 8;
  dbValidate = $10;
  imInsert = $80;
  DefImpExpOptions = imJustifyNum + exTrimLead + exTrimTrail +
    dbConvertDates + dbValidate;
  DBImpExpOptions: Byte = DefImpExpOptions;

  LastProgIndex: Integer = 0;
  LastMacroIndex: Integer = 0;
  LastMacroNameCRC: Longint = 0;

  coModifyMemory = 1;
  coClearHistory = 2;
  coDeleteItem = 4;
  coSaveCurrentConfig = 8;
  coAbortEditor = $10;
  coAbortFileManager = $20;
  coCloseFileManager = $40;
  coCloseTerminal = $80;
  coExit = $100;
  ConfirmOptions: Word = 0;

  cdAutoMix = $01;
  cdAutoPlay = $02;
  cdLock = $04;
  cdRepeat = $08;
  cdEject = $10;

  cdDiskOrder = 0;
  cdUserOrder = 1;
  cdSingle = 2;
  cdIntro = 3;
  cdShuffle = 4;

  cdSettings: Byte = 0;
  cdSequence: Byte = 0;

  cdFastTime: Integer = 15;
  cdIntroTime: Integer = 15;

  AlbumDirLen = 67;
  MixerCommandLen = 127;

  cdAlbumDir: String[AlbumDirLen] = '';
  cdMixerCommand: String[MixerCommandLen] = '';

  loEnableWIN95LFN = 1;
  loConvertNames = 2;
  loShortNamesAsIs = 4;
  LFNOptions: Byte = 0;

  OutOfMemInUse: Boolean = False;

  ArcCopyCRC: Longint = 0;

  crDEC = 0;
  crHEX = 1;
  crBIN = 2;
  crOCT = 3;
  crEXP = 4;
  crSCI = 5;
  crBYT = 6;

  seAlwaysDialog = 1;
  seSaveSettings = 2;

  CopyResultAs: Byte = 0;
  SolveExprOpt: Byte = 0;

  DisableVGAPalette: Boolean = False;

  SaveClipboardData: Boolean = False;

  dlListNotLetter = 1;
  dlGetFromUser = 2;
  dlUserResources = 4;
  DriveListOptions: Byte = 0;

  WordStarChars = [^A, ^C, ^D, ^E, ^F, ^R, ^S, ^V, ^W, ^X, ^Z];
  wsA = $0001;
  wsC = $0002;
  wsD = $0004;
  wsE = $0008;
  wsF = $0010;
  wsR = $0020;
  wsS = $0040;
  wsV = $0080;
  wsW = $0100;
  wsX = $0200;
  wsZ = $0400;
  ws0 = $0800;
  ws1 = $8000;
  wsAll = wsA+wsC+wsD+wsE+wsF+wsR+wsS+wsV+wsW+wsX+wsZ;
  WordStarKeys: Word = wsAll;

implementation

end.