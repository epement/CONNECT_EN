{$I-,X+,O+,F+}
unit CmntDlg;

interface

uses Objects, Drivers, Views, Dialogs, CmntList;

type
  PCommentList = ^TCommentList;
  TCommentList = object(TListBox)
    SelList: PCollection;
    constructor Init(var Bounds: TRect; ANumCols: Integer;
      AScrollBar: PScrollBar);
    destructor Done; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function IsSelected(Item: Integer): Boolean; virtual;
    procedure SelectFocused(Down: Boolean);
    procedure Invert;
    procedure Unselect;
    procedure SaveList;
    function GetNewItem(const Header: String): PCommentRec;
    procedure ModifyItem;
    procedure NewItem;
    procedure ItemOptions;
    procedure ItemFiles;
    procedure ItemPrinter;
    procedure DeleteItem;
    procedure FocusMask;
    procedure NewItemPos;
  end;

  PCommentDialog = ^TCommentDialog;
  TCommentDialog = object(TDialog)
    CommentList: PCommentList;
    constructor Init;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure CommentDialog;

implementation

uses Dos, App, MsgBox, Swaps, EditMsg, HistList, History, DirPrim, Options,
  CNInputs, MacroDlg, HeapUMB, LFN, TPString, Consts, Commands, Defaults;

type
  PSelList = ^TSelList;
  TSelList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

procedure TSelList.FreeItem(Item: Pointer);
begin
end;

constructor TCommentList.Init(var Bounds: TRect; ANumCols: Integer;
  AScrollBar: PScrollBar);
begin
  Inherited Init(Bounds, 1, AScrollBar);
  SelList := New(PSelList, Init(8, 8));
end;

destructor TCommentList.Done;
begin
  Dispose(SelList, Done);
  Inherited Done;
end;

function TCommentList.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: PCommentRec;
  S, C: String;
begin
  P := Comments^.At(Item);
  if P = nil then S := ''
  else
  begin
    FillChar(S, SizeOf(String), #32);
    S[0] := Char(Size.X);
    if P^.Mask = nil then C := ''
    else C := P^.Mask^;
    Move(C[1], S[1], Length(C));
    if P^.Comment = nil then C := ''
    else C := P^.Comment^;
    if C[0] > #15 then C[0] := #15;
    Move(C[1], S[Size.X - Length(C) - 1], Length(C));
  end;
  GetText := S;
end;

procedure TCommentList.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evKeyDown) and (Event.KeyCode = kbIns) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmNewItem;
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and (Event.CharCode = ' ') then
  begin
    SelectFocused(True);
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and (Event.KeyCode = kbGrayMul) then
  begin
    Invert;
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and (Event.KeyCode = kbGrayMinus) then
  begin
    Unselect;
    Event.What := evNothing;
  end
  else if (Event.What = evMouseDown) and (Event.Buttons = mbRightButton) then
  begin
    Inherited HandleEvent(Event);
    SelectFocused(True);
  end
  else if (Event.What = evMouseDown) and Event.Double then
  begin
    Pending.What := evCommand;
    Pending.Command := cmModifyItem;
    Event.What := evNothing;
  end
  else Inherited HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbCtrlUp: if not MoveListItem(@Self, Comments, True) then Exit;
      kbCtrlDn: if not MoveListItem(@Self, Comments, False) then Exit;
      else Exit;
    end;
    SaveList;
    Event.What := evNothing;
  end;
end;

function TCommentList.IsSelected(Item: Integer): Boolean;
begin
  IsSelected := ((SelList^.Count = 0) and (Item = Focused)) or
    ((SelList^.Count > 0) and (SelList^.IndexOf(Comments^.At(Item)) <> -1));
end;

procedure TCommentList.SelectFocused(Down: Boolean);
var
  I: Integer;
  P: Pointer;
begin
  P := Comments^.At(Focused);
  if P = nil then Exit;
  I := SelList^.IndexOf(P);
  if I = -1 then SelList^.Insert(P)
  else SelList^.AtFree(I);
  if Down and (Focused < Range - 1) then FocusItem(Focused + 1)
  else DrawView;
end;

procedure TCommentList.Invert;
var
  I, N: Integer;
  P: Pointer;
begin
  for N := 0 to Comments^.Count - 1 do
  begin
    P := Comments^.At(N);
    I := SelList^.IndexOf(P);
    if I = -1 then SelList^.Insert(P)
    else SelList^.AtFree(I);
  end;
  DrawView;
end;

