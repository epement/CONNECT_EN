{$X+,O+,F+}
unit CColors;

interface

uses Objects;

procedure RSRColors(RSR: PResourceFile);
procedure LoadColorSel;

implementation

uses Drivers, Views, Memory, Dialogs, App, MsgBox,
  EditMsg, ColorSel, RGBColor;

procedure RSRColors(RSR: PResourceFile);
var
  C: Byte;
  D: PColorDialog;

function CDPlayerColorGroup(Next: PColorGroup): PColorGroup;
begin
  CDPlayerColorGroup := ColorGroup('CD Player',
    ColorItem('Frame passive',     211,
    ColorItem('Frame active',      212,
    ColorItem('Frame icons',       213,
    ColorItem('Static text',       216,
    ColorItem('Display',           214,
    ColorItem('Drive status',      217,
    ColorItem('Track title',       218,
    ColorItem('Progress bar',      215,
    ColorItem('Button normal',     220,
    ColorItem('Button default',    221,
    ColorItem('Button selected',   222,
    ColorItem('Button disabled',   223,
    ColorItem('Button shortcut',   224,
    ColorItem('Shortcut default',  242,
    ColorItem('Shortcut selected', 243,
    ColorItem('Button shadow',     225, nil)))))))))))))))),
    Next);
end;

function CPUWindowColorGroup(Next: PColorGroup): PColorGroup;
begin
  CPUWindowColorGroup := ColorGroup('CPU window',
    ColorItem('Frame passive',     113,
    ColorItem('Frame active',      114,
    ColorItem('Frame icons',       115,
    ColorItem('Scroll bar page',   116,
    ColorItem('Scroll bar icons',  117,
    ColorItem('Source normal',     118,
    ColorItem('Breakpoints',       119,
    ColorItem('Source position',   120,
    ColorItem('Registers normal',  121,
    ColorItem('Registers selected',122,
    ColorItem('Flags normal',      123,
    ColorItem('Flags selected',    124,
    ColorItem('Memory normal',     125,
    ColorItem('Stack normal',      126,
    ColorItem('Stack selected',    127, nil))))))))))))))),
    Next);
end;

function DBaseColorGroup(Next: PColorGroup): PColorGroup;
begin
  DBaseColorGroup := ColorGroup('dBASE viewer',
    ColorItem('Frame passive',     185,
    ColorItem('Frame active',      186,
    ColorItem('Frame icons',       187,
    ColorItem('Scroll bar page',   188,
    ColorItem('Scroll bar icons',  189,
    ColorItem('Fields',            190,
    ColorItem('Normal text',       191,
    ColorItem('Focused text',      192,
    ColorItem('Selected text',     209,
    ColorItem('Focused selected',  210,
    ColorItem('Modified text',     193,
    ColorItem('Current field',     194, nil)))))))))))),
    Next);
end;

function DialogColorGroup(Next: PColorGroup): PColorGroup;
begin
  DialogColorGroup := ColorGroup('Dialogs, Calc',
    ColorItem('Frame passive',     32,
    ColorItem('Frame active',      33,
    ColorItem('Frame icons',       34,
    ColorItem('Scroll bar page',   35,
    ColorItem('Scroll bar icons',  36,
    ColorItem('Static text',       37,
    ColorItem('Label normal',      38,
    ColorItem('Label selected',    39,
    ColorItem('Label shortcut',    40,
    ColorItem('Button normal',     41,
    ColorItem('Button default',    42,
    ColorItem('Button selected',   43,
    ColorItem('Button disabled',   44,
    ColorItem('Button shortcut',   45,
    ColorItem('Shortcut default',  63,
    ColorItem('Shortcut selected', 31,
    ColorItem('Button shadow',     46,
    ColorItem('Cluster normal',    47,
    ColorItem('Cluster selected',  48,
    ColorItem('Cluster disabled',  62,
    ColorItem('Cluster shortcut',  49,
    ColorItem('Input normal',      50,
    ColorItem('Input selected',    51,
    ColorItem('Input arrow',       52,
    ColorItem('History button',    53,
    ColorItem('History sides',     54,
    ColorItem('History bar page',  55,
    ColorItem('History bar icons', 56,
    ColorItem('List normal',       57,
    ColorItem('List focused',      58,
    ColorItem('List selected',     59,
    ColorItem('List divider',      60,
    ColorItem('Information pane',  61, nil))))))))))))))))))))))))))))))))),
    Next);
end;

function EditorColorGroup(Next: PColorGroup): PColorGroup;
begin
  EditorColorGroup := ColorGroup('Editor',
    ColorItem('Frame passive',     96,
    ColorItem('Frame active',      97,
    ColorItem('Frame icons',       98,
    ColorItem('Scroll bar page',   99,
    ColorItem('Scroll bar icons',  100,
    ColorItem('Normal text',       101,
    ColorItem('Highlighted text',  102,
    ColorItem('Breakpoints',       103,
    ColorItem('Source position',   104,
    ColorItem('Current line',      173,
    ColorItem('Current column',    200,
    ColorItem('Page break',        174,
    ColorItem('Text boundaries',   202, nil))))))))))))),
    Next);
