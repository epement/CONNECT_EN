(*
**  fdmsg.inc
**
**  Structures for .MSG files
**
**  Copyright 1993 Joaquim Homrighausen; All rights reserved.
**
**  Last revised: 93-06-21                    FrontDoor 2.11+
**
**  -------------------------------------------------------------------------
**  This information is not necessarily final and is subject to change at any
**  given time without further notice
**  -------------------------------------------------------------------------
*)

(*
**  FTS-1 (Opus 1.03 compatible) message header definition used by FrontDoor,
**  and TosScan among other products to create .MSG files. "!!" indicates
**  that the bit is not used by FrontDoor.

#define MSGPRIVATE        0x0001                             {Private message}
#define MSGCRASH          0x0002                               {High priority}
#define MSGREAD           0x0004                           {Read by addressee}
#define MSGSENT           0x0008                               {Has been sent}
#define MSGFILE           0x0010                        {File attached to msg}
#define MSGTRANSIT        0x0020                                  {In transit}
#define MSGORPHAN         0x0040                                {Unknown node}
#define MSGKILL           0x0080                          {Kill after mailing}
#define MSGLOCAL          0x0100                    {Message was entered here}
#define MSGHOLD           0x0200                             {Hold for pickup}
#define MSGUNUSED         0x0400                                          {!!}
#define MSGFREQ           0x0800                                {File request}
#define MSGRRREQ          0x1000                   {Return receipt request !!}
#define MSGISRR           0x2000                        {Is return receipt !!}
#define MSGAREQ           0x4000                            {Audit request !!}
#define MSGFUPDREQ        0x8000                      {File update request !!}

    { Message header, one per message }

    { All strings are NUL terminated, a'la C ASCIIZ strings. }

typedef struct
    {
    char    FromUser[36],                                  {Name in By: field}
            ToUser[36],                                    {Name in To: field}
            Subject[72],                                   {Name in Re: field}
            Date[20];                                   {ASCIIz creation date}
    unsigned short int
            TimesRead,                          {Number of times message read}
            DestNode,                                       {Destination node}
            OrigNode,                                       {Originating node}
            Cost,                                       {Cost to send message}
            OrigNet,                                         {Originating net}
            DestNet;                                         {Destination net}
    unsigned long
            DateWritten,                            {Date message was written}
            DateArrived;                          {Date message was read/sent}
    unsigned short int
            ReplyTo,                            {This is a reply to "ReplyTo"}
            Attr,                                  {Attribute bits, see above}
            ReplyNext;                                  {Next reply in thread}
    }
    FIDOMSG;
*)

const
 MSGPRIVATE = $0001;          {Private message}
 MSGCRASH   = $0002;          {High priority}
 MSGREAD    = $0004;          {Read by addressee}
 MSGSENT    = $0008;          {Has been sent}
 MSGFILE    = $0010;          {File attached to msg}
 MSGTRANSIT = $0020;          {In transit}
 MSGORPHAN  = $0040;          {Unknown node}
 MSGKILL    = $0080;          {Kill after mailing}
 MSGLOCAL   = $0100;          {Message was entered here}
 MSGHOLD    = $0200;          {Hold for pickup}
 MSGUNUSED  = $0400;          {!!}
 MSGFREQ    = $0800;          {File request}
 MSGRRREQ   = $1000;          {Return receipt request !!}
 MSGISRR    = $2000;          {Is return receipt !!}
 MSGAREQ    = $4000;          {Audit request !!}
 MSGFUPDREQ = $8000;          {File update request !!}

    { Message header, one per message }

    { All strings are NUL terminated, a'la C ASCIIZ strings. }

type
FidoMSG = Record
 FromUser,                                {Name in By: field}
 ToUser : Array[0..35] of char;           {Name in To: field}
 Subject : Array[0..71] of char;          {Name in Re: field}
 Date : Array[0..19] of char;             {ASCIIz creation date}
 TimesRead,                               {Number of times message read}
 DestNode,                                {Destination node}
 OrigNode,                                {Originating node}
 Cost,                                    {Cost to send message}
 OrigNet,                                 {Originating net}
 DestNet : Word;                          {Destination net}
 DateWritten,                             {Date message was written}
 DateArrived : Longint;                   {Date message was read/sent}
 ReplyTo,                                 {This is a reply to "ReplyTo"}
 Attr,                                    {Attribute bits, see above}
 ReplyNext: Word;                         {Next reply in thread}
end;
(*
**  The "DateWritten" and "DateArrived" fields are packed DOS dates with
**  the low word and high word exchanged as per the format used by Opus
**  1.03.
*)

(* end of file "fdmsg.inc" *)