procedure TCommentList.Unselect;
begin
  SelList^.FreeAll;
  DrawView;
end;

procedure TCommentList.SaveList;
var
  I: Integer;
  P: PCommentRec;
  S: TDosStream;
  Name: FNameStr;
begin
  LogEvent := lcDiskWrite;
  DrawStatusLine('Updating Editor Group list file.');
  SetCNConfigName(Name, 'CMT');
  S.Init(Name, stCreate);
  S.Write(NewCmtSign[1], 6);
  for I := 0 to Comments^.Count - 2 do
  begin
    if S.Status <> stOk then Break;
    P := Comments^.At(I);
    S.WriteStr(P^.Mask);
    S.WriteStr(P^.Comment);
    S.WriteStr(P^.HelpName);
    S.WriteStr(P^.INXLATName);
    S.WriteStr(P^.OUTXLATName);
    if P^.MacroName <> nil then
      P^.NewOptions := P^.NewOptions or crHasMacros
    else P^.NewOptions := P^.NewOptions and not crHasMacros;
    if P^.PrnRec <> nil then
      P^.NewOptions := P^.NewOptions or crHasPrnRec
    else P^.NewOptions := P^.NewOptions and not crHasPrnRec;
    S.Write(P^.NewOptions, SizeOf(Byte));
    if P^.NewOptions and crHasMacros <> 0 then S.WriteStr(P^.MacroName);
    S.WriteStr(P^.SyntaxName);
    if P^.NewOptions and crHasPrnRec <> 0 then
    begin
      S.WriteStr(P^.PrnRec^.PrnDeviceName);
      S.WriteStr(P^.PrnRec^.PrnFontName);
      S.WriteStr(P^.PrnRec^.PrnInitString);
      S.WriteStr(P^.PrnRec^.PrnLeftMargin);
      S.WriteStr(P^.PrnRec^.PrnTopMargin);
      S.WriteStr(P^.PrnRec^.PrnBottomMargin);
      S.WriteStr(P^.PrnRec^.PrnLinesPerPage);
      S.WriteStr(P^.PrnRec^.PrnInterval);
      S.WriteStr(P^.PrnRec^.PrnCharsPerCycle);
      S.Write(P^.PrnRec^.PrnOptions, SizeOf(Word));
    end;
    S.Write(P^.Options,
      SizeOf(Longint) + SizeOf(Byte) * 2 + SizeOf(TCharSet));
  end;
  S.Done;
  Message(Desktop, evBroadcast, cmEditOptions, nil);
end;

procedure SetStrField(P: PString; var S: String);
begin
  if P = nil then S := '' else S := P^;
end;

function TCommentList.GetNewItem(const Header: String): PCommentRec;
type
  TDataRec = record
    Mask: MaskStr;
    Comment: CommentStr;
    Opt: Word;
    HelpName: FNameStr;
    INXLATName: FNameStr;
    OUTXLATName: FNameStr;
    SyntaxName: FNameStr;
    MacroName: FNameStr;
    Options: Longint;
    TabSize: Byte;
    MaxLineWidth: Byte;
    WordDelims: TCharSet;
    NewOptions: Byte;
    PrnSign: Byte;
    PrnDeviceName: FNameStr;
    PrnFontName: FNameStr;
    PrnInitString: String[PrnInitLen];
    PrnLeftMargin: String[PrnMarginLen];
    PrnTopMargin: String[PrnMarginLen];
    PrnBottomMargin: String[PrnMarginLen];
    PrnLinesPerPage: String[PrnLinesLen];
    PrnInterval: String[PrnIntervalLen];
    PrnCharsPerCycle: String[PrnCycleLen];
    PrnOptions: Word;
  end;
var
  IsNew: Boolean;
  R: TRect;
  D: PDialog;
  Control: PView;
  P: PCommentRec;
  T: TDataRec;
