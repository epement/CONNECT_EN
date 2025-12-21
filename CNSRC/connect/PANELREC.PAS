{$I-,F+,O+}
unit PanelRec;

interface

uses Dos, Objects, LFN;

type
  PPanelRec = ^TPanelRec;
  TPanelRec = record
    Attr: Byte;
    Time: Longint;
    Size: Longint;
    Name: String[8];
    Ext: String[3];
    Selected: Boolean;
{    Scanned: Boolean;}
{ Added 2006.01.03 instead of Scanned }
    HiAttr: Byte;
    ThePath: PString;
    Color: Byte;
    Index: Byte;
    Percent: Byte;
    Info: Byte;
  end;

  PTempGroupRec = ^TTempGroupRec;
  TTempGroupRec = record
    MaskName: String[8];
    MaskExt: String[3];
    Color: Byte;
    Index: Byte;
    Dir: Boolean;
  end;

  PPanelCollection = ^TPanelCollection;
  TPanelCollection = object(TSortedCollection)
    Owner: Pointer;
    Full: Boolean;
    constructor Init(ALimit, ADelta: Integer; AOwner: Pointer);
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    procedure FreeItem(Item: Pointer); virtual;
    procedure Insert(Item: Pointer); virtual;
    procedure Sort;
  end;

  PTempGroupList = ^TTempGroupList;
  TTempGroupList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PFilterRec = ^TFilterRec;
  TFilterRec = record
    Text: PString;
    Unix: Boolean;
    LoTime: Longint;
    HiTime: Longint;
    LoSize: Longint;
    HiSize: Longint;
    Attr: Byte;
    PipePos: Byte;
    UseForLists: Boolean;
    ReservedWord: Word;
  end;

const
  smName = 0;
  smExt = 1;
  smTime = 2;
  smSize = 3;
  smDescr = 4;
  smFilesBBS = 5;
  smDisk = 6;
  smNumber = 7;

  sdAscending = 0;
  sdDescending = 1;

  scFiles = 1;
  scDirs = 2;
  scDesc = 4;

  spDirsFirst = 0;
  spFilesFirst = 1;
  spMixed = 2;

  fgGroupHighlight = $01;
  fgSelectionTurnsOff = $02;
  fgSortByIndex = $04;
  fgSortDirsByName = $08;
  fgSortDigitsAsChars = $10;
  fgSortInverse = $20;
  fgSortMixed = $40;
  fgSortNameExt = $80;

  TempGroups: PTempGroupList = nil;

  CopyRenameFilter: TFilterRec = (Text: nil);
  CopyRenameStates: Pointer = nil;

  piPathPrefix = $01;

function NewPanelRec(SR: lSearchRec; Caller: Pointer): PPanelRec;
procedure InitTempGroups;
procedure DoneTempGroups;
procedure GetGroupInfo(const Name, Ext: String; Dir: Boolean;
  var Color, Index: Byte);
function PanelRecHasPath(P: PPanelRec): Boolean;
procedure AddNameExt(const Path: FNameStr; P: PPanelRec; var S: FNameStr);
function PanelRecPath(P: PPanelRec): FNameStr;
function NameMatchesMultiMask(const Name, Mask: String;
  PipePos: Byte): Boolean;
function AdvancedFilterPassed(P: PFilterRec; States: Pointer;
  var SR: SearchRec; const ALongName: FNameStr): Boolean;

implementation

uses Memory, Views, App, FileMngr, FMAbort, FMGroups, DirPrim, UnixMask,
  HeapUMB, RevPos, TPString, Defaults;

const
  SafetyPool = 8192;

function NewPanelRec(SR: lSearchRec; Caller: Pointer): PPanelRec;
var
  I: Integer;
  P: PPanelRec;
begin
{  GetMem(P, SizeOf(TPanelRec));}
  GetMemUMB(P, SizeOf(TPanelRec));
  FillChar(P^, SizeOf(TPanelRec), 0);
  P^.Attr := SR.SR.Attr;
{ Added 2006.01.03 }
  P^.HiAttr := SR.HiAttr;
  P^.Time := SR.SR.Time;
  P^.Size := SR.SR.Size;
  I := RPos('.', SR.SR.Name);
  if SR.SR.Attr and Directory = 0 then
    if I <> 0 then
    begin
      P^.Name := System.Copy(SR.SR.Name, 1, I - 1);
      P^.Ext  := System.Copy(SR.SR.Name, I + 1, 3);
    end
    else P^.Name := SR.SR.Name
  else
    if (I <> 0) and (SR.SR.Name[1] <> '.') then
    begin
      P^.Name := System.Copy(SR.SR.Name, 1, I - 1);
      P^.Ext  := System.Copy(SR.SR.Name, I + 1, 3);
    end
    else P^.Name := SR.SR.Name;
  P^.Color := Byte(Application^.GetPalette^[141]);
  if PPanel(Caller)^.GroupOptions and
    (fgGroupHighlight + fgSortByIndex) <> 0 then
      GetGroupInfo(P^.Name, P^.Ext, SR.SR.Attr and Directory <> 0,
	P^.Color, P^.Index);
  NewPanelRec := P;
