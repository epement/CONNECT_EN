{$I-,X+,O+,F+}
unit Funcs;

interface

uses
  Objects, Views, Drivers, Dialogs;

type
  PMenuList = ^TMenuList;
  TMenuList = object(TListViewer)
    MenuCollection: PCollection;
    constructor Init(var Bounds: TRect; ANumCols: Word;
      AHScrollBar, AVScrollBar: PScrollBar);
    destructor Done; virtual;
    procedure GetData(var Rec); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
  end;

const
  mlNo = 0;
  mlOpen = 1;
  mlOk = 2;
  mlClose = 3;
  MenuListInUse: Byte = mlNo;

function GetStringNum(const FName: String; AModal: Boolean;
  FlagPtr: Pointer): Integer;
function GetFileName(var S: String): Boolean;
function GetString(var S: String): Boolean;
function GetValue(var L: Longint): Word;
function GetPrompt(var S: String; ATitle, ALabel: String): Boolean;
function GetFName(var S: String): Boolean;

implementation

uses Dos, Memory, MsgBox, StdDlg, App, HistList, EditMsg, LFN,
  StrCol, HeapUMB, DosTools, TPString, History, Consts, Commands;

constructor TMenuList.Init(var Bounds: TRect; ANumCols: Word;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TListViewer.Init(Bounds, ANumCols, AHScrollBar, AVScrollBar);
  MenuListInUse := mlOpen;
end;

destructor TMenuList.Done;
begin
  if MenuCollection <> nil then Dispose(MenuCollection, Done);
  MenuListInUse := mlNo;
  TListViewer.Done;
end;

procedure TMenuList.GetData(var Rec);
begin
  if MenuCollection^.Count = 0 then Integer(Rec) := 0
  else Integer(Rec) := Focused + 1;
end;

function TMenuList.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: PString;
begin
  P := MenuCollection^.At(Item);
  if P = nil then GetText := ''
  else GetText := Detab(P^, 8);
end;

procedure TMenuList.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    if Owner^.State and sfModal <> 0 then Owner^.EndModal(cmOk)
    else MenuListInUse := mlOk;
    Event.What := evNothing;
  end
  else if (Owner^.State and sfModal = 0) and
    ((Event.What = evKeyDown) and (Event.KeyCode = kbEsc)) then
  begin
    MenuListInUse := mlClose;
    Event.What := evNothing;
  end
  else TListViewer.HandleEvent(Event);
end;

procedure TMenuList.SetData(var Rec);
var
  F: lText;
  S: String;
begin
  Move(Rec, S, SizeOf(String));
  MenuCollection := New(PStringsCollection, Init(8, 8));
  if S <> '' then
  begin
    lAssignText(F, S);
    Reset(F.T);
    if IOResult <> 0 then CouldNotOpenMsgBox(S)
    else
    begin
      if IsDevice(TextRec(F.T).Handle) then FileIsDeviceMsgBox(S)
      else while not Eof(F.T) and (MenuCollection^.Count < 256) do
      begin
        Readln(F.T, S);
{       if S <> '' then MenuCollection^.Insert(NewStr(S));}
        if S <> '' then MenuCollection^.Insert(NewStrUMB(S));
      end;
      Close(F.T);
      InOutRes := 0;
    end;
  end;
  SetRange(MenuCollection^.Count);
  HScrollBar^.SetRange(0, 255);
end;

function GetStringNum(const FName: String; AModal: Boolean;
  FlagPtr: Pointer): Integer;
var
  I: Integer;
  D: PDialog;
  R: TRect;
  Event: TEvent;
  S: String;
begin
  S := FName;
  R.Assign(0, 0, 40, 15);
  D := New(PDialog, Init(R, 'User menu'));
  with D^ do
  begin
    Options := Options or (ofCentered + ofNotStorable);
    HelpCtx := hcMenuDialog;
    GetExtent(R);
    R.Grow(-1, -1);
    Insert(New(PMenuList, Init(R, 1,
      StandardScrollBar(sbHorizontal + sbHandleKeyboard),
      StandardScrollBar(sbVertical + sbHandleKeyboard))));
  end;
  if AModal then
    if Application^.ExecuteDialog(D, @S, True) = cmCancel then I := 0
    else Move(S, I, SizeOf(Integer))
  else
  begin
    D^.SetData(S);
    Application^.InsertWindow(D);
    I := 0;
    repeat
      NestedEventCount := 0;
      Application^.GetEvent(Event);
      Application^.HandleEvent(Event);
    until (MenuListInUse <> mlOpen) or Boolean(FlagPtr^);
    if MenuListInUse = mlOk then D^.GetData(I);
    if MenuListInUse <> mlNo then D^.Close;
  end;
  GetStringNum := I;
  StatusLine^.Update;
end;

function GetFileName(var S: String): Boolean;
begin
  GetFileName := Application^.ExecuteDialog(
    New(PFileDialog, Init('*.*', 'Open a file',
    '~N~ame', fdOkButton + fdHelpButton,
    HistoryID)), @S, True) <> cmCancel;
  StatusLine^.Update;
end;

function GetString(var S: String): Boolean;
var
  D: PDialog;
  Control: PInputLine;
  R: TRect;
begin
  R.Assign(0, 0, 60, 7);
  D := New(PDialog, Init(R, 'Enter a string'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcStringDialog;
    R.Assign(17, 2, Size.X - 6, 3);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, StringHistoryId);
    R.Assign(2, 2, 17, 3);
    Insert(New(PLabel, Init(R, '~T~ype a string', Control)));
    R.Assign(16, Size.Y - 3, 26, Size.Y - 1);
    StandardOkButton(R, D);
    Inc(R.A.X, 31); Inc(R.B.X, 31);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  GetString := Application^.ExecuteDialog(D, @S, True) <> cmCancel;
  StatusLine^.Update;
end;

function GetValue(var L: Longint): Word;
var
  P: Byte;
  Segment, Offset, C: Word;
  D: PDialog;
  Control: PInputLine;
  R: TRect;
  Data: String[11];
begin
  C := cmCancel;
  R.Assign(0, 0, 35, 7);
  D := New(PDialog, Init(R, 'Enter a value'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcValueDialog;
    R.Assign(16, 2, Size.X - 6, 3);
    Control := New(PInputLine, Init(R, 11));
    Insert(Control);
    StandardHistory(Control, ValueHistoryId);
    R.Assign(2, 2, 16, 3);
    Insert(New(PLabel, Init(R, '~T~ype a value', Control)));
    R.Assign(3, Size.Y - 3, 13, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  Str(L, Data);
  C := Application^.ExecuteDialog(D, @Data, True);
  StatusLine^.Update;
  GetValue := C;
  if C <> cmCancel then
  begin
    P := Pos(':', Data);
    if P <> 0 then
    begin
      if Str2Word('$' + Copy(Data, 1, Pred(P)), Segment) and
         Str2Word('$' + Copy(Data, Succ(P), Length(Data) - P), Offset) then
        L := LongMul(Segment, 16) + Offset
      else GetValue := cmNo;
    end
    else if not Str2Long(Data, L) then GetValue := cmNo;
  end;
end;

function GetPrompt(var S: String; ATitle, ALabel: String): Boolean;
var
  X: Integer;
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  if ATitle = '' then ATitle := 'Program arguments';
  if ALabel = '' then ALabel := '~P~rogram arguments';
  if Length(ALabel) > 32 then X := ScreenWidth
  else X := 63;

  R.Assign(0, 0, X, 7);
  D := New(PDialog, Init(R, ATitle));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcPromptDialog;

    X := CStrLen(ALabel) + 4;
    if X > Size.X - 22 then X := Size.X - 22;
    R.Assign(X, 2, Size.X - 6, 3);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, PromptHistoryId);
    R.Assign(2, 2, X, 3);
    Insert(New(PLabel, Init(R, ALabel, Control)));
    R.Assign(X - 1, Size.Y - 3, X + 9, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardCancelButton(R, D);

    SelectNext(False);
  end;
  GetPrompt := Application^.ExecuteDialog(D, @S, True) <> cmCancel;
end;

function GetFName(var S: String): Boolean;
var
  C: Word;
  Name: FNameStr;
begin
  Name := S;
  C := Application^.ExecuteDialog(New(PFileDialog, Init('*.*',
    'Select a file name', '~N~ame', fdOkButton + fdHelpButton,
    HistoryID)), @Name, False);
  if C <> cmCancel then S := Name;
  GetFName := C <> cmCancel;
end;

end.