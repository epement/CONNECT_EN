Unit Jump;
{$F+}
interface
 procedure SetJump;
 procedure LongJump;
implementation
{$L jump.obj}
 procedure SetJump;external;
 procedure LongJump;external;
end.
