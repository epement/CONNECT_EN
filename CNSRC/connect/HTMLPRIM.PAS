{$F+,I-,O+,X+}
unit HtmlPrim;

interface

Uses Objects;

const
 Tags = 'A B BR CENTER DD DL DT EM FRAME H1 H2 H3 H4 H5 H6 HL HR I ' +
        'IMG LH LI LINK LISTING MENU OL P PRE SAMP TABLE TD TH ' +
        'TITLE TR TT UL XMP .LOCKQUOTE DIV AREA DIR CAPTION STYLE SCRIPT ';

 MaxOLLevel = 32;
 LStackSize = 64;

 xAlt = 0;
 xKoi = 1;
 xWin = 2;
 xTbl = $FF;

type
 TTag = (NUL, A, B, BR, CENTER, DD, DL, DT, EM, FRAME, H1, H2, H3,
         H4, H5, H6, HL, HR, I, IMG, LH, LI, LINK, LISTING, MENU, OL,
         P, PRE, SAMP, TABLE, TD, TH, TITLE, TR, TT, UL, XMP,
         BLOCKQUOTE, DIV_, AREA, DIR, CAPTION, STYLE, SCRIPT);

type
 PHTMLStream = ^THTMLStream;
 THTMLStream = object(TDosStream)
   Name: PString;
   Buffer: PByteArray;
   BufSize: Word;
   BufPtr: Word;
   BufEnd: Word;
   Position, Size: Longint;
   Percent: Byte;
   constructor Init(const FileName: FNameStr; Mode, ASize: Word);
   destructor Done; virtual;
   function GetCh: Char;
   procedure UngetCh(Count: Longint);
   function GetPosition: Longint;
   procedure SetPosition(Count: Longint);
   function GetPercent(var APercent: Byte): Boolean;
 end;

 PTables = ^TTables;
 TTables = Object(TObject)
  Table: PCollection;
  Caption: String;
  Cols, ColSize: Byte;
  Rows, LastRows: Integer;
  BrLine,
  OutOfMemory: Boolean;
  constructor Init(ACols, AColSize: Byte);
  procedure AddRow;
  procedure AddData;
  procedure AddCellStr(var STxt, SAttr: String);
  function GetLine: Integer;
  function GetPos: Integer;
  function GetOutLine: String;
  destructor Done; virtual;
 end;

 THtmlState = Record
  aRef,         {<a href></a>}
  RefIns,
  aName,        {<a name></a>}
  Pre,          {<pre></pre>}
  LISTING,      {<LISTING></LISTING>}
  XMP,          {<XMP></XMP>}
  Hdr,          {<h1></h1> <h2></h2> <h3></h3> <h4></h4>}
                {<h5></h5> <h6></h6>}
  THdr,         {<th>}
  OrdList,      {<ol></ol>}
  UList,        {<ul></ul>}
  DList,        {<dl></dl>}
  MList,        {<MENU></MENU>}
  Quote,        {<BLOCKQUOTE></BLOCKQUOTE>}
  ListHdr,      {<hl></hl>}
  Center,       {<center></center>}
  Tbl,          {<TABLE> </TABLE>}
  TableRow,     {<tr></tr>}
  TableData,    {<td></td>}
  TblCaption,   {<CAPTION></CAPTION>}
  Title,        {<title></title>}
  Para,         {<p>}
  LineBreak,    {<br>}
  LineList,     {<li><dt>}
  TabLine,      {<dd>}
  HorLine,      {<hr>}
  Image,        {<IMG SRC>}
  Area,         {<AREA>}
  Link,         {<LINK>}
  Frame,        {<FRAME>}
  Rem,
  Style,        {<STYLE> </STYLE>}
  Script        {<SCRIPT> </SCRIPT>}
                 : Boolean;
  EndCenter,
  StartCenter,
  NewLine: Boolean;
  Margin: Byte;
  Attr: Char;
  HighLite: Byte;
  OLLevel: Byte;
  OLNums: Array[1..MaxOLLevel] of Word;
  LStack: Array[0..LStackSize - 1] of TTag;
  LStackPtr: Byte;
  aTag: Byte;
  PTable: PTables;
  TblChars: LongInt;
  TblCol, MaxTblCol: Byte;
  TblCnt,
  TblPass: Byte;
  RowData,
  StartTable,
  EndTable : Boolean;
 end;

 PRefItem = ^TRefItem;
 TRefItem = record
  Line1: Integer;
  Pos1: Byte;
  Line2: Integer;
  Pos2: Byte;
  PFName, PRefName: PString;
  Scrolling: Boolean;
 end;

 PNameItem = ^TNameItem;
 TNameItem = record
  Line: Integer;
  Pos: Byte;
  PRefName: PString;
 end;

 PRefColl = ^TRefColl;
 TRefColl = object(TSortedCollection)
  Ref: TRefItem;
  function Compare(Key1, Key2: Pointer): Integer; virtual;
  procedure FreeItem(Item: Pointer); virtual;
  function CurRef(Y: Integer; X: Byte): PRefItem;
  function NextRef(Y: Integer; X: Byte; Back: Boolean): PRefItem;
 end;

 PNameColl  = ^TNameColl;
 TNameColl = object(TSortedCollection)
  IgnorePos: Boolean;
  function Compare(Key1, Key2: Pointer): Integer; virtual;
  procedure FreeItem(Item: Pointer); virtual;
 end;

 PHtml = ^THtml;
 THtml = object(TObject)
  FHtml: PHTMLStream;
  State: THtmlState;
  HtmlTitle: String;
  Alt, Koi, Win: Longint;
  TagPos: String[Length(Tags)+2];
  PTags: PString;
  STag: String;
  STxt: String[128];
  Line: Integer;
  Limit: Byte;
  Names: PNameColl;
  Refs: PRefColl;
  TableTag, FirstLine: Boolean;
  constructor Init(ALimit: Byte; ATableTag: Boolean);
  destructor Done; virtual;
  function InitStream(const FName: String; FromArchive: Boolean): Boolean;
  procedure DoneStream;
  function Pos2Tag(Ps: Byte): TTag;
  procedure Tag2State(StTag: String);
  procedure AddRefStart;
  procedure AddRefEnd;
  procedure AddImage(Len: Byte; PFName: PString; Scrolling: Boolean);
  procedure AddName;
  function GetLine: String;
 end;

{$IFNDEF DEBUG}
procedure FillXLATTable(Kind: Byte; var T);
{$ENDIF}

implementation

{$IFDEF DEBUG}
uses Memory, Strings, tpString, RevPos, GetID, StrCol;

function NewStrUMB(const S: String): PString;
begin
 NewStrUMB := NewStr(S);
end;

procedure DisposeStrUMB(P:PString);
begin
 DisposeStr(P);
end;

procedure GetMemUMB(var P: Pointer;  Size: Word);
begin
 GetMem(P, Size);
end;

procedure FreeMemUMB(var P: Pointer;  Size: Word);
begin
 FreeMem(P, Size);
end;

function MemAvailUMB: Longint;
begin
 MemAvailUMB := MemAvail;
end;

const
 atNormalText = #$07;
 atBoldText = #$09;
 atRefText = #$0f;
{$ELSE}
uses Drivers, Views, Memory, Strings, App, RevPos, GetID, StrCol, HeapUMB,
  EditMsg, DirPrim, Swaps, Keyboard, TPString, Commands, Defaults;

