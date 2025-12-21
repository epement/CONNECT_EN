{$F+,O+,X+}
unit DBFields;

interface

uses Objects, Drivers, Views, Dialogs, DataBase, EditFile;

type
  PFieldInfoViewer = ^TFieldInfoViewer;
  TFieldInfoViewer = object(TListViewer)
    Fields: PFieldList;
    TitleLen: Integer;
    constructor Init(var Bounds: TRect; AVScrollBar: PScrollBar;
      AFields: PFieldList);
    function DataSize: Word; virtual;
    procedure FocusItem(Item: Integer); virtual;
    procedure GetData(var Rec); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure SetData(var Rec); virtual;
  end;

  PDBCreateDialog = ^TDBCreateDialog;
  TDBCreateDialog = object(TDialog)
    Name: PString;
    Fields: PFieldList;
    Viewer: PFieldInfoViewer;
    OutXLATTable: ConvertTable;
    UseXLATTable: Boolean;
    constructor Init(const AName: FNameStr; AFields: PFieldList;
      XLATTable: ConvertTable; UseXLAT: Boolean);
    destructor Done; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure EndModal(Command: Word); virtual;
    function GetNewItem(Modify: Boolean): PFieldRec;
    procedure NewItemPos;
    procedure StoreFields;
    procedure UpdateCommands;
  end;

const
  FieldInfoLabelStr =
    '~Name~         ~Type~            ~Length~  ~Decimals~';

function NewDBDlg(const AName: FNameStr;
  AFields: PFieldList; ACurField: Byte;
  XLATTable: ConvertTable; UseXLAT: Boolean): Word;
function ImportFromTxt(const AName: FNameStr; DB: PDataBase;
  SelList: PCollection; InsIndex: Longint): Boolean;
function ExportToTxt(const AName: FNameStr; DB: PDataBase;
  SelList: PCollection): Boolean;
procedure ImpExpOptDlg;
procedure FieldSeparatorDlg;
function SortDatabase(DB: PDataBase; AField: Byte): Boolean;

implementation

uses Dos, Memory, App, MsgBox, Swaps, ClipPrim, EditMsg, HistList, History,
  DirPrim, CNInputs, DosTools, HeapUMB, MSortP, Keyboard, TPString, LFN,
  Consts, Commands, Defaults;

constructor TFieldInfoViewer.Init(var Bounds: TRect; AVScrollBar: PScrollBar;
  AFields: PFieldList);
begin
  Inherited Init(Bounds, 1, nil, AVScrollBar);
  GrowMode := gfGrowHiY;
  Fields := AFields;
  SetRange(Fields^.Count);
end;

function TFieldInfoViewer.DataSize: Word;
begin
  DataSize := SizeOf(Byte);
end;

procedure TFieldInfoViewer.FocusItem(Item: Integer);
var
  Params: Array[0..1] of Longint;
  S, C: String;
begin
  Inherited FocusItem(Item);
  if Owner <> nil then
  begin
    Params[0] := Focused + Byte(Range <> 0);
    Params[1] := Range;
    FormatStr(S, '(%d/%d)', Params);
    with PWindow(Owner)^ do
    begin
      if TitleLen = 0 then TitleLen := Length(Title^);
      C := System.Copy(Title^, 1, TitleLen);
      DisposeStr(Title);
      Title := NewStr(C + ' ' + S);
      Frame^.DrawView;
    end;
  end;
end;

procedure TFieldInfoViewer.GetData(var Rec);
begin
  Byte(Rec) := Byte(Focused);
end;

function TFieldInfoViewer.GetText(Item: Integer; MaxLen: Integer): String;
var
  W: Word;
  P: PFieldRec;
  C: String[15];
  S: String;
begin
  P := Fields^.At(Item);
  if P = nil then GetText := ''
  else
  begin
    FillChar(S[1], Size.X, ' ');
    S[0] := Char(Size.X);
    Move(P^.Name[1], S[1], SizeOf(P^.Name));
    if Size.X > 12 then
    begin
      case TPString.Upcase(P^.Iden) of
        'C': C := 'Character';
        'D': C := 'Date';
        'F': C := 'Floating point';
        'L': C := 'Logical';
        'M': C := 'Memo';
        'N': C := 'Numeric';
        'P': C := 'Pattern';
        else C := 'Unknown type';
      end;
      Move(C[1], S[14], Length(C));
      if (TPString.Upcase(P^.Iden) = 'C') and (P^.Dec <> 0) then
	Move(P^.Len, W, SizeOf(Word))
      else if (TPString.Upcase(P^.Iden) = 'D') and (P^.Len = 10) then
	W := 8
      else W := P^.Len;
      Str(W, C);
      Move(C[1], S[36 - Length(C)], Length(C));
      if (TPString.Upcase(P^.Iden) in ['F', 'N']) and (P^.Dec <> 0) then
      begin
        Str(P^.Dec, C);
        Move(C[1], S[Size.X - Length(C) - 1], Length(C));
      end;
    end;
    GetText := S;
  end;
end;

