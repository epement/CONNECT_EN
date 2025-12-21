{$I-,X+,O+,F+}
unit Options;

interface

uses Objects, LFN;

const
  EditTitle = 'Editor options';
  EditorKeysTitle = 'Editor keys';
  FMKeysTitle = 'File Manager keys';
  FMFilesTitle = 'File Manager files';
  FMTitle = 'File Manager options';
  FMCopyTitle = 'File copy/rename options';
  UserProgTitle = 'User program options';
  LogTitle = 'Log file options';
  SetupTitle = 'Setup';
  PrinterSetupTitle = 'Printer setup';
  ModeTitle = 'Communication parameters';
  OvrTitle = 'Overlay options';
  ConfirmTitle = 'Confirmations';
  CDTitle = 'CD Player options';

procedure RetrieveOptions;
procedure SaveOptions;
function EditorOptions(const ATitle: String;
  var AEditOptions: Longint; var ANewEditOptions: Word;
  var ATabSize, AMaxLineWidth: Byte; AWordDelims: PCharSet;
  EnableGroups, Local: Boolean): Boolean;
procedure EditorKeys;
procedure FMFiles;
procedure FMKeys;
procedure FManagerOptions;
procedure FMCopyOptions;
procedure UserOptions;
procedure LogFileOptions;
procedure OvrOptions;
procedure PrinterSetup;
procedure Setup;
procedure Mode;
procedure Confirmations;
procedure CDOptions;

procedure RSREditOptionsDialog(RSR: PResourceFile);
procedure RSREditorKeysDialog(RSR: PResourceFile);
procedure RSRFMFilesDialog(RSR: PResourceFile);
procedure RSRFMKeysDialog(RSR: PResourceFile);
procedure RSRFMOptionsDialog(RSR: PResourceFile);
procedure RSRFMCopyOptionsDialog(RSR: PResourceFile);
procedure RSRUserOptionsDialog(RSR: PResourceFile);
procedure RSRLogOptionsDialog(RSR: PResourceFile);
procedure RSRPrinterDialog(RSR: PResourceFile);
procedure RSRSetupDialog(RSR: PResourceFile);
procedure RSROvrDialog(RSR: PResourceFile);
procedure RSRModeDialog(RSR: PResourceFile);
procedure RSRConfirmDialog(RSR: PResourceFile);
procedure RSRCDOptionsDialog(RSR: PResourceFile);
procedure ResNotFound(const AName: String);

implementation

uses Dos, Drivers, Views, Dialogs, Memory, StdDlg, App, MsgBox, HistList,
  Swaps, Desktops, EditMsg, DirPrim, MacroDlg, APPort, APCom, APMisc,
  UserScr, CNInputs, Compiler, Date, History, ConOvr, AsynPrim, LogFile,
  DevLayer, HideMain, DosCase, DosTools, TPString, Consts, Commands, Defaults;

const
  oeBackupFiles         = $00000001;
  oeInsertMode          = $00000002;
  oeAutoIndentMode      = $00000004;
  oeUseTabs             = $00000008;
  oeUseEMS              = $00000010;
  oePromptOnNew         = $00000020;
  oeChangeDirOnOpen     = $00000040;
  oeCascade             = $00000080;
  oeFindTextAtCursor    = $00000100;
  oeEnableUndo          = $00000200;
  oeEnableWrap          = $00000400;
  oeWordDivision        = $00000800;
  oeExpandLine          = $00001000;

  oeSyntax              = $00002000;
  oeHilitCurLine        = $00004000;
  oeHilitCurColumn      = $00008000;
  oeHilitPageBreak      = $00010000;
  oeHilitBounds         = $00020000;
  oeNonPersistent       = $00040000;
  oeOverwriteBlocks     = $00080000;
  oePasteGoesToEnd      = $00100000;
  oeTrailingBlanks      = $00200000;
  oeWrapLinesOnLoad     = $00400000;
  oeUnwrapLinesOnSave   = $00800000;
  oeWriteCRLF           = $01000000;
  oeWriteEOF            = $02000000;

  keLiteralInput        = $0001;
  keSmartTabs           = $0002;
  keInsertPairs         = $0004;
  keAutoSpaces          = $0008;
  keHomeToggles         = $0010;
  keEscCloses           = $0020;

  fkInsMovesDown = $01;
  fkBackGoesPrev = $02;
  fkEscTogglesPanels = $04;
  fkDelErasesFiles = $08;
  fkSpaceSelects = $10;
  fkDrvSelDifCtrl = $20;
  fkOpenFocused = $40;
  fkAltCtrlNames = $80;
  fkSpaceSizes = $100;
  fkSpaceMovesDown = $200;
  fkAltF3MovesDown = $400;
  fkCapsLockSearch = $800;
  fkXPanel = $1000;

  fdAutoChangeDir = 1;
  fdCopyLeft = 2;
  fdUnsel = 4;
  fdDragPrompt = 8;
  fdDirDelPrompt = $10;
  fdSameList = $20;
  fdCheckFreeSpace = $40;
  fdRereadUnselects = $80;
  fdDrawEmpty = $100;
  fdCopyDescriptions = $200;
  fdSaveSelection = $400;
  fdLoadCurDir = $800;
  fdAltTreeinfo = $1000;
  fdNoAutoUpdateTree = $2000;
  fdNoMaskDescriptions = $4000;
  fdResetUnfoldFlag = $8000;
  fdForceUpperDirs = $10000;

  suSaveEditorFiles = 1;
  suSaveEnvironment = 2;
  suSaveDesktop = 4;

  suCheckSnow = 1;
  suEnhancedPalette = 2;
  suRestoreVideoMode = 4;

  suReturnToDirAtStart = 1;
  suReturnToDirOnExit = 2;

  suDisableSysinfo = 1;
  suDisableVGAPalette = 2;
  suDisableSounds = 4;
  suLocalAssocs = 8;

  PatternSignature = $4E525450 {'PTRN'};

procedure ResNotFound(const AName: String);
begin
  ResourceNotFoundMsgBox(AName + ' dialog');
end;

procedure WriteDataToEXE(SeekPos, Signature: Longint;
  var Data; DataSize: Word);
var
  SaveTime, L: Longint;
  S: TDosStream;
  Name: FNameStr;
  F: Text;
begin
  Name := FExpand(ParamStr(0));
  if Name = '' then Exit;
  Assign(F, Name);
  Reset(F);
  if IOResult <> 0 then Exit;
  GetFTime(F, SaveTime);
  Close(F);
  S.Init(Name, stOpen);
  if S.Status <> stOk then Exit;
  S.Seek(SeekPos);
  S.Read(L, SizeOf(Longint));
  if L = Signature then S.Write(Data, DataSize);
  S.Done;
  Reset(F);
  if IOResult <> 0 then Exit;
  SetFTime(F, SaveTime);
  Close(F);
end;

procedure SetLFNOptions(AOptions: Word);
var
  SaveOpt: Byte;
  SaveAPI: lAPIType;
begin
  SaveAPI := lAPI;
  SaveOpt := LFNOptions;
  LFNOptions := AOptions;
  if LFNOptions and loEnableWIN95LFN <> 0 then
    SetLFNSupport(lWIN95, True)
  else
  begin
    lAPI := lDOS;
    fAPI := fDOS;
  end;
  if SaveAPI <> lAPI then
    Message(Application, evBroadcast, cmlAPIChanged, Pointer(SaveAPI))
  else if (SaveOpt and (loConvertNames + loShortNamesAsIs)) <>
    (LFNOptions and (loConvertNames + loShortNamesAsIs)) then
      Message(Desktop, evBroadcast, cmReRead, nil);
end;

function EditOptionsDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 67, 23);
  D := New(PDialog, Init(R, EditTitle));
  with D^ do
  begin
    HelpCtx := hcEditOptions;
    Options := Options or ofCentered;

    R.Assign(3, 2, 64, 15);
    Control := New(PMultiCheckBoxes, Init(R,
      NewSItem('~C~reate backup files',
      NewSItem('~I~nsert mode',
      NewSItem('~A~uto-indent mode',
      NewSItem('~U~se tab characters',
      NewSItem('Use e~x~panded memory',
      NewSItem('~P~rompt on new file',
      NewSItem('C~h~ange dir on open',
      NewSItem('Cascade ~n~ew window',
      NewSItem('~F~ind text at cursor',
      NewSItem('Enable Un~d~o/Redo',
      NewSItem('Enable text w~r~ap',
      NewSItem('Ena~b~le hyphenation  ',
      NewSItem('Expand wrapped ~l~ine',

      NewSItem('~S~yntax highlight',
      NewSItem('Hi~g~hlight current line',
      NewSItem('Highlight current c~o~lumn',
      NewSItem('Highligh~t~ page breaks',
      NewSItem('Highlight ~>~boundaries~<~',
      NewSItem('Non~-~persistent blocks',
      NewSItem('O~v~erwrite blocks',
      NewSItem('~P~aste goes to end of block',
      NewSItem('K~e~ep trailing blanks',
      NewSItem('Wrap lines on [Load~]~',
      NewSItem('Unwrap lines on ~[~Save]',
      NewSItem('Write CR~/~LF chars at the end',
      NewSItem('Write EOF char (~'#26'~) at the end',
        nil)))))))))))))))))))))))))), 2, cfOneBit, ' X'));
    Insert(Control);
    R.Assign(2, 1, Size.X - 3, 2);
    Insert(New(PLabel, Init(R, 'Editor settings', Control)));

    R.Assign(12, Size.Y - 7, 16, Size.Y - 6);
    Control := New(PCInputLine, Init(R, 2, 2, 16));
    Insert(Control);
    R.Assign(2, Size.Y - 7, 12, Size.Y - 6);
    Insert(New(PLabel, Init(R, 'Tab si~z~e', Control)));

    R.Assign(32, Size.Y - 7, 36, Size.Y - 6);
    Control := New(PCInputLine, Init(R, 2, 0, 30));
    Insert(Control);
    R.Assign(19, Size.Y - 7, 32, Size.Y - 6);
    Insert(New(PLabel, Init(R, 'Left margin', Control)));

    R.Assign(59, Size.Y - 7, 64, Size.Y - 6);
    Control := New(PCInputLine, Init(R, 3, 16, 255));
    Insert(Control);
    R.Assign(39, Size.Y - 7, 59, Size.Y - 6);
    Insert(New(PLabel, Init(R, '~M~aximum line width', Control)));

    R.Assign(19, Size.Y - 5, 61, Size.Y - 4);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, DelimsHistoryId);
    R.Assign(2, Size.Y - 5, 19, Size.Y - 4);
    Insert(New(PLabel, Init(R, '~W~ord delimiters', Control)));

    R.Assign(2, Size.Y - 3, 12, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(14, Size.Y - 3, 27, Size.Y - 1);
    Insert(New(PButton, Init(R, 'Groups~.~..', cmEditorGroups, bfNormal)));
    R.Assign(29, Size.Y - 3, 40, Size.Y - 1);
    Insert(New(PButton, Init(R, 'Ke~y~s...', cmEditorKeys, bfNormal)));
    R.Assign(42, Size.Y - 3, 52, Size.Y - 1);
    StandardCancelButton(R, D);
    R.Assign(54, Size.Y - 3, 64, Size.Y - 1);
    StandardHelpButton(R, D);

    SelectNext(False);
  end;
  EditOptionsDialog := PDialog(Application^.ValidView(D));
end;

procedure RSREditOptionsDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := EditOptionsDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'EDITDIALOG');
    Dispose(D, Done);
  end;
