{$O+,F+,X+}
unit RMenus;

interface

uses Objects, Drivers, Views, Menus, App;

type
  PRStatusLine = ^TRStatusLine;
  TRStatusLine = object(TStatusLine)
    HintsList: PStringList;
    destructor Done; virtual;
    function Hint(AHelpCtx: Word): String; virtual;
    procedure Draw; virtual;
    procedure DrawStatusMsg; virtual;
  end;

  PRMenuBar = ^TRMenuBar;
  TRMenuBar = object(TMenuBar)
    function Execute: Word; virtual;
    function GetMouseShape(var Event: TEvent): Char; virtual;
  end;

const
  RRStatusLine: TStreamRec = (
     ObjType: 1180;
     VmtLink: Ofs(TypeOf(TRStatusLine)^);
     Load:    @TRStatusLine.Load;
     Store:   @TRStatusLine.Store
  );
  RRMenuBar: TStreamRec = (
     ObjType: 1181;
     VmtLink: Ofs(TypeOf(TRMenuBar)^);
     Load:    @TRMenuBar.Load;
     Store:   @TRMenuBar.Store
  );

procedure RSRStatusLine(RSR: PResourceFile);
procedure RSRHints(RSR: PResourceFile);
procedure RSRMenuBar(RSR: PResourceFile);
procedure RegisterRMenus;

implementation

uses Memory, HistList, History, ExecMenu, Macros, ExecPrim, LogFile, DialDlg,
  TPString, Consts, Commands, Defaults;

destructor TRStatusLine.Done;
begin
  if HintsList <> nil then Dispose(HintsList, Done);
  TStatusLine.Done;
end;

function TRStatusLine.Hint(AHelpCtx: Word): String;
begin
  if (AHelpCtx > hcError) and (AHelpCtx < $FFFF) then AHelpCtx := hcError
  else if (AHelpCtx > hcCompilerError) and (AHelpCtx < hcError) then
    AHelpCtx := hcCompilerError;
  Hint := HintsList^.Get(AHelpCtx);
end;

procedure TRStatusLine.Draw;
var
  C: Byte;
  B: TDrawBuffer;
begin
  if not MacroCalled and not ProgramCalled then
    if MacroRecording or (HelpCtx = hcDialing) then
    begin
      C := GetColor(1);
      MoveChar(B, ' ', C, Size.X);
      if MacroRecording then MoveStr(B[1],
        'Recording a new keystroke macro. Press Ctrl+Break to abort.', C)
      else MoveStr(B[1], GetDialStatus, C);
      WriteLine(0, 0, Size.X, 1, B);
    end
    else TStatusLine.Draw;
end;

procedure TRStatusLine.DrawStatusMsg;
begin
  TStatusLine.DrawStatusMsg;
  if EnableLog and loEnable <> 0 then WriteToLog(StatusMsg);
  LogEvent := lcOther;
end;

function TRMenuBar.Execute: Word;
begin
  if ExecMenuInherited then Execute := TMenuBar.Execute
  else Execute := ExecuteMenu;
end;

function TRMenuBar.GetMouseShape(var Event: TEvent): Char;
begin
  if (HideOptions and hvMenuBar = 0) and
     (Event.Where.X = 0) and (Event.Where.Y = 0) then
    GetMouseShape := ''
  else GetMouseShape := Inherited GetMouseShape(Event);
end;

procedure RSRHints(RSR: PResourceFile);
var
  M: PStrListMaker;
