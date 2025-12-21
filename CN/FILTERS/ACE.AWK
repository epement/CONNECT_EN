# Фильтр для работы с архиватором ACE
# для работы с этим фильтром нужно запускать
# ACE L ARCH.ACE
#
# P.S. И что только под новый год не напишешь... ;-)
# 01-01-98г. 03:26:07
# Andy Shevchenko 2:461/73.55
# AKA "King-Kong"


BEGIN{
      Brk = "Date    │";
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
    if ($0 =="") exit;
    FName = substr($0, 45);
    FSize = substr($0, 28, 9);
    FDate = substr($0, 1, 2);
    FMont = substr($0, 4, 2);
    FYear = substr($0, 7, 2);
    FTime = substr($0, 10, 5);
    print FName" "FSize" "FMont"-"FDate"-"FYear" "FTime
  }
}
