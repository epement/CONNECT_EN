{$I-,F+,O+,X+}
unit FindDlg;

interface

uses Objects, Views, Drivers, Dialogs;

type
  TSearchData = record
    MatchStr: String[255];
    Options: Word;
  end;

  TReplaceData = record
    MatchStr, NewString: String[255];
    Options: Word;
  end;

  PDragInputLine = ^TDragInputLine;
  TDragInputLine = object(TInputLine)
    procedure HandleEvent(var Event: TEvent); virtual;
    function Valid(Command: Word): Boolean; virtual;
  end;

  PFindAllList = ^TFindAllList;
  TFindAllList = object(TListViewer)
    Caller: PView;
    Buffer: PCollection;
    TopLine: Integer;
    constructor Init(var Bounds: TRect; ANumCols: Integer;
      AHScrollBar, AVScrollBar: PScrollBar);
    destructor Done; virtual;
    procedure GetData(var Rec); virtual;
    procedure GetLine(Index: Integer; var S: String);
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure ClipCopy;
    procedure UpdateCommands;
  end;

  PMultiSearchList = ^TMultiSearchList;
  TMultiSearchList = object(TListViewer)
    List, SelList: PCollection;
    constructor Init(var Bounds: TRect; ANumCols: Integer;
      AHScrollBar, AVScrollBar: PScrollBar);
    destructor Done; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function IsSelected(Item: Integer): Boolean; virtual;
    procedure Invert;
    procedure FillList;
    procedure MultiSearch(ACommand: Word);
    procedure SelectFocused(Down: Boolean);
  end;

const
  frCaseSensitive = 1;
  frFromCursor = 2;
  frWholeWordsOnly = 4;
  frRegExp = 8;
  frSelectedText = $10;
  frBackward = $20;
  frPromptOnReplace = $40;
  frGroupUndo = $80;

  SearchData: TSearchData = (MatchStr: ''; Options: 0);
  ReplaceData: TReplaceData = (MatchStr: ''; NewString: ''; Options: $40);

  SearchMsg: String[31] = 'Searching for text. Esc aborts.';

{ Added 02.03.99 }
  REGEXPHistStr = #$FF + '(REGEXP)';

function WordPos(var ASubS, AStr: String;
  Delims: TCharSet; Back: Boolean): Byte;
function ConfirmReplaceMsgBox(var R: TRect): Word;
procedure InvalidRegExpMsgBox;
function ValidRegExp(const S: String): Boolean;
function FindDialog(All: Boolean): PDialog;
procedure RSRFindDialog(RSR: PResourceFile);
function LoadFindDialog(All, DisAll: Boolean; DisableMask: Longint): PDialog;
procedure ReplaceFindClusterText(D: PDialog; Index: Integer;
  const NewText: String);
function ReplaceDialog: PDialog;
procedure RSRReplaceDialog(RSR: PResourceFile);
function LoadReplaceDialog(DisableMask: Longint): PDialog;
function FindAllDialog(Count: Integer; Hex: Boolean): PDialog;
procedure MultiSearchDialog;

implementation

uses App, MsgBox, History, FindAll, FEditor, EditMsg, Swaps, ClipPrim,
  RegExp, RevPos, StrCol, HeapUMB, Keyboard, TPString, Consts, Commands,
  Defaults;

type
  PMultiCollection = ^TMultiCollection;
  TMultiCollection = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

function WordPos(var ASubS, AStr: String;
  Delims: TCharSet; Back: Boolean): Byte;
var
  P: Byte;
  NotWord: Boolean;
label
  Loop;
begin
  WordPos := 0;
Loop:
  if Back then P := RPos(ASubS, AStr)
  else P := Pos(ASubS, AStr);
  if P = 0 then Exit;
  NotWord := ((P > 1) and not (AStr[P - 1] in Delims)) or
    ((P + Length(ASubS) <= Length(AStr)) and
     not (AStr[P + Length(ASubS)] in Delims));
  if NotWord then
  begin
    AStr[P] := #$FF;
    Goto Loop;
  end;
  WordPos := P;
