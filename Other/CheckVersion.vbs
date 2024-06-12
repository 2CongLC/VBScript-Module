Option Explicit

Dim WS : Set WS = CreateObject("WScript.Shell")
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

ScanFolder()

Private Sub ScanFolder()
 Dim i 
 For Each i in FSO.Drives
  Processes(i.RootFolder)
 Next
End Sub

Private Sub Processes(Byref cmd)
 If FSO.FolderExists(cmd) Then
  CheckOSDir(cmd)
 Else
  WScript.Quit
 End if
End Sub

Private Sub CheckOSDir(Byref cmd)
 If FSO.FolderExists(cmd & "Windows\") Then
  CheckOSType(cmd)
 End if
End Sub

Private Sub CheckOSType(Byref cmd)
 If Not Instr(cmd,"X:\") <> 0 Then
  CheckOSVer(cmd)
 End if 
End Sub

Private Sub CheckOSVer(Byref cmd)
 Dim Ver : Ver = FSO.GetFileVersion(cmd & "Windows\explorer.exe")
 If Instr(Ver,"10.0") <> 0 Then W10(cmd)
 If Instr(Ver,"8.1") <> 0 Then W81(cmd)
 If Instr(Ver,"8.0") <> 0 Then W80(cmd)
 If Instr(Ver,"7.0") <> 0 Then W70(cmd)
End Sub

Private Sub W10(ByRef cmd)
 WScript.echo "10"
End Sub

Private Sub W81(ByRef cmd)
  WScript.echo "81"
End Sub

Private Sub W80(ByRef cmd)
  WScript.echo "80"
End Sub

Private Sub W70(ByRef cmd)
  WScript.echo "70"
End Sub