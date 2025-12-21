# Фильтр для работы с SQZ
# для работы с этим фильтром нужно запускать
# sqz v -s ARCH.SQZ

BEGIN{
      Flag = 0;
     }
# Main body
{
 if ((Flag == 0)&&(index($0, "------------") != 0))
  {
   Flag = 1;
   next;
  }
 if (Flag == 1)
  {
    split($3, Date, "/");
    print $1" "$2" "Date[2]"-"Date[3]"-"Date[1]" "$4;
  }
}