begin
  M := New(PStrListMaker, Init(16383, $FF));
  M^.Put(hcSystem, 'System commands plus some useful tools');
  M^.Put(hcSAbout, 'Show version and copyright information');
  M^.Put(hcSInfo, 'Show system information');
  M^.Put(hcSRefreshDisplay, 'Redraw the screen, reset mouse and hardware cursor');
  M^.Put(hcSClearDesktop, 'Close all windows on the desktop');
  M^.Put(hcSClearHistory, 'Clear all history lists');
  M^.Put(hcSMemoryMap, 'Memory map window');
  M^.Put(hcSCode, 'Open a Code window');
  M^.Put(hcSDump, 'Open a Memory Dump editor');
  M^.Put(hcSEnvDlg, 'Open the Environment editor dialog box');
  M^.Put(hcEnvDlg, 'View or modify the Environment variables');
  M^.Put(hcSASCIITable, 'Open an IBM PC ASCII table');
  M^.Put(hcASCIITable, 'Use keyboard or mouse to select a character');
  M^.Put(hcSCalculator, 'Load a multifunctional hexadecimal desktop calculator');
  M^.Put(hcToggleHex, 'Set calculator display mode');
  M^.Put(hcToggleCalc, 'Set calculator display range');
  M^.Put(hcCalcPush, 'Write the displayed value to memory buffer');
  M^.Put(hcCalcPop, 'Read the specified value from memory buffer');
  M^.Put(hcExpressions, 'Open the Solve expressions dialog box');
  M^.Put(hcSolveExprDlg, 'Type an expression to solve, use variables if needed');
  M^.Put(hcSCalendar, 'View a month at a time');
  M^.Put(hcCalendar, 'Press arrows or use mouse to change months');
  M^.Put(hcSAlarm, 'Open the Alarm Clock List dialog box');
  M^.Put(hcAlarm, 'Add new items, delete or modify old ones');
  M^.Put(hcNewItem, 'Enter new item definitions');
  M^.Put(hcSSpooler, 'Open the Print Spooler dialog box');
  M^.Put(hcSpooler, 'Rearrange the print queue, add or delete items');
  M^.Put(hcSDialer, 'Open the Phone Dialer Queue dialog box');
  M^.Put(hcDialer, 'View or modify phone dialer queue, abort calls');
  M^.Put(hcSCDPlayer, 'Open a CD Player window');
  M^.Put(hcCDTracks, 'Choose a track to play');
  M^.Put(hcCDTrackList, 'Choose a CD album track to play');
  M^.Put(hcFile, 'File management commands');
  M^.Put(hcFileDialog, 'Enter a file name or type for incremental search');
  M^.Put(hcCtrlKB, 'Set block begin marker');
  M^.Put(hcCtrlKK, 'Set block end marker');
  M^.Put(hcCtrlKC, 'Copy marked block at the cursor position');
  M^.Put(hcCtrlKV, 'Move marked block at the cursor position, delete the area');
  M^.Put(hcCtrlKM, 'Move marked block at the cursor position, clear the area');
  M^.Put(hcCtrlKY, 'Delete marked block, remove the gap');
  M^.Put(hcCtrlKD, 'Clear marked block, fill the area with whitespaces');
  M^.Put(hcCtrlKR, 'Read block from disk at the cursor position');
  M^.Put(hcCtrlKW, 'Write marked block to disk');
  M^.Put(hcCtrlKH, 'Turn block marking on/off');
  M^.Put(hcCtrlKP, 'Print marked block');
  M^.Put(hcCtrlKI, 'Indent marked block');
  M^.Put(hcCtrlKU, 'Unindent marked block');
  M^.Put(hcCtrlKL, 'Mark line at the cursor position');
  M^.Put(hcCtrlKT, 'Mark single word at the cursor position');
  M^.Put(hcCtrlQB, 'Position cursor at the beginning of marked block');
  M^.Put(hcCtrlQK, 'Position cursor at the end of marked block');
  M^.Put(hcCtrlQY, 'Delete text from the cursor position to end of line');
  M^.Put(hcCtrlQZ, 'Delete text from the cursor position to end of file');
  M^.Put(hcCtrlQU, 'Convert characters to uppercase (block or single line)');
  M^.Put(hcCtrlQL, 'Convert characters to lowercase (block or single line)');
  M^.Put(hcCtrlQI, 'Perform logical operation for all bytes in marked block');
  M^.Put(hcCtrlQS, 'Switch to Single Line Draw mode');
  M^.Put(hcCtrlQD, 'Switch to Double Line Draw mode');
  M^.Put(hcCtrlQT, 'Insert current date and time at the cursor position');
  M^.Put(hcCtrlQG, 'Justify left margin (block or single line)');
  M^.Put(hcCtrlQC, 'Center line(s) relative to the cursor position');
  M^.Put(hcCtrlQE, 'Justify right margin (block or single line)');
  M^.Put(hcCtrlQR, 'Reformat paragraphs of text (block or global)');
  M^.Put(hcCtrlQO, 'Unformat text by removing extra blanks (block or global)');
  M^.Put(hcCtrlQH, 'Turn QWERTY to ЙЦУКЕН (block or single line)');
  M^.Put(hcCtrlQp, 'Turn ЙЦУКЕН to QWERTY (block or single line)');
  M^.Put(hcCtrlQV, 'Convert Russian text to Volapyuk (block or single line)');
  M^.Put(hcCtrlQM, 'Calculate numbers or solve equations (block or single line)');
  M^.Put(hcCtrlQX, 'Rearrange text lines in marked block');
  M^.Put(hcCtrlQNew, 'Attempt to open the file indicated by the word at cursor');
  M^.Put(hcCtrlQPath, 'Create the directory indicated by the word at cursor');
  M^.Put(hcCtrlQW, 'Convert text using the specified XLAT table file');
  M^.Put(hcOtherCtrlQ, 'Miscellaneous text formatting commands');
  M^.Put(hcSetTextMode, 'Toggle DOS/UNIX text mode');
  M^.Put(hcFOpen, 'Locate and open a text file in an Edit window');
  M^.Put(hcFNew, 'Create a new text file in a new Edit window');
  M^.Put(hcFOpenHex, 'Locate and open a file in a Hex-Edit window');
  M^.Put(hcFNewHex, 'Create a new file in a new Hex-Edit window');
  M^.Put(hcFSave, 'Save the file in the active edit window');
  M^.Put(hcFSaveAs, 'Save the current file under a different name');
  M^.Put(hcFSaveAll, 'Save all modified files');
  M^.Put(hcFPrint, 'Print the contents of the active Edit window');
  M^.Put(hcFChangeDir, 'Choose a new default directory');
  M^.Put(hcDirDialog, 'Change to the specified directory');
  M^.Put(hcFDosShell, 'Temporarily exit to DOS');
  M^.Put(hcFExit, 'Quit The IBM HandShaker');
  M^.Put(hcEdit, 'Cut-and-paste editing commands');
  M^.Put(hcEUndo, 'Undo the previous editor operation');
  M^.Put(hcERedo, 'Redo the previously undone editor operation');
  M^.Put(hcECut, 'Remove the selected text and put it in the Clipboard');
  M^.Put(hcECopy, 'Copy the selected text into the Clipboard');
  M^.Put(hcEPaste, 'Insert selected text from the Clipboard at cursor position');
  M^.Put(hcEClear, 'Delete the selected text');
  M^.Put(hcESelectAll, 'Select all text in the edit window');
  M^.Put(hcBlockDragAndDrop, 'Drag the selected block to a new destination');
  M^.Put(hcECopyToAddClip, 'Copy the selected text to additional Clipboard');
  M^.Put(hcECopyToWinClip, 'Copy the selected text into MS Windows Clipboard');
  M^.Put(hcEPasteFromAddClip, 'Insert text from additional Clipboard at cursor position');
  M^.Put(hcEPasteFromWinClip, 'Insert text from MS Windows Clipboard at cursor position');
  M^.Put(hcEShowClipboard, 'Open the Clipboard window');
  M^.Put(hcESaveClipData, 'Do not erase the Clipboard data files on exit');
  M^.Put(hcEToggleMarkMode, 'Enable or disable vertical blocks of text');
  M^.Put(hcEFillHex, 'Fill the selected Hex-Edit area with a specified character');
  M^.Put(hcSearch, 'Text search and replacement commands');
  M^.Put(hcSHFind, 'Search for text or sequence of characters');
  M^.Put(hcFind, 'Enter text to search for');
  M^.Put(hcSHReplace, 'Search for text and replace it with new text');
  M^.Put(hcReplace, 'Enter text to search for and new text to replace with');
  M^.Put(hcSHFindAll, 'Search the entire file, find all matches');
  M^.Put(hcSHShowAllFound, 'Show list of all matches, previously created with Find all');
  M^.Put(hcSHSearchAgain, 'Repeat the last Find command');
  M^.Put(hcSHIncSearch, 'Switch to the incremental text search mode');
  M^.Put(hcSHGoToLineNumber, 'Move the cursor to a specified line number');
  M^.Put(hcSHMultiSearch, 'Search and replace text across windows');
  M^.Put(hcRun, 'Execute or single-step through a user program');
  M^.Put(hcRCompile, 'Compile source file');
  M^.Put(hcRRun, 'Run the current user program');
  M^.Put(hcRProgramReset, 'Halt debugging session and release memory');
  M^.Put(hcRGoToCursor, 'Run program from the run bar to the cursor position');
  M^.Put(hcRTraceInto, 'Execute next line, stopping within the current procedure');
  M^.Put(hcRStepOver, 'Execute next line, skipping over the current procedure');
  M^.Put(hcRAnimateTracing, 'Trace source lines or instructions continuously');
  M^.Put(hcRAnimateStepping, 'Step over source lines or instructions continuously');
  M^.Put(hcROpenCPUWindow, 'Enable or disable debugging in a CPU window');
  M^.Put(hcGoToAddress, 'Set a new address for data display');
  M^.Put(hcGoOpposite, 'Move cursor to opposite location');
  M^.Put(hcOrigin, 'Go to origin');
  M^.Put(hcIncrement, 'Increment the highlighted register');
  M^.Put(hcDecrement, 'Decrement the highlighted register');
  M^.Put(hcZero, 'Set the highlighted register to zero');
  M^.Put(hcChange, 'Change data at the cursor location');
  M^.Put(hcWriteTo, 'Write from a memory block to a disk file');
  M^.Put(hcReadFrom, 'Read from a disk file to a memory block');
  M^.Put(hcFollow, 'Use data at cursor as new address to display');
  M^.Put(hcNearCode, 'Set code pane to near address at cursor');
  M^.Put(hcFarCode, 'Set code pane to far address at cursor');
  M^.Put(hcOffsetToData, 'Set data pane to new offset at cursor');
  M^.Put(hcSegmentToData, 'Set data pane to new segment:offset at cursor');
  M^.Put(hcBaseToData, 'Set data pane to segment:0 at cursor');
  M^.Put(hcDebug, 'Modify data, set breakpoints and watches');
  M^.Put(hcDModify, 'Modify user program parameter');
  M^.Put(hcModify, 'Enter new value for parameter');
  M^.Put(hcDAddWatch, 'Insert a watch expression into the Watches window');
  M^.Put(hcDEditWatch, 'Edit the current expression in the Watches window');
  M^.Put(hcDDeleteWatch, 'Remove the current expression from the Watches window');
  M^.Put(hcDClearWatches, 'Delete all watch expressions from the Watches window');
  M^.Put(hcEnterWatch, 'Enter expression to add as watch');
  M^.Put(hcDToggleBreakpoint, 'Set or clear breakpoint at the cursor position');
  M^.Put(hcDClearBreakpoints, 'Delete all breakpoints');
  M^.Put(hcDClearOutput, 'Clear the contents of the Output window');
  M^.Put(hcRegExpDlg, 'Debug regular expressions');
  M^.Put(hcWindow, 'Update, arrange, and list windows');
  M^.Put(hcWUpdateASCII, 'Reload the active editor window in ASCII format');
  M^.Put(hcWUpdateHex, 'Reload the active editor window in Hex format');
  M^.Put(hcWResize, 'Change the size or position of the active window');
  M^.Put(hcWZoom, 'Enlarge or restore the size of the active window');
  M^.Put(hcWTile, 'Arrange windows on desktop by tiling');
  M^.Put(hcWCascade, 'Arrange windows on desktop by cascading');
  M^.Put(hcWNext, 'Make the next window active');
  M^.Put(hcWPrevious, 'Make the previous window active');
  M^.Put(hcWClose, 'Close the active window');
  M^.Put(hcWWatch, 'Open the Watches window');
  M^.Put(hcWOutput, 'Open the Output window');
  M^.Put(hcCopyOutput, 'Copy the Output window contents into the Clipboard');
  M^.Put(hcOOptions, 'Specify Output settings');
  M^.Put(hcOutputOptions, 'Set defaults for Output window');
  M^.Put(hcWMessage, 'Open the Message window');
  M^.Put(hcWTerminal, 'Open the Terminal window');
  M^.Put(hcProtocol, 'Select the desired handshake protocol');
  M^.Put(hcUpload, 'Upload file(s) using the specified protocol');
  M^.Put(hcDownload, 'Download file(s) using the specified protocol');
  M^.Put(hcDial, 'Make a phone call by auto-dialing the selected phone number');
  M^.Put(hcFlushBuffers, 'Clear input/output buffers');
  M^.Put(hcHangup, 'Send Hangup modem string');
  M^.Put(hcAnswer, 'Send Answer modem string');
  M^.Put(hcSerialBreak, 'Send a serial line break');
  M^.Put(hcDownloadPath, 'Specify Download directory');
  M^.Put(hcModemSetup, 'Specify modem command strings, set auto-dialer defaults');
  M^.Put(hcTransferSetup, 'Specify transfer options, select progress bar direction');
  M^.Put(hcCopyTerminal, 'Copy the Terminal window contents into the Clipboard');
  M^.Put(hcPasteTerminal, 'Send the Clipboard selected text');
  M^.Put(hcClearTerminal, 'Clear the contents of the Terminal window');
  M^.Put(hcTOptions, 'Specify Terminal settings');
  M^.Put(hcTerminalOptions, 'Set defaults for Terminal window');
  M^.Put(hcWBack, 'Open the Back window');
  M^.Put(hcWUserScreen, 'Switch to the full-screen user output');
  M^.Put(hcWList, 'Show a list of all open windows');
  M^.Put(hcReopen, 'Reopen indicated file in a new editor window');
  M^.Put(hcWindowFlags, 'Set or clear specified window flags');
  M^.Put(hcOptions, 'Set defaults for communication, mouse, desktop');
  M^.Put(hcOMode, 'Set default communication parameters');
  M^.Put(hcOKeyboard, 'Specify keyboard scroll settings');
  M^.Put(hcKbdDialog, 'Adjust the vertical scroll speed');
  M^.Put(hcOMouse, 'Specify mouse settings');
  M^.Put(hcMouse, 'Adjust the double click speed, make the active button');
  M^.Put(hcOCursor, 'Modify default cursor size/shape');
  M^.Put(hcOColors, 'Customize desktop colors for menus, dialogues, etc.');
  M^.Put(hcColors, 'Select a desktop group and customize its colors');
  M^.Put(hcRGBDialog, 'Set red, green & blue color values (VGA display only)');
  M^.Put(hcOCountry, 'Specify country settings for date, time and calendar');
  M^.Put(hcOEditOptions, 'Specify editor settings');
  M^.Put(hcEditOptions, 'Set defaults for Editor windows');
  M^.Put(hcCommentDlg, 'View or modify the Editor group list');
  M^.Put(hcNewComment, 'Enter new file name mask and comment pattern(s)');
  M^.Put(hcEditGroupNames, 'Specify Help and XLAT file names for selected group');
  M^.Put(hcEditorKeysDialog, 'Specify Editor window keystroke options');
  M^.Put(hcOFMOptions, 'Set defaults for File Manager panels');
  M^.Put(hcGroupDlg, 'View or modify the File group list');
  M^.Put(hcNewGroup, 'Specify file name mask, highlight attribute and index');
  M^.Put(hcFMFilesDialog, 'Specify File Manager dirinfo and description file names');
  M^.Put(hcFMKeysDialog, 'Specify File Manager panel keystroke options');
  M^.Put(hcOUserOptions, 'Specify compiler and user program executor options');
  M^.Put(hcOvrOptions, 'Change overlay preferences and buffer size');
  M^.Put(hcOPrinter, 'Set defaults for Printer');
  M^.Put(hcPrinterSetup, 'Modify default Printer settings');
  M^.Put(hcOCDOptions, 'Specify CD Player settings');
  M^.Put(hcOSetup, 'Permanently change default setup');
  M^.Put(hcSetup, 'Modify default setup');
  M^.Put(hcOLog, 'Set defaults for event logging');
  M^.Put(hcOExplode, 'Specify window settings, set delay for exploding windows');
  M^.Put(hcOEGALines, 'Toggle the display between 25 and 43/50 line modes');
  M^.Put(hcOConfirmations, 'Enable or disable prompt on various program actions');
  M^.Put(hcOSaveOptions, 'Save all the desktop settings you''ve made');
  M^.Put(hcORetrieveOptions, 'Load desktop files previously created with Save options');
  M^.Put(hcUser, 'Macros handling and execution commands');
  M^.Put(hcUMacro, 'Execute previously created macro with a hot key');
  M^.Put(hcURecordMacro, 'Start recording a new keystroke macro');
  M^.Put(hcUStopRecording, 'Stop recording and save a new keystroke macro');
  M^.Put(hcUUserMacros, 'Create a new macro, execute or modify an old one');
  M^.Put(hcMacroInputBox, 'Enter a string for the macro');
  M^.Put(hcHotKeyListDlg, 'Create new hot key sequence for the currently edited item');
  M^.Put(hcUserDialog, 'Add commands, keys or strings to the currently edited macro');
  M^.Put(hcMacrosDialog, 'View, run, repeat, add, edit or delete macros');
  M^.Put(hcUExecute, 'Run previously defined external program with a hot key');
  M^.Put(hcUUserPrograms, 'Create new program definitions, run or modify old ones');
  M^.Put(hcProgList, 'View, run, add, edit or delete programs');
  M^.Put(hcNewProg, 'Enter new program definitions');
  M^.Put(hcMenuDialog, 'Select a user menu command');
  M^.Put(hcStringDialog, 'Enter new string');
  M^.Put(hcValueDialog, 'Enter new value');
  M^.Put(hcPromptDialog, 'Enter program arguments');
  M^.Put(hcULoadIcon, 'Locate and load a user program ready for execution');
  M^.Put(hcIcon, 'User program icon');
  M^.Put(hcUPhoneBook, 'View or modify Phone list, make phone calls');
  M^.Put(hcNewPhone, 'Enter new phone entry fields');
  M^.Put(hcUDecoders, 'Display User defined decoder list');
  M^.Put(hcDecoderList, 'Customize User defined decoder list');
  M^.Put(hcDecoderListItem, 'Enter new decoder definitions');
  M^.Put(hcSelectDecoder, 'Apply indicated decoder to current desktop window');
  M^.Put(hcResetDecoder, 'Disable input and output decoding for current desktop window');
  M^.Put(hcFileManager, 'Open a File Manager window');
  M^.Put(hcPromptHistory, 'Select a history string or type for incremental search');
  M^.Put(hcAssocHistory, 'Choose a program or command from the association list');
  M^.Put(hcFMCopyOptions, 'Set defaults for Copy/Rename file operations');
  M^.Put(hcCopyDialog, 'Copy the selected file or directory to a new destination');
  M^.Put(hcShiftCopyDialog, 'Copy the specified file or directory to a new destination');
  M^.Put(hcArcCopyDlg, 'Copy or move the selected file or directory to an archive');
  M^.Put(hcRenMovDialog, 'Rename or move the selected file or directory');
  M^.Put(hcShiftRenMovDialog, 'Rename or move the specified file or directory');
  M^.Put(hcMkDirDialog, 'Enter a new directory name');
  M^.Put(hcShiftDeleteDialog, 'Delete the specified file or directory');
  M^.Put(hcDragAndDrop, 'Drag the selected file(s) to a new destination');
  M^.Put(hcCopySkipDialog, 'Confirm prompt on overwrite or cancel operation');
  M^.Put(hcDeleteSkipDialog, 'Confirm prompt on delete or cancel operation');
  M^.Put(hcDiskErrorDialog, 'Confirm prompt on retry, ignore or cancel operation');
  M^.Put(hcTreeDialog, 'Select a directory name or type for incremental search');
  M^.Put(hcSearchDirHistory, 'Choose a name from the list of matching directories');
  M^.Put(hcDirSizes, 'Display file/size information for the selected directory');
  M^.Put(hcBrief, 'Show three columns of directories and files');
  M^.Put(hcFull, 'Show directories and files with full information');
  M^.Put(hcTree, 'Show the directory structure of the current drive');
  M^.Put(hcInfo, 'Show the current directory information');
  M^.Put(hcQuickView, 'View the contents of the file or directory information');
  M^.Put(hcQuickDescr, 'View description of the focused file or directory');
  M^.Put(hcSelectGroup, 'Select a group of files matching the specified mask');
  M^.Put(hcUnselectGroup, 'Unselect a group of files matching the specified mask');
  M^.Put(hcToggleSelected, 'Select non-selected files and unmark selected');
  M^.Put(hcRestoreSelection, 'Re-select processed or unmarked files');
  M^.Put(hcFindFile, 'Find the specified file(s)');
  M^.Put(hcFindFileOptions, 'Set defaults for file searching');
  M^.Put(hcSort, 'Rearrange the Panel file list');
  M^.Put(hcFilter, 'Show files matching the specified mask only');
  M^.Put(hcAdvancedFilter, 'Specify advanced filter settings for current panel');
  M^.Put(hcReRead, 'Re-read the current directory');
  M^.Put(hcSwapPanels, 'Make left panel right and vice versa');
  M^.Put(hcTogglePanels, 'Show or hide left, right, or both panels');
  M^.Put(hcFileAttributes, 'Change the selected file attributes');
  M^.Put(hcCompareDirectories, 'Compare directories in both panels, select missing files');
  M^.Put(hcFMisc, 'Miscellaneous panel setup commands');
  M^.Put(hcExecOptions, 'Specify execution options');
  M^.Put(hcAssociate, 'View or modify the association file');
  M^.Put(hcExtDlg, 'View or modify the association list');
  M^.Put(hcNewExt, 'Enter new association definitions');
  M^.Put(hcViewers, 'View or modify the viewer file');
  M^.Put(hcViewDlg, 'View or modify the viewer list');
  M^.Put(hcNewViewer, 'Enter new viewer definitions');
  M^.Put(hcArchivers, 'View or modify default settings for the specified archiver');
  M^.Put(hcUserArchivers, 'Set defaults for the specified user defined archiver');
  M^.Put(hcOpenArchive, 'View the contents of the specified archive file');
  M^.Put(hcArcPassword, 'Enter password for the specified archive');
  M^.Put(hcReadFileList, 'Load the directory structure from the specified text file');
  M^.Put(hcSaveFocusedName, 'Put the specified file name to History list');
  M^.Put(hcPanelHistory, 'Select new directory from the History list');
  M^.Put(hcClearSelection, 'Clear panel selection and dispose of tag list');
  M^.Put(hcPanelSettings, 'Specify panel display mode and layout settings');
  M^.Put(hcShowHiddenFiles, 'Display hidden files and directories');
  M^.Put(hcExOnly, 'Display executable files only (.BAT, .COM, .EXE)');
  M^.Put(hcMiniStatus, 'Show/hide column titles and mini status line (info pane)');
  M^.Put(hcDriveSelector, 'Show/hide Drive selector at the bottom of the panel');
  M^.Put(hcFilesBBS, 'Display user defined file descriptions (Full status only)');
  M^.Put(hcCalcDirSize, 'Calculate and display total sizes for all subdirectories');
  M^.Put(hcIgnoreSelection, 'Ignore selected files, always handle file at cursor');
  M^.Put(hcSepSelInfo, 'Display focused file info and selection info separately');
  M^.Put(hcUnfold, 'Display files in subdirectories (directory branch)');
  M^.Put(hcDrive, 'Change to the specified drive');
  M^.Put(hcDriveDialog, 'Choose a new default drive');
  M^.Put(hcRedirList, 'Choose a new redirected device entry');
  M^.Put(hcDriveListDlg, 'Display detailed information for each logical drive');
  M^.Put(hcUserDefinedDriveList, 'Customize user defined drive list settings');
  M^.Put(hcUserDefinedNetList, 'Customize user defined network resource list settings');
  M^.Put(hcNewNetListItem, 'Specify new user defined network resource name (UNC path)');
  M^.Put(hcDriveReadyDialog, 'Choose a valid drive');
  M^.Put(hcDataFields, 'Display database field info');
  M^.Put(hcViewMemo, 'Display memo for the database record at cursor');
  M^.Put(hcDeleteRecord, 'Delete the database record at cursor');
  M^.Put(hcPackDataBase, 'Remove all records marked as deleted');
  M^.Put(hcZapDataBase, 'Clear the database by truncating the file');
  M^.Put(hcFieldCursor, 'Toggle record/field cursor mode');
  M^.Put(hcDBCreate, 'Create field list for new database file');
  M^.Put(hcNewField, 'Enter new field definitions');
  M^.Put(hcInOutCommands, 'Data exchange and setup commands');
  M^.Put(hcDBXLATFile, 'Specify conversion table file names for current database');
  M^.Put(hcDBClearXLAT, 'Disable input/output data conversion for current database');
  M^.Put(hcDBConvertDates, 'Toggle database date field display mode');
  M^.Put(hcDBValidate, 'Enable or disable database non-character field validators');
  M^.Put(hcImportData, 'Load records from the specified text file');
  M^.Put(hcExportData, 'Store records to the specified text file');
  M^.Put(hcImpExpOptions, 'Set defaults for data exchange procedures');
  M^.Put(hcFieldSeparator, 'Select new field separator character');
  M^.Put(hcSortDatabase, 'Rearrange records in the database file');
  M^.Put(hcHTMLHistoryList, 'Open the HTML reference history list window');
  M^.Put(hcHTMLHistory, 'Select a reference item or type for incremental search');
  M^.Put(hcHTMLTables, 'Enable or disable HTML table processing and display');
  M^.Put(hcHTMLReload, 'Reread HTML source file');
  M^.Put(hcPlaceMarkerDlg, 'Select a line containing a place marker to go to');
  M^.Put(hcMenuHelp, 'Get online Help');
  M^.Put(hcHHelp, 'Get context-sensitive Help');
  M^.Put(hcHContents, 'Show table of contents for online Help');
  M^.Put(hcHTopicSearch, 'Display Help on the word at the cursor');
  M^.Put(hcHPreviousTopic, 'Redisplay the last-viewed online Help screen');
  M^.Put(hcAltHelpName, 'Define or clear current Help file name');
  M^.Put(hcReopenHelp, 'Reopen indicated topic in a new Help window');
  M^.Put(hcGoToTopic, 'Switch to the specified Help context');
  M^.Put(hcSaveTopic, 'Put currently displayed Help screen to History list');
  M^.Put(hcOpenHelpBrowser, 'Open the Help Browser window');
  M^.Put(hcCloseHelpBrowser, 'Close the Help Browser window');
  M^.Put(hcYesButton, 'Perform the action');
  M^.Put(hcNoButton, 'Do not perform the action');
  M^.Put(hcOKButton, 'Accept the settings in this dialog box');
  M^.Put(hcCancelButton, 'Close the dialog box without making any changes');
  M^.Put(hcAppOutOfMemory, 'Heap or EMS overflow error');
  M^.Put(hcNewItemPos, 'Drag the selected item to a new location and press Enter');
  M^.Put(hcNewPhonePos, 'Select a new phone entry and press the Adjust button');
  M^.Put(hcCompilerError, 'Compiler error occurred. Press any key to remove message');
  M^.Put(hcError, 'User program terminated');
  M^.Put(hcNT_Recycle, 'Delete files or directories to Trash Bin (Windows NT only)');

  M^.Put($FF00, 'Авторы программы -');
  M^.Put($FF01, 'Борис Блант,');
  M^.Put($FF02, 'Дмитрий Орлов');
  M^.Put($FF03, 'и Ян Балтер -');
  M^.Put($FF04, 'выражают свою благодарность');
  M^.Put($FF05, 'всем, кто высказывал свои');
  M^.Put($FF06, 'замечания и пожелания, а особенно');
  M^.Put($FF07, 'нижеперечисленным фирмам,');
  M^.Put($FF08, 'командам и просто людям:');
  M^.Put($FF09, '');
  M^.Put($FF0A, 'Async stuff and other useful things:');
  M^.Put($FF0B, 'Copyright (c) TurboPower Software');
  M^.Put($FF0C, 'Portions');
  M^.Put($FF0D, 'Copyright (c) Information Technology');
  M^.Put($FF0E, '');
  M^.Put($FF0F, '"Wierd Stream Tricks":');
  M^.Put($FF10, 'Copyright (c) D.J.Murdoch');
  M^.Put($FF11, '');
  M^.Put($FF12, 'File Manager interface concept:');
  M^.Put($FF13, 'Copyright (c) Peter Norton Computing');
  M^.Put($FF14, '');
  M^.Put($FF15, 'Просмотр архивов:');
  M^.Put($FF16, 'Copyright (c) Назаренко С.В.');
  M^.Put($FF17, '');
  M^.Put($FF18, 'We wish to express our gratitude');
  M^.Put($FF19, 'to DOS Navigator Team');
  M^.Put($FF1A, 'for inspiration and ideas');
  M^.Put($FF1B, '');
  M^.Put($FF1C, 'CPU & CoCPU detection:');
  M^.Put($FF1D, 'Copyright (c) B-coolWare');
  M^.Put($FF1E, '');
  M^.Put($FF1F, 'Regular expressions:');
  M^.Put($FF20, 'Copyright (c) Henry Spencer,');
  M^.Put($FF21, 'University of Toronto');
  M^.Put($FF22, '');
  M^.Put($FF23, 'UNIX style file name wildcards:');
  M^.Put($FF24, 'Copyright (c) Keith S. Brown');
  M^.Put($FF25, '');
  M^.Put($FF26, 'Алгоритм русских переносов:');
  M^.Put($FF27, 'Copyright (c) Андрей Левочкин');
  M^.Put($FF28, '');
  M^.Put($FF29, 'Графические шрифты и команды принтера:');
  M^.Put($FF2A, 'Copyright (c) A.Gutnikov');
  M^.Put($FF2B, '');
  M^.Put($FF2C, 'Disassembler stuff:');
  M^.Put($FF2D, 'Copyright (c) William L. Peavy,');
  M^.Put($FF2E, 'Houston, Texas');
  M^.Put($FF2F, '');
  M^.Put($FF30, '"Overlay buffer in UMB" trick:');
  M^.Put($FF31, 'Copyright (c) Jean-Marc Lasgouttes');
  M^.Put($FF32, '');
  M^.Put($FF33, 'Interrupt list:');
  M^.Put($FF34, 'Copyright (c) Ralf Brown');
  M^.Put($FF35, '');
  M^.Put($FF36, 'NTOLDAPP library:');
  M^.Put($FF37, 'Copyright (c) Claus Andre Faerber');
  M^.Put($FF38, '');
  M^.Put($FF39, 'Special thanks to Borland International.');

  RSR^.Put(M, 'HINTS');
  Dispose(M, Done);
