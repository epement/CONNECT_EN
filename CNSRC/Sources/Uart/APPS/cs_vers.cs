//
// NAME: CS_VERS.CS
//
// TYPE: Win32 mode (VC#).
//
// DATE: August 6, 2004
//
// PURPOSE: Displays the WSC32.DLL Version, Build #, and registration string.
//
//          Also demonstrates how to call WSC functions from within C# programs.
//
// COMPILE: Using the VC# integrated developer environment (IDE), open the 
//          workspace "cs_vers.csproj".
//
//          Compile using /unsafe option.
//

using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;
using System.Data;
using System.Runtime.InteropServices; // REQUIRED 

namespace cs_vers
{
                         
        /// <summary>
        /// Summary description for cs_vers.
        /// </summary>
        public class cs_vers : System.Windows.Forms.Form
        {
            private System.Windows.Forms.Button button1;
            private System.Windows.Forms.Button button2;
                /// <summary>
                /// Required designer variable.
                /// </summary>
                
                private System.ComponentModel.Container components;
                [DllImport("user32")]
                public static extern int MessageBox(int h, string m, string c, int type); 
                [DllImport("user32")]
                public static extern unsafe int MessageBox(int h, char* m, string c, int type);
                
                // C# Declarations for WSC4C
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioKeyCode(long KeyCode);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioGetReg(char* Buffer, int Size);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioReset(int Port, int InQueue, int OutQueue);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioDone(int Port);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioBaud(int Port, long BaudRate);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioPutc(int Port, char Byte);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioPuts(int Port, char* Buffer, long Size);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioGetc(int Port);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioGets(int Port,char* Buffer,long Size);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioDTR(int Port,char Cmd);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioRTS(int Port,char Cmd);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioTxClear(int Port); 
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioRxClear(int Port); 
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioTxQue(int Port);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioRxQue(int Port); 
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioStatus(int Port, long Mask);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioFlow(int Port,char Cmd); 
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioParms(int Port,int Parity,int StopBits,int DataBits);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioCTS(int Port);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioDSR(int Port);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioRI(int Port);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioDebug(int Parm);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioSetInteger(int Port, int ParmName, long ParmValue); 
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioInfo(char Parm);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioDCD(int Port);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioBrkSig(int Port,char Cmd); 
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioUnGetc(int Port,char Chr);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioWinError(char* Buffer, int Size);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioRead(int Port, int Reg);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioEvent(int Port, long MaskArg);
                [DllImport("wsc32.dll")]
                public static extern unsafe int SioMessage(int Port, long hMsgWnd, int MsgCode, long Mask);

                public cs_vers()
                {
                        //
                        // Required for Windows Form Designer support
                        //
                        InitializeComponent();

                        //
                        // TODO: Add any constructor code after InitializeComponent call
                        //
                }

                /// <summary>
                /// Clean up any resources being used.
                /// </summary>
                protected override void Dispose( bool disposing )
                {
                        if( disposing )
                        {
                                if (components != null) 
                                {
                                 components.Dispose();
                                }
                        }
                        base.Dispose( disposing );
                }

                #region Windows Form Designer generated code
                /// <summary>
                /// Required method for Designer support - do not modify
                /// the contents of this method with the code editor.
                /// </summary>
                private void InitializeComponent()
                {
                 this.button1 = new System.Windows.Forms.Button();
                 this.button2 = new System.Windows.Forms.Button();
                 this.SuspendLayout();
                 // 
                 // button1
                 // 
                 this.button1.Location = new System.Drawing.Point(8, 8);
                 this.button1.Name = "button1";
                 this.button1.Size = new System.Drawing.Size(176, 72);
                 this.button1.TabIndex = 0;
                 this.button1.Text = "Push Me";
                 this.button1.Click += new System.EventHandler(this.button1_Click);
                 // 
                 // button2
                 // 
                 this.button2.Location = new System.Drawing.Point(8, 88);
                 this.button2.Name = "button2";
                 this.button2.Size = new System.Drawing.Size(176, 72);
                 this.button2.TabIndex = 1;
                 this.button2.Text = "Exit";
                 this.button2.Click += new System.EventHandler(this.button2_Click);
                 // 
                 // cs_vers
                 // 
                 this.AutoScaleBaseSize = new System.Drawing.Size(5, 13);
                 this.ClientSize = new System.Drawing.Size(192, 166);
                 this.Controls.AddRange(new System.Windows.Forms.Control[] 
                   {
                    this.button2,                                                                                                                                    this.button1});
                    this.Name = "cs_vers";
                    this.Text = "C# Example";
                    this.Load += new System.EventHandler(this.cs_vers_Load);
                    this.ResumeLayout(false);
                   }
                   
                #endregion

                /// <summary>
                /// The main entry point for the application.
                /// </summary>
                [STAThread]
                static void Main() 
                {
                 Application.Run(new cs_vers());
                }

                private void cs_vers_Load(object sender, System.EventArgs e)
                {
                
                }

                private unsafe void button1_Click(object sender, System.EventArgs e)
                {// button 1
                 int Code;
                 int Version;
                 int Build;
                 string TempBuffer;
                         
                 // WSC constants go here (see WSC.H for list)
                 const int WSC_KEY_CODE= 0;
                 // pass key code
                 Code = SioKeyCode(WSC_KEY_CODE);  // Key code = 0 for evaluation version
                 if(Code<0)
                    {TempBuffer = String.Format("Error {0}",Code);
                     MessageBox(0, "Cannot attach WSC32.DLL", TempBuffer, 0);
                     return;
                    } 
                 // display version and build                      
                 Version = SioInfo('V');
                 Build = SioInfo('B');  
                 TempBuffer = String.Format("WSC Version: {0}.{1}.{2}",
                            0x0f&(Version>>8),0x0f&(Version>>4),0x0f&Version,Build);
                 button1.Text = TempBuffer;
                         
                           {// display registration string
                            char[] UnsafeBuffer = new char[128];
                            fixed (char* pBuffer = UnsafeBuffer)
                               {// display registration string
                                Code = SioGetReg(pBuffer, 50);
                                MessageBox(0, pBuffer, "Registration", 0);
                               }
                           }
        
                }

               private void button2_Click(object sender, System.EventArgs e)
                 {// button 2
                  Application.Exit();
                 }
        }
}
