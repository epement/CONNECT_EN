{$A-,B-,D+,E+,F+,G-,I-,L+,N+,O-,P-,Q-,R-,S-,T-,V-,X+}
{$M 16384,0,655360}

program CalcTst;
uses
 StrCalc;
var
 S : String;
 begin
  if ParamCount = 0 then
  begin
   CalcStrInit;
   repeat
    Readln(S);
    WriteLn(CalcStr(S));
   until (S='') or eof;
   CalcStrDone;
  end
  else
   begin
    S := ParamStr(1);
    if Pos('/h',S) + Pos('/H',S) + Pos('/?',S) = 0 then WriteLn(CalcStr(S))
    else
     begin
      WriteLn('');
      WriteLn('Command Line Calculator Copyright by Orlov D., 2:461/27, (C) 1994');
      WriteLn('');
      WriteLn('Калькулятор умеет выполнять следующие действия над вещественными и');
      WriteLn('целыми числами. Шестнадцатиричные числа вводятся с префиксом $.');
      WriteLn('Определена константа Pi = 3.1415926535');
      WriteLn('Вычисляется либо выражение, заданное в командной строке, либо, если');
      WriteLn('она не задана, введенное с клавиатуры до первой пустой строки.');
      WriteLn('');
      WriteLn('^                     - Возведение в степень');
      WriteLn('/, *                  - Деление, умножение');
      WriteLn('%                     - Целочисленное деление');
      WriteLn('-, +                  - Вычитание, сложение');
      WriteLn('');
      WriteLn('Доступны следующие функции.');
      WriteLn('');
      WriteLn('ARCCOS, ARCSIN, ARCTG - Результат в радианах');
      WriteLn('SING                  - Синус от угла в градусах');
      WriteLn('SIN                   - Синус от угла в радианах');
      WriteLn('COSG                  - Косинус от угла в градусах');
      WriteLn('COS                   - Косинус от угла в радианах');
      WriteLn('CTGG                  - Котангенс от угла в градусах');
      WriteLn('CTG                   - Котангенс от угла в радианах');
      WriteLn('TGG                   - Тангенс от угла в градусах');
      Write('Press ENTER to continue');
      ReadLn;
      WriteLn('TG                    - Тангенс от угла в радианах');
      WriteLn('SQRT                  - Квадратный корень');
      WriteLn('LG                    - Десятичный логарифм');
      WriteLn('LN                    - Натуральный логарифм');
      WriteLn('EXP10                 - 10 в степени');
      WriteLn('EXP                   - Экспонента');
      WriteLn('ABS                   - Абсолютное значение');
     end;
   end;
 end.