end;

procedure RSRStatusLine(RSR: PResourceFile);
var
  StatusLine: PRStatusLine;
  R: TRect;

function EmptyStatusKeys(Next: PStatusItem): PStatusItem;
begin
  EmptyStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F3~ Open', kbF3, cmOpenASCII,
    NewStatusKey('~Ctrl+F3~ Hex', kbCtrlF3, cmOpenHex,
    NewStatusKey('~Alt+F9~ Execute', kbAltF9, cmExecute,
    NewStatusKey('~F10~ Menu', kbF10, cmMenu,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbShiftF1, cmContents,
    NewStatusKey('', kbCtrlF1, cmTopicSearch,
    NewStatusKey('', kbAltF1, cmPreviousTopic,
    Next)))))))));
end;

function DraggingStatusKeys(Next: PStatusItem): PStatusItem;
begin
  DraggingStatusKeys :=
    NewStatusKey('~'#24#25#26#27'~ Move', kbNoKey, 0,
    NewStatusKey('~Shift+'#24#25#26#27'~ Resize', kbNoKey, 0,
    NewStatusKey('~─┘~ Done', kbNoKey, cmOk,
    NewStatusKey('~Esc~ Cancel', kbNoKey, cmCancel,
    NewStatusKey('', kbF1, cmHelp,
    NewStatusKey('', kbShiftF1, cmContents,
    NewStatusKey('', kbCtrlF1, cmTopicSearch,
    NewStatusKey('', kbAltF1, cmPreviousTopic,
    Next))))))));