procedure TFieldInfoViewer.SetData(var Rec);
begin
  FocusItem(Byte(Rec));
  DrawView;
end;

constructor TDBCreateDialog.Init(const AName: FNameStr; AFields: PFieldList;
  XLATTable: ConvertTable; UseXLAT: Boolean);
var
  B: Byte;
  FP: PFieldRec;
  VBar, HBar: PScrollBar;
  R: TRect;
begin
  R.Assign(0, 0, 65, ScreenHeight - 4);
  Inherited Init(R, 'New database: ' + TrimmedName(AName, 32));
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcDBCreate;

{  Name := NewStr(AName);}
  Name := NewStrUMB(AName);
  Fields := New(PFieldList, Init(8, 8));
  if AFields <> nil then for B := 0 to AFields^.Count - 1 do
  begin
{    GetMem(FP, SizeOf(TFieldRec));}
    GetMemUMB(FP, SizeOf(TFieldRec));
    FP^ := PFieldRec(AFields^.At(B))^;
    Fields^.Insert(FP);
  end;

  UseXLATTable := UseXLAT;
  if UseXLAT then OutXLATTable := XLATTable;

  R.Assign(Size.X - 15, 3, Size.X - 14, Size.Y - 2);
  VBar := New(PScrollBar, Init(R));
  Insert(VBar);

  R.Assign(3, 3, Size.X - 15, Size.Y - 2);
  Viewer := New(PFieldInfoViewer, Init(R, VBar, Fields));
  Insert(Viewer);
  R.Assign(3, 2, Size.X - 3, 3);
  Insert(New(PLabel, Init(R, FieldInfoLabelStr, Viewer)));

  R.Assign(Size.X - 13, 3, Size.X - 3, 5);
  Insert(New(PButton, Init(R, '~N~ew', cmNewItem, bfDefault)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~I~nsert', cmRunItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~E~dit', cmModifyItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'Ad~j~ust', cmNewItemPos, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'D~o~ne', cmOk, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardCancelButton(R, @Self);
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardHelpButton(R, @Self);

  Viewer^.Select;
  UpdateCommands;
end;

destructor TDBCreateDialog.Done;
begin
  Dispose(Fields, Done);
{  DisposeStr(Name);}
  DisposeStrUMB(Name);
  Inherited Done;
end;

procedure TDBCreateDialog.HandleEvent(var Event: TEvent);
var
  P: PFieldRec;
begin
  Inherited HandleEvent(Event);
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbDel:
	begin
	  Event.What := evCommand;
	  Event.Command := cmDeleteItem;
	end;
      kbIns:
	begin
	  Event.What := evCommand;
	  Event.Command := cmRunItem;
	end;
      kbCtrlUp: if Viewer^.State and sfSelected <> 0 then
	MoveListItem(Viewer, Fields, True);
      kbCtrlDn: if Viewer^.State and sfSelected <> 0 then
	MoveListItem(Viewer, Fields, False);
    end
  else if (Event.What = evBroadcast) and
    (Event.Command = cmListItemSelected) then
  begin
    Event.What := evCommand;
    Event.Command := cmModifyItem;
  end;
  if (Event.What = evCommand) and CommandEnabled(Event.Command) then
  begin
    case Event.Command of
      cmNewItem, cmModifyItem, cmRunItem:
	P := GetNewItem(Event.Command = cmModifyItem);
      else P := @Self;
    end;
    with Viewer^ do
    begin
      if P <> nil then
      begin
	case Event.Command of
	  cmModifyItem, cmDeleteItem: Fields^.AtFree(Focused);
	end;
	case Event.Command of
	  cmNewItem: Fields^.Insert(P);
	  cmModifyItem, cmRunItem: Fields^.AtInsert(Focused, P);
	  cmDeleteItem: ;
	  cmNewItemPos: NewItemPos;
	  else Exit;
	end;
      end;
      SetRange(Fields^.Count);
      Select;
      FocusItem(Focused);
      DrawView;
    end;
    UpdateCommands;
    Event.What := evNothing;
  end;
end;

procedure TDBCreateDialog.EndModal(Command: Word);
begin
  if Command = cmOk then
    if Fields^.Count = 0 then Command := cmCancel
    else StoreFields;
  Inherited EndModal(Command);
end;

function TDBCreateDialog.GetNewItem(Modify: Boolean): PFieldRec;
type
  DialogData = record
    Name: String[10];
    Len: String[3];
    Dec: String[3];
    Iden: Word;
  end;
var
  Code: Integer;
  D: PDialog;
  Control: PView;
  P: PFieldRec;
  R: TRect;
  Header: String[15];
  AData: DialogData;
begin
  GetNewItem := nil;
  if Modify then Header := 'Modify' else Header := 'New';
  Header := Header + ' field';
  R.Assign(0, 0, 52, 14);
  D := New(PDialog, Init(R, Header));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcNewField;

    R.Assign(12, 3, 24, 4);
    Control := New(PInputLine, Init(R, 10));
    Insert(Control);
    R.Assign(2, 3, 12, 4);
    Insert(New(PLabel, Init(R, 'N~a~me', Control)));
    StandardHistory(Control, FieldNameHistoryId);

    R.Assign(12, 6, 17, 7);
    Control := New(PCInputLine, Init(R, 3, 1, 255));
    Insert(Control);
    R.Assign(2, 6, 12, 7);
    Insert(New(PLabel, Init(R, 'Len~g~th', Control)));

    R.Assign(12, 9, 17, 10);
    Control := New(PCInputLine, Init(R, 3, 0, 255));
    Insert(Control);
    R.Assign(2, 9, 12, 10);
    Insert(New(PLabel, Init(R, 'D~e~cimals', Control)));

    R.Assign(29, 3, 49, 10);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~C~haracter',
      NewSItem('~D~ate',
      NewSItem('~F~loating point',
      NewSItem('~L~ogical',
      NewSItem('~M~emo',
      NewSItem('~N~umeric',
      NewSItem('~P~attern', nil)))))))));
    Insert(Control);
    R.Assign(28, 2, 49, 3);
    Insert(New(PLabel, Init(R, 'Field type', Control)));

    R.Assign(3, 11, 13, 13);
    StandardOkButton(R, D);
    R.Assign(20, 11, 30, 13);
    StandardCancelButton(R, D);
    R.Assign(37, 11, 47, 13);
    StandardHelpButton(R, D);
    SelectNext(False);
  end;
  P := Fields^.At(Viewer^.Focused);
  if P <> nil then
  begin
    AData.Name := Trim(P^.Name);
    Str(P^.Len, AData.Len);
    if P^.Dec = 0 then AData.Dec := ''
    else Str(P^.Dec, AData.Dec);
    case TPString.Upcase(P^.Iden) of
      'D': AData.Iden := 1;
      'F': AData.Iden := 2;
      'L': AData.Iden := 3;
      'M': AData.Iden := 4;
      'N': AData.Iden := 5;
      'P': AData.Iden := 6;
      else AData.Iden := 0;
    end;
  end
  else FillChar(AData, SizeOf(DialogData), 0);
  if Application^.ExecuteDialog(D, @AData, False) <> cmCancel then
  begin
{    GetMem(P, SizeOf(TFieldRec));}
    GetMemUMB(P, SizeOf(TFieldRec));
    FillChar(P^, SizeOf(TFieldRec), 0);
    Move(AData.Name[1], P^.Name, Length(AData.Name));
    Val(AData.Len, P^.Len, Code);
    Val(AData.Dec, P^.Dec, Code);
    case AData.Iden of
      1: P^.Iden := 'D';
      2: P^.Iden := 'F';
      3: P^.Iden := 'L';
      4: P^.Iden := 'M';
      5: P^.Iden := 'N';
      6: P^.Iden := 'P';
    else P^.Iden := 'C';
    end;
    GetNewItem := P;
  end;
