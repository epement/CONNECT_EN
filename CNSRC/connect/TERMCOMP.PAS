{$I-,F+,O+,X+}
unit TermComp; {termcap compiler}

interface

uses Objects;

const
 MaxArgs = 10;
type
 PTermItem = ^TTermItem;
 TTermItem = record
  Cmd : array[0..1] of char;
  CStr : PString;
  Keyb: Boolean;                  {Added 01-17-97}
 end;

 PTermColl = ^TTermColl;
 TTermColl = object(TCollection)
  procedure FreeItem(Item: Pointer); virtual;
  function FindCode(Code : Word; var Index : Integer): boolean;
 end;

 TArg = Array[0..MaxArgs] of integer;

 TTermResult = (trComplete, trIncomplete, trUnknown);

const
  TermColl: PTermColl = nil;

procedure InitTermColl;
procedure DoneTermColl;
function ReadTermcap(const Name, Term: String): Boolean;
function InputControl(var InStr : String;
                      var Cmd : Word;
                      var Arg : TArg;
                      var Args : Integer): TTermResult;
procedure DoCmd(Cmd : Word;
                var Arg : TArg;
                var Args : Integer);
function KeyCodeStr(Key : Word) : String;

implementation

uses Dos, Drivers, Views, Memory, App, RevPos, Filters, TermProc,
  DirPrim, HeapUMB, EditMsg, LFN, DosTools, Timer, TPString, Defaults,
  fmAbort;

procedure ExchangeWords(var I, J : Word);
  {-Exchange words I and J. Useful in sorts}
  inline(
    $8C/$DB/                 {mov bx,ds       ;save DS}
    $5E/                     {pop si}
    $1F/                     {pop ds          ;DS:SI => J}
    $5F/                     {pop di}
    $07/                     {pop es          ;ES:DI => I}
    $8B/$04/                 {mov ax,[si]     ;AX = J}
    $26/$87/$05/             {xchg ax,es:[di] ;I = J, AX = I}
    $89/$04/                 {mov [si],ax     ;J = I}
    $8E/$DB);                {mov ds,bx       ;restore DS}


procedure TTermColl.FreeItem(Item : Pointer);
begin
 if Item <> Nil then
  begin
{   DisposeStr(TTermItem(Item^).CStr);}
   DisposeStrUMB(TTermItem(Item^).CStr);
   FreeMem(Item, SizeOf(TTermItem));
  end;
end;

function TTermColl.FindCode(Code : Word; var Index : Integer): Boolean;
var
 I : Integer;
begin
 FindCode := False;
 for I := Count-1 downto 0 do
  if Code = Word(TTermItem(At(I)^).Cmd) then
   begin
    FindCode := True;
    Index := I;
    Exit;
   end;
end;

procedure InitTermColl;
begin
  if TermColl = nil then TermColl := New(PTermColl, Init(32, 32));
end;

procedure DoneTermColl;
begin
  if TermColl <> nil then Dispose(TermColl, Done);
  TermColl := nil;
end;

function InsertCode(Const Code : String; Const Termcap : String) : Boolean;
const
 KeybCmd =
  'k1 k2 k3 k4 k5 k6 k7 k8 k9 k; kb kd kD kP kN kB kF kR kC kh kI kl kr ku kE';
var
 PItem, P : PTermItem;
 I, J, V, Cd : Integer;
 C : Byte;
 Cmd : array[0..1] of char;
 SS : String;