end;

procedure EditorOptionsToCheckData(
  AEditOptions: Longint; ANewEditOptions: Word;
  var L: Longint);
begin
  L := 0;
  if AEditOptions and eoBackupFiles <> 0 then
    L := L or oeBackupFiles;
  if AEditOptions and eoInsertMode <> 0 then
    L := L or oeInsertMode;
  if AEditOptions and eoAutoIndentMode <> 0 then
    L := L or oeAutoIndentMode;
  if AEditOptions and eoUseTabs <> 0 then
    L := L or oeUseTabs;
  if AEditOptions and eoUseEMS <> 0 then
    L := L or oeUseEMS;
  if AEditOptions and eoPromptOnNew <> 0 then
    L := L or oePromptOnNew;
  if AEditOptions and eoChangeDirOnOpen <> 0 then
    L := L or oeChangeDirOnOpen;
  if AEditOptions and eoCascade <> 0 then
    L := L or oeCascade;
  if AEditOptions and eoFindTextAtCursor <> 0 then
    L := L or oeFindTextAtCursor;
  if AEditOptions and eoEnableUndo <> 0 then
    L := L or oeEnableUndo;
  if AEditOptions and eoEnableWrap <> 0 then
    L := L or oeEnableWrap;
  if AEditOptions and eoWordDivision <> 0 then
    L := L or oeWordDivision;
  if AEditOptions and eoExpandLine <> 0 then
    L := L or oeExpandLine;

  if AEditOptions and eoSyntax <> 0 then
    L := L or oeSyntax;
  if AEditOptions and eoHilitCurLine <> 0 then
    L := L or oeHilitCurLine;
  if AEditOptions and eoHilitCurColumn <> 0 then
    L := L or oeHilitCurColumn;
  if AEditOptions and eoHilitPageBreak <> 0 then
    L := L or oeHilitPageBreak;
  if AEditOptions and eoHilitBounds <> 0 then
    L := L or oeHilitBounds;
  if AEditOptions and eoNonPersistent <> 0 then
    L := L or oeNonPersistent;
  if AEditOptions and eoOverwriteBlocks <> 0 then
    L := L or oeOverwriteBlocks;
  if ANewEditOptions and neoPasteGoesToEnd <> 0 then
    L := L or oePasteGoesToEnd;
  if ANewEditOptions and neoTrailingBlanks <> 0 then
    L := L or oeTrailingBlanks;
  if AEditOptions and eoWrapLinesOnLoad <> 0 then
    L := L or oeWrapLinesOnLoad;
  if AEditOptions and eoUnwrapLinesOnSave <> 0 then
    L := L or oeUnwrapLinesOnSave;
  if ANewEditOptions and neoWriteCRLF <> 0 then
    L := L or oeWriteCRLF;
  if ANewEditOptions and neoWriteEOF <> 0 then
    L := L or oeWriteEOF;
end;

procedure CheckDataToEditorOptions(
  var AEditOptions: Longint; var ANewEditOptions: Word;
  L: Longint);
begin
  if L and oeBackupFiles <> 0 then
    AEditOptions := AEditOptions or eoBackupFiles
  else AEditOptions := AEditOptions and not eoBackupFiles;
  if L and oeInsertMode <> 0 then
    AEditOptions := AEditOptions or eoInsertMode
  else AEditOptions := AEditOptions and not eoInsertMode;
  if L and oeAutoIndentMode <> 0 then
    AEditOptions := AEditOptions or eoAutoIndentMode
  else AEditOptions := AEditOptions and not eoAutoIndentMode;
  if L and oeUseTabs <> 0 then
    AEditOptions := AEditOptions or eoUseTabs
  else AEditOptions := AEditOptions and not eoUseTabs;
  if L and oeUseEMS <> 0 then
    AEditOptions := AEditOptions or eoUseEMS
  else AEditOptions := AEditOptions and not eoUseEMS;
  if L and oePromptOnNew <> 0 then
    AEditOptions := AEditOptions or eoPromptOnNew
  else AEditOptions := AEditOptions and not eoPromptOnNew;
  if L and oeChangeDirOnOpen <> 0 then
    AEditOptions := AEditOptions or eoChangeDirOnOpen
  else AEditOptions := AEditOptions and not eoChangeDirOnOpen;
  if L and oeCascade <> 0 then
    AEditOptions := AEditOptions or eoCascade
  else AEditOptions := AEditOptions and not eoCascade;
  if L and oeFindTextAtCursor <> 0 then
    AEditOptions := AEditOptions or eoFindTextAtCursor
  else AEditOptions := AEditOptions and not eoFindTextAtCursor;
  if L and oeEnableUndo <> 0 then
    AEditOptions := AEditOptions or eoEnableUndo
  else AEditOptions := AEditOptions and not eoEnableUndo;
  if L and oeEnableWrap <> 0 then
    AEditOptions := AEditOptions or eoEnableWrap
  else AEditOptions := AEditOptions and not eoEnableWrap;
  if L and oeWordDivision <> 0 then
    AEditOptions := AEditOptions or eoWordDivision
  else AEditOptions := AEditOptions and not eoWordDivision;
  if L and oeExpandLine <> 0 then
    AEditOptions := AEditOptions or eoExpandLine
  else AEditOptions := AEditOptions and not eoExpandLine;

  if L and oeSyntax <> 0 then
    AEditOptions := AEditOptions or eoSyntax
  else AEditOptions := AEditOptions and not eoSyntax;
  if L and oeHilitCurLine <> 0 then
    AEditOptions := AEditOptions or eoHilitCurLine
  else AEditOptions := AEditOptions and not eoHilitCurLine;
  if L and oeHilitCurColumn <> 0 then
    AEditOptions := AEditOptions or eoHilitCurColumn
  else AEditOptions := AEditOptions and not eoHilitCurColumn;
  if L and oeHilitPageBreak <> 0 then
    AEditOptions := AEditOptions or eoHilitPageBreak
  else AEditOptions := AEditOptions and not eoHilitPageBreak;
  if L and oeHilitBounds <> 0 then
    AEditOptions := AEditOptions or eoHilitBounds
  else AEditOptions := AEditOptions and not eoHilitBounds;
  if L and oeNonPersistent <> 0 then
    AEditOptions := AEditOptions or eoNonPersistent
  else AEditOptions := AEditOptions and not eoNonPersistent;
  if L and oeOverwriteBlocks <> 0 then
    AEditOptions := AEditOptions or eoOverwriteBlocks
  else AEditOptions := AEditOptions and not eoOverwriteBlocks;
  if L and oePasteGoesToEnd <> 0 then
    ANewEditOptions := ANewEditOptions or neoPasteGoesToEnd
  else ANewEditOptions := ANewEditOptions and not neoPasteGoesToEnd;
  if L and oeTrailingBlanks <> 0 then
    ANewEditOptions := ANewEditOptions or neoTrailingBlanks
  else ANewEditOptions := ANewEditOptions and not neoTrailingBlanks;
  if L and oeWrapLinesOnLoad <> 0 then
    AEditOptions := AEditOptions or eoWrapLinesOnLoad
  else AEditOptions := AEditOptions and not eoWrapLinesOnLoad;
  if L and oeUnwrapLinesOnSave <> 0 then
    AEditOptions := AEditOptions or eoUnwrapLinesOnSave
  else AEditOptions := AEditOptions and not eoUnwrapLinesOnSave;
  if L and oeWriteCRLF <> 0 then
    ANewEditOptions := ANewEditOptions or neoWriteCRLF
  else ANewEditOptions := ANewEditOptions and not neoWriteCRLF;
  if L and oeWriteEOF <> 0 then
    ANewEditOptions := ANewEditOptions or neoWriteEOF
  else ANewEditOptions := ANewEditOptions and not neoWriteEOF;
end;

procedure EditorKeysToCheckData(
  AEditOptions: Longint; ANewEditOptions: Word;
  var W: Word);
begin
  W := 0;
  if AEditOptions and eoLiteralInput <> 0 then
    W := W or keLiteralInput;
  if ANewEditOptions and neoSmartTabs <> 0 then
    W := W or keSmartTabs;
  if AEditOptions and eoInsertPairs <> 0 then
    W := W or keInsertPairs;
  if AEditOptions and eoAutoSpaces <> 0 then
    W := W or keAutoSpaces;
  if ANewEditOptions and neoHomeToggles <> 0 then
    W := W or keHomeToggles;
  if AEditOptions and eoEscCloses <> 0 then
    W := W or keEscCloses;
end;

procedure CheckDataToEditorKeys(
  var AEditOptions: Longint; var ANewEditOptions: Word;
  W: Word);
begin
  if W and keLiteralInput <> 0 then
    AEditOptions := AEditOptions or eoLiteralInput
  else AEditOptions := AEditOptions and not eoLiteralInput;
  if W and keSmartTabs <> 0 then
    ANewEditOptions := ANewEditOptions or neoSmartTabs
  else ANewEditOptions := ANewEditOptions and not neoSmartTabs;
  if W and keInsertPairs <> 0 then
    AEditOptions := AEditOptions or eoInsertPairs
  else AEditOptions := AEditOptions and not eoInsertPairs;
  if W and keAutoSpaces <> 0 then
    AEditOptions := AEditOptions or eoAutoSpaces
  else AEditOptions := AEditOptions and not eoAutoSpaces;
  if W and keHomeToggles <> 0 then
    ANewEditOptions := ANewEditOptions or neoHomeToggles
  else ANewEditOptions := ANewEditOptions and not neoHomeToggles;
  if W and keEscCloses <> 0 then
    AEditOptions := AEditOptions or eoEscCloses
  else AEditOptions := AEditOptions and not eoEscCloses;
end;

function EditorKeysDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 67, 23);
  D := New(PDialog, Init(R, EditorKeysTitle));
  with D^ do
  begin
    HelpCtx := hcEditorKeysDialog;
    Options := Options or ofCentered;

    R.Assign(3, 3, Size.X - 3, 9);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Literal ke~y~ input',
      NewSItem('Enable s~m~art tab cursor movement',
      NewSItem('Add matching characters ~()~',
      NewSItem('Auto-spaces after ~,~.:;!?',
      NewSItem('~H~ome goes to first non-blank character',
      NewSItem('Esc cl~o~ses', nil))))))));
    Insert(Control);
    R.Assign(2, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(R, 'Editor key options', Control)));

    R.Assign(3, 11, Size.X - 3, 17);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Ctrl+~A~ - Select all',
      NewSItem('Ctrl+~C~ - Copy',
      NewSItem('Ctrl+~D~ - Not assigned',
      NewSItem('Ctrl+~E~ - Incremental search',
      NewSItem('Ctrl+~F~ - Find',
      NewSItem('Ctrl+~R~ - Replace',
      NewSItem('Ctrl+~S~ - Save',
      NewSItem('Ctrl+~V~ - Paste',
      NewSItem('Ctrl+~W~ - Not assigned',
      NewSItem('Ctrl+~X~ - Cut',
      NewSItem('Ctrl+~Z~ - Undo',
      NewSItem('A~l~l', nil))))))))))))));
    Insert(Control);
    R.Assign(2, 10, Size.X - 3, 11);
    Insert(New(PLabel, Init(R,
      'Convert old-style cursor movement keystrokes to commands', Control)));

    R.Assign(3, 18, Size.X - 3, 19);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Convert Ctrl+Home/End to Ctrl+~P~gUp/PgDn and vice versa',
        nil)));
    Insert(Control);

    StandardButtonRow(D, True);
  end;
  EditorKeysDialog := PDialog(Application^.ValidView(D));