end;

procedure TDBCreateDialog.NewItemPos;
var
  SaveFocused, LastFocused: Integer;
  SaveCtx: Word;
  P: Pointer;
  Event: TEvent;
begin
  with Viewer^ do
  begin
    P := Fields^.At(Focused);
    SaveFocused := Focused;
    SaveCtx := Owner^.HelpCtx;
    Owner^.HelpCtx := hcNewItemPos;
    repeat
      GetEvent(Event);
      HandleEvent(Event);
      LastFocused := Fields^.IndexOf(P);
      if (LastFocused <> -1) and (LastFocused <> Focused) then
      begin
        Fields^.AtDelete(LastFocused);
        Fields^.AtInsert(Focused, P);
        FocusItem(Focused);
        DrawView;
      end;
      if ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) or
         ((Event.What = evCommand) and (Event.Command = cmOk)) then Break;
      if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
      begin
        Fields^.AtDelete(LastFocused);
        Fields^.AtInsert(SaveFocused, P);
        FocusItem(SaveFocused);
        DrawView;
        Break;
      end;
    until False;
    Owner^.HelpCtx := SaveCtx;
  end;
end;

procedure TDBCreateDialog.StoreFields;
var
  B: Byte;
  Y, M, D, W: Word;
  P: PFieldRec;
  Stream: TDosStream;
  Header: TDBFHeader;
begin
  LogEvent := lcDiskWrite;
  DrawStatusLine('Creating new database ' + TrimmedName(Name^, 45) + '.');
  Stream.Init(Name^, stCreate);
  FillChar(Header, SizeOf(TDBFHeader), 0);
  Header.Iden := 3;
  GetDate(Y, M, D, W);
  if Y >= 2000 then Dec(Y, 2000) else Dec(Y, 1900);
  with Header do
  begin
    Year := Y;
    Month := M;
    Day := D;
  end;
  Header.HeaderLen := SizeOf(TDBFHeader) +
    SizeOf(TFieldRec) * Fields^.Count + 1;
  Header.RecordLen := 1;
  for W := 0 to Fields^.Count - 1 do
  begin
    P := Fields^.At(W);
    if (Upcase(P^.Iden) = 'C') and (P^.Dec <> 0) then
      Move(P^.Len, D, SizeOf(Word))
    else D := P^.Len;
    Inc(Header.RecordLen, D);
  end;
  Stream.Write(Header, SizeOf(TDBFHeader));
  for W := 0 to Fields^.Count - 1 do
  begin
    P := Fields^.At(W);
    if UseXLATTable then for B := 1 to SizeOf(P^.Name) do
      P^.Name[B] := OutXLATTable[P^.Name[B]];
    Stream.Write(P^, SizeOf(TFieldRec));
  end;
  W := $1A0D;
  Stream.Write(W, SizeOf(Word));
  Stream.Done;
  UpdateFiles(Name^);
