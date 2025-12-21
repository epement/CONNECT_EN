                CONNECT Fixes

12.08.94 15.01

1. Find All List now copies the contents into Clipboard (Ctrl+Ins).
2. Clipboard selected area bug fixed.
3. Find File Dialog now prompts for action if too many files are found;
   Info pane with current file name/selected size was added;
   Selection remains after closing the dialog.

12.15.94 15:30

1. File Copy routine: Split Copy bug fixed.
   Status line shows each copied portion and percentage.
2. Optimal Fill now prompts for more when finished.
3. Options³File Manager: Incremental search options added.
4. Editor: Make dir at cursor reports if the file/directory already
   exists.

21.12.94 15:05

1. Options³File Manager: File group options added;
   <Groups> button added. The Groups command calls File group list dialog
   that allows you to specify file name masks, highlight attributes and
   group sort indexes. The panels now are brightly-feathered and gay...

22.12.94 10:30

1. Options³File Manager: Draw empty panel flag added to FM options
   to make File Manager optionally behave like The Norton Commander:
   before reading the specified directory it 'clears the screen'.

23.12.94 10:00

1. Description file reading routine:
   Pressing Esc now has no effect... And you may write a description
   for upper directory (..).

27.12.94 09:41

1. Find File Dialog bug fixed. <Go to> command positioned the panel cursor
   on the wrong file name. The bug was caused by the new sort method
   (group indexes). Binary search failed when no index was specified.

28.12.94 11:14

1. Options³File Manager: Copy/rename/delete descriptions flag added.
   Descriptions are copied, renamed or deleted along with files, just
   like 4DOS does it.
   Unselect same files flag added to File compare options.

03.01.95 13:00

1. Find File Dialog bug fixed. If you select an item and then
   find it again with the <Search> command, it unexpectedly becomes
   unselected, but Selected count/size displayed at the bottom
   of the list remains unchanged. The bug existed since long ago,
   but became visible 12.08.94, when info pane was inserted
   into the Find File Dialog.
2. Status Line updates itself each time after drawing dynamic status
   like 'Reading the directory D:\BP.', so that all keyboard/mouse
   events are now hopefully handled in a correct way.

05.01.95 10:17

1. Some improvements were made to <Select valid drive> error dialog:
   TInputLine object was replaced by a new one which now looks more
   like the Norton Commander's.

09.01.95 13:33

1. SYSTEM.PAS Readln(Text, String) routine was slightly modified
   to always read less than SizeOf(String) bytes, even if CRLF
   was not found upon buffer scan.

13.01.95 14:56

1. Text file viewer added.
2. Color dialog: if you hold Ctrl key down, the <Default> command
   sets default color only for currently focused item.

16.01.95 10:30

1. The <Paste> command was forced not to select directories
   in File Manager panels.
2. File Manager <Restore selection> routine fixed slightly.
3. <Set file attribute> procedure unselects and redraws the panel
   each time the attrribute is set.
4. The <Wrap/Unrap> command added to Text file viewer.

17.01.95 10:27

1. Hex Editor Find All List bug fixed. It simply didn't work.
2. The <Find all> and <Show all found> commands added to Text file viewer.

20.01.95 10:19

1. Panel Dir History bug fixed.
2. Alt+N, Alt+Z (the <Next> and <Zoom> commands missing earlier)
   added to Text file viewer.

24.01.95 14:04

1. Hex file viewer added.
2. Editor options: the <Highlight current line> and <Add matching chars>
   flags added.

25.01.95 10:20

1. Both ASCII and Hex Editor Shift+Tab bug fixed.
2. File Manager: Ctrl+[ and Ctrl+] keystrokes now insert a string,
   consisting of backslashed left/right panel path, into the Prompt line.
   That was made for compatibility with VC and DN.
   Toggle <Display directory sizes> flag hot key is now Ctrl+Minus
   instead of Ctrl+]. The whole routine was reviewed and some bugs fixed.
3. The <Restore selection> command bug fixed (when applied to a Tree panel).
4. The <Ignore selection> (Alt+I) command added to File Manager
   Miscellaneous commands to optionally handle single files (directories)
   at cursor, even if some files have been selected. This way you always
   see file info at the bottom of the panel instead of selected count/size.
5. Free disk space is displayed when Drives icon (:) is focused in panel:

    Drives  87,964,322 bytes free on D:

   This feature appears to be especially useful when user selects
   a floppy drive, so he can see the amount of free space on it
   the very moment the panel is redrawn. The <Enable Drive panel>
   flag (Ctrl+D) must be set to enable this feature.

26.01.95 10:40

1. File Editor: Ctrl+Q+[, or Ctrl+Q+], or Ctrl+Q+Esc keystrokes search
   for pair character to match the symbol at cursor (Borland IDE style).
   Characters that match: (), [], {}, '', "".
   Feature not documented (same Borland IDE style).

27.01.95 09:03

