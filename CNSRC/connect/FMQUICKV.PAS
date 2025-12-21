{$F+,O+,X+}
unit FMQuickV;

interface

uses Objects, FileMngr;

procedure QuickViewPrim(FManager: PPanel);
procedure UpdateTextReaderPrim(FManager: PPanel; var Item: Integer);
procedure TextReaderGoTopPrim(FManager: PPanel);
procedure TextReaderGoBottomPrim(FManager: PPanel);

implementation

uses Dos, Drivers, Views, App, PanelRec, DiskPrim, ExecPrim,
  FMAbort, FMAction, ArcV, TextRead, ExeView, DataView, Tags,
  HeapUMB, Keyboard, DosTools, LFN, RevPos, TPString, Defaults;

procedure AddPipe(var S: String; APos: Byte);
begin
  Insert('|', S, APos);
  Inc(S[0]);
  S[Length(S)] := '|';
end;

procedure QuickViewDirPrim(FManager: PPanel;
  SR: PPanelRec; var S: FNameStr);
var
  NumF,	NumSel, NumSD: Longint;
  NumS_, NumB_, SelS_, SelB_: Longint;
  NumS, NumB, SelS, SelB, Cmpr, SelC: Real;
  DS, FS, BS, TS, TB, CmprS, TaggedCmprS, SDS: FNameStr;
begin
  with FManager^ do
  begin
    if Opposite^.InArchive then
      if (SR^.Attr and VolumeID <> 0) and
	 (SR^.Name[1] <> '.') then
      begin
	S := '';
	Exit;
      end
      else
      begin
	Opposite^.Archiver^.GetDirInfo(S, NumF, NumS_, NumB_,
	  NumSel, SelS_, SelB_, NumSD, TagList^.Count <> 0);
	NumS := NumS_;
	NumB := NumB_;
	SelS := SelS_;
	SelB := SelB_;
	Cmpr := 0;
	SelC := 0;
      end
    else GetDirInfo(S, NumF, NumSel, NumSD, NumS, NumB, SelS, SelB, Cmpr, SelC,
      TagList^.Count <> 0, Opposite^.Settings and seList = 0, True);
    GetDirViewLines(FManager^.Opposite, FManager^.Size.X - 18, S,
      NumF, NumSel, NumSD, NumS, NumB, SelS, SelB, Cmpr, SelC,
      DS, FS, BS, TS, TB, CmprS, TaggedCmprS, SDS);
    AddPipe(DS, 15);
    AddPipe(FS, 15);
    AddPipe(BS, 15);
    if CmprS <> '' then AddPipe(CmprS, 15);
    AddPipe(SDS, 15);
    if TagList^.Count <> 0 then
    begin
      AddPipe(TS, 15);
      AddPipe(TB, 15);
      if TaggedCmprS <> '' then AddPipe(TaggedCmprS, 15);
    end;
    Dirinfo^.Insert(nil);
    Dirinfo^.Insert(nil);
{
    Dirinfo^.Insert(NewStr('  ' + DS));
    Dirinfo^.Insert(NewStr('  ' + FS));
    Dirinfo^.Insert(NewStr('  ' + BS));
    if CmprS <> '' then Dirinfo^.Insert(NewStrUMB('  ' + CmprS));
    Dirinfo^.Insert(NewStr('  ' + SDS));
    if TagList^.Count <> 0 then
    begin
      Dirinfo^.Insert(nil);
      Dirinfo^.Insert(NewStr('  ' + TS));
      Dirinfo^.Insert(NewStr('  ' + TB));
      if TaggedCmprS <> '' then Dirinfo^.Insert(NewStr('  ' + TaggedCmprS));
    end;
}
    Dirinfo^.Insert(NewStrUMB('  ' + DS));
    Dirinfo^.Insert(NewStrUMB('  ' + FS));
    Dirinfo^.Insert(NewStrUMB('  ' + BS));
    if CmprS <> '' then Dirinfo^.Insert(NewStrUMB('  ' + CmprS));
    Dirinfo^.Insert(NewStrUMB('  ' + SDS));
    if TagList^.Count <> 0 then
    begin
      Dirinfo^.Insert(nil);
      Dirinfo^.Insert(NewStrUMB('  ' + TS));
      Dirinfo^.Insert(NewStrUMB('  ' + TB));
      if TaggedCmprS <> '' then Dirinfo^.Insert(NewStrUMB('  ' + TaggedCmprS));
    end;
    QuickStatus := qsColor;
    S := '';
  end;
