Unit UnixMask;
{$F+,O+,X+}

{---------------------------------------------------------------------------

			UNIX style wild cards

  Author      - Keith S. Brown (except where otherwise noted)
		Surface mail:              Email:(brown@smd4.jsc.nasa.gov)
		  K.Brown
		  Code:NASA/JSC/ES64
		  Houston, TX 77058 (USA)  Voice:713-483-8952

  Remarks     - Uses regular expression parsing to handle UNIX style file
		name wild cards such as '*ss.[^ef]*'
		  --> file names ending with 'SS' and whose extension starts
		      with neither 'E' nor 'F'.
---------------------------------------------------------------------------}
Interface

{ Added 02.03.99 }
uses Dialogs;

Const
  MaxState    = 31;

Type
  CharSet= set of Char;
  states = 0..MaxState;
  metaCharType= (null,tClosure,tCCl,tLitChar);
  metaCharRec = record
    _set   : CharSet;
    _next  : States;
    _type  : MetaCharType;
  end {record};
  Tarcs = array[0..MaxState] of MetaCharRec;

  PState = ^TState;
  TState = record
   arcs: Tarcs;
   lastState: states;
  end;

procedure MakeAutomaton(Const metaCharExpr:String; var State: TState);
function IsAcceptable(const s:String;  var State: TState):Boolean;

{ Added 02.03.99 }
const
  UNIXHistStr = #$FF + '(UNIX)';

function UNIXPutHistoryFunc(Link: PInputLine;
  const S: String): String;
function UNIXGetHistoryFunc(Link: PInputLine;
  const S: String): String;

Implementation

{ Added 02.03.99 }
uses Objects, Views;