end;

procedure TDBCreateDialog.UpdateCommands;
begin
  EnableCommands(NewCommands + RunItemCommands);
  if Fields^.Count <> 0 then EnableCommands(ModifyCommands + DeleteCommands)
  else DisableCommands(ModifyCommands + DeleteCommands);
  if Fields^.Count > 1 then EnableCommands(NewItemPosCommands)
  else DisableCommands(NewItemPosCommands);
end;

function NewDBDlg(const AName: FNameStr;
  AFields: PFieldList; ACurField: Byte;
  XLATTable: ConvertTable; UseXLAT: Boolean): Word;
begin
  NewDBDlg := Application^.ExecuteDialog(
    New(PDBCreateDialog, Init(AName, AFields,
    XLATTable, UseXLAT)), @ACurField, False);
end;

function ImportFromTxt(const AName: FNameStr; DB: PDataBase;
  SelList: PCollection; InsIndex: Longint): Boolean;
var
  All, SingleSep: Boolean;
  Field, FL: Byte;
  RecSize, Ofs, Len: Word;
  I, ClipIndex, Code: Integer;
  L, Count: Longint;
  FP: PFieldRec;
  P: PByteArray;
  CS: String[15];
  F: lText;
  S, SS: String;

procedure GetNextLine;
begin
  if not SingleSep then while S = '' do
  begin
    if AName <> '' then
    begin
      if Eof(F.T) then
      begin
        All := True;
        Break;
      end;
      Readln(F.T, S);
    end
    else
    begin
      if ClipIndex > ClipArea^.KK then
      begin
        All := True;
        Break;
      end;
      GetClipLine(ClipIndex, S);
      Inc(ClipIndex);
    end;
    S := Detab(S, 8);
    TrimSt(S);
    if (S = '') and (RecSize >= 255) then Break;
  end;
  SingleSep := False;
end;

procedure FillRecord;
var
  C: Byte;
label
  Next;
begin
  FillChar(P^, RecSize, ' ');
  Ofs := 1;
  for C := 0 to DB^.Fields^.Count - 1 do
  begin
Next:
    GetNextLine;
    if All then Break;
    if S[1] = '*' then
    begin
      P^[0] := 42;
      Delete(S, 1, 1);
      if S = '' then Goto Next;
    end;
    FP := DB^.Fields^.At(C);
    if (TPString.Upcase(FP^.Iden) = 'D') and (FP^.Len = 10) then Len := 8
    else Len := DB^.GetFieldLen(FP);
    I := Pos(FieldSeparator, S);
    if I = 0 then
    begin
      SS := S;
      S := '';
    end
    else
    begin
      Dec(I);
      SS := Copy(S, 1, I);
      Delete(S, 1, I);
      TrimSt(S);
      if S = FieldSeparator then SingleSep := True;
      Delete(S, 1, 1);
    end;
    TrimSt(SS);
    if Length(SS) > Len then SS[0] := Char(Len)
    else if not (TPString.Upcase(FP^.Iden) in ['C', 'P']) and
      (DBImpExpOptions and imJustifyNum <> 0) then
	SS := LeftPad(SS, Len);
    Move(SS[1], P^[Ofs], Length(SS));
    Inc(Ofs, Len);
  end;
end;

