{$X+,O+,F+}
unit KeyDlg;

interface

uses Objects, Drivers, Views, Dialogs, HotKeys;

type
  PKeyView = ^TKeyView;
  TKeyView = object(TView)
    Key: Word;
    constructor Init(var Bounds: TRect);
    procedure Draw; virtual;
    function GetText: String;
    procedure HandleEvent(var Event: TEvent); virtual;
    function DataSize: Word; virtual;
    procedure GetData(var Rec); virtual;
    procedure SetData(var Rec); virtual;
  end;

  PHotKeyDialog = ^THotKeyDialog;
  THotKeyDialog = object(TDialog)
    KeyView: PKeyView;
    Flag: Boolean;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PHotKeyList = ^THotKeyList;
  THotKeyList = object(TListBox)
    HotKeyCount: ^Word;
    HotKeySequence: PHotKeySequence;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure UpdateCommands;
  end;

  PHotKeySeqDialog = ^THotKeySeqDialog;
  THotKeySeqDialog = object(THotKeyDialog)
    HotKeyCount: Word;
    HotKeySequence: THotKeySequence;
    HotKeyOpt: Word;
    SeqTitle: String[15];
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure HotKeySequenceDialog(Caller: PHotKeySeqDialog;
  var HotKeySequence: THotKeySequence;
  var HotKeyCount: Word;
  var HotKeyOpt: Word);
function GetSequenceStr(P: Pointer; APos: Word;
  MaxLen: Byte; Back: Boolean): String;
procedure DrawSequenceStatusLine(APos: Word);

implementation

uses App, KeyName, TPString, Consts, Commands;

constructor TKeyView.Init(var Bounds: TRect);
begin
  TView.Init(Bounds);
  Options := Options or ofSelectable;
  HelpCtx := hcKeyView;
end;

procedure TKeyView.Draw;
var
  C, P: Byte;
  B: TDrawBuffer;
  S: String;
