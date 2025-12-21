Uses int2f;

type
 TSCRInfo = record
   horzsize: Longint;   {// Width, in millimeters, of the physical screen.}
   vertsize: Longint;   {// Height, in millimeters, of the physical screen.}
   horzres: Longint;    {// Width, in pixels, of the screen.}
   vertres: Longint;    {// Height, in raster lines, of the screen.}
   logpixelsx: Longint; {// Number of pixels per logical inch along the screen width.}
   logpixelsy: Longint; {// Number of pixels per logical inch along the screen height.}
   bitspixel: Longint;  {// Number of adjacent color bits for each pixel.}
   colorres: Longint;   {// Actual color resolution of the device, in bits per pixel.}
   vrefresh: Longint;   {// The current vertical refresh rate of the device, in cycles per second (Hz).}
 end;

var
 SCI: TSCRInfo;
begin
 Inst_CN_NT;
 ScrInfo(SCI);
 with SCI do
  begin
   WriteLn('Width, in millimeters = ', horzsize);
   WriteLn('Height, in millimeters = ', vertsize);
   WriteLn('Width, in pixels = ', horzres);
   WriteLn('Height, in raster lines = ', vertres);
   WriteLn('Number of pixels per logical inch along the screen width = ', logpixelsx);
   WriteLn('Number of pixels per logical inch along the screen height = ', logpixelsy);
   WriteLn('Number of adjacent color bits for each pixel = ', bitspixel);
   WriteLn('Actual color resolution of the device, in bits per pixel = ', colorres);
   WriteLn('The current vertical refresh rate = ', vrefresh, ' Hz');
  end;
end.