{$I-,F+,O-,X+}
unit Macros;

interface

uses Objects, Drivers;

type
  PEvent = ^TEvent;

  PEventCollection = ^TEventCollection;
  TEventCollection = object(TCollection)
    Index: Integer;
    procedure FreeItem(Item: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
  end;

procedure InitMacroEvents;
procedure DoneMacroEvents;
procedure LoadMacroEvents(const AName: FNameStr);
procedure StoreMacroEvents(const AName: FNameStr);

const
  MacroEvents: PEventCollection = nil;
  MacroStorage: PEventCollection = nil;

  MacroCalled: Boolean = False;
  MacroRunning: Boolean = False;
  MacroWaiting: Boolean = False;
  MacroRecording: Boolean = False;
  MacroRepeat: Word = 0;

implementation

uses Memory;

procedure TEventCollection.FreeItem(Item: Pointer);
begin
  if Item <> nil then FreeMem(Item, SizeOf(TEvent));
end;

function TEventCollection.GetItem(var S: TStream): Pointer;
var
  Item: PEvent;
begin
  Item := MemAlloc(SizeOf(TEvent));
  if Item <> nil then S.Read(Item^, SizeOf(TEvent));
  GetItem := Item;
end;

procedure TEventCollection.PutItem(var S: TStream; Item: Pointer);
begin
  S.Write(Item^, SizeOf(TEvent));
end;

procedure InitMacroEvents;
begin
  MacroEvents := New(PEventCollection, Init(8, 8));
end;

procedure DoneMacroEvents;
begin
  if MacroEvents <> nil then Dispose(MacroEvents, Done);
end;

procedure LoadMacroEvents(const AName: FNameStr);
var
  DoErase: Boolean;
  S: TDosStream;
  F: File;
begin
  DoErase := False;
  S.Init(AName, stOpenRead);
  if S.Status = stOk then
  begin
    S.Read(MacroWaiting, SizeOf(Boolean));
    MacroEvents := PEventCollection(S.Get);
    if MacroEvents = nil then InitMacroEvents
    else if MacroEvents^.Count > 0 then MacroRunning := True;
    DoErase := True;
  end
  else InitMacroEvents;
  S.Done;
  if DoErase then
  begin
    Assign(F, AName);
    Erase(F);
    InOutRes := 0;
  end;
end;

procedure StoreMacroEvents(const AName: FNameStr);
var
  S: TDosStream;
begin
  if MacroEvents^.Count <> 0 then
  begin
    S.Init(AName, stCreate);
    if S.Status = stOk then
    begin
      S.Write(MacroWaiting, SizeOf(Boolean));
      S.Put(MacroEvents);
    end;
    S.Done;
  end;
end;

end.