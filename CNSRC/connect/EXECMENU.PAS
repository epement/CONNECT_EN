{$F+,O+,X+}
unit ExecMenu;

interface

uses Menus;

const
  ExecMenuInherited: Boolean = False;
  FileDefault: Integer = 0;
  HelpDefault: Integer = 0;

function ExecuteMenu: Word;

implementation

uses Objects, Drivers, Views, App, HistList, History, UserScr, HeapUMB,
  TPString, Consts, Commands, Defaults;

function GetMenuItem(Command: Word): PMenuItem;
var
  SubMenu: PMenu;
  BigItem, Item: PMenuItem;
  Found: Boolean;
begin
  GetMenuItem := nil;
  Found := False;
  with MenuBar^.Menu^ do
  begin
    BigItem := Items;
    while not Found and (BigItem <> nil) do
    begin
      SubMenu := BigItem^.SubMenu;
      Item := SubMenu^.Items;
      while not Found and (Item <> nil) do
      begin
	Found := Item^.Command = Command;
	if not Found then Item := Item^.Next;
      end;
      BigItem := BigItem^.Next;
    end;
  end;
  if Found then GetMenuItem := Item;
end;

procedure CheckToggleItem(Command: Word; Flag: Boolean);
var
  P: PMenuItem;
begin
  P := GetMenuItem(Command);
  if P <> nil then
    if Flag then P^.Param^ := 'Yes' else P^.Param^ := ' No';
end;

procedure SetMultiClipItems;
var
  P: PMenuItem;
  S: String[15];
begin
  if MultitaskerDetected then S := 'MS Windows'
  else S := 'additional';
  P := GetMenuItem(cmCopyToMT);
  if P <> nil then
  begin
    Move(S[1], P^.Name^[11], Length(S));
    if MultitaskerDetected then P^.HelpCtx := hcECopyToWinClip
    else P^.HelpCtx := hcECopyToAddClip;
  end;
  P := GetMenuItem(cmPasteFromMT);
  if P <> nil then
  begin
    Move(S[1], P^.Name^[14], Length(S));
    if MultitaskerDetected then P^.HelpCtx := hcEPasteFromWinClip
    else P^.HelpCtx := hcEPasteFromAddClip;
  end;
end;

const
  TempHelpHistoryID = 199;

procedure FillTempHelpHistory(var Count: Integer);
var
  First, Lock: Boolean;
  C, I: Integer;
  P, R: PHistoryRec;
label
  Scan;
begin
  First := True;
  Count := 0;
  C := HistoryCount(HelpHistoryID);
  if C <> 0 then
  begin
Scan:
    for I := C - 1 downto 0 do
    begin
      R := HistoryRec(HelpHistoryID, I);
      Lock := Byte(R^.Lock) <> 0;
      if (R <> nil) and	(Lock <> First) then
      begin
{
	GetMem(P, SizeOf(THistoryRec));
	P^.StrPtr := NewStr(R^.StrPtr^);
}
	GetMemUMB(P, SizeOf(THistoryRec));
	P^.StrPtr := NewStrUMB(R^.StrPtr^);
	P^.Id := TempHelpHistoryID;
	Byte(P^.Lock) := I;
	HistoryList^.Insert(P);
	Inc(Count);
      end;
    end;
    if First then
    begin
      First := False;
      Goto Scan;
    end;
  end;
end;

function ExecuteMenu: Word;
var
  B: Byte;
  FileCount, HelpCount, MaxCount, I: Integer;
  Item, NextItem, QuitItem, AltHelpItem: PMenuItem;
  FileSubMenu, HelpSubMenu: PMenu;
  R: PHistoryRec;
  S: String;
