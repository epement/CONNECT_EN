{$F+,O+,X+}
unit CDPlayer;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PCDIndicator = ^TCDIndicator;
  TCDIndicator = object(TView)
    Empty: Boolean;
    Track: Byte;
    Mins: Byte;
    Secs: Byte;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
  end;

  PCDInfoPane = ^TCDInfoPane;
  TCDInfoPane = object(TView)
    Text: String[63];
    Progress: Byte;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PTrackDialog = ^TTrackDialog;
  TTrackDialog = object(TDialog)
    Sel: Char;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PCDPlayer = ^TCDPlayer;
  TCDPlayer = object(TDialog)
    NextPlayer: PCDPlayer;
    Indicator: PCDIndicator;
    TrackLabel: PStaticText;
    TimeLabel: PStaticText;
    InfoPane: PCDInfoPane;
    Drive: Byte;
    TrackLabelMode: Byte;
    TimeLabelMode: Byte;
    CDParams: Word;
    Empty: Boolean;
    Changed: Boolean;
    Playing: Boolean;
    Paused: Boolean;
    Stopped: Boolean;
    DoorLocked: Boolean;
    TrackList: PCollection;
    TrackListTime: Longint;
    TrackListSize: Longint;
    TrackListIndex: Integer;
    UPCCode: String[14];
    AlbumName: String[8];
    AlbumTitle: String[44];
    LyricsCommand: String[127];
    AutoLyrics: Boolean;
    AutoLyricsNum: Byte;
    LoTrack: Byte;
    HiTrack: Byte;
    NumTracks: Byte;
    LeadOutAddr: Longint;
    DiskStart: Longint;
    DiskEnd: Longint;
    DiskMinutes: Byte;
    DiskSeconds: Byte;
    TrackTitle: String[47];
    PlayedTrack: Byte;
    TrackNum: Byte;
    TrackMinute: Byte;
    TrackSecond: Byte;
    TrackMins: Byte;
    TrackSecs: Byte;
    TrackMinsLeft: Byte;
    TrackSecsLeft: Byte;
    DiskMinute: Byte;
    DiskSecond: Byte;
    DiskFrame: Byte;
    DiskMinsLeft: Byte;
    DiskSecsLeft: Byte;
    LastSecond: Byte;
    DoUpdate: Boolean;
    MsgInUse: Boolean;
    IsValid: Boolean;
    constructor Init;
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
    function Valid(Command: Word): Boolean; virtual;
    procedure InitCDDevice;
    procedure InitTrackList;
    procedure DoneTrackList;
    procedure ExecCommand(const S: String);
    function GetCDFileName: FNameStr;
    function GetTrackListNumber(Index: Integer): Byte;
    function GetTrackAlbumStr(Track: Byte): String;
    function GetTrackTitle(Track: Byte): String;
    function GetTrackStart(Track: Byte): Longint;
    function GetTrackNumber(Start: Longint): Byte;
    procedure GetTrackTime(Track: Byte; var Minutes, Seconds: Byte);
    function GetDiskPos: Longint;
    procedure GetAudioDiskInfo;
    procedure GetAudioQChannelInfo;
    procedure GetAudioStatusInfo;
    procedure GetMediaChangedInfo;
    procedure ForceEject(Force: Boolean);
    procedure PlayAudio(From: Longint);
    procedure StartPlay;
    procedure StopPlay;
    procedure PausePlay;
    procedure ResumePlay;
    procedure SkipForward;
    procedure SkipBack;
    procedure FastForward;
    procedure Rewind;
    procedure Restart;
    procedure FirstTrack;
    procedure LastTrack;
    procedure SelectTrack;
    procedure TrackHistory;
    procedure AlbumTitles;
    procedure AlbumLyrics;
    procedure SoundMixer;
    procedure UpdateCommands;
    procedure UpdateIndicator;
    procedure UpdateInfoPane;
    procedure UpdateLabels;
    procedure UpdateTitle;
    procedure UpdateTrackList;
    procedure UpdateViews;
    procedure Update;
  end;

const
  CCDIndicator = #4;
  CCDInfoPane  = #7#8#6#5;
  CCDPlayer    = #211#212#213#214#215#216#217#218#219#220#221#222#223#224 +
		 #225#226#227#228#229#230#231#232#233#234#235#236#237#238 +
		 #239#240#241#242#243;

  CCDColor     = #$70#$7F#$7A#$70#$07#$70#$7E#$3F#$7F#$50#$5B#$5F#$78#$5E +
		 #$70#$07#$0F#$0A#$31#$31#$07#$09#$70#$0F#$3E#$0E#$0B#$3E +
		 #$3B#$00#$00#$5E#$5E;
  CCDBW        = #$70#$7F#$7F#$70#$07#$70#$7F#$7F#$7F#$07#$0F#$0F#$78#$0F +
		 #$78#$07#$0F#$0F#$70#$70#$07#$0F#$70#$0F#$70#$0F#$07#$0F +
		 #$07#$00#$00#$0F#$0F;
  CCDMono      = #$70#$70#$70#$07#$07#$70#$70#$70#$0F#$07#$07#$0F#$70#$0F +
		 #$70#$07#$0F#$0F#$70#$70#$07#$0F#$70#$0F#$70#$0F#$07#$0F +
		 #$07#$00#$00#$0F#$0F;

  CDPlayers: PCDPlayer = nil;

procedure RSRCDPlayer(RSR: PResourceFile);
procedure LoadCDPlayer;
procedure UpdateCDPlayers;

implementation

uses CNCrt, Dos, WinIcons, CDCtl, App, MsgBox, HistList, HistWin, StrCol,
  EditMsg, EditFile, ProgList, ExecPrim, DirPrim, DiskBase, Options, HeapUMB,
  WinPos, CNWinPos, CRC32, LFN, TPString, Consts, Commands, Defaults;

{
  ‹  ‹‹‹  ‹‹‹  ‹ ‹  ‹‹‹  ‹‹‹  ‹‹‹  ‹‹‹  ‹‹‹  ‹‹‹
  €  ‹‹€   ‹€  €‹€  €‹‹  €‹‹    €  €‹€  €‹€  € €  ﬂ
  €  €‹‹  ‹‹€    €  ‹‹€  €‹€    €  €‹€  ‹‹€  €‹€  ﬂ
}

const
  cdZero  = '‹‹‹€ €€‹€';
  cdOne   = '  ‹  €  €';
  cdTwo   = '‹‹‹‹‹€€‹‹';
  cdThree = '‹‹‹ ‹€‹‹€';
  cdFour  = '‹ ‹€‹€  €';
  cdFive  = '‹‹‹€‹‹‹‹€';
  cdSix   = '‹‹‹€‹‹€‹€';
  cdSeven = '‹‹‹  €  €';
  cdEight = '‹‹‹€‹€€‹€';
  cdNine  = '‹‹‹€‹€‹‹€';

  cdChars = cdZero + cdOne + cdTwo + cdThree + cdFour +
            cdFive + cdSix + cdSeven + cdEight + cdNine;

  tmTrack       = 0;
  tmTotal       = 1;

  tmTrackTime   = 0;
  tmTrackTotal  = 1;
  tmTrackLeft   = 2;
  tmDiskTime    = 3;
  tmDiskTotal   = 4;
  tmDiskLeft    = 5;

  MaxHiTrack = 99;
  MaxTrackTitleLen = 43;

procedure AddCDPlayer(Player: PCDPlayer);
var
  P, PP: PCDPlayer;
