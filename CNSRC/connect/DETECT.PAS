{$F+,O+,X+}
unit Detect;

interface

const
  VGA = 9;
  grError = 11;

procedure DetectGraph(var Gd, Gm: Integer);

implementation

{$L detect.obj}

procedure DetectGraph(var Gd, Gm: Integer); external;

end.