end;

function CalcStatusKeys(Next: PStatusItem): PStatusItem;
begin
  CalcStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~Alt+F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~F10~ Menu', kbF10, cmMenu,
    NewStatusKey('~Alt+F10~ Pop-up', kbAltF10, cmPopup,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbShiftF1, cmContents,
    NewStatusKey('', kbCtrlF1, cmTopicSearch,
    NewStatusKey('', kbAltF1, cmPreviousTopic,
    NewStatusKey('', kbCtrlF5, cmResize,
    Next)))))))));
end;

function ASCIIStatusKeys(Next: PStatusItem): PStatusItem;
begin
  ASCIIStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F2~ Save', kbF2, cmSave,
    NewStatusKey('~F3~ Open', kbF3, cmOpenASCII,
    NewStatusKey('~Alt+F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~Alt+A~ Reload', kbAltA, cmUpdateASCII,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbF10, cmMenu,
    Next)))))));
end;

function CtrlKStatusKeys(Next: PStatusItem): PStatusItem;
begin
  CtrlKStatusKeys :=
    NewStatusKey('Editor status: Ctrl+K pressed.', kbNoKey, 0,
    NewStatusKey('', kbF10, cmMenu,
    Next));
end;

function CtrlQStatusKeys(Next: PStatusItem): PStatusItem;
begin
  CtrlQStatusKeys :=
    NewStatusKey('Editor status: Ctrl+Q pressed.', kbNoKey, 0,
    NewStatusKey('', kbF10, cmMenu,
    Next));
end;

function CtrlPStatusKeys(Next: PStatusItem): PStatusItem;
begin
  CtrlPStatusKeys :=
    NewStatusKey('Editor status: Ctrl+P pressed.', kbNoKey, 0,
    NewStatusKey('', kbF10, cmMenu,
    Next));
end;

function CtrlOStatusKeys(Next: PStatusItem): PStatusItem;
begin
  CtrlOStatusKeys :=
    NewStatusKey('Editor status: Ctrl+O pressed.', kbNoKey, 0,
    NewStatusKey('', kbF10, cmMenu,
    Next));
end;

function DrawSingleStatusKeys(Next: PStatusItem): PStatusItem;
begin
  DrawSingleStatusKeys :=
    NewStatusKey('~'#24#25#26#27'~ Move cursor', kbNoKey, 0,
    NewStatusKey('~Shift+'#24#25#26#27'~ Draw single lines', kbNoKey, 0,
    NewStatusKey('~Esc~ Cancel', kbNoKey, cmCancel,
    NewStatusKey('', kbF10, cmMenu,
    Next))));
end;

function DrawDoubleStatusKeys(Next: PStatusItem): PStatusItem;
begin
  DrawDoubleStatusKeys :=
    NewStatusKey('~'#24#25#26#27'~ Move cursor', kbNoKey, 0,
    NewStatusKey('~Shift+'#24#25#26#27'~ Draw double lines', kbNoKey, 0,
    NewStatusKey('~Esc~ Cancel', kbNoKey, cmCancel,
    NewStatusKey('', kbF10, cmMenu,
    Next))));
end;

function EditIncSearchStatusKeys(Next: PStatusItem): PStatusItem;
begin
  EditIncSearchStatusKeys :=
    NewStatusKey('Type for incremental search. Ctrl+L - next match, Back - previous', kbNoKey, 0,
    NewStatusKey('', kbF10, cmMenu,
    Next));
end;

function ClipboardStatusKeys(Next: PStatusItem): PStatusItem;
begin
  ClipboardStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F3~ Open', kbF3, cmOpenASCII,
    NewStatusKey('~Alt+F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~F10~ Menu', kbF10, cmMenu,
    NewStatusKey('~Alt+F10~ Pop-up', kbAltF10, cmPopup,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbShiftF1, cmContents,
    NewStatusKey('', kbCtrlF1, cmTopicSearch,
    NewStatusKey('', kbAltF1, cmPreviousTopic,
    NewStatusKey('', kbF5, cmZoom,
    NewStatusKey('', kbCtrlF5, cmResize,
    Next)))))))))));
end;

function HexStatusKeys(Next: PStatusItem): PStatusItem;
begin
  HexStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F2~ Save', kbF2, cmSave,
    NewStatusKey('~Ctrl+F3~ Hex', kbCtrlF3, cmOpenHex,
    NewStatusKey('~Alt+F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~Alt+H~ Reload', kbAltH, cmUpdateHex,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbF10, cmMenu,
    Next)))))));
end;

function AltEditStatusKeys(Next: PStatusItem): PStatusItem;
begin
  AltEditStatusKeys :=
    NewStatusKey('~Alt:~', kbNoKey, 0,
    NewStatusKey('~Back~ Undo', kbAltBack, cmUndo,
    NewStatusKey('~A~ Reload as ASCII', kbAltA, cmUpdateASCII,
    NewStatusKey('~H~ Reload as Hex', kbAltH, cmUpdateHex,
    NewStatusKey('~F10~ Pop-up', kbAltF10, cmPopUp,
    NewStatusKey('~X~ Exit', kbAltX, cmQuit,
    Next))))));
end;

function AltHexStatusKeys(Next: PStatusItem): PStatusItem;
begin
  AltHexStatusKeys :=
    NewStatusKey('~Alt:~', kbNoKey, 0,
    NewStatusKey('~F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~A~ Reload as ASCII', kbAltA, cmUpdateASCII,
    NewStatusKey('~H~ Reload as Hex', kbAltH, cmUpdateHex,
    NewStatusKey('~F10~ Pop-up', kbAltF10, cmPopUp,
    NewStatusKey('~X~ Exit', kbAltX, cmQuit,
    Next))))));
end;

function EditStatusDef(Next: PStatusDef): PStatusDef;
begin
  EditStatusDef :=
    NewStatusDef(hcASCIIEditor, hcASCIIEditor,
      ASCIIStatusKeys(nil),
    NewStatusDef(hcAltASCIIEditor, hcAltASCIIEditor,
      AltEditStatusKeys(nil),
    NewStatusDef(hcCtrlKPressed, hcCtrlKPressed,
      CtrlKStatusKeys(nil),
    NewStatusDef(hcCtrlQPressed, hcCtrlQPressed,
      CtrlQStatusKeys(nil),
    NewStatusDef(hcCtrlPPressed, hcCtrlPPressed,
      CtrlPStatusKeys(nil),
    NewStatusDef(hcCtrlOPressed, hcCtrlOPressed,
      CtrlOStatusKeys(nil),
    NewStatusDef(hcDrawSingle, hcDrawSingle,
      DrawSingleStatusKeys(nil),
    NewStatusDef(hcDrawDouble, hcDrawDouble,
      DrawDoubleStatusKeys(nil),
    NewStatusDef(hcClipboard, hcClipboard,
      ClipboardStatusKeys(nil),
    NewStatusDef(hcHexEditor, hcHexEditor,
      HexStatusKeys(nil),
    NewStatusDef(hcAltHexEditor, hcAltHexEditor,
      AltHexStatusKeys(nil),
    NewStatusDef(hcHexCtrlKPressed, hcHexCtrlKPressed,
      CtrlKStatusKeys(nil),
    NewStatusDef(hcHexCtrlQPressed, hcHexCtrlQPressed,
      CtrlQStatusKeys(nil),
    NewStatusDef(hcCtrlPPressed, hcCtrlPPressed,
      CtrlPStatusKeys(nil),
    NewStatusDef(hcCtrlOPressed, hcCtrlOPressed,
      CtrlOStatusKeys(nil),
    NewStatusDef(hcEditIncSearch, hcEditIncSearch,
      EditIncSearchStatusKeys(nil),
    Next))))))))))))))));
end;

function TextViewerStatusKeys(Next: PStatusItem): PStatusItem;
begin
  TextViewerStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F2~ Wrap', kbF2, cmToggleWrap,
    NewStatusKey('~F4~ Hex', kbF4, cmUpdateHex,
    NewStatusKey('~F7~ Find', kbF7, cmFind,
    NewStatusKey('~Alt+A~ Edit', kbAltA, cmUpdateASCII,
    NewStatusKey('~Esc~ Close', kbNoKey, cmClose,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbCtrlF2, cmCtrlToggleWrap,
    NewStatusKey('', kbShiftF7, cmSearchAgain,
    NewStatusKey('', kbF10, cmMenu,
    Next))))))))));
end;

function WrapTextViewerStatusKeys(Next: PStatusItem): PStatusItem;
begin
  WrapTextViewerStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F2~ Unwrap', kbF2, cmToggleWrap,
    NewStatusKey('~F4~ Hex', kbF4, cmUpdateHex,
    NewStatusKey('~F7~ Find', kbF7, cmFind,
    NewStatusKey('~Alt+A~ Edit', kbAltA, cmUpdateASCII,
    NewStatusKey('~Esc~ Close', kbNoKey, cmClose,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbCtrlF2, cmCtrlToggleWrap,
    NewStatusKey('', kbShiftF7, cmSearchAgain,
    NewStatusKey('', kbF10, cmMenu,
    Next))))))))));
end;

function HexViewerStatusKeys(Next: PStatusItem): PStatusItem;
begin
  HexViewerStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F2~ Save', kbF2, cmSave,
    NewStatusKey('~F4~ Text', kbF4, cmUpdateASCII,
    NewStatusKey('~F7~ Find', kbF7, cmFind,
    NewStatusKey('~Alt+H~ Edit', kbAltH, cmUpdateHex,
    NewStatusKey('~Esc~ Close', kbNoKey, cmClose,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbShiftF7, cmSearchAgain,
    NewStatusKey('', kbF10, cmMenu,
    Next)))))))));
end;

function ViewerCtrlKStatusKeys(Next: PStatusItem): PStatusItem;
begin
  ViewerCtrlKStatusKeys :=
    NewStatusKey('Viewer status: Ctrl+K pressed.', kbNoKey, 0,
    NewStatusKey('', kbF10, cmMenu,
    Next));
end;

function ViewerCtrlQStatusKeys(Next: PStatusItem): PStatusItem;
begin
  ViewerCtrlQStatusKeys :=
    NewStatusKey('Viewer status: Ctrl+Q pressed.', kbNoKey, 0,
    NewStatusKey('', kbF10, cmMenu,
    Next));
end;

function AltTextViewerStatusKeys(Next: PStatusItem): PStatusItem;
begin
  AltTextViewerStatusKeys :=
    NewStatusKey('~Alt:~', kbNoKey, 0,
    NewStatusKey('~A~ Reload as ASCII', kbAltA, cmUpdateASCII,
    NewStatusKey('~H~ Reload as Hex', kbAltH, cmUpdateHex,
    NewStatusKey('~F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~F10~ Pop-up', kbAltF10, cmPopUp,
    NewStatusKey('~X~ Exit', kbAltX, cmQuit,
    Next))))));
end;

function AltHexViewerStatusKeys(Next: PStatusItem): PStatusItem;
begin
  AltHexViewerStatusKeys := AltTextViewerStatusKeys(Next);
end;

function ViewerStatusDef(Next: PStatusDef): PStatusDef;
begin
  ViewerStatusDef :=
    NewStatusDef(hcTextViewer, hcTextViewer,
      TextViewerStatusKeys(nil),
    NewStatusDef(hcWrapTextViewer, hcWrapTextViewer,
      WrapTextViewerStatusKeys(nil),
    NewStatusDef(hcAltTextViewer, hcAltTextViewer,
      AltTextViewerStatusKeys(nil),
    NewStatusDef(hcHexViewer, hcHexViewer,
      HexViewerStatusKeys(nil),
    NewStatusDef(hcAltHexViewer, hcAltHexViewer,
      AltHexViewerStatusKeys(nil),
    NewStatusDef(hcViewerCtrlKPressed, hcViewerCtrlKPressed,
      ViewerCtrlKStatusKeys(nil),
    NewStatusDef(hcViewerCtrlQPressed, hcViewerCtrlQPressed,
      ViewerCtrlQStatusKeys(nil),
    NewStatusDef(hcHexViewerCtrlKPressed, hcHexViewerCtrlKPressed,
      ViewerCtrlKStatusKeys(nil),
    NewStatusDef(hcHexViewerCtrlQPressed, hcHexViewerCtrlQPressed,
      ViewerCtrlQStatusKeys(nil),
    Next)))))))));
