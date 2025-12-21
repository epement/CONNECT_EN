@for %%f in (*.p??) do crc %%f>> crclist.lst
@for %%f in (*.obj) do crc %%f>> crclist.lst