end;

procedure RSREditorKeysDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := EditorKeysDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'EDITORKEYSDIALOG');
    Dispose(D, Done);
  end;
end;

const
  EditOptionsPtr: ^Longint = nil;
  NewEditOptionsPtr: ^Word = nil;
  WS_KEYS: Word = 0;

procedure EditorKeysProc(V: PView; var Event: TEvent);

function IsWSCheckBox(P: PView): Boolean; far;
begin
  IsWSCheckBox := (TypeOf(P^) = TypeOf(TCheckBoxes)) and
    (P^.Origin.Y = 11);
end;

var
  P: PCheckBoxes;
begin
  P := PCheckBoxes(PDialog(V)^.FirstThat(@IsWSCheckBox));
  if (P <> nil) and (P^.Value <> WS_KEYS) then
  begin
    if (P^.Value and ws0 <> 0) <> (WS_KEYS and ws0 <> 0) then
      if P^.Value and ws0 <> 0 then P^.Value := wsAll + ws0
      else P^.Value := 0
    else if P^.Value and not ws0 = wsAll then
      P^.Value := P^.Value or ws0
    else P^.Value := P^.Value and not ws0;
    P^.DrawView;
    WS_KEYS := P^.Value;
  end;
end;

procedure EditorKeys;
type
  TData = record
    Opt: Word;
    WS: Word;
    PS: Word;
  end;
var
  D: PDialog;
  Data: TData;
begin
  D := PDialog(Resource^.Get('EDITORKEYSDIALOG'));
  if D = nil then
  begin
    ResNotFound(EditorKeysTitle);
    Exit;
  end;
  D^.PostProcessEvent := EditorKeysProc;
  EditorKeysToCheckData(EditOptionsPtr^, NewEditOptionsPtr^, Data.Opt);
  WS_KEYS := WordStarKeys and not ws1;
  if WS_KEYS >= wsAll then WS_KEYS := WS_KEYS or ws0;
  Data.WS := WS_KEYS;
  if WordStarKeys and ws1 <> 0 then Data.PS := 1 else Data.PS := 0;
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    CheckDataToEditorKeys(EditOptionsPtr^, NewEditOptionsPtr^, Data.Opt);
    WordStarKeys := Data.WS and not ws0;
    if Data.PS and 1 <> 0 then WordStarKeys := WordStarKeys or ws1;
  end;
end;

function EditorOptions(const ATitle: String;
  var AEditOptions: Longint; var ANewEditOptions: Word;
  var ATabSize, AMaxLineWidth: Byte; AWordDelims: PCharSet;
  EnableGroups, Local: Boolean): Boolean;
type
  TDialogData = record
    EditOptions: Longint;
    TabSize: String[2];
    LeftMargin: String[2];
    LineWidth: String[3];
    Delims: String[255];
  end;
var
  Code: Integer;
  N: Longint;
  D: PDialog;
  AData: TDialogData;
begin
  EditorOptions := False;
  D := PDialog(Resource^.Get('EDITDIALOG'));
  if D = nil then
  begin
    ResNotFound(EditTitle);
    Exit;
  end;
  if ATitle <> '' then
  begin
    DisposeStr(D^.Title);
    D^.Title := NewStr(EditTitle + ' ' + ATitle);
  end;
  EditOptionsPtr := @AEditOptions;
  NewEditOptionsPtr := @ANewEditOptions;
  if EnableGroups then
    Application^.EnableCommands(EditorGroupCommands)
  else
  begin
    Application^.DisableCommands(EditorGroupCommands);
    if (D^.Current <> nil) and
       (TypeOf(D^.Current^) = TypeOf(TMultiCheckBoxes)) then
      PCluster(D^.Current)^.SetButtonState(oeUseEMS + oeCascade, False);
  end;
  EditorOptionsToCheckData(AEditOptions, ANewEditOptions,
    AData.EditOptions);
  Str(ATabSize, AData.TabSize);
  N := (AEditOptions and not EditOptMask) shr 26;
  if N = 0 then AData.LeftMargin := 'No'
  else Str(N, AData.LeftMargin);
  Str(AMaxLineWidth, AData.LineWidth);
  CharSetToStr(AWordDelims^, AData.Delims);
  if Application^.ExecuteDialog(D, @AData, False) <> cmCancel then
  begin
    CheckDataToEditorOptions(AEditOptions, ANewEditOptions,
      AData.EditOptions);
    Val(AData.TabSize, ATabSize, Code);
    Val(AData.LeftMargin, N, Code);
    AEditOptions := (AEditOptions and EditOptMask) or (N shl 26);
    Val(AData.LineWidth, AMaxLineWidth, Code);
    if AData.Delims = '' then
      if EnableGroups then AWordDelims^ := DefWordDelims
      else AWordDelims^ := []
    else StrToCharSet(CharSet(AWordDelims^), AData.Delims);
    if not Local then Message(Desktop, evBroadcast, cmEditOptions, nil);
    EditorOptions := True;
  end;
end;

function GetFMKeyOptions: Word;
var
  W: Word;
begin
  W := 0;
  if FMOptions and foInsMovesDown <> 0 then
    W := W or fkInsMovesDown;
  if FMOptions and foBackGoesPrev <> 0 then
    W := W or fkBackGoesPrev;
  if FMOptions and foEscTogglesPanels <> 0 then
    W := W or fkEscTogglesPanels;
  if FMOptions and foDelErasesFiles <> 0 then
    W := W or fkDelErasesFiles;
  if FMOptions and foSpaceSelects <> 0 then
    W := W or fkSpaceSelects;
  if FMOptions and foDrvSelDifCtrl <> 0 then
    W := W or fkDrvSelDifCtrl;
  if FMOptions and foOpenFocused <> 0 then
    W := W or fkOpenFocused;
  if FMOptions and foAltCtrlNames <> 0 then
    W := W or fkAltCtrlNames;
  if FMOptions and foSpaceSizes <> 0 then
    W := W or fkSpaceSizes;
  if FMOptions and foSpaceMovesDown <> 0 then
    W := W or fkSpaceMovesDown;
  if FMOptions and foAltF3MovesDown <> 0 then
    W := W or fkAltF3MovesDown;
  if FMOptions and foCapsLockSearch <> 0 then
    W := W or fkCapsLockSearch;
  if FMOptions and foXPanel <> 0 then
    W := W or fkXPanel;
  GetFMKeyOptions := W;
end;

procedure SetFMKeyOptions(W: Word);
begin
  FMOptions := FMOptions and not
    (foInsMovesDown + foBackGoesPrev + foEscTogglesPanels +
     foDelErasesFiles + foSpaceSelects + foDrvSelDifCtrl +
     foOpenFocused + foAltCtrlNames + foSpaceSizes +
     foSpaceMovesDown + foAltF3MovesDown + foCapsLockSearch +
     foXPanel);
  if W and fkInsMovesDown <> 0 then
    FMOptions := FMOptions or foInsMovesDown;
  if W and fkBackGoesPrev <> 0 then
    FMOptions := FMOptions or foBackGoesPrev;
  if W and fkEscTogglesPanels <> 0 then
    FMOptions := FMOptions or foEscTogglesPanels;
  if W and fkDelErasesFiles <> 0 then
    FMOptions := FMOptions or foDelErasesFiles;
  if W and fkSpaceSelects <> 0 then
    FMOptions := FMOptions or foSpaceSelects;
  if W and fkDrvSelDifCtrl <> 0 then
    FMOptions := FMOptions or foDrvSelDifCtrl;
  if W and fkOpenFocused <> 0 then
    FMOptions := FMOptions or foOpenFocused;
  if W and fkAltCtrlNames <> 0 then
    FMOptions := FMOptions or foAltCtrlNames;
  if W and fkSpaceSizes <> 0 then
    FMOptions := FMOptions or foSpaceSizes;
  if W and fkSpaceMovesDown <> 0 then
    FMOptions := FMOptions or foSpaceMovesDown;
  if W and fkAltF3MovesDown <> 0 then
    FMOptions := FMOptions or foAltF3MovesDown;
  if W and fkCapsLockSearch <> 0 then
    FMOptions := FMOptions or foCapsLockSearch;
  if W and fkXPanel <> 0 then
    FMOptions := FMOptions or foXPanel;
end;

function GetFMOptions: Longint;
var
  L: Longint;
begin
  L := 0;
  if FMOptions and foAutoChangeDir <> 0 then
    L := L or fdAutoChangeDir;
  if FMOptions and foCopyLeft <> 0 then
    L := L or fdCopyLeft;
  if FMOptions and foUnsel <> 0 then
    L := L or fdUnsel;
  if FMOptions and foDragPrompt <> 0 then
    L := L or fdDragPrompt;
  if FMOptions and foDirDelPrompt <> 0 then
    L := L or fdDirDelPrompt;
  if FMOptions and foSameList <> 0 then
    L := L or fdSameList;
  if FMOptions and foCheckFreeSpace <> 0 then
    L := L or fdCheckFreeSpace;
  if FMOptions and foRereadUnselects <> 0 then
    L := L or fdRereadUnselects;
  if FMOptions and foDrawEmpty <> 0 then
    L := L or fdDrawEmpty;
  if FMOptions and foCopyDescriptions <> 0 then
    L := L or fdCopyDescriptions;
  if FMOptions and foSaveSelection <> 0 then
    L := L or fdSaveSelection;
  if FMOptions and foLoadCurDir <> 0 then
    L := L or fdLoadCurDir;
  if FMOptions and foAltTreeinfo <> 0 then
    L := L or fdAltTreeinfo;
  if FMOptions and foNoAutoUpdateTree <> 0 then
    L := L or fdNoAutoUpdateTree;
  if FMOptions and foNoMaskDescriptions <> 0 then
    L := L or fdNoMaskDescriptions;
  if FMOptions and foResetUnfoldFlag <> 0 then
    L := L or fdResetUnfoldFlag;
  if FMOptions and foForceUpperDirs <> 0 then
    L := L or fdForceUpperDirs;
  GetFMOptions := L;
end;

procedure SetFMOptions(L: Longint);
begin
  FMOptions := FMOptions and not
    (foAutoChangeDir + foCopyLeft + foUnsel + foDragPrompt +
     foDirDelPrompt + foSameList + foCheckFreeSpace +
     foRereadUnselects + foDrawEmpty + foCopyDescriptions +
     foSaveSelection + foLoadCurDir + foAltTreeinfo +
     foNoAutoUpdateTree + foNoMaskDescriptions +
     foResetUnfoldFlag + foForceUpperDirs);
  if L and fdAutoChangeDir <> 0 then
    FMOptions := FMOptions or foAutoChangeDir;
  if L and fdCopyLeft <> 0 then
    FMOptions := FMOptions or foCopyLeft;
  if L and fdUnsel <> 0 then
    FMOptions := FMOptions or foUnsel;
  if L and fdDragPrompt <> 0 then
    FMOptions := FMOptions or foDragPrompt;
  if L and fdDirDelPrompt <> 0 then
    FMOptions := FMOptions or foDirDelPrompt;
  if L and fdSameList <> 0 then
    FMOptions := FMOptions or foSameList;
  if L and fdCheckFreeSpace <> 0 then
    FMOptions := FMOptions or foCheckFreeSpace;
  if L and fdRereadUnselects <> 0 then
    FMOptions := FMOptions or foRereadUnselects;
  if L and fdDrawEmpty <> 0 then
    FMOptions := FMOptions or foDrawEmpty;
  if L and fdCopyDescriptions <> 0 then
    FMOptions := FMOptions or foCopyDescriptions;
  if L and fdSaveSelection <> 0 then
    FMOptions := FMOptions or foSaveSelection;
  if L and fdLoadCurDir <> 0 then
    FMOptions := FMOptions or foLoadCurDir;
  if L and fdAltTreeinfo <> 0 then
    FMOptions := FMOptions or foAltTreeinfo;
  if L and fdNoAutoUpdateTree <> 0 then
    FMOptions := FMOptions or foNoAutoUpdateTree;
  if L and fdNoMaskDescriptions <> 0 then
    FMOptions := FMOptions or foNoMaskDescriptions;
  if L and fdResetUnfoldFlag <> 0 then
    FMOptions := FMOptions or foResetUnfoldFlag;
  if L and fdForceUpperDirs <> 0 then
    FMOptions := FMOptions or foForceUpperDirs;
