{$I-,F+,O+,X+}
unit Snipper;

interface

procedure CopySnipper;
procedure CopyToMultitasker;
procedure PasteFromMultitasker;

implementation

uses Objects, Drivers, Views, Memory, App, MsgBox, EditMsg,
  Swaps, FEditor, Clipbrd, ClipPrim, Desktops, DosTools, WinClip,
TPString, Commands, Defaults;

procedure DoneCopyToClip(SaveCount: Integer; MaxLen: Byte);
begin
  ClipOverflow;
  SetOrExpandClipArea(SaveCount, MaxLen);
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
  Application^.Current^.SetState(sfFocused, True);
end;

procedure CopySnipper;
var
  P: PByteArray;
  Pos: Word;
  SaveCount: Integer;
  C, MaxLen: Byte;
  S: String;
begin
  SetExpandClipAreaFlag;
  SaveCount := PSwapLinesCollection(ClipLines)^.Count;
  P := ExchBufferPtr^.TxtBufferPtr;
  MaxLen := 0;
  Pos := 0;
  while (Pos < ExchBufferPtr^.TxtBufferEnd - 1) and
    (DiskClipStream^.Status = stOk) and
    (PSwapLinesCollection(ClipLines)^.Status <> coOverflow) do
  begin
    C := P^[Pos] + 1;
    if not MarkColumns or (C > MaxLen) then MaxLen := C;
    Move(P^[Pos], S, C);
    PutClipLine(S);
    Inc(Pos, C);
  end;
  ExchBufferPtr^.Snipp_ClearBuffer;
  ExchBufferPtr^.TxtBufferEnd := 0;
  DoneCopyToClip(SaveCount, MaxLen);
end;

const
  mtNo = 0;
  mtWin = 1;

function DetectMultitasker: Byte;
begin
  if IdentifyWinOldAp then DetectMultitasker := mtWin
  else DetectMultitasker := mtNo;
end;

function OpenMultiClip(MultiId: Byte): Boolean;
var
  B: Boolean;
begin
  B := False;
  case MultiId of
    mtWin: B := OpenWinClipboard;
  end;
  if not B then MessageBox(^C'Error accessing MS Windows Clipboard.',
    nil, mfError + mfOkButton);
  OpenMultiClip := B;
end;

function CloseMultiClip(MultiId: Byte): Boolean;
var
  B: Boolean;
begin
  B := False;
  case MultiId of
    mtWin: B := CloseWinClipboard;
  end;
  if not B then MessageBox(^C'Error closing MS Windows Clipboard.',
    nil, mfError + mfOkButton);
  CloseMultiClip := B;
end;

procedure AllocBuffer(var Buffer: PByteArray; var BufSize: Word);
begin
  BufSize := $FF01;
  repeat
    Buffer := MemAlloc(BufSize);
    if Buffer <> nil then Break;
    Dec(BufSize, $1000);
    if BufSize < $1000 then Break;
  until False;
  if Buffer = nil then Application^.OutOfMemory;
end;

procedure FillBuffer(Buffer: PByteArray; BufSize: Word;
  var BufBytes: Longint);
var
  C: Byte;
  I: Integer;
  S: String;
begin
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
  BufBytes := 0;
  for I := ClipArea^.KB to ClipArea^.KK do
  begin
    GetClipLine(I, S);
    C := Length(S);
    if BufBytes + C + 4 > BufSize then Break;
    Move(S[1], Buffer^[BufBytes], C);
    Inc(BufBytes, C);
    if I < ClipArea^.KK then
    begin
      Buffer^[BufBytes] := 13;
      Inc(BufBytes);
      Buffer^[BufBytes] := 10;
      Inc(BufBytes);
    end;
    if EscPressed then Break;
  end;
  Buffer^[BufBytes] := 0;
  Inc(BufBytes);
end;

procedure CopyToAltClip;
var
  Ok: Boolean;
  BufSize: Word;
  BufBytes: Longint;
  Buffer: PByteArray;
  F: File;
  S: FNameStr;
begin
  if (DiskClipStream = nil) or not ClipAreaSelected then Exit;
  AllocBuffer(Buffer, BufSize);
  if Buffer = nil then Exit;
  FillBuffer(Buffer, BufSize, BufBytes);
  GetValidSwapDir(S, False);
  S := Concat(S, 'CONNECT.CLP');
  DrawStatusLine('Copying the selected text to additional Clipboard.');
  Ok := False;
  Assign(F, S);
  Rewrite(F, 1);
  if IOResult = 0 then
  begin
    BlockWrite(F, Buffer^, BufBytes);
    Ok := IOResult = 0;
    Close(F);
    InOutRes := 0;
  end;
  if not Ok then CouldNotWriteMsgBox(S);
  FreeMem(Buffer, BufSize);
end;

procedure CopyToWinClip;
var
  BufSize: Word;
  BufBytes: Longint;
  Buffer: PByteArray;
begin
  if (DiskClipStream = nil) or not ClipAreaSelected then Exit;
  AllocBuffer(Buffer, BufSize);
  if Buffer = nil then Exit;
  DrawStatusLine('Copying the selected text to MS Windows Clipboard.');
  FillBuffer(Buffer, BufSize, BufBytes);
  if not ClearWinClipboard or not SetWinClipboardData(Buffer, BufBytes) then
    MessageBox(^C'Error copying data to MS Windows Clipboard.',
      nil, mfError + mfOkButton);
  FreeMem(Buffer, BufSize);