begin
  ImportFromTxt := False;
  if AName <> '' then
  begin
    lAssignText(F, AName);
    Reset(F.T);
    if IOResult <> 0 then
    begin
      CouldNotOpenMsgBox(AName);
      Exit;
    end;
    if IsDevice(TextRec(F.T).Handle) then
    begin
      Close(F.T);
      InOutRes := 0;
      FileIsDeviceMsgBox(AName);
      Exit;
    end;
  end
  else
  begin
    if (DiskClipStream = nil) or not ClipAreaSelected then Exit;
    Message(Desktop, evBroadcast, cmUpdateViews, nil);
    ClipIndex := ClipArea^.KB;
  end;
  RecSize := DB^.Header^.RecordLen;
  P := MemAlloc(RecSize);
  if P = nil then
  begin
    if AName <> '' then
    begin
      Close(F.T);
      InOutRes := 0;
    end;
    Application^.OutOfMemory;
    Exit;
  end;
  if AName <> '' then SS := 'text file ' + TrimmedName(AName, 37)
  else SS := 'the Clipboard';
  LogEvent := lcDiskWrite;
  DrawStatusLine('Importing data from ' + SS + '.');
  SelList^.FreeAll;
  DB^.InitDBF(stOpen);
  DB^.TruncateToLast;
  S := '';
  Count := 0;
  if DBImpExpOptions and imInsert <> 0 then
  begin
    L := InsIndex;
    InsIndex := DB^.Header^.HeaderLen +
      InsIndex * (DB^.Header^.RecordLen - DB^.ExtraRecordLen);
  end
  else L := DB^.Header^.NumRecords;
  All := False;
  SingleSep := False;
  repeat
    FillRecord;
    if All then Break;
    if (DBImpExpOptions and dbConvertDates <> 0) and
       (DB^.Options and dbHasDates <> 0) then
      DB^.ConvertDates(dcDATEIN, P^);
    if (DBImpExpOptions and dbValidate <> 0) and
      not DB^.ValidRecord(Field, Code, False, P^) then
    begin
      if (TPString.Upcase(
	PFieldRec(DB^.Fields^.At(Field))^.Iden) = 'D') then FL := 8
      else FL := 32;
      InvalidDBFieldMsgBox(
	Trim(Copy(DB^.GetFieldStr(Field, P^), 1, FL)));
      Break;
    end;
    if DB^.Options and dbXLATOUT <> 0 then
      DB^.ConvertRecord(dcXLATOUT, P^);
    if (DBImpExpOptions and dbConvertDates <> 0) and
       (DB^.Options and dbHasDates <> 0) then
      DB^.ConvertDates(dcDATEOUT, P^);
    if DBImpExpOptions and imInsert <> 0 then
    begin
      InsertBlock(DB^.DBF, InsIndex, RecSize - DB^.ExtraRecordLen, P^);
      Inc(InsIndex, RecSize - DB^.ExtraRecordLen);
      GiveTicks;
    end
    else DB^.DBF^.Write(P^, RecSize - DB^.ExtraRecordLen);
    if DB^.DBF^.Status <> stOk then
    begin
      CouldNotWriteMsgBox(AName);
      Break;
    end;
    Inc(DB^.Header^.NumRecords);
    Inc(Count);
    if (SelList^.Count = MaxCollectionSize) or
       ((SelList^.Count = SelList^.Limit) and
        (MaxAvail <= LongMul(SelList^.Limit +
          SelList^.Delta, 4) + $2000)) then
    else SelList^.Insert(Pointer(L));
    Inc(L);
    if AName <> '' then CS := 'text file' else CS := 'the Clipboard';
    FormatStr(SS,
      'Importing data from ' + CS + '. Records added: %d', Count);
    LogEvent := 0;
    DrawStatusLine(SS);
    if (DBImpExpOptions and imInsert <> 0) and EscPressed then Break;
    if (KbdStatus = 1) and AbortAction then Break;
    if Count mod 10 = 0 then GiveTicks;
  until False;
  DB^.WriteEndingChar;
  DB^.DoneDBF;
  FreeMem(P, RecSize);
  if AName <> '' then
  begin
    Close(F.T);
    InOutRes := 0;
  end;
  ImportFromTxt := Count <> 0;
end;

function ExportToTxt(const AName: FNameStr; DB: PDataBase;
  SelList: PCollection): Boolean;
var
  Append: Boolean;
  W, RecSize, Ofs, Len: Word;
  I, SaveCount, MaxLen: Integer;
  L, Count: Longint;
  FP: PFieldRec;
  P: PByteArray;
  F: lText;
  S, SS: String;

procedure DrawExportStatus(Processed: Longint);
var
  CS: String[15];
begin
  if AName <> '' then CS := 'text file' else CS := 'the Clipboard';
  FormatStr(SS,
    'Exporting data to ' + CS + '. Records processed: %d', Processed);
  LogEvent := 0;
  DrawStatusLine(SS);
end;

function WriteToClipboard: Boolean;
begin
  PutClipLine(S);
  if not MarkColumns or (Length(S) > MaxLen) then MaxLen := Length(S);
  WriteToClipboard := not ClipOverflow;
end;

function ProcessRecord: Boolean;
var
  B, C: Byte;
begin
  if P^[0] = 42 then S := '*'
  else S := '';
  Ofs := 1;
  for C := 0 to DB^.Fields^.Count - 1 do
  begin
    SS := '';
    FP := DB^.Fields^.At(C);
    if (TPString.Upcase(FP^.Iden) = 'D') and (FP^.Len = 10) then Len := 8
    else Len := DB^.GetFieldLen(FP);
    if Len > 255 then B := 255 else B := Len;
    Move(P^[Ofs], SS[1], B);
    SS[0] := Char(B);
    if DBImpExpOptions and exTrimLead <> 0 then LeadTrim(SS);
    if DBImpExpOptions and exTrimTrail <> 0 then TrailTrim(SS);
    if Length(S) + Length(SS) > 255 then
    begin
      if S[Length(S)] = FieldSeparator then Dec(S[0]);
      if AName <> '' then
      begin
	Writeln(F.T, S);
	if IOResult <> 0 then
	begin
	  CouldNotWriteMsgBox(AName);
	  ProcessRecord := False;
	  Exit;
	end;
      end
      else if not WriteToClipboard then
      begin
	ProcessRecord := False;
	Exit;
      end;
      S := SS;
    end
    else S := S + SS;
    if (Length(S) <> 255) and (C <> DB^.Fields^.Count - 1) then
    begin
      Inc(S[0]);
      S[Length(S)] := FieldSeparator;
    end;
    Inc(Ofs, Len);
  end;
  if AName <> '' then
  begin
    Writeln(F.T, S);
    if IOResult <> 0 then
    begin
      CouldNotWriteMsgBox(AName);
      ProcessRecord := False;
    end
    else ProcessRecord := True;
  end
  else ProcessRecord := WriteToClipboard;
