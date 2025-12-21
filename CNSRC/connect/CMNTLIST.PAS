{$I-,X+}
unit CmntList;

interface

uses Objects;

type
  MaskStr = String[12];
  CommentStr = String[127];

  PPrnRec = ^TPrnRec;
  TPrnRec = record
    PrnSign: Byte;
    PrnDeviceName: PString;
    PrnFontName: PString;
    PrnInitString: PString;
    PrnLeftMargin: PString;
    PrnTopMargin: PString;
    PrnBottomMargin: PString;
    PrnLinesPerPage: PString;
    PrnInterval: PString;
    PrnCharsPerCycle: PString;
    PrnOptions: Word;
  end;

  PCommentRec = ^TCommentRec;
  TCommentRec = record
    Mask: PString;
    Comment: PString;
    HelpName: PString;
    INXLATName: PString;
    OUTXLATName: PString;
    MacroName: PString;
    SyntaxName: PString;
    PrnRec: PPrnRec;
    Options: Longint;
    TabSize: Byte;
    MaxLineWidth: Byte;
    WordDelims: TCharSet;
    NewOptions: Byte;
  end;

  PCommentList = ^TCommentList;
  TCommentList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

procedure InitComments(const Name: FNameStr);
procedure DoneComments;
procedure GetComment(const Name: FNameStr;
  var Comment: CommentStr; var Options: Longint;
  var TabSize: Byte; var MaxLineWidth: Byte;
  var WordDelims: TCharSet; var NewOptions: Word;
  var HelpName, INXLATName, OUTXLATName, MacroName, SyntaxName: PString;
  var PrnRec: PPrnRec; SkipOptions: Boolean);
procedure DisposePrnRec(P: PPrnRec);
procedure DisposeCommentRec(P: PCommentRec);

const
  Comments: PCommentList = nil;
  eoRegExpComment = $80000000;

  crHasPrnRec = 1;
  crHasMacros = 2;

  NewCmtSign: String[6] = 'CNCMT1';

implementation

uses Dos, DirPrim, LFN, HeapUMB, TPString;

procedure DisposePrnRec(P: PPrnRec);
begin
  if P <> nil then
  begin
{
    DisposeStr(P^.PrnCharsPerCycle);
    DisposeStr(P^.PrnInterval);
    DisposeStr(P^.PrnLinesPerPage);
    DisposeStr(P^.PrnBottomMargin);
    DisposeStr(P^.PrnTopMargin);
    DisposeStr(P^.PrnLeftMargin);
    DisposeStr(P^.PrnInitString);
    DisposeStr(P^.PrnFontName);
    DisposeStr(P^.PrnDeviceName);
    FreeMem(P, SizeOf(TPrnRec));
}
    DisposeStrUMB(P^.PrnCharsPerCycle);
    DisposeStrUMB(P^.PrnInterval);
    DisposeStrUMB(P^.PrnLinesPerPage);
    DisposeStrUMB(P^.PrnBottomMargin);
    DisposeStrUMB(P^.PrnTopMargin);
    DisposeStrUMB(P^.PrnLeftMargin);
    DisposeStrUMB(P^.PrnInitString);
    DisposeStrUMB(P^.PrnFontName);
    DisposeStrUMB(P^.PrnDeviceName);
    FreeMemUMB(P, SizeOf(TPrnRec));
  end;
end;

procedure DisposeCommentRec(P: PCommentRec);
begin
  if P <> nil then
  begin
    DisposePrnRec(P^.PrnRec);
{
    DisposeStr(P^.SyntaxName);
    DisposeStr(P^.MacroName);
    DisposeStr(P^.OUTXLATName);
    DisposeStr(P^.INXLATName);
    DisposeStr(P^.HelpName);
    DisposeStr(P^.Comment);
    DisposeStr(P^.Mask);
    FreeMem(P, SizeOf(TCommentRec));
}
    DisposeStrUMB(P^.SyntaxName);
    DisposeStrUMB(P^.MacroName);
    DisposeStrUMB(P^.OUTXLATName);
    DisposeStrUMB(P^.INXLATName);
    DisposeStrUMB(P^.HelpName);
    DisposeStrUMB(P^.Comment);
    DisposeStrUMB(P^.Mask);
    FreeMemUMB(P, SizeOf(TCommentRec));
  end;
end;

procedure TCommentList.FreeItem(Item: Pointer);
begin
  DisposeCommentRec(PCommentRec(Item));
end;

procedure InitComments(const Name: FNameStr);
var
  NewCmt: Boolean;
  Sign: String[6];
  P: PCommentRec;
  S: TDosStream;