end;

function MessageStatusKeys(Next: PStatusItem): PStatusItem;
begin
  MessageStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~─┘~ Go to source', kbEnter, cmOk,
    NewStatusKey('~Space~ Track source', kbSpace, cmYes,
    NewStatusKey('~F7~ Find', kbF7, cmFind,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbCtrlEnter, cmOk,
    NewStatusKey('', kbF10, cmMenu,
    Next)))))));
end;

function WatchStatusKeys(Next: PStatusItem): PStatusItem;
begin
  WatchStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~Alt+F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~Ins~ Add', kbIns, cmAddWatch,
    NewStatusKey('~Enter~ Edit', kbEnter, cmEditWatch,
    NewStatusKey('~Del~ Delete', kbDel, cmDeleteWatch,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbF10, cmMenu,
    Next)))))));
end;

function OutputStatusKeys(Next: PStatusItem): PStatusItem;
begin
  OutputStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~Ctrl+Del~ Clear', kbCtrlDel, cmClearOutput,
    NewStatusKey('~Alt+F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~Alt+F10~ Pop-up', kbAltF10, cmPopup,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbF10, cmMenu,
    Next))))));
end;

function TerminalStatusKeys(Next: PStatusItem): PStatusItem;
begin
  TerminalStatusKeys :=
    NewStatusKey('~PgUp~ Upload', kbNoKey, cmUpload,
    NewStatusKey('~Ctrl+Del~ Clear', kbNoKey, cmFileClear,
    NewStatusKey('~Alt+F3~ Close', kbNoKey, cmClose,
    NewStatusKey('~Alt+F10~ Pop-up', kbNoKey, cmPopup,
    NewStatusKey('~Alt+X~ Exit', kbNoKey, cmQuit,
    NewStatusKey('', kbNoKey, cmDownload,
    NewStatusKey('', kbNoKey, cmDial,
    NewStatusKey('', kbNoKey, cmBack,
    NewStatusKey('', kbNoKey, cmHangup,
    NewStatusKey('', kbNoKey, cmAnswer,
    Next))))))))));
end;

function WindowStatusDef(Next: PStatusDef): PStatusDef;
begin
  WindowStatusDef :=
    NewStatusDef(hcMessage, hcMessage,
      MessageStatusKeys(nil),
    NewStatusDef(hcWatchWindow, hcWatchWindow,
      WatchStatusKeys(nil),
    NewStatusDef(hcOutputWindow, hcOutputWindow,
      OutputStatusKeys(nil),
    NewStatusDef(hcTerminal, hcTerminal,
      TerminalStatusKeys(nil),
    Next))));
end;

function SourceStatusKeys(Next: PStatusItem): PStatusItem;
begin
  SourceStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F3~ Open', kbF3, cmOpenASCII,
    NewStatusKey('~Alt+F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~Alt+F10~ Pop-up', kbAltF10, cmPopUp,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbF10, cmMenu,
    Next))))));
end;

function SourceListStatusKeys(Next: PStatusItem): PStatusItem;
begin
  SourceListStatusKeys :=
    NewStatusKey('~Ctrl:~', kbNoKey, 0,
    NewStatusKey('~G~o to', kbNoKey, cmGoTo,
    NewStatusKey('~O~rigin', kbNoKey, cmOrigin,
    NewStatusKey('~F~ind', kbNoKey, cmFind,
    NewStatusKey('~S~earch again', kbNoKey, cmSearchAgain,
    Next)))));
end;

function RegistersListStatusKeys(Next: PStatusItem): PStatusItem;
begin
  RegistersListStatusKeys :=
    NewStatusKey('~Ctrl:~', kbNoKey, 0,
    NewStatusKey('I~n~crement', kbNoKey, cmIncrement,
    NewStatusKey('~D~ecrement', kbNoKey, cmDecrement,
    NewStatusKey('~Z~ero', kbNoKey, cmZero,
    NewStatusKey('~C~hange', kbNoKey, cmChange,
    Next)))));
end;

function FlagsListStatusKeys(Next: PStatusItem): PStatusItem;
begin
  FlagsListStatusKeys :=
    NewStatusKey('~Ctrl:~', kbNoKey, 0,
    NewStatusKey('~T~oggle', kbNoKey, cmChange,
    Next));
end;

function MemListStatusKeys(Next: PStatusItem): PStatusItem;
begin
  MemListStatusKeys :=
    NewStatusKey('~Ctrl:~', kbNoKey, 0,
    NewStatusKey('~G~o to', kbNoKey, cmGoTo,
    NewStatusKey('~O~pposite', kbNoKey, cmGoOpposite,
    NewStatusKey('~F~ind', kbNoKey, cmFind,
    NewStatusKey('~S~earch again', kbNoKey, cmSearchAgain,
    NewStatusKey('~W~rite to', kbNoKey, cmWriteTo,
    NewStatusKey('~R~ead from', kbNoKey, cmReadFrom,
    Next)))))));
end;

function StackListStatusKeys(Next: PStatusItem): PStatusItem;
begin
  StackListStatusKeys :=
    NewStatusKey('~Ctrl:~', kbNoKey, 0,
    NewStatusKey('~G~o to', kbNoKey, cmGoTo,
    NewStatusKey('~O~rigin', kbNoKey, cmOrigin,
    NewStatusKey('~F~ollow', kbNoKey, cmFollow,
    NewStatusKey('~C~hange', kbNoKey, cmChange,
    Next)))));
end;

function CPUStatusDef(Next: PStatusDef): PStatusDef;
begin
  CPUStatusDef :=
    NewStatusDef(hcSource, hcStack,
      SourceStatusKeys(nil),
    NewStatusDef(hcSourceList, hcSourceList,
      SourceListStatusKeys(nil),
    NewStatusDef(hcRegistersList, hcRegistersList,
      RegistersListStatusKeys(nil),
    NewStatusDef(hcFlagsList, hcFlagsList,
      FlagsListStatusKeys(nil),
    NewStatusDef(hcMemList, hcMemList,
      MemListStatusKeys(nil),
    NewStatusDef(hcStackList, hcStackList,
      StackListStatusKeys(nil),
    Next))))));
end;

function ContentsStatusKeys(Next: PStatusItem): PStatusItem;
begin
  ContentsStatusKeys :=
    NewStatusKey('~Alt+F1~ Previous', kbAltF1, cmPreviousTopic,
    NewStatusKey('~Ctrl+F1~ Topics', kbCtrlF1, cmTopicSearch,
    NewStatusKey('~Shift+F1~ Contents', kbShiftF1, cmContents,
    NewStatusKey('~Alt+F10~ Pop-up', kbAltF10, cmPopUp,
    NewStatusKey('', kbF1, cmHelp,
    NewStatusKey('', kbAltF3, cmClose,
    NewStatusKey('', kbCtrlF5, cmResize,
    NewStatusKey('', kbF5, cmZoom,
    NewStatusKey('', kbAltZ, cmZoom,
    NewStatusKey('', kbF10, cmMenu,
    Next))))))))));
end;

function PanelStatusKeys(Next: PStatusItem): PStatusItem;
begin
  PanelStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F3~ View', kbF3, cmFView,
    NewStatusKey('~F4~ Edit', kbF4, cmIsASCII,
    NewStatusKey('~F5~ Copy', kbF5, cmFCopy,
    NewStatusKey('~F6~ RenMov', kbF6, cmFRenMov,
    NewStatusKey('~F7~ MkDir', kbF7, cmFMkDir,
    NewStatusKey('~F8~ Delete', kbF8, cmFDelete,
    NewStatusKey('', kbAltF1, cmSelectLeftDrive,
    NewStatusKey('', kbAltF2, cmSelectRightDrive,
    NewStatusKey('', kbAltF3, cmFAltView,
    NewStatusKey('', kbAltF4, cmClose,
    NewStatusKey('', kbAltF7, cmFindFileDlg,
    NewStatusKey('', kbAltF10, cmPopUp,
    NewStatusKey('', kbAltF12, cmResize,
    NewStatusKey('', kbAltK, cmPanelSettings,
    NewStatusKey('', kbAltS, cmIncSearch,
    NewStatusKey('', kbAltY, cmExecOptions,
    NewStatusKey('', kbAltBack, cmRestoreSelection,
    NewStatusKey('', kbCtrlF1, cmToggleLeftPanel,
    NewStatusKey('', kbCtrlF2, cmToggleRightPanel,
    NewStatusKey('', kbCtrlF3, cmFCtrlView,
    NewStatusKey('', kbCtrlF5, cmFCtrlCopy,
    NewStatusKey('', kbCtrlF6, cmFCtrlRenMov,
    NewStatusKey('', kbCtrlF8, cmFCtrlDelete,
    NewStatusKey('', kbShiftF1, cmArcCopyDlg,
    NewStatusKey('', kbShiftF3, cmFShiftView,
    NewStatusKey('', kbShiftF4, cmOpenASCII,
    NewStatusKey('', kbShiftF5, cmShiftCopy,
    NewStatusKey('', kbShiftF6, cmShiftRenMov,
    NewStatusKey('', kbShiftF7, cmShiftMkDir,
    NewStatusKey('', kbShiftF8, cmShiftDelete,
    NewStatusKey('', kbF10, cmMenu,
    Next))))))))))))))))))))))))))))))));
end;

{ Added 2005.10.11 to support extended panel status line }
function XPanelStatusKeys(Next: PStatusItem): PStatusItem;
begin
  XPanelStatusKeys :=
    NewStatusKey('~1~ Help', kbF1, cmHelp,
    NewStatusKey('~2~ User', kbF2, cmUserMenu,
    NewStatusKey('~3~ View', kbF3, cmFView,
    NewStatusKey('~4~ Edit', kbF4, cmIsASCII,
    NewStatusKey('~5~ Copy', kbF5, cmFCopy,
    NewStatusKey('~6~ RenMov', kbF6, cmFRenMov,
    NewStatusKey('~7~ MkDir', kbF7, cmFMkDir,
    NewStatusKey('~8~ Del', kbF8, cmFDelete,
    NewStatusKey('~9~ Menu', kbF9, cmMenu,
    NewStatusKey('1~0~ Exit', kbF10, cmQuit,
    NewStatusKey('', kbAltF1, cmSelectLeftDrive,
    NewStatusKey('', kbAltF2, cmSelectRightDrive,
    NewStatusKey('', kbAltF3, cmFAltView,
    NewStatusKey('', kbAltF4, cmClose,
    NewStatusKey('', kbAltF7, cmFindFileDlg,
    NewStatusKey('', kbAltF10, cmPopUp,
    NewStatusKey('', kbAltF12, cmResize,
    NewStatusKey('', kbAltK, cmPanelSettings,
    NewStatusKey('', kbAltS, cmIncSearch,
    NewStatusKey('', kbAltY, cmExecOptions,
    NewStatusKey('', kbAltBack, cmRestoreSelection,
    NewStatusKey('', kbCtrlF1, cmToggleLeftPanel,
    NewStatusKey('', kbCtrlF2, cmToggleRightPanel,
    NewStatusKey('', kbCtrlF3, cmFCtrlView,
    NewStatusKey('', kbCtrlF5, cmFCtrlCopy,
    NewStatusKey('', kbCtrlF6, cmFCtrlRenMov,
    NewStatusKey('', kbCtrlF8, cmFCtrlDelete,
    NewStatusKey('', kbShiftF1, cmArcCopyDlg,
    NewStatusKey('', kbShiftF3, cmFShiftView,
    NewStatusKey('', kbShiftF4, cmOpenASCII,
    NewStatusKey('', kbShiftF5, cmShiftCopy,
    NewStatusKey('', kbShiftF6, cmShiftRenMov,
    NewStatusKey('', kbShiftF7, cmShiftMkDir,
    NewStatusKey('', kbShiftF8, cmShiftDelete,
    NewStatusKey('', kbShiftF10, cmUserPrograms,
    Next)))))))))))))))))))))))))))))))))));