end;

function ConfirmReplaceMsgBox(var R: TRect): Word;
begin
  ConfirmReplaceMsgBox := MessageBoxRect(R,
    ^C'Replace this occurence ?', nil, mfConfirmation + mfYesAllNoCancel);
end;

procedure InvalidRegExpMsgBox;
begin
  MessageBox(^C'Invalid regular expression:'#13#13^C +
    RegError + '.', nil, mfError + mfOkButton);
end;

function ValidRegExp(const S: String): Boolean;
var
  Regex: Pointer;
begin
  if S = '' then ValidRegExp := True
  else
  begin
    Regex := nil;
    Regex := RegCompile(S);
    ValidRegExp := Regex <> nil;
    RegFree(Regex);
  end;
end;

procedure TDragInputLine.HandleEvent(var Event: TEvent);
var
  I: Integer;
  P: Pointer;
  S: String;
begin
  if Event.What = evKeyDown then
    if (Event.KeyCode = kbRight) and (CurPos = Length(Data^)) then
    begin
      P := Message(Application, evBroadcast, cmGetLine, Application);
      if P <> nil then
      begin
	S := PString(P)^;
	if Data^ = '' then Data^ := S[1]
	else
	begin
	  I := Pos(Data^, S);
	  if (I <> 0) and (I + Length(Data^) <= Length(S)) then
	    Data^ := Data^ + S[I + Length(Data^)];
	end;
      end;
    end
    else if (Event.KeyCode = kbLeft) and (CurPos = 0) and
      (SelStart = 0) and (SelEnd = 0) then
    begin
      P := Message(Application, evBroadcast, cmGetLine, Application);
      if P <> nil then
      begin
	S := PString(P)^;
	if Data^ = '' then Data^ := S[Byte(S[0])]
	else
	begin
	  I := RPos(Data^, S);
	  if I > 1 then Data^ := S[I - 1] + Data^;
	end;
	DrawView;
      end;
    end;
  TInputLine.HandleEvent(Event);
end;

function TDragInputLine.Valid(Command: Word): Boolean;

function RegExpChecked: Boolean;
var
  C: PView;

function IsCluster(P: PView): Boolean; far;
begin
  IsCluster := (P <> @Self) and (P^.DataSize <> 0);
end;

begin
  C := Owner^.FirstThat(@IsCluster);
  RegExpChecked := (C <> nil) and
    (PCluster(C)^.Value and frRegExp <> 0);
end;

begin
  Valid := False;
  if ((Command = cmOk) or (Command = cmYes)) and (Origin.Y = 2) then
  begin
    if Data^ = '' then
    begin
      MessageBox(^C'The search string cannot be blank.',
	nil, mfError + mfOkButton);
      Select;
      Exit;
    end;
    if RegExpChecked and not ValidRegExp(Data^) then
    begin
      InvalidRegExpMsgBox;
      Select;
      Exit;
    end;
  end;
  Valid := TInputLine.Valid(Command);
end;

function FindDialog(All: Boolean): PDialog;
var
  D: PDialog;
  Control: PView;
  R: TRect;
  S: String[4];