end;

function FMKeysDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 61, 21);
  D := New(PDialog, Init(R, FMKeysTitle));
  with D^ do
  begin
    HelpCtx := hcFMKeysDialog;
    Options := Options or ofCentered;

    R.Assign(3, 2, Size.X - 3, 15);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~I~ns moves down',
      NewSItem('~B~ackspace goes to upper directory',
      NewSItem('~E~sc toggles panels on/off',
      NewSItem('~D~el erases files and directories',
      NewSItem('~S~pace selects/unselects items',
      NewSItem('D~r~ive selectors sensitive to Left/Right Ctrl keys',
      NewSItem('F~4~/Ctrl+F4 opens focused file only',
      NewSItem('~A~lt+Ctrl displays names under mouse cursor',
      NewSItem('S~p~ace calculates selected directory size',
      NewSItem('Spa~c~e moves down',
      NewSItem('Alt+F~3~ on directory moves down',
      NewSItem('Caps~L~ock+character activates incremental search',
      NewSItem('E~x~tended status line (F9 - Menu, F10 - Exit)',
	nil)))))))))))))));
    Insert(Control);
    R.Assign(2, 1, Size.X - 3, 2);
    Insert(New(PLabel, Init(R, 'Panel key options', Control)));

    R.Assign(14, 16, Size.X - 17, 17);
    Control := New(PFInputLine, Init(R, 79));
    Insert(Control);
    StandardHistory(Control, MacroNameHistoryID);
    R.Assign(2, 16, 14, 17);
    Insert(New(PLabel, Init(R, '~M~acro file', Control)));

    R.Assign(Size.X - 14, 16, Size.X - 3, 18);
    Insert(New(PButton, Init(R, 'Open~.~..', cmUserMacros, bfNormal)));

    StandardButtonRow(D, True);
  end;
  FMKeysDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRFMKeysDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := FMKeysDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'FMKEYSDIALOG');
    Dispose(D, Done);
  end;
end;

procedure FMMacroProc(V: PView; var Event: TEvent);

function IsMacroInput(P: PView): Boolean; far;
begin
  IsMacroInput := (TypeOf(P^) = TypeOf(TFInputLine)) {and
    (P^.Origin.Y = 11)};
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

procedure FMKeys;
type
  TData = record
    Opt: Word;
    Name: String[79];
  end;
var
  D: PDialog;
  Data: TData;
begin
  D := PDialog(Resource^.Get('FMKEYSDIALOG'));
  if D = nil then
  begin
    ResNotFound(FMKeysTitle);
    Exit;
  end;
  D^.PostProcessEvent := FMMacroProc;
  Data.Opt := GetFMKeyOptions;
  Data.Name := FMMacroName;
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    SetFMKeyOptions(Data.Opt);
    if Data.Name <> FMMacroName then
    begin
      FMMacroName := StUpcase(Trim(Data.Name));
      Message(Desktop, evBroadcast, cmReloadMacroList, nil);
    end;
  end;
end;

function FMFilesDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 56, 14);
  D := New(PDialog, Init(R, FMFilesTitle));
  with D^ do
  begin
    HelpCtx := hcFMFilesDialog;
    Options := Options or ofCentered;

    R.Assign(21, 2, Size.X - 3, 3);
    Control := New(PInputLine, Init(R, 79));
    Insert(Control);
    R.Assign(2, 2, 21, 3);
    Insert(New(PLabel, Init(R, '`D~i~rinfo'' files', Control)));

    R.Assign(21, 4, Size.X - 3, 5);
    Control := New(PInputLine, Init(R, 79));
    Insert(Control);
    R.Assign(2, 4, 21, 5);
    Insert(New(PLabel, Init(R, '~D~escription files', Control)));

    R.Assign(49, 6, Size.X - 3, 7);
    Control := New(PCInputLine, Init(R, 2, 0, 32));
    Insert(Control);
    R.Assign(2, 6, 49, 7);
    Insert(New(PLabel, Init(R,
      '~W~hitespaces between file name and description', Control)));

    R.Assign(3, 9, Size.X - 3, 10);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~R~emove extra spaces from description text', nil)));
    Insert(Control);
    R.Assign(2, 8, Size.X - 3, 9);
    Insert(New(PLabel, Init(R, 'Copy description options', Control)));

    StandardButtonRow(D, True);
  end;
  FMFilesDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRFMFilesDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := FMFilesDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'FMFILESDIALOG');
    Dispose(D, Done);
  end;
end;

procedure FMFiles;
type
  TData = record
    DirinfoNames: String[79];
    BBSNames: String[79];
    Spaces: String[2];
    BBSOpt: Word;
  end;
var
  OtherName, OtherBBSOpt: Boolean;
  Code: Integer;
  D: PDialog;
  Data: TData;
begin
  D := PDialog(Resource^.Get('FMFILESDIALOG'));
  if D = nil then
  begin
    ResNotFound(FMFilesTitle);
    Exit;
  end;
  Data.DirinfoNames := DirinfoNames;
  Data.BBSNames := BBSNames;
  Str(BBSSpaces, Data.Spaces);
  Data.BBSOpt := BBSOptions;
  if Application^.ExecuteDialog(D, @Data, False) = cmCancel then Exit;
  TrimSt(Data.BBSNames);
  UpcaseSt(Data.BBSNames);
  TrimSt(Data.DirinfoNames);
  UpcaseSt(Data.DirinfoNames);
  OtherName := (BBSNames <> Data.BBSNames) or
    (DirinfoNames <> Data.DirinfoNames);
  DirinfoNames := Data.DirinfoNames;
  BBSNames := Data.BBSNames;
  Val(Data.Spaces, BBSSpaces, Code);
  OtherBBSOpt := BBSOptions <> Data.BBSOpt;
  BBSOptions := Data.BBSOpt;
  if OtherName then Message(Desktop, evBroadcast, cmReRead, nil)
  else if OtherBBSOpt then
    Message(Desktop, evBroadcast, cmBBSOptChanged, nil);
end;

function FMOptionsDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 76, 23);
  D := New(PDialog, Init(R, FMTitle));
  with D^ do
  begin
    HelpCtx := hcOFMOptions;
    Options := Options or ofCentered;

    R.Assign(3, 2, 44, Size.Y - 4);
    Control := New(PMultiCheckBoxes, Init(R,
      NewSItem('~A~uto change directory',
      NewSItem('~E~nable reverse Copy bar',
      NewSItem('~U~nselect processed files',
      NewSItem('~P~rompt on Drag-And-Drop',
      NewSItem('~C~onfirm erasing non-empty directory',
      NewSItem('~S~ame Find File list for both panels',
      NewSItem('Check free disk space ~b~efore Copy',
      NewSItem('~R~e-read unselects',
      NewSItem('Dra~w~ empty panel on re-reading',
      NewSItem('Copy~/~rename/delete descriptions',
      NewSItem('Save ~d~irectory selection',
      NewSItem('L~o~ad current directory',
      NewSItem('Enable TREEINFO.CN~x~',
      NewSItem('Disable TREEINFO auto~-~update',
      NewSItem('Disable mask descriptions ~(~MSK)',
      NewSItem('Clear the U~n~fold flag on dir change',
      NewSItem('Create d~i~rectories in uppercase',
        nil))))))))))))))))), 2, cfOneBit, ' X'));
    Insert(Control);
    R.Assign(2, 1, 44, 2);
    Insert(New(PLabel, Init(R, 'File Manager settings', Control)));

    R.Assign(46, 2, Size.X - 3, 6);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Case sensiti~v~e',
      NewSItem('I~g~nore cyrillic',
      NewSItem('Alt activates/aborts',
      NewSItem('Ctrl activates/aborts', nil))))));
    Insert(Control);
    R.Assign(45, 1, Size.X - 3, 2);
    Insert(New(PLabel, Init(R, 'Incremental search options', Control)));

    R.Assign(46, 7, Size.X - 3, 13);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Compare by si~z~e',
      NewSItem('Compare by ti~m~e',
      NewSItem('Compare by at~t~ribute',
      NewSItem('Select in bot~h~ panels',
      NewSItem('Unse~l~ect same files',
      NewSItem('Prompt on compare', nil))))))));
    Insert(Control);
    R.Assign(45, 6, Size.X - 3, 7);
    Insert(New(PLabel, Init(R, 'File compare options', Control)));

    R.Assign(Size.X - 8, 7, Size.X - 3, 9);
    Control := New(PMultiCheckBoxes, Init(R,
      NewSItem(' ', NewSItem(' ', nil)), 3, cfTwoBits, ' <>'));
    Insert(Control);

    R.Assign(46, 14, Size.X - 3, 17);
    Control := New(PRadioButtons, Init(R,
      NewSItem('Modified only',
      NewSItem('Always',
      NewSItem('Never', nil)))));
    Insert(Control);
    R.Assign(45, 13, Size.X - 3, 14);
    Insert(New(PLabel, Init(R, 'Panel auto re-read options', Control)));

    R.Assign(60, 17, 63, 18);
    Control := New(PInputLine, Init(R, 1));
    Control^.Options := Control^.Options and not ofFirstClick;
    Insert(Control);
    R.Assign(45, 17, 60, 18);
    Insert(New(PLabel, Init(R, 'Tag character', Control)));

    R.Assign(68, 18, Size.X - 3, 19);
    Control := New(PCInputLine, Init(R, 5, 0, 65535));
    Insert(Control);
    R.Assign(45, 18, 68, 19);
    Insert(New(PLabel, Init(R, 'Auto change delay~,~ ms', Control)));

    R.Assign(2, Size.Y - 3, 12, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(13, Size.Y - 3, 26, Size.Y - 1);
    Insert(New(PButton, Init(R, 'Groups~.~..', cmGroups, bfNormal)));
    R.Assign(27, Size.Y - 3, 39, Size.Y - 1);
    Insert(New(PButton, Init(R, '~F~iles...', cmFMFiles, bfNormal)));
    R.Assign(40, Size.Y - 3, 51, Size.Y - 1);
    Insert(New(PButton, Init(R, 'Ke~y~s...', cmFMKeys, bfNormal)));
    R.Assign(52, Size.Y - 3, 62, Size.Y - 1);
    StandardCancelButton(R, D);
    R.Assign(63, Size.Y - 3, 73, Size.Y - 1);
    StandardHelpButton(R, D);

    SelectNext(False);
  end;
  FMOptionsDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRFMOptionsDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := FMOptionsDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'FMDIALOG');
    Dispose(D, Done);
  end;
