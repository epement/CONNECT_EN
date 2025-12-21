
NTFSOMps.dll: dlldata.obj NTFSOM_p.obj NTFSOM_i.obj
	link /dll /out:NTFSOMps.dll /def:NTFSOMps.def /entry:DllMain dlldata.obj NTFSOM_p.obj NTFSOM_i.obj \
		kernel32.lib rpcndr.lib rpcns4.lib rpcrt4.lib oleaut32.lib uuid.lib \

.c.obj:
	cl /c /Ox /DWIN32 /D_WIN32_WINNT=0x0400 /DREGISTER_PROXY_DLL \
		$<

clean:
	@del NTFSOMps.dll
	@del NTFSOMps.lib
	@del NTFSOMps.exp
	@del dlldata.obj
	@del NTFSOM_p.obj
	@del NTFSOM_i.obj
