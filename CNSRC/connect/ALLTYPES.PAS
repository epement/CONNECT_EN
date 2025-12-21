{$F-,O-}
unit AllTypes;

interface

procedure RegisterAllTypes;

implementation

uses Objects, Views, WinIcons, Dialogs,
  About, Alarm, ASCIITab, BarWin, Calc, Calendar, CDPlayer, ClipBrd,
  CNInputs, CodeWin, ColorSel, CPUWin, DataView, Date, DirTree, DumpWin,
  FEditor, FileMngr, FMBars, FindDlg, FindFile, FMDrvSel, HEditor, HelpFile,
  HexView, Icons, LongView, MacroDlg, Macros, MapWin, MsgWin, OutWin,
  Phones, ProgList, SpoolDlg, DialDlg, RegExDlg, Exploder, StatWin, StrCol,
  Swaps, Tags, Terminal, TxtView, WatchWin, HTMLView;

const
  RView: TStreamRec = (
    ObjType: 1;
    VmtLink: Ofs(TypeOf(TView)^);
    Load:    @TView.Load;
    Store:   @TView.Store
  );
  RFrame: TStreamRec = (
    ObjType: 2;
    VmtLink: Ofs(TypeOf(TFrame)^);
    Load:    @TFrame.Load;
    Store:   @TFrame.Store
  );
  RScrollBar: TStreamRec = (
    ObjType: 3;
    VmtLink: Ofs(TypeOf(TScrollBar)^);
    Load:    @TScrollBar.Load;
    Store:   @TScrollBar.Store
  );
  RScroller: TStreamRec = (
    ObjType: 4;
    VmtLink: Ofs(TypeOf(TScroller)^);
    Load:    @TScroller.Load;
    Store:   @TScroller.Store
  );
  RListViewer: TStreamRec = (
    ObjType: 5;
    VmtLink: Ofs(TypeOf(TListViewer)^);
    Load:    @TListViewer.Load;
    Store:   @TLIstViewer.Store
  );
  RGroup: TStreamRec = (
    ObjType: 6;
    VmtLink: Ofs(TypeOf(TGroup)^);
    Load:    @TGroup.Load;
    Store:   @TGroup.Store
  );
  RWindow: TStreamRec = (
    ObjType: 7;
    VmtLink: Ofs(TypeOf(TWindow)^);
    Load:    @TWindow.Load;
    Store:   @TWindow.Store
  );
  RWinIcon: TStreamRec = (
    ObjType: 8;
    VmtLink: Ofs(TypeOf(TWinIcon)^);
    Load:    @TWinIcon.Load;
    Store:   @TWinIcon.Store
  );
  RDialog: TStreamRec = (
    ObjType: 10;
    VmtLink: Ofs(TypeOf(TDialog)^);
    Load:    @TDialog.Load;
    Store:   @TDialog.Store
  );
  RInputLine: TStreamRec = (
    ObjType: 11;
    VmtLink: Ofs(TypeOf(TInputLine)^);
    Load:    @TInputLine.Load;
    Store:   @TInputLine.Store
  );
  RButton: TStreamRec = (
    ObjType: 12;
    VmtLink: Ofs(TypeOf(TButton)^);
    Load:    @TButton.Load;
    Store:   @TButton.Store
  );
  RCluster: TStreamRec = (
    ObjType: 13;
    VmtLink: Ofs(TypeOf(TCluster)^);
    Load:    @TCluster.Load;
    Store:   @TCluster.Store
  );
  RRadioButtons: TStreamRec = (
    ObjType: 14;
    VmtLink: Ofs(TypeOf(TRadioButtons)^);
    Load:    @TRadioButtons.Load;
    Store:   @TRadioButtons.Store
  );
  RCheckBoxes: TStreamRec = (
    ObjType: 15;
    VmtLink: Ofs(TypeOf(TCheckBoxes)^);
    Load:    @TCheckBoxes.Load;
    Store:   @TCheckBoxes.Store
  );
  RMultiCheckBoxes: TStreamRec = (
    ObjType: 27;
    VmtLink: Ofs(TypeOf(TMultiCheckBoxes)^);
    Load:    @TMultiCheckBoxes.Load;
    Store:   @TMultiCheckBoxes.Store
  );
  RListBox: TStreamRec = (
    ObjType: 16;
    VmtLink: Ofs(TypeOf(TListBox)^);
    Load:    @TListBox.Load;
    Store:   @TListBox.Store
  );
  RStaticText: TStreamRec = (
    ObjType: 17;
    VmtLink: Ofs(TypeOf(TStaticText)^);
    Load:    @TStaticText.Load;
    Store:   @TStaticText.Store
  );
  RLabel: TStreamRec = (
    ObjType: 18;
    VmtLink: Ofs(TypeOf(TLabel)^);
    Load:    @TLabel.Load;
    Store:   @TLabel.Store
  );
  RHistory: TStreamRec = (
    ObjType: 19;
    VmtLink: Ofs(TypeOf(THistory)^);
    Load:    @THistory.Load;
    Store:   @THistory.Store
  );
  RParamText: TStreamRec = (
    ObjType: 20;
    VmtLink: Ofs(TypeOf(TParamText)^);
    Load:    @TParamText.Load;
    Store:   @TParamText.Store
  );
  RAboutDialog: TStreamRec = (
    ObjType: 1002;
    VmtLink: Ofs(TypeOf(TAboutDialog)^);
    Load:    @TAboutDialog.Load;
    Store:   @TAboutDialog.Store
  );
  RAlarmList: TStreamRec = (
    ObjType: 1000;
    VmtLink: Ofs(TypeOf(TAlarmList)^);
    Load:    @TAlarmList.Load;
    Store:   @TAlarmList.Store
  );
  RAlarmDialog: TStreamRec = (
    ObjType: 1001;
    VmtLink: Ofs(TypeOf(TAlarmDialog)^);
    Load:    @TAlarmDialog.Load;
    Store:   @TAlarmDialog.Store
  );
  RTable: TStreamRec = (
    ObjType: 910;
    VmtLink: Ofs(TypeOf(TTable)^);
    Load:    @TTable.Load;
    Store:   @TTable.Store
  );
  RReport: TStreamRec = (
    ObjType: 911;
    VmtLink: Ofs(TypeOf(TReport)^);
    Load:    @TReport.Load;
    Store:   @TReport.Store
  );
  RASCIIChart: TStreamRec = (
    ObjType: 912;
    VmtLink: Ofs(TypeOf(TASCIIChart)^);
    Load:    @TASCIIChart.Load;
    Store:   @TASCIIChart.Store
  );
  RBarView: TStreamRec = (
    ObjType: 1003;
    VmtLink: Ofs(TypeOf(TBarView)^);
    Load:    @TBarView.Load;
    Store:   @TBarView.Store
  );
  RCDIndicator: TStreamRec = (
    ObjType: 1006;
    VmtLink: Ofs(TypeOf(TCDIndicator)^);
    Load:    @TCDIndicator.Load;
    Store:   @TCDIndicator.Store
  );
  RCDInfoPane: TStreamRec = (
    ObjType: 1007;
    VmtLink: Ofs(TypeOf(TCDInfoPane)^);
    Load:    @TCDInfoPane.Load;
    Store:   @TCDInfoPane.Store
  );
  RCDPlayer: TStreamRec = (
    ObjType: 1008;
    VmtLink: Ofs(TypeOf(TCDPlayer)^);
    Load:    @TCDPlayer.Load;
    Store:   @TCDPlayer.Store
  );
  RCalcDisplay: TStreamRec = (
    ObjType: 900;
    VmtLink: Ofs(TypeOf(TCalcDisplay)^);
    Load:    @TCalcDisplay.Load;
    Store:   @TCalcDisplay.Store
  );
  RHexDisplay: TStreamRec = (
    ObjType: 901;
    VmtLink: Ofs(TypeOf(THexDisplay)^);
    Load:    @THexDisplay.Load;
    Store:   @THexDisplay.Store
  );
  RCalcButton: TStreamRec = (
    ObjType: 902;
    VmtLink: Ofs(TypeOf(TCalcButton)^);
    Load:    @TCalcButton.Load;
    Store:   @TCalcButton.Store
  );
  RCalculator: TStreamRec = (
    ObjType: 903;
    VmtLink: Ofs(TypeOf(TCalculator)^);
    Load:    @TCalculator.Load;
    Store:   @TCalculator.Store
  );
  RCalendarView: TStreamRec = (
    ObjType: 940;
    VmtLink: Ofs(TypeOf(TCalendarView)^);
    Load:    @TCalendarView.Load;
    Store:   @TCalendarView.Store
  );
  RCalendarWindow: TStreamRec = (
    ObjType: 941;
    VmtLink: Ofs(TypeOf(TCalendarWindow)^);
    Load:    @TCalendarWindow.Load;
    Store:   @TCalendarWindow.Store
  );
  RClipEditor: TStreamRec = (
    ObjType: 1010;
    VmtLink: Ofs(TypeOf(TClipEditor)^);
    Load:    @TClipEditor.Load;
    Store:   @TClipEditor.Store
  );
  RClipWindow: TStreamRec = (
    ObjType: 1011;
    VmtLink: Ofs(TypeOf(TClipWindow)^);
    Load:    @TClipWindow.Load;
    Store:   @TClipWindow.Store
  );
  RCInputLine: TStreamRec = (
    ObjType: 1023;
    VmtLink: Ofs(TypeOf(TCInputLine)^);
    Load:    @TCInputLine.Load;
    Store:   @TCInputLine.Store
  );
  RFInputLine: TStreamRec = (
    ObjType: 1024;
    VmtLink: Ofs(TypeOf(TFInputLine)^);
    Load:    @TFInputLine.Load;
    Store:   @TFInputLine.Store
  );
  RDInputLine: TStreamRec = (
    ObjType: 1025;
    VmtLink: Ofs(TypeOf(TDInputLine)^);
    Load:    @TDInputLine.Load;
    Store:   @TDInputLine.Store
  );
  RCodeList: TStreamRec = (
    ObjType: 1062;
    VmtLink: Ofs(TypeOf(TCodeList)^);
    Load:    @TCodeList.Load;
    Store:   @TCodeList.Store
  );
  RCodeWindow: TStreamRec = (
    ObjType: 1063;
    VmtLink: Ofs(TypeOf(TCodeWindow)^);
    Load:    @TCodeWindow.Load;
    Store:   @TCodeWindow.Store
  );
  RColorSelector: TStreamRec = (
    ObjType: 21;
    VmtLink: Ofs(TypeOf(TColorSelector)^);
    Load:    @TColorSelector.Load;
    Store:   @TColorSelector.Store
  );
  RMonoSelector: TStreamRec = (
    ObjType: 22;
    VmtLink: Ofs(TypeOf(TMonoSelector)^);
    Load:    @TMonoSelector.Load;
    Store:   @TMonoSelector.Store
  );
  RColorDisplay: TStreamRec = (
    ObjType: 23;
    VmtLink: Ofs(TypeOf(TColorDisplay)^);
    Load:    @TColorDisplay.Load;
    Store:   @TColorDisplay.Store
  );
  RColorGroupList: TStreamRec = (
    ObjType: 24;
    VmtLink: Ofs(TypeOf(TColorGroupList)^);
    Load:    @TColorGroupList.Load;
    Store:   @TColorGroupList.Store
  );
  RColorItemList: TStreamRec = (
    ObjType: 25;
    VmtLink: Ofs(TypeOf(TColorItemList)^);
    Load:    @TColorItemList.Load;
    Store:   @TColorItemList.Store
  );
  RColorDialog: TStreamRec = (
    ObjType: 26;
    VmtLink: Ofs(TypeOf(TColorDialog)^);
    Load:    @TColorDialog.Load;
    Store:   @TColorDialog.Store
  );
  RSourceList: TStreamRec = (
    ObjType: 1040;
    VmtLink: Ofs(TypeOf(TSourceList)^);
    Load:    @TSourceList.Load;
    Store:   @TSourceList.Store
  );
  RRegistersList: TStreamRec = (
    ObjType: 1041;
    VmtLink: Ofs(TypeOf(TRegistersList)^);
    Load:    @TRegistersList.Load;
    Store:   @TRegistersList.Store
  );
  RFlagsList: TStreamRec = (
    ObjType: 1042;
    VmtLink: Ofs(TypeOf(TFlagsList)^);
    Load:    @TFlagsList.Load;
    Store:   @TFlagsList.Store
  );
  RMemList: TStreamRec = (
    ObjType: 1043;
    VmtLink: Ofs(TypeOf(TMemList)^);
    Load:    @TMemList.Load;
    Store:   @TMemList.Store
  );
  RStackList: TStreamRec = (
    ObjType: 1044;
    VmtLink: Ofs(TypeOf(TStackList)^);
    Load:    @TStackList.Load;
    Store:   @TStackList.Store
  );
  RCPUIndicator: TStreamRec = (
    ObjType: 1045;
    VmtLink: Ofs(TypeOf(TCPUIndicator)^);
    Load:    @TCPUIndicator.Load;
    Store:   @TCPUIndicator.Store
  );
  RCPUWindow: TStreamRec = (
    ObjType: 1047;
    VmtLink: Ofs(TypeOf(TCPUWindow)^);
    Load:    @TCPUWindow.Load;
    Store:   @TCPUWindow.Store
  );
  RDates: TStreamRec = (
    ObjType: 1050;
    VmtLink: Ofs(TypeOf(TDates)^);
    Load:    @TDates.Load;
    Store:   @TDates.Store
  );
  RTreeCollection: TStreamRec = (
    ObjType: 1055;
    VmtLink: Ofs(TypeOf(TTreeCollection)^);
    Load:    @TTreeCollection.Load;
    Store:   @TTreeCollection.Store
  );
  RDumpIndicator: TStreamRec = (
    ObjType: 1046;
    VmtLink: Ofs(TypeOf(TDumpIndicator)^);
    Load:    @TDumpIndicator.Load;
    Store:   @TDumpIndicator.Store
  );
  RDumpList: TStreamRec = (
    ObjType: 1060;
    VmtLink: Ofs(TypeOf(TDumpList)^);
    Load:    @TDumpList.Load;
    Store:   @TDumpList.Store
  );
  RDumpWindow: TStreamRec = (
    ObjType: 1061;
    VmtLink: Ofs(TypeOf(TDumpWindow)^);
    Load:    @TDumpWindow.Load;
    Store:   @TDumpWindow.Store
  );
  RIndicator: TStreamRec = (
    ObjType: 1070;
    VmtLink: Ofs(TypeOf(TIndicator)^);
    Load:    @TIndicator.Load;
    Store:   @TIndicator.Store
  );
  RFileEditor: TStreamRec = (
    ObjType: 1071;
    VmtLink: Ofs(TypeOf(TFileEditor)^);
    Load:    @TFileEditor.Load;
    Store:   @TFileEditor.Store
  );
  REditorWindow: TStreamRec = (
    ObjType: 1072;
    VmtLink: Ofs(TypeOf(TEditorWindow)^);
    Load:    @TEditorWindow.Load;
    Store:   @TEditorWindow.Store
  );
  RUndoChain: TStreamRec = (
    ObjType: 1074;
    VmtLink: Ofs(TypeOf(TUndoChain)^);
    Load:    @TUndoChain.Load;
    Store:   @TUndoChain.Store
  );
  RExplodeDialog: TStreamRec = (
    ObjType: 1076;
    VmtLink: Ofs(TypeOf(TExplodeDialog)^);
    Load:    @TExplodeDialog.Load;
    Store:   @TExplodeDialog.Store
  );
  RPrompt: TStreamRec = (
    ObjType: 1080;
    VmtLink: Ofs(TypeOf(TPrompt)^);
    Load:    @TPrompt.Load;
    Store:   @TPrompt.Store
  );
  RPromptLine: TStreamRec = (
    ObjType: 1081;
    VmtLink: Ofs(TypeOf(TPromptLine)^);
    Load:    @TPromptLine.Load;
    Store:   @TPromptLine.Store
  );
  RPanel: TStreamRec = (
    ObjType: 1082;
    VmtLink: Ofs(TypeOf(TPanel)^);
    Load:    @TPanel.Load;
    Store:   @TPanel.Store
  );
  RPanelFrame: TStreamRec = (
    ObjType: 1083;
    VmtLink: Ofs(TypeOf(TPanelFrame)^);
    Load:    @TPanelFrame.Load;
    Store:   @TPanelFrame.Store
  );
  RPanelWindow: TStreamRec = (
    ObjType: 1084;
    VmtLink: Ofs(TypeOf(TPanelWindow)^);
    Load:    @TPanelWindow.Load;
    Store:   @TPanelWindow.Store
  );
  RDragInputLine: TStreamRec = (
    ObjType: 1073;
    VmtLink: Ofs(TypeOf(TDragInputLine)^);
    Load:    @TDragInputLine.Load;
    Store:   @TDragInputLine.Store
  );
  RFindFileCollection: TStreamRec = (
    ObjType: 1085;
    VmtLink: Ofs(TypeOf(TFindFileCollection)^);
    Load:    @TFindFileCollection.Load;
    Store:   @TFindFileCollection.Store
  );
  RTagList: TStreamRec = (
    ObjType: 1086;
    VmtLink: Ofs(TypeOf(TTagList)^);
    Load:    @TTagList.Load;
    Store:   @TTagList.Store
  );
  RDriveSelector: TStreamRec = (
    ObjType: 1087;
    VmtLink: Ofs(TypeOf(TDriveSelector)^);
    Load:    @TDriveSelector.Load;
    Store:   @TDriveSelector.Store
  );
  RPanelBar: TStreamRec = (
    ObjType: 1088;
    VmtLink: Ofs(TypeOf(TPanelBar)^);
    Load:    @TPanelBar.Load;
    Store:   @TPanelBar.Store
  );
  RHexIndicator: TStreamRec = (
    ObjType: 1090;
    VmtLink: Ofs(TypeOf(THexIndicator)^);
    Load:    @THexIndicator.Load;
    Store:   @THexIndicator.Store
  );
  RHexEditor: TStreamRec = (
    ObjType: 1091;
    VmtLink: Ofs(TypeOf(THexEditor)^);
    Load:    @THexEditor.Load;
    Store:   @THexEditor.Store
  );
  RHexEditorWindow: TStreamRec = (
    ObjType: 1092;
    VmtLink: Ofs(TypeOf(THexEditorWindow)^);
    Load:    @THexEditorWindow.Load;
    Store:   @THexEditorWindow.Store
  );
  RHelpTopic: TStreamRec = (
    ObjType: 10000;
    VmtLink: Ofs(TypeOf(THelpTopic)^);
    Load:    Addr(THelpTopic.Load);
    Store:   {Addr(THelpTopic.Store)} nil
  );
  RHelpIndex: TStreamRec = (
    ObjType: 10001;
    VmtLink: Ofs(TypeOf(THelpIndex)^);
    Load:    Addr(THelpIndex.Load);
    Store:   {Addr(THelpIndex.Store)} nil
  );
  RHelpViewer: TStreamRec = (
    ObjType: 10002;
    VmtLink: Ofs(TypeOf(THelpViewer)^);
    Load:    Addr(THelpViewer.Load);
    Store:   Addr(THelpViewer.Store)
  );
  RHelpWindow: TStreamRec = (
    ObjType: 10003;
    VmtLink: Ofs(TypeOf(THelpWindow)^);
    Load:    Addr(THelpWindow.Load);
    Store:   Addr(THelpWindow.Store)
  );
  RIcon: TStreamRec = (
    ObjType: 1110;
    VmtLink: Ofs(TypeOf(TIcon)^);
    Load:    @TIcon.Load;
    Store:   @TIcon.Store
  );
  RHTMLList: TStreamRec = (
    ObjType: 1111;
    VmtLink: Ofs(TypeOf(THTMLList)^);
    Load:    @THTMLList.Load;
    Store:   @THTMLList.Store
  );
  RHTMLIndicator: TStreamRec = (
    ObjType: 1112;
    VmtLink: Ofs(TypeOf(THTMLIndicator)^);
    Load:    @THTMLIndicator.Load;
    Store:   @THTMLIndicator.Store
  );
  RHTMLTitle: TStreamRec = (
    ObjType: 1113;
    VmtLink: Ofs(TypeOf(THTMLTitle)^);
    Load:    @THTMLTitle.Load;
    Store:   @THTMLTitle.Store
  );
  RHTMLInfo: TStreamRec = (
    ObjType: 1114;
    VmtLink: Ofs(TypeOf(THTMLInfo)^);
    Load:    @THTMLInfo.Load;
    Store:   @THTMLInfo.Store
  );
  RHTMLViewer: TStreamRec = (
    ObjType: 1115;
    VmtLink: Ofs(TypeOf(THTMLViewer)^);
    Load:    @THTMLViewer.Load;
    Store:   @THTMLViewer.Store
  );
  RHTMLWindow: TStreamRec = (
    ObjType: 1116;
    VmtLink: Ofs(TypeOf(THTMLWindow)^);
    Load:    @THTMLWindow.Load;
    Store:   @THTMLWindow.Store
  );
  RMacro: TStreamRec = (
    ObjType: 1120;
    VmtLink: Ofs(TypeOf(TMacro)^);
    Load:    @TMacro.Load;
    Store:   @TMacro.Store
  );
  REventCollection: TStreamRec = (
    ObjType: 1130;
    VmtLink: Ofs(TypeOf(TEventCollection)^);
    Load:    @TEventCollection.Load;
    Store:   @TEventCollection.Store
  );
  RMapViewer: TStreamRec = (
    ObjType: 1140;
    VmtLink: Ofs(TypeOf(TMapViewer)^);
    Load:    @TMapViewer.Load;
    Store:   @TMapViewer.Store
  );
  RMapWindow: TStreamRec = (
    ObjType: 1141;
    VmtLink: Ofs(TypeOf(TMapWindow)^);
    Load:    @TMapWindow.Load;
    Store:   @TMapWindow.Store
  );
  RMessageViewer: TStreamRec = (
    ObjType: 1150;
    VmtLink: Ofs(TypeOf(TMessageViewer)^);
    Load:    @TMessageViewer.Load;
    Store:   @TMessageViewer.Store
  );
  RMessageWindow: TStreamRec = (
    ObjType: 1151;
    VmtLink: Ofs(TypeOf(TMessageWindow)^);
    Load:    @TMessageWindow.Load;
    Store:   @TMessageWindow.Store
  );
  ROutputCollection: TStreamRec = (
    ObjType: 1160;
    VmtLink: Ofs(TypeOf(TOutputCollection)^);
    Load:    @TOutputCollection.Load;
    Store:   @TOutputCollection.Store
  );
  ROutput: TStreamRec = (
    ObjType: 1161;
    VmtLink: Ofs(TypeOf(TOutput)^);
    Load:    @TOutput.Load;
    Store:   @TOutput.Store
  );
  ROutputWindow: TStreamRec = (
    ObjType: 1162;
    VmtLink: Ofs(TypeOf(TOutputWindow)^);
    Load:    @TOutputWindow.Load;
    Store:   @TOutputWindow.Store
  );
  RExecItem: TStreamRec = (
    ObjType: 1170;
    VmtLink: Ofs(TypeOf(TExecItem)^);
    Load:    @TExecItem.Load;
    Store:   @TExecItem.Store
  );
  RPhoneEntry: TStreamRec = (
    ObjType: 1185;
    VmtLink: Ofs(TypeOf(TPhoneEntry)^);
    Load:    @TPhoneEntry.Load;
    Store:   @TPhoneEntry.Store
  );
  RSpoolerList: TStreamRec = (
    ObjType: 1190;
    VmtLink: Ofs(TypeOf(TSpoolerList)^);
    Load:    @TSpoolerList.Load;
    Store:   @TSpoolerList.Store
  );
  RSpoolerDialog: TStreamRec = (
    ObjType: 1191;
    VmtLink: Ofs(TypeOf(TSpoolerDialog)^);
    Load:    @TSpoolerDialog.Load;
    Store:   @TSpoolerDialog.Store
  );
  RDialList: TStreamRec = (
    ObjType: 1195;
    VmtLink: Ofs(TypeOf(TDialList)^);
    Load:    @TDialList.Load;
    Store:   @TDialList.Store
  );

  RDialDialog: TStreamRec = (
    ObjType: 1196;
    VmtLink: Ofs(TypeOf(TDialDialog)^);
    Load:    @TDialDialog.Load;
    Store:   @TDialDialog.Store
  );
  RStatusText: TStreamRec = (
    ObjType: 1192;
    VmtLink: Ofs(TypeOf(TStatusText)^);
    Load:    @TStatusText.Load;
    Store:   @TStatusText.Store
  );
  RLineText: TStreamRec = (
    ObjType: 1193;
    VmtLink: Ofs(TypeOf(TLineText)^);
    Load:    @TLineText.Load;
    Store:   @TLineText.Store
  );
  RStatusWindow: TStreamRec = (
    ObjType: 1194;
    VmtLink: Ofs(TypeOf(TStatusWindow)^);
    Load:    @TStatusWindow.Load;
    Store:   @TStatusWindow.Store
  );
  RStringsCollection: TStreamRec = (
    ObjType: 1200;
    VmtLink: Ofs(TypeOf(TStringsCollection)^);
    Load:    @TStringsCollection.Load;
    Store:   @TStringsCollection.Store
  );
  RSwapLinesCollection: TStreamRec = (
    ObjType: 1201;
    VmtLink: Ofs(TypeOf(TSwapLinesCollection)^);
    Load:    @TSwapLinesCollection.Load;
    Store:   @TSwapLinesCollection.Store
  );
  RTerminal: TStreamRec = (
    ObjType: 1205;
    VmtLink: Ofs(TypeOf(TTerminal)^);
    Load:    @TTerminal.Load;
    Store:   @TTerminal.Store
  );
  RTerminalWindow: TStreamRec = (
    ObjType: 1206;
    VmtLink: Ofs(TypeOf(TTerminalWindow)^);
    Load:    @TTerminalWindow.Load;
    Store:   @TTerminalWindow.Store
  );
  RBack: TStreamRec = (
    ObjType: 1207;
    VmtLink: Ofs(TypeOf(TBack)^);
    Load:    @TBack.Load;
    Store:   @TBack.Store
  );
  RBackWindow: TStreamRec = (
    ObjType: 1208;
    VmtLink: Ofs(TypeOf(TBackWindow)^);
    Load:    @TBackWindow.Load;
    Store:   @TBackWindow.Store
  );
  RHexBack: TStreamRec = (
    ObjType: 1209;
    VmtLink: Ofs(TypeOf(THexBack)^);
    Load:    @THexBack.Load;
    Store:   @THexBack.Store
  );
  RHexBackWindow: TStreamRec = (
    ObjType: 1210;
    VmtLink: Ofs(TypeOf(THexBackWindow)^);
    Load:    @THexBackWindow.Load;
    Store:   @THexBackWindow.Store
  );
  RWatchViewer: TStreamRec = (
    ObjType: 1211;
    VmtLink: Ofs(TypeOf(TWatchViewer)^);
    Load:    @TWatchViewer.Load;
    Store:   @TWatchViewer.Store
  );
  RWatchWindow: TStreamRec = (
    ObjType: 1212;
    VmtLink: Ofs(TypeOf(TWatchWindow)^);
    Load:    @TWatchWindow.Load;
    Store:   @TWatchWindow.Store
  );
  RViewIndicator: TStreamRec = (
    ObjType: 1220;
    VmtLink: Ofs(TypeOf(TViewIndicator)^);
    Load:    @TViewIndicator.Load;
    Store:   @TViewIndicator.Store
  );
  RTextViewer: TStreamRec = (
    ObjType: 1221;
    VmtLink: Ofs(TypeOf(TTextViewer)^);
    Load:    @TTextViewer.Load;
    Store:   @TTextViewer.Store
  );
  RTextWindow: TStreamRec = (
    ObjType: 1222;
    VmtLink: Ofs(TypeOf(TTextWindow)^);
    Load:    @TTextWindow.Load;
    Store:   @TTextWindow.Store
  );
  RLongScrollBar: TStreamRec = (
    ObjType: 1230;
    VmtLink: Ofs(TypeOf(TLongScrollBar)^);
    Load:    @TLongScrollBar.Load;
    Store:   @TLongScrollBar.Store
  );
  RHexViewIndicator: TStreamRec = (
    ObjType: 1231;
    VmtLink: Ofs(TypeOf(THexViewIndicator)^);
    Load:    @THexViewIndicator.Load;
    Store:   @THexViewIndicator.Store
  );
  RHexViewer: TStreamRec = (
    ObjType: 1232;
    VmtLink: Ofs(TypeOf(THexViewer)^);
    Load:    @THexViewer.Load;
    Store:   @THexViewer.Store
  );
  RHexWindow: TStreamRec = (
    ObjType: 1233;
    VmtLink: Ofs(TypeOf(THexWindow)^);
    Load:    @THexWindow.Load;
    Store:   @THexWindow.Store
  );
  RFieldViewer: TStreamRec = (
    ObjType: 1240;
    VmtLink: Ofs(TypeOf(TFieldViewer)^);
    Load:    @TFieldViewer.Load;
    Store:   @TFieldViewer.Store
  );
  RDataViewIndicator: TStreamRec = (
    ObjType: 1241;
    VmtLink: Ofs(TypeOf(TDataViewIndicator)^);
    Load:    @TDataViewIndicator.Load;
    Store:   @TDataViewIndicator.Store
  );
  RDataViewer: TStreamRec = (
    ObjType: 1242;
    VmtLink: Ofs(TypeOf(TDataViewer)^);
    Load:    @TDataViewer.Load;
    Store:   @TDataViewer.Store
  );
  RDataWindow: TStreamRec = (
    ObjType: 1243;
    VmtLink: Ofs(TypeOf(TDataWindow)^);
    Load:    @TDataWindow.Load;
    Store:   @TDataWindow.Store
  );
  RSelList: TStreamRec = (
    ObjType: 1244;
    VmtLink: Ofs(TypeOf(TSelList)^);
    Load:    @TSelList.Load;
    Store:   @TSelList.Store
  );
  RRegExpInputLine: TStreamRec = (
    ObjType: 1245;
    VmtLink: Ofs(TypeOf(TRegExpInputLine)^);
    Load:    @TRegExpInputLine.Load;
    Store:   @TRegExpInputLine.Store
  );
  RRegExpDialog: TStreamRec = (
    ObjType: 1246;
    VmtLink: Ofs(TypeOf(TRegExpDialog)^);
    Load:    @TRegExpDialog.Load;
    Store:   @TRegExpDialog.Store
  );