end;

procedure FManagerOptions;
type
  TData = record
    Opt: Longint;
    Srch: Word;
    Comp: Word;
    AdvComp: Longint;
    Rrd: Word;
    Tag: String[1];
    AutoDelay: String[5];
  end;
var
  Same: Boolean;
  SaveChar: Char;
  Code: Integer;
  D: PDialog;
  Data: TData;
begin
  D := PDialog(Resource^.Get('FMDIALOG'));
  if D = nil then ResNotFound(FMTitle)
  else
  begin
    Same := FMOptions and foSameList <> 0;
    Data.Opt := GetFMOptions;
    Data.Srch := FMSearchOptions;
    Data.Comp := CompareOptions;
    Data.AdvComp := CmpAdvOpt;
    Data.Rrd := FMAutoRereadOptions;
    Data.Tag := TagChar;
    Str(FMAutoDelay, Data.AutoDelay);
    if Application^.ExecuteDialog(D, @Data, False) = cmCancel then Exit;
    SetFMOptions(Data.Opt);
    SaveFMOptions := FMOptions;
    FMSearchOptions := Data.Srch;
    CompareOptions := Data.Comp;
    CmpAdvOpt := Data.AdvComp;
    FMAutoRereadOptions := Data.Rrd;
    SaveChar := TagChar;
    if Data.Tag = '' then TagChar := #0
    else TagChar := Data.Tag[1];
    Val(Data.AutoDelay, FMAutoDelay, Code);
    if SaveChar <> TagChar then
      Message(Desktop, evBroadcast, cmTagChar, nil);
    if (FMOptions and foSameList <> 0) <> Same then
      Message(Desktop, evBroadcast, cmFindFileDlg, nil);
  end;
end;

function FMCopyOptionsDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 80, 21);
  D := New(PDialog, Init(R, FMCopyTitle));
  with D^ do
  begin
    HelpCtx := hcFMCopyOptions;
    Options := Options or ofCentered;

    R.Assign(3, 2, Size.X - 3, 3);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~P~rompt',
      NewSItem('~O~verwrite all',
      NewSItem('~S~kip all',
      NewSItem('~C~ompare by time/size', nil))))));
    Insert(Control);
    R.Assign(2, 1, Size.X - 3, 2);
    Insert(New(PLabel, Init(R, 'File exists action', Control)));

    R.Assign(3, 5, Size.X - 3, 8);
    Control := New(PMultiCheckBoxes, Init(R,
      NewSItem('~N~ewer and longer',
      NewSItem('Newer and s~h~orter',
      NewSItem('Ne~w~er and same size',
      NewSItem('O~l~der and longer',
      NewSItem('Older and shor~t~er',
      NewSItem('Ol~d~er and same size',
      NewSItem('Sa~m~e time, longer',
      NewSItem('Same time, short~e~r',
      NewSItem('Same t~i~me and size',
	nil))))))))), 6, cfThreeBits, '?SNAOR'));
    Insert(Control);
    R.Assign(2, 4, Size.X - 3, 5);
    Insert(New(PLabel, Init(R, 'File compare action', Control)));

    R.Assign(3, 10, Size.X - 3, 14);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Check free disk space ~b~efore Copy',
      NewSItem('Copy~/~rename descriptions',
      NewSItem('Clear ~R~eadOnly attribute on Copy',
      NewSItem('~U~nselect skipped files',
      NewSItem('Hide Copy pro~g~ress window',
      NewSItem('Hide Cop~y~ statistics window',
      NewSItem('Enable recursive Copy/Mo~v~e',
      NewSItem('Do not copy/move empty dirs', nil))))))))));
    Insert(Control);
    R.Assign(2, 9, Size.X - 3, 10);
    Insert(New(PLabel, Init(R, 'File operation options', Control)));

    R.Assign(3, 16, Size.X - 3, 17);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Settings in this di~a~log box',
      NewSItem('Modified ~F~ile Manager options', nil))));
    Insert(Control);
    R.Assign(2, 15, Size.X - 3, 16);
    Insert(New(PLabel, Init(R,
      'Restore settings on completing the Copy/Rename operation', Control)));

    StandardButtonRow(D, True);
  end;
  FMCopyOptionsDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRFMCopyOptionsDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := FMCopyOptionsDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'COPYOPTIONSDIALOG');
    Dispose(D, Done);
  end;
end;

procedure FMCopyOptions;
var
  D: PDialog;
begin
  D := PDialog(Resource^.Get('COPYOPTIONSDIALOG'));
  if D = nil then ResNotFound(FMCopyTitle)
  else
  begin
    if FMOptions and foCheckFreeSpace <> 0 then
      FileCopyOptions := FileCopyOptions or fsCheckFreeSpace
    else FileCopyOptions := FileCopyOptions and not fsCheckFreeSpace;
    if FMOptions and foCopyDescriptions <> 0 then
      FileCopyOptions := FileCopyOptions or fsCopyDescriptions
    else FileCopyOptions := FileCopyOptions and not fsCopyDescriptions;
    Move(FileExistsAction, SaveFileExistsAction, SizeOf(Word) * 5);
    SaveFMOptions := FMOptions;
    if Application^.ExecuteDialog(D,
      @FileExistsAction, False) = cmCancel then Exit;
    if FileCopyOptions and fsCheckFreeSpace <> 0 then
      FMOptions := FMOptions or foCheckFreeSpace
    else FMOptions := FMOptions and not foCheckFreeSpace;
    if FileCopyOptions and fsCopyDescriptions <> 0 then
      FMOptions := FMOptions or foCopyDescriptions
    else FMOptions := FMOptions and not foCopyDescriptions;
  end;
end;

function UserOptionsDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 44, 14);
  D := New(PDialog, Init(R, UserProgTitle));
  with D^ do
  begin
    HelpCtx := hcOUserOptions;
    Options := Options or ofCentered;

    R.Assign(3, 3, 41, 4);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~C~reate .CBL file', nil)));
    Insert(Control);
    R.Assign(2, 2, 41, 3);
    Insert(New(PLabel, Init(R, 'Compiler', Control)));

    R.Assign(3, 6, 41, 10);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~T~erminate and restart afterwards',
      NewSItem('Terminate and do ~n~ot restart',
      NewSItem('~D~o not terminate',
      NewSItem('~P~rompt', nil))))));
    Insert(Control);
    R.Assign(2, 5, 41, 6);
    Insert(New(PLabel, Init(R, 'User program termination', Control)));

    R.Assign(3, 11, 13, 13);
    StandardOkButton(R, D);
    Inc(R.A.X, 14); Inc(R.B.X, 14);
    StandardCancelButton(R, D);
    Inc(R.A.X, 14); Inc(R.B.X, 14);
    StandardHelpButton(R, D);
    SelectNext(False);
  end;
  UserOptionsDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRUserOptionsDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := UserOptionsDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'USEROPTDIALOG');
    Dispose(D, Done);
  end;
end;

procedure UserOptions;
type
  TData = record
    List: Word;
    Abort: Word;
  end;
var
  D: PDialog;
  Data: TData;
begin
  D := PDialog(Resource^.Get('USEROPTDIALOG'));
  if D = nil then ResNotFound(UserProgTitle)
  else
  begin
    Data.List := Byte(LstFlag);
    Data.Abort := AbortUser;
    if Application^.ExecuteDialog(D, @Data, False) <> cmOk then Exit;
    LstFlag := Boolean(Data.List);
    AbortUser := Data.Abort;
  end;
end;

function ConfirmDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 57, 16);
  D := New(PDialog, Init(R, ConfirmTitle));
  with D^ do
  begin
    HelpCtx := hcOConfirmations;
    Options := Options or ofCentered;

    R.Assign(3, 3, 54, 12);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~M~odify memory',
      NewSItem('Clear ~h~istory lists',
      NewSItem('~D~elete items from a list box',
      NewSItem('Save ~c~urrent configuration before loading new',
      NewSItem('Abort ~E~ditor operations',
      NewSItem('Abort ~F~ile Manager operations',
      NewSItem('Close File Manager ~w~indow',
      NewSItem('Close ~T~erminal window on dialing/pasting',
      NewSItem('E~x~it the program', nil)))))))))));
    Insert(Control);
    R.Assign(2, 2, 54, 3);
    Insert(New(PLabel, Init(R, 'Prompt on action', Control)));

    StandardButtonRow(D, True);
  end;
  ConfirmDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRConfirmDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := ConfirmDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'CONFIRMDIALOG');
    Dispose(D, Done);
  end;
end;

procedure Confirmations;
var
  D: PDialog;
begin
  D := PDialog(Resource^.Get('CONFIRMDIALOG'));
  if D = nil then ResNotFound(ConfirmTitle)
  else Application^.ExecuteDialog(D, @ConfirmOptions, False);
end;

function LogOptionsDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 40, 22);
  D := New(PDialog, Init(R, LogTitle));
  with D^ do
  begin
    HelpCtx := hcOLog;
    Options := Options or ofCentered;

    R.Assign(3, 3, Size.X - 3, 4);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~E~nable event logging', nil)));
    Insert(Control);
    R.Assign(2, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(R, 'Log file', Control)));

    R.Assign(3, 6, Size.X - 3, 16);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~R~ead from disk           (-)',
      NewSItem('~W~rite to disk            (+)',
      NewSItem('E~x~ecute external program (>)',
      NewSItem('~T~ransmit/Receive data    ()',
      NewSItem('Error ~m~essage box        (!)',
      NewSItem('W~a~rning message box      (#)',
      NewSItem('~C~onfirmation message box (?)',
      NewSItem('~I~nformation message box  (^)',
      NewSItem('~L~oad/Save desktop        ($)',
      NewSItem('~O~ther events             ( )', nil))))))))))));
    Insert(Control);
    R.Assign(2, 5, Size.X - 3, 6);
    Insert(New(PLabel, Init(R, 'Log events', Control)));

    R.Assign(17, 17, Size.X - 6, 18);
    Control := New(PFInputLine, Init(R, 79));
    Insert(Control);
    StandardHistory(Control, LogHistoryId);
    R.Assign(2, 17, 17, 18);
    Insert(New(PLabel, Init(R, 'Log file ~n~ame', Control)));

    StandardButtonRow(D, True);
  end;
  LogOptionsDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRLogOptionsDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := LogOptionsDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'LOGOPTDIALOG');
    Dispose(D, Done);
  end;
end;

procedure LogFileOptions;
type
  TData = record
    Enable: Word;
    Class: Word;
    Name: String[79];
  end;
var
  D: PDialog;
  Data: TData;
begin
  D := PDialog(Resource^.Get('LOGOPTDIALOG'));
  if D = nil then ResNotFound(LogTitle)
  else
  begin
    Data.Enable := EnableLog;
    Data.Class := LogClass;
    Data.Name := LogName;
    if Application^.ExecuteDialog(D, @Data, False) <> cmOk then Exit;
    TrimSt(Data.Name);
    UpcaseSt(Data.Name);
    if (Data.Enable <> EnableLog) or (Data.Name <> LogName) then
    begin
      EnableLog := Data.Enable;
      LogClass := Data.Class;
      LogName := Data.Name;
      InitLog;
    end
    else if Data.Class <> LogClass then LogClass := Data.Class;
  end;
end;

function PrinterSetupDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 45, 20);
  D := New(PDialog, Init(R, PrinterSetupTitle));
  with D^ do
  begin
    HelpCtx := hcPrinterSetup;
    Options := Options or ofCentered;

    R.Assign(19, 2, Size.X - 6, 3);
    Control := New(PFInputLine, Init(R, NameLen));
    Insert(Control);
    StandardHistory(Control, PrnDeviceHistoryId);
    R.Assign(2, 2, 19, 3);
    Insert(New(PLabel, Init(R, 'Prn ~d~evice name', Control)));

    R.Assign(19, 3, Size.X - 6, 4);
    Control := New(PFInputLine, Init(R, NameLen));
    Insert(Control);
    StandardHistory(Control, FontFileHistoryId);
    R.Assign(2, 3, 19, 4);
    Insert(New(PLabel, Init(R, '~F~ont file name', Control)));

    R.Assign(3, 6, Size.X - 3, 9);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~U~se external font (Graphics mode)',
      NewSItem('~B~old characters (double strike)',
      NewSItem('Force page breaks (e~j~ect pages)', nil)))));
    Insert(Control);
    R.Assign(2, 5, Size.X - 3, 6);
    Insert(New(PLabel, Init(R, 'Print options', Control)));

    R.Assign(19, 10, Size.X - 6, 11);
    Control := New(PInputLine, Init(R, PrnInitLen));
    Insert(Control);
    StandardHistory(Control, PrnInitHistoryId);
    R.Assign(2, 10, 19, 11);
    Insert(New(PLabel, Init(R, '~I~nit string', Control)));

    R.Assign(19, 12, 26, 13);
    Control := New(PCInputLine, Init(R, PrnMarginLen, 0, 255));
    Insert(Control);
    R.Assign(2, 12, 19, 13);
    Insert(New(PLabel, Init(R, '~L~eft margin', Control)));

    R.Assign(19, 13, 26, 14);
    Control := New(PCInputLine, Init(R, PrnMarginLen, 0, 255));
    Insert(Control);
    R.Assign(2, 13, 19, 14);
    Insert(New(PLabel, Init(R, '~T~op margin', Control)));

    R.Assign(19, 14, 26, 15);
    Control := New(PCInputLine, Init(R, PrnMarginLen, 0, 255));
    Insert(Control);
    R.Assign(2, 14, 19, 15);
    Insert(New(PLabel, Init(R, 'B~o~ttom margin', Control)));

    R.Assign(19, 15, 26, 16);
    Control := New(PCInputLine, Init(R, PrnLinesLen, 0, 255));
    Insert(Control);
    R.Assign(2, 15, 19, 16);
    Insert(New(PLabel, Init(R, 'Lines ~p~er page', Control)));

    R.Assign(19, 16, 26, 17);
    Control := New(PInputLine, Init(R, PrnIntervalLen));
    Insert(Control);
    R.Assign(2, 16, 19, 17);
    Insert(New(PLabel, Init(R, 'Line inter~v~al', Control)));

    R.Assign(19, 17, 26, 18);
    Control := New(PCInputLine, Init(R, PrnCycleLen, 0, $FFFF));
    Insert(Control);
    R.Assign(2, 17, 19, 18);
    Insert(New(PLabel, Init(R, '~C~hars per cycle', Control)));

    R.Assign(Size.X - 13, 12, Size.X - 3, 14);
    StandardOkButton(R, D);
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    StandardCancelButton(R, D);
    Inc(R.A.Y, 3); Inc(R.B.Y, 3);
    StandardHelpButton(R, D);
    SelectNext(False);
  end;
  PrinterSetupDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRPrinterDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := PrinterSetupDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'PRINTERDIALOG');
    Dispose(D, Done);
  end;
end;

procedure PrinterSetup;
var
  D: PDialog;
begin
  D := PDialog(Resource^.Get('PRINTERDIALOG'));
  if D = nil then ResNotFound(PrinterSetupTitle)
  else if Application^.ExecuteDialog(D, @PrnDeviceName, False) = cmOk then
    Message(Desktop, evBroadcast, cmEditOptions, nil);;
end;

function SetupDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 80, 23);
  D := New(PDialog, Init(R, SetupTitle));
  with D^ do
  begin
    HelpCtx := hcSetup;
    Options := Options or ofCentered;

    R.Assign(3, 3, 21, 6);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Editor ~f~iles',
      NewSItem('E~n~vironment',
      NewSItem('Deskt~o~p', nil)))));
    Insert(Control);
    R.Assign(2, 2, 21, 3);
    Insert(New(PLabel, Init(R, 'Auto save', Control)));

    R.Assign(23, 3, 49, 6);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('CGA sno~w~ checking',
      NewSItem('Palette ~1~6/16',
      NewSItem('Restore ~v~ideo mode', nil)))));
    Insert(Control);
    R.Assign(22, 2, 49, 3);
    Insert(New(PLabel, Init(R, 'Display', Control)));

    R.Assign(3, 7, 21, 9);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('A~t~ the start  ',
      NewSItem('On e~x~it', nil))));
    Insert(Control);
    R.Assign(2, 6, 21, 7);
    Insert(New(PLabel, Init(R, 'Return to last dir', Control)));

    R.Assign(23, 7, 49, 9);
    Control := New(PRadioButtons, Init(R,
      NewSItem('Dra~g~ until released',
      NewSItem('D~r~ag until pressed', nil))));
    Insert(Control);
    R.Assign(22, 6, 49, 7);
    Insert(New(PLabel, Init(R, 'Mouse Drag-And-Drop', Control)));

    R.Assign(3, 10, 21, 14);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~M~enu bar',
      NewSItem('Status ~l~ine',
      NewSItem('~C~lock',
      NewSItem('Hea~p~', nil))))));
    Insert(Control);
    R.Assign(2, 9, 21, 10);
    Insert(New(PLabel, Init(R, 'Hide views', Control)));

    R.Assign(23, 10, 49, 14);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Disable s~y~sinfo',
      NewSItem('Disable VGA palette',
      NewSItem('Disabl~e~ all sounds',
      NewSItem('Local associations', nil))))));
    Insert(Control);
    R.Assign(22, 9, 49, 10);
    Insert(New(PLabel, Init(R, 'Various system settings', Control)));

    R.Assign(3, 15, 21, 17);
    Control := New(PRadioButtons, Init(R,
      NewSItem('Always',
      NewSItem('Idle~-~state', nil))));
    Insert(Control);
    R.Assign(2, 14, 21, 15);
    Insert(New(PLabel, Init(R, 'Release time-slice', Control)));

    R.Assign(23, 15, 49, 17);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('INT 2~8~ (DOS Idle)',
      NewSItem('INT ~2~F (1680)', nil))));
    Insert(Control);
    R.Assign(22, 14, 49, 15);
    Insert(New(PLabel, Init(R, 'Time-slicing strategy', Control)));

    R.Assign(51, 3, Size.X - 3, 6);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~A~uto detect',
      NewSItem('~D~OS',
      NewSItem('~U~NIX', nil)))));
    Insert(Control);
    R.Assign(50, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(R, 'Text file reading mode', Control)));

    R.Assign(51, 7, Size.X - 3, 9);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Text viewer',
      NewSItem('HTML viewer', nil))));
    Insert(Control);
    R.Assign(50, 6, Size.X - 3, 7);
    Insert(New(PLabel, Init(R, 'Enable auto-decoding', Control)));

    R.Assign(51, 10, Size.X - 3, 13);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Enable Win9~5~ LFN API',
      NewSItem('Case convers~i~on',
      NewSItem('Short names ~"~as is"', nil)))));
{      NewSItem('Enable  OS/~2~ LFN API', nil))));
    PCheckBoxes(Control)^.SetButtonState(loEnableOS2LFN, False);}
    Insert(Control);
    R.Assign(50, 9, Size.X - 3, 10);
    Insert(New(PLabel, Init(R, 'Long filename support', Control)));

    R.Assign(51, 14, Size.X - 3, 15);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Use AutoComplete', nil)));
    Insert(Control);
    R.Assign(50, 13, Size.X - 3, 14);
    Insert(New(PLabel, Init(R, 'Input lines', Control)));

    R.Assign(71, 16, Size.X - 3, 17);
    Control := New(PCInputLine, Init(R, 5, 0, 65535));
    Insert(Control);
    R.Assign(50, 16, 71, 17);
    Insert(New(PLabel, Init(R, 'Auto save time, min', Control)));

    R.Assign(71, 17, Size.X - 3, 18);
    Control := New(PCInputLine, Init(R, 5, 0, 65535));
    Insert(Control);
    R.Assign(50, 17, 71, 18);
    Insert(New(PLabel, Init(R, 'Animation delay, ms', Control)));

    R.Assign(71, 18, Size.X - 3, 19);
    Control := New(PCInputLine, Init(R, 5, 0, 65535));
    Insert(Control);
    R.Assign(50, 18, 71, 19);
    Insert(New(PLabel, Init(R, 'Ending signal, sec', Control)));

    R.Assign(71, 19, Size.X - 3, 20);
    Control := New(PCInputLine, Init(R, 5, -32768, 32767));
    Insert(Control);
    R.Assign(50, 19, 71, 20);
    Insert(New(PLabel, Init(R, 'Idle sky delay~,~ min', Control)));

    R.Assign(71, 20, Size.X - 3, 21);
    Control := New(PCInputLine, Init(R, 2, 1, 64));
    Insert(Control);
    R.Assign(50, 20, 71, 21);
    Insert(New(PLabel, Init(R, '~H~istory lines limit', Control)));

    R.Assign(71, 21, 74, 22);
    Control := New(PInputLine, Init(R, 1));
    Control^.Options := Control^.Options and not ofFirstClick;
    Insert(Control);
    R.Assign(50, 21, 71, 22);
    Insert(New(PLabel, Init(R, '~B~ackground pattern', Control)));

    R.Assign(3, 18, 46, 19);
    Control := New(PDInputLine, Init(R, 67));
    Insert(Control);
    StandardHistory(Control, DirHistoryId);
    R.Assign(2, 17, 46, 18);
    Insert(New(PLabel, Init(R, '~S~wap file directory', Control)));

    R.Assign(2, Size.Y - 3, 12, Size.Y - 1);
    StandardOkButton(R, D);
    Inc(R.A.X, 19); Inc(R.B.X, 19);
    StandardCancelButton(R, D);
    Inc(R.A.X, 18); Inc(R.B.X, 18);
    StandardHelpButton(R, D);
    SelectNext(False);
  end;
  SetupDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRSetupDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := SetupDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'SETUPDIALOG');
    Dispose(D, Done);
  end;
end;

const
  ptPosSignature: Longint = $53505450 {'PTPS'} ;
  ptSeekPos: Longint = MaxLongint;

procedure Setup;
type
  TDialogData = record
    DesktopSetup, DisplaySetup, DirSetup, DropMode, HideSetup,
    Sysinfo, SliceOpt, SliceType, TxtMode, AutoXLAT, LFNSetup,
    AutoComplete: Word;
    SaveTime: String[5];
    AnimationDelay: String[5];
    BeepTime: String[5];
    SaverDelay: String[5];
    HistoryDepth: String[2];
    Pattern: String[1];
    SwapDir: String[67];
  end;
var
  SavePattern: Char;
  D: PDialog;
  Code: Integer;
  W: Word;
  AData: TDialogData;