1. Keyboard options: The <Use INT 09 key handler> flag is added to
   the dialog to enable or disable standard keystroke interrupt handler
   while Up and Down arrows are pressed. If the flag is set, the
   vertical scroll speed is no longer adjustable, and all keyboard events
   are handled as usual instead of undocumented Port[$60] readings.

03.02.95 15:28

1. The <Unfold subdirectories> (Alt+B) command added to File Manager
   Miscellaneous commands to display files in subdirectories.

06.02.95 15:30

1. System information: a brand-new routine is used to detect the
   CPU/CoCPU type and calculate CPU speed. Supposed to identify all
   Intel compatible types currently in use.
   (Copyright(c) 1993-95 by B-coolWare. Written by Bobby Z.) Thanks.
2. Selection bug fixed: Ins, Ctrl+I, Ctrl+B.

08.02.95 13:09

1. Completely new History system was developed. If you press Ins in a
   History window, the item at cursor becomes 'locked', that is,
   it never gets dropped off by newer items. Items that are not locked
   may be dropped off the top of the list only if a new item with
   the same history ID is added, and History count reaches History limit
   (see Options³Setup). If you then lock all items in the window, no more
   lines will be added to this particular History list.
   Undocumented feature: the <Clear history> command does not remove
   locked History items if Ctrl+Alt keys are held down.
2. All Message boxes now handle Right and Left arrow keystrokes as
   Tab/Shift+Tab.

09.02.95 10:29

1. Pop-up menus added to both Text and Hex viewer windows.
2. The Text viewer <Go to block begin/end> bug fixed (or rather
   an attempt was made).
3. The <Copy to Clipboard> command bug fixed: if a single copied line was
   exactly 255 characters long, the Clipboard window displayed no
   selection at all.

13.02.95 09:12

1. The CPU speed calculation routine bug fixed.

14.02.95 14:18

1. File Manager Sort routine slightly modified.
2. The <Update description file> log event reassigned.
3. Terminal Dialer now works as a background task (to be precise,
   everything else does).

15.02.95 - ??.04.95

1. The Text viewer <Go to place marker> bug fixed.
2. Text/Hex Editors and Hex Viewer now set the original attribute
   to the modified file after saving it to disk.
3. Options³Overlay: Setting new overlay defaults does not change
   date/time stamp of the file CONNECT.EXE.
4. Options³File Manager: The <Display directory sizes> flag was
   replaced by the <Check free disk space before Copy> flag to
   optionally speed up the Copy routine.
5. File Manager: The <Display directory sizes> flag menu item was
   added to the Panel Pop-up Miscellaneous submenu. Pressing Ctrl+Minus
   now toggles this flag for current panel only.
6. Text editor: matching brackets are inserted only if the character
   at cursor is a whitespace.
7. File Manager: The <Archivers> and <Open archive> commands are added
   to the Panel Pop-up Miscellaneous submenu to support archive handling
   (not completed yet).
8. The Copy/Rename/Delete descriptions bug fixed (Files that have same
   name, but different extension).
9. File Manager panel: Del keystroke deletes items (focused or selected).
10. New command line directives added: $LEFT, $RIGHT, $OPPOSITE.
11. File Manager panel and Find File List: The <Cut> command (Shift+Del)
    unselects file names that are selected in the Clipboard (contrary
    to the <Paste> command).
12. File Copy routine: yet another Copy bug fixed.
    If you get a Message box like

    ÉÍ[ş]ÍÍÍÍÍÍÍÍÍÍ Warning ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
    º                                      º
    º    There is not enough free space    º
    º  on drive A: to copy "newfile.new".  º
    º    Copy and continue on new disk ?   º
    º                                      º
    º     Yes   Ü      No   Ü    Cancel Ü  º
    º    ßßßßßßßß    ßßßßßßßß    ßßßßßßßß  º
    ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼
    and replace or remove the disk in drive A: before closing the dialog,
    the newly created file remains unclosed, and you'll get troubles
    with lost clusters, critical system errors and things like that.
13. Alt+key (C, L, T...) troubles fixed.
14. Panel <Sort by size/time> bugs fixed (maybe).
15. The <Save directory selection> flag and <Clear selection list> command
    are added to support saveable tags throughout all directories.
16. Find File Dialog enhanced (tags) and still there are things to be done
    (search through archives, current dir etc.).
17. History lock bug fixed (Editor and Viewer windows did not store
    the lock flag).
18. A newer version of CPU/CoCPU detection code implemented.
    (Copyright(c) 1993-95 by B-coolWare. Written by Bobby Z.).
19. Alt+Ins keystroke inserts Current Dir into all modal input lines.
20. The <Selection jams> flag added to File Manager group options
    to enable or disable group highlight when there are selected items
    in panel.
21. The Optimal Fill enabled while copying from an archive.
22. The Copy³Filter bug fixed (copying a directory from/to an archive).
23. The Text/Hex viewer filename is now removed from the History list
    if the viewer was opened from within an archive.
24. A new color item <highlighted text> added to File Manager palette
    (different to <selected text>).