end;

procedure CopyToMultitasker;
var
  MultiId: Byte;
begin
  MultiId := DetectMultitasker;
  if (MultiId = mtWin) and not OpenMultiClip(MultiId) then Exit;
  case MultiId of
    mtNo: CopyToAltClip;
    mtWin: CopyToWinClip;
  end;
  if MultiId = mtWin then CloseMultiClip(MultiId);
end;

procedure ScanMultiBuffer(Buffer: PByteArray; BufSize: Word);
var
  LastEmpty: Boolean;
  MaxWidth, B: Byte;
  BufPos, C: Word;
  SaveCount: Integer;
  MaxLen: Byte;
  S: String;
begin
  SetExpandClipAreaFlag;
  SaveCount := PSwapLinesCollection(ClipLines)^.Count;
{
  if TheClipboard <> nil then MaxWidth :=
    PFileEditor(TheClipboard^.Editor)^.LocalMaxLineWidth
  else MaxWidth := MaxLineWidth;
  if MaxWidth < 32 then MaxWidth := 32;
}
  MaxWidth := 255; { Fixed 06-24-03 }
  MaxLen := 0;
  BufPos := 0;
  C := 0;
  LastEmpty := False;
  while (BufPos < BufSize - 1) and
    (DiskClipStream^.Status = stOk) and
    (PSwapLinesCollection(ClipLines)^.Status <> coOverflow) do
  begin
    BufPos := C;
    while (C < BufSize) and (C - BufPos < MaxWidth) and
      not (Buffer^[C] in [0, 10]) do Inc(C);
    if C - BufPos = MaxWidth then
    begin
      B := 0;
      while (B < 32) and (Buffer^[C] <> 32) do
      begin
	Dec(C);
	Inc(B);
      end;
      if B < 32 then B := 1;
      Inc(C, B);
      if C - BufPos > 255 then C := BufPos + 255;
    end;
    S[0] := Char(C - BufPos);
    Move(Buffer^[BufPos], S[1], Length(S));
    while S[Length(S)] = #13 do Dec(S[0]);
    if not MarkColumns or (Length(S) >= MaxLen) then
      MaxLen := Length(S) + 1;
    PutClipLine(S);
    LastEmpty := S = '';
    while (C < BufSize) and (Buffer^[C] = 10) do Inc(C);
    if (C >= BufSize) or (Buffer^[C] = 0) or EscPressed then Break;
  end;
  if LastEmpty then PutClipLine(S);
  DoneCopyToClip(SaveCount, MaxLen);
end;

procedure PasteFromAltClip;
var
  Size: Longint;
  Buffer: PByteArray;
  F: File;
  S: FNameStr;
begin
  GetValidSwapDir(S, False);
  S := Concat(S, 'CONNECT.CLP');
  DrawStatusLine('Pasting text from additional Clipboard.');
  Assign(F, S);
  ResetReadOnly(F, 1);
  Size := FileSize(F);
  if (IOResult <> 0) or (Size = 0) then
  begin
    Close(F);
    InOutRes := 0;
    MessageBox(^C'Additional Clipboard is empty.',
      nil, mfError + mfOkButton);
    Exit;
  end;
  if Size >= $FF01 then
  begin
    Close(F);
    InOutRes := 0;
    Application^.OutOfMemory;
    Exit;
  end;
  Buffer := MemAlloc(Size);
  if Buffer = nil then
  begin
    Close(F);
    InOutRes := 0;
    Application^.OutOfMemory;
    Exit;
  end;
  BlockRead(F, Buffer^, Size);
  Close(F);
  InOutRes := 0;
  ScanMultiBuffer(Buffer, Size);
  FreeMem(Buffer, Size);
end;

procedure PasteFromWinClip;
var
  Size: Longint;
  Buffer: PByteArray;
begin
  Size := GetWinClipboardDataSize;
  if Size = 0 then
  begin
    MessageBox(^C'MS Windows Clipboard is empty.',
      nil, mfError + mfOkButton);
    Exit;
  end;
  if Size >= $FF01 then
  begin
    Application^.OutOfMemory;
    Exit;
  end;
  Buffer := MemAlloc(Size);
  if Buffer = nil then
  begin
    Application^.OutOfMemory;
    Exit;
  end;
  if not GetWinClipboardData(Buffer) then OpenMultiClip(mtNo)
  else
  begin
    DrawStatusLine('Pasting data from MS Windows Clipboard.');
    ScanMultiBuffer(Buffer, Size);
  end;
  FreeMem(Buffer, Size);
end;

procedure PasteFromMultitasker;
var
  MultiId: Byte;
begin
  MultiId := DetectMultitasker;
  if (MultiId = mtWin) and not OpenMultiClip(MultiId) then Exit;
  case MultiId of
    mtNo: PasteFromAltClip;
    mtWin: PasteFromWinClip;
  end;
  if MultiId = mtWin then CloseMultiClip(MultiId);
end;

end.