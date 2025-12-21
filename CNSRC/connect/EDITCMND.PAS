{$F+,O+,X+}
unit EditCmnd;

interface

uses Drivers, FEditor;

procedure GetCtrlKCommand(Ch: Char; var C: Word);
procedure GetCtrlQCommand(Ch: Char; var C: Word);
procedure ToggleEditOptionsPrim(Editor: PFileEditor; var Event: TEvent);
procedure HideNonPersistentBlock(Editor: PFileEditor; var Event: TEvent);
procedure HandleEditKey(Editor: PFileEditor; var Event: TEvent);
procedure HandleEditMouse(Editor: PFileEditor; var Event: TEvent);
procedure HandleEditCommand(Editor: PFileEditor; var Event: TEvent);
procedure HandleEditBroadcast(Editor: PFileEditor; var Event: TEvent);
procedure HandleIndicatorMouse(Editor: PFileEditor; var Event: TEvent);
function IndicatorGetMouseShape(Editor: PFileEditor;
  var Event: TEvent): Char;
function PreprocessEnabledPrim(Editor: PFileEditor;
  var Event: TEvent): Boolean;

implementation

uses CNCrt, Objects, Views, Dialogs, WinIcons, App, FindDlg, Compiler,
  Swaps, Spooler, EditChk, EditClip, EditConv, EditDrag, EditFile,
  EditFind, EditJust, EditMisc, EditPop, EditPrim, EditUpdt, EditWrap,
  PlcHist, Macros, CNMacros, Options, DirPrim, Keyboard, LFN, TPString,
  Consts, Commands, Defaults;

procedure GetCtrlKCommand(Ch: Char; var C: Word);
begin
  case Ch of
    'A', 'a', '‰', 'î', ^A: C := cmCtrlKA;
    'B', 'b', '®', 'à', ^B: C := cmCtrlKB;
    'K', 'k', '´', 'ã', ^K: C := cmCtrlKK;
    'H', 'h', '‡', 'ê', ^H: C := cmCtrlKH;
    'Y', 'y', '≠', 'ç', ^Y: C := cmCtrlKY;
    'D', 'd', '¢', 'Ç', ^D: C := cmCtrlKD;
    'C', 'c', '·', 'ë', ^C: C := cmCtrlKC;
    'V', 'v', '¨', 'å', ^V: C := cmCtrlKV;
    'M', 'm', 'Ï', 'ú', ^M: C := cmCtrlKM;
    'I', 'i', 'Ë', 'ò', ^I: C := cmCtrlKI;
    'U', 'u', '£', 'É', ^U: C := cmCtrlKU;
    'P', 'p', 'ß', 'á', ^P: C := cmCtrlKP;
    'R', 'r', '™', 'ä', ^R: C := cmCtrlKR;
    'W', 'w', 'Ê', 'ñ', ^W: C := cmCtrlKW;
    'L', 'l', '§', 'Ñ', ^L: C := cmCtrlKL;
    'T', 't', '•', 'Ö', ^T: C := cmCtrlKT;
    'S', 's', 'Î', 'õ', ^S: C := cmSave;
    'F', 'f', '†', 'Ä', ^F: C := cmFillHex;
  end;
end;

procedure GetCtrlQCommand(Ch: Char; var C: Word);
begin
  case Ch of
    'F', 'f', '†', 'Ä', ^F: C := cmFind;
    'A', 'a', '‰', 'î', ^A: C := cmReplace;
    'Y', 'y', '≠', 'ç', ^Y: C := cmCtrlQY;
    'Z', 'z', 'Ô', 'ü', ^Z: C := cmCtrlQZ;
    'U', 'u', '£', 'É', ^U: C := cmCtrlQU;
    'L', 'l', '§', 'Ñ', ^L: C := cmCtrlQL;
    'D', 'd', '¢', 'Ç', ^D: C := cmCtrlQD;
    'S', 's', 'Î', 'õ', ^S: C := cmCtrlQS;
    'B', 'b', '®', 'à', ^B: C := cmCtrlQB;
    'C', 'c', '·', 'ë', ^C: C := cmCtrlQC;
    'E', 'e', '„', 'ì', ^E: C := cmCtrlQE;
    'R', 'r', '™', 'ä', ^R: C := cmCtrlQR;
    'O', 'o', 'È', 'ô', ^O: C := cmCtrlQO;
    'M', 'm', 'Ï', 'ú', ^M: C := cmCtrlQM;
    'X', 'x', 'Á', 'ó', ^X: C := cmCtrlQX;
    'T', 't', '•', 'Ö', ^T: C := cmCtrlQT;
    'N', 'n', '‚', 'í', ^N: C := cmCtrlQN;
    'K', 'k', '´', 'ã', ^K: C := cmCtrlQK;
    'G', 'g', 'Ø', 'è', ^G: C := cmCtrlQG;
    'V', 'v', '¨', 'å', ^V: C := cmCtrlQV;
    'Q', 'q', '©', 'â', ^Q: C := cmCtrlQQ;
    'W', 'w', 'Ê', 'ñ', ^W: C := cmCtrlQW;
    'P', 'p', 'ß', 'á', ^P: C := cmCtrlQPath;
    'J', 'j', 'Æ', 'é', ^J: C := cmCtrlQJ;
    'I', 'i', 'Ë', 'ò', ^I: C := cmCtrlQI;
    'H', 'h': C := cmCtrlQH;
    'ê', '‡': C := cmCtrlQp;
    '\', ^\: C := cmDateStamp;
    '|': C := cmTimeStamp;
    ' ': C := cmCtrlQSpace;
    '~': C := cmCtrlQShort;
    '`': C := cmCtrlQLong;
    ',', '<', '°', 'Å': C := cmCtrlQPeriod;
  end;