end;

begin
  ExportToTxt := False;
  Append := False;
  if AName <> '' then
  begin
    if ThisFileExists(AName) then
    begin
      W := AppendMessageBox(AName);
      case W of
	cmYes: Append := True;
        cmCancel: Exit;
      end;
    end;
    lAssignText(F, AName);
    if Append then
    begin
      System.Append(F.T);
      if IOResult <> 0 then Rewrite(F.T);
    end
    else Rewrite(F.T);
    if IOResult <> 0 then
    begin
      CouldNotCreateMsgBox(AName);
      Exit;
    end;
    if NotAccessible(TextRec(F.T).Handle) then
    begin
      Close(F.T);
      InOutRes := 0;
      FileIsDeviceMsgBox(AName);
      Exit;
    end;
  end
  else
  begin
    if DiskClipStream = nil then Exit;
    SetExpandClipAreaFlag;
    MaxLen := 0;
    SaveCount := ClipLines^.Count;
  end;
  RecSize := DB^.Header^.RecordLen;
  P := MemAlloc(RecSize);
  if P = nil then
  begin
    if AName <> '' then
    begin
      Close(F.T);
      InOutRes := 0;
    end;
    Application^.OutOfMemory;
    Exit;
  end;
  if AName <> '' then
  begin
    LogEvent := lcDiskWrite;
    DrawStatusLine(
      'Exporting data to text file ' + TrimmedName(AName, 39) + '.')
  end
  else DrawDBClipCopyStatus;
  DB^.InitDBF(stOpenRead);
  if SelList^.Count <> 0 then
  begin
    Count := 0;
    for I := SelList^.Count - 1 downto 0 do
    begin
      L := DB^.Header^.HeaderLen +
        Longint(SelList^.At(I)) *
        (DB^.Header^.RecordLen - DB^.ExtraRecordLen);
      DB^.DBF^.Seek(L);
      DB^.DBF^.Read(P^, RecSize - DB^.ExtraRecordLen);
      if DB^.DBF^.Status <> stOk then Break;
      if DB^.Options and dbXLATIN <> 0 then
        DB^.ConvertRecord(dcXLATIN, P^);
      if not ProcessRecord then Break;
      Inc(Count);
      DrawExportStatus(Count);
      if (KbdStatus = 1) and AbortAction then Break;
      if I mod 10 = 0 then GiveTicks;
    end;
  end
  else
  begin
    DB^.DBF^.Seek(DB^.Header^.HeaderLen);
    for Count := 0 to DB^.Header^.NumRecords - 1 do
    begin
      DB^.DBF^.Read(P^, RecSize - DB^.ExtraRecordLen);
      if DB^.DBF^.Status <> stOk then Break;
      if DB^.Options and dbXLATIN <> 0 then
        DB^.ConvertRecord(dcXLATIN, P^);
      if not ProcessRecord then Break;
      DrawExportStatus(Count + 1);
      if (KbdStatus = 1) and AbortAction then Break;
      if Count mod 10 = 0 then GiveTicks;
    end;
  end;
  DB^.DoneDBF;
  FreeMem(P, RecSize);
  if AName <> '' then
  begin
    Close(F.T);
    InOutRes := 0;
  end
  else SetOrExpandClipArea(SaveCount, MaxLen + 1);
  ExportToTxt := True;
end;

procedure ImpExpOptDlg;
type
  TData = record
    InsOpt: Word;
    FieldOpt: Word;
  end;
var
  SaveOpt: Byte;
  D: PDialog;
  Control: PView;
  R: TRect;
  Data: TData;
