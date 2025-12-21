{$F+,O+,X+}
unit OpenHelp;

interface

uses Drivers;

procedure SetAltHelpName;
procedure CallHelp(var Event: TEvent);
procedure ReopenHelp(Index: Integer);

implementation

uses Objects, Views, App, StdDlg, HelpPrim, HelpFile, History, ExecPrim,
  HistList, Consts, Commands, Defaults;

procedure SetAltHelpName;
var
  C: Word;
  S: FNameStr;
begin
  S := AltHelpName;
  C := Application^.ExecuteDialog(
    New(PFileDialog, Init('*.HLP', 'Help file',
    '~N~ame', fdOkButton + fdClearButton + fdHelpButton,
    HistoryID)), @S, False);
  if C <> cmCancel then
    if C = cmFileClear then AltHelpName := ''
    else AltHelpName := S;
end;

procedure CallHelp(var Event: TEvent);
var
  ExecHelp: Boolean;
  CurCtx: Word;
  P: PString;
  R: TPrevHelpRec;
begin
  ExecHelp := Event.InfoPtr = @ExecRec;
  if ModalHelpInUse or (not ExecHelp and
    (((TheHelpViewer <> nil) and (TheHelpViewer^.Owner^.State and
     (sfActive + sfFocused + sfSelected + sfDragging) =
      sfActive + sfFocused + sfSelected)))) or (not ExecHelp and
    (((TheHelpBrowser <> nil) and (TheHelpBrowser^.Owner^.State and
     (sfActive + sfFocused + sfSelected + sfDragging) =
      sfActive + sfFocused + sfSelected)))) then Exit;
  if Event.Command = cmPreviousTopic then GetHelp(R)
  else
  begin
    FillChar(R, SizeOf(TPrevHelpRec), 0);
    CurCtx := Application^.GetHelpCtx;
    if (Event.Command = cmHelp) and (CurCtx = hcDragging) then
      R.PrevIndex := hcDragging
    else if NoModalWindows then
    begin
      if ExecHelp then
      begin
        P := Event.InfoPtr;
        if ExecRec.Params <> '' then Event.Command := cmTopicSearch;
      end
      else if AltHelpName <> '' then P := @AltHelpName
      else P := Message(Desktop^.Current, evBroadcast, cmHelp, nil);
      R.PrevName := P;
      if Event.Command <> cmHelp then
      begin
        if P <> nil then R.PrevIndex := 1
        else if Event.Command = cmContents then R.PrevIndex := hcContents
        else R.PrevIndex := hcTopicSearch;
        if Event.Command = cmTopicSearch then
        begin
          if ExecHelp then
            if ExecRec.Params = '' then P := nil
            else P := @ExecRec.Params
          else P := Message(Desktop^.Current, evBroadcast, cmGetWord, nil);
          if P <> nil then PutHelpSearchStr(P^);
        end;
      end
      else if P = nil then R.PrevIndex := CurCtx;
    end
    else if Event.Command = cmContents then R.PrevIndex := hcContents
    else if Event.Command = cmTopicSearch then R.PrevIndex := hcTopicSearch
    else R.PrevIndex := CurCtx;
  end;
  Help(R, ExecHelp and (ExecRec.Options and opInfoBit <> 0));
  Event.What := evNothing;
end;

procedure ReopenHelp(Index: Integer);
var
  P: Byte;
  R: TPrevHelpRec;
  S: String;
begin
  S := HistoryStr(HelpHistoryID, Index);
  P := Pos(#$FF, S);
  if P = 0 then Exit;
  Delete(S, 1, P);
  P := Pos(#$FF, S);
  Move(S[P + 1], R.PrevIndex, SizeOf(TPrevHelpRec) - SizeOf(PString));
  S[0] := Char(P - 1);
  if S = '' then R.PrevName := nil else R.PrevName := @S;
  PutHelp(R);
  Pending.What := evCommand;
  Pending.Command := cmPreviousTopic;
end;

end.