uses Dos, Objects, TPString;

type
  PPhoneEntry = ^TPhoneEntry;
  TPhoneEntry = object(TSortedCollection)
    Name: PString;
    Phone: PString;
    Notes: PString;
    Owner: PPhoneEntry;
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure Insert(Item: Pointer); virtual;
    procedure Store(var S: TStream); virtual;
  end;

const
  RPhoneEntry: TStreamRec = (
    ObjType: 1185;
    VmtLink: Ofs(TypeOf(TPhoneEntry)^);
    Load:    @TPhoneEntry.Load;
    Store:   @TPhoneEntry.Store
  );

  PhoneDelta = 4;

constructor TPhoneEntry.Load(var S: TStream);
begin
  Inherited Load(S);
  Name := S.ReadStr;
  Phone := S.ReadStr;
  Notes := S.ReadStr;
end;

destructor TPhoneEntry.Done;
begin
  DisposeStr(Notes);
  DisposeStr(Phone);
  DisposeStr(Name);
  Inherited Done;
end;

function TPhoneEntry.Compare(Key1, Key2: Pointer): Integer;
var
  S1, S2: String;
begin
  if PPhoneEntry(Key1)^.Name = nil then S1 := ''
  else S1 := StUpcase(PPhoneEntry(Key1)^.Name^);
  if PPhoneEntry(Key2)^.Name = nil then S2 := ''
  else S2 := StUpcase(PPhoneEntry(Key2)^.Name^);
  if S1 < S2 then Compare := -1
  else Compare := 1;
end;

function TPhoneEntry.GetItem(var S: TStream): Pointer;
var
  Item: PPhoneEntry;
begin
  Item := Inherited GetItem(S);
  if Item <> nil then Item^.Owner := @Self;
  GetItem := Item;
end;

procedure TPhoneEntry.Insert(Item: Pointer);
begin
  if Item <> nil then PPhoneEntry(Item)^.Owner := @Self;
  Inherited Insert(Item);
end;

procedure TPhoneEntry.Store(var S: TStream);
begin
  Inherited Store(S);
  S.WriteStr(Name);
  S.WriteStr(Phone);
  S.WriteStr(Notes);
end;

var
  Stream: PDosStream;
  P, Item: PPhoneEntry;
  F: Text;
  InName, OutName: FNameStr;
  S, NameStr, PhoneStr, NotesStr: String;

procedure Stop(const Msg: String; CloseInput, CloseOutput: Boolean);
begin
  if CloseInput then Dispose(Stream, Done);
  if CloseOutput then Close(F);
  Writeln(Msg);
  Halt(1);
end;

procedure AddItem;
var
  Found: Boolean;
  Level, B: Byte;
  I: Integer;
  PP: PPhoneEntry;
  SS: String;
begin
  Level := 0;
  PP := P;
  repeat
    Inc(Level);
    if Level > 32 then
    begin
      Writeln('Too many entries in line, skipping: ', NameStr);
      Break;
    end;
    B := Pos('\', NameStr);
    if B = 0 then
    begin
      SS := NameStr;
      NameStr := '';
    end
    else
    begin
      SS := Copy(NameStr, 1, B - 1);
      Delete(NameStr, 1, B);
    end;
    if SS <> '' then
    begin
      Found := False;
      if NameStr <> '' then for I := 0 to PP^.Count - 1 do
      begin
        Item := PP^.At(I);
        if (Item^.Name <> nil) and
           (StUpcase(Item^.Name^) = StUpcase(SS)) then
        begin
          PP := Item;
          Found := True;
          Break;
        end;
      end;
      if not Found then
      begin
        Item := New(PPhoneEntry, Init(PhoneDelta, PhoneDelta));
        Item^.Name := NewStr(SS);
        PP^.Insert(Item);
        PP := Item;
      end;
    end;
  until NameStr = '';
  if PP <> P then
  begin
    DisposeStr(PP^.Phone);
    PP^.Phone := NewStr(PhoneStr);
    DisposeStr(PP^.Notes);
    PP^.Notes := NewStr(NotesStr);
  end;
end;

const
  UnexpectedMsg: String[30] = 'Unexpected end of source file.';

function IsDev(var T : text): boolean; assembler;
asm
 les di, T
 mov ax,$4400
 mov bx, es:[di]
 int 21h
 mov ax, dx
 and al,80h
end;

begin
  WriteLn('Text -> CONNECT.PHN Copyright (c) 1995 KHEMZ Inc.');
  WriteLn('TXT2PHN [FileName]|[< FileName]');
  InName := ParamStr(1);
  OutName := FExpand('CONNECT.PHN');
  if FExpand(InName) = FExpand(OutName) then
    Stop('Source file and output file must differ.', False, False);
  Assign(F, InName);
  Reset(F);
  if IsDev(F) or (IOResult <> 0) then Stop('Could not open source file.', False, False);
  Stream := New(PDosStream, Init(OutName, stCreate));
  if Stream^.Status <> stOk then
    Stop('Could not create output file.', True, False);

  RegisterType(RPhoneEntry);
  P := New(PPhoneEntry, Init(PhoneDelta, PhoneDelta));
  repeat
    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 4)) = 'NAME' then Break;
    until Eof(F);
    if Eof(F) then Break;
    NameStr := Copy(S, 6, 255);

    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 5)) = 'PHONE' then Break;
    until Eof(F);
    if Eof(F) then Stop(UnexpectedMsg, True, True);
    PhoneStr := Copy(S, 7, 255);

    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 5)) = 'NOTES' then Break;
    until Eof(F);
    NotesStr := Copy(S, 7, 255);

    AddItem;
  until False;
  Close(F);

  Stream^.Put(P);
  if Stream^.Status <> stOk then
    Stop('Error writing to output file.', True, True);
  Dispose(P, Done);
  Dispose(Stream, Done);
end.