begin
  GetNewItem := nil;
  IsNew := Header[1] = 'N';
  R.Assign(0, 0, 33, 11);
  D := New(PDialog, Init(R, Header));
  with D^ do
  begin
    HelpCtx := hcNewComment;
    Options := Options or ofCentered;
    R.Assign(13, 2, Size.X - 3, 3);
    Control := New(PInputLine, Init(R, 12));
    Insert(Control);
    R.Assign(2, 2, 13, 3);
    Insert(New(PLabel, Init(R, 'File ~n~ame', Control)));

    R.Assign(13, 4, Size.X - 3, 5);
    Control := New(PInputLine, Init(R, 127));
    Insert(Control);
    R.Assign(2, 4, 13, 5);
    Insert(New(PLabel, Init(R, '~C~omments', Control)));

    R.Assign(3, 6, Size.X - 3, 7);
    Insert(New(PCheckBoxes, Init(R,
      NewSItem('~R~egular expression', nil))));

    R.Assign(3, Size.Y - 3, 13, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  P := Comments^.At(Focused);
  if P = nil then
  begin
    SetStrField(nil, T.Mask);
    SetStrField(nil, T.Comment);
    T.Opt := 0;
    SetStrField(nil, T.HelpName);
    SetStrField(nil, T.INXLATName);
    SetStrField(nil, T.OUTXLATName);
    SetStrField(nil, T.MacroName);
    SetStrField(nil, T.SyntaxName);
    T.Options := EditOptions;
    T.TabSize := TabSize;
    T.MaxLineWidth := MaxLineWidth;
    T.WordDelims := WordDelims;
    T.NewOptions := NewEditOptions;
    T.PrnSign := 0;
  end
  else
  begin
    SetStrField(P^.Mask, T.Mask);
    SetStrField(P^.Comment, T.Comment);
    if P^.Options and eoRegExpComment = 0 then T.Opt := 0
    else T.Opt := 1;
    SetStrField(P^.HelpName, T.HelpName);
    SetStrField(P^.INXLATName, T.INXLATName);
    SetStrField(P^.OUTXLATName, T.OUTXLATName);
    SetStrField(P^.MacroName, T.MacroName);
    SetStrField(P^.SyntaxName, T.SyntaxName);
    T.Options := P^.Options;
    T.TabSize := P^.TabSize;
    T.MaxLineWidth := P^.MaxLineWidth;
    T.WordDelims := P^.WordDelims;
    T.NewOptions := P^.NewOptions;
    if P^.PrnRec = nil then T.PrnSign := 0
    else
    begin
      T.PrnSign := P^.PrnRec^.PrnSign;
      SetStrField(P^.PrnRec^.PrnDeviceName, T.PrnDeviceName);
      SetStrField(P^.PrnRec^.PrnFontName, T.PrnFontName);
      SetStrField(P^.PrnRec^.PrnInitString, T.PrnInitString);
      SetStrField(P^.PrnRec^.PrnLeftMargin, T.PrnLeftMargin);
      SetStrField(P^.PrnRec^.PrnTopMargin, T.PrnTopMargin);
      SetStrField(P^.PrnRec^.PrnBottomMargin, T.PrnBottomMargin);
      SetStrField(P^.PrnRec^.PrnLinesPerPage, T.PrnLinesPerPage);
      SetStrField(P^.PrnRec^.PrnInterval, T.PrnInterval);
      SetStrField(P^.PrnRec^.PrnCharsPerCycle, T.PrnCharsPerCycle);
      T.PrnOptions := P^.PrnRec^.PrnOptions;
    end;
  end;
  if Header[Length(Header)] = 's' then T.Mask := 'Selected';
  if Application^.ExecuteDialog(D, @T, False) <> cmCancel then
  begin
{
    GetMem(P, SizeOf(TCommentRec));
    P^.Mask := NewStr(Trim(T.Mask));
    P^.Comment := NewStr(StUpcase(Trim(T.Comment)));
    P^.HelpName := NewStr(T.HelpName);
    P^.INXLATName := NewStr(T.INXLATName);
    P^.OUTXLATName := NewStr(T.OUTXLATName);
    P^.MacroName := NewStr(T.MacroName);
    P^.SyntaxName := NewStr(T.SyntaxName);
    if T.PrnSign = 0 then P^.PrnRec := nil
    else
    begin
      GetMem(P^.PrnRec, SizeOf(TPrnRec));
      P^.PrnRec^.PrnSign := T.PrnSign;
      P^.PrnRec^.PrnDeviceName := NewStr(T.PrnDeviceName);
      P^.PrnRec^.PrnFontName := NewStr(T.PrnFontName);
      P^.PrnRec^.PrnInitString := NewStr(T.PrnInitString);
      P^.PrnRec^.PrnLeftMargin := NewStr(T.PrnLeftMargin);
      P^.PrnRec^.PrnTopMargin := NewStr(T.PrnTopMargin);
      P^.PrnRec^.PrnBottomMargin := NewStr(T.PrnBottomMargin);
      P^.PrnRec^.PrnLinesPerPage := NewStr(T.PrnLinesPerPage);
      P^.PrnRec^.PrnInterval := NewStr(T.PrnInterval);
      P^.PrnRec^.PrnCharsPerCycle := NewStr(T.PrnCharsPerCycle);
      P^.PrnRec^.PrnOptions := T.PrnOptions;
    end;
}
    GetMemUMB(P, SizeOf(TCommentRec));
    P^.Mask := NewStrUMB(Trim(T.Mask));
    P^.Comment := NewStrUMB(StUpcase(Trim(T.Comment)));
    P^.HelpName := NewStrUMB(T.HelpName);
    P^.INXLATName := NewStrUMB(T.INXLATName);
    P^.OUTXLATName := NewStrUMB(T.OUTXLATName);
    P^.MacroName := NewStrUMB(T.MacroName);
    P^.SyntaxName := NewStrUMB(T.SyntaxName);
    if T.PrnSign = 0 then P^.PrnRec := nil
    else
    begin
      GetMemUMB(P^.PrnRec, SizeOf(TPrnRec));
      P^.PrnRec^.PrnSign := T.PrnSign;
      P^.PrnRec^.PrnDeviceName := NewStrUMB(T.PrnDeviceName);
      P^.PrnRec^.PrnFontName := NewStrUMB(T.PrnFontName);
      P^.PrnRec^.PrnInitString := NewStrUMB(T.PrnInitString);
      P^.PrnRec^.PrnLeftMargin := NewStrUMB(T.PrnLeftMargin);
      P^.PrnRec^.PrnTopMargin := NewStrUMB(T.PrnTopMargin);
      P^.PrnRec^.PrnBottomMargin := NewStrUMB(T.PrnBottomMargin);
      P^.PrnRec^.PrnLinesPerPage := NewStrUMB(T.PrnLinesPerPage);
      P^.PrnRec^.PrnInterval := NewStrUMB(T.PrnInterval);
      P^.PrnRec^.PrnCharsPerCycle := NewStrUMB(T.PrnCharsPerCycle);
      P^.PrnRec^.PrnOptions := T.PrnOptions;
    end;
    P^.Options := T.Options;
    if T.Opt and 1 = 0 then P^.Options := P^.Options and not eoRegExpComment
    else P^.Options := P^.Options or eoRegExpComment;
    P^.TabSize := T.TabSize;
    P^.MaxLineWidth := T.MaxLineWidth;
    P^.WordDelims := T.WordDelims;
    P^.NewOptions := T.NewOptions;
    GetNewItem := P;
  end;
end;

procedure TCommentList.ModifyItem;
var
  I: Integer;
  Item, P: PCommentRec;
  S: String[15];
begin
  if (Focused = Range - 1) and (SelList^.Count = 0) then
  begin
    NewItem;
    Exit;
  end;
  S := 'Modify items';
  if SelList^.Count = 0 then Dec(S[0]);
  Item := GetNewItem(S);
  if Item <> nil then
  begin
    if SelList^.Count <> 0 then
    begin
      for I := 0 to SelList^.Count - 1 do
      begin
        P := SelList^.At(I);
        if Item^.Comment <> nil then
        begin
{
          DisposeStr(P^.Comment);
          P^.Comment := NewStr(Item^.Comment^);
}
          DisposeStrUMB(P^.Comment);
          P^.Comment := NewStrUMB(Item^.Comment^);
        end;
        if Item^.Options and eoRegExpComment <> 0 then
          P^.Options := P^.Options or eoRegExpComment
        else P^.Options := P^.Options and not eoRegExpComment;
      end;
{      FreeMem(Item, SizeOf(TCommentRec));}
      FreeMemUMB(Item, SizeOf(TCommentRec));
    end
    else
    begin
      Comments^.AtFree(Focused);
      Comments^.AtInsert(Focused, Item);
    end;
    SaveList;
  end;
end;

procedure TCommentList.NewItem;
var
  Item: PCommentRec;
begin
  Item := GetNewItem('New item');
  if Item <> nil then
  begin
    Comments^.AtInsert(Focused, Item);
    SaveList;
  end;
end;

function GetForStr(Count: Integer; P: PCommentRec): String;
var
  S: String[15];
begin
  if Count <> 0 then
  begin
    S := 'selected groups';
    if Count = 1 then Dec(S[0]);
  end
  else
  begin
    if P^.Mask = nil then S := ''
    else S := P^.Mask^;
    S := '"' + S + '"';
  end;
  GetForStr := S;
end;

procedure TCommentList.ItemOptions;
var
  B: Boolean;
  TS, MW: Byte;
  NO: Word;
  I, IHi: Integer;
  P: PCommentRec;
  EO: Longint;
  WD: TCharSet;
begin
  P := Comments^.At(Focused);
  if P = nil then
    if SelList^.Count <> 0 then P := SelList^.At(0)
    else Exit;
  if GetShiftState and kbCtrlShift <> 0 then
  begin
    IHi := SelList^.Count;
    if IHi <> 0 then Dec(IHi);
    for I := 0 to IHi do
    begin
      if SelList^.Count <> 0 then P := SelList^.At(I);
      P^.Options := EditOptions;
      P^.TabSize := TabSize;
      P^.MaxLineWidth := MaxLineWidth;
      P^.WordDelims := WordDelims;
      P^.NewOptions := NewEditOptions;
    end;
    SaveList;
    Exit;
  end;

  EO := P^.Options;
  NO := P^.NewOptions;
  TS := P^.TabSize;
  MW := P^.MaxLineWidth;
  WD := P^.WordDelims;
  if EditorOptions('for ' + GetForStr(SelList^.Count, P),
    EO, NO, TS, MW, @WD, False, False) then
  begin
    IHi := SelList^.Count;
    if IHi <> 0 then Dec(IHi);
    for I := 0 to IHi do
    begin
      if SelList^.Count <> 0 then P := SelList^.At(I);
      B := P^.Options and eoRegExpComment <> 0;
      P^.Options := EO;
      if B then P^.Options := P^.Options or eoRegExpComment;
      P^.NewOptions := NO;
      P^.TabSize := TS;
      P^.MaxLineWidth := MW;
      if WD <> [] then P^.WordDelims := WD;
    end;
    SaveList;
  end;
end;

procedure EditMacroProc(V: PView; var Event: TEvent);

function IsMacroInput(P: PView): Boolean; far;
begin
  IsMacroInput := (TypeOf(P^) = TypeOf(TFInputLine)) and
    (P^.Origin.Y = 10);
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

procedure TCommentList.ItemFiles;
type
  TNameData = record
    HelpName: FNameStr;
    INXLATName: FNameStr;
    OUTXLATName: FNameStr;
    SyntaxName: FNameStr;
    MacroName: FNameStr;
  end;
var
  I, IHi: Integer;
  P: PCommentRec;
  D: PDialog;
  Control: PView;
  R: TRect;
  Data: TNameData;
begin
  P := Comments^.At(Focused);
  if P = nil then
    if SelList^.Count <> 0 then P := SelList^.At(0)
    else Exit;
  R.Assign(0, 0, 59, 15);
  D := New(PDialog, Init(R, 'Auxiliary file names for ' +
    GetForStr(SelList^.Count, P)));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcEditGroupNames;
    R.Assign(17, 2, Size.X - 6, 3);
    Control := New(PFInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, HelpNameHistoryID);
    R.Assign(2, 2, 17, 3);
    Insert(New(PLabel, Init(R, '~H~elp file', Control)));
    R.Assign(17, 4, Size.X - 6, 5);
    Control := New(PFInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, XLATNameHistoryID);
    R.Assign(2, 4, 17, 5);
    Insert(New(PLabel, Init(R, '~I~n XLAT file', Control)));
    R.Assign(17, 6, Size.X - 6, 7);
    Control := New(PFInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, XLATNameHistoryID);
    R.Assign(2, 6, 17, 7);
    Insert(New(PLabel, Init(R, '~O~ut XLAT file', Control)));
    R.Assign(17, 8, Size.X - 6, 9);
    Control := New(PFInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, SyntaxHistoryID);
    R.Assign(2, 8, 17, 9);
    Insert(New(PLabel, Init(R, '~S~yntax file', Control)));
    R.Assign(17, 10, Size.X - 17, 11);
    Control := New(PFInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, MacroNameHistoryID);
    R.Assign(2, 10, 17, 11);
    Insert(New(PLabel, Init(R, '~M~acro file', Control)));

    R.Assign(Size.X - 14, 10, Size.X - 3, 12);
    Insert(New(PButton, Init(R, 'Open~.~..', cmUserMacros, bfNormal)));

    StandardButtonRow(D, True);
  end;
  if P^.HelpName = nil then Data.HelpName := ''
  else Data.HelpName := P^.HelpName^;
  if P^.INXLATName = nil then Data.INXLATName := ''
  else Data.INXLATName := P^.INXLATName^;
  if P^.OUTXLATName = nil then Data.OUTXLATName := ''
  else Data.OUTXLATName := P^.OUTXLATName^;
  if P^.MacroName = nil then Data.MacroName := ''
  else Data.MacroName := P^.MacroName^;
  if P^.SyntaxName = nil then Data.SyntaxName := ''
  else Data.SyntaxName := P^.SyntaxName^;
  D^.PostProcessEvent := EditMacroProc;
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    IHi := SelList^.Count;
    if IHi <> 0 then Dec(IHi);
    for I := 0 to IHi do
    begin
      if SelList^.Count <> 0 then P := SelList^.At(I);
{
      if Data.HelpName <> '' then
      begin
        DisposeStr(P^.HelpName);
        P^.HelpName := NewStr(StUpcase(Trim(Data.HelpName)));
      end;
      if Data.INXLATName <> '' then
      begin
        DisposeStr(P^.INXLATName);
        P^.INXLATName := NewStr(StUpcase(Trim(Data.INXLATName)));
      end;
      if Data.OUTXLATName <> '' then
      begin
        DisposeStr(P^.OUTXLATName);
        P^.OUTXLATName := NewStr(StUpcase(Trim(Data.OUTXLATName)));
      end;
      if Data.MacroName <> '' then
      begin
        DisposeStr(P^.MacroName);
        P^.MacroName := NewStr(StUpcase(Trim(Data.MacroName)));
      end;
      if Data.SyntaxName <> '' then
      begin
	DisposeStr(P^.SyntaxName);
	P^.SyntaxName := NewStr(StUpcase(Trim(Data.SyntaxName)));
      end;
}
      if (SelList^.Count = 0) or (Data.HelpName <> '') then
      begin
        DisposeStrUMB(P^.HelpName);
        P^.HelpName := NewStrUMB(StUpcase(Trim(Data.HelpName)));
      end;
      if (SelList^.Count = 0) or (Data.INXLATName <> '') then
      begin
        DisposeStrUMB(P^.INXLATName);
        P^.INXLATName := NewStrUMB(StUpcase(Trim(Data.INXLATName)));
      end;
      if (SelList^.Count = 0) or (Data.OUTXLATName <> '') then
      begin
        DisposeStrUMB(P^.OUTXLATName);
        P^.OUTXLATName := NewStrUMB(StUpcase(Trim(Data.OUTXLATName)));
      end;
      if (SelList^.Count = 0) or (Data.MacroName <> '') then
      begin
        DisposeStrUMB(P^.MacroName);
        P^.MacroName := NewStrUMB(StUpcase(Trim(Data.MacroName)));
      end;
      if (SelList^.Count = 0) or (Data.SyntaxName <> '') then
      begin
	DisposeStrUMB(P^.SyntaxName);
	P^.SyntaxName := NewStrUMB(StUpcase(Trim(Data.SyntaxName)));
      end;
    end;
    SaveList;
  end;
end;

procedure TCommentList.ItemPrinter;
type
  TDialogData = record
    PrnDeviceName: String[NameLen];
    PrnFontName: String[NameLen];
    PrnOptions: Word;
    PrnInitString: String[PrnInitLen];
    PrnLeftMargin: String[PrnMarginLen];
    PrnTopMargin: String[PrnMarginLen];
    PrnBottomMargin: String[PrnMarginLen];
    PrnLinesPerPage: String[PrnLinesLen];
    PrnInterval: String[PrnIntervalLen];
    PrnCharsPerCycle: String[PrnCycleLen];
  end;
var
  I, IHi: Integer;
  P: PCommentRec;
  D: PDialog;
  Data: TDialogData;
  TS: TTitleStr;
begin
  P := Comments^.At(Focused);
  if P = nil then
    if SelList^.Count <> 0 then P := SelList^.At(0)
    else Exit;
  if GetShiftState and kbCtrlShift <> 0 then
  begin
    IHi := SelList^.Count;
    if IHi <> 0 then Dec(IHi);
    for I := 0 to IHi do
    begin
      if SelList^.Count <> 0 then P := SelList^.At(I);
      DisposePrnRec(P^.PrnRec);
      P^.PrnRec := nil;
    end;
    SaveList;
    Exit;
  end;
  D := PDialog(Resource^.Get('PRINTERDIALOG'));
  if D = nil then
  begin
    ResNotFound(PrinterSetupTitle);
    Exit;
  end;
  TS := D^.Title^;
  DisposeStr(D^.Title);
  D^.Title := NewStr(TS + ' for ' + GetForStr(SelList^.Count, P));
  if P^.PrnRec = nil then FillChar(Data, SizeOf(TDialogData), 0)
  else
  begin
    SetStrField(P^.PrnRec^.PrnDeviceName, Data.PrnDeviceName);
    SetStrField(P^.PrnRec^.PrnFontName, Data.PrnFontName);
    SetStrField(P^.PrnRec^.PrnInitString, Data.PrnInitString);
    SetStrField(P^.PrnRec^.PrnLeftMargin, Data.PrnLeftMargin);
    SetStrField(P^.PrnRec^.PrnTopMargin, Data.PrnTopMargin);
    SetStrField(P^.PrnRec^.PrnBottomMargin, Data.PrnBottomMargin);
    SetStrField(P^.PrnRec^.PrnLinesPerPage, Data.PrnLinesPerPage);
    SetStrField(P^.PrnRec^.PrnInterval, Data.PrnInterval);
    SetStrField(P^.PrnRec^.PrnCharsPerCycle, Data.PrnCharsPerCycle);
    Data.PrnOptions := P^.PrnRec^.PrnOptions;
  end;
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    IHi := SelList^.Count;
    if IHi <> 0 then Dec(IHi);
    for I := 0 to IHi do
    begin
      if SelList^.Count <> 0 then P := SelList^.At(I);
      DisposePrnRec(P^.PrnRec);
{
      GetMem(P^.PrnRec, SizeOf(TPrnRec));
      P^.PrnRec^.PrnSign := 1;
      P^.PrnRec^.PrnDeviceName := NewStr(Data.PrnDeviceName);
      P^.PrnRec^.PrnFontName := NewStr(Data.PrnFontName);
      P^.PrnRec^.PrnInitString := NewStr(Data.PrnInitString);
      P^.PrnRec^.PrnLeftMargin := NewStr(Data.PrnLeftMargin);
      P^.PrnRec^.PrnTopMargin := NewStr(Data.PrnTopMargin);
      P^.PrnRec^.PrnBottomMargin := NewStr(Data.PrnBottomMargin);
      P^.PrnRec^.PrnLinesPerPage := NewStr(Data.PrnLinesPerPage);
      P^.PrnRec^.PrnInterval := NewStr(Data.PrnInterval);
      P^.PrnRec^.PrnCharsPerCycle := NewStr(Data.PrnCharsPerCycle);
}
      GetMemUMB(P^.PrnRec, SizeOf(TPrnRec));
      P^.PrnRec^.PrnSign := 1;
      P^.PrnRec^.PrnDeviceName := NewStrUMB(Data.PrnDeviceName);
      P^.PrnRec^.PrnFontName := NewStrUMB(Data.PrnFontName);
      P^.PrnRec^.PrnInitString := NewStrUMB(Data.PrnInitString);
      P^.PrnRec^.PrnLeftMargin := NewStrUMB(Data.PrnLeftMargin);
      P^.PrnRec^.PrnTopMargin := NewStrUMB(Data.PrnTopMargin);
      P^.PrnRec^.PrnBottomMargin := NewStrUMB(Data.PrnBottomMargin);
      P^.PrnRec^.PrnLinesPerPage := NewStrUMB(Data.PrnLinesPerPage);
      P^.PrnRec^.PrnInterval := NewStrUMB(Data.PrnInterval);
      P^.PrnRec^.PrnCharsPerCycle := NewStrUMB(Data.PrnCharsPerCycle);
      P^.PrnRec^.PrnOptions := Data.PrnOptions;
    end;
    SaveList;
  end;
end;

procedure TCommentList.DeleteItem;
var
  I, N: Integer;
begin
  if SelList^.Count <> 0 then
  begin
    if DeleteItemsMsgBox(SelList^.Count) <> cmOk then Exit;
    for I := 0 to SelList^.Count - 1 do
    begin
      N := Comments^.IndexOf(SelList^.At(I));
      if N <> -1 then Comments^.AtFree(N);
    end;
    SaveList;
    Unselect;
  end
  else with Comments^ do
    if (Focused < Count - 1) and (DeleteItemMsgBox = cmOk) then
  begin
    AtFree(Focused);
    SaveList;
  end;
end;

procedure TCommentList.FocusMask;
var
  I: Integer;
  PS: PString;
  P: PCommentRec;
  N: String;
begin
  PS := Message(Desktop, evBroadcast, cmGetSource, nil);
  if PS = nil then Exit;
  N := JustFileName(PS^);
  if N <> '' then for I := 0 to Comments^.Count - 2 do
  begin
    P := Comments^.At(I);
    if (P^.Mask <> nil) and WildCardMatch(N, P^.Mask^) then
    begin
      FocusItem(I);
      Exit;
    end;
  end;
end;

procedure TCommentList.NewItemPos;
var
  SaveFocused, LastFocused: Integer;
  SaveCtx: Word;
  P: Pointer;
  Event: TEvent;
begin
  with Comments^ do
  begin
    if Focused >= Count - 1 then Exit;
    P := At(Focused);
    SaveFocused := Focused;
    SaveCtx := Owner^.HelpCtx;
    Owner^.HelpCtx := hcNewItemPos;
    repeat
      GetEvent(Event);
      HandleEvent(Event);
      LastFocused := IndexOf(P);
      if (Focused < Count - 1) and
         (LastFocused <> -1) and (LastFocused <> Focused) then
      begin
        AtDelete(LastFocused);
        AtInsert(Focused, P);
        FocusItem(Focused);
        DrawView;
      end;
      if ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) or
         ((Event.What = evCommand) and (Event.Command = cmOk)) then
      begin
        SaveList;
        Break;
      end
      else if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
      begin
        AtDelete(LastFocused);
        AtInsert(SaveFocused, P);
        FocusItem(SaveFocused);
        DrawView;
        Break;
      end;
    until False;
    Owner^.HelpCtx := SaveCtx;
  end;
  Select;
