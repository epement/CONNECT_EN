# Фильтр для работы со списками файлов, полученными командой ls -lR
# в юниксе вида:
# ./pub:
# total 106
# drwxr-xr-x   7 fredm    system      8192 Mar  2 08:33 6270
# drwxr-xr-x   7 fredm    system      8192 Mar  6 18:59 6811
# -rw-r--r--   1 root     system      1812 Jan 18  1994 README
# drwxr-xr-x   2 root     system      8192 Feb 14 12:13 starlogo
# drwxrwxrwx   2 root     system      8192 Oct  3 14:11 trellos
#  или
# pub:
# total 106
# drwxr-xr-x   7 fredm    system      8192 Mar  2 08:33 6270
# drwxr-xr-x   7 fredm    system      8192 Mar  6 18:59 6811
# -rw-r--r--   1 root     system      1812 Jan 18  1994 README
# drwxr-xr-x   2 root     system      8192 Feb 14 12:13 starlogo
# drwxrwxrwx   2 root     system      8192 Oct  3 14:11 trellos
#
#Modify user defined Archiver setup|View command:
#
# type $ARC $Msg($Cn\Mawk\mawk -f $Cn\Filters\ls.awk)
{
 if (substr($0,length($0),1)==":")
  {
   if (substr($0, 1, 1) == ".") Dir = substr($0, 3, length($0)-3)"/"
   else Dir = substr($0, 1, length($0)-1)"/"
  }
 if (substr($0, 1, 1) == "-") print Dir $9  " "$5
}

