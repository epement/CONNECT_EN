{$I-,F+,O+,X+}
unit Icons;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PIcon = ^TIcon;
  TIcon = object(TDialog)
    IsValid: Boolean;
    Running: Boolean;
    FileName: PString;
    Params: PString;
    constructor Init(var FName: String);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function GetHelpCtx: Word; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
    function Valid(Command: Word): Boolean; virtual;
    procedure Validate;
    procedure RunProg;
  end;

const
  sfAborted = $1000;
  sfExecutable = $2000;
  sfHasParams = $4000;

implementation

uses Dos, WinIcons, App, MsgBox, Compiler, EditMsg, IconPrim, ProgList,
  ExecPrim, HeapUMB, LFN, DosTools, TPString, Consts, Commands, Defaults;

constructor TIcon.Init(var FName: String);
var
  R: TRect;
begin
  R.Assign(30, 9, 49, 14);
  TDialog.Init(R, JustName(FName));
  HelpCtx := hcIcon;
{  FileName := NewStr(FName);}
  FileName := NewStrUMB(FName);
  if IconParams <> nil then
  begin
    State := State or sfHasParams;
{    Params := NewStr(IconParams^);}
    Params := NewStrUMB(IconParams^);
    IconParams := nil;
  end;
  R.Assign(1, 2, 8, 4);
  Insert(New(PButton, Init(R, '~R~un', cmOk, bfDefault)));
  Inc(R.A.X, 7); Inc(R.B.X, 9);
  Insert(New(PButton, Init(R, '~C~lose', cmCancel, bfNormal)));
  SelectNext(False);
  Validate;
end;

constructor TIcon.Load(var S: TStream);
begin
  TDialog.Load(S);
{
  FileName := S.ReadStr;
  if State and sfHasParamStr <> 0 then Params := S.ReadStr;
}
  FileName := ReadStrUMB(@S);
  if State and sfHasParams <> 0 then Params := ReadStrUMB(@S);
  Validate;
end;

destructor TIcon.Done;
begin
{
  DisposeStr(Params);
  DisposeStr(FileName);
}
  DisposeStrUMB(Params);
  DisposeStrUMB(FileName);
  TDialog.Done;
end;

function TIcon.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else if Running then GetHelpCtx := hcRunning
  else GetHelpCtx := hcIcon;
end;

procedure TIcon.HandleEvent(var Event: TEvent);
begin
  if (State and sfAborted <> 0) and
     (Event.What = evBroadcast) and
     (Event.Command = cmLoadIcon) then
  begin
    ClearEvent(Event);
    State := State and not sfAborted;
    if not ProgRunning then RunProg;
  end;
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbEsc: Exit;
      kbLeft, kbRight: Event.KeyCode := kbTab;
    end;
  if Event.What = evCommand then
    case Event.Command of
      cmOk:
	begin
	  PutEvent(Event);
	  if not AbortUserProgram then Exit;
	  Event.What := evNothing;
	  RunProg;
	end;
      cmCancel:
	begin
	  Event.Command := cmClose;
	  Event.InfoPtr := nil;
	end;
    end
  else if (Event.What = evBroadcast) and (Event.Command = cmUpload) and
    (Event.InfoPtr <> nil) and (PString(Event.InfoPtr)^ = FileName^) then
  begin
    Validate;
    IsValid := True;
  end;
  TDialog.HandleEvent(Event);
end;

procedure TIcon.Store(var S: TStream);
begin
  TDialog.Store(S);
  S.WriteStr(FileName);
  if State and sfHasParams <> 0 then S.WriteStr(Params);
end;

function TIcon.Valid(Command: Word): Boolean;
begin
  if Running and (Command = cmClose) then
  begin
    CtrlBreakHit := True;
    Valid := False;
  end
  else Valid := TDialog.Valid(Command) and IsValid;
end;

procedure TIcon.RunProg;
var
  W: Word;
  Item: PExecItem;
  S: TDosStream;
begin
  if State and sfExecutable <> 0 then
  begin
    S.Init(FileName^, stOpenRead);
    Item := PExecItem(S.Get);
    S.Done;
    if Item <> nil then
    begin
      Item^.GetData(ExecRec, W);
      Dispose(Item, Done);
      PrepareExecEvent;
    end
    else InvalidProgFileMsgBox(FileName^);
  end
  else
  begin
    StatusLine^.Update;
    RunPrim(@Self);
  end;
end;

procedure TIcon.Validate;
var
  W: Word;
  F: lFile;
  S: String;
begin
  IsValid := False;
  State := State and not sfExecutable;
  lAssignFile(F, FileName^);
  lResetReadOnly(F, 1);
  if IOResult <> 0 then
  begin
    CouldNotOpenMsgBox(FileName^);
    Exit;
  end;
  if IsDevice(FileRec(F.F).Handle) then
  begin
    System.Close(F.F);
    InOutRes := 0;
    FileIsDeviceMsgBox(FileName^);
    Exit;
  end;
  BlockRead(F.F, W, SizeOf(Word));
  if IOResult = 0 then
  begin
    if W = $492 then
    begin
      BlockRead(F.F, S[0], SizeOf(Byte));
      BlockRead(F.F, S[1], Length(S));
      if IOResult = 0 then
      begin
	DisposeStr(Title);
	Title := NewStr(S);
	Frame^.DrawView;
	if Icon <> nil then PWinIcon(Icon)^.Update;
	State := State or sfExecutable;
	IsValid := True;
      end;
    end
    else if W = $4243 then
    begin
      BlockRead(F.F, W, SizeOf(Word));
      if (IOResult = 0) and (W = $5250) then IsValid := True;
    end;
  end;
  System.Close(F.F);
  InOutRes := 0;
  if not IsValid then InvalidProgFileMsgBox(FileName^);
end;

end.