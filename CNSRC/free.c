//---------------------------------------------------------------------------
#include <stdio.h>
#include <windows.h>
#pragma hdrstop

//---------------------------------------------------------------------------

#pragma argsused
int main(int argc, char* argv[])
{
    LPCTSTR lpRootPathName;	// address of root path
    LPDWORD lpSectorsPerCluster;	// address of sectors per cluster
    LPDWORD lpBytesPerSector;	// address of bytes per sector
    LPDWORD lpNumberOfFreeClusters;	// address of number of free clusters
    LPDWORD lpTotalNumberOfClusters; 	// address of total number of clusters

    lpRootPathName = "c:";
(void)GetDiskFreeSpace(0l, //lpRootPathName,	// address of root path
     lpSectorsPerCluster,	// address of sectors per cluster
     lpBytesPerSector,	// address of bytes per sector
     lpNumberOfFreeClusters,	// address of number of free clusters
     lpTotalNumberOfClusters 	// address of total number of clusters
   );



 printf("Hello, World!");
        return 0;
}
//---------------------------------------------------------------------------
 