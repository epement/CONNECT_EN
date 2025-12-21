Unit Labels;

Interface
Uses
  Crt,
  Dos;

type
  Str20 = String[20];
  Char5   = array[0..4] of Char;
  Char8   = array[0..7] of Char;
  Char9   = array[0..8] of Char;
  Char11  = array[0..10] of Char;

Type
  PDTA = ^DTA;
  DTA = Record
    Res1 : Char8;
    OldVolid : Char11;
    Res2 : Char5;
    NewVolid : Char11;
    Res3 : Char9;
  End;

  VolFCB = Record
    ExtCode : Byte;
    Reserved : Char5;
    Code : Byte;
    OldDrive : Byte;
    OldName : Char11;
    Reserved2 : Char5;
    NewName : Char11;
    Reserved3 : Char9;
  End;


var
  VFCB : VolFCB;
  MyDTA : DTA;


Function GetLabel(DriveLetter : Char) : String;
Function SetLabel(DriveLetter : Char; ALabel : String): Boolean;
Function GetLabelAndDrive(CmdLine: String; var Labl: Str20; var DriveLetter : Char): Boolean;
Implementation

procedure Beep(Freq, Time : Integer);
begin
  Sound(Freq);
  Delay(Time);
  NoSound;
end;

Procedure SetUpVFCB;
{Use with SetLabel and GetLabel}
  Begin
    VFCB.ExtCode := $0FF;
    FillChar(VFCB.Reserved,5,#0);
    VFCB.Code := $08;
    VFCB.OldDrive := 0;
    FillChar(VFCB.OldName,11,'?');
  End;

Function GetLabel(DriveLetter : Char) : String;
{
  Function for getting volume label from a disk.
}
var
  Regs : Registers;
  ErrorCode : Integer;
  S         : String;
  Drive     : Byte;
  Begin
    SetUpVFCB;
    Drive := ord(DriveLetter) - 64;
    Regs.dx := Ofs(MyDta);
    Regs.ds := Seg(MyDta);
    Regs.ah := $1A;
    intr($21,Regs);

    VFCB.OldDrive := Drive;

    Regs.dx := Ofs(VFCB);
    Regs.ds := Seg(VFCB);
    Regs.ah := $11;
    intr($21,Regs);

    ErrorCode := Regs.al;
    if ErrorCode = 0 then begin
       Move(MyDta.OldVolid,S[1],11);
       S[0] := #11;
       GetLabel := S;
    end else begin
       Beep(100,100);
       GetLabel := '';
    End;
  End;

Function SetLabel(DriveLetter : Char; ALabel : String): Boolean;
{Function for setting a label on a disk }
var
  Regs : Registers;
  i    : Integer;
  Errorcode : Integer;
  Volid     : Char11;
  Drive     : Byte;

  Function DoNoLabel(var Volid : Char11): Boolean;
  var
    j : Integer;
  Begin
    for j := 0 to 10 do begin
      if (ALabel = '') then
         VFCB.OldName[j] := #32
      else
         VFCB.OldName[j] := Volid[j];
    end;
    Regs.dx := Ofs(VFCB);
    Regs.ds := Seg(VFCB);
    Regs.ah := $16;
    intr($21,Regs);
    ErrorCode := Regs.al;
    if ErrorCode = 0 then
      DoNoLabel := True
    else
      DoNoLabel := False;
  End;

  Begin
    SetUpVFCB;
    Drive := ord(DriveLetter)-64;
    FillChar(Volid,11,#32);
    Move(ALabel[1], Volid, Ord(ALabel[0]));
    if GetLabel(DriveLetter) = '' then
      SetLabel := DoNoLabel(Volid)
    else Begin
      for i := 0 to 10 do begin
        if ALabel = '' then MyDta.NewVolid[i] := ' '
      else
          MyDta.NewVolid[i] := Volid[i];
      End;
      Regs.dx := Ofs(MyDta);
      Regs.ds := Seg(MyDta);
      Regs.ah := $17;
      intr($21,Regs);
      ErrorCode := Regs.al;
      if Errorcode = 0 then SetLabel := True
      else SetLabel := False;
    End;
  End;

Function GetLabelAndDrive(CmdLine: String; var Labl: Str20; var DriveLetter : Char): Boolean;
{If there's an error, then  tell the user Invalid Drive Specification}
Var
  WhichDrive : String;
  i : Byte;
   Begin
     whichdrive:='';
     GetLabelAndDrive := False;
     if length(cmdline) < 2 then Exit;
     whichdrive:=copy(cmdline,1,2);
     if (whichdrive[2] <> ':') or
        (not (upcase(whichdrive[1]) in ['A'..'Z'])) then Exit;
     for i := 2 to paramcount do
       cmdline:=cmdline+' '+paramstr(i);
     labl:=copy(cmdline,3,11);
     DriveLetter := UpCase(whichdrive[1]);
     GetLabelAndDrive := True;
  End;
End.