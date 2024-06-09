'Coder : 2CongLC.Vn
'File Name : File2Base64.vbs
'Copyright © 2017 By 2CongLC.Vn | All Rights

Option Explicit

Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")
Dim SA : Set SA = CreateObject("Shell.Application")
Dim ADO : Set ADO = CreateObject ("ADODB.Stream")
Dim BS64 : Set BS64 = CreateObject("MSxml2.DomDocument").CreateElement("Base64Data")
 
Private Function IsPermission()
 If Err.Number <> 0 Then
  IsPermission = "No"
  Else
  IsPermission = "Yes"
  End if
 End Function

Private Sub AD()
 If WScript.Arguments.length = 0 Then
   SA.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34) & Chr(32) & "RunAsAdministrator", , "runas", 1
   WSCript.Quit
  End if
 End Sub

If WSCript.Arguments.length <> 0 Then
 Dim Target : Target =  WSCript.Arguments.Item(0)
 Else
 WSCript.Quit
 End if
 
If IsPermission = "Yes" Then AD()

If FSO.FileExists(Target) Then
 Call ToBase64String(Target, FSO.GetParentFolderName(Target) & "\" & FSO.GetFileName(Target) & ".txt")
 Else
 WSCript.Quit
 End if

Private Sub ToBase64String(inPut, outPut)
 ADO.Type = 1
 ADO.Open()
 ADO.LoadFromFile(inPut)
 BS64.Datatype = "bin.base64"
 BS64.Nodetypedvalue = ADO.read()
 FSO.CreateTextFile outPut, True, False
 Dim FS : Set FS = FSO.GetFile(outPut).OpenasTextStream(2, 0)
 FS.Write BS64.Text
 ADO.close()
 FS.Close()
End Sub

Private Sub FromBase64String(inPut, outPut)
 BS64.Datatype = "bin.base64"
 BS64.Text = FSO.GetFile(inPut).OpenasTextStream(1, 0).ReadAll() 
 ADO.Type = 1
 ADO.Open()
 ADO.Write BS64.Nodetypedvalue
 ADO.SaveToFile outPut, 2
 FSO.Close()
 ADO.Close() 
 End Sub

Set BS64 = Nothing 
Set FSO = Nothing
Set SA = Nothing
Set ADO = Nothing
