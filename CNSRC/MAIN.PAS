unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, ImgList, Menus, ActnList, RXSwitch,
  Placemnt, TB2Dock, AdStatLt, OoMisc, AdPort, TBXStatusBars, TBXDkPanels,
  TB2Item, TBX, TB2Toolbar, TBXSwitcher, TBXOfficeXPTheme, TBXExtItems,
  TB2ExtItems, A3nalogGauge, RXSplit, TBXToolPals;

const
  MaxLamps = 1024;
  EETestMaxItems = 20;

  PacketSize = 4;

type
  TReceiveResult = (rrOk, rrByteTimeout, rrBlockTimeout, rrError);

  TNameStr = String[31]; // Should be enough...

  PLampRec = ^TLampRec;
  TLampRec = record
    Name: TNameStr;
    Address: Integer;
    Group0Address: Byte;
    Group1Address: Byte;
    Group2Address: Byte;
    Group3Address: Byte;
//    Lit: Boolean;
//    Brightness: Integer;
  end;

  TLampArray = Array[0..MaxLamps - 1] of TLampRec;

  PLampParamRec = ^TLampParamRec;
  TLampParamRec = record
    Name: TNameStr;
    Address: Integer;
    Value, Multiplier, Min, Max, Lo, Hi, Default: Real;
    Format: TNameStr;
    Digits, MajorTicks, MinorTicks: Integer;
    Meter: TA3nalogGauge;
    Attempts: Longint;
  end;

  TLampParamList = class(TList)
  public
    destructor Destroy; override;
    procedure FreeAll;
  end;

  PNetworkFieldRec = ^TNetworkFieldRec;
  TNetworkFieldRec = record
    Name: TNameStr;
    Address: Integer;
    Multiplier, LoFail, HiFail, LoWarn, HiWarn: Real;
    Format: TNameStr;
    Attempts: Longint;
  end;

  TNetworkFieldList = class(TList)
  public
    destructor Destroy; override;
    procedure FreeAll;
  end;

  PNetworkStateRec = ^TNetworkStateRec;
  TNetworkStateRec = record
    Address: Integer;
    NetStateStrings: TStringList;
    NetAlarmStrings: TStringList;
    NetworkFieldList: TNetworkFieldList;
  end;

  TNetworkStateList = class(TList)
  public
    destructor Destroy; override;
    procedure FreeAll;
  end;

  PScheduleRec = ^TScheduleRec;
  TScheduleRec = record
    LoMinute, LoHour, LoDay, LoMonth, LoWeekDay, LoYear,
    HiMinute, HiHour, HiDay, HiMonth, HiWeekDay, HiYear,
    Action, Data, Address, Group, RepeatSeconds: Integer;
    Time: TDateTime;
  end;

  TScheduleList = class(TList)
  public
    Index: Integer;
    CustomTime: TDateTime;
    destructor Destroy; override;
    procedure FreeAll;
  end;

