{$F+,O+,X+}
unit EnvDlg;

interface

uses Objects, Drivers, Views, Dialogs, StrCol;

type
  PEnvList = ^TEnvList;
  TEnvList = object(TStringsCollection)
    CNEnvSeg, CONNECTEnvSeg: Word;
    CNName, CONNECTName: PString;
    CNSaveVar: PString;
    MaxSize: Word;
    StoreList: Boolean;
    Modified: Boolean;
    constructor Init;
    destructor Done; virtual;
    function GetCurSize: Word;
    procedure CNSaveReplace(const S: String);
    procedure CNSaveGrow(GrowBy: Word);
    function CNSaveShrink(Data, P: PString): Boolean;
    procedure LoadData;
    procedure StoreData;
    procedure ClipCopy;
  end;

  PEnvInput = ^TEnvInput;
  TEnvInput = object(TInputLine)
    SaveCurPos: Integer;
    SaveFirstPos: Integer;
    SaveSelStart: Integer;
    SaveSelEnd: Integer;
    SkipSetDataCheck: Boolean;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure SynchronizeData;
    procedure UpdateLabel;
  end;

  PEnvViewer = ^TEnvViewer;
  TEnvViewer = object(TListViewer)
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure FocusCurrent;
  end;

  PEnvDlg = ^TEnvDlg;
  TEnvDlg = object(TDialog)
    List: PEnvList;
    InputLabel: PLabel;
    Input: PEnvInput;
    Viewer: PEnvViewer;
    constructor Init;
    destructor Done; virtual;
    procedure EndModal(Command: Word); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure EnvDialog;
procedure SetEnvVar(const S: String);
function GetEnvUC(EnvVar: String): String;
function ConditionOK(Condition: String): Boolean;

implementation

uses App, MsgBox, Desktops, Swaps, ClipPrim, EditMsg, History,
  HeapUMB, Strings, TPString, Consts, Commands, Defaults;

procedure DrawEnvStatus(const Action: String);
begin
  DrawStatusLine(Action + 'ing the Environment variables.');
end;

procedure EnvOverflow;
begin
  MessageBox(^C'Environment buffer is full.',
    nil, mfError + mfOkButton);
end;

function IsCNSave(const S: String): Boolean;
begin
  IsCNSave := (S[1] = '$') and (StUpcase(Copy(S, 2, 8)) = 'CNSAVE=#');
end;

function PStringLen(P: PString): Integer;
begin
  if P = nil then PStringLen := 0 else PStringLen := Length(P^);
end;

constructor TEnvList.Init;
begin
  Inherited Init(8, 8);
  LoadData;
end;

destructor TEnvList.Done;
begin
  if StoreList then StoreData;
{
  DisposeStr(CNName);
  DisposeStr(CONNECTName);
}
  DisposeStrUMB(CNName);
  DisposeStrUMB(CONNECTName);
  Inherited Done;
end;

function TEnvList.GetCurSize: Word;
var
  I: Integer;
  W: Word;
  P: PString;
begin
  CNSaveVar := nil;
  W := 2;
  for I := 0 to Count - 1 do
  begin
    P := At(I);
    if P <> nil then
    begin
      Inc(W, PStringLen(P) + 1);
      if IsCNSave(P^) then CNSaveVar := P;
    end;
  end;
  GetCurSize := W;
end;

procedure TEnvList.CNSaveReplace(const S: String);
var
  I: Integer;
begin
  I := IndexOf(CNSaveVar);
  if I <> -1 then
  begin
{    CNSaveVar := NewStr(S);}
    CNSaveVar := NewStrUMB(S);
    AtFree(I);
    AtInsert(I, CNSaveVar);
  end;
end;

procedure TEnvList.CNSaveGrow(GrowBy: Word);
var
  S: String;
begin
  S := CNSaveVar^;
  while (Length(S) < 255) and (GrowBy <> 0) do
  begin
    Inc(S[0]);
    S[Length(S)] := '#';
    Dec(GrowBy);
  end;
  CNSaveReplace(S);
end;

function TEnvList.CNSaveShrink(Data, P: PString): Boolean;
var
  L: Integer;
