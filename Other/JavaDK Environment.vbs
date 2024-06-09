'Coder : 2CongLc.Vn
'File Name : JavaDK Environment.vbs
'Version : Public/Release 1.5.17
Option Explicit

Dim WS : Set WS = CreateObject("WSCript.Shell")
Dim SA : Set SA = CreateObject("Shell.Application")
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")
RunasAdmin()


Dim CDir : CDir = FSO.GetParentFolderName(WSCript.ScriptFullName) & "\"
Dim JavaArray : JavaArray = Array("bin","lib","jre","db","include")
Dim j,Root
For Each j in JavaArray
 If FSO.FolderExists(CDir & j) Then
  Root = CDir
 Else
  If FSO.FolderExists(WS.ExpandEnvironmentStrings("%ProgramFiles%") & "\Java") Then
   Dim k
   For Each k in FSO.GetFolder(WS.ExpandEnvironmentStrings("%ProgramFiles%") & "\Java").subfolders
    Root = k
   Next 
  End if
 End if 
Next

If Not FSO.FolderExists(Root) Then WScript.Quit

Dim SE : If Err.Number = 0 Then  Set SE = WS.Environment("SYSTEM") Else Set SE = WS.Environment("USER")
Dim SDic : Set SDic = CreateObject("Scripting.Dictionary")
SDic.CompareMode = vbTextCompare
Dim PATHS : PATHS = Split(SE("PATH"), ";")
Dim i
For Each i In PATHS
 SDic(i) = ""
 Next
 
If FSO.FileExists(Root & "\bin\java.exe") Then
 WS.Environment.item("JAVA_HOME") = Root
 WS.Environment.item("ClassPath") = ".;%JAVA_HOME%\lib;%JAVA_HOME%\lib\dt.jar;%JAVA_HOME%\lib\tools.jar"
 WS.Environment.item("JRE_HOME") = "%JAVA_HOME%\jre"
 SDic("%JAVA_HOME%\bin\") = ""
 SDic("%ClassPath%") = ""
 SDic("%JRE_HOME%") = "" 
 SE("PATH") = Join(SDic.Keys, ";")
 WScript.Echo "Set JDK Environment :" & FSO.GetFileVersion(Root & "\bin\java.exe") & "Done !"
 Else
 WScript.Echo "Not Find JavaDK !"
 End if

Private Sub RunasAdmin()
 If Err.Number = 0 Then
 If WScript.Arguments.Count = 0 Then
   SA.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34) & Chr(32) & "/2CongLC.Vn", , "runas", 1
   WSCript.Quit
  End if
 End if 
End Sub
  
Set WS = Nothing
Set SA = Nothing
Set FSO = Nothing
