{$X+,O+,F+}
unit HotKeys;

interface

const
  hkSeq = $FFFF;
  MaxHotKeys = $40;

type
  PHotKeySequence = ^THotKeySequence;
  THotKeySequence = Array[0..MaxHotKeys - 1] of Word;

var
  GlobalSequence: THotKeySequence;

function SameKey(EventKey, RecKey: Word): Boolean;
function SameSequence(const S1, S2: THotKeySequence; Size: Word): Boolean;
function HotKeyOptMatch(State: Byte; Options, Count: Word): Boolean;

implementation

uses Objects;

const
  ckNo = 0;
  ckFirst = 1;
  ckAll = 2;

function SameKey(EventKey, RecKey: Word): Boolean;
begin
  if EventKey = 0 then SameKey := False
  else if (WordRec(EventKey).Lo = 0) or
    (WordRec(RecKey).Lo = 0) then SameKey := EventKey = RecKey
  else SameKey := (WordRec(EventKey).Hi = WordRec(RecKey).Hi) and
    (Upcase(Char(EventKey)) = Upcase(Char(RecKey)));
end;

function SameSequence(const S1, S2: THotKeySequence; Size: Word): Boolean;
var
  Index: Integer;
begin
  for Index := 0 to Size - 1 do
    if not SameKey(S1[Index], S2[Index]) then
    begin
      SameSequence := False;
      Exit;
    end;
  SameSequence := True;
end;

function HotKeyOptMatch(State: Byte; Options, Count: Word): Boolean;
begin
  if (WordRec(Options).Hi = ckNo) or
     ((WordRec(Options).Hi = ckFirst) and (Count <> 0)) then
    HotKeyOptMatch := True
  else HotKeyOptMatch :=
    ((WordRec(Options).Lo = 0) and (State = 0)) or
    (WordRec(Options).Lo and State <> 0);
end;

end.
