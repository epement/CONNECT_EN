{$I-,F+,O+,X+}
unit FMSecond;

interface

uses Objects, Drivers, Views, Dialogs, HistWin, FileMngr;

type
  PQuickDirViewer = ^TQuickDirViewer;
  TQuickDirViewer = object(THistoryViewer)
    function GetCopyText(Item: Integer; MaxLen: Integer): String; virtual;
  end;

  PQuickDirHistory = ^TQuickDirHistory;
  TQuickDirHistory = object(THistWindow)
    procedure InitViewer(HistoryId: Word); virtual;
  end;

procedure GetExecHistStr(var S: String; const Title: TTitleStr;
  FocusFirst, Topmost: Boolean);
procedure ExecOptionsPrim(Caller: PView);
procedure GetHistoryStrPrim(ThePrompt: PPromptLine);
procedure PromptPopupPrim(AnOrigin: TPoint);
procedure SaveFocusedNamePrim(FManager: PPanel);
procedure GetDirHistStr(var S: String; const Title: TTitleStr;
  FocusFirst, Topmost: Boolean);
procedure DirHistoryPrim(FManager: PPanel);
procedure AltNumpadHistoryPrim(FManager: PPanel; Code: Byte);
procedure AltCtrlPgUpHistoryPrim(FManager: PPanel; Down: Boolean);
procedure PopupPrim(FManager: PPanel; AnOrigin: TPoint);
procedure SetColumnWidthPrim(FManager: PPanel; AWidth: Integer);
procedure DragColumnsPrim(FManager: PPanel; Event: TEvent);
procedure DragPanelsPrim(PanelWindow: PPanelWindow; Event: TEvent;
  Mode: Byte; var Limits: TRect; MinSize, MaxSize: TPoint);
procedure ZoomPrim(PanelWindow: PPanelWindow);
procedure TogglePanelPrim(PanelWindow: PPanelWindow; APanel: PPanel;
  ByWhat: Byte);
procedure ToggleBothPanelsPrim(PanelWindow: PPanelWindow);

implementation

uses Memory, Menus, MenuBox, HistList, App, Popups, FMDrvSel, ArcV, ProgList,
  DirPrim, History, TPString, Consts, Commands, Defaults;

function TQuickDirViewer.GetCopyText(Item: Integer; MaxLen: Integer): String;
var
  S: String;
begin
  S := THistoryViewer.GetCopyText(Item, MaxLen);
  if S[Length(S)] = #255 then Dec(S[0], 3);
  GetCopyText := S;
end;

procedure TQuickDirHistory.InitViewer(HistoryId: Word);
var
  R: TRect;
begin
  GetExtent(R);
  R.Grow(-1, -1);
  Viewer := New(PQuickDirViewer, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    HistoryId));
  Viewer^.HelpCtx := hcPromptHistory;
  Insert(Viewer);
end;

{
procedure ExecOptionsPrim(Caller: PView);
type
  TExecData = record
    Main, Setup, Opt, Apply: Word;
  end;
const
  eoLeft = $0001;
  eoRight = $0002;
  eoPrompt = $0004;
  ApplyOpt: Word = 0;
var
  B: Boolean;
  W: Word;
  D: PDialog;
  Control: PView;
  R: TRect;
  ED: TExecData;
  S: String[15];
begin
  R.Assign(0, 0, 67, 12);
  B := TypeOf(Caller^) = TypeOf(TPromptLine);
  if B then S := 'Command line'
  else if PPanel(Caller)^.Which = pnRight then S := 'Right panel'
  else S := 'Left panel';
  D := InitSimpleDialog(R, S + ' Exec options', hcExecOptions);
  with D^ do
  begin
    Options := Options or ofCentered;
    R.Assign(3, 3, 15, 6);
    Control := MainControl(R);
    Insert(Control);
    R.Assign(2, 2, 15, 3);
    Insert(New(PLabel, Init(R, 'Main', Control)));

    R.Assign(17, 3, 40, 6);
    Control := SetupControl(R);
    Insert(Control);
    R.Assign(16, 2, 40, 3);
    Insert(New(PLabel, Init(R, 'Setup', Control)));

    R.Assign(42, 3, 64, 6);
    Control := OptionsControl(R, True);
    Insert(Control);
    R.Assign(41, 2, 64, 3);
    Insert(New(PLabel, Init(R, 'Options', Control)));

    R.Assign(12, 7, Size.X - 3, 8);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Le~f~t panel',
      NewSItem('~R~ight panel',
      NewSItem('~C~ommand line', nil)))));
    Insert(Control);
    R.Assign(2, 7, 12, 8);
    Insert(New(PLabel, Init(R, 'Apply to', Control)));

    for W := 0 to 2 do SelectNext(True);
  end;

  if B then with PPromptLine(Caller)^ do
  begin
    ED.Main := Main;
    ED.Setup := Setup;
    ED.Opt := Opt;
    W := eoPrompt;
  end
  else with PPanel(Caller)^ do
  begin
    ED.Main := Main;
    ED.Setup := Setup;
    ED.Opt := Opt;
    if Which = pnRight then W := eoRight
    else W := eoLeft;
  end;
  if not B and (ApplyOpt <> 0) then W := ApplyOpt;
  ED.Apply := W;

  if Application^.ExecuteDialog(D, @ED, False) = cmCancel then Exit;

  with PPanelWindow(Caller^.Owner)^ do
  begin
    if ED.Apply and eoLeft <> 0 then
    begin
      LeftPanel^.Main := ED.Main;
      LeftPanel^.Setup := ED.Setup;
      LeftPanel^.Opt := ED.Opt;
    end;
    if ED.Apply and eoRight <> 0 then
    begin
      RightPanel^.Main := ED.Main;
      RightPanel^.Setup := ED.Setup;
      RightPanel^.Opt := ED.Opt;
    end;
    if ED.Apply and eoPrompt <> 0 then
    begin
      PromptLine^.Main := ED.Main;
      PromptLine^.Setup := ED.Setup;
      PromptLine^.Opt := ED.Opt;
    end;
  end;

  if ED.Apply <> W then ApplyOpt := ED.Apply;