begin
  if All then S := ' all' else S := '';
  R.Assign(0, 0, 52, 12);
  D := New(PDialog, Init(R, 'Find' + S));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcFind;
    R.Assign(16, 2, Size.X - 6, 3);
    Control := New(PDragInputLine, Init(R, 255));
    Control^.Options := Control^.Options or ofValidate;
    Insert(Control);
    R.Assign(2, 2, 16, 3);
    Insert(New(PLabel, Init(R, '~T~ext to find', Control)));
    StandardHistory(Control, FindHistoryId);

    R.Assign(3, 5, Size.X - 3, 8);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~C~ase sensitive',
      NewSItem('~F~rom cursor',
      NewSItem('~W~hole words only',
      NewSItem('~R~egular expression',
      NewSItem('~S~elected text',
      NewSItem('Search ~b~ackward', nil))))))));
    Control^.HelpCtx := hcFind;
    Insert(Control);
    R.Assign(2, 4, Size.X - 3, 5);
    Insert(New(PLabel, Init(R, 'Options', Control)));

    if All then
    begin
      R.Assign(3, Size.Y - 3, 13, Size.Y - 1);
      Insert(New(PButton, Init(R, 'O~K~', cmYes, bfDefault)));
      R.Assign(14, Size.Y - 3, 26, Size.Y - 1);
      Insert(New(PButton, Init(R, 'Find ~1~st', cmOk, bfNormal)));
    end
    else
    begin
      R.Assign(3, Size.Y - 3, 13, Size.Y - 1);
      StandardOkButton(R, D);
      R.Assign(14, Size.Y - 3, 26, Size.Y - 1);
      Insert(New(PButton, Init(R, 'Find ~a~ll', cmYes, bfNormal)));
    end;
    R.Assign(27, Size.Y - 3, 37, Size.Y - 1);
    StandardCancelButton(R, D);
    R.Assign(38, Size.Y - 3, 48, Size.Y - 1);
    StandardHelpButton(R, D);

    SelectNext(False);
  end;
  FindDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRFindDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := FindDialog(False);
  if D <> nil then
  begin
    RSR^.Put(D, 'FINDDIALOG');
    Dispose(D, Done);
  end;
  D := FindDialog(True);
  if D <> nil then
  begin
    RSR^.Put(D, 'FINDALLDIALOG');
    Dispose(D, Done);
  end;
end;

{ Added 02.03.99 }
function IsREGEXPCheckBoxStr(P: PString): Boolean;
begin
  IsREGEXPCheckBoxStr := (P <> nil) and (Length(P^) > 1) and
    (P^[1] = '~') and (P^[2] = 'R');
end;

function GetREGEXPCheckBox(G: PGroup; var Mask: Word): PCheckBoxes;

function IsREGEXPCheckBox(P: PView): Boolean; far;
var
  B: Boolean;
  I: Integer;
begin
  B := False;
  if TypeOf(P^) = TypeOf(TCheckBoxes) then
    for I := 0 to PCheckBoxes(P)^.Strings.Count - 1 do
      if PCheckBoxes(P)^.ButtonState(I) and
	 IsREGEXPCheckBoxStr(PCheckBoxes(P)^.Strings.At(I)) then
      begin
	B := True;
	Mask := 1 shl I;
	Break;
      end;
  IsREGEXPCheckBox := B;
end;

begin
  GetREGEXPCheckBox := PCheckBoxes(G^.FirstThat(@IsREGEXPCheckBox));
end;

function REGEXPPutHistoryFunc(Link: PInputLine;
  const S: String): String;
var
  Mask: Word;
  P: PCheckBoxes;
begin
  P := GetREGEXPCheckBox(Link^.Owner, Mask);
  if (S = '') or (P = nil) or (P^.Value and Mask = 0) then
    REGEXPPutHistoryFunc := S
  else REGEXPPutHistoryFunc := S + REGEXPHistStr;
end;

function REGEXPGetHistoryFunc(Link: PInputLine;
  const S: String): String;
var
  I: Integer;
  Mask: Word;
  P: PCheckBoxes;
begin
  I := Pos(REGEXPHistStr, S);
  P := GetREGEXPCheckBox(Link^.Owner, Mask);
  if P <> nil then
  begin
    P^.PreserveBits := Mask;
    if I <> 0 then P^.Value := P^.Value or Mask
    else P^.Value := P^.Value and not Mask;
    P^.DrawView;
  end;
  if I <> 0 then REGEXPGetHistoryFunc := Copy(S, 1, I - 1)
  else REGEXPGetHistoryFunc := S;
end;

function LoadFindDialog(All, DisAll: Boolean; DisableMask: Longint): PDialog;
var
  D: PDialog;
  B: PButton;
  C: PCheckBoxes;
  H: PHistory;
  S: String[15];

