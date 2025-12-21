{$I-,F+,O+,X+}
unit Archives;

interface

uses Dos, Objects, Dialogs, StrCol, PanelRec, ArcRec, LFN;

type
  TParamStr = String[255];

  PNameList = ^TNameList;
  TNameList = object(TStringsCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PArchiver = ^TArchiver;
  TArchiver = object(TObject)
    Owner: Pointer;
    Prev: PArchiver;
    ArcId: Byte;
    ArcRec: SearchRec;
    ArcName: PString;
    DosName: PString;
    UserListName: PString;
    ArcDir: PString;
    Password: PString;
    ExtractedNames: PCollection;
    ArchiveRec: PArchiveRec;
    Status: Byte;
    Secondary: Boolean;
    AtLeastOneHidden: Boolean;
    UserArcId: Byte; { Added 2004.12.09 }
    constructor Init(AOwner: Pointer);
    destructor Done; virtual;
    function CheckPassword(Attr: Byte): Boolean;
    procedure CopyPrim(const ToName, Mask: FNameStr; Single: Boolean);
    procedure DeletePrim(Single: Boolean);
    function ExtractItem(SR: PPanelRec; const Name: FNameStr): Boolean;
    function ExtractByName(const Name: FNameStr): PString;
    procedure ExtractPrim;
    procedure GetArchiveRec;
    function GetDirInfo(const ADir: FNameStr;
      var NumFiles, FilesSize, NumBytes,
      NumTagged, TaggedSize, TaggedBytes,
      NumSubDirs: Longint; CalcTagged: Boolean): Boolean;
    procedure GetDownOrUpName(Down: Boolean; var NewName: FNameStr);
    function GetExtension: String;
    function GetTopArchiver: PArchiver;
    function GetTopName: FNameStr;
    procedure InsertExtractedName(const Name: FNameStr);
    procedure InsertItem(SR: SearchRec; Percent, Info: Byte;
      const Path: FNameStr);
    procedure NewArcDir(const Name: FNameStr);
    procedure NewArchive(const Name, DName: FNameStr);
    procedure PrepareExecRec;
    procedure PrepareParams(SR: PPanelRec; var Params: TParamStr;
      const Mask: FNameStr; Single: Boolean; var PasswordNeeded: Boolean);
    procedure PrepareSource(var S: FNameStr);
    procedure RunPrim(PName, PAction: PString; const ADir, Mask: FNameStr;
      CheckVolume, CheckPsw, Single, SwapScreen: Boolean);
    procedure SaveSelected(TextPtr: Pointer; const Mask, Fmt: FNameStr;
      var PasswordNeeded: Boolean);
    procedure SaveSubFiles(TextPtr: Pointer; const Mask, Fmt: FNameStr;
      var PasswordNeeded: Boolean);
    procedure SetFieldsForDots(var SR: lSearchRec);
    procedure SetItemPathName(SR: PPanelRec; var S: FNameStr);
    procedure SetPassword;
    procedure TestPrim;
  end;

  PPasswordInput = ^TPasswordInput;
  TPasswordInput = object(TInputLine)
    procedure Draw; virtual;
  end;

var
  TheArchiver: PArchiver;

function OverwriteArcMsgBox(const Name: FNameStr): Word;
procedure ProcessFmt(const Fmt: FNameStr; var S: FNameStr);
procedure NewArchiverPrim(FManager: Pointer);
procedure ScanArchivePrim(FManager: Pointer; NoDone: Boolean);
procedure ReadArchivePrim(FManager: Pointer; UnfoldSel: Boolean);
procedure ReadArchiveTreePrim(FManager: Pointer);
procedure IntoArchive(FManager: Pointer; const Name: FNameStr; Info: Byte);
procedure OutOfArchive(FManager: Pointer);
procedure GetArchiveRec(const Dest: FNameStr; var P: PArchiveRec);
procedure PreparePassword(P: PArchiveRec; var Params: TParamStr);
procedure RunPacker(P: PArchiveRec);
procedure CopyToArchive(FManager: Pointer; Single, RenMov: Boolean;
  const Dest, Mask: FNameStr; CustomRec: Pointer);
procedure ClipboardToArchive(RenMov: Boolean; const Dest: FNameStr);
procedure ReadUserArchive(const Name: FNameStr; var Id: Byte;
  ForceList, Info, FF: Boolean; var Status: Byte);
function UserArchiveEnabled(P: PUserArchiveRec): Boolean;

implementation

uses Drivers, Views, App, MsgBox, StdDlg, HistList, FileMngr, ArcV, DirPrim,
  DiskPrim, DirTree, Trees, Swaps, ClipPrim, ProgList, ExecPrim, Compiler,
  FMAbort, FMAction, EnvDlg, Tags, HeapUMB, DosTools, History, Keyboard,
  TPString, Consts, Commands, Defaults;

type
  PArcSizeInfo = ^TArcSizeInfo;
  TArcSizeInfo = record
    ArcName: PString;
    Name: PString;
    NumFiles: Longint;
    PackedSize: Longint;
    TotalSize: Longint;
    NumTagged: Longint;
    TaggedSize: Longint;
    TaggedBytes: Longint;
    NumSubDirs: Longint;
  end;

  PSaveSelInfo = ^TSaveSelInfo;
  TSaveSelInfo = record
    Panel: PPanel;
    TextFile: ^Text;
    FlagPtr: ^Boolean;
    ClearSlash: Boolean;
    Optimized: Boolean;
    FilesOnly: Boolean;
    Mask: PString;
    Fmt: PString;
    Info: Byte;
  end;

  PSaveSubInfo = ^TSaveSubInfo;
  TSaveSubInfo = record
    ArcName: PString;
    Name: PString;
    TextFile: ^Text;
    FlagPtr: ^Boolean;
    ClearSlash: Boolean;
    Mask: PString;
    Fmt: PString;
  end;

const
  Extracting: Boolean = False;
  AddLeadingSlash: Boolean = False;
  ArcUnfoldSel: Boolean = False;

function OverwriteArcMsgBox(const Name: FNameStr): Word;
begin
  OverwriteArcMsgBox := MessageBox(^C'Archive file'#13^C'|' + Name +
    '|'#13^C'already exists. Overwrite ?', nil, mfConfirmation + mfOkCancel);
end;

procedure CannotExecMessageBox;
begin
  MessageBox(
    ^C'Cannot execute this command while running or debugging user program.',
    nil, mfInformation + mfOkButton);
end;

procedure ExecPending;
var
  Event: TEvent;
begin
  Event := Pending;
  Pending.What := evNothing;
  if StackOverflow then Exit;
  Extracting := True;
  Application^.HandleEvent(Event);
  Extracting := False;
end;

function ArcFileExists(const FileName: String; Time, Size: Longint): Boolean;
var
  SR: lSearchRec;
begin
  lFindFirst(FileName, AnyFile and not (Directory + VolumeID), SR);
  lFindClose(SR);
  ArcFileExists := (DosError = 0) and (SR.SR.Attr and Directory = 0) and
    (Time = SR.SR.Time) and (Size = SR.SR.Size);
end;

function PasswordDialog: PDialog;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 56, 7);
  D := New(PDialog, Init(R, 'Archive password'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcArcPassword;
    R.Assign(12, 2, Size.X - 3, 3);
    Control := New(PPasswordInput, Init(R, 39));
    Insert(Control);
    R.Assign(2, 2, 12, 3);
    Insert(New(PLabel, Init(R, '~P~assword', Control)));
    R.Assign(11, Size.Y - 3, 21, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  PasswordDialog := D;
end;

procedure CheckLeadingSlash(var Params: TParamStr);
var
  I: Integer;
begin
  AddLeadingSlash := False;
  I := Pos(' \', Params);
  if (I = 0) or
     ((Length(Params) >= I + 2) and (Params[I + 2] <> ' ')) then Exit;
  System.Delete(Params, I, 2);
  AddLeadingSlash := True;
end;

procedure AddSource(const Directive: String; Source: FNameStr;
  UseLeadingSlash: Boolean; var Params: TParamStr);
var
  B: Byte;
begin
  if UseLeadingSlash then Source := '\' + Source;
  if Pos(' ', Source) <> 0 then Source := '"' + Source + '"';
  B := UCPos(Directive, Params);
  if B = 0 then
    if Params = '' then Params := Source
    else Params := Params + ' ' + Source
  else
  begin
    System.Delete(Params, B, Length(Directive));
    System.Insert(Source, Params, B);
  end;
end;

procedure SaveExecRec(var R: TExecRec; var M: Boolean);
begin
  R := ExecRec;
  M := MultiExec;
end;

procedure RestoreExecRec(R: TExecRec; M: Boolean);
begin
  ExecRec := R;
  MultiExec := M;
end;

function SearchForFmt(var Params: TParamStr; var Fmt: FNameStr): Byte;
var
  B, C: Byte;
begin
  Fmt := '';
  B := UCPos('$FMT(', Params);
  if B <> 0 then
  begin
    C := B + 4;
    while (C < Length(Params)) and (Params[C + 1] <> ')') do Inc(C);
    Fmt := System.Copy(Params, B + 5, C - B - 4);
    System.Delete(Params, B, C - B + 3);
  end;
  SearchForFmt := B;
end;

procedure ProcessFmt(const Fmt: FNameStr; var S: FNameStr);
var
  B: Byte;
  C: FNameStr;
begin
  if Fmt = '' then Exit;
  C := Fmt;
  B := UCPos('$FILE', C);
  if B <> 0 then
  begin
    System.Delete(C, B, 5);
    System.Insert(S, C, B);
  end;
  S := C;
end;

function SingleFmt(const Source: FNameStr; var Params: TParamStr): Boolean;
var
  B: Byte;
  S, Fmt: FNameStr;
begin
  SingleFmt := False;
  B := SearchForFmt(Params, Fmt);
  if B = 0 then Exit;
  S := Source;
  ProcessFmt(Fmt, S);
  System.Insert(S, Params, B);
  SingleFmt := True;
end;

function UserArchiveEnabled(P: PUserArchiveRec): Boolean;
begin
  UserArchiveEnabled := (P^.EnvCondition = nil) or
    ConditionOk(P^.EnvCondition^);
end;

procedure NewArchiveItem(ALine: FNameStr; Time, OrgSize, Size: Longint);
var
  Long: Boolean;
  Percent, Info: Byte;
  B, E, I: Integer;
  SR: SearchRec;
  S, Path: FNameStr;

procedure NameFilter;
begin
  if not WildCardMatch(SR.Name, PPanel(TheArchiver^.Owner)^.Filter) then
    SR.Name := '';
end;

procedure ExecFilter;
var
  I: Integer;
begin
  I := Pos('.', SR.Name);
  if I <> 0 then S := StUpcase(System.Copy(SR.Name, I + 1, 3));
  if (I = 0) or
    not ((S = 'BAT') or (S = 'COM') or (S = 'EXE')) then SR.Name := '';
end;

procedure SetItemName;
begin
  SR.Name := '';
  S := TheArchiver^.ArcName^ + ALine;
  Path := TheArchiver^.ArcDir^ + '\';
  if UCPos(Path, S) = 0 then Exit;
  B := Length(Path) + 1;
  if PPanel(TheArchiver^.Owner)^.Settings and seUnfold <> 0 then
  begin
    if ArcUnfoldSel and (TagList^.Count <> 0) then
    begin
      E := B;
      while (E <= Length(S)) and (S[E] <> '\') do Inc(E);
      if E > Length(S) then Exit;
      Path := System.Copy(S, 1, E - 1);
      if not TagList^.NameFound(Path) then Exit;
    end;
    E := Length(S);
    while (E > B) and (S[E] <> '\') do Dec(E);
    if S[E] = '\' then Inc(E);
    SetSearchRecName(System.Copy(S, E, 255), SR, Long);
    if Long then Path := #0 + System.Copy(S, B, 255)
    else Path := System.Copy(S, B, E - B - Byte(E <> B));
  end
  else
  begin
    E := B;
    while (E <= Length(S)) and (S[E] <> '\') do Inc(E);
    if E <= Length(S) then SR.Attr := SR.Attr or Directory;
    SetSearchRecName(System.Copy(S, B, E - B), SR, Long);
    if Long then Path := #0 + System.Copy(S, B, E - B)
    else Path := '';
  end;
  if SR.Name = '' then Exit;
  if SR.Attr and Directory <> 0 then
    if PPanel(TheArchiver^.Owner)^.UseFilter and
       PPanel(TheArchiver^.Owner)^.AdvancedFilter.UseForLists and
      (PPanel(TheArchiver^.Owner)^.AdvancedFilter.Attr <> AnyFile) and
      (PPanel(TheArchiver^.Owner)^.AdvancedFilter.Attr and Directory = 0) then
        SR.Name := '' else
  else if PPanel(TheArchiver^.Owner)^.State and sfExOnly <> 0 then ExecFilter
  else if PPanel(TheArchiver^.Owner)^.Filter <> '*.*' then NameFilter;
  if PPanel(TheArchiver^.Owner)^.UseFilter and
     PPanel(TheArchiver^.Owner)^.AdvancedFilter.UseForLists and
    (SR.Name <> '') then
  begin
    SR.Time := Time;
    SR.Size := OrgSize;
    if not AdvancedFilterPassed(@PPanel(TheArchiver^.Owner)^.AdvancedFilter,
      PPanel(TheArchiver^.Owner)^.UnixStates, SR, '') then SR.Name := '';
  end;
end;

function IncItemSize: Boolean;
var
  P: PPanelRec;
begin
  IncItemSize := False;
  I := 0;
  with PPanel(TheArchiver^.Owner)^ do
  begin
    FindByName(SR.Name, I);
    if I = -1 then Exit;
    P := List^.At(I);
    Inc(P^.Size, OrgSize);
    List^.AtDelete(I);
    List^.Insert(P);
  end;
  IncItemSize := True;
end;

begin
  if (KbdStatus = 1) and FMAbortAction then ArcEnd := True;
  if ALine = '' then Exit;
  Info := 0;
  if TPString.Upcase(ALine[1]) in ['D', 'U'] then
  begin
    if TheArchiver^.ArcDir^ <> TheArchiver^.ArcName^ then Exit;
    if TPString.Upcase(ALine[1]) = 'D' then SR.Name := 'Next.Vol'
    else SR.Name := 'Previous.Vol';
    SR.Time := $210000;
    SR.Size := 0;
    SR.Attr := VolumeID + Directory;
    Path := '';
  end
  else
  begin
    if ALine[1] = '*' then
    begin
      SR.Attr := Hidden;
      TheArchiver^.AtLeastOneHidden := True;
    end
    else SR.Attr := Archive;
    ALine[1] := '\';
    if (Length(ALine) >= 3) and (ALine[2] = '.') and (ALine[3] = '\') then
    begin
      Info := piPathPrefix;
      Delete(ALine, 2, 2);
    end;
    SetItemName;
    if SR.Name = '' then Exit;
    if SR.Attr and Directory <> 0 then
    begin
      SR.Time := $210000;
      SR.Size := 0;
      if PPanel(TheArchiver^.Owner)^.Settings and seCalcDirSize <> 0 then
      begin
        SR.Size := OrgSize;
        if IncItemSize then Exit;
      end;
    end
    else
    begin
      SR.Time := Time;
      SR.Size := OrgSize;
      if OrgSize = 0 then Percent := 0
      else Percent := Round(Size * 100 / OrgSize);
    end;
  end;
  TheArchiver^.InsertItem(SR, Percent, Info, Path);
end;

procedure ArchiveDirInfo(ALine: FNameStr; Time, OrgSize, Size: Longint);
var
  B: Byte;
  S: FNameStr;
begin
  if (KbdStatus = 1) and FMAbortAction then ArcEnd := True;
  if ALine = '' then Exit;
  if (TPString.Upcase(ALine[1]) in ['D', 'U']) or
     (ALine[Length(ALine)] = '\') then
  begin
    with PArcSizeInfo(ArchiveInfoPtr)^ do Inc(NumSubDirs);
    Exit;
  end;
  ALine[1] := '\';
  if (Length(ALine) >= 3) and (ALine[2] = '.') and (ALine[3] = '\') then
    Delete(ALine, 2, 2);
  with PArcSizeInfo(ArchiveInfoPtr)^ do
    if (Name = nil) or (UCPos(Name^, ALine) = 1) then
    begin
      Inc(NumFiles);
      Inc(PackedSize, Size);
      Inc(TotalSize, OrgSize);
      if TagList^.Count <> 0 then
      begin
        S := ArcName^ + ALine;
        B := Length(S);
        while S[B] <> '\' do Dec(B);
        S := Concat(Copy(S, 1, B), Copy(S, B + 1, 255));
        repeat
          if TagList^.NameFound(S) then
          begin
            Inc(NumTagged);
            Inc(TaggedSize, Size);
            Inc(TaggedBytes, OrgSize);
            Break;
          end;
          S := PrevDir(S);
        until Length(S) <= Length(ArcName^);
      end;
    end;
end;

procedure NewArchiveTreeItem(ALine: FNameStr; Time, OrgSize, Size: Longint);
var
  OutOfMem: Boolean;
begin
  if (KbdStatus = 1) and FMAbortAction then ArcEnd := True;
  if (ALine = '') or (TPString.Upcase(ALine[1]) in ['D', 'U']) or
     (Pos('\', ALine) = 0) then Exit;
  ALine[1] := '\';
  if (Length(ALine) >= 3) and (ALine[2] = '.') and (ALine[3] = '\') then
    Delete(ALine, 2, 2);
  if ALine[Length(ALine)] = '\' then ALine := ALine + '1';
  with PPanel(ArchiveInfoPtr)^ do
  begin
    AddDirToTreePrim(
      JustPathName(Concat(Archiver^.ArcName^, CRCShortName(ALine))),
      JustPathName(Concat(Archiver^.ArcName^, ALine)), TheTree, OutOfMem);
    if OutOfMem then ArcEnd := True;
  end;
end;

procedure SearchForOptimized(P: PSaveSelInfo);
var
  I: Integer;
begin
  P^.Optimized := True;
  for I := 0 to P^.Panel^.List^.Count - 1 do
    if Byte(PPanelRec(P^.Panel^.List^.At(I))^.Selected) > 1 then Exit;
  P^.Optimized := False;
end;

procedure WriteSelItem(ALine: FNameStr; Time, OrgSize, Size: Longint);
var
  B: Boolean;
  D: Byte;
  SR: PPanelRec;
  S, SS: FNameStr;

function IsSel(P: PPanel): Boolean;
var
  I: Integer;
begin
  IsSel := True;
  for I := 0 to P^.List^.Count - 1 do
  begin
    SR := P^.List^.At(I);
    if SR^.Selected and not
       (PSaveSelInfo(ArchiveInfoPtr)^.Optimized and
       (Byte(SR^.Selected) = 1)) then
    begin
      P^.GetRecStr(SR, S);
      if SR^.Attr and Directory <> 0 then S := AddedSlash(S);
      if UCPos(S, SS) = 1 then Exit;
    end;
  end;
  IsSel := False;
end;

begin
  if (KbdStatus = 1) and FMAbortAction then ArcEnd := True;
  if (ALine = '') or (TPString.Upcase(ALine[1]) in ['D', 'U']) then Exit;
  B := ALine[1] = '*';
  ALine[1] := '\';
  if (Length(ALine) >= 3) and (ALine[2] = '.') and (ALine[3] = '\') then
  begin
    D := piPathPrefix;
    Delete(ALine, 2, 2);
  end
  else D := 0;
  with PSaveSelInfo(ArchiveInfoPtr)^ do
  begin
    SS := Panel^.Archiver^.ArcName^ + ALine;
    if FilesOnly or IsSel(Panel) then
    begin
      if ALine[Length(ALine)] <> '\' then
        if (Mask^ <> '') and
          not WildCardMatch(JustFileName(ALine), Mask^) then Exit else
      else if ClearSlash then Dec(ALine[0]);
      S := System.Copy(ALine, 2 - Byte(AddLeadingSlash), 255);
      if (Info and piPathPrefix <> 0) or
         (D and piPathPrefix <> 0) then S := '.\' + S;
      ProcessFmt(Fmt^, S);
      Writeln(TextFile^, S);
      if B then FlagPtr^ := True;
    end;
  end;
end;

procedure WriteSubItem(ALine: FNameStr; Time, OrgSize, Size: Longint);
var
  B: Boolean;
  D: Byte;
  S: FNameStr;
begin
  if (KbdStatus = 1) and FMAbortAction then ArcEnd := True;
  if (ALine = '') or (TPString.Upcase(ALine[1]) in ['D', 'U']) then Exit;
  B := ALine[1] = '*';
  ALine[1] := '\';
  if (Length(ALine) >= 3) and (ALine[2] = '.') and (ALine[3] = '\') then
  begin
    D := piPathPrefix;
    Delete(ALine, 2, 2);
  end
  else D := 0;
  with PSaveSubInfo(ArchiveInfoPtr)^ do
    if UCPos(Name^, ArcName^ + ALine) = 1 then
    begin
      if ALine[Length(ALine)] <> '\' then
        if (Mask^ <> '') and
          not WildCardMatch(JustFileName(ALine), Mask^) then Exit else
      else if ClearSlash then Dec(ALine[0]);
      S := System.Copy(ALine, 2 - Byte(AddLeadingSlash), 255);
      if D and piPathPrefix <> 0 then S := '.\' + S;
      ProcessFmt(Fmt^, S);
      Writeln(TextFile^, S);
      if B then FlagPtr^ := True;
    end;
end;

procedure SaveSelFilesOnly;
var
  I: Integer;
  SR: PPanelRec;
  S: String;
begin
  with PSaveSelInfo(ArchiveInfoPtr)^ do
    for I := 0 to Panel^.List^.Count - 1 do
    begin
      SR := Panel^.List^.At(I);
      if SR^.Selected and not
        (Optimized and (Byte(SR^.Selected) = 1)) then
      begin
        Panel^.GetRecStr(SR, S);
        S := ' ' + System.Copy(
          S, Length(Panel^.Archiver^.ArcName^) + 2, 255);
        if SR^.Attr = Hidden then S[1] := '*';
        Info := SR^.Info;
	ArchiveLineProc(S, 0, 0, 0);
      end;
    end;
end;

procedure NewArchiverPrim(FManager: Pointer);
var
  SR: PPanelRec;
  A: PArchiver;
  S, DS: PString;
begin
  with PPanel(FManager)^ do
  begin
    if (List^.Count = 0) or (Status >= stTree) then Exit;
    SR := List^.At(Focused);
    if SR^.Attr and $10 <> 0 then Exit;
    GetMem(S, SizeOf(String));
    GetMem(DS, SizeOf(String));
    GetRecStr(SR, S^);
    if InArchive then
    begin
      GetValidSwapDir(DS^, False);
      AddNameExt(DS^, SR, DS^);
    end
    else DS^ := '';
    A := New(PArchiver, Init(FManager));
    A^.NewArchive(S^, DS^);
    A^.Secondary := InArchive;
    if InArchive then A^.Prev := Archiver
    else InArchive := True;
    Archiver := A;
    if A^.Secondary and not ArcFileExists(DS^, SR^.Time, SR^.Size) then
    begin
      NewDir(ListDir^, A^.Prev^.ExtractItem(SR, DS^));
      if Archiver = A then Focused := 0;
    end
    else NewDir(ListDir^, True);
    FocusItem(Focused);
    FreeMem(DS, SizeOf(String));
    FreeMem(S, SizeOf(String));
  end;
end;

procedure ReadUserArchive(const Name: FNameStr; var Id: Byte;
  ForceList, Info, FF: Boolean; var Status: Byte);
var
  Found, Tree, AltCtrl, Multitasker: Boolean;
  B: Integer;
  L: Longint;
  PS: PString;
  P: PUserArchiveRec;
  XNames: PCollection;
  Stream: TDosStream;
  ArcDir, ListName, ListCommand: PString;
  S: String;

procedure ConcatListName;
var
  TempByte: Byte absolute $40:$40;
  TempWord: Word absolute $40:$6C;
begin
  ListName^ := ListName^ + 'UA' +
    HexB(TempByte) + HexW(TempWord) + '.LST';
end;

procedure CreateList;
var
  SaveMultiExec, Redir: Boolean;
  I: Integer;
  SaveOptions: Longint;
  SaveRec: TExecRec;
begin
  SaveExecRec(SaveRec, SaveMultiExec);
  TheArchiver^.PrepareExecRec;
  Redir := True;
  I := UCPos('$LST', ListCommand^);
  while I <> 0 do
  begin
    Redir := False;
    System.Delete(ListCommand^, I, 4);
    System.Insert(ListName^, ListCommand^, I);
    I := UCPos('$LST', ListCommand^);
  end;
  I := Pos(' ', ListCommand^);
  if I = 0 then I := 255;
  with ExecRec do
  begin
    Path := Trim(System.Copy(ListCommand^, 1, I));
    lGetShortFileName(TheArchiver^.DosName^, S);
    Params := Trim(System.Copy(ListCommand^, I, 255)) + ' ' + S;
    if UCPos('$ARC', Params) <> 0 then
    begin
      Dec(Params[0], Length(S) + 1);
      AddSource('$ARC', S, False, Params);
    end;
    if UCPos('$SRC', Params) <> 0 then
    begin
      S := AddedSlash(Copy(TheArchiver^.ArcDir^,
	Length(TheArchiver^.ArcName^) + 1, 255));
      AddSource('$SRC', S, False, Params);
    end;
    Options := Options or opNoReread;
    if Redir then
      if Options and opMessage = 0 then
	Options := Options or (opMessage + opNoMsgWin + opUserScr) else
    else Options := Options and not opMessage;
    if FF then Options := Options or (opNoMsgWin + opNoRedraw + opNoXfer);
  end;
  PrepareExecEvent;
  if not FF then PPanel(TheArchiver^.Owner)^.Owner^.Unlock;
  SaveOptions := FMOptions;
  FMOptions := FMOptions and not foDrawEmpty;
  S := ReportFile;
  ReportFile := ListName^;
  ExecPending;
  ReportFile := S;
  FMOptions := SaveOptions;
  RestoreExecRec(SaveRec, SaveMultiExec);
end;

procedure ProcessLine;
const
  IllegalChars =
    [';', ',', '=', '+', '<', '>', '*', '?', '|', '"', '[', ']'];
var
  C: Byte;
  Code: Integer;
  Size, Time: Longint;
  DT: DateTime;
  SS: String;

procedure UnquoteLine;
var
  I: Integer;
begin
  I := 2;
  while (I <= Length(S)) and (S[I] <> '"') do Inc(I);
  SS := Copy(S, I + 1, 255);
  S := Copy(S, 2, I - 2);
end;

procedure GetValue(var V: Word);
begin
  B := 1;
  while (B <= Length(SS)) and not (SS[B] in ['0'..'9']) do Inc(B);
  System.Delete(SS, 1, B - 1);
  B := 1;
  while (B <= Length(SS)) and (SS[B] in ['0'..'9']) do Inc(B);
  Val(System.Copy(SS, 1, B - 1), V, Code);
  System.Delete(SS, 1, B);
end;

procedure GetTimeAndSize;
begin
  B := 1;
  while (B <= Length(SS)) and not (SS[B] in ['0'..'9']) do Inc(B);
  System.Delete(SS, 1, B - 1);
  B := 1;
  while (B <= Length(SS)) and (SS[B] in ['0'..'9']) do Inc(B);
  Val(System.Copy(SS, 1, B - 1), Size, Code);
  System.Delete(SS, 1, B);

  GetValue(DT.Month);
  if (DT.Month < 1) or (DT.Month > 12) then Exit;
  GetValue(DT.Day);
  if (DT.Day < 1) or (DT.Day > 31) then Exit;
  GetValue(DT.Year);
  if DT.Year < 80 then Inc(DT.Year, 2000)
  else if DT.Year <= 99 then Inc(DT.Year, 1900);
  if (DT.Year < 1980) or (DT.Year > 2099) then Exit;
  GetValue(DT.Hour);
  if DT.Hour > 24 then Exit;
  GetValue(DT.Min);
  if DT.Min >= 60 then Exit;
  GetValue(DT.Sec);
  if DT.Sec >= 60 then Exit;
  PackTime(DT, Time);
end;

begin
  S := Detab(S, 8);
  if (S <> '') and (S[1] = '"') then UnquoteLine
  else
  begin
    B := Pos(' ', S);
    if B <> 0 then
    begin
      SS := System.Copy(S, B + 1, 255);
      S[0] := Char(B - 1);
    end
    else SS := '';
  end;
  if (S = '') or (S[1] = ':') or (S[1] in IllegalChars) then Exit;
  if S[1] in ['\', '/'] then System.Delete(S, 1, 1);
  S := '\' + S;
  for C := 2 to Length(S) do
    if S[C] in IllegalChars then
    begin
      S := '';
      Exit;
    end
    else if S[C] = '/' then S[C] := '\';
  if Tree then S[1] := ' '
  else if UCPos(ArcDir^, TheArchiver^.ArcName^ + S) = 0 then Exit;
  Time := $210000;
  Size := 0;
  if not Tree and (SS <> '') then GetTimeAndSize;
  ArchiveLineProc(S, Time, Size, Size);
end;

procedure ReadList;
var
  F: Text;
begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Reading the file list ' +
    TrimmedName(ListName^, 45) + '.');
  Assign(F, ListName^);
  Reset(F);
  if IOResult <> 0 then Exit;
  if not IsDevice(TextRec(F).Handle) then
  begin
    Tree := not FF and (PPanel(TheArchiver^.Owner)^.Status = stTree);
    ArcDir^ := TheArchiver^.ArcDir^ + '\';
    ArcEnd := False;
    while not Eof(F) and not ArcEnd do
    begin
      Readln(F, S);
      ProcessLine;
    end;
  end;
  Close(F);
  InOutRes := 0;
end;

function TradeMarkMatchesAltCtrl: Boolean;
begin
  TradeMarkMatchesAltCtrl := True;
  if Multitasker then
    if Pos('[32]', P^.TradeMark^) <> 0 then
      TradeMarkMatchesAltCtrl := False else
  else
    if Pos('[16]', P^.TradeMark^) <> 0 then
      TradeMarkMatchesAltCtrl := False;
end;

label
  Next, Quit;
begin
  AltCtrl := GetShiftState and (kbAltShift + kbCtrlShift) =
    kbAltShift + kbCtrlShift;
  Multitasker := MultitaskerDetected;
  Found := False;
  GetMem(ArcDir, SizeOf(String));
  GetMem(ListName, SizeOf(String));
  GetMem(ListCommand, SizeOf(String));
  Stream.Init(ConfigPath + UserArchiverName, stOpenRead);
  B := avUsr;
  while (Stream.Status = stOk) and not Found and (B < 255) do
  begin
    L := Stream.GetPos;
    P := NewUserArchiveRec;
    ReadUserArchiveRec(@Stream, P);
    if (Id <> avNo) and (Id <> B) then goto Next;
    if (Id = avNo) and AltCtrl and (P^.TradeMark <> nil) and
      not TradeMarkMatchesAltCtrl then goto Next;
    if (Stream.Status = stOk) and UserArchiveEnabled(P) and
       (P^.Mask <> nil) and WildCardMatch(JustFileName(Name), P^.Mask^) then
    begin
      if P^.DirViewCommand <> nil then
      begin
	ListCommand^ := P^.DirViewCommand^;
	if not Info then ForceList := True;
      end
      else if P^.ViewCommand <> nil then ListCommand^ := P^.ViewCommand^
      else ListCommand^ := '';
      DisposeArchiveRec(TheArchiver^.ArchiveRec);
      TheArchiver^.ArchiveRec := NewArchiveRec;
      Stream.Seek(L);
      ReadArchiveRec(@Stream, TheArchiver^.ArchiveRec);
      Id := B;
      Found := True;
    end;
Next:
    DisposeUserArchiveRec(P);
    Inc(B);
  end;
  Stream.Done;
  if not Found then Goto Quit;
  if StUpcase(ListCommand^) = '$XW' then
  begin
    Status := arcView;
    TheArchiver^.PrepareExecRec;
    ExecRec.Path := '$XW(' + TheArchiver^.DosName^ + ')';
    PrepareExecEvent;
    Goto Quit;
  end;
  Status := arcOk;
  if TheArchiver^.UserListName = nil then
  begin
    GetValidSwapDir(ListName^, False);
    ConcatListName;
    TheArchiver^.InsertExtractedName(ListName^);
    XNames := TheArchiver^.GetTopArchiver^.ExtractedNames;
    TheArchiver^.UserListName := XNames^.At(XNames^.Count - 1);
    ForceList := True;
  end
  else ListName^ := TheArchiver^.UserListName^;
  if ForceList and (ListCommand^ <> '') then
    if Debugging or ProgRunning then CannotExecMessageBox
    else CreateList;
  ReadList;
Quit:
  FreeMem(ListCommand, SizeOf(String));
  FreeMem(ListName, SizeOf(String));
  FreeMem(ArcDir, SizeOf(String));
end;

procedure ScanArchivePrim(FManager: Pointer; NoDone: Boolean);
var
  Error: Boolean;
  W: Word;
  I: Integer;
  A: PArchiver;
  SaveTime: Longint;
  S: FNameStr;

procedure DrawStatusStr;
begin
  S := 'Reading the archive ' +
    TrimmedName(TheArchiver^.ArcName^, 47) + '.';
  LogEvent := lcDiskRead;
  DrawStatusLine(S);
end;

function ArchiveErrorMsgBox(const Msg: String; Buttons: Word): Word;
var
  S: FNameStr;
begin
  S := TheArchiver^.ArcName^ + '|.';
  if Buttons = mfYesNoCancel then S := S +
    #13^C'Try user defined archivers ?';
  ArchiveErrorMsgBox := MessageBox(^C + Msg +
    ' the archive'#13^C'|' + S, nil, mfError + Buttons);
end;

label
  DoRead, TryUser, Focus;
begin
  Error := False;
DoRead:
  TheArchiver := PPanel(FManager)^.Archiver;
  if (@ArchiveLineProc = @NewArchiveItem) or
     (@ArchiveLineProc = @ArchiveDirInfo) then DrawStatusStr;
  with TheArchiver^ do
  begin
    AtLeastOneHidden := False;
    SaveTime := ArcRec.Time;
    ReadArchive(DosName^, ArcId, ArcRec, Status);
    if Status = arcNotIdentified then
    begin
TryUser:
      ReadUserArchive(DosName^, UserArcId, ArcRec.Time <> SaveTime,
	False, False, Status);
      ArcId := UserArcId; { Added 2004.12.09 }
    end
    else GetArchiveRec;
    case Status of
      arcNotFound: S := 'Could not open';
      arcNotIdentified: S := 'Could not identify';
      arcBroken: S := 'Error reading';
      arcView: ;
      else if not Error then Exit else Goto Focus;
    end;
    if Status <> arcView then
      if Status <> arcBroken then
	ArchiveErrorMsgBox(S, mfOkButton)
      else
      begin
	W := ArchiveErrorMsgBox(S, mfYesNoCancel);
	if W = cmYes then
	begin
	  PPanel(FManager)^.List^.FreeAll;
	  Goto TryUser;
	end
	else if W = cmNo then if not Error then Exit else Goto Focus;
      end;
    Error := True;
  end;
  if NoDone or Extracting then Exit;
  S := TheArchiver^.ArcName^;
  A := TheArchiver^.Prev;
  TheArchiver^.Prev := nil;
  Dispose(TheArchiver, Done);
  PPanel(FManager)^.Archiver := A;
  if A = nil then with PPanel(FManager)^ do
  begin
    InArchive := False;
    NewDir(ListDir^, True);
  end
  else Goto DoRead;
Focus:
  with PPanel(FManager)^ do
  begin
    GetItemNum(S, I);
    FocusItem(I);
  end;
end;

procedure ReadArchivePrim(FManager: Pointer; UnfoldSel: Boolean);
begin
  ArchiveLineProc := NewArchiveItem;
  ArchiveCommentList := nil;
  ArcUnfoldSel := UnfoldSel;
  ScanArchivePrim(FManager, False);
end;

procedure ReadArchiveTreePrim(FManager: Pointer);
var
  SR: SearchRec;
begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Building the Tree for the currently viewed archive.');
  with PPanel(FManager)^ do
  begin
    SR.Name := '';
    SR.Attr := Directory;
    SR.Time := 0;
    SR.Size := 0;
    TheTree^.FreeAll;
    TheTree^.Insert(NewTreeRec(SR));
    TheTree^.BaseName := Archiver^.ArcName^;
    TheTree^.ForceLong := True;
  end;
  ArchiveLineProc := NewArchiveTreeItem;
  ArchiveCommentList := nil;
  ArchiveInfoPtr := FManager;
  ScanArchivePrim(FManager, False);
end;

procedure IntoArchive(FManager: Pointer; const Name: FNameStr; Info: Byte);
var
  I: Integer;
  ArcName, ArcDir, ListDirName: FNameStr;
begin
  ArcName := System.Copy(Name, 1, Info);
  ArcDir := ClearedSlash(JustPathName(Name));
  ListDirName := ClearedSlash(JustPathName(ArcName));
  with PPanel(FManager)^ do
  begin
{
    DisposeStr(ListDir);
    ListDir := NewStr(ListDirName);
}
    DisposeStrUMB(ListDir);
    ListDir := NewStrUMB(ListDirName);
    Archiver := New(PArchiver, Init(FManager));
    Archiver^.NewArchive(ArcName, '');
    Archiver^.NewArcDir(ArcDir);
    InArchive := True;
    NewDir(ListDir^, True);
    if InArchive and (Name[Length(Name)] <> '\') then GetItemNum(Name, I)
    else I := 0;
    FocusItem(I);
  end;
end;

procedure OutOfArchive(FManager: Pointer);
var
  I: Integer;
  A: Pointer;
  S: FNameStr;
begin
  with PPanel(FManager)^ do
  begin
    if not InArchive or (Status > stTree) then Exit;
    if Status = stTree then
    begin
      S := Archiver^.ArcName^;
      A := Archiver^.Prev;
      Archiver^.Prev := nil;
      Dispose(Archiver, Done);
      Archiver := A;
      InArchive := A <> nil;
      Status := stBrief;
      NewDir(ListDir^, True);
      GetItemNum(S, I);
      FocusItem(I);
    end
    else
    begin
      Archiver^.NewArcDir(Archiver^.ArcName^);
      ItemSelectedPrim(FManager, 0);
    end;
  end;
end;

procedure TNameList.FreeItem(Item: Pointer);
var
  S: String[239];
  F: File;

procedure DeleteHistoryEntry(const Title: String);
var
  I: Integer;
begin
  I := HistoryIndex(ReopenHistoryID, Pad(Title, 6) + S);
  if I <> -1 then HistoryList^.AtFree(I);
end;

begin
  if Item = nil then Exit;
  S := PString(Item)^ + #$FF;
  DeleteHistoryEntry('View');
  DeleteHistoryEntry('XView');
  DeleteHistoryEntry('dBASE');
  DeleteHistoryEntry('HTML');
  Assign(F, PString(Item)^);
  SetFAttr(F, Archive);
  Erase(F);
  InOutRes := 0;
  if Application^.EndState <> cmQuit then
    Message(Desktop, evBroadcast, cmUpdateTime, Item);
{  DisposeStr(Item);}
  DisposeStrUMB(Item);
end;

constructor TArchiver.Init(AOwner: Pointer);
begin
  Inherited Init;
  Owner := AOwner;
  ExtractedNames := New(PNameList, Init(4, 4));
  ArchiveRec := NewArchiveRec;
end;

destructor TArchiver.Done;
begin
  if Prev <> nil then Dispose(Prev, Done);
  DisposeArchiveRec(ArchiveRec);
{
  DisposeStr(Password);
  DisposeStr(ArcDir);
  DisposeStr(DosName);
  DisposeStr(ArcName);
}
  DisposeStrUMB(Password);
  DisposeStrUMB(ArcDir);
  DisposeStrUMB(DosName);
  DisposeStrUMB(ArcName);
  Dispose(ExtractedNames, Done);
  Inherited Done;
end;

function TArchiver.CheckPassword(Attr: Byte): Boolean;
begin
  CheckPassword := True;
  if (Attr and Hidden = 0) or (Password <> nil) or
     (ArchiveRec^.Password = nil) then Exit;
  SetPassword;
  CheckPassword := Password <> nil;
end;

function TArchiver.ExtractItem(SR: PPanelRec; const Name: FNameStr): Boolean;
var
  SaveMultiExec: Boolean;
  S: FNameStr;
  SaveRec: TExecRec;
begin
  ExtractItem := False;
  if Debugging or ProgRunning then
  begin
    CannotExecMessageBox;
    Exit;
  end;
  if (ArchiveRec^.UnpackerName = nil) or
    not CheckPassword(SR^.Attr) then Exit;
  InsertExtractedName(Name);
  SaveExecRec(SaveRec, SaveMultiExec);
  PrepareExecRec;
  ExecRec.Options := ExecRec.Options or opNoReread;
  ExecRec.Path := ArchiveRec^.UnpackerName^;
  if ArchiveRec^.Extract = nil then ExecRec.Params := ''
  else ExecRec.Params := ArchiveRec^.Extract^;
  lGetShortFileName(DosName^, S);
  AddSource('$ARC', S, False, ExecRec.Params);
  CheckLeadingSlash(ExecRec.Params);
  SetItemPathName(SR, S);
  if not SingleFmt(S, ExecRec.Params) then
    AddSource('$SRC', S, AddLeadingSlash, ExecRec.Params);
  if (SR^.Attr and Hidden <> 0) and (Password <> nil) and
     (ArchiveRec^.Password <> nil) then ExecRec.Params :=
       ExecRec.Params + ' ' + ArchiveRec^.Password^ + Password^;
  GetValidSwapDir(S, False);
  if Length(S) > 3 then S := ClearedSlash(S);
  FailSysErrors := True;
  lChDir(S);
  FailSysErrors := False;
  InOutRes := 0;
  PrepareExecEvent;
  ExecPending;
  RestoreExecRec(SaveRec, SaveMultiExec);
  ExtractItem := True;
end;

function TArchiver.ExtractByName(const Name: FNameStr): PString;
var
  SR: TPanelRec;
  S, SS: String;
begin
  ExtractByName := nil;
  if Name = '' then Exit;
  SS := Name;
  SR.Name := JustName(Name);
  SR.Ext := JustExtension(Name);
  GetValidSwapDir(S, False);
  S := #0 + Copy(Name, Length(S) + 1, 255);
  SR.ThePath := @S;
  SR.Attr := Archive;
  GlobalRedrawLock := True;
  GlobalQuietExec := True;
  if ExtractItem(@SR, Name) then ExtractByName := @SS;
  GlobalRedrawLock := False;
  GlobalQuietExec := False;
end;

procedure TArchiver.GetArchiveRec;
var
  B: Byte;
  I: Integer;
  Stream: TDosStream;
begin
  if (ArcId = avNo) or not (Status in [arcOk, arcBroken]) then Exit;
  Stream.Init(ConfigPath + ArchiverName, stOpenRead);
  for I := avZip to ArcId do
  begin
    DisposeArchiveRec(ArchiveRec);
    ArchiveRec := NewArchiveRec;
    ReadArchiveRec(@Stream, ArchiveRec);
  end;
  Stream.Done;
end;

function TArchiver.GetDirInfo(const ADir: FNameStr;
  var NumFiles, FilesSize, NumBytes,
  NumTagged, TaggedSize, TaggedBytes,
  NumSubDirs: Longint; CalcTagged: Boolean): Boolean;
var
  P: PArcSizeInfo;
  S: FNameStr;
begin
  ArchiveLineProc := ArchiveDirInfo;
  ArchiveCommentList := nil;
  GetMem(P, SizeOf(TArcSizeInfo));
  FillChar(P^, SizeOf(TArcSizeInfo), 0);
  P^.ArcName := ArcName;
  S := System.Copy(ADir, Length(ArcName^) + 1, 255);
  if S <> '' then P^.Name := @S;
  ArchiveInfoPtr := P;
  ScanArchivePrim(Owner, True);
  NumFiles := P^.NumFiles;
  FilesSize := P^.PackedSize;
  NumBytes := P^.TotalSize;
  NumTagged := P^.NumTagged;
  TaggedSize := P^.TaggedSize;
  TaggedBytes := P^.TaggedBytes;
  NumSubDirs := P^.NumSubDirs;
  FreeMem(P, SizeOf(TArcSizeInfo));
  GetDirInfo := Status in [arcOk, arcBroken];
end;

procedure TArchiver.GetDownOrUpName(Down: Boolean; var NewName: FNameStr);
var
  OpenFileDlg: Boolean;
  I, Code: Integer;
  Dir, Name, Ext, NewExt: String;
begin
  NewName := ArcName^;
  OpenFileDlg := True;
  lFSplit(NewName, Dir, Name, Ext);
  if Ext <> '' then System.Delete(Ext, 1, 1);
  Val(System.Copy(Ext, 2, 2), I, Code);
  if (I <> 0) or Down then
  begin
    if Down then Inc(I) else Dec(I);
    if I = 0 then NewExt := GetExtension
    else
    begin
      Str(I, NewExt);
      if Length(NewExt) = 1 then NewExt := '0' + NewExt;
      NewExt := Ext[1] + NewExt;
    end;
    NewName := Dir + Name + '.' + NewExt;
    if ThisFileExists(NewName) then OpenFileDlg := False;
  end;
  if OpenFileDlg and (Application^.ExecuteDialog(
    New(PFileDialog, Init('*.*', 'Archive volume',
    '~N~ame', fdOpenButton + fdHelpButton,
    HistoryID)), @NewName, False) = cmCancel) then NewName := '';
end;

function TArchiver.GetExtension: String;
begin
  if ArchiveRec^.Extension = nil then GetExtension := ''
  else GetExtension := StUpcase(ArchiveRec^.Extension^);
end;

function TArchiver.GetTopArchiver: PArchiver;
var
  A: PArchiver;
begin
  A := @Self;
  while A^.Prev <> nil do A := A^.Prev;
  GetTopArchiver := A;
end;

function TArchiver.GetTopName: FNameStr;
begin
  GetTopName := GetTopArchiver^.ArcName^;
end;

procedure TArchiver.InsertExtractedName(const Name: FNameStr);
begin
{  GetTopArchiver^.ExtractedNames^.Insert(NewStr(Name));}
  GetTopArchiver^.ExtractedNames^.Insert(NewStrUMB(Name));
end;

procedure TArchiver.InsertItem(SR: SearchRec; Percent, Info: Byte;
  const Path: FNameStr);
var
  P: PPanelRec;
  lSR: lSearchRec;
begin
  lSR.SR := SR;
{ Added 2006.01.03 }
  lSR.HiAttr := 0;
  P := NewPanelRec(lSR, Owner);
  P^.Percent := Percent;
  P^.Info := Info;
{  if Path <> '' then P^.ThePath := NewStr(Path);}
  if Path <> '' then P^.ThePath := NewStrUMB(Path);
  PPanel(Owner)^.List^.Insert(P);
end;

procedure TArchiver.NewArcDir(const Name: FNameStr);
begin
{
  DisposeStr(ArcDir);
  ArcDir := NewStr(Name);
}
  DisposeStrUMB(ArcDir);
  ArcDir := NewStrUMB(Name);
end;

procedure TArchiver.NewArchive(const Name, DName: FNameStr);
begin
{
  DisposeStr(DosName);
  DisposeStr(ArcName);
  ArcName := NewStr(Name);
  if DName = '' then DosName := NewStr(Name)
  else DosName := NewStr(DName);
}
  DisposeStrUMB(DosName);
  DisposeStrUMB(ArcName);
  ArcName := NewStrUMB(Name);
  if DName = '' then DosName := NewStrUMB(Name)
  else DosName := NewStrUMB(DName);
  NewArcDir(Name);
end;

procedure TArchiver.PrepareExecRec;
begin
  with ExecRec do
  begin
    Path := '';
    Params := '';
    FileMask := '';
    LineMask := '';
    if ArchiveRec^.Main and amSwapMainBody = 0 then Main := mnNone
    else Main := mnSwap;
    Setup := 0;
    if ArchiveRec^.Main and amLoadCOMMAND = 0 then Options := 0
    else Options := opLoadCOMMANDCOM;
    if ArchiveRec^.Main and amUserScreen = 0 then
{ Added 2005.10.06 }
      if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
	Options := (Options and not (opMessage + opNoMsgWin)) or opUserScr
      else Options := Options or (opMessage + opNoMsgWin);
  end;
end;

procedure TArchiver.PrepareParams(SR: PPanelRec; var Params: TParamStr;
  const Mask: FNameStr; Single: Boolean; var PasswordNeeded: Boolean);
var
  FS: String[12];
  S, Fmt: FNameStr;
  F: Text;
begin
  if Mask = '*.*' then FS := ''
  else FS := Mask;
  with PPanel(Owner)^ do
  begin
    if Single or (SelCount = 0) or
      (Settings and seIgnoreSelection <> 0) then
    begin
      if SR^.Attr and Directory = 0 then
      begin
        SetItemPathName(SR, S);
        if not SingleFmt(S, Params) then
          AddSource('$SRC', S, AddLeadingSlash, Params);
        PasswordNeeded := SR^.Attr and Hidden <> 0;
        Exit;
      end;
      if (SR^.Attr and VolumeID <> 0) and (SR^.Name[1] = '.') and
         (Settings and seUnfold = 0) and (FS = '') then
      begin
        if not SingleFmt('', Params) then
          AddSource('$SRC', '', False, Params);
        PasswordNeeded := AtLeastOneHidden;
        Exit;
      end;
    end;
    PasswordNeeded := False;
    if ArchiveRec^.ListChar = #0 then
    begin
      Params := '';
      Exit;
    end;
    GetValidSwapDir(S, False);
    S := S + SelListName;
    AddSource('$SRC', ArchiveRec^.ListChar + S, False, Params);
    SearchForFmt(Params, Fmt);
    Assign(F, S);
    Rewrite(F);
    if IOResult <> 0 then Exit;
    LogEvent := lcDiskWrite;
    DrawStatusLine('Creating list file ' + TrimmedName(S, 48) + '.');
    if (SelCount > 0) and (Settings and seIgnoreSelection = 0) then
      SaveSelected(@F, FS, Fmt, PasswordNeeded)
    else SaveSubFiles(@F, FS, Fmt, PasswordNeeded);
    Close(F);
    InOutRes := 0;
  end;
end;

procedure TArchiver.PrepareSource(var S: FNameStr);
var
  SavePath: PString;
  SR: PPanelRec;
begin
  with PPanel(Owner)^ do SR := List^.At(Focused);
  if SR = nil then S := ''
  else if not Extracting and (SR^.Attr and Directory = 0) then
  begin
    GetValidSwapDir(S, False);
    SavePath := SR^.ThePath;
    if (ArchiveRec^.Main and amEnableLFN = 0) or
       (SR^.ThePath = nil) or (SR^.ThePath^[1] <> #0) then
      SR^.ThePath := nil;
    AddNameExt(S, SR, S);
    SR^.ThePath := SavePath;
    if ArcFileExists(S, SR^.Time, SR^.Size) then Exit;
    if not ExtractItem(SR, S) then S := '';
  end
  else PPanel(Owner)^.GetRecStr(SR, S);
end;

procedure TArchiver.SaveSelected(TextPtr: Pointer; const Mask, Fmt: FNameStr;
  var PasswordNeeded: Boolean);
var
  Optimized: Boolean;
  I: Integer;
  P: PSaveSelInfo;
  SR: PPanelRec;
begin
  ArchiveLineProc := WriteSelItem;
  ArchiveCommentList := nil;
  GetMem(P, SizeOf(TSaveSelInfo));
  FillChar(P^, SizeOf(TSaveSelInfo), 0);
  P^.Panel := PPanel(Owner);
  P^.TextFile := TextPtr;
  P^.FlagPtr := @PasswordNeeded;
  P^.ClearSlash := ArcID = avArj;
  P^.Mask := @Mask;
  P^.Fmt := @Fmt;
  SearchForOptimized(P);
  Optimized := P^.Optimized;
  P^.FilesOnly := P^.Panel^.SelDirCount = 0;
  ArchiveInfoPtr := P;
  if P^.FilesOnly then SaveSelFilesOnly
  else ScanArchivePrim(Owner, True);
  FreeMem(P, SizeOf(TSaveSelInfo));
  with PPanel(Owner)^ do
    for I := 0 to List^.Count - 1 do
    begin
      SR := List^.At(I);
      if SR^.Selected and not
        (Optimized and (Byte(SR^.Selected) = 1)) then
          SetSelect(SR, False);
    end;
end;

procedure TArchiver.SaveSubFiles(TextPtr: Pointer; const Mask, Fmt: FNameStr;
  var PasswordNeeded: Boolean);
var
  P: PSaveSubInfo;
  S: FNameStr;
begin
  ArchiveLineProc := WriteSubItem;
  ArchiveCommentList := nil;
  GetMem(P, SizeOf(TSaveSubInfo));
  FillChar(P^, SizeOf(TSaveSubInfo), 0);
  P^.ArcName := ArcName;
  with PPanel(Owner)^ do GetItemStr(Focused, S);
  S := AddedSlash(S);
  P^.Name := @S;
  P^.TextFile := TextPtr;
  P^.FlagPtr := @PasswordNeeded;
  P^.ClearSlash := ArcID = avArj;
  P^.Mask := @Mask;
  P^.Fmt := @Fmt;
  ArchiveInfoPtr := P;
  ScanArchivePrim(Owner, True);
  FreeMem(P, SizeOf(TSaveSubInfo));
end;

procedure TArchiver.SetFieldsForDots(var SR: lSearchRec);
begin
  SR.SR.Name := '..';
  if ArcName^ = ArcDir^ then
  begin
    SR.SR.Size := ArcRec.Size;
    SR.SR.Time := ArcRec.Time;
    SR.SR.Attr := VolumeID + Directory;
  end
  else
  begin
    SR.SR.Size := 0;
    SR.SR.Time := $210000;
    SR.SR.Attr := Directory;
  end;
{ Added 2006.01.03 }
  SR.HiAttr := 0;
end;

procedure TArchiver.SetItemPathName(SR: PPanelRec; var S: FNameStr);
begin
  if SR^.ThePath <> nil then S := PanelRecPath(SR)
  else S := '';
  if S = '' then S := System.Copy(ArcDir^, Length(ArcName^) + 2, 255);
  if S <> '' then S := AddedSlash(S);
  AddNameExt(S, SR, S);
  if SR^.Info and piPathPrefix <> 0 then S := '.\' + S;
end;

procedure TArchiver.SetPassword;
var
  S: String[39];
begin
  if Password = nil then S := '' else S := Password^;
  if Application^.ExecuteDialog(
    PasswordDialog, @S, False) <> cmCancel then
  begin
{
    DisposeStr(Password);
    Password := NewStr(S);
}
    DisposeStrUMB(Password);
    Password := NewStrUMB(S);
  end;
end;

procedure TArchiver.RunPrim(PName, PAction: PString;
  const ADir, Mask: FNameStr;
  CheckVolume, CheckPsw, Single, SwapScreen: Boolean);
var
  PasswordNeeded: Boolean;
  SR: PPanelRec;
  S: FNameStr;
begin
  with PPanel(Owner)^ do
  begin
    SR := List^.At(Focused);
    if CheckVolume and ((SelCount = 0) or
       (Settings and seIgnoreSelection <> 0)) and
       (SR^.Attr and VolumeID <> 0) and (SR^.Name[1] <> '.') then Exit;
  end;
  if PName = nil then Exit;
  if ADir <> '' then
  begin
    S := lFExpand(ADir);
    if Length(S) > 3 then S := ClearedSlash(S);
    MkDirPrim(S, nil);
    if not DirPresent(S) then Exit;
    FailSysErrors := True;
    lChDir(S);
    FailSysErrors := False;
    InOutRes := 0;
  end;
  PrepareExecRec;
  ExecRec.Path := PName^;
  if SwapScreen then
    ExecRec.Options := ExecRec.Options and not (opMessage + opNoMsgWin);
{ Added 2005.11.15 }
  if ArcId >= avUsr then ExecRec.Options := ExecRec.Options or opNoReread;
  if PAction = nil then ExecRec.Params := ''
  else ExecRec.Params := PAction^;
  lGetShortFileName(DosName^, S);
  AddSource('$ARC', S, False, ExecRec.Params);
  CheckLeadingSlash(ExecRec.Params);
  PrepareParams(SR, ExecRec.Params, Mask, Single, PasswordNeeded);
  if ExecRec.Params = '' then Exit;
  if CheckPsw and PasswordNeeded then
  begin
    if not CheckPassword(Hidden) then Exit;
    if (Password <> nil) and (ArchiveRec^.Password <> nil) then
      ExecRec.Params := ExecRec.Params + ' ' +
        ArchiveRec^.Password^ + Password^;
  end;
  PrepareExecEvent;
  ExecPending;
{ Added 2005.11.15 }
  if ArcId >= avUsr then
  begin
    Pending.What := evBroadcast;
    Pending.Command := cmReRead;
    Pending.InfoPtr := nil;
  end;
end;

procedure TArchiver.TestPrim;
begin
  RunPrim(ArchiveRec^.UnpackerName, ArchiveRec^.Test,
    '', '', True, True, False, True);
end;

procedure TArchiver.ExtractPrim;
begin
  RunPrim(ArchiveRec^.UnpackerName, ArchiveRec^.ExWithDirs,
    '', '', True, True, False, False);
end;

procedure TArchiver.DeletePrim(Single: Boolean);
begin
  RunPrim(ArchiveRec^.PackerName, ArchiveRec^.Del,
    '', '', False, False, Single, False);
end;

procedure TArchiver.CopyPrim(const ToName, Mask: FNameStr; Single: Boolean);
var
  P: PString;
begin
  if AreDirs(PPanel(Owner), Single) then
    P := ArchiveRec^.ExWithDirs
  else P := ArchiveRec^.Extract;
  RunPrim(ArchiveRec^.UnpackerName, P,
    ToName, Mask, False, True, Single, False);
end;

procedure TPasswordInput.Draw;
var
  P: PString;
  S: String;
begin
  S := Data^;
  FillChar(S[1], Length(S), 'þ');
  P := Data;
  Data := @S;
  Inherited Draw;
  Data := P;
end;

procedure GetArchiveRec(const Dest: FNameStr; var P: PArchiveRec);
var
  B: Byte;
  I: Integer;
  L: Longint;
  UP: PUserArchiveRec;
  Stream: TDosStream;
  S: String[3];
label
  Error;
begin
  I := Pos(':', Dest);
  if I < 3 then Goto Error;
  S := Trim(System.Copy(Dest, 1, I - 1));
  Stream.Init(ConfigPath + ArchiverName, stOpenRead);
  P := nil;
  for I := avZip to avLast do
  begin
    DisposeArchiveRec(P);
    P := NewArchiveRec;
    ReadArchiveRec(@Stream, P);
    if (P^.Extension <> nil) and
       (CompUCString(Trim(P^.Extension^), S) = Equal) then
    begin
      Stream.Done;
      Exit;
    end;
  end;
  Stream.Done;
  DisposeArchiveRec(P);

  Stream.Init(ConfigPath + UserArchiverName, stOpenRead);
  B := avUsr;
  while (Stream.Status = stOk) and (B < 255) do
  begin
    L := Stream.GetPos;
    UP := NewUserArchiveRec;
    ReadUserArchiveRec(@Stream, UP);
    if (Stream.Status = stOk) and UserArchiveEnabled(UP) and
       (UP^.ArchiveRec <> nil) and
       (UP^.ArchiveRec^.Extension <> nil) and
       (CompUCString(Trim(UP^.ArchiveRec^.Extension^), S) = Equal) then
    begin
      DisposeUserArchiveRec(UP);
      P := NewArchiveRec;
      Stream.Seek(L);
      ReadArchiveRec(@Stream, P);
      Stream.Done;
      Exit;
    end
    else DisposeUserArchiveRec(UP);
    Inc(B);
  end;
  Stream.Done;

Error:
  P := nil;
  MessageBox(^C'Archive name incorrectly specified.',
    nil, mfError + mfOkButton);
end;

procedure PreparePassword(P: PArchiveRec; var Params: TParamStr);
var
  Password: String[39];
begin
  Password := '';
  if (Application^.ExecuteDialog(
    PasswordDialog, @Password, True) <> cmCancel) and
    (P^.Password <> nil) and (Password <> '') then Params :=
      Params + ' ' + P^.Password^ + Password;
end;

procedure RunPacker(P: PArchiveRec);
var
  S: FNameStr;
begin
  with ExecRec do
  begin
    if P^.Password <> nil then PreparePassword(P, Params);
    FileMask := '';
    LineMask := '';
    if P^.Main and amSwapMainBody = 0 then Main := mnNone
    else Main := mnSwap;
    Setup := 0;
    if P^.Main and amLoadCOMMAND = 0 then Options := 0
    else Options := opLoadCOMMANDCOM;
    if P^.Main and amUserScreen = 0 then
{ Added 2005.10.06 }
      if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
	Options := (Options and not (opMessage + opNoMsgWin)) or opUserScr
      else Options := Options or (opMessage + opNoMsgWin);
  end;
  DisposeArchiveRec(P);
  PrepareExecEvent;
end;

procedure CopyToArchive(FManager: Pointer; Single, RenMov: Boolean;
  const Dest, Mask: FNameStr; CustomRec: Pointer);
var
  Id: Byte;
  P: PArchiveRec;
  PS: PString;
  DestName: FNameStr;

procedure PrepareParams(var Params: TParamStr);
var
  Scan: Boolean;
  SR, NR: PPanelRec;
  SaveList, FakeList: PPanelCollection;
  FS: String[12];
  S, Fmt: FNameStr;
  F: Text;
begin
  if Mask = '*.*' then FS := ''
  else FS := Mask;
  with PPanel(FManager)^ do
  begin
    if Single or (SelCount = 0) or
      (Settings and seIgnoreSelection <> 0) then
    begin
      SR := List^.At(Focused);
      GetRecStr(SR, S);
      if P^.Main and amEnableLFN = 0 then lGetShortFileName(S, S);
      if SR^.Attr and Directory = 0 then
      begin
        if not SingleFmt(S, Params) then
          AddSource('$SRC', S, False, Params);
        Exit;
      end;
      if (SR^.Name[1] = '.') and (Settings and seUnfold = 0) and
         (CRCList = nil) and (FS = '') then
      begin
        if not SingleFmt('', Params) then
          AddSource('$SRC', '', False, Params);
        Exit;
      end;
      Scan := True;
    end
    else Scan := False;
    if P^.ListChar = #0 then
    begin
      Params := '';
      Exit;
    end;
    GetValidSwapDir(S, False);
    S := S + SelListName;
    AddSource('$SRC', P^.ListChar + S, False, Params);
    SearchForFmt(Params, Fmt);
    Assign(F, S);
    Rewrite(F);
    if IOResult <> 0 then Exit;
    Close(F);
    InOutRes := 0;
    if Scan then
    begin
      FakeList := New(PPanelCollection, Init(4, 4, FManager));
      GetMem(NR, SizeOf(TPanelRec));
      NR^ := SR^;
      if SR^.ThePath <> nil then
        NR^.ThePath := NewStr(SR^.ThePath^);
      NR^.Selected := True;
      FakeList^.Insert(NR);
      SaveList := PPanelCollection(List);
      List := FakeList;
    end;
    AppendSelListPrim(FManager, S, FS, Fmt,
      P^.Main and amEnableLFN <> 0, False, True);
    if Scan then
    begin
      Dispose(FakeList, Done);
      List := SaveList;
    end;
  end;
end;

begin
  if CustomRec <> nil then P := CustomRec
  else GetArchiveRec(Dest, P);
  if P = nil then Exit;
  if P^.PackerName = nil then
  begin
    DisposeArchiveRec(P);
    Exit;
  end;
  with ExecRec do
  begin
    Path := P^.PackerName^;
    if AreDirs(PPanel(FManager), Single) then
      if RenMov then PS := P^.MoveWithDirs
      else PS := P^.AddWithDirs
    else
      if RenMov then PS := P^.Move
      else PS := P^.Add;
    if PS = nil then Params := ''
    else Params := PS^;
    DestName := Trim(System.Copy(Dest, Pos(':', Dest) + 1, 255));
    if P^.Main and amEnableLFN = 0 then
      lGetShortFileName(DestName, DestName);
    AddSource('$ARC', DestName, False, Params);
    if (JustExtension(DestName) = '') and (P^.Extension <> nil) then
      DestName := ForceExtension(DestName, P^.Extension^);
    DestName := lFExpand(DestName);
    if (P^.Main and amPrompt <> 0) and ThisFileExists(DestName) and
       (OverwriteArcMsgBox(DestName) <> cmOk) then Params := ''
    else PrepareParams(Params);
    if Params = '' then
    begin
      DisposeArchiveRec(P);
      Exit;
    end;
  end;
  if not Single and (PPanel(FManager)^.SelCount <> 0) and
    (PPanel(FManager)^.Settings and seIgnoreSelection = 0) then
      PPanel(FManager)^.UnselectAll;
  DisposeStr(PPanelWindow(PPanel(FManager)^.Owner)^.DestName);
  PPanelWindow(PPanel(FManager)^.Owner)^.DestName := NewStr(DestName);
  RunPacker(P);
end;

procedure ClipboardToArchive(RenMov: Boolean; const Dest: FNameStr);
var
  Id: Byte;
  P: PArchiveRec;
  PS: PString;

procedure PrepareParams(var Params: TParamStr);
var
  I: Integer;
  F: Text;
  Fmt: FNameStr;
  S: String;
begin
  if P^.ListChar = #0 then
  begin
    Params := '';
    Exit;
  end;
  GetValidSwapDir(S, False);
  S := S + SelListName;
  AddSource('$SRC', P^.ListChar + S, False, Params);
  SearchForFmt(Params, Fmt);
  Assign(F, S);
  Rewrite(F);
  if IOResult <> 0 then Exit;
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
  for I := ClipArea^.KB to ClipArea^.KK do
  begin
    GetClipLine(I, S);
    if P^.Main and amEnableLFN = 0 then lGetShortFileName(S, S);
    ProcessFmt(Fmt, S);
    Writeln(F, S);
  end;
  Close(F);
  InOutRes := 0;
end;

begin
  if (DiskClipStream = nil) or not ClipAreaSelected then Exit;
  GetArchiveRec(Dest, P);
  if P = nil then Exit;
  if P^.PackerName = nil then
  begin
    DisposeArchiveRec(P);
    Exit;
  end;
  with ExecRec do
  begin
    Path := P^.PackerName^;
    if RenMov then PS := P^.Move
    else PS := P^.Add;
    if PS = nil then Params := ''
    else Params := PS^;
    AddSource('$ARC', Trim(System.Copy(Dest, Pos(':', Dest) + 1, 255)),
      False, Params);
    PrepareParams(Params);
    if Params = '' then
    begin
      DisposeArchiveRec(P);
      Exit;
    end;
  end;
  RunPacker(P);
end;

end.