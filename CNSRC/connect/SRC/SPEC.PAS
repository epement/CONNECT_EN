type
 TSpc = record
  S: String[6];
  N : Byte;
 end;
const
SpecCnt = 105;
Specials : array[0..SpecCnt - 1] of TSpc =
 ((S: 'AElig'  ;N: 198),
  (S: 'Aacute' ;N: 193),
  (S: 'Acirc'  ;N: 194),
  (S: 'Agrave' ;N: 192),
  (S: 'Aring'  ;N: 197),
  (S: 'Atilde' ;N: 195),
  (S: 'Auml'   ;N: 196),
  (S: 'Ccedil' ;N: 199),
  (S: 'ETH'    ;N: 208),
  (S: 'Eacute' ;N: 201),
  (S: 'Ecirc'  ;N: 202),
  (S: 'Egrave' ;N: 200),
  (S: 'Euml'   ;N: 203),
  (S: 'Iacute' ;N: 205),
  (S: 'Icirc'  ;N: 206),
  (S: 'Igrave' ;N: 204),
  (S: 'Iuml'   ;N: 207),
  (S: 'Ntilde' ;N: 209),
  (S: 'Oacute' ;N: 211),
  (S: 'Ocirc'  ;N: 212),
  (S: 'Ograve' ;N: 210),
  (S: 'Oslash' ;N: 216),
  (S: 'Otilde' ;N: 213),
  (S: 'Ouml'   ;N: 214),
  (S: 'THORN'  ;N: 222),
  (S: 'Uacute' ;N: 218),
  (S: 'Ucirc'  ;N: 219),
  (S: 'Ugrave' ;N: 217),
  (S: 'Uuml'   ;N: 220),
  (S: 'Yacute' ;N: 221),
  (S: 'aacute' ;N: 225),
  (S: 'acirc'  ;N: 226),
  (S: 'acute'  ;N: 180),
  (S: 'aelig'  ;N: 230),
  (S: 'agrave' ;N: 224),
  (S: 'amp'    ;N: 153),
  (S: 'aring'  ;N: 229),
  (S: 'atilde' ;N: 227),
  (S: 'auml'   ;N: 228),
  (S: 'brvbar' ;N: 166),
  (S: 'ccedil' ;N: 184),
  (S: 'ccedil' ;N: 231),
  (S: 'cent'   ;N: 162),
  (S: 'copy'   ;N: 169),
  (S: 'curren' ;N: 164),
  (S: 'deg'    ;N: 176),
  (S: 'divide' ;N: 247),
  (S: 'eacute' ;N: 233),
  (S: 'ecirc'  ;N: 234),
  (S: 'egrave' ;N: 232),
  (S: 'emdash' ;N: 159),
  (S: 'emsp'   ;N: 156),
  (S: 'endash' ;N: 158),
  (S: 'ensp'   ;N: 155),
  (S: 'eth'    ;N: 240),
  (S: 'euml'   ;N: 235),
  (S: 'frac12' ;N: 189),
  (S: 'frac14' ;N: 188),
  (S: 'frac34' ;N: 190),
  (S: 'gt'     ;N: 152),
  (S: 'iacute' ;N: 237),
  (S: 'icirc'  ;N: 238),
  (S: 'iexcl'  ;N: 161),
  (S: 'igrave' ;N: 236),
  (S: 'iquest' ;N: 191),
  (S: 'iuml'   ;N: 239),
  (S: 'laquo'  ;N: 171),
  (S: 'lt'     ;N: 151),
  (S: 'macr'   ;N: 175),
  (S: 'micro'  ;N: 181),
  (S: 'middot' ;N: 183),
  (S: 'nbsp'   ;N: 157),
  (S: 'nbsp'   ;N: 160),
  (S: 'not'    ;N: 172),
  (S: 'ntilde' ;N: 241),
  (S: 'oacute' ;N: 243),
  (S: 'ocirc'  ;N: 244),
  (S: 'ograve' ;N: 242),
  (S: 'ordf'   ;N: 170),
  (S: 'ordm'   ;N: 186),
  (S: 'oslash' ;N: 248),
  (S: 'otilde' ;N: 245),
  (S: 'ouml'   ;N: 246),
  (S: 'para'   ;N: 182),
  (S: 'plusmn' ;N: 177),
  (S: 'pound'  ;N: 163),
  (S: 'quot'   ;N: 154),
  (S: 'raquo'  ;N: 187),
  (S: 'reg'    ;N: 174),
  (S: 'sect'   ;N: 167),
  (S: 'shy'    ;N: 173),
  (S: 'sup1'   ;N: 185),
  (S: 'sup2'   ;N: 178),
  (S: 'sup3'   ;N: 179),
  (S: 'szlig'  ;N: 223),
  (S: 'thorn'  ;N: 254),
  (S: 'times'  ;N: 215),
  (S: 'uacute' ;N: 250),
  (S: 'ucirc'  ;N: 251),
  (S: 'ugrave' ;N: 249),
  (S: 'uml'    ;N: 168),
  (S: 'uuml'   ;N: 252),
  (S: 'yacute' ;N: 253),
  (S: 'yen'    ;N: 165),
  (S: 'yuml'   ;N: 255));

{
function SpecSearch(const Key: String; var Index: Integer): Boolean;
var
  L, H, I: Integer;
  C: CompareType;
begin
  Search := False;
  L := 0;
  H := SpecCnt - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := CompString(Specials[i], Key);
    if C = Less then L := I + 1 else
    begin
      H := I - 1;
      if C = Equal then
      begin
        Search := True;
        L := I;
      end;
    end;
  end;
  Index := L;
end;

}
 var
  F: File;
 begin
  assign(F, 'spec.bin');
  rewrite(F, 1);
  BlockWrite(F, Specials, SizeOf(Specials));
  Close(F);
 end.

