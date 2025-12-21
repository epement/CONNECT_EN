//---------------------------------------------------------------------------
#ifndef BCB_PGMH
#define BCB_PGMH
//---------------------------------------------------------------------------
#include <vcl\Classes.hpp>
#include <vcl\Controls.hpp>
#include <vcl\StdCtrls.hpp>
#include <vcl\Forms.hpp>
#include <vcl\Menus.hpp>
#include <vcl\ExtCtrls.hpp>
//---------------------------------------------------------------------------
class TBCB_PGM : public TForm
{
__published:	// IDE-managed Components
	TMainMenu *MainMenu;
	TMenuItem *Line;
	TMenuItem *Exit;
	TMenuItem *OnLine;
	TMenuItem *OffLine;
	TMenuItem *Port;
	TMenuItem *mCOM1;
	TMenuItem *mCOM2;
	TMenuItem *mCOM3;
	TMenuItem *mCOM4;
	TMenuItem *Baud;
	TMenuItem *N9600;
	TMenuItem *N19200;
	TMenuItem *N38400;
	TMenuItem *N57600;
	TTimer *Timer;
	TMemo *Memo;
	void __fastcall ExitClick(TObject *Sender);
	
	void __fastcall TimerTimer(TObject *Sender);
	void __fastcall OnLineClick(TObject *Sender);
	void __fastcall OffLineClick(TObject *Sender);
	void __fastcall mCOM1Click(TObject *Sender);
	void __fastcall mCOM2Click(TObject *Sender);
	void __fastcall mCOM3Click(TObject *Sender);
	void __fastcall mCOM4Click(TObject *Sender);
	void __fastcall N9600Click(TObject *Sender);
	void __fastcall N19200Click(TObject *Sender);
	void __fastcall N38400Click(TObject *Sender);
	void __fastcall N57600Click(TObject *Sender);
	
	
	void __fastcall OnKeyPress(TObject *Sender, char &Key);
	
private:	// User declarations
public:		// User declarations
	__fastcall TBCB_PGM(TComponent* Owner);
};
//---------------------------------------------------------------------------
extern TBCB_PGM *BCB_PGM;
//---------------------------------------------------------------------------
#endif
