/* this file contains the actual definitions of */
/* the IIDs and CLSIDs */

/* link this file in with the server and any clients */


/* File created by MIDL compiler version 5.01.0164 */
/* at Fri Mar 31 17:03:52 2000
 */
/* Compiler settings for D:\Articles\MSDN News\NTFS2\Source\NTFSOM\NTFSOM.idl:
    Oicf (OptLev=i2), W1, Zp8, env=Win32, ms_ext, c_ext
    error checks: allocation ref bounds_check enum stub_data 
*/
//@@MIDL_FILE_HEADING(  )
#ifdef __cplusplus
extern "C"{
#endif 


#ifndef __IID_DEFINED__
#define __IID_DEFINED__

typedef struct _IID
{
    unsigned long x;
    unsigned short s1;
    unsigned short s2;
    unsigned char  c[8];
} IID;

#endif // __IID_DEFINED__

#ifndef CLSID_DEFINED
#define CLSID_DEFINED
typedef IID CLSID;
#endif // CLSID_DEFINED

const IID IID_IFileObject = {0x0BFCA612,0x0820,0x4645,{0xB1,0xF6,0x20,0x2A,0x5F,0x5C,0x49,0xAB}};


const IID LIBID_NTFSOMLib = {0x37A52452,0xB8C6,0x4F0A,{0x80,0xC4,0x81,0xDE,0x59,0xCC,0x3C,0xEF}};


const CLSID CLSID_FileObject = {0xA241F97C,0xA550,0x4AED,{0x9E,0x66,0x3E,0x33,0x63,0xFE,0x1D,0x38}};


#ifdef __cplusplus
}
#endif

