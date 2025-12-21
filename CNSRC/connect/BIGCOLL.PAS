{*********************************************************}
{*                   BIGCOLL.PAS 1.01                    *}
{*       Copyright (c) TurboPower Software 1993.         *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$S-,R-,V-,I-,B-,F-,W-,A-,G+,X+}

unit BigColl;
  {-Manage large collections of pointers}

interface

uses
  {$IFDEF Windows}
    {$IFDEF Ver70}
      Objects;
    {$ELSE}
      WObjects;
    {$ENDIF}
  {$ELSE}
    Objects;
  {$ENDIF}

{--------------------------------------------------------------------
Notes:
  - The TBigCollection mimics Borland's TCollection object, except
    that the maximum number of items allowed is 134,193,153. Note that
    this would mean a total in excess of 500Mb to store just the
    collection! (See Borland's documentation on the TCollection
    object for a refresher on terminology.)
  - The TBigCollection can store any type of item: either a type that is
    up to 4 bytes in length, or as a pointer to any type.
  - Items can be inserted into the collection either in sorted or
    unsorted order. If the collection items are sorted, you can
    specify whether duplicate items can be inserted, or should cause
    an error. Note the differences here from TCollection: there is no
    separate object class for a sorted collection, and insertion of a
    duplicate item causes an error rather than being ignored.
  - There are three methods you will most likely override: FreeItem
    (to dispose of an item), Compare (to compare two items when the
    TBigCollection is sorted), and Error (to report an error). The
    default implementations are described below, but you would be
    advised to install your own routines.
  - No Load and Store methods have been written for this version.
---------------------------------------------------------------------}

{---Collection limits---}
const
  MaxItemsOnPage = $4000-1;
     {The maximum number of items on a page - 16,383 in decimal}
  MaxPagesInColl = ($4000 div 2)-1;
     {The maximum number of pages for a collection - 8,191 in decimal}

{---TBigCollection error codes---}
const
  bcErrNone        = 0;  {Error code: no error}
  bcErrOutOfRange  = 1;  {Error code: index is out of range}
  bcErrOutOfMemory = 2;  {Error code: unable to allocate required heap memory}
  bcErrDuplicate   = 3;  {Error code: duplicate item is already present}
  bcErrBug         = 4;  {Error code: programming bug}

{---Function and procedure types---}
type
  TbcEnumFunc = function  (Item : pointer) : boolean;
     {Type of the function for visiting items in the collection in
      sequential order until a condition is met}

  TbcEnumProc = procedure (Item : pointer);
     {Type of the function for visiting all items in the collection
      in sequential order}

