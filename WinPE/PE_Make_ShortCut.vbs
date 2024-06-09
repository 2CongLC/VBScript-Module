'Coder : 2CongLc.Vn
'File Name : Make_ShortCut.vbs
'Version : Public/Release 1.5.17
Option Explicit

Dim WS : Set WS = CreateObject("WSCript.Shell")
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")
Dim Name : Name = "PassMark OSF Mount"
Dim EXE : EXE = "OSFMount.exe"
Dim Folder : Folder = "OSFMount" & "\"
Dim Local : Local = "X:\Program Files\Tools\" & Folder
Dim CDir : CDir = FSO.GetParentFolderName(WSCript.ScriptFullName) & "\"



Dim link: Set link = WS.CreateShortcut(CDir & Name & ".lnk")
 With link
 .TargetPath = WS.ExpandEnvironmentStrings("%ProgramFiles%") & "\Tools\" & Folder & EXE
 .Arguments = ""
 .Description = ""
 .HotKey = ""
 .IconLocation = Local & EXE & ", 0"
 '.IconLocation = WS.ExpandEnvironmentStrings("%Systemroot%") & "\System32\Shell32.dll, 26" 
 .WindowStyle = "1"
 .WorkingDirectory = Local
 .Save
 End With

Set link = Nothing
Set WS = Nothing
Set FSO = Nothing
