{$I-,F+,O+,X+}
unit EditPop;

interface

uses Objects;

procedure PopUpPrim(AnOrigin: TPoint; Unix: Boolean);

implementation

uses Drivers, Views, Menus, Popups, Consts, Commands;

procedure PopUpPrim(AnOrigin: TPoint; Unix: Boolean);

function EditSubMenu(Next: PMenuItem): PMenuItem;
begin
  EditSubMenu := NewSubMenu('~O~ther block commands', hcOtherCtrlQ, NewMenu(
    NewItem('Mark single word            Ctrl+K ~T~', '', kbNoKey, cmCtrlKT, hcCtrlKT,
    NewItem('M~a~rk line                   Ctrl+K L', '', kbNoKey, cmCtrlKL, hcCtrlKL,
    NewItem('Move to begin of block      Ctrl+Q ~B~', '', kbNoKey, cmCtrlQB, hcCtrlQB,
    NewItem('Move to end of block        Ctrl+Q ~K~', '', kbNoKey, cmCtrlQK, hcCtrlQK,
    Menus.NewLine(
    NewItem('Delete to end of line       Ctrl+Q ~Y~', '', kbNoKey, cmCtrlQY, hcCtrlQY,
    NewItem('Delete to end of file       Ctrl+Q ~Z~', '', kbNoKey, cmCtrlQZ, hcCtrlQZ,
    NewItem('Indent block                Ctrl+K ~I~', '', kbNoKey, cmCtrlKI, hcCtrlKI,
    NewItem('U~n~indent block              Ctrl+K U', '', kbNoKey, cmCtrlKU, hcCtrlKU,
    NewItem('Left justify                Ctrl+Q ~G~', '', kbNoKey, cmCtrlQG, hcCtrlQG,
    NewItem('Center                      Ctrl+Q ~C~', '', kbNoKey, cmCtrlQC, hcCtrlQC,
    NewItem('Right justify               Ctrl+Q ~E~', '', kbNoKey, cmCtrlQE, hcCtrlQE,
    NewItem('Uppercase                   Ctrl+Q ~U~', '', kbNoKey, cmCtrlQU, hcCtrlQU,
    NewItem('Lowercase                   Ctrl+Q ~L~', '', kbNoKey, cmCtrlQL, hcCtrlQL,
    NewItem('"QWERTY" to "âñìäÖç"        Ctrl+Q ~H~', '', kbNoKey, cmCtrlQH, hcCtrlQH,
    NewItem('"âñìäÖç" to "QWERTY"        Ctrl+Q ~ê~', '', kbNoKey, cmCtrlQp, hcCtrlQp,
    NewItem('Translate into Volapyuk     Ctrl+Q ~V~', '', kbNoKey, cmCtrlQV, hcCtrlQV,
    NewItem('Reformat text...            Ctrl+Q ~R~', '', kbNoKey, cmCtrlQR, hcCtrlQR,
    NewItem('Unformat text...            Ctrl+Q ~O~', '', kbNoKey, cmCtrlQO, hcCtrlQO,
    NewItem('Sort lines in block...      Ctrl+Q ~X~', '', kbNoKey, cmCtrlQX, hcCtrlQX,
    Menus.NewLine(
    NewItem('Math operation...           Ctrl+Q ~M~', '', kbNoKey, cmCtrlQM, hcCtrlQM,
      nil))))))))))))))))))))))), Next);
end;

var
  S: String[4];
begin
  if Unix then S := 'UNIX' else S := 'DOS';
  ShowPopup(AnOrigin, NewMenu(
    NewItem('Mark block begin        Ctrl+K ~B~', '', kbNoKey, cmCtrlKB, hcCtrlKB,
    NewItem('Mark block end          Ctrl+K ~K~', '', kbNoKey, cmCtrlKK, hcCtrlKK,
    NewItem('Copy block              Ctrl+K ~C~', '', kbNoKey, cmCtrlKC, hcCtrlKC,
    NewItem('Move block (Delete)     Ctrl+K ~V~', '', kbNoKey, cmCtrlKV, hcCtrlKV,
    NewItem('Move block (Clear)      Ctrl+K ~M~', '', kbNoKey, cmCtrlKM, hcCtrlKM,
    NewItem('Delete block            Ctrl+K ~Y~', '', kbNoKey, cmCtrlKY, hcCtrlKY,
    NewItem('Clear block             Ctrl+K ~D~', '', kbNoKey, cmCtrlKD, hcCtrlKD,
    NewItem('Read block from disk... Ctrl+K ~R~', '', kbNoKey, cmCtrlKR, hcCtrlKR,
    NewItem('Write block to disk...  Ctrl+K ~W~', '', kbNoKey, cmCtrlKW, hcCtrlKW,
    NewItem('Hide/Display block      Ctrl+K ~H~', '', kbNoKey, cmCtrlKH, hcCtrlKH,
    NewItem('Print block             Ctrl+K ~P~', '', kbNoKey, cmCtrlKP, hcCtrlKP,
    EditSubMenu(
    Menus.NewLine(
    NewItem('Draw single lines       Ctrl+Q ~S~', '', kbNoKey, cmCtrlQS, hcCtrlQS,
    NewItem('Dr~a~w double lines       Ctrl+Q D', '', kbNoKey, cmCtrlQD, hcCtrlQD,
    Menus.NewLine(
    NewItem('Date/Time stamp         Ctrl+Q ~T~', '', kbNoKey, cmCtrlQT, hcCtrlQT,
    NewItem('Open file at cursor     Ctrl+Q ~N~', '', kbNoKey, cmCtrlQN, hcCtrlQNew,
    NewItem('Mak~e~ dir at cursor      Ctrl+Q P', '', kbNoKey, cmCtrlQPath, hcCtrlQPath,
    NewItem('XLAT table...           Ctrl+Q ~Q~', '', kbNoKey, cmCtrlQQ, hcCtrlQW,
    Menus.NewLine(
    NewItem('Set ' + S + ' te~x~t mode', '', kbNoKey, cmSetTextMode, hcSetTextMode,
      nil))))))))))))))))))))))));
end;

end.