{---TBigCollection subtypes and type---}
type
  PItemArray = ^TItemArray;
    {A pointer to a [TItemArray], an array of pointers}
  TItemArray = array [0..pred(MaxItemsOnPage)] of pointer;
    {Type for handling arrays of pointers (ie items)}

  TbcPage = record
    {Type that defines a page of items for the collection}
    bcpCount    : integer;       {The current number of items in a page}
    bcpMaxItems : integer;       {The page array size as a number of items}
    bcpItems    : PItemArray;    {The page's item array}
  end;

  PPageArray = ^TPageArray;
    {A pointer to a [TPageArray], an array of pages}
  TPageArray = array [0..pred(MaxPagesInColl)] of TbcPage;
    {Type that defines an array of pages for a collection}

  PBigCollection = ^TBigCollection;
    {A pointer to a [TBigCollection]}
  TBigCollection = object(TObject)
    {Type that defines a 'big' collection. This operates in the same way
     as the Borland Pascal TCollection object, but can hold more items, up
     to 134,193,153 items.}
    bcCount      : longint;    {The total items in the collection}
    bcNumPages   : integer;    {The current number of pages in the collection}
    bcMaxPages   : integer;    {The collection's page array size as a number of pages}
    bcSorted     : boolean;    {True if collection is to be kept in sorted order}
    bcDups       : boolean;    {True if duplicate items are allowed in a sorted collection}
    bcPages      : PPageArray; {The collection's array of pages}

    constructor Init(Sorted, AllowDups : boolean);
      {-Initialises a new TBigCollection - requires 24K free memory}
    destructor Done; virtual;
      {-Disposes of a collection, freeing all remaining items.}

    function  At(Index : longint) : pointer;
      {-Returns the item in the collection at position Index.}
    procedure AtDelete(Index : longint);
      {-Deletes the item at position Index from the collection, but does
        NOT free the item itself.}
    procedure AtFree(Index : longint);
      {-Deletes the item at position Index from the collection, and also
        frees it.}
    procedure AtInsert(Index : longint; Item : pointer);
      {-Inserts the new Item into the collection at position Index.}
    function  Compare(Item1, Item2 : pointer) : integer; virtual;
      {-Compares two items, returns a negative number if Item1 is less than
        Item2, 0 if they are equal, a positive number otherwise. The
        default implementation always return 0.}
    procedure Delete(Item : pointer);
      {-Deletes Item from the collection, but does NOT free it.}
    procedure DeleteAll;
      {-Deletes all items from the collection, freeing none of them.}
    procedure Error(Code : integer); virtual;
      {-Called if an error occurs during the object's processing. The
        default implementation ignores all errors.}
    function  FirstThat(CallRoutine : TbcEnumFunc) : pointer;
      {-Calls CallRoutine for each item in index order until CallRoutine
        returns true and then returns that item. If no item caused
        CallRoutine to return true, then bcFirstThat returns NIL.}
    procedure ForEach(CallRoutine : TbcEnumProc);
      {-Calls CallRoutine for each item in index order.}
    procedure Free(Item : pointer);
      {-Deletes Item from the collection, and then frees it.}
    procedure FreeAll;
      {-Deletes all items from the collection, and frees all of them.}
    procedure FreeItem(Item : pointer); virtual;
      {-Deallocates the memory pointed to by Item. The default
        implementation assumes Item is a TObject descendant and calls
        Dispose(Item, Done).}
    function  IndexOf(Item : pointer) : longint;
      {-Returns the positional index of Item in the collection, or -1 if
        not found.}
    procedure Insert(Item : pointer); virtual;
      {-Inserts Item into the collection.}
    function  Search(Item : pointer; var Index : longint) : boolean;
      {-Searches for Item in the collection; returns True and its Index if
        found, False if not.}

    {---Helper methods---}
    function  bcFoundItemInPage(PageNum : integer;
                                Item : pointer;
                            var IndexInPage : integer) : boolean;
    procedure bcFreePage(PageNum : integer);
    function  bcGetPageForIndex(Index : longint;
                            var IndexInPage : integer) : integer;
    function  bcGrowPage(PageNum : integer) : boolean;
    function  bcGrowPageArray : boolean;
    function  bcIndexIsValid(Index : longint) : boolean;
    function  bcMakeNewPage(var Page : TbcPage;                     {!!.01}
                            NumItems : word) : boolean;
  end;

implementation

{.$DEFINE UsePascal} { A debugging switch - should normally be off }

const
  {The page array start size *must* be even, between 2 and MaxPagesInColl}
  PageArrayStart = $400;  {ie 8K for the page array}

  {The item array start size *must* be even, between 2 and MaxItemsOnPage}
  ItemArrayStart = $1000; {ie 16K for each page}

{---Internal helper routines---}
function TBigCollection.bcIndexIsValid(Index : longint) : boolean;
  begin
    if (0 <= Index) and (Index < bcCount) then
      bcIndexIsValid := true
    else
      begin
        Error(bcErrOutOfRange);
        bcIndexIsValid := false;
      end;
  end;

function TBigCollection.bcGetPageForIndex(Index : longint;
                                      var IndexInPage : integer) : integer;
  {-Given an item index, returns the page number it appears in, and
    the index within that page. If the returned page number is -1,
    then the index or collection counts were invalid. BC is assumed
    valid.}
{$IFDEF UsePascal}
  var
    PageCount,
    PageNum : integer;
    WIndex  : longint;
  begin
    PageNum := 0;
    WIndex := Index;
    PageCount := bcPages^[PageNum].bcpCount;
    while (WIndex >= PageCount) do
      begin
        dec(WIndex, PageCount);
        inc(PageNum);
        if (PageNum >= bcNumPages) then
          begin
            {if we get to this point then the sum of all the
             bcpCounts is greater than bcCount itself}
            bcGetPageForIndex := -1;
            Error(bcErrBug);
            Exit;
          end;
        PageCount := bcPages^[PageNum].bcpCount;
      end;
    IndexInPage := WIndex;
    bcGetPageForIndex := PageNum;
  end;
{$ELSE}
assembler;
  const
    SizeOfPage = sizeof(TbcPage);
  asm
    mov dx, Index.Word[2]
    mov ax, Index.Word[0]
    xor bx, bx
    mov cx, bx
    les di, Self
    les di, es:[di].TBigCollection.bcPages
  @@NextPage:
    sub ax, es:[di].TbcPage.bcpCount
    sbb dx, bx
    jl @@FinishUp
    inc cx
    add di, SizeOfPage
    jmp @@NextPage
  @@FinishUp:
    add ax, es:[di].TbcPage.bcpCount
    les di, IndexInPage
    mov es:[di], ax
  @@SavePageNum:
    xchg ax, cx
  end;
{$ENDIF}

function TBigCollection.bcFoundItemInPage(PageNum : integer;
                                          Item : pointer;
                                      var IndexInPage : integer) : boolean;
  {-Tries to find Item in the given page PageNum via a sequential
    search. If found, returns true and the index of Item in the
    page, otherwise returns false. BC is assumed valid.}
{$IFDEF UsePascal}
  var
    i : integer;
    Found : boolean;
  begin
    i := 0;
    Found := false;
    with bcPages^[PageNum] do
      while (not Found) and (i < bcpCount) do
        if (bcpItems^[i] = Item) then
          begin
            Found := true;
            IndexInPage := i;
          end
        else
          inc(i);
    bcFoundItemInPage := Found;
  end;
{$ELSE}
assembler;
  asm
    { point ES:DI to the required page }
    les di, Self
    les di, es:[di].TBigCollection.bcPages
    mov ax, PageNum
  {$IFOPT G+}
    shl ax, 3
  {$ELSE}
    shl ax, 1; shl ax, 1; shl ax, 1
  {$ENDIF}
    add di, ax
    { get the count of items into CX, save it in DX }
    mov cx, es:[di].TbcPage.bcpCount
    mov dx, cx
    { now point ES:DI at the item array }
    les di, es:[di].TbcPage.bcpItems
    { get the item to check for in BX:AX }
    mov bx, Item.Word[2]
    mov ax, Item.Word[0]
    cld
  @@CheckNextItem:
    scasw
    jne @@NotEqual
    cmp bx, es:[di]
    jne @@NotEqual
    { the item has been found, calc IndexInPage }
    sub dx, cx
    mov ax, 1
    jmp @@Exit
  @@NotEqual:
    inc di; inc di
    loop @@CheckNextItem
    { if this point is reached the item is not there }
    xor ax, ax
    mov dx, ax
  @@Exit:
    les di, IndexInPage
    mov es:[di], dx
  end;
{$ENDIF}

function TBigCollection.bcGrowPageArray : boolean;
  {-Attempts to resize the collection's page array. If successful
    returns true, otherwise false. No errors are reported, but if
    it returns false it can be assumed to be an out-of-memory type
    error. The resizing process is an allocate new block, copy data,
    free old block type algorithm.}
  var
    NewNumPages,
    OldArraySize,
    NewArraySize   : word;
    NewPageArray   : PPageArray;
  begin
    bcGrowPageArray := false;
    if (bcMaxPages < MaxPagesInColl) then
      begin
        {Calc new size, and allocate it, exit if no memory}
        NewNumPages := bcMaxPages + PageArrayStart;
        if (NewNumPages > MaxPagesInColl) then
          NewNumPages := MaxPagesInColl;
        NewArraySize := NewNumPages*sizeof(TbcPage);
        GetMem(NewPageArray, NewArraySize);
        if (NewPageArray <> nil) then
          begin
            {Transfer old page array to new one, free old array}
            OldArraySize := bcMaxPages*sizeof(TbcPage);
            Move(bcPages^, NewPageArray^, OldArraySize);
            FreeMem(bcPages, OldArraySize);
            bcPages := NewPageArray;
            bcMaxPages := NewNumPages;
            bcGrowPageArray := true;
          end;
      end;
  end;

function TBigCollection.bcMakeNewPage(var Page : TbcPage;           {!!.01}
                                      NumItems : word) : boolean;
  {-Creates a new page. Allocates the required default memory for the
    item array as well, sets the page variables.}
  begin
    bcMakeNewPage := false;

    with Page do
      begin
        GetMem(bcpItems, NumItems*sizeof(pointer));                 {!!.01}
        if (bcpItems = nil) then Exit;
        bcpCount := 0;
        bcpMaxItems := NumItems;                                    {!!.01}
      end;

    bcMakeNewPage := true;
  end;

procedure TBigCollection.bcFreePage(PageNum : integer);
  {-Given a page number PageNum, frees the memory held by the page and
    adjusts the collection's page array. Always leaves at least one
    page present - in other words does not free the memory for the
    last page.}
  begin
    if (bcNumPages > 1) then
      begin
        {free the page array}
        with bcPages^[PageNum] do
          FreeMem(bcpItems, bcpMaxItems*sizeof(pointer));
        {squeeze out page element}
        dec(bcNumPages);
        if (PageNum < bcNumPages) then
          Move(bcPages^[PageNum+1], bcPages^[PageNum],
               (bcNumPages-PageNum)*sizeof(TbcPage));
      end;
  end;

function TBigCollection.bcGrowPage(PageNum : integer) : boolean;
  {-Attempts to resize the given page's item array. If successful
    returns true, otherwise false. No errors are reported, but if
    it returns false it can be assumed to be an out-of-memory type
    error. The resizing process is an allocate new block, copy data,
    free old block type algorithm.}
  var
    NewNumElems,
    OldArraySize,
    NewArraySize   : word;
    NewArray       : PItemArray;
  begin
    bcGrowPage := false;
    with bcPages^[PageNum] do
      if (bcpMaxItems < MaxItemsOnPage) then
        begin
          NewNumElems := bcpMaxItems + ItemArrayStart;
          if (NewNumElems > MaxItemsOnPage) then
            NewNumElems := MaxItemsOnPage;
          NewArraySize := NewNumElems*sizeof(pointer);
          GetMem(NewArray, NewArraySize);
          if (NewArray <> nil) then
            begin
              OldArraySize := bcpMaxItems*sizeof(pointer);
              Move(bcpItems^, NewArray^, OldArraySize);
              FreeMem(bcpItems, OldArraySize);
              bcpItems := NewArray;
              bcpMaxItems := NewNumElems;
              bcGrowPage := true;
            end;
        end;
  end;

{---Constructor / Destructor ---}
constructor TBigCollection.Init(Sorted      : boolean;
                                AllowDups   : boolean);
  begin
    if not TObject.Init then Fail;
    bcCount      := 0;
    bcNumPages   := 0;
    bcMaxPages   := 0;
    bcPages      := nil;

    GetMem(bcPages, PageArrayStart*sizeof(TbcPage));
    if (bcPages = nil) then Fail;

    if not bcMakeNewPage(bcPages^[0], ItemArrayStart) then          {!!.01}
      begin
        FreeMem(bcPages, PageArrayStart*sizeof(TbcPage));
        Fail;
      end;

    bcNumPages := 1;
    bcMaxPages := PageArrayStart;
    bcSorted := Sorted;
    if Sorted then
      bcDups := AllowDups
    else
      bcDups := false;
  end;

destructor TBigCollection.Done;
  begin
    {free all items and all pages ... except page 0}
    FreeAll;
    {free page 0}
    with bcPages^[0] do
      FreeMem(bcpItems, bcpMaxItems*sizeof(pointer));
    {free the page array}
    FreeMem(bcPages, bcMaxPages*sizeof(TbcPage));

    TObject.Done;
  end;

procedure TBigCollection.FreeItem(Item : pointer);
  begin
    {assumes a TObject descendant and done/disposes it}
    if (Item <> nil) then Dispose(PObject(Item), Done);
  end;

function  TBigCollection.Compare(Item1, Item2 : pointer) : integer;
  begin
    {returns equal}
    Compare := 0;
  end;

procedure TBigCollection.Error(Code : integer);
  begin
    {does nothing!}
  end;

{---Interfaced big collection routines---}
function  TBigCollection.At(Index : longint) : pointer;
  var
    InxInPage,
    PageNum  : integer;
  begin
    if bcIndexIsValid(Index) then
      begin
        PageNum := bcGetPageForIndex(Index, InxInPage);
        At := bcPages^[PageNum].bcpItems^[InxInPage];
      end
    else
      At := nil;
  end;

procedure TBigCollection.AtDelete(Index : longint);
  var
    InxInPage,
    PageNum  : integer;
  begin
    if bcIndexIsValid(Index) then
      begin
        PageNum := bcGetPageForIndex(Index, InxInPage);
        with bcPages^[PageNum] do
          begin
            dec(bcCount);
            dec(bcpCount);
            if (bcpCount = 0) then
              bcFreePage(PageNum)
            else
              if (InxInPage < bcpCount) then
                Move(bcpItems^[InxInPage+1], bcpItems^[InxInPage],
                     (bcpCount-InxInPage)*sizeof(pointer));
          end;
      end;
  end;

procedure TBigCollection.AtFree(Index : longint);
  var
    InxInPage,
    PageNum  : integer;
  begin
    if bcIndexIsValid(Index) then
      begin
        PageNum := bcGetPageForIndex(Index, InxInPage);
        with bcPages^[PageNum] do
          begin
            FreeItem(bcpItems^[InxInPage]);
            dec(bcCount);
            dec(bcpCount);
            if (bcpCount = 0) then
              bcFreePage(PageNum)
            else
              if (InxInPage < bcpCount) then
                Move(bcpItems^[InxInPage+1], bcpItems^[InxInPage],
                     (bcpCount-InxInPage)*sizeof(pointer));
          end;
      end;
  end;

procedure TBigCollection.AtInsert(Index : longint; Item : pointer);
  var
    AddToEnd,
    NeedNewPage : boolean;
    NumToMove,
    InxInPage,
    PageNum : integer;
    NewPage,
    FullPage: TbcPage;
  begin
    {take care of special case: adding to end of collection}
    if (Index = bcCount) then
      begin
        AddToEnd := true;
        PageNum := bcNumPages-1;
        InxInPage := bcPages^[PageNum].bcpCount;
      end
    {if Index is in range then find out page number normally}
    else if bcIndexIsValid(Index) then
      begin
        AddToEnd := false;
        PageNum := bcGetPageForIndex(Index, InxInPage);
      end
    {just exit if Index is invalid - it's been reported}
    else
      Exit;

    {Is page full up? If so either allocate another page and split
     this one, or if that's impossible grow this one}
    if (bcPages^[PageNum].bcpCount = bcPages^[PageNum].bcpMaxItems) then
      begin
        if (bcNumPages < bcMaxPages) then                           {!!.01}
          NeedNewPage := true                                       {!!.01}
        else {the page array is full, so...}                        {!!.01}
          if bcGrowPageArray then
            NeedNewPage := true
          else if bcGrowPage(PageNum) then
            NeedNewPage := false
          else
            begin
              Error(bcErrOutOfMemory);
              Exit;
            end;

        {create a new page if required}
        if NeedNewPage then
          begin
            if not bcMakeNewPage(NewPage, bcPages^[PageNum].bcpMaxItems) then {!!.01}
              begin
                Error(bcErrOutOfMemory);
                Exit;
              end;

            {a choice: if we're trying to add a new page to the end of
             a collection, do it, and reset InxInPage and PageNum}
            if AddToEnd then
              begin
                bcPages^[bcNumPages] := NewPage;
                inc(bcNumPages);
                inc(PageNum);
                InxInPage := 0;
              end
            else {otherwise, slot the new page in, split the page etc}
              begin
                {move half the items in page PageNum to new page}
                with bcPages^[PageNum] do
                  begin
                    NumToMove := bcpMaxItems div 2;
                    dec(bcpCount, NumToMove);                       {!!.01}
                    Move(bcpItems^[bcpCount],                       {!!.01}
                         NewPage.bcpItems^[0],
                         NumToMove*sizeof(pointer));
                   {dec(bcpCount, NumToMove);                deleted !!.01}
                    NewPage.bcpCount := NumToMove;
                  end;

                {slot new page in PageArray just after page PageNum}
                if (PageNum < bcNumPages-1) then
                  Move(bcPages^[PageNum+1], bcPages^[PageNum+2],
                       (bcNumPages-1-PageNum)*sizeof(TbcPage));
                bcPages^[PageNum+1] := NewPage;
                inc(bcNumPages);

                {recalc InxInPage if necessary}
                if (InxInPage > NumToMove) then
                  begin
                    dec(InxInPage, NumToMove);
                    inc(PageNum);
                  end;
              end;
          end;
      end;

    with bcPages^[PageNum] do
      begin
        if (InxInPage < bcpCount) then
          Move(bcpItems^[InxInPage], bcpItems^[InxInPage+1],
               (bcpCount-InxInPage)*sizeof(pointer));
        bcpItems^[InxInPage] := Item;
        inc(bcpCount);
        inc(bcCount);
      end;
  end;

procedure TBigCollection.Delete(Item : pointer);
  var
    Index : longint;
  begin
    Index := IndexOf(Item);
    if (Index <> -1) then
      AtDelete(Index);
  end;

procedure TBigCollection.DeleteAll;
  var
    PageNum : integer;
  begin
    {dispose all pages except page 0}
    for PageNum := (bcNumPages-1) downto 1 do
      bcFreePage(PageNum);
    {force item counts to zero}
    bcPages^[0].bcpCount := 0;
    bcCount := 0;
  end;

function  TBigCollection.FirstThat(CallRoutine : TbcEnumFunc) : pointer;
{$IFDEF UsePascal}
  var
    InxInPage,
    PageNum : integer;
  begin
    FirstThat := nil;
    if (bcCount = 0) then Exit;

    for PageNum := 0 to bcNumPages-1 do
      with bcPages^[PageNum] do
        for InxInPage := 0 to bcpCount-1 do
          if CallRoutine(bcpItems^[InxInPage]) then
            begin
              FirstThat := bcpItems^[InxInPage];
              Exit;
            end;
  end;
{$ELSE}
assembler;
  const
    SizeOfPage = sizeof(TbcPage);
    SizeOfPtr  = sizeof(pointer);
  var
    ItemArray,
    PageArray : pointer;
  asm
    { check whether any elements exist }
    les di, Self
    mov ax, es:[di].TBigCollection.bcCount.Word[2]
    or  ax, es:[di].TBigCollection.bcCount.Word[0]
    jnz @@ElemsExist
    jmp @@NoItemFound
  @@ElemsExist:
    { get the number of pages in CX }
    mov cx, es:[di].TBigCollection.bcNumPages
    { set ES:DI to point to the page array, save it }
    les di, es:[di].TBigCollection.bcPages
    mov PageArray.Word[2], es
  @@ProcessPage:
    { save our page counter, and offset }
    mov PageArray.Word[0], di
    push cx
    { get number of elements in CX }
    mov cx, es:[di].TbcPage.bcpCount
    { set ES:DI to point to the item array, save it }
    les di, es:[di].TbcPage.bcpItems
    mov ItemArray.Word[2], es
  @@ProcessItem:
    { save our item counter, and offset }
    mov ItemArray.Word[0], di
    push cx
    { call the user routine, check reply }
    push es:[di].Word[2]
    push es:[di].Word[0]
    call CallRoutine
    les di, ItemArray
    or al, al
    jz @@WasFalse
    { the user routine returned true; return the item }
    add sp, 4  { pop the two CX counts }
    mov dx, es:[di].Word[2]
    mov ax, es:[di].Word[0]
    jmp @@Exit
  @@WasFalse:
    { go process next item }
    pop cx
    add di, SizeOfPtr
    loop @@ProcessItem
    { go process next page (if any) }
    pop cx
    les di, PageArray
    add di, SizeOfPage
    loop @@ProcessPage
    { if we reach here the user routine never returned true, so
      return nil ourselves }
  @@NoItemFound:
    xor ax, ax
    mov dx, ax
  @@Exit:
  end;
{$ENDIF}

procedure TBigCollection.ForEach(CallRoutine : TbcEnumProc);
{$IFDEF UsePascal}
  var
    InxInPage,
    PageNum : integer;
  begin
    if (bcCount = 0) then Exit;

    for PageNum := 0 to bcNumPages-1 do
      with bcPages^[PageNum] do
        for InxInPage := 0 to bcpCount-1 do
          CallRoutine(bcpItems^[InxInPage]);
  end;
{$ELSE}
assembler;
  const
    SizeOfPage = sizeof(TbcPage);
    SizeOfPtr  = sizeof(pointer);
  var
    ItemArray,
    PageArray : pointer;
  asm
    { check whether any elements exist }
    les di, Self
    mov ax, es:[di].TBigCollection.bcCount.Word[2]
    or  ax, es:[di].TBigCollection.bcCount.Word[0]
    jnz @@ElemsExist
    jmp @@Exit
  @@ElemsExist:
    { get the number of pages in CX }
    mov cx, es:[di].TBigCollection.bcNumPages
    { set ES:DI to point to the page array, save it }
    les di, es:[di].TBigCollection.bcPages
    mov PageArray.Word[2], es
  @@ProcessPage:
    { save our page counter, and offset }
    mov PageArray.Word[0], di
    push cx
    { get number of elements in CX }
    mov cx, es:[di].TbcPage.bcpCount
    { set ES:DI to point to the item array, save it }
    les di, es:[di].TbcPage.bcpItems
    mov ItemArray.Word[2], es
  @@ProcessItem:
    { save our item counter, and offset }
    mov ItemArray.Word[0], di
    push cx
    { call the user routine }
    push es:[di].Word[2]
    push es:[di].Word[0]
    call CallRoutine
    { go process next item }
    pop cx
    les di, ItemArray
    add di, SizeOfPtr
    loop @@ProcessItem
    { go process next page (if any) }
    pop cx
    les di, PageArray
    add di, SizeOfPage
    loop @@ProcessPage
  @@Exit:
  end;
{$ENDIF}

procedure TBigCollection.Free(Item : pointer);
  var
    Index : longint;
  begin
    Index := IndexOf(Item);
    if (Index <> -1) then
      AtFree(Index);
  end;

procedure TBigCollection.FreeAll;
  var
    OrigNumPages,
    PageNum,
    InxInPage   : integer;
  begin
    {free each item}
    for PageNum := 0 to bcNumPages-1 do
      with bcPages^[PageNum] do
        for InxInPage := 0 to bcpCount-1 do
          FreeItem(bcpItems^[InxInPage]);
    {free all pages (except the first)}
    for PageNum := bcNumPages-1 downto 1 do
      bcFreePage(PageNum);
    {force item counts to zero}
    bcPages^[0].bcpCount := 0;
    bcCount := 0;
  end;

function  TBigCollection.IndexOf(Item : pointer) : longint;
  var
    Index   : longint;
  begin
    if Search(Item, Index) then
         IndexOf := Index
    else IndexOf := -1;
  end;

procedure TBigCollection.Insert(Item : pointer);
  var
    FoundItem : boolean;
    Index     : longint;
  begin
    if bcSorted then
      begin
        FoundItem := Search(Item, Index);
        if FoundItem and (not bcDups) then
          Error(bcErrDuplicate)
        else
          AtInsert(Index, Item);
      end
    else { BC is not sorted, insert at end }
      AtInsert(bcCount, Item);
  end;

function  TBigCollection.Search(Item : pointer; var Index : longint) : boolean;
  var
    FoundItem : boolean;
    Result,
    i,
    PageNum,
    InxInPage,
    FoundPage : integer;
    WIndex,
    L, R, M  : longint;
  begin
    Search := false;
    Index := 0;
    if (bcCount = 0) then Exit;

    if bcSorted then {do binary search}
      begin
        L := 0;
        R := bcCount-1;
        repeat
          M := (L+R) shr 1;
          PageNum := bcGetPageForIndex(M, InxInPage);
          Result := Compare(Item, bcPages^[PageNum].bcpItems^[InxInPage]);
          if (Result < 0) then
               R := M - 1
          else L := M + 1;
        until (Result = 0) or (L > R);
        if (Result > 0) then
          inc(M);
        Index := M;
        Search := Result = 0;
      end
    else {BC is not sorted: do sequential search}
      begin
        PageNum := 0;
        FoundItem := false;
        WIndex := 0;
        while (not FoundItem) and (PageNum < bcNumPages) do
          begin
            if bcFoundItemInPage(PageNum, Item, InxInPage) then
              begin
                FoundItem := true;
                Index := WIndex + InxInPage;
                Search := true;
              end
            else
              begin
                inc(WIndex, bcPages^[PageNum].bcpCount);
                inc(PageNum);
              end;
          end;
      end;
  end;

end.

