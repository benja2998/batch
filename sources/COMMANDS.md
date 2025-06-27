# Command list for Windows Batch Script

ASSOC
Displays or modifies file extension associations.

```cmd
ASSOC .ext=FileType
ASSOC
```

ATTRIB
Displays or changes file attributes.

```cmd
ATTRIB +R +S +H file.txt
ATTRIB -R -S -H file.txt
ATTRIB
```

BREAK
Sets or clears extended CTRL+C checking.([ninjaone.com][1])

```cmd
BREAK ON
BREAK OFF
```

BCDEDIT
Sets boot configuration data.

```cmd
BCDEDIT /set {bootmgr} displayorder {current} /addfirst
```

CACLS
Displays or modifies access control lists (ACLs) of files.

```cmd
CACLS file.txt /E /G User:F
```

CALL
Calls one batch program from another.

```cmd
CALL batchfile.bat
```

CD
Displays the current directory or changes the current directory.

```cmd
CD
CD path
```

CHCP
Displays or sets the active code page number.([en.wikipedia.org][2])

```cmd
CHCP
CHCP 437
```

CHDIR
Displays the current directory or changes the current directory.

```cmd
CHDIR
CHDIR path
```

CHKDSK
Checks a disk and displays a status report.

```cmd
CHKDSK C:
CHKDSK C: /F
```

CHKNTFS
Displays or modifies the checking of disk at boot time.

```cmd
CHKNTFS C:
CHKNTFS /D
```

CLS
Clears the screen.

```cmd
CLS
```

CMD
Starts a new instance of the Windows command interpreter.

```cmd
CMD
```

COLOR
Sets the default console foreground and background colors.

```cmd
COLOR 0A
```

COMP
Compares the contents of two files or sets of files.

```cmd
COMP file1.txt file2.txt
```

COMPACT
Displays or alters the compression of files on NTFS partitions.

```cmd
COMPACT
COMPACT /C /S:"C:\Folder" *.txt
```

CONVERT
Converts FAT volumes to NTFS.

```cmd
CONVERT C: /FS:NTFS
```

COPY
Copies one or more files to another location.([ninjaone.com][1])

```cmd
COPY file1.txt D:\
COPY *.txt D:\Backup\
```

DATE
Displays or sets the date.([en.wikipedia.org][3])

```cmd
DATE
DATE MM-DD-YY
```

DEL
Deletes one or more files.

```cmd
DEL file.txt
DEL *.txt
```

DIR
Displays a list of files and subdirectories in a directory.([ninjaone.com][1])

```cmd
DIR
DIR /S
```

DISKPART
Displays or configures disk partitions.

```cmd
DISKPART
LIST DISK
SELECT DISK 1
```

DOSKEY
Edits command lines, recalls Windows commands, and creates macros.([phoenixnap.com][4])

```cmd
DOSKEY
DOSKEY macro=command
```

DRIVERQUERY
Displays current device driver status and properties.

```cmd
DRIVERQUERY
```

ECHO
Displays messages or turns command echoing on or off.

```cmd
ECHO Hello, World!
ECHO OFF
```

ENDLOCAL
Ends localization of environment changes in a batch file.

```cmd
ENDLOCAL
```

ERASE
Deletes one or more files.

```cmd
ERASE file.txt
ERASE *.txt
```

EXIT
Exits the CMD.EXE program (command interpreter).

```cmd
EXIT
```

FC
Compares two files or sets of files and displays the differences.

```cmd
FC file1.txt file2.txt
```

FIND
Searches for a text string in a file or files.([ninjaone.com][1])

```cmd
FIND "text" file.txt
```

FINDSTR
Searches for strings in files.

```cmd
FINDSTR "text" *.txt
```

FOR
Runs a specified command for each file in a set of files.

```cmd
FOR %f IN (*.txt) DO ECHO %f
```

FORMAT
Formats a disk for use with Windows.

```cmd
FORMAT D: /FS:NTFS
```

FSUTIL
Displays or configures file system properties.

```cmd
FSUTIL 8dot3name set C: 0
```