end;
}

procedure ExecOptionsPrim(Caller: PView);
type
  TExecData = record
    Main, Setup, Opt, Apply: Word;
  end;
const
  eoLeft = $0001;
  eoRight = $0002;
  eoPrompt = $0004;
var
  B: Boolean;
  D: PDialog;
  Control: PView;
  R: TRect;
  ED: TExecData;
  S: String[15];
begin
  R.Assign(0, 0, 67, 12);
  B := TypeOf(Caller^) = TypeOf(TPromptLine);
  if B then S := 'Command line'
  else if PPanel(Caller)^.Which = pnRight then S := 'Right panel'
  else S := 'Left panel';
  D := InitSimpleDialog(R, S + ' Exec options', hcExecOptions);
  with D^ do
  begin
    Options := Options or ofCentered;
    R.Assign(3, 3, 15, 6);
    Control := MainControl(R);
    Insert(Control);
    R.Assign(2, 2, 15, 3);
    Insert(New(PLabel, Init(R, 'Main', Control)));

    R.Assign(17, 3, 40, 6);
    Control := SetupControl(R);
    Insert(Control);
    R.Assign(16, 2, 40, 3);
    Insert(New(PLabel, Init(R, 'Setup', Control)));

    R.Assign(42, 3, 64, 6);
    Control := OptionsControl(R, True);
    Insert(Control);
    R.Assign(41, 2, 64, 3);
    Insert(New(PLabel, Init(R, 'Options', Control)));

    R.Assign(12, 7, Size.X - 3, 8);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Le~f~t panel',
      NewSItem('~R~ight panel',
      NewSItem('~C~ommand line', nil)))));
    Insert(Control);
    R.Assign(2, 7, 12, 8);
    Insert(New(PLabel, Init(R, 'Apply to', Control)));

    SelectNext(True);
    SelectNext(True);
    SelectNext(True);
  end;

  if B then with PPromptLine(Caller)^ do
  begin
    ED.Main := Main;
    ED.Setup := Setup;
    ED.Opt := Opt;
    ED.Apply := eoPrompt;
  end
  else with PPanel(Caller)^ do
  begin
    ED.Main := Main;
    ED.Setup := Setup;
    ED.Opt := Opt;
    if Which = pnRight then ED.Apply := eoRight
    else ED.Apply := eoLeft;
  end;

  if Application^.ExecuteDialog(D, @ED, False) = cmCancel then Exit;

  with PPanelWindow(Caller^.Owner)^ do
  begin
    if ED.Apply and eoLeft <> 0 then
    begin
      LeftPanel^.Main := ED.Main;
      LeftPanel^.Setup := ED.Setup;
      LeftPanel^.Opt := ED.Opt;
    end;
    if ED.Apply and eoRight <> 0 then
    begin
      RightPanel^.Main := ED.Main;
      RightPanel^.Setup := ED.Setup;
      RightPanel^.Opt := ED.Opt;
    end;
    if ED.Apply and eoPrompt <> 0 then
    begin
      PromptLine^.Main := ED.Main;
      PromptLine^.Setup := ED.Setup;
      PromptLine^.Opt := ED.Opt;
    end;
  end;
end;

procedure GetExecHistStr(var S: String; const Title: TTitleStr;
  FocusFirst, Topmost: Boolean);
var
  C: Word;
  W: PHistoryWindow;
  R: TRect;
