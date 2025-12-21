# Фильтр для работы с BSA
# для работы с этим фильтром нужно запускать
# bsa -l -r ARCH.BSA

BEGIN{
      Brk = "------------------------------";
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
    N = split($0, A, "/");
    FName = A[1];
    for(i=2; i <= N; i++) FName = FName"\\"A[i];
    getline;
    FSize = substr($0, 1, 25);
    FDate = substr($0, 44, 8);
    FTime = substr($0, 53, 8);
    print FName" "sprintf("%g",FSize)" "FDate" "FTime;
  }
}