end;

(* Removed 05.24.99
procedure QuickViewArcFilePrim(FManager: PPanel;
  SR: PPanelRec; var S: FNameStr);
begin
  with FManager^ do
  begin
    Dirinfo^.Insert(nil);
    Dirinfo^.Insert(nil);
{    Dirinfo^.Insert(NewStr('  Press |F3| to view.'));}
    Dirinfo^.Insert(NewStrUMB('  Press |F3| to view.'));
    QuickStatus := qsColor;
  end;
  S := '';
end;
*)

procedure QuickArchiveLine(ALine: FNameStr; Time, OrgSize, Size: Longint);
begin
  if (KbdStatus = 1) and FMAbortAction then ArcEnd := True;
{  PCollection(ArchiveInfoPtr)^.Insert(NewStr(ALine));}
  PCollection(ArchiveInfoPtr)^.Insert(NewStrUMB(ALine));
end;

function QuickArchiveReadPrim(FManager: PPanel; const S: FNameStr): Boolean;
var
  B: Boolean;
  Id, Status: Byte;
  SR: SearchRec;
begin
  ArchiveLineProc := QuickArchiveLine;
  ArchiveCommentList := nil;
  ArchiveInfoPtr := FManager^.Dirinfo;
  ReadArchive(S, Id, SR, Status);
  B := Status in [arcOk, arcBroken];
  if Status = arcBroken then
  begin
    FManager^.Dirinfo^.Insert(nil);
{    FManager^.Dirinfo^.Insert(NewStr('Error reading the archive.'));}
    FManager^.Dirinfo^.Insert(NewStrUMB('Error reading the archive.'));
  end;
  if B then FManager^.QuickStatus := qsPercent;
  QuickArchiveReadPrim := B;
end;

function QuickExeReadPrim(FManager: PPanel; const S: FNameStr): Boolean;
var
  B: Boolean;
begin
  B := GetExeInfo(S, FManager^.Dirinfo);
  if B then FManager^.QuickStatus := qsColor;
  QuickExeReadPrim := B;
end;

function QuickDbfReadPrim(FManager: PPanel; const S: FNameStr): Boolean;
var
  B: Boolean;
begin
  B := GetDbfInfo(S, FManager^.Dirinfo);
  if B then FManager^.QuickStatus := qsColor;
  QuickDbfReadPrim := B;
end;

function QuickViewExtPrim(FManager: PPanel; var S: FNameStr): Boolean;
var
  B: Boolean;
  Key: Word;
  I: Integer;
  P: PString;
  C: String;
  F: Text;