begin
  L := PStringLen(Data) - PStringLen(P) + Byte(P = nil);
  if (CNSaveVar = nil) or (CNSaveVar = P) or
     (PStringLen(CNSaveVar) < L + 9) then CNSaveShrink := False
  else
  begin
    CNSaveReplace(Copy(CNSaveVar^, 1, PStringLen(CNSaveVar) - L));
    CNSaveShrink := True;
  end;
end;

procedure TEnvList.LoadData;
var
  C: Char;
  EnvSeg, EnvOfs, EnvSize, CNPrefixSeg: Word;
  S: String;
begin
  DrawEnvStatus('Read');

  EnvSeg := MemW[PrefixSeg:$2C];
  CONNECTEnvSeg := EnvSeg;
  EnvSize := MemW[EnvSeg - 1:3] shl 4;

  EnvOfs := 0;
  S := '';
  while EnvOfs < EnvSize do
  begin
    C := Char(Mem[EnvSeg:EnvOfs]);
    if C = #0 then
    begin
{      Insert(NewStr(S));}
      Insert(NewStrUMB(S));
      S := '';
      if Mem[EnvSeg:EnvOfs + 1] = 0 then Break;
    end
    else if S[0] < #255 then
    begin
      Inc(S[0]);
      S[Length(S)] := C;
    end;
    Inc(EnvOfs);
  end;
  if Count = 0 then Insert(nil);

  Inc(EnvOfs, 2);
  S := Char(Mem[EnvSeg:EnvOfs]) + Char(Mem[EnvSeg:EnvOfs + 1]);
  Inc(EnvOfs, 2);
  while EnvOfs < EnvSize do
  begin
    C := Char(Mem[EnvSeg:EnvOfs]);
    if C = #0 then Break;
    if S[0] < #255 then
    begin
      Inc(S[0]);
      S[Length(S)] := C;
    end;
    Inc(EnvOfs);
  end;
{  CONNECTName := NewStr(S);}
  CONNECTName := NewStrUMB(S);
  MaxSize := EnvSize - Length(S);

  if Auto then Exit;

  CNPrefixSeg := Word(Ptr(
    PtrRec(ExchBufferPtr).Seg,
    PtrRec(ExchBufferPtr).Ofs - 2)^);
  EnvSeg := MemW[CNPrefixSeg:$2C];
  CNEnvSeg := EnvSeg;
  EnvSize := MemW[EnvSeg - 1:3] shl 4;

  EnvOfs := 0;
  while (EnvOfs < EnvSize) and (MemW[EnvSeg:EnvOfs] <> 0) do
    Inc(EnvOfs);
  Inc(EnvOfs, 2);
  S := Char(Mem[EnvSeg:EnvOfs]) + Char(Mem[EnvSeg:EnvOfs + 1]);
  Inc(EnvOfs, 2);
  while EnvOfs < EnvSize do
  begin
    C := Char(Mem[EnvSeg:EnvOfs]);
    if C = #0 then Break;
    if S[0] < #255 then
    begin
      Inc(S[0]);
      S[Length(S)] := C;
    end;
    Inc(EnvOfs);
  end;
{  CNName := NewStr(S);}
  CNName := NewStrUMB(S);
  if EnvSize - Length(S) < MaxSize then
    MaxSize := EnvSize - Length(S);
end;

procedure TEnvList.StoreData;
var
  EnvSeg, EnvOfs, EnvSize, CNPrefixSeg: Word;

procedure StoreItems(const Name: String);
var
  I, C: Integer;
  P: PString;
begin
  EnvOfs := 0;
  C := 0;

  for I := 0 to Count - 1 do
  begin
    P := At(I);
    if P <> nil then
    begin
      Move(P^[1], Mem[EnvSeg:EnvOfs], PStringLen(P));
      Inc(EnvOfs, PStringLen(P));
      Mem[EnvSeg:EnvOfs] := 0;
      Inc(EnvOfs);
      Inc(C);
    end;
  end;

  Mem[EnvSeg:EnvOfs] := 0;
  Inc(EnvOfs);
  if C = 0 then
  begin
    Mem[EnvSeg:EnvOfs] := 0;
    Inc(EnvOfs);
  end;
  Move(Name[1], Mem[EnvSeg:EnvOfs], Length(Name));
  Inc(EnvOfs, Length(Name));
  Mem[EnvSeg:EnvOfs] := 0;