begin
  D := PDialog(Resource^.Get('SETUPDIALOG'));
  if D = nil then
  begin
    ResNotFound(SetupTitle);
    Exit;
  end;
  FillChar(AData, SizeOf(TDialogData), 0);
  if DesktopData^.SaveEditorFiles then
    AData.DesktopSetup := AData.DesktopSetup or suSaveEditorFiles;
  if DesktopData^.SaveEnvironment then
    AData.DesktopSetup := AData.DesktopSetup or suSaveEnvironment;
  if DesktopData^.SaveDesktop then
    AData.DesktopSetup := AData.DesktopSetup or suSaveDesktop;
  if DoCheckSnow then
    AData.DisplaySetup := AData.DisplaySetup or suCheckSnow;
  if EnhancedPaletteOn then
    AData.DisplaySetup := AData.DisplaySetup or suEnhancedPalette;
  if RestoreVideoMode then
    AData.DisplaySetup := AData.DisplaySetup or suRestoreVideoMode;
  if DesktopData^.ReturnToDirAtStart then
    AData.DirSetup := AData.DirSetup or suReturnToDirAtStart;
  if DesktopData^.ReturnToDirOnExit then
    AData.DirSetup := AData.DirSetup or suReturnToDirOnExit;
  AData.DropMode := Byte(Boolean(ddMode));
  AData.SwapDir := SwapDir;
  AData.SaveTime := DesktopData^.SaveTime;
  AData.AnimationDelay := DesktopData^.AnimationDelay;
  AData.BeepTime := DesktopData^.EndingBeep;
  AData.SaverDelay := DesktopData^.SaverDelay;
  Str(HistoryDepth, AData.HistoryDepth);
  AData.Pattern := Desktop^.Background^.Pattern;
  SavePattern := Desktop^.Background^.Pattern;
  AData.HideSetup := HideOptions;
  AData.TxtMode := TextReadMode;
  AData.AutoXLAT := AutoDecode and not adAutoComplete;
  AData.SliceOpt := TimeSliceOptions;
  AData.SliceType := TimeSliceType;
  AData.Sysinfo := Byte(DisableSysinfo) +
    Byte(DisableVGAPalette) shl 1 +
    Byte(DisableSounds) shl 2 +
    Byte(LocalAssocs) shl 3;
  AData.LFNSetup := LFNOptions;
{ Added 04.08.08 to support InputLine AutoComplete }
  if AutoDecode and adAutoComplete <> 0 then AData.AutoComplete := 1
  else AData.AutoComplete := 0;
  if Application^.ExecuteDialog(D, @AData, False) <> cmCancel then
  begin
    DesktopData^.SaveEditorFiles :=
      AData.DesktopSetup and suSaveEditorFiles <> 0;
    DesktopData^.SaveEnvironment :=
      AData.DesktopSetup and suSaveEnvironment <> 0;
    DesktopData^.SaveDesktop :=
      AData.DesktopSetup and suSaveDesktop <> 0;
    DoCheckSnow := AData.DisplaySetup and suCheckSnow <> 0;
    EnhancedPaletteOn := AData.DisplaySetup and suEnhancedPalette <> 0;
    RestoreVideoMode := AData.DisplaySetup and suRestoreVideoMode <> 0;
    DesktopData^.ReturnToDirAtStart :=
      AData.DirSetup and suReturnToDirAtStart <> 0;
    DesktopData^.ReturnToDirOnExit :=
      AData.DirSetup and suReturnToDirOnExit <> 0;
    ddMode := AData.DropMode;
    SwapDir := StUpcase(Trim(AData.SwapDir));
    DesktopData^.SaveTime := AData.SaveTime;
    Val(DesktopData^.SaveTime, AutoSaveTime, Code);
    DesktopData^.AnimationDelay := AData.AnimationDelay;
    Val(DesktopData^.AnimationDelay, AnimateDelay, Code);
    DesktopData^.EndingBeep := AData.BeepTime;
    Val(DesktopData^.EndingBeep, EndingBeepTime, Code);
    DesktopData^.SaverDelay := AData.SaverDelay;
    Val(DesktopData^.SaverDelay, SaverDelay, Code);
    Val(AData.HistoryDepth, HistoryDepth, Code);
    if AData.Pattern = '' then PatternChar := #32
    else PatternChar := AData.Pattern[1];
    Desktop^.Background^.Pattern := PatternChar;
    TextReadMode := AData.TxtMode;
    AutoDecode := AData.AutoXLAT;
    TimeSliceOptions := AData.SliceOpt;
    TimeSliceType := AData.SliceType;
    DisableSysinfo := AData.Sysinfo and suDisableSysinfo <> 0;
    DisableVGAPalette := AData.Sysinfo and suDisableVGAPalette <> 0;
    DisableSounds := AData.Sysinfo and suDisableSounds <> 0;
    LocalAssocs := AData.Sysinfo and suLocalAssocs <> 0;
    if HideOptions <> AData.HideSetup then
    begin
      HideOptions := AData.HideSetup;
      UpdateMainViews;
    end;
    if SavePattern <> PatternChar then
      WriteDataToEXE(ptSeekPos, PatternSignature, PatternChar, 1);
    RefreshDisplay;
    SetLFNOptions(AData.LFNSetup);
{ Added 04.08.08 to support InputLine AutoComplete }
    if AData.AutoComplete and 1 <> 0 then AutoDecode :=
      AutoDecode or adAutoComplete;
  end;
end;

procedure SaveOptions;
var
  Name: FNameStr;
begin
  SetConfigExt('CFG', Name);
  if Application^.ExecuteDialog(New(PFileDialog, Init(
    '*.CFG', 'Save options', '~O~ptions file name',
    fdOkButton + fdHelpButton, OptionsHistoryID)),
    @Name, False) <> cmCancel then
  begin
    while Pos('.', Name) <> 0 do Dec(Name[0]);
    SetConfigName(Name);
    SaveDesktop(True);
  end;
end;

procedure RetrieveOptions;
var
  C: Word;
  Name: FNameStr;
begin
  if not SaveOnExit then Exit;
  Name := HistoryStr(OptionsHistoryID, 0);
  if Application^.ExecuteDialog(New(PFileDialog, Init(
    '*.CFG', 'Retrieve options', '~O~ptions file name',
    fdOkButton + fdHelpButton, OptionsHistoryID)),
    @Name, False) <> cmCancel then
  begin
    while Pos('.', Name) <> 0 do Dec(Name[0]);
    if (Name <> ConfigPath + ConfigMask) and
       (DesktopData^.SaveEnvironment or DesktopData^.SaveDesktop) then
    begin
      if ConfirmOptions and coSaveCurrentConfig = 0 then C := cmYes
      else C := MessageBox(^C'Save current configuration to'#13^C'|' +
	ConfigPath + ConfigMask + '.CFG' + '| ?',
	nil, mfConfirmation + mfYesNoCancel);
      if C = cmCancel then Exit;
      if C = cmYes then SaveDesktop(False);
    end;
    Message(Desktop, evBroadcast, cmQuit, Pointer(1));
    CloseAllViews;
    DoneClipboard(False, True);
    DoneDiskSwapStream;
    Dispose(Dates, Done);
    DoneDesktopData;
    ClearHistory;
    SetAltCase;
    SetConfigName(Name);
    InitDesktopData;
    SetCNConfigName(Name, 'ALR');
    LoadDates(Name);
    RetrieveDesktop;
  end;
end;

function ModeDialog: PDialog;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 72, 23);
  D := New(PDialog, Init(R, ModeTitle));
  with D^ do
  begin
    HelpCtx := hcOMode;
    Options := Options or ofCentered;

    R.Assign(16, 2, 69, 3);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~U~ART', NewSItem('~I~nt14',
      NewSItem('~F~ossil', NewSItem('~D~igi14', nil))))));
    Insert(Control);
    R.Assign(2, 2, 16, 3);
    Insert(New(PLabel, Init(R, 'Device layer', Control)));

    R.Assign(16, 4, 21, 5);
    Control := New(PCInputLine, Init(R, 3, 0, $FFF));
    Insert(Control);
    R.Assign(2, 4, 16, 5);
    Insert(New(PLabel, Init(R, 'Port address', Control)));

    R.Assign(35, 4, 39, 5);
    Control := New(PCInputLine, Init(R, 2, 0, 99));
    Insert(Control);
    R.Assign(23, 4, 35, 5);
    Insert(New(PLabel, Init(R, 'IRQ number', Control)));

    R.Assign(53, 4, 57, 5);
    Control := New(PCInputLine, Init(R, 2, 0, $FF));
    Insert(Control);
    R.Assign(41, 4, 53, 5);
    Insert(New(PLabel, Init(R, 'COM vector', Control)));

    R.Assign(3, 7, 13, 15);
    Control := New(PRadioButtons, Init(R,
      NewSItem('COM~1~', NewSItem('COM~2~',
      NewSItem('COM~3~', NewSItem('COM~4~',
      NewSItem('COM5', NewSItem('COM6',
      NewSItem('COM7', NewSItem('COM8', nil))))))))));
    Insert(Control);
    R.Assign(2, 6, 13, 7);
    Insert(New(PLabel, Init(R, 'Port', Control)));

    R.Assign(15, 7, 27, 19);
    Control := New(PRadioButtons, Init(R,
      NewSItem('110', NewSItem('150',
      NewSItem('300', NewSItem('600',
      NewSItem('1200', NewSItem('24~0~0',
      NewSItem('4800', NewSItem('~9~600',
      NewSItem('19200', NewSItem('38400',
      NewSItem('57600', NewSItem('115200', nil))))))))))))));
    Insert(Control);
    R.Assign(14, 6, 27, 7);
    Insert(New(PLabel, Init(R, 'Baud rate', Control)));

    R.Assign(29, 7, 40, 12);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~N~one', NewSItem('~O~dd',
      NewSItem('~E~ven', NewSItem('~M~ark',
      NewSItem('~S~pace', nil)))))));
    Insert(Control);
    R.Assign(28, 6, 40, 7);
    Insert(New(PLabel, Init(R, 'Parity', Control)));

    R.Assign(3, 17, 13, 19);
    Control := New(PRadioButtons, Init(R,
      NewSItem('1', NewSItem('2', nil))));
    Insert(Control);
    R.Assign(2, 16, 13, 17);
    Insert(New(PLabel, Init(R, 'Stop bits', Control)));

    R.Assign(29, 15, 40, 19);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~5~', NewSItem('~6~',
      NewSItem('~7~', NewSItem('~8~', nil))))));
    Insert(Control);
    R.Assign(29, 14, 40, 15);
    Insert(New(PLabel, Init(R, 'Data bits', Control)));

    R.Assign(42, 7, 69, 15);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Use D~T~R', NewSItem('Use ~R~TS',
      NewSItem('Re~q~uire DSR', NewSItem('Require ~C~TS',
      NewSItem('DTR ~a~ctive low', NewSItem('RTS acti~v~e low',
      NewSItem('DSR active ~l~ow', NewSItem('CTS active lo~w~', nil))))))))));
    Insert(Control);
    R.Assign(41, 6, 69, 7);
    Insert(New(PLabel, Init(R, 'Hardware flow control', Control)));

    R.Assign(42, 17, 69, 19);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Receiver flow',
      NewSItem('Transmitter flow', nil))));
    Insert(Control);
    R.Assign(41, 16, 69, 17);
    Insert(New(PLabel, Init(R, 'Software flow control', Control)));

    R.Assign(61, 20, 69, 21);
    Control := New(PCInputLine, Init(R, 5, 1024, 65520));
    Insert(Control);
    R.Assign(41, 20, 61, 21);
    Insert(New(PLabel, Init(R, 'In~p~ut buffer size', Control)));

    R.Assign(61, 21, 69, 22);
    Control := New(PCInputLine, Init(R, 5, 1024, 65520));
    Insert(Control);
    R.Assign(41, 21, 61, 22);
    Insert(New(PLabel, Init(R, 'Output ~b~uffer size', Control)));

    R.Assign(3, Size.Y - 3, 13, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(16, Size.Y - 3, 26, Size.Y - 1);
    StandardCancelButton(R, D);
    R.Assign(29, Size.Y - 3, 39, Size.Y - 1);
    StandardHelpButton(R, D);

    SelectNext(False);
  end;
  ModeDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRModeDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := ModeDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'MODEDIALOG');
    Dispose(D, Done);
  end;