end;

procedure ToggleEditOptionsPrim(Editor: PFileEditor; var Event: TEvent);
var
  L, T, B, I: Byte;
  W: Word;
  C: Longint;

procedure UpdateEditor;
begin
  with Editor^ do
  begin
    if Options and ofHex = 0 then
    begin
      if (C and eoWrapLinesOnLoad <> 0) and not IsClip then
      begin
        IsReloading := True;
        UpdateLinesPrim(Editor, '');
        IsReloading := False;
      end;
      if C and eoHilitPageBreak <> 0 then
	if LocalEditOptions and eoHilitPageBreak = 0 then
	  LinesPerPage := 0
	else GetPrnValues(PrnRec, L, T, B, LinesPerPage, I, W);
    end;
    DrawView;
  end;
end;

begin
  case Event.CharCode of
    'C', 'c', '·', 'ë', ^C: C := eoBackupFiles;
    'I', 'i', 'Ë', 'ò', ^I:
      if Event.KeyCode = kbTab then C := eoSmartTabs
      else C := eoInsertMode;
    'A', 'a', '‰', 'î', ^A: C := eoAutoIndentMode;
    'U', 'u', '£', 'É', ^U: C := eoUseTabs;
    'E', 'e', '„', 'ì', ^E: C := eoEscCloses;
    'X', 'x', 'Á', 'ó', ^X: C := eoUseEMS;
    'S', 's', 'Î', 'õ', ^S: C := eoSyntax;
    'ê', '‡', 'ß', 'á', ^P: C := eoPromptOnNew;
    'H', 'h', '‡', 'ê', ^H: C := eoChangeDirOnOpen;
    'N', 'n', '‚', 'í', ^N: C := eoCascade;
    'F', 'f', '†', 'Ä', ^F: C := eoFindTextAtCursor;
    'D', 'd', '¢', 'Ç', ^D: C := eoEnableUndo;
    'R', 'r', '™', 'ä', ^R: C := eoEnableWrap;
    'L', 'l', '§', 'Ñ', ^L: C := eoExpandLine;
    'B', 'b', '®', 'à', ^B: C := eoWordDivision;
    'Y', 'y', '≠', 'ç', ^Y: C := eoLiteralInput;
    '(':                    C := eoInsertPairs;
    'G', 'g', 'Ø', 'è', ^G: C := eoHilitCurLine;
    'O', 'o', 'È', 'ô', ^O: C := eoHilitCurColumn;
    'T', 't', '•', 'Ö', ^T: C := eoHilitPageBreak;
    '<', '>':               C := eoHilitBounds;
    ',', '.', ';', ':',
    '!', '?':               C := eoAutoSpaces;
    '-', '_':               C := eoNonPersistent;
    'V', 'v', '¨', 'å', ^V: C := eoOverwriteBlocks;
    '}', ']', 'Í', 'ö':     C := eoWrapLinesOnLoad;
    '{', '[', 'Â', 'ï':     C := eoUnwrapLinesOnSave;
    #32:                    C := eoTrailingBlanks;
    'Q', 'q', '©', 'â', ^Q: with Editor^ do
      begin
	C := LocalEditOptions;
	if EditorOptions('',
	  LocalEditOptions, NewLocalOptions, LocalTabSize,
	  LocalMaxLineWidth, @LocalWordDelims, True, True) then
	begin
	  C := C xor LocalEditOptions;
          UpdateEditor;
	end;
        Exit;
      end;
    else Exit;
  end;
  with Editor^ do
  begin
    if (C < 0) or (C >= eoWriteCRLF) then
    begin
      C := C shr 24;
      NewLocalOptions := NewLocalOptions xor C;
    end
    else LocalEditOptions := LocalEditOptions xor C;
    UpdateEditor;
  end;
end;

