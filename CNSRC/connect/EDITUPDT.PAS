{$I-,F+,O+,X+}
unit EditUpdt;

interface

uses Objects, FEditor;

procedure UpdateLinesPrim(Editor: PFileEditor; const Name: FNameStr);
procedure UpdateTimePrim(Editor: PFileEditor);

implementation

uses Dos, Views, Drivers, MsgBox, App, EditMsg, Compiler,
  Disks, LFN, TPString, Commands;

procedure UpdateLinesPrim(Editor: PFileEditor; const Name: FNameStr);
var
  C: Word;
  FName: FNameStr;
begin
  with Editor^ do
  begin
    if IsDebug then
    begin
      Pending.What := evCommand;
      Pending.Command := cmUpdateASCII;
      if not AbortUserProgram then Exit;
    end;
    C := SaveOrCancel;
    if (C = cmCancel) or ((C = cmYes) and not Save('', False)) then Exit;
    SwapTruncate;
    if FindAllList <> nil then Dispose(FindAllList, Done);
    if RedoList <> nil then Dispose(RedoList, Done);
    if UndoList <> nil then Dispose(UndoList, Done);
    if NewLines <> nil then Dispose(NewLines, Done);
    if FileLines <> nil then Dispose(FileLines, Done);
    if Name <> '' then FName := Name
    else if State and sfNoname <> 0 then FName := ''
    else FName := FileName^;
    DrawFlag := True;
    if (FName <> '') and (FileName <> nil) and
       (CompUCString(FName, FileName^) <> Equal) then GoCtrlPgUp;
    ReadFile(FName);
    IsValid := True;
    Unselect;
    ClearPlaces;
    ClearBreakpoints;
    DrawFlag := False;
    DrawView;
    Indicator^.DrawView;
    PWindow(Owner)^.Frame^.DrawView;
    if State and sfFocused <> 0 then
      DisableCommands(UndoCommands + RedoCommands);
  end;
end;

procedure UpdateTimePrim(Editor: PFileEditor);
var
  L: Longint;
  S: String[5];
begin
  with Editor^ do
    if not IsClip and GetFileTime(FileName^, L) and (L <> LastTime) then
    begin
      if Options and ofHex <> 0 then S := 'Hex' else S := 'ASCII';
      if TimeChangedMsgBox(S, FileName^) = cmOk then UpdateLines('')
      else LastTime := L;
    end;
end;

end.