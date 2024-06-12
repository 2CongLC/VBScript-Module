'Encoding : Windows-1258
'Tãìt UAC hêò thôìng
'Taìc giaÒ : 2CongLC
'Phiên baÒn : 14.05.2019

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
  Accept = Msgbox(msg & vbnewline & "Baòn coì ðôÌng yì không ?", vbYesNo+vbInformation, "Tãt tiình nãng UAC cuÒa hêò thôìng")
  End if
 End Function

message = "- Viêòc tãìt tiình nãng naÌy khiêìn cõ chêì baÒo vêò biò suy giaÒm." & VbCr & _
          "- KhaÒ nãng lây nhiêÞm caìc ýìng duòng ðôòc haòi coì thêÒ  xaÒy ra dêÞ daÌng hõn." & VbCr & _
		  "- Baòn ðaÞ ðoòc vaÌ hiêÒu caìc nguy cõ kêÒ trên." & VbCr & _
		  "===============================================" & VbCr & _
		  "<Yes> : ÐôÌng yì, Coì nghiÞa laÌ ðaÞ châìp thuâòn moòi ruÒi ro."

If Accept(message) = 6 Then	 
 If Not Instr(GetOS("c"),"Microsoft Windows XP") <> 0 Then
  If Not (RegInfo("HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorAdmin")) = "0" Then  WS.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorAdmin","0","REG_DWORD"
  If Not (RegInfo("HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorUser")) = "3" Then    WS.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\ConsentPromptBehaviorUser","3","REG_DWORD"
  If Not (RegInfo("HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\PromptOnSecureDesktop")) = "0" Then WS.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\PromptOnSecureDesktop","0","REG_DWORD"
  If Not (RegInfo("HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA")) = "1" Then WS.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA","1","REG_DWORD"   
  WScript.Echo "ÐaÞ thýòc hiêòn xong !"
  End if
 End if

Set WMI = Nothing
Set WS = Nothing
Set SA = Nothing