procedure RegisterAllTypes;
var
  P: PStreamRec;
begin
  P := @RView;
  repeat
    RegisterType(P^);
    Inc(PtrRec(P).Ofs, SizeOf(TStreamRec));
  until PtrRec(P).Ofs > Ofs(RRegExpDialog);

(*
  RegisterType(RView);
  RegisterType(RFrame);
  RegisterType(RScrollBar);
  RegisterType(RScroller);
  RegisterType(RListViewer);
  RegisterType(RGroup);
  RegisterType(RWindow);
  RegisterType(RDialog);
  RegisterType(RInputLine);
  RegisterType(RButton);
  RegisterType(RCluster);
  RegisterType(RRadioButtons);
  RegisterType(RCheckBoxes);
  RegisterType(RMultiCheckBoxes);
  RegisterType(RListBox);
  RegisterType(RStaticText);
  RegisterType(RLabel);
  RegisterType(RHistory);
  RegisterType(RParamText);
  RegisterType(RAboutDialog);
  RegisterType(RAlarmList);
  RegisterType(RAlarmDialog);
  RegisterType(RTable);
  RegisterType(RReport);
  RegisterType(RASCIIChart);
  RegisterType(RBarView);
  RegisterType(RCalcDisplay);
  RegisterType(RHexDisplay);
  RegisterType(RCalcButton);
  RegisterType(RCalculator);
  RegisterType(RCalendarView);
  RegisterType(RCalendarWindow);
  RegisterType(RClipEditor);
  RegisterType(RClipWindow);
  RegisterType(RCRadioButtons);
  RegisterType(RCCheckBoxes);
  RegisterType(RCMultiCheckBoxes);
  RegisterType(RCInputLine);
  RegisterType(RFInputLine);
  RegisterType(RCodeList);
  RegisterType(RCodeWindow);
  RegisterType(RColorSelector);
  RegisterType(RMonoSelector);
  RegisterType(RColorDisplay);
  RegisterType(RColorGroupList);
  RegisterType(RColorItemList);
  RegisterType(RColorDialog);
  RegisterType(RSourceList);
  RegisterType(RRegistersList);
  RegisterType(RFlagsList);
  RegisterType(RMemList);
  RegisterType(RStackList);
  RegisterType(RCPUIndicator);
  RegisterType(RCPUWindow);
  RegisterType(RDates);
  RegisterType(RTreeCollection);
  RegisterType(RDumpIndicator);
  RegisterType(RDumpList);
  RegisterType(RDumpWindow);
  RegisterType(RIndicator);
  RegisterType(RFileEditor);
  RegisterType(REditorWindow);
  RegisterType(RUndoChain);
  RegisterType(RPrompt);
  RegisterType(RPromptLine);
  RegisterType(RPanel);
  RegisterType(RPanelFrame);
  RegisterType(RPanelWindow);
  RegisterType(RDragInputLine);
  RegisterType(RFindFileCollection);
  RegisterType(RTagList);
  RegisterType(RHexIndicator);
  RegisterType(RHexEditor);
  RegisterType(RHexEditorWindow);
  RegisterType(RHelpTopic);
  RegisterType(RHelpIndex);
  RegisterType(RIcon);
  RegisterType(RMacro);
  RegisterType(REventCollection);
  RegisterType(RMapViewer);
  RegisterType(RMapWindow);
  RegisterType(RMessageViewer);
  RegisterType(RMessageWindow);
  RegisterType(ROutputCollection);
  RegisterType(ROutput);
  RegisterType(ROutputWindow);
  RegisterType(RExecItem);
  RegisterType(RPhoneEntry);
  RegisterType(RSpoolerList);
  RegisterType(RSpoolerDialog);
  RegisterType(RDialList);
  RegisterType(RDialDialog);
  RegisterType(RStatusText);
  RegisterType(RLineText);
  RegisterType(RStatusWindow);
  RegisterType(RStringsCollection);
  RegisterType(RSwapLinesCollection);
  RegisterType(RTerminal);
  RegisterType(RTerminalWindow);
  RegisterType(RBack);
  RegisterType(RBackWindow);
  RegisterType(RWatchViewer);
  RegisterType(RWatchWindow);
  RegisterType(RViewIndicator);
  RegisterType(RTextViewer);
  RegisterType(RTextWindow);
  RegisterType(RLongScrollBar);
  RegisterType(RHexViewIndicator);
  RegisterType(RHexViewer);
  RegisterType(RHexWindow);
  RegisterType(RFieldViewer);
  RegisterType(RDataViewIndicator);
  RegisterType(RDataViewer);
  RegisterType(RDataWindow);
*)
end;

end.