uses Filters;

var
 S, SS: String;
begin
 S := 'ERROR: file C:\Pic\m400hfl.c; line 1820; column 22; undefined identifier: dfIcap_lim';
 S := 'C:\Pic\400.c: 268: , expected (error)';
 SS := '$COPY("line ", ";"):$COPY("column ", ";")';
 SS := '$SEARCH("^.:\\[^:]*")';
 WriteLn(StringFilter(S, SS));
 SS := '$SEARCH(": ([0-9]+): ")';
 WriteLn(StringFilter(S, SS));
 SS := '$copy(": ", ": ")';
 WriteLn(StringFilter(S, SS));
end.