begin
  R.Assign(0, 0, 51, 14);
  D := New(PDialog, Init(R, 'Database Import/Export options'));
  with D^ do
  begin
    HelpCtx := hcImpExpOptions;
    Options := Options or ofCentered;

    R.Assign(3, 3, Size.X - 3, 5);
    Control := New(PRadioButtons, Init(R,
      NewSItem('A~d~d records to the end of the database',
      NewSItem('I~n~sert records at the cursor position', nil))));
    Insert(Control);
    R.Assign(2, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(R, 'Data import options', Control)));

    R.Assign(3, 7, Size.X - 3, 10);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Numer~i~c fields right-justified (Import)',
      NewSItem('Trim ~l~eading whitespaces       (Export)',
      NewSItem('Trim ~t~railing whitespaces      (Export)', nil)))));
    Insert(Control);
    R.Assign(2, 6, Size.X - 3, 7);
    Insert(New(PLabel, Init(R, 'Field options', Control)));

    StandardButtonRow(D, True);
  end;
  if DBImpExpOptions and imInsert <> 0 then Data.InsOpt := 1
  else Data.InsOpt := 0;
  Data.FieldOpt := DBImpExpOptions and 7;
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    SaveOpt := DBImpExpOptions;
    DBImpExpOptions := Data.FieldOpt;
    if SaveOpt and dbConvertDates <> 0 then
      DBImpExpOptions := DBImpExpOptions or dbConvertDates;
    if SaveOpt and dbValidate <> 0 then
      DBImpExpOptions := DBImpExpOptions or dbValidate;
    if Data.InsOpt = 1 then
      DBImpExpOptions := DBImpExpOptions or imInsert;
  end;
end;

procedure FieldSeparatorDlg;
var
  D: PDialog;
  Control: PView;
  R: TRect;
  S: String[1];
