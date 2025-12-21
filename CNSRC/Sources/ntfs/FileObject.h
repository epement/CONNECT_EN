// FileObject.h : Declaration of the CFileObject

#ifndef __FILEOBJECT_H_
#define __FILEOBJECT_H_

#include "resource.h"       // main symbols

/////////////////////////////////////////////////////////////////////////////
// CFileObject
class ATL_NO_VTABLE CFileObject : 
	public CComObjectRootEx<CComSingleThreadModel>,
	public CComCoClass<CFileObject, &CLSID_FileObject>,
	public IDispatchImpl<IFileObject, &IID_IFileObject, &LIBID_NTFSOMLib>
{
public:
	CFileObject()
	{
	}

DECLARE_REGISTRY_RESOURCEID(IDR_FILEOBJECT)

DECLARE_PROTECT_FINAL_CONSTRUCT()

BEGIN_COM_MAP(CFileObject)
	COM_INTERFACE_ENTRY(IFileObject)
	COM_INTERFACE_ENTRY(IDispatch)
END_COM_MAP()

// IFileObject
public:
	STDMETHOD(DeleteMountVolume)(BSTR bstrVolume);
	STDMETHOD(MountVolume)(BSTR bstrMountName, BSTR bstrVolume);
	STDMETHOD(Test)();
	STDMETHOD(Zero)(long lFrom, long lTo);
	STDMETHOD(get_Sparse)(/*[out, retval]*/ long *pVal);
	STDMETHOD(MakeSparse)();
	STDMETHOD(get_Size)(/*[out, retval]*/ long *pVal);
	STDMETHOD(get_CompressedSize)(/*[out, retval]*/ long *pVal);
	STDMETHOD(get_EncryptionStatus)(/*[out, retval]*/ long *pVal);
	STDMETHOD(get_Encrypted)(/*[out, retval]*/ long *pVal);
	STDMETHOD(put_Encrypted)(/*[in]*/ long newVal);
	STDMETHOD(SetFile)(BSTR bstrFile);
	STDMETHOD(get_Compressed)(/*[out, retval]*/ long *pVal);
	STDMETHOD(put_Compressed)(/*[in]*/ long newVal);

private:
	TCHAR m_szFile[MAX_PATH];
};

#endif //__FILEOBJECT_H_
