{$F+,O+,X+}
unit EditChk;

interface

uses FEditor;

procedure CheckSpellingPrim(Editor: PFileEditor);
procedure DeleteFromDictionaryPrim(Editor: PFileEditor);

implementation

uses Objects, Drivers, Views, MsgBox, App, Swaps, EditMsg, EditTabl,
  SpellChk, CRC32, Tags, Keyboard, TPString, Defaults;

const
  Letters = ['A'..'Z', 'a'..'z', '€'..'Ÿ', ' '..'¯', 'à'..'ï', #240, #241];
  DicStr = 'the Spell Checker Dictionary';

procedure CheckSpellingPrim(Editor: PFileEditor);
const
  StatusInfo = 'Spell checking in progress. Total words: %d, new: %d';
var
  SaveSelect, SaveColumns, AddAll: Boolean;
  LoX, HiX, PX: Byte;
  C: Word;
  I, IP, LoY, HiY: Integer;
  CRC, Pos: Longint;
  Stream: PStream;
  CRCList: PTagList;
  Params: Array[0..1] of Longint;
  SaveArea: TArea;
  Spot: TPoint;
  R: TRect;
  Name: FNameStr;
  S, PS, SS: String;

function FirstWord: Boolean;
var
  B: Byte;
begin
  FirstWord := False;
  for B := LoX - 1 downto 1 do
    if S[B] <> ' ' then Exit;
  FirstWord := True;
end;

function WrappedWord: Boolean;
begin
  WrappedWord := (Length(PS) > 1) and
    (PS[Length(PS)] = '-') and (PS[Length(PS) - 1] in Letters);
end;

function GetLoX: Boolean;
begin
  GetLoX := False;
  LoY := I;
  HiY := I;
  with Editor^ do LoX := Delta.X + Cursor.X + 1;
  while (LoX <> 0) and (LoX <= Length(S)) and
    not (S[LoX] in Letters) do Inc(LoX);
  if (LoX = 0) or (LoX > Length(S)) then Exit;
  HiX := LoX;
  while (LoX > 1) and (S[LoX - 1] in Letters) do Dec(LoX);
  if (I > 0) and FirstWord then
  begin
    PX := LoX;
    IP := I;
    repeat
      Dec(IP);
      Editor^.GetValidLine(IP, PS);
      if (PS <> '') and (Trim(PS) <> '') then
      begin
        if WrappedWord then
        begin
          LoY := IP;
          LoX := Length(PS) - 1;
          while (LoX > 1) and (PS[LoX - 1] in Letters) do Dec(LoX);
        end;
        Break;
      end;
    until IP = 0;
  end;
  GetLoX := True;
end;

function GetHiX: Boolean;
begin
  while (HiX <> 0) and (HiX <= Length(S)) and
    (S[HiX] in Letters) do Inc(HiX);
  GetHiX := (HiX <> 0) and ((HiX <> Length(S)) or (S[HiX] <> '-'));
end;

procedure GoToWord;
begin
  Inc(Params[0]);
  with Editor^ do
  begin
    DrawFlag := True;
    GoToPos(HiX - 1, HiY);
    DrawFlag := False;
  end;
end;

procedure GetCurrentWord;
begin
  if LoY = HiY then SS := Copy(S, LoX, HiX - LoX)
  else SS := Copy(PS, LoX, Length(PS) - LoX) + Copy(S, PX, HiX - PX);
  UpcaseSt(SS);
end;

function WordAction: Word;
begin
  CRC := GetStringCRC32(SS);
  if (Length(SS) <= 2) or (Length(SS) > 64) or
    CRCList^.Search(Pointer(CRC), IP) or
    CRCSearch(Stream, CRC, Pos) then C := cmNo
  else if AddAll then C := cmYes
  else with Editor^ do
  begin
    SetArea(Area, LoY, LoX, HiY, HiX);
    IsSelected := True;
    SaveColumns := MarkColumns;
    MarkColumns := False;
    DrawView;
    MarkColumns := SaveColumns;
    IsSelected := False;
    MakeGlobal(Cursor, Spot);
    if Spot.Y < ScreenHeight div 2 then
      R.Assign(19, Spot.Y + 1, 61, Spot.Y + 10)
    else R.Assign(19, Spot.Y - 10 - Byte(LoY <> HiY),
      61, Spot.Y - 1 - Byte(LoY <> HiY));
    C := MessageBoxRect(R,
      ^C'Unknown or misspelt word:'#13 +
      ^C + System.Copy(SS, 1, 37) + #13 +
      ^C'Add it to the Dictionary ?',
      nil, mfConfirmation + mfYesAllNoCancel);
    DrawView;
    if C = cmOk then
    begin
      C := cmYes;
      AddAll := True;
    end
    else if C = cmNo then CRCList^.AtInsert(IP, Pointer(CRC));
  end;
  if C = cmYes then
  begin
    if not AddAll then
    begin
      SS := 'Adding ' + SS + ' to ' + DicStr + '.';
      LogEvent := lcDiskWrite;
      DrawStatusLine(SS);
    end;
    CRCAdd(Stream, Pos, CRC);
    if Stream^.Status <> stOk then
    begin
      CouldNotWriteMsgBox(Name);
      C := cmCancel;
    end
    else Inc(Params[1]);
  end;
  WordAction := C;
end;

procedure DrawInfo;
begin
  FormatStr(SS, StatusInfo, Params);
  LogEvent := 0;
  DrawStatusLine(SS);
end;

label
  Stop;
begin
  DrawStatusLine('Initializing the Spell Checker.');
  SetCNConfigName(Name, 'DIC');
  InitCRCStream(Name, Stream);
  if Stream^.Status <> stOk then CouldNotOpenMsgBox(Name)
  else with Editor^ do
  begin
    CRCList := New(PTagList, Init(16, 16));
    Params[0] := 0;
    Params[1] := 0;
    SaveArea := Area^;
    SaveSelect := IsSelected;
    IsSelected := False;
    AddAll := False;
    for I := Delta.Y + Cursor.Y to FileLines^.Count - 1 do
    begin
      GetValidLine(I, S);
      if (S <> '') and (TableLine(S) = tlNo) then
        while GetLoX and GetHiX do
        begin
          GoToWord;
          GetCurrentWord;
          if WordAction = cmCancel then Goto Stop;
        end;
      DrawInfo;
      GoToPos(0, I + 1);
      if (KbdStatus = 1) and AbortAction then Break;
    end;
Stop:
    Dispose(CRCList, Done);
    Area^ := SaveArea;
    IsSelected := SaveSelect;
    DrawView;
  end;
  Dispose(Stream, Done);
end;

procedure DeleteFromDictionaryPrim(Editor: PFileEditor);
var
  LoX, HiX, PX, NX: Byte;
  I, IP, II, LoY, HiY: Integer;
  CRC, Pos: Longint;
  Stream: PStream;
  CRCList: PTagList;
  S, PS, NS, SS: String;

function FirstWord: Boolean;
var
  B: Byte;
begin
  FirstWord := False;
  for B := LoX - 1 downto 1 do
    if S[B] <> ' ' then Exit;
  FirstWord := True;
end;

function WrappedWord: Boolean;
begin
  WrappedWord := (Length(PS) > 1) and
    (PS[Length(PS)] = '-') and (PS[Length(PS) - 1] in Letters);
end;

function GetLoX: Boolean;
begin
  GetLoX := False;
  LoY := I;
  HiY := I;
  with Editor^ do LoX := Delta.X + Cursor.X + 1;
  while (LoX <> 0) and (LoX <= Length(S)) and
    not (S[LoX] in Letters) do Inc(LoX);
  if (LoX = 0) or (LoX > Length(S)) then Exit;
  HiX := LoX;
  while (LoX > 1) and (S[LoX - 1] in Letters) do Dec(LoX);
  if (I > 0) and FirstWord then
  begin
    PX := LoX;
    IP := I;
    repeat
      Dec(IP);
      Editor^.GetValidLine(IP, PS);
      if (PS <> '') and (Trim(PS) <> '') then
      begin
        if WrappedWord then
        begin
          LoY := IP;
          LoX := Length(PS) - 1;
          while (LoX > 1) and (PS[LoX - 1] in Letters) do Dec(LoX);
        end;
        Break;
      end;
    until IP = 0;
  end;
  GetLoX := True;
end;

function GetHiX: Boolean;
begin
  GetHiX := False;
  while (HiX <> 0) and (HiX <= Length(S)) and
    (S[HiX] in Letters) do Inc(HiX);
  if (HiX = Length(S)) and (S[HiX] = '-') then
  begin
    II := I;
    repeat
      Inc(II);
      Editor^.GetValidLine(II, NS);
      if (NS <> '') and (Trim(NS) <> '') then
      begin
        HiY := II;
        HiX := 1;
        while (HiX <> 0) and (HiX <= Length(NS)) and
          (NS[HiX] = ' ') do Inc(HiX);
        if (HiX = 0) or (HiX > Length(NS)) or
          not (NS[HiX] in Letters) then Exit;
        NX := HiX;
        while (HiX <> 0) and (HiX <= Length(NS)) and
          (NS[HiX] in Letters) do Inc(HiX);
        Break;
      end;
    until II >= Editor^.FileLines^.Count;
  end;
  GetHiX := HiX <> 0;
end;

procedure GetCurrentWord;
begin
  if LoY = HiY then SS := Copy(S, LoX, HiX - LoX)
  else if LoY = I then
    SS := Copy(S, LoX, Length(S) - LoX) + Copy(NS, NX, HiX - NX)
  else SS := Copy(PS, LoX, Length(PS) - LoX) + Copy(S, PX, HiX - PX);
  UpcaseSt(SS);
end;

begin
  with Editor^ do
  begin
    I := Delta.Y + Cursor.Y;
    GetValidLine(I, S);
  end;
  if not GetLoX or not GetHiX then Exit;
  GetCurrentWord;
  UpcaseSt(SS);
  if (Length(SS) <= 2) or (Length(SS) > 64) or
     (MessageBox(^C'Delete the word'#13 +
       ^C + System.Copy(SS, 1, 35) + #13^C'from ' + DicStr + ' ?',
       nil, mfConfirmation + mfOkCancel) = cmCancel) then Exit;
  SetCNConfigName(S, 'DIC');
  InitCRCStream(S, Stream);
  if Stream^.Status <> stOk then CouldNotOpenMsgBox(S)
  else
  begin
    CRCList := New(PTagList, Init(1, 1));
    CRC := GetStringCRC32(SS);
    Dispose(CRCList, Done);
    if not CRCSearch(Stream, CRC, Pos) then
      SearchStringNotFoundMsgBox
    else
    begin
      LogEvent := lcDiskWrite;
      DrawStatusLine('Deleting ' + SS + ' from ' + DicStr + '.');
      CRCDelete(Stream, Pos);
      if Stream^.Status <> stOk then CouldNotWriteMsgBox(S);
    end;
  end;
  Dispose(Stream, Done);
end;

end.