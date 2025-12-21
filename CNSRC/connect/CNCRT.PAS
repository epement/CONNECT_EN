{$I-,F+,O+,X+}
unit CNCrt;

interface

function KeyPressed: Boolean;
function ReadKey: Char;
procedure DelayInit;
procedure Delay(MS: Word);
procedure Sound(Hz: Word);
procedure NoSound;

implementation

{$L CNCRT.OBJ}

procedure DelayInit; external;
function KeyPressed; external;
function ReadKey; external;
procedure Delay; external;
procedure Sound; external;
procedure NoSound; external;

end.