end;

constructor TCommentDialog.Init;
var
  R: TRect;
  Control: PView;
begin
  R.Assign(0, 0, 50, ScreenHeight - 3);
  TDialog.Init(R, 'Editor group list');
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcCommentDlg;

  R.Assign(Size.X - 16, 3, Size.X - 15, Size.Y - 2);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3, 3, Size.X - 16, Size.Y - 2);
  CommentList := New(PCommentList, Init(R, 1, PScrollBar(Control)));
  CommentList^.GrowMode := gfGrowHiY;
  CommentList^.SetRange(Comments^.Count);
  Insert(CommentList);
  CommentList^.FocusMask;
  R.Assign(2, 2, Size.X - 15, 3);
  Insert(New(PLabel, Init(R,
    ' ~F~ile names           Comments', CommentList)));

  R.Assign(Size.X - 14, 3, Size.X - 3, 5);
  Insert(New(PButton, Init(R, '~M~odify', cmModifyItem, bfDefault)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~N~ew', cmNewItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~O~ptions', cmRunItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'F~i~les', cmShow, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~P~rinter', cmHide, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'Ad~j~ust', cmNewItemPos, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardCancelButton(R, @Self);
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardHelpButton(R, @Self);
  SelectNext(False);
  EnableCommands(NewCommands);
  if Comments^.Count > 1 then
    EnableCommands(ModifyCommands + RunItemCommands + ShowCommands +
      HideCommands + DeleteCommands + NewItemPosCommands)
  else DisableCommands(ModifyCommands + RunItemCommands + ShowCommands +
    HideCommands + DeleteCommands + NewItemPosCommands);
end;

procedure TCommentDialog.HandleEvent(var Event: TEvent);
begin
  TDialog.HandleEvent(Event);
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbDel:
        begin
          Event.What := evCommand;
          Event.Command := cmDeleteItem;
        end;
      kbShiftIns:
        begin
          Event.What := evCommand;
          Event.Command := cmNewItem;
        end;
    end;
  if Event.What = evCommand then with CommentList^ do
  begin
    case Event.Command of
      cmModifyItem: ModifyItem;
      cmNewItem: NewItem;
      cmRunItem: ItemOptions;
      cmShow: ItemFiles;
      cmHide: ItemPrinter;
      cmDeleteItem: DeleteItem;
      cmNewItemPos: NewItemPos;
      else Exit;
    end;
    SetRange(Comments^.Count);
    FocusItem(Focused);
    DrawView;
    Select;
    if Comments^.Count > 1 then
      EnableCommands(ModifyCommands + RunItemCommands + ShowCommands +
        HideCommands + DeleteCommands + NewItemPosCommands)
    else DisableCommands(ModifyCommands + RunItemCommands + ShowCommands +
      HideCommands + DeleteCommands + NewItemPosCommands);
    Event.What := evNothing;
  end;
end;

procedure CommentDialog;
begin
  Application^.ExecuteDialog(New(PCommentDialog, Init), nil, False);
end;

end.