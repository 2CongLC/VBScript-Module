'Encoding : Windows-1258
'T��t Windows Firewall h�� th��ng
'Ta�c gia� : 2CongLC
'Phi�n ba�n : 16.05.2019

Option Explicit

Dim WMI : Set WMI = GetObject("winmgmts:\\.\root\cimv2")
Dim WS : Set WS = CreateObject("WScript.Shell")
Dim SA : Set SA = CreateObject("Shell.Application")

'Checking Permission
If Err.Number = 0 And WScript.Arguments.Count = 0 Then
 SA.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34) & Chr(32) & "/2CongLC.vn",Chr(32),"runas",1
 WScript.Quit
End if 

Private Function GetOS(cmd)
 Dim i
 For Each i in WMI.Execquery("Select * from Win32_OperatingSystem")
  If cmd = "c" Then GetOS = i.Caption
  Next
 End Function

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

Dim message
Private Function Accept(msg) ' 6 = yes | 7 = no
 If msg <> "" Then
  Accept = Msgbox(msg & vbnewline & "Ba�n co� ���ng y� kh�ng ?", vbYesNo+vbInformation, "T�t Windows FireWall cu�a h�� th��ng")
  End if
 End Function

message = "- Khi t��t ti�nh n�ng na�y co� nguy c� bi� tin t��c t��n c�ng." & VbCr & _
          "- H�� th��ng r��t d�� bi� �a�nh c��p th�ng tin va� truy��n ra ngoa�i." & VbCr & _
		  "- Ba�n �a� �o�c va� hi��u ca�c nguy c� k�� tr�n." & VbCr & _
		  "===============================================" & VbCr & _
		  "<Yes> : ���ng y�, Co� nghi�a la� �a� ch��p thu��n mo�i ru�i ro."

If Accept(message) = 6 Then	 
 If Not (RegInfo("HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile\EnableFirewall")) = "0" Then WS.RegWrite "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile\EnableFirewall","0","REG_DWORD"
 If Not (RegInfo("HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile\EnableFirewall")) = "0" Then WS.RegWrite "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile\EnableFirewall","0","REG_DWORD"
 If Not (RegInfo("HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\EnableFirewall")) = "0" Then WS.RegWrite "HKLM\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\EnableFirewall","0","REG_DWORD"
 WScript.Echo "�a� th��c hi��n xong !"
 End if

Set WMI = Nothing
Set WS = Nothing
Set SA = Nothing
