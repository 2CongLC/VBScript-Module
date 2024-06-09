'Coder : 2CongLc.Vn
'File Name : ResetAttribs.vbs | ResetAttribs.cmd
'Version : Public/Release 1.5.17
Option Explicit

Dim WS : Set WS = CreateObject("WSCript.Shell")
Dim SA : Set SA = CreateObject("Shell.Application")
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

Dim Root
If WScript.Arguments.Count <> 0 Then
 Set Root = FSO.GetFolder(FSO.GetParentFolderName(WScript.Arguments.Item(0)))
Else
 Set Root = FSO.GetFolder(FSO.GetParentFolderName(WScript.ScriptFullName))
End if 

ScanFolders Root


Private Sub ScanFolders(cmd)
 Processes cmd.Path
 Dim i
 For Each i In cmd.SubFolders
    ScanFolders i
  Next
End Sub


Private Sub Processes(ByRef cmd)
 Dim CDir : Set CDir = FSO.GetFolder(cmd)
 If FSO.FolderExists(CDir) Then Reset(CDir)
 Dim i
 For Each i in CDir.Files
  If FSO.FileExists(i) Then Reset(i)
 Next
End Sub

Private Sub Reset(ByRef cmd)
 If cmd.Attributes <> 0 Then
  cmd.Attributes = 0
 End if
End Sub


Set WS = Nothing
Set SA = Nothing
Set FSO = Nothing