begin
  S := '';
  GetHistWinBounds(FPromptHistoryID, Title, R);
  W := New(PHistWindow, Init(R, FPromptHistoryID));
  DisposeStr(W^.Title);
  W^.Title := NewStr(Title);
  W^.Options := W^.Options or ofCentered;
  W^.HelpCtx := hcPromptHistory;
  if Application^.ValidView(W) <> nil then
  begin
    if FocusFirst then W^.Viewer^.FocusItem(0);
    if Topmost then C := Application^.ExecView(W)
    else C := Desktop^.ExecView(W);
    if C = cmOk then S := W^.GetSelection;
    Dispose(W, Done);
  end;
end;

procedure GetHistoryStrPrim(ThePrompt: PPromptLine);
var
  S: String;
begin
  with ThePrompt^ do
  begin
    HistoryAdd(FPromptHistoryID, Data^, True);
    GetExecHistStr(S, 'Exec history', Trim(Data^) = '', False);
    if S <> '' then
    begin
      if Byte(S[0]) > MaxLen then S[0] := Char(MaxLen);
      SetData(S);
    end;
  end;
end;

procedure PromptPopupPrim(AnOrigin: TPoint);
var
  W1, W2: Word;
  S: String[10];
begin
  if MultitaskerDetected then
  begin
    S := 'MS Windows';
    W1 := hcECopyToWinClip;
    W2 := hcEPasteFromWinClip;
  end
  else
  begin
    S := 'additional';
    W1 := hcECopyToAddClip;
    W2 := hcEPasteFromAddClip;
  end;
  ShowPopup(AnOrigin, NewMenu(
    NewItem('~D~elete', 'Del', kbDel, cmDeleteItem, hcEClear,
    NewItem('Cu~t~', 'Shift+Del', kbShiftDel, cmCut, hcECut,
    NewItem('~C~opy', 'Ctrl+Ins', kbCtrlIns, cmCopy, hcECopy,
    NewItem('~P~aste', 'Shift+Ins', kbShiftIns, cmPaste, hcEPaste,
    NewItem('C~l~ear', 'Ctrl+Del', kbCtrlDel, cmClear, hcEClear,
    NewLine(
    NewItem('Cop~y~ to ' + S + ' Clipboard', 'Ctrl+F12', kbCtrlF12, cmCopyToMT, W1,
    NewItem('Paste fr~o~m ' + S + ' Clipboard', 'Shift+F12', kbShiftF12, cmPasteFromMT, W2,
    NewLine(
    NewItem('Panels o~n~/off', 'Ctrl+O', kbNoKey, cmTogglePanels, hcTogglePanels,
    NewItem('L~e~ft panel on/off', 'Ctrl+F1', kbCtrlF1, cmToggleLeftPanel, hcTogglePanels,
    NewItem('R~i~ght panel on/off', 'Ctrl+F2', kbCtrlF2, cmToggleRightPanel, hcTogglePanels,
    NewLine(
    NewItem('E~x~ec options...', 'Alt+Y', kbAltY, cmExecOptions, hcExecOptions,
    NewItem('~H~istory...', 'Down', kbDown, cmPromptHistory, hcPromptHistory,
      nil)))))))))))))))));
end;

procedure SaveFocusedNamePrim(FManager: PPanel);
var
  S: FNameStr;
