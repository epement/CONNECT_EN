uses Objects, TPString;

type
  PInRec = ^TInRec;
  TInRec = record
    Mask: PString;
    Comment: PString;
    Options: Longint;
    TabSize: Byte;
    MaxLineWidth: Byte;
    WordDelims: TCharSet;
  end;

  POutRec = ^TOutRec;
  TOutRec = record
    Mask: PString;
    Comment: PString;
    HelpName: PString;
    INXLATName: PString;
    OUTXLATName: PString;
    Reserved: PString;
    Options: Longint;
    TabSize: Byte;
    MaxLineWidth: Byte;
    WordDelims: TCharSet;
  end;

  PCommentList = ^TCommentList;
  TCommentList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

procedure DisposeInCommentRec(P: PInRec);
begin
  if P = nil then Exit;
  DisposeStr(P^.Comment);
  DisposeStr(P^.Mask);
  FreeMem(P, SizeOf(TInRec));
end;

procedure DisposeOutCommentRec(P: POutRec);
begin
  if P = nil then Exit;
  DisposeStr(P^.Reserved);
  DisposeStr(P^.OUTXLATName);
  DisposeStr(P^.INXLATName);
  DisposeStr(P^.HelpName);
  DisposeStr(P^.Comment);
  DisposeStr(P^.Mask);
  FreeMem(P, SizeOf(TOutRec));
end;

procedure TCommentList.FreeItem(Item: Pointer);
begin
  DisposeInCommentRec(PInRec(Item));
end;

var
  I: Integer;
  S: PDosStream;
  List: PCommentList;
  P: PInRec;
  O: POutRec;
  Name: FNameStr;
begin
  Name := 'CONNECT.CMT';
  S := New(PDosStream, Init(Name, stOpenRead));
  if S^.Status <> stOk then
  begin
    Writeln('File ', Name, ' not found.');
    Halt(1);
  end;
  List := New(PCommentList, Init(8, 8));
  repeat
    GetMem(P, SizeOf(TInRec));
    P^.Mask := S^.ReadStr;
    P^.Comment := S^.ReadStr;
    S^.Read(P^.Options,
      SizeOf(Longint) + SizeOf(Byte) * 2 + SizeOf(TCharSet));
    if S^.Status <> stOk then
    begin
      DisposeInCommentRec(P);
      Break;
    end
    else List^.Insert(P);
  until False;
  Dispose(S, Done);
  S := New(PDosStream, Init(Name, stCreate));
  for I := 0 to List^.Count - 1 do
  begin
    P := List^.At(I);
    GetMem(O, SizeOf(TOutRec));
    if P^.Mask = nil then O^.Mask := nil
    else O^.Mask := NewStr(P^.Mask^);
    if P^.Comment = nil then O^.Comment := nil
    else O^.Comment := NewStr(P^.Comment^);
    O^.HelpName := nil;
    O^.INXLATName := nil;
    O^.OUTXLATName := nil;
    O^.Reserved := nil;
    O^.Options := P^.Options;
    O^.TabSize := P^.TabSize;
    O^.MaxLineWidth := P^.MaxLineWidth;
    O^.WordDelims := P^.WordDelims;
    S^.WriteStr(O^.Mask);
    S^.WriteStr(O^.Comment);
    S^.WriteStr(O^.HelpName);
    S^.WriteStr(O^.INXLATName);
    S^.WriteStr(O^.OUTXLATName);
    S^.WriteStr(O^.Reserved);
    S^.Write(O^.Options,
      SizeOf(Longint) + SizeOf(Byte) * 2 + SizeOf(TCharSet));
    DisposeOutCommentRec(O);
  end;
  Dispose(S, Done);
  Dispose(List, Done);
  Writeln('Comment file upgraded OK.');
end.