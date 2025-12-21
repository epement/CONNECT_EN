unit Commands;

interface

uses Views;

const

{ Commands that CAN be enabled or disabled }

  cmShow             = 100;
  cmHide             = 101;
  cmModifyItem       = 102;
  cmNewItem          = 103;
  cmDeleteItem       = 104;
  cmRunItem          = 105;
  cmNewItemPos       = 106;
  cmAbort            = 107;
  cmReset            = 108;

  cmCtrlKA           = 109;
  cmCtrlKC           = 110;
  cmCtrlKD           = 111;
  cmCtrlKI           = 112;
  cmCtrlKM           = 113;
  cmCtrlKP           = 114;
  cmCtrlKU           = 115;
  cmCtrlKV           = 116;
  cmCtrlKW           = 117;
  cmCtrlKY           = 118;
  cmCtrlKB           = 119;
  cmCtrlKH           = 120;
  cmCtrlKK           = 121;
  cmCtrlKL           = 122;
  cmCtrlKR           = 123;
  cmCtrlKT           = 124;
  cmCtrlQB           = 125;
  cmCtrlQC           = 126;
  cmCtrlQD           = 127;
  cmCtrlQE           = 128;
  cmCtrlQG           = 129;
  cmCtrlQH           = 130;
  cmCtrlQK           = 131;
  cmCtrlQp           = 132;
  cmCtrlQL           = 133;
  cmCtrlQS           = 134;
  cmCtrlQU           = 135;
  cmCtrlQY           = 136;
  cmCtrlQR           = 137;
  cmCtrlQT           = 138;
  cmCtrlQO           = 139;
  cmCtrlQM           = 140;
  cmCtrlQI           = 141;
  cmCtrlQN           = 142;
  cmCtrlQZ           = 143;
  cmCtrlQX           = 144;
  cmCtrlQPath        = 145;
  cmCtrlQV           = 146;
  cmCtrlQW           = 147;
  cmCtrlQQ           = 148;
  cmCtrlQJ           = 149;
  cmCtrlQSpace       = 150;
  cmCtrlQShort       = 157;
  cmCtrlQLong        = 158;
  cmCtrlQPeriod      = 166;

  cmInXLAT           = 151;
  cmOutXLAT          = 152;
  cmClearInXLAT      = 153;
  cmClearOutXLAT     = 154;
  cmDBConvertDates   = 155;
  cmDBValidate       = 156;

  cmDeleteSel        = 159;

  cmAddHotKey        = 160;
  cmStopHotKey       = 161;
  cmRemoveHotKey     = 162;
  cmHotKeyUp         = 163;
  cmHotKeyDown       = 164;
  cmClearHotKeys     = 165;

  cmStopPlay         = 180;
  cmPlayAudio        = 181;
  cmPausePlay        = 182;
  cmEjectDisk        = 183;
  cmSkipBack         = 184;
  cmRewind           = 185;
  cmFastForward      = 186;
  cmSkipForward      = 187;
  cmFirstTrack       = 188;
  cmLastTrack        = 189;
  cmSelTrack         = 190;
  cmAlbumTitles      = 191;
  cmAlbumLyrics      = 192;
  cmMixSound         = 193;

  cmIncSearch        = 209;
  cmSpellCheck       = 210;
  cmImport           = 211;
  cmExport           = 212;
  cmSeek             = 213;
  cmSeekAgain        = 214;
  cmSystemInfo       = 215;
  cmCopyToMT         = 216;
  cmPasteFromMT      = 217;
  cmEditorGroups     = 218;
  cmMultiSearch      = 219;
  cmShowAllFound     = 220;
  cmFindAll          = 221;
  cmInterrupts       = 222;
  cmInputOutput      = 223;
  cmMemory           = 224;
  cmLoadProgram      = 225;
  cmClearBreakPoints = 226;
  cmToggleBreakPoint = 227;
  cmCompile          = 228;
  cmDeleteWatch      = 229;
  cmClearWatches     = 230;
  cmClearOutput      = 231;
  cmTogglePalette    = 232;
  cmToggleEGALines   = 233;
  cmCopySnipper      = 234;
  cmShowClipboard    = 235;
  cmRun              = 236;
  cmProgramReset     = 237;
  cmGoToCursor       = 238;
  cmTraceInto        = 239;
  cmStepOver         = 240;
  cmAnimateTracing   = 241;
  cmAnimateStepping  = 242;
  cmSave             = 243;
  cmSaveAs           = 244;
  cmSaveAll          = 245;
  cmPrint            = 246;
  cmRestoreLine      = 247;
  cmFillHex          = 248;
  cmFind             = 249;
  cmReplace          = 250;
  cmSearchAgain      = 251;
  cmGoToLine         = 252;
  cmUpdateASCII      = 253;
  cmUpdateHex        = 254;
  cmPause            = 255;