function IsCluster(P: PView): Boolean; far;
begin
  IsCluster := TypeOf(P^) = TypeOf(TCheckBoxes);
end;

function IsAllButton(P: PView): Boolean; far;
begin
  IsAllButton := (TypeOf(P^) = TypeOf(TButton)) and
    (PButton(P)^.Title^[1] = 'F');
end;

function IsFindHistory(P: PView): Boolean; far;
begin
  IsFindHistory := TypeOf(P^) = TypeOf(THistory);
end;

begin
  if All then S := 'FINDALLDIALOG' else S := 'FINDDIALOG';
  D := PDialog(Resource^.Get(S));
  if D = nil then ResourceNotFoundMsgBox('Find dialog')
  else
  begin
    if DisAll then
    begin
      B := PButton(D^.FirstThat(@IsAllButton));
      if B <> nil then B^.State := B^.State or sfDisabled;
    end;
    if DisableMask <> 0 then
    begin
      C := PCheckBoxes(D^.FirstThat(@IsCluster));
      if C <> nil then C^.SetButtonState(DisableMask, False);
    end;
    H := PHistory(D^.FirstThat(@IsFindHistory));
    if H <> nil then
    begin
      H^.HistoryPutFunc := REGEXPPutHistoryFunc;
      H^.HistoryGetFunc := REGEXPGetHistoryFunc;
    end;
  end;
  LoadFindDialog := PDialog(Application^.ValidView(D));
end;

procedure ReplaceFindClusterText(D: PDialog; Index: Integer;
  const NewText: String);
var
  C: PCheckBoxes;

function IsCluster(P: PView): Boolean; far;
begin
  IsCluster := TypeOf(P^) = TypeOf(TCheckBoxes);
end;

begin
  if D <> nil then
  begin
    C := PCheckBoxes(D^.FirstThat(@IsCluster));
    if C <> nil then
    begin
      C^.Strings.AtFree(Index);
      C^.Strings.AtInsert(Index, NewStr(NewText));
    end;
  end;
end;

function ReplaceDialog;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 53, 15);
  D := New(PDialog, Init(R, 'Replace'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcReplace;
    R.Assign(16, 2, Size.X - 6, 3);
    Control := New(PDragInputLine, Init(R, 255));
    Control^.Options := Control^.Options or ofValidate;
    Insert(Control);
    R.Assign(2, 2, 16, 3);
    Insert(New(PLabel, Init(R, '~T~ext to find', Control)));
    StandardHistory(Control, FindHistoryId);

    R.Assign(16, 4, Size.X - 6, 5);
    Control := New(PDragInputLine, Init(R, 255));
    Control^.Options := Control^.Options or ofValidate;
    Insert(Control);
    R.Assign(6, 4, 16, 5);
    Insert(New(PLabel, Init(R, '~N~ew text', Control)));
    StandardHistory(Control, ReplaceHistoryId);

    R.Assign(3, 7, Size.X - 3, 11);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~C~ase sensitive',
      NewSItem('~F~rom cursor',
      NewSItem('~W~hole words only',
      NewSItem('~R~egular expression',
      NewSItem('~S~elected text',
      NewSItem('Search ~b~ackward',
      NewSItem('~P~rompt on replace',
      NewSItem('~G~roup Undo', nil))))))))));
    Control^.HelpCtx := hcReplace;
    Insert(Control);
    R.Assign(2, 6, Size.X - 3, 7);
    Insert(New(PLabel, Init(R, 'Options', Control)));

    StandardButtonRow(D, True);
  end;
  ReplaceDialog := PDialog(Application^.ValidView(D));
end;

procedure RSRReplaceDialog(RSR: PResourceFile);
var
  D: PDialog;
begin
  D := ReplaceDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'REPLACEDIALOG');
    Dispose(D, Done);
  end;
end;

function LoadReplaceDialog(DisableMask: Longint): PDialog;
var
  D: PDialog;
  C: PCheckBoxes;
  H: PHistory;

