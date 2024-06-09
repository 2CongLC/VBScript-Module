'Coder : 2CongLc.Vn
'File Name : ResetNTFSPermission.vbs | ResetNTFSPermission.cmd
'Version : Public/Release 1.5.17

Option Explicit

Dim WS : Set WS = CreateObject("WSCript.Shell")
Dim SA : Set SA = CreateObject("Shell.Application")
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")


Dim message 
message = "Script Version : Public/Release 1.5.17" & Vbcr & _
          "======================================" & Vbcr & _
		  "This Script have reset permission of a" & Vbcr & _
		  "file or folder for everyone." & Vbcr & _
          "======================================" & Vbcr & _
		  "<Yes> : You have accept EULA. This Script was FullAccess Limited Your System."
		  
If Accept(message) = 6 Then		  
 Dim Root
 If WScript.Arguments.Count <> 0 Then
  Root = FSO.GetFolder(WScript.Arguments.Item(0))
 Else
  WScript.Quit
 End if 

 Dim Command
 Command ="cacls " & Chr(34) & Root & Chr(34) & " /T /C /G Everyone:F"
 If Err.Number = 0 Then
  SA.ShellExecute "cmd.exe","/c Echo Y| " & Command, "", "runas", 1
 Else
  WS.Run "%ComSpec% /c Echo Y| " & Command,2,True
 End if
End if

Private Function Accept(msg) ' 6 = yes | 7 = no
 If msg <> "" Then
  Accept = Msgbox(msg & vbnewline & " Are you sure?",vbYesNo+vbInformation, "< 2CongLC.Vn > Reset NTFS Permission")
 End if
End Function

Set WS = Nothing
Set SA = Nothing
Set FSO = Nothing