end;

begin
  DrawEnvStatus('Updat');

  EnvSeg := CONNECTEnvSeg;
  StoreItems(CONNECTName^);
  if (CNEnvSeg <> 0) and (CNName <> nil) then
  begin
    EnvSeg := CNEnvSeg;
    StoreItems(CNName^);
  end;
end;

procedure TEnvList.ClipCopy;
var
  I, SaveCount, MaxLen: Integer;
  P: PString;
  S: String;
begin
  if (DiskClipStream = nil) or (Count = 0) then Exit;
  DrawEnvClipCopyStatus;
  SetExpandClipAreaFlag;
  MaxLen := 0;
  SaveCount := ClipLines^.Count;
  for I := 0 to Count - 1 do
  begin
    P := At(I);
    if P = nil then S := '' else S := P^;
    PutClipLine(S);
    if not MarkColumns or (Length(S) > MaxLen) then MaxLen := Length(S);
    if ClipOverflow then Break;
  end;
  SetOrExpandClipArea(SaveCount, MaxLen + 1);
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure TEnvInput.HandleEvent(var Event: TEvent);
begin
  Move(CurPos, SaveCurPos, SizeOf(Integer) * 4);
  Inherited HandleEvent(Event);
  SynchronizeData;
end;

procedure TEnvInput.SetData(var Rec);
var
  P: PString;
  S: String;
begin
  if not SkipSetDataCheck then
    Move(CurPos, SaveCurPos, SizeOf(Integer) * 4);
  Inherited SetData(Rec);
  if not SkipSetDataCheck then SynchronizeData;
end;

procedure TEnvInput.SynchronizeData;
var
  P: PString;
begin
  with PEnvDlg(Owner)^ do
  begin
    P := List^.At(Viewer^.Focused);
    if ((P = nil) and (Data^ <> '')) or
       ((P <> nil) and (CompString(P^, Data^) <> Equal)) then
    begin
      if (((P = nil) and (Data^ <> '')) or
	  ((P <> nil) and (PStringLen(P) < PStringLen(Data)))) and
	 (List^.GetCurSize - PStringLen(P) + PStringLen(Data) +
	   Byte(P = nil) > List^.MaxSize) and
	   not List^.CNSaveShrink(Data, P) then
      begin
	EnvOverflow;
	if P = nil then Data^ := '' else Data^ := P^;
	Move(SaveCurPos, CurPos, SizeOf(Integer) * 4);
	Self.DrawView;
      end
      else
      begin
	List^.AtFree(Viewer^.Focused);
{	List^.AtInsert(Viewer^.Focused, NewStr(Data^));}
	List^.AtInsert(Viewer^.Focused, NewStrUMB(Data^));
	List^.Modified := True;
      end;
      UpdateLabel;
      Viewer^.DrawView;
    end;
  end;
end;

procedure TEnvInput.UpdateLabel;
var
  CurSize: Word;
  S: String[2];
begin
  with PEnvDlg(Owner)^.List^ do
  begin
    CurSize := GetCurSize;
    if (CNSaveVar <> nil) and (CurSize < MaxSize) then
    begin
      CNSaveGrow(MaxSize - CurSize);
      CurSize := GetCurSize;
    end;
    CurSize := MaxSize - CurSize;
    if CNSaveVar <> nil then Inc(CurSize, PStringLen(CNSaveVar) - 9);
    if Modified then S := ' *' else S := '';
  end;
  with PEnvDlg(Owner)^ do
  begin
    DisposeStr(InputLabel^.Text);
    InputLabel^.Text := NewStr(
      '~E~dit (bytes free: ' + Long2Str(CurSize) +
      ', line length: ' + Long2Str(Length(Data^)) + ')' + S);
    InputLabel^.DrawView;
  end;
end;

procedure TEnvViewer.FocusItem(Item: Integer);
var
  I: Integer;
  P: PString;
  S: String;
begin
  I := Focused;
  Inherited FocusItem(Item);
  if I <> Focused then with PEnvDlg(Owner)^ do
  begin
    P := List^.At(Focused);
    if P = nil then S := '' else S := P^;
    Input^.SkipSetDataCheck := True;
    Input^.SetData(S);
    Input^.SkipSetDataCheck := False;
    Input^.UpdateLabel;
  end;
