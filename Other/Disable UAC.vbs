'Encoding : Windows-1258
'T��t UAC h�� th��ng
'Ta�c gia� : 2CongLC
'Phi�n ba�n : 14.05.2019

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
  Accept = Msgbox(msg & vbnewline & "Ba�n co� ���ng y� kh�ng ?", vbYesNo+vbInformation, "T�t ti�nh n�ng UAC cu�a h�� th��ng")
  End if
 End Function

message = "- Vi��c t��t ti�nh n�ng na�y khi��n c� ch�� ba�o v�� bi� suy gia�m." & VbCr & _
          "- Kha� n�ng l�y nhi��m ca�c ��ng du�ng ���c ha�i co� th��  xa�y ra d�� da�ng h�n." & VbCr & _
		  "- Ba�n �a� �o�c va� hi��u ca�c nguy c� k�� tr�n." & VbCr & _
		  "===============================================" & VbCr & _
		  "<Yes> : ���ng y�, Co� nghi�a la� �a� ch��p thu��n mo�i ru�i ro."

If Accept(message) = 6 Then	 
 If Not Instr(GetOS("c"),"Microsoft Windows XP") <> 0 Then
  If Not (RegInfo("HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorAdmin")) = "0" Then  WS.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorAdmin","0","REG_DWORD"
  If Not (RegInfo("HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorUser")) = "3" Then    WS.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorUser","3","REG_DWORD"
  If Not (RegInfo("HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\PromptOnSecureDesktop")) = "0" Then WS.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\PromptOnSecureDesktop","0","REG_DWORD"
  If Not (RegInfo("HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA")) = "1" Then WS.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA","1","REG_DWORD"   
  WScript.Echo "�a� th��c hi��n xong !"
  End if
 End if

Set WMI = Nothing
Set WS = Nothing
Set SA = Nothing
