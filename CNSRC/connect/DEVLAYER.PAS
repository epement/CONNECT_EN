{$I APDEFINE.INC}
{$F-,O-}
unit DevLayer;

interface

const
  dlUART = 0;
  dlInt14 = 1;
  dlFossil = 2;
  dlDigi14 = 3;
  DefDeviceLayer = $FF;
  OldLayer: Byte = DefDeviceLayer;
  DeviceLayer: Byte = DefDeviceLayer;

procedure InitDeviceLayer;

implementation

uses APPort
{$IFDEF UseUart}
   , ApUART
{$ENDIF}
{$IFDEF UseInt14}
   , ApInt14
{$ENDIF}
{$IFDEF UseFossil}
   , ApFossil
{$ENDIF}
{$IFDEF UseDigi14}
   , ApDigi14
{$ENDIF};

procedure InitDeviceLayer;
var
  I: Integer;
begin
  if DeviceLayer = OldLayer then Exit;
  for I := 1 to MaxActivePort do DonePort(ActiveComPort[I]);
  OldLayer := DeviceLayer;
  case DeviceLayer of
{$IFDEF UseUart}
    dlUART: InitApUART;
{$ENDIF}
{$IFDEF UseInt14}
    dlInt14: InitApInt14;
{$ENDIF}
{$IFDEF UseFossil}
    dlFossil: InitApFossil;
{$ENDIF}
{$IFDEF UseDigi14}
    dlDigi14: InitApDigi14;
{$ENDIF}
  end;
end;

end.