{$A+,B-,D-,E+,F+,G-,I-,L-,N+,O+,P-,Q-,R-,S-,T-,V-,X+,Y-}
uses
  Objects, Views, Menus, Dialogs, App, RMenus, Options, StrCol, StatWin,
  CNInputs, ColorSel, CColors, Calc, About, ASCIITab, Overlay, AllTypes,
  FindDlg, ErrMsgs, CPUWin, CodeWin, DumpWin, MapWin, OutWin, WatchWin,
  Desktops, FEditor, Swaps, ClipBrd, Alarm, Spooler, SpoolDlg, DialDlg,
  RegExDlg, Exploder, CmntList, Terminal, CDPlayer, HeapUMB;

{$O About}
{$O AddrDlg}
{$O Alarm}
{$O ApAbsPcl}
{$O ApAscii}
{$O ApBPlus}
{$O ApCom}
{$O ApDigi14}
{$O ApFossil}
{$O ApInt14}
{$O ApKermit}
{$O ApMisc}
{$O ApXmodem}
{$O ApYmodem}
{$O ApZmodem}
{$O ArcDlg}
{$O Archives}
{$O ArcRec}
{$O ArcV}
{$O ASCIITab}
{$O AsynPrim}
{$O BarWin}
{$O BBSStuff}
{$O Bounds}
{$O Calc}
{$O Calendar}
{$O CColors}
{$O CDCtl}
{$O CDPlayer}
{$O ClipBrd}
{$O ClipPrim}
{$O CNInputs}
{$O CodeWin}
{$O ColorSel}
{$O CompPrim}
{$O CopyScr}
{$O CPUType}
{$O CPUWin}
{$O DataBase}
{$O DataView}
{$O DBFields}
{$O DialDlg}
{$O Dialogs}
{$O DirPrim}
{$O DirTree}
{$O Disasm}
{$O DiskBase}
{$O DiskPrim}
{$O Disks}
{$O DragDrop}
{$O DumpWin}
{$O EditBlk}
{$O EditChk}
{$O EditClip}
{$O EditCmnd}
{$O EditConv}
{$O EditDrag}
{$O EditFile}
{$O EditFind}
{$O EditGo}
{$O EditJust}
{$O EditMisc}
{$O EditMsg}
{$O EditPop}
{$O EditPrim}
{$O EditTabl}
{$O EditUndo}
{$O EditUpdt}
{$O EditWrap}
{$O ExecMenu}
{$O ExecPrim}
{$O ExeView}
{$O ExtList}
{$O FileMngr}
{$O Filters}
{$O FindDlg}
{$O FindFile}
{$O FMAbort}
{$O FMAction}
{$O FMBBS}
{$O FMClip}
{$O FMDialog}
{$O FMDrag}
{$O FMDrvSel}
{$O FMInfo}
{$O FMList}
{$O FMPrim}
{$O FMQuickV}
{$O FMSecond}
{$O FMShift}
{$O FMWork}
{$O Funcs}
{$O GetID}
{$O HEditor}
{$O HelpFile}
{$O HelpFind}
{$O HexView}
{$O HistList}
{$O HistWin}
{$O HotKeys}
{$O Icons}
{$O LongView}
{$O MacroDlg}
{$O MapWin}
{$O MenuBox}
{$O MsgBox}
{$O MsgWin}
{$O MSortP}
{$O NexViews}
{$O OpenHelp}
{$O OpenPrim}
{$O Options}
{$O OutWin}
{$O PanelRec}
{$O Phones}
{$O PopUps}
{$O Procs}
{$O ProgList}
{$O ProtPrim}
{$O RegExDlg}
{$O RegExp}
{$O RevPos}
{$O RGBDlg}
{$O ScrPrim}
{$O Snipper}
{$O SpellChk}
{$O SpoolDlg}
{$O Spooler}
{$O StatWin}
{$O StdDlg}
{$O StrCalc}
{$O StrCol}
{$O StrFiles}
{$O Strings}
{$O StrWrap}
{$O SysInfo}
{$O TermComp}
{$O Terminal}
{$O TermProc}
{$O TextRead}
{$O TileAr}
{$O TilePrim}
{$O TPDate}
{$O TreeDlg}
{$O Trees}
{$O TxtView}
{$O UnAsm}
{$O UnixMask}
{$O VExplode}
{$O ViewFind}
{$O ViewPop}
{$O WatchWin}
{$O WinIcons}

var
  MyApp: TApplication;
  F: PResourceFile;
  S: PStream;

procedure InitRSR;
begin
  S := New(PDosStream, Init('C:\CNSRC\EXE\CONNECT.RES', stCreate));
  if S^.Status <> stOk then
  begin
    Dispose(S, Done);
    Writeln('Error ', S^.Status, ' creating resource file.');
    Halt(1);
  end;
  F := New(PResourceFile, Init(S));
end;

procedure DoneRSR;
begin
  Dispose(F, Done);
end;

procedure RegisterRSR;
begin
  RegisterType(RStrListMaker);
  RegisterRMenus;
  RegisterAllTypes;
end;

procedure AddRSR;
begin
  RSRStatusLine(F);
  RSRMenuBar(F);
  RSRColors(F);
  RSRCalculator(F);
  RSRAboutDialog(F);
  RSRASCIITab(F);
  RSRFindDialog(F);
  RSRReplaceDialog(F);
  RSRPrinterDialog(F);
  RSRSetupDialog(F);
  RSRConfirmDialog(F);
  RSREditOptionsDialog(F);
  RSREditorKeysDialog(F);
  RSRFMFilesDialog(F);
  RSRFMKeysDialog(F);
  RSRFMOptionsDialog(F);
  RSRFMCopyOptionsDialog(F);
  RSRUserOptionsDialog(F);
  RSRLogOptionsDialog(F);
  RSROvrDialog(F);
  RSRCDPlayer(F);
  RSRCDOptionsDialog(F);
  RSRModeDialog(F);
  RSRAlarmDialog(F);
  RSRSpoolerDialog(F);
  RSRDialDialog(F);
  RSRExplodeDialog(F);
  RSRRegExpDialog(F);
  RSRCPUWindow(F);
  RSRCodeWindow(F);
  RSRDumpWindow(F);
  RSRMapWindow(F);
  RSROutputWindow(F);
  RSRWatchWindow(F);
  RSRClipWindow(F);
  RSRTerminalWindow(F);
  RSRStatusWindow(F);
  RSRHints(F);
  RSRCompilerErrors(F);
  RSRRunErrors(F);
  RSRAsyncErrors(F);
end;

begin
  OvrInit('C:\CNSRC\EXE\RESOURCE.OVR');
  OvrSetBuf(105000);
{  InitUMBHeap;}
  RegisterRSR;
  CreatingResource := True;
  MyApp.Init;
  InitClipboard('RESOURCE.$$$');
  InitComments('C:\CNSRC\EXE\CONNECT.CMT');
  TheSpooler := New(PSpooler, Init(1, 1));
  InitRSR;
  AddRSR;
  Dispose(TheSpooler, Done);
  DoneComments;
  DoneClipboard(False, True);
  MyApp.Done;
  DoneRSR;
end.