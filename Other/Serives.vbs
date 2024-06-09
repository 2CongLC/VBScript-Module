
Option Explicit

Dim WS : Set WS = CreateObject("WScript.Shell")
Dim SA : Set SA = CreateObject("Shell.Application")

If Err.Number = 0 And WScript.Arguments.Count = 0 Then
 SA.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34) & Chr(32) & "/2CongLC.vn",Chr(32),"runas",1
 WScript.Quit
End if 


'=========== DISABLE SERVICE ==========
'Diagnostic Policy Service
If Not SA.IsServiceRunning("DPS") = 0 Then Call SA.ServiceStop("DPS", true)
'Distributed Link Tracking Client
If Not SA.IsServiceRunning("TrkWks") = 0 Then Call SA.ServiceStop("TrkWks", true)
'IP Helper
If Not SA.IsServiceRunning("iphlpsvc") = 0 Then Call SA.ServiceStop("iphlpsvc", true)
'Offline Files
If Not SA.IsServiceRunning("CscService") = 0 Then Call SA.ServiceStop("CscService", true)
'Portable Device Enumerator Service
If Not SA.IsServiceRunning("WPDBusEnum") = 0 Then Call SA.ServiceStop("WPDBusEnum", true)
'Program Compatibility Assistant Service
If Not SA.IsServiceRunning("PcaSvc") = 0 Then Call SA.ServiceStop("PcaSvc", true)
'RemoteRegistry
If Not SA.IsServiceRunning("RemoteRegistry") = 0 Then Call SA.ServiceStop("RemoteRegistry", true)
'Superfetch
If Not SA.IsServiceRunning("SysMain") = 0 Then Call SA.ServiceStop("SysMain", true)
'Windows Event Log
If Not SA.IsServiceRunning("EventLog") = 0 Then Call SA.ServiceStop("EventLog", true)
'Windows Firewall
If Not SA.IsServiceRunning("MpsSvc") = 0 Then Call SA.ServiceStop("MpsSvc", true)
'Windows Update
If Not SA.IsServiceRunning("wuauserv") = 0 Then Call SA.ServiceStop("wuauserv", true)

'Fax & Printer
If WS.ExpandEnvironmentStrings("%Username%") = "2CongLC.Vn" Then
 If Not SA.IsServiceRunning("Fax") = 0 Then Call SA.ServiceStop("Fax", true)
 If Not SA.IsServiceRunning("Spooler") = 0 Then Call SA.ServiceStop("Spooler", true)
Else
 If Not SA.IsServiceRunning("Fax") <> 0 Then Call SA.ServiceStart("Fax", true)
 If Not SA.IsServiceRunning("Spooler") <> 0 Then Call SA.ServiceStart("Spooler", true) 
End if 

Set SA = Nothing