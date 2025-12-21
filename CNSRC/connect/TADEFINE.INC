{*********************************************************}
{*                   TADEFINE.INC 7.00                   *}
{*      Copyright (c) TurboPower Software 1988,1993.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

{Define Debug to make it easier to trace PSA operation in real mode}

{.$DEFINE Debug}

{if UseEnhKbd is defined, the TpEnhKbd unit is used by MONITOR, PROFILE, and
 ANALYST. In MONITOR and PROFILE, the Alt-Left and Alt-Right key combinations
 move the right marker. Undefine it and the Shift-Left and Shift-Right combos
 are used instead. This may be necessary on older systems that exhibit
 problems when using TpEnhKbd.}

{$DEFINE UseEnhKbd}

{if FilterNoise is DEFINEd, PROFILE's sorted reports filter out bins with
 minimal activity, as well as those with none}

{.$DEFINE FilterNoise}

{if UseTPRO is defined, the Analyst utilities (but not the Analyst IDE) are
 compiled using Turbo Professional rather than Object Professional}

{$DEFINE UseTPRO}

{it isn't possible to use the OPRO units when compiling under Turbo Pascal
 4.0. Don't modify the following.}

{$IFDEF Ver40}
{$DEFINE UseTPRO}
{$ENDIF}

{$IFDEF Ver60}
{$DEFINE Heap6}
{$ENDIF}
{$IFDEF Ver70}
{$DEFINE Heap6}
{$ENDIF}
