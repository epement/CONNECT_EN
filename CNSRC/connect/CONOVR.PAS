unit ConOvr;

interface

const
  ovUseMem = 1;
  ovBufInUMB = 2;
  ovHeapUMB = 4;

  ovEMSOnly = 0;
  ovXMSOnly = 1;
  ovEMSOver = 2;
  ovXMSOver = 3;

  ovLoadAll = 0;
  ovLoadSeg = 1;

  OvrSignature: Longint = $504F564F {'OVOP'} ;
  ovMem: Byte = ovUseMem;
  ovPref: Byte = ovXMSOver;
  ovLoad: Byte = ovLoadSeg;
  ovBufSize: Longint = 105000;

implementation

end.