unit CNWinPos;

interface

uses WinPos;

const
  MMapWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  CodeWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  DumpWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  CharWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  CalcWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  CalnWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  CDPlWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  ClipWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  WatcWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  OutpWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  MesgWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  TermWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  BackWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);
  HelpWinPos: TWinPosRec = (AX: 0.0; AY: 0.0; BX: 0.0; BY: 0.0);

  NumWinPos = 14;

  wpMMap = $0001;
  wpCode = $0002;
  wpDump = $0004;
  wpChar = $0008;
  wpCalc = $0010;
  wpCaln = $0020;
  wpCDPl = $0040;
  wpClip = $0080;
  wpWatc = $0100;
  wpOutp = $0200;
  wpMesg = $0400;
  wpTerm = $0800;
  wpBack = $1000;
  wpHelp = $2000;
{ added 04.02.26 to support optional new-style frame top icons }
  wpLeftClickCloses = $4000;
  wpIcons = $8000;

  WinPosMask: Word = 0;

implementation

end.