end;

procedure GetKeyName(Key: Pointer; Long: Boolean; CaseSens: Byte;
  var Name, Ext: FNameStr);
var
  ForceCase: Boolean;
  SaveAPI: LAPIType;
  Dir: FNameStr;
begin
  if Long then
  begin
    SaveAPI := lAPI;
    lAPI := lWIN95;
    lFSplit(Copy(PPanelRec(Key)^.ThePath^, 2, 255), Dir, Name, Ext);
    if (Ext <> '') and (Ext[1] = '.') then Delete(Ext, 1, 1);
    lAPI := SaveAPI;
  end
  else
  begin
    Name := PPanelRec(Key)^.Name;
    Ext := PPanelRec(Key)^.Ext;
  end;
  ForceCase := not Long or (LFNOptions and loConvertNames <> 0);
  if PPanelRec(Key)^.Attr and Directory = 0 then
    if ForceCase or (CaseSens and scFiles = 0) then
    begin
      LocaseSt(Name);
      LocaseSt(Ext);
    end else
  else
    if ForceCase or (CaseSens and scDirs = 0) then
    begin
      UpcaseSt(Name);
      UpcaseSt(Ext);
    end;
end;

const
  SignChars = [#0..'/'];
  DigitChars = ['0'..'9'];
  CharChars = [#58..#255];

procedure CalcDigits(const S: String; var E: Extended; var CS: String);
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    if S[I] in DigitChars then
    begin
      if E < 0 then E := 0;
      E := E * 10 + Byte(S[I]) - Byte('0');
      CS := CS + S[I];
    end;
end;

function GetNameNumber(const Name1, Ext1, Name2, Ext2: FNameStr;
  AsChars: Boolean): Integer;
var
  I: Integer;
  Number1, Number2: Extended;
  CS1, CS2: FNameStr;
begin
  Number1 := -1;
  CS1 := '';
  CalcDigits(Name1, Number1, CS1);
  CalcDigits(Ext1, Number1, CS1);
  if Number1 < 0 then Number1 := 1.0E256;

  Number2 := -1;
  CS2 := '';
  CalcDigits(Name2, Number2, CS2);
  CalcDigits(Ext2, Number2, CS2);
  if Number2 < 0 then Number2 := 1.0E256;

  if AsChars and (CS1 > CS2) then GetNameNumber := 1
  else if AsChars and (CS1 < CS2) then GetNameNumber := -1
  else if Number1 = Number2 then GetNameNumber := 0
  else if Number1 > Number2 then GetNameNumber := 1
  else GetNameNumber := -1;
end;

type
  TCompCase = (ccNone, ccLower, ccUpper);
  TCharType = (ctSign, ctDigit, ctChar);

function CompMixedString(S1, S2: String;
  CompCase: TCompCase): CompareType;
var
  C: CompareType;
  CT1, CT2: TCharType;
  I1Lo, I1Hi, I2Lo, I2Hi, Code: Integer;
  N1, N2: Extended;
  SS1, SS2: String;
begin
  C := Equal;
  I1Hi := 1;
  I2Hi := 1;
  repeat
    I1Lo := I1Hi;
    I2Lo := I2Hi;
    CT1 := ctChar;
    if I1Hi <= Length(S1) then
      if S1[I1Hi] in SignChars then CT1 := ctSign
      else if S1[I1Hi] in DigitChars then CT1 := ctDigit;
    CT2 := ctChar;
    if I2Hi <= Length(S2) then
      if S2[I2Hi] in SignChars then CT2 := ctSign
      else if S2[I2Hi] in DigitChars then CT2 := ctDigit;
    while (I1Hi <= Length(S1)) and
      (((CT1 = ctSign) and not (S1[I1Hi] in DigitChars)) or
       ((CT1 = ctDigit) and (S1[I1Hi] in DigitChars)) or
       ((CT1 = ctChar) and (S1[I1Hi] in CharChars))) do
    begin
      if S1[I1Hi] = '_' then S1[I1Hi] := '?';
      Inc(I1Hi);
    end;
    while (I2Hi <= Length(S2)) and
      (((CT2 = ctSign) and not (S2[I2Hi] in DigitChars)) or
       ((CT2 = ctDigit) and (S2[I2Hi] in DigitChars)) or
       ((CT2 = ctChar) and (S2[I2Hi] in CharChars))) do
    begin
      if S2[I2Hi] = '_' then S2[I2Hi] := '?';
      Inc(I2Hi);
    end;
    SS1 := Copy(S1, I1Lo, I1Hi - I1Lo);
    SS2 := Copy(S2, I2Lo, I2Hi - I2Lo);
    if (CT1 = ctDigit) and (CT2 = ctDigit) then
    begin
      Val(SS1, N1, Code);
      if Code <> 0 then N1 := 0; {-1.0E4932;}
      Val(SS2, N2, Code);
      if Code <> 0 then N2 := 0; {-1.0E4932;}
      if N1 > N2 then C := Greater
      else if N1 < N2 then C := Less;
      if C <> Equal then Break;
    end;
    if CompCase = ccUpper then C := CompUCString(SS1, SS2)
    else if CompCase = ccLower then C := CompLCString(SS1, SS2)
    else C := CompString(SS1, SS2);
    if C <> Equal then Break;
    if I1Hi > Length(S1) then
    begin
      if I2Hi <= Length(S2) then C := Less;
      Break;
    end;
    if I2Hi > Length(S2) then
    begin
      if I1Hi <= Length(S1) then C := Greater;
      Break;
    end;
  until False;
  CompMixedString := C;
end;

procedure SortByIndexStr(const S: String;
  Index1, Index2: Byte; var C: Integer);
var
  ILo, IHi, I1, I2, I, Code: Integer;
begin
  I1 := MaxInt;
  I2 := MaxInt;
  IHi := 1;
  repeat
    while (IHi <= Length(S)) and not (S[IHi] in DigitChars) do Inc(IHi);
    ILo := IHi;
    while (IHi <= Length(S)) and (S[IHi] in DigitChars) do Inc(IHi);
    Val(Copy(S, ILo, IHi - ILo), I, Code);
    if I = Index1 then I1 := ILo
    else if I = Index2 then I2 := ILo;
  until (IHi > Length(S)) or ((I1 <> MaxInt) and (I2 <> MaxInt));
  if I1 < I2 then C := -1
  else if I1 > I2 then C := 1;
end;

function NamePlusExt(const Name, Ext: String; SortBy: Byte): String;
begin
  if SortBy = smExt then
    if (Name = '') or (Ext = '') then NamePlusExt := Ext + Name
    else NamePlusExt := Ext + Name + '.'
  else
    if (Name = '') or (Ext = '') then NamePlusExt := Name + Ext
    else NamePlusExt := Name + '.' + Ext;
end;

function ComparePanelRecSizes(P1, P2: PPanelRec): Integer;
var
  C: lCompareType;
begin
  C := lCompareSizes(
    lGetFileRealSize(P1^.Attr, P1^.Size),
    lGetFileRealSize(P2^.Attr, P2^.Size));
  if C = lEqual then ComparePanelRecSizes := 0
  else if C = lGreater then ComparePanelRecSizes := 1
  else ComparePanelRecSizes := -1;
end;

constructor TPanelCollection.Init(ALimit, ADelta: Integer; AOwner: Pointer);
begin
  Inherited Init(ALimit, ADelta);
  Owner := AOwner;
end;

function TPanelCollection.Compare(Key1, Key2: Pointer): Integer;
var
  LongMode, BothDirsByName, SortMixed, SortNameExt: Boolean;
  Index1, Index2: Byte;
  Name, Ext, Time, Sizes, Number, Path, C: Integer;
  Mode: Word;
  Name1, Name2, Ext1, Ext2, Path1, Path2: FNameStr;
begin
  with PPanel(Owner)^ do
  begin
    BothDirsByName := (SortMode <> smName) and
      (GroupOptions and fgSortDirsByName <> 0) and
      (PPanelRec(Key1)^.Attr and Directory <> 0) and
      (PPanelRec(Key2)^.Attr and Directory <> 0);
    SortMixed := GroupOptions and fgSortMixed <> 0;
    SortNameExt := (GroupOptions and fgSortNameExt <> 0) and not BothDirsByName;
    LongMode := (Status <= stFull) and
      ((Settings and seLongNames <> 0) or (ColWidth <> 13));
    if GroupOptions and fgSortInverse <> 0 then LongMode := not LongMode;
    if LongMode then
    begin
      GetKeyName(Key1, PanelRecHasPath(PPanelRec(Key1)) and
        (PPanelRec(Key1)^.ThePath^[1] = #0), SortCaseSens, Name1, Ext1);
      GetKeyName(Key2, PanelRecHasPath(PPanelRec(Key2)) and
        (PPanelRec(Key2)^.ThePath^[1] = #0), SortCaseSens, Name2, Ext2);
      if SortMixed then
      begin
        if SortNameExt then
        begin
          Name := Integer(CompMixedString(
            NamePlusExt(Name1, Ext1, SortMode),
            NamePlusExt(Name2, Ext2, SortMode), ccNone)) - 1;
          Ext := Name;
        end
        else
        begin
          Name := Integer(CompMixedString(Name1, Name2, ccNone)) - 1;
          Ext := Integer(CompMixedString(Ext1, Ext2, ccNone)) - 1;
        end;
      end
      else
      begin
        if SortNameExt then
        begin
          Name := Integer(CompString(
            NamePlusExt(Name1, Ext1, SortMode),
            NamePlusExt(Name2, Ext2, SortMode))) - 1;
          Ext := Name;
        end
        else
        begin
          Name := Integer(CompString(Name1, Name2)) - 1;
          Ext := Integer(CompString(Ext1, Ext2)) - 1;
        end;
      end;
    end
    else if (PPanelRec(Key1)^.Attr and Directory = 0) and
      (PPanelRec(Key2)^.Attr and Directory = 0) then
    begin
      if SortCaseSens and scFiles = 0 then
      begin
        if SortMixed then
        begin
          if SortNameExt then
          begin
            Name := Integer(CompMixedString(
              NamePlusExt(PPanelRec(Key1)^.Name, PPanelRec(Key1)^.Ext, SortMode),
              NamePlusExt(PPanelRec(Key2)^.Name, PPanelRec(Key2)^.Ext, SortMode), ccLower)) - 1;
            Ext := Name;
          end
          else
          begin
            Name := Integer(CompMixedString(
              PPanelRec(Key1)^.Name, PPanelRec(Key2)^.Name, ccLower)) - 1;
            Ext := Integer(CompMixedString(
              PPanelRec(Key1)^.Ext, PPanelRec(Key2)^.Ext, ccLower)) - 1;
          end;
        end
        else
        begin
          if SortNameExt then
          begin
            Name := Integer(CompLCString(
              NamePlusExt(PPanelRec(Key1)^.Name, PPanelRec(Key1)^.Ext, SortMode),
              NamePlusExt(PPanelRec(Key2)^.Name, PPanelRec(Key2)^.Ext, SortMode))) - 1;
            Ext := Name;
          end
          else
          begin
            Name := Integer(CompLCString(
              PPanelRec(Key1)^.Name, PPanelRec(Key2)^.Name)) - 1;
            Ext := Integer(CompLCString(
              PPanelRec(Key1)^.Ext, PPanelRec(Key2)^.Ext)) - 1;
          end;
        end;
      end
      else
      begin
        if SortMixed then
        begin
          if SortNameExt then
          begin
            Name := Integer(CompMixedString(
              NamePlusExt(PPanelRec(Key1)^.Name, PPanelRec(Key1)^.Ext, SortMode),
              NamePlusExt(PPanelRec(Key2)^.Name, PPanelRec(Key2)^.Ext, SortMode), ccNone)) - 1;
            Ext := Name;
          end
          else
          begin
            Name := Integer(CompMixedString(
              PPanelRec(Key1)^.Name, PPanelRec(Key2)^.Name, ccNone)) - 1;
            Ext := Integer(CompMixedString(
              PPanelRec(Key1)^.Ext, PPanelRec(Key2)^.Ext, ccNone)) - 1;
          end;
        end
        else
        begin
          if SortNameExt then
          begin
            Name := Integer(CompString(
              NamePlusExt(PPanelRec(Key1)^.Name, PPanelRec(Key1)^.Ext, SortMode),
              NamePlusExt(PPanelRec(Key2)^.Name, PPanelRec(Key2)^.Ext, SortMode))) - 1;
            Ext := Name;
          end
          else
          begin
            Name := Integer(CompString(
              PPanelRec(Key1)^.Name, PPanelRec(Key2)^.Name)) - 1;
            Ext := Integer(CompString(
              PPanelRec(Key1)^.Ext, PPanelRec(Key2)^.Ext)) - 1;
          end;
        end;
      end;
    end
    else
    begin
      if SortCaseSens and scDirs = 0 then
      begin
        if SortMixed then
        begin
          if SortNameExt then
          begin
            Name := Integer(CompMixedString(
              NamePlusExt(PPanelRec(Key1)^.Name, PPanelRec(Key1)^.Ext, SortMode),
              NamePlusExt(PPanelRec(Key2)^.Name, PPanelRec(Key2)^.Ext, SortMode), ccUpper)) - 1;
            Ext := Name;
          end
          else
          begin
            Name := Integer(CompMixedString(
              PPanelRec(Key1)^.Name, PPanelRec(Key2)^.Name, ccUpper)) - 1;
            Ext := Integer(CompMixedString(
              PPanelRec(Key1)^.Ext, PPanelRec(Key2)^.Ext, ccUpper)) - 1;
          end;
        end
        else
        begin
          if SortNameExt then
          begin
            Name := Integer(CompUCString(
              NamePlusExt(PPanelRec(Key1)^.Name, PPanelRec(Key1)^.Ext, SortMode),
              NamePlusExt(PPanelRec(Key2)^.Name, PPanelRec(Key2)^.Ext, SortMode))) - 1;
            Ext := Name;
          end
          else
          begin
            Name := Integer(CompUCString(
              PPanelRec(Key1)^.Name, PPanelRec(Key2)^.Name)) - 1;
            Ext := Integer(CompUCString(
              PPanelRec(Key1)^.Ext, PPanelRec(Key2)^.Ext)) - 1;
          end;
        end;
      end
      else
      begin
        if SortMixed then
        begin
          if SortNameExt then
          begin
            Name := Integer(CompMixedString(
              NamePlusExt(PPanelRec(Key1)^.Name, PPanelRec(Key1)^.Ext, SortMode),
              NamePlusExt(PPanelRec(Key2)^.Name, PPanelRec(Key2)^.Ext, SortMode), ccNone)) - 1;
            Ext := Name;
          end
          else
          begin
            Name := Integer(CompMixedString(
              PPanelRec(Key1)^.Name, PPanelRec(Key2)^.Name, ccNone)) - 1;
            Ext := Integer(CompMixedString(
              PPanelRec(Key1)^.Ext, PPanelRec(Key2)^.Ext, ccNone)) - 1;
          end;
        end
        else
        begin
          if SortNameExt then
          begin
            Name := Integer(CompString(
              NamePlusExt(PPanelRec(Key1)^.Name, PPanelRec(Key1)^.Ext, SortMode),
              NamePlusExt(PPanelRec(Key2)^.Name, PPanelRec(Key2)^.Ext, SortMode))) - 1;
            Ext := Name;
          end
          else
          begin
            Name := Integer(CompString(
              PPanelRec(Key1)^.Name, PPanelRec(Key2)^.Name)) - 1;
            Ext := Integer(CompString(
              PPanelRec(Key1)^.Ext, PPanelRec(Key2)^.Ext)) - 1;
          end;
        end;
      end;
    end;
    if not PanelRecHasPath(PPanelRec(Key1)) then Path1 := ''
    else Path1 := PPanelRec(Key1)^.ThePath^;
    if not PanelRecHasPath(PPanelRec(Key2)) then Path2 := ''
    else Path2 := PPanelRec(Key2)^.ThePath^;
    Path := Integer(CompUCString(Path1, Path2)) - 1;
    if (Name = 0) and (Ext = 0) and (Path = 0) then Compare := 0

    else if (PPanelRec(Key1)^.Name[1] in [':', '.']) and
      (PPanelRec(Key1)^.Attr and Directory <> 0) then Compare := -1
    else if (PPanelRec(Key2)^.Name[1] in [':', '.']) and
      (PPanelRec(Key2)^.Attr and Directory <> 0) then Compare := 1

    else if PPanelRec(Key1)^.Attr and VolumeID <> 0 then
      if PPanelRec(Key1)^.Name[1] = 'N' then Compare := 1
      else Compare := -1
    else if PPanelRec(Key2)^.Attr and VolumeID <> 0 then
      if PPanelRec(Key2)^.Name[1] = 'N' then Compare := -1
      else Compare := 1
    else if (PPanelRec(Key1)^.Attr and Directory <> 0) and
      (PPanelRec(Key2)^.Attr and Directory = 0) and
      (SortPriority <> spMixed) then
        if SortPriority = spFilesFirst then Compare := 1
        else Compare := -1
    else if (PPanelRec(Key2)^.Attr and Directory <> 0) and
      (PPanelRec(Key1)^.Attr and Directory = 0) and
      (SortPriority <> spMixed) then
        if SortPriority = spFilesFirst then Compare := -1
        else Compare := 1
    else
    begin
      if PPanelRec(Key1)^.Time = PPanelRec(Key2)^.Time then Time := 0
      else if PPanelRec(Key1)^.Time < PPanelRec(Key2)^.Time then Time := 1
      else Time := -1;
      Sizes := ComparePanelRecSizes(PPanelRec(Key1), PPanelRec(Key2));
      if Options and ofValidate <> 0 then Mode := smName
      else Mode := SortMode;
      if Mode in [smDescr, smFilesBBS] then Mode := smName;
      if (Mode = smName) or BothDirsByName then
      begin
        if Name <> 0 then C := Name
        else if Ext <> 0 then C := Ext
        else if Time <> 0 then C := Time
        else if Sizes <> 0 then C := Sizes
        else if Path <> 0 then C := Path
        else C := -1;
      end
      else if Mode = smExt then
      begin
        if Ext <> 0 then C := Ext
        else if Name <> 0 then C := Name
        else if Time <> 0 then C := Time
        else if Sizes <> 0 then C := Sizes
        else if Path <> 0 then C := Path
        else C := -1;
      end
      else if Mode = smTime then
      begin
        if Time <> 0 then C := Time
        else if Name <> 0 then C := Name
        else if Ext <> 0 then C := Ext
        else if Sizes <> 0 then C := Sizes
        else if Path <> 0 then C := Path
        else C := 1;
      end
      else if Mode = smSize then
      begin
        if Sizes <> 0 then C := Sizes
        else if Name <> 0 then C := Name
        else if Ext <> 0 then C := Ext
        else if Time <> 0 then C := Time
        else if Path <> 0 then C := Path
        else C := 1;
      end
      else if Mode = smNumber then
      begin
        if (Status <= stFull) and
           ((Settings and seLongNames <> 0) or (ColWidth <> 13)) then
          Number := GetNameNumber(Name1, Ext1, Name2, Ext2,
            GroupOptions and fgSortDigitsAsChars <> 0)
        else Number := GetNameNumber(
          PPanelRec(Key1)^.Name, PPanelRec(Key1)^.Ext,
          PPanelRec(Key2)^.Name, PPanelRec(Key2)^.Ext,
            GroupOptions and fgSortDigitsAsChars <> 0);
        if Number <> 0 then C := Number
        else if Name <> 0 then C := Name
        else if Ext <> 0 then C := Ext
        else if Time <> 0 then C := Time
        else if Sizes <> 0 then C := Sizes
        else if Path <> 0 then C := Path
        else C := -1;
      end
      else if Path <> 0 then C := Path
      else C := -1;
      if GroupOptions and fgSortByIndex <> 0 then
      begin
        Index1 := PPanelRec(Key1)^.Index;
        Index2 := PPanelRec(Key2)^.Index;
        if Index1 = 0 then Index1 := 255;
        if Index2 = 0 then Index2 := 255;
        if Index1 <> Index2 then
          if (SortIndexStr <> nil) and (SortIndexStr^ <> '') then
            SortByIndexStr(SortIndexStr^, Index1, Index2, C)
          else if Index1 > Index2 then C := 1
          else if Index1 < Index2 then C := -1;
      end;
      if SortSel then
      begin
        if PPanelRec(Key1)^.Selected and
          not PPanelRec(Key2)^.Selected then
            if Byte(SortSel) <> 1 then C := 1
            else C := -1
        else if not PPanelRec(Key1)^.Selected and
          PPanelRec(Key2)^.Selected then
            if Byte(SortSel) <> 1 then C := -1
            else C := 1
        else if (C <> 0) and (SortDirection = sdDescending) then C := -C;
      end
      else if (C <> 0) and (SortDirection = sdDescending) then C := -C;
      Compare := C;
    end;
  end;
end;

procedure TPanelCollection.FreeItem(Item: Pointer);
begin
{
  DisposeStr(PPanelRec(Item)^.ThePath);
  FreeMem(Item, SizeOf(TPanelRec));
}
  DisposeStrUMB(PPanelRec(Item)^.ThePath);
  FreeMemUMB(Item, SizeOf(TPanelRec));
end;

procedure TPanelCollection.Insert(Item: Pointer);
var
  CanInsert: Boolean;
  I: Integer;
  P: PPanelRec;
begin
  if not Search(Item, I) then
  begin
    if Count < Limit then CanInsert := MaxAvail > SafetyPool
    else CanInsert := MaxAvail > LongMul(Limit + Delta, 4) + SafetyPool;
    if not CanInsert then Full := True;
    if not CanInsert or
      ((PPanelRec(Item)^.Color = 0) and (Owner <> nil) and
       (PPanel(Owner)^.GroupOptions and fgGroupHighlight <> 0)) then
         FreeItem(Item)
    else AtInsert(I, Item);
  end
  else
  begin
    P := At(I);
    Move(Item^, P^, SizeOf(Byte) + SizeOf(Longint) + SizeOf(Longint));
    FreeItem(Item);
  end;
end;

procedure TPanelCollection.Sort;
var
  Abort: Boolean;
  C: CompareType;
  J, M: Integer;
  Panel: PPanel;
  P1, P2: PPanelRec;
  F1, F2: PFilesBBSRec;
  S1, S2: String;

function LessItem(N1, N2: Integer): Boolean;
begin
  if N1 = N2 then
  begin
    LessItem := False;
    Exit;
  end;
  P1 := At(N1);
  P2 := At(N2);
  if (Panel^.SortMode in [smDescr, smFilesBBS]) and
     (Panel^.FilesBBS^.Count = Count) and
     (P1^.Attr and Directory = 0) and
     (P2^.Attr and Directory = 0) and
     (not Panel^.SortSel or
       ((Byte(P1^.Selected) <> 0) = (Byte(P2^.Selected) <> 0))) then
  begin
    F1 := Panel^.FilesBBS^.At(N1);
    F2 := Panel^.FilesBBS^.At(N2);
    if Panel^.SortMode = smFilesBBS then Str(F1^.Num:5, S1)
    else if F1^.Text = nil then S1 := ''
    else S1 := Copy(F1^.Text^, Panel^.SortDescrPos, 255);
    if Panel^.SortMode = smFilesBBS then Str(F2^.Num:5, S2)
    else if F2^.Text = nil then S2 := ''
    else S2 := Copy(F2^.Text^, Panel^.SortDescrPos, 255);
    if Panel^.SortCaseSens and scDesc <> 0 then
      C := CompString(S1, S2)
    else C := CompUCString(S1, S2);
    if C = Equal then {}
    else
    begin
      LessItem := C = Less;
      Exit;
    end;
  end;
  LessItem := Compare(P1, P2) = -1;
end;

procedure QuickSort(L, R: Integer);
var
  I: Integer;
begin
  if StackOverflow then
  begin
    Abort := True;
    Exit;
  end;
  repeat
    I := L;
    J := R;
    M := (L + R) shr 1;
    repeat
      while LessItem(I, M) do Inc(I);
      while LessItem(M, J) do Dec(J);
      if I < J then
      begin
        P1 := Items^[I];
        Items^[I] := Items^[J];
        Items^[J] := P1;

        if Panel^.FilesBBS^.Count = Count then
        begin
          F1 := Panel^.FilesBBS^.Items^[I];
          Panel^.FilesBBS^.Items^[I] := Panel^.FilesBBS^.Items^[J];
          Panel^.FilesBBS^.Items^[J] := F1;
        end;
      end;

      if I <= J then
      begin
        if M = I then M := J
        else if M = J then M := I;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSort(L, J);
    L := I;
  until Abort or (I >= R);
end;

begin
  if Count <> 0 then
  begin
    Panel := Owner;
    Abort := False;
    QuickSort(0, Count - 1);
  end;
end;

procedure TTempGroupList.FreeItem(Item: Pointer);
begin
  if Item <> nil then FreeMem(Item, SizeOf(TTempGroupRec));
end;

procedure InitTempGroups;
var
  I, J: Integer;
  P: PGroupRec;
  R: PTempGroupRec;
  Mask: String[12];
begin
  if TempGroups <> nil then Exit;
  TempGroups := New(PTempGroupList, Init(8, 8));
  for I := 0 to Groups^.Count - 2 do
  begin
    GetMem(R, SizeOf(TTempGroupRec));
    FillChar(R^, SizeOf(TTempGroupRec), ' ');
    P := Groups^.At(I);
    R^.Dir := Byte(P^.Mask[0]) and $80 <> 0;
    if R^.Dir then Byte(P^.Mask[0]) := Byte(P^.Mask[0]) and not $80;
    Mask := StUpcase(P^.Mask);
    if R^.Dir then Byte(P^.Mask[0]) := Byte(P^.Mask[0]) or $80;
    J := Pos('.', Mask);
    if (J <> 0) and (Mask[1] <> '.') then
    begin
      R^.MaskName := Copy(Mask, 1, J - 1);
      R^.MaskExt :=  Copy(Mask, J + 1, 3);
    end
    else
    begin
      R^.MaskName := Mask;
      R^.MaskExt[0] := #3;
    end;
    ExpandName(R^.MaskName, 8);
    ExpandName(R^.MaskExt, 3);
    R^.Color := P^.Color;
    R^.Index := P^.Index;
    TempGroups^.Insert(R);
  end;
end;

procedure DoneTempGroups;
begin
  if TempGroups = nil then Exit;
  Dispose(TempGroups, Done);
  TempGroups := nil;
end;

procedure GetGroupInfo(const Name, Ext: String; Dir: Boolean;
  var Color, Index: Byte);
var
  I, II: Integer;
  P: PTempGroupRec;
  AExt: String[3];
  AName: String[8];
label
  NextRec;
begin
asm
  cld
  mov di,sp
  push ss
  pop es
  mov al,' '
  mov cx,bp
  sub cx,di
  rep stosb
end;
  AName := StUpcase(Name);
  AName[0] := #8;
  AExt := StUpcase(Ext);
  AExt[0] := #3;
  for I := 0 to TempGroups^.Count - 1 do
  begin
    P := TempGroups^.At(I);
    if P^.Dir <> Dir then Goto NextRec;
    for II := 1 to 3 do
      if (P^.MaskExt[II] <> '?') and
         not ((P^.MaskExt[II] = '+') and (AExt[II] in DigitChars)) and
         (P^.MaskExt[II] <> AExt[II]) then Goto NextRec;
    for II := 1 to 8 do
      if (P^.MaskName[II] <> '?') and
         not ((P^.MaskName[II] = '+') and (AName[II] in DigitChars)) and
         (P^.MaskName[II] <> AName[II]) then Goto NextRec;
    Color := P^.Color;
    Index := P^.Index;
    Exit;
NextRec:
  end;
end;

function PanelRecHasPath(P: PPanelRec): Boolean;
begin
  PanelRecHasPath := (P^.ThePath <> nil) and (P^.ThePath^[1] <> #$FF);
end;

procedure AddNameExt(const Path: FNameStr; P: PPanelRec; var S: FNameStr);
begin
  if PanelRecHasPath(P) and (P^.ThePath^[1] = #0) then
  begin
    if Pos(':', P^.ThePath^) <> 0 then
      S := Concat(Path, Copy(P^.ThePath^, 2, 255))
    else S := Concat(Path, JustFileName(Copy(P^.ThePath^, 2, 255)))
  end
  else
  begin
    S := Concat(Path, P^.Name);
    if P^.Ext <> '' then S := Concat(S, '.', P^.Ext);
  end;
end;

function PanelRecPath(P: PPanelRec): FNameStr;
begin
  if not PanelRecHasPath(P) then PanelRecPath := ''
  else if P^.ThePath^[1] = #0 then
    PanelRecPath := ClearedSlash(JustPathName(Copy(P^.ThePath^, 2, 255)))
  else PanelRecPath := P^.ThePath^;
end;

function NameMatchesMultiMask(const Name, Mask: String;
  PipePos: Byte): Boolean;
var
  B, E, L: Byte;
begin
  L := Length(Mask);
  if PipePos <> 0 then
  begin
    E := PipePos + 1;
    repeat
      while (E <= L) and (Mask[E] in [{' ',} ';', ',']) do Inc(E);
      if E > L then Break;
      B := E;
      while (E <= L) and not (Mask[E] in [{' ',} ';', ',']) do Inc(E);
      if WildCardMatch(Name, Copy(Mask, B, E - B)) then
      begin
        NameMatchesMultiMask := False;
        Exit;
      end;
    until False;
  end;
  NameMatchesMultiMask := True;
  if PipePos = 1 then Exit;
  if PipePos <> 0 then L := PipePos - 1;
  E := 1;
  repeat
    while (E <= L) and (Mask[E] in [{' ',} ';', ',']) do Inc(E);
    if E > L then Break;
    B := E;
    while (E <= L) and not (Mask[E] in [{' ',} ';', ',']) do Inc(E);
    if WildCardMatch(Name, Copy(Mask, B, E - B)) then Exit;
  until False;
  NameMatchesMultiMask := False;
end;

function AdvancedFilterPassed(P: PFilterRec; States: Pointer;
  var SR: SearchRec; const ALongName: FNameStr): Boolean;
var
  I: Integer;
  R: Real;
  Ext: String[3];
  Name: String[12];
begin
  R := lGetFileRealSize(SR.Attr, SR.Size);
  if ((P^.Attr and AnyFile <> AnyFile) and (SR.Attr and P^.Attr = 0)) or
     ((P^.LoSize >= 0) and (R < P^.LoSize)) or
     ((P^.HiSize >= 0) and (R > P^.HiSize)) or
     ((P^.LoTime <> -1) and (SR.Time < P^.LoTime)) or
     ((P^.HiTime <> -1) and (SR.Time > P^.HiTime)) then
    AdvancedFilterPassed := False
  else
  begin
    if ALongName = '' then
    begin
      I := Pos('.', SR.Name);
      if I = 0 then
      begin
	Name := SR.Name;
	TrimSt(Name);
	Ext := '';
      end
      else
      begin
	Name := Copy(SR.Name, 1, I - 1);
	TrimSt(Name);
	Ext := Copy(SR.Name, I + 1, 3);
	TrimSt(Ext);
      end;
      Name := Concat(Name, '.', Ext);
    end;
    if P^.Unix then
      if ALongName <> '' then AdvancedFilterPassed :=
	IsAcceptable(ALongName, PState(States)^)
      else AdvancedFilterPassed :=
	IsAcceptable(Name, PState(States)^)
    else if ALongName <> '' then AdvancedFilterPassed :=
      NameMatchesMultiMask(ALongName, P^.Text^, P^.PipePos)
    else AdvancedFilterPassed :=
      NameMatchesMultiMask(Name, P^.Text^, P^.PipePos);
  end;
end;

end.