begin
 if SPtr < $D00 then Exit;
 InsertCode := True;
 Cmd[0] := Code[1];
 Cmd[1] := Code[2];
 {Если Boolean Capabilities или Numeric Capabilities и такая уже есть,
 игнорировать ее}
 if not ((Byte(Code[0]) > 2) and (Code[3] = '='))
    and TermColl^.FindCode(Word(Cmd), I) then exit;
 PItem := MemAlloc(SizeOf(TTermItem));
 if PItem = Nil then
  begin
   InsertCode := False;
   Exit;
  end;
 Word(PItem^.Cmd) := Word(Cmd);
 SS[0] := #2; SS[1] := Code[1]; SS[2] := Code[2];
 PItem^.Keyb := Pos(SS, KeybCmd) <> 0;
 PItem^.CStr := Nil;

 case Word(Cmd) of
{Boolean Capabilities}
{am}  $6D61 : TerminalOptions := TerminalOptions or ooAutoWrap; {Automatic margins which means automatic line wrap}
                   {при достижении последней колонки курсор автоматически}
                   {переходит в начало следующей строки}
{bs}  $7362 : TerminalOptions := TerminalOptions and not ooDestructiveBS {Control-H (8 dec.) performs a backspace}
                   {для перемещения на одну позицию влево служит код \b}
 else
  if (Byte(Code[0]) > 2) and (Code[3] = '#') then
  begin
   SS := Copy(Code, 4, 255);
   Val(SS, V, Cd);
      case Word(Cmd) of
  {Numeric Capabilities}
  {co}  $6F63 : if (V >= 1) and (V <= 132) then TerminalWidth := V;
                                        {Number of columns}
                                        {Число колонок}
  {li}  $696C : if (V >= 1) and (V <= 80) then TerminalHeight := V;
                                        {Number of lines}
                                        {Число строк}
      end {case};
  end;
 end {case};

 if (Byte(Code[0]) > 2) and (Code[3] = '=') then
  begin
   J := 1; I := 4;
   while I <= Length(Code) do
    begin

     {^ коды }
     if (Code[I] = '^') and (I + 1 <= Length(Code))
        and (Code[I + 1] in ['@'..'_']) then
      begin
       SS[J] := Char(Byte(Code[I+1]) - Byte('A') + 1);
       Inc(J);
       Inc(I, 2);
       Continue;
      end;

      {\ }
     if (Code[I] = '\') and (I + 1 <= Length(Code))
        and (Code[I + 1] in ['\','^','E','e','n','r','t','b','f']) then
      begin
       case Code[I+1] of
        '\' : SS[J] := '\';
        '^' : SS[J] := '^';
    'E','e' : SS[J] := #27;
        'n' : SS[J] := #10;
        'r' : SS[J] := #13;
        't' : SS[J] := #9;
        'b' : SS[J] := #8;
        'f' : SS[J] := #12;
       end; {case}
       Inc(J);
       Inc(I, 2);
       Continue;
      end;

      {\[0-9]}
     if (Code[I] = '\') and (I + 1 < Length(Code))
        and (Code[I + 1] in ['0'..'7']) then
      begin
       Inc(I); C := 0;
       while (I <= Length(Code)) and (Code[I] in ['0'..'7']) do
        begin
         C := (C shl 3) + Byte(Code[I]) - Byte('0');
         Inc(I);
        end;
       SS[J] := Char(C);
       Inc(J);
       Continue;
      end;

     {% коды}
     if (Code[I] = '%') and (I + 1 < Length(Code))
        and (Code[I + 1] in ['<']) then
      begin
       Inc(I, 2);
       Continue;
      end;

     SS[J] := Code[I];
     Inc(J); Inc(I);
    end;

   SS[0] := Char(J - 1);
   if Word(Cmd) = {tc} $6374 then
    begin
     FreeMem(PItem, SizeOf(TTermItem));
     ReadTermcap(Termcap, SS);
     Exit;
    end;
   if (Cmd[0] = 'g') and (Cmd[1] in ['t', '1'..'6']) then
    begin
     SetGraphChars(SS, Cmd[1]);
     FreeMem(PItem, SizeOf(TTermItem));
     Exit;
    end;
   while (SS[1] in ['0'..'9', '*']) and (Length(SS) > 0) do Delete(SS, 1, 1);
{   PItem^.CStr := NewStr(SS);}
   PItem^.CStr := NewStrUMB(SS);
  end;
 for I := 0 to TermColl^.Count - 1 do
 begin
   P := TermColl^.At(I);
   if (P^.Cmd = PItem^.Cmd) and ((P^.CStr = PItem^.CStr) or
      ((P^.CStr <> nil) and (PItem^.CStr <> nil) and
       (P^.CStr^ = PItem^.CStr^))) then
    begin
      TermColl^.FreeItem(PItem);
      Exit;
    end;
 end;
 TermColl^.Insert(PItem);
end;

function ReadTermcap(const Name, Term: String): Boolean;
var
 FoundTerm : Boolean;
 Ps, Ps1 : Byte;
 TC : lText;
 S, SS, TermName : String;
begin
 ReadTermcap := False;
 if SPtr < $D00 then Exit;
 Ps := Length(Term);
 if Ps > 30 then Ps := 30;
 TermName := CNFileName(Name);
 LogEvent := lcDiskRead;
 DrawStatusLine('Reading TERMCAP file ' +
   TrimmedName(TermName, 42 - Ps) + ' (' + Term + ').');
 lAssignText(TC, TermName);
 Reset(TC.T);
 if IOResult <> 0 then
 begin
   InitTimer(50, evCommand, cmOk, True);
   CouldNotOpenMsgBox(TermName);
   Exit;
 end;
 if not IsDevice(TextRec(TC.T).Handle) then
 begin
   if not Eof(TC.T) then
   begin
     SetUNIXTextMode;
     ReadLn(TC.T,S);
     if S[Length(S)] = #13 then SetDOSTextMode;
     TextSeek(TC.T, 0);
   end;
   FoundTerm := False;
   While not eof(TC.T) do
   begin
    if EscPressed then
    begin
      TermColl^.FreeAll;
      Break;
    end;
    ReadLn(TC.T, S);
    if S[1] = '#' then Continue;
    Ps := Pos(':', S);
    if not FoundTerm and (S[1] <> ' ') and (Ps <> 0) then
     begin
      SS := Copy(S, 1, Ps - 1);
      FoundTerm := RGSearch(SS, Term) = StUpCase(Term);
     end;
    if not FoundTerm then Continue;
    if Ps <> 0 then
    repeat
     Ps1 := FIPos(':', S, Ps);
     if Ps1 <> 0 then
      begin
       SS := Copy(S, Ps + 1, Ps1 - Ps - 1);
       InsertCode(SS, Name);
       Ps := Ps1;
      end;
    until Ps1 = 0;
    if S[Length(S)] <> '\' then Break;
   end;
   SetDOSTextMode;
   if not FoundTerm then
   begin
     InitTimer(50, evCommand, cmOk, True);
     TermcapNotFoundMsgBox(TermName, Term);
   end
   else ReadTermcap := True;
 end
 else
 begin
   InitTimer(50, evCommand, cmOk, True);
   FileIsDeviceMsgBox(TermName);
 end;
 Close(TC.T);
 InOutRes := 0;
end;

function InputControl(var InStr : String;
                      var Cmd : Word;
                      var Arg : TArg;
                      var Args : Integer): TTermResult;
var
 I, Idx : Integer;
 Cpl, InputCtl, Complete : Boolean;
 PStr : PString;
 PItem : PTermItem;

function StrComp(const CStr : String;
                 var Cpl : Boolean) : Boolean;
var
 x,y : Byte;
 I, J, V, ArgI : Integer;
 iFl, rFl, nFl, DFl, BFl, xyFl : Boolean;
begin
 iFl := False; rFl := False;
 nFl := False; DFl := False;
 BFl := False; xyFl := False;
 {FillChar(iFl, 6, 0);}
 StrComp := False; Cpl := False;
 I := 1; J := 1;
 ArgI := 0; Args := 0;
 while (I <= Length(InStr)) and (J <= Length(CStr)) do
  begin
    if (CStr[J] = '%') and (J + 1 <= Length(CStr)) then
     begin {Обработка шаблонов}
      Inc(J);
      case CStr[J] of
       '%': if InStr[I] <> '%' then Exit
            else Inc(I);
       'd','1','2' : {Аргумент - десятичное число в символьном виде}
        begin
         V := 0;
         if not (InStr[I] in ['0'..'9']) then Exit;
         while (I <= Length(InStr)) and (InStr[I] in ['0'..'9']) do
          begin
            V := V*10 + Byte(InStr[I]) - Byte('0');
            Inc(I);
          end;
         if IFl and (V > 0) then Dec(V);
         Arg[ArgI] := V;
         if ArgI < MaxArgs then Inc(ArgI);
        end;
       'i' : iFl := True; {Признак инкрементирования следующих аргументов}
       'r' : rFl := True; {Признак перемены местами первого и второго аргументов}
       'n' : nFl := True; {}
       'B' : BFl := True; {}
       'D' : DFl := True; {}
       '>' : {Признак относительного числового аргумента в бинарном виде}
        begin
         Inc(J);
         x := Byte(CStr[J]);
         Inc(J);
         y := Byte(CStr[J]);
         xyFl := True;
        end;
       '.' : {Признак числового аргумента в бинарном виде}
        begin
         V := Byte(InStr[I]);
         Inc(I);
         if IFl and (V > 0) then Dec(V);
         Arg[ArgI] := V;
         if ArgI < MaxArgs then Inc(ArgI);
        end;
       '+' : {Признак относительного числового аргумента в бинарном виде}
        begin
         Inc(J);
         if xyFl and (Byte(InStr[I]) - Byte(CStr[J]) > x) then
           V := Byte(InStr[I]) - Byte(CStr[J]) - y
         else V := Byte(InStr[I]) - Byte(CStr[J]);
         Inc(I);
         if IFl and (V > 0) then Dec(V);
         Arg[ArgI] := V;
         if ArgI < MaxArgs then Inc(ArgI);
        end;
      end; {case}
     Inc(J);
     end
    else
     begin
      if InStr[I] <> CStr[J] then Exit
      else
       begin
        Inc(I); Inc(J);
        if J > Length(CStr) then
         begin
          StrComp := True;
          Cpl := True;
          Args := ArgI;
          if rFl then ExchangeWords(Word(Arg[0]), Word(Arg[1]));
          Exit;
         end;
       end;
     end;
  end;
 Cpl := True;
 if J > Length(CStr) then
  begin
   StrComp := True;
   Args := ArgI;
   if rFl then ExchangeWords(Word(Arg[0]), Word(Arg[1]));
  end;
end;

begin
 InputCtl := false; Cmd := 0; Complete := False;
 for I := TermColl^.Count - 1 downto 0 do
  begin
   PItem := TermColl^.At(I);
   if PItem^.Keyb then Continue;
   PStr := PItem^.CStr;
   if PStr = Nil then Continue;
   if StrComp(PStr^, Cpl) then
    begin
     Cmd := Word(PItem^.Cmd);
     InStr := '';
     InputControl := trComplete; {Найдена команда}
     Exit;
    end;
   Complete := Complete or Cpl;
  end;
  if Complete then InputControl := trIncomplete {Продолжить}
  else InputControl := trUnknown; {Вывести строку}
end;

procedure DoCmd(Cmd : Word;
                var Arg : TArg;
                var Args : Integer);
begin
 case Cmd of
  {AL}  $4C41 :   InsertLine(Arg[0]);  {Insert %1 lines}
  {al}  $6C61 :   InsertLine(1); {Insert one line}
                  {Вставить пустую строку}
  {kb}{ $626B,}   {Backspace key}
                  {Код клавиши возврат на шаг}
  {bc}  $6362 :   Backspace; {Backspace, if not ^H}
                  {Перевод курсора на одну позицию назад (если не \b);}
  {bl}  $6C62 :   Bell; {Audio bell}
                  {Звуковой сигнал (если не \7)}
  {bt}  $7462 :   BackTab; {Move to previous tab stop}
                  {Обратная табуляция}
  {cb}  $6263 :   ClearToCursor;  {Clear from beginning of line to cursor}
  {Cb}  $6243 :   SetBackColor(Arg[0]);  {Установка цвета фона по номеру}
  {cd}  $6463 :   ClearToEOS; {Clear to end of screen}
                  {Стирание части экрана с текущей строки и до конца}
  {ce}  $6563 :   ClearToEOL; {Clear to end of line}
                  {Стирание информации от текущей позиции до конца строки}
  {Cf}  $6643 :   SetForeColor(Arg[0]); {Установка основного цвета по номеру}
  {ch}  $6863 :   SetCursorTo(-1, Arg[0]);  {Move cursor horizontally only to column %1}
                  {Адресация курсора в пределах текущей строки (по горизонтали)}
  {cl}  $6C63 :   Clear; {Clear screen and cursor home}
                  {Очистка экрана}
  {cm}  $6D63 :   SetCursorTo(Arg[0], Arg[1]); {Cursor move to row %1 and column %2 (on screen)}
                  {Адресация курсора}
  {cr}  $7263 :   CarriageReturn;  {Carriage return}
                  {Возврат в начало строки (если не \r);}
  {cs}  $7363 :   SetScrollRegion(Arg[0], Arg[1]); {Scroll region from line %1 to %2}
                  {Изменение области роллирования на экране (параметры аналогичны cm);}
  {cv}  $7663 :   SetCursorTo(Arg[0], -1);  {Move cursor vertically only to line %1}
                  {Адресация курсора по вертикали}
  {DC}  $4344 :   DeleteChar(Arg[0]); {Delete %1 characters}
                  {Код клавиши "исключить символ" (для red)}
  {kD}{ $446B,}   {Key for delete character under cursor}
                  {Клавиша удаления символа}
  {dc}  $6364 :   DeleteChar(1); {Delete one character}
                  {Исключить символ в текущей позиции}
  {DL}  $4C44 :   DeleteLine(Arg[0]); {Delete %1 lines}
                  {Код клавиши "исключить строку" (для red)}
  {dl}  $6C64 :   DeleteLine(1); {Delete one line}
                  {Удалить текущую строку}
  {DO}  $4F44 :   CursorDown(Arg[0]); {Cursor down %1 lines}
  {kd}{ $646B :   CursorDown(1);}{Cursor down key}
                  {Код клавиши курсор вниз}
  {do}  $6F64 :   MoveDown; {Cursor down one line}
                  {Перевод курсора вниз на одну строку}
  {ec}  $6365 :   EraseChar(Arg[0]); {Erase %1 characters starting at cursor}
                  {Очистить символ}
  {kh}{ $686B,}   {Cursor home key}
                  {Код клавиши home}
  {ho}  $6F68 :   SetCursorTo(0, 0); {Cursor home}
                  {Перевод курсора в первую позицию первой строки}
  {IC}  $4349 :   InsertChar(Arg[0]); {Insert %1 characters}
                  {Код клавиши "вставить символ" (для red)}
  {ic}  $6369 :   InsertChar(1); {Insert one character}
                  {Вставить символ в текущей позиции}
  {im}  $6D69 :   StartInsertMode; {Insert mode}
  {ei}  $6965 :   EndInsertMode; {End insert mode}
  {kc}{ $636B :   ;}{Num Lock off}
  {ke}{ $656B :   ;}{Num Lock on}
  {LE}  $454C :   CursorLeft(Arg[0]); {Cursor left %1 characters}
  {kl}{ $6C6B,}   {Cursor left key}
                  {Код клавиши курсор влево}
  {le}  $656C :   CursorLeft(1); {Cursor left one character}
                  {Перевод курсора на одну позицию влево}
  {ll}  $6C6C :   CursorLowerLeft; {Move cursor to lower left corner}
                  {Курсор в нижний левый угол экрана}
  {mb}  $626D :   SetBlinking; {Start blinking}
                  {Включение режима мигающих символов}
  {md}  $646D :   SetBold; {Start bold mode}
                  {Включение режима ярких символов}
  {me}  $656D,
  {se}  $6573 :   SetNormal; {End all mode like so, us, mb, md and mr}
                  {Отмена всех режимов выделения текста ("mb", "md", "ml", "mr", "us", "so")}
  {mh}  $686D :   SetHalfBright; {Start half bright mode}
                  {Включение режима тусклых символов}
  {mk}  $6B6D :   SetDark; {Dark mode (Characters invisible)}
                  {Включение режима невидимых символов}
  {mr}  $726D,
  {so}  $6F73 :   SetInverse; {Start reverse mode}
                  {Включение режима инверсных символов}
  {ri}  $6972,
  {kr}{ $726B,}   {Cursor right key}
                  {Код клавиши курсор вправо}
  {nd}  $646E :   CursorRight(1); {Non-destructive space (cursor right).}
                  {Перевод курсора на одну позицию вправо}
  {nl}  $6C6E :   NewLine; {Переход на следующую строку (если не \n)}
  {nw}  $776E :   CRLF; {Команда CR-LF}
  {rc}  $6372 :   RestoreCursor; {Restore saved cursor position}
                  {Восстановить положение курсора (после sc)}
  {RI}  $4952 :   CursorRight(Arg[0]); {Cursor right %1 characters}
  {rp}  $7072 :   RepeatChar(Char(Arg[0]), Arg[1]); {Repeat character %1 for %2 times}
  {sa}  $6173 :   SetAttr(@Arg, Args); {Set %1 %2 %3 %4 %5 %6 %7 %8 %9 attributes}
  {sc}  $6373 :   SaveCursor; {Save cursor position}
                  {Запомнить текущее положение курсора}
  {SF}  $4653 :   ScrollUp(Arg[0]); {Normal scroll %1 lines}
  {sf}  $6673 :   ScrollUp(1); {Normal scroll one line}
                  {Прокрутить текст вверх}
  {sr}  $7273 :   ScrollDown(1); {Reverse scroll}
                  {Прокрутить текст вниз}
  {SR}  $5253 :   ScrollDown(Arg[0]); {scroll back %1 lines}
  {ta}  $6174 :   Tab; {move to next hardware tab}
                  {Команда табуляции (если не \t)}
  {uc}  $6375 :   UnderlineChar; {Underline character under cursor and move cursor right}
                  {Подчеркнуть один символ}
  {ue}  $6575 :   EndUnderline; {End underlining}
                  {Конец режима подчеркивания}
  {UP}  $5055 :   CursorUp(Arg[0]); {Cursor up %1 lines}
  {ku}{ $756B :   CursorUp(1);}{Cursor up key}
                  {Клавиша стрелка вверх}
  {up}  $7075 :   MoveUp; {Cursor up one line}
                  {Перевод курсора на строку вверх}
  {us}  $7375 :   SetUnderline; {Start underlining}
                  {Включить режим подчеркивания выводимых символов}
  {vb}  $6276 :   Bell; {Visible bell (must not move cursor).}
                  {Видимый аналог звукового сигнала}
  {vi}  $6976 :   CursorInvisible; {Hide cursor}
                  {Спрятать курсор}
  {ve}  $6576,
  {vs}  $7376 :   CursorVisible; {Show cursor}
                  {Показать курсор}
  {gs}  $7367 :   SetGraphMode(1); {Включить режим вывода псевдографики}
  {ge}  $6567 :   SetGraphMode(0); {Выключить режим вывода псевдографики}

(*
  {k1}  $316B,    {Function key 1}
                  {Функциональная клавиша 1}
  {k2}  $326B,    {Function key 2}
                  {Функциональная клавиша 2}
  {k3}  $336B,    {Function key 3}
                  {Функциональная клавиша 3}
  {k4}  $346B,    {Function key 4}
                  {Функциональная клавиша 4}
  {k5}  $356B,    {Function key 5}
                  {Функциональная клавиша 5}
  {k6}  $366B,    {Function key 6}
                  {Функциональная клавиша 6}
  {k7}  $376B,    {Function key 7}
                  {Функциональная клавиша 7}
  {k8}  $386B,    {Function key 8}
                  {Функциональная клавиша 8}
  {k9}  $396B,    {Function key 9}
                  {Функциональная клавиша 9}
  {k;}  $3B6B:;   {Function key 10}
                  {Функциональная клавиша 10}
*)
 end; {case}
end;

function KeyCodeStr(Key : Word) : String;
var
 Cmd : Word;
 I : Integer;
 PS : PString;
begin
 KeyCodeStr := '';
 case Key of
 {k1} $3B00 : Cmd := $316B;    {Function key 1}
                               {Функциональная клавиша 1}
 {k2} $3C00 : Cmd := $326B;    {Function key 2}
                               {Функциональная клавиша 2}
 {k3} $3D00 : Cmd := $336B;    {Function key 3}
                               {Функциональная клавиша 3}
 {k4} $3E00 : Cmd := $346B;    {Function key 4}
                               {Функциональная клавиша 4}
 {k5} $3F00 : Cmd := $356B;    {Function key 5}
                               {Функциональная клавиша 5}
 {k6} $4000 : Cmd := $366B;    {Function key 6}
                               {Функциональная клавиша 6}
 {k7} $4100 : Cmd := $376B;    {Function key 7}
                               {Функциональная клавиша 7}
 {k8} $4200 : Cmd := $386B;    {Function key 8}
                               {Функциональная клавиша 8}
 {k9} $4300 : Cmd := $396B;    {Function key 9}
                               {Функциональная клавиша 9}
 {k;} $4400 : Cmd := $3B6B;    {Function key 10}
                               {Функциональная клавиша 10}
 {kb} $0E08 : Cmd := $626B;    {Backspace key}
                               {Код клавиши возврат на шаг}
 {kd} $5000 : Cmd := $646B;    {Cursor down key}
                               {Код клавиши курсор вниз}
 {kD} $5300 : Cmd := $446B;    {Key for delete character under cursor}
                               {Клавиша удаления символа}
 {kP} $4900 : Cmd := $506B;    {PgUp}
 {kN} $5100 : Cmd := $4E6B;    {PgDn}
 {kB} $0F00 : Cmd := $426B;    {Shift+Tab}
 {kF} $0900 : Cmd := $466B;    {Ctrl+Down (Клавиша роллирования вперед)}
 {kR} $0800 : Cmd := $526B;    {Ctrl+Up (Клавиша роллирования назад)}
 {kC} $0600 : Cmd := $436B;    {Ctrl+Del (Клавиша очистки экрана)}
 {kh} $4700 : Cmd := $686B;    {Cursor home key}
                               {Код клавиши home}
 {kI} $5200 : Cmd := $496B;    {Insert character/Insert mode key}
                               {Клавиша вставки символа (INSERT)}
 {kl} $4B00 : Cmd := $6C6B;    {Cursor left key}
                               {Код клавиши курсор влево}
 {kr} $4D00 : Cmd := $726B;    {Cursor right key}
                               {Код клавиши курсор вправо}
                               {Клавиша установки табуляции}
 {ku} $4800 : Cmd := $756B;    {Cursor up key}
                               {Клавиша стрелка вверх}
 {kE} $1C0D : Cmd := $456B;    {Клавиша Enter}
 else Exit;
 end {case};
 if TermColl^.FindCode(Word(Cmd), I) then
 begin
   PS := TTermItem(TermColl^.At(I)^).CStr;
   if PS <> nil then KeyCodeStr := PS^;
 end;
end;

end.