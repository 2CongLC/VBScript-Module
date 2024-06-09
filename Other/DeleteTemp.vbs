'Coder : 2CongLc.Vn
'File Name : DeleteTemp.vbs
'Version : Public/Release 12.09.2020
Option Explicit

Dim WS : Set WS = CreateObject("WScript.Shell")
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")
Dim SA : Set SA = CreateObject("Shell.Application")

Private Function IsPermission()
 If Err.Number <> 0 Then
  IsPermission = "No"
  Else
  IsPermission = "Yes"
  End if
 End Function

Private Sub AD()
 If WScript.Arguments.length = 0 Then
   SA.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34) & Chr(32) & "/2CongLC.vn", , "runas", 1
   WSCript.Quit
  End if
 End Sub
 
If IsPermission = "Yes" Then AD()

DeleteFiles WS.ExpandEnvironmentStrings("%Temp%")
DeleteFiles WS.ExpandEnvironmentStrings("%Windir%") & "\SoftwareDistribution\Download"
DeleteFiles WS.ExpandEnvironmentStrings("%Windir%") & "\Prefetch"


Private Sub DeleteFiles(ByVal cmd)

 Dim Folder : Set Folder = FSO.GetFolder(cmd)
 Dim i, j 
 
 'Xóa ở thư mục gốc
 For Each i in Folder.Files
 On Error Resume Next
  i.Delete True
  If Err Then
   WScript.Echo "Can't Delete File : " & i.Name & " - " & Err.Description
  End if  
  On Error GoTo 0
 Next
 
 'Xóa ở thư mục con
 For Each j in Folder.SubFolders
 On Error Resume Next
  j.Delete True
  If Err Then
   WScript.Echo "Can't Delete File : " & j.Name & " - " & Err.Description
  End if  
  On Error GoTo 0
 Next
End Sub


Set WS = Nothing
Set FSO = Nothing
Set SA = Nothing