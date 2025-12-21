(*
**  fdpkt.inc
**  Structures for .FDC and .PKT files
**  Copyright 1993 Joaquim Homrighausen; All rights reserved.
**  Last revised: 93-06-21                    FrontDoor 2.11+
*)

  { FDC field type flags }

CONST
  FDC_ISFILE            =$E0;                                    {File attach}
  FDC_ISFREQ            =$E1;                                   {File request}
  FDC_ISFUREQ           =$E2;                            {File update request}
  FDC_ISMSG             =$FD;                                        {Message}

  { Call status flags (CALLSTATUS) }

  FDC_UNUSED            =0;
  FDC_FAILED            =1;
  FDC_SENT              =2;
  FDC_HOLD              =3;
  FDC_CRASH             =4;
  FDC_ACTIVE            =5;
  FDC_PRIORITY          =6;
  FDC_DELETED           =7;

  { FDC header, one per .FDC file }

TYPE
  FDCHEAD = RECORD
    Zone,                                                {Destination address}
    Net,
    Node,
    Point,
    BusyRetry,                           {Number of call attempts (max->zero)}
    Resend  :WORD;                     {Number of resend attempts (max->zero)}
    PktTime :LONGINT;                   {UNIX-style timestamp with event time}
    MsgCount,                                     {Number of messages in .PKT}
    FileCount,                                       {Number of files to send}
    FReqCount,                                       {Number of file requests}
    Cost    :WORD;                                 {Cost per minute to system}
    CallStatus:BYTE;                                               {See above}
    Script  :STRING[8];                                {Name of script to use}
    EventTag:CHAR;                      {During which event tag it was packed}
  END;{FDCHEAD}

(*
**  FTS-1 (FSC-39 compliant) packet definition used by FrontDoor, TosScan,
**  and FrontDoor APX among other products to create .PKT files.
*)
CONST
  CW_2PLUS              =$0001;                  {Support for Type 2+ bundles}
  CW_N2PLUS             =$0100;                      {Validation for CW_2PLUS}
  PKTVERSION            =2;                    {Current packet revision level}

  { Packet header, one per packet }

TYPE
  FTS1PKTHDR = RECORD
    OrigNode,                                               {Originating node}
    DestNode,                                               {Destination node}
    Year,                                           {Year created (1993-nnnn)}
    Month,                                              {Month created (0-11)}
    Day,                                                  {Day created (1-31)}
    Hour,                                                {Hour created (0-23)}
    Minute,                                            {Minute created (0-59)}
    Second,                                            {Second created (0-59)}
    Rate,                                                  {Baudrate (unused)}
    Version,                                              {Packet version (2)}
    OrigNet,                                                 {Originating net}
    DestNet  :WORD;                                           {Destination net}
    PCodeLo,                                        {Product code (low-order)}
    PRevMajor:BYTE;                                            {Major version}
    Password:ARRAY[1..8] of CHAR;               {Packet password (not ASCIIZ)}
    QMOrigZone,                                     {Originating zone (QMail)}
    QMDestZone,                                     {Destination zone (QMail)}
    AuxNet,                                           {Auxillary net (unused)}
    CWValidate:WORD;                                      {CapWord validation}
    PCodeHi,                                       {Product code (high-order)}
    PRevMinor:BYTE;                                            {Minor version}
    CWCapWord,                                                  {Capabilities}
    OrigZone,                                      {Originating zone (FSC-39)}
    DestZone,                                      {Destination zone (FSC-39)}
    OrigPoint,                                    {Originating point (FSC-39)}
    DestPoint:WORD;                               {Destination point (FSC-39)}
    LongData:LONGINT;                          {Product dependent information}
  END;{FTS1PKTHDR}

  { Packed message, none or more per packet }

  FTS1PKTMSG = RECORD
    Version,                                              {Packet version (2)}
    OrigNode,                                               {Originating node}
    DestNode,                                               {Destination node}
    OrigNet,                                                 {Originating net}
    DestNet,                                                 {Destination net}
    Attr,                                                        {FTS1 status}
    Cost    :WORD;                                           {Cost of message}
    (*
    **  The message header follows this but is of variable length ASCIIZ
    **  strings in the order: AsciiDate, ToUser, FromUser, Subject, and
    **  MsgText.
    *)
  END;{FTS1PKTMSG}

