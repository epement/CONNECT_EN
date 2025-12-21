unit RGBColor;

interface

function IsVGA: Boolean;
procedure GetRGBColor(ColorNum: Integer;
  var RedValue, GreenValue, BlueValue: Byte);
procedure SetRGBColor(ColorNum: Integer;
  RedValue, GreenValue, BlueValue: Byte);
procedure GetRGBPalette(Palette: Pointer; Count: Integer);
procedure SetRGBPalette(Palette: Pointer; Count: Integer);

implementation

uses Detect, Defaults;

function IsVGA: Boolean;
var
  GraphDriver, GraphMode: Integer;
begin
  if DisableVGAPalette then IsVGA := False
  else
  begin
    DetectGraph(GraphDriver, GraphMode);
    IsVGA := GraphDriver = VGA;
  end;
end;

procedure GetRGBColor(ColorNum: Integer;
  var RedValue, GreenValue, BlueValue: Byte); assembler;
asm
        MOV      AX,1007H
        MOV      BX,ColorNum
        INT      10H
        MOV      AX,1015H
        MOV      BL,BH
        XOR      BH,BH
        INT      10H
        LES      DI,RedValue
        MOV      BYTE PTR ES:[DI],DH
        LES      DI,GreenValue
        MOV      BYTE PTR ES:[DI],CH
        LES      DI,BlueValue
        MOV      BYTE PTR ES:[DI],CL
end;

procedure SetRGBColor(ColorNum: Integer;
  RedValue, GreenValue, BlueValue: Byte); assembler;
asm
        MOV      AX,1007H
        MOV      BX,ColorNum
        INT      10H
        MOV      AX,1010H
        MOV      BL,BH
        XOR      BH,BH
        MOV      DH,RedValue
        MOV      CH,GreenValue
        MOV      CL,BlueValue
        INT      10H
end;

procedure GetRGBPalette(Palette: Pointer; Count: Integer); assembler;
asm
@@1:    MOV      DX,3DAH
        IN       AL,DX
        AND      AL,8
        OR       AL,AL
        JNE      @@1
@@2:    MOV      DX,3DAH
        IN       AL,DX
        AND      AL,8
        OR       AL,AL
        JE       @@2
        MOV      AX,1017H
        LES      DX,DWORD PTR Palette
        MOV      BX,0
        MOV      CX,Count
        INT      10H
end;

procedure SetRGBPalette(Palette: Pointer; Count: Integer); assembler;
asm
@@1:    MOV      DX,3DAH
	IN       AL,DX
	TEST     AL,8
	JE       @@1
@@2:    MOV      DX,3DAH
	IN       AL,DX
	TEST     AL,8
	JNE      @@2
	MOV      AX,1012H
	LES      DX,DWORD PTR Palette
	MOV      BX,0
	MOV      CX,Count
	INT      10H
end;

end.
