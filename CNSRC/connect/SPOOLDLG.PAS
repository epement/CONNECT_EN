{$I-,X+,O+,F+}
unit SpoolDlg;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PSpoolerList = ^TSpoolerList;
  TSpoolerList = object(TListViewer)
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure NewSource;
    procedure NextItem;
    procedure Update;
  end;

  PSpoolerDialog = ^TSpoolerDialog;
  TSpoolerDialog = object(TDialog)
    SpoolerList: PSpoolerList;
    constructor Init;
    constructor Load(var S: TStream);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
  end;

procedure RSRSpoolerDialog(RSR: PResourceFile);
procedure SpoolerDialog;

implementation

uses App, MsgBox, StdDlg, EditMsg, Spooler, HistList, History,
  FEditor, HEditor, HTMLView, Strings, Consts, Commands, Defaults;

procedure UpdateCommands;
begin
  with Application^ do
  begin
    EnableCommands(NewCommands + RunItemCommands);
    if TheSpooler^.Count = 0 then
      DisableCommands(ModifyCommands + DeleteCommands)
    else
    begin
      EnableCommands(DeleteCommands);
      if TheSpooler^.Count > 2 then EnableCommands(ModifyCommands)
      else DisableCommands(ModifyCommands);
    end;
  end;
end;

function TSpoolerList.GetText(Item: Integer; MaxLen: Integer): String;
const
  ofHTML = $8000;
var
  P: PSpoolerRec;
  E: PHexEditor;
  Params: Array[0..4] of Longint;
  ES, NS: String[15];
  TS: String[222];
  S: String;
begin
  if Item > TheSpooler^.Count - 1 then GetText := ''
  else
  begin
    P := TheSpooler^.At(Item);
    if P^.FromDisk then
    begin
      ES := 'File ';
      TS := StrPas(P^.Source^.FullName);
      Params[2] := P^.SourceSize;
      NS := 'byte';
    end
    else
    begin
      E := P^.Editor;
      if (E^.Options and (ofASCII + ofHTML) <> 0) or E^.IsClip then
      begin
	if E^.Options and ofHTML <> 0 then ES := 'HTML '
	else ES := 'ASCII';
	if P^.Lo >= 0 then Params[2] := P^.Hi - P^.Lo + 1
	else if E^.Options and ofHTML <> 0 then
	  Params[2] := PHTMLViewer(E)^.FileLines^.Count
	else Params[2] := E^.FileLines^.Count;
	if Params[2] <= 0 then Params[2] := 1;
	NS := 'line';
	if P^.Lo >= 0 then NS := 'selected ' + NS;
      end
      else
      begin
	ES := 'Hex  ';
	if P^.Lo >= 0 then
	begin
	  Params[2] := P^.Hi - P^.Lo + 1;
	  NS := 'selected line';
	  Params[3] := Longint(@NS);
	end
	else
	begin
	  Params[2] := E^.NumBytes;
	  NS := 'byte';
	end;
      end;
      if E^.Options and ofHTML <> 0 then
	TS := PHTMLViewer(E)^.SourceName^
      else TS := PEditorWindow(E^.Owner)^.Title^;
    end;
    Params[0] := Longint(@ES);
    Params[1] := Longint(@TS);
    Params[3] := Longint(@NS);
    if Params[2] = 1 then Params[4] := Byte(' ')
    else Params[4] := Byte('s');
    FormatStr(S, '%s %s  %d %s%c', Params);
    GetText := S;
  end;
end;

procedure TSpoolerList.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmModifyItem;
    Event.What := evNothing;
  end
  else TListViewer.HandleEvent(Event);
end;

procedure TSpoolerList.NewSource;
type
  TData = record
    Name: FNameStr;
    Opt: Word;
  end;
var
  D: PFileDialog;
  R: TRect;
  Data: TData;
begin
  D := New(PFileDialog, Init('*.*', 'Print a file', '~N~ame',
    fdOkButton + fdHelpButton, HistoryID));
  with D^ do
  begin
    R.Assign(Size.X - 14, Size.Y - 5, Size.X - 2, Size.Y - 4);
    Insert(New(PCheckBoxes, Init(R, NewSItem('~B~inary', nil))));
    SelectNext(False);
  end;
  Data.Name := HistoryStr(HistoryID, 0);
  Data.Opt := Byte(BinaryPrinting);
  if Application^.ExecuteDialog(D, @Data, True) <> cmCancel then
  begin
    BinaryPrinting := Data.Opt and 1 <> 0;
    if TheSpooler^.NewSource(Data.Name) <> nil then
    begin
      Update;
      FocusItem(Range - 1);
    end;
  end;
