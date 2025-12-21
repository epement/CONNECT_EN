{$F+,O+,X+}
unit HistWin;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PHistWindow = ^THistWindow;
  THistWindow = object(THistoryWindow)
    procedure ChangeBounds(var Bounds: TRect); virtual;
    function GetPalette: PPalette; virtual;
  end;

  PSpecialHistViewer = ^TSpecialHistViewer;
  TSpecialHistViewer = object(THistoryViewer)
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PSpecialHistWindow = ^TSpecialHistWindow;
  TSpecialHistWindow = object(THistWindow)
    procedure InitViewer(HistoryId: Word); virtual;
  end;

const
  CHistWindow = #147#148#149#139#140#150#151;

procedure GetHistWinBounds(Id: Word; const Title: TTitleStr; var R: TRect);

implementation

uses App, HistList;

procedure THistWindow.ChangeBounds(var Bounds: TRect);
begin
  TWindow.ChangeBounds(Bounds);
end;

function THistWindow.GetPalette: PPalette;
const
  P: String[Length(CHistWindow)] = CHistWindow;
begin
  GetPalette := @P;
end;

procedure TSpecialHistViewer.HandleEvent(var Event: TEvent);
begin
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbDel, kbIns, kbAlt1..kbAlt0: Event.What := evNothing;
    end;
  if (Event.What = evMouseDown) and (Event.Buttons = mbRightButton) then
    TListViewer.HandleEvent(Event);
  Inherited HandleEvent(Event);
end;

procedure TSpecialHistWindow.InitViewer(HistoryId: Word);
var
  R: TRect;
begin
  GetExtent(R);
  R.Grow(-1,-1);
  Viewer := New(PSpecialHistViewer, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    HistoryId));
  Insert(Viewer);
  Viewer^.FocusItem(0);
end;

procedure GetHistWinBounds(Id: Word; const Title: TTitleStr; var R: TRect);
var
  I: Integer;
  Count: Word;
begin
  I := HistoryWidth(Id) + 2 + 2 * Byte(Id < 200);
  if I < Length(Title) + 12 then I := Length(Title) + 12
  else if I > Desktop^.Size.X - 2 then I := Desktop^.Size.X - 2;
  Count := HistoryCount(Id);
  if Count <= Desktop^.Size.Y - MinWinSize.Y - 2 then
    Count := Count + MinWinSize.Y
  else Count := Desktop^.Size.Y - 2;
  R.Assign(0, 0, I, Count);
end;

end.