function IsCluster(P: PView): Boolean; far;
begin
  IsCluster := TypeOf(P^) = TypeOf(TCheckBoxes);
end;

function IsFindHistory(P: PView): Boolean; far;
begin
  IsFindHistory := (TypeOf(P^) = TypeOf(THistory)) and
    (P^.Origin.Y = 2);
end;

begin
  D := PDialog(Resource^.Get('REPLACEDIALOG'));
  if D = nil then ResourceNotFoundMsgBox('Replace dialog')
  else
  begin
    if DisableMask <> 0 then
    begin
      C := PCheckBoxes(D^.FirstThat(@IsCluster));
      if C <> nil then C^.SetButtonState(DisableMask, False);
    end;
    H := PHistory(D^.FirstThat(@IsFindHistory));
    if H <> nil then
    begin
      H^.HistoryPutFunc := REGEXPPutHistoryFunc;
      H^.HistoryGetFunc := REGEXPGetHistoryFunc;
    end;
  end;
  LoadReplaceDialog := PDialog(Application^.ValidView(D));
end;

const
  MaxLines = 64;

constructor TFindAllList.Init(var Bounds: TRect; ANumCols: Integer;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TListViewer.Init(Bounds, 1, AHScrollBar, AVScrollBar);
  GrowMode := gfGrowHiY;
  Buffer := New(PStringsCollection, Init(MaxLines, 1));
end;

destructor TFindAllList.Done;
begin
  Dispose(Buffer, Done);
  TListViewer.Done;
end;

procedure TFindAllList.GetData(var Rec);
begin
  Integer(Rec) := Integer(
    PSwapLinesCollection(
      PFileEditor(Caller)^.FindAllList)^.ExtraAt(Focused));
end;

procedure TFindAllList.GetLine(Index: Integer; var S: String);
var
  I, N: Integer;
  P: PString;
  L: Longint;
begin
  if (Index < TopLine) or (Index >= TopLine + Buffer^.Count) then
  begin
    Buffer^.FreeAll;
    TopLine := Index - MaxLines div 2;
    if TopLine + MaxLines > Range then TopLine := Range - MaxLines;
    if TopLine < 0 then TopLine := 0;
    I := TopLine;
    while (I < TopLine + MaxLines) and (I < Range) do
    begin
      N := Integer(
	PSwapLinesCollection(
          PFileEditor(Caller)^.FindAllList)^.ExtraAt(I));
      if Caller^.Options and ofHex <> 0 then
      begin
        PFileEditor(Caller)^.GetValidLine(N, S);
        TrimSt(S);
{        Buffer^.Insert(NewStr(S));}
	Buffer^.Insert(NewStrUMB(S));
      end
      else
      begin
        L := Longint(PSwapLinesCollection(
          PFileEditor(Caller)^.FileLines)^.ExtraAt(N));
        if L = 0 then S := ''
        else with PFileEditor(Caller)^.SwapStream^ do
        begin
          Seek(L);
          Read(S[0], 1);
	  Read(S[1], Byte(S[0]));
	  S := Trim(Detab(S, TabSize));
	end;
{        Buffer^.Insert(NewStr(S));}
	Buffer^.Insert(NewStrUMB(S));
      end;
      Inc(I);
    end;
  end;
  I := Index - TopLine;
  P := Buffer^.At(I);
  if P = nil then S := '' else S := P^;
end;

function TFindAllList.GetText(Item: Integer; MaxLen: Integer): String;
var
  Hex: Boolean;
  I: Integer;
  L: Longint;
  C, S: String;
begin
  Hex := Caller^.Options and ofHex <> 0;
  GetLine(Item, S);
  I := Integer(
    PSwapLinesCollection(
      PFileEditor(Caller)^.FindAllList)^.ExtraAt(Item));
  if Hex then
  begin
    L := LongMul(I, 16);
    FormatStr(C, '%05x ', L);
  end
  else
  begin
    L := I + 1;
    FormatStr(C, '%-5d ', L);
  end;
  GetText := C + S;
end;

procedure TFindAllList.HandleEvent(var Event: TEvent);
var
  P: Pointer;
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    Event.What := evCommand;
    if Event.CharCode = ' ' then Event.Command := cmModifyItem
    else Event.Command := cmNewItem;
  end
  else if Event.What = evKeyDown then
    case Event.KeyCode of
      kbDel:
        begin
          Event.What := evCommand;
	  Event.Command := cmDeleteItem;
        end;
      kbCtrlIns:
        begin
          Event.What := evCommand;
          Event.Command := cmCopy;
	end;
    end;
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmNewItem: if CommandEnabled(cmNewItem) then EndModal(cmOk);
      cmModifyItem: if CommandEnabled(cmModifyItem) then
	begin
	  PFileEditor(Caller)^.DrawFlag := True;
	  LongRec(P).Hi := Integer(
	    PSwapLinesCollection(
	      PFileEditor(Caller)^.FindAllList)^.ExtraAt(Focused));
	  LongRec(P).Lo := 0;
	  if Caller^.Size.Y > 3 then PFileEditor(Caller)^.ScrollTo(
	    PFileEditor(Caller)^.Delta.X, LongRec(P).Hi - 2);
	  Message(Caller, evBroadcast, cmGoToLine, P);
	  PFileEditor(Caller)^.DrawFlag := False;
	  Message(Caller, evBroadcast, cmTrackSource, P);
	end;
      cmDeleteItem: if CommandEnabled(cmDeleteItem) then
	begin
	  PSwapLinesCollection(
	    PFileEditor(Caller)^.FindAllList)^.ExtraAtFree(Focused);
	  Buffer^.FreeAll;
	  TopLine := MaxInt;
	  SetRange(PFileEditor(Caller)^.FindAllList^.Count);
	  UpdateCommands;
	  DrawView;
	end;
      cmCopy: ClipCopy;
      else Exit;
    end;
    Event.What := evNothing;
  end;
  TListViewer.HandleEvent(Event);
end;

procedure TFindAllList.SetData(var Rec);
var
  I, N: Integer;
begin
  Caller := PView(Rec);
  SetRange(PFileEditor(Caller)^.FindAllList^.Count);
  HScrollBar^.SetRange(0, 261 * Byte(Caller^.Options and ofHex = 0));
  I := 0;
  with PFileEditor(Caller)^ do
  begin
    N := Delta.Y + Cursor.Y;
    while (I < FindAllList^.Count - 1) and
      (Integer(PSwapLinesCollection(
        FindAllList)^.ExtraAt(I)) < N) do Inc(I);
  end;
  FocusItem(I);
  UpdateCommands;
end;

procedure TFindAllList.ClipCopy;
var
  I, SaveCount, MaxLen: Integer;
  S: String;
begin
  if (DiskClipStream = nil) or
     (PFileEditor(Caller)^.FindAllList^.Count = 0) then Exit;
  DrawFindAllClipCopyStatus;
  SetExpandClipAreaFlag;
  MaxLen := 0;
  SaveCount := ClipLines^.Count;
  for I := 0 to PFileEditor(Caller)^.FindAllList^.Count - 1 do
  begin
    GetLine(I, S);
    PutClipLine(S);
    if not MarkColumns or (Length(S) > MaxLen) then MaxLen := Length(S);
    if ClipOverflow or ((KbdStatus = 1) and AbortAction) then Break;
  end;
  SetOrExpandClipArea(SaveCount, MaxLen + 1);
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure TFindAllList.UpdateCommands;
begin
  if PFileEditor(Caller)^.FindAllList^.Count = 0 then
    DisableCommands(NewCommands + ModifyCommands + DeleteCommands)
  else
  begin
    EnableCommands(NewCommands + DeleteCommands);
    if Caller^.Options and ofHex <> 0 then
      DisableCommands(ModifyCommands)
    else EnableCommands(ModifyCommands);
  end;
end;

function InitFindAllViewer(var R: TRect; HBar, VBar: PScrollBar;
  InfoPtr: Pointer): PView;
begin
  InitFindAllViewer := New(PFindAllList, Init(R, 1, HBar, VBar));
end;

function FindAllDialog(Count: Integer; Hex: Boolean): PDialog;
var
  R: TRect;
  F: TInitViewerFunc;
begin
  R.Assign(0, 0, 69, ScreenHeight - 14);
  if Hex then R.B.X := 42;
  F := InitFindAllViewer;
  FindAllDialog := CustomFindAllDialog(R,
    '~E~ditor' + FoundLinesCountStr(Count), F, nil);
end;

procedure TMultiCollection.FreeItem(Item: Pointer);
begin
end;

constructor TMultiSearchList.Init(var Bounds: TRect; ANumCols: Integer;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TListViewer.Init(Bounds, 1, AHScrollBar, AVScrollBar);
  GrowMode := gfGrowHiY;
  List := New(PMultiCollection, Init(8, 8));
  SelList := New(PMultiCollection, Init(8, 8));
end;

destructor TMultiSearchList.Done;
begin
  Dispose(SelList, Done);
  Dispose(List, Done);
  TListViewer.Done;
end;

function TMultiSearchList.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: PWindow;
  S: String;
begin
  P := List^.At(Item);
  if P = nil then GetText := ''
  else
  begin
    S := '    ' + EditorTypes[P^.Options and ofHex <> 0] + P^.Title^;
    if SelList^.IndexOf(List^.At(Item)) <> -1 then S[1] := 'û';
    if P^.Number > 0 then S[3] := Char(P^.Number + $30);
    GetText := S;
  end;
end;

procedure TMultiSearchList.HandleEvent(var Event: TEvent);
begin
  if (State and sfSelected <> 0) and (Event.What = evKeyDown) and
     ((Event.KeyCode = kbIns) or (Event.KeyCode = kbEnter) or
      (Event.CharCode = ' ')) then
  begin
    SelectFocused(Event.KeyCode <> kbEnter);
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and (Event.KeyCode = kbGrayMul) then
  begin
    Invert;
    Event.What := evNothing;
  end
  else if (Event.What = evMouseDown) and
    (Event.Buttons = mbRightButton) then
  begin
    TListViewer.HandleEvent(Event);
    SelectFocused(True);
  end
  else TListViewer.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmFind, cmReplace, cmSearchAgain, cmUndo, cmRedo, cmSave:
        if List^.Count <> 0 then EndModal(Event.Command);
      else Exit;
    end;
    Select;
    Event.What := evNothing;
  end;
end;

function TMultiSearchList.IsSelected(Item: Integer): Boolean;
begin
  IsSelected := ((SelList^.Count = 0) and (Item = Focused)) or
    ((SelList^.Count > 0) and (SelList^.IndexOf(List^.At(Item)) <> -1));
end;

procedure TMultiSearchList.Invert;
var
  I, N: Integer;
  P: Pointer;
begin
  for N := 0 to List^.Count - 1 do
  begin
    P := List^.At(N);
    I := SelList^.IndexOf(P);
    if I = -1 then SelList^.Insert(P)
    else SelList^.AtFree(I);
  end;
  DrawView;
end;

procedure TMultiSearchList.FillList;
var
  I: Integer;
  SaveP: Pointer;

procedure DoInsert(P: PView); far;
begin
  if (Message(P, evBroadcast, cmIsASCII, nil) <> nil) or
     (Message(P, evBroadcast, cmIsHex, nil) <> nil) then List^.Insert(P);
end;

begin
  SaveP := List^.At(Focused);
  List^.FreeAll;
  Desktop^.ForEach(@DoInsert);
  SetRange(List^.Count);
  if SaveP <> nil then
  begin
    I := List^.IndexOf(SaveP);
    if I <> -1 then FocusItem(I);
  end;
  EnableCommands(UndoCommands + RedoCommands);
end;

procedure TMultiSearchList.MultiSearch(ACommand: Word);
var
  Flag: Boolean;
  I, Count: Integer;
  P: PFileEditor;
begin
  case ACommand of
    cmFind: if Application^.ExecuteDialog(LoadFindDialog(False, True, 0),
      @SearchData, False) = cmCancel then Exit;
    cmReplace: if Application^.ExecuteDialog(LoadReplaceDialog(0),
      @ReplaceData, False) = cmCancel then Exit;
  end;
  Count := SelList^.Count;
  if Count = 0 then Count := 1;
  for I := 0 to Count - 1 do
  begin
    if SelList^.Count = 0 then
      P := PFileEditor(PEditorWindow(List^.At(Focused))^.Editor)
    else P := PFileEditor(PEditorWindow(SelList^.At(I))^.Editor);
    if ACommand <> cmSave then P^.Owner^.Select;
    case ACommand of
      cmFind: P^.Search(SearchData.MatchStr, SearchData.Options);
      cmReplace:
	begin
	  Byte(Flag) := 2;
	  P^.Replace(Flag);
	end;
      cmSearchAgain, cmUndo, cmRedo, cmSave:
	Message(P, evCommand, ACommand, nil);
    end;
  end;
end;

procedure TMultiSearchList.SelectFocused(Down: Boolean);
var
  I: Integer;
  P: Pointer;
begin
  P := List^.At(Focused);
  I := SelList^.IndexOf(P);
  if I = -1 then SelList^.Insert(P)
  else SelList^.AtFree(I);
  if Down and (Focused < Range - 1) then FocusItem(Focused + 1)
  else DrawView;
end;

procedure MultiSearchDialog;
var
  C: Word;
  D: PDialog;
  VBar, HBar: PScrollBar;
  Control: PMultiSearchList;
  R: TRect;
begin
  R.Assign(0, 0, 69, ScreenHeight - 6);
  D := New(PDialog, Init(R, 'Multiple search and replace'));
  with D^ do
  begin
    Options := Options or ofCentered;
    GrowMode := GrowMode + gfGrowHiY;
    HelpCtx := hcSHMultiSearch;

    R.Assign(3, Size.Y - 2, Size.X - 16, Size.Y - 1);
    HBar := New(PScrollBar, Init(R));
    HBar^.Options := HBar^.Options or ofPostProcess;
    HBar^.SetRange(0, 255);
    Insert(HBar);

    R.Assign(Size.X - 16, 2, Size.X - 15, Size.Y - 2);
    VBar := New(PScrollBar, Init(R));
    VBar^.Options := VBar^.Options or ofPostProcess;
    Insert(VBar);

    R.Assign(3, 2, Size.X - 16, Size.Y - 2);
    Control := New(PMultiSearchList, Init(R, 1, HBar, VBar));
    Control^.Options := Control^.Options or ofPostProcess;
    Insert(Control);
    R.Assign(2, 1, Size.X - 15, 2);
    Insert(New(PLabel, Init(R, '~W~indows', Control)));

    R.Assign(Size.X - 14, 2, Size.X - 3, 4);
    Insert(New(PButton, Init(R, '~F~ind', cmFind, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    Insert(New(PButton, Init(R, '~R~eplace', cmReplace, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    Insert(New(PButton, Init(R, '~A~gain', cmSearchAgain, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    Insert(New(PButton, Init(R, '~U~ndo', cmUndo, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    Insert(New(PButton, Init(R, 'Re~d~o', cmRedo, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    Insert(New(PButton, Init(R, '~S~ave', cmSave, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    StandardCancelButton(R, D);
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    StandardHelpButton(R, D);
    SelectNext(False);
  end;
  repeat
    Control^.FillList;
    if Application^.ValidView(D) = nil then Exit;
    C := Desktop^.ExecView(D);
    if C = cmCancel then Break;
    Control^.MultiSearch(C);
  until False;
  Dispose(D, Done);
end;

end.
