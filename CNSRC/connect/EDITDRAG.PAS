{$I-,F+,O+,X+}
unit EditDrag;

interface

uses Objects, FEditor;

procedure DragDropPrim(Editor: PFileEditor; Where: TPoint);

implementation

uses Dos, Drivers, Views, MsgBox, App, Swaps, EditMsg, DragDrop,
  TPString, Consts, Commands, Defaults;

procedure DragDropPrim(Editor: PFileEditor; Where: TPoint);
var
  Action: Byte;
  Shift: Word;
  SaveOpt: Longint;
  W: PDragWindow;
  P: PFileEditor;
  R: TRect;
  Title: String[4];
  E: TEvent;
  F: File;
  Name: FNameStr;
  S: String;

procedure WriteBinaryBlock;
begin
  with Editor^ do
  begin
    Assign(F, Name);
    Rewrite(F, 1);
    if IOResult <> 0 then
    begin
      CouldNotOpenMsgBox(Name);
      Exit;
    end;
    GetSelectedString(Area^.KB, S);
    if LocalEditOptions and eoUseTabs <> 0 then
      S := Entab(S, LocalTabSize);
    BlockWrite(F, S[1], Byte(S[0]));
    Close(F);
  end;
end;

begin
  with Editor^ do
  begin
    Shift := GetShiftState;
    if Shift and kbAltShift <> 0 then Action := 2
    else if Shift and kbCtrlShift <> 0 then Action := 1
    else Action := 0;
    if Action = 2 then Title := 'Drag'
    else if Action = 1 then Title := 'Move'
    else Title := 'Copy';

    R.Assign(Where.X, Where.Y, Where.X + 18, Where.Y + 3);
    W := New(PDragWindow, Init(R, Title, Owner,
      hcBlockDragAndDrop, 'Selected block'));
    Application^.Insert(W);

    Application^.GetExtent(R);
    E.What := evMouseDown;
    E.Where := Where;
    W^.DragView(E, dmDragMove, R, W^.Size, W^.Size);
    if W^.Cancel then
    begin
      W^.Close;
      Exit;
    end;

    P := Message(Desktop, evBroadcast, cmGetBlockDest, W);
    W^.Close;

    if P = nil then Clear(Action <> 2, True)
    else if P = Editor then
    begin
      if Action = 2 then
	TransferBlock(Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1, False)
      else if Action = 1 then
	MoveBlock(Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1)
      else InsertBlock(Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1);
      DrawView;
      Indicator^.DrawView;
    end
    else
    begin
      DrawStatusLine('Copying block to another destination.');
      SaveLastLine;
      GetValidSwapDir(Name, False);
      Name := Name + TempName + '.!!!';
      SaveOpt := LocalEditOptions;
      LocalEditOptions := LocalEditOptions and not eoUseTabs;
      if (Options and ofHex = 0) and
	 (P^.Options and ofHex <> 0) and
	 (Area^.KB = Area^.KK) then WriteBinaryBlock
      else WriteBlock(Name, False);
      LocalEditOptions := SaveOpt;
      if Action > 0 then Clear(Action <> 2, True);
      if P^.Options and ofHex = 0 then
	P^.NewUndoChain(Area^.KK - Area^.KB + 1);
      P^.ReadBlock(Name, True);
      P^.AddUndoChain;
      P^.DrawView;
      P^.Indicator^.DrawView;
      Assign(F, Name);
      Erase(F);
      InOutRes := 0;
    end;
  end;
end;

end.