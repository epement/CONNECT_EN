{$I-,F+,O+,X+}
unit HelpFind;

interface

uses Objects, Drivers, Views, Dialogs, HelpFile;

type
  PHelpFindAllList = ^THelpFindAllList;
  THelpFindAllList = object(TListViewer)
    Caller: PHelpViewer;
    procedure GetData(var Rec); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure ClipCopy;
    procedure UpdateCommands;
  end;

function HelpFindAllDialog(Count: Integer): PDialog;

implementation

uses App, HelpPrim, FindAll, Swaps, ClipPrim, EditMsg, Keyboard,
  TPString, Consts, Commands, Defaults;

procedure THelpFindAllList.GetData(var Rec);
begin
  Integer(Rec) := Focused;
end;

function THelpFindAllList.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: PFindAllItem;
  S: String[5];
begin
  P := Caller^.FindAllList^.At(Item);
  if P = nil then GetText := ''
  else
  begin
    Str(P^.Rec.PrevIndex, S);
    GetText := Pad(S, 6) + P^.Line^;
  end;
end;

procedure THelpFindAllList.HandleEvent(var Event: TEvent);
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
	Message(Caller, evBroadcast, cmTrackSource, Pointer(Focused));
      cmDeleteItem: if CommandEnabled(cmDeleteItem) then
	begin
	  Caller^.FindAllList^.AtFree(Focused);
	  SetRange(Caller^.FindAllList^.Count);
	  UpdateCommands;
	  DrawView;
	end;
      cmCopy: ClipCopy;
      else Exit;
    end;
    Event.What := evNothing;
  end;
  Inherited HandleEvent(Event);
end;

procedure THelpFindAllList.SetData(var Rec);
var
  C, I, N: Integer;
  P: PFindAllItem;
begin
  Caller := PHelpViewer(Rec);
  SetRange(Caller^.FindAllList^.Count);
  HScrollBar^.SetRange(0, MaxViewWidth);
  N := Caller^.CurCtx;
  C := Caller^.FindAllList^.Count;
  I := 0;
  while (I < C) and
    (PFindAllItem(Caller^.FindAllList^.At(I))^.Rec.PrevIndex < N) do Inc(I);
  FocusItem(I);
  UpdateCommands;
end;

procedure THelpFindAllList.ClipCopy;
var
  I, SaveCount, MaxLen: Integer;
  P: PFindAllItem;
  S: String;
begin
  if (DiskClipStream = nil) or (Caller^.FindAllList^.Count = 0) then Exit;
  SetExpandClipAreaFlag;
  DrawFindAllClipCopyStatus;
  MaxLen := 0;
  SaveCount := ClipLines^.Count;
  for I := 0 to Caller^.FindAllList^.Count - 1 do
  begin
    P := Caller^.FindAllList^.At(I);
    if P = nil then S := '' else S := P^.Line^;
    PutClipLine(S);
    if not MarkColumns or (Length(S) > MaxLen) then MaxLen := Length(S);
    if ClipOverflow or ((KbdStatus = 1) and AbortAction) then Break;
  end;
  SetOrExpandClipArea(SaveCount, MaxLen + 1);
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure THelpFindAllList.UpdateCommands;
var
  C: TCommandSet;
begin
  C := NewCommands + ModifyCommands + DeleteCommands;
  if Caller^.FindAllList^.Count = 0 then DisableCommands(C)
  else EnableCommands(C);
end;

function InitFindAllViewer(var R: TRect; HBar, VBar: PScrollBar;
  InfoPtr: Pointer): PView;
begin
  InitFindAllViewer := New(PHelpFindAllList, Init(R, 1, HBar, VBar));
end;

function HelpFindAllDialog(Count: Integer): PDialog;
var
  R: TRect;
  F: TInitViewerFunc;
begin
  R.Assign(0, 0, 72, ScreenHeight - 14);
  F := InitFindAllViewer;
  HelpFindAllDialog := CustomFindAllDialog(R,
    '~H~elp topic' + FoundLinesCountStr(Count), F, nil);
end;

end.