begin
  CheckToggleItem(cmOpenCPUWindow, OpenCPUWindow);
  CheckToggleItem(cmSaveClipData, SaveClipboardData);
  CheckToggleItem(cmToggleMarkMode, MarkColumns);
  CheckToggleItem(cmToggleEGALines, EGALinesOn);
  SetMultiClipItems;
  AltHelpItem := GetMenuItem(cmAltHelpName);
  if AltHelpName <> '' then
    AltHelpItem^.Param := NewStr(JustFileName(AltHelpName));
  with MenuBar^ do
  begin
    FileSubMenu := Menu^.Items^.Next^.SubMenu;
    FileCount := HistoryCount(ReopenHistoryID);
    if FileCount <> 0 then
    begin
      if ScreenHeight > 25 then MaxCount := 9 else MaxCount := 7;
      if FileCount > MaxCount then FileCount := MaxCount;
      if FileDefault > FileCount then FileDefault := FileCount;
      QuitItem := GetMenuItem(cmQuit);
      Item := nil;
      for I := FileCount - 1 downto 0 do
      begin
	S := HistoryStr(ReopenHistoryID, I);
	S[0] := Char(Pos(#$FF, S) - 1);
	Item := NewItem('~' + Char(I + $31) + '~. ' +
	  Copy(S, 1, 6) + TrimmedName(Copy(S, 7, 255), 29),
	  '', kbNoKey, cmReopen + I, hcReopen, Item);
	if I + 1 = FileDefault then FileSubMenu^.Default := Item;
      end;
      Item := NewLine(Item);
      QuitItem^.Next := Item;
    end
    else if FileDefault <> 0 then
      FileSubMenu^.Default := FileSubMenu^.Items;
    HelpSubMenu := Menu^.Items^.Next^.Next^.Next^.Next^.Next^.Next^.Next^.Next^.Next^.SubMenu;
    FillTempHelpHistory(MaxCount);
    if MaxCount <> 0 then
    begin
      HelpCount := MaxCount;
      if HelpCount > 9 then HelpCount := 9;
      if HelpDefault > HelpCount then HelpDefault := HelpCount;
      Item := nil;
      for I := HelpCount - 1 downto 0 do
      begin
	R := HistoryRec(TempHelpHistoryID, I);
	S := R^.StrPtr^;
	B := Pos(#$FF, S) - 1;
	if B = 0 then
	begin
	  Delete(S, 1, 1);
	  S := TrimmedName(Copy(S, 1, Pos(#$FF, S) - 1), 35);
	end
	else S[0] := Char(Pos(#$FF, S) - 1);
	Item := NewItem('~' + Char(I + $31) + '~. ' + S,
	  '', kbNoKey, cmReopenHelp + Byte(R^.Lock), hcReopenHelp, Item);
	if I + 1 = HelpDefault then HelpSubMenu^.Default := Item;
      end;
      ClearHistoryId(TempHelpHistoryID);
      Item := NewLine(Item);
      AltHelpItem^.Next := Item;
    end
    else if HelpDefault <> 0 then
      HelpSubMenu^.Default := HelpSubMenu^.Items;
    if HideOptions and hvMenuBar <> 0 then Show;
    ExecMenuInherited := True;
    ExecuteMenu := Execute;
    ExecMenuInherited := False;
    if HideOptions and hvMenuBar <> 0 then Hide;
    FileDefault := 0;
    if FileCount <> 0 then
    begin
      Item := QuitItem^.Next;
      while Item <> nil do
      begin
	DisposeStr(Item^.Name);
	NextItem := Item^.Next;
	Dispose(Item);
	Item := NextItem;
	if Item = FileSubMenu^.Default then
	  FileDefault := Item^.Command - cmReopen + 1;
      end;
      QuitItem^.Next := nil;
    end;
    HelpDefault := 0;
    if HelpCount <> 0 then
    begin
      I := 0;
      Item := AltHelpItem^.Next;
      while Item <> nil do
      begin
	DisposeStr(Item^.Name);
	NextItem := Item^.Next;
	Dispose(Item);
	Item := NextItem;
	Inc(I);
	if Item = HelpSubMenu^.Default then HelpDefault := I;
      end;
      AltHelpItem^.Next := nil;
    end;
  end;
  if AltHelpName <> '' then
  begin
    DisposeStr(AltHelpItem^.Param);
    AltHelpItem^.Param := nil;
  end;
end;

end.