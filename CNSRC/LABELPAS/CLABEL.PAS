Program CLabel;
{
  A program to change the labels on a disk.
  Copyright (c) 1991 by C&M Enterprises
  Programmer: Charlie Calvert
}
Uses
  Crt,
  Dos,
  Labels;


Procedure TellHow;
  Begin
    ClrScr;
    WriteLn('CLabel.Exe copyright (c) 1991 C&M Enterprises.');
    WriteLn('Programmer: Charlie Calvert. Compuserve 71601,1224.');
    WriteLn('This program is freeware.');
    WriteLn('Feel free to give away unmodified versions of this program.');
    WriteLn;
    WriteLn('Use this program to relabel disks.');
    WriteLn('Synatax: Label [Drive:][Label]');
    WriteLn('Syntax translation:');
    WriteLn('To relabel the current drive enter the ');
    WriteLn('new drive name as a single argument.');
    WriteLn;
    WriteLn('Example:');
    WriteLn('  CLabel NewName');
    WriteLn('(This command would give the current drive the label NewName.)');
    WriteLn;
    WriteLn('To rename a drive other than the current drive specify');
    WriteLn('the drive letter followed by a colon and the new name.');
    WriteLn;
    WriteLn('Example:');
    WriteLn('  CLabel a:NewName');
    WriteLn;
    WriteLn('(This command would rename the disk in drive A.)');
    Halt(1);
  End;

Var
  Drv : Char;
  Labl : Str20;
  CmdLine: String;
  begin
    if (ParamCount < 1) or (ParamCount > 1) then TellHow;
    CmdLine := ParamStr(1);
    if Length(CmdLine) > 13 then begin
      WriteLn('Labels can be only 11 characters in length.');
      Halt(1);
    end;
    if not GetLabelandDrive(CmdLine,Labl,Drv) then begin
       WriteLn('Invalid Drive Specification');
       Halt(1);
    end;
    if SetLabel(Drv,Labl) then WriteLn('Worked') else WriteLn('Error');
    WriteLn(GetLabel(Drv));
  end.