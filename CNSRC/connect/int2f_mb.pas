Uses int2f, CRT;

const
{ MessageBox Flags }
  mb_Ok                         = $00000000;
  mb_OkCancel                   = $00000001;
  mb_AbortRetryIgnore           = $00000002;
  mb_YesNoCancel                = $00000003;
  mb_YesNo                      = $00000004;
  mb_RetryCancel                = $00000005;
  mb_IconHand                   = $00000010;
  mb_IconQuestion               = $00000020;
  mb_IconExclamation            = $00000030;
  mb_IconAsterisk               = $00000040;
  mb_IconInformation            = mb_IconAsterisk;
  mb_IconStop                   = mb_IconHand;
  mb_DefButton1                 = $00000000;
  mb_DefButton2                 = $00000100;
  mb_DefButton3                 = $00000200;
  mb_ApplModal                  = $00000000;
  mb_SystemModal                = $00001000;
  mb_NoFocus                    = $00008000;
  mb_SetForeground              = $00010000;
  mb_Service_Notification       = $00040000;
  mb_TypeMask                   = $0000000F;
  mb_IconMask                   = $000000F0;
  mb_DefMask                    = $00000F00;
  mb_ModeMask                   = $00003000;
  mb_MiscMask                   = $0000C000;


begin
 Inst_CN_NT;
 WriteLn(WinMsgBox(ParamStr(1), ParamStr(2), mb_OkCancel));
end.