FTYPE
Displays or modifies file types used in file extension associations.

```cmd
FTYPE txtfile="C:\Program Files\Notepad++\notepad++.exe" "%1"
```

GOTO
Directs the Windows command interpreter to a labeled line in a batch program.

```cmd
GOTO label
```

GPRESULT
Displays Group Policy information for a machine or user.

```cmd
GPRESULT /R
```

HELP
Provides help information for Windows commands.

```cmd
HELP
HELP command
```

ICACLS
Displays, modifies, or backs up ACLs for files and directories.

```cmd
ICACLS file.txt /grant User:F
```

IF
Performs conditional processing in batch programs.

```cmd
IF EXIST file.txt ECHO File exists
```

LABEL
Creates, changes, or deletes the volume label of a disk.

```cmd
LABEL D: NewLabel
```

MD
Creates a directory.

```cmd
MD newdir
```

MKDIR
Creates a directory.

```cmd
MKDIR newdir
```

MKLINK
Creates symbolic links and hard links.([en.wikipedia.org][5])

```cmd
MKLINK link target
```

MODE
Configures system devices.([en.wikipedia.org][2])

```cmd
MODE CON: COLS=80 LINES=25
```

MORE
Displays output one screen at a time.

```cmd
MORE file.txt
```

MOVE
Moves one or more files from one directory to another.

```cmd
MOVE file.txt D:\
```

OPENFILES
Displays files opened by remote users for file sharing.

```cmd
OPENFILES
```

PATH
Displays or sets a search path for executable files.

```cmd
PATH
PATH C:\Program Files\Java\bin
```

PAUSE
Suspends processing of a batch file and displays a message.([en.wikipedia.org][2])

```cmd
PAUSE
```

POPD
Restores the previous value of the current directory saved by PUSHD.([en.wikipedia.org][2])

```cmd
POPD
```

PRINT
Prints a text file.

```cmd
PRINT file.txt
```

PROMPT
Changes the command prompt.

```cmd
PROMPT $P$G
```

PUSHD
Saves the current directory and changes to a new one.

```cmd
PUSHD path
```

RD
Removes a directory.

```cmd
RD dir
```

RECOVER
Recovers readable information from a bad or defective disk.

```cmd
RECOVER D:\
```

REM
Records comments (remarks) in batch files or CONFIG.SYS.

```cmd
REM This is a comment
```

REN
Renames a file or files.([ninjaone.com][1])

```cmd
REN oldname.txt newname.txt
```

RENAME
Renames a file or files.([ninjaone.com][1])

```cmd
RENAME oldname.txt newname.txt
```

REPLACE
Replaces files.

```cmd
REPLACE source destination
```

RMDIR
Removes a directory.

```cmd
RMDIR dir
```

ROBOCOPY
Advanced utility to copy files and directories.

```cmd
ROBOCOPY source destination /E
```

SET
Displays, sets, or removes environment variables for the current session.

```cmd
SET VAR=value
SET
```

SETLOCAL
Begins localization of environment changes in a batch file.

```cmd
SETLOCAL
```

SC
Displays or configures services (background processes).

```cmd
SC QUERY
SC STOP service
```

SCHTASKS
Schedules commands and programs to run on a computer.

```cmd
SCHTASKS /CREATE /SC DAILY /TN "Backup" /TR "backup.bat" /ST 02
```

[1]: https://www.ninjaone.com/blog/windows-cmd-commands/?utm_source=chatgpt.com "38 Windows CMD Commands You Need To Know - NinjaOne"
[2]: https://en.wikipedia.org/wiki/List_of_DOS_commands?utm_source=chatgpt.com "List of DOS commands"
[3]: https://en.wikipedia.org/wiki/CLS_%28command%29?utm_source=chatgpt.com "CLS (command)"
[4]: https://phoenixnap.com/kb/cmd-commands?utm_source=chatgpt.com "Windows CMD Commands: Mastering the Command Prompt"
[5]: https://en.wikipedia.org/wiki/Diskpart?utm_source=chatgpt.com "Diskpart"
