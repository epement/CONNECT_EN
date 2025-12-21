# Фильтр для работы с UC2
# для работы с этим фильтром нужно запускать
# uc V -S ARCH.UC2

BEGIN{
      DirSign = "Directory of \\";
      split("JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC", Mounths);
      Flag = 0;
     }
# Main body
{
 if ($0 ~ /files listed/) exit;
 Pos = index($0, DirSign);
 if (Pos != 0)
  {
   Dir = substr($0, Pos + length(DirSign));
   Flag = 1;
  }
 else
  if (Flag != 0)
   {
    FSize = substr($0, 14, 13);
    if (FSize ~ /([0-9]+)|(.*<DIR>.*)/)
     {
      FName = substr($0, 1, 8);
      if (FName == "") next;
      FExt = substr($0, 10, 3);
      A[1] = ""; A[2] = ""; split(FName" "FExt, A);
      if (A[2] != "") FNameExt = Dir""A[1]"."A[2]
      else FNameExt = Dir""A[1];
      if (FSize !~ /.*<DIR>.*/)
       {
        FMonth = substr($0, 28, 3);
        i = 1; while(FMonth != Mounths[i]) i++; FMonth = i;
        FDate = FMonth"-"substr($0, 32, 2)"-"substr($0, 37, 2);
        FTime = substr($0, 41, 8);
        print FNameExt" "sprintf("%g",FSize)" "FDate" "FTime;
       }
      else print FNameExt"\\";
     }
   }
}