end;

function AltPanelStatusKeys(Next: PStatusItem): PStatusItem;
begin
  AltPanelStatusKeys :=
    NewStatusKey('~Alt:~', kbNoKey, 0,
    NewStatusKey('~F1~ Left', kbAltF1, cmSelectLeftDrive,
    NewStatusKey('~F2~ Right', kbAltF2, cmSelectRightDrive,
    NewStatusKey('~F4~ Close', kbAltF4, cmClose,
    NewStatusKey('~F7~ Find', kbAltF7, cmFindFileDlg,
    NewStatusKey('~A~ Open archive', kbAltA, cmOpenArchive,
    NewStatusKey('~F10~ Pop-up', kbAltF10, cmPopUp,
    NewStatusKey('', kbAltF3, cmFAltView,
    NewStatusKey('', kbAltF12, cmResize,
    NewStatusKey('', kbAltK, cmPanelSettings,
    NewStatusKey('', kbAltS, cmIncSearch,
    NewStatusKey('', kbAltY, cmExecOptions,
    NewStatusKey('', kbAltBack, cmRestoreSelection,
    Next)))))))))))));
end;

function CtrlPanelStatusKeys(Next: PStatusItem): PStatusItem;
begin
  CtrlPanelStatusKeys :=
    NewStatusKey('~Ctrl:~', kbNoKey, 0,
    NewStatusKey('~B~rief', kbNoKey, cmBrief,
    NewStatusKey('~F~ull', kbNoKey, cmFull,
    NewStatusKey('~T~ree', kbNoKey, cmTree,
    NewStatusKey('~I~nfo', kbNoKey, cmInfo,
    NewStatusKey('~R~e-read', kbNoKey, cmReRead,
    NewStatusKey('~A~ttributes', kbNoKey, cmFAttributes,
    NewStatusKey('~C~ompare', kbNoKey, cmCompareDirs,
    NewStatusKey('~O~n/Off', kbNoKey, cmTogglePanels,
    NewStatusKey('', kbAltK, cmPanelSettings,
    NewStatusKey('', kbAltY, cmExecOptions,
    NewStatusKey('', kbAltF12, cmResize,
    NewStatusKey('', kbCtrlF1, cmToggleLeftPanel,
    NewStatusKey('', kbCtrlF2, cmToggleRightPanel,
    NewStatusKey('', kbCtrlF3, cmFCtrlView,
    NewStatusKey('', kbCtrlF4, cmIsHex,
    NewStatusKey('', kbCtrlF5, cmFCtrlCopy,
    NewStatusKey('', kbCtrlF6, cmFCtrlRenMov,
    NewStatusKey('', kbCtrlF8, cmFCtrlDelete,
    Next)))))))))))))))))));
end;

function ArcPanelStatusKeys(Next: PStatusItem): PStatusItem;
begin
  ArcPanelStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F3~ View', kbF3, cmFView,
    NewStatusKey('~F4~ Extract', kbF4, cmExtract,
    NewStatusKey('~F5~ Copy', kbF5, cmFCopy,
    NewStatusKey('~F6~ Test', kbF6, cmTest,
    NewStatusKey('~F7~ Password', kbF7, cmPassword,
    NewStatusKey('~F8~ Delete', kbF8, cmFDelete,
    NewStatusKey('', kbAltF1, cmSelectLeftDrive,
    NewStatusKey('', kbAltF2, cmSelectRightDrive,
    NewStatusKey('', kbAltF3, cmFAltView,
    NewStatusKey('', kbAltF4, cmClose,
    NewStatusKey('', kbAltF7, cmFindFileDlg,
    NewStatusKey('', kbAltF10, cmPopUp,
    NewStatusKey('', kbAltK, cmPanelSettings,
    NewStatusKey('', kbAltS, cmIncSearch,
    NewStatusKey('', kbAltY, cmExecOptions,
    NewStatusKey('', kbAltBack, cmRestoreSelection,
    NewStatusKey('', kbCtrlF1, cmToggleLeftPanel,
    NewStatusKey('', kbCtrlF2, cmToggleRightPanel,
    NewStatusKey('', kbCtrlF3, cmFCtrlView,
    NewStatusKey('', kbShiftF3, cmFShiftView,
    NewStatusKey('', kbShiftF4, cmOpenASCII,
    NewStatusKey('', kbShiftF5, cmShiftCopy,
    NewStatusKey('', kbShiftF6, cmShiftRenMov,
    NewStatusKey('', kbShiftF7, cmShiftMkDir,
    NewStatusKey('', kbShiftF8, cmShiftDelete,
    NewStatusKey('', kbF10, cmMenu,
    Next)))))))))))))))))))))))))));
end;

function IncrSearchStatusKeys(Next: PStatusItem): PStatusItem;
begin
  IncrSearchStatusKeys :=
    NewStatusKey('Type for incremental search, Ctrl+L for next match', kbNoKey, 0,
    NewStatusKey('', kbF3, cmFView,
    NewStatusKey('', kbF4, cmIsASCII,
    NewStatusKey('', kbF5, cmFCopy,
    NewStatusKey('', kbF6, cmFRenMov,
    NewStatusKey('', kbF7, cmFMkDir,
    NewStatusKey('', kbF8, cmFDelete,
    NewStatusKey('', kbAltF1, cmSelectLeftDrive,
    NewStatusKey('', kbAltF2, cmSelectRightDrive,
    NewStatusKey('', kbAltF3, cmFAltView,
    NewStatusKey('', kbAltF4, cmClose,
    NewStatusKey('', kbAltF7, cmFindFileDlg,
    NewStatusKey('', kbAltF10, cmPopUp,
    NewStatusKey('', kbAltF12, cmResize,
    NewStatusKey('', kbAltK, cmPanelSettings,
    NewStatusKey('', kbAltS, cmIncSearch,
    NewStatusKey('', kbAltY, cmExecOptions,
    NewStatusKey('', kbAltBack, cmRestoreSelection,
    NewStatusKey('', kbCtrlF1, cmToggleLeftPanel,
    NewStatusKey('', kbCtrlF2, cmToggleRightPanel,
    NewStatusKey('', kbCtrlF5, cmFCtrlCopy,
    NewStatusKey('', kbCtrlF6, cmFCtrlRenMov,
    NewStatusKey('', kbCtrlF8, cmFCtrlDelete,
    NewStatusKey('', kbShiftF1, cmArcCopyDlg,
    NewStatusKey('', kbShiftF3, cmFShiftView,
    NewStatusKey('', kbShiftF4, cmOpenASCII,
    NewStatusKey('', kbShiftF5, cmShiftCopy,
    NewStatusKey('', kbShiftF6, cmShiftRenMov,
    NewStatusKey('', kbShiftF7, cmShiftMkDir,
    NewStatusKey('', kbShiftF8, cmShiftDelete,
    NewStatusKey('', kbF10, cmMenu,
    Next)))))))))))))))))))))))))))))));
end;

function ArcIncrSearchStatusKeys(Next: PStatusItem): PStatusItem;
begin
  ArcIncrSearchStatusKeys :=
    NewStatusKey('Type for incremental search, Ctrl+L for next match', kbNoKey, 0,
    NewStatusKey('', kbF3, cmFView,
    NewStatusKey('', kbF4, cmExtract,
    NewStatusKey('', kbF5, cmFCopy,
    NewStatusKey('', kbF6, cmTest,
    NewStatusKey('', kbF7, cmPassword,
    NewStatusKey('', kbF8, cmFDelete,
    NewStatusKey('', kbAltF1, cmSelectLeftDrive,
    NewStatusKey('', kbAltF2, cmSelectRightDrive,
    NewStatusKey('', kbAltF3, cmFAltView,
    NewStatusKey('', kbAltF4, cmClose,
    NewStatusKey('', kbAltF7, cmFindFileDlg,
    NewStatusKey('', kbAltF10, cmPopUp,
    NewStatusKey('', kbAltK, cmPanelSettings,
    NewStatusKey('', kbAltS, cmIncSearch,
    NewStatusKey('', kbAltY, cmExecOptions,
    NewStatusKey('', kbAltBack, cmRestoreSelection,
    NewStatusKey('', kbCtrlF1, cmToggleLeftPanel,
    NewStatusKey('', kbCtrlF2, cmToggleRightPanel,
    NewStatusKey('', kbShiftF3, cmFShiftView,
    NewStatusKey('', kbShiftF4, cmOpenASCII,
    NewStatusKey('', kbShiftF5, cmShiftCopy,
    NewStatusKey('', kbShiftF6, cmShiftRenMov,
    NewStatusKey('', kbShiftF7, cmShiftMkDir,
    NewStatusKey('', kbShiftF8, cmShiftDelete,
    NewStatusKey('', kbF10, cmMenu,
    Next))))))))))))))))))))))))));
end;

function PromptLineStatusKeys(Next: PStatusItem): PStatusItem;
begin
  PromptLineStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~Alt+F1~ Left', kbAltF1, cmSelectLeftDrive,
    NewStatusKey('~Alt+F2~ Right', kbAltF2, cmSelectRightDrive,
    NewStatusKey('~Alt+F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~Alt+F10~ Pop-up', kbAltF10, cmPopUp,
    NewStatusKey('', kbAltF4, cmClose,
    NewStatusKey('', kbAltF7, cmFindFileDlg,
    NewStatusKey('', kbF10, cmMenu,
    NewStatusKey('', kbShiftF1, cmArcCopyDlg,
    NewStatusKey('', kbShiftF4, cmOpenASCII,
    NewStatusKey('', kbShiftF5, cmShiftCopy,
    NewStatusKey('', kbShiftF6, cmShiftRenMov,
    NewStatusKey('', kbF7, cmFMkDir,
    NewStatusKey('', kbShiftF7, cmShiftMkDir,
    NewStatusKey('', kbShiftF8, cmShiftDelete,
    NewStatusKey('', kbAltK, cmPanelSettings,
    NewStatusKey('', kbAltY, cmExecOptions,
    NewStatusKey('', kbCtrlF1, cmToggleLeftPanel,
    NewStatusKey('', kbCtrlF2, cmToggleRightPanel,
    Next)))))))))))))))))));
end;

function FindFileStatusKeys(Next: PStatusItem): PStatusItem;
begin
  FindFileStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~Alt+F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~F3~ View', kbF3, cmFView,
    NewStatusKey('~F4~ Edit', kbF4, cmIsASCII,
    NewStatusKey('~F5~ Copy', kbF5, cmFCopy,
    NewStatusKey('~F6~ RenMov', kbF6, cmFRenMov,
    NewStatusKey('~F8~ Delete', kbF8, cmFDelete,
    NewStatusKey('', kbCtrlF3, cmFAltView,
    NewStatusKey('', kbCtrlF4, cmIsHex,
    NewStatusKey('', kbShiftF1, cmContents,
    NewStatusKey('', kbCtrlF1, cmTopicSearch,
    NewStatusKey('', kbAltF1, cmPreviousTopic,
    NewStatusKey('', kbAltF12, cmResize,
    NewStatusKey('', kbCtrlF5, cmFCtrlCopy,
    NewStatusKey('', kbCtrlF6, cmFCtrlRenMov,
    NewStatusKey('', kbCtrlF8, cmFCtrlDelete,
    Next))))))))))))))));
end;

function PanelStatusDef(Next: PStatusDef): PStatusDef;
begin
  PanelStatusDef :=
    NewStatusDef(hcPanel, hcPanel,
      PanelStatusKeys(nil),
{ Added 2005.10.11 to support extended panel status line }
    NewStatusDef(hcXPanel, hcXPanel,
      XPanelStatusKeys(nil),
    NewStatusDef(hcAltPanel, hcAltPanel,
      AltPanelStatusKeys(nil),
    NewStatusDef(hcCtrlPanel, hcCtrlPanel,
      CtrlPanelStatusKeys(nil),
    NewStatusDef(hcArcPanel, hcArcPanel,
      ArcPanelStatusKeys(nil),
    NewStatusDef(hcIncrSearch, hcIncrSearch,
      IncrSearchStatusKeys(nil),
    NewStatusDef(hcArcIncrSearch, hcArcIncrSearch,
      ArcIncrSearchStatusKeys(nil),
    NewStatusDef(hcPromptLine, hcPromptLine,
      PromptLineStatusKeys(nil),
    NewStatusDef(hcFindFileDlg, hcFindFileDlg,
      FindFileStatusKeys(nil),
    Next)))))))));
