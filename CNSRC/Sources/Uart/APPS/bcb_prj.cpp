//---------------------------------------------------------------------------
#include <vcl.h>
#pragma hdrstop
USEUNIT("Bcb_prj.cpp");
USEFORM("Bcb_pgm.cpp", BCB_PGM);
USEFILE("Bcb_pgm.dfm");
//---------------------------------------------------------------------------
WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{
    try
    {
        Application->Initialize();
        Application->CreateForm(__classid(TBCB_PGM), &BCB_PGM);
        Application->Run();
    }
    catch (Exception &exception)
    {
        Application->ShowException(&exception);
    }
    return 0;
}
//---------------------------------------------------------------------------