end;

function TEnvViewer.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: PString;
begin
  with PEnvDlg(Owner)^ do
  begin
    P := List^.At(Item);
    if P = nil then GetText := '' else GetText := P^;
  end;
end;

procedure TEnvViewer.FocusCurrent;
var
  I: Integer;
begin
  PEnvDlg(Owner)^.Input^.UpdateLabel;
  I := Focused;
  Focused := -1;
  FocusItem(I);
  DrawView;
end;

constructor TEnvDlg.Init;
var
  HBar, VBar: PScrollBar;
  R: TRect;
begin
  R.Assign(0, 0, 60, ScreenHeight - 7);
  TDialog.Init(R, 'Environment editor');
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcEnvDlg;

  R.Assign(3, 2, Size.X - 17, 3);
  Input := New(PEnvInput, Init(R, 255));
  Insert(Input);
  R.Assign(2, 1, Size.X - 14, 2);
  InputLabel := New(PLabel, Init(R, '', Input));
  Insert(InputLabel);
  StandardHistory(Input, EnvHistoryId);

  R.Assign(3, Size.Y - 2, Size.X - 15, Size.Y - 1);
  HBar := New(PScrollBar, Init(R));
  HBar^.Options := HBar^.Options or ofPostProcess;
  HBar^.SetRange(0, 255);
  Insert(HBar);

  R.Assign(Size.X - 15, 5, Size.X - 14, Size.Y - 2);
  VBar := New(PScrollBar, Init(R));
  Insert(VBar);

  R.Assign(3, 5, Size.X - 15, Size.Y - 2);
  Viewer := New(PEnvViewer, Init(R, 1,
    PScrollBar(HBar), PScrollBar(VBar)));
  Viewer^.GrowMode := gfGrowHiY;
  Insert(Viewer);
  R.Assign(2, 4, Size.X - 14, 5);
  Insert(New(PLabel, Init(R, 'Environment ~v~ariables', Viewer)));

  R.Assign(Size.X - 13, 2, Size.X - 3, 4);
  Insert(New(PButton, Init(R, '~M~odify', cmModifyItem, bfDefault)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~N~ew', cmNewItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~C~opy', cmRunItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'D~o~ne', cmYes, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardCancelButton(R, @Self);
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardHelpButton(R, @Self);

  New(List, Init);

  Viewer^.SetRange(List^.Count);
  Viewer^.FocusCurrent;
  Viewer^.Select;
end;

destructor TEnvDlg.Done;
begin
  Dispose(List, Done);
  Inherited Done;
end;

procedure TEnvDlg.EndModal(Command: Word);
begin
  if (Command = cmCancel) and List^.Modified then
  begin
    Command := MessageBox(^C'Save changes to the Environment ?',
      nil, mfConfirmation + mfYesNoCancel);
    if Command = cmCancel then Exit;
  end;
  if Command = cmYes then List^.StoreList := True;
  Inherited EndModal(Command);
end;

procedure TEnvDlg.HandleEvent(var Event: TEvent);
var
  CurSize: Word;
begin
  if (Event.What = evKeyDown) and (Viewer^.State and sfSelected <> 0) then
    case Event.KeyCode of
      kbDel:
	begin
	  Event.What := evCommand;
	  Event.Command := cmDeleteItem;
	end;
      kbIns:
	begin
	  Event.What := evCommand;
	  Event.Command := cmNewItem;
	end;
      kbCtrlIns:
	if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
	begin
	  Event.What := evCommand;
	  Event.Command := cmRunItem;
	end;
    end;
  if (Event.What = evKeyDown) and (Event.KeyCode = kbEnter) and
     (Input^.State and sfSelected <> 0) then
  begin
    Viewer^.Select;
    Event.What := evNothing;
  end;
  Inherited HandleEvent(Event);
  if Event.What = evCommand then with List^ do
  begin
    case Event.Command of
      cmModifyItem: Input^.Select;
      cmNewItem:
	begin
	  CurSize := MaxSize - GetCurSize;
	  if CNSaveVar <> nil then
	    Inc(CurSize, PStringLen(CNSaveVar) - 9);
	  if CurSize = 0 then EnvOverflow
	  else
	  begin
	    AtInsert(Viewer^.Focused, nil);
	    Modified := True;
	    Viewer^.SetRange(Count);
	    Viewer^.FocusCurrent;
	    Input^.Select;
	  end;
	end;
      cmDeleteItem:
	if DeleteItemMsgBox = cmOk then
	begin
	  AtFree(Viewer^.Focused);
	  if Count = 0 then Insert(nil);
	  Modified := True;
	  Viewer^.SetRange(Count);
	  Viewer^.FocusCurrent;
	  Viewer^.Select;
	end;
      cmRunItem: ClipCopy;
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

procedure EnvDialog;
begin
  Application^.ExecuteDialog(New(PEnvDlg, Init), nil, False);
end;

procedure SetEnvVar(const S: String);
var
  B, E, I, N: Integer;
  CurSize: Word;
  P, Q: PString;
  List: PEnvList;
  C: String;
begin
  B := Pos('=', S);
  if B <= 1 then
  begin
    MessageBox(^C'Invalid $SETENV() parameter:'#13^C'"' +
      Copy(S, 1, 32) + '".'#13^C'Syntax: $SETENV(ENVVAR=VALUE)',
      nil, mfError + mfOkButton);
    Exit;
  end;
  C := Copy(S, 1, B - 1);
  New(List, Init);
  N := List^.Count;
  Q := nil;
  for I := 0 to List^.Count - 1 do
  begin
    P := List^.At(I);
    if P <> nil then
    begin
      E := Pos('=', P^);
      if (E > 1) and
	 (CompUCString(Copy(P^, 1, E - 1), C) = Equal) then
      begin
	N := I;
	Q := P;
	Break;
      end;
    end;
  end;

  with List^ do
  begin
    if B = Length(S) then
      if Q <> nil then
      begin
	AtFree(N);
	StoreList := True;
      end else
    else if (GetCurSize - PStringLen(Q) + Length(S) +
      Byte(Q = nil) > MaxSize) and not CNSaveShrink(@S, Q) then
	EnvOverflow
    else
    begin
      if Q <> nil then AtFree(N);
{      AtInsert(N, NewStr(S));}
      AtInsert(N, NewStrUMB(S));
      StoreList := True;
    end;

    if StoreList then
    begin
      CurSize := GetCurSize;
      if (CNSaveVar <> nil) and (CurSize < MaxSize) then
	CNSaveGrow(MaxSize - CurSize);
    end;
  end;

  Dispose(List, Done);
end;

function GetEnvUC(EnvVar: String): String;
var
  EnvSeg, EnvSize, EnvOfs: Word;
  Env: PChar;
  BT: BTable;
begin
  EnvVar := Concat(StUpCase(EnvVar), '=');
  BMMakeTable(EnvVar, BT);
  EnvSeg := MemW[PrefixSeg:$2C];
  EnvSize := MemW[EnvSeg - 1:3] shl 4;
  EnvOfs := BMSearchUC(Ptr(EnvSeg, 0)^, EnvSize, BT, EnvVar);
  if EnvOfs <> $FFFF then
  begin
    Env := Ptr(EnvSeg, EnvOfs + Length(EnvVar));
    GetEnvUC := StrPas(Env);
  end
  else GetEnvUC := '';
end;

function ConditionOK(Condition: String): Boolean;
var
  P: Integer;
  S: String;
begin
  if Condition = '' then ConditionOk := True
  else
  begin
    ConditionOK := False;
    repeat
      P := Pos('|', Condition);
      if P = 0 then P := Length(Condition) + 1;
      S := Copy(Condition, 1, P - 1);
      Delete(Condition, 1, P);
      P := Pos('=', S);
      if ((P = 0) and (GetEnvUC(Trim(S)) <> '')) or
	 ((P <> 0) and (CompUCString(GetEnvUC(
	   Trim(Copy(S, 1, P - 1))),
	   Trim(Copy(S, P + 1, 255))) = Equal)) then
      begin
	ConditionOk := True;
	Exit;
      end;
    until Condition = '';
  end;
end;

end.