begin
  with FManager^ do
  begin
    if (List^.Count = 0) or (Status >= stTree) or
       (Options and ofValidate <> 0) or InArchive then Exit;
    GetItemStr(Focused, S);
    HistoryAdd(DirHistoryID, S + #32#25#255, True);
  end;
end;

procedure GetDirHistStr(var S: String; const Title: TTitleStr;
  FocusFirst, Topmost: Boolean);
var
  C: Word;
  W: PHistoryWindow;
  R: TRect;
begin
  S := '';
  GetHistWinBounds(DirHistoryID, Title, R);
  W := New(PQuickDirHistory, Init(R, DirHistoryID));
  DisposeStr(W^.Title);
  W^.Title := NewStr(Title);
  W^.Options := W^.Options or ofCentered;
  if Application^.ValidView(W) <> nil then
  begin
    if FocusFirst then W^.Viewer^.FocusItem(0);
    if Topmost then C := Application^.ExecView(W)
    else C := Desktop^.ExecView(W);
    if C = cmOk then S := ClearedSlash(W^.GetSelection);
    Dispose(W, Done);
  end;
end;

procedure SwitchToHistoryDirPrim(FManager: PPanel; S: String);
var
  I: Integer;
begin
  if S <> '' then with FManager^ do
  begin
    if S[Length(S)] = #255 then
    begin
      Dec(S[0], 3);
      if (Status <> stTree) or
	 (CompUCString(RootName(S), RootName(ListDir^)) <> Equal) then
	SwitchToDir(JustPathName(S), False);
      if Status <> stTree then GetItemNum(S, I)
      else GetItemNum(ClearedSlash(JustPathName(S)), I);
    end
    else
    begin
      S := CNFileName(S);
      if (Status <> stTree) or
	 (CompUCString(RootName(S), RootName(ListDir^)) <> Equal) then
	SwitchToDir(AddedSlash(S), False);
      if Status <> stTree then I := 0 else GetItemNum(S, I);
    end;
    FocusItem(I);
  end;
end;

procedure DirHistoryPrim(FManager: PPanel);
var
  I: Integer;
  S: String;
begin
  with FManager^ do
  begin
    HistoryAdd(DirHistoryID, ListDir^, True);
    GetDirHistStr(S, 'Panel history', False, False);
    SwitchToHistoryDirPrim(FManager, S);
  end;
end;

procedure AltNumpadHistoryPrim(FManager: PPanel; Code: Byte);
var
  I: Integer;
  P: PHistoryRec;
begin
  with FManager^ do
  begin
    I := HistoryLockIndex(DirHistoryId, Code);
    if I = -1 then Exit;
    P := HistoryRec(DirHistoryId, I);
    if P = nil then Exit;
    HistoryAdd(DirHistoryID, ListDir^, True);
    SwitchToHistoryDirPrim(FManager, P^.StrPtr^);
  end;
end;

procedure AltCtrlPgUpHistoryPrim(FManager: PPanel; Down: Boolean);
var
  I: Integer;
  P: PHistoryRec;
begin
  with FManager^ do
  begin
    I := AltHistoryIndex;
    if Down then if I = 0 then Exit else Dec(I)
    else if I >= HistoryCount(DirHistoryId) - 1 then Exit else Inc(I);
    P := HistoryRec(DirHistoryId, I);
    if P <> nil then SwitchToHistoryDirPrim(FManager, P^.StrPtr^);
    AltHistoryIndex := I;
  end;
end;

procedure PopupPrim(FManager: PPanel; AnOrigin: TPoint);
var
  YesOrNo: Array[False..True] of String[3];
  Mark: Array[False..True] of Char;

function ArcSubMenu(Next: PMenuItem): PMenuItem;
begin
  ArcSubMenu := NewToggleSubMenu('A~r~chivers', hcArchivers, NewMenu(
    NewItem(Mark[ArcFlags and afArc = 0] + ' ' + ArchiveTradeMark(avArc), '', kbNoKey, cmArc, hcArchivers,
    NewItem(Mark[ArcFlags and afArj = 0] + ' ' + ArchiveTradeMark(avArj), '', kbNoKey, cmArj, hcArchivers,
    NewItem(Mark[ArcFlags and afChz = 0] + ' ' + ArchiveTradeMark(avChz), '', kbNoKey, cmChz, hcArchivers,
    NewItem(Mark[ArcFlags and afHa  = 0] + ' ' + ArchiveTradeMark(avHa), '', kbNoKey, cmHa, hcArchivers,
    NewItem(Mark[ArcFlags and afLha = 0] + ' ' + ArchiveTradeMark(avLzh), '', kbNoKey, cmLzh, hcArchivers,
    NewItem(Mark[ArcFlags and afLim = 0] + ' ' + ArchiveTradeMark(avLim), '', kbNoKey, cmLim, hcArchivers,
    NewItem(Mark[ArcFlags and afPak = 0] + ' ' + ArchiveTradeMark(avPak), '', kbNoKey, cmPak, hcArchivers,
    NewItem(Mark[ArcFlags and afRar = 0] + ' ' + ArchiveTradeMark(avRar), '', kbNoKey, cmRar, hcArchivers,
    NewItem(Mark[ArcFlags and afZip = 0] + ' ' + ArchiveTradeMark(avZip), '', kbNoKey, cmZip, hcArchivers,
    NewItem(Mark[ArcFlags and afZoo = 0] + ' ' + ArchiveTradeMark(avZoo), '', kbNoKey, cmZoo, hcArchivers,
    NewLine(
    NewItem(Mark[ArcFlags and afZiW = 0] + ' ' + ArchiveTradeMark(avZiW), '', kbNoKey, cmZiW, hcArchivers,
    NewItem(Mark[ArcFlags and afArW = 0] + ' ' + ArchiveTradeMark(avArW), '', kbNoKey, cmArW, hcArchivers,
    NewItem(Mark[ArcFlags and afRaW = 0] + ' ' + ArchiveTradeMark(avRaW), '', kbNoKey, cmRaW, hcArchivers,
      nil))))))))))))))), Next, @ArcFlags);
end;

function MiscSubMenu(Next: PMenuItem): PMenuItem;
begin
  MiscSubMenu := NewSubMenu('~M~iscellaneous', hcFMisc, NewMenu(
    NewItem('E~x~ec options...', 'Alt+Y', kbAltY, cmExecOptions, hcExecOptions,
    NewItem('~A~ssociate...', 'Ctrl+X', kbNoKey, cmExtensions, hcAssociate,
    NewItem('~V~iewers...', 'Ctrl+V', kbNoKey, cmViewers, hcViewers,
    ArcSubMenu(
    NewItem('~U~ser defined archivers...', '', kbNoKey, cmUserArchivers, hcUserArchivers,
    NewItem('Copy~/~move to archive...', 'Shift+F1', kbNoKey, cmArcCopyDlg, hcArcCopyDlg,
    NewItem('~O~pen archive', 'Alt+A', kbNoKey, cmOpenArchive, hcOpenArchive,
    NewItem('Read ~f~ile list', 'Alt+V', kbNoKey, cmReadFileList, hcReadFileList,
    NewItem('~W~rite name to history', 'Alt+H', kbNoKey, cmSaveFocusedName, hcSaveFocusedName,
    NewItem('Panel histor~y~...', 'Ctrl+W', kbNoKey, cmDirHistory, hcPanelHistory,
    NewItem('~C~lear selection list', 'Shift+Gray Minus', kbNoKey, cmClearSelection, hcClearSelection,
    NewLine(
    NewItem('Panel se~t~tings...', 'Alt+K', kbNoKey, cmPanelSettings, hcPanelSettings,
    NewItem('~M~ini status                  Ctrl+K', YesOrNo[FManager^.State and sfMiniStatus <> 0],
      kbNoKey, cmToggleMiniStatus, hcMiniStatus,
    NewItem('Enab~l~e selection info box     Alt+"', YesOrNo[FManager^.Settings and seSepSelInfo <> 0],
      kbNoKey, cmSepSelInfo, hcSepSelInfo,
    NewItem('Display Driv~e~ selector        Alt+J', YesOrNo[FManager^.Settings and seDriveSelector <> 0],
      kbNoKey, cmDriveSelector, hcDriveSelector,
    NewItem('Show ~h~idden files            Ctrl+H', YesOrNo[FManager^.State and sfShowHidden <> 0],
      kbNoKey, cmToggleHidden, hcShowHiddenFiles,
    NewItem('~D~isplay executable only      Ctrl+Z', YesOrNo[FManager^.State and sfExOnly <> 0],
      kbNoKey, cmToggleExOnly, hcExOnly,
    NewItem('Di~s~play directory sizes  Ctrl+Minus', YesOrNo[FManager^.Settings and seCalcDirSize <> 0],
      kbNoKey, cmCalcDirSize, hcCalcDirSize,
    NewItem('Unfold su~b~directories         Alt+B', YesOrNo[FManager^.Settings and seUnfold <> 0],
      kbNoKey, cmToggleUnfold, hcUnfold,
    NewItem('Show file descri~p~tions       Ctrl+P', YesOrNo[FManager^.Options and ofFilesBBS <> 0],
      kbNoKey, cmFilesBBS, hcFilesBBS,
    NewItem('~I~gnore selection              Alt+I', YesOrNo[FManager^.Settings and seIgnoreSelection <> 0],
      kbNoKey, cmIgnoreSelection, hcIgnoreSelection,
       nil))))))))))))))))))))))), Next);
end;

begin
{ Added 2005.11.18 }
  if GetShiftState and (kbAltShift + kbCtrlShift) =
    kbAltShift + kbCtrlShift then
  begin
    Pending.What := evCommand;
    Pending.Command := cmCopy;
    Exit;
  end;

  YesOrNo[False] := ' No';
  YesOrNo[True] := 'Yes';
  Mark[False] := ' ';
  Mark[True] := 'û';
  with FManager^ do
  begin
    ShowPopup(AnOrigin, NewMenu(
      NewItem(Mark[Status = stBrief] + ' ~B~rief', 'Ctrl+B', kbNoKey, cmBrief, hcBrief,
      NewItem(Mark[Status = stFull] + ' ~F~ull', 'Ctrl+F', kbNoKey, cmFull, hcFull,
      NewItem(Mark[Status = stTree] + ' ~T~ree', 'Ctrl+T', kbNoKey, cmTree, hcTree,
      NewItem(Mark[Status = stInfo] + ' ~I~nfo', 'Ctrl+I', kbNoKey, cmInfo, hcInfo,
      NewItem(Mark[Status = stQuickView] + ' ~Q~uick view', 'Ctrl+^', kbNoKey, cmQuickView, hcQuickView,
      NewItem(Mark[Status = stQuickDescr] + ' Descri~p~tion', 'Ctrl+D', kbNoKey, cmQuickDescr, hcQuickDescr,
      NewLine(
      NewItem('Select ~g~roup...', 'Gray +', kbGrayPlus, cmSelectGroup, hcSelectGroup,
      NewItem('~U~nselect group...', 'Gray -', kbGrayMinus, cmUnselectGroup, hcUnselectGroup,
      NewItem('In~v~ert selection', 'Gray *', kbGrayMul, cmInvert, hcToggleSelected,
      NewItem('Rest~o~re selection', 'Alt+Back', kbAltBack, cmRestoreSelection, hcRestoreSelection,
      NewLine(
      MiscSubMenu(
      NewLine(
      NewItem('Fi~n~d file...', 'Alt+F7', kbAltF7, cmFindFileDlg, hcFindFile,
      NewItem('~S~ort and display...', 'Ctrl+S', kbNoKey, cmFSort, hcSort,
      NewItem('Filt~e~r...', 'Ctrl+N', kbNoKey, cmFilter, hcFilter,
      NewItem('~R~e-read', 'Ctrl+R', kbNoKey, cmReRead, hcReRead,
      NewItem('S~w~ap panels', 'Ctrl+U', kbNoKey, cmSwapPanels, hcSwapPanels,
      NewItem('File ~a~ttributes...', 'Ctrl+A', kbNoKey, cmFAttributes, hcFileAttributes,
      NewItem('~C~ompare directories', 'Ctrl+C', kbNoKey, cmCompareDirs, hcCompareDirectories,
      NewItem('~D~rive...', 'Alt+F' + Char(Which + $31), kbAltF1 + $100 * Which, cmSelectLeftDrive + Which, hcDrive,
        nil))))))))))))))))))))))));
  end;
end;

procedure SetColumnWidthPrim(FManager: PPanel; AWidth: Integer);
begin
  with FManager^ do
  begin
    if AWidth < MinPanelWidth then AWidth := MinPanelWidth
    else if AWidth >= Size.X then AWidth := Size.X - 1;
    ColWidth := AWidth;
{
    if Status = stBrief then
      if ColWidth = 13 then
        Settings := Settings and not seLongNames
      else Settings := Settings or seLongNames;
}
    SetColumns;
    DrawView;
    PWindow(Owner)^.Frame^.DrawView;
  end;
end;

procedure DragColumnsPrim(FManager: PPanel; Event: TEvent);
var
  N, W, X: Integer;
  Mouse: TPoint;
begin
  with FManager^ do
  begin
    MakeLocal(Event.Where, Mouse);
    X := Mouse.X;
    N := (X + 1) div ColWidth;
    if N <= 0 then N := 1;
    repeat
      MakeLocal(Event.Where, Mouse);
      if Mouse.X <> X then
      begin
        X := Mouse.X;
        if X < 0 then X := 0;
        W := (X + 1) div N;
        if W <> ColWidth then SetColumnWidthPrim(FManager, W);
      end;
    until not MouseEvent(Event, evMouseMove + evMouseAuto);
    Event.What := evNothing;
  end;
end;

procedure DragPanelsPrim(PanelWindow: PPanelWindow; Event: TEvent;
  Mode: Byte; var Limits: TRect; MinSize, MaxSize: TPoint);
var
  SaveColWidth: Byte;
  P, S, SaveWhere: TPoint;
  SaveBounds, SaveLeft, SaveRight: TRect;

function Min(I, J: Integer): Integer;
begin
  if I < J then Min := I else Min := J;
end;

function Max(I, J: Integer): Integer;
begin
  if I > J then Max := I else Max := J;
end;

procedure MoveGrow(P, S: TPoint);
var
  R: TRect;
begin
  S.X := Min(Max(S.X, MinSize.X), MaxSize.X);
  S.Y := Min(Max(S.Y, MinSize.Y), MaxSize.Y);
  P.X := Min(Max(P.X, Limits.A.X - S.X + 1), Limits.B.X - 1);
  P.Y := Min(Max(P.Y, Limits.A.Y - S.Y + 1), Limits.B.Y - 1);
  if Mode and dmLimitLoX <> 0 then P.X := Max(P.X, Limits.A.X);
  if Mode and dmLimitLoY <> 0 then P.Y := Max(P.Y, Limits.A.Y);
  if Mode and dmLimitHiX <> 0 then P.X := Min(P.X, Limits.B.X - S.X);
  if Mode and dmLimitHiY <> 0 then P.Y := Min(P.Y, Limits.B.Y - S.Y);
  if Mode = dmMouseResize then
    R.Assign(PanelWindow^.Origin.X, P.Y,
      PanelWindow^.Origin.X + PanelWindow^.Size.X, P.Y + S.Y)
  else R.Assign(P.X, P.Y, P.X + S.X, P.Y + S.Y);
  PanelWindow^.Locate(R);
end;

procedure Change(DX, DY: Integer);
begin
  if (Mode and dmDragMove <> 0) and (GetShiftState and $03 = 0) then
  begin
    Inc(P.X, DX);
    Inc(P.Y, DY);
  end else
  if (Mode and dmDragGrow <> 0) and (GetShiftState and $03 <> 0) then
  begin
    Inc(S.X, DX);
    Inc(S.Y, DY);
  end;
end;

procedure Update(X, Y: Integer);
begin
  if Mode and dmDragMove <> 0 then
  begin
    P.X := X;
    P.Y := Y;
  end;
end;

procedure ResizePanels(DeltaX, DeltaY: Integer);
var
  R: TRect;
begin
  with PanelWindow^ do
  begin
    if DeltaX < 0 then
      if (LeftPanel^.Size.X + DeltaX < MinPanelWidth) or
         (RightPanel^.Size.X - DeltaX > Size.X - 8) then Exit else
    else
      if (LeftPanel^.Size.X + DeltaX > Size.X - 8) or
         (RightPanel^.Size.X - DeltaX < MinPanelWidth) then Exit;
    if ((DeltaY < 0) and
        (LeftPanel^.Size.Y + DeltaY < MinPanelHeight)) or
       ((DeltaY > 0) and
        (LeftPanel^.Size.Y + DeltaY > Size.Y - 3)) then Exit;
    Owner^.Lock;
    LeftPanel^.GetBounds(R);
    Inc(R.B.X, DeltaX);
    Inc(R.B.Y, DeltaY);
    LeftPanel^.Locate(R);
    RightPanel^.GetBounds(R);
    Inc(R.A.X, DeltaX);
    Inc(R.B.Y, DeltaY);
    RightPanel^.Locate(R);
    Frame^.DrawView;
    LeftPanelSize := 0;
    Owner^.Unlock;
  end;
end;

procedure ResizeColumns(DeltaX: Integer);
begin
  with PanelWindow^.CurrentPanel^ do
    if (Status = stBrief) or
       ((Status = stFull) and (Settings and seLongNames = 0)) then
      SetColumnWidthPrim(PanelWindow^.CurrentPanel, ColWidth + DeltaX);
end;

begin
{ Added 2005.11.18 }
  if (Event.What = evCommand) and (Event.Command = cmResize) and
     (GetShiftState and (kbAltShift + kbCtrlShift) =
       kbAltShift + kbCtrlShift) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmCopyToMT;
    Exit;
  end;

  with PanelWindow^ do
  begin
    SetState(sfDragging, True);
    GetCurrentPanel;
    SaveColWidth := CurrentPanel^.ColWidth;
    if Event.What = evMouseDown then
    begin
      if Mode = dmMouseResize then
      begin
        SaveWhere := Event.Where;
        P.X := Size.X - Event.Where.X;
        P.Y := Size.Y - Event.Where.Y;
        repeat
          ResizePanels(
            Event.Where.X - SaveWhere.X, Event.Where.Y - SaveWhere.Y);
          SaveWhere := Event.Where;
          Inc(Event.Where.X, P.X);
          Inc(Event.Where.Y, P.Y);
{
          MoveGrow(Origin, Event.Where);
}
        until not MouseEvent(Event, evMouseMove);
      end
      else if Mode and dmDragMove <> 0 then
      begin
        P.X := Origin.X - Event.Where.X;
        P.Y := Origin.Y - Event.Where.Y;
        repeat
          Inc(Event.Where.X, P.X);
          Inc(Event.Where.Y, P.Y);
          MoveGrow(Event.Where, Size);
        until not MouseEvent(Event, evMouseMove);
      end else
      begin
        P.X := Size.X - Event.Where.X;
        P.Y := Size.Y - Event.Where.Y;
        repeat
          Inc(Event.Where.X, P.X);
          Inc(Event.Where.Y, P.Y);
          MoveGrow(Origin, Event.Where);
        until not MouseEvent(Event, evMouseMove);
      end;
    end else
    begin
      GetBounds(SaveBounds);
      LeftPanel^.GetBounds(SaveLeft);
      RightPanel^.GetBounds(SaveRight);
      repeat
        P := Origin;
        S := Size;
        KeyEvent(Event);
        if Event.KeyCode = kbGrayPlus then ResizeColumns(1)
        else if Event.KeyCode = kbGrayMinus then ResizeColumns(-1)
        else if Event.KeyCode = kbGrayMul then ResizeColumns(255)
        else if Event.KeyCode = $E02F {GrayDiv} then ResizeColumns(-255)
        else case Event.KeyCode and $FF00 of
          kbLeft: Change(-1, 0);
          kbRight: Change(1, 0);
          kbUp: Change(0, -1);
          kbDown: Change(0, 1);
          kbCtrlLeft: Change(-8, 0);
          kbCtrlRight: Change(8, 0);
          kbAltLeft: ResizePanels(-1, 0);
          kbAltRight: ResizePanels(1, 0);
          kbAltUp: ResizePanels(0, -1);
          kbAltDn: ResizePanels(0, 1);
          kbHome: Update(Limits.A.X, P.Y);
          kbEnd: Update(Limits.B.X - S.X, P.Y);
          kbPgUp: Update(P.X, Limits.A.Y);
          kbPgDn: Update(P.X, Limits.B.Y - S.Y);
        end;
        MoveGrow(P, S);
      until (Event.KeyCode = kbEnter) or (Event.KeyCode = kbEsc);
      if Event.KeyCode = kbEsc then
      begin
        Owner^.Lock;
        Locate(SaveBounds);
        LeftPanel^.Locate(SaveLeft);
        RightPanel^.Locate(SaveRight);
        if CurrentPanel^.ColWidth <> SaveColWidth then
          SetColumnWidthPrim(CurrentPanel, SaveColWidth);
        Owner^.Unlock;
      end;
    end;
    SetState(sfDragging, False);
  end;
end;

procedure ZoomPrim(PanelWindow: PPanelWindow);
var
  R, LeftR, RightR: TRect;
begin
  with PanelWindow^ do
  begin
    Owner^.Lock;
    if (Longint(Size) <> Longint(Owner^.Size)) or
       (ZoomRect.B.Y - ZoomRect.A.Y > Owner^.Size.Y) then
    begin
      Owner^.GetExtent(R);
      LeftR.Copy(R);
      Inc(LeftR.A.X); LeftR.B.X := LeftR.A.X + Owner^.Size.X div 2 - 2;
      Inc(LeftR.A.Y); LeftR.B.Y := LeftR.A.Y + Owner^.Size.Y - 3;
      RightR.Copy(LeftR);
      RightR.Move(Owner^.Size.X div 2, 0);
    end
    else
    begin
      R.Copy(ZoomRect);
      LeftR.Copy(LeftZoomRect);
      RightR.Copy(RightZoomRect);
    end;
    GetBounds(ZoomRect);
    LeftPanel^.GetBounds(LeftZoomRect);
    RightPanel^.GetBounds(RightZoomRect);
    Locate(R);
    GetExtent(R); R.A.Y := R.B.Y - 1; Inc(R.A.X, Length(Prompt^.Text^));
    PromptLine^.Locate(R);
    LeftPanel^.Locate(LeftR);
    RightPanel^.Locate(RightR);
    GetExtent(R); Dec(R.B.Y);
    Frame^.Locate(R);
    LeftPanelSize := 0;
    DoneMemory;
    Application^.Redraw;
    Owner^.Unlock;
  end;
end;

procedure TogglePanelPrim(PanelWindow: PPanelWindow; APanel: PPanel;
  ByWhat: Byte);
var
  Hidden, Selected: Boolean;
  Mask: Byte;
  P: PDriveSelector;
begin
  with PanelWindow^ do
  begin
    Hidden := APanel^.State and sfVisible = 0;
    Selected := not Hidden and (APanel^.State and sfSelected <> 0);
    Mask := APanel^.ToggleMask;
    if APanel^.Which = pnLeft then P := PDriveSelector(LeftSelector)
    else P := PDriveSelector(RightSelector);
    Owner^.Lock;
    if P <> nil then P^.SetState(sfVisible, Hidden);
    APanel^.Options := APanel^.Options and not ofSelectable;
    APanel^.SetState(sfVisible, Hidden);
    APanel^.Options := APanel^.Options or ofSelectable;
    Hidden := APanel^.State and sfVisible = 0;
    if not Hidden and (Mask and tmSel <> 0) then APanel^.Select
    else if Hidden then
    begin
      if Selected then APanel^.ToggleMask := ByWhat + tmSel
      else APanel^.ToggleMask := ByWhat;
      if APanel^.Opposite^.State and sfVisible = 0 then
        PromptLine^.Select
      else if PromptLine^.State and sfSelected = 0 then
        APanel^.Opposite^.Select;
    end;
    Frame^.DrawView;
    Owner^.Unlock;
  end;
end;

procedure ToggleBothPanelsPrim(PanelWindow: PPanelWindow);
var
  Left, Right, Both: Byte;
begin
  with PanelWindow^ do
  begin
    Left := LeftPanel^.ToggleMask;
    Right := RightPanel^.ToggleMask;
    Both := Byte(Left = tmVis) + Byte(Right = tmVis) shl 1;
    Owner^.Lock;
    case Both of
      0:
        begin
          if (Left and tmByO <> 0) or (Right and tmByO = 0) then
            TogglePanelPrim(PanelWindow, LeftPanel, tmVis);
          if (Right and tmByO <> 0) or (Left and tmByO = 0) then
            TogglePanelPrim(PanelWindow, RightPanel, tmVis);
        end;
      1: TogglePanelPrim(PanelWindow, LeftPanel, tmByO);
      2: TogglePanelPrim(PanelWindow, RightPanel, tmByO);
      3:
        begin
          GetCurrentPanel;
          TogglePanelPrim(PanelWindow, CurrentPanel^.Opposite, tmByO);
          TogglePanelPrim(PanelWindow, CurrentPanel, tmByO);
        end;
    end;
    Owner^.Unlock;
  end;
end;

end.