{$F-,O-,X+}
unit UserScr;

interface

uses Objects;

type
  PUserScreen = ^TUserScreen;
  TUserScreen = Array[0..1] of Word;

const
  EGALinesOn: Boolean = False;
  EnhancedPaletteOn: Boolean = False;
  RestoreVideoMode: Boolean = True;
  XVideoMode: Byte = 0;

  UserScreenBuffer: PUserScreen = nil;

var
  Equipment: Word absolute $40:$87;
  UserScreenBufSize: Word;
  UserScreenCols, UserScreenRows: Byte;
  SaveCursorPos: TPoint;

procedure InitUserScreenBuffer;
procedure DoneUserScreenBuffer;
procedure InitUserScreen;
procedure DoneUserScreen;
procedure GetUserScreen;
procedure RestoreUserScreen;
procedure UserScreen;

function GetCursorState: Word;
procedure SetCursorState(AState: Word);
procedure GetCursorPos(var APos: TPoint);
procedure SetCursorPos(APos: TPoint);
procedure SetDefaultCursor;
procedure FixPalette;
procedure SetMouseCursor(X, Y: Integer);
procedure ResetMouse;
procedure RefreshDisplay;

implementation

uses Drivers, Views, Memory, App, ScrPrim, HeapUMB, Commands;

function GetCursorState: Word; assembler;
asm
	MOV      AH,3
	XOR      BH,BH
	INT      10H
	MOV      AX,CX
end;

procedure SetCursorState(AState: Word); assembler;
asm
	MOV      AH,1
	XOR      BH,BH
	MOV      CX,AState
	INT      10H
end;

procedure SetDefaultCursor;
begin
  SetCursorState(DefaultCursor);
end;

procedure GetCursorPos(var APos: TPoint); assembler;
asm
	MOV     AH,3
	XOR     BH,BH
	INT     10H
	XOR	AL,AL
	LES     DI,[BP+6]
	MOV     ES:[DI],DL
	MOV     ES:[DI+1],AL
	MOV     ES:[DI+2],DH
	MOV     ES:[DI+3],AL
end;

procedure SetCursorPos(APos: TPoint); assembler;
asm
	MOV     AH,2
	XOR     BH,BH
	MOV     DL,BYTE PTR APos
	MOV     DH,BYTE PTR APos+2
	INT     10H
end;

procedure FixPalette; assembler;
asm
	MOV      AX,1003H
	MOV      BL,EnhancedPaletteOn
	XOR      BL,1
	INT      10H
end;

procedure InitUserScreenBuffer;
begin
  DoneUserScreenBuffer;
  UserScreenBufSize := ScreenWidth * ScreenHeight * 2;
  if MaxAvail > UserScreenBufSize + $2000 then
{    GetMem(UserScreenBuffer, UserScreenBufSize);}
    GetMemUMB(UserScreenBuffer, UserScreenBufSize);
end;

procedure DoneUserScreenBuffer;
begin
  if UserScreenBuffer <> nil then
  begin
{    FreeMem(UserScreenBuffer, UserScreenBufSize);}
    FreeMemUMB(UserScreenBuffer, UserScreenBufSize);
    UserScreenBuffer := nil;
  end;
end;

procedure InitUserScreen;
begin
  GetUserScreenProc := @GetUserScreen;
  PutUserScreenProc := @RestoreUserScreen;
end;

procedure DoneUserScreen;
begin
  DoneUserScreenBuffer;
end;

procedure GetUserScreen;
begin
  UserScreenCols := ScreenWidth;
  UserScreenRows := ScreenHeight;
  GetCursorPos(SaveCursorPos);
  if SaveCursorPos.Y >= ScreenHeight - 1 then
  begin
    PrintStr(#13#10);
    SaveCursorPos.Y := ScreenHeight - 2;
  end;
  InitUserScreenBuffer;
  if UserScreenBuffer <> nil then
    Move(ScreenBuffer^, UserScreenBuffer^, UserScreenBufSize);
end;

procedure FillWord(var Dest; Count, Filler: Word);
  inline(
    $58/                     {pop ax    ;AX = Filler}
    $59/                     {pop cx    ;CX = Count}
    $5F/                     {pop di    ;ES:DI => Dest}
    $07/                     {pop es}
    $FC/                     {cld       ;go forward}
    $F2/$AB);                {rep stosw ;fill memory}

procedure RestoreUserScreen;
var
  B: Boolean;
begin
  if XVideoMode <> 0 then
  begin
    SetCustomVideoMode(XVideoMode);
    if UserScreenCols <> ScreenWidth then DoneUserScreenBuffer;
  end
  else if ScreenMode <> StartupMode then SetVideoMode(StartupMode);
  B := EnhancedPaletteOn;
  EnhancedPaletteOn := False;
  FixPalette;
  EnhancedPaletteOn := B;
  if UserScreenBuffer <> nil then
    Move(UserScreenBuffer^, ScreenBuffer^, UserScreenBufSize)
  else FillWord(ScreenBuffer^, UserScreenBufSize div 2, $0720);
  SetDefaultCursor;
  SetCursorPos(SaveCursorPos);
end;

procedure UserScreen;
begin
  UserScreenPrim;
end;

procedure SetMouseCursor(X, Y: Integer);
begin
  DoneEvents;
asm
	CMP     ButtonCount,0
	JE      @@1
	MOV     AX,4
	MOV     CX,X
	MOV     DX,Y
	INT     33H
@@1:
end;
  InitEvents;
end;

procedure ResetMouse;
var
  X, Y: Integer;
begin
  DoneEvents;
  X := ScreenWidth * 8 - 1;
  Y := ScreenHeight * 8 - 1;
  asm
	CMP     ButtonCount,0
	JE      @@1
	MOV	AX,3
	INT     33H
	PUSH	CX
	PUSH	DX
	MOV     AX,21H
	INT     33H
	MOV     AX,7
	XOR     CX,CX
	MOV     DX,X
	INT     33H
	MOV     AX,8
	XOR     CX,CX
	MOV     DX,Y
	INT     33H
	MOV	AX,4
	POP	DX
	POP	CX
	INT     33H
  @@1:
  end;
  InitEvents;
end;

procedure RefreshDisplay;
begin
  ResetMouse;
  FixPalette;
  DoneMemory;
  Application^.Redraw;
end;

end.