{ Commands that CANNOT be enabled or disabled }

  cmContents         = 1000;
  cmTopicSearch      = 1001;
  cmPreviousTopic    = 1002;

  cmFileOpen         = 2001;
  cmFileReplace      = 2002;
  cmFileClear        = 2003;
  cmFileInit         = 2004;
  cmChangeDir        = 2005;
  cmRevert           = 2006;
  cmFileMask         = 2007;
  cmSelectedFiles    = 2008;

  cmOpenCPUWindow    = 3000;

  cmModifyValue      = 4000;
  cmUpdateViews      = 4001;
  cmPopUp            = 4002;
  cmIsCPU            = 4003;
  cmDoneCPU          = 4004;
  cmGoTo             = 4010;
  cmGoOpposite       = 4011;
  cmWriteTo          = 4012;
  cmReadFrom         = 4013;
  cmIncrement        = 4014;
  cmDecrement        = 4015;
  cmZero             = 4016;
  cmChange           = 4017;
  cmOrigin           = 4018;
  cmFollow           = 4019;
  cmNearCode         = 4020;
  cmFarCode          = 4021;
  cmOffsetToData     = 4022;
  cmSegmentToData    = 4023;
  cmBaseToData       = 4024;
  cmFilters          = 4025;
  cmMixed            = 4026;

  cmIsASCII          = 6000;
  cmASCIIOpened      = 6001;
  cmIsHex            = 6002;
  cmHexOpened        = 6003;
  cmIsPrintable      = 6004;
  cmGetWord          = 6005;
  cmGetLine          = 6006;
  cmGetPrintLine     = 6007;
  cmGetSelPrintLine  = 6008;
  cmToggleWrap       = 6009;
  cmToggleInsert     = 6010;
  cmTrackSource      = 6011;
  cmToggleExplode    = 6012;
  cmGetBlockDest     = 6013;
  cmSetTextMode      = 6014;
  cmCtrlToggleWrap   = 6015;
  cmGetMarkerLine    = 6016;
  cmDateStamp        = 6090;
  cmTimeStamp        = 6091;
  cmSaveBlock        = 6092;
  cmRestoreBlock     = 6093;
  cmSaveCursor       = 6094;
  cmRestoreCursor    = 6095;
  cmHideBlock        = 6096;
  cmDisplayBlock     = 6097;
  cmEditorKeys       = 6098;
  cmSelectAll        = 6099;
  cmReopen           = 6900;

  cmUpdateTime       = 7000;
  cmNewSwapStream    = 7666;
  cmReopenHelp       = 7900;
  cmHelpBrowser      = 7998;
  cmHelpHistory      = 7999;

  cmIsMessage        = 8000;
  cmGetSource        = 8001;
  cmGetDest          = 8002;
  cmGetLeftPath      = 8010;
  cmGetRightPath     = 8011;
  cmGetOppositePath  = 8012;
  cmGetOppSource     = 8013;
  cmGetArcDir        = 8020;

  cmRegExpDlg        = 8800;
  cmAutoRegExp       = 8801;

  cmDecoderList      = 8900;
  cmDecoders         = 8901;

  cmExecRec          = 9000;
  cmCancelExec       = 9001;

  cmCommand          = 9100;
  cmKey              = 9101;
  cmString           = 9102;
  cmKeySequence      = 9103;

  cmAbout            = 10001;
  cmRefreshDisplay   = 10002;
  cmClearDesktop     = 10003;
  cmClearHistory     = 10004;
  cmASCIITable       = 10005;
  cmCalculator       = 10006;
  cmCalendar         = 10007;
  cmPuzzle           = 10008;
  cmEditOptions      = 10009;
  cmOpenASCII        = 10012;
  cmNewASCII         = 10013;
  cmOpenHex          = 10014;
  cmNewHex           = 10015;
  cmChangeDirectory  = 10016;
  cmDosShell         = 10017;
  cmMessage          = 10018;
  cmUserScreen       = 10019;
  cmMode             = 10020;
  cmMouse            = 10021;
  cmColors           = 10022;
  cmSetUp            = 10023;
  cmSaveOptions      = 10024;
  cmRetrieveOptions  = 10025;
  cmMacro            = 10026;
  cmUserMacros       = 10027;
  cmExecute          = 10028;
  cmUserPrograms     = 10029;
  cmLoadIcon         = 10030;
  cmAlarm            = 10031;
  cmSpooler          = 10032;
  cmKeyboard         = 10033;
  cmMap              = 10034;
  cmDump             = 10035;
  cmCode             = 10036;
  cmList             = 10037;
  cmTerminal         = 10038;
  cmBack             = 10039;
  cmToggleMarkMode   = 10040;
  cmDialer           = 10041;
  cmCursor           = 10042;
  cmOverlay          = 10043;
  cmRecordMacro      = 10044;
  cmStopRecording    = 10045;
  cmFMOptions        = 10046;
  cmComments         = 10047;
  cmUserOptions      = 10048;
  cmLogFile          = 10049;
  cmPhoneBook        = 10050;
  cmGroups           = 10051;
  cmOpenTextViewer   = 10052;
  cmOpenHexViewer    = 10053;
  cmIsTextViewer     = 10054;
  cmIsHexViewer      = 10055;
  cmOpenDataViewer   = 10056;
  cmPrinterSetup     = 10057;
  cmAltHelpName      = 10058;
  cmCountry          = 10059;
  cmConfirmations    = 10060;
  cmEnvDlg           = 10061;
  cmSaveClipData     = 10062;

  cmOutput           = 20000;
  cmWatch            = 20010;
  cmAddWatch         = 20011;
  cmEditWatch        = 20012;
  cmModify           = 20013;

  cmUpdateBar        = 30000;
  cmNotReadyShow     = 30001;
  cmNotReadyHide     = 30002;
  cmCloseBar         = 30003;
  cmBarVolume        = 30004;
  cmResetBar         = 30005;
  cmProtocol         = 30100;
  cmUpload           = 30101;
  cmDownload         = 30102;
  cmDial             = 30103;
  cmDownloadPath     = 30104;
  cmModemSetup       = 30105;
  cmTransferSetup    = 30106;
  cmHangup           = 30107;
  cmAnswer           = 30108;
  cmFlushBuffers     = 30109;
  cmSerialBreak      = 30110;
  cmDialQueue        = 30111;

  cmOpenHTML         = 40000;
  cmHRef             = 40001;
  cmHTMLHistory      = 40002;
  cmHTMLReload       = 40003;
  cmToggleHTMLTables = 40010;

  cmCDPlayer         = 50000;
  cmTrackMode        = 50010;
  cmTimeMode         = 50011;
  cmRestart          = 50020;
  cmTrackHist        = 50030;
  cmCDOptions        = 50050;
  cmTracks           = 50100;

  cmFCopy            = 60000;
  cmFRenMov          = 60001;
  cmFMkDir           = 60002;
  cmFDelete          = 60003;
  cmShiftCopy        = 60004;
  cmShiftRenMov      = 60005;
  cmShiftMkDir       = 60006;
  cmShiftDelete      = 60007;
  cmFView            = 60008;
  cmFAltView         = 60009;
  cmFShiftView       = 60010;
  cmBrief            = 60011;
  cmFull             = 60012;
  cmTree             = 60013;
  cmInfo             = 60014;
  cmSelectLeftDrive  = 60015;
  cmSelectRightDrive = 60016;
  cmSelectGroup      = 60017;
  cmUnselectGroup    = 60018;
  cmInvert           = 60019;
  cmFindFileDlg      = 60020;
  cmFSort            = 60021;
  cmReRead           = 60022;
  cmFAttributes      = 60023;
  cmFilter           = 60024;
  cmCompareDirs      = 60025;
  cmSwapPanels       = 60026;
  cmNewPrompt        = 60027;
  cmAddFileName      = 60028;
  cmPromptHistory    = 60029;
  cmExecOptions      = 60030;
  cmPanelSettings    = 60031;
  cmExtensions       = 60032;
  cmViewers          = 60033;
  cmToggleHidden     = 60034;
  cmToggleExOnly     = 60035;
  cmToggleMiniStatus = 60036;
  cmToggleDrivePanel = 60037;
  cmFilesBBS         = 60038;
  cmRestoreSelection = 60039;
  cmFCtrlView        = 60040;
  cmIgnoreSelection  = 60041;
  cmToggleUnfold     = 60042;
  cmCalcDirSize      = 60043;
  cmOpenArchive      = 60044;
  cmPassword         = 60045;
  cmTest             = 60046;
  cmExtract          = 60047;
  cmClearSelection   = 60048;
  cmSaveFocusedName  = 60049;
  cmDiskChanged      = 60050;
  cmUpdateDisk       = 60051;
  cmTreeItemSelected = 60052;
  cmReadFileList     = 60053;
  cmQuickView        = 60054;
  cmSwitchToDir      = 60055;
  cmDriveSelector    = 60056;
  cmFMFiles          = 60057;
  cmToggleLeftPanel  = 60058;
  cmToggleRightPanel = 60059;
  cmTogglePanels     = 60060;
  cmSepSelInfo       = 60061;
  cmFMKeys           = 60062;
  cmQuickDescr       = 60063;
  cmBBSOptChanged    = 60064;
  cmDirHistory       = 60065;
  cmArcCopyDlg       = 60066;
  cmFMViewPrev       = 60070;
  cmFMViewNext       = 60071;
  cmExtractByName    = 60072;
  cmToggleDrive      = 60073;
  cmChangeClass      = 60074;
  cmChangeClassInfo  = 60075;
  cmUserDriveFocused = 60076;
  cmDriveOptions     = 60077;
  cmAutoDetect       = 60078;
  cmToggleLFNFlag    = 60079;
  cmTagChar          = 60080;
  cmNetListOptions   = 60089;
  cmSaveSelected     = 60090;
  cmLSaveSelected    = 60091;
  cmFCtrlRenMov      = 60092;
  cmFCtrlDelete      = 60093;
  cmFCtrlCopy        = 60094;
  cmFileManager      = 60100;
  cmCDFM             = 60200;

  cmNoArc            = 61000;
  cmZip              = 61001;
  cmArc              = 61002;
  cmLzh              = 61003;
  cmArj              = 61004;
  cmPak              = 61005;
  cmChz              = 61006;
  cmZoo              = 61007;
  cmLim              = 61008;
  cmHa               = 61009;
  cmRar              = 61010;
  cmZiW              = 61011;
  cmArW              = 61012;
  cmRaW              = 61013;

  cmUserArchivers    = 61020;
  cmUserMenu         = 61021;

  cmlAPIChanged      = 62000;

  cmReloadMacroList  = 63000;
  cmGetMacroName     = 63001;

  TileCommands = [cmTile, cmCascade];
  BlockCommands = [cmCut, cmCopy, cmClear,
    cmCtrlKA..cmCtrlKY, cmCtrlQB, cmCtrlQI, cmCtrlQK, cmCtrlQX];
  UndoCommands = [cmUndo];
  RedoCommands = [cmRedo];
  CopyCommands = [cmCopy];
  PasteCommands = [cmPaste];
  HexCommands = [cmFillHex, cmUpdateASCII, cmUpdateHex,
    cmFind, cmReplace, cmShowAllFound, cmFindAll, cmSearchAgain,
    cmIncSearch, cmGoToLine, cmMultiSearch, cmSave, cmSaveAs, cmPrint];
  ASCIICommands = [cmUpdateASCII, cmUpdateHex, cmFind, cmReplace,
    cmShowAllFound, cmFindAll, cmSearchAgain, cmIncSearch, cmGoToLine,
    cmMultiSearch, cmSave, cmSaveAs, cmPrint, cmCompile,
    cmToggleBreakpoint, cmClearBreakpoints];
  SaveAllCommands = [cmSaveAll];
  DebugCommands = [cmRun, cmProgramReset, cmGoToCursor, cmTraceInto,
    cmStepOver, cmAnimateTracing, cmAnimateStepping];
  BreakpointCommands = [cmToggleBreakpoint, cmClearBreakpoints];
  FindCommands = [cmFind, cmSearchAgain];
  SnipperCommands = [cmCopySnipper];
  EGACommands = [cmToggleEGALines, cmTogglePalette];
  ShowCommands = [cmShow];
  HideCommands = [cmHide];
  ModifyCommands = [cmModifyItem];
  DeleteCommands = [cmDeleteItem];
  DeleteSelCommands = [cmDeleteSel];
  NewCommands = [cmNewItem];
  RunItemCommands = [cmRunItem];
  NewItemPosCommands = [cmNewItemPos];
  AbortCommands = [cmAbort];
  ResetCommands = [cmReset];
  WatchCommands = [cmDeleteWatch, cmClearWatches];
  OutputCommands = [cmClearOutput];
  LoadProgramCommands = [cmLoadProgram];
  EditorGroupCommands = [cmEditorGroups];
  MTCopyCommands = [cmCopyToMT];
  MTPasteCommands = [cmPasteFromMT];
  MTCommands = [cmCopyToMT, cmPasteFromMT];
  SysinfoCommands = [cmSystemInfo];
  ImportCommands = [cmImport];
  ExportCommands = [cmExport];
  SeekCommands = [cmSeek];
  SeekAgainCommands = [cmSeekAgain];
  IncSearchCommands = [cmIncSearch];
  CDCommands = [cmStopPlay, cmPlayAudio, cmPausePlay, cmEjectDisk,
    cmSkipBack, cmRewind, cmFastForward, cmSkipForward, cmFirstTrack,
    cmLastTrack, cmSelTrack, cmAlbumTitles, cmAlbumLyrics, cmMixSound];
  DBInOutCommands = [cmInXLAT, cmOutXLAT, cmClearInXLAT, cmClearOutXLAT,
    cmDBConvertDates, cmDBValidate];

implementation

end.