end;

procedure Mode;
type
  TData = record
    Device: Word;
    Address: String[3];
    IRQ: String[2];
    Vector: String[2];
    ComName: Word;
    Baud: Word;
    Parity: Word;
    StopBits: Word;
    DataBits: Word;
    HWFlow: Word;
    SWFlow: Word;
    InSize: String[5];
    OutSize: String[5];
  end;
var
  I: Integer;
  BufferFull, BufferResume: Word;
  D: PDialog;
  Data: TData;

procedure Mode2Data;
var
  B: Byte;
begin
  Data.Device := DeviceLayer;
  if PortAddress = 0 then Data.Address := ''
  else Data.Address := Copy(HexW(PortAddress), 2, 3);
  if IRQNumber = 0 then Data.IRQ := ''
  else Str(IRQNumber, Data.IRQ);
  if COMVector = 0 then Data.Vector := ''
  else Data.Vector := HexB(COMVector);
  Data.ComName := Ord(ComName);
  for B := 0 to MaxBauds - 1 do if BaudTable[B] = Baud then Break;
  Data.Baud := B;
  Data.Parity := Ord(Parity);
  Data.DataBits := Ord(DataBits) - 5;
  Data.StopBits := Ord(StopBits) - 1;
  Data.HWFlow := HWFlow;
  Data.SWFlow := SWFlow;
  Str(InBufSize, Data.InSize);
  Str(OutBufSize, Data.OutSize);
end;

procedure Data2Mode;
begin
  DeviceLayer := Data.Device;
  Val('$' + Data.Address, PortAddress, I);
  Val(Data.IRQ, IRQNumber, I);
  Val('$' + Data.Vector, COMVector, I);
  ComName := ComNameType(Data.ComName);
  if Data.Baud < MaxBauds then Baud := BaudTable[Data.Baud]
  else Baud := 9600;
  Parity := ParityType(Data.Parity);
  DataBits := Data.DataBits + 5;
  StopBits := Data.StopBits + 1;
  HWFlow := Data.HWFlow;
  SWFlow := Data.SWFlow;
  Val(Data.InSize, InBufSize, I);
  Val(Data.OutSize, OutBufSize, I);
end;

begin
  D := PDialog(Resource^.Get('MODEDIALOG'));
  if D = nil then ResNotFound(ModeTitle)
  else
  begin
    Mode2Data;
    if Application^.ExecuteDialog(D, @Data, False) = cmCancel then Exit;
    Data2Mode;
    for I := 1 to MaxActivePort do
      if (ActiveComPort[I] <> nil) and
         (ActiveComPort[I]^.PortName = ComName) then
      begin
        SetLine(ActiveComPort[I], Baud, Parity, DataBits, StopBits);
        if ActiveComPort[I]^.Flags and ptHiIrq <> 0 then
          ActiveComPort[I]^.Flags := PortOptions or ptHiIrq
        else ActiveComPort[I]^.Flags := PortOptions;
        if (OldLayer = dlUART) and (DeviceLayer = dlUART) then
        begin
          ChangeBufferSizes(ActiveComPort[I], InBufSize, OutBufSize);
          BufferFull := Round(InBufSize * 0.75);
          BufferResume := Round(InBufSize * 0.25);
          if HWFlow and $FF = 0 then HWFlowDisable(ActiveComPort[I])
          else HWFlowEnable(ActiveComPort[I],
            BufferFull, BufferResume, HWFlow);
          if SWFlow and $03 = 0 then SWFlowDisable(ActiveComPort[I])
          else SWFlowEnableOpt(ActiveComPort[I],
            BufferFull, BufferResume, SWFlow);
        end;
        if AsyncStatus <> ecOk then
        begin
          AsyncErrorProc(ActiveComPort[I], AsyncStatus);
          Exit;
        end;
      end;
  end;
end;

function OvrOptionsDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 47, 22);
  D := New(PDialog, Init(R, OvrTitle));
  with D^ do
  begin
    HelpCtx := hcOvrOptions;
    Options := Options or ofCentered;

    R.Assign(3, 3, Size.X - 3, 6);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Use expanded (extended) ~m~emory',
      NewSItem('Move bu~f~fer to upper memory (UMB)',
      NewSItem('Use upper memory (UMB) for ~H~eap', nil)))));
    Insert(Control);
    R.Assign(2, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(R, 'Overlay in memory', Control)));

    R.Assign(3, 8, Size.X - 3, 12);
    Control := New(PRadioButtons, Init(R,
      NewSItem('Use ~E~MS only (do not try XMS)',
      NewSItem('Use ~X~MS only (do not try EMS)',
      NewSItem('~U~se EMS over XMS (try EMS first)',
      NewSItem('U~s~e XMS over EMS (try XMS first)', nil))))));
    Insert(Control);
    R.Assign(2, 7, Size.X - 3, 8);
    Insert(New(PLabel, Init(R, 'Overlay preferences', Control)));

    R.Assign(3, 14, Size.X - 3, 16);
    Control := New(PRadioButtons, Init(R,
      NewSItem('Load ~a~ll segments at the start',
      NewSItem('Load segments at ~r~un-time as needed', nil))));
    Insert(Control);
    R.Assign(2, 13, Size.X - 3, 14);
    Insert(New(PLabel, Init(R, 'Overlay read options', Control)));

    R.Assign(23, 17, 31, 18);
    Control := New(PCInputLine, Init(R, 6, 90000, 150000));
    Insert(Control);
    R.Assign(2, 17, 23, 18);
    Insert(New(PLabel, Init(R, 'Overlay ~b~uffer size', Control)));

    StandardButtonRow(D, True);
  end;
  OvrOptionsDialog := PDialog(Application^.ValidView(D));
end;

procedure RSROvrDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := OvrOptionsDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'OVRDIALOG');
    Dispose(D, Done);
  end;
end;

const
  ovrPosSignature: Longint = $5350564F {'OVPS'} ;
  ovrSeekPos: Longint = MaxLongint;

procedure OvrOptions;
type
  TDialogData = record
    Mem, Pref, Load: Word;
    Size: String[6];
  end;
var
  SaveTime: Longint;
  D: PDialog;
  S: TDosStream;
  L: Longint;
  Code: Integer;
  AData: TDialogData;
  Name: FNameStr;
  F: Text;
begin
  D := PDialog(Resource^.Get('OVRDIALOG'));
  if D = nil then
  begin
    ResNotFound(OvrTitle);
    Exit;
  end;
  FillChar(AData, SizeOf(TDialogData), 0);
  AData.Mem := ovMem;
  AData.Pref := ovPref;
  AData.Load := ovLoad;
  Str(ovBufSize, AData.Size);
  if (Application^.ExecuteDialog(D, @AData, False) <> cmCancel) and
     (MessageBox(^C'Changes are written directly to'#13 +
       ^C'CONNECT.EXE and do not take effect'#13 +
       ^C'until you reload the IDE.',
       nil, mfWarning + mfOkCancel) <> cmCancel) then
  begin
    ovMem := AData.Mem;
    ovPref := AData.Pref;
    ovLoad := AData.Load;
    Val(AData.Size, ovBufSize, Code);
    WriteDataToEXE(ovrSeekPos, ovrSignature, ovMem, 7);
  end;
end;

function CDOptionsDialog: PDialog;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 57, 18);
  D := New(PDialog, Init(R, CDTitle));
  with D^ do
  begin
    HelpCtx := hcOCDOptions;
    Options := Options or ofCentered;

    R.Assign(3, 3, 34, 8);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~R~un Mixer on activate',
      NewSItem('~A~uto play on media change',
      NewSItem('~L~ock door on play',
      NewSItem('R~e~peat on end',
      NewSItem('E~j~ect disk on stop', nil)))))));
    Insert(Control);
    R.Assign(2, 2, 34, 3);
    Insert(New(PLabel, Init(R, 'Settings', Control)));

    R.Assign(36, 3, 54, 8);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~D~isk order',
      NewSItem('~U~ser order',
      NewSItem('Si~n~gle track',
      NewSItem('~I~ntroduction',
      NewSItem('~S~huffle', nil)))))));
    Insert(Control);
    R.Assign(35, 2, 54, 3);
    Insert(New(PLabel, Init(R, 'Play sequence', Control)));

    R.Assign(23, 9, 28, 10);
    Control := New(PCInputLine, Init(R, 3, 1, 999));
    Insert(Control);
    R.Assign(2, 9, 23, 10);
    Insert(New(PLabel, Init(R, '~F~orward/Rewind time', Control)));

    R.Assign(49, 9, 54, 10);
    Control := New(PCInputLine, Init(R, 3, 1, 999));
    Insert(Control);
    R.Assign(30, 9, 49, 10);
    Insert(New(PLabel, Init(R, 'In~t~roduction time', Control)));

    R.Assign(23, 11, 54, 12);
    Control := New(PDInputLine, Init(R, 67));
    Insert(Control);
    R.Assign(2, 11, 23, 12);
    Insert(New(PLabel, Init(R, 'CD al~b~ums directory', Control)));

    R.Assign(23, 13, 54, 14);
    Control := New(PInputLine, Init(R, 127));
    Insert(Control);
    R.Assign(2, 13, 23, 14);
    Insert(New(PLabel, Init(R, 'Sound Mi~x~er command', Control)));

    StandardButtonRow(D, True);
  end;
  CDOptionsDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRCDOptionsDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := CDOptionsDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'CDOPTIONSDIALOG');
    Dispose(D, Done);
  end;
end;

procedure CDOptions;
type
  TData = record
    Settings: Word;
    Sequence: Word;
    FastTime: String[3];
    IntroTime: String[3];
    Dir: String[67];
    Mixer: String[127];
  end;
var
  Code: Integer;
  D: PDialog;
  Control: PView;
  R: TRect;
  Data: TData;
begin
  D := PDialog(Resource^.Get('CDOPTIONSDIALOG'));
  if D = nil then
  begin
    ResNotFound(CDTitle);
    Exit;
  end;
  with Data do
  begin
    Settings := cdSettings;
    Sequence := cdSequence;
    Str(cdFastTime, FastTime);
    Str(cdIntroTime, IntroTime);
    Dir := cdAlbumDir;
    Mixer := cdMixerCommand;
  end;
  if Application^.ExecuteDialog(
    D, @Data, False) <> cmCancel then with Data do
  begin
    cdSettings := Settings;
    cdSequence := Sequence;
    Val(FastTime, cdFastTime, Code);
    Val(IntroTime, cdIntroTime, Code);
    cdAlbumDir := StUpcase(Trim(Dir));
    cdMixerCommand := Trim(Mixer);
  end;
end;

end.