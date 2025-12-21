uses LDist, Strings;
var
 S1, S2: array[0..255] of char;
 threshold, dist: integer;

begin
 WriteLn('Returns ''Levenstein Distance'' of two strings on command line.');
 if ParamCount < 2 then
  begin
   WriteLn('Error, not enough arguments');
   WriteLn('Usage: LDIST2 str1 str2');
   Halt(1)
  end;

 StrPCopy(S1, ParamStr(1));
 StrPCopy(S2, ParamStr(2));
 Writeln('Determining Distance for ', S1, 'and ', S2);
 Write('Words are ');
 if not is_alike(s1, s2, threshold, dist) then Write('not ');
 WriteLn('alike, L Distance is ', dist, ', Threshold was ', threshold);
end.
