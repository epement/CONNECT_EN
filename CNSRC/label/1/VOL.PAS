(*************************************************************************

      VOL.PAS   v1.01    Vernon E. Davis   for Turbo Pascal v4.x  v5.x

 *************************************************************************)

Unit VOL;
Interface
Uses
   DOS;
Type
   VolFCB = Record
      FCB_flag : Byte;
      reserved : Array[1..5] of Byte;
      fileattr : Byte;
      drive_id : Byte;
      filename : Array[1..8] of Byte;
      file_ext : Array[1..3] of Byte;
      unused_1 : Array[1..5] of Byte;
      file_new : Array[1..8] of Byte;
      fext_new : Array[1..3] of Byte;
      unused_2 : Array[1..9] of Byte
   End;

   VolumeName  = String[11];
   Drive       = Byte;

(* Internal Function Declarations *)

   Function V1IVOL(sr : SearchRec) : VolumeName;
      { Internal Function : correctly spaces the Volume Name }

   Function V2IVOL(d : Byte) : Boolean;
      { Internal Function : checks for valid Drive: number }


(* User Function Declarations *)

   Function DELVOL(d : Byte) : Boolean;
      { Deletes the Volume Name from the specified Drive: }

   Function ADDVOL(d : Byte; f : VolumeName) : Boolean;
      { Adds a New Volume Name to a specified Drive: }

   Function CHGVOL(d : Byte; f : VolumeName) : Boolean;
      { Changes the Volume Name of a specified Drive: }

   Function GETVOL(d : Byte) : VolumeName;
      { Retrieves the Volume Name from the specified Drive: }


Implementation

Function V1IVOL(sr : SearchRec) : VolumeName;
Var
   h,i : Byte;
Begin
   With sr Do
   Begin
      i := Pos('.',Name);
      Case i of
      9    : Delete(Name,i,1);
      1..8 : Begin
                Delete(Name,i,1);
                For h := 1 To (9 - i) Do Insert(' ',Name,i)
             End
      End;
      V1IVOL := Name
   End
End;

Function V2IVOL(d : Byte) : Boolean;
Begin
   If (d < 1) OR (d > 26) Then
      V2IVOL := FALSE
   Else
      V2IVOL := TRUE
End;

Function DELVOL(d : Byte) : Boolean;
Var
   regs : Registers;
   srec : SearchRec;
   fcb  : VolFCB;
   i    : Byte;
   f    : VolumeName;
Begin
   If NOT V2IVOL(d) Then
   Begin
      DELVOL := FALSE;
      Exit
   End;
   FindFirst(Chr(d+64) + ':\*.*',VolumeID,srec);
   i := DosError;
   If i <> 0 Then
   Begin
      DELVOL := FALSE;
      Exit
   End;
   f := V1IVOL(srec);
   While Length(f) <> 11 Do f := f + ' ';
   With fcb Do
   Begin
      FCB_flag := $FF;
      fileattr := $08;
      drive_id := d;
      For i := 1 To 8 Do filename[i] := Ord(f[i]);
      For i := 1 To 3 Do file_ext[i] := Ord(f[i+8])
   End;
   With regs Do
   Begin
      DS := Seg(fcb);
      DX := Ofs(fcb);
      AX := $1300
   End;
   MsDos(regs);
   If regs.AL = 0 Then
      DELVOL := TRUE
   Else
      DELVOL := FALSE
End;

Function ADDVOL(d : Byte; f : VolumeName) : Boolean;
Var
   regs : Registers;
   srec : SearchRec;
   fcb  : VolFCB;
   i    : Byte;
Begin
   If NOT V2IVOL(d) Then
   Begin
      ADDVOL := FALSE;
      Exit
   End;
   FindFirst(Chr(d+64) + ':\*.*',VolumeID,srec);
   i := DosError;
   If i = 0 Then
   Begin
      ADDVOL := FALSE;
      Exit
   End;
   While Length(f) <> 11 Do f := f + ' ';
   For i := 1 To 11 Do f[i] := UpCase(f[i]);
   With fcb Do
   Begin
      FCB_flag := $FF;
      fileattr := $08;
      drive_id := d;
      For i := 1 To 8 Do filename[i] := Ord(f[i]);
      For i := 1 To 3 Do file_ext[i] := Ord(f[i+8])
   End;
   With regs Do
   Begin
      DS := Seg(fcb);
      DX := Ofs(fcb);
      AX := $1600
   End;
   MsDos(regs);
   If regs.AL = 0 Then
      ADDVOL := TRUE
   Else
      ADDVOL := FALSE
End;

Function CHGVOL(d : Byte; f : VolumeName) : Boolean;
Var
   regs : Registers;
   srec : SearchRec;
   fcb  : VolFCB;
   i    : Byte;
Begin
   If NOT V2IVOL(d) Then
   Begin
      CHGVOL := FALSE;
      Exit
   End;
   FindFirst(Chr(d+64) + ':\*.*',VolumeID,srec);
   i := DosError;
   If i <> 0 Then
   Begin
      CHGVOL := FALSE;
      Exit
   End;
   i := Pos('.',f);
   If i > 0 Then Delete(f,i,1);
   While Length(f) <> 11 Do f := f + ' ';
   For i := 1 To 11 Do f[i] := UpCase(f[i]);
   With fcb Do
   Begin
      FCB_flag := $FF;
      fileattr := $08;
      drive_id := d;
      For i := 1 To 8 Do file_new[i] := Ord(f[i]);
      For i := 1 To 3 Do fext_new[i] := Ord(f[i+8])
   End;
   f := V1IVOL(srec);
   While Length(f) <> 11 Do f := f + ' ';
   With fcb Do
   Begin
      For i := 1 To 8 Do filename[i] := Ord(f[i]);
      For i := 1 To 3 Do file_ext[i] := Ord(f[i+8])
   End;
   With regs Do
   Begin
      DS := Seg(fcb);
      DX := Ofs(fcb);
      AX := $1700
   End;
   MsDos(regs);
   If regs.AL = 0 Then
      CHGVOL := TRUE
   Else
      CHGVOL := FALSE
End;

Function GETVOL(d : Byte) : VolumeName;
Var
   srec : SearchRec;
   i    : Byte;
Begin
   If NOT V2IVOL(d) Then
   Begin
      GETVOL := '';
      Exit
   End;
   FindFirst(Chr(d+64) + ':\*.*',VolumeID,srec);
   i := DosError;
   If i <> 0 Then
   Begin
      GETVOL := '';
      Exit
   End;
   GETVOL := V1IVOL(srec)
End;

End.