begin
  C := GetColor(1);
  S := GetText;
  if Options and ofCentered = 0 then P := 0
  else P := (Size.X - Byte(S[0])) div 2;
  MoveChar(B, ' ', C, Size.X);
  MoveStr(B[P], S, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TKeyView.GetText: String;
var
  S: String;
begin
  if Key = 0 then
    if Options and ofCentered = 0 then S := 'None'
    else S := ''
  else if Options and ofCentered <> 0 then
    S := GetKeyName(Key) + ' ($' + HexW(Key) + ')'
  else if GetShiftState and (kbAltShift + kbCtrlShift) =
    kbAltShift + kbCtrlShift then S := '$' + HexW(Key)
  else S := GetKeyName(Key);
  if S[1] = #255 then
  begin
    Delete(S, 1, 1);
    S := '#255' + S;
  end;
  GetText := S;
end;

procedure TKeyView.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    if (State and sfSelected = 0) or (Key = hkSeq) then Exit;
    case Event.KeyCode of
      kbEsc, kbEnter, kbTab, kbShiftTab: if Key <> 0 then Exit;
      0: if Key = 0 then { Ctrl+Break }
	begin
	  Event.What := evNothing;
	  Owner^.SelectNext(False);
          Exit;
        end;
    end;
    if Event.KeyCode = Key then Exit;
    Key := Event.KeyCode;
    SetData(Key);
    Event.What := evNothing;
  end;
  if (Event.What = evMouseDown) and Event.Double then
  begin
    Key := 0;
    SetData(Key);
    Event.What := evNothing;
  end;
end;

function TKeyView.DataSize: Word;
begin
  DataSize := SizeOf(Key);
end;

procedure TKeyView.GetData(var Rec);
begin
  Word(Rec) := Key;
end;

procedure TKeyView.SetData(var Rec);
begin
  Key := Word(Rec);
  DrawView;
end;

procedure THotKeyDialog.HandleEvent(var Event: TEvent);
var
  S: String;
begin
  if KeyView <> nil then
  begin
    if Flag <> (GetShiftState and (kbAltShift + kbCtrlShift) =
      kbAltShift + kbCtrlShift) then
    begin
      KeyView^.DrawView;
      Flag := not Flag;
    end;
    if Event.What = evKeyDown then KeyView^.HandleEvent(Event);
  end;
  TDialog.HandleEvent(Event);
  if (Event.What = evCommand) and (Event.Command = cmDefault) then
  begin
    S := KeyView^.GetText;
    Event.What := evNothing;
    if Length(S) > 8 then
    begin
      S := 'PutKey' + Copy(S, Length(S) - 6, 7) +
        ' Rem ' + Copy(S, 1, Length(S) - 8);
      Message(Desktop, evBroadcast, cmCopy, @S);
    end;
  end;
end;

function THotKeyList.GetText(Item: Integer; MaxLen: Integer): String;
begin
  if Item >= Range then GetText := ''
  else GetText := GetKeyName(HotKeySequence^[Item]);
end;

procedure THotKeyList.HandleEvent(var Event: TEvent);

procedure Refresh(Item: Integer);
begin
  SetRange(HotKeyCount^);
  if Item <= 0 then Item := 0
  else if Item >= Range then Item := Range - 1;
  FocusItem(Item);
  DrawView;
  Select;
  Event.What := evNothing;
end;

begin
  if (Event.What = evKeyDown) and (State and sfSelected <> 0) and
     (Owner^.HelpCtx = hcHotKeyList) then
  begin
    if Event.KeyCode = 0 { Ctrl+Break } then
    begin
      Event.What := evCommand;
      Event.Command := cmStopHotKey;
    end
    else if HotKeyCount^ < MaxHotKeys then
    begin
      HotKeySequence^[HotKeyCount^] := Event.KeyCode;
      Inc(HotKeyCount^);
      Refresh(HotKeyCount^);
    end;
  end;
  Inherited HandleEvent(Event);
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbIns:
	begin
	  Event.What := evCommand;
	  Event.Command := cmAddHotKey;
	end;
      kbDel:
	begin
	  Event.What := evCommand;
	  Event.Command := cmRemoveHotKey;
	end;
      kbCtrlDel:
	begin
	  Event.What := evCommand;
	  Event.Command := cmClearHotKeys;
	end;
    end;
  if Event.What = evCommand then
    case Event.Command of
      cmAddHotKey:
	begin
	  Refresh(Focused);
	  Owner^.HelpCtx := hcHotKeyList;
	end;
      cmStopHotKey: with Owner^ do
	begin
	  HelpCtx := hcHotKeyListDlg;
	  Select;
	  SelectNext(True);
	  SelectNext(True);
	  SelectNext(True);
	end;
      cmRemoveHotKey: if Focused < HotKeyCount^ then
	begin
	  Dec(HotKeyCount^);
	  Move(HotKeySequence^[Focused + 1], HotKeySequence^[Focused],
	    (HotKeyCount^ - Focused) * SizeOf(Word));
	  Refresh(Focused);
	end;
      cmHotKeyUp: if Focused <> 0 then
	begin
	  Event.InfoWord := HotKeySequence^[Focused - 1];
	  HotKeySequence^[Focused - 1] := HotKeySequence^[Focused];
	  HotKeySequence^[Focused] := Event.InfoWord;
	  Refresh(Focused - 1);
	end;
      cmHotKeyDown: if Focused < Range - 1 then
	begin
	  Event.InfoWord := HotKeySequence^[Focused + 1];
	  HotKeySequence^[Focused + 1] := HotKeySequence^[Focused];
	  HotKeySequence^[Focused] := Event.InfoWord;
	  Refresh(Focused + 1);
	end;
      cmClearHotKeys:
	begin
	  HotKeyCount^ := 0;
	  Refresh(0);
	end;
    end;
  UpdateCommands;
end;

procedure THotKeyList.UpdateCommands;
const
  AddCommands = [cmAddHotKey];
  StopCommands = [cmStopHotKey];
  DelCommands = [cmRemoveHotKey, cmClearHotKeys];
  UpCommands = [cmHotKeyUp];
  DownCommands = [cmHotKeyDown];
begin
  if Range <> HotKeyCount^ then SetRange(HotKeyCount^);
  if Owner^.HelpCtx = hcHotKeyList then
  begin
    EnableCommands(StopCommands);
    DisableCommands(AddCommands);
  end
  else
  begin
    if HotKeyCount^ < MaxHotKeys then EnableCommands(AddCommands)
    else DisableCommands(AddCommands);
    DisableCommands(StopCommands);
  end;
  if HotKeyCount^ <> 0 then EnableCommands(DelCommands)
  else DisableCommands(DelCommands);
  if Focused <> 0 then EnableCommands(UpCommands)
  else DisableCommands(UpCommands);
  if Focused < Range - 1 then EnableCommands(DownCommands)
  else DisableCommands(DownCommands);
end;

procedure THotKeySeqDialog.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evCommand) and (Event.Command = cmKeySequence) then
  begin
    HotKeySequenceDialog(@Self,
      HotKeySequence, HotKeyCount, HotKeyOpt);
    Event.What := evNothing;
  end;
  Inherited HandleEvent(Event);
end;

procedure HotKeySequenceDialog(Caller: PHotKeySeqDialog;
  var HotKeySequence: THotKeySequence;
  var HotKeyCount: Word;
  var HotKeyOpt: Word);
