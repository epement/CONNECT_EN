{$I-,F+,O+,X+}
unit FMClip;

interface

uses FileMngr;

procedure ClipCopyPrim(FManager: PPanel);
procedure ClipPastePrim(FManager: PPanel; Unselect: Boolean);

implementation

uses Objects, Drivers, Views, App, PanelRec, Swaps, ClipPrim, FindFile,
  FMAbort, BBSStuff, EditMsg, Menus, Popups, RevPos, DirPrim, LFN, Keyboard,
  TPString, Consts, Commands, Defaults;

procedure ClipCopyPrim(FManager: PPanel);
const
  cmFMClipCopy = 60500;
var
  Short: Boolean;
  PopupCommand: Word;
  I, SaveCount, MaxLen, PopupResult: Integer;
  SR: PPanelRec;
  PS: PFilesBBSRec;
  S, C: String;

procedure ClipCopyPopup;
var
  Item: PMenuItem;
  R: TRect;
begin
  Item :=
    NewItem('~1~. path\name.ext', '', kbNoKey, cmFMClipCopy, hcECopy,
    NewLine(
    NewItem('~2~. path', '', kbNoKey, cmFMClipCopy + 1, hcECopy,
    NewItem('~3~. path\', '', kbNoKey, cmFMClipCopy + 2, hcECopy,
    NewItem('~4~. path\name', '', kbNoKey, cmFMClipCopy + 3, hcECopy,
    NewLine(
    NewItem('~5~. name', '', kbNoKey, cmFMClipCopy + 4, hcECopy,
    NewItem('~6~. name.ext', '', kbNoKey, cmFMClipCopy + 5, hcECopy,
    NewLine(
    NewItem('~7~. ext', '', kbNoKey, cmFMClipCopy + 6, hcECopy,
    NewItem('~8~. .ext', '', kbNoKey, cmFMClipCopy + 7, hcECopy,
    NewLine(
    NewItem('~A~lt - short name', '', kbNoKey, cmFMClipCopy + 8, hcECopy,
      nil)))))))))))));
  if FManager^.Which = pnLeft then R.A.X := 19
  else R.A.X := ScreenWidth - 19;
  R.A.Y := ScreenHeight div 2 - 2;
  ShowPopup(R.A, NewMenu(Item));
  PopupCommand := $FFFF;
  if (Pending.What = evCommand) and (Pending.Command >= cmFMClipCopy) then
  begin
    PopupCommand := Pending.Command;
    Pending.What := evNothing;
    if PopupCommand = cmFMClipCopy + 8 then
    begin
      PopupCommand := cmFMClipCopy;
      Short := True;
    end
    else Short := MenuItemRightClicked or (GetShiftState and kbAltShift <> 0);
  end;
end;

procedure GetCopyStr;
var
  B: Byte;
begin
  with FManager^ do
  if (Status = stFull) and (Options and ofFilesBBS <> 0) and
     (Settings and seLongNames = 0) then
  begin
    PS := FilesBBS^.At(I);
    if (PS = nil) or (PS^.Text = nil) then C := ''
    else C := PS^.Text^;
    AddNameExt('', SR, S);
    lGetShortFileName(S, S);
    S := JustFileName(S);
    UpcaseSt(S);
    if BBSSpaces = 0 then B := Length(S) + 1
    else B := BBSWrapPos;
    PadSt(S, B);
    S := S + C;
  end
  else
  begin
    GetRecStr(SR, S);
{ Added 2005.10.04 }
    if SR^.Attr and $10 <> 0 then S := AddedSlash(S);
    if InArchive then S := System.Copy(
      S, Length(Archiver^.ArcName^) + 2, 255)
    else if Short then lGetShortFileName(S, S);
    case PopupCommand of
      cmFMClipCopy + 1: S := ClearedSlash(JustPathName(S));
      cmFMClipCopy + 2: S := AddedSlash(JustPathName(S));
      cmFMClipCopy + 3: S := AddedSlash(JustPathName(S)) + JustName(S);
      cmFMClipCopy + 4: S := JustName(S);
      cmFMClipCopy + 5: S := JustFileName(S);
      cmFMClipCopy + 6: S := JustExtension(S);
      cmFMClipCopy + 7: S := '.' + JustExtension(S);
    end;
  end;
