# Фильтр для работы с UC2
# для работы с этим фильтром нужно запускать
# uc ~D ARCH.UC2

 function GetName(S)
 {
  gsub(/(.*\[)|(\])/, "", S);
  return S;
 }

 function GetVal(S)
 {
  gsub(/.*=/, "", S);
  return S;
 }

 function DateTime()
 {
   getline;
   Date = GetVal($0);
   split(Date, ADate);
   Date = ADate[1]"-"ADate[2]"-"(ADate[3]-1900);
   getline;
   Time = GetVal($0);
   split(Time, ATime);
   Time = ATime[1]":"ATime[2]":"ATime[3];
   return Date" "Time;
 }

/LIST \[.+\]/ {
              Dir = substr(GetName($0),2);
              }
/ +DIR$/      {
               getline;
               Name = GetName($0);
               print Dir""Name"\\"
              }
/ +FILE$/     {
               getline;
               Name = GetName($0);
               getline;
               getline;
               Size = GetVal($0);
               DT = DateTime();
               print Dir""Name" "Size" "DT;
              }