25. Redraw after Exec: now panels redraw themselves smoothly.
26. MkDir: little bug fixed (..\SOMEDIR).
27. File Manager Group Color & Index search optimized.
    (Read directory procedure is now up to two times faster).
28. Ignore selection bug fixed (Set file attributes, Copy to Clipboard).
29. Archive open error horrible bug fixed (total shutdown).
30. Find File Dialog: Search in archives routine completed.
    Tagged filenames are displayed as selected.
31. Set file attributes & time: seconds too can be set now.
32. Message window now supports text viewer:
    Ctrl+Enter - Go to source, Ctrl+Space - Track source.
33. The <Write filename to History> command added to the Panel
    Pop-up Miscellaneous submenu to support quick search of the stored
    position in panel.
34. Copy/RenMov Directory bug fixed (Rename OLDNAME.EXT to NEWNAME.*).
35. File Copy/RenMov routines: <The file already exists> dialog displays
    time and size of both new and existing files.
36. The <Adjust> command added to Alarm List Dialog.
37. The <Disable auto re-reads> flag added to File Manager options
    to optionally speed up work under certain circumstances (large or
    unfolded directories etc.).
38. The Tree routines have been completely rewritten.
39. Copy description routine bug fixed (Destination file not closed).
40. Tree in Archives.
41. Copy selected Dir from archive bug fixed (no files copied).
42. <Auto change dir> mode enhanced. Current directory in the Tree
    is marked.
43. Editor Replace bug fixed.
44. Copy/RenMov descriptions optimized.
45. Wildcard bug fixed (????1234.123 = NO  1234.123).
46. The <Restore video mode> flag added to Setup³Display.
47. The <Setup³Auto save> options slightly changed.
48. Incremental search fixed ('.' and BackSpace).
49. The <Load current directory> flag added to File Manager options.
50. The <Alt/Ctrl activates/aborts> flags added to File Manager
    incremental search options (DN-like).
51. The <Return to last directory> flags added to Options³Setup.
52. The File Manager command line passes commands like
      C:, D:\CONNECT\, CD E:\DOC, etc
    to the active panel, causing it to change to the specified directory.
53. The <View directory info> command (F3 on dir) updates the Treeinfo.cn
    file if subdirectories on disk are not found in the list.
54. $VIEW, $XVIEW, $ARC macros handling rewritten.
55. New macros added: $NOSWAPMSG, $SWAPDIR, $REPORT.
56. Copy descriptions bug fixed.
57. Multi exec added (not tested yet).
58. Esc keystroke now aborts the Read Archive procedure.
59. New mask macros and filters added: $POS(), $UP(), $DOWN().
60. Text viewer VScrollBar fixed.
61. New macros added: $EDIT, $XEDIT.
62. Text editor <Move block> bug fixed.
63. New macro added: $USERSCR.
64. Text viewer Search and Go to Pos bug fixed.
65. The <Reload as ASCII> command turns current Text viewer window
    into Text editor. The <Reload as Hex> command does the same trick
    with Hex viewer window.
66. Tree search with auto change dir bug fixed.
67. Quick <Out of archive> hot key added: Ctrl+Up.




                       What should be done.



1. Shift-F1 ¤®«¦¥­ ¢ë§ë¢ âì ¢â®à®© ª®­â¥ªáâ ¯®¤ª«îç¥­­®£® å¥«¯ 
2. Dialer ¯®á«¥ ¯®ï¢«¥­¨ï CD ¯®áë« ¥â Redial string
3. •®à®è® ¡ë, çâ®¡ë Dialer ¢ ¯à®æ¥áá¥ ¤®§¢®­  ¯®ª §ë¢ « ¢ áâ âãá-áâà®ª¥
   ¯à®æ¥áá ã¬¥­ìè¥­¨ï Redial time, çâ®¡ë ¡ë«® ¢¨¤­® áª®«ìª® ¢à¥¬¥­¨ ®áâ «®áì.
4. à¨ ­ ¦ â¨¨ ­  ¯à®¡¥« Dialer ¤®«¦¥­ ¯¥à¥å®¤¨âì ­  á«¥¤ãîé¨© ¢ ®ç¥à¥¤¨
   ­®¬¥à. ¥à¥§¢®­ ¯® â¥ªãé¥¬ã, ¥á«¨ ¨ ¤¥« âì, â® ¯®¢¥á¨âì áª ¦¥¬ ­ 
   Ctrl-Space
5. ‚ á¯¨áª¥ ®ª®­ Back ¯®ª §ë¢ ¥âáï ª ª NONAME
6. •®à®è® ¡ë, çâ®¡ë ¨§ â¥à¬¨­ «  ®ª®èª® Dialer ¢ë§ë¢ «®áì £®àïç¥© ª« ¢¨è¥©,
   ­ ¯à¨¬¥à Alt-I
7. Alt+Number ¢ ¨áâ®à¨¨.

ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³2. Async + Icon error 204 ?                            ³
³3. SysInfo: OS/2 bug. ?                                ³
³4. SysInfo: NWDos bug.                                 ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