end;

begin
  with FManager^ do
  begin
    if DiskClipStream = nil then Exit;
    PopupCommand := 0;
    Short := False;
    if MenuItemRightClicked or (GetShiftState and kbAltShift <> 0) then
      ClipCopyPopup;
    if PopupCommand = $FFFF then Exit;
    DrawFMClipCopyStatus;
    if (Status >= stInfo) or
       ((SelCount > 0) and (Settings and seIgnoreSelection = 0)) then
    begin
      SetExpandClipAreaFlag;
      MaxLen := 0;
      SaveCount := ClipLines^.Count;
      if Status >= stInfo then for I := 0 to Dirinfo^.Count - 1 do
      begin
	PS := Dirinfo^.At(I);
	if PS = nil then S := ''
	else S := DelChar('|', PString(PS)^);
	PutClipLine(S);
	if not MarkColumns or (Length(S) > MaxLen) then
	  MaxLen := Length(S);
	if ClipOverflow then Break;
	if (KbdStatus = 1) and FMAbortAction then Break;
      end
      else for I := 0 to List^.Count - 1 do
      begin
	SR := List^.At(I);
	if SR^.Selected then
	begin
	  GetCopyStr;
	  PutClipLine(S);
	  if not MarkColumns or (Length(S) > MaxLen) then
	    MaxLen := Length(S);
	  if ClipOverflow then Break;
	end;
	if (KbdStatus = 1) and FMAbortAction then Break;
      end;
      SetOrExpandClipArea(SaveCount, MaxLen + 1);
      Message(Desktop, evBroadcast, cmUpdateViews, nil);
    end
    else
    begin
      I := Focused;
      SR := List^.At(I);
      GetCopyStr;
      Message(Application, evBroadcast, cmCopy, @S);
    end;
  end;
end;

procedure ClipPastePrim(FManager: PPanel; Unselect: Boolean);
var
  B: Byte;
  I, N: Integer;
  P: PPanelRec;
  E: TEvent;
  S: String;

procedure ScanLine;
begin
  B := 1;
  repeat
    TrimSt(S);
    if S = '' then Exit;
    while (B <= Length(S)) and (S[B] <> ' ') do Inc(B);
    N := 0;
    repeat
      FManager^.FindByName(Copy(S, 1, B - 1), N);
      if N = -1 then Break;
      with FManager^ do
      begin
	P := List^.At(N);
	if P^.Attr and $10 = 0 then SetSelect(P, not Unselect);
      end;
      Inc(N);
    until False;
    System.Delete(S, 1, B);
  until False;
end;

begin
  with FManager^ do
  begin
    if (DiskClipStream = nil) or not ClipAreaSelected or
       (Status > stTree) or (List^.Count = 0) then Exit;
    if PPanelWindow(Owner)^.State and sfSearching <> 0 then
    begin
      GetClipLine(ClipArea^.KB, S);
      for I := 1 to Length(S) do
      begin
	E.What := evKeyDown;
	E.CharCode := S[I];
	N := SearchPos;
	HandleEvent(E);
	if N = SearchPos then Exit;
      end;
      Exit;
    end;
    if Status = stTree then Exit;
    DrawStatusLine('Searching for the selected file names.');
    Message(Desktop, evBroadcast, cmUpdateViews, nil);
    for I := ClipArea^.KB to ClipArea^.KK do
    begin
      GetClipLine(I, S);
      ScanLine;
      if (KbdStatus = 1) and FMAbortAction then Break;
    end;
    FocusItem(Focused);
  end;
end;

end.