begin
  ExecRec.Params := '';
  ExecRec.Options := 0;
  if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then Key := 2
  else if GetShiftState and kbAltShift <> 0 then Key := 1
  else Key := 0;
  Byte(B) := 2;
  if ExtractExecRec(ExecRec, S, Key, B) then
  begin
    ExecRec.Options := ExecRec.Options or opNoReread;
    C := ExecRec.Path;
    Key := Pos(' ', C);
    if Key <> 0 then C[0] := Char(Key - 1);
    with FManager^ do
    begin
      Dirinfo^.Insert(nil);
{
      Dirinfo^.Insert(NewStr(
	' Quick viewer associated with |' + JustFileName(S) + '|:'));
      Dirinfo^.Insert(nil);
      Dirinfo^.Insert(NewStr(' |' + C + '|'));
}
      Dirinfo^.Insert(NewStrUMB(
	' Quick viewer associated with |' + JustFileName(S) + '|:'));
      Dirinfo^.Insert(nil);
      Dirinfo^.Insert(NewStrUMB(' |' + C + '|'));
      QuickStatus := qsColor;
      S := ReportFile;
      Assign(F, S);
      Rewrite(F);
      if IOResult = 0 then for I := 0 to Dirinfo^.Count - 1 do
      begin
	P := Dirinfo^.At(I);
	if P = nil then Writeln(F) else Writeln(F, DelChar('|', P^));
      end;
      Close(F);
      InOutRes := 0;
    end;
    PrepareExecEvent;
    Application^.HandleEvent(Pending);
    QuickViewExtPrim := True;
  end
  else
  begin
    if FManager^.Opposite^.InArchive then
       FManager^.Opposite^.GetSource(S);
    QuickViewExtPrim := False;
  end;
end;

procedure QuickViewFilePrim(FManager: PPanel;
  SR: PPanelRec; var S: FNameStr);
begin
  with FManager^ do
    if QuickViewExtPrim(FManager, S) then {}
    else if QuickArchiveReadPrim(FManager, S) or
      QuickExeReadPrim(FManager, S) or
      ((CompUCString(SR^.Ext, 'DBF') = Equal) and
	QuickDbfReadPrim(FManager, S)) then S := '';
end;

procedure QuickViewPrim(FManager: PPanel);
var
  SR: PPanelRec;
  S: FNameStr;
begin
  with FManager^ do
  begin
    QuickStatus := 0;
    SR := Opposite^.List^.At(Opposite^.Focused);
    if SR <> nil then
    begin
      Opposite^.GetRecStr(SR, S);
      if SR^.Attr and Directory <> 0 then
	QuickViewDirPrim(FManager, SR, S)
      else QuickViewFilePrim(FManager, SR, S);
    end
    else S := '';
    if S <> '' then
    begin
      S := lFExpand(S);
      QuickStatus := qsPercent;
    end;
    TextReader^.NewSourceName(S);
    TextReader^.DoneSource;
    TextReader^.NewBuffer(Dirinfo);
    TextReader^.InitSource;
    UpdateDirinfoRanges;
    FocusItem(0);
    PWindow(Owner)^.Frame^.DrawView;
  end;
end;

procedure UpdateTextReaderPrim(FManager: PPanel; var Item: Integer);
var
  B: Boolean;
  I: Integer;
begin
  with FManager^ do
  begin
    if TextReader^.SourceSize = -1 then Exit;
    B := False;
    if State and sfMiniStatus <> 0 then I := Size.Y - 3
    else I := Size.Y - 1;
    if Item + I >= Range then
      if TextReader^.BufEnd < TextReader^.SourceSize then
      begin
	I := TopItem;
	TextReader^.ReadDown(I);
	Dec(Item, TopItem);
	B := True;
      end else
    else if (Item < 0) and (TextReader^.BufOrg <> 0) then
    begin
      TextReader^.ReadUp(I);
      Inc(Item, I);
      B := True;
    end;
    if B then UpdateDirinfoRanges;
  end;
end;

procedure TextReaderGoTopPrim(FManager: PPanel);
begin
  with FManager^ do
  begin
    if TextReader^.BufOrg <> 0 then
    begin
      TextReader^.FillBuffer(0);
      UpdateDirinfoRanges;
    end;
    FocusItem(0);
  end;
end;

procedure TextReaderGoBottomPrim(FManager: PPanel);
var
  I: Integer;
begin
  with FManager^ do
  begin
    if TextReader^.BufEnd < TextReader^.SourceSize then
    begin
      TextReader^.ReadLastPortion;
      UpdateDirinfoRanges;
    end;
    if State and sfMiniStatus <> 0 then I := Size.Y - 2
    else I := Size.Y;
    if Focused + I <= Range then FocusItem(Range - I);
  end;
end;

end.
