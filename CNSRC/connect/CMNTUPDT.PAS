uses Objects, TPString;

type
  InRec = record
    Ext: String[3];
    Comment: String[15];
  end;

  OutRec = record
    Mask: String[12];
    Comment: String[15];
    Options: Longint;
    TabSize: Byte;
    MaxLineWidth: Byte;
    WordDelims: TCharSet;
  end;

  PCommentList = ^TCommentList;
  TCommentList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

procedure TCommentList.FreeItem(Item: Pointer);
begin
  if Item <> nil then FreeMem(Item, SizeOf(InRec));
end;

var
  I: Integer;
  Stream: PDosStream;
  List: PCommentList;
  InR: ^InRec;
  OutR: OutRec;
  Name: FNameStr;
begin
  Name := 'CONNECT.CMT';
  Stream := New(PDosStream, Init(Name, stOpenRead));
  if Stream^.Status <> stOk then
  begin
    Writeln('File ', Name, ' not found.');
    Halt(1);
  end;
  List := New(PCommentList, Init(8, 8));
  for I := 1 to Stream^.GetSize div SizeOf(InRec) do
  begin
    GetMem(InR, SizeOf(InRec));
    Stream^.Read(InR^, SizeOf(InRec));
    List^.Insert(InR);
  end;
  Dispose(Stream, Done);
  Stream := New(PDosStream, Init(Name, stCreate));
  for I := 0 to List^.Count - 1 do
  begin
    InR := List^.At(I);
    OutR.Mask := '*.' + InR^.Ext;
    OutR.Comment := InR^.Comment;
    OutR.Options := $ED6;
    OutR.TabSize := 8;
    OutR.MaxLineWidth := 70;
    OutR.WordDelims :=
      [#32, #34, #39..#45, #47, #58..#63, #91..#94, #123..#126];
    Stream^.Write(OutR, SizeOf(OutRec));
  end;
  Dispose(Stream, Done);
  Dispose(List, Done);
end.