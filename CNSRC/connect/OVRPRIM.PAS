{$I-,F+,O-,X+}
unit OvrPrim;

interface

implementation

uses Overlay, Objects, Streams, ConOvr, OvrUMB;

procedure OvrInitEMSPrim;
var
  OvrSize: Longint;
  OvrStream: PStream;
begin
  if ovLoad = ovLoadAll then OvrInitEMS
  else
  begin
    OvrSize := OvrSizeNeeded;
    OvrStream := New(PEMSStream, Init(OvrSize, OvrSize));
    if OvrStream^.Status <> stOk then
    begin
      Dispose(OvrStream, Done);
      OvrResult := -1;
      Exit;
    end;
    OvrInitStream(OvrStream);
    OvrEMSHandle := PEMSStream(OvrStream)^.Handle;
  end;
end;

procedure OvrInitXMSPrim;
var
  OvrSize: Longint;
  OvrStream: PStream;
begin
  OvrSize := OvrSizeNeeded;
  OvrStream := New(PXMSStream, Init(OvrSize, OvrSize));
  if OvrStream^.Status <> stOk then
  begin
    Dispose(OvrStream, Done);
    OvrResult := -1;
    Exit;
  end;
  OvrInitStream(OvrStream);
  if ovLoad = ovLoadAll then if not OvrLoadAll then OvrDisposeStreams;
end;

procedure OvrInitMemPrim;
begin
  case ovPref of
    ovEMSOnly, ovEMSOver: OvrInitEMSPrim;
    ovXMSOnly, ovXMSOver: OvrInitXMSPrim;
  end;
  if OvrResult <> ovrOk then case ovPref of
    ovEMSOver: OvrInitXMSPrim;
    ovXMSOver: OvrInitEMSPrim;
  end;
  OvrResult := ovrOk;
end;

begin
  OvrFileMode := 64;
  OvrInit(ParamStr(0));
  OvrSetBuf(ovBufSize);
  OvrSetRetry(ovBufSize div 3);
  if ovMem and ovBufInUMB <> 0 then OvrInitUMBBuf;
  if ovMem and ovUseMem <> 0 then OvrInitMemPrim;
end.