type
  TData = record
    State: Word;
    Check: Word;
    List: PCollection;
    Sel: Word;
  end;
var
  Count: Word;
  D: PDialog;
  Control: PView;
  KeyList: PHotKeyList;
  R: TRect;
  Data: TData;
  HotKeys: THotKeySequence;
begin
  Count := HotKeyCount;
  if Count <> 0 then Move(HotKeySequence, HotKeys, Count * SizeOf(Word));

  R.Assign(0, 0, 57, 19);
  D := New(PDialog, Init(R, Caller^.SeqTitle + ' hot key sequence'));
  with D^ do
  begin
    HelpCtx := hcHotKeyListDlg;
    Options := Options or ofCentered;

    R.Assign(17, 3, 32, 5);
    Insert(New(PButton, Init(R, 'ÄÄÄÄÄÄ ~A~dd', cmAddHotKey, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    Insert(New(PButton, Init(R, 'ÄÄÄXÄÄ ~S~top', cmStopHotKey, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    Insert(New(PButton, Init(R, '~R~emove ÄÄÄ', cmRemoveHotKey, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    Insert(New(PButton, Init(R, '~C~lear all', cmClearHotKeys, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    Insert(New(PButton, Init(R, ' Move ~u~p  ', cmHotKeyUp, bfNormal)));
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    Insert(New(PButton, Init(R, ' Move ~d~own', cmHotKeyDown, bfNormal)));

    R.Assign(34, 3, Size.X - 3, 10);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Ri~g~ht Shift',
      NewSItem('Left S~h~ift',
      NewSItem('Ctr~l~',
      NewSItem('Al~t~',
      NewSItem('Scr~o~ll Lock',
      NewSItem('Nu~m~ Lock',
      NewSItem('Ca~p~s Lock', nil)))))))));
    Insert(Control);
    R.Assign(33, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(R, 'Keyboard state', Control)));

    R.Assign(34, 12, Size.X - 3, 15);
    Control := New(PRadioButtons, Init(R,
      NewSItem('Do ~n~ot check',
      NewSItem('~F~irst key only',
      NewSItem('All k~e~ys', nil)))));
    Insert(Control);
    R.Assign(33, 11, Size.X - 3, 12);
    Insert(New(PLabel, Init(R, 'Check keyboard state', Control)));

    StandardButtonRow(D, False);

    R.Assign(15, 3, 16, Size.Y - 4);
    Control := New(PScrollBar, Init(R));
    Insert(Control);
    R.Assign(3, 3, 15, Size.Y - 4);
    KeyList := New(PHotKeyList, Init(R, 1, PScrollBar(Control)));
    Insert(KeyList);
    KeyList^.Options := KeyList^.Options or ofPreProcess;
    KeyList^.HotKeyCount := @Count;
    KeyList^.HotKeySequence := @HotKeys;
    R.Assign(2, 2, 16, 3);
    Insert(New(PLabel, Init(R, 'Ke~y~s', KeyList)));

    if Count = 0 then SelectNext(False);
  end;

  with Data do
  begin
    List := nil;
    Sel := 0;
    State := WordRec(HotKeyOpt).Lo;
    Check := WordRec(HotKeyOpt).Hi;
  end;

  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    HotKeyCount := Count;
    if Count <> 0 then
    begin
      Move(HotKeys, HotKeySequence, Count * SizeOf(Word));
      WordRec(HotKeyOpt).Lo := Data.State;
      WordRec(HotKeyOpt).Hi := Data.Check;
      Caller^.KeyView^.Key := hkSeq;
    end
    else Caller^.KeyView^.Key := 0;
    Caller^.KeyView^.DrawView;
  end;
end;

function GetSequenceStr(P: Pointer; APos: Word;
  MaxLen: Byte; Back: Boolean): String;
var
  I, N: Integer;
  C: String[15];
  S: String;
begin
  S := '';
  if Back then
  begin
    I := APos;
    N := 0;
  end
  else
  begin
    I := 0;
    N := APos;
  end;
  repeat
    C := ' ' + GetKeyName(PHotKeySequence(P)^[I]);
    if Length(C) + Length(S) > MaxLen then
    begin
      if Back then S := '' + S else S := S + '';
      Break;
    end;
    if Back then
    begin
      S := C + S;
      Dec(I);
      if I < N then Break;
    end
    else
    begin
      S := S + C;
      Inc(I);
      if I > N then Break;
    end;
  until False;
  GetSequenceStr := S;
end;

procedure DrawSequenceStatusLine(APos: Word);
begin
  StatusLine^.Update;
  DrawStatusLine('Waiting for the next key:' +
    GetSequenceStr(@GlobalSequence, APos, 44, True));
end;

end.