begin
  R.Assign(0, 0, 27, 7);
  D := New(PDialog, Init(R, 'Field separator'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcFieldSeparator;

    R.Assign(15, 2, 18, 3);
    Control := New(PInputLine, Init(R, 1));
    Insert(Control);
    R.Assign(4, 2, 15, 3);
    Insert(New(PLabel, Init(R, '~C~haracter', Control)));

    R.Assign(2, 4, 10, 6);
    StandardOkButton(R, D);
    R.Assign(14, 4, 24, 6);
    StandardCancelButton(R, D);

    SelectNext(False);
  end;
  S := FieldSeparator;
  if (Application^.ExecuteDialog(D, @S, False) <> cmCancel) and
     (S <> '') then FieldSeparator := S[1];
end;

const
  msAscend = 0;
  msDescend = 1;

  msCaseSensitive = 1;
  msFilterDel = 2;

var
  msDB: PDataBase;
  msRP: PByteArray;
  msFP: PFieldRec;
  msField: Byte;
  msDir: Byte;
  msOpts: Byte;
  msPos: Byte;
  msChanged, msCmpFlag: Boolean;

procedure SendToSortEngine; far;
var
  Count: Longint;
  SS: String;
begin
  msDB^.InitDBF(stOpenRead);
  msDB^.DBF^.Seek(msDB^.Header^.HeaderLen);
  for Count := 0 to msDB^.Header^.NumRecords - 1 do
  begin
    FormatStr(SS, 'Sending database records to Sort Engine: %d', Count);
    LogEvent := 0;
    DrawStatusLine(SS);
    msDB^.DBF^.Read(msRP^, msDB^.Header^.RecordLen - msDB^.ExtraRecordLen);
    if msDB^.DBF^.Status <> stOk then
    begin
      AbortSort;
      CouldNotReadMsgBox(msDB^.Name^);
      Break;
    end;
    if msDB^.Options and dbXLATIN <> 0 then
      msDB^.ConvertRecord(dcXLATIN, msRP^);
    msCmpFlag := True;
    if not PutElement(msRP^) then Break;
    if (KbdStatus = 1) and AbortAction then
    begin
      AbortSort;
      Break;
    end;
    if Count mod 10 = 0 then GiveTicks;
  end;
  msDB^.DoneDBF;
end;

procedure GetFromSortEngine; far;
var
  Count: Longint;
  SS: String;
begin
  msDB^.InitDBF(stOpen);
  msDB^.DBF^.Seek(msDB^.Header^.HeaderLen);
  msChanged := True;
  msCmpFlag := True;
  for Count := 0 to msDB^.Header^.NumRecords - 1 do
  begin
    if not GetElement(msRP^) then Break;
    FormatStr(SS, 'Getting sorted records from Sort Engine: %d', Count);
    LogEvent := 0;
    DrawStatusLine(SS);
    if msDB^.Options and dbXLATOUT <> 0 then
      msDB^.ConvertRecord(dcXLATOUT, msRP^);
    msDB^.DBF^.Write(msRP^, msDB^.Header^.RecordLen - msDB^.ExtraRecordLen);
    if msDB^.DBF^.Status <> stOk then
    begin
      AbortSort;
      CouldNotWriteMsgBox(msDB^.Name^);
      Break;
    end;
    if (KbdStatus = 1) and AbortAction then
    begin
      AbortSort;
      Break;
    end;
    if Count mod 10 = 0 then GiveTicks;
  end;
  msDB^.DoneDBF;
end;

function CompareElements(var X, Y): Boolean; far;
var
  Code: Integer;
  E1, E2: Extended;
  S1, S2: String;
begin
  if (KbdStatus = 1) and AbortAction then
  begin
    AbortSort;
    CompareElements := False;
    Exit;
  end;

  if msCmpFlag then
  begin
    LogEvent := 0;
    DrawStatusLine('Sorting database records. Esc aborts.');
    msCmpFlag := False;
  end;

  S1 := msDB^.GetFieldStr(msField, X);
  S2 := msDB^.GetFieldStr(msField, Y);

  if msOpts and msFilterDel <> 0 then
  begin
    if (Char(X) = '*') and (Char(Y) <> '*') then
    begin
      CompareElements := msDir <> msAscend;
      Exit;
    end;
    if (Char(X) <> '*') and (Char(Y) = '*') then
    begin
      CompareElements := msDir = msAscend;
      Exit;
    end;
  end;

  if msPos > 1 then
  begin
    S1 := Copy(S1, msPos, 255);
    S2 := Copy(S2, msPos, 255);
  end;

  if TPString.Upcase(msFP^.Iden) in ['F', 'N'] then
  begin
    TrimSt(S1);
    TrimSt(S2);
    Val(S1, E1, Code);
    Val(S2, E2, Code);
    if msDir = msAscend then CompareElements := E1 < E2
    else CompareElements := E1 > E2;
  end
  else
  begin
    if msOpts and msCaseSensitive = 0 then
    begin
      UpcaseSt(S1);
      UpcaseSt(S2);
    end;
    if msDir = msAscend then CompareElements := S1 < S2
    else CompareElements := S1 > S2;
  end;
end;

function GetSortOptions(DB: PDataBase; AField: Byte): Boolean;
type
  TData = record
    Field: Byte;
    Dir: Word;
    Opts: Word;
    Pos: String[3];
  end;
const
  SortData: TData = (Field: 0; Dir: 0; Opts: 0; Pos: '1');
var
  Code: Integer;
  D: PDialog;
  VBar: PScrollBar;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 41, 15);
  D := New(PDialog, Init(R, 'Sort database records'));
  with D^ do
  begin
    Options := Options or ofCentered;
    GrowMode := GrowMode + gfGrowHiY;
    HelpCtx := hcSortDatabase;

    R.Assign(15, 3, 16, Size.Y - 2);
    VBar := New(PScrollBar, Init(R));
    Insert(VBar);
    R.Assign(3, 3, 15, Size.Y - 2);
    Control := New(PFieldInfoViewer, Init(R, VBar, DB^.Fields));
    Insert(Control);
    R.Assign(3, 2, 16, 3);
    Insert(New(PLabel, Init(R, '~F~ield name', Control)));

    R.Assign(18, 3, 38, 5);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~A~scending',
      NewSItem('~D~escending', nil))));
    Insert(Control);
    R.Assign(17, 2, 38, 3);
    Insert(New(PLabel, Init(R, 'Sort direction', Control)));

    R.Assign(18, 7, 38, 9);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~C~ase sensitive',
      NewSItem('F~i~lter deleted', nil))));
    Insert(Control);
    R.Assign(17, 6, 38, 7);
    Insert(New(PLabel, Init(R, 'Sort options', Control)));

    R.Assign(33, Size.Y - 5, 38, Size.Y - 4);
    Control := New(PCInputLine, Init(R, 3, 1, 255));
    Insert(Control);
    R.Assign(17, Size.Y - 5, 33, Size.Y - 4);
    Insert(New(PLabel, Init(R, 'Field ~p~osition', Control)));

    R.Assign(17, Size.Y - 3, 27, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(28, Size.Y - 3, 38, Size.Y - 1);
    StandardCancelButton(R, D);

    SelectNext(False);
  end;
  SortData.Field := AField;
  if Application^.ExecuteDialog(D, @SortData, False) = cmOk then
  begin
    msField := SortData.Field;
    msDir := SortData.Dir;
    msOpts := SortData.Opts;
    Val(SortData.Pos, msPos, Code);
    GetSortOptions := True;
  end
  else GetSortOptions := False;
end;

function SortDatabase(DB: PDataBase; AField: Byte): Boolean;
var
  RecSize: Word;
  MemSize, Result: Longint;
begin
  SortDatabase := False;
  if (DB^.Header^.NumRecords = 0) or
    not GetSortOptions(DB, AField) then Exit;
  RecSize := DB^.Header^.RecordLen;
  msRP := MemAlloc(RecSize);
  if msRP = nil then
  begin
    Application^.OutOfMemory;
    Exit;
  end;
  msDB := DB;
  msFP := msDB^.Fields^.At(msField);
  msChanged := False;
  MemSize := OptimumHeapToUse(RecSize, DB^.Header^.NumRecords);
  LogEvent := lcDiskWrite;
  DrawStatusLine('Sorting database records in ' +
    TrimmedName(msDB^.Name^, 39) + '.');
  Result := MergeSort(MemSize, RecSize,
    SendToSortEngine, CompareElements, GetFromSortEngine,
    DefaultMergeName);
  FreeMem(msRP, RecSize);
  if (Result > 1) and (Result <> 213) then MessageBox(
    ^C'Error %d sorting database file'#13^C'|' +
    msDB^.Name^ + '|.', @Result, mfError + mfOkButton);
  SortDatabase := msChanged;
end;

end.