'Coder : 2CongLC.Vn
'File Name : HideProcesses.vbs
'Example : HideProcesses.vbs notepad.exe 0
'Version : Public/Release 11.09.2020
Option Explicit

Dim WS : Set WS = CreateObject("WSCript.Shell")
Dim WMI : Set WMI = GetObject("winmgmts:\\.\root\cimv2")
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
 
Dim Args : Set Args = WSCript.Arguments
Dim Command, Flag 
If Args.Count <> 0 Then
   Command = Chr(34) & Args.Item(0) & Chr(34)
   Flag = Args.Item(1)
 End if

Dim Startup: Set Startup = WMI.Get("Win32_ProcessStartup")
Dim Config : Set Config = Startup.SpawnInstance_
' Hide = 0 , Show = 1
Config.ShowWindow = Flag

Dim Process : Set Process = WMI.Get("Win32_Process")
Dim result, ProcessID
result = Process.Create _
    (Command, Null, Config, ProcessID)
	
If result <> 0 Then
    Wscript.Echo "Process could not be created." & _
        vbNewLine & "Command line: " & Command & _
        vbNewLine & "Return value: " & result
Else
    Wscript.Echo "Process created." & _
        vbNewLine & "Command line: " & Command & _
        vbNewLine & "Process ID: " & ProcessID
End If	