end;

function UserMenuStatusKeys(Next: PStatusItem): PStatusItem;
begin
  UserMenuStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~Enter~ Run', kbEnter, cmOk,
    NewStatusKey('~Ctrl+Enter~ Edit', kbCtrlEnter, cmModifyItem,
    NewStatusKey('~Ins~ New', kbIns, cmNewItem,
    NewStatusKey('~Del~ Delete', kbDel, cmDeleteItem,
    NewStatusKey('~Esc~ Cancel', kbEsc, cmCancel,
    NewStatusKey('', kbAltF3, cmClose,
    Next)))))));
end;

function DataViewerStatusKeys(Next: PStatusItem): PStatusItem;
begin
  DataViewerStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F2~ Fields', kbF2, cmPuzzle,
    NewStatusKey('~F4~ View memo', kbF4, cmRunItem,
    NewStatusKey('~F7~ Find', kbF7, cmFind,
    NewStatusKey('~F8~ Delete', kbF8, cmDeleteItem,
    NewStatusKey('~Alt+F10~ Pop-up', kbAltF10, cmPopUp,
    NewStatusKey('', kbCtrlF4, cmNewItemPos,
    NewStatusKey('', kbAltF2, cmNewItem,
    NewStatusKey('', kbShiftF7, cmSearchAgain,
    NewStatusKey('', kbShiftF8, cmModifyItem,
    NewStatusKey('', kbF10, cmMenu,
    Next)))))))))));
end;

function HTMLViewerStatusKeys(Next: PStatusItem): PStatusItem;
begin
  HTMLViewerStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~Alt+F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~F7~ Find', kbF7, cmFind,
    NewStatusKey('~F10~ Menu', kbF10, cmMenu,
    NewStatusKey('~Alt+F10~ Pop-up', kbAltF10, cmPopup,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbShiftF7, cmSearchAgain,
    NewStatusKey('', kbF10, cmMenu,
    Next))))))));
end;

function PhoneBookStatusKeys(Next: PStatusItem): PStatusItem;
begin
  PhoneBookStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~F2~ Dial', kbF2, cmRunItem,
    NewStatusKey('~F4~ Import', kbF4, cmImport,
    NewStatusKey('~F5~ Export', kbF5, cmExport,
    NewStatusKey('~F6~ Abort', kbF6, cmAbort,
    NewStatusKey('~F7~ Find', kbF7, cmSeek,
    NewStatusKey('~F8~ Delete', kbF8, cmDeleteItem,
    NewStatusKey('', kbAltF3, cmClose,
    NewStatusKey('', kbCtrlF2, cmRunItem,
    NewStatusKey('', kbShiftF2, cmRunItem,
    NewStatusKey('', kbShiftF7, cmSeekAgain,
    Next)))))))))));
end;

function WinIconStatusKeys(Next: PStatusItem): PStatusItem;
begin
  WinIconStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~Alt+F3~ Close', kbAltF3, cmClose,
    NewStatusKey('~'#24#25#26#27'~ Move', kbNoKey, 0,
    NewStatusKey('~Enter~ Maximize', kbEnter, cmOk,
    NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
    NewStatusKey('', kbSpace, cmOk,
    NewStatusKey('', kbAltM, cmOk,
    NewStatusKey('', kbF10, cmMenu,
    Next))))))));
end;

function CDPlayerStatusKeys(Next: PStatusItem): PStatusItem;
begin
  CDPlayerStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('~S~top', kbNoKey, cmStopPlay,
    NewStatusKey('~P~lay', kbNoKey, cmPlayAudio,
    NewStatusKey('Pa~u~se', kbNoKey, cmPausePlay,
    NewStatusKey('E~j~ect', kbNoKey, cmEjectDisk,
    NewStatusKey('Pr~i~or', kbNoKey, cmSkipBack,
    NewStatusKey('~R~ewind', kbNoKey, cmRewind,
    NewStatusKey('~F~ast forward', kbNoKey, cmFastForward,
    NewStatusKey('~N~ext', kbNoKey, cmSkipForward,
    NewStatusKey('', kbF10, cmMenu,
    Next))))))))));
end;

function CtrlCDPlayerStatusKeys(Next: PStatusItem): PStatusItem;
begin
  CtrlCDPlayerStatusKeys :=
    NewStatusKey('~Ctrl:~', kbNoKey, 0,
    NewStatusKey('~Home~ First', kbNoKey, cmFirstTrack,
    NewStatusKey('~Left~ Prior', kbNoKey, cmSkipBack,
    NewStatusKey('~Right~ Next', kbNoKey, cmSkipForward,
    NewStatusKey('~End~ Last', kbNoKey, cmLastTrack,
    NewStatusKey('~Ins~ Force eject', kbNoKey, cmEjectDisk,
    Next))))));
end;

function RestStatusKeys(Next: PStatusItem): PStatusItem;
begin
  RestStatusKeys :=
    NewStatusKey('~F1~ Help', kbF1, cmHelp,
    NewStatusKey('', kbShiftF1, cmContents,
    NewStatusKey('', kbCtrlF1, cmTopicSearch,
    NewStatusKey('', kbAltF1, cmPreviousTopic,
    NewStatusKey('', kbAltF3, cmClose,
    NewStatusKey('', kbCtrlF5, cmResize,
    NewStatusKey('', kbF5, cmZoom,
    NewStatusKey('', kbF10, cmMenu,
    Next))))))));
end;

begin
  Application^.GetExtent(R);
  R.B.X := R.A.X + 132;
  R.A.Y := R.B.Y - 1;
  StatusLine := New(PRStatusLine, Init(R,
    NewStatusDef(hcNoContext, hcNoContext,
      EmptyStatusKeys(nil),
    NewStatusDef(hcDragging, hcDragging,
      DraggingStatusKeys(nil),
    NewStatusDef(hcCalculator, hcCalculator,
      CalcStatusKeys(nil),
    EditStatusDef(
    ViewerStatusDef(
    WindowStatusDef(
    CPUStatusDef(
    NewStatusDef(hcRunning, hcRunning,
      NewStatusKey('Program running. Ctrl+Break aborts.', kbNoKey, 0,
    nil),
    NewStatusDef(hcStatusWindow, hcStatusWindow,
      NewStatusKey('Protocol handshake in progress. Esc aborts.', kbNoKey, 0,
    nil),
    NewStatusDef(hcContents, hcContents,
      ContentsStatusKeys(nil),
    NewStatusDef(hcKeyView, hcKeyView,
      NewStatusKey(
        'Select a key or a two-key combination; mouse double click clears.',
{       kbAltF1, cmClear,} kbNoKey, 0,
    nil),
    NewStatusDef(hcHotKeyList, hcHotKeyList,
      NewStatusKey(
        'Press keys to add to the hot key sequence; Ctrl+Break aborts.',
        kbNoKey, 0,
    nil),
    PanelStatusDef(
    NewStatusDef(hcUserMenuDlg, hcUserMenuDlg, UserMenuStatusKeys(nil),
    NewStatusDef(hcDataViewer, hcDataViewer, DataViewerStatusKeys(nil),
    NewStatusDef(hcHTMLViewer, hcHTMLViewer, HTMLViewerStatusKeys(nil),
    NewStatusDef(hcPhoneBook, hcPhoneBook, PhoneBookStatusKeys(nil),
    NewStatusDef(hcWinIcon, hcWinIcon, WinIconStatusKeys(nil),
    NewStatusDef(hcCDPlayer, hcCDPlayer, CDPlayerStatusKeys(nil),
    NewStatusDef(hcCtrlCDPlayer, hcCtrlCDPlayer, CtrlCDPlayerStatusKeys(nil),
    NewStatusDef(hcDragging, $FFFF,
      RestStatusKeys(nil),
  nil)))))))))))))))))))))));
  StatusLine^.HintsList := nil;
  RSR^.Put(StatusLine, 'STATUSLINE');
  Dispose(StatusLine, Done);
end;

procedure RSRMenuBar(RSR: PResourceFile);
var
  MenuBar: PMenuBar;
  R: TRect;

function SystemMenuItems(Next: PMenuItem): PMenuItem;
begin
  SystemMenuItems :=
    NewItem('~A~bout...', '', kbNoKey, cmAbout, hcSAbout,
    NewItem('System ~i~nformation...', 'F11', kbF11, cmSystemInfo, hcSInfo,
    NewLine(
    NewItem('Re~f~resh display', '', kbNoKey, cmRefreshDisplay,
      hcSRefreshDisplay,
    NewItem('Clear des~k~top', '', kbNoKey, cmClearDesktop,
      hcSClearDesktop,
    NewItem('Clear ~h~istory', 'Alt+Del', kbAltDel, cmClearHistory,
      hcSClearHistory,
    NewLine(
    NewItem('~M~emory map', '', kbNoKey, cmMap, hcSMemoryMap,
    NewItem('Cod~e~', '', kbNoKey, cmCode, hcSCode,
    NewItem('~D~ump', '', kbNoKey, cmDump, hcSDump,
    NewItem('En~v~ironment...', 'Alt+F11', kbAltF11, cmEnvDlg, hcSEnvDlg,
    NewLine(
    NewItem('Alarm cl~o~ck...', 'Alt+<', kbAltLess, cmAlarm, hcSAlarm,
    NewItem('~S~pooler...', 'Alt+>', kbAltGreat, cmSpooler, hcSSpooler,
    NewItem('Diale~r~...', 'Alt+?', kbAltQuest, cmDialer, hcSDialer,
    NewLine(
    NewItem('ASCII ~t~able', 'Alt+T', kbAltT, cmASCIITable, hcSASCIITable,
    NewItem('Ca~l~culator', 'Alt+L', kbAltL, cmCalculator, hcSCalculator,
    NewItem('~C~alendar', 'Alt+C', kbAltC, cmCalendar, hcSCalendar,
    NewItem('CD ~P~layer', 'Ctrl+F11', kbCtrlF11, cmCDPlayer, hcSCDPlayer,
    Next))))))))))))))))))));
end;

function FileMenuItems(Next: PMenuItem): PMenuItem;
begin
  FileMenuItems :=
    NewItem('~O~pen...', 'F3', kbF3, cmOpenASCII, hcFOpen,
    NewItem('~N~ew', '', kbNoKey, cmNewASCII, hcFNew,
    NewItem('Open ~H~ex...', 'Ctrl+F3', kbCtrlF3, cmOpenHex, hcFOpenHex,
    NewItem('N~e~w Hex', '', kbNoKey, cmNewHex, hcFNewHex,
    NewItem('~S~ave', 'F2', kbF2, cmSave, hcFSave,
    NewItem('Save ~a~s...', '', kbNoKey, cmSaveAs, hcFSaveAs,
    NewItem('Save a~l~l', '', kbNoKey, cmSaveAll, hcFSaveAll,
    NewLine(
    NewItem('~P~rint', '' {'F12'}, kbNoKey {kbF12}, cmPrint, hcFPrint,
    NewItem('~C~hange dir...', 'Alt+\', kbAltPipe, cmChangeDirectory, hcFChangeDir,
    NewItem('~D~OS shell', 'Alt+Q', kbAltQ, cmDosShell, hcFDosShell,
    NewItem('E~x~it', 'Alt+X', kbAltX, cmQuit, hcFExit,
    Next))))))))))));
end;

