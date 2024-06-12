Option Explicit

Dim WS : Set WS = CreateObject("WSCript.Shell")
Dim SA : Set SA = CreateObject("Shell.Application")
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")


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
 
If IsPermission = "Yes" Then AD()

'RegInfo
Private Function RegInfo(cmd) 'http://www.oocities.org/kilian0072002/registry/vbsreg.htm
 Dim entry
 On Error Resume Next
 entry = WS.RegRead(cmd)
 If Err.Number <> 0 Then
  Err.Clear
  RegInfo = "False"
 Else
  Err.Clear
  If IsArray(entry) Then
   Dim b: b = entry
   Dim I
   For I = LBound(entry) To UBound(entry)
    b(I) = Hex (CInt(entry(I))) 
   Next
  RegInfo = Join(b)
  Else 
  RegInfo = entry
  End if
 End if
 End Function


Dim CDir : CDir = FSO.GetParentFolderName(WSCript.ScriptFullName) & "\"

Dim FS : Set FS = FSO.OpenTextFile(CDir & "Dump.txt",2,True)
FS.WriteLine Reginfo("HKEY_CURRENT_USER\Control Panel\Desktop\UserPreferencesMask")
FS.Close()

Set WS = Nothing
Set SA = Nothing
Set FSO = Nothing