begin
  Comments := New(PCommentList, Init(8, 8));
  S.Init(Name, stOpenRead);
  Sign[0] := #6;
  S.Read(Sign[1], 6);
  NewCmt := (S.Status = stOk) and (Sign = NewCmtSign);
  if not NewCmt then S.Seek(0);
  while S.Status = stOk do
  begin
{
    GetMem(P, SizeOf(TCommentRec));
    P^.Mask := S.ReadStr;
    P^.Comment := S.ReadStr;
    P^.HelpName := S.ReadStr;
    P^.INXLATName := S.ReadStr;
    P^.OUTXLATName := S.ReadStr;
}
    GetMemUMB(P, SizeOf(TCommentRec));
    P^.Mask := ReadStrUMB(@S);
    P^.Comment := ReadStrUMB(@S);
    P^.HelpName := ReadStrUMB(@S);
    P^.INXLATName := ReadStrUMB(@S);
    P^.OUTXLATName := ReadStrUMB(@S);
    S.Read(P^.NewOptions, SizeOf(Byte));
    if P^.NewOptions and crHasMacros = 0 then P^.MacroName := nil
    else
{      P^.MacroName := S.ReadStr;}
      P^.MacroName := ReadStrUMB(@S);
    if not NewCmt then P^.SyntaxName := nil
    else
{      P^.SyntaxName := S.ReadStr;}
      P^.SyntaxName := ReadStrUMB(@S);
    if P^.NewOptions and crHasPrnRec = 0 then P^.PrnRec := nil
    else
    begin
{
      GetMem(P^.PrnRec, SizeOf(TPrnRec));
      P^.PrnRec^.PrnSign := B;
      P^.PrnRec^.PrnDeviceName := S.ReadStr;
      P^.PrnRec^.PrnFontName := S.ReadStr;
      P^.PrnRec^.PrnInitString := S.ReadStr;
      P^.PrnRec^.PrnLeftMargin := S.ReadStr;
      P^.PrnRec^.PrnTopMargin := S.ReadStr;
      P^.PrnRec^.PrnBottomMargin := S.ReadStr;
      P^.PrnRec^.PrnLinesPerPage := S.ReadStr;
      P^.PrnRec^.PrnInterval := S.ReadStr;
      P^.PrnRec^.PrnCharsPerCycle := S.ReadStr;
}
      GetMemUMB(P^.PrnRec, SizeOf(TPrnRec));
      P^.PrnRec^.PrnSign := P^.NewOptions;
      P^.PrnRec^.PrnDeviceName := ReadStrUMB(@S);
      P^.PrnRec^.PrnFontName := ReadStrUMB(@S);
      P^.PrnRec^.PrnInitString := ReadStrUMB(@S);
      P^.PrnRec^.PrnLeftMargin := ReadStrUMB(@S);
      P^.PrnRec^.PrnTopMargin := ReadStrUMB(@S);
      P^.PrnRec^.PrnBottomMargin := ReadStrUMB(@S);
      P^.PrnRec^.PrnLinesPerPage := ReadStrUMB(@S);
      P^.PrnRec^.PrnInterval := ReadStrUMB(@S);
      P^.PrnRec^.PrnCharsPerCycle := ReadStrUMB(@S);
      S.Read(P^.PrnRec^.PrnOptions, SizeOf(Word));
    end;
    S.Read(P^.Options,
      SizeOf(Longint) + SizeOf(Byte) * 2 + SizeOf(TCharSet));
    if S.Status <> stOk then DisposeCommentRec(P)
    else Comments^.Insert(P);
  end;
  S.Done;
  Comments^.Insert(nil);
end;

procedure DoneComments;
begin
  if Comments <> nil then Dispose(Comments, Done);
end;

procedure GetComment(const Name: FNameStr;
  var Comment: CommentStr; var Options: Longint;
  var TabSize: Byte; var MaxLineWidth: Byte;
  var WordDelims: TCharSet; var NewOptions: Word;
  var HelpName, INXLATName, OUTXLATName, MacroName, SyntaxName: PString;
  var PrnRec: PPrnRec; SkipOptions: Boolean);
var
  I: Integer;
  P: PCommentRec;
  N: String;
begin
  Comment := '';
  N := JustFileName(Name);
  if N <> '' then for I := 0 to Comments^.Count - 2 do
  begin
    P := Comments^.At(I);
    if (P^.Mask <> nil) and WildCardMatch(N, P^.Mask^) then
    begin
      Comment := P^.Comment^;
      if not SkipOptions then
      begin
	Options := P^.Options;
	TabSize := P^.TabSize;
	MaxLineWidth := P^.MaxLineWidth;
	WordDelims := P^.WordDelims;
	NewOptions := P^.NewOptions;
      end;
      HelpName := P^.HelpName;
      INXLATName := P^.INXLATName;
      OUTXLATName := P^.OUTXLATName;
      MacroName := P^.MacroName;
      SyntaxName := P^.SyntaxName;
      PrnRec := P^.PrnRec;
      Exit;
    end;
  end;
end;

end.