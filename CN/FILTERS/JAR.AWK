# Фильтр для работы с JAR
# для работы с этим фильтром нужно запускать
# JAR v ARCH.J

BEGIN{
      Brk = "---------- -----";
      Flag = 0;
     }
# Main body
{
 if ((Flag == 0)&&(index($0, Brk) != 0))
  {
   Flag = 1;
   next;
  }
 if (Flag == 1)
  {
    if (index($0, Brk) != 0) exit;
    if (match($1, "[0-9]+\)") == 0) exit;
    FName = $2;
    getline;
    FSize = $1;
    FYear = substr($0, 43, 2);
    FDate = substr($0, 46, 5);
    FTime = substr($0, 52, 8);
    Dir = substr($0, 16, 1);
    getline;
    if (Dir == "D") print FName"\ "FSize" "FDate"-"FYear" "FTime
    else print FName" "FSize" "FDate"-"FYear" "FTime
  }
}