(*
  PPowerRec = ^TPowerRec;
  TPowerRec = record
    LampAddress: Integer;
    Address: Integer;
    Multiplier: Real;
    Format: TNameStr;
  end;

  TPowerList = class(TList)
  public
    destructor Destroy; override;
    function Compare(R1, R2: TPowerRec): Integer;
    procedure FreeAll;
    function Search(R: TPowerRec; var Index: Integer): Boolean;
    function GetPowerRec(LampAddress: Integer): PPowerRec;
  end;
*)

  TLampsMainForm = class(TForm)
    Timer: TTimer;
    ActionList: TActionList;
    AddToNewGroupAction: TAction;
    AddToSelGroupAction: TAction;
    CreateGroupAction: TAction;
    DeleteItemAction: TAction;
    RenameItemAction: TAction;
    ChangeGroupAddressAction: TAction;
    FormStorage: TFormStorage;
    ChangeLampAddressAction: TAction;
    ExitAction: TAction;
    TopDock: TTBDock;
    BottomDock: TTBDock;
    LeftDock: TTBDock;
    RightDock: TTBDock;
    StatusBar: TTBXStatusBar;
    TXDLight: TApdStatusLight;
    RXDLight: TApdStatusLight;
    ComPort: TApdComPort;
    SLController: TApdSLController;
    AllPanel: TTBXDockablePanel;
    ListView1: TListView;
    GroupPanel: TTBXDockablePanel;
    ListView2: TListView;
    SelGroupPanel: TTBXDockablePanel;
    ListView3: TListView;
    StatePanel: TTBXDockablePanel;
    ListView4: TListView;
    TBXSwitcher: TTBXSwitcher;
    MenuToolbar: TTBXToolbar;
    FileSubmenu: TTBXSubmenuItem;
    CommandsSubmenu: TTBXSubmenuItem;
    PropertiesSubmenu: TTBXSubmenuItem;
    ToolsSubmenu: TTBXSubmenuItem;
    TBXItem1: TTBXItem;
    TBXItem2: TTBXItem;
    TBXItem3: TTBXItem;
    TBXSeparatorItem1: TTBXSeparatorItem;
    TBXItem4: TTBXItem;
    TBXItem6: TTBXItem;
    TBXItem7: TTBXItem;
    PacketTestAction: TAction;
    TBXItem8: TTBXItem;
    ViewSubmenu: TTBXSubmenuItem;
    AllLampsPanelItem: TTBXItem;
    TBXLabelItem1: TTBXLabelItem;
    AllGroupsPanelItem: TTBXItem;
    SelectedGroupPanelItem: TTBXItem;
    SelectedLampStatePanelItem: TTBXItem;
    PropPortItem: TTBXComboList;
    PropBaudItem: TTBXComboList;
    PropParityItem: TTBXComboList;
    PropDataBitsItem: TTBXComboList;
    PropStopBitsItem: TTBXComboList;
    ListView1PopupMenu: TTBXPopupMenu;
    TBXItem9: TTBXItem;
    TBXSeparatorItem3: TTBXSeparatorItem;
    TBXItem10: TTBXItem;
    TBXItem11: TTBXItem;
    ListView2PopupMenu: TTBXPopupMenu;
    TBXItem12: TTBXItem;
    TBXSeparatorItem4: TTBXSeparatorItem;
    TBXItem13: TTBXItem;
    TBXItem14: TTBXItem;
    TBXItem15: TTBXItem;
    ListView3PopupMenu: TTBXPopupMenu;
    TBXItem16: TTBXItem;
    RefreshPanel: TTBXAlignmentPanel;
    HelpSubmenu: TTBXSubmenuItem;
    SmallImages: TTBImageList;
    AboutAction: TAction;
    TBXItem5: TTBXItem;
    SendAction: TAction;
    BroadcastAction: TAction;
    SelectLampAction: TAction;
    TBXItem19: TTBXItem;
    TBXSeparatorItem6: TTBXSeparatorItem;
    TBXItem20: TTBXItem;
    TBXSeparatorItem7: TTBXSeparatorItem;
    EEAction: TAction;
    TBXSeparatorItem8: TTBXSeparatorItem;
    TBXItem21: TTBXItem;
    TBXSeparatorItem9: TTBXSeparatorItem;
    TBXItem22: TTBXItem;
    TBXSeparatorItem10: TTBXSeparatorItem;
    TBXItem23: TTBXItem;
    SetGroup0Action: TAction;
    SetGroup1Action: TAction;
    SetGroup2Action: TAction;
    SetGroup3Action: TAction;
    TBXItem24: TTBXItem;
    TBXItem25: TTBXItem;
    TBXItem26: TTBXItem;
    TBXItem27: TTBXItem;
    TBXSeparatorItem11: TTBXSeparatorItem;
    TBXSeparatorItem12: TTBXSeparatorItem;
    ControlToolbar: TTBXToolbar;
    GaugePanel: TTBXAlignmentPanel;
    TBControlItem2: TTBControlItem;
    Switch: TRxSwitch;
    DimmingLabel: TLabel;
    DimLabel: TLabel;
    TrackBar: TTrackBar;
    AxisLabel: TLabel;
    LargeImages: TTBImageList;
    TBXItem32: TTBXItem;
    TBXItem33: TTBXItem;
    SendToGroupAction: TAction;
    TBXItem34: TTBXItem;
    TBXSeparatorItem13: TTBXSeparatorItem;
    RefreshToolbar: TTBXToolbar;
    RefreshComboList: TTBXComboList;
    RefreshCheckBox: TTBXCheckBox;
    TBControlItem1: TTBControlItem;
    GetAction: TAction;
    TBXItem17: TTBXItem;
    TBXSeparatorItem14: TTBXSeparatorItem;
    ControlPanelItem: TTBXItem;
    SelectGroupAction: TAction;
    TBXItem18: TTBXItem;
    TBXSeparatorItem15: TTBXSeparatorItem;
    Meter: TA3nalogGauge;
    Splitter: TRxSplitter;
    MeterPopupMenu: TTBXPopupMenu;
    MeterMarginComboList: TTBXComboList;
    MeterFaceColorSubmenu: TTBXSubmenuItem;
    MeterFaceDefaultColorItem: TTBXColorItem;
    MeterFaceColorPalette: TTBXColorPalette;
    TBXSeparatorItem16: TTBXSeparatorItem;
    MeterFaceMoreColorsItem: TTBXItem;
    ColorDialog: TColorDialog;
    MeterLoColorSubmenu: TTBXSubmenuItem;
    MeterLoDefaultColorItem: TTBXColorItem;
    MeterLoColorPalette: TTBXColorPalette;
    TBXSeparatorItem17: TTBXSeparatorItem;
    MeterLoMoreColorsItem: TTBXItem;
    MeterNormalColorSubmenu: TTBXSubmenuItem;
    MeterNormalDefaultColorItem: TTBXColorItem;
    MeterNormalColorPalette: TTBXColorPalette;
    TBXSeparatorItem18: TTBXSeparatorItem;
    MeterNormalMoreColorsItem: TTBXItem;
    MeterHiColorSubmenu: TTBXSubmenuItem;
    MeterHiDefaultColorItem: TTBXColorItem;
    MeterHiColorPalette: TTBXColorPalette;
    TBXSeparatorItem19: TTBXSeparatorItem;
    MeterHiMoreColorsItem: TTBXItem;
    TBXSeparatorItem20: TTBXSeparatorItem;
    MeterArrowColorSubmenu: TTBXSubmenuItem;
    MeterArrowDefaultColorItem: TTBXColorItem;
    MeterArrowColorPalette: TTBXColorPalette;
    TBXSeparatorItem21: TTBXSeparatorItem;
    MeterArrowMoreColorsItem: TTBXItem;
    MeterCenterColorSubmenu: TTBXSubmenuItem;
    MeterCenterDefaultColorItem: TTBXColorItem;
    MeterCenterColorPalette: TTBXColorPalette;
    TBXSeparatorItem22: TTBXSeparatorItem;
    MeterCenterMoreColorsItem: TTBXItem;
    MeterValueColorSubmenu: TTBXSubmenuItem;
    MeterValueDefaultColorItem: TTBXColorItem;
    MeterValueColorPalette: TTBXColorPalette;
    TBXSeparatorItem23: TTBXSeparatorItem;
    MeterValueMoreColorsItem: TTBXItem;
    MeterTicksColorSubmenu: TTBXSubmenuItem;
    MeterTicksDefaultColorItem: TTBXColorItem;
    MeterTicksColorPalette: TTBXColorPalette;
    TBXSeparatorItem24: TTBXSeparatorItem;
    MeterTicksMoreColorsItem: TTBXItem;
    MeterCaptionColorSubmenu: TTBXSubmenuItem;
    MeterCaptionDefaultColorItem: TTBXColorItem;
    MeterCaptionColorPalette: TTBXColorPalette;
    TBXSeparatorItem25: TTBXSeparatorItem;
    MeterCaptionMoreColorsItem: TTBXItem;
    MeterCircleColorSubmenu: TTBXSubmenuItem;
    MeterCircleDefaultColorItem: TTBXColorItem;
    MeterCircleColorPalette: TTBXColorPalette;
    TBXSeparatorItem26: TTBXSeparatorItem;
    MeterCircleMoreColorsItem: TTBXItem;
    MeterMarginColorSubmenu: TTBXSubmenuItem;
    MeterMarginDefaultColorItem: TTBXColorItem;
    MeterMarginColorPalette: TTBXColorPalette;
    TBXSeparatorItem27: TTBXSeparatorItem;
    MeterMarginMoreColorsItem: TTBXItem;
    MeterMajorTickLengthComboList: TTBXComboList;
    MeterMinorTickLengthComboList: TTBXComboList;
    MeterCenterRadiusComboList: TTBXComboList;
    MeterCircleRadiusComboList: TTBXComboList;
    FontDialog: TFontDialog;
    MeterFontItem: TTBXItem;
    TBXSeparatorItem28: TTBXSeparatorItem;
    MeterArrowWidthComboList: TTBXComboList;
    TBXSeparatorItem30: TTBXSeparatorItem;
    PropDelayItem: TTBXComboList;
    PropEchoByteTimeoutItem: TTBXComboList;
    PropEchoBlockTimeoutItem: TTBXComboList;
    PropReplyByteTimeoutItem: TTBXComboList;
    PropReplyBlockTimeoutItem: TTBXComboList;
    NetworkStatusPanel: TTBXDockablePanel;
    ListView5: TListView;
    NetworkStatusPanelItem: TTBXItem;
    TBXAlignmentPanel1: TTBXAlignmentPanel;
    NetworkToolbar: TTBXToolbar;
    TBXItem35: TTBXItem;
    TBXSeparatorItem29: TTBXSeparatorItem;
    TBControlItem3: TTBControlItem;
    NetRefreshComboList: TTBXComboList;
    TBXSeparatorItem31: TTBXSeparatorItem;
    TBXItem36: TTBXItem;
    NetRefreshCheckBox: TTBXCheckBox;
    NetGetAction: TAction;
    NetClearAction: TAction;
    MeterPanelItem: TTBXItem;
    ClearLampAddressAction: TAction;
    ClearGroupAddressAction: TAction;
    TBXItem37: TTBXItem;
    TBXItem38: TTBXItem;
    TBXSeparatorItem2: TTBXSeparatorItem;
    MoreMetersAction: TAction;
    TBXSeparatorItem33: TTBXSeparatorItem;
    TBXItem39: TTBXItem;
    ReadConfigAction: TAction;
    WriteConfigAction: TAction;
    TBXSeparatorItem34: TTBXSeparatorItem;
    TBXItem41: TTBXItem;
    GroupBackupItem: TTBXItem;
    GroupBackupPromptItem: TTBXItem;
    TBXSubmenuItem1: TTBXSubmenuItem;
    CheckAllAction: TAction;
    UncheckAllAction: TAction;
    ListView5PopupMenu: TTBXPopupMenu;
    TBXItem40: TTBXItem;
    TBXItem42: TTBXItem;
    UncheckOnErrorItem: TTBXItem;
    TBXSeparatorItem5: TTBXSeparatorItem;
    TBXItem28: TTBXItem;
    TBXItem29: TTBXItem;
    TBXItem30: TTBXItem;
    TBXItem31: TTBXItem;
    TBXSeparatorItem35: TTBXSeparatorItem;
    TBXItem43: TTBXItem;
    TBXItem44: TTBXItem;
    TBXItem45: TTBXItem;
    TBXItem46: TTBXItem;
    TBXSeparatorItem36: TTBXSeparatorItem;
    LampHintItem: TTBXItem;
    TBXItem47: TTBXItem;
    TBXItem48: TTBXItem;
    TBXSeparatorItem37: TTBXSeparatorItem;
    TBXLabelItem3: TTBXLabelItem;
    NetworkReadAllItem: TTBXItem;
    NetworkReadVisibleItem: TTBXItem;
    TBXLabelItem4: TTBXLabelItem;
    NetworkFieldParam01Item: TTBXItem;
    NetworkFieldParam02Item: TTBXItem;
    NetworkFieldParam03Item: TTBXItem;
    NetworkFieldParam04Item: TTBXItem;
    NetworkFieldParam05Item: TTBXItem;
    NetworkFieldParam06Item: TTBXItem;
    NetworkFieldParam07Item: TTBXItem;
    NetworkFieldParam08Item: TTBXItem;
    NetworkFieldParam09Item: TTBXItem;
    NetworkFieldParam10Item: TTBXItem;
    NetworkFieldParam11Item: TTBXItem;
    NetworkFieldParam12Item: TTBXItem;
    NetworkFieldParam13Item: TTBXItem;
    NetworkFieldParam14Item: TTBXItem;
    NetworkFieldParam15Item: TTBXItem;
    NetworkFieldParam16Item: TTBXItem;
    NetworkFieldParam17Item: TTBXItem;
    NetworkFieldParam18Item: TTBXItem;
    TBXSeparatorItem38: TTBXSeparatorItem;
    NetworkSortItem: TTBXItem;
    NetworkUncheckedLamps: TTBXLabelItem;
    NetworkHiddenColumns: TTBXLabelItem;
    NetworkSaveItem: TTBXItem;
    TBXSeparatorItem32: TTBXSeparatorItem;
    CfgEditAction: TAction;
    TBXSeparatorItem39: TTBXSeparatorItem;
    TBXItem49: TTBXItem;
    SchEditAction: TAction;
    TBXItem50: TTBXItem;
    SchedulerItem: TTBXItem;
    RunSchedulerAction: TAction;
    TBXSeparatorItem41: TTBXSeparatorItem;
    TBXItem51: TTBXItem;
    LogFolderEdit: TTBXEditItem;
    LogNameMaskEdit: TTBXEditItem;
    LogUpdateComboList: TTBXComboList;
    LogNetworkItem: TTBXItem;
    TBXLabelItem6: TTBXLabelItem;
    LogONOFFItem: TTBXItem;
    LogSchedulerItem: TTBXItem;
    LogSemaphoreItem: TTBXItem;
    PropByteDelayItem: TTBXComboList;
    SavePropertiesAction: TAction;
    RestorePropertiesAction: TAction;
    TBXSeparatorItem43: TTBXSeparatorItem;
    TBXItem52: TTBXItem;
    TBXItem53: TTBXItem;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    PropBlockRetriesItem: TTBXComboList;
    TBXSeparatorItem44: TTBXSeparatorItem;
    PasswordEdit: TTBXEditItem;
    PropRetryDelayItem: TTBXComboList;
    NetworkGroupItem: TTBXItem;
    TBXSeparatorItem45: TTBXSeparatorItem;
    LogSETItem: TTBXItem;
    PropPriorityItem: TTBXComboList;
    PropComPriorityItem: TTBXComboList;
    TBXSubmenuItem2: TTBXSubmenuItem;
    TBXSubmenuItem3: TTBXSubmenuItem;
    TBXSubmenuItem4: TTBXSubmenuItem;
    TBXSeparatorItem40: TTBXSeparatorItem;
    TBXLabelItem2: TTBXLabelItem;
    TBXLabelItem5: TTBXLabelItem;
    TBXLabelItem7: TTBXLabelItem;
    TBXLabelItem8: TTBXLabelItem;
    TBXSeparatorItem42: TTBXSeparatorItem;
    PropRetryONOFFItem: TTBXItem;
    PropSendBreakItem: TTBXItem;
    TBXSeparatorItem46: TTBXSeparatorItem;
    TBXLabelItem9: TTBXLabelItem;
    PropFletcherItem: TTBXItem;
    PropBreakDelayItem: TTBXComboList;
    PropErrMsgItem: TTBXItem;
    TBXSeparatorItem47: TTBXSeparatorItem;
    TBXLabelItem10: TTBXLabelItem;
    PropRefreshAttemptsItem: TTBXComboList;
    SelectedLampStateMeterItem: TTBXItem;
    EETestPanel: TTBXDockablePanel;
    TBXAlignmentPanel2: TTBXAlignmentPanel;
    EETestToolbar: TTBXToolbar;
    TBXItem54: TTBXItem;
    TBXSeparatorItem48: TTBXSeparatorItem;
    TrackBar1: TTrackBar;
    TrackBar2: TTrackBar;
    TrackBar3: TTrackBar;
    TrackBar4: TTrackBar;
    TrackBar5: TTrackBar;
    TrackBar6: TTrackBar;
    TrackBar7: TTrackBar;
    TrackBar8: TTrackBar;
    TrackBar9: TTrackBar;
    TrackBar10: TTrackBar;
    TrackBar11: TTrackBar;
    TrackBar12: TTrackBar;
    TrackBar13: TTrackBar;
    TrackBar14: TTrackBar;
    TrackBar15: TTrackBar;
    TrackBar16: TTrackBar;
    TrackBar17: TTrackBar;
    TrackBar18: TTrackBar;
    TrackBar19: TTrackBar;
    TrackBar20: TTrackBar;
    EETestGetAction: TAction;
    EETestSetAction: TAction;
    EETestOnAction: TAction;
    EETestOffAction: TAction;
    EETestTestAction: TAction;
    TBXItem57: TTBXItem;
    TBXItem58: TTBXItem;
    TBXItem59: TTBXItem;
    EETestPanelItem: TTBXItem;
    TBXLabel1: TTBXLabel;
    TBXLabel2: TTBXLabel;
    TBXLabel3: TTBXLabel;
    TBXLabel4: TTBXLabel;
    TBXLabel5: TTBXLabel;
    TBXLabel6: TTBXLabel;
    TBXLabel7: TTBXLabel;
    TBXLabel8: TTBXLabel;
    TBXLabel9: TTBXLabel;
    TBXLabel10: TTBXLabel;
    TBXLabel11: TTBXLabel;
    TBXLabel12: TTBXLabel;
    TBXLabel13: TTBXLabel;
    TBXLabel14: TTBXLabel;
    TBXLabel15: TTBXLabel;
    TBXLabel16: TTBXLabel;
    TBXLabel17: TTBXLabel;
    TBXLabel18: TTBXLabel;
    TBXLabel19: TTBXLabel;
    TBXLabel20: TTBXLabel;
    TBXLabel21: TTBXLabel;
    TBXLabel22: TTBXLabel;
    TBXLabel23: TTBXLabel;
    TBXLabel24: TTBXLabel;
    TBXLabel25: TTBXLabel;
    TBXLabel26: TTBXLabel;
    TBXLabel27: TTBXLabel;
    TBXLabel28: TTBXLabel;
    TBXLabel29: TTBXLabel;
    TBXLabel30: TTBXLabel;
    TBXLabel31: TTBXLabel;
    TBXLabel32: TTBXLabel;
    TBXLabel33: TTBXLabel;
    TBXLabel34: TTBXLabel;
    TBXLabel35: TTBXLabel;
    TBXLabel36: TTBXLabel;
    TBXLabel37: TTBXLabel;
    TBXLabel38: TTBXLabel;
    TBXLabel39: TTBXLabel;
    TBXLabel40: TTBXLabel;
    TBXSeparatorItem49: TTBXSeparatorItem;
    ViewFixItem: TTBXItem;
    EETestSetDefaultsAction: TAction;
    TBXItem55: TTBXItem;
    EETestPopupMenu: TTBXPopupMenu;
    TBXItem60: TTBXItem;
    TBXItem61: TTBXItem;
    TBXItem62: TTBXItem;
    TBXSeparatorItem50: TTBXSeparatorItem;
    TBXItem63: TTBXItem;
    TBXItem64: TTBXItem;
    TBXItem65: TTBXItem;
    TBXAlignmentPanel3: TTBXAlignmentPanel;
    TBControlItem4: TTBControlItem;
    Image1: TImage;
    TBXSeparatorItem51: TTBXSeparatorItem;
    TBBackground1: TTBBackground;
    Bevel1: TBevel;
    TBXSubmenuItem5: TTBXSubmenuItem;
    ScanNetworkAction: TAction;
    NetScanMaskEdit: TTBXEditItem;
    NetScanLoAddrEdit: TTBXEditItem;
    NetScanHiAddrEdit: TTBXEditItem;
    RenameLampAction: TAction;
    TBXSeparatorItem52: TTBXSeparatorItem;
    TBXItem66: TTBXItem;
    SetSubmenu: TTBXSubmenuItem;
    EETestAutoSendTimeItem: TTBXComboList;
    NetScanNewItem: TTBXItem;
    TreeView1: TTreeView;
    AllViewComboList: TTBXComboList;
    TBXSeparatorItem53: TTBXSeparatorItem;
    TBXSeparatorItem54: TTBXSeparatorItem;
    AllToggleItem: TTBXItem;
    TBXItem56: TTBXItem;
    TBXItem67: TTBXItem;
    TBXSeparatorItem55: TTBXSeparatorItem;
    ReloadListsAction: TAction;
    TBXItem68: TTBXItem;
    TBXSeparatorItem56: TTBXSeparatorItem;
    TBXItem69: TTBXItem;
    TBXSeparatorItem57: TTBXSeparatorItem;
    TBXItem70: TTBXItem;
    TBXSeparatorItem58: TTBXSeparatorItem;
    CreateLampAction: TAction;
    CreateInGroupAction: TAction;
    TBXItem71: TTBXItem;
    TBXItem72: TTBXItem;
    TBXSubmenuItem6: TTBXSubmenuItem;
    PropConfDeleteLampItem: TTBXItem;
    PropConfDeleteGroupItem: TTBXItem;
    PropConfRemoveItem: TTBXItem;
    PropConfExitItem: TTBXItem;
    TBXLabelItem11: TTBXLabelItem;
    PerfectLayoutAction: TAction;
    TBXSubmenuItem7: TTBXSubmenuItem;
    LayoutItem0: TTBXItem;
    LayoutItem1: TTBXItem;
    LayoutItem2: TTBXItem;
    TXTOpenDialog: TOpenDialog;
    EETestLoadAction: TAction;
    TBXItem73: TTBXItem;
    TBXItem74: TTBXItem;
    PropReceiveDelayItem: TTBXComboList;
    EETestSaveDefaultsAction: TAction;
    TBXItem75: TTBXItem;
    TBXItem76: TTBXItem;
    procedure FormShow(Sender: TObject);
    procedure TrackBarChange(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
//    procedure ListView1SelectItem(Sender: TObject; Item: TListItem;
//      Selected: Boolean);
//    procedure ListView1Change(Sender: TObject; Item: TListItem;
//      Change: TItemChange);
    procedure ListView2DragOver(Sender, Source: TObject;
      X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure ListView2DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure AddToNewGroupActionExecute(Sender: TObject);
    procedure AddToSelGroupActionExecute(Sender: TObject);
    procedure CreateGroupActionExecute(Sender: TObject);
    procedure DeleteItemActionExecute(Sender: TObject);
    procedure ListView2SelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure ListView2Editing(Sender: TObject; Item: TListItem;
      var AllowEdit: Boolean);
    procedure ListView2Edited(Sender: TObject; Item: TListItem;
      var S: String);
//    procedure ListView1Enter(Sender: TObject);
    procedure RenameItemActionExecute(Sender: TObject);
    procedure ChangeGroupAddressActionExecute(Sender: TObject);
    procedure PackettestClick(Sender: TObject);
    procedure ChangeLampAddressActionExecute(Sender: TObject);
    procedure SwitchOff(Sender: TObject);
    procedure ExitActionExecute(Sender: TObject);
    procedure ListView4Deletion(Sender: TObject; Item: TListItem);
    procedure PacketTestActionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ViewSubmenuPopup(Sender: TTBCustomItem; FromLink: Boolean);
    procedure AllLampsPanelItemClick(Sender: TObject);
    procedure PropertiesSubmenuPopup(Sender: TTBCustomItem;
      FromLink: Boolean);
    procedure PropPortItemItemClick(Sender: TObject);
    procedure AboutActionExecute(Sender: TObject);
    procedure SendActionExecute(Sender: TObject);
    procedure SelectLampActionExecute(Sender: TObject);
    procedure EEActionExecute(Sender: TObject);
    procedure SetGroup0ActionExecute(Sender: TObject);
    procedure GetActionExecute(Sender: TObject);
    procedure MeterMarginComboListItemClick(Sender: TObject);
    procedure MeterPopupMenuPopup(Sender: TObject);
    procedure MeterFaceDefaultColorItemClick(Sender: TObject);
    procedure MeterFaceColorPaletteChange(Sender: TObject);
    procedure MeterFaceMoreColorsItemClick(Sender: TObject);
    procedure ListView1Deletion(Sender: TObject; Item: TListItem);
    procedure ListView1DblClick(Sender: TObject);
    procedure ListView2DblClick(Sender: TObject);
    procedure MeterFontItemClick(Sender: TObject);
    procedure ListView4Change(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure NetGetActionExecute(Sender: TObject);
    procedure NetClearActionExecute(Sender: TObject);
    procedure RefreshCheckBoxClick(Sender: TObject);
    procedure DimmingRadioButtonClick(Sender: TObject);
    procedure MoreMetersActionExecute(Sender: TObject);
    procedure ReadConfigActionExecute(Sender: TObject);
    procedure CheckAllActionExecute(Sender: TObject);
    procedure UncheckAllActionExecute(Sender: TObject);
    procedure ListView1InfoTip(Sender: TObject; Item: TListItem;
      var InfoTip: String);
    procedure ListView5PopupMenuPopup(Sender: TObject);
    procedure NetworkFieldParam01ItemClick(Sender: TObject);
    procedure ListView5MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListView5Compare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure NetworkSortItemClick(Sender: TObject);
    procedure CfgEditActionExecute(Sender: TObject);
    procedure RunSchedulerActionExecute(Sender: TObject);
    procedure SavePropertiesActionExecute(Sender: TObject);
    procedure RestorePropertiesActionExecute(Sender: TObject);
    procedure ListView5DblClick(Sender: TObject);
    procedure ListView5KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure PropPriorityItemItemClick(Sender: TObject);
    procedure PropComPriorityItemItemClick(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure TrackBar1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ViewFixItemClick(Sender: TObject);
    procedure AllPanelDockedResizing(Sender: TObject; Vertical: Boolean;
      var NewSize: Integer; Stage: TTBXResizingStage;
      var AllowResize: Boolean);
    procedure EETestGetActionExecute(Sender: TObject);
    procedure EETestSetActionExecute(Sender: TObject);
    procedure EETestOnActionExecute(Sender: TObject);
    procedure EETestOffActionExecute(Sender: TObject);
    procedure EETestTestActionExecute(Sender: TObject);
    procedure ScanNetworkActionExecute(Sender: TObject);
    procedure RenameLampActionExecute(Sender: TObject);
    procedure ListView1Edited(Sender: TObject; Item: TListItem;
      var S: String);
    procedure ListView1Editing(Sender: TObject; Item: TListItem;
      var AllowEdit: Boolean);
    procedure AllViewComboListItemClick(Sender: TObject);
    procedure AllToggleItemClick(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure TreeView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TreeView1Edited(Sender: TObject; Node: TTreeNode;
      var S: String);
    procedure TreeView1Editing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure TreeView1DblClick(Sender: TObject);
    procedure TreeView1AdvancedCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
      var PaintImages, DefaultDraw: Boolean);
    procedure AllPanelResize(Sender: TObject);
    procedure TreeView1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure TreeView1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure TreeView1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure TreeView1Expanded(Sender: TObject; Node: TTreeNode);
    procedure ReloadListsActionExecute(Sender: TObject);
    procedure CreateLampActionExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure LayoutItem0Click(Sender: TObject);
    procedure NetworkReadAllItemClick(Sender: TObject);
    procedure PropPortItemAcceptText(Sender: TObject; var NewText: String;
      var Accept: Boolean);
    procedure EETestLoadActionExecute(Sender: TObject);
    procedure PasswordEditAcceptText(Sender: TObject; var NewText: String;
      var Accept: Boolean);
    procedure ComPortTriggerAvail(CP: TObject; Count: Word);
    procedure EETestSaveDefaultsActionExecute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
//    Selecting: Boolean;
//    Tracking: Boolean;
    EditRequest: Boolean;
    TreeEditRequest: Boolean;
    SendRequest: Boolean;
    BroadcastRequest: Boolean;
    SendToGroupRequest: Boolean;
    EESendRequest: Boolean;
    GetRequest: Boolean;
    NetGetRequest: Boolean;
    EETestGetRequest: Boolean;
    EETestSetRequest: Boolean;
    SendAddress: Integer;
    SendOnOffCommand: Integer;
    SendDimming: Integer;
    SetGroupRequest: Boolean;
    SetGroupCommand: Integer;
    SetGroupAddress: Integer;
    SetGroupLampAddress: Integer;
    ConfigRequest: Boolean;
    ConfigRead: Boolean;
    NetScanRequest: Boolean;
    SelectedLampItem: TListItem;
    SelectedGroupItem: TListItem;
    NetSelectedGroupItem: TListItem;
    NetGroup: Boolean;
    AbortGet: Boolean;
    NetAbortGet: Boolean;
    NetLogTime: TDateTime;
    LogEvent: Boolean;
    LogSourceStr: String[31];
    ReloadingAll: Boolean;
    GetDisabled: Boolean;
    EETestTransferring: Boolean;
    EETestAutoSend: Boolean;
    EETestChangedSeconds: Integer;
    EETestValueArray: Array[0..EETestMaxItems - 1] of Integer;
    PopulatingTree: Boolean;
    LastDropTarget, HintNode: TTreeNode;
    ExpandNode1, ExpandNode2: String[255];
    EESection, EETestSection: Integer;
    procedure ExceptionHandler(Sender: TObject; E: Exception);
    procedure OnShowHint(Sender: TObject);
    procedure LoadCursors;
    procedure ClearGroupAddresses;
    procedure PopulateLampArray;
    procedure PopulateGroupAddresses;
    procedure PopulateTreeView(C: Integer);
    procedure PopulateLampListView(L: TListView;
      const A: TLampArray; C: Integer);
    procedure PopulateGroupListView(L: TListView);
    procedure PopulateStateListView(L: TListView);
    procedure PopulateEEListView(L: TListView);
    procedure PopulateEETestList;
    procedure PopulateNetworkStateList;
    procedure PopulateNetworkListView(L: TListView);
    procedure PopulateScheduleList(const FileName: String);
//    procedure ReadPowerFile;
    function GetNewLampName: String;
    function GetNewGroupName: String;
    procedure ListView1ToListView2NewGroup;
    procedure ListView1ToListView2AddToGroup;
//    procedure UpdateListView(L: TListView);
    procedure UpdateActionState;
    procedure HandleRequests;
    function GroupExists(const S: String; EditedItem: TListItem): Boolean;
    function TreeGroupExists(const S: String;
      EditedNode: TTreeNode): Boolean;
    procedure EditGroupAddress(EditedItem: TListItem; DoClear: Boolean);
    procedure EditLampAddress(EditedItem: TListItem; DoClear: Boolean);
    procedure TrackIniFiles;
    procedure TrackScheduleList;
    procedure SetMeter(M: TA3nalogGauge; P: PLampParamRec);
    procedure SetMeters;
    procedure GetState;
    procedure NetGetState;
    procedure ClearStatePanel;
    procedure RemoveStateAndMeters;
    procedure ListView5CheckAll(State: Boolean);
    function BackupGroupFiles: Boolean;
    function StoreNetworkConfiguration: Boolean;
    procedure PromptForConfig(Read: Boolean);
    function GetRefreshCount: Integer;
    function GetNetRefreshCount: Integer;
    procedure SortNetworkStateList;
    procedure NetworkSaveAsHTML;
    procedure NetworkSaveAsTXT;
    function LogFileName: String;
    function LogPeriod: TDateTime;
    procedure WriteToLog(L: TStringList;
      const FileName, Title: String);
    function LogEventStr(Command: Integer): String;
    procedure ReloadAllLists;
    function GetThreadPriorityIndex: Integer;
    function EETestTrackBarByIndex(I: Integer): TTrackBar;
    function EETestValueArrayChangeCount: Integer;
    procedure EETestGet;
    procedure EETestSet;
    procedure SyncAllListWithTree;
    procedure SyncGroupListWithTree;
    procedure SyncTreeWithAllList;
    procedure SyncTreeWithGroupList;
    procedure SelectEEFileName;
    procedure SaveEEDefaults;
  end;

const
  cmOn = 0;
  cmOff = 1;
  cmGetRam = 2;
  cmGetEE = 3;
  cmSetAddr = 4;
  cmSetGroup0 = 5;
  cmSetGroup1 = 6;
  cmSetGroup2 = 7;
  cmSetGroup3 = 8;
//  cmSetEE0 = 9;
  cmLock = 9;
  cmWriteAddr = 10;
  cmSetEEAddr = 11;
  cmSetEEData = 12;
  cmEETest = 13;

  AddTimeout: Integer = 0;

  RefreshCount: Integer = 0;
  NetRefreshCount: Integer = 0;

  StateStrings: Array[0..15] of String[31] =
    ('Fail', 'Start', 'On', 'Ign', 'No ign', 'Warmup', 'Normal',
     '', '', '', '', '', '', '', '', '');
  AlarmStrings: Array[0..15] of String[31] =
    ('Mains Low', 'Mains off', 'PFC Low', 'PFC High', 'Short load',
     'No load', 'No ign', 'Overtemp', 'Switch off', 'Vout Low',
     'Vout High', '', '', '', '', '');

  UnlockRequiredStr = 'Unlock required';
  EEDataMismatchStr = 'Set EE data mismatch';

const
//  PowerList: TPowerList = nil;
  NetworkStateList: TNetworkStateList = nil;
  ScheduleList: TScheduleList = nil;
  EETestList: TLampParamList = nil;

var
  LampsMainForm: TLampsMainForm;

var
  LampArray: TLampArray;
  TotalLamps: Integer;  

function AllFileName: String;  
procedure Pause(MS: DWORD);
function ReceiveBlock(ComPort: TApdComPort;
  P: PByteArray; Size: Integer;
  ByteTimeout, BlockTimeout: Integer): TReceiveResult;
function SendLampCommand(Address, Command, Data: Integer;
  Group, Broad: Boolean; var B0, B1, B2: Byte): String;
function PLampRecByAddress(Address: Integer): PLampRec;
function FormatX(const S: String; R: Real): String;
function HourMinSecToStr(T: TDateTime): String;
procedure ResetInputData;

implementation

{$R *.DFM}
{$R CURSORS.RES}

uses CommCtrl, IniFiles, AppUtils, ADExcept, AddrFrm, EEFrm, ComFrm,
  MeterFrm, ConnxFrm, About, MsgBoxes, PrmptFrm, DTFrm,
  PrgrsFrm, FileUtil;

const
  MaxImages = 10;

  AllName = 'ALL.TXT';
  StateName = 'STATE.TXT';
  NetStateName = 'NETSTATE.TXT';
  TemplateName = 'TEMPLATE.TXT';
//  PowerName = 'POWER.TXT';
  EEName = 'EE.TXT';
  EEName0 = 'EE_0.TXT';
  EEName1 = 'EE_1.TXT';
  EETestName = 'EETEST.TXT';
  EETestName0 = 'EETEST_0.TXT';
  EETestName1 = 'EETEST_1.TXT';
  ScheduleName = 'SCHEDULE.TXT';
  SemaphoreName = 'SEMAPHORE.TXT';
  RemChar = ';';
  SepChar = ':';
  NewLampNamePattern = 'New lamp';
  NewGroupNamePattern = 'New group';
  GroupNameExt = '.GRP';
  GroupAddressDirective = '#GROUPADDRESS';

  crDragCursor = 1;
  crMDragCursor = 2;
  crDragAdd = 3;
  crMDragAdd = 4;

//  ActiveListView: TListView = nil;

  BaseRegistryKey = 'Software\Lamps\Toolbars';

  InfinityTime = 100000.0;

  AllFileAge: Integer = 0;
  StateFileAge: Integer = 0;
  NetStateFileAge: Integer = 0;
//  PowerFileAge: Integer = 0;
  EEFileAge: Integer = 0;
  EETestFileAge: Integer = 0;
  ScheduleFileAge: Integer = 0;
  ScheduleRepeatTime: TDateTime = InfinityTime;

  ForceRetries: Integer = -1;

  TopLevel = $7FFF;
  PasswordLevel: Integer = -1;
  IgnorePasswordCase: Boolean = False;

var
  ScheduleRepeatRec: TScheduleRec;

const
  InputDataSize = PacketSize * 2;
  InputDataPutIndex: Integer = 0;
  InputDataGetIndex: Integer = 0;

var
  InputData: Array[0..InputDataSize - 1] of Char;

function xCharReady: Boolean;
begin
  Result := InputDataPutIndex > InputDataGetIndex;
end;

function xGetChar: Char;
begin
  Result := #0;
  if InputDataGetIndex < InputDataSize then
  begin
    Result := InputData[InputDataGetIndex];
    Inc(InputDataGetIndex);
  end;
end;

procedure ResetInputData;
begin
  InputDataPutIndex := 0;
  InputDataGetIndex := 0;
end;

function IndexToThreadPriority(I: Integer): Integer;
begin
  case I of
    0: Result := THREAD_PRIORITY_IDLE;
    1: Result := THREAD_PRIORITY_LOWEST;
    2: Result := THREAD_PRIORITY_BELOW_NORMAL;
    3: Result := THREAD_PRIORITY_NORMAL;
    4: Result := THREAD_PRIORITY_ABOVE_NORMAL;
    5: Result := THREAD_PRIORITY_HIGHEST;
    6: Result := THREAD_PRIORITY_TIME_CRITICAL;
    else Result := -1;
  end;
end;

function ThreadPriorityToIndex(P: Integer): Integer;
begin
  case P of
    THREAD_PRIORITY_IDLE: Result := 0;
    THREAD_PRIORITY_LOWEST: Result := 1;
    THREAD_PRIORITY_BELOW_NORMAL: Result := 2;
    THREAD_PRIORITY_NORMAL: Result := 3;
    THREAD_PRIORITY_ABOVE_NORMAL: Result := 4;
    THREAD_PRIORITY_HIGHEST: Result := 5;
    THREAD_PRIORITY_TIME_CRITICAL: Result := 6;
    else Result := -1;
  end;
end;

function FormatX(const S: String; R: Real): String;
begin
  try
    Result := Format(S, [R]);
  except
    Result := Format(S, [Trunc(R)]);
  end;
end;

function HourMinSecToStr(T: TDateTime): String;
var
  H, M, S, I, J: Word;
begin
  I := Trunc(T);
  DecodeTime(T, H, M, S, J);
  if (I <> 0) and (H < 24) then Inc(H, I * 24);
  Result := Format('%d:%.2d:%.2d', [H, M, S]);
end;

destructor TLampParamList.Destroy;
begin
  FreeAll;
  Inherited Destroy;
end;

procedure TLampParamList.FreeAll;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    FreeMem(Items[I], SizeOf(TLampParamRec));
  Clear;
end;

destructor TNetworkFieldList.Destroy;
begin
  FreeAll;
  Inherited Destroy;
end;

procedure TNetworkFieldList.FreeAll;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    FreeMem(Items[I], SizeOf(TNetworkFieldRec));
  Clear;
end;

destructor TNetworkStateList.Destroy;
begin
  FreeAll;
  Inherited Destroy;
end;

procedure TNetworkStateList.FreeAll;
var
  I: Integer;
  P: PNetworkStateRec;
begin
  for I := 0 to Count - 1 do
  begin
    P := Items[I];
    if P <> nil then with P^ do
    begin
      NetworkFieldList.Free;
      NetAlarmStrings.Free;
      NetStateStrings.Free;
      FreeMem(P, SizeOf(TNetworkStateRec));
    end;
  end;
  Clear;
end;

procedure DateTimeToScheduleDateTime(T: TDateTime; var ST: TDateTime);
var
  Year, Month, Day, Hour, Minute, W: Word;
begin
  DecodeDate(T, Year, Month, Day);
  DecodeTime(T, Hour, Minute, W, W);
  ST := EncodeDate(Year, Month, Day) + EncodeTime(Hour, Minute, 0, 0);
end;

procedure DateTimeToScheduleRec(T: TDateTime; var R: TScheduleRec);
var
  Year, Month, Day, Hour, Minute, W: Word;
begin
  DecodeDate(T, Year, Month, Day);
  DecodeTime(T, Hour, Minute, W, W);
  R.LoMinute := Minute;
  R.LoHour := Hour;
  R.LoDay := Day;
  R.LoMonth := Month;
  R.LoWeekDay := DayOfWeek(T);
  R.LoYear := Year;
end;

function ScheduleRecordMatchesTime(T: TDateTime; P: PScheduleRec): Boolean;
var
  R: TScheduleRec;

function FieldsMatch(I, ILo, IHi: Integer): Boolean;
begin
  Result := (ILo = -1) or ((I >= ILo) and (I <= IHi));
end;

begin
  DateTimeToScheduleRec(T, R);
  Result :=
    FieldsMatch(R.LoMinute, P^.LoMinute, P^.HiMinute) and
    FieldsMatch(R.LoHour, P^.LoHour, P^.HiHour) and
    FieldsMatch(R.LoDay, P^.LoDay, P^.HiDay) and
    FieldsMatch(R.LoMonth, P^.LoMonth, P^.HiMonth) and
    FieldsMatch(R.LoWeekDay, P^.LoWeekDay, P^.HiWeekDay) and
    FieldsMatch(R.LoYear, P^.LoYear, P^.HiYear);
end;

destructor TScheduleList.Destroy;
begin
  FreeAll;
  Inherited Destroy;
end;

procedure TScheduleList.FreeAll;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    FreeMem(Items[I], SizeOf(TScheduleRec));
  Clear;
  Index := 0;
  CustomTime := 0;
end;

(*
destructor TPowerList.Destroy;
begin
  FreeAll;
  Inherited Destroy;
end;

function TPowerList.Compare(R1, R2: TPowerRec): Integer;
begin
  if R1.LampAddress > R2.LampAddress then Compare := 1
  else if R1.LampAddress < R2.LampAddress then Compare := -1
  else Compare := 0;
end;

procedure TPowerList.FreeAll;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    FreeMem(Items[I], SizeOf(TPowerRec));
  Clear;
end;

function TPowerList.Search(R: TPowerRec;
  var Index: Integer): Boolean;
var
  L, H, I, C: Integer;
  P: PPowerRec;
begin
  Search := False;
  L := 0;
  H := Count - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    P := Items[I];
    C := Compare(P^, R);
    if C < 0 then L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Search := True;
        L := I;
      end;
    end;
  end;
  Index := L;
end;

function TPowerList.GetPowerRec(LampAddress: Integer): PPowerRec;
var
  I: Integer;
  R: TPowerRec;
begin
  if Count = 0 then
  begin
    GetMem(Result, SizeOf(TPowerRec));
    Result^.LampAddress := 0;
    Result^.Address := 4;
    Result^.Multiplier := 4.0;
    Result^.Format := '%3.0f W';
  end
  else
  begin
    R.LampAddress := LampAddress;
    if not Search(R, I) then Dec(I);
    if (I < 0) or (I >= Count) then Result := Items[0]
    else Result := Items[I];
  end;
end;
*)

// ComPort stuff

// Pseudo sleep
(*
procedure Pause(MS: DWORD);
var
  D: Real;
  T: TDateTime;
begin
  if MS = 0 then
  begin
    Sleep(0);
    Exit;
  end;
  D := MS;
  T := Now;
  repeat
    Application.ProcessMessages;
    if (GetKeyState(VK_LBUTTON) and $8000 <> 0) or
       (GetKeyState(VK_RBUTTON) and $8000 <> 0) or
       (GetKeyState(VK_ESCAPE) and $8000 <> 0) then Exit;
  until Now > T + D / (24.0 * 3600000.0);
end;
*)

procedure Pause(MS: DWORD);
begin
  Sleep(MS);
end;

// Convert milliseconds to Delphi TDateTime
function TimeInterval(MSec: Integer): TDateTime;
const
  MSecsInDay = 3600 * 1000 * 24;
begin
  Result := MSec / MSecsInDay;
end;

const
  Receiving: Boolean = False;
  ActuallyReceived: Integer = 0;

// Receive Size bytes into P array via ComPort, check for timeouts
function ReceiveBlock(ComPort: TApdComPort;
  P: PByteArray; Size: Integer;
  ByteTimeout, BlockTimeout: Integer): TReceiveResult;
var
  I, J: Integer;
  ByTimeout, BlTimeout, ByteTime, BlockTime, NowTime: TDateTime;
begin
  Result := rrError;
  PostMessage(LampsMainForm.Handle, 0, 0, 0);
  ByTimeout := TimeInterval(ByteTimeout);
  BlTimeout := TimeInterval(BlockTimeout);
  I := 0;
  J := StrToIntDef(LampsMainForm.PropReceiveDelayItem.Text, 2);
  ByteTime := Now;
  BlockTime := ByteTime;
  ActuallyReceived := 0;
  Receiving := True;
  try
//    with ComPort do
    repeat
Application.ProcessMessages;
Sleep(0);
Sleep(J);
      if xCharReady then
      begin
        Char(P^[I]) := xGetChar;
        Inc(I);
        ActuallyReceived := I;
        if I >= Size then Result := rrOk;
        ByteTime := Now;
      end
      else
      begin
//        Application.ProcessMessages;
//        Sleep(1);
        NowTime := Now;
        if (ByteTimeout > 0) and (NowTime - ByteTime > ByTimeout) then
          Result := rrByteTimeout
        else if (BlockTimeout > 0) and (NowTime - BlockTime > BlTimeout) then
          Result := rrBlockTimeout;
      end;
    until Result <> rrError;
  finally
    Receiving := False;
  end;
end;

function SendLampCommand(Address, Command, Data: Integer;
  Group, Broad: Boolean; var B0, B1, B2: Byte): String;
var
  F: Boolean;
  I, J, M, N: Integer;
  R: TReceiveResult;
  A, B: Array[0..PacketSize - 1] of Byte;
begin
  Result := '';
  F := LampsMainForm.PropFletcherItem.Checked;
  if ForceRetries >= 0 then N := ForceRetries
  else N := StrToIntDef(LampsMainForm.PropBlockRetriesItem.Text, 0);
  for M := 0 to N do
  begin
// No retries on broadcast
    if (Group or Broad) and (ForceRetries < 0) and (M <> 0) then Exit;
    with LampsMainForm, ComPort do
    begin
      if M <> 0 then Pause(StrToIntDef(PropRetryDelayItem.Text, 0));

      FlushInBuffer;
      FlushOutBuffer;
      ResetInputData;

//      if Address = $3FF then Broad := True;
      Address := Address and $3FF;
      A[0] := (Command * 8) + (Address div 256);
      if Group then A[0] := A[0] or $04;
      A[1] := Byte(Address);
      A[2] := Byte(Data);
      if F then A[3] := (A[0] + A[0] + A[0] + A[1] + A[1] + A[2]) and $7F
      else A[3] := (A[0] + A[1] + A[2]) and $7F;
//      PutBlock(A, PacketSize);
      J := StrToIntDef(PropByteDelayItem.Text, 0);
      if J = 0 then PutBlock(A, PacketSize)
      else for I := 0 to PacketSize - 1 do
      begin
        PutChar(Char(A[I]));
        Pause(J);
      end;
      LampsMainForm.StatusBar.Panels[1].Caption :=
        'Last sent: ' +
        IntToHex(A[0], 2) + ' ' + IntToHex(A[1], 2) + ' ' +
        IntToHex(A[2], 2) + ' ' + IntToHex(A[3], 2);
      if LogEvent then
        WriteToLog(nil, LogFileName,
          ' - ' + LogSourceStr + ' ' + LogEventStr(Command) + ': ' +
          IntToHex(A[0], 2) + ' ' + IntToHex(A[1], 2) + ' ' +
          IntToHex(A[2], 2) + ' ' + IntToHex(A[3], 2));
      R := ReceiveBlock(ComPort, @B, PacketSize,
        StrToIntDef(PropEchoByteTimeoutItem.Text, 20),
        StrToIntDef(PropEchoBlockTimeoutItem.Text, 100));
      case R of
        rrByteTimeout: Result := 'Echo byte timeout';
        rrBlockTimeout: Result := 'Echo block timeout';
        rrError: Result := 'Echo internal error';
        else if not CompareMem(@A, @B, 4) then
          Result := 'Echo mismatch:'#13#13 +
            IntToHex(A[0], 2) + ' ' + IntToHex(A[1], 2) + ' ' +
            IntToHex(A[2], 2) + ' ' + IntToHex(A[3], 2) + #13 +
            IntToHex(B[0], 2) + ' ' + IntToHex(B[1], 2) + ' ' +
            IntToHex(B[2], 2) + ' ' + IntToHex(B[3], 2) + #13#13 +
            '(block sent, block received)'
        else if not Group and not Broad then
        begin
          R := ReceiveBlock(ComPort, @B, PacketSize,
            StrToIntDef(PropReplyByteTimeoutItem.Text, 20) + AddTimeout,
            StrToIntDef(PropReplyBlockTimeoutItem.Text, 100) + AddTimeout * 8);
          case R of
            rrByteTimeout: Result := 'Reply byte timeout';
            rrBlockTimeout: Result := 'Reply block timeout';
            rrError: Result := 'Reply internal error';
            else if F and ((Byte(B[0] + B[0] + B[0] +
              B[1] + B[1] + B[2]) or $80) <> B[3]) then
                Result := 'Checksum mismatch'
            else if not F and ((Byte(
              B[0] + B[1] + B[2]) or $80) <> B[3]) then
                Result := 'Checksum mismatch'
            else if (Command = cmSetEEData) and (B[1] <= 1) then
            begin
              Result := UnlockRequiredStr;
              Exit;
            end
            else if (Command = cmSetEEData) and (B[2] <> Data) then
            begin
              Result := EEDataMismatchStr + ':'#13#13 + 'received: ' +
                IntToHex(B[0], 2) + ' ' + IntToHex(B[1], 2) + ' ' +
                IntToHex(B[2], 2) + ' ' + IntToHex(B[3], 2);
              Exit;  
            end
            else
            begin
              B0 := B[0];
              B1 := B[1];
              B2 := B[2];
            end;
          end;
          if Result <> '' then
          begin
            LampsMainForm.StatusBar.Panels[2].Caption :=
              'Last received: ' + Result;
            if LogEvent then WriteToLog(nil, LogFileName,
              ' - Received: ' + Result);
            if PropSendBreakItem.Checked then
            begin
              J := StrToIntDef(LampsMainForm.PropBreakDelayItem.Text, -1);
              if J >= 0 then SendBreak(J, False);
            end;
          end
          else
          begin
            LampsMainForm.StatusBar.Panels[2].Caption :=
              'Last received: ' +
              IntToHex(B[0], 2) + ' ' + IntToHex(B[1], 2) + ' ' +
              IntToHex(B[2], 2) + ' ' + IntToHex(B[3], 2);
            if LogEvent then WriteToLog(nil, LogFileName,
              ' - Received: ' +
              IntToHex(B[0], 2) + ' ' + IntToHex(B[1], 2) + ' ' +
              IntToHex(B[2], 2) + ' ' + IntToHex(B[3], 2));
            if ForceRetries < 0 then Exit; // Success
          end;
        end
        else if ForceRetries < 0 then Exit; // Success
      end;
    end;
  end;
end;

// Remove line breaks from the string
function CleanString(const S: String): String;
var
  I: Integer;
begin
  I := Pos(#13, S);
  if I <> 0 then Result := Copy(S, 1, I - 1)
  else Result := S;
end;

// Get decimal digits by Format string (%5.2f)
function GetDigits(S: String): Integer;
var
  I: Integer;
begin
  Result := 0;
  repeat
    I := Pos('.', S);
    if I <> 0 then
    begin
      if (I < Length(S) - 1) and (S[I + 1] in ['0'..'9']) and
         (S[I + 2] = 'f') then
      begin
        Result := StrToIntDef(Copy(S, I + 1, 1), 0);
        Exit;
      end;
      Delete(S, 1, I);
    end;
  until I = 0;
end;

// ImageList index by TrackBar position
function IndexByPosition(I: Integer): Integer;
begin
  if I < 0 then Result := 0
  else if I >= 100 then Result := MaxImages - 1
  else Result := I div MaxImages;
end;

// File name for ALL.TXT
function AllFileName: String;
begin
  Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + AllName;
end;

// File name for STATE.TXT
function StateFileName: String;
begin
  Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + StateName;
end;

// File name for NETSTATE.TXT
function NetStateFileName: String;
begin
  Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + NetStateName;
end;

// File name for TEMPLATE.TXT
function TemplateFileName: String;
begin
  Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + TemplateName;
end;

// File name for SCHEDULE.TXT
function ScheduleFileName: String;
begin
  Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + ScheduleName;
end;

// File name for SEMAPHORE.TXT
function SemaphoreFileName: String;
begin
  Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + SemaphoreName;
end;

// File name for POWER.TXT
(*
function PowerFileName: String;
begin
  Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + PowerName;
end;
*)

// File name for EE.TXT
function EEFileName: String;
begin
  if PasswordLevel = 0 then Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + EEName0
  else if PasswordLevel = 1 then Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + EEName1
  else
  begin
    Result := LampsMainForm.FormStorage.StoredValues[0].Value;
    if (Result = '') or (Result = '*') then
      Result := IncludeTrailingBackSlash(
        ExtractFilePath(Application.ExeName)) + EEName;
  end;
end;

// File name for EETEST.TXT
function EETestFileName: String;
begin
  if PasswordLevel = 0 then Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + EETestName0
  else if PasswordLevel = 1 then Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + EETestName1
  else
  begin
    Result := LampsMainForm.FormStorage.StoredValues[1].Value;
    if (Result = '') or (Result = '*') then
      Result := IncludeTrailingBackSlash(
        ExtractFilePath(Application.ExeName)) + EETestName;
  end;
end;

// File name for LAMPS.INI
function FSIniFileName: String;
begin
  Result := ChangeFileExt(Application.ExeName, '.INI');
end;

// File name for group
function FileNameByGroupCaption(const S: String): String;
begin
  Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + S + GroupNameExt;
end;

// Lamp address by lamp item
function LampAddressByLampItem(Item: TListItem): Integer;
begin
  if (Item = nil) or (Item.Data = nil) then Result := -1
  else Result := PLampRec(Item.Data)^.Address;
end;

// Lamp index by lamp name
function LampIndexByLampName(const S: String): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to TotalLamps - 1 do
    if LampArray[I].Name = S then
    begin
      Result := I;
      Exit;
    end;
end;

// Group address index by group address
function GroupAddressIndexByGroupAddress(P: PLampRec; A: Integer): Integer;
begin
  if P^.Group0Address = A then Result := 0
  else if P^.Group1Address = A then Result := 1
  else if P^.Group2Address = A then Result := 2
  else if P^.Group3Address = A then Result := 3
  else Result := -1;
end;

// Group address by group item
function GroupAddressByGroupItem(Item: TListItem): Integer;
begin
  if (Item = nil) or (Item.SubItems.Count = 0) then Result := -1
  else Result := StrToIntDef(Item.SubItems[0], -1);
end;

// Group file mask
function GroupFileMask: String;
begin
  Result := IncludeTrailingBackSlash(
    ExtractFilePath(Application.ExeName)) + '*' + GroupNameExt;
end;

// PLampRec by address
function PLampRecByAddress(Address: Integer): PLampRec;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to TotalLamps - 1 do
    if LampArray[I].Address = Address then
    begin
      Result := @LampArray[I];
      Exit;
    end;
end;

// PLampRec by array record
function PLampRecByArrayRec(P: PLampRec): PLampRec;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to TotalLamps - 1 do
    if (LampArray[I].Name = P^.Name) and
       (LampArray[I].Address = P^.Address) and
       (LampArray[I].Group0Address = P^.Group0Address) and
       (LampArray[I].Group1Address = P^.Group1Address) and
       (LampArray[I].Group2Address = P^.Group2Address) and
       (LampArray[I].Group3Address = P^.Group3Address) then
    begin
      Result := @LampArray[I];
      Exit;
    end;
end;

// Array contains lamp record
function PLampRecInArray(P: PLampRec;
  const A: TLampArray; C: Integer): PLampRec;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to C - 1 do
    if (A[I].Name = P^.Name) and (A[I].Address = P^.Address) and
       (A[I].Group0Address = P^.Group0Address) and
       (A[I].Group1Address = P^.Group1Address) and
       (A[I].Group2Address = P^.Group2Address) and
       (A[I].Group3Address = P^.Group3Address) then
    begin
      Result := P;
      Exit;
    end;
end;

// Load lamp list into LampArray
procedure LoadFromText(const FileName: String;
  var A: TLampArray; var C: Integer);
var
  G: Boolean;
  I, J: Integer;
  S: String;
begin
  C := 0;
  if not FileExists(FileName) then Exit;
  G := @A <> @LampArray;
  with TStringList.Create do
  try
    LoadFromFile(FileName);
    for I := 0 to Count - 1 do
    begin
      S := Strings[I];
      if Pos(GroupAddressDirective, Uppercase(S)) <> 0 then
        Continue;
      J := Pos(RemChar, S);
      if J <> 0 then SetLength(S, J - 1);
      J := Pos(SepChar, S);
      if J <> 0 then
        if G then
        begin
          S := Trim(Copy(S, 1, J - 1));
          J := LampIndexByLampName(S);
          if J <> -1 then
          begin
            A[C] := LampArray[J];
            Inc(C);
          end;
        end
        else with A[C] do
        begin
          Name := Trim(Copy(S, 1, J - 1));
          Address := StrToIntDef(Trim(Copy(S, J + 1, 255)), -1);
          if Address <> -1 then Inc(C);
        end;
      if C >= MaxLamps then Break;
    end;
  finally
    Free;
  end;
end;

// Save LampArray to file
procedure SaveToText(const FileName: String;
  const A: TLampArray; C, Address: Integer);
var
  I, J: Integer;
begin
  with TStringList.Create do
  try
    Add(GroupAddressDirective + ' ' + IntToStr(Address));
    for I := 0 to C - 1 do
    begin
      J := GroupAddressIndexByGroupAddress(@A[I], Address);
      if J <> -1 then Add(Format('%s : %d', [A[I].Name, J]));
    end;  
    SaveToFile(FileName);
  finally
    Free;
  end;
end;

function CanAddToGroup(P: PLampRec; GA: Integer;
  ShowError: Boolean): Boolean;
begin
  Result := True;
  if P^.Group0Address = $FF then P^.Group0Address := GA
  else if P^.Group1Address = $FF then P^.Group1Address := GA
  else if P^.Group2Address = $FF then P^.Group2Address := GA
  else if P^.Group3Address = $FF then P^.Group3Address := GA
  else
  begin
    Result := False;
    if ShowError then ErrMsgBox(P^.Name +
      ' cannot be added to another group,' +
      ' because it is already owned by four groups.');
  end;
end;

// ListView selected to LampArray
procedure SelectedToArray(L: TListView;
  var A: TLampArray; var C: Integer; GA: Integer);
var
  I: Integer;
  P: PLampRec;
begin
  C := 0;
  if (L <> nil) and (L.Selected <> nil) then with L do
    if SelCount > 1 then
    begin
      for I := 0 to Items.Count - 1 do
        if Items[I].Selected then
        begin
          P := Items[I].Data;
          if P <> nil then
          begin
            if not CanAddToGroup(P, GA, True) then Exit;
            Move(P^, A[C], SizeOf(TLampRec));
            Inc(C);
          end;
        end;
    end
    else if Selected <> nil then
    begin
      P := Selected.Data;
      if P <> nil then
      begin
        if not CanAddToGroup(P, GA, True) then Exit;
        Move(P^, A[C], SizeOf(TLampRec));
        Inc(C);
      end;
    end;
end;

// ListView to LampArray
procedure ListViewToArray(L: TListView;
  var A: TLampArray; var C: Integer);
var
  I: Integer;
  P: PLampRec;
begin
  C := 0;
  if L <> nil then with L, Items do
    for I := 0 to Count - 1 do
    begin
      P := Items[I].Data;
      if P <> nil then
      begin
        Move(P^, A[C], SizeOf(TLampRec));
        Inc(C);
      end;
    end;
end;

// TreeView node to LampArray
procedure TreeNodeToArray(N: TTreeNode;
  var A: TLampArray; var C: Integer);
var
  I: Integer;
  P: PLampRec;
begin
  C := 0;
  if N <> nil then with N do
    for I := 0 to Count - 1 do
    begin
      P := Item[I].Data;
      if P <> nil then
      begin
        Move(P^, A[C], SizeOf(TLampRec));
        Inc(C);
      end;
    end;
end;

// Append A1 to A2 and adjust C2
procedure AppendArray(const A1: TLampArray; var A2: TLampArray;
  C1: Integer; var C2: Integer; CheckAddr: Boolean);
var
  Found: Boolean;
  I, J: Integer;
begin
  for I := 0 to C1 - 1 do
  begin
    Found := False;
    if CheckAddr then for J := 0 to C2 - 1 do
      if A1[I].Address = A2[J].Address then
      begin
        Found := True;
        Break;
      end;
    if not Found then
    begin
      A2[C2] := A1[I];
      Inc(C2);
    end;
  end;
end;

// Read group address from text file
// Syntax:
// #GROUPADDRESS 256
function GetGroupAddress(const FileName: String): Integer;
var
  I, J: Integer;
  S: String;
begin
  Result := 0;
  if not FileExists(FileName) then Exit;
  with TStringList.Create do
  try
    LoadFromFile(FileName);
    for I := 0 to Count - 1 do
    begin
      S := Strings[I];
      J := Pos(RemChar, S);
      if J <> 0 then SetLength(S, J - 1);
      J := Pos(GroupAddressDirective, Uppercase(S));
      if J <> 0 then
      begin
        Result := StrToIntDef(Trim(
          Copy(S, J + Length(GroupAddressDirective), 255)), 0);
        Break;
      end;
    end;
  finally
    Free;
  end;
end;

// Change group address in text file
procedure ModifyGroupAddress(const FileName: String;
  Address: Integer);
var
  Found: Boolean;
  I, J: Integer;
  S: String;
begin
  if not FileExists(FileName) then Exit;
  with TStringList.Create do
  try
    LoadFromFile(FileName);
    Found := False;
    for I := 0 to Count - 1 do
    begin
      S := Strings[I];
      J := Pos(RemChar, S);
      if J <> 0 then SetLength(S, J - 1);
      J := Pos(GroupAddressDirective, Uppercase(S));
      if J <> 0 then
      begin
        Found := True;
        Strings[I] := GroupAddressDirective + ' ' + IntToStr(Address);
        Break;
      end;
    end;
    if not Found then Insert(0,
      GroupAddressDirective + ' ' + IntToStr(Address));
    SaveToFile(FileName);
  finally
    Free;
  end;
end;

// Change lamp name in text files
procedure ModifyLampName(P: PLampRec; const NewName: String);
var
  Found: Boolean;
  I, J: Integer;
  R: TSearchRec;
  S, OldName, GroupName: String;
begin
  OldName := P^.Name;

  Found := False;
  if FileExists(AllFileName) then with TStringList.Create do
  try
    LoadFromFile(AllFileName);
    for I := 0 to Count - 1 do
    begin
      S := Strings[I];
      if Pos(GroupAddressDirective, Uppercase(S)) <> 0 then
        Continue;
      J := Pos(SepChar, S);
      if (J <> 0) and (Trim(Copy(S, 1, J - 1)) = OldName) and
         (StrToIntDef(Trim(Copy(S, J + 1, 255)), -1) = P^.Address) then
      begin
        Found := True;
        S := NewName + ' ' + Copy(S, J, 255);
        Strings[I] := S;
      end;
    end;
    if Found then
    begin
      P^.Name := NewName;
      SaveToFile(AllFileName);
      AllFileAge := FileAge(AllFileName);
    end;
  finally
    Free;
  end;

  I := FindFirst(GroupFileMask, faAnyFile and
    not (faDirectory + faVolumeID), R);
  try
    while I = 0 do
    begin
      GroupName := FileNameByGroupCaption(Copy(R.Name, 1, Length(R.Name) - 4));
      if FileExists(GroupName) then with TStringList.Create do
      try
        LoadFromFile(GroupName);
        for I := 0 to Count - 1 do
        begin
          S := Strings[I];
          if Pos(GroupAddressDirective, Uppercase(S)) <> 0 then
            Continue;
          J := Pos(SepChar, S);
          if (J <> 0) and (Trim(Copy(S, 1, J - 1)) = OldName) then
          begin
            Found := True;
            S := NewName + ' ' + Copy(S, J, 255);
            Strings[I] := S;
          end;
        end;
        if Found then SaveToFile(GroupName);
      finally
        Free;
      end;
      I := FindNext(R);
    end;
  finally
    FindClose(R);
  end;

  with LampsMainForm do
    if (SelectedLampItem <> nil) and (SelectedLampItem.Data = P) then
    begin
      StatePanel.Caption := 'Selected lamp: ' + NewName;
      MeterForm.Caption := NewName + ' meters';
    end;
end;

// Change lamp address in text file
procedure ModifyLampAddress(P: PLampRec; A: Integer);
var
  I, J: Integer;
  L: TListItem;
  S: String;
begin
  if FileExists(AllFileName) then with TStringList.Create do
  try
    LoadFromFile(AllFileName);
    for I := 0 to Count - 1 do
    begin
      S := Strings[I];
      if Pos(GroupAddressDirective, Uppercase(S)) <> 0 then
        Continue;
      J := Pos(RemChar, S);
      if J <> 0 then SetLength(S, J - 1);
      J := Pos(SepChar, S);
      if (J <> 0) and (Trim(Copy(S, 1, J - 1)) = P^.Name) and
         (StrToIntDef(Trim(Copy(S, J + 1, 255)), -1) = P^.Address) then
      begin
        S := P^.Name + ' ' + SepChar + ' ' + IntToStr(A);
        Strings[I] := S;
        SaveToFile(AllFileName);
        AllFileAge := FileAge(AllFileName);
        Break;
      end;
    end;
  finally
    Free;
  end;
  P^.Address := A;

  with LampsMainForm do
  begin
    for I := 0 to ListView1.Items.Count - 1 do
    begin
      L := ListView1.Items[I];
      if L.Data = P then
      begin
        L.SubItems[0] := IntToStr(P^.Address);
        Break;
      end;
    end;
    for I := 0 to ListView3.Items.Count - 1 do
    begin
      L := ListView3.Items[I];
      if L.Data = P then
      begin
        L.SubItems[0] := IntToStr(P^.Address);
        Break;
      end;
    end;
  end;
end;

// Remove lamp from text files
function DeleteLamp(P: PLampRec): Boolean;
var
  Found: Boolean;
  I, J: Integer;
  R: TSearchRec;
  S, GroupName: String;
begin
  Result := False;
  if LampsMainForm.PropConfDeleteLampItem.Checked and not
    ConfMsgBox('Delete ' + P^.Name + '?', True) then Exit;
  Result := True;
  Found := False;
  if FileExists(AllFileName) then with TStringList.Create do
  try
    LoadFromFile(AllFileName);
    for I := 0 to Count - 1 do
    begin
      S := Strings[I];
      if Pos(GroupAddressDirective, Uppercase(S)) <> 0 then
        Continue;
      J := Pos(SepChar, S);
      if (J <> 0) and (Trim(Copy(S, 1, J - 1)) = P^.Name) and
         (StrToIntDef(Trim(Copy(S, J + 1, 255)), -1) = P^.Address) then
      begin
        Found := True;
        Delete(I);
        Break;
      end;
    end;
    if Found then
    begin
      SaveToFile(AllFileName);
      AllFileAge := FileAge(AllFileName);
    end;
  finally
    Free;
  end;

  I := FindFirst(GroupFileMask, faAnyFile and
    not (faDirectory + faVolumeID), R);
  try
    while I = 0 do
    begin
      GroupName := FileNameByGroupCaption(Copy(R.Name, 1, Length(R.Name) - 4));
      if FileExists(GroupName) then with TStringList.Create do
      try
        LoadFromFile(GroupName);
        for I := 0 to Count - 1 do
        begin
          S := Strings[I];
          if Pos(GroupAddressDirective, Uppercase(S)) <> 0 then
            Continue;
          J := Pos(SepChar, S);
          if (J <> 0) and (Trim(Copy(S, 1, J - 1)) = P^.Name) then
          begin
            Found := True;
            Delete(I);
            Break;
          end;
        end;
        if Found then SaveToFile(GroupName);
      finally
        Free;
      end;
      I := FindNext(R);
    end;
  finally
    FindClose(R);
  end;
end;

// Safe SaveToFile
procedure SaveToFileSafe(L: TStrings; const FileName: String);
var
  I: Integer;
begin
  for I := 0 to 7 do
  begin
    try
      L.SaveToFile(FileName);
      Exit;
    except
      {do nothing}
    end;
    Pause(0);
    Pause(200);
  end;
end;

function DirectoryExists(const Name: String): Boolean;
var
  Code: Integer;
begin
  Code := GetFileAttributes(PChar(Name));
  Result := (Code <> -1) and (FILE_ATTRIBUTE_DIRECTORY and Code <> 0);
end;

function ForceDirectories(Dir: String): Boolean;
begin
  Result := True;
  if Dir = '' then Exit;
  Dir := ExcludeTrailingBackSlash(Dir);
  if (Length(Dir) < 3) or DirectoryExists(Dir) or
     (ExtractFilePath(Dir) = Dir) then Exit;
  Result := ForceDirectories(ExtractFilePath(Dir)) and CreateDir(Dir);
end;

procedure MakeNodeBold(N: TTreeNode; Bold: Boolean);
var
  Item: TTVItem;
  Template: Integer;
begin
  if N = nil then Exit;
  if Bold then Template := -1
  else Template := 0;
  with Item do
  begin
    Mask := TVIF_STATE;
    hItem := N.ItemId;
    StateMask := TVIS_BOLD;
    State := StateMask and Template;
  end;
  TreeView_SetItem(N.Handle, Item);
end;

procedure MakeNodeVisible(N: TTreeNode);
var
  R: TRect;
begin
  if N <> nil then with N do
  begin
    if IsVisible then
    begin
      R := DisplayRect(False);
      if (R.Right <> 0) and (R.Top >= 0) and
         (R.Top < TreeView.Height) then Exit;
    end;
    MakeVisible;
    TreeView.Perform(WM_HSCROLL, SB_TOP, 0);
  end;
end;

procedure DisplayControlHint(Control: TControl;
  X, Y: Integer; const S: String);
var
  M: TMessage;
begin
  with Control do
  begin
    Hint := S;
    ShowHint := True;
  end;
  with TWMMouse(M) do
  begin
    Msg := WM_MOUSEMOVE;
    Keys := 0;
    XPos := X;
    YPos := Y;
  end;
  Application.HintMouseMessage(Control, M);
end;

function GetLampInfoTip(P: PLampRec): String;
begin
  if P = nil then Result := ''
  else Result :=
    'Group 0 address: ' + IntToStr(P^.Group0Address) + #13 +
    'Group 1 address: ' + IntToStr(P^.Group1Address) + #13 +
    'Group 2 address: ' + IntToStr(P^.Group2Address) + #13 +
    'Group 3 address: ' + IntToStr(P^.Group3Address);
end;

procedure TLampsMainForm.LoadCursors;
begin
  Screen.Cursors[crDragCursor] := LoadCursor(hInstance, PChar('DRAG'));
  Screen.Cursors[crMDragCursor] := LoadCursor(hInstance, PChar('MDRAG'));
  Screen.Cursors[crDragAdd] := LoadCursor(hInstance, PChar('DRAGADD'));
  Screen.Cursors[crMDragAdd] := LoadCursor(hInstance, PChar('MDRAGADD'));
end;

procedure TLampsMainForm.PopulateLampArray;
begin
  LoadFromText(AllFileName, LampArray, TotalLamps);
  AllFileAge := FileAge(AllFileName);
end;

procedure TLampsMainForm.ClearGroupAddresses;
var
  I: Integer;
  P: PLampRec;
begin
  for I := 0 to TotalLamps - 1 do
  begin
    P := @LampArray[I];
    P^.Group0Address := $FF;
    P^.Group1Address := $FF;
    P^.Group2Address := $FF;
    P^.Group3Address := $FF;
  end;
end;

procedure TLampsMainForm.PopulateGroupAddresses;
var
  A, G, I, J: Integer;
  P: PLampRec;
  R: TSearchRec;
  S, SS: String;
begin
  ClearGroupAddresses;
  I := FindFirst(GroupFileMask, faAnyFile and
    not (faDirectory + faVolumeID), R);
  try
    while I = 0 do
    begin
      S := FileNameByGroupCaption(Copy(R.Name, 1, Length(R.Name) - 4));
      if FileExists(S) then with TStringList.Create do
      try
        LoadFromFile(S);
        A := -1;
        for I := 0 to Count - 1 do
        begin
          S := Strings[I];
          J := Pos(RemChar, S);
          if J <> 0 then SetLength(S, J - 1);
          J := Pos(GroupAddressDirective, Uppercase(S));
          if J <> 0 then
          begin
            A := StrToIntDef(Trim(
              Copy(S, J + Length(GroupAddressDirective), 255)), -1);
            Break;
          end;
        end;
        if A <> -1 then for I := 0 to Count - 1 do
        begin
          S := Strings[I];
          J := Pos(RemChar, S);
          if J <> 0 then SetLength(S, J - 1);
          J := Pos(SepChar, S);
          if J <> 0 then
          begin
            SS := Trim(Copy(S, 1, J - 1));
            G := StrToIntDef(Trim(Copy(S, J + 1, 255)), -1);
            if (G >= 0) and (G <= 3) then
            begin
              J := LampIndexByLampName(SS);
              if J <> -1 then
              begin
                P := @LampArray[J];
                case G of
                  0: if P^.Group0Address = $FF then P^.Group0Address := A;
                  1: if P^.Group1Address = $FF then P^.Group1Address := A;
                  2: if P^.Group2Address = $FF then P^.Group2Address := A;
                  else if P^.Group3Address = $FF then P^.Group3Address := A;
                end;
              end;
            end;
          end;
        end;
      finally
        Free;
      end;
      I := FindNext(R);
    end;
  finally
    FindClose(R);
  end;
end;

procedure TLampsMainForm.PopulateTreeView(C: Integer);
var
  I, J: Integer;
  N: TTreeNode;
  P: PLampRec;
  R: TSearchRec;
  GroupName, GroupNodeCaption, S: String;
  FoundArray: Array[0..MaxLamps - 1] of Boolean;
begin
  PopulatingTree := True;
  with TreeView1, Items do
  try
    FillChar(FoundArray, SizeOf(FoundArray), 0);
    BeginUpdate;
    try
      Clear;

      I := FindFirst(GroupFileMask, faAnyFile and
        not (faDirectory + faVolumeID), R);
      try
        while I = 0 do
        begin
          GroupNodeCaption := Copy(R.Name, 1, Length(R.Name) - 4);
          GroupName := FileNameByGroupCaption(GroupNodeCaption);
          N := Add(nil, GroupNodeCaption);
          N.ImageIndex := -1;
          N.StateIndex := -1;
          N.SelectedIndex := -1;
          N.Data := Pointer(GetGroupAddress(GroupName));
          N.HasChildren := True;
          MakeNodeBold(N, True);

          with TStringList.Create do
          try
            LoadFromFile(GroupName);
            for I := 0 to Count - 1 do
            begin
              S := Strings[I];
              if Pos(GroupAddressDirective, Uppercase(S)) <> 0 then
                Continue;
              J := Pos(RemChar, S);
              if J <> 0 then SetLength(S, J - 1);
              J := Pos(SepChar, S);
              if J <> 0 then
              begin
                S := Trim(Copy(S, 1, J - 1));
                J := LampIndexByLampName(S);
                if J <> -1 then
                begin
                  P := @LampArray[J];
                  with AddChild(N, P^.Name) do
                  begin
                    Data := P;
                    ImageIndex := -1;
                    StateIndex := -1;
                    SelectedIndex := -1;
                  end;
                  FoundArray[J] := True;
                end;
              end;
            end;
          finally
            Free;
          end;

          if N.HasChildren and
             ((Uppercase(GroupNodeCaption) = Uppercase(ExpandNode1)) or
              (Uppercase(GroupNodeCaption) = Uppercase(ExpandNode2))) then
            N.Expand(False);

          I := FindNext(R);
        end;
      finally
        FindClose(R);
      end;

      for I := 0 to C - 1 do
      begin
        if FoundArray[I] then Continue;
        P := @LampArray[I];
        if P <> nil then with Add(nil, P^.Name) do
        begin
          Data := P;
          ImageIndex := -1;
          StateIndex := -1;
          SelectedIndex := -1;
        end;
      end;
    finally
      EndUpdate;
      ExpandNode1 := '';
      ExpandNode2 := '';
    end;
  finally
    PopulatingTree := False;
  end;
end;

procedure TLampsMainForm.PopulateLampListView(L: TListView;
  const A: TLampArray; C: Integer);
var
  I: Integer;
  P: PLampRec;
begin
  with L, Items do
  begin
    BeginUpdate;
    try
      Clear;
      Columns[0].Width := 80;
      for I := 0 to C - 1 do
      begin
        if @A = @LampArray then P := @A[I]
        else P := PLampRecByArrayRec(@A[I]);
        if P <> nil then with Add do
        begin
          Caption := P^.Name;
          Data := P;
//          Checked := P^.Lit;
          ImageIndex := -1; //9; //IndexByPosition(P^.Brightness);
          SubItems.Add(IntToStr(P^.Address));
        end;
      end;
// Ensure the first item is selected
      if not ReloadingAll and (Count <> 0) then
      begin
        Selected := Items[0];
        Selected.Focused := True;
// Autosize columns by item width and column header
//        Columns[0].Width := -1;
      end;
//      else Columns[0].Width := -2;
      Columns[1].Width := -2;
    finally
      EndUpdate;
    end;
  end;

  if L = ListView1 then 
  begin
    PopulateTreeView(C);
    with TreeView1, Items do
// Ensure the first item is selected
      if not ReloadingAll and (Count <> 0) then
      begin
        Selected := Items[0];
        Selected.Focused := True;
        MakeNodeVisible(Selected);
      end;
  end;
end;

procedure TLampsMainForm.PopulateGroupListView(L: TListView);
var
  I: Integer;
  R: TSearchRec;
begin
  with L, Items do
  begin
    BeginUpdate;
    try
      Clear;
      Columns[0].Width := 80;
      I := FindFirst(GroupFileMask, faAnyFile and
        not (faDirectory + faVolumeID), R);
      try
        while I = 0 do
        begin
          with Add do
          begin
            Caption := Copy(R.Name, 1, Length(R.Name) - 4);
            ImageIndex := -1; //10;
            SubItems.Add(IntToStr(GetGroupAddress(
              FileNameByGroupCaption(Caption))));
          end;
          I := FindNext(R);
        end;
      finally
        FindClose(R);
      end;
// Ensure the first item is selected
      if not ReloadingAll and (Count <> 0) then
      begin
        Selected := Items[0];
        Selected.Focused := True;
// Autosize columns by item width and column header
//        Columns[0].Width := -1;
      end;
//      else Columns[0].Width := -2;
      Columns[1].Width := -2;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TLampsMainForm.PopulateStateListView(L: TListView);
var
  A, I, J, N, Q, Y: Integer;
  R: TLampParamRec;
  P: PLampParamRec;
  S, SectionStr: String;
begin
  AbortGet := True;
  if SelectedLampItem = nil then A := $3FF
  else A := LampAddressByLampItem(SelectedLampItem);

  with L, Items do
  begin
    if Selected = nil then Y := -1
    else Y := Selected.Index;
    BeginUpdate;
    try
      Clear;
      Columns[0].Width := 96;
      with Add do
      begin
        Caption := 'State';
        ImageIndex := -1;
        SubItems.Add('');
        Checked := True;
      end;
      with Add do
      begin
        Caption := 'Alarm';
        ImageIndex := -1;
        SubItems.Add('');
        Checked := True;
      end;

      with TIniFile.Create(StateFileName) do
      try
        Q := 0;
        for N := 0 to A do
        begin
          SectionStr := Format('State%.03d', [N]);
          if SectionExists(SectionStr) then Q := N;
        end;
        SectionStr := Format('State%.03d', [Q]);

        for I := 0 to 15 do
          StateStrings[I] := ReadString(
            SectionStr, 'StateString' + IntToStr(I), StateStrings[I]);
        for I := 0 to 15 do
          AlarmStrings[I] := ReadString(
            SectionStr, 'AlarmString' + IntToStr(I), AlarmStrings[I]);

        for I := 0 to 255 do
        begin
// these fields MUST be defined
          S := ReadString(
            SectionStr, 'Param' + IntToStr(I) + 'Name', '');
          if S = '' then Break;
          R.Name := S;
          R.Address := ReadInteger(
            SectionStr, 'Param' + IntToStr(I) + 'Address', -1);
          if R.Address = -1 then Break;
          S := ReadString(
            SectionStr, 'Param' + IntToStr(I) + 'Multiplier', '');
          if S = '' then Break;
          Val(S, R.Multiplier, J);
          if J <> 0 then Break;
          S := ReadString(
            SectionStr, 'Param' + IntToStr(I) + 'Format', '');
          if S = '' then Break;
          R.Format := S;
// these fields MAY be defined
          S := ReadString(
            SectionStr, 'Param' + IntToStr(I) + 'Min', '');
          if S = '' then R.Min := 0
          else Val(S, R.Min, J);
          S := ReadString(
            SectionStr, 'Param' + IntToStr(I) + 'Max', '');
          if S = '' then R.Max := 255.0 * R.Multiplier
          else Val(S, R.Max, J);
          S := ReadString(
            SectionStr, 'Param' + IntToStr(I) + 'Lo', '');
          if S = '' then R.Lo := R.Max * 0.1
          else Val(S, R.Lo, J);
          S := ReadString(
            SectionStr, 'Param' + IntToStr(I) + 'Hi', '');
          if S = '' then R.Hi := R.Max * 0.9
          else Val(S, R.Hi, J);
          R.Digits := ReadInteger(
            SectionStr, 'Param' + IntToStr(I) + 'Digits', 0);
          R.MajorTicks := ReadInteger(
            SectionStr, 'Param' + IntToStr(I) + 'MajorTicks', 5);
          R.MinorTicks := ReadInteger(
            SectionStr, 'Param' + IntToStr(I) + 'MinorTicks', 4);
          R.Value := R.Min;
          R.Attempts := 0;

          GetMem(P, SizeOf(TLampParamRec));
          P^ := R;
          P^.Meter := nil;
          with Add do
          begin
            Caption := R.Name;
            Data := P;
            ImageIndex := -1;
            SubItems.Add('');
            Checked := True;
          end;
        end;
      finally
        Free;
      end;
      StateFileAge := FileAge(StateFileName);

// Ensure the Y item is selected
      if Count <> 0 then
      begin
        if (Y < 0) or (Y >= Count) then Y := 0;
        Selected := Items[Y];
        Selected.Focused := True;
// Autosize columns by item width and column header
//        Columns[0].Width := -1;
      end;
//      else Columns[0].Width := -2;
      Columns[1].Width := -2;

      SetMeters;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TLampsMainForm.PopulateEEListView(L: TListView);
var
  A, I, J, N: Integer;
  R: TLampParamRec;
  P: PLampParamRec;
  S, SectionStr: String;
begin
  if SelectedLampItem = nil then Exit;
  EESection := 0;
  A := LampAddressByLampItem(SelectedLampItem);

  with L, Items do
  begin
    BeginUpdate;
    try
      Clear;

      with TIniFile.Create(EEFileName) do
      try
        for N := 0 to A do
        begin
          SectionStr := Format('EE%.03d', [N]);
          if SectionExists(SectionStr) then EESection := N;
        end;
        SectionStr := Format('EE%.03d', [EESection]);
        for I := 0 to 255 do
        begin
          S := ReadString(
            SectionStr, 'Param' + IntToStr(I) + 'Name', '');
          if S = '' then Break;
          R.Name := S;
          R.Address := ReadInteger(
            SectionStr, 'Param' + IntToStr(I) + 'Address', -1);
          if R.Address = -1 then Break;
          S := ReadString(
            SectionStr, 'Param' + IntToStr(I) + 'Multiplier', '');
          if S = '' then Break;
          Val(S, R.Multiplier, J);
          if J <> 0 then Break;
          S := ReadString(
            SectionStr, 'Param' + IntToStr(I) + 'Format', '');
          if S = '' then Break;
          R.Format := S;
          S := ReadString(
            SectionStr, 'Param' + IntToStr(I) + 'Default', '0');
          Val(S, R.Default, J);
          R.Value := R.Min;

          GetMem(P, SizeOf(TLampParamRec));
          P^ := R;
          P^.Meter := nil;
          with Add do
          begin
            Caption := R.Name;
            Data := P;
            ImageIndex := -1;
            SubItems.Add('');
            Checked := True;
          end;
        end;
      finally
        Free;
      end;
      EEFileAge := FileAge(EEFileName);

// Ensure the first item is selected
      if Count <> 0 then
      begin
        Selected := Items[0];
        Selected.Focused := True;
        with EEForm do
        begin
          GetAction.Enabled := True;
          SetAction.Enabled := True;
        end;
      end
      else with EEForm do
      begin
        GetAction.Enabled := False;
        SetAction.Enabled := False;
      end;
      Columns[1].Width := -2;

    finally
      EndUpdate;
    end;
  end;
end;

procedure TLampsMainForm.PopulateEETestList;
var
  A, I, J, N: Integer;
  R: TLampParamRec;
  P: PLampParamRec;
  S, SectionStr: String;
begin
  FillChar(EETestValueArray, SizeOf(EETestValueArray), $FF);
  EETestSection := 0;
  with EETestList do
  begin
    FreeAll;
    TrackBar1Change(nil);
    if SelectedLampItem = nil then A := $3FF
    else A := LampAddressByLampItem(SelectedLampItem);
    with TIniFile.Create(EETestFileName) do
    try
      for N := 0 to A do
      begin
        SectionStr := Format('EE%.03d', [N]);
        if SectionExists(SectionStr) then EETestSection := N;
      end;
      SectionStr := Format('EE%.03d', [EETestSection]);
      for I := 0 to 255 do
      begin
        S := ReadString(
          SectionStr, 'Param' + IntToStr(I) + 'Name', '');
        if S = '' then Break;
        R.Name := S;
        R.Address := ReadInteger(
          SectionStr, 'Param' + IntToStr(I) + 'Address', -1);
        if R.Address = -1 then Break;
        S := ReadString(
          SectionStr, 'Param' + IntToStr(I) + 'Multiplier', '');
        if S = '' then Break;
        Val(S, R.Multiplier, J);
        if J <> 0 then Break;
        S := ReadString(
          SectionStr, 'Param' + IntToStr(I) + 'Format', '');
        if S = '' then Break;
        R.Format := S;
        S := ReadString(
          SectionStr, 'Param' + IntToStr(I) + 'Default', '0');
        Val(S, R.Default, J);

        GetMem(P, SizeOf(TLampParamRec));
        P^ := R;
        P^.Meter := nil;
        Add(P);
      end;
    finally
      Free;
    end;
  end;
  TrackBar1Change(nil);
  EETestFileAge := FileAge(EETestFileName);
end;

procedure TLampsMainForm.PopulateNetworkStateList;
var
  I, J, K: Integer;
  L: TStringList;
  Q: PNetworkStateRec;
  P: PNetworkFieldRec;
  R: TNetworkFieldRec;
  SectionStr, S: String;
begin
  NetAbortGet := True;
  NetworkStateList.FreeAll;
  with TIniFile.Create(NetStateFileName) do
  try
    L := TStringList.Create;
    try
      ReadSections(L);
      for K := 0 to L.Count - 1 do
      begin
        SectionStr := L.Strings[K];
        if (Length(SectionStr) = 11) and
           (Uppercase(Copy(SectionStr, 1, 8)) = 'NETSTATE') then
        begin
          GetMem(Q, SizeOf(TNetworkStateRec));
          Q^.Address := StrToIntDef(Copy(SectionStr, 9, 3), 0);
          Q^.NetStateStrings := TStringList.Create;
          Q^.NetAlarmStrings := TStringList.Create;
          Q^.NetworkFieldList := TNetworkFieldList.Create;
          NetworkStateList.Add(Q);

          for I := 0 to 15 do
          begin
            Q^.NetStateStrings.Add(
              ReadString(SectionStr, 'StateString' + IntToStr(I), ''));
            Q^.NetAlarmStrings.Add(
              ReadString(SectionStr, 'AlarmString' + IntToStr(I), ''));
          end;

          for I := 0 to 255 do
          begin
// these fields MUST be defined
            S := ReadString(
              SectionStr, 'Param' + IntToStr(I) + 'Name', '');
            if S = '' then Break;
            R.Name := S;
            R.Address := ReadInteger(
              SectionStr, 'Param' + IntToStr(I) + 'Address', -1);
            if R.Address = -1 then Break;
            S := ReadString(
              SectionStr, 'Param' + IntToStr(I) + 'Multiplier', '');
            if S = '' then Break;
            Val(S, R.Multiplier, J);
            if J <> 0 then Break;
            S := ReadString(
              SectionStr, 'Param' + IntToStr(I) + 'Format', '');
            if S = '' then Break;
            R.Format := S;
// these fields MAY be defined
            S := ReadString(
              SectionStr, 'Param' + IntToStr(I) + 'LoFail', '');
            if S = '' then R.LoFail := 0
            else Val(S, R.LoFail, J);
            S := ReadString(
              SectionStr, 'Param' + IntToStr(I) + 'HiFail', '');
            if S = '' then R.HiFail := 255.0 * R.Multiplier
            else Val(S, R.HiFail, J);
            S := ReadString(
              SectionStr, 'Param' + IntToStr(I) + 'LoWarn', '');
            if S = '' then R.LoWarn := R.HiFail * 0.1
            else Val(S, R.LoWarn, J);
            S := ReadString(
              SectionStr, 'Param' + IntToStr(I) + 'HiWarn', '');
            if S = '' then R.HiWarn := R.HiFail * 0.9
            else Val(S, R.HiWarn, J);
            R.Attempts := 0;
            GetMem(P, SizeOf(TNetworkFieldRec));
            P^ := R;
            Q^.NetworkFieldList.Add(P);
          end;
        end;
      end;
    finally
      L.Free;
    end;
  finally
    Free;
  end;
  NetStateFileAge := FileAge(NetStateFileName);
end;

procedure TLampsMainForm.PopulateNetworkListView(L: TListView);
var
  I, J, C1, C2: Integer;
  P: PLampRec;
  Q: PNetworkStateRec;
  R: PNetworkFieldRec;
  A1, A2: TLampArray;

function CanAddColumn(const S: String): Boolean;
var
  K: Integer;
begin
  Result := True;
  with ListView5, Columns do
    if Count >= 19 then Result := False
    else for K := 0 to Count - 1 do
      if Columns[K].Caption = S then
      begin
        Result := False;
        Exit;
      end;
end;

procedure AddColumn(const S: String; ImgIndex, Wid: Integer);
begin
  with ListView5, Columns, Add do
  begin
    AutoSize := False;
    Caption := S;
    ImageIndex := ImgIndex;
    Width := Wid;
  end;
end;

begin
  PopulateNetworkStateList;

  NetSelectedGroupItem := SelectedGroupItem;
  NetGroup := NetworkGroupItem.Checked;
  C2 := 0;
  if (NetSelectedGroupItem <> nil) and NetGroup then
  begin
    LoadFromText(FileNameByGroupCaption(NetSelectedGroupItem.Caption), A1, C1);
    AppendArray(A1, A2, C1, C2, False);
  end;

  with ListView5, Items do
  begin
    BeginUpdate;
    try
      for I := 0 to Columns.Count - 1 do Columns[I].AutoSize := False;
      Clear;
      Columns.Clear;
      AddColumn('Lamps', 9, 96);
      AddColumn('State', 32, 80);
      AddColumn('Alarm', 33, 80);
      for I := 0 to NetworkStateList.Count - 1 do
      begin
        Q := NetworkStateList.Items[I];
        for J := 0 to Q^.NetworkFieldList.Count - 1 do
        begin
          R := Q^.NetworkFieldList.Items[J];
          if CanAddColumn(R^.Name) then AddColumn(R^.Name, 18, 72);
        end;
      end;

      for I := 0 to TotalLamps - 1 do
      begin
        P := @LampArray[I];
        if NetGroup then P := PLampRecInArray(P, A2, C2);
        if P <> nil then with Add do
        begin
          Caption := P^.Name;
          Data := P;
          Checked := Pos(';' + P^.Name + ';',
            NetworkUncheckedLamps.Caption) = 0;
          if Checked then ImageIndex := 38 else ImageIndex := 39;
          for J := 1 to Columns.Count - 1 do SubItems.Add('');
        end;
      end;
      if Count <> 0 then
      begin
        Selected := Items[0];
        Selected.Focused := True;
      end;

      for I := 0 to Columns.Count - 1 do
      begin
        Columns[I].AutoSize := (I = 0) or
          (Pos(';' + Columns[I].Caption + ';',
           NetworkHiddenColumns.Caption) = 0);
        if not Columns[I].AutoSize then Columns[I].Width := 0;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TLampsMainForm.PopulateScheduleList(const FileName: String);
var
  Missing, Invalid: Boolean;
  I, J: Integer;
  P: PScheduleRec;
  R: TScheduleRec;
  S, Minute, Hour, Day, Month, WeekDay, Year,
  Action, Data, Address, Group, RepeatSeconds: String;

procedure NextField(var FS: String);
begin
  FS := '';
  while (J <= Length(S)) and (S[J] = ' ') do Inc(J);
  while J <= Length(S) do
  begin
    if S[J] = ' ' then Break;
    FS := FS + S[J];
    Inc(J);
  end;
  if FS = '' then
  begin
    Missing := True;
    if ConfMsgBox('File ' + FileName +
      'contains invalid line ' + IntToStr(I + 1) +
      ': one or more schedule fields are missing.'#13#13 +
      'Abort loading schedule data from this file?', False) then Abort;
  end;
end;

procedure NextFieldDef(var FS: String; const DS: String);
begin
  FS := '';
  while (J <= Length(S)) and (S[J] = ' ') do Inc(J);
  while J <= Length(S) do
  begin
    if S[J] = ' ' then Break;
    FS := FS + S[J];
    Inc(J);
  end;
  if FS = '' then FS := DS;
end;

procedure ConvertTimeField(FS: String; var ILo, IHi: Integer);
var
  II: Integer;
begin
  II := Pos('-', FS);
  if II > 1 then
  begin
    ILo := StrToIntDef(Copy(FS, 1, II - 1), -2);
    IHi := StrToIntDef(Copy(FS, II + 1, 255), -2);
  end
  else
  begin
    ILo := StrToIntDef(FS, -2);
    IHi := ILo;
  end;
  if (ILo = -2) or (IHi = -2) then
  begin
    Invalid := True;
    if ConfMsgBox('File ' + FileName +
      'contains invalid schedule time field in line ' +
      IntToStr(I + 1) +  ': "' + FS + '".'#13#13 +
      'Abort loading schedule data from this file?', False) then Abort;
  end;
end;

procedure ConvertCommandField(FS: String; var FI: Integer);
var
  B: Boolean;
begin
  if FS[Length(FS)] = '%' then
  begin
    SetLength(FS, Length(FS) - 1);
    B := True;
  end
  else B := False;
  FI := StrToIntDef(FS, -2);
  if FI = -2 then
  begin
    Invalid := True;
    if ConfMsgBox('File ' + FileName +
      'contains invalid schedule command field in line ' +
      IntToStr(I + 1) +  ': "' + FS + '".'#13#13 +
      'Abort loading schedule data from this file?', False) then Abort;
  end
  else if B then FI := Round(FI * 255.0 / 100.0);
end;

begin
  ScheduleList.FreeAll;
  with TStringList.Create do
  try
    LoadFromFile(FileName);
    ScheduleFileAge := FileAge(FileName);

    for I := 0 to Count - 1 do
    begin
      S := Strings[I];
      J := Pos('#', S);
      if J <> 0 then SetLength(S, J - 1);
      J := Pos(';', S);
      if J <> 0 then SetLength(S, J - 1);
      if Trim(S) = '' then Continue;
      S := StringReplace(S, '*', '-1', [rfReplaceAll, rfIgnoreCase]);
      S := StringReplace(S, 'on', '1', [rfReplaceAll, rfIgnoreCase]);
      S := StringReplace(S, 'off', '2', [rfReplaceAll, rfIgnoreCase]);
      S := StringReplace(S, 'ee', '1', [rfReplaceAll, rfIgnoreCase]);
      S := StringReplace(S, 'yes', '1', [rfReplaceAll, rfIgnoreCase]);
      S := StringReplace(S, 'no', '0', [rfReplaceAll, rfIgnoreCase]);
      J := 1;
      Missing := False;
      NextField(Minute);
      NextField(Hour);
      NextField(Day);
      NextField(Month);
      NextField(WeekDay);
      NextField(Year);
      NextField(Action);
      NextField(Data);
      NextField(Address);
      NextField(Group);
      NextFieldDef(RepeatSeconds, '0');
      if Missing then Continue;

      Invalid := False;
      ConvertTimeField(Minute, R.LoMinute, R.HiMinute);
      ConvertTimeField(Hour, R.LoHour, R.HiHour);
      ConvertTimeField(Day, R.LoDay, R.HiDay);
      ConvertTimeField(Month, R.LoMonth, R.HiMonth);
      ConvertTimeField(WeekDay, R.LoWeekDay, R.HiWeekDay);
      ConvertTimeField(Year, R.LoYear, R.HiYear);
      ConvertCommandField(Action, R.Action);
      Dec(R.Action);
      ConvertCommandField(Data, R.Data);
      ConvertCommandField(Address, R.Address);
      ConvertCommandField(Group, R.Group);
      ConvertCommandField(RepeatSeconds, R.RepeatSeconds);
      if Invalid then Continue;
      if R.Address = -1 then R.Address := $3FF;

      R.Time := 0;
      GetMem(P, SizeOf(TScheduleRec));
      P^ := R;
      ScheduleList.Add(P);
    end;
  finally
    Free;
  end;
end;

(*
procedure TLampsMainForm.ReadPowerFile;
var
  I, J, Addr: Integer;
  P: PPowerRec;
  R, Mult: Real;
  SectionStr, S, FmtS: String;
begin
  Addr := 4;
  Mult := 4.0;
  FmtS := '%3.0f W';
  with TIniFile.Create(PowerFileName) do
  try
    for I := 0 to MaxLamps - 1 do
    begin
      SectionStr := Format('Power%.03d', [I]);
      if (I = 0) or SectionExists(SectionStr) then
      begin
        GetMem(P, SizeOf(TPowerRec));
        P^.LampAddress := I;
        P^.Address := ReadInteger(SectionStr, 'Address', Addr);
        S := ReadString(SectionStr, 'Multiplier', '');
        Val(S, R, J);
        if J = 0 then P^.Multiplier := R
        else P^.Multiplier := Mult;
        S := ReadString(SectionStr, 'Format', '');
        if S <> '' then P^.Format := S
        else P^.Format := FmtS;
        PowerList.Add(P);
      end;
    end;
  finally
    Free;
  end;
  PowerFileAge := FileAge(PowerFileName);
end;
*)

procedure TLampsMainForm.ListView1ToListView2NewGroup;
var
  T: Boolean;
  C: Integer;
  A: TLampArray;
  P: TListItem;
  S: String;
begin
  T := TreeView1.Focused;
  SelectedToArray(ListView1, A, C, 0);
  if C = 0 then
  begin
    PopulateGroupAddresses;
    Exit;
  end;
  S := GetNewGroupName;
  SaveToText(FileNameByGroupCaption(S), A, C, 0);
  if T then
  begin
    if (TreeView1.Selected <> nil) and
       (TreeView1.Selected.Parent <> nil) then
      ExpandNode1 := TreeView1.Selected.Parent.Text;
    ExpandNode2 := S;
  end;
  PopulateTreeView(TotalLamps);
  P := ListView2.Items.Add;
  with P do
  begin
    Caption := S;
    ImageIndex := -1;//10;
    SubItems.Add('0');
    RenameItemAction.Enabled := False;
    EditCaption; // Just focus new item
    ListView2SelectItem(nil, P, True);
    SyncTreeWithGroupList;
    EditGroupAddress(P, False);
    if T then
      if (TreeView1.Selected <> nil) and
        TreeView1.Selected.HasChildren then
      begin
        RenameLampAction.Enabled := True;
        TreeView1.Selected.EditText;
      end else
    else
    begin
      RenameItemAction.Enabled := True;
      EditCaption;
    end;  
  end;
  PopulateGroupAddresses;
//  PromptForConfig(False);
end;

procedure TLampsMainForm.ListView1ToListView2AddToGroup;
var
  T: Boolean;
  GA, C1, C3, SC: Integer;
  A1, A3: TLampArray;
  S: String;
begin
  T := TreeView1.Focused;
  if ListView2.Selected = nil then Exit;
  GA := GroupAddressByGroupItem(ListView2.Selected);
  SelectedToArray(ListView1, A1, C1, GA);
  if C1 = 0 then
  begin
    PopulateGroupAddresses;
    Exit;
  end;
  ListViewToArray(ListView3, A3, C3);
  SC := C3;
  AppendArray(A1, A3, C1, C3, False);
  if C3 = SC then
  begin
    PopulateGroupAddresses;
    Exit;
  end;
  S := ListView2.Selected.Caption;
  SaveToText(FileNameByGroupCaption(S), A3, C3, GA);
  PopulateGroupAddresses;
  ListView2SelectItem(nil, ListView2.Selected, True);
  if T then
  begin
    if (TreeView1.Selected <> nil) and
       (TreeView1.Selected.Parent <> nil) then
      ExpandNode1 := TreeView1.Selected.Parent.Text;
    ExpandNode2 := S;
  end;
  PopulateTreeView(TotalLamps);
  SyncTreeWithGroupList;
  PromptForConfig(False);
end;

function TLampsMainForm.GetNewLampName: String;
var
  Found: Boolean;
  I, J: Integer;
begin
  Result := NewLampNamePattern;
  J := 0;
  repeat
    Found := False;
    for I := 0 to TotalLamps - 1 do
      if Uppercase(LampArray[I].Name) = Uppercase(Result) then
      begin
        Found := True;
        Break;
      end;
    if not Found then Exit;
    Inc(J);
    Result := NewLampNamePattern + IntToStr(J);
  until False;
end;

function TLampsMainForm.GetNewGroupName: String;
var
  Found: Boolean;
  I, J: Integer;
begin
  Result := NewGroupNamePattern;
  J := 0;
  repeat
    Found := False;
    with ListView2 do
      for I := 0 to Items.Count - 1 do
        if Uppercase(Items[I].Caption) = Uppercase(Result) then
        begin
          Found := True;
          Break;
        end;
    if not Found then Exit;
    Inc(J);
    Result := NewGroupNamePattern + IntToStr(J);
  until False;
end;

(*
procedure TLampsMainForm.UpdateListView(L: TListView);
var
  I, ILo, IHi: Integer;
  P: PLampRec;
//  S: String[3];
begin
// Update visible items
  with L do
    if TopItem <> nil then
    begin
      ILo := TopItem.Index;
      IHi := ILo + VisibleRowCount + 1;
      while (ILo <= IHi) and (ILo < Items.Count) do
      begin
        P := Items[ILo].Data;
        if P <> nil then
        begin
          if Items[ILo].Checked <> P^.Lit then
             Items[ILo].Checked := P^.Lit;
          I := IndexByPosition(P^.Brightness);
          if Items[ILo].ImageIndex <> I then
             Items[ILo].ImageIndex := I;
//----------
//          S := IntToStr(P^.Brightness);
//          if Items[ILo].SubItems[0] <> S then
//             Items[ILo].SubItems[0] := S;
        end;
        Inc(ILo);
      end;
    end;
end;
*)

procedure GetPasswordLevel(S: String);
const
  Password = 'Light My Fire';
var
  SS: String;
begin
  PasswordLevel := -1;
  if IgnorePasswordCase then S := Uppercase(S);
  SS := Password;
  if IgnorePasswordCase then SS := Uppercase(SS);
  if S = SS then PasswordLevel := TopLevel
  else if S = SS + ' 0' then PasswordLevel := 0
  else if S = SS + ' 1' then PasswordLevel := 1;
end;

procedure TLampsMainForm.UpdateActionState;
var
  B: Boolean;
begin
  GetPasswordLevel(PasswordEdit.Text);
  B := PasswordLevel >= 0;
  if not B then PasswordEdit.Text := '';
  CreateGroupAction.Enabled := B and
    ((AllPanel.Visible and TreeView1.Visible) or GroupPanel.Visible);
  AddToNewGroupAction.Enabled := B and
    ((TreeView1.Focused and (TreeView1.Selected <> nil) and not
      TreeView1.Selected.HasChildren) or
     (not TreeView1.Visible and (ListView1.Selected <> nil) and
      GroupPanel.Visible));
  AddToSelGroupAction.Enabled := B and GroupPanel.Visible and
    (ListView2.Selected <> nil) and
    ((ListView1.Visible and (ListView1.Selected <> nil)) or
     (TreeView1.Focused and (TreeView1.Selected <> nil) and not
      TreeView1.Selected.HasChildren));
  CreateLampAction.Enabled := B and
    AllPanel.Visible and (TotalLamps < MaxLamps);
  CreateInGroupAction.Enabled := CreateLampAction.Enabled and
    ((GroupPanel.Visible and (ListView2.Selected <> nil)) or
     (TreeView1.Focused and (TreeView1.Selected <> nil) and
     (TreeView1.Selected.HasChildren or
     (TreeView1.Selected.Parent <> nil))));
  DeleteItemAction.Enabled := B and
    ((ListView1.Focused and (ListView1.Selected <> nil)) or
     (TreeView1.Focused and (TreeView1.Selected <> nil)) or
     (ListView2.Focused and (ListView2.Selected <> nil)) or
     (ListView3.Focused and (ListView3.Selected <> nil)));
  RenameLampAction.Enabled := B and
    ((ListView1.Focused and (ListView1.Selected <> nil)) or
     (TreeView1.Focused and (TreeView1.Selected <> nil)));
  RenameItemAction.Enabled := B and
    ListView2.Focused and (ListView2.Selected <> nil);
//  ReloadGroupsAction.Enabled := TreeView1.Focused or ListView2.Focused;  
  ChangeGroupAddressAction.Enabled := B and (SelectedGroupItem <> nil);
  ChangeLampAddressAction.Enabled := B; // and (SelectedLampItem <> nil);
  ClearGroupAddressAction.Enabled := B and (SelectedGroupItem <> nil);
  ClearLampAddressAction.Enabled := B; // and (SelectedLampItem <> nil);
  SelectLampAction.Enabled :=
    (ListView1.Focused and (ListView1.Selected <> nil)) or
    (ListView3.Focused and (ListView3.Selected <> nil)) or
    (TreeView1.Focused and (TreeView1.Selected <> nil));
  SelectGroupAction.Enabled :=
    ListView2.Focused and (ListView2.Selected <> nil);
  EEAction.Enabled := B and (SelectedLampItem <> nil);
  SendAction.Enabled := SelectedLampItem <> nil;
  SendToGroupAction.Enabled := SelectedGroupItem <> nil;
  SetGroup0Action.Enabled := B and (SelectedLampItem <> nil);
  SetGroup1Action.Enabled := B and (SetGroup0Action.Enabled);
  SetGroup2Action.Enabled := B and (SetGroup0Action.Enabled);
  SetGroup3Action.Enabled := B and (SetGroup0Action.Enabled);
  GetAction.Enabled :=
    (not RefreshCheckbox.Checked or not StatePanel.Visible) and
    (not NetRefreshCheckbox.Checked or not NetworkStatusPanel.Visible);
//     and (SelectedLampItem <> nil);
  NetGetAction.Enabled :=
    (not RefreshCheckbox.Checked or not StatePanel.Visible) and
    (not NetRefreshCheckbox.Checked or not NetworkStatusPanel.Visible);
  RunSchedulerAction.Enabled := B and (ScheduleList.Count <> 0);
  ScanNetworkAction.Enabled := B;
  ReadConfigAction.Enabled := B;
  WriteConfigAction.Enabled := B;
  CfgEditAction.Enabled := B;
  PacketTestAction.Enabled := B;
  PropertiesSubmenu.Enabled := B;
  EETestGetAction.Enabled := B and (EETestList.Count <> 0);
  EETestSetAction.Enabled := B and (EETestList.Count <> 0);
  EETestSetDefaultsAction.Enabled := B and (EETestList.Count <> 0);
  EETestOnAction.Enabled := B and (EETestList.Count <> 0);
  EETestOffAction.Enabled := B and (EETestList.Count <> 0);
  EETestTestAction.Enabled := B and (EETestList.Count <> 0);
  EETestLoadAction.Enabled := PasswordLevel = TopLevel;
  EETestSaveDefaultsAction.Enabled := (PasswordLevel = TopLevel) and
    (EETestList.Count <> 0);
  EEForm.LoadAction.Enabled := PasswordLevel = TopLevel;
  EETestPanelItem.Enabled := B;
  if not B and EETestPanel.Visible then EETestPanel.Visible := False;

// Re-enable Del action
  if not ListView1.IsEditing and not ListView2.IsEditing and
     not TreeView1.IsEditing then
    if DeleteItemAction.ShortCut = 0 then
       DeleteItemAction.ShortCut := ShortCut(VK_DELETE, []);
end;

procedure TLampsMainForm.HandleRequests;
var
  Group, Broad, EEReq: Boolean;
  B0, B1, B2: Byte;
  P: PLampRec;
  S: String;
begin
  if EditRequest then
  begin
    EditRequest := False;
    with ListView2 do
      if Selected <> nil then Selected.EditCaption;
  end;
  if TreeEditRequest then
  begin
    TreeEditRequest := False;
    with TreeView1 do
      if Selected <> nil then Selected.EditText;
  end;
  if SendRequest or SendToGroupRequest or BroadcastRequest then
  begin
    Group := SendToGroupRequest;
    Broad := BroadcastRequest;
    EEReq := EESendRequest;
    SendRequest := False;
    SendToGroupRequest := False;
    BroadcastRequest := False;
    EESendRequest := False;

    if Group then SendAddress := GroupAddressByGroupItem(SelectedGroupItem)
    else if SelectedLampItem = nil then SendAddress := $3FF
    else SendAddress := LampAddressByLampItem(SelectedLampItem);
    if SendAddress = $3FF then Broad := True;
    if (SendAddress < 0) and not Broad then Exit;
    if Broad then SendAddress := $3FF;
    if LogONOFFItem.Checked then
    begin
      LogEvent := True;
      if EEReq then LogSourceStr := 'EE test panel'
      else LogSourceStr := 'Control panel';
    end;
    if PropRetryONOFFItem.Checked then
      ForceRetries := StrToIntDef(PropBlockRetriesItem.Text, 1)
    else ForceRetries := 1;
    if ForceRetries < 1 then ForceRetries := 1;
    try
      S := SendLampCommand(SendAddress, SendOnOffCommand,
        SendDimming, Group, Broad, B0, B1, B2);
      if (S <> '') and LogEvent then WriteToLog(
        nil, LogFileName, ' - Error: ' + S);
    finally
      ForceRetries := -1;
      LogEvent := False;
      LogSourceStr := '';
    end;
    if (S <> '') and PropErrMsgItem.Checked then ErrMsgBox(S + '.');
  end;
  if SetGroupRequest then
  begin
    SetGroupRequest := False;
    if SelectedLampItem = nil then Exit;
    P := SelectedLampItem.Data;
    S := SendLampCommand(P^.Address, cmGetRam,
      SetGroupCommand - cmSetGroup0 + 1, False, False, B0, B1, B2);
    if S = '' then SetGroupAddress := B1
    else case SetGroupCommand of
      cmSetGroup0: SetGroupAddress := P^.Group0Address;
      cmSetGroup1: SetGroupAddress := P^.Group1Address;
      cmSetGroup2: SetGroupAddress := P^.Group2Address;
      else SetGroupAddress := P^.Group3Address;
    end;
    if not SetLampGroupAddress(Char(Byte('0') +
      SetGroupCommand - cmSetGroup0), SetGroupAddress) then Exit;
    AddTimeout := 50;
    try
      S := SendLampCommand(SetGroupLampAddress, cmLock, $AA, False, False, B0, B1, B2);
      if S = '' then
      begin
        Pause(StrToIntDef(PropDelayItem.Text, 0));
        S := SendLampCommand(SetGroupLampAddress, SetGroupCommand,
          SetGroupAddress, False, False, B0, B1, B2);
        if S = '' then
        begin
          Pause(StrToIntDef(PropDelayItem.Text, 0));
          S := SendLampCommand(SetGroupLampAddress, cmLock, $55, False, False, B0, B1, B2);
        end;
      end;
    finally
      AddTimeout := 0;
    end;
    if S <> '' then
      if PropErrMsgItem.Checked then ErrMsgBox(S + '.') else
    else
    begin
      case SetGroupCommand of
        cmSetGroup0: P^.Group0Address := SetGroupAddress;
        cmSetGroup1: P^.Group1Address := SetGroupAddress;
        cmSetGroup2: P^.Group2Address := SetGroupAddress;
        else P^.Group3Address := SetGroupAddress;
      end;
      PromptForConfig(True);
    end;
  end;
  if GetRequest then
  begin
    GetRequest := False;
    GetState;
  end;
  if NetGetRequest then
  begin
    NetGetRequest := False;
    NetGetState;
  end;
  if EETestGetRequest then
  begin
    EETestGetRequest := False;
    EETestGet;
  end;
  if EETestSetRequest then
  begin
    EETestSetRequest := False;
    DisplayProgressForm(True);
  end;
  if ConfigRequest then
  begin
    ConfigRequest := False;
    DisplayConnectionForm(False);
  end;
  if NetScanRequest then
  begin
    NetScanRequest := False;
    DisplayConnectionForm(True);
  end;
end;

function TLampsMainForm.GroupExists(const S: String;
  EditedItem: TListItem): Boolean;
var
  I: Integer;
begin
  Result := False;
  with ListView2, Items do
    for I := 0 to Count - 1 do
      if Items[I] <> EditedItem then
        if Uppercase(Items[I].Caption) = Uppercase(S) then
        begin
          Result := True;
          Exit;
        end;
end;

function TLampsMainForm.TreeGroupExists(const S: String;
  EditedNode: TTreeNode): Boolean;
var
  I: Integer;
begin
  Result := False;
  with TreeView1, Items do
    for I := 0 to Count - 1 do
      if Items[I].HasChildren and (Items[I] <> EditedNode) then
        if Uppercase(Items[I].Text) = Uppercase(S) then
        begin
          Result := True;
          Exit;
        end;
end;

procedure TLampsMainForm.EditGroupAddress(EditedItem: TListItem;
  DoClear: Boolean);
var
  B0, B1, B2: Byte;
  A: Integer;
  S: String;
begin
  if EditedItem <> nil then with EditedItem do
  begin
    if DoClear then A := $3FF
    else A := GroupAddressByGroupItem(EditedItem);
    if DoClear or ((A >= 0) and ChangeGroupAddress(A)) then
    begin
      if LogSETItem.Checked then
      begin
        LogEvent := True;
        LogSourceStr := 'Set group addr';
      end;
      AbortGet := True;
      NetAbortGet := True;
      GetDisabled := True;
      try
        S := SendLampCommand($3FF, cmLock, $AA, True, True, B0, B1, B2);
        if S <> '' then
          if PropErrMsgItem.Checked then ErrMsgBox(S + '.') else
        else
        begin
          Pause(StrToIntDef(PropDelayItem.Text, 0));
          S := SendLampCommand(A, cmSetAddr, $55, True, True, B0, B1, B2);
          if S <> '' then
            if PropErrMsgItem.Checked then ErrMsgBox(S + '.') else
          else
          begin
            Pause(StrToIntDef(PropDelayItem.Text, 0));
            S := SendLampCommand(A, cmWriteAddr, $55, True, False, B0, B1, B2);
            if S <> '' then
              if PropErrMsgItem.Checked then ErrMsgBox(S + '.') else
            else
            begin
              Pause(StrToIntDef(PropDelayItem.Text, 0));
              S := SendLampCommand($3FF, cmLock, $55, True, True, B0, B1, B2);
              if S <> '' then
                if PropErrMsgItem.Checked then ErrMsgBox(S + '.') else
              else
              begin
                SubItems[0] := IntToStr(A);
                ModifyGroupAddress(FileNameByGroupCaption(Caption), A);
                PopulateGroupAddresses;
                PromptForConfig(False);
              end;
            end;
          end;
        end;
      finally
        GetDisabled := False;
        LogEvent := False;
        LogSourceStr := '';
      end;
    end;
  end
end;

procedure TLampsMainForm.EditLampAddress(EditedItem: TListItem;
  DoClear: Boolean);
var
  B0, B1, B2: Byte;
  A: Integer;
  P: PLampRec;
  S: String;

function AddrWord: Word;
begin
  WordRec(Result).Lo := B1;
  WordRec(Result).Hi := B2;
end;

begin
//  if EditedItem <> nil then with EditedItem do
  begin
    if EditedItem <> nil then P := EditedItem.Data
    else if (ListView1.Focused and (ListView1.Selected <> nil)) then
      P := ListView1.Selected.Data
    else if (TreeView1.Focused and (TreeView1.Selected <> nil) and
      not TreeView1.Selected.HasChildren and
      (Longint(TreeView1.Selected.Data) > $FF)) then
        P := TreeView1.Selected.Data
    else if (ListView3.Focused and (ListView3.Selected <> nil)) then
      P := ListView3.Selected.Data
    else P := nil;
    if DoClear then A := $3FF
    else if P = nil then A := 0
    else A := P^.Address;
    if LogSETItem.Checked then
    begin
      LogEvent := True;
      LogSourceStr := 'Set addr';
    end;
    AbortGet := True;
    NetAbortGet := True;
    GetDisabled := True;
    try
      if DoClear or ChangeLampAddress(A, P) then
      begin
        S := SendLampCommand($3FF, cmGetRam, $09, False, False, B0, B1, B2);
        if S <> '' then
        begin
          ErrMsgBox(S + ' on attempt to read data from RAM before setting address.');
          Exit;
        end;
        Pause(StrToIntDef(PropDelayItem.Text, 0));
        S := SendLampCommand($3FF, cmLock, $AA, False, True, B0, B1, B2);
        if S <> '' then ErrMsgBox(S + ' on attempt to send LOCK command before setting address.')
        else
        begin
          Pause(StrToIntDef(PropDelayItem.Text, 0));
          S := SendLampCommand(A, cmSetAddr, $55, False, True, B0, B1, B2);
          if S <> '' then ErrMsgBox(S + ' on attempt to send SETADDR command.')
          else
          begin
            Pause(StrToIntDef(PropDelayItem.Text, 0));
            S := SendLampCommand(A, cmWriteAddr, $55, False, False, B0, B1, B2);
            if S <> '' then ErrMsgBox(S + ' on attempt to send WRITEADDR command.')
            else
            begin
              Pause(StrToIntDef(PropDelayItem.Text, 0));
              S := SendLampCommand($3FF, cmLock, $55, False, True, B0, B1, B2);
              if S <> '' then ErrMsgBox(S + ' on attempt to send LOCK command after setting address.')
              else
              begin
                Pause(StrToIntDef(PropDelayItem.Text, 0));
                S := SendLampCommand($3FF, cmGetRam, $09, False, False, B0, B1, B2);
                if S <> '' then ErrMsgBox(S + ' on attempt to read data from RAM after setting address.')
                else if AddrWord <> A then ErrMsgBox('Address verification failure:'#13#13 +
                  'expected: ' + IntToStr(A) + ' (0x' + IntToHex(A, 4) + ')'#13 +
                  'received: ' + IntToStr(AddrWord) + ' (0x' + IntToHex(AddrWord, 4) + ')')
                else if P <> nil then ModifyLampAddress(P, A);
              end;
            end;
          end;
        end;
      end;
    finally
      GetDisabled := False;
      LogEvent := False;
      LogSourceStr := '';
    end;
  end
end;

procedure TLampsMainForm.OnShowHint(Sender: TObject);
var
  I: Integer;
  S: String;
begin
  S := Application.Hint;
  repeat
    I := Pos(#13#10, S);
    if I = 0 then Break;
    S[I] := '.';
    S[I + 1] := ' ';
  until False;
  StatusBar.Panels[0].Caption := S;
end;

var
  Splash: TForm;

procedure ShowSplash(Bitmap: TGraphic;
  const Title, LabelCaption: String);
begin
  Splash := TForm.Create(Application);
  with Splash do
  begin
    Name := 'SplashWindow';
    Caption := Title;
    Color := clWhite;
    Position := poScreenCenter;
    BorderStyle := bsDialog;
    FormStyle := fsStayOnTop;
    BorderIcons := [];
    ClientHeight := Bitmap.Height + 32;
    ClientWidth := Bitmap.Width + 32;
    Cursor := crHourGlass;
    Show;
    with Canvas do
    begin
      Draw(8, 8, Bitmap);
      TextOut(12, Bitmap.Height + 8, LabelCaption);
    end;
  end;
end;

procedure KillSplash;
begin
  if IsWindow(Splash.Handle) then Splash.Free;
end;

const
  UseSplash: Boolean = True;

procedure TLampsMainForm.FormShow(Sender: TObject);
var
  S: String;
begin
  S := 'Loading configuration files...';
  if UseSplash then ShowSplash(AboutDlg.Image1.Picture.Graphic,
    'Lamps', S);
  try
    if not UseSplash then Screen.Cursor := crHourGlass;
    StatusBar.Panels[0].Caption := S;
    try
      StatusBar.Refresh;
      LoadCursors;
      PopulateLampArray;
      PopulateGroupAddresses;
      PopulateLampListView(ListView1, LampArray, TotalLamps);
      PopulateGroupListView(ListView2);
  //    PopulateStateListView(ListView4);
      PopulateNetworkListView(ListView5);
      ComPort.Open := True;
      SLController.Monitoring := True;
      TrackBarChange(nil);
  //    DimmingRadioButtonClick(nil);
      SetMeters;
      CheckAllAction.ShortCut := VK_ADD;
      UncheckAllAction.ShortCut := VK_SUBTRACT;
      with PropPriorityItem do ItemIndex := Tag;
      PropPriorityItemItemClick(nil);
      with PropComPriorityItem do ItemIndex := Tag;
      PropComPriorityItemItemClick(nil);
      ViewFixItemClick(nil);
      if LayoutItem1.Checked then LayoutItem0Click(LayoutItem1)
      else if LayoutItem2.Checked then LayoutItem0Click(LayoutItem2);
    finally
      if not UseSplash then Screen.Cursor := crDefault;
      StatusBar.Panels[0].Caption := '';
    end;
  finally
    if UseSplash then KillSplash;
    UseSplash := False;
  end;
end;

procedure TLampsMainForm.TrackBarChange(Sender: TObject);
(*
var
  B0, B1, B2: Byte;
  I, J: Integer;
  P: PLampRec;
  S: String;
*)
begin
  DimLabel.Caption := IntToStr(TrackBar.Position) + '%';
(*
// Avoid changes when a group of items is selected
  if Selecting or Tracking then Exit;
// Repaint picture
//  PaintBoxPaint(nil);
// Apply changes to those lamps which are pointed to
// by selected items of the most recently active ListView
// if Group ListView is active then apply changes to ListView3
  Tracking := True;
  try
    J := TrackBar.Position;
    if ActiveListView = ListView2 then with ListView3, Items do
    begin
      if ListView2.Selected = nil then Exit;
      I := GroupAddressByGroupItem(ListView2.Selected);
      S := SendLampCommand(I, cmDimm, J, True, False, B0, B1, B2);
      if S <> '' then ErrMsgBox(S)
      else for I := 0 to Items.Count - 1 do
      begin
        P := Items[I].Data;
        if P <> nil then P^.Brightness := J;
      end;
    end
    else if ActiveListView <> nil then with ActiveListView, Items do
{
      if SelCount > 1 then
      begin
        for I := 0 to Items.Count - 1 do
          if Items[I].Selected then
          begin
            P := Items[I].Data;
            if P <> nil then
            begin
              S := SendLampCommand(P^.Address, cmDimm, J, False, False, B0, B1, B2);
              if S <> '' then
              begin
                ErrMsgBox(S);
                Break;
              end
              else P^.Brightness := J;
            end;
          end;
      end
      else} if Selected <> nil then
      begin
        P := Selected.Data;
        if P <> nil then
        begin
          S := SendLampCommand(P^.Address, cmDimm, J, False, False, B0, B1, B2);
          if S <> '' then ErrMsgBox(S)
          else P^.Brightness := J;
        end;
      end;
  finally
    Tracking := False;
  end;
*)
end;

const
  SLSkipCount: Integer = 1;

procedure TLampsMainForm.TimerTimer(Sender: TObject);
var
  I: Integer;
  CanGet: Boolean;
begin
  if not InPopupMessageLoop then with Timer do
  begin
    Enabled := False;
    try
      CanGet := not GetDisabled and not Receiving and
        not AddressForm.Visible and not EEForm.Visible and
        not ComForm.Visible and (ConnectionForm = nil) and
        not EETestTransferring;
      Inc(RefreshCount);
      Inc(NetRefreshCount);
      if RefreshCount >= GetRefreshCount then
      begin
        RefreshCount := 0;
        if CanGet and RefreshCheckBox.Checked and StatePanel.Visible {and
          (SelectedLampItem <> nil)} then GetState;
      end;
      if NetRefreshCount >= GetNetRefreshCount then
      begin
        NetRefreshCount := 0;
        if CanGet and NetRefreshCheckBox.Checked and
          NetworkStatusPanel.Visible then NetGetState;
      end;

//    To be added...
//    Read lamp info via com-port
//    .....

// Update visible items
//      UpdateListView(ListView1);
//      UpdateListView(ListView3);
// Process requests if any
      HandleRequests;
// Update enabled/disabled actions
      UpdateActionState;
// Update INI-file ListViews if necessary
      TrackIniFiles;
// Perform schedule tasks     
      TrackScheduleList;
// Track netgroup
      if (NetGroup <> NetworkGroupItem.Checked) or
         (NetGroup and (NetSelectedGroupItem <> SelectedGroupItem)) then
        PopulateNetworkListView(ListView5);

      if SLSkipCount = 0 then
      begin
        SLSkipCount := 1;
        SLController.Monitoring := False;
        SLController.Monitoring := True;
      end
      else Dec(SLSkipCount);

      if not EETestTransferring and EETestPanel.Visible then
        if EETestChangedSeconds > 0 then
        begin
          I := StrToIntDef(EETestAutoSendTimeItem.Text, 0) * 2;
          if I > 0 then
          begin
            Inc(EETestChangedSeconds);
            if EETestChangedSeconds > I then
              if EETestValueArrayChangeCount = 0 then
                 EETestChangedSeconds := 0
              else
              begin
                EETestChangedSeconds := 1;
                EETestAutoSend := True;
                EETestSetRequest := True;
              end;
          end;
        end;
    finally
      Enabled := True;
    end;
  end;
end;

(*
procedure TLampsMainForm.ListView1SelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
var
  I: Integer;
  P: PLampRec;
begin
  if Selected and (Item <> nil) then
  begin
    P := Item.Data;
    if P = nil then Exit;
    Selecting := True;
    try
//      Switch.StateOn := P^.Lit;
//      TrackBar.Position := P^.Brightness;
      StatePanel.Caption := 'Selected lamp: ' + P^.Name;
      with ListView4, Items do
      begin
        Tag := P^.Address;
        for I := 0 to Count - 1 do Items[I].SubItems[0] := '';
      end;
    finally
      Selecting := False;
    end;
  end;
end;
*)

(*
procedure TLampsMainForm.ListView1Change(Sender: TObject; Item: TListItem;
  Change: TItemChange);
var
  B0, B1, B2: Byte;
  I: Integer;
  P: PLampRec;
  S: String;
begin
  if not ComPort.Open then Exit;
  if Item <> nil then
  begin
    P := Item.Data;
    if P <> nil then
    begin
      if P^.Lit = Item.Checked then Exit;
      if Item.Checked then I := cmOn else I := cmOff;
      S := SendLampCommand(P^.Address, I, 0, False, False, B0, B1, B2);
      if S <> '' then ErrMsgBox(S)
      else P^.Lit := Item.Checked;
      if Item.Selected then Switch.StateOn := Item.Checked;
    end;
  end;
end;
*)

procedure TLampsMainForm.ListView2DragOver(Sender, Source: TObject;
  X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  if not PacketTestAction.Enabled then Accept := False
  else if Source = TreeView1 then
  begin
    Accept := (TreeView1.Selected <> nil) and
      not TreeView1.Selected.HasChildren;
    if Accept then with TreeView1 do
      if (GetKeyState(VK_CONTROL) and $8000 <> 0) or
       (Sender = ListView3) then DragCursor := crDragAdd
      else DragCursor := crDragCursor;
  end
  else if Source = ListView1 then
  begin
    Accept := True;
    with ListView1 do
      if (GetKeyState(VK_CONTROL) and $8000 <> 0) or
         (Sender = ListView3) then
        if SelCount > 1 then DragCursor := crMDragAdd
        else DragCursor := crDragAdd
      else if SelCount > 1 then DragCursor := crMDragCursor
      else DragCursor := crDragCursor;
  end;
end;

procedure TLampsMainForm.ListView2DragDrop(Sender, Source: TObject;
  X, Y: Integer);
begin
  if (Source = ListView1) or (Source = TreeView1) then
    if (GetKeyState(VK_CONTROL) and $8000 <> 0) or
       (Sender = ListView3) then
    begin
      if Sender = ListView2 then with ListView2 do
        if DropTarget <> nil then Selected := DropTarget;
      ListView1ToListView2AddToGroup;
    end
    else ListView1ToListView2NewGroup;
end;

procedure TLampsMainForm.AddToNewGroupActionExecute(Sender: TObject);
begin
  ListView1ToListView2NewGroup;
end;

procedure TLampsMainForm.AddToSelGroupActionExecute(Sender: TObject);
begin
  ListView1ToListView2AddToGroup;
end;

procedure TLampsMainForm.CreateGroupActionExecute(Sender: TObject);
var
  T: Boolean;
  C: Integer;
  A: TLampArray;
  P: TListItem;
  N: TTreeNode;
  S: String;
begin
  T := AllPanel.Visible and TreeView1.Visible;
  S := GetNewGroupName;
  C := 0;
  SaveToText(FileNameByGroupCaption(S), A, C, 0);
  P := ListView2.Items.Add;
  with P do
  begin
    Caption := S;
    ImageIndex := -1;//10;
    SubItems.Add('0');
    N := nil;
    C := TreeView1.Items.Count - 1;
    while C >= 0 do
    begin
      N := TreeView1.Items[C];
      if N.HasChildren then
      begin
        N := N.GetNextSibling;
        Break;
      end;
      Dec(C);
    end;
    if N <> nil then N := TreeView1.Items.Insert(N, S)
    else N := TreeView1.Items.Add(nil, S);
    N.ImageIndex := -1;
    N.StateIndex := -1;
    N.SelectedIndex := -1;
    N.Data := nil;
    N.HasChildren := True;
    MakeNodeBold(N, True);
    if T then TreeView1.Selected := N
    else
    begin
      RenameItemAction.Enabled := False;
      EditCaption; // Just focus new item
    end;
    ListView2SelectItem(nil, P, True);
    EditGroupAddress(P, False);
    C := GroupAddressByGroupItem(P);
    N.Data := Pointer(C);
    if T then
    begin
      RenameLampAction.Enabled := True;
      N.EditText;
    end
    else
    begin
      RenameItemAction.Enabled := True;
      EditCaption;
    end;
  end;
end;

procedure TLampsMainForm.DeleteItemActionExecute(Sender: TObject);
var
  B: Boolean;
  I: Integer;
  C: Integer;
  P: PLampRec;
  N, Q: TTreeNode;
  A: TLampArray;
begin
  if ListView1.Focused and (ListView1.Selected <> nil) then
    with ListView1, Items do
  begin
    if SelCount > 1 then
    begin
      B := PropConfDeleteLampItem.Checked;
      if B and not ConfMsgBox('Delete ' + IntToStr(SelCount) +
        ' selected lamps?', True) then Exit;
      PropConfDeleteLampItem.Checked := False;
      try
        for I := 0 to Count - 1 do
          if Items[I].Selected then
          begin
            P := Items[I].Data;
            DeleteLamp(P);
          end;
      finally
        PropConfDeleteLampItem.Checked := B;
      end;
    end
    else
    begin
      P := Selected.Data;
      if not DeleteLamp(P) then Exit;
    end;
    ReloadAllLists;
  end
  else if TreeView1.Focused and (TreeView1.Selected <> nil) and
    not TreeView1.Selected.HasChildren and
    ((TreeView1.Selected.Parent = nil) or
     (GetKeyState(VK_CONTROL) and $8000 <> 0)) then
  begin
    P := TreeView1.Selected.Data;
    if not DeleteLamp(P) then Exit;
    ReloadAllLists;
  end
  else if TreeView1.Focused and (TreeView1.Selected <> nil) and
    (TreeView1.Selected.Parent <> nil) then with TreeView1, Items do
  begin
    N := Selected.Parent;
    P := Selected.Data;
    if PropConfRemoveItem.Checked and not ConfMsgBox(
      'Remove ' + P^.Name + ' from ' + N.Text + '?', True) then Exit;
    BeginUpdate;
    try
      Selected.Delete;
      N.HasChildren := True;
      Q := nil;
      for I := 0 to Count - 1 do
      begin
        Q := Items[I];
        if not Q.HasChildren and (Q.Data = P) then Break;
        Q := nil;
      end;
      if Q = nil then with Add(nil, P^.Name) do
      begin
        Data := P;
        ImageIndex := -1;
        StateIndex := -1;
        SelectedIndex := -1;
      end;
    finally
      EndUpdate;
    end;
    TreeNodeToArray(N, A, C);
    SaveToText(FileNameByGroupCaption(N.Text), A, C, Longint(N.Data));
    if ListView2.Selected <> nil then
       ListView2SelectItem(nil, ListView2.Selected, True);
  end
  else if ListView2.Focused or (TreeView1.Focused and
    (TreeView1.Selected <> nil) and
     TreeView1.Selected.HasChildren) then with ListView2, Items do
  begin
    if TreeView1.Focused then SyncGroupListWithTree;
    if SelCount > 1 then
    begin
      if PropConfDeleteGroupItem.Checked and not ConfMsgBox(
        'Delete ' + IntToStr(SelCount) +
        ' selected groups?', True) then Exit;
      BeginUpdate;
      try
        B := False;
        for I := Count - 1 downto 0 do
          if Items[I].Selected then
          begin
            if not DeleteFile(FileNameByGroupCaption(
              Items[I].Caption)) then B := True;
            Items[I].Delete;
          end;
      finally
        EndUpdate;
      end;
      if B then ErrMsgBox('Some group files could not be deleted.');
    end
    else if Selected <> nil then
    begin
      if PropConfDeleteGroupItem.Checked and not ConfMsgBox(
        'Delete ' + Selected.Caption + '?', True) then Exit;
      if not DeleteFile(FileNameByGroupCaption(
        Selected.Caption)) then ErrMsgBox('Cannot delete file ' +
          FileNameByGroupCaption(Selected.Caption) + '.');
      Selected.Delete;
    end;
    if ItemFocused <> nil then Selected := ItemFocused
    else PopulateLampListView(ListView3, A, 0);
    if (TreeView1.Selected <> nil) and
       (TreeView1.Selected.Parent <> nil) then
      ExpandNode1 := TreeView1.Selected.Parent.Text;
    PopulateTreeView(TotalLamps);
    SyncTreeWithGroupList;
  end
  else if ListView3.Focused and (ListView2.Selected <> nil) then
    with ListView3, Items do
  begin
    if SelCount > 1 then
    begin
      if PropConfRemoveItem.Checked and not ConfMsgBox(
        'Remove ' + IntToStr(SelCount) +
        ' selected lamps from focused group?', True) then Exit;
      BeginUpdate;
      try
        for I := Count - 1 downto 0 do
          if Items[I].Selected then Items[I].Delete;
      finally
        EndUpdate;
      end;
    end
    else if Selected <> nil then
    begin
      if PropConfRemoveItem.Checked and not ConfMsgBox(
        'Remove ' + Selected.Caption +
        ' from focused group?', True) then Exit;
      Selected.Delete;
    end;
    ListViewToArray(ListView3, A, C);
    SaveToText(FileNameByGroupCaption(
      ListView2.Selected.Caption), A, C,
      GroupAddressByGroupItem(ListView2.Selected));
    if ItemFocused <> nil then Selected := ItemFocused;
    if (TreeView1.Selected <> nil) and
       (TreeView1.Selected.Parent <> nil) then
      ExpandNode1 := TreeView1.Selected.Parent.Text;
    ExpandNode2 := ListView2.Selected.Caption;
    PopulateTreeView(TotalLamps);
  end
  else Exit;
  PopulateGroupAddresses;
  PromptForConfig(False);
end;

procedure TLampsMainForm.ListView2SelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
var
  I, C1, C2: Integer;
  A1, A2: TLampArray;
begin
  with ListView2, Items do
  begin
    C2 := 0;
    for I := 0 to Count - 1 do
      if Items[I].Selected then
      begin
        LoadFromText(FileNameByGroupCaption(Items[I].Caption), A1, C1);
        AppendArray(A1, A2, C1, C2, False);
      end;
  end;
  PopulateLampListView(ListView3, A2, C2);
end;

procedure TLampsMainForm.ActionListUpdate(Action: TBasicAction;
  var Handled: Boolean);
begin
  Handled := True;
  UpdateActionState;
end;

procedure TLampsMainForm.ListView2Editing(Sender: TObject; Item: TListItem;
  var AllowEdit: Boolean);
begin
// Enable Del keystrokes while editing
  if RenameItemAction.Enabled then DeleteItemAction.ShortCut := 0
  else AllowEdit := False;
end;

procedure TLampsMainForm.ListView2Edited(Sender: TObject; Item: TListItem;
  var S: String);
var
  I: Integer;
  N: TTreeNode;
  OldName, NewName: String;
begin
  if Trim(S) = '' then S := Item.Caption;
  if GroupExists(S, Item) then
  begin
    ErrMsgBox('A group with the name "' + S + '" already exists. ' +
      'Please enter a different name for the selected item.');
    S := Item.Caption;
    EditRequest := True;
  end;
  if S <> Item.Caption then
  begin
    for I := 0 to TreeView1.Items.Count - 1 do
    begin
      N := TreeView1.Items[I];
      if N.HasChildren and (Uppercase(N.Text) = Uppercase(Item.Caption)) then
        N.Text := S;
    end;
    NewName := FileNameByGroupCaption(S);
    OldName := FileNameByGroupCaption(Item.Caption);
    if FileExists(OldName) then
      if not RenameFile(OldName, NewName) then ErrMsgBox(
        'Cannot rename file ' + OldName + ' to ' + NewName + '.')
    else ErrMsgBox('File ' + OldName + ' does not exist.');
  end;
end;

(*
procedure TLampsMainForm.ListView1Enter(Sender: TObject);
begin
  if Sender is TListView then
  begin
    ActiveListView := Sender as TListView;
//    if (ActiveListView = ListView1) or (ActiveListView = ListView3) then
//      ListView1SelectItem(ActiveListView, ActiveListView.Selected, True);
  end;
end;
*)

procedure TLampsMainForm.RenameItemActionExecute(Sender: TObject);
begin
  with ListView2 do
    if Selected <> nil then Selected.EditCaption;
end;

procedure TLampsMainForm.ChangeGroupAddressActionExecute(Sender: TObject);
begin
  if SelectedGroupItem <> nil then EditGroupAddress(SelectedGroupItem,
    Sender = ClearGroupAddressAction);
end;

procedure TLampsMainForm.PackettestClick(Sender: TObject);
begin
  ComForm.ShowModal;
end;

procedure TLampsMainForm.ChangeLampAddressActionExecute(Sender: TObject);
begin
//  if SelectedLampItem <> nil then
  EditLampAddress(SelectedLampItem, Sender = ClearLampAddressAction);
end;

procedure TLampsMainForm.SwitchOff(Sender: TObject);
(*
var
  B0, B1, B2: Byte;
  I, J: Integer;
  P: PLampRec;
  S: String;
*)
begin
(*
// Avoid changes when a group of items is selected
  if Selecting then Exit;
  if Switch.StateOn then J := cmOn else J := cmOff;
// Repaint picture
//  PaintBoxPaint(nil);
// Apply changes to those lamps which are pointed to
// by selected items of the most recently active ListView
// if Group ListView is active then apply changes to ListView3
  if ActiveListView = ListView2 then with ListView3, Items do
  begin
    if ListView2.Selected = nil then Exit;
    I := GroupAddressByGroupItem(ListView2.Selected);
    S := SendLampCommand(I, J, 0, True, False, B0, B1, B2);
    if S <> '' then ErrMsgBox(S)
    else for I := 0 to Items.Count - 1 do
    begin
      P := Items[I].Data;
      if P <> nil then P^.Lit := Switch.StateOn;
    end;
  end
  else if ActiveListView <> nil then with ActiveListView, Items do
{
    if SelCount > 1 then
    begin
      for I := 0 to Items.Count - 1 do
        if Items[I].Selected then
        begin
          P := Items[I].Data;
          if P <> nil then
          begin
            S := SendLampCommand(P^.Address, J, 0, False, False, B0, B1, B2);
            if S <> '' then
            begin
              ErrMsgBox(S);
              Break;
            end
            else P^.Lit := Switch.StateOn;
          end;
        end;
    end
    else} if Selected <> nil then
    begin
      P := Selected.Data;
      if P <> nil then
      begin
        S := SendLampCommand(P^.Address, J, 0, False, False, B0, B1, B2);
        if S <> '' then ErrMsgBox(S)
        else P^.Lit := Switch.StateOn;
      end;
    end;
*)
end;

procedure TLampsMainForm.ExitActionExecute(Sender: TObject);
begin
  Close;
end;

procedure TLampsMainForm.ListView4Deletion(Sender: TObject;
  Item: TListItem);
begin
  if Item.Data <> nil then
  begin
    FreeMem(Item.Data, SizeOf(TLampParamRec));
    Item.Data := nil;
  end;
end;

procedure TLampsMainForm.PacketTestActionExecute(Sender: TObject);
begin
  ComForm.ShowModal;
end;

procedure TLampsMainForm.ExceptionHandler(Sender: TObject; E: Exception);
begin
  if E is EAPDException then
  begin
    RefreshCheckBox.Checked := False;
    NetRefreshCheckBox.Checked := False;
    E.Message := 'Windows communications driver ' +
      'reports an error:'#13 + E.Message;
  end;
  Application.ShowException(E);
end;

procedure TLampsMainForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  Application.OnException := ExceptionHandler;
  Application.OnHint := OnShowHint;
  Application.HintHidePause := 10000;
  OnGetDefaultIniName := FSIniFileName;
  PropPortItem.Strings.Clear;
  for I := 1 to 256 do PropPortItem.Strings.Add('COM' + IntToStr(I));
  if FileExists(FSIniFileName) then
  begin
    TBIniLoadPositions(Self, FSIniFileName, '');
    FormStorage.UseRegistry := False;
  end
  else TBRegLoadPositions(Self, HKEY_CURRENT_USER, BaseRegistryKey);
//  PowerList := TPowerList.Create;
  NetworkStateList := TNetworkStateList.Create;
  ScheduleList := TScheduleList.Create;
  EETestList := TLampParamList.Create;
  if Screen.PixelsPerInch > 96 then AxisLabel.Font.Size := 7;
end;

procedure TLampsMainForm.FormDestroy(Sender: TObject);
begin
  if FileExists(FSIniFileName) then
    TBIniSavePositions(Self, FSIniFileName, '')
  else TBRegSavePositions(Self, HKEY_CURRENT_USER, BaseRegistryKey);
  Timer.Enabled := False;
  SLController.Monitoring := False;
  ComPort.Open := False;
  EETestList.Free;
  ScheduleList.Free;
  NetworkStateList.Free;
//  PowerList.Free;
end;

procedure TLampsMainForm.ViewSubmenuPopup(Sender: TTBCustomItem;
  FromLink: Boolean);
begin
  AllLampsPanelItem.Checked := AllPanel.Visible;
  AllGroupsPanelItem.Checked := GroupPanel.Visible;
  SelectedGroupPanelItem.Checked := SelGroupPanel.Visible;
  SelectedLampStatePanelItem.Checked := StatePanel.Visible;
  SelectedLampStateMeterItem.Checked := Meter.Visible;
  NetworkStatusPanelItem.Checked := NetworkStatusPanel.Visible;
  ControlPanelItem.Checked := ControlToolbar.Visible;
  EETestPanelItem.Checked := EETestPanel.Visible;
  MeterPanelItem.Checked := MeterForm.Visible;
  if TreeView1.Visible then AllViewComboList.Text := 'Tree'
  else AllViewComboList.Text := 'List';
end;

procedure TLampsMainForm.AllLampsPanelItemClick(Sender: TObject);
begin
  if not (Sender is TTBXItem) then Exit;
  with Sender as TTBXItem do Checked := not Checked;
  AllPanel.Visible := AllLampsPanelItem.Checked;
  GroupPanel.Visible := AllGroupsPanelItem.Checked;
  SelGroupPanel.Visible := SelectedGroupPanelItem.Checked;
  StatePanel.Visible := SelectedLampStatePanelItem.Checked;
  Meter.Visible := SelectedLampStateMeterItem.Checked;
  NetworkStatusPanel.Visible := NetworkStatusPanelItem.Checked;
  ControlToolbar.Visible := ControlPanelItem.Checked;
  EETestPanel.Visible := EETestPanelItem.Checked;
  MeterForm.Visible := MeterPanelItem.Checked;
  if not Meter.Visible and Splitter.Visible then
  begin
    Splitter.Visible := False;
    ListView4.Align := alClient;
    ListView4.Align := alTop;
  end
  else if Meter.Visible and not Splitter.Visible then
  begin
    Splitter.Visible := True;
    ListView4.Height := StatePanel.Height div 2;
  end;
end;

procedure TLampsMainForm.PropertiesSubmenuPopup(Sender: TTBCustomItem;
  FromLink: Boolean);
begin
  with PropPortItem do Text := ComName(ComPort.ComNumber);
  with PropBaudItem do Text := IntToStr(ComPort.Baud);
  with PropParityItem do Text := Strings[Integer(ComPort.Parity)];
  with PropDataBitsItem do Text := IntToStr(ComPort.DataBits);
  with PropStopBitsItem do Text := IntToStr(ComPort.StopBits);

  PropPriorityItem.ItemIndex := GetThreadPriorityIndex;
  PropComPriorityItem.ItemIndex := Integer(ComPort.ThreadBoost);
end;

function COMNumberByText(const S: String): Word;
var
  I: Integer;
begin
  I := Length(S);
  while (I > 0) and (S[I] in ['0'..'9']) do Dec(I);
  I := StrToIntDef(Copy(S, I + 1, 255), 1);
  if (I < 1) or (I > 65535) then I := 1;
  Result := I;
end;

function ParityByText(const S: String): TParity;
begin
  if S = 'Odd' then Result := pOdd
  else if S = 'Even' then Result := pEven
  else if S = 'Mark' then Result := pMark
  else if S = 'Space' then Result := pSpace
  else Result := pNone;
end;

procedure TLampsMainForm.PropPortItemItemClick(Sender: TObject);
begin
  with PropPortItem do ComPort.ComNumber := COMNumberByText(Text);
  with PropBaudItem do ComPort.Baud := StrToIntDef(Text, ComPort.Baud);
  with PropParityItem do ComPort.Parity := ParityByText(Text);
  with PropDataBitsItem do ComPort.DataBits :=
    StrToIntDef(Text, ComPort.DataBits);
  with PropStopBitsItem do ComPort.StopBits :=
    StrToIntDef(Text, ComPort.StopBits);
end;

procedure TLampsMainForm.AboutActionExecute(Sender: TObject);
begin
  AboutDlg.ShowModal;
end;

procedure TLampsMainForm.SendActionExecute(Sender: TObject);
begin
  if Sender = SendAction then SendRequest := True;
  if Sender = SendToGroupAction then SendToGroupRequest := True;
  if Sender = BroadcastAction then BroadcastRequest := True;
  if Switch.StateOn then SendOnOffCommand := cmOn
  else SendOnOffCommand := cmOff;
  SendDimming := Round(TrackBar.Position * 255.0 / 100.0);
end;

procedure TLampsMainForm.TrackIniFiles;
var
  I: Integer;
begin
  I := FileAge(AllFileName);
  if I <> AllFileAge then ReloadAllLists;
  I := FileAge(StateFileName);
  if I <> StateFileAge then PopulateStateListView(ListView4);
  I := FileAge(NetStateFileName);
  if I <> NetStateFileAge then PopulateNetworkListView(ListView5);
//  I := FileAge(PowerFileName);
//  if I <> PowerFileAge then ReadPowerFile;
  I := FileAge(EEFileName);
  if (I <> EEFileAge) and EEForm.Visible then
    PopulateEEListView(EEForm.ListView);
  I := FileAge(EETestFileName);
  if I <> EETestFileAge then PopulateEETestList;
  I := FileAge(ScheduleFileName);
  if I <> ScheduleFileAge then PopulateScheduleList(ScheduleFileName);
end;

procedure TLampsMainForm.TrackScheduleList;
const
  SecsInDay = 3600 * 24;
var
  RepeatTimeMatches: Boolean;
  B0, B1, B2: Byte;
  I: Integer;
  T: TDateTime;
  P: PScheduleRec;
  L: TScheduleList;
  S: String;
begin
  L := nil;
  try
    if FileExists(SemaphoreFileName) then
    begin
      L := TScheduleList.Create;
      for I := 0 to ScheduleList.Count - 1 do
      begin
        GetMem(P, SizeOf(TScheduleRec));
        P^ := PScheduleRec(ScheduleList.Items[I])^;
        L.Add(P);
      end;
      PopulateScheduleList(SemaphoreFileName);
      DeleteFile(SemaphoreFileName);
    end;

    if SchedulerItem.Checked or (L <> nil) then with ScheduleList do
    begin
      if Count = 0 then Exit;
      if L <> nil then CustomTime := Now;
      if CustomTime = 0 then T := Now
      else T := CustomTime;
      DateTimeToScheduleDateTime(T, T);
      if CustomTime <> 0 then
      begin
        for I := 0 to Count - 1 do
        begin
          P := Items[I];
          if P^.Time = T then Exit;
          if ScheduleRecordMatchesTime(T, P) then
          begin
            if (L <> nil) and LogSemaphoreItem.Checked then
            begin
              LogEvent := True;
              LogSourceStr := 'Semaphore';
            end
            else
            if (L = nil) and LogSchedulerItem.Checked then
            begin
              LogEvent := True;
              LogSourceStr := 'Scheduler';
            end;
            ForceRetries := StrToIntDef(PropBlockRetriesItem.Text, -1);
            try
              S := SendLampCommand(P^.Address, P^.Action, P^.Data,
                P^.Group = 1, P^.Address = $3FF, B0, B1, B2);
              if (S <> '') and LogEvent then WriteToLog(
                nil, LogFileName, ' - Error: ' + S);
            finally
              ForceRetries := -1;
              LogEvent := False;
              LogSourceStr := '';
            end;
            if S = '' then P^.Time := T;
            Pause(StrToIntDef(PropDelayItem.Text, 10));
            if P^.RepeatSeconds > 0 then
            begin
              ScheduleRepeatTime := Now + P^.RepeatSeconds / SecsInDay;
              ScheduleRepeatRec := P^;
            end
            else ScheduleRepeatTime := InfinityTime;
          end;
        end;
        CustomTime := 0;
      end
      else
      begin
        P := @ScheduleRepeatRec;
        RepeatTimeMatches := Now > ScheduleRepeatTime;
        if not RepeatTimeMatches then
        begin
          if Index >= Count then Index := 0;
          P := Items[Index];
          Inc(Index);
          if P^.Time = T then Exit;
        end;
        if RepeatTimeMatches or ScheduleRecordMatchesTime(T, P) then
        begin
          if LogSchedulerItem.Checked then
          begin
            LogEvent := True;
            LogSourceStr := 'Scheduler';
          end;
          ForceRetries := StrToIntDef(PropBlockRetriesItem.Text, -1);
          try
            S := SendLampCommand(P^.Address, P^.Action, P^.Data,
              P^.Group = 1, P^.Address = $3FF, B0, B1, B2);
            if (S <> '') and LogEvent then WriteToLog(
              nil, LogFileName, ' - Error: ' + S);
          finally
            ForceRetries := -1;
            LogEvent := False;
            LogSourceStr := '';
          end;
          if S = '' then P^.Time := T;
          if P^.RepeatSeconds > 0 then
          begin
            ScheduleRepeatTime := Now + P^.RepeatSeconds / SecsInDay;
            ScheduleRepeatRec := P^;
          end
          else ScheduleRepeatTime := InfinityTime;
        end;
      end;

      if L <> nil then
      begin
        FreeAll;
        for I := 0 to L.Count - 1 do
        begin
          GetMem(P, SizeOf(TScheduleRec));
          P^ := PScheduleRec(L.Items[I])^;
          Add(P);
        end;
      end;
    end;
  finally
    L.Free;
  end;
end;

procedure TLampsMainForm.SelectLampActionExecute(Sender: TObject);
var
  I: Integer;
  P: PLampRec;
  L: TListView;
  N: TTreeNode;
begin
  N := nil;
  if TreeView1.Focused then
  begin
    N := TreeView1.Selected;
    if N <> nil then
      if N.HasChildren then
      begin
        SyncGroupListWithTree;
        Sender := SelectGroupAction;
      end
      else
      begin
        SyncAllListWithTree;
        Sender := SelectLampAction;
      end;
  end
  else if ListView1.Focused then
  begin
    SyncTreeWithAllList;
    N := TreeView1.Selected;
  end
  else if ListView2.Focused then
  begin
    SyncTreeWithGroupList;
    N := TreeView1.Selected;
  end;  

  if Sender = SelectGroupAction then
  begin
    with ListView2, Items do
      if Selected <> nil then
      begin
        for I := 0 to Count - 1 do
          if Items[I].ImageIndex = 10 then
          begin
            Items[I].ImageIndex := -1;
            Break;
          end;
        for I := 0 to TreeView1.Items.Count - 1 do
          if TreeView1.Items[I].ImageIndex = 10 then
          begin
            TreeView1.Items[I].ImageIndex := -1;
            TreeView1.Items[I].StateIndex := -1;
            TreeView1.Items[I].SelectedIndex := -1;
          end;

        if (SelectedGroupItem = nil) or
           (SelectedGroupItem <> Selected) then
        begin
          Selected.ImageIndex := 10;
          SelectedGroupItem := Selected;
          if N <> nil then
          begin
            N.ImageIndex := 10;
            N.StateIndex := 10;
            N.SelectedIndex := 10;
          end;
        end
        else SelectedGroupItem := nil;
      end;
  end
  else if Sender = SelectLampAction then
  begin
    if ListView1.Focused or TreeView1.Focused then L := ListView1
    else if ListView3.Focused then L := ListView3
    else Exit;
    AbortGet := True;
    with L, Items do
      if Selected <> nil then
      begin
        if Selected.ImageIndex = 9 then P := nil
        else P := Selected.Data;
        with ListView1, Items do
          for I := 0 to Count - 1 do
            if Items[I].ImageIndex = 9 then
            begin
              Items[I].ImageIndex := -1;
              Break;
            end;
        with ListView3, Items do
          for I := 0 to Count - 1 do
            if Items[I].ImageIndex = 9 then
            begin
              Items[I].ImageIndex := -1;
              Break;
            end;
        if N <> nil then for I := 0 to TreeView1.Items.Count - 1 do
          if TreeView1.Items[I].ImageIndex = 9 then
          begin
            TreeView1.Items[I].ImageIndex := -1;
            TreeView1.Items[I].StateIndex := -1;
            TreeView1.Items[I].SelectedIndex := -1;
          end;
        if P = nil then
        begin
          SelectedLampItem := nil;
          RemoveStateAndMeters;
          PopulateStateListView(ListView4);
          PopulateEETestList;
        end
        else
        begin
          SelectedLampItem := Selected;
          Selected.ImageIndex := 9;
          StatePanel.Caption := 'Selected lamp: ' + P^.Name;
          PopulateStateListView(ListView4);
          PopulateEETestList;
          if N <> nil then
          begin
            N.ImageIndex := 9;
            N.StateIndex := 9;
            N.SelectedIndex := 9;
          end;
        end;
//        with ListView4, Items do
//          for I := 0 to Count - 1 do Items[I].SubItems[0] := '';
      end;
  end;
end;

procedure TLampsMainForm.EEActionExecute(Sender: TObject);
var
  P: PLampRec;
begin
  if SelectedLampItem <> nil then
  begin
//    if ViewFixItem.Checked then EEForm.BorderStyle := bsDialog
//    else EEForm.BorderStyle := bsSizeable;
    P := SelectedLampItem.Data;
    PopulateEEListView(EEForm.ListView);
    if SelectedGroupItem <> nil then
    begin
      EEForm.GroupAddress := GroupAddressByGroupItem(SelectedGroupItem);
      EEForm.Group := EEForm.GroupAddress >= 0;
    end
    else EEForm.Group := False;
    DisplayEEForm(P^.Name, P^.Address);
  end;
end;

procedure TLampsMainForm.SetGroup0ActionExecute(Sender: TObject);
begin
  if Sender is TAction then with Sender as TAction do
  begin
    if SelectedLampItem = nil then Exit;
    SetGroupCommand := cmSetGroup0 + Tag;
    SetGroupLampAddress := LampAddressByLampItem(SelectedLampItem);
    SetGroupRequest := True;
  end;
end;

procedure TLampsMainForm.GetState;
var
  GotState: Boolean;
  B0, B1, B2: Byte;
  W: Word;
  I, J: Integer;
  P: PLampParamRec;
  S: String;

procedure GotError;
var
  I: Integer;
begin
  with ListView4, Items do
  begin
    if (Count > 0) and (Items[0].SubItems[0] <> 'Error') then
      Items[0].SubItems[0] := 'Error';
    if (Count > 1) and (Items[1].SubItems[0] <> S) then
      Items[1].SubItems[0] := CleanString(S);
    for I := 2 to Count - 1 do
    begin
      if Items[I].SubItems[0] <> '' then
         Items[I].SubItems[0] := '';
      P := Items[I].Data;
      if (P <> nil) and (P^.Meter <> nil) then with P^.Meter do
      begin
        Position := 0;
        ValueStr := '';
      end;
    end;
    with Meter do
    begin
      Position := 0;
      ValueStr := '';
    end;
  end;
end;

begin
  GotState := False;
  AbortGet := False;
  if SelectedLampItem = nil then J := $3FF
  else J := LampAddressByLampItem(SelectedLampItem);
  with ListView4, Items do
  begin
    for I := 2 to Count - 1 do
    begin
      if I mod 4 = 0 then TrackScheduleList;
      if Items[I].Checked then
      begin
        P := Items[I].Data;
//S := '';B0:= 1;B1:=I;B2:=0;Pause(10);Application.ProcessMessages;
        S := SendLampCommand(J, cmGetRam, P^.Address, False, False, B0, B1, B2);
        if GetDisabled then Exit;
        if AbortGet then Exit;
        if ReloadingAll then Exit;
        if EETestTransferring then Exit;
        if Application.Terminated then Exit;
        if not StatePanel.Visible then Exit;
        if InPopupMessageLoop then Exit;
        if (GetKeyState(VK_LBUTTON) and $8000 <> 0) or
           (GetKeyState(VK_RBUTTON) and $8000 <> 0) or
           (GetKeyState(VK_ESCAPE) and $8000 <> 0) then Exit;
        if S <> '' then
        begin
          Inc(P^.Attempts);
          if P^.Attempts > StrToIntDef(
            PropRefreshAttemptsItem.Text, 0) then GotError;
        end
        else
        begin
          P^.Attempts := 0;
          if not GotState then
          begin
            if Items[0].Checked then
            begin
              S := StateStrings[B0 and $0F];
              if S <> Items[0].SubItems[0] then Items[0].SubItems[0] := S;
            end;
            if Items[1].Checked then
            begin
              S := AlarmStrings[(B0 and $F0) shr 4];
              if S <> Items[1].SubItems[0] then Items[1].SubItems[0] := S;
            end;
            GotState := True;
          end;
          WordRec(W).Lo := B1;
          WordRec(W).Hi := B2;
          P^.Value := W * P^.Multiplier;
          S := FormatX(P^.Format, P^.Value);
          if S <> Items[I].SubItems[0] then Items[I].SubItems[0] := S;
          if Items[I].Selected then with Meter do
          begin
            Position := W * P^.Multiplier;
            ValueStr := S;
          end;
          if MeterForm.Visible and (P^.Meter <> nil) then with P^.Meter do
          begin
            Position := W * P^.Multiplier;
            ValueStr := S;
          end;
        end;
        Pause(StrToIntDef(PropDelayItem.Text, 10));
      end;
    end;

    if not GotState and (Items[0].Checked or Items[1].Checked) then
    begin
      S := SendLampCommand(J, cmGetRam, 0, False, False, B0, B1, B2);
      if GetDisabled then Exit;
      if AbortGet then Exit;
      if ReloadingAll then Exit;
      if EETestTransferring then Exit;
      if Application.Terminated then Exit;
      if not StatePanel.Visible then Exit;
      if InPopupMessageLoop then Exit;
      if (GetKeyState(VK_LBUTTON) and $8000 <> 0) or
         (GetKeyState(VK_RBUTTON) and $8000 <> 0) or
         (GetKeyState(VK_ESCAPE) and $8000 <> 0) then Exit;
      if S <> '' then GotError
      else
      begin
        if Items[0].Checked then
        begin
          S := StateStrings[B0 and $0F];
          if S <> Items[0].SubItems[0] then Items[0].SubItems[0] := S;
        end;
        if Items[1].Checked then
        begin
          S := AlarmStrings[(B0 and $F0) shr 4];
          if S <> Items[1].SubItems[0] then Items[1].SubItems[0] := S;
        end;
      end;
      Pause(StrToIntDef(PropDelayItem.Text, 10));
    end;
  end;
end;

procedure TLampsMainForm.GetActionExecute(Sender: TObject);
begin
  GetRequest := True;
end;

procedure TLampsMainForm.SetMeter(M: TA3nalogGauge; P: PLampParamRec);
begin
  with M do
  begin
    RedrawDisabled := True;
    try
      if P = nil then
      begin
        ScaleMin := 0;
        ScaleMax := 100;
        Position := 0;
        IndMinimum := 10;
        IndMaximum := 90;
        NumberMainTicks := 5;
        NumberSubTicks := 4;
        Caption := 'No parameter to display';
        ValueStr := '';
        Digits := 0;
        FaceOptions := FaceOptions -
          [ShowIndicatorMin, ShowIndicatorMid,
           ShowIndicatorMax, ShowValues];
      end
      else
      begin
        ScaleMin := P^.Min;
        ScaleMax := P^.Max;
        Position := P^.Value;
        IndMinimum := P^.Lo;
        IndMaximum := P^.Hi;
        NumberMainTicks := P^.MajorTicks;
        NumberSubTicks := P^.MinorTicks;
        Caption := P^.Name;
        ValueStr := FormatX(P^.Format, P^.Value);
        Digits := P^.Digits;
        FaceOptions := FaceOptions +
          [ShowIndicatorMin, ShowIndicatorMid,
           ShowIndicatorMax, ShowValues];
      end;
    finally
      RedrawDisabled := False;
      RedrawScale;
    end;
  end;
end;

procedure TLampsMainForm.SetMeters;
var
  I, J: Integer;
  P: PLampParamRec;
  M: TA3nalogGauge;

procedure SetMeterProperties;
begin
  M.RedrawDisabled := True;
  try
    M.Margin := Meter.Margin;
    M.ArrowWidth := Meter.ArrowWidth;
    M.LengthMainTicks := Meter.LengthMainTicks;
    M.LengthSubTicks := Meter.LengthSubTicks;
    M.CenterRadius := Meter.CenterRadius;
    M.CircleRadius := Meter.CircleRadius;
    M.Font := Meter.Font;

    M.FaceColor := Meter.FaceColor;
    M.MinColor := Meter.MinColor;
    M.MidColor := Meter.MidColor;
    M.MaxColor := Meter.MaxColor;
    M.ArrowColor := Meter.ArrowColor;
    M.CenterColor := Meter.CenterColor;
    M.ValueColor := Meter.ValueColor;
    M.TicksColor := Meter.TicksColor;
    M.CaptionColor := Meter.CaptionColor;
    M.CircleColor := Meter.CircleColor;
    M.MarginColor := Meter.MarginColor;
  finally
    M.RedrawDisabled := False;
    M.RedrawScale;
  end;
end;

begin
  I := 1;
  with ListView4, Items do
  begin
    for J := 0 to Count - 1 do
    begin
      P := PLampParamRec(Items[J].Data);
      if P <> nil then
      begin
        M := TA3nalogGauge(MeterForm.FindComponent(
          'Meter' + IntToStr(I)));
        if M <> nil then
        begin
          P^.Meter := M;
          SetMeterProperties;
          if Items[J].Checked then SetMeter(M, P)
          else SetMeter(M, nil);
          Inc(I);
        end;
      end;
    end;
    for J := I to 9 do
    begin
      M := TA3nalogGauge(MeterForm.FindComponent(
        'Meter' + IntToStr(J)));
      if M <> nil then
      begin
        SetMeterProperties;
        SetMeter(M, nil);
      end;
    end;
  end;
  if SelectedLampItem <> nil then MeterForm.Caption :=
    PLampRec(SelectedLampItem.Data)^.Name + ' meters'
  else MeterForm.Caption := 'Meters';
end;

procedure TLampsMainForm.MeterMarginComboListItemClick(Sender: TObject);
begin
  if Sender = MeterMarginComboList then
    Meter.Margin := StrToIntDef(MeterMarginComboList.Text, 12)
  else if Sender = MeterArrowWidthComboList then
    Meter.ArrowWidth := StrToIntDef(MeterArrowWidthComboList.Text, 1)
  else if Sender = MeterMajorTickLengthComboList then
    Meter.LengthMainTicks := StrToIntDef(MeterMajorTickLengthComboList.Text, 15)
  else if Sender = MeterMinorTickLengthComboList then
    Meter.LengthSubTicks := StrToIntDef(MeterMinorTickLengthComboList.Text, 8)
  else if Sender = MeterCenterRadiusComboList then
    Meter.CenterRadius := StrToIntDef(MeterCenterRadiusComboList.Text, 8)
  else if Sender = MeterCircleRadiusComboList then
    Meter.CircleRadius := StrToIntDef(MeterCircleRadiusComboList.Text, 3)
  else Exit;
  SetMeters;
end;

procedure TLampsMainForm.MeterPopupMenuPopup(Sender: TObject);
begin
  MeterFaceDefaultColorItem.Color := clWhite;
  MeterFaceColorPalette.Color := Meter.FaceColor;
  MeterFaceDefaultColorItem.Checked :=
    Meter.FaceColor = MeterFaceDefaultColorItem.Color;

  MeterLoDefaultColorItem.Color := clGreen;
  MeterLoColorPalette.Color := Meter.MinColor;
  MeterLoDefaultColorItem.Checked :=
    Meter.MinColor = MeterLoDefaultColorItem.Color;

  MeterNormalDefaultColorItem.Color := clYellow;
  MeterNormalColorPalette.Color := Meter.MidColor;
  MeterNormalDefaultColorItem.Checked :=
    Meter.MidColor = MeterNormalDefaultColorItem.Color;

  MeterHiDefaultColorItem.Color := clRed;
  MeterHiColorPalette.Color := Meter.MaxColor;
  MeterHiDefaultColorItem.Checked :=
    Meter.MaxColor = MeterHiDefaultColorItem.Color;

  MeterArrowDefaultColorItem.Color := clBlack;
  MeterArrowColorPalette.Color := Meter.ArrowColor;
  MeterArrowDefaultColorItem.Checked :=
    Meter.ArrowColor = MeterArrowDefaultColorItem.Color;

  MeterCenterDefaultColorItem.Color := clGray;
  MeterCenterColorPalette.Color := Meter.CenterColor;
  MeterCenterDefaultColorItem.Checked :=
    Meter.CenterColor = MeterCenterDefaultColorItem.Color;

  MeterValueDefaultColorItem.Color := clBlack;
  MeterValueColorPalette.Color := Meter.ValueColor;
  MeterValueDefaultColorItem.Checked :=
    Meter.ValueColor = MeterValueDefaultColorItem.Color;

  MeterTicksDefaultColorItem.Color := clBlack;
  MeterTicksColorPalette.Color := Meter.TicksColor;
  MeterTicksDefaultColorItem.Checked :=
    Meter.TicksColor = MeterTicksDefaultColorItem.Color;

  MeterCaptionDefaultColorItem.Color := clBlack;
  MeterCaptionColorPalette.Color := Meter.CaptionColor;
  MeterCaptionDefaultColorItem.Checked :=
    Meter.CaptionColor = MeterCaptionDefaultColorItem.Color;

  MeterCircleDefaultColorItem.Color := clWhite;
  MeterCircleColorPalette.Color := Meter.CircleColor;
  MeterCircleDefaultColorItem.Checked :=
    Meter.CircleColor = MeterCircleDefaultColorItem.Color;

  MeterMarginDefaultColorItem.Color := clGray;
  MeterMarginColorPalette.Color := Meter.MarginColor;
  MeterMarginDefaultColorItem.Checked :=
    Meter.MarginColor = MeterMarginDefaultColorItem.Color;

  MeterMarginComboList.Text := IntToStr(Meter.Margin);
  MeterArrowWidthComboList.Text := IntToStr(Meter.ArrowWidth);
  MeterMajorTickLengthComboList.Text := IntToStr(Meter.LengthMainTicks);
  MeterMinorTickLengthComboList.Text := IntToStr(Meter.LengthSubTicks);
  MeterCenterRadiusComboList.Text := IntToStr(Meter.CenterRadius);
  MeterCircleRadiusComboList.Text := IntToStr(Meter.CircleRadius);
end;

procedure TLampsMainForm.MeterFaceDefaultColorItemClick(Sender: TObject);
begin
  if Sender = MeterFaceDefaultColorItem then
    if Meter.FaceColor <> MeterFaceDefaultColorItem.Color then
       Meter.FaceColor := MeterFaceDefaultColorItem.Color
    else Exit
  else if Sender = MeterLoDefaultColorItem then
    if Meter.MinColor <> MeterLoDefaultColorItem.Color then
       Meter.MinColor := MeterLoDefaultColorItem.Color
    else Exit
  else if Sender = MeterNormalDefaultColorItem then
    if Meter.MidColor <> MeterNormalDefaultColorItem.Color then
       Meter.MidColor := MeterNormalDefaultColorItem.Color
    else Exit
  else if Sender = MeterHiDefaultColorItem then
    if Meter.MaxColor <> MeterHiDefaultColorItem.Color then
       Meter.MaxColor := MeterHiDefaultColorItem.Color
    else Exit
  else if Sender = MeterArrowDefaultColorItem then
    if Meter.ArrowColor <> MeterArrowDefaultColorItem.Color then
       Meter.ArrowColor := MeterArrowDefaultColorItem.Color
    else Exit
  else if Sender = MeterCenterDefaultColorItem then
    if Meter.CenterColor <> MeterCenterDefaultColorItem.Color then
       Meter.CenterColor := MeterCenterDefaultColorItem.Color
    else Exit
  else if Sender = MeterValueDefaultColorItem then
    if Meter.ValueColor <> MeterValueDefaultColorItem.Color then
       Meter.ValueColor := MeterValueDefaultColorItem.Color
    else Exit
  else if Sender = MeterTicksDefaultColorItem then
    if Meter.TicksColor <> MeterTicksDefaultColorItem.Color then
       Meter.TicksColor := MeterTicksDefaultColorItem.Color
    else Exit
  else if Sender = MeterCaptionDefaultColorItem then
    if Meter.CaptionColor <> MeterCaptionDefaultColorItem.Color then
       Meter.CaptionColor := MeterCaptionDefaultColorItem.Color
    else Exit
  else if Sender = MeterCircleDefaultColorItem then
    if Meter.CircleColor <> MeterCircleDefaultColorItem.Color then
       Meter.CircleColor := MeterCircleDefaultColorItem.Color
    else Exit
  else if Sender = MeterMarginDefaultColorItem then
    if Meter.MarginColor <> MeterMarginDefaultColorItem.Color then
       Meter.MarginColor := MeterMarginDefaultColorItem.Color
    else Exit
  else Exit;
  SetMeters;
end;

procedure TLampsMainForm.MeterFaceColorPaletteChange(Sender: TObject);
begin
  if Sender = MeterFaceColorPalette then
    if Meter.FaceColor <> MeterFaceColorPalette.Color then
       Meter.FaceColor := MeterFaceColorPalette.Color
    else Exit
  else if Sender = MeterLoColorPalette then
    if Meter.MinColor <> MeterLoColorPalette.Color then
       Meter.MinColor := MeterLoColorPalette.Color
    else Exit
  else if Sender = MeterNormalColorPalette then
    if Meter.MidColor <> MeterNormalColorPalette.Color then
       Meter.MidColor := MeterNormalColorPalette.Color
    else Exit
  else if Sender = MeterHiColorPalette then
    if Meter.MaxColor <> MeterHiColorPalette.Color then
       Meter.MaxColor := MeterHiColorPalette.Color
    else Exit
  else if Sender = MeterArrowColorPalette then
    if Meter.ArrowColor <> MeterArrowColorPalette.Color then
       Meter.ArrowColor := MeterArrowColorPalette.Color
    else Exit
  else if Sender = MeterCenterColorPalette then
    if Meter.CenterColor <> MeterCenterColorPalette.Color then
       Meter.CenterColor := MeterCenterColorPalette.Color
    else Exit
  else if Sender = MeterValueColorPalette then
    if Meter.ValueColor <> MeterValueColorPalette.Color then
       Meter.ValueColor := MeterValueColorPalette.Color
    else Exit
  else if Sender = MeterTicksColorPalette then
    if Meter.TicksColor <> MeterTicksColorPalette.Color then
       Meter.TicksColor := MeterTicksColorPalette.Color
    else Exit
  else if Sender = MeterCaptionColorPalette then
    if Meter.CaptionColor <> MeterCaptionColorPalette.Color then
       Meter.CaptionColor := MeterCaptionColorPalette.Color
    else Exit
  else if Sender = MeterCircleColorPalette then
    if Meter.CircleColor <> MeterCircleColorPalette.Color then
       Meter.CircleColor := MeterCircleColorPalette.Color
    else Exit
  else if Sender = MeterMarginColorPalette then
    if Meter.MarginColor <> MeterMarginColorPalette.Color then
       Meter.MarginColor := MeterMarginColorPalette.Color
    else Exit
  else Exit;
  SetMeters;
end;

procedure TLampsMainForm.MeterFaceMoreColorsItemClick(Sender: TObject);
begin
  with ColorDialog do
  begin
    if Sender = MeterFaceMoreColorsItem then
    begin
      Color := Meter.FaceColor;
      if Execute then
        if Meter.FaceColor <> Color then Meter.FaceColor := Color
        else Exit;
    end
    else if Sender = MeterLoMoreColorsItem then
    begin
      Color := Meter.MinColor;
      if Execute then
        if Meter.MinColor <> Color then Meter.MinColor := Color
        else Exit;
    end
    else if Sender = MeterNormalMoreColorsItem then
    begin
      Color := Meter.MidColor;
      if Execute then
        if Meter.MidColor <> Color then Meter.MidColor := Color
        else Exit;
    end
    else if Sender = MeterHiMoreColorsItem then
    begin
      Color := Meter.MaxColor;
      if Execute then
        if Meter.MaxColor <> Color then Meter.MaxColor := Color
        else Exit;
    end
    else if Sender = MeterArrowMoreColorsItem then
    begin
      Color := Meter.ArrowColor;
      if Execute then
        if Meter.ArrowColor <> Color then Meter.ArrowColor := Color
        else Exit;
    end
    else if Sender = MeterCenterMoreColorsItem then
    begin
      Color := Meter.CenterColor;
      if Execute then
        if Meter.CenterColor <> Color then Meter.CenterColor := Color
        else Exit;
    end
    else if Sender = MeterValueMoreColorsItem then
    begin
      Color := Meter.ValueColor;
      if Execute then
        if Meter.ValueColor <> Color then Meter.ValueColor := Color
        else Exit;
    end
    else if Sender = MeterTicksMoreColorsItem then
    begin
      Color := Meter.TicksColor;
      if Execute then
        if Meter.TicksColor <> Color then Meter.TicksColor := Color
        else Exit;
    end
    else if Sender = MeterCaptionMoreColorsItem then
    begin
      Color := Meter.CaptionColor;
      if Execute then
        if Meter.CaptionColor <> Color then Meter.CaptionColor := Color
        else Exit;
    end
    else if Sender = MeterCircleMoreColorsItem then
    begin
      Color := Meter.CircleColor;
      if Execute then
        if Meter.CircleColor <> Color then Meter.CircleColor := Color
        else Exit;
    end
    else if Sender = MeterMarginMoreColorsItem then
    begin
      Color := Meter.MarginColor;
      if Execute then
        if Meter.MarginColor <> Color then Meter.MarginColor := Color
        else Exit;
    end
    else Exit;
    SetMeters;
  end;
end;

procedure TLampsMainForm.ListView1Deletion(Sender: TObject;
  Item: TListItem);
begin
  if Item = SelectedLampItem then
  begin
    SelectedLampItem := nil;
    if not Application.Terminated and (Item <> nil) then
    begin
      RemoveStateAndMeters;
      PopulateStateListView(ListView4);
    end;  
  end
  else if Item = SelectedGroupItem then SelectedGroupItem := nil;
end;

procedure TLampsMainForm.ListView1DblClick(Sender: TObject);
begin
  SelectLampActionExecute(SelectLampAction);
end;

procedure TLampsMainForm.ListView2DblClick(Sender: TObject);
begin
  SelectLampActionExecute(SelectGroupAction);
end;

procedure TLampsMainForm.MeterFontItemClick(Sender: TObject);
begin
  with FontDialog do
  begin
    Font.Assign(Meter.Font);
    if Execute then
    begin
      Meter.Font.Assign(Font);
      SetMeters;
    end;  
  end;
end;

procedure TLampsMainForm.ListView4Change(Sender: TObject; Item: TListItem;
  Change: TItemChange);
var
  P: PLampParamRec;
begin
  if Application.Terminated then Exit;
  if Item <> nil then
  begin
    P := Item.Data;
    if not Item.Checked and (Item.SubItems.Count <> 0) then
      Item.SubItems[0] := '';
    if Item.Selected then
    begin
      if Item.Checked then SetMeter(Meter, P)
      else SetMeter(Meter, nil);
    end;
    if (P <> nil) and (P^.Meter <> nil) then
      if (Item.Checked and not (ShowValues in P^.Meter.FaceOptions)) or
         (not Item.Checked and (ShowValues in P^.Meter.FaceOptions)) then
        SetMeters;
  end;
end;

procedure TLampsMainForm.NetGetState;
var
  GotState, ImageChanged: Boolean;
  B0, B1, B2: Byte;
  W: Word;
  I, J, K, ILo, IHi: Integer;
  P: PLampRec;
  R: PNetworkFieldRec;
  Q: PNetworkStateRec;
  V: Real;
  S: String;

procedure GotError;
var
  I, J: Integer;
begin
  with ListView5 do
  begin
//    if Items[ILo].ImageIndex <> -1 then
//       Items[ILo].ImageIndex := -1;
    if (Items.Count > ILo) and (Items[ILo].SubItems[0] <> 'Error') then
      Items[ILo].SubItems[0] := 'Error';
    if (Items.Count > ILo) and (Items[ILo].SubItems[1] <> S) then
      Items[ILo].SubItems[1] := CleanString(S);
    for J := 2 to Items[ILo].SubItems.Count - 1 do
    begin
      if Items[ILo].SubItems[J] <> '' then
         Items[ILo].SubItems[J] := '';
      if Items[ILo].SubItemImages[J] <> -1 then
         Items[ILo].SubItemImages[J] := -1;
    end;
    if UncheckOnErrorItem.Checked then
      if (Items.Count > ILo) and (Items[ILo].Checked) then
      begin
        Items[ILo].Checked := False;
        if Items[ILo].ImageIndex <> 39 then
           Items[ILo].ImageIndex := 39;
        S := ';';
        for I := 0 to Items.Count - 1 do
          if not Items[I].Checked then
            S := S + Items[I].Caption + ';';
        NetworkUncheckedLamps.Caption := S;
      end;
  end;
  GotState := True;
end;

begin
  NetAbortGet := False;
  ImageChanged := False;
  with ListView5 do
  begin
    if TopItem <> nil then
    begin
      if NetworkReadAllItem.Checked then
      begin
        ILo := 0;
        IHi := Items.Count - 1;
      end
      else
      begin
        ILo := TopItem.Index;
        IHi := ILo + VisibleRowCount + 1;
      end;
      while (ILo <= IHi) and (ILo < Items.Count) do
      begin
        if GetDisabled then Exit;
        if NetAbortGet then Exit;
        if ReloadingAll then Exit;
        if EETestTransferring then Exit;
        if Application.Terminated then Exit;
        if not NetworkStatusPanel.Visible then Exit;
        if InPopupMessageLoop then Exit;
        if (GetKeyState(VK_LBUTTON) and $8000 <> 0) or
           (GetKeyState(VK_RBUTTON) and $8000 <> 0) or
           (GetKeyState(VK_ESCAPE) and $8000 <> 0) then Exit;
        if ILo mod 4 = 0 then TrackScheduleList;   
        if Items[ILo].Checked then
        begin
          GotState := False;
          P := Items[ILo].Data;
          Q := nil;
          for I := 0 to NetworkStateList.Count - 1 do
          begin
            Q := NetworkStateList.Items[I];
            if Q^.Address = P^.Address then Break;
            if Q^.Address > P^.Address then
            begin
              if I > 0 then Q := NetworkStateList.Items[I - 1];
              Break;
            end;
          end;
          if Q = nil then Exit;
          for J := 0 to Q^.NetworkFieldList.Count - 1 do
          begin
            R := Q^.NetworkFieldList.Items[J];
            I := 3;
            while I < Columns.Count do
            begin
              if Columns[I].Caption = R^.Name then Break;
              Inc(I);
            end;
            if (I < Columns.Count) and Columns[I].AutoSize then
            begin
//S := '';B0:=1;B1:=I;B2:=0;Application.Processmessages;
              S := SendLampCommand(P^.Address,
                cmGetRam, R^.Address, False, False, B0, B1, B2);
              if GetDisabled then Exit;
              if NetAbortGet then Exit;
              if ReloadingAll then Exit;
              if EETestTransferring then Exit;
              if Application.Terminated then Exit;
              if not NetworkStatusPanel.Visible then Exit;
              if InPopupMessageLoop then Exit;
              if (GetKeyState(VK_LBUTTON) and $8000 <> 0) or
                 (GetKeyState(VK_RBUTTON) and $8000 <> 0) or
                 (GetKeyState(VK_ESCAPE) and $8000 <> 0) then Exit;
              if S <> '' then
              begin
                Inc(R^.Attempts);
                if R^.Attempts > StrToIntDef(
                  PropRefreshAttemptsItem.Text, 0) then GotError;
              end
              else
              begin
                R^.Attempts := 0;
                if not GotState and
                  (Columns[1].AutoSize or Columns[2].AutoSize) then
                begin
                  S := Q^.NetStateStrings[B0 and $0F];
                  if S <> Items[ILo].SubItems[0] then
                    Items[ILo].SubItems[0] := S;
                  S := Q^.NetAlarmStrings[(B0 and $F0) shr 4];
                  if S <> Items[ILo].SubItems[1] then
                    Items[ILo].SubItems[1] := S;
                  GotState := True;
                end;
                WordRec(W).Lo := B1;
                WordRec(W).Hi := B2;
                V := W * R^.Multiplier;
                S := FormatX(R^.Format, V);
                if Items[ILo].SubItems[I - 1] <> S then
                   Items[ILo].SubItems[I - 1] := S;

(*
if (ILo = 1) and (I = 6) then K := 41
else if (ILo = 2) and (I = 4) then K := 44
else if (ILo = 1) and (I = 5) then K := 44
else K := 42;
*)

                if V >= R^.HiFail then K := 44
                else if V >= R^.HiWarn then K := 43
                else if V <= R^.LoFail then K := 40
                else if V <= R^.LoWarn then K := 41
                else K := 42;
                if Items[ILo].SubItemImages[I - 1] <> K then
                begin
                  Items[ILo].SubItemImages[I - 1] := K;
                  ImageChanged := True;
                end;
              end;
              Pause(StrToIntDef(PropDelayItem.Text, 10));
            end;
          end;
          if not GotState and
            (Columns[1].AutoSize or Columns[2].AutoSize) then
          begin
            S := SendLampCommand(P^.Address,
              cmGetRam, 0, False, False, B0, B1, B2);
            if S <> '' then GotError
            else
            begin
              S := Q^.NetStateStrings[B0 and $0F];
              if S <> Items[ILo].SubItems[0] then
                Items[ILo].SubItems[0] := S;
              S := Q^.NetAlarmStrings[(B0 and $F0) shr 4];
              if S <> Items[ILo].SubItems[1] then
                Items[ILo].SubItems[1] := S;
            end;
            Pause(StrToIntDef(PropDelayItem.Text, 10));
          end;
        end;
        Inc(ILo);
      end;
    end;
    if NetworkSortItem.Checked and ImageChanged then
      SortNetworkStateList;
    if NetworkSaveItem.Checked then NetworkSaveAsHTML;
    if LogNetworkItem.Checked then NetworkSaveAsTXT;
  end;
end;

procedure TLampsMainForm.NetGetActionExecute(Sender: TObject);
begin
  NetGetRequest := True;
end;

procedure TLampsMainForm.NetClearActionExecute(Sender: TObject);
var
  I, J: Integer;
begin
  with ListView5, Items do
    for I := 0 to Count - 1 do
    begin
//      if Items[I].ImageIndex <> -1 then Items[I].ImageIndex := -1;
      for J := 0 to Items[I].SubItems.Count - 1 do
      begin
        if Items[I].SubItems[J] <> '' then Items[I].SubItems[J] := '';
        if Items[I].SubItemImages[J] <> -1 then Items[I].SubItemImages[J] := -1;
      end;
    end;    
end;

procedure TLampsMainForm.ClearStatePanel;
var
  I: Integer;
  P: PLampParamRec;
begin
  with ListView4, Items do
    for I := 0 to Count - 1 do
    begin
      if Items[I].SubItems[0] <> '' then
         Items[I].SubItems[0] := '';
      P := Items[I].Data;
      if P <> nil then P^.Value := P^.Min;
    end;
  with Meter do
  begin
    Position := 0;
    ValueStr := '';
  end;
  SetMeters;
end;

procedure TLampsMainForm.RemoveStateAndMeters;
begin
  StatePanel.Caption := 'No lamp selected';
(*
  with ListView4, Items do
    if Count <> 0 then
    begin
      BeginUpdate;
      try
        Clear;
      finally
        EndUpdate;
      end;
    end;
*)    
  SetMeter(Meter, nil);
  SetMeters;
end;

procedure TLampsMainForm.RefreshCheckBoxClick(Sender: TObject);
begin
  if Sender = RefreshCheckBox then
  begin
    ClearStatePanel;
    AbortGet := True;
    RefreshCount := $FF;
  end
  else if Sender = NetRefreshCheckBox then
  begin
    NetClearActionExecute(nil);
    NetAbortGet := True;
    NetRefreshCount := $FF;
  end;
end;

procedure TLampsMainForm.DimmingRadioButtonClick(Sender: TObject);
begin
(*
  with ListView5 do
    if DimmingRadioButton.Checked then
      Columns[3].Caption := 'Dimming'
      else Columns[3].Caption := 'Power';
  if Sender <> nil then NetClearActionExecute(nil);
*)  
end;

procedure TLampsMainForm.MoreMetersActionExecute(Sender: TObject);
begin
  with MeterForm do
  begin
    if Visible then
    begin
      SetFocus;
      if Active then SetForegroundWindow(Handle);
    end
    else Show;
    if WindowState = wsMinimized then WindowState := wsNormal;
  end;
end;

procedure TLampsMainForm.ReadConfigActionExecute(Sender: TObject);
begin
  ConfigRequest := True;
  ConfigRead := Sender = ReadConfigAction;
end;

function TLampsMainForm.BackupGroupFiles: Boolean;
var
  I: Integer;
  R: TSearchRec;
  S: String;
begin
  Result := False;
  if Result then Exit; // Suppress compiler hint
  I := FindFirst(GroupFileMask, faAnyFile and
    not (faDirectory + faVolumeID), R);
  try
    while I = 0 do
    begin
      S := FileNameByGroupCaption(Copy(R.Name, 1, Length(R.Name) - 4));
      CopyFile(S, ChangeFileExt(S, '.BAK'), nil);
      I := FindNext(R);
    end;
    Result := True;
  finally
    FindClose(R);
  end;
end;

function TLampsMainForm.StoreNetworkConfiguration: Boolean;
var
  I, J, N: Integer;
  P: PLampRec;
  R: TSearchRec;
  S: String;
  GroupNames: Array[0..254] of TNameStr;
begin
  Result := False;
  if Result then Exit; // Suppress compiler hint

  FillChar(GroupNames, SizeOf(GroupNames), 0);
  for I := 0 to ListView2.Items.Count - 1 do
  begin
    J := GroupAddressByGroupItem(ListView2.Items[I]);
    if (J >= 0) and (J < 255) and (GroupNames[J] = '') then
      GroupNames[J] := ListView2.Items[I].Caption;
  end;

  I := FindFirst(GroupFileMask, faAnyFile and
    not (faDirectory + faVolumeID), R);
  try
    while I = 0 do
    begin
      S := FileNameByGroupCaption(Copy(R.Name, 1, Length(R.Name) - 4));
      DeleteFile(S);
      I := FindNext(R);
    end;
  finally
    FindClose(R);
  end;

  with TStringList.Create do
  try
    for J := 0 to 254 do
    begin
      Clear;
      for I := 0 to TotalLamps - 1 do
      begin
        P := @LampArray[I];
        N := GroupAddressIndexByGroupAddress(P, J);
        if N <> -1 then Add(Format('%s : %d', [P^.Name, N]));
      end;
      if Count <> 0 then
      begin
        Insert(0, GroupAddressDirective + ' ' + IntToStr(J));
        S := GroupNames[J];
        if S = '' then S := 'Group' + IntToStr(J);
        SaveToFile(FileNameByGroupCaption(S));
      end;
    end;
  finally
    Free;
  end;
  PopulateTreeView(TotalLamps);
  PopulateGroupListView(ListView2);
  Result := True;
end;

const
  ConfigPromptChecks: Array[Boolean] of Boolean = (False, False);
  ConfigPromptFlags: Array[Boolean] of Boolean = (False, False);

procedure TLampsMainForm.PromptForConfig(Read: Boolean);
begin
  Prompt('Perform "' + OperationStrings[Read] +
    ' network configuration" operation ' +
    'to synchronize disk and network data?',
    ConfigPromptChecks[Read], ConfigPromptFlags[Read]);
  if not ConfigPromptFlags[Read] then Exit;
  ConfigRequest := True;
  ConfigRead := Read;
end;

procedure TLampsMainForm.ListView5CheckAll(State: Boolean);
var
  I, J: Integer;
  S: String;
begin
  S := ';';
  with ListView5, Items do
  begin
    for I := 0 to Count - 1 do
    begin
      if Items[I].Checked <> State then Items[I].Checked := State;
      if State then J := 38 else J := 39;
      if Items[I].ImageIndex <> J then Items[I].ImageIndex := J;
      if not State then
      begin
        for J := 0 to Items[I].SubItems.Count - 1 do
        begin
          if Items[I].SubItems[J] <> '' then Items[I].SubItems[J] := '';
          if Items[I].SubItemImages[J] <> -1 then Items[I].SubItemImages[J] := -1;
        end;
        S := S + Items[I].Caption + ';';
      end;
    end;
  end;
  NetworkUncheckedLamps.Caption := S;
end;

procedure TLampsMainForm.CheckAllActionExecute(Sender: TObject);
begin
  ListView5CheckAll(True);
end;

procedure TLampsMainForm.UncheckAllActionExecute(Sender: TObject);
begin
  ListView5CheckAll(False);
end;

procedure TLampsMainForm.ListView1InfoTip(Sender: TObject; Item: TListItem;
  var InfoTip: String);
var
  P: PLampRec;
begin
  if not LampHintItem.Checked then
  begin
    InfoTip := '';
    Exit;
  end;
  if (Item = nil) or (Item.Data = nil) then P := nil
  else P := Item.Data;
  if P <> nil then InfoTip := GetLampInfoTip(P);
end;

function TLampsMainForm.GetRefreshCount: Integer;
begin
  Result := StrToIntDef(Trim(Copy(RefreshComboList.Text, 1, 2)), -1);
  if (Result < 1) or (Result > 30) then Result := 1;
  Result := Result * 2;
end;

function TLampsMainForm.GetNetRefreshCount: Integer;
begin
  Result := StrToIntDef(Trim(Copy(NetRefreshComboList.Text, 1, 2)), -1);
  if (Result < 1) or (Result > 30) then Result := 1;
  Result := Result * 2;
end;

procedure TLampsMainForm.ListView5PopupMenuPopup(Sender: TObject);
var
  I, J, K: Integer;
  P: TTBXItem;
begin
  J := ListView5PopupMenu.Items.IndexOf(NetworkFieldParam01Item);
  if J = -1 then Exit;
  for I := J to J + 17 do
  begin
    P := ListView5PopupMenu.Items[I] as TTBXItem;
    K := I - J + 1;
    with ListView5, Columns do
      if Count <= K then P.Visible := False
      else
      begin
        P.Caption := Columns[K].Caption;
        P.Checked := Columns[K].AutoSize;
      end;
  end;
end;

procedure TLampsMainForm.NetworkFieldParam01ItemClick(Sender: TObject);
var
  I, J: Integer;
  P: TTBXItem;
  S: String;
begin
  if not (Sender is TTBXItem) then Exit;
  P := Sender as TTBXItem;
  I := StrToIntDef(Copy(P.Name, 18, 2), 0);
  with ListView5, Columns do
  begin
    if (I > 0) and (I < Count) then
      if P.Checked then
      begin
        Columns[I].MaxWidth := 0;
        Columns[I].Width := 96;
        Columns[I].AutoSize := True;
      end
      else
      begin
        Columns[I].AutoSize := False;
        Columns[I].Width := 0;
        Columns[I].MaxWidth := -1;
        for J := 0 to ListView5.Items.Count - 1 do
        begin
          if ListView5.Items[J].SubItems[I - 1] <> '' then
             ListView5.Items[J].SubItems[I - 1] := '';
          if ListView5.Items[J].SubItemImages[I - 1] <> -1 then
             ListView5.Items[J].SubItemImages[I - 1] := -1;
        end;
      end;
    S := ';';
    for I := 0 to Count - 1 do
      if not Columns[I].AutoSize then
        S := S + Columns[I].Caption + ';';
    NetworkHiddenColumns.Caption := S;
  end;
end;

procedure TLampsMainForm.ListView5MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  P: TListItem;
  S: String;
begin
  if (Button = mbLeft) and (X < 16) then with ListView5 do
  begin
    P := GetItemAt(X, Y);
    if P <> nil then with P do
    begin
      Checked := not Checked;
      if Checked then
      begin
        if ImageIndex <> 38 then ImageIndex := 38;
      end
      else
      begin
        if ImageIndex <> 39 then ImageIndex := 39;
        for I := 0 to SubItems.Count - 1 do
        begin
          if SubItems[I] <> '' then SubItems[I] := '';
          if SubItemImages[I] <> -1 then SubItemImages[I] := -1;
        end;
      end;
      S := ';';
      for I := 0 to Items.Count - 1 do
        if not Items[I].Checked then S := S + Items[I].Caption + ';';
      NetworkUncheckedLamps.Caption := S;  
    end;
  end;
end;

procedure TLampsMainForm.ListView5Compare(Sender: TObject;
  Item1, Item2: TListItem; Data: Integer; var Compare: Integer);

function ItemSortSum(Item: TListItem): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 2 to Item.SubItems.Count - 1 do
    case Item.SubItemImages[I] of
      40, 44: Inc(Result, 10);
      41, 43: Inc(Result, 1);
    end;
end;

var
  I1, I2: Integer;
begin
  if not NetworkSortItem.Checked then Compare :=
    CompareText(Item1.Caption, Item2.Caption)
  else
  begin
    I1 := ItemSortSum(Item1);
    I2 := ItemSortSum(Item2);
    if I1 = I2 then Compare := 0
    else if I1 < I2 then Compare := 1
    else Compare := -1;
  end;  
end;

procedure TLampsMainForm.SortNetworkStateList;
begin
  with ListView5 do
  begin
    AlphaSort;
    if Selected <> nil then
    begin
      Selected.Selected := False;
      Selected := nil;
      ItemFocused := nil;
    end;
    if Items.Count > 0 then
    begin
      Items[0].Selected := True;
      Selected := Items[0];
      ItemFocused := Selected;
    end;
  end;
end;

procedure TLampsMainForm.NetworkSortItemClick(Sender: TObject);
begin
  SortNetworkStateList;
end;

procedure TLampsMainForm.NetworkSaveAsHTML;
var
  B: Boolean;
  I, J, N: Integer;
  L: TStringList;
  S: String;
begin
  L := TStringList.Create;
  with L do
  try
    S := TemplateFileName;
    if FileExists(S) then LoadFromFile(S);
    B := Count = 0;
    if B then
    begin
      Add('<html>');
      Add('<head>');
      Add('<meta http-equiv="refresh" content="60">');
      Add('<title>');
      Add('Network status table');
      Add('</title>');
      Add('</head>');
      Add('<body>');
      Add('<b>' + FormatDateTime('c', Now) + ' - Network status table</b>');
      Add('<p>');
      N := Count;
    end
    else
    begin
      N := -1;
      for I := 0 to Count - 1 do
      begin
        S := Strings[I];
        if Pos('%REPORTTITLE', Uppercase(Trim(S))) = 1 then
        begin
          S := Copy(S, 14, Length(S));
          Strings[I] := FormatDateTime(S, Now);
          Break;
        end;
      end;
      for I := 0 to Count - 1 do
      begin
        S := Strings[I];
        if Pos('%NETWORKSTATUSTABLE', Uppercase(Trim(S))) = 1 then
        begin
          Delete(I);
          N := I;
          Break;
        end;
      end;
      if N = -1 then N := Count;
    end;

    Insert(N, '<table>');
    Inc(N);
    with ListView5 do
    begin
      Insert(N, '<tr>');
      Inc(N);
      for I := 0 to Columns.Count - 1 do
        if Columns[I].AutoSize then
        begin
          Insert(N, '<td bgcolor="silver" style=''color:black''><b>' +
            Columns[I].Caption + '</b></td>');
          Inc(N);
        end;
      Insert(N, '</tr>');
      Inc(N);

      for I := 0 to Items.Count - 1 do
        if Items[I].Checked then
        begin
          Insert(N, '<tr>');
          Inc(N);
          Insert(N, '<td bgcolor="silver" style=''color:black''><b>' +
            Items[I].Caption + '</b></td>');
          Inc(N);
          for J := 1 to Columns.Count - 1 do
          begin
            S := '';
            if J <= 2 then
              if Items[I].SubItems[J - 1] <> '' then
                S := ' bgcolor="silver" style=''color:black'''
              else
            else case Items[I].SubItemImages[J - 1] of
              40, 44: S := ' bgcolor="red" style=''color:yellow''';
              41, 43: S := ' bgcolor="yellow" style=''color:red''';
              42: S := ' bgcolor="green" style=''color:white''';
            end;
            if Columns[J].AutoSize then
            begin
              Insert(N, '<td' + S + '>' + Items[I].SubItems[J - 1] + '</td>');
              Inc(N);
            end;
          end;
          Insert(N, '</tr>');
          Inc(N);
        end;
    end;
    Insert(N, '</table>');

    if B then
    begin
      Add('</body>');
      Add('</html>');
    end;  

    SaveToFileSafe(L, ChangeFileExt(NetStateFileName, '.HTM'));
  finally
    Free;
  end;
end;

procedure TLampsMainForm.CfgEditActionExecute(Sender: TObject);
var
  I: Integer;
  S: String;
begin
  if Sender = SchEditAction then
  begin
    S := ScheduleFileName;
    if not FileExists(S) then with TStringList.Create do
    try
      Add('# min hour day month weekday year action data address group');
      Add('  *   *    *   *     *       *    on     100% *       no');
      SaveToFile(S);
      ScheduleFileAge := FileAge(S);
    finally
      Free;
    end;
  end;
  if Sender = SchEditAction then
    S := 'NOTEPAD "' + ScheduleFileName + '"'
    else S := '"' + IncludeTrailingBackSlash(
      ExtractFilePath(Application.ExeName)) + 'CFGEDIT.EXE"';
  I := WinExec(PChar(S), SW_SHOWNORMAL);
  if I < 32 then ErrMsgBox('Error ' + IntToStr(I) +
    ' on attempt to execute ' + S + '.');
end;

procedure TLampsMainForm.RunSchedulerActionExecute(Sender: TObject);
begin
  ScheduleList.CustomTime := GetCustomDateTime;
end;

function TLampsMainForm.LogFileName: String;
begin
  Result := ExpandFileName(
    IncludeTrailingBackSlash(LogFolderEdit.Text) +
    FormatDateTime(LogNameMaskEdit.Text, Now));
end;

function TLampsMainForm.LogPeriod: TDateTime;
var
  I: Integer;
begin
  I := StrToIntDef(Trim(Copy(LogUpdateComboList.Text, 1, 2)), 0);
  Result := I / (60 * 24);
end;

function TLampsMainForm.LogEventStr(Command: Integer): String;
begin
  case Command of
    cmOn: Result := 'ON command';
    cmOff: Result := 'OFF command';
    cmGetRam: Result := 'GET RAM command';
    cmGetEE: Result := 'GET EE command';
    cmSetAddr: Result := 'SET ADDR command';
    cmSetGroup0: Result := 'SET GROUP0 command';
    cmSetGroup1: Result := 'SET GROUP1 command';
    cmSetGroup2: Result := 'SET GROUP2 command';
    cmSetGroup3: Result := 'SET GROUP3 command';
    cmLock: Result := 'LOCK command';
    cmWriteAddr: Result := 'WRITE ADDR command';
    cmSetEEAddr: Result := 'SET EE ADDR command';
    cmSetEEData: Result := 'SET EE DATA command';
    cmEETest: Result := 'EE TEST command';
(*
    cmSetEE0..cmSetEE0 + 23: Result := 'Set EE' +
      IntToStr(Command - cmSetEE0);
*)
    else Result := 'command ' + IntToStr(Command);
  end;
end;

procedure TLampsMainForm.WriteToLog(L: TStringList;
  const FileName, Title: String);
var
  B: Boolean;
  I: Integer;
  T: TextFile;
begin
  if not ForceDirectories(ExtractFilePath(FileName)) then Exit;
  System.Assign(T, FileName);
  B := False;
  for I := 0 to 7 do
  begin
    try
      if FileExists(FileName) then Append(T)
      else Rewrite(T);
      B := True;
      Break;
    except
      {do nothing}
    end;
    Pause(0);
    Pause(200);
  end;
  if B then
  try
    Writeln(T, FormatDateTime('c', Now) + Title);
    if L <> nil then
      for I := 0 to L.Count - 1 do Writeln(T, L.Strings[I]);
    Writeln(T, '----------------------------------------------------------------');
  finally
    System.Close(T);
  end;
end;

procedure TLampsMainForm.NetworkSaveAsTXT;
var
  I, J: Integer;
  L: TStringList;
  S: String;
begin
  if Now - NetLogTime < LogPeriod then Exit;
  L := TStringList.Create;
  try
    with ListView5 do
    begin
      S := '';
      for I := 0 to Columns.Count - 1 do
        if Columns[I].AutoSize then
        begin
          S := S + Columns[I].Caption + #9;
          if I = 0 then S := S + #9;
        end;
      while S[Length(S)] = #9 do SetLength(S, Length(S) - 1);
      L.Add(S);

      for I := 0 to Items.Count - 1 do
        if Items[I].Checked then
        begin
          S := Items[I].Caption + #9;
          for J := 1 to Columns.Count - 1 do
            if Columns[J].AutoSize then
              S := S + Items[I].SubItems[J - 1] + #9;
          while S[Length(S)] = #9 do SetLength(S, Length(S) - 1);
          L.Add(S);
        end;
    end;

    WriteToLog(L, LogFileName, ' - Network status table');
  finally
    L.Free;
  end;
  NetLogTime := Now;
end;

procedure TLampsMainForm.SavePropertiesActionExecute(Sender: TObject);
var
  B: Boolean;
begin
  with SaveDialog, FormStorage do
  begin
    if FileName = '' then FileName := FSIniFileName;
    if not Execute then Exit;
    IniFileName := FileName;
    B := UseRegistry;
    UseRegistry := False;
    try
      SaveFormPlacement;
    finally
      UseRegistry := B;
      IniFileName := '';
    end;
  end;
end;

procedure TLampsMainForm.RestorePropertiesActionExecute(Sender: TObject);
var
  B: Boolean;
begin
  with OpenDialog, FormStorage do
  begin
    if FileName = '' then FileName := FSIniFileName;
    if not Execute then Exit;
    IniFileName := FileName;
    B := UseRegistry;
    UseRegistry := False;
    try
      RestoreFormPlacement;
    finally
      UseRegistry := B;
      IniFileName := '';
    end;
  end;
end;

procedure TLampsMainForm.ReloadAllLists;
var
  B1, B2, B3, B4: Boolean;
  I1, I2, I3, I4: Integer;
  L: TListView;
  T: TTreeView;
  SelLampName, SelGroupName: String;
begin
  ReloadingAll := True;
  try
    SelLampName := '';
    SelGroupName := '';
    with ListView1 do
    begin
      if Selected <> nil then
      begin
        I1:= Selected.Index;
        B1:= Selected.ImageIndex = 9;
        if B1 then SelLampName := Selected.Caption;
      end
      else
      begin
        I1:= -1;
        B1 := False;
      end;
    end;
    with ListView2 do
    begin
      if Selected <> nil then
      begin
        I2:= Selected.Index;
        B2:= Selected.ImageIndex = 10;
        if B2 then SelGroupName := Selected.Caption;
      end
      else
      begin
        I2:= -1;
        B2 := False;
      end;
    end;
    with ListView3 do
    begin
      if Selected <> nil then
      begin
        I3:= Selected.Index;
        B3:= Selected.ImageIndex = 9;
        if B3 then SelLampName := Selected.Caption;
      end
      else
      begin
        I3:= -1;
        B3 := False;
      end;
    end;
    with TreeView1 do
    begin
      if Selected <> nil then
      begin
        I4:= Selected.AbsoluteIndex;
        B4:= Selected.ImageIndex = 9;
        if B4 then SelLampName := Selected.Text;
        if Selected.Parent <> nil then
          ExpandNode1 := Selected.Parent.Text;
      end
      else
      begin
        I4:= -1;
        B4 := False;
      end;
    end;

    if ListView1.Focused then L := ListView1
    else if ListView2.Focused then L := ListView2
    else if ListView3.Focused then L := ListView3
    else if ListView4.Focused then L := ListView4
    else if ListView5.Focused then L := ListView5
    else L := nil;
    if TreeView1.Focused then T := TreeView1
    else T := nil;

    FormShow(nil);

    with ListView1 do
    begin
      if I1 >= Items.Count then I1 := Items.Count - 1;
      if I1 >= 0 then
      begin
        Selected := Items[I1];
        Selected.Focused := True;
      end;
      if B1 and (T = nil) then
      begin
        SetFocus;
        if (Selected <> nil) and (Selected.Caption = SelLampName) then
          SelectLampActionExecute(SelectLampAction);
      end;
    end;
    with ListView2 do
    begin
      if I2 >= Items.Count then I2 := Items.Count - 1;
      if I2 >= 0 then
      begin
        Selected := Items[I2];
        Selected.Focused := True;
      end;
      if B2 then
      begin
        SetFocus;
        if (Selected <> nil) and (Selected.Caption = SelGroupName) then
          SelectLampActionExecute(SelectGroupAction);
      end;
    end;
    with ListView3 do
    begin
      if I3 >= Items.Count then I3 := Items.Count - 1;
      if I3 >= 0 then
      begin
        Selected := Items[I3];
        Selected.Focused := True;
      end;
      if B3 then
      begin
        SetFocus;
        if (Selected <> nil) and (Selected.Caption = SelLampName) then
          SelectLampActionExecute(SelectLampAction);
      end;
    end;
    with TreeView1 do
    begin
      if I4 >= Items.Count then I4 := Items.Count - 1;
      if I4 >= 0 then
      begin
        Selected := Items[I4];
        Selected.Focused := True;
      end;
      if B4 and (T <> nil) then
      begin
        SetFocus;
        if (Selected <> nil) and (Selected.Text = SelLampName) then
          SelectLampActionExecute(SelectLampAction);
      end;
    end;

    if L = ListView1 then ListView1.SetFocus
    else if L = ListView2 then ListView2.SetFocus
    else if L = ListView3 then ListView3.SetFocus
    else if L = ListView4 then ListView4.SetFocus
    else if L = ListView5 then ListView5.SetFocus
    else if T = TreeView1 then TreeView1.SetFocus;
  finally
    ReloadingAll := False;
  end;
end;

procedure TLampsMainForm.ListView5DblClick(Sender: TObject);
var
  I: Integer;
  P: PLampRec;
begin
  with ListView5 do
  begin
    if Selected = nil then Exit;
    P := Selected.Data;
  end;

  with ListView1, Items do
    for I := 0 to Count - 1 do
      if Items[I].Data = P then
      begin
        if Selected <> nil then
        begin
          Selected.Selected := False;
          Selected := nil;
          ItemFocused := nil;
        end;
        Items[I].Selected := True;
        Selected := Items[I];
        ItemFocused := Selected;
        Selected.MakeVisible(False);
        AllPanel.Visible := True;
        if TreeView1.Visible then
        begin
          SyncTreeWithAllList;
          TreeView1.SetFocus;
        end
        else if ListView1.Visible then ListView1.SetFocus;
        SelectLampActionExecute(SelectLampAction);
        Exit;
      end;
end;

procedure TLampsMainForm.ListView5KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_INSERT) and not (ssAlt in Shift) and
    not (ssCtrl in Shift) and not (ssShift in Shift) then
  begin
    Key := 0;
    ListView5DblClick(nil);
  end;  
end;

function TLampsMainForm.GetThreadPriorityIndex: Integer;
var
  H: HWnd;
begin
  H := GetCurrentThread;
  Result := GetThreadPriority(H);
  if Result = THREAD_PRIORITY_ERROR_RETURN then Result := -1
  else Result := ThreadPriorityToIndex(Result);
end;

procedure TLampsMainForm.PropPriorityItemItemClick(Sender: TObject);
var
  I: Integer;
  H: HWnd;
begin
  with PropPriorityItem do Tag := ItemIndex;
  H := GetCurrentThread;
  I := IndexToThreadPriority(PropPriorityItem.ItemIndex);
  if I <> -1 then SetThreadPriority(H, I);
end;

procedure TLampsMainForm.PropComPriorityItemItemClick(Sender: TObject);
begin
  with PropComPriorityItem do
  begin
    Tag := ItemIndex;
    if ItemIndex <> -1 then
      ComPort.ThreadBoost := TApThreadBoost(ItemIndex);
  end;
end;

procedure TLampsMainForm.ViewFixItemClick(Sender: TObject);
begin
  if ViewFixItem.Checked then
  begin
    AllPanel.DockMode := dmCannotFloatOrChangeDocks;
    GroupPanel.DockMode := dmCannotFloatOrChangeDocks;
    SelGroupPanel.DockMode := dmCannotFloatOrChangeDocks;
    StatePanel.DockMode := dmCannotFloatOrChangeDocks;
    NetworkStatusPanel.DockMode := dmCannotFloatOrChangeDocks;
    EETestPanel.DockMode := dmCannotFloatOrChangeDocks;
    Splitter.Enabled := False;
  end
  else
  begin
    AllPanel.DockMode := dmCanFloat;
    GroupPanel.DockMode := dmCanFloat;
    SelGroupPanel.DockMode := dmCanFloat;
    StatePanel.DockMode := dmCanFloat;
    NetworkStatusPanel.DockMode := dmCanFloat;
    EETestPanel.DockMode := dmCanFloat;
    Splitter.Enabled := True;
  end
end;

procedure TLampsMainForm.AllPanelDockedResizing(Sender: TObject;
  Vertical: Boolean; var NewSize: Integer; Stage: TTBXResizingStage;
  var AllowResize: Boolean);
begin
  AllowResize := not ViewFixItem.Checked;
end;

function TLampsMainForm.EETestTrackBarByIndex(I: Integer): TTrackBar;
begin
  case I of
    0: Result := TrackBar1;
    1: Result := TrackBar2;
    2: Result := TrackBar3;
    3: Result := TrackBar4;
    4: Result := TrackBar5;
    5: Result := TrackBar6;
    6: Result := TrackBar7;
    7: Result := TrackBar8;
    8: Result := TrackBar9;
    9: Result := TrackBar10;
    10: Result := TrackBar11;
    11: Result := TrackBar12;
    12: Result := TrackBar13;
    13: Result := TrackBar14;
    14: Result := TrackBar15;
    15: Result := TrackBar16;
    16: Result := TrackBar17;
    17: Result := TrackBar18;
    18: Result := TrackBar19;
    19: Result := TrackBar20;
    else Result := nil;
  end;
end;

procedure TLampsMainForm.TrackBar1Change(Sender: TObject);

  procedure SetEETestLabelCaption(ATrackBar: TTrackBar;
    ALabel1, ALabel2: TTBXLabel; Index: Integer);
  var
    P: PLampParamRec;
    S: String;
  begin
    if (Index < 0) or (Index >= EETestList.Count) then
    begin
      ATrackBar.Position := 0;
      ATrackBar.Visible := False;
      ALabel1.Caption := '';
      ALabel2.Caption := '';
      Exit;
    end;
    P := EETestList.Items[Index];
    S := P^.Name + ':';
    if ALabel1.Caption <> S then ALabel1.Caption := S;
    P^.Value := ATrackBar.Position * P^.Multiplier;
    ATrackBar.Visible := True;
    S := Trim(FormatX(P^.Format, P^.Value));
    if ALabel2.Caption <> S then ALabel2.Caption := S;
  end;

begin
  if Sender is TTrackBar then EETestChangedSeconds := 1
  else EETestChangedSeconds := 0;
  SetEETestLabelCaption(TrackBar1, TBXLabel1, TBXLabel21, 0);
  SetEETestLabelCaption(TrackBar2, TBXLabel2, TBXLabel22, 1);
  SetEETestLabelCaption(TrackBar3, TBXLabel3, TBXLabel23, 2);
  SetEETestLabelCaption(TrackBar4, TBXLabel4, TBXLabel24, 3);
  SetEETestLabelCaption(TrackBar5, TBXLabel5, TBXLabel25, 4);
  SetEETestLabelCaption(TrackBar6, TBXLabel6, TBXLabel26, 5);
  SetEETestLabelCaption(TrackBar7, TBXLabel7, TBXLabel27, 6);
  SetEETestLabelCaption(TrackBar8, TBXLabel8, TBXLabel28, 7);
  SetEETestLabelCaption(TrackBar9, TBXLabel9, TBXLabel29, 8);
  SetEETestLabelCaption(TrackBar10, TBXLabel10, TBXLabel30, 9);
  SetEETestLabelCaption(TrackBar11, TBXLabel11, TBXLabel31, 10);
  SetEETestLabelCaption(TrackBar12, TBXLabel12, TBXLabel32, 11);
  SetEETestLabelCaption(TrackBar13, TBXLabel13, TBXLabel33, 12);
  SetEETestLabelCaption(TrackBar14, TBXLabel14, TBXLabel34, 13);
  SetEETestLabelCaption(TrackBar15, TBXLabel15, TBXLabel35, 14);
  SetEETestLabelCaption(TrackBar16, TBXLabel16, TBXLabel36, 15);
  SetEETestLabelCaption(TrackBar17, TBXLabel17, TBXLabel37, 16);
  SetEETestLabelCaption(TrackBar18, TBXLabel18, TBXLabel38, 17);
  SetEETestLabelCaption(TrackBar19, TBXLabel19, TBXLabel39, 18);
  SetEETestLabelCaption(TrackBar20, TBXLabel20, TBXLabel40, 19);
end;

procedure TLampsMainForm.TrackBar1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ssAlt in Shift then Exit;
  if Key = VK_DOWN then Keybd_Event(VK_TAB, 0, 0, 0)
  else if Key = VK_UP then
  begin
    Keybd_Event(VK_SHIFT, 0, 0, 0);
    Keybd_Event(VK_TAB, 0, 0, 0);
    Keybd_Event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0);
  end
  else if Key = VK_RETURN then EETestSetActionExecute(nil)
  else if (Key = VK_RIGHT) and (ssShift in Shift) then
    Keybd_Event(VK_NEXT, 0, 0, 0)
  else if (Key = VK_LEFT) and (ssShift in Shift) then
    Keybd_Event(VK_PRIOR, 0, 0, 0)
  else Exit;
  Key := 0;
end;

function TLampsMainForm.EETestValueArrayChangeCount: Integer;
var
  I: Integer;
  T: TTrackBar;
begin
  Result := 0;
  with EETestList do
    for I := 0 to EETestMaxItems - 1 do
      if I < Count then
      begin
        T := EETestTrackBarByIndex(I);
        if (T <> nil) and T.Visible then
          if T.Position <> EETestValueArray[I] then Inc(Result);
      end;
end;

procedure TLampsMainForm.EETestGetActionExecute(Sender: TObject);
begin
  EETestGetRequest := True;
end;

procedure TLampsMainForm.EETestGet;
var
  B0, B1, B2: Byte;
  A, I: Integer;
  P: PLampParamRec;
  T: TTrackBar;
  S: String;
begin
  if EETestTransferring then Exit;

  with TrackBar1 do if Visible then SetFocus;

  if SelectedLampItem = nil then A := $3FF
  else A := LampAddressByLampItem(SelectedLampItem);

  if LogSETItem.Checked then
  begin
    LogEvent := True;
    LogSourceStr := 'Get EE (test)';
  end;

  EETestTransferring := True;
  try
    with EETestList do
    begin
      for I := 0 to EETestMaxItems - 1 do
        if I < Count then
        begin
          P := Items[I];
          S := SendLampCommand(A, cmGetEE, P^.Address, False, False, B0, B1, B2);
          if not EETestPanel.Visible then Break;
          if GetKeyState(VK_ESCAPE) and $8000 <> 0 then Break;
          if S <> '' then
          begin
            if PropErrMsgItem.Checked then
            begin
              ErrMsgBox(S + ' on attempt to get ' + P^.Name + ' value.');
              Break;
            end;
          end
          else
          begin
            T := EETestTrackBarByIndex(I);
            if T <> nil then T.Position := B1;
            EETestValueArray[I] := B1;
            TrackBar1Change(nil);
          end;
          Pause(StrToIntDef(PropDelayItem.Text, 10));
        end;
    end;
  finally
    EETestTransferring := False;
    LogEvent := False;
    LogSourceStr := '';
  end;
end;

procedure TLampsMainForm.EETestSetActionExecute(Sender: TObject);
var
  B: Byte;
  I: Integer;
  P: PLampParamRec;
  T: TTrackBar;
begin
  if Sender = EETestSetDefaultsAction then with EETestList do
  begin
    for I := 0 to EETestMaxItems - 1 do
      if I < Count then
      begin
        P := Items[I];
        if P^.Multiplier <> 0 then
          B := Round(P^.Default / P^.Multiplier)
        else B := 0;
        T := EETestTrackBarByIndex(I);
        if T <> nil then T.Position := B;
      end;
    TrackBar1Change(nil);
  end;
  EETestAutoSend := False;
  EETestSetRequest := True;
end;

procedure TLampsMainForm.EETestSet;
var
  G, All: Boolean;
  B0, B1, B2, D: Byte;
  A, I, N, MismatchCount, Percent, OldPercent: Integer;
  BytesTotal, BytesCur: Longint;
  StartTime, EstimatedTime, ElapsedTime, RemainingTime: TDateTime;
  P: PLampParamRec;
  T: TTrackBar;
  S: String;
label
  SetStart, SetAttempt;
begin
  if EETestTransferring then Exit;

  if EETestAutoSend then All := False
  else All := GetKeyState(VK_CONTROL) and $8000 <> 0;
  EETestAutoSend := False;

SetStart:
  if SelectedLampItem = nil then A := $3FF
  else A := LampAddressByLampItem(SelectedLampItem);
  G := False;

  if not All then
  begin
    BytesTotal := EETestValueArrayChangeCount;
    if BytesTotal <= 0 then
    begin
      if RetryMsgBox('No parameter changes were made since ' +
        'last "Get/Set EE test values" operation. ' +
        'Click [Cancel] button and then click [Set] button ' +
        'while holding Ctrl key down to set EE values ' +
        'for all parameters, or click [Retry] button ' +
        'to set all values right now.', True) then
      begin
        All := True;
        goto SetStart;
      end;
      ProgressForm.ModalResult := mrCancel;
      with TrackBar1 do if Visible then SetFocus;
      Exit;
    end;
  end
  else if EETestList.Count > EETestMaxItems then
    BytesTotal := EETestMaxItems
  else BytesTotal := EETestList.Count;
  BytesCur := 0;
  OldPercent := -1;
  StartTime := Now;

  N := StrToIntDef(PropBlockRetriesItem.Text, 0);

  if LogSETItem.Checked then
  begin
    LogEvent := True;
    LogSourceStr := 'Set EE (test)';
  end;

  EETestTransferring := True;
  try
    S := SendLampCommand(A, cmLock, $AA, G, A = $3FF, B0, B1, B2);
    if S <> '' then ErrMsgBox(S +
      ' on attempt to unlock before setting EE value.')
    else
    begin
      Pause(StrToIntDef(PropDelayItem.Text, 10));

      with EETestList do
      begin
        for I := 0 to EETestMaxItems - 1 do
          if I < Count then
          begin
            T := EETestTrackBarByIndex(I);
            if (T <> nil) and T.Visible then
            begin
              P := Items[I];
              D := T.Position;

              if not All and (D = EETestValueArray[I]) then Continue;

              MismatchCount := 0;
SetAttempt:
              AddTimeout := 50;
              try
                S := SendLampCommand(A, cmSetEEAddr, P^.Address,
                  G, A = $3FF, B0, B1, B2);
                if S = '' then
                begin
                  Pause(StrToIntDef(PropDelayItem.Text, 10));
                  S := SendLampCommand(A, cmSetEEData, D,
                    G, A = $3FF, B0, B1, B2);
                end;
              finally
                AddTimeout := 0;
              end;
              if not EETestPanel.Visible then Break;
              if GetKeyState(VK_ESCAPE) and $8000 <> 0 then Break;
              if S = UnlockRequiredStr then
              begin
                Pause(StrToIntDef(PropDelayItem.Text, 10));
                S := SendLampCommand(A, cmLock, $AA, G, A = $3FF, B0, B1, B2);
                if S <> '' then
                begin
                  ErrMsgBox(S + ' on attempt to unlock while setting EE value.');
                  Break;
                end;
                Pause(StrToIntDef(PropDelayItem.Text, 10));
                goto SetAttempt;
              end
              else if Pos(EEDataMismatchStr, S) = 1 then
              begin
                Inc(MismatchCount);
                if MismatchCount > N then
                begin
                  ErrMsgBox(S);
                  Break;
                end;
                Pause(StrToIntDef(PropDelayItem.Text, 10));
                goto SetAttempt;
              end
              else if S <> '' then
//                if LampsMainForm.PropErrMsgItem.Checked then
                begin
                  ErrMsgBox(S + ' on attempt to set ' + P^.Name + ' value.');
                  Break;
                end
              else EETestValueArray[I] := D;
              Pause(StrToIntDef(PropDelayItem.Text, 10));
            end;

            if ProgressForm <> nil then with ProgressForm do
            begin
              Inc(BytesCur);
              if (BytesTotal = 0) or (BytesTotal <= BytesCur) then
                Percent := 100
              else if BytesCur = 0 then Percent := 0
              else Percent := Trunc(BytesCur * 100.0 / BytesTotal);
              if Percent <> OldPercent then
              begin
                OldPercent := Percent;
                DrawProgress(Percent);
              end;
              ElapsedTime := Now - StartTime;
              if BytesCur = 0 then EstimatedTime := 0
              else EstimatedTime := ElapsedTime * BytesTotal / BytesCur;
              RemainingTime := EstimatedTime - ElapsedTime;
              DrawIndicators(
                BytesTotal, BytesCur, BytesTotal - BytesCur,
                EstimatedTime, ElapsedTime, RemainingTime);
              Application.ProcessMessages;
              if ModalResult <> mrNone then Break;
            end;
          end;
      end;
    end;
    S := SendLampCommand(A, cmLock, $55, G, A = $3FF, B0, B1, B2);
    if S <> '' then ErrMsgBox(S +
      ' on attempt to lock after setting EE value.');
  finally
    ProgressForm.ModalResult := mrCancel;
    EETestTransferring := False;
    LogEvent := False;
    LogSourceStr := '';
  end;
end;

procedure TLampsMainForm.EETestOnActionExecute(Sender: TObject);
begin
  SendOnOffCommand := cmOn;
  SendDimming := 255;
  SendRequest := True;
  EESendRequest := True;
end;

procedure TLampsMainForm.EETestOffActionExecute(Sender: TObject);
begin
  SendOnOffCommand := cmOff;
  SendDimming := 0;
  SendRequest := True;
  EESendRequest := True;
end;

procedure TLampsMainForm.EETestTestActionExecute(Sender: TObject);
begin
  SendOnOffCommand := cmEETest;
  SendDimming := 255;
  SendRequest := True;
  EESendRequest := True;
end;

procedure TLampsMainForm.ScanNetworkActionExecute(Sender: TObject);
begin
  NetScanRequest := True;
end;

procedure TLampsMainForm.RenameLampActionExecute(Sender: TObject);
begin
  if TreeView1.Focused then with TreeView1 do
    if Selected <> nil then Selected.EditText else
  else if ListView1.Focused then with ListView1 do
    if Selected <> nil then Selected.EditCaption;
end;

procedure TLampsMainForm.ListView1Edited(Sender: TObject; Item: TListItem;
  var S: String);
var
  I: Integer;
  N: TTreeNode;
  L: TListItem;
  P: PLampRec;
begin
  if Trim(S) = '' then S := Item.Caption;
  if S <> Item.Caption then
  begin
    P := Item.Data;
    if P <> nil then
    begin
      for I := 0 to TreeView1.Items.Count - 1 do
      begin
        N := TreeView1.Items[I];
        if not N.HasChildren and (Uppercase(N.Text) = Uppercase(Item.Caption)) then
          N.Text := S;
      end;
      for I := 0 to ListView5.Items.Count - 1 do
      begin
        L := ListView5.Items[I];
        if Uppercase(L.Caption) = Uppercase(Item.Caption) then
          L.Caption := S;
      end;
      ModifyLampName(P, S);
      if ListView2.Selected <> nil then
         ListView2SelectItem(nil, ListView2.Selected, True);
    end;
  end;
end;

procedure TLampsMainForm.ListView1Editing(Sender: TObject; Item: TListItem;
  var AllowEdit: Boolean);
begin
// Enable Del keystrokes while editing
  if RenameLampAction.Enabled then DeleteItemAction.ShortCut := 0
  else AllowEdit := False;
end;

procedure TLampsMainForm.AllViewComboListItemClick(Sender: TObject);
begin
  if AllViewComboList.Text = 'Tree' then
  begin
    SyncTreeWithAllList;
    TreeView1.Visible := True;
    ListView1.Visible := False;
    if AllPanel.Visible then TreeView1.SetFocus;
  end
  else
  begin
    SyncAllListWithTree;
    ListView1.Visible := True;
    TreeView1.Visible := False;
    if AllPanel.Visible then ListView1.SetFocus;
  end;
end;

procedure TLampsMainForm.AllToggleItemClick(Sender: TObject);
begin
  if TreeView1.Visible then AllViewComboList.Text := 'List'
  else AllViewComboList.Text := 'Tree';
  AllViewComboListItemClick(nil);
end;

procedure TLampsMainForm.SyncAllListWithTree;
var
  I: Integer;
  N: TTreeNode;
begin
  N := TreeView1.Selected;
  if (N <> nil) and not N.HasChildren then with ListView1 do
    for I := 0 to Items.Count - 1 do
      if N.Data = Items[I].Data then
      begin
        if Selected <> nil then
        begin
          Selected.Selected := False;
          Selected := nil;
          ItemFocused := nil;
        end;
        Items[I].Selected := True;
        Selected := Items[I];
        Selected.Focused := True;
        ItemFocused := Selected;
        Selected.MakeVisible(False);
        Break;
      end;
end;

procedure TLampsMainForm.SyncGroupListWithTree;
var
  I: Integer;
  N: TTreeNode;
begin
  N := TreeView1.Selected;
  if (N <> nil) and N.HasChildren then with ListView2 do
    for I := 0 to Items.Count - 1 do
      if Uppercase(Items[I].Caption) = Uppercase(N.Text) then
      begin
        if Selected <> nil then
        begin
          Selected.Selected := False;
          Selected := nil;
          ItemFocused := nil;
        end;
        Items[I].Selected := True;
        Selected := Items[I];
        Selected.Focused := True;
        ItemFocused := Selected;
        Selected.MakeVisible(False);
        Break;
      end;
end;

procedure TLampsMainForm.SyncTreeWithAllList;
var
  I: Integer;
  Item: TListItem;
begin
  Item := ListView1.Selected;
  if Item <> nil then with TreeView1 do
    for I := 0 to Items.Count - 1 do
      if Items[I].Data = Item.Data then
      begin
        Selected := Items[I];
        MakeNodeVisible(Selected);
        Break;
      end;
end;

procedure TLampsMainForm.SyncTreeWithGroupList;
var
  I: Integer;
  Item: TListItem;
begin
  Item := ListView2.Selected;
  if Item <> nil then with TreeView1 do
    for I := 0 to Items.Count - 1 do
      if Items[I].HasChildren and
        (Uppercase(Items[I].Text) = Uppercase(Item.Caption)) then
      begin
        Selected := Items[I];
        MakeNodeVisible(Selected);
        Break;
      end;
end;

procedure TLampsMainForm.TreeView1Change(Sender: TObject; Node: TTreeNode);
begin
  if not PopulatingTree and (Node <> nil) then
    if Node.HasChildren then SyncGroupListWithTree
    else SyncAllListWithTree;
end;

procedure TLampsMainForm.TreeView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ssCtrl in Shift then
  begin
    if Key = VK_DELETE then
    begin
      Key := 0;
      if DeleteItemAction.Enabled then DeleteItemActionExecute(nil);
      Exit;
    end;
    if (Key <> VK_RIGHT) and (Key <> VK_LEFT) then Exit;
    TreeView1.Items.BeginUpdate;
    try
      if Key = VK_RIGHT then TreeView1.FullExpand
      else TreeView1.FullCollapse;
      MakeNodeVisible(TreeView1.Selected);
    finally
      TreeView1.Items.EndUpdate;
    end;
    Key := 0;
  end;
end;

procedure TLampsMainForm.TreeView1Edited(Sender: TObject; Node: TTreeNode;
  var S: String);
var
  I: Integer;
  P: PLampRec;
  N: TListItem;
  OldName, NewName: String;
begin
  if Trim(S) = '' then S := Node.Text;
  if S <> Node.Text then
    if Node.HasChildren then
    begin
      if TreeGroupExists(S, Node) then
      begin
        ErrMsgBox('A group with the name "' + S + '" already exists. ' +
          'Please enter a different name for the selected item.');
        S := Node.Text;
        TreeEditRequest := True;
      end;
      for I := 0 to ListView2.Items.Count - 1 do
      begin
        N := ListView2.Items[I];
        if Uppercase(N.Caption) = Uppercase(Node.Text) then N.Caption := S;
      end;
      NewName := FileNameByGroupCaption(S);
      OldName := FileNameByGroupCaption(Node.Text);
      if FileExists(OldName) then
        if not RenameFile(OldName, NewName) then ErrMsgBox(
          'Cannot rename file ' + OldName + ' to ' + NewName + '.')
      else ErrMsgBox('File ' + OldName + ' does not exist.');    
    end
    else
    begin
      P := Node.Data;
      if P <> nil then
      begin
        for I := 0 to ListView1.Items.Count - 1 do
        begin
          N := ListView1.Items[I];
          if Uppercase(N.Caption) = Uppercase(Node.Text) then
            N.Caption := S;
        end;
        for I := 0 to ListView5.Items.Count - 1 do
        begin
          N := ListView5.Items[I];
          if Uppercase(N.Caption) = Uppercase(Node.Text) then
            N.Caption := S;
        end;
        ModifyLampName(P, S);
        if ListView2.Selected <> nil then
           ListView2SelectItem(nil, ListView2.Selected, True);
      end;
    end;
end;

procedure TLampsMainForm.TreeView1Editing(Sender: TObject; Node: TTreeNode;
  var AllowEdit: Boolean);
begin
// Enable Del keystrokes while editing
  if RenameLampAction.Enabled then DeleteItemAction.ShortCut := 0
  else AllowEdit := False;
end;

procedure TLampsMainForm.TreeView1DblClick(Sender: TObject);
var
  P: TPoint;
  T: THitTests;
begin
  GetCursorPos(P);
  P := TreeView1.ScreenToClient(P);
  T := TreeView1.GetHitTestInfoAt(P.X, P.Y);
  if htOnItem in T then SelectLampActionExecute(SelectLampAction);
end;

procedure TLampsMainForm.TreeView1AdvancedCustomDrawItem(
  Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState;
  Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
var
  I: Integer;
  P: PLampRec;
  R: TRect;
  S: String;
begin
  if Stage <> cdPostPaint then Exit;
  R := Node.DisplayRect(True);
  I := R.Right;
  R := Node.DisplayRect(False);
  R.Left := I;
  with TreeView1.Canvas do
  begin
    Brush.Style := bsClear;
    Brush.Color := TreeView1.Color;
    FillRect(R);
  end;
  R.Left := I + 4;
  Dec(R.Right, 4);
  P := Node.Data;
  if Node.HasChildren or (Longint(P) <= $FF) then
    S := '[' + IntToStr(Longint(P)) + ']'
  else
  begin
    if P <> nil then S := '(' + IntToStr(P^.Address) + ')'
    else S := '';
  end;
  if S <> '' then with TreeView1.Canvas do
  begin
    Brush.Style := bsClear;
    Brush.Color := TreeView1.Color;
    Font.Color := TreeView1.Font.Color;
    if S[1] = '[' then Font.Style := [fsBold];
    if TextWidth(S) <= R.Right - R.Left then
      DrawText(Handle, PChar(S), Length(S), R,
        DT_RIGHT + DT_SINGLELINE + DT_VCENTER);
  end;
end;

procedure TLampsMainForm.AllPanelResize(Sender: TObject);
begin
  TreeView1.Refresh;
end;

procedure TLampsMainForm.TreeView1DragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
var
  N: TTreeNode;
begin
  if not PacketTestAction.Enabled then Accept := False
  else with TreeView1 do
  begin
    N := DropTarget;
    Accept := (Source = TreeView1) and (N <> nil) and
      (Selected <> nil) and not Selected.HasChildren and
      (Selected <> N) and (Selected.Parent <> N) and not
       (not N.HasChildren and (N.Parent = nil));
    if Accept then
      if (GetKeyState(VK_CONTROL) and $8000 <> 0) and
         (Selected.Parent <> nil) then DragCursor := crDragAdd
      else DragCursor := crDragCursor;
    if (X < 16) and (N <> nil) and (N.Count <> 0) and
      not N.Expanded then
    begin
      ImageList_DragShowNoLock(False);
      N.Expand(False);
      Refresh;
      ImageList_DragShowNoLock(True);
    end;
    if N <> nil then
      if Y < 16 then N := N.GetPrevVisible
      else if Y > ClientHeight - 16 then N := N.GetNextVisible
      else N := nil;
    if (N <> nil) and (N <> LastDropTarget) then
    begin
      LastDropTarget := N;
      ImageList_DragShowNoLock(False);
      N.MakeVisible;
      Refresh;
      ImageList_DragShowNoLock(True);
    end;
  end;
end;

procedure TLampsMainForm.TreeView1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  N: TTreeNode;
begin
  if LampHintItem.Checked then with TreeView1 do
  begin
    N := GetNodeAt(X, Y);
    if N = HintNode then Exit;
    HintNode := N;
    Application.CancelHint;
    if (N <> nil) and not N.HasChildren and
       (Longint(N.Data) > $FF) then DisplayControlHint(
      TreeView1, X, Y, GetLampInfoTip(N.Data) + '|')
    else ShowHint := False;
  end;
end;

function NodeContainsLamp(N: TTreeNode; P: PLampRec): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to N.Count - 1 do
    if N.Item[I].Data = P then
    begin
      Result := True;
      Exit;
    end;
end;

procedure TLampsMainForm.TreeView1DragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  Accept: Boolean;
  C, SourceGA, DestGA: Integer;
  SourceNode, SourceParentNode,
  DestNode, DestParentNode, N: TTreeNode;
  P: PLampRec;
  A: TLampArray;
begin
  with TreeView1 do
  begin
    SourceNode := Selected;
    if SourceNode = nil then Exit;
    SourceParentNode := SourceNode.Parent;
    DestNode := DropTarget;
    if DestNode = nil then Exit;
    DestParentNode := DestNode.Parent;
    Accept := (Source = TreeView1) and
      not SourceNode.HasChildren and (SourceNode <> DestNode);
    if not Accept then Exit;
    P := SourceNode.Data;
    if (P = nil) or (Longint(P) <= $FF) then Exit;
    if SourceParentNode <> nil then
      SourceGA := Longint(SourceParentNode.Data)
    else SourceGA := -1;
    if DestParentNode <> nil then
    begin
      if (SourceParentNode <> DestParentNode) and
        NodeContainsLamp(DestParentNode, P) then Exit;
      DestGA := Longint(DestParentNode.Data);
    end
    else if DestNode.HasChildren then
    begin
      if SourceParentNode = DestNode then Exit;
      if NodeContainsLamp(DestNode, P) then Exit;
      DestGA := Longint(DestNode.Data);
    end
    else DestGA := -1;
    if DestGA < 0 then Exit;
    if (GetKeyState(VK_CONTROL) and $8000 <> 0) and
       (SourceParentNode <> nil) and
       (SourceParentNode <> DestParentNode) then
    begin
      if not CanAddToGroup(P, DestGA, True) then Exit;
      if DestNode.HasChildren then
      begin
        DestNode.Expand(False);
        N := Items.AddChild(DestNode, P^.Name);
      end
      else N := Items.Insert(DestNode, P^.Name);
      N.Data := P;
      N.ImageIndex := -1;
      N.StateIndex := -1;
      N.SelectedIndex := -1;
    end
    else
    begin
      if SourceGA <> -1 then
        if P^.Group0Address = SourceGA then P^.Group0Address := $FF
        else if P^.Group1Address = SourceGA then P^.Group1Address := $FF
        else if P^.Group2Address = SourceGA then P^.Group2Address := $FF
        else if P^.Group3Address = SourceGA then P^.Group3Address := $FF;
      if not CanAddToGroup(P, DestGA, True) then Exit;
      if DestNode.HasChildren then
        SourceNode.MoveTo(DestNode, naAddChild)
      else if DestNode = SourceNode.GetNextSibling then
        DestNode.MoveTo(SourceNode, naInsert)
      else SourceNode.MoveTo(DestNode, naInsert);
    end;  
    if SourceParentNode <> nil then
    begin
      SourceParentNode.HasChildren := True;
      TreeNodeToArray(SourceParentNode, A, C);
      SaveToText(FileNameByGroupCaption(SourceParentNode.Text),
        A, C, Longint(SourceParentNode.Data));
    end;
    if (DestParentNode <> nil) and (DestParentNode <> SourceParentNode) then
    begin
      TreeNodeToArray(DestParentNode, A, C);
      SaveToText(FileNameByGroupCaption(DestParentNode.Text),
        A, C, Longint(DestParentNode.Data));
    end
    else if DestNode.HasChildren and (DestNode <> SourceParentNode) then
    begin
      TreeNodeToArray(DestNode, A, C);
      SaveToText(FileNameByGroupCaption(DestNode.Text),
        A, C, Longint(DestNode.Data));
    end;
    if ListView2.Selected <> nil then
       ListView2SelectItem(nil, ListView2.Selected, True);
    PopulateGroupAddresses;
    PromptForConfig(False);
  end;
end;

procedure TLampsMainForm.TreeView1Expanded(Sender: TObject;
  Node: TTreeNode);
begin
  TreeView1.Invalidate;
end;

procedure TLampsMainForm.ReloadListsActionExecute(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  StatusBar.Panels[0].Caption := 'Reloading lists...';
  try
    StatusBar.Refresh;
    PopulateLampListView(ListView1, LampArray, TotalLamps);
//    PopulateTreeView(TotalLamps);
    PopulateGroupListView(ListView2);
{
    with TreeView1, Items do
      if Count <> 0 then
      begin
        Selected := Items[0];
        Selected.Focused := True;
        MakeNodeVisible(Selected);
      end;
}
    PopulateGroupAddresses;
  finally
    Screen.Cursor := crDefault;
    StatusBar.Panels[0].Caption := '';
  end;
end;

procedure TLampsMainForm.CreateLampActionExecute(Sender: TObject);
var
  G, T: Boolean;
  A: Integer;
  P: PLampRec;
  L: TListItem;
  N: TTreeNode;
  S: String;
begin
  if not AllPanel.Visible or (TotalLamps >= MaxLamps) then Exit;
  T := TreeView1.Focused;
  G := Sender = CreateInGroupAction;
  P := @LampArray[TotalLamps];
  with P^ do
  begin
    Name := GetNewLampName;
    Address := 0;
    Group0Address := $FF;
    Group1Address := $FF;
    Group2Address := $FF;
    Group3Address := $FF;
  end;
  Inc(TotalLamps);

  with TStringList.Create do
  try
    if FileExists(AllFileName) then LoadFromFile(AllFileName);
    Add(P^.Name + ' ' + SepChar + ' 0');
    SaveToFile(AllFileName);
  finally
    Free;
  end;
  AllFileAge := FileAge(AllFileName);

  L := ListView1.Items.Add;
  L.Caption := P^.Name;
  L.Data := P;
  L.ImageIndex := -1;
  L.SubItems.Add(IntToStr(P^.Address));

  if G then
  begin
    if not T then SyncTreeWithGroupList;
    N := TreeView1.Selected;
    if N <> nil then
    begin
      if not N.HasChildren then N := N.Parent;
      if N <> nil then
      begin
        P^.Group0Address := Longint(N.Data);
        S := FileNameByGroupCaption(N.Text);
        if FileExists(S) then with TStringList.Create do
        try
          LoadFromFile(S);
          Add(P^.Name + ' ' + SepChar + ' 0');
          SaveToFile(S);
        finally
          Free;
        end
        else raise Exception.Create('Group file not found: ' + S + '.');
        N := TreeView1.Items.AddChild(N, P^.Name)
      end;
    end;
  end
  else N := TreeView1.Items.Add(nil, P^.Name);
  if N = nil then raise Exception.Create('Failed to create new tree node.');
  N.Data := P;
  N.ImageIndex := -1;
  N.StateIndex := -1;
  N.SelectedIndex := -1;
  TreeView1.Selected := N;
  MakeNodeVisible(N);

  PopulateNetworkListView(ListView5);

  if G and (ListView2.Selected <> nil) then
    ListView2SelectItem(nil, ListView2.Selected, True);

  A := P^.Address;
  if ChangeLampAddress(A, P) then ModifyLampAddress(P, A);

  RenameLampAction.Enabled := True;
  if T then N.EditText
  else L.EditCaption;
end;

procedure TLampsMainForm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if PropConfExitItem.Checked and not ConfMsgBox(
    'Terminate the application?', False) then CanClose := False;
  if CanClose and FileExists(FSIniFileName) then
  begin
    FormStorage.UseRegistry := False;
    EEForm.FormStorage.UseRegistry := False;
    MeterForm.FormStorage.UseRegistry := False;
  end;
end;

procedure TLampsMainForm.LayoutItem0Click(Sender: TObject);
begin
  if not (Sender is TTBXItem) then Exit;
  (Sender as TTBXItem).Checked := True;
  if Sender = LayoutItem0 then Exit;

  if Sender = LayoutItem1 then with ListView5, Items do
  begin
    BeginUpdate;
    try
      Clear;
    finally
      EndUpdate;
    end;
  end;    

  WindowState := wsMaximized;

  ControlToolbar.Visible := True;
  AllPanel.Visible := True;
  GroupPanel.Visible := False;
  SelGroupPanel.Visible := False;
  StatePanel.Visible := True;
  Meter.Visible := False;
  Splitter.Visible := False;
  MeterForm.Visible := False;

  AllPanel.CurrentDock := LeftDock;
  AllPanel.DockPos := -1;

  if Sender = LayoutItem1 then
  begin
    EETestPanel.Visible := False;
    StatePanel.CurrentDock := LeftDock;
    NetworkStatusPanel.Visible := True;
    NetworkStatusPanel.CurrentDock := RightDock;

    AllPanel.Width := Trunc(Width * 0.244);
    StatePanel.Width := Trunc(Width * 0.216);
    NetworkStatusPanel.Width :=
      ClientWidth - AllPanel.Width - StatePanel.Width;

    ListView4.Align := alClient;
    ListView4.Align := alTop;

    PopulateNetworkListView(ListView5);

    if not TreeView1.Visible then AllToggleItemClick(nil);
  end
  else if Sender = LayoutItem2 then
  begin
    NetworkStatusPanel.Visible := False;
    EETestPanel.Visible := True;
    EETestPanel.CurrentDock := LeftDock;
    StatePanel.CurrentDock := RightDock;

    EETestPanel.Width := Trunc(Width * 0.415);
    if EETestPanel.Width < 392 then
    begin
      EETestPanel.Width := 392;
      AllPanel.Width := 184;
    end
    else AllPanel.Width := Trunc(Width * 0.365);
    StatePanel.Width :=
      ClientWidth - AllPanel.Width - EETestPanel.Width;

    ListView4.Align := alClient;
    ListView4.Align := alTop;

    if TreeView1.Visible then AllToggleItemClick(nil);
  end;
end;

procedure TLampsMainForm.NetworkReadAllItemClick(Sender: TObject);
begin
  if Sender is TTBXItem then (Sender as TTBXItem).Checked := True;
end;

procedure TLampsMainForm.PropPortItemAcceptText(Sender: TObject;
  var NewText: String; var Accept: Boolean);
var
  I: Integer;
begin
  I := Length(NewText);
  while (I > 0) and (NewText[I] in ['0'..'9']) do Dec(I);
  I := StrToIntDef(Copy(NewText, I + 1, 255), -1);
  if (I < 1) or (I > 65535) then
  begin
    Accept := False;
    ErrMsgBox('COM port number incorrectly specified. ' +
      'Valid range is 1..65535.');
  end
  else
  begin
    PropPortItem.Text := NewText;
    PropPortItemItemClick(nil);
  end;
end;

procedure TLampsMainForm.SelectEEFileName;
begin
  with TXTOpenDialog, FormStorage do
  begin
    FileName := EEFileName;
    if not Execute then Exit;
    StoredValues[0].Value := FileName;
  end;
  EEFileAge := 0;
  PopulateEEListView(EEForm.ListView);
end;

procedure TLampsMainForm.EETestLoadActionExecute(Sender: TObject);
begin
  with TXTOpenDialog, FormStorage do
  begin
    FileName := EETestFileName;
    if not Execute then Exit;
    StoredValues[1].Value := FileName;
  end;
  EETestFileAge := 0;
end;

procedure TLampsMainForm.PasswordEditAcceptText(Sender: TObject;
  var NewText: String; var Accept: Boolean);
begin
  IgnorePasswordCase := True;
end;

procedure TLampsMainForm.ComPortTriggerAvail(CP: TObject; Count: Word);
var
  C: Char;
  I: Integer;
begin
  for I := 1 to Count do
  begin
    C := ComPort.GetChar;
    if InputDataPutIndex < InputDataSize then
    begin
      InputData[InputDataPutIndex] := C;
      Inc(InputDataPutIndex);
    end;
  end;
end;

procedure TLampsMainForm.SaveEEDefaults;
var
  I: Integer;
  P: PLampParamRec;
  S, SectionStr: String;
begin
  SectionStr := Format('EE%.03d', [EESection]);
  with TIniFile.Create(EEFileName) do
  try
    with EEForm.ListView, Items do
    begin
      for I := 0 to Count - 1 do
        if Items[I].Checked then
        begin
          P := Items[I].Data;
          Str(P^.Value:0:3, S);
          WriteString(SectionStr, 'Param' + IntToStr(I) + 'Default', S);
        end;
    end;
  finally
    UpdateFile;
    Free;
  end;
  EEFileAge := FileAge(EEFileName);
end;

procedure TLampsMainForm.EETestSaveDefaultsActionExecute(Sender: TObject);
var
  I: Integer;
  P: PLampParamRec;
  S, SectionStr: String;
begin
  SectionStr := Format('EE%.03d', [EETestSection]);
  with TIniFile.Create(EETestFileName) do
  try
    with EETestList do
      for I := 0 to Count - 1 do
      begin
        P := Items[I];
        Str(P^.Value:0:3, S);
        WriteString(SectionStr, 'Param' + IntToStr(I) + 'Default', S);
      end;
  finally
    UpdateFile;
    Free;
  end;
  EETestFileAge := FileAge(EETestFileName);
end;

end.
