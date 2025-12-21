/*
        NNTVDM.C ([Guessed] Missing functions from NTVDM.)

        Copyright (C) 1998-01-18 Claus André Färber

        This program is free software; you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation; either version 2 of the License, or
        (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program; if not, write to the Free Software
        Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <windows.h>
#include <windowsx.h>

#include "ntvdm.h"

BOOL WINAPI FlushVDMPointer(
IN ULONG  Addr,
IN USHORT  Size,
PBYTE  Buffer,
IN BOOL  ProtectedMode )
{
        return TRUE;
}

BOOL  WINAPI FreeVDMPointer(
IN ULONG  Address,
IN USHORT  Size,
PBYTE  Buffer,
IN BOOL  ProtectedMode)
{
        return TRUE;
}

PBYTE WINAPI MGetVdmPointer(
IN ULONG  Address,
IN ULONG  Size,
IN BOOL  ProtectedMode);

PBYTE WINAPI  GetVDMPointer(
IN ULONG  Address,
IN ULONG  Size,
IN BOOL  ProtectedMode)
{
        return MGetVdmPointer(Address, Size, ProtectedMode );
}