function IsOverwriteKey(Key: Word): Boolean;
begin
  IsOverwriteKey := (Key = kbDel) or
    (Char(Key) in [#7..#9, #32..#255]);
end;

procedure HideNonPersistentBlock(Editor: PFileEditor; var Event: TEvent);
begin
  with Editor^ do
  begin
    if (Event.What = evKeyDown) and
       (IsCtrlKPressed or IsCtrlQPressed or
        IsCtrlPPressed or IsCtrlOPressed or
        (Event.CharCode in [^K, ^O, ^P, ^Q]) or
        ((Options and ofHex = 0) and
         (LocalEditOptions and eoOverwriteBlocks <> 0) and
          IsOverwriteKey(Event.KeyCode))) then Exit;
    if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
       (((Event.What = evKeyDown) and (Event.CharCode = #0)) or
         (Event.What = evMouseDown)) then Exit;
    IsSelected := False;
    DrawView;
  end;
end;

procedure SelectAllPrim(Editor: PFileEditor);
begin
  with Editor^ do
  begin
    if FileLines^.Count = 0 then Exit;
    if MarkColumns then Message(
      Application, evCommand, cmToggleMarkMode, nil);
    Highlight(0, 1, FileLines^.Count, 1);
    DrawView;
  end;
end;

procedure HandleEditKey(Editor: PFileEditor; var Event: TEvent);
var
  B, E: Byte;
  C: Word;
begin
  if (Event.KeyCode = kbCtrlHome) or (Event.KeyCode = kbCtrlEnd) or
     (Event.KeyCode = kbCtrlPgUp) or (Event.KeyCode = kbCtrlPgDn) or
     (Event.CharCode in WordStarChars) then
    if PreprocessEnabledPrim(Editor, Event) then
    begin
      ConvertWSKey(WordStarKeys, Event);
      if Event.What = evCommand then
      begin
	HandleEditCommand(Editor, Event);
	Exit;
      end;
    end;
  with Editor^ do
  begin
    if IncSearch then
    begin
      if Event.CharCode <> #0 then
      begin
        IncSearchPrim(Editor, Event.CharCode);
        Event.What := evNothing;
        Exit;
      end;
      if (Event.KeyCode = kbShiftIns) or
         (Event.KeyCode = kbShiftF12) then Exit;
      DoneIncSearchPrim(Editor);
    end
    else if DoRedraw then
    begin
      DrawView;
      DoRedraw := False;
    end;
    if (Cursor.X < 0) or (Cursor.X >= Size.X) or
       (Cursor.Y < 0) or (Cursor.Y >= Size.Y) then
         GoToPos(Delta.X + Cursor.X, Delta.Y + Cursor.Y);
    if IsSelected and (LocalEditOptions and eoNonPersistent <> 0) then
      HideNonPersistentBlock(Editor, Event);
    if Event.CharCode <> #0 then
    begin
      if IsCtrlKPressed then
      begin
	IsCtrlKPressed := False;
	C := 0;
        case Event.CharCode of
          'Q', 'q', '©', 'â', ^Q:
            begin
              Pending.What := evCommand;
              Pending.Command := cmMenu;
            end;
          '0'..'9':
            begin
              Places[Event.CharCode].X := GetLinePos;
              Places[Event.CharCode].Y := Delta.Y + Cursor.Y;
            end;
          else GetCtrlKCommand(Event.CharCode, C);
        end;
        Event.What := evCommand;
        Event.Command := C;
        if C <> 0 then HandleEvent(Event);
      end
      else if IsCtrlQPressed then
      begin
        IsCtrlQPressed := False;
        C := 0;
        case Event.CharCode of
          '0'..'9':
            if (Places[Event.CharCode].X <> -1) and
               (Places[Event.CharCode].Y <> -1) then
              GoToPos(Places[Event.CharCode].X, Places[Event.CharCode].Y);
          ';':
            begin
              State := State xor sfSemicolon;
	      GetLocalFields;
              DrawView;
            end;
          '[', ']', ^[, ^], 'Â', 'ï', 'Í', 'ö': FindMatchingCharPrim(Editor);
          '', '=', '+': DubbLinePrim(Editor, Delta.Y + Cursor.Y);
          else GetCtrlQCommand(Event.CharCode, C);
        end;
        Event.What := evCommand;
        Event.Command := C;
        if C <> 0 then HandleEvent(Event);
      end
      else if IsCtrlPPressed or (State and sfActive = 0) or
        (LocalEditOptions and eoLiteralInput <> 0) then
      begin
        IsCtrlPPressed := False;
        if IsInsert then InsertCharPrim(Editor,
          Event.CharCode, Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X))
        else ReplaceCharPrim(Editor,
          Event.CharCode, Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
      end
      else if IsCtrlOPressed then
      begin
        IsCtrlOPressed := False;
	ToggleEditOptionsPrim(Editor, Event);
      end
      else if Event.CharCode = #27 then
        if State and sfDrawing <> 0 then State := State and not sfDrawing
        else if LocalEditOptions and eoEscCloses <> 0 then
        begin
          Pending.What := evCommand;
          Pending.Command := cmClose;
          Pending.InfoPtr := Owner;
        end else
      else if (Event.CharCode = #32) and
        (GetShiftState and kbCtrlShift <> 0) and not MacroRunning then
          SearchData.MatchStr := GetWord(B, E)
      else if Event.CharCode = ^\ then
        if IsClip or (State and sfNoname <> 0) then
          Message(Desktop, evBroadcast, cmFileManager, nil)
        else Message(Desktop, evBroadcast, cmReopen, FileName)
      else if Event.KeyCode = kbCtrlEnter then Redo
      else
      begin
        CharPressedPrim(Editor, Event.CharCode);
        if ((KbdStatus = 21) and
           (GetShiftState and kbCtrlShift <> 0)) or
           (KbdStatus in [28, 38]) then
        begin
          repeat until KeyPressed or not (KbdStatus in [21, 28, 38]);
          while ((KbdStatus = 21) and
            (GetShiftState and kbCtrlShift <> 0)) or
            (KbdStatus in [28, 38]) do
          begin
            CharPressedPrim(Editor, Event.CharCode);
            Indicator^.DrawView;
            if KbdDelay <> 0 then Delay(KbdDelay);
            ClearKbd;
          end;
        end;
      end;
    end
    else
    begin
      if Event.KeyCode = kbAltY then
        PlaceMarkerDlg(Editor, not IsCtrlQPressed)
      else if Event.KeyCode = kbShiftTab then InsertTabPrim(
        Editor, Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1, True)
      else if Event.KeyCode = kbShiftF2 then CalcWordsAndCharsPrim(Editor)
      else if Event.KeyCode = kbShiftF4 then CheckSpellingPrim(Editor)
      else if Event.KeyCode = kbShiftF8 then DeleteFromDictionaryPrim(Editor)
      else if Event.KeyCode = kbCtrl2 then InitIncSearchPrim(Editor)
      else if Event.KeyCode = kbCtrlIns then
	Message(Application, evCommand, cmCopy, nil)
      else if Event.KeyCode = kbCtrlF12 then
	Message(Application, evCommand, cmCopyToMT, nil)
      else if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
      begin
	if State and sfDrawing <> 0 then
        begin
          case Event.KeyCode of
            kbLeft, kbRight, kbUp, kbDown:
	      DrawLinePrim(Editor, Event.KeyCode);
          end;
          Scroll(Event);
          if Event.What <> evNothing then Exit;
        end
        else
        begin
          if IsSelected and
            (((Delta.Y + Cursor.Y = Area^.KB) and
            (Delta.X + Cursor.X + 1 = Area^.PB)) or
            ((Delta.Y + Cursor.Y = Area^.KK) and
            (Delta.X + Cursor.X + 1 = Area^.PK))) then {}
          else if not (Event.ScanCode in
            [Hi(kbShiftF1)..Hi(kbShiftF10),
             Hi(kbShiftF11)..Hi(kbShiftF12)]) then
          begin
            IsSelected := False;
	    Highlight(Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X),
              Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
          end;
	  DrawFlag := True;
          Scroll(Event);
          DrawFlag := False;
          if Event.What <> evNothing then Exit;
          SelectOn(Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
          if IsSelected and
             (Area^.KB = Area^.KK) and (Area^.PB = Area^.PK) then Unselect;
          DrawView;
        end;
      end
      else
      begin
        Scroll(Event);
        if Event.What <> evNothing then Exit;
      end;
    end;
    Indicator^.DrawView;
    Event.What := evNothing;
  end;
end;

procedure HandleEditMouse(Editor: PFileEditor; var Event: TEvent);
var
  WasSelected, Dropped: Boolean;
  C: Word;
  Spot: TPoint;
begin
  with Editor^ do
  begin
    if IncSearch then DoneIncSearchPrim(Editor)
    else if DoRedraw then
    begin
      DrawView;
      DoRedraw := False;
    end;
    if Event.Buttons = mbRightButton then
    begin
      repeat until not MouseEvent(Event, evMouseDown);
      PopUpPrim(Event.Where, not UnixMode);
      Event.What := evNothing;
    end
    else
    begin
      if IsSelected and (LocalEditOptions and eoNonPersistent <> 0) then
        HideNonPersistentBlock(Editor, Event);
      WasSelected := IsSelected;
      Dropped := False;
      repeat
        DrawFlag := True;
        MakeLocal(Event.Where, Spot);
        if (State and sfDrawing <> 0) and
           (Event.What and (evMouseMove + evMouseAuto) <> 0) then
        begin
          C := 0;
          if Spot.X > Cursor.X then C := kbRight
          else if Spot.X < Cursor.X then C := kbLeft;
          if Spot.Y > Cursor.Y then C := kbDown
          else if Spot.Y < Cursor.Y then C := kbUp;
          if C <> 0 then DrawLinePrim(Editor, C);
        end;
	if MouseInView(Event.Where) then
        begin
          if not IsSelected and
             (((Event.What and evMouseMove <> 0) and
               (State and sfDrawing = 0)) or
             (GetShiftState and (kbLeftShift + kbRightShift) <> 0)) then
	    Highlight(Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X),
              Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
	  while Delta.Y + Spot.Y > FileLines^.Count do Dec(Spot.Y);
          SetCursor(Spot.X, Spot.Y);
        end
        else
        begin
          Spot.X := 0;
          Spot.Y := 0;
          MakeGlobal(Spot, Spot);
          if Event.Where.X < Spot.X then GoLeft;
          if Event.Where.X > Spot.X + Size.X - 1 then GoRight;
          if Event.Where.Y < Spot.Y then GoUp;
          if Event.Where.Y > Spot.Y + Size.Y - 1 then GoDown;
	end;
        if IsSelected and
           ((not WasSelected and (State and sfDrawing = 0)) or
            (GetShiftState and (kbLeftShift + kbRightShift) <> 0)) then
          SelectOn(Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
        if (MouseButtons = mbLeftButton + mbRightButton) and
           Selected(Delta.Y + Cursor.Y) then
        begin
          DragDropPrim(Editor, Event.Where);
          Dropped := True;
        end
        else if Event.Double then
        begin
          if IsSelected then Unselect
          else if State and sfDrawing <> 0 then
            State := State and not sfDrawing
	  else HighLight(Delta.Y + Cursor.Y, 1, Delta.Y + Cursor.Y + 1, 1);
          Dropped := True;
        end;
        DrawFlag := False;
	DrawView;
        Indicator^.DrawView;
      until Dropped or (not MouseEvent(Event, evMouseMove + evMouseAuto));
      if IsSelected and
         (Area^.KB = Area^.KK) and (Area^.PB = Area^.PK) then Unselect;
    end;
  end;
end;

procedure HandleEditCommand(Editor: PFileEditor; var Event: TEvent);
var
  B, E: Byte;
  Spot: TPoint;
  S: String;
begin
  with Editor^ do
  begin
    if IncSearch and
      (Event.Command <> cmPaste) and
      (Event.Command <> cmPasteFromMT) then DoneIncSearchPrim(Editor);
    case Event.Command of
      cmSave: SavePrim(Editor, '', False);
      cmSaveAs: SaveAsPrim(Editor);
      cmPrint: TheSpooler^.NewEditor(Editor, -1, 0);
      cmUndo: Undo;
      cmRedo: Redo;
      cmCut: Cut;
      cmCopy: Copy;
      cmPaste: Paste;
      cmClear: Clear({False} True, True);
      cmFind: FindPrim(Editor, False);
      cmReplace: ReplacePrim(Editor, True);
      cmFindAll: FindPrim(Editor, True);
      cmShowAllFound: FindAllDlgPrim(Editor);
      cmSearchAgain: SearchPrim(Editor, SearchData.MatchStr,
        SearchData.Options or frFromCursor);
      cmIncSearch: InitIncSearchPrim(Editor);
      cmGoToLine: GoToLineNumberPrim(Editor);
      cmCompile: if SyntaxWord = swCBS then
	begin
	  if not Debugging then InitSource(Editor);
          Exit;
        end
        else ExtCompile;
      cmToggleBreakPoint: ToggleBreakPointPrim(Editor);
      cmClearBreakPoints: ClearBreakPoints;
      cmUpdateASCII: UpdateLines('');
      cmCancel: if State and sfDrawing <> 0 then
        begin
          State := State and not sfDrawing;
          Indicator^.DrawView;
        end;
      cmSetTextMode:
        begin
          UnixMode := not UnixMode;
          PWindow(Owner)^.Frame^.DrawView;
        end;
      cmSaveBlock:
	begin
	  SavedBlock := Area^;
	  SavedColumns := MarkColumns;
	  SavedIsSel := IsSelected;
	end;
      cmRestoreBlock:
	begin
	  if SavedColumns <> MarkColumns then
	    Message(Application, evCommand, cmToggleMarkMode, nil);
	  Highlight(SavedBlock.KB, SavedBlock.PB,
	    SavedBlock.KK, SavedBlock.PK);
	  IsSelected := SavedIsSel;
	  DrawView;
	end;
      cmSaveCursor:
	begin
	  SavedCursor.X := Delta.X + Cursor.X;
	  SavedCursor.Y := Delta.Y + Cursor.Y;
	  SavedInsert := IsInsert;
	end;
      cmRestoreCursor:
	begin
	  if SavedInsert <> IsInsert then ToggleInsert;
	  GoToPos(SavedCursor.X, SavedCursor.Y);
	end;
      cmHideBlock:
	begin
	  IsSelected := False;
	  DisableCommands(BlockCommands + MTCopyCommands);
	  if IsClip then
	  begin
	    ClipAreaSelected := False;
	    DisableCommands(PasteCommands);
	  end;
	  DrawView;
	end;
      cmDisplayBlock: if not IsSelected then
	begin
	  Highlight(Area^.KB, Area^.PB, Area^.KK, Area^.PK);
	  DrawView;
	end;
      cmSelectAll: SelectAllPrim(Editor);
      cmPopUp:
	begin
	  Spot.X := Size.X div 2;
          Spot.Y := 0;
	  MakeGlobal(Spot, Spot);
          PopUpPrim(Spot, not UnixMode);
        end;
      else
      begin
        case Event.Command of
          cmCtrlKB: Highlight(Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1,
            Area^.KK, Area^.PK);
          cmCtrlKK: Highlight(Area^.KB, Area^.PB,
            Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
	  cmCtrlKH:
	    if not IsSelected then Highlight(
	      Area^.KB, Area^.PB, Area^.KK, Area^.PK)
	    else
	    begin
	      IsSelected := False;
	      DisableCommands(BlockCommands + MTCopyCommands);
	      if IsClip then
	      begin
		ClipAreaSelected := False;
		DisableCommands(PasteCommands);
	      end;
	    end;
	  cmCtrlKY: if IsSelected then Clear(True, False)
	    else
	    begin
              Event.Command := cmCtrlKH;
              HandleEvent(Event);
            end;
          cmCtrlKD: if IsSelected then Clear(False, False)
            else
            begin
              Event.Command := cmCtrlKH;
              HandleEvent(Event);
            end;
          cmCtrlKC: if IsSelected then
            InsertBlock(Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1)
            else
            begin
              Event.Command := cmCtrlKH;
              HandleEvent(Event);
            end;
          cmCtrlKV: if IsSelected then
            MoveBlock(Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1)
            else
            begin
              Event.Command := cmCtrlKH;
              HandleEvent(Event);
            end;
          cmCtrlKM: if IsSelected then
            TransferBlock(Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1, False)
            else
            begin
              Event.Command := cmCtrlKH;
              HandleEvent(Event);
            end;
          cmCtrlKI: IndentBlockPrim(Editor);
          cmCtrlKU: UnindentBlockPrim(Editor);
          cmCtrlKP: if IsSelected then
            TheSpooler^.NewEditor(Editor, Area^.KB, Area^.KK);
          cmCtrlKR: ReadBlockFromFile('', True);
          cmCtrlKW,
          cmCtrlKA: WriteBlockToFile('', True, Event.Command = cmCtrlKA);
          cmCtrlKL:
            begin
              Unselect;
              HighLight(Delta.Y + Cursor.Y, 1, Delta.Y + Cursor.Y, 255);
            end;
          cmCtrlKT:
            begin
              S := GetWord(B, E);
              if E > B then
              begin
                Unselect;
                HighLight(Delta.Y + Cursor.Y, B, Delta.Y + Cursor.Y, E);
              end;
            end;
          cmCtrlQY: DeleteToEndPrim(
            Editor, Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1);
          cmCtrlQZ: DeleteToEndOfFilePrim(Editor);
          cmCtrlQU: ConvertBlockPrim(Editor, cvUpcase);
          cmCtrlQL: ConvertBlockPrim(Editor, cvLocase);
          cmCtrlQD: State := (State or sfDrawDouble) and not sfDrawSingle;
          cmCtrlQS: State := (State or sfDrawSingle) and not sfDrawDouble;
	  cmCtrlQG: JustifyLinePrim(Editor, 'B');
	  cmCtrlQC: JustifyLinePrim(Editor, 'C');
	  cmCtrlQE: JustifyLinePrim(Editor, 'E');
	  cmCtrlQH: ConvertBlockPrim(Editor, cvRus);
          cmCtrlQp: ConvertBlockPrim(Editor, cvLatin);
          cmCtrlQQ: ConvertBlockPrim(Editor, cvFTable);
          cmCtrlQW: ConvertBlockPrim(Editor, cvTable);
	  cmCtrlQI: ConvertBlockPrim(Editor, cvCaps);
	  cmCtrlQV: ConvertToVolapyukPrim(Editor, False);
          cmCtrlQR: ReformatBlockPrim(Editor, False);
          cmCtrlQJ: ReformatBlockPrim(Editor, True);
          cmCtrlQO: UnformatBlockPrim(Editor);
          cmCtrlQX: SortBlockPrim(Editor);
          cmCtrlQM: MathOperationPrim(Editor);
          cmCtrlQT: TimeStampPrim(Editor, tsBoth);
          cmCtrlQN: OpenFileAtCursorPrim(Editor);
          cmCtrlQPath: MkDirAtCursorPrim(Editor);
          cmCtrlQB: if IsSelected then GoToPos(Area^.PB - 1, Area^.KB);
          cmCtrlQK: if IsSelected then GoToPos(Area^.PK - 1, Area^.KK);
	  cmCtrlQSpace: DeleteEmptyLinesPrim(Editor);
	  cmCtrlQShort: ConvertBlockPrim(Editor, cvShort);
	  cmCtrlQLong: ConvertBlockPrim(Editor, cvLong);
	  cmDateStamp: TimeStampPrim(Editor, tsDate);
	  cmTimeStamp: TimeStampPrim(Editor, tsTime);
	  cmCtrlQPeriod: ConvertToVolapyukPrim(Editor, True);
	  else Exit;
        end;
        if IsSelected and
           (Area^.KB = Area^.KK) and (Area^.PB = Area^.PK) then Unselect;
        DrawView;
        Indicator^.DrawView;
      end;
    end;
    Event.What := evNothing;
  end;
end;

procedure HandleEditBroadcast(Editor: PFileEditor; var Event: TEvent);
var
  SameName, SaveDebug: Boolean;
  B, E: Byte;
  C: Word;
  I, SaveSource: Integer;
  Spot: TPoint;
  S: String;
begin
  with Editor^ do
  begin
    case Event.Command of
      cmIsASCII: if Owner^.State and sfVisible <> 0 then ClearEvent(Event);
      cmASCIIOpened:
        begin
          SameName :=
            CompUCString(PString(Event.InfoPtr)^, FileName^) = Equal;
          if not SameName and not SameWinFlag then Exit;
          if not SameName then
            UpdateLinesPrim(Editor, PString(Event.InfoPtr)^);
          PWindow(Owner)^.Deiconize;
          Owner^.Show;
          Owner^.Select;
          ClearEvent(Event);
        end;
      cmIsPrintable: if Event.InfoPtr = Editor then ClearEvent(Event);
      cmSaveAll: if IsModified then Save('', False);
      cmUpdateTime:
	if (Event.InfoPtr = nil) or
	   (CompUCString(PString(Event.InfoPtr)^, FileName^) = Equal) then
	  UpdateTime
	else if (Event.InfoPtr <> nil) and (SyntaxList <> nil) and
	  (SyntaxList^.Count <> 0) and
	  (CompUCString(PString(Event.InfoPtr)^,
	   SyntaxList^.FileName^) = Equal) then
	begin
	  GetLocalFields;
	  DrawView;
	end;
      cmToggleMarkMode:
        begin
          DrawView;
          Indicator^.DrawView;
        end;
      cmGetSource: if Owner^.State and sfVisible <> 0 then
        begin
          Event.What := evNothing;
          Event.InfoPtr := FileName;
        end;
      cmGoToLine: if Owner^.State and sfVisible <> 0 then
        begin
          GoToPos(LongRec(Event.InfoPtr).Lo, LongRec(Event.InfoPtr).Hi);
          ClearEvent(Event);
        end;
      cmTrackSource: if Owner^.State and sfVisible <> 0 then
        begin
          SaveDebug := IsDebug;
          IsDebug := True;
          SaveSource := SourceLine;
          SourceLine := LongRec(Event.InfoPtr).Hi;
          DrawView;
          IsDebug := SaveDebug;
          SourceLine := SaveSource;
          DoRedraw := True;
          ClearEvent(Event);
        end;
      cmQuit: if Event.InfoPtr <> nil then IsModified := False else
        begin
          C := SaveOrCancel;
          if C = cmCancel then ClearEvent(Event)
          else if C = cmYes then Save('', False);
        end;
      cmRun, cmGoToCursor, cmTraceInto, cmStepOver:
        if not Debugging and not CPUInUse and
	  (Owner^.State and sfVisible <> 0) then
        begin
          Debug;
          ClearEvent(Event);
        end;
      cmGetWord:
        begin
          Event.What := evNothing;
          S := GetWord(B, E);
          if S = '' then Event.InfoPtr := nil
          else Event.InfoPtr := @S;
        end;
      cmGetLine:
        begin
          Event.What := evNothing;
          if Event.InfoPtr = Application then
            GetValidLine(Delta.Y + Cursor.Y, S)
          else S := GetLine;
          if S = '' then Event.InfoPtr := nil
	  else Event.InfoPtr := @S;
        end;
      cmGetPrintLine, cmGetSelPrintLine:
        begin
          I := Event.InfoInt;
          ClearEvent(Event);
          if GetPrintLine(I, Event.Command = cmGetSelPrintLine, S) then
            if S = '' then Event.InfoPtr := nil
            else Event.InfoPtr := @S;
        end;
      cmGetMarkerLine:
        begin
          Event.What := evNothing;
          if (Event.InfoChar in ['0'..'9']) and
             (Places[Event.InfoChar].X <> -1) and
             (Places[Event.InfoChar].Y <> -1) then
          begin
            GetValidLine(Places[Event.InfoChar].Y, S);
            Event.InfoPtr := @S;
	  end
          else Event.InfoPtr := nil;
        end;
      cmPrinterSetup:
        begin
          Event.What := evNothing;
          Event.InfoPtr := PrnRec;
        end;
      cmGetBlockDest: if (Owner^.State and sfVisible <> 0) and
        MouseInView(PView(Event.InfoPtr)^.Origin) then
        begin
          MakeLocal(PView(Event.InfoPtr)^.Origin, Spot);
	  while Delta.Y + Spot.Y > FileLines^.Count do Dec(Spot.Y);
          SetCursor(Spot.X, Spot.Y);
          ClearEvent(Event);
        end;
      cmNewSwapStream: SwapStream := Event.InfoPtr;
      cmEditOptions:
        begin
	  GetLocalFields;
	  DrawView;
        end;
      cmHelp:
        begin
          C := GetHelpCtx;
          if (C = hcAltASCIIEditor) or (C = hcASCIIEditor) or
             (C = hcClipboard) then
          begin
            Event.What := evNothing;
            Event.InfoPtr := HelpName;
          end;
        end;
      cmCtrlKW:
        begin
          WriteBlockToFilePrim(Editor, PString(Event.InfoPtr)^, False, False);
          ClearEvent(Event);
        end;
      cmCtrlKR:
        begin
          if IsSelected then ClearPrim(Editor, True, False);
          ReadBlockFromFilePrim(Editor, PString(Event.InfoPtr)^, False);
          DrawView;
          Indicator^.DrawView;
          ClearEvent(Event);
        end;
      cmUserMacros: if (MacroList <> nil) and
        (CompUCString(PString(Event.InfoPtr)^,
          CNFileName(MacroName^)) = Equal) then
            InitMacroListPrim(Editor);
      cmGetMacroName: if (Owner^.State and sfActive <> 0) and
        (Owner^.State and sfSelected <> 0) and (MacroList <> nil) then
        begin
          Event.What := evNothing;
          Event.InfoPtr := MacroName;
        end;
      cmlAPIChanged: if not IsClip then
        begin
          lGetFileNameForChangedAPI(lAPIType(Event.InfoByte),
            FileName^, S);
          NewTitle(S);
          if PWindow(Owner)^.Icon <> nil then
            PWinIcon(PWindow(Owner)^.Icon)^.Update;
        end;
    end
  end;
end;

const
  ipNo = 0;
  ipModified = 1;
  ipRowCol = 2;
  ipChar = 3;

function GetIndicatorPos(Editor: PFileEditor; X: Integer): Byte;
var
  Params: Array[0..1] of Longint;
  S: String;
begin
  GetIndicatorPos := ipNo;
  with Editor^ do
  begin
    if IsModified and (X = 0) then GetIndicatorPos := ipModified
    else if Options and ofHex <> 0 then GetIndicatorPos := ipRowCol
    else
    begin
      Params[0] := Delta.Y + Cursor.Y + 1;
      Params[1] := Delta.X + Cursor.X + 1;
      FormatStr(S, '%d:%d', Params);
      if (X > 2) and (X < 5 + Length(S)) then
        GetIndicatorPos := ipRowCol
      else if (X >= 5 + Length(S)) and
        (X < Indicator^.Size.X - 3) then
          GetIndicatorPos := ipChar;
    end;
  end;
end;

procedure HandleIndicatorMouse(Editor: PFileEditor; var Event: TEvent);
var
  B: Byte;
  Mouse: TPoint;
begin
  with Editor^.Indicator^ do
  begin
    MakeLocal(Event.Where, Mouse);
    B := GetIndicatorPos(Editor, Mouse.X);
    if B = ipModified then Event.Command := cmSave
    else if B = ipRowCol then Event.Command := cmGoToLine
    else if B = ipChar then Event.Command := cmASCIITable
    else if Mouse.X >= Size.X - 3 then
    begin
      if Event.Buttons = mbRightButton then
        if Editor^.State and sfDrawing <> 0 then
          Event.Command := cmCancel
        else Event.Command := cmCtrlKH
      else if Editor^.State and sfDrawSingle <> 0 then
        Event.Command := cmCtrlQD
      else if Editor^.State and sfDrawDouble <> 0 then
        Event.Command := cmCtrlQS
      else Event.Command := cmToggleMarkMode;
    end
    else Exit;
    Message(Application, evCommand, Event.Command, nil);
    Event.What := evNothing;
  end;
end;

function IndicatorGetMouseShape(Editor: PFileEditor;
  var Event: TEvent): Char;
var
  B: Byte;
  C: Char;
  P: TPoint;
begin
  C := #0;
  with Editor^.Indicator^ do
  if (State and sfActive <> 0) and
     (Owner^.State and sfFocused <> 0) then
  begin
    MakeLocal(Event.Where, P);
    B := GetIndicatorPos(Editor, P.X);
    case B of
      ipModified: if not Editor^.IsClip then C := '';
      ipRowCol: C := '';
      ipChar: C := '#';
    end;
  end;
  IndicatorGetMouseShape := C;
end;

function PreprocessEnabledPrim(Editor: PFileEditor;
  var Event: TEvent): Boolean;
begin
  with Editor^ do
    PreprocessEnabledPrim := (Event.CharCode = #0) or
      (not IsCtrlKPressed and not IsCtrlQPressed and
       not IsCtrlPPressed and not IsCtrlOPressed);
end;

end.