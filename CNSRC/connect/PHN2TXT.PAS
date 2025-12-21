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
  S: String;

procedure Stop(const Msg: String; CloseInput, CloseOutput: Boolean);
begin
  if CloseInput then Dispose(Stream, Done);
  if CloseOutput then Close(F);
  Writeln(Msg);
  Halt(1);
end;

function GetFullName(CurEntry: PPhoneEntry): String;
var
  B: Byte;
  PP: PPhoneEntry;
  SS: String;
begin
  SS := '';
  PP := CurEntry;
  repeat
    if PP^.Name <> nil then SS := Concat(PP^.Name^, '\', SS);
    PP := PP^.Owner;
  until PP = nil;
  if SS[Length(SS)] = '\' then Dec(SS[0]);
  GetFullName := SS;
end;

{$S+}
procedure ScanEntry(P: PPhoneEntry);
var
  I: Integer;
begin
  for I := 0 to P^.Count - 1 do
  begin
    Item := P^.At(I);
    S := 'NAME';
    if Item^.Name <> nil then S := S + ' ' + GetFullName(Item);
    Writeln(F, S);
    S := 'PHONE';
    if Item^.Phone <> nil then S := S + ' ' + Item^.Phone^;
    Writeln(F, S);
    S := 'NOTES';
    if Item^.Notes <> nil then S := S + ' ' + Item^.Notes^;
    Writeln(F, S);
    Writeln(F);
    if Item^.Count <> 0 then ScanEntry(Item);
  end;
end;
{$S-}

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
  if IsDev(Output) then
   begin
    WriteLn('CONNECT.PHN -> Text Copyright (c) 1995 KHEMZ Inc.');
    WriteLn('PHN2TXT [FileName.PHN] [OutName.Txt]|[> OutName.Txt]');
   end;
  InName := ParamStr(1);
  if InName = '' then InName := 'CONNECT.PHN';
   {Stop('Source file not specified.', False, False);}
  OutName := ParamStr(2);
  {if OutName = '' then OutName := ForceExtension(InName, 'TXT');}
  if FExpand(InName) = FExpand(OutName) then
    Stop('Source file and output file must differ.', False, False);

  Stream := New(PDosStream, Init(InName, stOpenRead));
  if Stream^.Status <> stOk then
    Stop('Could not open source file.', False, False);
  Assign(F, OutName);
  Rewrite(F);
  if IsDev(F) or (IOResult <> 0) then Stop('Could not create output file.', True, False);

  RegisterType(RPhoneEntry);
  P := PPhoneEntry(Stream^.Get);
  if (P = nil) or (Stream^.Status <> stOk) then
    Stop('Error reading source file.', True, True);

  ScanEntry(P);
  Dispose(P, Done);

  Close(F);
  Dispose(Stream, Done);
end.