end;

function FileManagerColorGroup(Next: PColorGroup): PColorGroup;
begin
  FileManagerColorGroup := ColorGroup('File Manager',
    ColorItem('Frame passive',     136,
    ColorItem('Frame active',      137,
    ColorItem('Frame icons',       138,
    ColorItem('Scroll bar page',   250,
    ColorItem('Scroll bar icons',  251,
    ColorItem('Normal text',       141,
    ColorItem('Focused text',      143,
    ColorItem('Selected text',     142,
    ColorItem('Focused selected',  144,
    ColorItem('Highlighted text',  134,
    ColorItem('Info box text',     135,
    ColorItem('Info box digits',   203,
    ColorItem('Sel info box text', 204,
    ColorItem('Sel info box digits', 252,
    ColorItem('Mouse hint text',   253,
    ColorItem('Prompt normal text', 145,
    ColorItem('Prompt selected text', 112,
    ColorItem('History frame',     148,
    ColorItem('History icons',     149,
    ColorItem('History bar page',  139,
    ColorItem('History bar icons', 140,
    ColorItem('History normal',    150,
    ColorItem('History focused',   151,
    ColorItem('Drive button normal', 146,
    ColorItem('Drive button selected', 83,
    ColorItem('Drive button shadow', 84,
    ColorItem('Drive selector normal', 207,
    ColorItem('Drive selector current', 208, nil)))))))))))))))))))))))))))),
    Next);
end;

function HelpColorGroup(Next: PColorGroup): PColorGroup;
begin
  HelpColorGroup := ColorGroup('Help window',
    ColorItem('Frame passive',     64,
    ColorItem('Frame active',      65,
    ColorItem('Frame icons',       66,
    ColorItem('Scroll bar page',   67,
    ColorItem('Scroll bar icons',  68,
    ColorItem('Normal text',       69,
    ColorItem('Selected text',     86,
    ColorItem('Normal topic',      70,
    ColorItem('Highlighted topic', 71,
    ColorItem('Highlight color 1', 195,
    ColorItem('Highlight color 2', 196,
    ColorItem('Highlight color 3', 197,
    ColorItem('Highlight color 4', 198,
    ColorItem('Highlight color 5', 199, nil)))))))))))))),
    Next);
end;

function HTMLColorGroup(Next: PColorGroup): PColorGroup;
begin
  HTMLColorGroup := ColorGroup('HTML viewer',
    ColorItem('Frame passive',     226,
    ColorItem('Frame active',      227,
    ColorItem('Frame icons',       228,
    ColorItem('Scroll bar page',   229,
    ColorItem('Scroll bar icons',  230,
    ColorItem('Normal text',       231,
    ColorItem('Bold text',         232,
    ColorItem('Highlighted text',  233,
    ColorItem('Normal link',       234,
    ColorItem('Selected link',     235,
    ColorItem('Title label',       236,
    ColorItem('Title text',        237,
    ColorItem('Info label',        238,
    ColorItem('Info text',         239, nil)))))))))))))),
    Next);
end;

function ViewerColorGroup(Next: PColorGroup): PColorGroup;
begin
  ViewerColorGroup := ColorGroup('Viewer',
    ColorItem('Frame passive',     175,
    ColorItem('Frame active',      176,
    ColorItem('Frame icons',       177,
    ColorItem('Scroll bar page',   178,
    ColorItem('Scroll bar icons',  179,
    ColorItem('Normal text',       180,
    ColorItem('Highlighted text',  181,
    ColorItem('Modified text',     182,
    ColorItem('Source position',   183,
    ColorItem('Current line',      184,
    ColorItem('Current column',    201, nil))))))))))),
    Next);
end;

