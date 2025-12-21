(********************************************************************

         VOLTEST.PAS  for testing VOL.TPU   Vernon E. Davis

 ********************************************************************)

Program VOLTEST;
Uses
   CRT,DOS,VOL;

(* Type VolumeName is declared in the VOL Unit as String[11] *)
(* Type Drive is declared in the VOL Unit as Byte *)

Var
   sel : Byte;

(*********************************************************************)
(*                                                                   *)
(*                       INTERNAL FUNCTIONS                          *)
(*                                                                   *)
(*********************************************************************)

Procedure PRESSKEY;
Var
   ch : Char;
Begin
   Write('Press any key ...');
   ch := ReadKey;
   If ch = #0 Then ch := ReadKey;
   Writeln
End;

Function GETKEY(max : Byte) : Byte;
Var
   ch : Char;
Begin
   Repeat
      ch := UpCase(ReadKey);
      If ch = #27 Then
      Begin
         GETKEY := 0;
         Exit
      End
   Until (ch >= 'A') OR (ch <= Chr(max+64));
   Write(ch);
   GETKEY := Ord(ch) - 64
End;

(*********************************************************************)
(*                                                                   *)
(*                      VOLUME LABEL FUNCTIONS                       *)
(*                                                                   *)
(*********************************************************************)


Procedure AV;
Var
   so,
   st  : VolumeName;
   dr  : Drive;
Begin
   Writeln;
   Writeln;
   Write('Press the Drive Letter ( or Esc ) => ');
   dr := GETKEY(26);
   If dr = 0 Then Exit;
   Writeln(':');
   Write('Enter the New Volume Label (11 Characters Max) => ');
   Readln(st);
   If Length(st) = 0 Then Exit;
   Writeln;
   If ADDVOL(dr,st) Then
      Writeln('New Volume Label Added.')
   Else
      Writeln('ERROR in Adding New Volume Label.');
   Writeln;
   PRESSKEY
End;

Procedure CV;
Var
   so,
   st  : VolumeName;
   dr  : Drive;
Begin
   Writeln;
   Writeln;
   Write('Press the Drive Letter ( or Esc ) => ');
   dr := GETKEY(26);
   If dr = 0 Then Exit;
   Writeln(':');
   Writeln;
   so := GETVOL(dr);
   If Length(so) = 0 Then
   Begin
      Writeln('ERROR in Reading Volume Label or no Volume Label found.');
      Writeln;
      PRESSKEY;
      Exit
   End;
   Writeln('Old Volume Label is ',so);
   Write('Enter the New Volume Label (11 Characters Max) => ');
   Readln(st);
   If Length(st) = 0 Then Exit;
   Writeln;
   If CHGVOL(dr,st) Then
      Writeln('Volume Label Changed.')
   Else
      Writeln('ERROR in Changing Volume Label.');
   Writeln;
   PRESSKEY
End;

Procedure DV;
Var
   dr  : Drive;
Begin
   Writeln;
   Writeln;
   Write('Press the Drive Letter ( or Esc ) => ');
   dr := GETKEY(26);
   If dr = 0 Then Exit;
   Writeln(':');
   If DELVOL(dr) Then
      Writeln('Volume Label Deleted.')
   Else
      Writeln('ERROR in Deleting Volume Label.');
   Writeln;
   PRESSKEY
End;

Procedure GV;
Var
   st  : VolumeName;
   dr  : Drive;
Begin
   Writeln;
   Writeln;
   Write('Press the Drive Letter ( or Esc ) => ');
   dr := GETKEY(26);
   If dr = 0 Then Exit;
   Writeln(':');
   st := GETVOL(dr);
   If Length(st) > 0 Then
      Writeln('Volume Label is ',st)
   Else
      Writeln('ERROR in Reading Volume Label or no Volume Label found.');
   Writeln;
   PRESSKEY
End;

(*********************************************************************)
(*                                                                   *)
(*                          MAIN PROGRAM                             *)
(*                                                                   *)
(*********************************************************************)

Begin
   Repeat
      ClrScr;
      Writeln('VOLTEST   v1.00   Vernon E. Davis');
      Writeln('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      Writeln('    A. Add Volume Name');
      Writeln('    B. Change Volume Name');
      Writeln('    C. Delete Volume Name');
      Writeln('    D. Get Volume Name');
      Writeln('    E. (or Esc) = QUIT');
      Writeln('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
      Writeln;
      Write('Press the Proper Letter => ');
      sel := GETKEY(5);
      Case sel of
      1 : AV;
      2 : CV;
      3 : DV;
      4 : GV
      End
   Until (sel = 5) OR (sel = 0)
End.
