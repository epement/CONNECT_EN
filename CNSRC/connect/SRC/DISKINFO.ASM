        INCLUDE d:\work\asm\OPCOMMON.ASM

CODE    SEGMENT BYTE PUBLIC

        ASSUME  CS:CODE

        PUBLIC  GetDiskInfo

;****************************************************** GetDiskInfo

;function GetDiskInfo(Drive : Byte; var ClustersAvailable, TotalClusters,
;                     BytesPerSector, SectorsPerCluster: Word) : Boolean;
;Return technical info about the specified drive

GDDrive         EQU     BYTE PTR [BP+22]
GDClustAvail    EQU     DWORD PTR [BP+18]
GDTotalClust    EQU     DWORD PTR [BP+14]
GDBytesPerSec   EQU     DWORD PTR [BP+10]
GDSecPerClust   EQU     DWORD PTR [BP+6]

GetDiskInfo     PROC FAR

        StackFrameBP
        MOV     DL,GDDrive              ;DL = Drive
        MOV     AH,36h                  ;Get disk free space
        INT     21h                     ;call DOS
        CMP     AX,0FFFFh               ;invalid drive?
        JE      GDIerror                ;error if so
        CLD                             ;go forward
        LES     DI,GDSecPerClust        ;ES:DI => SectorsPerCluster
        STOSW                           ;value in AX
        LES    DI,GDBytesPerSec         ;ES:DI => BytesPerSector
        MOV    AX,CX                    ;value in CX
        STOSW
        LES    DI,GDTotalClust          ;ES:DI => TotalClusters
        MOV    AX,DX                    ;value in DX
        STOSW
        LES    DI,GDClustAvail          ;ES:DI => ClustersAvailable
        MOV    AX,BX                    ;value in BX
        STOSW
        MOV     AX,1                    ;set OK flag
GDIdone:
        ExitCode 18                     ;remove parameters and return
GDIerror:
        SetZero AX                      ;AX = 0
        JMP SHORT GDIdone               ;exit

GetDiskInfo     ENDP

CODE    ENDS

        END

