{$I-,F+,O+,X+}
unit ViewPop;

interface

uses Objects;

procedure ViewerPopup(AnOrigin: TPoint; Txt, Unix: Boolean);

implementation

uses Drivers, Views, Menus, Popups, Consts, Commands;

procedure ViewerPopup(AnOrigin: TPoint; Txt, Unix: Boolean);
var
  Item: PMenuItem;
  S: String[4];
begin
  if Txt then
  begin
    if Unix then S := 'UNIX' else S := 'DOS';
    Item := NewLine(
      NewItem('Set ' + S + ' te~x~t mode', '', kbNoKey, cmSetTextMode, hcSetTextMode,
      nil));
  end
  else Item := nil;
  ShowPopup(AnOrigin, NewMenu(
    NewItem('Mark block begin        Ctrl+K ~B~', '', kbNoKey, cmCtrlKB, hcCtrlKB,
    NewItem('Mark block end          Ctrl+K ~K~', '', kbNoKey, cmCtrlKK, hcCtrlKK,
    NewItem('Mark single word        Ctrl+K ~T~', '', kbNoKey, cmCtrlKT, hcCtrlKT,
    NewItem('Mark line               Ctrl+K ~L~', '', kbNoKey, cmCtrlKL, hcCtrlKL,
    NewItem('Hide/Display block      Ctrl+K ~H~', '', kbNoKey, cmCtrlKH, hcCtrlKH,
    NewItem('Write block to disk...  Ctrl+K ~W~', '', kbNoKey, cmCtrlKW, hcCtrlKW,
    NewLine(
    NewItem('~C~opy to Clipboard       Ctrl+Ins', '', kbNoKey, cmCopy, hcECopy,
    NewLine(
    NewItem('~F~ind...                       F7', '', kbF7, cmFind, hcSHFind,
    NewItem('~R~eplace...', '', kbNoKey, cmReplace, hcSHReplace,
    NewItem('Find ~a~ll...', '', kbNoKey, cmFindAll, hcSHFindAll,
    NewItem('Sh~o~w all found...', '', kbNoKey, cmShowAllFound, hcSHShowAllFound,
    NewItem('~S~earch again              Ctrl+L', '', kbNoKey, cmSearchAgain, hcSHSearchAgain,
    NewItem('~I~ncremental search        Ctrl+@', '', kbNoKey, cmIncSearch, hcSHIncSearch,
    NewItem('~G~o to line number...', 'Alt+G', kbAltG, cmGoToLine, hcSHGoToLineNumber,
    NewLine(
    NewItem('~M~ove to begin of block  Ctrl+Q B', '', kbNoKey, cmCtrlQB, hcCtrlQB,
    NewItem('Mo~v~e to end of block    Ctrl+Q K', '', kbNoKey, cmCtrlQK, hcCtrlQK,
      Item)))))))))))))))))))));
end;

end.