end;

procedure TSpoolerList.NextItem;
var
  P: Pointer;
begin
  if Focused > 1 then with TheSpooler^ do
  begin
    P := At(Focused);
    AtDelete(Focused);
    AtInsert(1, P);
    FocusItem(1);
  end;
end;

procedure TSpoolerList.Update;
begin
  SetRange(TheSpooler^.Count);
  UpdateCommands;
  DrawView;
end;

constructor TSpoolerDialog.Init;
var
  VBar, HBar: PScrollBar;
  R: TRect;
begin
  R.Assign(0, 0, 70, 17);
  TDialog.Init(R, 'Spooler');
  Options := Options or ofCentered;
  HelpCtx := hcSpooler;

  R.Assign(3, Size.Y - 4, Size.X - 15, Size.Y - 3);
  HBar := New(PScrollBar, Init(R));
  HBar^.Options := HBar^.Options or ofPostProcess;
  HBar^.SetRange(0, 255);
  Insert(HBar);
  R.Assign(Size.X - 15, 3, Size.X - 14, Size.Y - 4);
  VBar := New(PScrollBar, Init(R));
  VBar^.Options := VBar^.Options or ofPostProcess;
  Insert(VBar);

  R.Assign(3, 3, Size.X - 15, Size.Y - 4);
  SpoolerList := New(PSpoolerList, Init(R, 1, HBar, VBar));
  Insert(SpoolerList);
  R.Assign(2, 2, 56, 3);
  Insert(New(PLabel, Init(R, '~S~pooler queue', SpoolerList)));

  R.Assign(Size.X - 13, 3, Size.X - 3, 5);
  Insert(New(PButton, Init(R, '~F~ile', cmFileOpen, bfDefault)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~N~ext', cmModifyItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~A~bort', cmRunItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardCancelButton(R, @Self);
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardHelpButton(R, @Self);

  SpoolerList^.Select;
  SpoolerList^.FocusItem(0);
end;

constructor TSpoolerDialog.Load(var S: TStream);
begin
  TheSpooler^.Update;
  TDialog.Load(S);
  GetSubViewPtr(S, SpoolerList);
  SpoolerList^.SetRange(TheSpooler^.Count);
  UpdateCommands;
end;

procedure TSpoolerDialog.HandleEvent(var Event: TEvent);
begin
  TDialog.HandleEvent(Event);
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbDel:
        begin
          Event.What := evCommand;
          Event.Command := cmDeleteItem;
        end;
      kbIns:
        begin
          Event.What := evCommand;
	  Event.Command := cmFileOpen;
        end;
    end;
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmFileOpen: SpoolerList^.NewSource;
      cmModifyItem: SpoolerList^.NextItem;
      cmDeleteItem: if DeleteItemMsgBox = cmOk then
	TheSpooler^.DeleteItem(SpoolerList^.Focused);
      cmRunItem:
	begin
	  TheSpooler^.Abort;
	  SpoolerList^.Select;
	end;
      else Exit;
    end;
    SpoolerList^.Select;
    SpoolerList^.DrawView;
    Event.What := evNothing;
  end
  else if Event.What = evBroadcast then
    case Event.Command of
      cmUpdateViews:
        begin
          SpoolerList^.Update;
	  Event.What := evNothing;
	end;
    end;
end;

procedure TSpoolerDialog.Store(var S: TStream);
begin
  TDialog.Store(S);
  PutSubViewPtr(S, SpoolerList);
end;

procedure RSRSpoolerDialog(RSR: PResourceFile);
var
  D: PSpoolerDialog;
begin
  D := New(PSpoolerDialog, Init);
  RSR^.Put(D, 'SPOOLERDIALOG');
  Dispose(D, Done);
end;

procedure SpoolerDialog;
var
  D: PSpoolerDialog;
begin
  D := PSpoolerDialog(Resource^.Get('SPOOLERDIALOG'));
  if D <> nil then Application^.ExecuteDialog(D, nil, False)
  else ResourceNotFoundMsgBox('Spooler dialog');
end;

end.
