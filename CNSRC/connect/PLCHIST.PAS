{$F+,O+,X+}
unit PlcHist;

interface

uses Views, FEditor;

procedure PlaceMarkerDlg(Caller: PView; SendCtrlQ: Boolean);

implementation

uses Objects, Drivers, App, HistList, HistWin, HeapUMB, TPString,
  Consts, Commands;

procedure PlaceMarkerDlg(Caller: PView; SendCtrlQ: Boolean);
const
  PlaceHistoryID = 199;
var
  C: Char;
  PS: PString;
  P: PHistoryRec;
  W: PSpecialHistWindow;
  R: TRect;
  S: String;
begin
  for C := '9' downto '0' do
  begin
    PS := Message(Caller, evBroadcast, cmGetMarkerLine, Pointer(C));
    if PS <> nil then
    begin
      S := PS^;
{
      GetMem(P, SizeOf(THistoryRec));
      P^.StrPtr := NewStr(Trim(PS^));
}
      GetMemUMB(P, SizeOf(THistoryRec));
      P^.StrPtr := NewStrUMB(Trim(S));
      P^.Id := PlaceHistoryId;
      Char(P^.Lock) := C;
      HistoryList^.Insert(P);
    end;
  end;

  C := #0;
  S := 'Place markers';
  GetHistWinBounds(PlaceHistoryID, S, R);
  W := New(PSpecialHistWindow, Init(R, PlaceHistoryID));
  DisposeStr(W^.Title);
  W^.Title := NewStr(S);
  W^.Options := W^.Options or ofCentered;
  W^.HelpCtx := hcPlaceMarkerDlg;

  if Application^.ValidView(W) <> nil then
  begin
    if Desktop^.ExecView(W) = cmOk then
    begin
      P := HistoryRec(PlaceHistoryID, W^.Viewer^.Focused);
      if P <> nil then C := Char(P^.Lock);
    end;
    Dispose(W, Done);
  end;

  ClearHistoryId(PlaceHistoryId);

  if C in ['0'..'9'] then
  begin
    if SendCtrlQ then Message(Caller, evKeyDown, Byte(^Q), nil);
    Message(Caller, evKeyDown, Byte(C), nil);
  end;
end;

end.