const
 atNormalText = #231;
 atBoldText = #232;
 atRefText = #234;
{$ENDIF}

 ImageStr = ' [IMAGE] ';
 LinkStr = ' [LINK] ';
 FrameStr = ' [FRAME] ';
 MapStr = ' [MAP] ';

 BufOverlap = $100;

 AltSet = [#160 .. #175, #224 .. #239];
 KoiSet = [#193 .. #208, #210 .. #213, #198, #195, #219 .. #223, #217, #216, #192, #209];
 WinSet = [#224 .. #239, #240 .. #255];

 SpecSet = ['#', '0'..'9', 'A'..'Z', 'a'..'z'];

function CollCanInsert(P: PCollection): Boolean;
begin
 CollCanInsert :=
  not ((P^.Count = MaxCollectionSize) or
       ((P^.Count = P^.Limit) and
        (MaxAvail <= LongMul(P^.Limit + P^.Delta, 4) + $2000)));
end;

constructor THTMLStream.Init(const FileName: FNameStr; Mode, ASize: Word);
begin
  Inherited Init(FileName, Mode);
  Name := NewStr(FileName);
  BufSize := ASize + BufOverlap;
  Size := GetSize;
  GetMem(Buffer, BufSize);
end;

destructor THTMLStream.Done;
begin
  FreeMem(Buffer, BufSize);
  DisposeStr(Name);
  Inherited Done;
end;

function THTMLStream.GetCh: Char;
begin
  if BufPtr >= BufEnd then
  begin
    BufPtr := BufOverlap;
    if BufEnd > BufOverlap then
      Move(Buffer^[BufEnd - BufOverlap], Buffer^[0], BufOverlap);
    ReadBlock(Buffer^[BufPtr], BufSize - BufOverlap, BufEnd);
    if BufEnd = 0 then
    begin
      Error(stReadError, 0);
      GetCh := #0;
      Exit;
    end;
    Inc(BufEnd, BufOverlap);
  end;
  GetCh := Char(Buffer^[BufPtr]);
  Inc(BufPtr);
  Inc(Position);
end;

procedure THTMLStream.UnGetCh(Count: Longint);
begin
 if BufPtr > Count then Dec(BufPtr, Count)
 else
  begin
   Seek(GetPos - BufEnd + BufPtr - Count + 1);
   BufPtr := 0;
   BufEnd := 0;
  end;
 if Position > 0 then Dec(Position, Count);
end;

function THTMLStream.GetPosition: Longint;
begin
  GetPosition := Position;
end;

procedure THTMLStream.SetPosition(Count: Longint);
begin
 Seek(Count);
 BufPtr := 0;
 BufEnd := 0;
 Position := Count;
end;

function THTMLStream.GetPercent(var APercent: Byte): Boolean;
var
 P: Byte;
begin
 if Size = 0 then P := 100
 else P := Position * 100 div Size;
 APercent := P;
 GetPercent := P <> Percent;
 Percent := P;
end;

function GetStrAddr(const S: String): PString; inline($58/$5A);

procedure AddStr(var S: String; C: Char; Count: Byte); assembler;
asm
 mov cl, Count
 xor ch, ch
 jcxz @@1
@@0:
 les di, S
 inc byte ptr es:[di]
 mov al, byte ptr es:[di]
 xor ah, ah
 add di, ax
 mov al, C
 mov byte ptr es:[di], al
 loop @@0
@@1:
end;

function Space(Count : Byte) : String;
var
 SSS : String;
begin
 SSS[0] := Char(Count);
 FillChar(SSS[1],Count,' ');
 Space := SSS;
end;

function DupChar(Ch: Char; Count : Byte) : String;
var
 SSS : String;
begin
 SSS[0] := Char(Count);
 FillChar(SSS[1],Count, Ch);
 DupChar := SSS;
end;

function Num2Str(Num:Byte): String;
var
 S: String;
begin
 Str(Num:3, S);
 AddStr(S, '.', 1);
 AddStr(S, ' ', 1);
 Num2Str := S;
end;

function NumW2Str(Num: Word): String;
var
 S: String;
begin
 Str(Num:5, S);
 AddStr(S, '.', 1);
 AddStr(S, ' ', 1);
 NumW2Str := S;
end;

function Pad(S: String; B: Byte; FillCh, EndCh: Char): String;
var
 Attr: Char;
begin
 Attr := S[Length(S)];
 if Attr = #0 then Attr := atNormalText;
 S[Length(S)] := Attr;
 if B < 127 then
  begin
   while Length(S) < B * 2 do
    begin
     AddStr(S, FillCh, 1);
     AddStr(S, Attr, 1);
    end;
   AddStr(S, EndCh, 1);
   AddStr(S, atNormalText, 1);
  end;
 Pad := S;
end;

{$IFDEF DEBUG}

function SA2S(const S: String): String;
var
 i: Byte;
 SS: String;
begin
 SS := '';
 i := 1;
 while i < Length(S) do
  begin
   AddStr(SS, S[i], 1);
   Inc(i, 2);
  end;
 SA2S := SS;
end;
{$ENDIF}


constructor TTables.Init(ACols, AColSize: Byte);
begin
 inherited Init;
 Table := New(PCollection, Init(10, 10));
 ColSize := AColSize-1;
 Cols := ACols;
end;

procedure TTables.AddRow;
var
 Row: PCollection;
begin
 Row := New(PCollection, Init(10, 10));
 OutOfMemory := not CollCanInsert(Table);
 if OutOfMemory then Dispose(Row, Done)
 else
  begin
   if Table <> Nil then Table^.Insert(Row);
   Inc(Rows, LastRows);
   if LastRows <> 0 then Inc(Rows); {Break line}
   LastRows := 0;
  end;
end;

procedure TTables.AddData;
var
 Data: PStringsCollection;
 Row: PCollection;
begin
 Data := New(PStringsCollection, Init(10, 10));
 OutOfMemory := not CollCanInsert(Row);
 if OutOfMemory then Dispose(Data, Done)
 else
  begin
   Row := Table^.At(Table^.Count - 1);
   if Row <> Nil then Row^.Insert(Data);
  end;
end;

procedure TTables.AddCellStr(var STxt, SAttr: String);
var
 Row: PCollection;
 Data: PStringsCollection;
 i: Integer;
 S: String;
begin
 if STxt = '' then Exit;
 S := '';
 for i := 1 to Length(STxt) do
  begin
   AddStr(S, STxt[i], 1);
   AddStr(S, SAttr[i], 1);
  end;
 if S = '' then S := ' '#0;
 STxt := ''; SAttr := '';
 if (Table <> Nil) and (Table^.Count > 0) then
  begin
   Row := Table^.At(Table^.Count - 1);
   if (Row <> Nil) and (Row^.Count > 0) then
    begin
     Data := Row^.At(Row^.Count - 1);
     OutOfMemory := not CollCanInsert(Data);
     if OutOfMemory then Exit;
     if Data <> Nil then Data^.Insert(NewStrUMB(S));
     if LastRows < Data^.Count then LastRows := Data^.Count;
    end;
  end;
end;

function TTables.GetLine: Integer;
var
 Row: PCollection;
 Data: PStringsCollection;
begin
 GetLine := Rows;
 if (Table <> Nil) and (Table^.Count > 0) then
  begin
   Row := Table^.At(Table^.Count - 1);
   if (Row <> Nil) and (Row^.Count > 0) then
    begin
     Data := Row^.At(Row^.Count - 1);
     GetLine := Rows + Data^.Count;
    end;
   end;
end;

function TTables.GetPos: Integer;
var
 Row: PCollection;
 Data: PStringsCollection;
begin
 GetPos := 0;
 if (Table <> Nil) and (Table^.Count > 0) then
  begin
   Row := Table^.At(Table^.Count - 1);
   if (Row <> Nil) and (Row^.Count > 0) then
    GetPos := (Row^.Count - 1) * (ColSize + 1);
  end;
end;

function TTables.GetOutLine: String;
var
 j, k: Integer;
 Empty: Boolean;
 Row: PCollection;
 Data: PStringsCollection;
 S: String;
begin
 S := '';
 if Caption <> '' then
  begin
   GetOutLine :=  Pad(Caption, (Cols) * (ColSize + 1) - 1, ' ', '|');
   Caption := '';
   Exit;
  end
 else
  repeat
   if (Table <> Nil) and (Table^.Count > 0) then
    begin
     Row := Table^.At(0);
     if (Row <> Nil) and (Row^.Count > 0) then
      begin
       Empty := True;
       for k := 0 to Row^.Count - 1 do
        begin
         Data := Row^.At(k);
         if (Data <> Nil) and Empty then Empty := Data^.Count = 0;
        end;
       if not Empty then
        begin
         BrLine := True;
         for j := 0 to Cols - 1 do
          begin
           if j < Row^.Count then Data := Row^.At(j);
           if (j < Row^.Count) and (Data <> Nil) and (Data^.Count > 0) then
            begin
             S := S + Pad(PString(Data^.At(0))^, ColSize,' ', '|');
             Data^.AtFree(0);
            end
           else S := S + Pad(' '#0, ColSize,' ', '|');
          end;
        end
       else Table^.AtFree(0);
       Break;
      end
     else Table^.AtFree(0);
    end;
  until Table^.Count = 0;

 if BrLine and Empty and (Table^.Count <> 0) then {Break line}
  begin
   for j := 1 to Cols do S := S + Pad('-'#0, ColSize,'-', '+');
   BrLine := False;
  end;
 GetOutLine := S;
end;

destructor TTables.Done;
begin
 if Table <> Nil then Dispose(Table, Done);
 inherited Done;
end;

{$L Spec.obj}
procedure Specials;external;

const
 SpecCnt = 105;

type
 TSpc = record
  S: String[6];
  N : Byte;
 end;
 PSpecials = ^TSpecials;
 TSpecials = Array[0..SpecCnt - 1] of TSpc;

function DataAddress(P: Pointer): Pointer;
type
  SO = record
    O, S: Word;
  end;
  JumpInstr = record
    Opcode: Byte;
    Address: Pointer;
  end;
begin
  if SO(P).S <> CSeg then DataAddress := JumpInstr(P^).Address
  else DataAddress := P;
end;

function SpecSearch(const Key: String; var Index: Byte): Boolean;
var
  L, H, I: Integer;
  C: CompareType;
begin
  SpecSearch := False;
  L := 0;
  H := SpecCnt - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := CompString(PSpecials(DataAddress(@Specials))^[i].S, Key);
    if C = Less then L := I + 1 else
    begin
      H := I - 1;
      if C = Equal then
      begin
        SpecSearch := True;
        L := I;
      end;
    end;
  end;
  Index := PSpecials(DataAddress(@Specials))^[L].N;
end;

procedure SetStr(const S: String; var D: String);
begin
 D := S;
end;

function SpecStr(var SSpec: String): Boolean;
var
 Ch: Byte;
 Code: Integer;
 Result: Boolean;
begin
 SpecStr := False;
 if SSpec[1] in ['0'.. '9'] then
  begin
   Val(SSpec, Ch, Code);
   Result := Code = 0;
  end
 else
 if SSpec[1] = '#' then
  begin
   Val(Copy(SSpec, 2, 255), Ch, Code);
   Result := Code = 0;
  end
 else Result := SpecSearch(SSpec, Ch);

 if Result then
  case Ch of
   0..150 : SSpec := Char(Ch);
   151 : SSpec := '<';
   152 : SSpec := '>';
   153 : SSpec := '&';
   154 : SSpec := '"';
   155..
   160 : SSpec := ' ';
   161,
   162 : SSpec := '^';
   163 : SSpec := '&';
   164 : SSpec := '$';
   165,
   221 : SSpec := 'Y';
   166 : SSpec := '|';
   167 : SSpec := '';
   168 : SSpec := '"';
   169 : SSpec := '(C)';
   170 : SSpec := 'a';
   171 : SSpec := '<<';
   172 : SSpec := '-';
   173 : SSpec := '_';
   174 : SSpec := '(R)';
   175 : SSpec := '-';
   176 : SSpec := '''';
   177 : SSpec := '+/-';
   178 : SSpec := '2';
   179 : SSpec := '3';
   180 : SSpec := '`';
   181 : SSpec := 'u';
   182 : SSpec := '';
   183 : SSpec := '.';
   184 : SSpec := 'c';
   185 : SSpec := '1';
   186 : SSpec := '`';
   187 : SSpec := '>>';
   188 : SSpec := '1/4';
   189 : SSpec := '1/2';
   190 : SSpec := '3/4';
   191 : SSpec := '?';
   192..
   197 : SSpec := 'A';
   198 : SSpec := 'AE';
   199 : SSpec := 'C';
   200..
   203 : SSpec := 'E';
   204..
   207 : SSpec := 'I';
   208 : SSpec := 'D';
   209 : SSpec := 'N';
   210..
   214 : SSpec := 'O';
   215 : SSpec := 'X';
   216 : SSpec := '0';
   217..
   220 : SSpec := 'U';
   222 : SSpec := 'P';
   223 : SSpec := 'B';
   224..
   229 : SSpec := 'a';
   230 : SSpec := 'ae';
   231 : SSpec := 'c';
   232..
   235 : SSpec := 'e';
   236..
   239 : SSpec := 'i';
   240 : SSpec := 'eth';
   241 : SSpec := 'n';
   242..
   246 : SSpec := 'o';
   247 : SSpec := ':';
   248 : SSpec := '0';
   249..
   252 : SSpec := 'u';
   253,
   255 : SSpec := 'y';
   254 : SSpec := 'p';
  end;
 SpecStr := Result;
end;

function TagValue(const STag, Key: String) : String;
var
 Ps1, Ps2: Byte;
 S: String;
begin
 S := '';
 Ps1 := 1;
 repeat
  Ps1 := FIPos(Key, StUpCase(STag), Ps1);
 until (Ps1 = 0) or (Ps1 = 1) or ((Ps1 > 1) and (STag[Ps1-1] = ' '));
 if Ps1 <> 0 then
  begin
   Ps1 := FIPos('=', STag, Ps1);
   if Ps1 <> 0 then
    begin
     Inc(Ps1);
     while (STag[Ps1] = ' ') and (Ps1 <= Length(STag)) do Inc(Ps1);
     if Ps1 <= Length(STag) then
      begin
       if STag[Ps1] = '"' then S := GetLiterals(STag, Ps1, Ps2)
       else
       while (STag[Ps1] <> ' ') and (Ps1 <= Length(STag)) do
        begin
         AddStr(S, STag[Ps1], 1);
         Inc(Ps1);
        end;
      end;
    end;
  end;
 TagValue := S;
end;

procedure DeSpace(var S: String);
var
 i, j : Byte;
begin
 i := 1;
 while  i < Length(S) do
  begin
   if S[i] = ' ' then Delete(S, i, 1)
   else Inc(i);
  end;
end;

procedure ParseHREF(const STag: String; var PFName, PRefName: PString);
var
 Ps1, Ps2: Byte;
 S: String;
begin
 PRefName := Nil;
 PFName := Nil;
 S := TagValue(STag, 'HREF');
 if S <> '' then
  begin
   Ps1 := RPos('#', S);
   if Ps1 <> 0 then
    begin
     {PRefName := NewStr(Copy(S, Ps1 + 1, 255));}
     PRefName := NewStrUMB(Copy(S, Ps1 + 1, 255));
     S[0] := Char(Ps1 -1);
     {PFName := NewStr(S);}
     {DeSpace(S);}
     PFName := NewStrUMB(S);
    end
   {else PFName := NewStr(S);}
   else
    begin
     {DeSpace(S);}
     PFName := NewStrUMB(S);
    end;
  end;
end;

procedure ParseNAME(const STag: String; var PRefName: PString);
var
 Ps1, Ps2: Byte;
 CharSet: Set of Char;
 S: String;
begin
 PRefName := Nil;
 S := TagValue(STag, 'NAME');
 if S[1] = '#' then Delete(S, 1, 1);
 {if S <> '' then PRefName := NewStr(S);}
 if S <> '' then PRefName := NewStrUMB(S)
end;

function ParseIMG(const STag: String; var PFName: PString): String;
var
 Ps1, Ps2: Byte;
 S: String;
begin
 PFName := Nil;
 S := TagValue(STag, 'SRC');
 DeSpace(S);
 {if S <> '' then PFName := NewStr(S);}
 if S <> '' then PFName := NewStrUMB(S);
 S := TagValue(STag, 'ALT');
 if S <> '' then ParseIMG := Concat(' ', S, ' ')
 else ParseIMG := ImageStr;
end;

function ParseArea(const STag: String; var PFName: PString): String;
var
 Ps1, Ps2: Byte;
 S: String;
begin
 PFName := Nil;
 S := TagValue(STag, 'HREF');
 DeSpace(S);
 {if S <> '' then PFName := NewStr(S);}
 if S <> '' then PFName := NewStrUMB(S);
 S := TagValue(STag, 'ALT');
 if S <> '' then ParseArea := Concat(' ', S, ' ')
 else ParseArea := MapStr;
end;

function ParseLINK(const STag: String; var PFName: PString): String;
var
 Ps1, Ps2: Byte;
 S: String;
begin
 PFName := Nil;
 S := TagValue(STag, 'HREF');
 DeSpace(S);
 {if S <> '' then PFName := NewStr(S);}
 if S <> '' then PFName := NewStrUMB(S)
 else
  begin
   S := TagValue(STag, 'SRC');
   DeSpace(S);
   {if S <> '' then PFName := NewStr(S);}
   if S <> '' then PFName := NewStrUMB(S)
  end;
 S := TagValue(STag, 'TITLE');
 if S = '' then S := TagValue(STag, 'REL');
 if S = '' then S := TagValue(STag, 'REV');
 if S <> '' then ParseLINK := Concat(' ', S, ' ')
 else ParseLINK := LinkStr;
end;

function ParseFrame(const STag: String;
                    var PFName: PString;
                    var Scrolling: Boolean): String;
var
 Ps1, Ps2: Byte;
 S: String;
begin
 PFName := Nil;
 S := TagValue(STag, 'SRC');
 DeSpace(S);
 {if S <> '' then PFName := NewStr(S);}
 if S <> '' then PFName := NewStrUMB(S);
 S := TagValue(STag, 'SCROLLING');
 Scrolling := Pos('NO', StUpCase(S)) <> 0;
 S := TagValue(STag, 'NAME');
 if S <> '' then ParseFrame := Concat(' ', S, ' ')
 else ParseFrame := FrameStr;
end;

constructor THtml.Init(ALimit: Byte; ATableTag: Boolean);
var
 PPs, Idx: Byte;
begin
 inherited Init;
 Limit := ALimit;
 TableTag := ATableTag;
 State.Attr := atNormalText;
 {PTags := NewStr(Tags);}
 PTags := NewStrUMB(Tags);
 TagPos[1] := #1;
 TagPos[0] := PTags^[0];
 PPs := 1;
 for Idx := 1 to Length(PTags^) do
  if PTags^[Idx] = ' ' then
   begin
    Inc(PPs);
    TagPos[Succ(Idx)] := Char(PPs);
   end;
 Names := New(PNameColl, Init(20, 10));
 Names^.Duplicates := True;
 Refs := New(PRefColl, Init(20, 10));
 Refs^.Duplicates := True;
end;

destructor THtml.Done;
begin
 if Names <> Nil then Dispose(Names, Done);
{
 DisposeStr(PTags);
 DisposeStr(Refs^.Ref.PFName);
 DisposeStr(Refs^.Ref.PRefName);
}
 DisposeStrUMB(PTags);
 DisposeStrUMB(Refs^.Ref.PFName);
 DisposeStrUMB(Refs^.Ref.PRefName);
 if Refs <> Nil then Dispose(Refs, Done);
 if State.PTable <> Nil then Dispose(State.PTable, Done);
 inherited Done;
end;

function THtml.InitStream(const FName: String;
  FromArchive: Boolean): boolean;
var
 P: PString;
 S: String;
begin
 FHtml := New(PHTMLStream, Init(FName, stOpenRead, 4096));
{$IFNDEF DEBUG}
 if FHtml^.Status <> stOk then
 begin
  if FromArchive then
  begin
    P := Message(Desktop, evBroadcast, cmExtractByName, @FName);
    if P <> nil then
    begin
     GetValidSwapDir(S, False);
     DoneStream;
     FHtml := New(PHTMLStream, Init(
       QuasiShortName(S + JustFileName(P^)), stOpenRead, 4096));
    end;
  end
  else
  begin
   S := QuasiShortName(FName);
   if S <> FName then
   begin
    DoneStream;
    FHtml := New(PHTMLStream, Init(S, stOpenRead, 4096));
   end;
  end
 end;
{$ENDIF}
 InitStream := FHtml^.Status = stOk;
end;

procedure THtml.DoneStream;
begin
 if FHtml <> Nil then
 begin
  Dispose(FHtml, Done);
  FHtml := nil;
 end;
end;

function THtml.Pos2Tag(Ps: Byte):TTag;
begin
 if Ps <> 0 then Pos2Tag := TTag(TagPos[Ps])
 else Pos2Tag := NUL;
end;

procedure THtml.Tag2State(StTag: String);
var
 EndTag: Boolean;
 SpPos: Byte;
 Tag: TTag;
begin
 EndTag := False;
 if StTag[1] = '/' then
  begin
   Delete(StTag, 1, 1);
   EndTag := True;
  end;
  SpPos := Pos(' ', StTag);
  if SpPos = 0 then Tag := Pos2Tag(Pos(Concat(StTag, ' '), PTags^))
  else Tag := Pos2Tag(Pos(Copy(StTag, 1, SpPos), PTags^));
  case Tag of
   PRE: State.Pre := not EndTag;
   XMP: State.XMP := not EndTag;
   LISTING: State.LISTING := not EndTag;
   A: begin
       if not EndTag then Inc(State.aTag)
       else if State.aTag > 0 then Dec(State.aTag);
       if EndTag then
        begin
         if State.aRef then
          begin
           State.aRef := False;
           if State.TblPass <> 1 then AddRefEnd;
          end;
         if State.aName then State.aName := False;
        end
       else
        begin
         if Pos('HREF', StTag) <> 0 then State.aRef := True;
         if Pos('NAME', StTag) <> 0 then State.aName := True;
        end;
      end;
   H1..H6: State.Hdr := not EndTag;
   OL: State.OrdList := not EndTag;
   STYLE: State.Style := not EndTag;
   SCRIPT: State.Script := not EndTag;
   UL: State.UList := not EndTag;
   MENU: State.MList := not EndTag;
   BLOCKQUOTE: State.Quote := not EndTag;
   DL: State.DList := not EndTag;
   HL: State.ListHdr := not EndTag;
   LI, DT: State.LineList := not EndTag;
   DD: State.TabLine := not EndTag;
   HR: if State.TblPass in [0, 3] then State.HorLine := not EndTag;
   P:  State.Para := not EndTag;
   BR: State.LineBreak := not EndTag;
   TITLE: State.Title := not EndTag;
   IMG: State.Image := not EndTag;
   AREA: State.Area := not EndTag;
   LINK: State.Link := not EndTag;
   FRAME: State.Frame := not EndTag;
   CAPTION: if State.TblPass <> 3 then
             begin
              State.TblCaption := not EndTag;
              if EndTag and (State.PTable <> Nil) and
                 (State.PTable^.Caption <> '') then
                  Inc(State.PTable^.Rows);
             end;
   CENTER: if not State.Center then
            begin
             State.Center := True;
             State.StartCenter := True;
            end
           else
            begin
             State.Center := False;
             State.EndCenter := True;
            end;
   TR: begin
        State.TableRow := not EndTag;
        State.RowData := True;
        if State.MaxTblCol < State.TblCol then
          State.MaxTblCol := State.TblCol;
        State.TblCol := 0;
        if not EndTag then State.NewLine := True;
        if State.THdr then
         begin
          State.THdr := False;
          State.Attr := atNormalText;
         end;
       end;
   TH: begin
        State.THdr := not EndTag;
        if not EndTag then State.Attr := atBoldText
        else State.Attr := atNormalText;
       end;
   TD, TABLE:
       if State.THdr then
        begin
         State.THdr := False;
         State.Attr := atNormalText;
        end;
  end;

  case Tag of
   TABLE: begin

            if (State.TblPass <> 0) then
             begin
              if not EndTag then
               begin
                inc(State.TblCnt);
                Exit;
               end;
              if EndTag and (State.TblCnt <> 0) then
               begin
                dec(State.TblCnt);
                Exit;
               end;
             end;

            if TableTag then
             begin
              {State.HorLine := True;}
              State.Tbl := not EndTag;
              if State.Tbl and (State.TblPass <> 1) then
               begin
                State.TblPass := 1;
                State.StartTable := True;
                State.TblChars := FHtml^.GetPosition;
                State.TblCol := 0;
                State.MaxTblCol := 0;
                State.RowData := False;
               end
              else
               begin
                if State.MaxTblCol < State.TblCol then
                  State.MaxTblCol := State.TblCol;
                State.TblCol := 0;
               end;
              if State.TblPass in [2, 3] then
               begin
                State.TblPass := 0;
                State.TblCol := 0;
                State.MaxTblCol := 0;
                State.EndTable := True;
                State.RowData := False;
               end;
             end;
           end;
   TD, TH: State.TableData := not EndTag;
   OL, HL, UL, DL, MENU, DIR:
    begin
     if not EndTag then
      begin
       Inc(State.Margin);
       if State.LStackPtr < LStackSize then
        begin
         Inc(State.LStackPtr);
         State.LStack[State.LStackPtr] := Tag;
        end;
      end
     else
      begin
       if State.Margin > 0 then Dec(State.Margin);
       if State.LStackPtr > 0 then Dec(State.LStackPtr);
      end;
     State.NewLine := True;
    end;
   LI: if not EndTag then State.NewLine := True;
   P, BR, HR, DD, DT, PRE, XMP, LISTING, CENTER: State.NewLine := True;
   A: begin
       if State.aRef then State.Attr := atRefText
         else if (State.HighLite > 0) or
                 State.THdr then State.Attr := atBoldText
              else State.Attr := atNormalText;
      end;
  end;
  if Tag in [TABLE, TH, TD, TR] then
   begin
    if State.TblCaption and (State.PTable <> Nil) and
       (State.PTable^.Caption <> '') then Inc(State.PTable^.Rows);
    State.TblCaption := False;
   end;
  if Tag in [B, I, H1..H6, LH, EM, SAMP] then
   begin
    if not EndTag then Inc(State.HighLite)
    else if State.HighLite > 0 then Dec(State.HighLite);
    if not State.aRef then
     if not EndTag then State.Attr := atBoldText
     else State.Attr := atNormalText;
   end;
  if Tag in [H1..H6, BLOCKQUOTE, DIV_] then State.NewLine := True;
  if Tag = OL then
   begin
    if not EndTag then
     begin
      if State.OLLevel < MaxOLLevel then Inc(State.OLLevel);
     end
    else
     if State.OLLevel > 0 then
      begin
       State.OLNums[State.OLLevel] := 0;
       Dec(State.OLLevel);
      end;
   end;
  if (Tag = LI) and
     not EndTag and
     (State.OLLevel <> 0) and
     (State.LStack[State.LStackPtr] = OL) then
     Inc(State.OLNums[State.OLLevel]);
end;

procedure THtml.AddRefStart;
begin
 Refs^.Ref.Line1 := Line;
 Refs^.Ref.Pos1 := Length(STxt) + 1;
 if (State.TblPass = 2) and (State.PTable <> Nil) then
  begin
   Refs^.Ref.Line1 := Line + State.PTable^.GetLine;
   Refs^.Ref.Pos1 := Refs^.Ref.Pos1 + State.PTable^.GetPos;
  end;

 if (Refs^.Ref.PFName <> Nil) or (Refs^.Ref.PRefName <> Nil) then
  begin
   DisposeStrUMB(Refs^.Ref.PFName);
   DisposeStrUMB(Refs^.Ref.PRefName);
  end;
 ParseHREF(STag, Refs^.Ref.PFName, Refs^.Ref.PRefName);
 State.RefIns := True;
end;

function NewRef(P: PRefItem): PRefItem;
 var
  PP: PRefItem;
begin
 PP := MemAlloc(SizeOf(TRefItem));
 if P <> Nil then
  begin
   PP^ := P^;
   if P^.PFName <> Nil then PP^.PFName := NewStrUMB(P^.PFName^);
   if P^.PRefName <> Nil then PP^.PRefName := NewStrUMB(P^.PRefName^);
  end;
 NewRef := PP;
end;

procedure THtml.AddRefEnd;
var
 P, PP: PRefItem;
 i: Integer;
 Ps: Byte;
begin
 Refs^.Ref.Line2 := Line;
 Refs^.Ref.Pos2 := Length(STxt) + 1;
 if (State.TblPass = 2) and (State.PTable <> Nil) then
  begin
   Ps := State.PTable^.GetPos;
   Refs^.Ref.Line2 := Line + State.PTable^.GetLine;
   Refs^.Ref.Pos2 := Refs^.Ref.Pos2 + Ps;
   if Refs^.Ref.Line1 <> Refs^.Ref.Line2 then
    begin
     if Refs^.Ref.Pos1 < Ps + State.PTable^.ColSize then
      begin
       P := NewRef(@Refs^.Ref);
       if P <> Nil then
        begin
         P^.Pos2 := Ps + State.PTable^.ColSize + 1;
         P^.Line2 := P^.Line1;
         if CollCanInsert(Refs) then Refs^.Insert(P)
         else FreeMem(P, SizeOf(TRefItem));
        end;
      end;

     if (Refs^.Ref.Line2 - Refs^.Ref.Line1) >= 2 then
      for i := Refs^.Ref.Line1 + 1 to Refs^.Ref.Line2 - 1 do
       begin
        P := NewRef(@Refs^.Ref);
        if P <> Nil then
         begin
          P^.Pos1 := Ps + 1;
          P^.Line1 := i;
          P^.Pos2 := Ps + State.PTable^.ColSize + 1;
          P^.Line2 := i;
          if CollCanInsert(Refs) then Refs^.Insert(P)
          else FreeMem(P, SizeOf(TRefItem));
         end;
       end;

     Refs^.Ref.Line1 := Refs^.Ref.Line2;
     Refs^.Ref.Pos1 := State.PTable^.GetPos + 1;
    end;
  end;

 P := MemAlloc(SizeOf(TRefItem));
 if P <> Nil then
  begin
   Move(Refs^.Ref, P^, SizeOf(TRefItem));
   if not CollCanInsert(Refs) then FreeMem(P, SizeOf(TRefItem))
   else
    begin
     Refs^.Insert(P);
     FillChar(Refs^.Ref, SizeOf(TRefItem), 0);
    end;
  end;
 State.RefIns := False;
end;

procedure THtml.AddImage(Len: Byte; PFName: PString; Scrolling: Boolean);
var
 P: PRefItem;
begin
 P := MemAlloc(SizeOf(TRefItem));
 if P <> Nil then
  begin
   FillChar(P^, SizeOf(TRefItem), 0);
   P^.Line1 := Line;
   P^.Pos1 := Length(STxt) + 1;
   P^.Line2 := Line;
   P^.Pos2 := Length(STxt) + Len + 1;
   if (State.TblPass = 2) and (State.PTable <> Nil) then
    begin
     P^.Line1 := P^.Line1 + State.PTable^.GetLine;
     P^.Line2 := P^.Line1;
     P^.Pos1 := P^.Pos1 + State.PTable^.GetPos;
     P^.Pos2 := P^.Pos2 + State.PTable^.GetPos;
    end;
   P^.PFName := PFName;
   P^.PRefName := Nil;
   P^.Scrolling := Scrolling;
   if not CollCanInsert(Refs) then FreeMem(P, SizeOf(TRefItem))
   else Refs^.Insert(P);
  end;
end;

procedure THtml.AddName;
var
 PN: PNameItem;
begin
 PN := MemAlloc(SizeOf(TNameItem));
 if PN <> Nil then
  begin
   FillChar(PN^, SizeOf(TNameItem), 0);
   PN^.Line := Line;
   PN^.Pos := Length(STxt);
   if (State.TblPass = 2) and (State.PTable <> Nil) then
    begin
     PN^.Line := PN^.Line + State.PTable^.GetLine;
     PN^.Pos := PN^.Pos + State.PTable^.GetPos;
    end;
   ParseNAME(STag, PN^.PRefName);
   if not CollCanInsert(Names) then FreeMem(PN, SizeOf(TNameItem))
   else Names^.Insert(PN);
  end;
end;

function THtml.GetLine: String;
var
 LineSt: (Text, Tag, Spec);
 InText, SpecInTag, Scrolling: Boolean;
 Ch, PrevCh: Char;
 SpPos, bb, ALimit, BLimit: Byte;
 I: Integer;
 NoSpace: LongInt;
 PFName: PString;
 P: PRefItem;
 R: TRefItem;
 PercentStr: String[7];
 SAttr, SSpec: String[128];
 SOut: String;
label
 NoTag, NewLine;
begin
NewLine:
 ALimit := Limit;
 BLimit := 32;
 LineSt := Text;
 InText := True;
 STxt := '';
 SAttr := '';
 SOut := '';
 NoSpace := 0;
 if State.TblPass in [0, 3] then
  begin
   AddStr(STxt, ' ', State.Margin * 2);
   AddStr(SAttr, State.Attr, State.Margin * 2);
  end;
 SSpec := '';
 PFName := Nil;
 Ch := #0;
 PrevCh := ' ';

 if State.LineList then
  begin
   if (State.OLLevel <> 0) and (State.LStack[State.LStackPtr] = OL) then
    begin
     if Length(STxt) >= 2 then Dec(STxt[0], 2);
     STxt := STxt + NumW2Str(State.OLNums[State.OLLevel]);
     AddStr(SAttr, State.Attr, 5);
    end
   else STxt[Length(STxt) - 1] := '*';
   State.LineList := False;
  end;

 if State.Quote then
  begin
   STxt := STxt + '> ';
   AddStr(SAttr, State.Attr, 2);
  end;

 while (FHtml^.Status = stOk) do
  begin

   if State.StartTable then
    begin
     State.StartTable := False;
     Break;
    end;

   if (State.PTable <> Nil) and
      State.PTable^.OutOfMemory then
    begin
     State.EndTable := False;
     Dispose(State.PTable, Done);
     State.PTable := Nil;
     FHtml^.SetPosition(State.TblChars);
     FillChar(State, SizeOf(State), 0);
     State.TblPass := 3;
     State.Attr := atNormalText;
     I := 0;
     while I < Refs^.Count do
      if PRefItem(Refs^.At(I))^.Line1 > Line then Refs^.AtFree(I)
      else Inc(I);
     I := 0;
     while I < Names^.Count do
      if PNameItem(Names^.At(I))^.Line > Line then Names^.AtFree(I)
      else Inc(I);
     GoTo NewLine;
    end;

   if (State.TblPass = 1) and not State.Tbl then
    begin
     FHtml^.SetPosition(State.TblChars);
     if State.MaxTblCol = 0 then State.MaxTblCol := 1;
     bb := Limit Div State.MaxTblCol;
     if (bb < 6) and (State.MaxTblCol * 6 < 125) then bb := 6;
     if bb > 5 then
      begin
       State.TblPass := 2;
       if State.PTable <> Nil then Dispose(State.PTable, Done);
       State.PTable := New(PTables, Init(State.MaxTblCol, bb));
       FirstLine := True;
       bb := State.MaxTblCol * bb - 1;
       GetLine := Pad('-'#0, bb, '-', '-');
       Inc(Line);
       Exit;
      end
     else State.TblPass := 3;
     GoTo NewLine;
    end;

   if State.NewLine then
    begin
     State.NewLine := False;
     if (State.TblPass = 1) and State.Tbl then GoTo NewLine
     else if (State.PTable <> Nil) and (State.TblPass = 2) then
           begin
            State.PTable^.AddCellStr(STxt, SAttr);
            Continue;
           end
          else Break;
    end;

   if State.TabLine then
    begin
     State.TabLine := False;
     AddStr(STxt, ' ', 2);
     AddStr(SAttr, State.Attr, 2);
     NoSpace := 0;
     Continue;
    end;

  if (State.TblPass = 3) or not TableTag then
   begin
    if State.TableData then
     begin
      State.TableData := False;
      AddStr(STxt, '|', 1);
      AddStr(SAttr, State.Attr, 1);
     end;
   end
  else
   begin
    if State.TableData then
     begin
      if (State.PTable <> Nil) and (State.TblPass = 2) then
       begin
        State.PTable^.AddCellStr(STxt, SAttr);
        if State.RowData then State.PTable^.AddRow;
        State.PTable^.AddData;
       end
      else Inc(State.TblCol);
      State.TableData := False;
      State.RowData := False;
     end;

    if State.TableRow then
     begin
      if (State.PTable <> Nil) and (State.TblPass = 2) then
       begin
        State.PTable^.AddCellStr(STxt, SAttr);
        State.PTable^.AddRow;
       end;
      State.TableRow := False;
     end;

    if State.EndTable then
     begin
      if (State.PTable <> Nil) and (State.TblPass = 4) then
       begin
        if State.PTable^.Table^.Count > 0 then
         begin
          FirstLine := True;
          repeat
           SOut := State.PTable^.GetOutLine;
          until (State.PTable^.Table^.Count = 0) or (SOut <> '');
          if SOut = '' then Continue;
          GetLine := SOut;
          Inc(Line);
          Exit;
         end
        else
         begin
          State.EndTable := False;
          if State.PTable^.BrLine then
            bb := State.PTable^.Cols * (State.PTable^.ColSize + 1) - 1
          else bb := 0;
          if State.PTable <> Nil then Dispose(State.PTable, Done);
          State.PTable := Nil;
          State.TblPass := 0;
          if bb <> 0 then
           begin
            GetLine := Pad('-'#0, bb, '-', '-');
            FirstLine := True;
            Inc(Line);
            Exit;
           end
          else GoTo NewLine;
         end;
       end
      else
       begin
        if State.PTable <> Nil then
         begin
          State.PTable^.AddCellStr(STxt, SAttr);
          State.TblPass := 4;
          Continue;
         end;
       end;
     end;
   end;


  if State.TblPass <> 1 then
    begin

     if State.HorLine then
      begin
       State.HorLine := False;
       STxt := '';
       SAttr := '';
       AddStr(STxt, '-', Limit+1);
       AddStr(SAttr, State.Attr, Limit+1);
       Break;
      end;

     if State.Image then
      begin
       PFName := Nil;
       SOut := ParseIMG(STag, PFName);
       if Length(SOut) > Limit then SOut[0] := Char(Limit);
       if Length(STxt) + Length(SOut) <= Limit then
        begin
         State.Image := False;
         AddImage(Length(SOut), PFName, False);
         STxt := Concat(STxt, SOut);
         AddStr(SAttr, atRefText, Length(SOut));
         NoSpace := 0;
         Continue;
        end
       else
        begin
         if PFName <> Nil then DisposeStrUMB(PFName);
         Break;
        end;
      end;

     if State.Area then
      begin
       PFName := Nil;
       SOut := ParseArea(STag, PFName);
       if Length(SOut) > Limit then SOut[0] := Char(Limit);
       if Length(STxt) + Length(SOut) <= Limit then
        begin
         State.Area := False;
         AddImage(Length(SOut), PFName, False);
         STxt := Concat(STxt, SOut);
         AddStr(SAttr, atRefText, Length(SOut));
         NoSpace := 0;
         Continue;
        end
       else
        begin
         if PFName <> Nil then DisposeStrUMB(PFName);
         Break;
        end;

      end;

     if State.Link then
      begin
       PFName := Nil;
       SOut := ParseLINK(STag, PFName);
       if Length(SOut) > Limit then SOut[0] := Char(Limit);
       if Length(STxt) + Length(SOut) <= Limit then
        begin
         State.Link := False;
         AddImage(Length(SOut), PFName, False);
         STxt := Concat(STxt, SOut);
         AddStr(SAttr, atRefText, Length(SOut));
         NoSpace := 0;
         Continue;
        end
       else
        begin
         if PFName <> Nil then DisposeStrUMB(PFName);
         Break;
        end;
      end;

     if State.Frame then
      begin
       PFName := Nil;
       SOut := ParseFrame(STag, PFName, Scrolling);
       if Length(SOut) > Limit then SOut[0] := Char(Limit);
       if Length(STxt) + Length(SOut) <= Limit then
        begin
         State.Frame := False;
         AddImage(Length(SOut), PFName, Scrolling);
         STxt := Concat(STxt, SOut);
         AddStr(SAttr, atRefText, Length(SOut));
         NoSpace := 0;
         Continue;
        end
       else
        begin
         if PFName <> Nil then DisposeStrUMB(PFName);
         Break;
        end;
      end;
     end
    else
     begin
      if State.Image then State.Image := False;
      if State.Area then State.Area := False;
      if State.Link then State.Link := False;
      if State.Frame then State.Frame := False;
     end;

   Ch := FHtml^.GetCh;
   {$IFDEF DEBUG}
   if FHtml^.GetPercent(bb) then Write(bb, '%'#13);
   {$ELSE}
   if FHtml^.GetPercent(bb) then
   begin
     PercentStr := Long2Str(bb) + '%';
     LogEvent := 0;
     if State.TblPass in [1, 2] then
       DrawStatusLine('Loading HTML table: ' + PercentStr)
     else DrawStatusLine('Processing HTML file ' +
       TrimmedName(FHtml^.Name^, 40) + ': ' + PercentStr);
     if (KbdStatus = 1) and AbortAction then
     begin
       GetLine := '';
       FHtml^.Status := stReadError;
       Exit;
     end;
   end;
   {$ENDIF}
   Inc(NoSpace);
   if (LineSt = Text) and (Ch = '<') then
    begin
     if State.XMP {or State.PRE} or State.Listing then
      begin
       Ch := FHtml^.GetCh;
       FHtml^.UngetCh(1);
       if Ch <> '/' then
        begin
         Ch := '<';
         GoTo NoTag
        end;
      end;
     {$B+}
     if (FHtml^.GetCh = '-') and
        (FHtml^.GetCh = '-') and
        (FHtml^.GetCh = '!') then  {Called first in BP7}
        State.Rem := True;
     {$B-}
     FHtml^.UngetCh(3);
     LineSt := Tag;
     STag := '';
     InText := False;
     SpecInTag := False;
     Continue;
    NoTag:
    end;
   if (LineSt = Tag) and (Ch = '>') then
    begin
     if State.Rem and (RPos('--', STag) <> Length(STag) - 1) then Continue
     else State.Rem := False;
     LineSt := Text;
     Tag2State(StUpCase(STag));
     if State.TblPass <> 1 then
      begin
       if State.aName then AddName;
       if State.aRef and not State.RefIns then AddRefStart;
      end;
     NoSpace := 0;
     Continue;
    end;
   if (LineSt = Text) and (Ch = '&') then
    begin
     LineSt := Spec;
     SSpec := '';
     InText := False;
     Continue;
    end;
   if (LineSt = Spec) and (not (Ch in SpecSet) or
      (Length(SSpec) > 6)) then
    begin
     LineSt := Text;
     PrevCh := #0;
     bb := Length(SSpec);
     if SpecStr(SSpec) then
      if not State.Title and (Length(STxt) + Length(SSpec) > Limit) then
       begin
         FHtml^.UngetCh(bb + 2);
         Break;
       end
      else
       begin
        if State.Title then HtmlTitle := Concat(HtmlTitle, SSpec)
        else
         begin
          STxt := Concat(STxt, SSpec);
          AddStr(SAttr, State.Attr, Length(SSpec));
         end;
        if Ch <> ';' then FHtml^.UngetCh(1);
        if Pos(' ', SSpec) <> 0 then NoSpace := 0;
        Continue;
       end
     else
      begin
        if State.Title then HtmlTitle := Concat(HtmlTitle, '&')
        else
         begin
          STxt := Concat(STxt, '&');
          AddStr(SAttr, State.Attr, 1);
         end;
        FHtml^.UngetCh(bb + 1);
        Continue;
      end;
    end;
   case LineSt of
    Text:
     begin
      if State.Style then Continue; {01-27-00. 22:20:00}
      if State.Script then Continue; {01-27-00. 22:20:00}
      if (State.TblPass = 1) and State.Tbl then Continue;

      {$IFNDEF DEBUG}
      if AutoDecode and adHTML <> 0 then
      begin
        if Ch in AltSet then Inc(Alt);
        if Ch in KoiSet then Inc(Koi);
        if Ch in WinSet then Inc(Win);
      end;
      {$ENDIF}

      if State.Title then
       begin
        if Ch in [#9, #10, #13] then Ch := ' ';
        if (HtmlTitle <> '') or (Ch <> ' ') then AddStr(HtmlTitle, Ch, 1);
        Continue;
       end;

      if (State.TblPass = 0) and State.PRE or State.LISTING or State.XMP then
       begin
        case Ch of
         #10: Break;
         #13: Continue;
         #9: begin
              SpPos := 9 - (Length(STxt) + 1) mod 8;
              if SpPos = 9 then SpPos := 1;
              if Length(STxt) + SpPos < {Limit} 120 then
               begin
                Addstr(STxt, ' ', SpPos);
                AddStr(SAttr, State.Attr, SpPos);
                NoSpace := 0;
                Continue;
               end
              else Break;
             end;
        end;
       end
      else
       begin
        if (Ch in [#9, #10, #13]) then Ch := ' ';
        if (PrevCh = ' ') and (Ch = ' ') then Continue;
        PrevCh := Ch;
       end;

      if State.TblPass = 2 then
       begin
        if State.MaxTblCol = 0 then State.MaxTblCol := 1;
        ALimit := State.PTable^.ColSize - 1;
        BLimit := ALimit;
        if State.TblCaption then
         begin
          if Length(State.PTable^.Caption) < 253 then
           begin
            Addstr(State.PTable^.Caption, Ch, 1);
            AddStr(State.PTable^.Caption, atBoldText, 1);
           end;
          Continue;
         end
       end
      else
       begin
        ALimit := Limit;
        BLimit := 32;
        if (State.TblPass = 0) and
           State.PRE or State.LISTING or State.XMP then ALimit := 120;
       end;

      if Length(STxt) <= ALimit then
       begin
        Addstr(STxt, Ch, 1);
        AddStr(SAttr, State.Attr, 1);
        if Ch = ' ' then NoSpace := 0;
       end
      else
       begin
        if InText then
          begin
           SpPos := Length(STxt);
           while (Length(STxt) - SpPos < BLimit) and
                 (STxt[SpPos] <> ' ') and
                 (SAttr[SpPos] = State.Attr) do Dec(SpPos);
           if (STxt[SpPos] = ' ') or (SAttr[SpPos] <> State.Attr) then
            begin
             FHtml^.UngetCh(NoSpace);
             STxt[0] := Char(SpPos);
             SAttr[0] := Char(SpPos);
            end
           else FHtml^.UngetCh(1);
          end
         else FHtml^.UngetCh(1);

        if (State.PTable <> Nil) and (State.TblPass = 2) then
         begin
          State.PTable^.AddCellStr(STxt, SAttr);
          Continue;
         end
        else Break;
       end;
      InText := True;
      if State.TblPass = 2 then Continue;
     end;

    Tag:
     begin
      if SpecInTag then
       begin
        if not (Ch in SpecSet) or (Length(SSpec) > 6) then
         begin
          bb := Length(SSpec);
          SpecInTag := False;
          if SpecStr(SSpec) then
           begin
            STag := Concat(STag, SSpec);
            if Ch <> ';' then FHtml^.UngetCh(1);
           end
          else
           begin
            FHtml^.UngetCh(bb + 1);
            STag := Concat(STag, '&');
           end;
         end
        else AddStr(SSpec, Ch, 1);
        Continue;
       end;
      if Ch = '&' then
       begin
        SpecInTag := True;
        SSpec := '';
        Continue;
       end;
      if Ch in [#9, #10] then Ch := ' ';
      if Ch = #13 then Continue;
      Addstr(STag, Ch, 1);
      if State.Rem and (Length(STag) > 200) then
        System.Delete(STag, 4, 10);
     end;

    Spec:
     begin
      Addstr(SSpec, Ch, 1);
      if Length(SSpec) > 6 then
       begin
        LineSt := Text;
        FHtml^.UngetCh(Length(SSpec));
        if State.Title then AddStr(HtmlTitle, '&', 1)
        else
         begin
          Addstr(STxt, '&', 1);
          AddStr(SAttr, State.Attr, 1);
         end;
       end;
     end;

   end;
  end;
 SOut := '';
 if Trim(STxt) <> '' then
  begin
   FirstLine := True;
   if State.TblPass <> 2 then
    begin
     if State.StartCenter then State.StartCenter := False
     else
     if not State.TableRow and (State.Center or State.EndCenter) and (Length(STxt) < Limit + 1) then
      begin
       if State.EndCenter then State.EndCenter := False;
       SpPos := (Limit - Length(STxt)) div 2;
       System.Insert(Space(SpPos), STxt, 1);
       System.Insert(DupChar(atNormalText, SpPos), SAttr, 1);
       R.Line1 := Line;
       R.Pos1 := 1;
       Refs^.Search(@R, I);
       if (I <> 0) and (I = Refs^.Count) then
       begin
         Dec(I);
         P := Refs^.At(I);
         if (P <> nil) and (P^.Line1 < Line) and (P^.Line2 = Line) then
           Inc(P^.Pos2, SpPos);
       end
       else
       repeat
         P := Refs^.At(I);
         if (P = nil) or (P^.Line1 <> Line) then Break;
         Inc(P^.Pos1, SpPos);
         Inc(P^.Pos2, SpPos);
         Inc(I);
       until False;
       if Refs^.Ref.Line1 = Line then Inc(Refs^.Ref.Pos1, SpPos);
      end;
     if (Refs^.Ref.Line1 = Line) and
        (Refs^.Ref.Pos1 = Length(STxt) + 1) then
      begin
       Inc(Refs^.Ref.Line1);
       Refs^.Ref.Pos1 := 1;
      end;
    end;
   for SpPos := 1 to Length(STxt) do
    begin
     AddStr(SOut, STxt[SpPos], 1);
     AddStr(SOut, SAttr[SpPos], 1);
    end;
  end;
 if FirstLine then Inc(Line);
 State.StartCenter := False;
 GetLine := SOut;
end;

function TRefColl.Compare(Key1, Key2: Pointer): Integer;
begin
 if PRefItem(Key1)^.Line1 > PRefItem(Key2)^.Line1 then Compare := 1
 else
   if PRefItem(Key1)^.Line1 < PRefItem(Key2)^.Line1 then Compare := -1
   else
     if PRefItem(Key1)^.Pos1 > PRefItem(Key2)^.Pos1 then Compare := 1
     else
       if PRefItem(Key1)^.Pos1 < PRefItem(Key2)^.Pos1 then Compare := -1
       else  Compare := 0;
end;

procedure TRefColl.FreeItem(Item: Pointer);
begin
 if Item <> Nil then
  begin
{
   DisposeStr(PRefItem(Item)^.PFName);
   DisposeStr(PRefItem(Item)^.PRefName);
}
   DisposeStrUMB(PRefItem(Item)^.PFName);
   DisposeStrUMB(PRefItem(Item)^.PRefName);
   FreeMem(Item, SizeOf(TRefItem));
  end;
end;

function PointInRef(Y: Integer; X: Byte; P: PRefItem): Boolean;
begin
  with P^ do
    PointInRef := ((Y > Line1) and (Y < Line2)) or
      ((Line1 = Line2) and (Y = Line1) and
       (X >= Pos1) and (X <= Pos2)) or
      ((Line1 <> Line2) and
       (((Y = Line1) and (X >= Pos1)) or
       ((Y = Line2) and (X <= Pos2))));
end;

function TRefColl.CurRef(Y: Integer; X: Byte): PRefItem;
var
  I: Integer;
  P: PRefItem;
  R: TRefItem;
begin
  R.Line1 := Y;
  R.Pos1 := X;
  if not Search(@R, I) then Dec(I);
  P := At(I);
  if (P <> nil) and PointInRef(Y, X, P) then CurRef := P
  else CurRef := nil;
end;

function TRefColl.NextRef(Y: Integer; X: Byte; Back: Boolean): PRefItem;
var
  I: Integer;
  R: TRefItem;
begin
  R.Line1 := Y;
  R.Pos1 := X;
  if Search(@R, I) then
    if Back then Dec(I) else Inc(I)
  else if CurRef(Y, X) <> nil then
    if Back then Dec(I, 2) else {}
  else if Back then Dec(I);
  NextRef := At(I);
end;

function TNameColl.Compare(Key1, Key2: Pointer): Integer;
var
 C: CompareType;
begin
 C := CompUCString(PNameItem(Key1)^.PRefName^, PNameItem(Key2)^.PRefName^);
 if C = Greater then Compare := 1
 else
 if C = Less then Compare := -1
 else if IgnorePos then Compare := 0
 else
 begin
  if PNameItem(Key1)^.Line > PNameItem(Key2)^.Line then Compare := 1
  else
  if PNameItem(Key1)^.Line < PNameItem(Key2)^.Line then Compare := -1
  else
  if PNameItem(Key1)^.Pos > PNameItem(Key2)^.Pos then Compare := 1
  else
  if PNameItem(Key1)^.Pos < PNameItem(Key2)^.Pos then Compare := -1
  else Compare := 0;
 end;
end;

procedure TNameColl.FreeItem(Item: Pointer);
begin
 if Item <> Nil then
  begin
{   DisposeStr(PNameItem(Item)^.PRefName);}
   DisposeStrUMB(PNameItem(Item)^.PRefName);
   FreeMem(Item, SizeOf(TNameItem));
  end;
end;

{$IFNDEF DEBUG}

{$L KOIXLAT.OBJ}
procedure KoiXLAT; external;

{$L WINXLAT.OBJ}
procedure WinXLAT; external;

procedure FillXLATTable(Kind: Byte; var T);
var
  I: Byte;
begin
  for I := 0 to 127 do TByteArray(T)[I] := I;
  if Kind = xKoi then
    Move(DataAddress(@KoiXLAT)^, TByteArray(T)[128], 128)
  else if Kind = xWin then
    Move(DataAddress(@WinXLAT)^, TByteArray(T)[128], 128);
end;
{$ENDIF}
end.