begin
  D := New(PColorDialog, Init('',
    ColorGroup('ASCII table',
      ColorItem('Frame passive',     24,
      ColorItem('Frame active',      25,
      ColorItem('Frame icons',       26,
      ColorItem('Scroll bar page',   27,
      ColorItem('Scroll bar icons',  28,
      ColorItem('Text',              29, nil)))))),
    ColorGroup('Bar window',
      ColorItem('Frame dragged',     82,
      ColorItem('Frame active',      81,
      ColorItem('Slider',            87,
      ColorItem('Normal text',       85,
      ColorItem('Highlighted text',  80, nil))))),
    ColorGroup('Calendar',
      ColorItem('Frame passive',     16,
      ColorItem('Frame active',      17,
      ColorItem('Frame icons',       18,
      ColorItem('Normal text',       21,
      ColorItem('Current day',       22,
      ColorItem('Weekend',           23, nil)))))),
    CDPlayerColorGroup(
    ColorGroup('Clock',
      ColorItem('Time',              244,
      ColorItem('Date',              245,
      ColorItem('Day of week',       246, nil))),
    CPUWindowColorGroup(
    DBaseColorGroup(
    ColorGroup('Desktop',
      ColorItem('Background color',  1, nil),
    DialogColorGroup(
    EditorColorGroup(
    FileManagerColorGroup(
    ColorGroup('Heap',
      ColorItem('Memory available',  247,
      ColorItem('Largest block',     248,
      ColorItem('Including UMB',     249, nil))),
    HelpColorGroup(
    HTMLColorGroup(
    ColorGroup('Memory map',
      ColorItem('Frame passive',     128,
      ColorItem('Frame active',      129,
      ColorItem('Frame icons',       130,
      ColorItem('Scroll bar page',   131,
      ColorItem('Scroll bar icons',  132,
      ColorItem('Normal text',       133, nil)))))),
    ColorGroup('Menus',
      ColorItem('Normal',            2,
      ColorItem('Disabled',          3,
      ColorItem('Shortcut',          4,
      ColorItem('Selected',          5,
      ColorItem('Selected disabled', 6,
      ColorItem('Shortcut selected', 7, nil)))))),
    ColorGroup('Message',
      ColorItem('Frame passive',     88,
      ColorItem('Frame active',      89,
      ColorItem('Frame icons',       90,
      ColorItem('Scroll bar page',   91,
      ColorItem('Scroll bar icons',  92,
      ColorItem('Normal text',       93,
      ColorItem('Highlighted text',  94, nil))))))),
    ColorGroup('Output',
      ColorItem('Frame passive',     72,
      ColorItem('Frame active',      73,
      ColorItem('Frame icons',       74,
      ColorItem('Scroll bar page',   75,
      ColorItem('Scroll bar icons',  76, nil))))),
    ColorGroup('Ruler',
      ColorItem('1, 2, 3...',        205,
      ColorItem('10, 20, 30...',     206, nil)),
    ColorGroup('Screen saver',
      ColorItem('Sky',               152,
      ColorItem('ú star',            153,
      ColorItem('ù star',            154,
      ColorItem(' star',            155,
      ColorItem(' star',            156,
      ColorItem('þ star',            157,
      ColorItem(' star',            158, nil))))))),
    ColorGroup('Shadow',
      ColorItem('Color',             255, nil),
    ColorGroup('Syntax',
      ColorItem('User defined comments', 165,
      ColorItem('.CBS functions',    166,
      ColorItem('.CBS operators',    167,
      ColorItem('.CBS statements',   168,
      ColorItem('.CBS symbols',      169,
      ColorItem('.CBS labels',       170,
      ColorItem('.CBS strings',      171,
      ColorItem('.CBS remarks',      172,
       nil)))))))),
    ColorGroup('Terminal',
      ColorItem('Frame passive',     160,
      ColorItem('Frame active',      161,
      ColorItem('Frame icons',       162,
      ColorItem('Scroll bar page',   163,
      ColorItem('Scroll bar icons',  164, nil))))),
    ColorGroup('Tile area',
      ColorItem('Frame',             159, nil),
    ViewerColorGroup(
    ColorGroup('Watches',
      ColorItem('Frame passive',     105,
      ColorItem('Frame active',      106,
      ColorItem('Frame icons',       107,
      ColorItem('Scroll bar page',   108,
      ColorItem('Scroll bar icons',  109,
      ColorItem('Normal text',       110,
      ColorItem('Highlighted text',  111, nil))))))),
	nil))))))))))))))))))))))))))));
  RSR^.Put(D, 'COLORS');
  Dispose(D, Done);
end;

procedure LoadColorSel;
const
  VGACommands = [cmColorSet];
var
  C: Word;
  D: PColorDialog;
  V: PView;
  SavePal: TPalette;
  Data: TColorDialogData;
begin
  Data.AppPal := Application^.GetPalette^;
  V := Desktop^.Current;
  if V = nil then Data.CurPal := #1
  else Data.CurPal := V^.GetPalette^;
  D := PColorDialog(Resource^.Get('COLORS'));
  if D = nil then ResourceNotFoundMsgBox('Color dialog')
  else if Application^.ValidView(D) = nil then Exit
  else
  begin
    D^.SetData(Data);
    D^.Pal[255] := Char(ShadowAttr);
    SavePal := Application^.GetPalette^;
    SavePal[255] := Char(ShadowAttr);
    if IsVGA then Application^.EnableCommands(VGACommands)
    else Application^.DisableCommands(VGACommands);
    C := Desktop^.ExecView(D);
    Application^.EnableCommands(VGACommands);
    if C <> cmCancel then
    begin
      Application^.GetPalette^ := D^.Pal;
      ShadowAttr := Byte(D^.Pal[255]);
    end
    else
    begin
      Application^.GetPalette^ := SavePal;
      ShadowAttr := Byte(SavePal[255]);
    end;
    Dispose(D, Done);
    DoneMemory;
    Application^.Redraw;
  end;
end;

end.