function EditMenuItems(Next: PMenuItem): PMenuItem;
begin
  EditMenuItems :=
    NewItem('~U~ndo', 'Alt+Back', kbAltBack, cmUndo, hcEUndo,
    NewItem('~R~edo', 'Ctrl+Enter', kbCtrlEnter, cmRedo, hcERedo,
    NewLine(
    NewItem('Cu~t~', 'Shift+Del', kbShiftDel, cmCut, hcECut,
    NewItem('~C~opy', 'Ctrl+Ins', kbCtrlIns, cmCopy, hcECopy,
    NewItem('~P~aste', 'Shift+Ins', kbShiftIns, cmPaste, hcEPaste,
    NewItem('C~l~ear', 'Ctrl+Del', kbCtrlDel, cmClear, hcEClear,
    NewItem('Cop~y~ to additional Clipboard', 'Ctrl+F12', kbCtrlF12,
      cmCopyToMT, hcECopyToAddClip,
    NewItem('Paste fr~o~m additional Clipboard', 'Shift+F12', kbShiftF12,
      cmPasteFromMT, hcEPasteFromAddClip,
    NewItem('~S~how Clipboard', 'Alt+Ins', kbAltIns, cmShowClipboard,
      hcEShowClipboard,
    NewLine(
    NewItem('Sa~v~e Clipboard data on exit', ' No', kbNoKey, cmSaveClipData,
      hcESaveClipData,
    NewLine(
    NewItem('Mar~k~ columns of text  Alt+K', ' No', kbAltK, cmToggleMarkMode,
      hcEToggleMarkMode,
    Next))))))))))))));
end;

function SearchMenuItems(Next: PMenuItem): PMenuItem;
begin
  SearchMenuItems :=
    NewItem('~F~ind...', '', kbNoKey, cmFind, hcSHFind,
    NewItem('~R~eplace...', '', kbNoKey, cmReplace, hcSHReplace,
    NewItem('Find ~a~ll...', '', kbNoKey, cmFindAll, hcSHFindAll,
    NewItem('S~h~ow all found...', '', kbNoKey, cmShowAllFound,
      hcSHShowAllFound,
    NewItem('~S~earch again', '', kbNoKey, cmSearchAgain, hcSHSearchAgain,
    NewItem('~I~ncremental search', '', kbNoKey, cmIncSearch, hcSHIncSearch,
    NewItem('~G~o to line number...', 'Alt+G', kbAltG, cmGoToLine,
      hcSHGoToLineNumber,
    NewLine(
    NewItem('~M~ultiple search...', '', kbNoKey, cmMultiSearch, hcSHMultiSearch,
    Next)))))))));
end;

function RunMenuItems(Next: PMenuItem): PMenuItem;
begin
  RunMenuItems :=
    NewItem('~C~ompile', 'Shift+F9', kbShiftF9, cmCompile, hcRCompile,
    NewItem('~R~un', 'Ctrl+F9', kbCtrlF9, cmRun, hcRRun,
    NewItem('~P~rogram reset', 'Ctrl+F2', kbCtrlF2, cmProgramReset,
      hcRProgramReset,
    NewItem('~G~o to cursor', 'F4', kbF4, cmGoToCursor, hcRGoToCursor,
    NewItem('~T~race into', 'F7', kbF7, cmTraceInto, hcRTraceInto,
    NewItem('~S~tep over', 'F8', kbF8, cmStepOver, hcRStepOver,
    NewItem('~A~nimate tracing', '', kbNoKey, cmAnimateTracing,
      hcRAnimateTracing,
    NewItem('Ani~m~ate stepping', '', kbNoKey, cmAnimateStepping,
      hcRAnimateStepping,
    NewLine(
    NewItem('~O~pen CPU window', ' No', kbNoKey, cmOpenCPUWindow,
      hcROpenCPUWindow,
    Next))))))))));
end;

function DebugMenuItems(Next: PMenuItem): PMenuItem;
begin
  DebugMenuItems :=
    NewItem('~M~odify...', 'Ctrl+F4', kbCtrlF4, cmModify, hcDModify,
    NewLine(
    NewItem('~A~dd watch...', 'Ctrl+F7', kbCtrlF7, cmAddWatch, hcDAddWatch,
    NewItem('~E~dit watch...', '', kbNoKey, cmEditWatch, hcDEditWatch,
    NewItem('~D~elete watch', '', kbNoKey, cmDeleteWatch, hcDDeleteWatch,
    NewItem('~C~lear watches', '', kbNoKey, cmClearWatches, hcDClearWatches,
    NewLine(
    NewItem('~T~oggle breakpoint', 'Ctrl+F8', kbCtrlF8, cmToggleBreakPoint,
      hcDToggleBreakpoint,
    NewItem('C~l~ear breakpoints', '', kbNoKey, cmClearBreakPoints,
      hcDClearBreakpoints,
    NewLine(
    NewItem('Clea~r~ output', '', kbNoKey, cmClearOutput, hcDClearOutput,
    NewLine(
    NewItem('Regular e~x~pression debugger...', '', kbNoKey, cmRegExpDlg,
      hcRegExpDlg,
    Next)))))))))))));
end;

function WindowMenuItems(Next: PMenuItem): PMenuItem;
begin
  WindowMenuItems :=
    NewItem('Reload as ~A~SCII', 'Alt+A', kbAltA, cmUpdateASCII,
      hcWUpdateASCII,
    NewItem('Reload as ~H~ex', 'Alt+H', kbAltH, cmUpdateHex, hcWUpdateHex,
    NewLine(
    NewItem('~R~esize/move', 'Ctrl+F5', kbCtrlF5, cmResize, hcWResize,
    NewItem('~Z~oom', 'F5', kbF5, cmZoom, hcWZoom,
    NewItem('~N~ext', 'F6', kbF6, cmNext, hcWNext,
    NewItem('~P~revious', 'Shift+F6', kbShiftF6, cmPrev, hcWPrevious,
    NewItem('~C~lose', 'Alt+F3', kbAltF3, cmClose, hcWClose,
    NewItem('T~i~le', '', kbNoKey, cmTile, hcWTile,
    NewItem('Cascad~e~', '', kbNoKey, cmCascade, hcWCascade,
    NewLine(
    NewItem('~W~atch', '', kbNoKey, cmWatch, hcWWatch,
    NewItem('~O~utput', '', kbNoKey, cmOutput, hcWOutput,
    NewItem('~M~essage', 'Alt+Home', kbAltHome, cmMessage, hcWMessage,
    NewItem('~T~erminal', 'Alt+End', kbAltEnd, cmTerminal, hcWTerminal,
    NewItem('~B~ack', '', kbNoKey, cmBack, hcWBack,
    NewItem('~U~ser screen', 'Alt+F5', kbAltF5, cmUserScreen, hcWUserScreen,
    NewLine(
    NewItem('~L~ist...', 'Alt+0', kbAlt0, cmList, hcWList,
    Next)))))))))))))))))));
end;

function OptionsMenuItems(Next: PMenuItem): PMenuItem;
begin
  OptionsMenuItems :=
    NewItem('Commu~n~ication...', '', kbNoKey, cmMode, hcOMode,
    NewItem('~K~eyboard...', '', kbNoKey, cmKeyboard, hcOKeyboard,
    NewItem('~M~ouse...', '', kbNoKey, cmMouse, hcOMouse,
    NewItem('~C~ursor...', '', kbNoKey, cmCursor, hcOCursor,
    NewItem('C~o~lors...', '', kbNoKey, cmColors, hcOColors,
    NewItem('Countr~y~...', '', kbNoKey, cmCountry, hcOCountry,
    NewItem('Ed~i~tor...', '', kbNoKey, cmEditOptions, hcOEditOptions,
    NewItem('~F~ile Manager...', '', kbNoKey, cmFMOptions, hcOFMOptions,
    NewItem('User ~p~rograms...', '', kbNoKey, cmUserOptions, hcOUserOptions,
    NewItem('O~v~erlay...', '', kbNoKey, cmOverlay, hcOvrOptions,
    NewItem('~L~og file...', '', kbNoKey, cmLogFile, hcOLog,
    NewItem('Prin~t~er...', '', kbNoKey, cmPrinterSetup, hcOPrinter,
    NewItem('C~D~ Player...', '', kbNoKey, cmCDOptions, hcOCDOptions,
    NewItem('Set~u~p...', '', kbNoKey, cmSetup, hcOSetup,
    NewItem('Confirm~a~tions...', '', kbNoKey, cmConfirmations, hcOConfirmations,
    NewItem('~W~indow settings...', '', kbNoKey, cmToggleExplode,
      hcOExplode,
    NewItem('~E~GA/VGA lines  Alt+F6', ' No', kbNoKey, cmToggleEGALines,
      hcOEGALines,
    NewLine(
    NewItem('~S~ave options...', '', kbNoKey, cmSaveOptions, hcOSaveOptions,
    NewItem('~R~etrieve options...', '', kbNoKey, cmRetrieveOptions,
      hcORetrieveOptions,
    Next))))))))))))))))))));
end;

function UserMenuItems(Next: PMenuItem): PMenuItem;
begin
  UserMenuItems :=
    NewItem('~E~xecute macro', 'Alt+F8', kbAltF8, cmMacro, hcUMacro,
    NewItem('~R~ecord macro', 'Alt+Equal', kbAltEqual, cmRecordMacro,
      hcURecordMacro,
    NewItem('~S~top recording', 'Alt+Minus', kbAltMinus, cmStopRecording,
      hcUStopRecording,
    NewItem('~M~acro list...', 'Alt+PgUp', kbAltPgUp, cmUserMacros, hcUUserMacros,
    NewLine(
    NewItem('E~x~ecute program', 'Alt+F9', kbAltF9, cmExecute, hcUExecute,
    NewItem('~P~rogram list...', 'F9', kbF9, cmUserPrograms, hcUUserPrograms,
    NewLine(
    NewItem('~L~oad icon...', '', kbNoKey, cmLoadIcon, hcULoadIcon,
    NewLine(
    NewItem('P~h~one book...', 'Alt+PgDn', kbAltPgDn, cmPhoneBook, hcUPhoneBook,
    NewLine(
    NewItem('~D~ecoders...', 'Ctrl+F6', kbCtrlF6, cmDecoders, hcUDecoders,
    NewLine(
    NewItem('~F~ile Manager', 'Ctrl+F10', kbCtrlF10, cmFileManager,
      hcFileManager,
    Next)))))))))))))));
end;

function HelpMenuItems(Next: PMenuItem): PMenuItem;
begin
  HelpMenuItems :=
    NewItem('~H~elp', 'F1', kbF1, cmHelp, hcHHelp,
    NewItem('~C~ontents', 'Shift+F1', kbShiftF1, cmContents, hcHContents,
    NewItem('~T~opic search', 'Ctrl+F1', kbCtrlF1, cmTopicSearch,
      hcHTopicSearch,
    NewItem('~P~revious topic', 'Alt+F1', kbAltF1, cmPreviousTopic,
      hcHPreviousTopic,
    NewLine(
    NewItem('Help ~f~ile...', '', kbNoKey, cmAltHelpName, hcAltHelpName,
    Next))))));
end;

begin
  Application^.GetExtent(R);
  R.B.X := R.A.X + 132;
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PRMenuBar, Init(R, NewMenu(
{    NewSubMenu('~'#240'~', hcSystem, NewMenu( } {Fixed 04.01.08 to replace menu char }
    NewSubMenu('~'#4'~', hcSystem, NewMenu(
      SystemMenuItems(nil)),
    NewSubMenu('~F~ile', hcFile, NewMenu(
      FileMenuItems(nil)),
    NewSubMenu('~E~dit', hcEdit, NewMenu(
      EditMenuItems(nil)),
    NewSubMenu('~S~earch', hcSearch, NewMenu(
      SearchMenuItems(nil)),
    NewSubMenu('~R~un', hcRun, NewMenu(
      RunMenuItems(nil)),
    NewSubMenu('~D~ebug', hcDebug, NewMenu(
      DebugMenuItems(nil)),
    NewSubMenu('~W~indow', hcWindow, NewMenu(
      WindowMenuItems(nil)),
    NewSubMenu('~O~ptions', hcOptions, NewMenu(
      OptionsMenuItems(nil)),
    NewSubMenu('~U~ser', hcUser, NewMenu(
      UserMenuItems(nil)),
    NewSubMenu('Hel~p~', hcMenuHelp, NewMenu(
      HelpMenuItems(nil)),
  nil)))))))))))));
  RSR^.Put(MenuBar, 'MENUBAR');
  Dispose(MenuBar, Done);
end;

procedure RegisterRMenus;
begin
  RegisterType(RRStatusLine);
  RegisterType(RRMenuBar);
end;

end.