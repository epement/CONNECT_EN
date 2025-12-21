unit Net;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs,  ComCtrls, StdCtrls,
  Buttons, ImgList, ExtCtrls;

type
 TNetForm = class(TForm)
  ListView1: TListView;
  ImageList1: TImageList;
  Button1: TButton;
  Edit1: TEdit;
  Timer: TTimer;
  Label1: TLabel;
  Button2: TButton;
  { procedure FormShow(Sender: TObject);}
  procedure BitBtn2Click(Sender: TObject);
  procedure BitBtn1Click(Sender: TObject);
  procedure Button1Click(Sender: TObject);
  procedure Button2Click(Sender: TObject);
  procedure TimerTimer(Sender: TObject);
  procedure FormCreate(Sender: TObject);  private
  { Private declarations }
 public
  { Public declarations }
  function FillNetLevel(xxx: PNetResource; list: TListItems): Word;
  function GetComputer: string;
 end;

var
 NetForm: TNetForm;
 name_server: integer;

implementation

uses main, Info, Network_connect;

{$R *.DFM}

function TNetForm.FillNetLevel(xxx: PNetResource; List: TListItems): Word;

type
 PNRArr = ^TNRArr;
 TNRArr = array[0..59] of TNetResource;

var
 x: PNRArr;
 tnr: TNetResource;
 I: integer;
 EntrReq, SizeReq, twx: THandle;
 WSName: string;
 LI: TListItem;

 begin

(*
{ Network Browsing. }

function WNetOpenEnum(dwScope, dwType, dwUsage: DWord;
  lpNetResource: PNetResource; var lphEnum: THandle): DWord;
function WNetEnumResource(hEnum: THandle; var lpcCount: DWord;
  lpBuffer: Pointer; var lpBufferSize: DWord): DWord;
function WNetCloseEnum(hEnum: THandle): DWord;
function WNetGetResourceParent(lpNetResource: PNetResource;
  lpBuffer: Pointer; var cbBuffer: DWord): DWord;
*)
   Result := WNetOpenEnum(RESOURCE_GLOBALNET, RESOURCETYPE_ANY,
                           RESOURCEUSAGE_CONTAINER, xxx, twx);

   if Result = ERROR_NO_NETWORK then  Exit;
   if Result = NO_ERROR then
   begin
    New(x);
    EntrReq := 1;
    SizeReq := SizeOf(TNetResource) * 59;
    while (twx <> 0) and
      (WNetEnumResource(twx, EntrReq, x, SizeReq) <> ERROR_NO_MORE_ITEMS) do
     begin
      for i := 0 to EntrReq - 1 do
        begin
         Move(x^[i], tnr, SizeOf(tnr));
         case tnr.dwDisplayType of
          RESOURCEDISPLAYTYPE_SERVER:
           begin
            if tnr.lpRemoteName <> '' then WSName := tnr.lpRemoteName
            else WSName := tnr.lpComment;
            LI := list.Add;
            LI.Caption := copy(WSName, 3, length(WSName) - 2);
            //list.Add(WSName);
           end;
         else
          FillNetLevel(@tnr, list);
         end;
        end;
     end;
    //Dispose(x);
    WNetCloseEnum(twx);
   end;
 end;

{
procedure TNetForm.FormShow(Sender: TObject);
 begin
  ListView1.Items.Clear;
  FillNetLevel(nil,ListView1.Items);
 end;
}


function TNetForm.GetComputer: string;
 begin
  result := '';
  if (ShowModal = mrok) and (ListView1.Selected <> nil) then
    result := ListView1.Selected.Caption;
 end;

procedure TNetForm.BitBtn2Click(Sender: TObject);
 begin
  ModalResult := mrcancel;
 end;

procedure TNetForm.BitBtn1Click(Sender: TObject);
 begin
  modalresult := mrok;
 end;

procedure TNetForm.Button1Click(Sender: TObject);
 var
  i: integer;
  j: integer;
  name, k: string;
 begin
   try
     ListView1.Items.Clear;
     FillNetLevel(nil, ListView1.Items);
     i := ListView1.Items.Count;
     edit1.Text := IntToStr(i);
     i := ListView1.Items.Count;
     edit1.Text := IntToStr(i);   //i:=0;
     if i = 0 then
      begin
       Messagebox(0, 'Не найден ни один сетевой ресурс!' + #13#10+
                     'Вероятно ваша сеть неисправна!' + #13#10+
                     'Попробуйте перезагрузить компьютер.',
                     'Внимание!', MB_OK);
       Main_form.Edit1.Text := 'FALSE';
      end;
     if i > 0 then
      begin
       Messagebox(0, 'Найдены сетевые ресурсы!' + #13#10+
                     'Ваша сеть исправна!',
                     'Внимание!', MB_OK);
       Main_form.Edit1.Text := 'TRUE';
      end;
     button1.Enabled := false;
   except
     messagebox(0, 'Невозможно выполнить задачу', 'Внимание', MB_OK);
   end;
 end;

procedure TNetForm.Button2Click(Sender: TObject);
 begin
   close;
 end;

procedure TNetForm.TimerTimer(Sender: TObject);
 begin
  if ListView1.Items.Count = 0 then close;
 end;

procedure TNetForm.FormCreate(Sender: TObject);
 begin
  button1.Enabled := true;
 end;

end.