begin
  if CDPlayers = nil then CDPlayers := Player
  else
  begin
    P := CDPlayers;
    repeat
      PP := P^.NextPlayer;
      if PP = nil then Break;
      P := PP;
    until False;
    P^.NextPlayer := Player;
  end;
end;

procedure RemoveCDPlayer(Player: PCDPlayer);
var
  P, PP: PCDPlayer;
begin
  P := CDPlayers;
  PP := nil;
  while (P <> nil) and (P <> Player) do
  begin
    PP := P;
    P := P^.NextPlayer;
  end;
  if P <> nil then
    if PP = nil then CDPlayers := P^.NextPlayer
    else PP^.NextPlayer := P^.NextPlayer;
end;

procedure UpdateCDPlayers;
var
  P: PCDPlayer;
begin
  P := CDPlayers;
  while P <> nil do
  begin
    P^.Update;
    P := P^.NextPlayer;
  end;
end;

function SecondsToSectors(Seconds: Integer): Longint;
var
  RedBook: TRedBook;
begin
  Inc(Seconds, 2);
  with RedBook do
  begin
    Minute := Seconds div 60;
    Second := Seconds mod 60;
    Frame := 0;
  end;
  SecondsToSectors := RedBookToHSG(RedBook);
end;

function DirectivePos(const Directive, Source: String): Byte;
begin
  DirectivePos := Pos(Directive, StUpcase(Source));
end;

function TitlePos(const S: String): Byte;
begin
  TitlePos := DirectivePos('TITLE:', S);
end;

function LyricsPos(const S: String): Byte;
begin
  LyricsPos := DirectivePos('$LYRICS:', S);
end;

function NoLyricsPos(const S: String): Byte;
begin
  NoLyricsPos := DirectivePos('$NOLYRICS', S);
end;

function HelpPos(const S: String): Byte;
begin
  HelpPos := DirectivePos('$HELP', S);
end;

function AutoPos(const S: String): Byte;
begin
  AutoPos := DirectivePos('$AUTO', S);
end;

procedure SelDriveDlg(var Drive: Byte);
var
  NumRows, B, C: Byte;
  Command: Word;
  LoX, HiX: Integer;
  D: PDriveDialog;
  Control: PView;
  R: TRect;
  LS: String[17];
