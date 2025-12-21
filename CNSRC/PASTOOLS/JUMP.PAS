Unit Jump;
{$F+}
interface
procedure SetJump;
{
  Устанавливает	точку возврата по LongJump. Возможно до	10 вложенных
  вызовов.
}

procedure LongJump;
{
 Приводит к выходу из процедуры, в которой был установлен SetJump
}
implementation
{$L jump.obj}
 procedure SetJump;external;
 procedure LongJump;external;
end.