Const
  AllChars = [#1..#255];
  EmptySet = [];
  Mrange = '-';   {indicates range in set, ie. [a-z]}
  Mliteral = '\'; {indicates literal follows, ie. \?}
  MnotSet = '^';  {indicates every thing but, ie. [^a-z]}


{}procedure MakeAutomaton(Const metaCharExpr: String; var State: TState);
{---------------------------------------------------------------------------
  Purpose     - Convert a meta character expression to a finite state machine.
  Revised     - 1991.0628 (KSB) Fixed DoRange.
---------------------------------------------------------------------------}
  Var
    i    : Word;
    L    : Byte absolute metaCharExpr;

{}{}Procedure GetNextMetaChar(Var m:MetaCharType; Var ms:CharSet);
    Var
      c  : Char;
      IsIn    : Boolean;

{}{}{}Procedure Include(c:Char);
      begin
        case IsIn of
          True : ms := ms + [c];
          else
            ms := ms - [c];
        end {case};
{}{}{}end {Include};


{}{}{}Procedure GetChar(Var c:Char);
      begin
        if i <= L then begin
          c := UpCase(metaCharExpr[i]);
          Inc(i);
          {Write(c);}
        end else
          c := #0;
{}{}{}end {GetChar};


{}{}{}Procedure DoRange;
{---------------------------------------------------------------------------
  Revised     - 1991.0628 (KSB) Changed exit loop if i>L rather than i=L.
---------------------------------------------------------------------------}
      Var
        c1,c2 : Char;
      begin
        m := tCCl;
        c1:= #0;

        GetChar(c);
        if c = MnotSet then begin
          GetChar(c);
          IsIn := False;
          ms   := AllChars;
        end else
          IsIn := True;

        repeat
          case c of
            Mrange :
            if c1<>#0 then begin
              if metaCharExpr[Pred(Pred(i))] < metaCharExpr[i] then begin
                FOR c2 := Succ(c1) TO UpCase(metaCharExpr[i]) do
                  Include(c2);
                GetChar(c);
              end else begin
                GetChar(c);
                Include(c);
              end {FOR};
            end else
              Include(c);

            Mliteral :
            begin
              GetChar(c);
              Include(c);
              c := ' ';
            end {begin};

            ']' :;

            else begin
              Include(c);
              c1 := c;
            end {begin};

          end {case};

          GetChar(c);
        until (c=']') OR (i>L);
{}{}{}end {DoRange};


    begin {-- GetNextMetaChar --}
      ms := EmptySet;
      m  := Null;
      GetChar(c);

      case c of
        '*' :
        begin
          m := tClosure;
          ms:= AllChars;
        end {begin};

        '[' : DoRange;

        '.' :
        begin
          m  := tLitChar;
          ms := [c];
        end {begin};

        else
        if c in AllChars then begin
          m  := tLitChar;
          ms := [c];
        end else
        if c = '?' then begin
          m  := tLitChar;
          ms := AllChars;
        end else
          Exit;
      end {case};
{}{}end {GetNextMetaChar};


  Var
    n    : Word;
    m    : MetaCharType;
    mset : CharSet;
  begin {MakeAutomaton}
    FillChar(State.arcs, SizeOf(State.arcs),0);

    n := 0;
    i := 1;
    m := tLitChar;

    while (i <= L) and (m <> Null) and (n <= MaxState) do
    begin
      GetNextMetaChar(m,mset);
      case m of
        tClosure :
        begin
          with State.arcs[n] do
          begin
            _set  := AllChars;
            Inc(n);
            _next := n;
            _type := m;
          end {with};

          GetNextMetaChar(m,mset);
          if (m<>Null) then
            with State.arcs[n] do begin
              _set  := mset;
              _next := Succ(n);
              _type := m;
                {WriteLn(n,' tClosure set2=EmptySet ',State.arcs[n][2]._set=EmptySet);}
            end {with};
        end {begin};

        Null : ;

        else
          with State.arcs[n] do begin
            _set  := mset;
            _next := Succ(n);
            _type := m;
            {
            case m of
             tCCl    : WriteLn(n,' tCCl     set1=EmptySet ',State.arcs[n][1]._set=EmptySet);
             tLitChar: WriteLn(n,' tLitChar set1=EmptySet ',State.arcs[n][1]._set=EmptySet);
            end;
            }
          end {with};
      end {case};

      Inc(n);
    end {while};

    if m = Null then  Dec(n);
    State.lastState := n;
{}end {MakeAutomaton};

{}function  IsAcceptable(const s:String; var State: TState ):Boolean;
{---------------------------------------------------------------------------
  Purpose     - Determines if S fits the pattern established in the ARCS.
---------------------------------------------------------------------------}
  Var
    m, n: Integer;
    L: Byte absolute s;

{}{}function Amatch(offset:Integer; patNdx:Word):Integer;
{---------------------------------------------------------------------------
  Purpose     - Look for a match of pattern arcs starting at PATNDX with
                S[OFFSET].  Return the last position that matched.
---------------------------------------------------------------------------}

{}{}{}function Omatch(Var i:Integer; patNdx:Word):Boolean;
{---------------------------------------------------------------------------
  Purpose     - Match one pattern element at pattern pointed to by PATNDX
                and S[I].
---------------------------------------------------------------------------}
      Var
        advance: Integer;
        ttok: MetaCharType;
        c: Char;
      begin
        advance := -1;
        ttok := State.arcs[patNdx]._type;
        if i <= L then
        begin
          c := UpCase(s[i]);
          case ttok of
            tLitChar :
            if c in State.arcs[patNdx]._set then
              advance := 1;
            tCCL     :
            if c in State.arcs[patNdx]._set then
              advance := 1;
            tClosure :
            if c in State.arcs[patNdx]._set then
              advance := 1;
          end {case};
        end {if};

        if advance >= 0 then
        begin
          Omatch := True;
          i := i + advance;
        end
        else Omatch := False;
{}{}{}end {Omatch};

    Var
      done: Boolean;
      j, k: Word;
      i: Integer;
      ttok    : MetaCharType;
    begin {--- Amatch ---}
      done := False;
      j    := patNdx;

      while Not(done) and (j <= State.lastState) do begin
        ttok := State.arcs[j]._type;

        if (ttok = Null) and (offset > L) then
          done := True
        else
        if ttok = tClosure then begin
          i := offset;
          while Not(done) and (i<=L) do begin    {match as many as possible}
            if Not(Omatch(i,j)) then
              done := True;
          end {while};

          done := False;
          while Not(done) and (i >= offset) do begin
            k := Amatch(i,Succ(j));              {i is location of non-match}
            if k > 0 then
              done := True
            else
              Dec(i);                            {shrink closure by one after each failure}
          end {while};

          offset := k;
          done   := True;
        end else
        if Not (Omatch(offset,j)) then begin
          offset := 0;
          done   := True;
        end else begin
          Inc(j);
        end {begin};
      end {while};
      Amatch := offset;
{}{}end {Amatch};


  begin {--- IsAcceptable ---}
    IsAcceptable := false; m := 0;
    for n := 0 to MaxState do
     if State.arcs[n]._type = tClosure then inc(m);
     if m > 10 then Exit;
    IsAcceptable := (Amatch(1, 0) > 0);
{}end {IsAcceptable};

{ Added 02.03.99 }
function IsUNIXCheckBoxStr(P: PString): Boolean;
begin
  IsUNIXCheckBoxStr := (P <> nil) and (Length(P^) > 1) and
    (P^[1] = '~') and (P^[2] = 'U');
end;

function GetUNIXCheckBox(G: PGroup; var Mask: Word): PCheckBoxes;

function IsUNIXCheckBox(P: PView): Boolean; far;
var
  B: Boolean;
  I: Integer;
begin
  B := False;
  if TypeOf(P^) = TypeOf(TCheckBoxes) then
    for I := 0 to PCheckBoxes(P)^.Strings.Count - 1 do
      if PCheckBoxes(P)^.ButtonState(I) and
	 IsUNIXCheckBoxStr(PCheckBoxes(P)^.Strings.At(I)) then
      begin
	B := True;
	Mask := 1 shl I;
	Break;
      end;
  IsUNIXCheckBox := B;
end;

begin
  GetUNIXCheckBox := PCheckBoxes(G^.FirstThat(@IsUNIXCheckBox));
end;

function UNIXPutHistoryFunc(Link: PInputLine;
  const S: String): String;
var
  Mask: Word;
  P: PCheckBoxes;
begin
  P := GetUNIXCheckBox(Link^.Owner, Mask);
  if (S = '') or (P = nil) or (P^.Value and Mask = 0) then
    UNIXPutHistoryFunc := S
  else UNIXPutHistoryFunc := S + UNIXHistStr;
end;

function UNIXGetHistoryFunc(Link: PInputLine;
  const S: String): String;
var
  I: Integer;
  Mask: Word;
  P: PCheckBoxes;
begin
  I := Pos(UNIXHistStr, S);
  P := GetUNIXCheckBox(Link^.Owner, Mask);
  if P <> nil then
  begin
    P^.PreserveBits := Mask;
    if I <> 0 then P^.Value := P^.Value or Mask
    else P^.Value := P^.Value and not Mask;
    P^.DrawView;
  end;
  if I <> 0 then UNIXGetHistoryFunc := Copy(S, 1, I - 1)
  else UNIXGetHistoryFunc := S;
end;

end.