begin
  NumRows := (CDNumDrives - 1) div 10 + 1;
  LoX := 0;
  HiX := LoX + 6 + CDNumDrives * 6;
  if HiX > 66 then HiX := 66
  else if HiX < 36 then HiX := 36;
  R.Assign(LoX, 0, HiX, 7 + (NumRows - 1) * 2);
  D := New(PDriveDialog, Init(R, 'Drive letter'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcDriveDialog;

    LS := 'Select ~CD~ drive:';
    LoX := Size.X div 2 - CStrLen(LS) div 2;
    HiX := LoX + CStrLen(LS) + 1;
    R.Assign(LoX, 2, HiX, 3);
    Control := New(PLabel, Init(R, LS, nil));
    Control^.Options := Control^.Options and not ofSelectable;
    Insert(Control);

    LoX := Size.X div 2 - CDNumDrives * 3;
    if LoX < 3 then LoX := 3;
    HiX := LoX + 5;
    R.Assign(LoX, 4, HiX, 6);
    for B := 0 to CDNumDrives - 1 do
    begin
      C := CDDriveLetterList[B] + $41;
      Control := New(PButton, Init(R, '~' + Char(C) + '~', C, bfNormal));
      Insert(Control);
      Inc(R.A.X, 6); Inc(R.B.X, 6);
      if R.B.X > Size.X - 3 then
      begin
        R.A.X := Size.X div 2 - CDNumDrives * 3;
        if R.A.X < 3 then R.A.X := 3;
        R.B.X := R.A.X + 5; Inc(R.A.Y, 2); Inc(R.B.Y, 2);
      end;
    end;
    SelectNext(False);
  end;
  Command := Application^.ExecuteDialog(D, nil, False);
  if Command <> cmCancel then Drive := Command - $41;
end;

procedure SelTrackDlg(LoTrack, HiTrack, NumTracks: Byte;
  var Track: Byte);
var
  NumRows, C: Byte;
  Command: Word;
  LoX, HiX: Integer;
  D: PTrackDialog;
  Control, SelControl: PView;
  R: TRect;
  S: String[2];
begin
  NumRows := (NumTracks - 1) div 10 + 1;
  LoX := 0;
  HiX := LoX + 5 + NumTracks * 6;
  if HiX > 65 then HiX := 65
  else if HiX < 32 then HiX := 32;
  R.Assign(LoX, 0, HiX, 5 + (NumRows - 1) * 2);
  D := New(PTrackDialog, Init(R, 'Select a track to play'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcCDTracks;

    SelControl := nil;
    LoX := Size.X div 2 - NumTracks * 3;
    if LoX < 2 then LoX := 2;
    HiX := LoX + 6;
    R.Assign(LoX, 2, HiX, 4);
    for C := LoTrack to HiTrack do
    begin
      Str(C, S);
      if Length(S) = 1 then S := '0' + S;
      Control := New(PButton, Init(R, S, cmTracks + C, bfNormal));
      if C = Track then SelControl := Control;
      Insert(Control);
      Inc(R.A.X, 6); Inc(R.B.X, 6);
      if R.B.X > Size.X - 3 then
      begin
	R.A.X := Size.X div 2 - NumTracks * 3;
	if R.A.X < 2 then R.A.X := 2;
        R.B.X := R.A.X + 6;
        Inc(R.A.Y, 2); Inc(R.B.Y, 2);
      end;
    end;
    if SelControl <> nil then SelControl^.Select
    else SelectNext(False);
  end;
  Command := Application^.ExecuteDialog(D, nil, False);
  if Command = cmCancel then Track := 0
  else Track := Command - cmTracks;
end;

procedure TCDIndicator.Draw;
var
  C, I: Byte;
  Params: Array[0..2] of Longint;
  S: String;
  B: TDrawBuffer;

function From(Index: Byte): Byte;
begin
  From := (Byte(S[Index]) - $30) * 9 + (I - 1) * 3 + 1;
end;

begin
  if Empty then Inherited Draw
  else
  begin
    C := GetColor(1);
    Params[0] := Track;
    Params[1] := Mins;
    Params[2] := Secs;
    FormatStr(S, '%02d%2d%02d', Params);

    for I := 1 to 3 do
    begin
      MoveChar(B, ' ', C, Size.X);

      MoveStr(B[1], Copy(cdChars, From(1), 3), C);
      MoveStr(B[5], Copy(cdChars, From(2), 3), C);

      MoveStr(B[11], Copy(cdChars, From(3), 3), C);
      MoveStr(B[15], Copy(cdChars, From(4), 3), C);

      if I > 1 then MoveChar(B[19], 'ﬂ', C, 1);

      MoveStr(B[21], Copy(cdChars, From(5), 3), C);
      MoveStr(B[25], Copy(cdChars, From(6), 3), C);

      WriteLine(0, I - 1, Size.X, 1, B);
    end;
  end;
end;

function TCDIndicator.GetPalette: PPalette;
const
  P: String[Length(CCDIndicator)] = CCDIndicator;
begin
  GetPalette := @P;
end;

procedure TCDInfoPane.Draw;
var
  Len: Integer;
  Color: Word;
  B: TDrawBuffer;
begin
  Color := GetColor(1);
  if Progress <> 0 then Len := Length(Text)
  else Len := Size.X;
  MoveChar(B, ' ', Color, Len);
  if Text <> '' then
  begin
    MoveStr(B, Text, Color);
    if Text[1] <> 'C' then
      MoveChar(B[2], #0, GetColor(2), Len - 2);
  end;
  if Progress <> 0 then
  begin
    MoveChar(B[Len], ' ', GetColor(3), 1);
    Color := GetColor(4);
    Len := Size.X - Length(Text) - 1;
    MoveChar(B[Length(Text) + 1], '≤', Color, Len);
    MoveChar(B[Length(Text) + 1], ' ', Color,
      Trunc(Len * Progress / 100));
  end;
  WriteLine(0, 0, Size.X, 1, B);
end;

function TCDInfoPane.GetPalette: PPalette;
const
  P: String[Length(CCDInfoPane)] = CCDInfoPane;
begin
  GetPalette := @P;
end;

procedure TCDInfoPane.HandleEvent(var Event: TEvent);
var
  L: Longint;
  Mouse: TPoint;
begin
  Inherited HandleEvent(Event);
  if (Event.What = evMouseDown) and MouseInView(Event.Where) then
  begin
    MakeLocal(Event.Where, Mouse);
    if (Mouse.X >= 0) and (Mouse.X < Length(Text)) then
    begin
      Pending.What := evCommand;
      Pending.Command := cmTrackHist;
      Event.What := evNothing;
    end
    else if (Mouse.X > Length(Text)) and
      (Mouse.X < Size.X) then with PCDPlayer(Owner)^ do
    begin
      L := Round((TrackMins * 60 + TrackSecs) *
	(Mouse.X - Length(Text) - 1) / (Size.X - Length(Text) - 5));
      PlayAudio(GetTrackStart(TrackNum) + SecondsToSectors(L));
      Event.What := evNothing;
    end;
  end;
end;

procedure TTrackDialog.HandleEvent(var Event: TEvent);

procedure SelectNearest(ADirection: Word);
var
  X, Y: Integer;
  V: PView;

function IsNearest(P: PView): Boolean; far;
begin
  IsNearest := (P^.Options and ofSelectable <> 0) and
    (P^.Origin.X = X) and (P^.Origin.Y = Y);
end;

begin
  X := Current^.Origin.X;
  Y := Current^.Origin.Y;
  if ADirection = kbUp then Dec(Y, 2) else Inc(Y, 2);
  V := FirstThat(@IsNearest);
  if V <> nil then V^.Select;
end;

procedure SelectMatchingButton(PrevChar, CurChar: Char);
var
  V: PView;

function IsMatching(P: PView): Boolean; far;
begin
  IsMatching := (P^.Options and ofSelectable <> 0) and
    (((PrevChar = #0) and (PButton(P)^.Title^[1] = CurChar)) or
     ((PrevChar <> #0) and (PButton(P)^.Title^[1] = PrevChar) and
      (PButton(P)^.Title^[2] = CurChar)));
end;

begin
  V := FirstThat(@IsMatching);
  if V <> nil then
  begin
    V^.Select;
    if PrevChar = #0 then Sel := CurChar;
  end;
end;

var
  C: Char;
  Key: Word;
  S: String[2];
begin
  if (Event.What = evCommand) and
     (Event.Command >= cmTracks) and
     (Event.Command <= cmTracks + 99) then
  begin
    EndModal(Event.Command);
    Event.What := evNothing;
  end
  else Inherited HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    C := Sel;
    Sel := #0;
    if Event.CharCode in ['0'..'9'] then
    begin
      SelectMatchingButton(C, Event.CharCode);
      Event.What := evNothing;
    end
    else
    begin
      Key := CtrlToArrow(Event.KeyCode);
      case Key of
	kbRight: SelectNext(False);
	kbLeft: SelectNext(True);
        kbUp, kbDown: SelectNearest(Key);
        else Exit;
      end;
      Event.What := evNothing;
    end;
  end;
end;

constructor TCDPlayer.Init;
var
  R: TRect;
begin
  R.Assign(ScreenWidth div 2 - 34, ScreenHeight div 2 - 5,
    ScreenWidth div 2 + 33, ScreenHeight div 2 + 5);
  Inherited Init(R, '');
  Drive := $FF;

  R.Assign(3, 2, 32, 5);
  Indicator := New(PCDIndicator, Init(R));
  Indicator^.Options := Indicator^.Options or ofFramed;
  Insert(Indicator);

  R.Assign(6, 1, 11, 2);
  TrackLabel := New(PStaticText, Init(R, ''));
  Insert(TrackLabel);
  TrackLabel^.Hide;

  R.Assign(18, 1, 28, 2);
  TimeLabel := New(PStaticText, Init(R, ''));
  Insert(TimeLabel);
  TimeLabel^.Hide;

  R.Assign(2, 8, Size.X - 2, 9);
  InfoPane := New(PCDInfoPane, Init(R));
  Insert(InfoPane);

  R.Assign(33, 2, 41, 4);
  Insert(New(PButton, Init(R, '˛˛', cmStopPlay, bfNormal)));

  R.Assign(41, 2, 49, 4);
  Insert(New(PButton, Init(R, 'Õ', cmPlayAudio, bfDefault)));

  R.Assign(49, 2, 57, 4);
  Insert(New(PButton, Init(R, '||', cmPausePlay, bfNormal)));

  R.Assign(57, 2, 65, 4);
  Insert(New(PButton, Init(R, '', cmEjectDisk, bfNormal)));

  R.Assign(33, 4, 41, 6);
  Insert(New(PButton, Init(R, '[', cmSkipBack, bfNormal)));

  R.Assign(41, 4, 49, 6);
  Insert(New(PButton, Init(R, '', cmRewind, bfNormal)));

  R.Assign(49, 4, 57, 6);
  Insert(New(PButton, Init(R, '', cmFastForward, bfNormal)));

  R.Assign(57, 4, 65, 6);
  Insert(New(PButton, Init(R, ']', cmSkipForward, bfNormal)));

  R.Assign(1, 6, 10, 8);
  Insert(New(PButton, Init(R, '~T~rack', cmSelTrack, bfNormal)));

  R.Assign(10, 6, 19, 8);
  Insert(New(PButton, Init(R, '~A~lbum', cmAlbumTitles, bfNormal)));

  R.Assign(19, 6, 29, 8);
  Insert(New(PButton, Init(R, '~L~yrics', cmAlbumLyrics, bfNormal)));

  R.Assign(29, 6, 36, 8);
  Insert(New(PButton, Init(R, '~M~ix', cmMixSound, bfNormal)));

  R.Assign(36, 6, 47, 8);
  Insert(New(PButton, Init(R, '~O~ptions', cmCDOptions, bfNormal)));

  R.Assign(47, 6, 57, 8);
  StandardCancelButton(R, @Self);

  R.Assign(57, 6, 65, 8);
  StandardHelpButton(R, @Self);

  SelectNext(False);
  SelectNext(False);

  WinPos := @CDPlWinPos;
end;

constructor TCDPlayer.Load(var S: TStream);
begin
  Inherited Load(S);
  GetSubViewPtr(S, Indicator);
  GetSubViewPtr(S, TrackLabel);
  GetSubViewPtr(S, TimeLabel);
  GetSubViewPtr(S, InfoPane);
  S.Read(Drive, SizeOf(Drive) +
    SizeOf(TrackLabelMode) + SizeOf(TimeLabelMode));
  InitCDDevice;
  InitTrackList;
  Empty := True;
  Indicator^.Empty := True;
  WinPos := @CDPlWinPos;
end;

destructor TCDPlayer.Done;
begin
  RemoveCDPlayer(@Self);
  DoneTrackList;
  Inherited Done;
end;

function TCDPlayer.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else if GetShiftState and kbCtrlShift <> 0 then
    GetHelpCtx := hcCtrlCDPlayer
  else GetHelpCtx := hcCDPlayer;
end;

function TCDPlayer.GetPalette: PPalette;
const
  P: String[Length(CCDPlayer)] = CCDPlayer;
begin
  GetPalette := @P;
end;

function TCDPlayer.GetTitle(MaxSize: Integer): TTitleStr;
var
  S: TTitleStr;
begin
  S := 'CD Player≥';
  if Empty then GetTitle := S + 'Drive ' + Char(Drive + $41) + ':'
  else if AlbumTitle <> '' then GetTitle := S + AlbumTitle
  else GetTitle := S + 'Untitled';
end;

procedure TCDPlayer.HandleEvent(var Event: TEvent);
var
  Processed: Boolean;
  Mouse: TPoint;

procedure PutCommand(Command: Word);
begin
  Event.What := evCommand;
  Event.Command := Command;
  Event.InfoPtr := nil;
end;

begin
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbRight: PutCommand(cmFastForward);
      kbLeft: PutCommand(cmRewind);
      kbCtrlRight: PutCommand(cmSkipForward);
      kbCtrlLeft: PutCommand(cmSkipBack);
      kbIns, kbCtrlIns: PutCommand(cmEjectDisk);
      kbHome: PutCommand(cmRestart);
      kbEnd: PutCommand(cmSkipForward);
      kbCtrlHome: PutCommand(cmFirstTrack);
      kbCtrlEnd: PutCommand(cmLastTrack);
      kbTab: { Enable Ctrl+I keystroke };
      else
      case Upcase(Event.CharCode) of
	^S, 'S': PutCommand(cmStopPlay);
	^P, 'P': PutCommand(cmPlayAudio);
	^U, 'U': PutCommand(cmPausePlay);
	^J, 'J': PutCommand(cmEjectDisk);
	^I, 'I': PutCommand(cmSkipBack);
	^R, 'R': PutCommand(cmRewind);
	^F, 'F': PutCommand(cmFastForward);
	^N, 'N': PutCommand(cmSkipForward);
	     ^T: PutCommand(cmTrackMode);
	     ^D: PutCommand(cmTimeMode);
	     ^W: PutCommand(cmTrackHist);
      end;
    end;
  if Event.What = evMouseDown then
  begin
    MakeLocal(Event.Where, Mouse);
    if Mouse.Y = TrackLabel^.Origin.Y then
      if (Mouse.X >= TrackLabel^.Origin.X) and
         (Mouse.X < TrackLabel^.Origin.X + TrackLabel^.Size.X) then
           PutCommand(cmTrackMode)
      else if (Mouse.X >= TimeLabel^.Origin.X) and
        (Mouse.X < TimeLabel^.Origin.X + TimeLabel^.Size.X) then
           PutCommand(cmTimeMode) else
    else if (Mouse.X >= 3) and (Mouse.X < 12) and
      (Mouse.Y >= Indicator^.Origin.Y) and
      (Mouse.Y < Indicator^.Origin.Y + Indicator^.Size.Y) then
        PutCommand(cmSelTrack);
  end;
  if Event.What = evCommand then
  begin
    Processed := True;
    case Event.Command of
      cmTrackMode: if not Empty then
	if TrackLabelMode = tmTotal then TrackLabelMode := tmTrack
	else TrackLabelMode := tmTotal;
      cmTimeMode: if not Empty then
	if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
	  if TimeLabelMode = tmTrackTime then TimeLabelMode := tmDiskLeft
	  else Dec(TimeLabelMode)
	else
	  if TimeLabelMode = tmDiskLeft then TimeLabelMode := tmTrackTime
	  else Inc(TimeLabelMode);
      cmEjectDisk:
	if GetShiftState and kbCtrlShift <> 0 then ForceEject(True)
	else if CDParams and cd_DoorOpen = 0 then ForceEject(False)
	else CDCloseTray(Drive);
      cmPlayAudio: StartPlay;
      cmStopPlay: StopPlay;
      cmPausePlay: if Playing then PausePlay else ResumePlay;
      cmSkipForward: SkipForward;
      cmSkipBack: SkipBack;
      cmFastForward: FastForward;
      cmRewind: Rewind;
      cmRestart: Restart;
      cmFirstTrack: FirstTrack;
      cmLastTrack: LastTrack;
      cmSelTrack: SelectTrack;
      cmTrackHist: TrackHistory;
      cmAlbumTitles: AlbumTitles;
      cmAlbumLyrics: AlbumLyrics;
      cmMixSound: SoundMixer;
      cmCDOptions: CDOptions;
      cmCancel:
	begin
	  PutCommand(cmClose);
	  Processed := False;
	end
      else Processed := False;
    end;
    if Processed then
    begin
      DoUpdate := True;
      UpdateViews;
      Event.What := evNothing;
    end;
  end;
  if (Event.What = evBroadcast) and
     (Event.Command = cmCDPlayer) and (Event.InfoByte = Drive) then
  begin
    Deiconize;
    Show;
    Select;
    ClearEvent(Event);
  end;
  Inherited HandleEvent(Event);
end;

procedure TCDPlayer.Store(var S: TStream);
begin
  Inherited Store(S);
  PutSubViewPtr(S, Indicator);
  PutSubViewPtr(S, TrackLabel);
  PutSubViewPtr(S, TimeLabel);
  PutSubViewPtr(S, InfoPane);
  S.Write(Drive, SizeOf(Drive) +
    SizeOf(TrackLabelMode) + SizeOf(TimeLabelMode));
end;

function TCDPlayer.Valid(Command: Word): Boolean;
begin
  Valid := IsValid and Inherited Valid(Command);
end;

procedure TCDPlayer.InitCDDevice;
var
  R: TRect;
begin
  IsValid := False;
  if not CDAccessible then
  begin
    R.Assign(
      ScreenWidth div 2 - 22, ScreenHeight div 2 - 5,
      ScreenWidth div 2 + 22, ScreenHeight div 2 + 4);
    MessageBoxRect(R,
      ^C'There are no CD-ROM drives accessible.'#13 +
      ^C'Microsoft CD-ROM Extensions required'#13 +
      ^C'(MSCDEX.EXE 2.10 or above).', nil, mfError + mfOkButton);
  end
  else
  begin
    CDGetDriveLetterList;
    CDGetDriveDeviceList;
    if Drive = $FF then
      if CDNumDrives > 1 then
      begin
	SelDriveDlg(Drive);
	if Drive = $FF then Exit;
      end
      else Drive := CDDriveLetterList[0];
    if Message(Desktop, evBroadcast, cmCDPlayer, Pointer(Drive)) = nil then
    begin
      if not CDDriveCheck(Drive) then MessageBox(
	^C'CD-ROM drive ' + Char(Drive + $41) + ': not accessible.',
	nil, mfError + mfOkButton)
      else
      begin
	AddCDPlayer(@Self);
	if cdSettings and cdAutoMix <> 0 then SoundMixer;
	IsValid := True;
      end;
    end;
  end;
end;

procedure TCDPlayer.InitTrackList;
begin
  TrackList := New(PStringsCollection, Init(16, 16));
end;

procedure TCDPlayer.DoneTrackList;
begin
  if TrackList <> nil then Dispose(TrackList, Done);
end;

procedure TCDPlayer.ExecCommand(const S: String);
var
  I: Integer;
begin
  if S = '' then Exit;

  FillChar(ExecRec, SizeOf(TExecRec), 0);
  I := Pos(' ', S);
  if I <> 0 then
  begin
    ExecRec.Path := Copy(S, 1, I - 1);
    ExecRec.Params := Copy(S, I + 1, 255);
  end
  else ExecRec.Path := S;

  PrepareExecEvent;
end;

function TCDPlayer.GetCDFileName: FNameStr;
begin
  GetCDFileName := AddedSlash(CNFileName(cdAlbumDir)) + AlbumName + '.CD';
end;

function TCDPlayer.GetTrackListNumber(Index: Integer): Byte;
var
  B: Byte;
  Code: Integer;
  P: PString;
begin
  P := TrackList^.At(Index);
  if P = nil then GetTrackListNumber := 0
  else
  begin
    Val(Copy(P^, 1, 2), B, Code);
    GetTrackListNumber := B;
  end;
end;

function TCDPlayer.GetTrackAlbumStr(Track: Byte): String;
var
  B: Byte;
  I, Code: Integer;
  S: String;
begin
  for I := 0 to TrackList^.Count - 1 do
  begin
    S := PString(TrackList^.At(I))^;
    Val(Copy(S, 1, 2), B, Code);
    if B = Track then
    begin
      TrimSt(S);
      GetTrackAlbumStr := S;
      Exit;
    end;
  end;
  GetTrackAlbumStr := '';
end;

function TCDPlayer.GetTrackTitle(Track: Byte): String;
var
  B: Byte;
  S: String;
begin
  S := Trim(Copy(GetTrackAlbumStr(Track), 4, 255));
  if S <> '' then
  begin
    B := LyricsPos(S);
    if B <> 0 then S := Trim(Copy(S, 1, B - 1));
    B := NoLyricsPos(S);
    if B <> 0 then S := Trim(Copy(S, 1, B - 1));
    if Length(S) > MaxTrackTitleLen then
      S[0] := Char(MaxTrackTitleLen);
  end
  else
  begin
    Str(Track, S);
    if Length(S) = 1 then S := '0' + S;
    S := 'Track ' + S;
  end;
  GetTrackTitle := S;
end;

function TCDPlayer.GetTrackStart(Track: Byte): Longint;
var
  L: Longint;
begin
  if Track <= LoTrack then GetTrackStart := DiskStart
  else if Track > HiTrack then GetTrackStart := DiskEnd
  else
  begin
    L := CDGetTrackStart(Drive, Track);
    GetTrackStart := RedBookToHSG(TRedBook(L));
  end;
end;

function TCDPlayer.GetTrackNumber(Start: Longint): Byte;
var
  B: Byte;
  L: Longint;
begin
  Inc(Start, SecondsToSectors(1));
  B := LoTrack;
  while B <= HiTrack do
  begin
    L := GetTrackStart(B);
    if L > Start then Break;
    Inc(B);
  end;
  GetTrackNumber := B - 1;
end;

procedure TCDPlayer.GetTrackTime(Track: Byte; var Minutes, Seconds: Byte);
var
  RedBook: TRedBook;
begin
  HSGToRedBook(GetTrackStart(Track + 1) - GetTrackStart(Track), RedBook);
  Minutes := RedBook.Minute;
  Seconds := RedBook.Second;
end;

function TCDPlayer.GetDiskPos: Longint;
var
  RedBook: TRedBook;
begin
  RedBook.Minute := DiskMinute;
  RedBook.Second := DiskSecond;
  RedBook.Frame := DiskFrame;
  GetDiskPos := RedBookToHSG(RedBook);
end;

procedure TCDPlayer.GetAudioDiskInfo;
var
  L: Longint;
  RedBook: TRedBook;
  R: TAudioDiskInfo;
begin
  CDGetAudioDiskInfo(Drive, R);

  LoTrack := R.LoTrack;
  if LoTrack > MaxHiTrack then LoTrack := MaxHiTrack;
  HiTrack := R.HiTrack;
  if HiTrack < LoTrack then HiTrack := LoTrack;
  if HiTrack > MaxHiTrack then HiTrack := MaxHiTrack;
  if LoTrack + HiTrack = 0 then NumTracks := 0
  else NumTracks := HiTrack - LoTrack + 1;
  LeadOutAddr := R.LeadOutAddr;

  L := CDGetTrackStart(Drive, LoTrack);
  DiskStart := RedBookToHSG(TRedBook(L));
  DiskEnd := RedBookToHSG(TRedBook(LeadOutAddr));

  HSGToRedBook(DiskEnd - DiskStart, RedBook);
  DiskMinutes := RedBook.Minute;
  DiskSeconds := RedBook.Second;
end;

procedure TCDPlayer.GetAudioQChannelInfo;
var
  Code: Integer;
  StartPos, EndPos, DiskPos: Longint;
  R: TAudioQChannelInfo;
  RedBook: TRedBook;
begin
  if not CDGetAudioQChannelInfo(Drive, R) then Exit;

  if (TrackSecond <> R.TrackSecond) or
     (DiskSecond <> R.DiskSecond) then DoUpdate := True;

  Val(HexB(R.TrackNum), TrackNum, Code);
  TrackMinute := R.TrackMinute;
  TrackSecond := R.TrackSecond;
  DiskMinute := R.DiskMinute;
  DiskSecond := R.DiskSecond;
  DiskFrame := R.DiskFrame;

  if TrackNum = 0 then
  begin
    TrackMins := 0;
    TrackSecs := 0;
    TrackMinsLeft := 0;
    TrackSecsLeft := 0;
    DiskMinsLeft := DiskMinutes;
    DiskSecsLeft := DiskSeconds;
  end
  else
  begin
    StartPos := GetTrackStart(TrackNum);
    EndPos := GetTrackStart(TrackNum + 1);
    DiskPos := GetDiskPos;
    if DiskPos < StartPos then DiskPos := StartPos;

    HSGToRedBook(EndPos - StartPos, RedBook);
    TrackMins := RedBook.Minute;
    TrackSecs := RedBook.Second;

    HSGToRedBook(EndPos - DiskPos, RedBook);
    TrackMinsLeft := RedBook.Minute;
    TrackSecsLeft := RedBook.Second;

    HSGToRedBook(DiskEnd - DiskPos, RedBook);
    DiskMinsLeft := RedBook.Minute;
    DiskSecsLeft := RedBook.Second;
  end;
end;

procedure TCDPlayer.GetAudioStatusInfo;
var
  SavePlaying, SavePaused: Boolean;
  PlayingStatus: Word;
  R: TAudioStatusInfo;
begin
  SavePlaying := Playing;
  SavePaused := Paused;

{
  Playing := CDGetDeviceStatus(Drive) and cd_Busy <> 0;
  if Stopped then Paused := False
  else if not Playing then
  begin
    CDGetAudioStatusInfo(Drive, R);
    Paused := R.Status and cd_Paused <> 0;
  end;
}

  CDGetAudioStatusInfo(Drive, R, PlayingStatus);
  Playing := PlayingStatus and cd_Busy <> 0;
  if Playing or Stopped then Paused := False
  else Paused := R.Status and cd_Paused <> 0;

  if (SavePlaying <> Playing) or
     (SavePaused <> Paused) then DoUpdate := True;
end;

procedure TCDPlayer.GetMediaChangedInfo;
var
  B, I: Byte;
  CRC: Longint;
  C: String;
  TrackStarts: Array[0..99] of Longint;
begin
  Changed := not Playing and CDGetMediaChanged(Drive);
  if not Changed and (AlbumName <> '') then Exit;

{
  C := CDGetUPCCode(Drive);
  for B := Length(C) downto 1 do
    UPCCode := UPCCode + HexB(Byte(C[B]));
  System.Delete(UPCCode, 1, 1);
}

  TrackStarts[0] := DiskStart;
  I := 1;
  for B := LoTrack + 1 to HiTrack do
  begin
    TrackStarts[I] := CDGetTrackStart(Drive, B);
    Inc(I);
  end;
  TrackStarts[I] := DiskEnd;
  CRC := -1;
  IncCRC(TrackStarts, I + 1, CRC);
  FormatStr(C, '%08x', CRC);
  AlbumName := C;

  DoUpdate := True;
end;

procedure TCDPlayer.ForceEject(Force: Boolean);
begin
  if DoorLocked then
    if Force or (GetShiftState and kbCtrlShift <> 0) then
      CDUnlockDoor(Drive)
    else if cdSettings and cdLock <> 0 then Exit;
  CDEjectDisk(Drive);
end;

procedure TCDPlayer.PlayAudio(From: Longint);
var
  B: Byte;
  W: Word;
  L, N: Longint;
  S: String;
begin
  if MsgInUse then Exit;

  if From = MaxLongint then
  begin
    From := GetDiskPos;
    if From >= DiskEnd - SecondsToSectors(1) then From := 0;
  end;
  if From >= DiskEnd then From := DiskEnd - SecondsToSectors(1);
  if From <= 0 then From := DiskStart;
  B := GetTrackNumber(From);
  if cdSequence = cdDiskOrder then L := DiskEnd
  else
  begin
    N := GetTrackStart(B + 1);
    if cdSequence = cdIntro then
    begin
      L := GetTrackStart(B) + SecondsToSectors(cdIntroTime + 1);
      if L > N then L := N;
    end
    else L := N;
  end;
  Dec(L, From);
  if L <= 0 then Exit;
  if cdSettings and cdLock <> 0 then CDLockDoor(Drive);
  PlayedTrack := B;
  Stopped := False;

  CDStopAudio(Drive);
  if CDGetDeviceParams(Drive) and
    (cd_DoorOpen + cd_DiskNotPresent) <> 0 then Exit;

  if not CDPlayAudio(Drive, From, L) then
  begin
    if cdSettings and cdLock <> 0 then CDUnlockDoor(Drive);
    MsgInUse := True;
    S := ^C'This media type is not playable.'#13^C'Eject disk now ?';
    if cdSettings and cdEject <> 0 then
    begin
      S[0] := #33;
      W := mfError + mfOkButton;
    end
    else W := mfConfirmation + mfYesNo;
    if MessageBox(S, nil, W) = cmYes then ForceEject(True);
    MsgInUse := False;
  end;
end;

procedure TCDPlayer.StartPlay;
begin
  if not Playing then
    if Paused then ResumePlay else
    case cdSequence of
      cdUserOrder:
	begin
	  PlayedTrack := LoTrack;
	  TrackListIndex := 0;
	  Stopped := False;
	end;
      cdShuffle:
	begin
	  PlayedTrack := LoTrack;
	  Stopped := False;
	end;
      else PlayAudio(MaxLongint);
    end;
end;

procedure TCDPlayer.StopPlay;
begin
  CDStopAudio(Drive);
  if GetShiftState and kbCtrlShift <> 0 then CDResetDrive(Drive)
  else CDSeek(Drive, DiskStart);
  Stopped := True;
end;

procedure TCDPlayer.PausePlay;
begin
  CDStopAudio(Drive);
end;

procedure TCDPlayer.ResumePlay;
begin
  if cdSequence = cdDiskOrder then CDResumeAudio(Drive)
  else PlayAudio(MaxLongint);
end;

procedure TCDPlayer.SkipForward;
begin
  PlayAudio(GetTrackStart(TrackNum + 1));
end;

procedure TCDPlayer.SkipBack;
begin
  PlayAudio(GetTrackStart(TrackNum - 1));
end;

procedure TCDPlayer.FastForward;
var
  L, N, P: Longint;
begin
  L := GetDiskPos + SecondsToSectors(cdFastTime);
  if cdSequence = cdIntro then
  begin
    N := GetTrackStart(TrackNum + 1);
    P := GetTrackStart(TrackNum) + SecondsToSectors(cdIntroTime);
    if P > N then P := N;
    if L >= P then L := P - SecondsToSectors(1);
  end;
  PlayAudio(L);
end;

procedure TCDPlayer.Rewind;
var
  L, P: Longint;
begin
  L := GetDiskPos - SecondsToSectors(cdFastTime);
  if cdSequence = cdIntro then
  begin
    P := GetTrackStart(TrackNum);
    if L < P then L := P;
  end;
  PlayAudio(L);
end;

procedure TCDPlayer.Restart;
begin
  PlayAudio(GetTrackStart(TrackNum));
end;

procedure TCDPlayer.FirstTrack;
begin
  PlayAudio(DiskStart);
end;

procedure TCDPlayer.LastTrack;
begin
  PlayAudio(GetTrackStart(HiTrack));
end;

procedure TCDPlayer.SelectTrack;
var
  B: Byte;
begin
  if NumTracks = 0 then Exit;
  if GetShiftState and kbCtrlShift <> 0 then TrackHistory
  else
  begin
    B := TrackNum;
    SelTrackDlg(LoTrack, HiTrack, NumTracks, B);
    if B <> 0 then PlayAudio(GetTrackStart(B));
  end;
end;

procedure TCDPlayer.TrackHistory;
const
  TrackHistoryID = 199;
var
  Sel, B: Byte;
  C: Word;
  I: Integer;
  P: PHistoryRec;
  W: PHistoryWindow;
  R: TRect;
  S: String;
begin
  if TrackList^.Count = 0 then Exit;

  for I := TrackList^.Count - 1 downto 0 do
  begin
{    GetMem(P, SizeOf(THistoryRec));}
    GetMemUMB(P, SizeOf(THistoryRec));
    S := PString(TrackList^.At(I))^;
    B := LyricsPos(S);
    if B <> 0 then S[0] := Char(B - 1);
    B := NoLyricsPos(S);
    if B <> 0 then S[0] := Char(B - 1);
{    P^.StrPtr := NewStr(S);}
    P^.StrPtr := NewStrUMB(S);
    P^.Id := TrackHistoryId;
    P^.Lock := False;
    HistoryList^.Insert(P);
  end;

  S := 'Track list window';
  GetHistWinBounds(TrackHistoryID, S, R);
  W := New(PSpecialHistWindow, Init(R, TrackHistoryID));
  DisposeStr(W^.Title);
  W^.Title := NewStr(S);
  W^.Options := W^.Options or ofCentered;
  W^.HelpCtx := hcCDTrackList;

  if Application^.ValidView(W) <> nil then
  begin
    C := Desktop^.ExecView(W);
    if C = cmOk then
      Sel := GetTrackListNumber(W^.Viewer^.Focused)
    else Sel := 0;
    Dispose(W, Done);
  end;
  ClearHistoryId(TrackHistoryId);

  if Sel <> 0 then PlayAudio(GetTrackStart(Sel));
end;

function GetMinSecStr(Minutes, Seconds: Byte): String;
var
  Params: Array[0..1] of Longint;
  S: String;
begin
  Params[0] := Minutes;
  Params[1] := Seconds;
  FormatStr(S, ': ;%02d:%02d', Params);
  GetMinSecStr := S;
end;

procedure TCDPlayer.AlbumTitles;
var
  B, Minutes, Seconds: Byte;
  Name: FNameStr;
  F: lText;
begin
  if NumTracks = 0 then Exit;

  Name := GetCDFileName;
  if not ThisFileExists(Name) then
  begin
    lAssignText(F, Name);
    Rewrite(F.T);
    if IOResult <> 0 then
    begin
      CouldNotCreateMsgBox(Name);
      Exit;
    end;

    Writeln(F.T, 'TITLE', GetMinSecStr(DiskMinutes, DiskSeconds));
    Writeln(F.T, '$LYRICS:');
    for B := LoTrack to HiTrack do
    begin
      GetTrackTime(B, Minutes, Seconds);
      Writeln(F.T, Copy(GetMinSecStr(B, 0), 4, 2),
	GetMinSecStr(Minutes, Seconds));
    end;
    System.Close(F.T);
    InOutRes := 0;
    UpdateFiles(Name);
  end;

  Message(Application, evCommand, cmOpenASCII, @Name);
end;

procedure TCDPlayer.AlbumLyrics;
var
  B: Byte;
  S: String;
begin
  if (TrackNum >= LoTrack) and (TrackNum <= HiTrack) then
  begin
    S := GetTrackAlbumStr(TrackNum);
    if NoLyricsPos(S) <> 0 then Exit;
    B := LyricsPos(S);
    if B <> 0 then
    begin
      ExecCommand(Trim(Copy(S, B + 8, 255)));
      Exit;
    end;
  end;
  S := LyricsCommand;
  if (HelpPos(S) <> 0) and (Pos(' ', S) = 0) then
    S := S + ' ' + GetTrackTitle(TrackNum);
  ExecCommand(S);
end;

procedure TCDPlayer.SoundMixer;
begin
  ExecCommand(cdMixerCommand);
end;

procedure TCDPlayer.UpdateCommands;
var
  DC, EC: TCommandSet;
begin
  if Empty then
  begin
    DC := cdCommands - [cmEjectDisk];
    EC := [cmEjectDisk];
  end
  else
  begin
    if Playing then
    begin
      DC := [cmPlayAudio];
      EC := cdCommands - [cmPlayAudio];
      if DoorLocked and (GetShiftState and kbCtrlShift = 0) then
      begin
	DC := DC + [cmEjectDisk];
	EC := EC - [cmEjectDisk];
      end;
    end
    else
    begin
      DC := [];
      EC := cdCommands;

      if not Paused then
      begin
	DC := DC + [cmPausePlay];
	EC := EC - [cmPausePlay];
      end;

      if Stopped or
	(GetDiskPos <= DiskStart + SecondsToSectors(1)) then
      begin
	DC := DC + [cmStopPlay];
	EC := EC - [cmStopPlay];
      end;

      if (cdSequence = cdUserOrder) and
	 (TrackList^.Count = 0) then
      begin
	DC := DC + [cmPlayAudio];
	EC := EC - [cmPlayAudio];
      end;
    end;

    if NumTracks = 0 then
    begin
      DC := DC + [cmSelTrack];
      EC := EC - [cmSelTrack];
    end;

    if TrackNum <= LoTrack then
    begin
      DC := DC + [cmSkipBack];
      EC := EC - [cmSkipBack];
    end;
    if TrackNum >= HiTrack then
    begin
      DC := DC + [cmSkipForward];
      EC := EC - [cmSkipForward];
    end;

    if GetDiskPos <= DiskStart + SecondsToSectors(1) then
    begin
      DC := DC + [cmRewind];
      EC := EC - [cmRewind];
    end;
    if GetDiskPos >= DiskEnd - SecondsToSectors(1) then
    begin
      DC := DC + [cmFastForward];
      EC := EC - [cmFastForward];
    end;

    if LyricsCommand = '' then
    begin
      DC := DC + [cmAlbumLyrics];
      EC := EC - [cmAlbumLyrics];
    end;
    if cdMixerCommand = '' then
    begin
      DC := DC + [cmMixSound];
      EC := EC - [cmMixSound];
    end;
  end;

  DisableCommands(DC);
  EnableCommands(EC);
end;

procedure TCDPlayer.UpdateIndicator;
begin
  Indicator^.Empty := Empty;

  if not Empty then
  begin
    if TrackLabelMode = tmTrack then Indicator^.Track := TrackNum
    else Indicator^.Track := NumTracks;

    if TimeLabelMode = tmTrackTime then
    begin
      Indicator^.Mins := TrackMinute;
      Indicator^.Secs := TrackSecond;
    end
    else if TimeLabelMode = tmTrackTotal then
    begin
      Indicator^.Mins := TrackMins;
      Indicator^.Secs := TrackSecs;
    end
    else if TimeLabelMode = tmTrackLeft then
    begin
      Indicator^.Mins := TrackMinsLeft;
      Indicator^.Secs := TrackSecsLeft;
    end
    else if TimeLabelMode = tmDiskTime then
    begin
      Indicator^.Mins := DiskMinute;
      Indicator^.Secs := DiskSecond;
    end
    else if TimeLabelMode = tmDiskTotal then
    begin
      Indicator^.Mins := DiskMinutes;
      Indicator^.Secs := DiskSeconds;
    end
    else
    begin
      Indicator^.Mins := DiskMinsLeft;
      Indicator^.Secs := DiskSecsLeft;
    end
  end;

  Indicator^.DrawView;
end;

procedure TCDPlayer.UpdateInfoPane;
var
  StartPos, EndPos, TrackPos: Longint;
  R: Real;
  S: String[15];
begin
  if Playing then
    InfoPane^.Text := Concat(' ', GetTrackTitle(TrackNum))
  else if Paused then
    InfoPane^.Text := Concat(' ', GetTrackTitle(TrackNum))
  else
  begin
    InfoPane^.Text := 'CD drive status: disk ';
    if Empty then
      if CDParams and cd_DoorOpen <> 0 then S := 'eject'
      else S := 'not insert'
    else S := 'insert';
    InfoPane^.Text := Concat(InfoPane^.Text, S, 'ed.');
{
    if not Empty then
      InfoPane^.Text := InfoPane^.Text + ' UPC/EAN code: ' + UPCCode;
}
  end;

  if Playing or Paused then
  begin
    StartPos := GetTrackStart(TrackNum);
    EndPos := GetTrackStart(TrackNum + 1);
    TrackPos := GetDiskPos - StartPos;
    R := EndPos - StartPos;
    if R <= 0 then InfoPane^.Progress := 0
    else InfoPane^.Progress := Trunc((TrackPos / R) * 100) + 1;
    if InfoPane^.Progress > 100 then InfoPane^.Progress := 100;
  end
  else InfoPane^.Progress := 0;

  InfoPane^.DrawView;

  if Playing and AutoLyrics and
    (AutoLyricsNum <> TrackNum) then
  begin
    AutoLyricsNum := TrackNum;
    AlbumLyrics;
  end;
end;

procedure TCDPlayer.UpdateLabels;
var
  R: TRect;
begin
  if Empty then TrackLabel^.Hide
  else
  begin
    DisposeStr(TrackLabel^.Text);
    if TrackLabelMode = tmTrack then
      TrackLabel^.Text := NewStr('Track')
    else TrackLabel^.Text := NewStr('Total');
    TrackLabel^.Show;
    TrackLabel^.DrawView;
  end;

  if Empty then TimeLabel^.Hide
  else
  begin
    DisposeStr(TimeLabel^.Text);
    if TimeLabelMode = tmTrackTime then
      TimeLabel^.Text := NewStr('Track time')
    else if TimeLabelMode = tmTrackTotal then
      TimeLabel^.Text := NewStr('Track total')
    else if TimeLabelMode = tmTrackLeft then
      TimeLabel^.Text := NewStr('Track left')
    else if TimeLabelMode = tmDiskTime then
      TimeLabel^.Text := NewStr('Disk time')
    else if TimeLabelMode = tmDiskTotal then
      TimeLabel^.Text := NewStr('Disk total')
    else TimeLabel^.Text := NewStr('Disk left');

    R.Assign(TimeLabel^.Origin.X, TimeLabel^.Origin.Y,
      TimeLabel^.Origin.X + Length(TimeLabel^.Text^),
      TimeLabel^.Origin.Y + 1);
    TimeLabel^.Locate(R);
    TimeLabel^.Show;
    TimeLabel^.DrawView;
  end;
end;

procedure TCDPlayer.UpdateTitle;
begin
  Frame^.DrawView;
  if Icon <> nil then PWinIcon(Icon)^.Update;
end;

procedure TCDPlayer.UpdateTrackList;
var
  SR: lSearchRec;
  Name: FNameStr;

procedure ResetTrackList;
begin
  TrackList^.FreeAll;
  TrackListTime := 0;
  TrackListSize := 0;
  TrackListIndex := 0;
  AlbumTitle := '';
  LyricsCommand := '';
  AutoLyrics := False;
  AutoLyricsNum := 0;
end;

procedure ReadTrackList;
var
  I, Code: Integer;
  F: lText;
  S: String;
begin
  lAssignText(F, Name);
  FailSysErrors := True;
  Reset(F.T);
  FailSysErrors := False;
  if IOResult <> 0 then Exit;

  LogEvent := lcDiskRead;
  DrawStatusLine('Reading CD album file ' +
    TrimmedName(Name, 45) + '.');

  while not Eof(F.T) do
  begin
    Readln(F.T, S);
    S := Detab(S, 8);
    TrimSt(S);
    I := Pos(';', S);
    if I <> 0 then S[0] := Char(I - 1);
    Val(Copy(S, 1, 2), I, Code);
{    if B <> 0 then TrackList^.Insert(NewStr(S))}
    if I <> 0 then TrackList^.Insert(NewStrUMB(S))
    else if TitlePos(S) = 1 then
      AlbumTitle := Trim(Copy(S, 7, 255))
    else if LyricsPos(S) = 1 then
    begin
      LyricsCommand := Trim(Copy(S, 9, 255));
      I := AutoPos(LyricsCommand);
      if I <> 0 then
      begin
	LyricsCommand := Trim(Copy(LyricsCommand, 1, I - 1));
	AutoLyrics := True;
      end;
    end;
  end;

  System.Close(F.T);
  InOutRes := 0;
end;

begin
  if Empty or (NumTracks = 0) then
  begin
    ResetTrackList;
    Exit;
  end;

  Name := GetCDFileName;
  FailSysErrors := True;
  lFindFirst(Name, AnyFile and not (Directory + VolumeID), SR);
  lFindClose(SR);
  FailSysErrors := False;
  if ((DosError = 0) and
      (TrackListTime = SR.SR.Time) and
      (TrackListSize = SR.SR.Size)) or
     ((DosError <> 0) and
      (TrackListTime = 0) and
      (TrackListSize = 0)) then Exit;

  ResetTrackList;
  if DosError = 0 then
  begin
    TrackListTime := SR.SR.Time;
    TrackListSize := SR.SR.Size;
    ReadTrackList;
  end;
  DoUpdate := True;
end;

procedure TCDPlayer.UpdateViews;
begin
  UpdateTrackList;
  if not DoUpdate then Exit;
  UpdateTitle;
  UpdateLabels;
  UpdateInfoPane;
  UpdateIndicator;
  UpdateCommands;
end;

procedure TCDPlayer.Update;
var
  Hour, Minute, Second, Sec100, Params: Word;

procedure Stop;
begin
  if cdSettings and cdEject <> 0 then
    if not MsgInUse then ForceEject(True) else
  else if DoorLocked then CDUnlockDoor(Drive);
end;

procedure PlayDisk;
begin
  if cdSettings and cdRepeat <> 0 then PlayAudio(DiskStart)
  else Stopped := True;
end;

procedure PlayUser;
begin
  if TrackList^.Count <> 0 then
    if TrackListIndex < TrackList^.Count then
    begin
      PlayAudio(GetTrackStart(GetTrackListNumber(TrackListIndex)));
      Inc(TrackListIndex);
    end
    else if cdSettings and cdRepeat <> 0 then TrackListIndex := 0
    else Stopped := True;
end;

procedure PlaySingle;
begin
  if cdSettings and cdRepeat <> 0 then
    PlayAudio(GetTrackStart(PlayedTrack))
  else Stopped := True;
end;

procedure PlayIntro;
begin
  if TrackNum >= HiTrack then
    if cdSettings and cdRepeat <> 0 then PlayAudio(DiskStart)
    else Stopped := True
  else PlayAudio(GetTrackStart(PlayedTrack + 1));
end;

procedure PlayShuffle;
begin
  Randomize;
  PlayAudio(GetTrackStart(Random(HiTrack + 1)));
end;

procedure CheckDoorLock;
begin
  if DoorLocked <> (cdSettings and cdLock <> 0) then
  begin
    DoorLocked := not DoorLocked;
    if DoorLocked then CDLockDoor(Drive)
    else CDUnlockDoor(Drive);
  end;
end;

begin
  GetTime(Hour, Minute, Second, Sec100);
  if LastSecond = Second then Exit;
  LastSecond := Second;

  Params := CDGetDeviceParams(Drive);
  Empty := Params and (cd_DoorOpen + cd_DiskNotPresent) <> 0;

  if Empty then
  begin
    if CDParams <> Params then
    begin
      CDParams := Params;
      PlayedTrack := 0;
      Playing := False;
      Paused := False;
      Stopped := False;
      DoUpdate := True;
      UpdateViews;
    end;
    Exit;
  end;

  DoUpdate := CDParams <> Params;
  CDParams := Params;

  GetAudioDiskInfo;
  GetAudioQChannelInfo;
  GetAudioStatusInfo;
  GetMediaChangedInfo;

  if Playing then
  begin
    CheckDoorLock;
    if PlayedTrack = 0 then PlayedTrack := TrackNum;
  end;

  UpdateViews;
  if Playing or Paused then Exit;

  if (cdSettings and cdAutoPlay <> 0) and Changed then
    case cdSequence of
      cdUserOrder:
	begin
	  TrackListIndex := 0;
	  PlayUser;
	end;
      cdShuffle: PlayShuffle;
      else PlayAudio(DiskStart)
    end
  else if Stopped then Stop
  else if PlayedTrack <> 0 then
    case cdSequence of
      cdDiskOrder: PlayDisk;
      cdUserOrder: PlayUser;
      cdSingle: PlaySingle;
      cdIntro: PlayIntro;
      cdShuffle: PlayShuffle;
    end;
end;

procedure RSRCDPlayer(RSR: PResourceFile);
var
  P: PCDPlayer;
begin
  P := New(PCDPlayer, Init);
  RSR^.Put(P, 'CDPLAYER');
  Dispose(P, Done);
end;

procedure LoadCDPlayer;
var
  R: TRect;
  P: PCDPlayer;
begin
  P := PCDPlayer(Resource^.Get('CDPLAYER'));
  if P <> nil then
  begin
    if (WinPosMask and wpCDPl <> 0) and ValidWinPos(CDPlWinPos) then
    begin
      SetWinPos(Desktop, CDPlWinPos, R);
      P^.MoveTo(R.A.X, R.A.Y);
    end;
    Application^.InsertWindow(P);
  end
  else ResourceNotFoundMsgBox('CD Player');
end;

end.
