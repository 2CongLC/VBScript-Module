'Coder : 2CongLc.Vn
'File Name : PC.vbs
'Version : Public/Release 1.5.17
Option Explicit

'Variables
Dim WS : Set WS = CreateObject("WScript.Shell")
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")
Dim WMI : Set WMI = GetObject("winmgmts:\\.\root\cimv2")
Dim SA : Set SA = CreateObject("Shell.Application")
Dim REG : Set REG = GetObject("winmgmts:\\.\root\default:stdregprov")
Dim NAC: Set NAC = GetObject("winmgmts:").InstancesOf("Win32_NetworkAdapterConfiguration WHERE IPEnabled = True")

'Checking Permission
If Err.Number = 0 And WScript.Arguments.Count = 0 Then
 SA.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34) & Chr(32) & "/2CongLC.vn",Chr(32),"runas",1
 WScript.Quit
End if 

'Environment Variables
Private Function Envs(cmd)
 Envs = WS.ExpandEnvironmentStrings(cmd)
End Function

Private Sub Envs_Set(cmd)
 Dim se : If Err.Number = 0 Then Set se = WS.Environment("SYSTEM") Else Set se = WS.Environment("USER")
 Dim sd : Set sd = CreateObject("Scripting.Dictionary")
 sd.comparemode = vbTextCompare
 Dim cols : cols = split(se("Path"),";")
 Dim i
 For Each i in cols
  sd(i) = ""
  Next
 sd(cmd) = ""
 se("Path") = join(sd.keys,";") 
 End sub

'Checking OSVer
Private Function IsOS(cmd)
 Dim i
 For Each i in WMI.execquery("Select * from Win32_OperatingSystem")
  If cmd = "c" Then IsOS = i.caption
  If cmd = "v" Then IsOS = i.version
  If cmd = "inst" Then       
   Dim j: set j = CreateObject("WbemScripting.SWbemDateTime")
   j.value = i.InstallDate
   IsOS = j.GetVarDate
  End if
 Next 
End Function

'Checking Processor
Private Function IsProc()'https://msdn.microsoft.com/en-us/library/aa394373(v=vs.85).aspx
 Dim i
 For Each i in WMI.execquery("Select * From Win32_Processor")
  If i.AddressWidth = 32 Then IsProc = "x86"
  If i.AddressWidth = 64 Then IsProc = "x64"
  Next 
End Function

'Checking Hardware
Private Function IsPC()
 Dim i,j
 For Each i in WMI.execquery("Select * from Win32_SystemEnclosure") 'https://msdn.microsoft.com/en-us/library/aa394474(v=vs.85).aspx
  For Each j in i.ChassisTypes
   Select Case j 'https://msdn.microsoft.com/en-us/library/aa387204(v=vs.85).aspx
   Case 3
   IsPC = "Desktop"
   Case 9
   IsPC = "Laptop"
   End Select
  Next
 Next
End Function

'Get Domain
Private Function GetWorkgroup() 'https://msdn.microsoft.com/en-us/library/aa394102(v=vs.85).aspx
 Dim i
 For Each i in WMI.execquery("Select * from Win32_ComputerSystem")
  GetWorkgroup = i.Workgroup 'i.Domain
 Next
End Function

'Get IP & Mac Address
Private Function GetIP(cmd) 'https://msdn.microsoft.com/en-us/library/aa394217(v=vs.85).aspx
 Dim i,j
 For Each i in WMI.execquery("Select * from Win32_NetworkAdapterConfiguration")
  If cmd = "ip" Then
   If IsArray(i.IPAddress) Then GetIP = i.IPAddress(0)
  Elseif cmd = "mac" Then
   GetIP = GetIP & i.MacAddress	
  End if
 Next
End Function
'Get KeyOS
Private Function GetOSKey()
 If Instr(IsOS("c"), "Microsoft Windows XP") <> 0 Then
  GetOSKey = ""
 Else
  If Instr(IsOS("c"),"Microsoft Windows 7") <> 0 Then
   GetOSKey = ""
  Else 
   Dim Key : Key = WS.RegRead("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\" & "DigitalProductId")
   Dim Length : Length = (Key(66) \ 6) And 1
   Key(66) = (Key(66) And &HF7) Or ((Length And 2) * 4)
   Dim i : i = 24
   Dim Maps : Maps  = "BCDFGHJKMPQRTVWXY2346789"
   Do
    Dim Current : Current = 0
    Dim j : j = 14
    Do
     Current = Current * 256
     Current = Key(j + 52) + Current
     Key(j + 52) = (Current \ 24)
     Current= Current Mod 24
     j = j - 1
    Loop While j >= 0
    i = i -1
    Dim Out : Out = Mid(Maps,Current+ 1, 1) & Out
    Dim Last : Last = Current 
   Loop While i >= 0 
   Dim Firt : Firt = Mid(Out, 2, Last)
   Dim insert : insert = "N"
   Out =  Replace(Out, Firt, Firt & insert, 2, 1, 0)
   If Last = 0 Then Out = insert & Out
   GetOSKey = Mid(Out, 1, 5) & "-" & Mid(Out, 6, 5) & "-" & Mid(Out, 11, 5) & "-" & Mid(Out, 16, 5) & "-" & Mid(Out, 21, 5)   
  End if
 End if 
End Function 

Private Function ConvertSize(Size)
 Dim CommaLocate, Suffix
 Do While InStr(Size,",") 
  CommaLocate = InStr(Size,",") 
  Size = Mid(Size,1,CommaLocate - 1) & _ 
  Mid(Size,CommaLocate + 1,Len(Size) - CommaLocate) 
 Loop
 Suffix = " Bytes" 
 If Size >= 1024 Then suffix = " KB" 
 If Size >= 1048576 Then suffix = " MB" 
 If Size >= 1073741824 Then suffix = " GB" 
 If Size >= 1099511627776 Then suffix = " TB" 
 Select Case Suffix 
  Case " KB" Size = Round(Size / 1024, 1) 
  Case " MB" Size = Round(Size / 1048576, 1) 
  Case " GB" Size = Round(Size / 1073741824, 1) 
  Case " TB" Size = Round(Size / 1099511627776, 1) 
 End Select
 ConvertSize = Size & Suffix 
End Function

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

'Processes
Private Function Processes(Switch, Name)
 Dim i
 For Each i in WMI.ExecQuery("Select * From Win32_Process Where Name = " & "'" & Name & "'")
 If (Switch = "-f") Then
  Processes = i.ExecutablePath
 ElseIf (Switch = "-d") Then
  Processes = FSO.GetParentFolderName(i.ExecutablePath)
 ElseIf (Switch = "-k") Then
  i.Terminate()
 ElseIf (Switch = "-v") Then
  Processes = FSO.GetFileVersion(i.ExecutablePath)
 End if
 Next
End Function 

Private Sub WriteBytes(File, Bytes)
 Dim outStream: Set outStream = CreateObject("ADODB.Stream")
 With outStream
  .Type = 1
  .Open
  .Write Bytes
  .SaveToFile File, 2
 End with
End Sub
 
Private Function FromBase64String(cmd)
 Dim DM: Set DM = CreateObject("Microsoft.XMLDOM")
 Dim EL: Set EL = DM.createElement("tmp")
 With EL
  .DataType = "bin.base64"
  .Text = cmd
  FromBase64String = .NodeTypedValue
 End With
End Function

'Get Network Status
Private Function GetNetStatus(url)
 Dim SerHTTP : Set SerHTTP = CreateObject("MSXML2.ServerXMLHTTP")
 With SerHTTP
  .Open "GET", url, FALSE
  On Error Resume Next
  .Send
  If Err.Number = 0 Then
   If .statusText = "OK" Then
    GetNetStatus = "YES" ' Mạng truy cập bình thường
   Else
	GetNetStatus = "UNKNOW" 
   End if
  Else
   GetNetStatus = "NO" ' Không có kết nối mạng.
  End if
 On Error Goto 0
 End With
End Function 

'Set Enable Network
Private Sub EnableNetwork()
 Dim NIC_NAME, STATE, NETWORK_CONNECTIONS,CHECK, IsEnable, IsDisable 
 If Instr(IsOS("c"),"Microsoft Windows XP") > 0 Then 
  NETWORK_CONNECTIONS = 3
  If IsPC = "Laptop" Then
   NIC_NAME = "Wireless Network Connection"
  Else
   NIC_NAME = "Local Area Connection"
  End if
  Else
  NETWORK_CONNECTIONS = &H31& 
   If Instr(IsOS("c"),"Microsoft Windows 7") > 0 Then 
   If IsPC = "Laptop" Then
    NIC_NAME = "Wireless Network Connection"
   Else
    NIC_NAME = "Local Area Connection"
   End if
   Else
   If IsPC = "Laptop" Then
    NIC_NAME = "Wi-Fi"
   Else
    NIC_NAME = "Ethernet"
   End if   
   End if 
  End if 
 Dim NET : Set NET = SA.Namespace(NETWORK_CONNECTIONS)
 Dim Folder : Set Folder = Nothing
  If Instr(IsOS("c"),"Microsoft Windows XP") > 0 Then 
   Dim j
   For Each j in NET.Items
 	 If j.Name = "Network Connections" Then
	  Set Folder = j.getfolder
	  Exit For
	  End If
    Next
  Else
   Set Folder = NET.Self.GetFolder
  End if
 If Folder Is Nothing Then WScript.Quit		
 Dim TARGET, NIC : Set TARGET = Nothing
 For Each NIC In Folder.Items
  If LCase(NIC.Name) = LCase(NIC_NAME) Then
   Set TARGET = NIC
   Exit For
   End If
  Next
 If TARGET Is Nothing Then WScript.Quit
 STATE = True : Set IsEnable = Nothing : Set IsDisable = Nothing
 For Each CHECK In TARGET.Verbs
  If CHECK.Name = "En&able" Then Set IsEnable = CHECK : STATE = False
  If CHECK.Name = "Disa&ble" Then Set IsDisable = CHECK
 Next
 If STATE Then
  'IsDisable.DoIt
 Else
 IsEnable.DoIt
 End If
End Sub 

'Set DNS Server
Private Function SetDNS(Keys)
 Dim DNS,i
 For Each i in NAC
  If Keys = "level3" Then DNS = Array("209.244.0.3","209.244.0.4"): SetDNS = i.SetDNSServerSearchOrder(DNS)
  If Keys = "Google" Then DNS = Array("8.8.8.8","4.4.4.4"): SetDNS = i.SetDNSServerSearchOrder(DNS)
  If Keys = "dns.watch" Then DNS = Array("84.200.69.80","84.200.70.40"): SetDNS = i.SetDNSServerSearchOrder(DNS)
  If Keys = "OpenDNS" Then DNS = Array("208.67.222.222","208.67.220.220"): SetDNS = i.SetDNSServerSearchOrder(DNS)
  If Keys = "Norton" Then DNS = Array("199.85.126.20","199.85.127.20"): SetDNS = i.SetDNSServerSearchOrder(DNS)
 Next 
End Function 

'Enable DHCP
Private Sub EnableDHCP() 
 Dim i,j
 For Each i In NAC
  If Not i.DHCPEnabled Then   
   j = i.EnableDHCP
   If j = 0 Then
   WScript.Echo "DHCP enabled."   
   Else
    WScript.Echo "Unable to set DHCP obtained address."
    WScript.quit
    End If 
  Else
    'WScript.Echo "DHCP already enabled."    
  End If 
 Next 
End Sub

Dim message
Private Function Accept(msg) ' 6 = yes | 7 = no
 If msg <> "" Then
  Accept = Msgbox(msg & vbnewline & " Are you sure ?",vbYesNo+vbInformation, "< 2CongLC.Vn > PC Script")
  End if
 End Function
'================================================================================================
'                             C - O - D - E :: H - E - R - E !
'================================================================================================
message = "Script Version : Public/Release 1.5.17-Fixed" & VbCr & _
          "============================================" & VbCr & _
          "PC Model : "  & IsPC & VbCr & _
		  "============================================" & VbCr & _
		  "< OPERATING SYSTEM >" & VbCr & _
          "Caption : " & IsOS("c") & VbCr & _
		  "Verion : " & IsOS("v") & VbCr & _
		  "Processor : " & Envs("%PROCESSOR_ARCHITECTURE%") & VbCr & _
		  "Serial : " & GetOSKey & VbCr & _
		  "InstallDate : " & IsOS("inst") & VbCr & _
		  "============================================" & VbCr & _
		  "<Yes> : You have accept EULA. This Script was FullAccess Limited Your System."

If Accept(message) = 6 Then		  
'Get Local Script.
Dim CDir : CDir = FSO.GetParentFolderName(WScript.ScriptFullName)
Dim APP : APP = CDir & "\app\"
Dim BU : BU = CDir & "\bu\"
Dim CFG : CFG = CDir & "\conf\"

'Const
Private Const Current_All = "Software\Microsoft\Windows\CurrentVersion\"
Private Const Current_Explorer = "Software\Microsoft\Windows\CurrentVersion\Explorer\"
Private Const Current_Policies = "Software\Microsoft\Windows\CurrentVersion\Policies\"
Private Const Current_GPO = "Software\Microsoft\Windows\CurrentVersion\Group Policy Objects\"
Private Const Polices_Microsoft = "Software\Policies\Microsoft\"
Private Const Current_ControlSet = "SYSTEM\CurrentControlSet\"
Dim i

'CopyToLocal
If FSO.FileExists(CDir & "\PC.vbe") Then FSO.CopyFile CDir & "\PC.vbe",Envs("%SystemRoot%") & "\System32\"

'Disable Warning UAC 7/8/9/10
If Not Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKLM\" & Current_Policies & "System\ConsentPromptBehaviorAdmin")) = "0" Then  WS.RegWrite "HKLM\" & Current_Policies & "System\ConsentPromptBehaviorAdmin","0","REG_DWORD"
 If Not (RegInfo("HKLM\" & Current_Policies & "System\ConsentPromptBehaviorUser")) = "3" Then    WS.RegWrite "HKLM\" & Current_Policies & "System\ConsentPromptBehaviorUser","3","REG_DWORD"
 If Not (RegInfo("HKLM\" & Current_Policies & "System\PromptOnSecureDesktop")) = "0" Then WS.RegWrite "HKLM\" & Current_Policies & "System\PromptOnSecureDesktop","0","REG_DWORD"
 If Not (RegInfo("HKLM\" & Current_Policies & "System\EnableLUA")) = "1" Then WS.RegWrite "HKLM\" & Current_Policies & "System\EnableLUA","1","REG_DWORD"   
End if

'Fixing System
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\System\DisableCMD")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\System\DisableCMD"
If Not (RegInfo("HKCU\" & Current_Policies & "System\DisableRegistryTools")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "System\DisableRegistryTools"
If Not (RegInfo("HKCU\" & Current_Policies & "System\DisableTaskMgr")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "System\DisableTaskMgr" 
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoDrives")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoDrives"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoViewOnDrive")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoViewOnDrive"
If Not (RegInfo("HKLM\" & Current_ControlSet & "Control\StorageDevicePolicies\WriteProtect")) = "False" Then WS.RegDelete "HKLM\" & Current_ControlSet & "Control\StorageDevicePolicies\WriteProtect"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\RestrictRun")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\RestrictRun" : Shell.RegDelete "HKCU\" & Current_Policies & "Explorer\DisallowRun\" : Shell.RegDelete "HKCU\" & Current_Policies & "Explorer\RestrictRun\"
If Not (RegInfo("HKCU\" & Current_Policies & "System\DisableChangePassword")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "System\DisableChangePassword"
If Not (RegInfo("HKCU\" & Current_Policies & "System\DisableLockWorkstation")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "System\DisableLockWorkstation"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoLogoff")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoLogoff"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\DriverSearching\DontPromptForWindowsUpdate")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\DriverSearching\DontPromptForWindowsUpdate"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\DriverSearching\DontSearchFloppies")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\DriverSearching\DontSearchFloppies"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\DriverSearching\DontSearchCD")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\DriverSearching\DontSearchCD"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\DriverSearching\DontSearchWindowsUpdate")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\DriverSearching\DontSearchWindowsUpdate"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoFileMenu")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoFileMenu"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoHardwareTab")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoHardwareTab"
If Not (RegInfo("HKCU\" & Current_Policies & "Comdlg32\NoBackButton")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Comdlg32\NoBackButton"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoManageMyComputerVerb")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoManageMyComputerVerb"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoFolderOptions")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoFolderOptions"
If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\ShowSuperHidden")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\ShowSuperHidden","0","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\PersistBrowsers")) = "0" Then  WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\PersistBrowsers","0","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_ControlSet & "Control\Lsa\ForceGuest")) = "1" Then WS.RegWrite "HKLM\" & Current_ControlSet & "Control\Lsa\ForceGuest","1","REG_DWORD" 
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoViewContextMenu")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoViewContextMenu"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoChangeAnimation")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoChangeAnimation"
If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\EnableStartMenu")) = "1" Then WS.RegWrite"HKCU\" & Current_Explorer & "Advanced\EnableStartMenu","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\DisablePreviewDesktop")) = "1" Then  WS.RegWrite"HKCU\" & Current_Explorer & "Advanced\DisablePreviewDesktop","1","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "BuildAndTel\EnableBuildPreview")) = "0" Then  WS.RegWrite "HKLM\" & Current_Policies & "BuildAndTel\EnableBuildPreview","0","REG_DWORD"
If (RegInfo("HKCR\lnkfile\IsShortcut")) = "False" Then WS.RegWrite "HKCR\lnkfile\IsShortcut","","REG_SZ"
If Not (RegInfo("HKLM\" & Current_Policies & "System\DisableCAD")) = "1" Then WS.RegWrite "HKLM\" & Current_Policies & "System\DisableCAD","1","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\dontdisplaylastusername")) = "0" Then WS.RegWrite "HKLM\" & Current_Policies & "System\dontdisplaylastusername","0","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\EnableCursorSuppression")) = "1" Then  WS.RegWrite "HKLM\" & Current_Policies & "System\EnableCursorSuppression","1","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\EnableInstallerDetection")) = "1" Then WS.RegWrite "HKLM\" & Current_Policies & "System\EnableInstallerDetection","1","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\EnableSecureUIAPaths")) = "1" Then  WS.RegWrite "HKLM\" & Current_Policies & "System\EnableSecureUIAPaths","1","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\EnableUIADesktopToggle")) = "0" Then  WS.RegWrite "HKLM\" & Current_Policies & "System\EnableUIADesktopToggle","0","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\EnableVirtualization")) = "1" Then  WS.RegWrite "HKLM\" & Current_Policies & "System\EnableVirtualization","1","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\FilterAdministratorToken")) = "0" Then  WS.RegWrite "HKLM\" & Current_Policies & "System\FilterAdministratorToken","0","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\shutdownwithoutlogon")) = "1" Then  WS.RegWrite "HKLM\" & Current_Policies & "System\shutdownwithoutlogon","1","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\undockwithoutlogon")) = "1" Then WS.RegWrite "HKLM\" & Current_Policies & "System\undockwithoutlogon","1","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\ValidateAdminCodeSignatures")) = "0" Then  WS.RegWrite "HKLM\" & Current_Policies & "System\ValidateAdminCodeSignatures","0","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\DSCAutomationHostEnabled")) = "2" Then WS.RegWrite "HKLM\" & Current_Policies & "System\DSCAutomationHostEnabled","2","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_Policies & "System\legalnoticecaption")) = "" Then WS.RegWrite "HKLM\" & Current_Policies & "System\legalnoticecaption","","REG_SZ"
If Not (RegInfo("HKLM\" & Current_Policies & "System\legalnoticetext")) = "" Then  WS.RegWrite "HKLM\" & Current_Policies & "System\legalnoticetext","","REG_SZ"

'Fixing Desktop 
Dim DeskArray : DeskArray = Array("DisablePersonalDirChange","NoDesktop","NoInternetIcon","NoNetHood","NoPropertiesMyComputer","NoPropertiesMyDocuments","NoRecentDocsNetHood","NoPropertiesRecycleBin","NoSaveSettings","NoWindowMinimizingShortcuts","NoCloseDragDropBands","NoMovingBands","NoActiveDesktopChanges","NoActiveDesktop")
For Each i in DeskArray
 If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\" & i)) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\" & i
Next 

If Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKCU\" & Current_Explorer & "Desktop\CleanupWiz\NoRun")) = "1" Then WS.RegWrite "HKCU\" & Current_Explorer & "Desktop\CleanupWiz\NoRun","1","REG_DWORD"
Else
 If Instr(IsOS("c"),"Microsoft Windows 7") <> 0 Then
  If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoDesktopCleanupWizard")) = "1" Then WS.RegWrite "HKCU\" & Current_Policies & "Explorer\NoDesktopCleanupWizard","1","REG_DWORD" 
 End if
End if 

'Fixing Taskbar
Dim TaskArray : TaskArray = Array("LockTaskbar","HideClock","NoTaskGrouping","NoSetTaskbar","NoToolbarsOnTaskbar","NoTrayContextMenu","HideSCAHealth","HideSCANetwork","HideSCAPower", _
 "HideSCAVolume","TaskbarLockAll","TaskbarNoAddRemoveToolbar","TaskbarNoNotification","TaskbarNoRedock","TaskbarNoThumbnail")
For Each i in TaskArray
 If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\" & i)) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\" & i
Next
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Explorer\TaskbarNoMultimon")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Explorer\TaskbarNoMultimon"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Explorer\TaskbarNoPinnedList")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Explorer\TaskbarNoPinnedList"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Explorer\NoPinningStoreToTaskbar")) = "1" Then  WS.RegWrite "HKCU\" & Polices_Microsoft & "Windows\Explorer\NoPinningStoreToTaskbar","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Explorer\NoPinningToDestinations")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Explorer\NoPinningToDestinations"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Explorer\NoPinningToTaskbar")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Explorer\NoPinningToTaskbar"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Explorer\ShowWindowsStoreAppsOnTaskbar")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Explorer\ShowWindowsStoreAppsOnTaskbar"  
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\TaskbarNoResize")) = "1" Then WS.RegWrite "HKCU\" & Current_Policies & "Explorer\TaskbarNoResize","1","REG_DWORD" 

'Fixing StartMenu
Dim StartMenuArray : StartMenuArray = Array("ClearRecentDocsOnExit","ClearTilesOnExit","Intellimenus","NoChangeStartMenu","NoClose","NoCommonGroups","NoInstrumentation","NoNetworkConnections","NoStartMenuPinnedList","NoRecentDocsHistory","NoRecentDocsMenu","NoRun","NoSMConfigurePrograms","NoStartMenuNetworkPlaces","NoSetFolders","NoSimpleStartMenu", _
 "NoTrayItemsDisplay","NoUninstallFromStart","NoUserNameInStartMenu","PowerButtonAction","NoStartMenuEjectPC","ForceRunOnStartMenu","StartMenuLogOff")
For Each i in StartMenuArray
 If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\" & i)) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\" & i
Next
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\ClearRecentProgForNewUserInStartMenu")) = "1" Then  WS.RegWrite "HKCU\" & Current_Policies & "Explorer\ClearRecentProgForNewUserInStartMenu","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\ForceStartMenuLogOff")) = "1" Then  WS.RegWrite "HKCU\" & Current_Policies & "Explorer\ForceStartMenuLogOff","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoFavoritesMenu")) = "1" Then  WS.RegWrite "HKCU\" & Current_Policies & "Explorer\NoFavoritesMenu","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoFind")) = "1" Then  WS.RegWrite "HKCU\" & Current_Policies & "Explorer\NoFind","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoSMHelp")) = "1" Then  WS.RegWrite "HKCU\" & Current_Policies & "Explorer\NoSMHelp","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoSMMyDocs")) = "1" Then  WS.RegWrite "HKCU\" & Current_Policies & "Explorer\NoSMMyDocs","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoStartMenuMyMusic")) = "1" Then WS.RegWrite "HKCU\" & Current_Policies & "Explorer\NoStartMenuMyMusic","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoSMMyPictures")) = "1" Then  WS.RegWrite "HKCU\" & Current_Policies & "Explorer\NoSMMyPictures","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoWindowsUpdate")) = "1" Then WS.RegWrite "HKCU\" & Current_Policies & "Explorer\NoWindowsUpdate","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Explorer\NoBalloonFeatureAdvertisements")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Explorer\NoBalloonFeatureAdvertisements"
   
'Fixing Control Panel
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\DisallowCpl")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\DisallowCpl" : Shell.RegDelete "HKCU\" & Current_Policies & "Explorer\DisallowCpl\"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\ForceClassicControlPanel")) = "1" Then  WS.RegWrite "HKCU\" & Current_Policies & "Explorer\ForceClassicControlPanel","1","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoControlPanel")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoControlPanel"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\RestrictCpl")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\RestrictCpl" : Shell.RegDelete "HKCU\" & Current_Policies & "Explorer\RestrictCpl\"
If Not (RegInfo("HKCU\" & Current_Policies & "System\NoDispCPL")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "System\NoDispCPL"
If Not (RegInfo("HKCU\" & Current_Policies & "System\NoDispSettingsPage")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "System\NoDispSettingsPage"
If Not (RegInfo("HKCU\" & Current_Policies & "System\NoColorChoice")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "System\NoColorChoice"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoThemesTab")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoThemesTab"
If Not (RegInfo("HKCU\" & Current_Policies & "System\NoVisualStyleChoice")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "System\NoVisualStyleChoice"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Control Panel\Desktop\ScreenSaveActive")) = "1" Then WS.RegWrite "HKCU\" & Polices_Microsoft & "Windows\Control Panel\Desktop\ScreenSaveActive","1","REG_SZ"
If Not (RegInfo("HKCU\" & Current_Policies & "System\NoSizeChoice")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "System\NoSizeChoice"
If Not (RegInfo("HKCU\" & Current_Policies & "System\NoDispAppearancePage")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "System\NoDispAppearancePage"
If Not (RegInfo("HKCU\" & Current_Policies & "ActiveDesktop\NoChangingWallPaper")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "ActiveDesktop\NoChangingWallPaper"
If Not (RegInfo("HKCU\" & Current_Policies & "System\NoDispBackgroundPage")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "System\NoDispBackgroundPage"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Personalization\NoChangingMousePointers")) = "False" Then  WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Personalization\NoChangingMousePointers"
If Not (RegInfo("HKCU\" & Current_Policies & "System\NoDispScrSavPage")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "System\NoDispScrSavPage"  
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Personalization\NoChangingSoundScheme")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Personalization\NoChangingSoundScheme"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Control Panel\Desktop\ScreenSaverIsSecure")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Control Panel\Desktop\ScreenSaverIsSecure"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Control Panel\Desktop\ScreenSaveTimeOut")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Control Panel\Desktop\ScreenSaveTimeOut"  
If Not Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Control Panel\Desktop\SCRNSAVE.EXE")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Control Panel\Desktop\SCRNSAVE.EXE"
End if
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Personalization\ThemeFile")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\Personalization\ThemeFile"
If Not (RegInfo("HKCU\" & Current_Policies & "System\SetVisualStyle")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "System\SetVisualStyle"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows NT\Printers\Wizard\Downlevel Browse")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows NT\Printers\Wizard\Downlevel Browse"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows NT\Printers\Wizard\Printers Page URL")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows NT\Printers\Wizard\Printers Page URL"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoAddPrinter")) = "False" Then WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoAddPrinter"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoDeletePrinter")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "Explorer\NoDeletePrinter"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows NT\Printers\PackagePointAndPrint\PackagePointAndPrintOnly")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows NT\Printers\PackagePointAndPrint\PackagePointAndPrintOnly"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows NT\Printers\PointAndPrint\Restricted")) = "False" Then  WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows NT\Printers\PointAndPrint\"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows NT\Printers\Wizard\Default Search Scope")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows NT\Printers\Wizard\Default Search Scope"
If Not (RegInfo("HKCU\" & Current_Policies & "Programs\NoDefaultPrograms")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "Programs\NoDefaultPrograms"
If Not (RegInfo("HKCU\" & Current_Policies & "Programs\NoGetPrograms")) = "False" Then   WS.RegDelete "HKCU\" & Current_Policies & "Programs\NoGetPrograms"
If Not (RegInfo("HKCU\" & Current_Policies & "Programs\NoInstalledUpdates")) = "False" Then   WS.RegDelete "HKCU\" & Current_Policies & "Programs\NoInstalledUpdates"
If Not (RegInfo("HKCU\" & Current_Policies & "Programs\NoProgramsAndFeatures")) = "False" Then   WS.RegDelete "HKCU\" & Current_Policies & "Programs\NoProgramsAndFeatures"
If Not (RegInfo("HKCU\" & Current_Policies & "Programs\NoProgramsCPL")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "Programs\NoProgramsCPL"
If Not (RegInfo("HKCU\" & Current_Policies & "Programs\NoWindowsFeatures")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "Programs\NoWindowsFeatures"
If Not (RegInfo("HKCU\" & Current_Policies & "Programs\NoWindowsMarketplace")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "Programs\NoWindowsMarketplace"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Control Panel\International\HideAdminOptions")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Control Panel\International\HideAdminOptions"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Control Panel\International\HideCurrentLocation")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Control Panel\International\HideCurrentLocation"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Control Panel\International\HideLanguageSelection")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Control Panel\International\HideLanguageSelection"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Control Panel\International\HideLocaleSelectAndCustomize")) = "False" Then  WS.RegDelete "HKCU\" & Polices_Microsoft & "Control Panel\International\HideLocaleSelectAndCustomize"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Control Panel\Desktop\PreferredUILanguages")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Control Panel\Desktop\PreferredUILanguages"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Control Panel\Desktop\MultiUILanguageID")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Control Panel\Desktop\MultiUILanguageID"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Control Panel\International\TurnOffAutocorrectMisspelledWords")) = "False" Then  WS.RegDelete "HKCU\" & Polices_Microsoft & "Control Panel\International\TurnOffAutocorrectMisspelledWords"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Control Panel\International\TurnOffHighlightMisspelledWords")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Control Panel\International\TurnOffHighlightMisspelledWords"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Control Panel\International\TurnOffInsertSpace")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Control Panel\International\TurnOffInsertSpace"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Control Panel\International\TurnOffOfferTextPredictions")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "Control Panel\International\TurnOffOfferTextPredictions"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "InputPersonalization\RestrictImplicitTextCollection")) = "False" Then  WS.RegDelete "HKCU\" & Polices_Microsoft & "InputPersonalization\RestrictImplicitTextCollection"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "InputPersonalization\RestrictImplicitInkCollection")) = "False" Then   WS.RegDelete "HKCU\" & Polices_Microsoft & "InputPersonalization\RestrictImplicitInkCollection"

'Fixing Group Policy
Dim MMCArray : MMCArray = Array("{8EAD3A12-B2C1-11d0-83AA-00A0C92C9D5D}","{58221C67-EA27-11CF-ADCF-00AA00A80033}","{C9BC92DF-5B9A-11D1-8F00-00C04FC2C17B}","{EBC53A38-A23F-11D0-B09B-00C04FD8DCA6}","{D967F824-9968-11D0-B936-00C04FD8D5B0}","{E355E538-1C2E-11D0-8C37-00C04FD8FE93}","{0F6B957D-509E-11D1-A7CC-0000F87571E3}","{1AA7F83C-C7F5-11D0-A376-00C04FC9DA04}","{53D6AB1D-2488-11D1-A28C-00C04FB94F17}", _
 "{3F276EB4-70EE-11D1-8A0F-00C04FB93753}","{C2FE450B-D6C2-11D0-A37B-00C04FC9DA04}","{9EC88934-C774-11d1-87F4-00C04FC2C17B}","{90087284-d6d6-11d0-8353-00a0c90640bf}","{C2FE4502-D6C2-11D0-A37B-00C04FC9DA04}","{43668E21-2636-11D1-A1CE-0080C88593A5}","{677A2D94-28D9-11D1-A95B-008048918FB1}","{975797FC-4E2A-11D0-B702-00C04FD8DBF7}", _
 "{753EDB4D-2E1B-11D1-9064-00A0C90AB504}","{88E729D6-BDC1-11D1-BD2A-00C04FB9603F}","{8FC0B734-A0E1-11D1-A7D3-0000F87571E3}","{D70A2BEA-A63E-11D1-A7D4-0000F87571E3}","{2E19B602-48EB-11d2-83CA-00104BCA42CF}","{C2FE4508-D6C2-11D0-A37B-00C04FC9DA04}","{95AD72F0-44CE-11D0-AE29-00AA004B9986}","{8F8F8DC0-5713-11D1-9551-0060B0576642}", _
 "{FC715823-C5FB-11D1-9EEF-00A0C90347FF}","{A841B6C2-7577-11D0-BB1F-00A0C922E79C}","{C2FE4500-D6C2-11D0-A37B-00C04FC9DA04}","{DEA8AFA0-CC85-11d0-9CE2-0080C7221EBD}","{90810502-38F1-11D1-9345-00C04FC9DA04}","{90810500-38F1-11D1-9345-00C04FC9DA04}","{90810504-38F1-11D1-9345-00C04FC9DA04}","{5D6179C8-17EC-11D1-9AA9-00C04FD8FE93}", _
 "{6E8E0081-19CD-11D1-AD91-00AA00B8E05A}","{C2FE4506-D6C2-11D0-A37B-00C04FC9DA04}","{7478EF61-8C46-11d1-8D99-00A0C913CAD4}","{34AB8E82-C27E-11D1-A6C0-00C04FB94F17}","{FD57D297-4FD9-11D1-854E-00C04FC31FD3}","{B52C1E50-1DD2-11D1-BC43-00C04FC31FD3}","{5880CD5C-8EC0-11d1-9570-0060B0576642}","{3060E8CE-7020-11D2-842D-00C04FA372D4}", _
 "{243E20B0-48ED-11D2-97DA-00A024D77700}","{3CB6973D-3E6F-11D0-95DB-00A024D77700}","{C2FE4504-D6C2-11D0-A37B-00C04FC9DA04}","{C2FE4504-D6C2-11D0-A37B-00C04FC9DA04}","{DAB1A262-4FD7-11D1-842C-00C04FB6C218}","{1AA7F839-C7F5-11D0-A376-00C04FC9DA04}","{40B66650-4972-11D1-A7CA-0000F87571E3}","{40B6664F-4972-11D1-A7CA-0000F87571E3}", _
 "{011BE22D-E453-11D1-945A-00C04FB984F9}","{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}","{5ADF5BF6-E452-11D1-945A-00C04FB984F9}","{B1AFF7D0-0C49-11D1-BB12-00C04FC9A3A3}","{BD95BA60-2E26-AAD1-AD99-00AA00B8E05A}","{58221C66-EA27-11CF-ADCF-00AA00A80033}","{58221C65-EA27-11CF-ADCF-00AA00A80033}","{03f1f940-a0f2-11d0-bb77-00aa00a1eab7}", _
 "{7AF60DD3-4979-11D1-8A6C-00C04FC33566}","{942A8E4F-A261-11D1-A760-00C04FB9603F}","{45ac8c63-23e2-11d1-a696-00c04fd58bc3}","{0F3621F1-23C6-11D1-AD97-00AA00B88E5A}","{E26D02A0-4C1F-11D1-9AA1-00C04FC3357A}","{B91B6008-32D2-11D2-9888-00A0C925F917}","{5C659257-E236-11D2-8899-00104B2AFB46}")
For Each i in MMCArray
 If Not (RegInfo("HKCU\" & Polices_Microsoft & "MMC\" & i & "\Restrict_Run")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "MMC\" & i & "\"
Next 
If Not (RegInfo("HKCU\" & Polices_Microsoft & "MMC\RestrictAuthorMode")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "MMC\RestrictAuthorMode"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "MMC\RestrictToPermittedSnapins")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "MMC\RestrictToPermittedSnapins"

'Fixing LAN Setting
If Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKLM\SYSTEM\ControlSet001\Hardware Profiles\0001\Software\Microsoft\windows\CurrentVersion\Internet Settings\ProxyEnable")) = "0" Then WS.RegWrite "HKLM\SYSTEM\ControlSet001\Hardware Profiles\0001\Software\Microsoft\windows\CurrentVersion\Internet Settings\ProxyEnable","0","REG_DWORD"
 If Not (RegInfo("HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\DefaultConnectionSettings"))="3C 0 0 0 6 0 0 0 9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0" Then 
  Call REG.SetBinaryValue (&H80000001,"Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections","DefaultConnectionSettings",Array(60,0,0,0,6,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
 End if
Else
 If Not (RegInfo("HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\DefaultConnectionSettings"))="46 0 0 0 E 0 0 0 9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0" Then 
  Call REG.SetBinaryValue (&H80000001,"Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections","DefaultConnectionSettings",Array(70,0,0,0,14,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0))
 End if
End if
If Not (RegInfo("HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ProxyEnable"))="0" Then WS.RegWrite "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ProxyEnable","0","REG_DWORD"
  
'Shared Folders & Printer
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows NT\SharedFolders\PublishDfsRoots")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows NT\SharedFolders\PublishDfsRoots"
If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows NT\SharedFolders\PublishSharedFolders")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows NT\SharedFolders\PublishSharedFolders"
If Not (RegInfo("HKCU\" & Current_Policies & "Network\NoEntireNetwork")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "Network\NoEntireNetwork"
If Not (RegInfo("HKCU\" & Current_Policies & "Network\NoFileSharing")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "Network\NoFileSharing"
If Not (RegInfo("HKCU\" & Current_Policies & "Network\NoPrintSharing")) = "False" Then  WS.RegDelete "HKCU\" & Current_Policies & "Network\NoPrintSharing"
  
'Always Explorer Win XP
If Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then 
 If Not (RegInfo("HKCR\Folder\shell\")) = "explorer" Then WS.RegWrite "HKCR\Folder\shell\","explorer","REG_SZ" 
Else
 If Not (RegInfo("HKCR\Folder\shell\")) = "" Then WS.RegWrite "HKCR\Folder\shell\","","REG_SZ" 
End if 

'Disable Metro Win 8/8.1
If (Instr(IsOS("c"),"Microsoft Windows 8") <> 0) Or (Instr(IsOS("c"),"Microsoft Windows 8.1") <> 0) Then
 If Not (RegInfo("HKCU\" & Current_Explorer & "RPEnabled")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "RPEnabled",0,"REG_DWORD"
 If Not (RegInfo("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell")) = "explorer.exe /select,explorer.exe" Then WS.RegWrite "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell","explorer.exe /select,explorer.exe","REG_SZ"
End if

'Disable Autoplay & Autorun
If Not Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
  If Not (RegInfo("HKCU\" & Current_Explorer & "AutoplayHandlers\DisableAutoplay")) = "1" Then WS.RegWrite "HKCU\" & Current_Explorer & "AutoplayHandlers\DisableAutoplay","1","REG_DWORD"
End if
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoDriveTypeAutoRun")) = "255" Then WS.RegWrite "HKCU\" & Current_Policies & "Explorer\NoDriveTypeAutoRun","255","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\HonorAutorunSetting")) = "1" Then WS.RegWrite "HKLM\" & Current_Policies & "Explorer\HonorAutorunSetting","1","REG_DWORD"
If Not (RegInfo("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\IniFileMapping\Autorun.inf\")) = "@SYS:DoesNotExist" Then WS.RegWrite "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\IniFileMapping\Autorun.inf\","@SYS:DoesNotExist","REG_SZ" 
 
'Disable Dump & Log , Event, Autoreboot
If Not (RegInfo("HKLM\SYSTEM\ControlSet001\Control\CrashControl\LogEvent")) = "0" Then WS.RegWrite "HKLM\SYSTEM\ControlSet001\Control\CrashControl\LogEvent","0","REG_DWORD"
If Not (RegInfo("HKLM\SYSTEM\ControlSet001\Control\CrashControl\SendAlert")) = "0" Then WS.RegWrite "HKLM\SYSTEM\ControlSet001\Control\CrashControl\SendAlert","0","REG_DWORD"
If Not (RegInfo("HKLM\SYSTEM\ControlSet001\Control\CrashControl\AutoReboot")) = "0" Then WS.RegWrite "HKLM\SYSTEM\ControlSet001\Control\CrashControl\AutoReboot","0","REG_DWORD"
If Not (RegInfo("HKLM\SYSTEM\ControlSet001\Control\CrashControl\AlwaysKeepMemoryDump")) = "0" Then WS.RegWrite "HKLM\SYSTEM\ControlSet001\Control\CrashControl\AlwaysKeepMemoryDump","0","REG_DWORD"
If Not (RegInfo("HKLM\SOFTWARE\Microsoft\PCHealth\ErrorReporting\DoReport")) = "0" Then WS.RegWrite "HKLM\SOFTWARE\Microsoft\PCHealth\ErrorReporting\DoReport","0","REG_DWORD"
 
'Disable Taskbar Combine
If Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\TaskbarGlomming")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\TaskbarGlomming","0","REG_DWORD"
Else
 If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\TaskbarGlomLevel")) = "2" Then WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\TaskbarGlomLevel",2,"REG_DWORD"  
End if

'Disable SearchBox | Task View
If Instr(IsOS("c"),"Microsoft Windows 10")  <> 0 Then
 If Not (RegInfo("HKCU\" & Current_All & "Search\SearchboxTaskbarMode")) = "0" Then WS.RegWrite "HKCU\" & Current_All & "Search\SearchboxTaskbarMode",0,"REG_DWORD"
 If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\ShowTaskViewButton")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\ShowTaskViewButton",0,"REG_DWORD"
End if

'Disable Windows Take A Tour Bubble Popup
If Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKLM\Software\Microsoft\Windows\CurrentVersion\Applets\Tour\RunCount")) = "0" Then WS.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\Applets\Tour\RunCount","0","REG_DWORD"
End if

'Disable Quick Access
If Instr(IsOS("c"),"Microsoft Windows 10") <> 0 Then
 If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\LaunchTo")) = "1" Then WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\LaunchTo","1","REG_DWORD"   
End if

'Disable Cortana
If Instr(IsOS("c"),"Microsoft Windows 10") <> 0 Then
 If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Windows Search\AllowCortana")) = "0" Then WS.RegWrite "HKCU\" & Polices_Microsoft & "Windows\Windows Search\AllowCortana",0,"REG_DWORD"
End if

'Show File Extensions
If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\HideFileExt")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\HideFileExt",0,"REG_DWORD"

'Show Drive Letter
If Not (RegInfo("HKLM\" & Current_Explorer & "ShowDriveLettersFirst")) = "4" Then WS.RegWrite "HKLM\" & Current_Explorer & "ShowDriveLettersFirst","4","REG_DWORD"
 
'Windows Logon Background
If Instr(IsOS("c"),"Microsoft Windows 10") <> 0 Then
 If Not RegInfo("HKLM\" & Polices_Microsoft & "Windows\System\DisableLogonBackgroundImage") = "0" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows\System\DisableLogonBackgroundImage","0","REG_DWORD"
End if

'Disable SmartScreen
If Not Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not RegInfo("HKLM\" & Polices_Microsoft & "Windows\System\EnableSmartScreen") = "0" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows\System\EnableSmartScreen","0","REG_DWORD"
End if
'Remove Watermark
If Not (RegInfo("HKCU\Control Panel\Desktop\PaintDesktopVersion")) ="0" Then WS.RegWrite "HKCU\Control Panel\Desktop\PaintDesktopVersion","0","REG_DWORD"
 
'Enable Autotray
If Not (RegInfo("HKCU\" & Current_Explorer & "EnableAutoTray")) = "1" Then WS.RegWrite "HKCU\" & Current_Explorer & "EnableAutoTray","1","REG_DWORD"
 
'Disable Hibernate
If Not (RegInfo("HKLM\" & Current_ControlSet &"Control\Power\HibernateEnabled")) = "0" Then WS.RegWrite "HKLM\" & Current_ControlSet &"Control\Power\HibernateEnabled","0","REG_DWORD"

'Turn on Fast Startup (Default)
If Instr(IsOS("c"),"Microsoft Windows 10") <> 0 Then
 If Not (RegInfo("HKLM\" & Current_ControlSet &"Control\Session Manager\Power\HiberbootEnabled")) = "0" Then WS.RegWrite "HKLM\" & Current_ControlSet &"Control\Session Manager\Power\HiberbootEnabled","0","REG_DWORD"
End if
 
'Remove Shortcut Arrow_Text
If Not FSO.FileExists(Envs("%Systemroot%")& "\System32\2CongLC.Blank.ico") Then
 If FSO.FileExists(CFG & "2CongLC.Blank.ico") Then
  FSO.CopyFile CFG & "2CongLC.Blank.ico", Envs("%Systemroot%") & "\System32\"
Else
  Writebytes Envs("%Systemroot%")& "\System32\2CongLC.Blank.ico", FromBase64String(BS64_ShortCut_Arrow)
 End if
End if 
If Not (RegInfo("HKLM\" & Current_Explorer & "Shell Icons\29")) = Envs("%Systemroot%") & "\System32\2CongLC.Blank.ico" Then WS.RegWrite "HKLM\" & Current_Explorer & "Shell Icons\29",Envs("%Systemroot%") & "\System32\2CongLC.Blank.ico","REG_SZ"
If Not (RegInfo("HKCU\" & Current_Explorer & "link")) = "0 0 0 0" Then WS.RegWrite "HKCU\" & Current_Explorer & "link",CLng(0),"REG_BINARY"

'Disabke "Low Disk Space"
If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoLowDiskSpaceChecks")) = "1" Then WS.RegWrite "HKCU\" & Current_Policies & "Explorer\NoLowDiskSpaceChecks","1","REG_DWORD"

'Disable Windows Notifications
If Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then 
 If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\Explorer\DisableNotificationCenter")) = "1" Then WS.RegWrite "HKCU\" & Polices_Microsoft & "Windows\Explorer\DisableNotificationCenter",1,"REG_DWORD"
 If Not (RegInfo("HKLM\SOFTWARE\Microsoft\Security Center\FirewallDisableNotify")) = "1" Then WS.RegWrite "HKLM\SOFTWARE\Microsoft\Security Center\FirewallDisableNotify","1","REG_DWORD"
 If Not (RegInfo("HKLM\SOFTWARE\Microsoft\Security Center\UpdatesDisableNotify")) = "1" Then WS.RegWrite "HKLM\SOFTWARE\Microsoft\Security Center\UpdatesDisableNotify","1","REG_DWORD"
 If Not (RegInfo("HKLM\SOFTWARE\Microsoft\Security Center\AntiVirusDisableNotify")) = "1" Then WS.RegWrite "HKLM\SOFTWARE\Microsoft\Security Center\AntiVirusDisableNotify","1","REG_DWORD" 
End if
If Not (RegInfo("HKLM\" & Current_ControlSet & "SharedAccess\Parameters\FirewallPolicy\DomainProfile\DisableNotifications")) = "1" Then WS.RegWrite "HKLM\" & Current_ControlSet & "Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile\DisableNotifications","1","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_ControlSet & "SharedAccess\Parameters\FirewallPolicy\PublicProfile\DisableNotifications")) = "1" Then WS.RegWrite "HKLM\" & Current_ControlSet & "Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile\DisableNotifications","1","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_ControlSet & "SharedAccess\Parameters\FirewallPolicy\StandardProfile\DisableNotifications")) = "1" Then WS.RegWrite "HKLM\" & Current_ControlSet & "Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\DisableNotifications","1","REG_DWORD"
 
'Disable Windows Defender
If Not Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows Defender\DisableAntiSpyware")) = "0" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows Defender\DisableAntiSpyware","0","REG_DWORD"
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows Defender\Real-Time Protection\EnableUnknownPrompts")) = "0" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows Defender\Real-Time Protection\EnableUnknownPrompts","0","REG_DWORD"
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows Defender\Scan\CheckForSignaturesBeforeRunningScan")) = "0" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows Defender\Scan\CheckForSignaturesBeforeRunningScan","0","REG_DWORD"
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows Defender\Signature Updates\ForceFullUpdate")) = "0" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows Defender\Signature Updates\ForceFullUpdate","0","REG_DWORD"
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows Defender\Reporting\DisableLoggingForKnownGood")) = "1" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows Defender\Reporting\DisableLoggingForKnownGood","1","REG_DWORD"
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows Defender\Reporting\DisableLoggingForUnknown")) = "1" Then   WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows Defender\Reporting\DisableLoggingForUnknown","1","REG_DWORD"
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows Defender\SpyNet\SpyNetReporting")) = "0" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows Defender\SpyNet\SpyNetReporting","0","REG_DWORD"
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows Defender\Signature Updates\CheckAlternateDownloadLocation")) = "0" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows Defender\Signature Updates\CheckAlternateDownloadLocation","0","REG_DWORD"
End if

'Disable Windows Update | https://technet.microsoft.com/en-us/library/cc708449(v=ws.10).aspx
If Not (Instr(IsOS("c"), "Microsoft Windows XP") <> 0) Then
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\NoAutoUpdate")) = "1" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\NoAutoUpdate","1","REG_DWORD"  
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\DetectionFrequencyEnabled")) = "0" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\DetectionFrequencyEnabled","0","REG_DWORD"  
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\DetectionFrequency")) = "False" Then WS.RegDelete "HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\DetectionFrequency"
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\DeferUpgrade")) = "0" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\DeferUpgrade","0","REG_DWORD"         
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows\GWX\DisableGWX") = "1") Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows\GWX\DisableGWX","1","REG_DWORD"
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\DisableOSUpgrade") = "1") Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\DisableOSUpgrade","1","REG_DWORD"
 If Not (RegInfo("HKLM\" & Current_All & "WindowsUpdate\OSUpgrade\AllowOSUpgrade") = "0") Then WS.RegWrite "HKLM\" & Current_All & "WindowsUpdate\OSUpgrade\AllowOSUpgrade",0,"REG_DWORD"
 If Not (RegInfo("HKLM\" & Current_All & "WindowsUpdate\OSUpgrade\ReservationsAllowed") = "0") Then WS.RegWrite "HKLM\" & Current_All & "WindowsUpdate\OSUpgrade\ReservationsAllowed",0,"REG_DWORD" 
 If Not (RegInfo("HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\AUOptions")) = "2" Then WS.RegWrite "HKLM\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\AUOptions","2","REG_DWORD"  
 
 If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\NoAutoUpdate")) = "1" Then WS.RegWrite "HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\NoAutoUpdate","1","REG_DWORD"  
 If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\DetectionFrequencyEnabled")) = "0" Then WS.RegWrite "HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\DetectionFrequencyEnabled","0","REG_DWORD"  
 If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\DetectionFrequency")) = "False" Then WS.RegDelete "HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\DetectionFrequency"
 If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\DeferUpgrade")) = "0" Then WS.RegWrite "HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\DeferUpgrade","0","REG_DWORD"         
 If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\GWX\DisableGWX") = "1") Then WS.RegWrite "HKCU\" & Polices_Microsoft & "Windows\GWX\DisableGWX","1","REG_DWORD"
 If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\DisableOSUpgrade") = "1") Then WS.RegWrite "HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\DisableOSUpgrade","1","REG_DWORD"
 If Not (RegInfo("HKCU\" & Current_All & "WindowsUpdate\OSUpgrade\AllowOSUpgrade") = "0") Then WS.RegWrite "HKCU\" & Current_All & "WindowsUpdate\OSUpgrade\AllowOSUpgrade",0,"REG_DWORD"
 If Not (RegInfo("HKCU\" & Current_All & "WindowsUpdate\OSUpgrade\ReservationsAllowed") = "0") Then WS.RegWrite "HKCU\" & Current_All & "WindowsUpdate\OSUpgrade\ReservationsAllowed",0,"REG_DWORD" 
 If Not (RegInfo("HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\AUOptions")) = "2" Then WS.RegWrite "HKCU\" & Polices_Microsoft & "Windows\WindowsUpdate\AU\AUOptions","2","REG_DWORD"  

Else
 If Not (RegInfo("HKCU\" & Current_Policies & "Explorer\NoAutoUpdate")) = "1" Then WS.RegWrite "HKCU\" & Current_Policies & "Explorer\NoAutoUpdate","1","REG_DWORD" 
 If Not (RegInfo("HKLM\" & Current_Policies & "Explorer\NoAutoUpdate")) = "1" Then WS.RegWrite "HKLM\" & Current_Policies & "Explorer\NoAutoUpdate","1","REG_DWORD" 
End if

'Disable Windows Firewall
If Not (RegInfo("HKLM\" & Current_ControlSet & "Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile\EnableFirewall")) = "0" Then WS.RegWrite "HKLM\" & Current_ControlSet & "Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile\EnableFirewall","0","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_ControlSet & "Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile\EnableFirewall")) = "0" Then WS.RegWrite "HKLM\" & Current_ControlSet & "Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile\EnableFirewall","0","REG_DWORD"
If Not (RegInfo("HKLM\" & Current_ControlSet & "Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\EnableFirewall")) = "0" Then WS.RegWrite "HKLM\" & Current_ControlSet & "Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\EnableFirewall","0","REG_DWORD"
 
'Set Date & Time  GMT+7 VN
If Not (RegInfo("HKCU\Control Panel\International\sShortDate")) = "dd/MM/yyyy" Then WS.RegWrite "HKCU\Control Panel\International\sShortDate","dd/MM/yyyy","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\sShortTime")) = "hh:mm tt" Then WS.RegWrite "HKCU\Control Panel\International\sShortTime","hh:mm tt","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\sTimeFormat")) = "hh:mm:ss tt" Then WS.RegWrite "HKCU\Control Panel\International\sTimeFormat","hh:mm:ss tt","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\sLongDate")) = "dd MMMM yyyy" Then WS.RegWrite "HKCU\Control Panel\International\sLongDate","dd MMMM yyyy","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\sYearMonth")) = "MMMM yyyy" Then WS.RegWrite "HKCU\Control Panel\International\sYearMonth","MMMM yyyy","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\sDate")) = "/" Then WS.RegWrite "HKCU\Control Panel\International\sDate","/","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\sTime")) = ":" Then WS.RegWrite "HKCU\Control Panel\International\sTime",":","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\sThousand")) = "." Then WS.RegWrite "HKCU\Control Panel\International\sThousand",".","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\sNativeDigits")) = "0123456789" Then WS.RegWrite "HKCU\Control Panel\International\sNativeDigits","0123456789","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\sNegativeSign")) = "-" Then WS.RegWrite "HKCU\Control Panel\International\sNegativeSign","-","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\s1159")) = "Sáng" Then WS.RegWrite "HKCU\Control Panel\International\s1159","Sáng","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\s2359")) = "Chiều" Then WS.RegWrite "HKCU\Control Panel\International\s2359","Chiều","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\iCountry")) = "84" Then WS.RegWrite "HKCU\Control Panel\International\iCountry","84","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\sCountry")) = "Việt Nam" Then WS.RegWrite "HKCU\Control Panel\International\sCountry","Việt Nam","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\sLanguage")) = "VIT" Then WS.RegWrite "HKCU\Control Panel\International\sLanguage","VIT","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\LocaleName")) = "vi-VN" Then WS.RegWrite "HKCU\Control Panel\International\LocaleName","vi-VN","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\International\Locale")) = "0000042a" Then WS.RegWrite "HKCU\Control Panel\International\Locale","0000042a","REG_SZ" 
If Not Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then 
 If Not (RegInfo("HKCU\Control Panel\International\User Profile\ShowAutoCorrection")) = "1" Then WS.RegWrite "HKCU\Control Panel\International\User Profile\ShowAutoCorrection","1","REG_DWORD"
 If Not (RegInfo("HKCU\Control Panel\International\User Profile\ShowCasing")) = "1" Then WS.RegWrite "HKCU\Control Panel\International\User Profile\ShowCasing","1","REG_DWORD"
 If Not (RegInfo("HKCU\Control Panel\International\User Profile\ShowShiftLock")) = "1" Then WS.RegWrite "HKCU\Control Panel\International\User Profile\ShowShiftLock","1","REG_DWORD"
 If Not (RegInfo("HKCU\Control Panel\International\User Profile\ShowTextPrediction")) = "1" Then WS.RegWrite "HKCU\Control Panel\International\User Profile\ShowTextPrediction","1","REG_DWORD"
 If Not (RegInfo("HKCU\Control Panel\International\User Profile\UserLocaleFromLanguageProfileOptOut")) = "1" Then WS.RegWrite "HKCU\Control Panel\International\User Profile\UserLocaleFromLanguageProfileOptOut","1","REG_DWORD"
End if

'IE 7/8/9/10
If Not Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKCU\Software\Microsoft\Internet Explorer\Main\Start Page")) = "https://www.google.com.vn/" Then WS.RegWrite "HKCU\Software\Microsoft\Internet Explorer\Main\Start Page","https://www.google.com.vn/","REG_SZ"
 If Not (RegInfo("HKCU\Software\Microsoft\Internet Explorer\Geolocation\BlockAllWebsites")) = "0" Then WS.RegWrite "HKCU\Software\Microsoft\Internet Explorer\Geolocation\BlockAllWebsites","0","REG_DWORD"
 If Not (RegInfo("HKCU\Software\Microsoft\Internet Explorer\New Windows\PopupMgr")) = "0" Then WS.RegWrite "HKCU\Software\Microsoft\Internet Explorer\New Windows\PopupMgr","0","REG_DWORD"
 If Not (RegInfo("HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{871C5380-42A0-1069-A2EA-08002B30301D}")) = "" Then
  WS.RegWrite "HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{871C5380-42A0-1069-A2EA-08002B30301D}","0","REG_DWORD"
  WS.RegWrite "HKCU\" & Current_Explorer & "Desktop\NameSpace\{871C5380-42A0-1069-A2EA-08002B30301D}\","","REG_SZ"
 End if
 If RegInfo("HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}") = "False" Then
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\","Internet Explorer","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\InfoTip",Envs("%Systemroot%") & "\System32\ieframe.dll,-881","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\DefaultIcon\",Envs("%Systemroot%") & "\System32\ieframe.dll,-190","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\InProcServer32\",Envs("%Systemroot%") & "\System32\ieframe.dll","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\InProcServer32\ThreadingModel","Apartment","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\shell\","OpenHomePage","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\shell\Private\","Start InPrivate Browsing","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\shell\Private\Command\",Envs("%Programfiles%") & "\Internet Explorer\iexplore.exe -private","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\shell\NoAddOns\","Start Without Add-ons","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\shell\NoAddOns\Command\",Envs("%Programfiles%") & "\Internet Explorer\iexplore.exe -extoff","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\shell\OpenHomePage\","Open &Home Page","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\shell\OpenHomePage\Command\",Envs("%Programfiles%") & "\Internet Explorer\iexplore.exe","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\shell\Properties\","P&roperties","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\shell\Properties\Position","bottom","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\shell\Properties\command\","control.exe inetcpl.cpl","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\Shellex\ContextMenuHandlers\ieframe\","{871C5380-42A0-1069-A2EA-08002B30309D}","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\Shellex\MayChangeDefaultMenu\","","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\ShellFolder\",Envs("%Systemroot%") & "\System32\ieframe.dll,-190","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\ShellFolder\HideAsDeletePerUser","","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\ShellFolder\Attributes","24","REG_DWORD"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\ShellFolder\HideFolderVerbs","","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\ShellFolder\WantsParseDisplayName","","REG_SZ"
  WS.RegWrite "HKCR\CLSID\{871C5380-42A0-1069-A2EA-08002B30301D}\ShellFolder\HideOnDesktopPerUser","","REG_SZ"
  End if
End if

'Desktop Icons
If Not (RegInfo("HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{20D04FE0-3AEA-1069-A2D8-08002B30309D}")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{20D04FE0-3AEA-1069-A2D8-08002B30309D}","0","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{645FF040-5081-101B-9F08-00AA002F954E}")) = "0" Then  WS.RegWrite "HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{645ff040-5081-101b-9f08-00aa002f954E}","0","REG_DWORD"
If Not (RegInfo("HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}")) = "1" Then  WS.RegWrite "HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}","1","REG_DWORD"
If Instr(IsOS("c"), "Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKCU\" & Current_Explorer & "HideDesktopIcons\ClassicStartMenu\{20D04FE0-3AEA-1069-A2D8-08002B30309D}")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "HideDesktopIcons\ClassicStartMenu\{20D04FE0-3AEA-1069-A2D8-08002B30309D}","0","REG_DWORD"
 If Not (RegInfo("HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{450D8FBA-AD25-11D0-98A8-0800361B1103}")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{450D8FBA-AD25-11D0-98A8-0800361B1103}","0","REG_DWORD"
 If Not (RegInfo("HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{208D2C60-3AEA-1069-A2D7-08002B30309D}")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{208D2C60-3AEA-1069-A2D7-08002B30309D}","0","REG_DWORD"
Else
 If Not (RegInfo("HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{59031a47-3f72-44a7-89c5-5595fe6b30ee}")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{59031a47-3f72-44a7-89c5-5595fe6b30ee}","0","REG_DWORD"  
 If Not (RegInfo("HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}","0","REG_DWORD"
 If Not (RegInfo("HKCU\Software\Classes\CLSID\{B4FB3F98-C1EA-428d-A78A-D1F5659CBA93}\System.IsPinnedToNameSpaceTree")) = "1" Then WS.RegWrite "HKCU\Software\Classes\CLSID\{B4FB3F98-C1EA-428d-A78A-D1F5659CBA93}\System.IsPinnedToNameSpaceTree","1","REG_DWORD"
 If Not (RegInfo("HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{B4FB3F98-C1EA-428d-A78A-D1F5659CBA93}")) = "1" Then  WS.RegWrite "HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{B4FB3F98-C1EA-428d-A78A-D1F5659CBA93}","1","REG_DWORD"    
End if

'Visual Effect
If Not (RegInfo("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\VisualFXSetting")) = "3" Then WS.RegWrite "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\VisualFXSetting","3","REG_DWORD" 
If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\TaskbarAnimations")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\TaskbarAnimations","0","REG_DWORD"    		 
If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\ListviewAlphaSelect")) = "0" Then WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\ListviewAlphaSelect","0","REG_DWORD"
If Not (RegInfo("HKCU\Control Panel\Desktop\FontSmoothing")) = "2" Then WS.RegWrite "HKCU\Control Panel\Desktop\FontSmoothing","2","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\Desktop\WindowMetrics\MinAnimate")) = "0" Then WS.RegWrite "HKCU\Control Panel\Desktop\WindowMetrics\MinAnimate","0","REG_SZ"
If Not (RegInfo("HKCU\Control Panel\Desktop\DragFullWindows")) = "0" Then WS.RegWrite "HKCU\Control Panel\Desktop\DragFullWindows","0","REG_SZ"			 
If Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKCU\Control Panel\Desktop\FontSmoothingType")) = "1" Then WS.RegWrite "HKCU\Control Panel\Desktop\FontSmoothingType","1","REG_DWORD"
 If Not (RegInfo("HKLM\" & Current_Explorer & "AlwaysUnloadDLL")) = "1" Then WS.RegWrite "HKLM\" & Current_Explorer & "AlwaysUnloadDLL","1","REG_DWORD"
 If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\WebView")) = "1" Then WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\WebView","1","REG_DWORD"	
 If Not (RegInfo("HKCU\Software\Microsoft\Internet Explorer\Desktop\Components\GeneralFlags")) = "4" Then WS.RegWrite "HKCU\Software\Microsoft\Internet Explorer\Desktop\Components\GeneralFlags","4","REG_DWORD"
Else
 If Not (RegInfo("HKCU\Software\Microsoft\Windows\DWM\AlwaysHibernateThumbnails")) = "0" Then WS.RegWrite "HKCU\Software\Microsoft\Windows\DWM\AlwaysHibernateThumbnails","0","REG_DWORD"
 If Not (RegInfo("HKCU\Software\Microsoft\Windows\DWM\EnableAeroPeek")) = "0" Then WS.RegWrite "HKCU\Software\Microsoft\Windows\DWM\EnableAeroPeek","0","REG_DWORD"	
 If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\ListviewShadow")) = "1" Then WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\ListviewShadow","1","REG_DWORD"
 If Not (RegInfo("HKCU\" & Current_Explorer & "Advanced\IconsOnly")) = "1" Then WS.RegWrite "HKCU\" & Current_Explorer & "Advanced\IconsOnly","0","REG_DWORD"
 If Not (RegInfo("HKCU\Control Panel\Desktop\FontSmoothingType")) = "2" Then WS.RegWrite "HKCU\Control Panel\Desktop\FontSmoothingType","2","REG_DWORD"	
End if
If Instr(IsOS("c"),"Microsoft Windows 10") <> 0 Then
 If Not (RegInfo("HKCU\" & Current_All & "Themes\Personalize\ColorPrevalence")) = "1" Then WS.RegWrite "HKCU\" & Current_All & "Themes\Personalize\ColorPrevalence","1","REG_DWORD"
 If Not (RegInfo("HKCU\" & Current_All & "Themes\Personalize\EnableTransparency")) = "1" Then WS.RegWrite "HKCU\" & Current_All & "Themes\Personalize\EnableTransparency","1","REG_DWORD"
End if	
If Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKCU\Control Panel\Desktop\UserPreferencesMask")) = "98 12 03 80" Then Call REG.SetBinaryValue(&H80000001,"Control Panel\Desktop","UserPreferencesMask",Array(152,18,3,128))
Elseif Instr(IsOS("c"),"Microsoft Windows 7") <> 0 Then
 If Not (RegInfo("HKCU\Control Panel\Desktop\UserPreferencesMask")) = "9C 12 3 80 10 0 0 0" Then Call REG.SetBinaryValue(&H80000001,"Control Panel\Desktop","UserPreferencesMask",Array(156,18,3,128,16,0,0,0))
Elseif Instr(IsOS("c"),"Microsoft Windows 8") <> 0 Then
 
Elseif Instr(IsOS("c"),"Microsoft Windows 8.1") <> 0 Then 
 
Elseif Instr(IsOS("c"),"Microsoft Windows 10") <> 0 Then 
 If Not (RegInfo("HKCU\Control Panel\Desktop\UserPreferencesMask")) = "9c 12 03 80 10 01 00 00" Then Call REG.SetBinaryValue(&H80000001,"Control Panel\Desktop","UserPreferencesMask",Array(156,18,3,128,16,1,0,0)) 'Default : 9e 3e 07 80 12 01,00,00 = Array(158,62,7,128,18,1,0,0)
End if

'OEM
If Not FSO.FileExists(Envs("%Systemroot%") & "\System32\oemlogo.bmp") Then
 If FSO.FileExists(CFG & "oemlogo.bmp") Then
  FSO.CopyFile CFG & "oemlogo.bmp", Envs("%Systemroot%") & "\System32\"
 Else
  WriteBytes Envs("%Systemroot%") & "\System32\oemlogo.bmp", FromBase64String(BS64_OEM_img)
 End if
End if
If Instr(IsOS("c"),"Microsoft Windows XP") > 0 Then  
 If Not FSO.FileExists(Envs("%Systemroot%") & "\System32\oeminfo.ini") Then
  If FSO.FileExists(CFG & "oeminfo.ini") Then
   FSO.CopyFile CFG & "oeminfo.ini", Envs("%Systemroot%") & "\System32\"
  Else
   WriteBytes Envs("%Systemroot%") & "\System32\oeminfo.ini", FromBase64String(BS64_OEM_ini)
  End if
 End if
Else
 If Not (RegInfo("HKLM\" & Current_All & "OEMInformation\Logo")) = Envs("%Systemroot%") & "\System32\oemlogo.bmp" Then WS.RegWrite "HKLM\" & Current_All & "OEMInformation\Logo", Envs("%Systemroot%") & "\System32\oemlogo.bmp","REG_SZ"
 If Not (RegInfo("HKLM\" & Current_All & "OEMInformation\Manufacturer")) = "2CongLC.Vn" Then WS.RegWrite "HKLM\" & Current_All & "OEMInformation\Manufacturer","2CongLC.Vn","REG_SZ"
 If Not (RegInfo("HKLM\" & Current_All & "OEMInformation\Model")) = "" Then WS.RegWrite "HKLM\" & Current_All & "OEMInformation\Model","Lào Cai - Việt Nam","REG_SZ"
 If Not (RegInfo("HKLM\" & Current_All & "OEMInformation\SupportHours")) = "" Then WS.RegWrite "HKLM\" & Current_All & "OEMInformation\SupportHours","GMT +7","REG_SZ"
 If Not (RegInfo("HKLM\" & Current_All & "OEMInformation\SupportURL")) = "http://fb.com/2conglc.vn" Then WS.RegWrite "HKLM\" & Current_All & "OEMInformation\SupportURL","http://fb.com/2conglc.vn","REG_SZ"
End if

'HomeDrive Icon
If Not FSO.FileExists(Envs("%Systemroot%")& "\System32\2CongLC.Vn.ico") Then
 If FSO.FileExists(CFG & "2CongLC.Vn.ico") Then
  FSO.CopyFile CFG & "2CongLC.Vn.ico", Envs("%Systemroot%") & "\System32\"
 Else
  Writebytes Envs("%Systemroot%")& "\System32\2CongLC.Vn.ico", FromBase64String(BS64_HomeDrive_Icon)
 End if  
End if
If Not RegInfo("HKLM\" & Current_Explorer & "DriveIcons\C\DefaultIcon\")= Envs("%Systemroot%") & "\System32\2CongLC.Vn.ico" Then WS.RegWrite "HKLM\" & Current_Explorer & "DriveIcons\C\DefaultIcon\", Envs("%Systemroot%") & "\System32\2CongLC.Vn.ico","REG_SZ"
 
'Context Menu New
If Not (RegInfo("HKCR\Briefcase\ShellNew\")) = "False" Then WS.RegDelete "HKCR\Briefcase\ShellNew\Config\" : WS.RegDelete "HKCR\Briefcase\ShellNew\"
If Not (RegInfo("HKCR\.bmp\ShellNew\ItemName")) = "@%systemroot%\system32\mspaint.exe,-59414" Then WS.RegWrite "HKCR\.bmp\ShellNew\ItemName","@%systemroot%\system32\mspaint.exe,-59414","REG_EXPAND_SZ" : Shell.RegWrite "HKCR\.bmp\ShellNew\NullFile","","REG_SZ"
If Not (RegInfo("HKCR\.contact\ShellNew\")) = "False" Then WS.RegDelete "HKCR\.contact\ShellNew\"
If (RegInfo("HKCR\.lnk\ShellNew\")) = "False" Then 
 WS.RegWrite "HKCR\.lnk\ShellNew\Handler","{ceefea1b-3e29-4ef1-b34c-fec79c4f70af}","REG_SZ" 
 WS.RegWrite "HKCR\.lnk\ShellNew\IconPath","%SystemRoot%\system32\shell32.dll,-16769","REG_EXPAND_SZ"
 WS.RegWrite "HKCR\.lnk\ShellNew\ItemName","@shell32.dll,-30397","REG_SZ"
 WS.RegWrite "HKCR\.lnk\ShellNew\MenuText","@shell32.dll,-30318","REG_SZ"
 WS.RegWrite "HKCR\.lnk\ShellNew\NullFile","","REG_SZ"
End if
If (RegInfo("HKCR\Folder\ShellNew\")) = "False" Then 
 WS.RegWrite "HKCR\Folder\ShellNew\Directory","","REG_SZ"
 WS.RegWrite "HKCR\Folder\ShellNew\IconPath","%SystemRoot%\system32\shell32.dll,3","REG_EXPAND_SZ"
 WS.RegWrite "HKCR\Folder\ShellNew\ItemName","@shell32.dll,-30396","REG_SZ"
 WS.RegWrite "HKCR\Folder\ShellNew\MenuText","@shell32.dll,-30317","REG_SZ"
 WS.RegWrite "HKCR\Folder\ShellNew\NonLFNFileSpec","@shell32.dll,-30319","REG_SZ"
 WS.RegWrite "HKCR\Folder\ShellNew\Config\AllDrives","","REG_SZ"
 WS.RegWrite "HKCR\Folder\ShellNew\Config\IsFolder","","REG_SZ"
 WS.RegWrite "HKCR\Folder\ShellNew\Config\NoExtension","","REG_SZ"   
End if
If (RegInfo("HKCR\.rtf\ShellNew\")) = "False" Then 
 WS.RegWrite "HKCR\.rtf\ShellNew\Data","","REG_SZ"
 WS.RegWrite "HKCR\.rtf\ShellNew\ItemName","@%ProgramFiles%\Windows NT\Accessories\WORDPAD.EXE,-213","REG_EXPAND_SZ"  
End if 
If Not (RegInfo("HKCR\.rar\ShellNew\")) = "False" Then WS.RegDelete "HKCR\.rar\ShellNew\"
If Not (RegInfo("HKCR\.zip\CompressedFolder\ShellNew\")) = "False" Then WS.RegDelete "HKCR\.zip\CompressedFolder\ShellNew\"
If (RegInfo("HKCR\.txt\ShellNew\")) = "False" Then 
 WS.RegWrite "HKCR\.txt\ShellNew\NullFile","","REG_SZ"
 WS.RegWrite "HKCR\.txt\ShellNew\ItemName","@%SystemRoot%\system32\notepad.exe,-470","REG_EXPAND_SZ"  
End if

'Add Take Ownership
If Not Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (RegInfo("HKCR\exefile\shell\takeownership\")) = "Take Ownership" Then
  WS.RegWrite "HKCR\exefile\shell\takeownership\","Take Ownership","REG_SZ"
  If Not (RegInfo("HKCR\exefile\shell\takeownership\HasLUAShield"))="" Then WS.RegWrite "HKCR\exefile\shell\takeownership\HasLUAShield","","REG_SZ"
  If Not (RegInfo("HKCR\exefile\shell\takeownership\NoWorkingDirectory"))="" Then WS.RegWrite "HKCR\exefile\shell\takeownership\NoWorkingDirectory","","REG_SZ"
  If Not (RegInfo("HKCR\exefile\shell\takeownership\command\"))="" Then WS.RegWrite "HKCR\exefile\shell\takeownership\command\","cmd.exe /c takeown /f \”%1\” && icacls \”%1\” /grant administrators:F","REG_SZ"
  If Not (RegInfo("HKCR\exefile\shell\takeownership\command\IsolatedCommand"))="" Then WS.RegWrite "HKCR\exefile\shell\takeownership\command\IsolatedCommand","cmd.exe /c takeown /f \”%1\” && icacls \”%1\” /grant administrators:F","REG_SZ"
 End if
 If Not (RegInfo("HKCR\dllfile\shell\takeownership\")) = "Take Ownership" Then
  WS.RegWrite "HKCR\dllfile\shell\takeownership\","Take Ownership","REG_SZ"
  If Not (RegInfo("HKCR\dllfile\shell\takeownership\HasLUAShield"))="" Then WS.RegWrite "HKCR\dllfile\shell\takeownership\HasLUAShield","","REG_SZ"
  If Not (RegInfo("HKCR\dllfile\shell\takeownership\NoWorkingDirectory"))="" Then WS.RegWrite "HKCR\dllfile\shell\takeownership\NoWorkingDirectory","","REG_SZ"
  If Not (RegInfo("HKCR\dllfile\shell\takeownership\command\"))="" Then WS.RegWrite "HKCR\dllfile\shell\takeownership\command\","cmd.exe /c takeown /f \”%1\” && icacls \”%1\” /grant administrators:F","REG_SZ"
  If Not (RegInfo("HKCR\dllfile\shell\takeownership\command\IsolatedCommand"))="" Then WS.RegWrite "HKCR\dllfile\shell\takeownership\command\IsolatedCommand","cmd.exe /c takeown /f \”%1\” && icacls \”%1\” /grant administrators:F","REG_SZ"
 End if
 If Not (RegInfo("HKCR\Directory\shell\takeownership\")) = "Take Ownership" Then
  WS.RegWrite "HKCR\Directory\shell\takeownership\","Take Ownership","REG_SZ"
  If Not (RegInfo("HKCR\Directory\shell\takeownership\HasLUAShield"))="" Then WS.RegWrite "HKCR\Directory\shell\takeownership\HasLUAShield","","REG_SZ"
  If Not (RegInfo("HKCR\Directory\shell\takeownership\NoWorkingDirectory"))="" Then WS.RegWrite "HKCR\Directory\shell\takeownership\NoWorkingDirectory","","REG_SZ"
  If Not (RegInfo("HKCR\Directory\shell\takeownership\command\"))="" Then WS.RegWrite "HKCR\Directory\shell\takeownership\command\","cmd.exe /c takeown /f \”%1\” && icacls \”%1\” /grant administrators:F","REG_SZ"
  If Not (RegInfo("HKCR\Directory\shell\takeownership\command\IsolatedCommand"))="" Then WS.RegWrite "HKCR\Directory\shell\takeownership\command\IsolatedCommand","cmd.exe /c takeown /f \”%1\” && icacls \”%1\” /grant administrators:F","REG_SZ"
 End if  
End if

'Add Command Promt (Admin)
If Not Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Then
 If Not (Reginfo("HKCR\Directory\shell\runas\")) = "Open Command Window Here (Admin)" Then WS.RegWrite "HKCR\Directory\shell\runas\","Open Command Window Here (Admin)","REG_SZ"
 If Not (Reginfo("HKCR\Directory\shell\runas\HasLUAShield")) = "" Then WS.RegWrite "HKCR\Directory\shell\runas\HasLUAShield","","REG_SZ"
 If Not (Reginfo("HKCR\Directory\shell\runas\Command\")) = "cmd.exe /s /k pushd " & Chr(34) & "%V" & Chr(34) Then WS.RegWrite "HKCR\Directory\shell\runas\Command\","cmd.exe /s /k pushd " & Chr(34) & "%V" & Chr(34),"REG_SZ"
 If Not (Reginfo("HKCR\Drive\shell\runas\")) = "Open Command Window Here (Admin)" Then WS.RegWrite "HKCR\Drive\shell\runas\","Open Command Window Here (Admin)","REG_SZ"
 If Not (Reginfo("HKCR\Drive\shell\runas\HasLUAShield")) = "" Then WS.RegWrite "HKCR\Drive\shell\runas\HasLUAShield","","REG_SZ"
 If Not (Reginfo("HKCR\Drive\shell\runas\Command\")) = "cmd.exe /s /k pushd " & Chr(34) & "%V" & Chr(34) Then WS.RegWrite "HKCR\Drive\shell\runas\Command\","cmd.exe /s /k pushd " & Chr(34) & "%V" & Chr(34),"REG_SZ"
End if

'Add .Net Framework Environment
If FSO.FolderExists(Envs("%Systemroot%") & "\Microsoft.NET\Framework") Then
 Dim j
 For Each j in FSO.GetFolder(Envs("%Systemroot%") & "\Microsoft.NET\Framework").subfolders
  If FSO.FileExists(Envs("%Systemroot%") & "\Microsoft.NET\Framework\" & j.name & "\Regasm.exe") Then
   Envs_Set(Envs("%Systemroot%") & "\Microsoft.NET\Framework\" & j.name & "\")
  End if
 Next 
End if 

'Remove OneDrive
If Not (Instr(IsOS("c"),"Microsoft Windows XP") <> 0 Or Instr(IsOS("c"),"Microsoft Windows 7") <> 0) Then
 'If Not (Reginfo("HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\")) = "False" Then WS.RegDelete "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\"
 'If Not (Reginfo("HKCU\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\")) = "False" Then WS.RegDelete "HKCU\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\"
 'If Not (Reginfo("HKLM\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\")) = "False" Then WS.RegDelete "HKLM\SOFTWARE\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\"
 If Not (Reginfo("HKCU\" & Current_Explorer & "Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\")) = "False" Then WS.RegDelete "HKCU\" & Current_Explorer & "Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\"
 If Not (Reginfo("HKCU\" & Current_Explorer & "MyComputer\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\")) = "False" Then WS.RegDelete "HKCU\" & Current_Explorer & "MyComputer\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\"
 If Not (Reginfo("HKLM\" & Current_Explorer & "Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\")) = "False" Then WS.RegDelete "HKLM\" & Current_Explorer & "Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\"
 If Not (Reginfo("HKLM\" & Current_Explorer & "MyComputer\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\")) = "False" Then WS.RegDelete "HKLM\" & Current_Explorer & "MyComputer\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\"
 If Not (Reginfo("HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{018D5C66-4533-4307-9B53-224DE2ED1FE6}")) = "False" Then WS.RegDelete "HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
 If Not (Reginfo("HKLM\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{018D5C66-4533-4307-9B53-224DE2ED1FE6}")) = "False" Then WS.RegDelete "HKLM\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
End if 

'Remove BaiduNetdisk
If Not (Reginfo("HKCR\CLSID\{679F137C-3162-45da-BE3C-2F9C3D093F64}\")) = "False" Then WS.RegDelete "HKCR\CLSID\{679F137C-3162-45da-BE3C-2F9C3D093F64}\"
If Not (Reginfo("HKCU\Software\Classes\CLSID\{679F137C-3162-45da-BE3C-2F9C3D093F64}\")) = "False" Then WS.RegDelete "HKCU\Software\Classes\CLSID\{679F137C-3162-45da-BE3C-2F9C3D093F64}\"
If Not (Reginfo("HKLM\SOFTWARE\Classes\CLSID\{679F137C-3162-45da-BE3C-2F9C3D093F64}\")) = "False" Then WS.RegDelete "HKLM\SOFTWARE\Classes\CLSID\{679F137C-3162-45da-BE3C-2F9C3D093F64}\"
If Not (Reginfo("HKCU\" & Current_Explorer & "Desktop\NameSpace\{679F137C-3162-45da-BE3C-2F9C3D093F64}\")) = "False" Then WS.RegDelete "HKCU\" & Current_Explorer & "Desktop\NameSpace\{679F137C-3162-45da-BE3C-2F9C3D093F64}\"
If Not (Reginfo("HKCU\" & Current_Explorer & "MyComputer\NameSpace\{679F137C-3162-45da-BE3C-2F9C3D093F64}\")) = "False" Then WS.RegDelete "HKCU\" & Current_Explorer & "MyComputer\NameSpace\{679F137C-3162-45da-BE3C-2F9C3D093F64}\"
If Not (Reginfo("HKLM\" & Current_Explorer & "Desktop\NameSpace\{679F137C-3162-45da-BE3C-2F9C3D093F64}\")) = "False" Then WS.RegDelete "HKLM\" & Current_Explorer & "Desktop\NameSpace\{679F137C-3162-45da-BE3C-2F9C3D093F64}\"
If Not (Reginfo("HKLM\" & Current_Explorer & "MyComputer\NameSpace\{679F137C-3162-45da-BE3C-2F9C3D093F64}\")) = "False" Then WS.RegDelete "HKLM\" & Current_Explorer & "MyComputer\NameSpace\{679F137C-3162-45da-BE3C-2F9C3D093F64}\"
If Not (Reginfo("HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{679F137C-3162-45da-BE3C-2F9C3D093F64}")) = "False" Then WS.RegDelete "HKCU\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{679F137C-3162-45da-BE3C-2F9C3D093F64}"
If Not (Reginfo("HKLM\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{679F137C-3162-45da-BE3C-2F9C3D093F64}")) = "False" Then WS.RegDelete "HKLM\" & Current_Explorer & "HideDesktopIcons\NewStartPanel\{679F137C-3162-45da-BE3C-2F9C3D093F64}"


'Fixing Network
If GetNetStatus("https://www.google.com.vn/") = "NO" Then 
 EnableNetwork()
 EnableDHCP()
End if
If GetNetStatus("http://2conglcvn.blogspot.com/") = "NO" Then SetDNS("Google")
If GetNetStatus("https://www.facebook.com/") = "NO" Then SetDNS("Google")  
 
'Done !
message = "You need restart explorer."
If Accept(message) = 6 Then
 Call Processes("-k","explorer.exe")
 WScript.Sleep 500
 WS.Run "explorer.exe",0,true
End if

End if 'End of Accept

'All Data
Private Const BS64_HomeDrive_Icon = "AAABAAIAMDAAAAEAIACoJQAAJgAAADAwAAABAAgAqA4AAM4lAAAoAAAAMAAAAGAAAAABACAAAAAAAABIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP8BAAD/Af///wGqqv8Dqqr/A6qq/wMAAP8BAAD/AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA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"
Private Const BS64_ShortCut_Arrow = "AAABAAQAAAAAAAEAIAD9AgAARgAAADAwAAABACAAqCUAAEMDAAAgIAAAAQAgAKgQAADrKAAAEBAAAAEAIABoBAAAkzkAAIlQTkcNChoKAAAADUlIRFIAAAEAAAABAAgGAAAAXHKoZgAAAsRJREFUeJzt3VFu2zAURFHVq+QSvcqiHwWaAqmb2JEiivecFdB4M4+WAjjbBgAAAAAAAAAAAAAAAAAAAAAAAAAAAACsZIxxO/sMwBuFhDALAMIsAAizAOAEyfdhyQ8NE1NICLMAIMwCgBN4HIYwCwAAAAAAAAAAAAAAAAAAAAAAAAAA4EL8mCR7EiaAK3D7szeBApid2x+ilB+ilJ8jCRfAjNz+EKX8EKX8EKX8EKX8EKX8nEHoAM7k9oco5Yco5Yco5Yco5Yco5WcmwgjwHdz+EKX8EKX8EKX8EKX8EKX8XIGQAuzJ7Q9Ryg9Ryg9Ryg9Ryg9Ryg9BY4yb8kOQ4kOU8kOU8kOQ532IUnxWJtwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHCcH2cfgO/x6j84ud/vP/c+CwAAAAAAAAAAAAAAAAAAAAAAAAAAAMBjY4zbq7+sDFzYysVf9oMBwJesfPsD/6H8EOSFH0QpPkQpP0QpP0QpP0QpP0QpP0QpP0QpP0QpP0QpP0Qp/8UZIK+SnQUYIq+Qm4UYJs+Ql8UYKJ8lK4syWD4iI4szYB6RjQBD5l/kIsSw+Zs8BBk62yYHWQaPDMQJQJfZIwRR5s4fwtBi3rwjFB1mzTtC0WDOPCQcazNfPiQkazJXPkVQ1mOmPEVg1mKePE1o1mCOvEx4rs38+DIhuiZzYzfCdC3mxa4ECuIsAYizBCDOEoA4SwDiLAGIswQgzhKAOEsA4sYYN4sA4iwBiLMEIM4SgDhLAOK8HAQsAsAiADaLANgsAmDzFwPI820A8G0A6iwBrkBIAQAAAAAAAAAAAAAAAAAAAAAAAABY0sw/EDvtwYDjWQAAcKRZHwMOPdSsHxr4TUEhzAKAMAsAOIZ3APBmxj5MdyBgETNuPDjTbJ2Y6jAAAAAAAAAAAAAAAAAAAAAAAAAAAACwtF+LwZjITzHoCgAAAABJRU5ErkJggigAAAAwAAAAYAAAAAEAIAAAAAAAgCUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWFhYAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWFhYAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWFhYAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWFhYAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///////8AAP///////wAA////////AAD///////8AAP///////wAA////////AAD///////8AAP7/////fwAA////////AAD///////8AAP///////wAA////////AAD///////8AAP///////wAA////////AAD///////8AAP///////wAA////////AAD///////8AAP///////wAA////////AAD///////8AAP///////wAA////////AAD///////8AAP///////wAA////////AAD///////8AAP///////wAA////////AAD///////8AAP///////wAA////////AAD///////8AAP///////wAA////////AAD///////8AAP///////wAA////////AAD///////8AAP7/////fwAA////////AAD///////8AAP///////wAA////////AAD///////8AAP///////wAA////////AAAoAAAAIAAAAEAAAAABACAAAAAAAIAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWFhYAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABYWFgCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFhYWAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWFhYAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/////////////////////////////////////+//9///////////////////////////////////////////////////////////////////////////////////////7//3//////////////////////////////////////KAAAABAAAAAgAAAAAQAgAAAAAABABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABYWFgCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFhYWAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFhYWAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWFhYAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//wAA//8AAN/7AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA3/sAAP//AAD//wAA"
Private Const BS64_OEM_img = "Qk1+owAAAAAAADYAAAAoAAAAbgAAAF8AAAABACAAAAAAAAAAAADEDgAAxA4AAAAAAAAAAAAA/////////////////////////////////////////////////////////////////////////////////////////////////v7+/////////////v7+//7+/v/+/v7//v7+//7+/v/+/v7//f39//39/f/9/f3//Pz8//v7+//7+/v/+vr6//r6+v/5+fn/+fn5//j4+P/4+Pj/9/f3//f39//29vb/9fX1//X19f/19fX/9fX1//X19f/19fX/9PT0//T09P/09PT/9PT0//T09P/09PT/9PT0//T09P/09PT/8/Pz//T09P/09PT/9fX1//X19f/09PT/9fX1//X19f/29vb/9vb2//f39//39/f/+Pj4//j4+P/4+Pj/+vr6//r6+v/6+vr/+vr6//v7+//7+/v//Pz8//39/f/9/f3//f39//39/f/+/v7//v7+//7+/v////////////7+/v/+/v7//v7+//7+/v/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+/v7///////////////////////7+/v/+/v7//v7+//39/f/9/f3//Pz8//v7+//6+vr/+Pj4//f39//29vb/9fX1//Pz8//z8/P/8fHx/+/v7//u7u7/7Ozs/+zs7P/r6+v/6urq/+rq6v/p6en/6Ojo/+fn5//n5+f/5+fn/+fn5//m5ub/5ubm/+bm5v/m5ub/5ubm/+bm5v/m5ub/5ubm/+bm5v/l5eX/5eXl/+Xl5f/l5eX/5eXl/+Xl5f/l5eX/5eXl/+Xl5f/l5eX/5eXl/+Xl5f/l5eX/5eXl/+Xl5f/m5ub/5ubm/+bm5v/m5ub/5ubm/+bm5v/m5ub/5+fn/+fn5//o6Oj/6Ojo/+jo6P/p6en/6urq/+rq6v/q6ur/7Ozs/+zs7P/v7+//7+/v//Hx8f/y8vL/8/Pz//X19f/29vb/+Pj4//n5+f/7+/v/+/v7//z8/P/8/Pz//f39//7+/v/+/v7//v7+//7+/v/////////////////////////////////////////////////////////////////////////////////+/v7//v7+//39/f/9/f3//Pz8//r6+v/5+fn/9/f3//b29v/09PT/8vLy//Dw8P/u7u7/7Ozs/+rq6v/p6en/6Ojo/+fn5//m5ub/5ubm/+bm5v/l5eX/5eXl/+Xl5f/l5eX/5eXl/+Xl5f/l5eX/5eXl/+Tk5P/k5OT/5OTk/+Tk5P/l5eX/5eXl/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Xl5f/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/l5eX/5eXl/+Tk5P/k5OT/5OTk/+Tk5P/l5eX/5eXl/+Xl5f/l5eX/5eXl/+Xl5f/l5eX/5eXl/+bm5v/m5ub/5ubm/+bm5v/n5+f/6enp/+rq6v/s7Oz/7u7u/+/v7//x8fH/8/Pz//X19f/39/f/+Pj4//r6+v/7+/v//Pz8//7+/v/+/v7//v7+//7+/v////////////7+/v///////v7+//7+/v/+/v7//f39//z8/P/6+vr/+Pj4//b29v/09PT/8vLy//Dw8P/u7u7/7Ozs/+rq6v/o6Oj/5+fn/+bm5v/l5eX/5eXl/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/l5eX/5ubm/+bm5v/p6en/6urq/+zs7P/u7u7/8PDw//Ly8v/09PT/9/f3//j4+P/6+vr//Pz8//39/f/+/v7//v7+///////+/v7//v7+//z8/P/6+vr/9/f3//b29v/09PT/8fHx/+/v7//t7e3/7Ozs/+np6f/o6Oj/5eXl/+Xl5f/l5eX/5eXl/+Xl5f/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/m5ub/6Ojo/+rq6v/s7Oz/7u7u//Dw8P/y8vL/9PT0//b29v/4+Pj/+vr6//z8/P/+/v7///////7+/v/+/v7//Pz8//v7+//6+vr/9/f3//X19f/09PT/8vLy//Dw8P/t7e3/6+vr/+np6f/n5+f/5ubm/+Xl5f/l5eX/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k4+T/5OPk/+Tj5f/j4uT/4+Lk/+Pj5P/j4+T/4+Pk/+Pj5P/j4+T/4+Pk/+Pj5P/j4+T/4+Pk/+Pj5P/j4+T/4+Lk/+Tj5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Xl5f/l5eX/5eXl/+bm5v/p6en/6urq/+3t7f/v7+//8fHx//Ly8v/19fX/9/f3//n5+f/7+/v//Pz8//7+/v/+/v7//v7+//7+/v///////v7+//7+/v/9/f3/+/v7//v7+//5+fn/9/f3//X19f/09PT/8vLy//Dw8P/u7u7/7e3t/+rq6v/p6en/6Ojo/+fn5//m5ub/5eXl/+Xl5f/k5OT/5OTk/+Tk5P/l5eX/5eXl/+Tk5P/k5OT/5OTk/+Tk5P/l5eX/5OTk/+Tk5P/l5OX/5eXk/+Tk5P/k5OT/5OTk/+Tk5P/k5OT/5OTk/+Tj5P/i4uT/4uLk/+Lh5P/i4eT/4uHj/+Hh4//h4uT/4ODj/+Dg4//g4OP/4ODj/+Dg4//g4OP/4ODj/+Dg4//g4eP/4eDj/+Hg4//h4eT/4eLj/+Hi4//i4uT/4+Pk/+Pk5P/j4+T/5OTl/+Tk5f/l5OT/5OTk/+Tk5P/k5OT/5OTk/+Xk5P/l5OT/5OTk/+Tk5P/k5OT/5OTk/+Tk5P/l5eX/5OTk/+Tk5P/k5OT/5OTk/+Xl5f/l5eX/5ubm/+fn5//o6Oj/6enp/+rq6v/s7Oz/7e3t//Dw8P/y8vL/9PT0//b29v/4+Pj/+fn5//v7+//8/Pz//f39//7+/v/+/v7///////7+/v/+/v7//v7+/////////////////////////////v7+//7+/v/+/v7//f39//39/f/9/f3//Pz8//v7+//7+/v/+vr6//j4+P/39/f/9vb2//X19f/09PT/8/Pz//Ly8v/w8PD/7+/v/+/v7//t7e3/7Ozs/+zs7P/s7Oz/6+vr/+rq6v/p6er/6enp/+fq6P/o6er/6Onp/+fo6P/n5+j/5ebo/+Tk6f/j5Of/4+Pn/+Pj5//g4ej/3+Dq/+Dg6f/g3+j/4N/o/97e5//e3uf/3t3n/97c6f/e2+r/3tzs/97d6//f3ev/393p/97e5//f3ub/39/n/9/e6P/g3+j/4eDo/+Hg5//i4+f/4uPm/+Tk6P/m5ej/5ubo/+Xm6f/n6Oj/6Ojo/+np6v/p6en/6Orp/+nr6v/r6+v/6+vr/+vr6//s7Oz/7Ozs/+3t7f/u7u7/7+/v//Hx8f/x8fH/8/Pz//T09P/19fX/9vb2//f39//5+fn/+fn5//r6+v/6+vr//Pz8//39/f/9/f3//f39//7+/v/+/v7//v7+/////////////////////////////v7+//7+/v/+/v7//////////////////////////////////////////////////////////////////////////////////////////////////v7+//7+/v/+/v7//v7+//7+/v/+/v7//v7+//7+/v/9/f3//f39//39/f/9/f3//f39//z8/P/7/Pv/+vv6//n8+v/5+/r/+Pv3//f4+//19vz/8vL7/+Hi9//Ny/L/u7by/62l8v+el+//j4fr/4d67P98cfD/c2fv/21e7/9oV/H/Zlfw/2RU8f9iUfH/ZVPy/2ZV8f9pWPD/alrw/3Ji8f96bPD/gXbt/4qB6v+Yju7/pp/y/7Sv8v/Fw/P/2dfz/+3r+//49fz/+Pf6//n5/P/6+vr/+Pv5//n7+//6/Pz/+/v8//z8/P/9/f3//f39//39/f/9/f3//v7+//7+/v/+/v7//v7+//7+/v/+/v7//v7+//7+/v/+/v7///////7+/v/+/v7////////////////////////////////////////////////////////////////////////////+/v7//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v7+//37/v/29/7/6+n6/8zH8/+rovX/j4Tw/3Nk7P9bSe//Tj3x/0s39P9KM/f/Ry36/0Is+f9BK/j/Pij4/z0o9/8+KPf/Pif3/z0o9v89KPX/PSj1/z0n9v89J/b/PSj1/z0o9f89Jvb/PCf3/z4o+P8+KPj/Pyr4/0Ar+f9ELfr/SDD6/0w19f9PO/D/VUTv/2ZX7v+Bd+v/n5fx/7668v/i3vn/9PT9//v7/v/+/v7//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v/+//7///////7//v3///79/v/9/v3/+/v//+/t/v/EwfP/m5Lx/3Jm7f9WRPH/TDj0/0gy+P9BK/n/QCj1/z8r9v9DMvf/Rzj3/0s+9v9PRfj/U0r5/1VN+P9ZUfr/XFT7/15W+/9fWfz/YVr9/2Bc/v9gXP7/YFv+/2Bc/f9gXP3/X1v8/15Z/P9eV/v/XFX6/1pS+/9YT/r/VUv5/1FH+P9MQfX/Sjv2/0Y19/9BLvb/Pyr0/0Mt+P9HMPr/Sjj3/1E+8/9lVO7/iX7v/7Su8f/i3vn/+vj///z+/v/9/v7//v7+//7//f/9//7////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+///+/////f/9//3+/v/7+/z/7ev8/7q28/+EefD/Wkzt/045+P9FMfn/QCv3/0Mw9/9JOPn/T0T1/1dM+f9fVv3/Ylz+/2Rg/f9lYf3/ZGD+/2Rg/f9kYP//ZWH//2Ri/v9jYf3/YWD8/2Nh/v9jYf7/YmH+/2Jh/v9hYP7/YmH9/2Jh/f9iYf7/YmH+/2Rh/f9kYf3/ZGD+/2Rg//9kYP7/ZGH8/2Ri/P9kYv3/ZmP9/2Zi/v9lYP3/Xlf6/1ZM+P9OQfb/Rjf3/0Ev9f9FL/j/Sjb2/1BB8/9vZPD/ppvx/9vY+P/5+f///v3+//7+/v/9//7//f/9//3//v///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////f7+//z+/f/6+v3/1tP3/5KK7/9fTu7/Tzj5/0Qv+P9DLvX/TkD2/1lP+P9iXPv/ZGD+/2Bd+/9ZU/z/S0P5/0tD+v9ZVvz/X138/2Jh/P9jY/7/ZGP+/2Rj/v9kY/7/Y2L+/2Ni/v9jYv7/Y2L+/2Ji/v9gYf7/YGH+/2Bh/v9gYv3/YGL9/2Bi/f9gYv3/Y2L9/2Ni/v9jYv//ZGP+/2Rj/v9kY/7/ZGP+/2Rl/f9lZf3/ZmT+/2dk/v9nZf3/Z2b9/2dm/f9oZv7/ZmL9/11W+P9RRPf/STb1/0Qt9v9IM/v/VUHz/3ds7f+6tfH/8/D+//39/v/8/v3//f7////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////5+v7/ysX1/31z7v9RPvL/SDL5/0Mv9/9MQvb/Xlf5/2po/f9oZ/3/ZmX9/2Vi/v9fXP7/QTn2/yMS9v8eDfr/Hw77/yUV9P9JQfj/XVv9/2Jh//9iYv7/YmP+/2Ji/v9iYf//YWH//2Bh//9gYP//YGD//19g//9fYP//X2D//2Bg//9gYf//X2D+/19g/v9iYf//YmH9/2Jh/f9iYv7/YmL+/2Nj/v9jZP7/Y2X+/2Rl/v9mZf7/aGb+/2hn/f9oZ/3/aGf9/2lo/v9paP3/aWj9/2pp/f9oZ/z/ZV/6/1ZL9/9INfT/Ri/3/005+P9jVO3/qaXv/+7t/P/+/P7//////////////v///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v/+//7+///+/v///f////r8+//6+/3/19X4/3917/9RP/T/RTH2/0Y19v9YUPX/aWb8/2tq//9qav3/amn+/2po/f9lZf3/YF/9/zsy9v8hDPr/HhPu/xoQvv8YEr//HhHy/yEQ9/9LRfr/Wlr+/15f/v9eYP7/XmD+/15f/v9eXv//Xl7//15e//9eXv//XV7+/11e/v9dXf7/XV3+/11d/v9dXv7/XV7+/15e//9eXv//X1///19g/v9fYf7/YGH+/2Bh/v9jYv7/Y2P+/2Rk/v9lZf7/Z2b+/2dm/v9paP7/amr+/2pq/v9qav3/amr9/2pq/f9qav7/amr9/2xp/P9gWvn/TUD1/0Iu9v9MN/f/Y1Xw/6+s8f/09f3//f38//79/v///v7///7////+//////7//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////f/+//7//f/9/f7/8e/7/5qT7/9WQ/T/SC/5/0g48/9dVff/bmz8/2xs/f9ra/7/bGv//2ts/P9qa/z/aWf//2Rj/P9DPPf/Hw74/x4T4f8KB2r/AQEy/wQBO/8RDpD/HxD0/yoa+P9XVPz/WVn+/11c/v9dXP7/XVz+/1tc/v9aXP//WVv+/1lb/v9ZWv7/WVr+/1lb/v9ZWv7/WVr+/1la/v9ZWv7/Wlz+/1pc/v9bXP//XV3+/15e/v9fXv//X17//2Bg//9gYf7/YGH9/2Ji/f9jY/7/ZWX+/2Zm//9pZ/7/amn+/2pq//9ra/7/a2v9/2xs/v9sbP7/bGz+/2xs/f9tav7/aGP8/1FD9f9GL/b/Tzj5/3dp7P/W0/j/+v3+///+/v////////7////+///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8//7//fz9/9PR9/9uZOz/STX5/0Yy8/9aUvX/bmz8/25s/v9wbf7/bW39/2xs//9tbf7/a2z+/2lp/v9lY/3/VlL7/yMS9f8eEu7/Dglq/wQBHv8AAQj/AgER/wICNf8fEc//Hg75/0c/+v9WVv7/WFr+/1la/v9YWv7/WFn//1hY//9XWP//V1j//1dY/v9XWP7/V1j+/1dX/v9XV/7/V1j//1dY//9YWP//WFj//1lZ//9ZWf7/WVr+/1pb//9aW///XV3+/15e/v9fX/7/YGH9/2Fh/f9iYv3/Y2T+/2dl/v9oZv//aWf+/2pp/v9ra/3/bGz+/2xs/v9ubv7/bW39/25u/f9tbP7/bm38/2Vg+P9KOvX/RjH3/1hH8P+qovH/9vf+//7+/v/+/v7///7//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v/+//7//v/+//7//f7+//v7/v+4sPP/XEnw/0Yx9v9QQPT/a2b8/29u/f9vb/7/b3D+/25v/v9tbv7/bG3+/2xt/v9qav7/ZWX//19e/f81Kvf/Hw36/xcQmv8BASH/AAEG/wAAAf8BAAP/AgIT/xMOg/8dDvn/Mij3/1FS/f9VVv//Vlf//1ZX/v9VVv//VFb//1NV/v9UVf7/VFX+/1RU/v9UVP7/VFX+/1RV/v9VVf7/VVX+/1VV//9VVf//Vlb//1ZX/v9XWP7/WFn//1hZ//9aWv//W1v+/1xc/v9eXv7/X1/+/19g/v9fYf7/Y2L9/2Rj/v9mZf//aGf//2lp/v9ra///bGz//25t/v9ubv7/bW/+/25w/f9wcP3/b2/+/3Bt/v9bUvb/RjD1/1A69v+FfOv/7ez8//z9/f/+/f7//////////v/+//7//v/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////9/v7//P7///z+/v/6+v3/oJvv/1JA8/9FMPb/W1H2/3Bu/P9xb/7/cW///29x//9vcP//bm7+/21t/v9sbP7/amr+/2dm//9iYf3/Uk38/yAQ+v8gFN//BAQ//wABCP8AAQD/AAAA/wEAAv8BAAn/CAZT/x8U8P8mGPn/Tkv+/1JS//9TVP7/VFT+/1JT//9RU///UFL+/1BS/v9RUf//UFH//1BR//9RUv//UVL+/1FS//9RUv//UlP+/1JT/v9TU///U1T+/1VV/v9VVv7/VVb+/1dY//9YWP7/WVr//1pb/v9bXP7/Xl3+/19f//9hYf7/YWH+/2Jj/v9lZP7/Z2b+/2ho/v9paf7/a2v+/2xt/v9tbv7/b3D+/3Bx//9vcP//b3D//3Bu/f9oY/r/STf0/0oz+/9zZuv/5eL6//v8/f///v////7///7//v/+//7///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////7+/f/7/v3/+Pj+/56V7f9SO/b/RTL0/2Rg+P9xb/7/cnD9/3Jx/f9xcf//b3D//25u/v9tbf7/a2v+/2lq/v9oZ///Y2P+/15c/P85Lvf/Hw/6/xUQlv8DARv/AQAD/wEAAv8AAQH/AAAB/wAABf8CAjL/HhLi/x0R+P9KRf7/Tk3+/09Q/v9QUP//T0///05O/v9OT/7/Tk/+/05O/v9OTv7/Tk7+/05O/v9OTv7/Tk///05P//9PUP7/T1D+/09Q/v9QUf7/UVL//1JT//9SU///VVX//1VW/v9WV/7/V1n+/1la//9bW///W1v+/15e/v9eX/7/X2D+/2Fi/v9jY/3/ZWX+/2Zn//9qaf7/a2v+/2xs//9ubv7/b3D+/3Bx//9xcv//cXD9/3Jw/v9va/z/TT/z/0oz+f9uXe3/4t/5//z9/P/9/vv///7//////v///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////P7+//r7/v+inPD/UT71/0k19P9qZPn/dHL8/3Ry/f9zcv3/cnD+/3Fw//9ubv7/bW3+/2xr/f9paf7/Z2j+/2Rl/v9gYfz/V1X9/yMW9/8gEu3/CQdO/wICCf8CAQL/AQEB/wABAf8AAQD/AQED/wABJv8eE87/HA/4/0E9/f9LSv7/TU3+/01N/v9NTf//TEz+/0tL/v9LS/7/SUr+/0lK/v9JSv7/SUr+/0lK/f9KS/7/Skv+/0xM/v9MTP7/TUz//01N/v9OT/7/T1D//09Q//9SUv7/UlL9/1NU/v9WVv7/V1f//1hZ//9YWv//XFv+/1xc/v9eXv7/YGD9/2Jh/f9jYv3/ZWX+/2hn/v9paP7/a2v//21s/v9ubv7/b3D//3Bx//9zcv7/c3L9/3Jx/P9wbvz/UkTz/0Yy9/9tYe3/5+b5//z+/f///v///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v/+/v7//v/+//3//f/6/P3/ubLy/1RA9f9LN/X/b2j5/4N/8/94efn/c3T+/3Fy/v9wcP//bm7+/21t/v9ra/7/aWn+/2do//9kZf7/YGH//1xb/f9KRfr/Hw76/xwTx/8BACP/AQAC/wAAAP8AAQD/AAAA/wABAP8BAAL/AQAg/xkSv/8dDfv/PDj9/0dH/v9ISf//SUn//0hJ//9ISf//R0j+/0dI//9HR///R0f//0dH//9HR/7/R0f+/0hI//9ISP//SEn//0hJ//9ISf//SUr+/0pL/v9LTP//S03+/05P/v9OT/7/UFH//1JT/v9UVP7/VVX+/1dY//9YWP7/WVr//1pc//9cXf7/X1/+/2Fh/v9jYv7/ZmT+/2hm/v9oaP7/amr+/2xs//9tbf//bm///3Bx//9xcv//cnP//3Jx/v9xb/v/UEHz/0k0+f9+cu3/8fP9//3//v////3//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v/8/v7//P3+/9XR+P9cS/L/STf1/21l9/+MjPH/oJ/w/3Z2/P9yc/7/cXL//25v/v9tbf7/bGz+/2pp//9oZ/7/ZGX+/2Ji/f9eXv//WVf+/zcw+P8fDvv/FA+Q/wAAE/8AAQH/AAAA/wAAAP8AAAD/AAEA/wEAAv8BAB//GBK+/x0N/P86NP3/RUT+/0ZG/v9HRv//RkX+/0VF/v9FRf3/RUX9/0ND/f9DQ/3/RET+/0NE/v9DRP3/Q0X+/0NF/f9FRf3/RUX9/0ZG/v9HR/7/R0j+/0lK/v9JSv7/TEz+/0xM/v9OTv7/UFD+/1FS/v9SU/7/VFX+/1ZW/f9XV/7/WFj+/1pb//9cXf7/X1/+/2Fh/v9iYv3/ZGX+/2Zn/v9paP7/a2r+/2xs/v9tbv7/b3D+/3Bx//9yc///c3P//3Ny/f9wbvv/TDzz/0049/+bke7/+fv+//79/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v79//38/f/v8Pv/c2bs/0049v9oXfT/h4f0/8/R9f9/gfX/dnj8/3Fy/v9vb/7/bm3+/2xr/v9qaf7/aGf//2Zk/v9jYv3/YWH+/11c/v9WVP3/KyD4/x8R8/8MCWP/AQEK/wIAAf8AAQH/AQAB/wAAAP8BAQD/AAAB/wEAIP8YE73/HA36/zk0/P9CQf3/REP9/0RD/v9EQv//REL//0NC/v9DQv7/QUL+/0FC/v9BQv7/QkL+/0JC/v9CQf7/QkH+/0RD/f9EQ/3/REP9/0VE/v9FRP7/Rkb+/0ZH/v9KSP7/S0n//0xL//9NTf7/Tk7+/09Q//9QUf//VFT+/1VV/v9WV///WFn//1lb/v9cXf7/Xl7+/2Bg/v9hYv3/Y2T9/2dn/v9paP7/a2v+/2xs/v9ub/3/b3D+/3Fy/v9zc///dHP//3Ny/f9saPv/RzH2/1ZB8v/EwfX//f7+///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8/v7//Pv+/5+Z8P9TPPj/Wkv1/4SB9v/V1ff/rbHz/3t+/P9ydv3/b3D//21t/v9sa/7/amn+/2dn/v9mZf7/ZGL9/2Fh/v9fXv7/Wlj+/1NQ/f8iFPf/IhTo/wUEO/8BAQb/AQAA/wABAP8BAAD/AAAA/wEBAf8AAQL/AQEk/xsUxP8dDvn/ODP9/z8+/v9BQf7/QUH//0FA//9AQP//QED//0BA//8/P///Pz///z4+/v8+P/7/Pj/+/z4//v8+QP7/QEH+/0FB/v9BQv7/QkL//0JC/v9DQ/7/Q0T9/0ZF/v9HRv7/SEj//0lK//9KS/7/TU3//09O//9RUf7/UlP9/1VV/f9VV/7/WFj+/1la/v9bW///Xl7+/19h/v9hYf3/Y2T+/2dn/v9oaf7/amv+/2xt/f9tbv7/b3H+/3Fy//9zc///dHP+/3Jz/f9kXPf/RC/3/2lZ7//u7Pz//P7+//3+/v/+//////////////////////////////////////////////////////////////////////////////////////////////////////////3//f/e3Pj/Xkjz/1A89f9/ePr/trnz/+jp+/+Hh/b/e3z8/3Bz/f9tbv7/bGz+/2tq/v9oZ/7/ZWb+/2Jj/f9hYf3/X1/+/1xc/v9XVv7/S0f8/x4P+P8eE9T/AgIn/wABA/8AAAD/AAAA/wEAAP8AAAD/AQEB/wABA/8CACz/HhLY/x0O+/84Nf3/PTz+/z8+//8+Pv7/PT3//z09//88PP7/PDz+/zw8/v88PP7/PDz+/zw8/v88PP7/PDz+/zw8/v89Pf7/PT3+/z0+/v8+P/7/Pz/+/0FB/v9BQv7/REP+/0RD/f9GRf7/R0f//0hJ//9LSv7/TE3+/05Q/v9MU///UlP+/1NU/v9VVv7/V1j+/1lZ//9cXP7/Xl/+/2Fg/v9hYv3/Y2T+/2Zn/v9paf7/a2v//2xs/v9ub/7/cHL//3Jz//90c///c3P+/3Nw/f9RRfT/TDf5/56X8P/6/Pz//P/8//3////////////////////////////////////////////////////////////////////////////////////////////////////8/v7/+fr9/4yD7f9QOfj/a2D2/5SY8f/08/7/uLr1/3+C/P92dfz/bnD+/2xs/v9qav7/aWf+/2Zl/v9iY/7/YWH+/19f/v9dXP//WVr+/1RU/v9DPvv/HQ76/xsTvf8BACH/AAAC/wAAAP8AAAD/AQAA/wAAAP8BAAD/AAAG/wMDOP8hE+f/HRH7/zg2/v86Of7/PDz+/zw8/v87Ov7/Ozr//zo5/v86Of7/Ojj//zo4//86Of//Ojn//zo5//87Of//Ozn//zs6/v87Ov7/PDv//zw8//88PP7/Pj7+/z8///9BQf7/QkL+/0JD/v9ERP7/Rkb+/0dI/v9JTP//S1D9/0xU/f9MVf3/TlX9/1BV/v9VV/7/WFj//1la/v9bXP7/X1///2Bh/v9hYv3/ZGT+/2hn//9paf7/a2v+/21u/v9vcP//cXL+/3Jz//90dP7/cnT8/29p/P9FMfT/WUns/+Pg+v/8/vz//v3///////////////////////////////////////////////////////////////////////////////////////////////////7+/v/X1ff/WUjz/1NA9P+Ggfn/09X3/+/y/P+QkfT/e3v+/3Nz/f9ubf//a2v//2lo/v9oZv//ZWP+/2Jh/v9hYP7/YF7+/1tb//9XWP7/UlH+/z43+f8dDfv/FxKr/wECGf8AAAH/AAAA/wAAAP8BAAD/AAAA/wEAAf8BAAj/CghU/yER8P8hFvn/ODX//zk4//86Of3/OTj9/zg3/v84Nv7/NjT8/zY0/f82NP3/NjT9/zY0/f82NP3/NjT9/zY0/f82NP3/ODb9/zg2/f85OP7/Ojn//zs6//87O/7/PDz+/z49/v8/P/7/QEH+/0JC/v9EQ/3/RUf+/0dM/v9Ea/P/OGj0/0hc/P9MWf7/T1b//1JV/f9VVv7/WFn+/1lb/v9cXP7/X1///2Fh//9jYv7/Z2X//2hn/v9qav7/bG3+/25v/v9vcf3/cXP+/3Rz/v91cv//cnH+/1hM9v9KNfr/mJDu//78/v/8/v7//////////////////////////////////////////////////////////////////////////////////v/////+/v/+/v7/+/z+/5GI8f9RO/j/a2L3/6Kh8//7+v3/ys31/4SF/P94d///cG///2xs/v9oaf7/ZWb+/2Rk/v9jYv7/YGD//11d//9bW///WVr//1VV//9OTv7/ODP7/x4N/f8UDZ7/AAIW/wAAAP8AAAD/AAAA/wAAAP8EAQD/AQAD/wABD/8QDHv/HA74/yYc+P82M/7/NTX9/zU1/f80NPz/MzP+/zIy/v8xMv7/MTL+/zEx/v8xMf7/MTH+/zEx/f8xMf3/MjL+/zIy/v8zM/7/MzP+/zQ0/v81Nf7/Njb+/zg5//85Ov//Ozv+/zw9/v89P/7/PkD9/0BC/v9CRf3/Q0z+/zNn8v8p0/v/LYLy/0Rl/P9KX/z/T1f//1JW/v9WWP3/V1n+/1la/v9cXf7/X1/+/2Fh/f9iY/3/ZWf8/2hp/f9qbPz/bG3+/25v/v9wcf//cnP//3Rz/v90c/3/bmz7/0Yy9v9cTfD/6eb7//r+/P/////////////////////////////////////////////////////////////////////////////////+/////f////7+/f/s7Pv/XUzw/1E+9P+Ff/v/1dT3//n6/f+kpfP/fH/9/3N0/v9tbf3/aWr9/2do//9kZf7/Y2L9/2Fh/v9fX///XFz//1la/v9XWf3/U1T9/01M/v83Mvv/HQ37/xUOmv8AARb/AAAA/wAAAP8AAAD/AAAA/wIAAf8AAQL/AQAa/xcSq/8dDvz/KyT6/zIx/f8zMv7/MzP//zIy/v8xMP7/Ly/+/y8v/f8vL/3/LS7+/y0u/v8tLv7/LS7+/y0u/v8tL/7/LS/+/zAw/v8wMP7/MDD+/zIx/v80NP7/NDT+/zU1/f85OP7/Ojn+/zs7/v88Pf3/Pj/+/0FC/f9CS///N1v6/xnL9/8S7vv/KJrz/0Fs+/9LYf3/TVn9/1JX/f9WWP3/WVn//1pb/v9cX/7/X2H//2Ji//9iZv7/Zmv9/2Zs/f9qbv7/bG/+/29w/v9xcv//cnT+/3Nz/v9zcP3/Vkj2/0s4+P+vqPD/+/39//////////////////////////////////////////////////////////////////////////////////7////7//3//Pz9/7Sv8/9UPfr/YVj1/5yY8v/3+P3/6Or7/4qL9v94ef3/b3H+/2pu/f9mav7/ZWj//2Jk/v9gYv3/X1/+/11d/v9ZWv7/WFn+/1VX/f9SUv7/S0v9/zgx+/8dDfv/FhCf/wEAGf8AAAH/AAAA/wAAAP8BAAD/AwEB/wEBBv8EAjH/HxXa/xwN+v8uLP3/MDD+/y8v/v8vL/7/Li79/ywt/v8sLP7/Kyz+/yss/v8qK///Kiv//yor/v8qK/7/Kiv+/yor/v8qK/7/LS3+/y0t/v8tLv7/Ly/+/zAw/v8yMv7/MjP+/zU0/v82Nv7/ODj+/zs7//88O///Pj/+/z9H/v86WPv/JZz1/wr7/v8N9v7/IbL1/z5z+P9IYvz/Tlv+/1NZ/f9XWf7/WFn+/1td/v9dYv7/YGb+/19r/f9gcP3/YnH6/2Zv/v9qb/7/bXD+/3Fx/v9ycv7/cnL+/3Rx/f9sZPr/RS/2/3Nl7v/59/7//////////////////////////////////////////////////////////////////////////////////v////7+/v/5+vz/gXPv/0069/93dPr/xML2//38/v/FxvX/g4X8/3V3/v9scP//aG/9/2Rt/f9havz/YGT+/15h/v9dXv7/Wlv+/1hZ/v9VV/7/U1T+/1BQ/v9KS/7/OjL7/x0M/P8ZE67/AwEe/wAAAv8AAAD/AAAA/wAAAP8BAQL/AQIM/w0LZf8eEfP/IBT7/y4u/v8uLf3/LS3+/y0t/v8rLP7/Kiv//yoq//8pKf7/KCn+/ygp/v8oKf7/KCj+/ygp/v8oKf7/KSn+/ykp/v8qKv7/Kir+/yor/v8sLP7/LS3+/y4v//8vMP7/MzH+/zQz/v81Nf3/ODj//zs6/v88PP7/PEL+/ztS/f8qdfX/D/D+/wX9/v8K+v7/H8b4/zl49/9KZP7/UV39/1Na/v9VW/7/V2D//1ho/f9YcPz/Unn6/0WS8/9Ft/b/XXb5/2lv/v9sb/7/b3D//3Jy/v9zcv7/cnH+/3Jw/v9MOPX/UEDz/9nX+f/////////////////////////////////////////////////////////////////////////////////+/////v7+/+fk+v9cTfD/VUb1/4qI+f/o6fv/+fr+/6al9P9+gP7/cXf9/2Z1/P9hdPz/TpLz/1p59/9eZP7/XWD9/1tc//9YWf//Vlf//1NV/v9QUv7/Tk7//0lJ/v88N/3/HQ75/xwUx/8CASj/AAAC/wAAAP8AAAD/AAAB/wEBAv8BAR//GRKx/xsN+/8mH/z/LSz+/ywr/v8qK/7/Kiv//ykp/v8oKP7/KCj+/ycn/v8nJv3/Jyb9/ycm/f8mJv3/Jyb9/ycm/f8nJ/7/Jyf+/ygo/v8oKP7/KSn//ykq/v8qK/7/Kyz+/ywu//8wLv//MTD+/zIy/v8zNP7/Nzf9/zk5//86Pv//N0r+/zJi+v8Xzfj/Bf79/wH+//8K/P3/Gtj5/zSG8/9GbPv/TWP9/1Bm/f9Rbv3/Snj6/zqX9/8g0Pj/FfX8/zK/9/9gdf3/aG/+/2tt//9vbv//cHH//3Jz//9xcv7/cHH8/1lN9/9LN/n/qaLx/////v////7///7///////////////////////////////////////////////////////////////////7+///9/vz/v7v0/1FC+P9hXPb/naP1//j7/v/w9P3/jY73/3d//f9rev7/XX75/z2h9P812Pv/UHb3/11k/f9cXvz/Wln//1dY//9VVf7/UlP+/09Q//9NTP//R0f9/z49/f8gEPr/HhTi/wQEOP8BAAT/AAAB/wAAAf8AAAH/AwEN/wkGU/8fE+v/HA/5/ysq/P8rKv//Kyn+/ygp/v8oKP7/Jyf+/yYm/v8lJv7/JSb+/yUl/f8kJf7/IyX+/yQl/v8jJf7/IyX+/yQl/v8kJf7/JSb9/yUm/v8mJ/7/Jyf+/ygp/v8qKv//Kiv+/y0s//8uLv//MDD+/zIx/v80NPz/Njb+/zk6/v85Rf3/Nln8/yOd9v8F+/7/Av7//wT9//8G/f7/GOX8/y2V8/9Cefr/RHr6/zOU9v8gzfn/Dvb8/wT9/v8L+f//QJz2/2B0/v9nbv7/amz+/25t/v9vcP7/cXL//3Fy/v9ycP7/ZmP5/0cw9v96ce7/+/r+/////f///v////7////////////////////////////////////////////////////////////////+//v9/v+Vj+//TkH4/2aT9P+80fX/+/38/9jc9v+Djvv/cIT8/1+E/P87rfP/FvP9/yvI9/9Zcv3/W2X+/1pe/P9aWf//Vlf//1RU/v9RUv7/Tk/+/0tL/v9HRv7/QD7+/yUY+f8fEPT/DAln/wMAD/8AAAL/AQEA/wEBBf8CASb/GhKx/x4N+/8jGvv/Kyr+/ykp/v8pKP7/Jyf+/ycm/v8mJf//JCT+/yMk/v8iI/3/IiP9/yIi/v8hIf3/IiL+/yEi/f8hIv3/IiP+/yIj/v8iI/3/IyT9/yQl/v8mJf7/Jyb+/ygn/v8oKP7/Kir//yss/v8sLv7/MS/+/zIy/f8zNP7/ODf+/zk+/v80UPz/KXL0/w/z/v8C//3/Af7//wL+/v8E/fz/EPH8/yW39f8dzvn/DvX+/wT9/v8E/f//Av7//xnp/f9Ig/f/YHH+/2Zr/f9oav7/bGz+/25v/v9wcf//cXL+/3Fw/f9xbP3/RzT1/1xM8P/v7f3//v78///////////////////////////////////////////////////////////////////////9//7/+Pn+/3Nq7/9OQfb/d6T4/9f7///7/v7/vsv2/3mV/f9hkfv/OLT1/w/2/P8J+/7/N6n3/1lw/v9bYf//WVv+/1dY//9UVf7/UVL//09P/v9KS/7/SEn//0VF/v9CP/3/LCX5/x4O/P8WEq3/BAMp/wICDf8BAQv/AgIh/w4MfP8dEfL/HhD7/ygn/f8pKf7/KCj+/yYm/f8kJf//IyP+/yIi/v8iIf7/ISH+/yEh/f8hIf3/ICD//yAg//8fH///ICD+/yAg/v8gIf//ICH+/yEh/f8iIv7/IyP//yMk/v8jJP3/JCb9/yYn/v8oKP7/KSn//yor//8tLf7/MDD+/zIy/v8zNP3/NDn+/zRI/f8xYvr/G8z4/wT9/v8B//7/Av7//wD///8A////Av3+/wH+//8A////AP///wD///8F/f7/J8b3/1R6/P9fbP7/Zmj//2pp/v9ra///bm7+/29v//9xcv//cHH9/3Fu/f9RQfX/UT32/9HN9f/+/f3//P/+//7//v////////////////////////////////////////////////////////////3//f/u7f3/Xk7t/1NK8/+XnfX/8/v///j//v+S5fr/Wq/1/zq/+P8T+Pv/Avz9/xD3/v9AjvP/V23+/1hf/v9XWv7/Vlf+/1NU/v9QUf7/Tk7+/0pL//9ISf//RUX+/0I//P84Nv3/Hg74/yAR8P8NCXT/AQIz/wICNf8OCXX/HhLp/xsN+/8mH/z/KCj+/ycn/v8mJv3/JSX9/yMj/v8iIv7/ISD+/yAg//8gIP//ICD//yAg//8fH///Hx///x4e/v8eHv7/Hh7+/x8f//8fH///IB/9/yAf/f8gIP7/ISH+/yIi/v8jJP7/JCX+/ycm/v8oKP7/KSn//yor//8rLf7/LzD+/zEz/v8xOvz/NUf9/zFe+/8joff/CPz9/wH+/f8C//7/AP///wD///8A////AP///wD///8A////AP///wv5/v82nvf/WHP+/15o/f9kZv7/aGf9/2pq/v9ubv7/b2///3Fy//9wcf3/cW79/1lN9v9MN/j/sary//z9/f/+/////////////////////////////////////////////////////////////////////f39/9fU9/9aRfb/X1b3/6+v9P/5/f7/8////2H7/f8h9v7/DPr+/wP8//8D/f7/GuL7/0yA+/9Wav3/V13+/1VZ/f9VVf7/UlL9/09P/v9NTf7/SUr+/0ZH/v9ERP3/QUD+/zo5/v8tJfj/HA36/x4T6f8WD7H/GRC8/x4Q8P8fDPz/Ixv6/yoo/v8lJ/7/JCb+/yMk/v8iI/7/ISH9/yEg/v8gH/7/Hx7//x4e//8dHf7/HR3+/x0c/v8dHP7/HBz9/x0c/f8dHP3/HR3+/x0d/v8eHv7/Hh7+/x8f//8gIP//ISD+/yIi//8iI/7/JST9/ycm/f8nJ/7/KSn//yos//8tMf3/MDf+/zBA/f8vUfz/L2j6/x+Z9f8K+Pz/A/3+/wL//f8A////AP///wD///8A////AP///wD///8A////FOr8/0SG+P9acP7/XWb9/2Jk/v9mZv7/aWn+/21t/f9ub/7/cHH//29x/v9vbv7/YVv4/0cx+f+WjO//+f39///////////////////////////////////////////////////////////////////////+/f3/vLfv/1dB+v9rYff/yMb2//z+/v/r//7/Qvz9/wj9/v8B/v3/Af78/wP+/P8qyPf/UH/7/1Zr/f9VXf7/VVj9/1RU/v9RUf//Tk/+/0tM/v9JSv7/Rkf+/0VE/v9BQf7/PTv+/zk2/f8pIPn/HQz7/x0O+/8dDvz/HQ78/yMc/f8rJ/7/Jyb9/yUl/f8jJP3/IiH+/yEg/v8fIP7/Hx/+/x4e/f8dHf3/HRz+/xsa/v8aG/7/Gxv9/xsb/f8aGv3/Ghr9/xoa/f8bG/7/Gxv+/x0c/v8dHP7/Hh3+/x8f//8gIP//ISH//yIi/v8jI/3/JiT+/yYn/f8nK/7/KDD+/yo6/f8rRP3/K1X7/x518/8XvPf/DfP9/wP+/v8B//7/Af///wD///8A////AP///wD///8A////AP///wH///8ez/f/SIT7/1Ny/f9eZ/3/Y2T+/2Zm/f9oaf7/bGz+/25u/v9vcP//cHH//29u/v9pZvz/Qy72/3pt7f/6+////f///////v////////////////////////////////////////////////////////////39/v+povH/VUH5/3ds9v/a2Pf/+/7+/9n+/f81/P3/BP7//wH//v8B/v7/Bv7+/yHO+f9Ei/j/UXT8/1Vl/f9UXf7/U1b+/1BT/f9OUP7/TE3+/0pL/v9ISf7/Rkb8/0ND+/9AQP3/PDv8/zk2/f8xLfz/KCL7/yci+/8qKfz/Kyv9/ygp/P8lJ/3/JSX+/yQh/v8hIP7/ICD+/x4f/f8eHf7/HBz+/xob/v8bGv7/Ghn+/xgY/v8YGP7/GBj+/xgY/v8YGP3/GBj9/xgY/f8ZGf7/Gxr+/xsa/f8cHP3/HRz9/x4e/v8fH///ICH+/yAi/P8iJP7/Iyr9/ycz/f8mQf3/KE/8/x9w8/8YtfX/D/H9/wb8/v8C/v3/AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///xDz/P8vrfX/THv7/1lu/f9daP//Y2j8/2ln/v9pav//bW3//25v/v9vcP7/bm/9/21q//9DMfT/ZFbv//n4///9//7////+////////////////////////////////////////////////////////////+/39/5WN8/9SQ/j/e3jy/+bp+v/8/v//y/7+/yz9/f8C/v//Av/+/wP+/f8C/v7/Cfv9/x/b+v86k/f/TnT9/1Rn/P9TXP3/VFf7/1NW+/9VV/z/V1b7/1dW+/9YVvz/Vlb8/1VW/P9TU/z/UE/8/0xM/P9JSvz/RkX8/0JD+/8+P/v/Ozv6/zc3+v8wMfv/Kin6/yQj+v8hIPz/Hh79/xwc/f8aGv3/GBn9/xgZ/P8YGP3/GRb//xcX/v8XF/7/Fxf+/xcX/v8XF/7/Fxf+/xcX/v8YF/7/GRn+/xoa/v8bG/3/HRz+/x4d/v8fH/7/HyH+/yEr+v8iN/3/IEf8/xxm8/8XsPT/D+/8/wb9//8C/v7/Av7+/wH//v8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////Av3+/wz4/f8uuPX/SoD5/1py+v9fbP3/ZWn+/2hq/v9sbP7/bW7+/29w/v9ub/3/bmz//0Y19/9ZR/L/8O/+/////v/////////////////////////////////////////////////////////////////4/P7/iIPy/09I+f+AhvT/8fb+//z9/v+9/v7/Jv79/wL+//8B//7/Af/9/wP9/f8G/f3/Cf38/yHz/f87t/X/XYX5/2l6/f9rdf7/a3H9/2tu/f9qa/3/amr9/2hn/P9mZv7/YWP+/19g/v9dXf7/W1v9/1lZ/v9WV/7/VVT+/1NS/v9RUP3/TU39/0lK/P9HSP7/REX+/z4/+/83N/z/Li76/yYl+/8dHfn/Fxn6/xUW/f8XFf7/FRT+/xUU/v8VFP7/FRT+/xUU/v8WFf7/FhX+/xcX//8XF///GBj+/xoZ/v8cG/3/HRz+/x0f/v8dJv3/Hzf5/xtV9v8Vp/T/D+38/wX9/f8E/f3/A//+/wP+//8B//3/AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8C/v7/Av3+/wr6/f8nyvf/S4P5/1p1+/9gb/3/aGv+/2xs/v9tbv7/b3D+/25v/f9tbP3/Szv4/1NB8v/i4Pj///7//////v////////////////////////////////////////////////////////////j7/v94d+z/S1Pz/3bC9v/x/f3//f3+/7b9/f8k/f3/Bv/+/wn9/f8Q/f3/GPz+/xz9/v8j/f7/J/7//zH8/v9G3vn/XZj1/2x9+v9uc/3/bG/8/2xs/v9ra/7/aWj+/2dm//9kZP7/YWH//19g/v9cXv//Wlv+/1hZ//9WWP7/VFT+/1FS//9PT///TU3//0tK/v9HR/7/RkX+/0NC//8/QP7/PT39/zs6/v81Nvz/Kyz6/yEi+v8XGPr/ExP7/xQT/f8UE/3/ExL9/xIT/v8RE/3/FBT+/xcV//8XF/7/Fxj+/xgY/v8ZGv3/Gx/7/xU87/8ZlfP/Eeb8/wf6/v8C/v7/Av7//wP9/v8C/f7/BP7+/wT+/v8C/f3/Av79/wL+/v8C/v7/AP///wD///8A////Av7//wH///8C//7/AP/+/wD///8B////Av///wX8/v8i2Pr/SYn2/110+/9kbv7/aWz9/2tu/v9vcP7/bW7+/29s/f9PQPX/Uj/z/9XT9f//////////////////////////////////////////////////////////////////////9/n//2946P9MsPb/dfT9/+/+/f/9/f//tPr9/zX7/v8h/P7/If3+/yL9/f808v3/N/D+/zvw/P887vz/QOz8/0jl+/9T2vr/Y5r1/212+/9tcP3/bGz+/2tr/v9paP7/Z2b//2Rk/v9hYf//X2D+/1xe//9aW/7/WFn//1ZY/v9UVP7/UVL//09P//9NTf//S0r+/0hI//9HRv//REP+/0FC/v9AP/7/PT39/zs5/v84N/3/Njf9/zM2/f8rL/v/ICL7/xcX/P8SEPz/ExD+/xIR/f8SE/3/FRX9/xYV/v8XFv7/Fxf9/xgZ/P8aIvr/IGnz/xWP9P8RnPT/Fqn1/xa09P8VvfP/E8X0/xHK9/8Rz/j/ENb6/xHe+v8R5Pv/Een7/wf5/f8A////AP///wD///8B//7/Av7//wf7/v8L+v7/Bvz+/wX9/v8F/f//B/z+/wr7/P8i5fv/SY70/2Nw/P9pbf3/a23//29v//9tbv7/bmv+/1FE9P9QPPX/zcn2//3////////////////////////////////////////////////////////////////////y9f7/b3Xq/0t67v+OsfL/9v38//z+///B4ff/Vuz7/zH9/f8o/v7/NfL9/2Kt9/9pofr/a5n7/2yV/P9skvr/bYv6/22D+v9tevv/bnP9/2xw/f9tbf//a2v+/2lo/v9nZv7/Y2P9/2Bg/v9fX/7/W13//1la/f9YWf7/VVb9/1NT/f9RUf7/Tk7//0tL/v9KSf3/R0f//0ZF/v9EQ/7/QUH+/z8//v89PP7/Ozv+/zo5/f84OPz/NDX+/zMz/f8zMv7/MjH9/yss/P8gIPr/FBP4/xMR/f8SEv3/ExT8/xYW/f8XF/3/GBn9/xoa/f8eIP3/Hir+/x02+/8cP/v/H0T6/yJJ+/8kTvr/I1D6/yVU+/8pV/r/K1r6/y1j+P8ndvf/F8n4/wH///8A////AP///wH//v8E/P7/GtD2/zCd+P8xnPj/MZ/4/zGk+P8zqPj/Nar4/zqs9/9NpPL/YHH5/2ls/f9rbf7/bm3//21u/f9taf7/U0b0/045+P/EvvX//f////////////////////////////////////////////////////////////////////H0/v9sZe3/Y132/6mt9v/7/P7//P38/83d+P9r1/v/N/79/y7+/P9J2/v/cJz9/3mR/P95iP7/doX9/3eB//90gP3/c3r+/3F2/f9vc/3/bW7+/2xt//9ra/7/aWj+/2dl/v9jYv3/YGD+/19e/v9bXP//WVr+/1dY/v9TVf3/UlL+/1BQ/v9NTf7/Skv+/0lJ/f9GRv3/RET+/0NC//9AQP//Pj3//zw7//86Ov7/Nzj+/zY2/v81Nf3/MzP+/zEy/f8xMf3/MDH9/zEw/f8wMP7/JCX7/xcX+f8TE/3/FRX9/xYW/f8XGPz/GBj+/xkb/v8fHvz/ICL9/yAn/f8iKf3/Iy3+/yQx/v8oNf3/Kjj9/yo8/f8rQP3/MEj+/zBa/P8imPX/Bvz9/wD///8B//7/Av/+/wr6/v8snfj/QnL8/0lq/v9Mafz/UGz9/1Ju/v9Xb/7/WW/8/1xs/P9kbP3/aGr9/2xt/v9ubv7/bW79/2xq/v9USfX/Tjj6/8C69v/9////////////////////////////////////////////////////////////////////8/T//25i7f92aPf/sK71//z8///9/v3/0tz5/3rE+f9B+/3/Nvz//1rC+f94k/3/fYj9/3yB/f96fv7/eXz//3d6/v9zdf7/cnP//29w//9ubv7/bGz//2pq//9oZ/7/ZmT+/2Jh/f9gX///Xl3+/1pb//9YWf7/Vlf//1JT/v9QUf7/Tk/+/01N/v9JSv7/R0j9/0VF/f9DQv3/QUD//z4+/v88PP7/Ozr//zc3/v81Nf//MjT//zEz/v8wMf3/MDH+/zAw/v8wMP7/MDD+/zAw/v8yMP3/MzL+/ykp+v8cGvn/Fxb6/xcW/v8YGP7/GRn+/x0b/f8dHv3/HyD+/yEh/f8iJP3/JSf9/ycp/v8pLP7/Ky7+/y0y/v8tO/z/M0j+/yhs9f8S7Pz/Av3+/wL+/v8C/f7/F+n8/zZ49v9IY/7/Tlv//1Ja/v9TXf7/WGD+/1xk//9fZf7/YWb+/2do/v9oaP7/bGz//21t/f9tbf7/a2v+/1NJ9f9ON/n/vrr2//3+/v/+///////////////////////////////////////////////////////////////09P7/cGLt/3hn+P+xq/b//P3///3+/f/X3/n/iLP3/0/z/f8/+f7/a6j5/3yO//9+hP7/fX39/3p8/f95ef//d3j9/3N0/f9wc/7/bnD+/21u/v9sbP//amn+/2hn/v9lY/3/YmH9/2Bf/v9dXf7/Wlr+/1hZ/v9VVv7/UlL+/09Q//9NTf7/S0v+/0lJ/v9GRv7/RET9/0JC/v8/P///PT3+/zs6/v85OP7/NTX+/zMz/v8wMf7/LzD9/y4u/v8uL///Ly///y8v/v8vL/3/MDD+/zIy/v80Nf3/NjX9/zM0/P8pKvz/Gxr6/xkY+/8aGf3/Gxr+/x0d/v8fH/7/ISD+/yEi/f8kJf7/Jyf9/ykp/v8rK/7/Ly7+/y81/v8yQf7/MVv7/xnC9v8C/f7/Af7+/wX9/f8fwff/QGn9/0xa/f9OU/7/U1T9/1ZY//9ZW/7/XV79/2Bh/f9iY/7/Zmf+/2hp/f9ra/7/bW3+/2xs/f9qav7/U0n1/043+f++uvb//f7+//7///////////////////////////////////////////////////////////////b1/v9xY+3/dmf4/6+p+P/8/P///v79/9zi+v+UrPv/XNz6/1Dq/P9zmPr/fov+/36D/v99ff3/env+/3l5//93d/3/c3T+/3Fy/v9vcP7/bm7+/2xs//9qaf7/aGf+/2Vj/f9iYf3/YF/+/11d/v9aWv7/WFn+/1VW/v9SUv7/T0///01N//9LSv7/SEj+/0VF/v9EQ/7/QkH+/z49/v88PP7/Ozr+/zg3/v80NP3/MjH9/y8v/v8sLf//Kyz+/yss//8sLP//LS3+/y8v/v8wMf7/MjL+/zM0/v83Nv7/OTj+/zg5/f82N/z/KSf4/xsb+f8aG/3/HBz//yAf//8hIP//ISH+/yQl/v8mJv7/Jyj+/ykr/v8tLf7/MTL//zI9/f80Uv7/IpH1/wf7/v8B/f7/Cvn+/yqV9P9DYf7/Slb+/05T/f9TVP3/Vlj+/1pa/v9dXv3/X2D9/2Fj/v9lZv7/aGn9/2tr/f9tbf7/bGz9/2pq/v9TSfX/Tzj6/7+79//9/v7//v//////////////////////////////////////////////////////////////9/b+/3Vn6f91Zfj/p6T4//37/f/8/v7/5ef5/5in+v9wwPf/XM75/3+P/v+Ah///f4H9/319/f97e/3/enr//3Z2/v9zc/7/cHH+/29w/v9ubv7/a2v//2lp/v9nZf7/ZGP9/2Jh/P9eX/7/XVz//1la//9WWP7/VVT+/1JS/v9PT/7/TEz+/0tJ//9ISP7/RUX+/0FC/f9AQP//PTz//zw7//85OP7/NTT+/zIy/v8wMP7/LS3+/yor//8qKv//Kir//yoq//8rLP//LC3+/y4u/v8yMf3/NDT+/zc2//86Of3/Ozr+/z08/f89PP3/Njb8/yMj+P8eHfz/HR78/yEg/v8hIP//IyT+/ycm/v8oKP7/Kiv//ywt/v8xMP7/Mjf//zNJ//8obPT/Eun9/wP+//8V6Pz/NHL4/0Vb+/9MUv7/UFH//1NT/v9WV///Wlr+/11d//9gYP7/Y2L+/2Vm/v9naP7/a2v+/2xt/v9sbP3/a2r//1FG9P9OOPj/xMD2//7+/v/+/v7////////////////////////////////////////////////////////////5+f//e27o/3Ri+P+hnff/+/r///3+/v/t7vv/nab5/4Kl9/93q/n/gIr9/4CF/v9/gf7/fX3+/3t7/v96ev//dnb+/3Nz/v9wcf7/b3D+/25u/v9ra///aWn+/2dl/v9kY/3/YmH8/15f/v9dXP//WVr//1ZY/v9VVP7/UVL+/09P/v9MTP7/S0n//0hI/v9FRf7/QUL9/0BA//89PP//PDv//zk4/v81NP7/MjL+/zAw/v8tLf7/Kiv//ykp/v8oKP7/KCj+/yor//8sLP7/Li7+/zEx/f80NP7/Nzb//zs6//88O///Pj3+/0A//v9AQfz/QEH8/zAu+P8gIPz/ICH9/yEi/P8jJP3/Jyb+/ygo/v8qK///LC7+/y8x/v8wNf3/MkT+/zJZ/f8Zv/b/Bf3+/xy+9/8+Y/3/RlX9/0tP/v9QUf//U1P+/1ZX//9ZWv7/XV3//2Bg/v9jYv7/ZWb+/2do/v9ra/7/bG3+/2xs/v9qaf7/TkH1/0879v/QzPb//f7+//7+/v////////////////////////////////////////////////////////////r7//+He+//cl/4/5uU9//19P7//P7+//X4//+iqPf/jZf7/4KP+/+Chv3/gYP+/3+A//99fP7/e3v+/3l5//92dv7/c3P+/3Bx/v9vcP7/bm7+/2tr/v9paf7/Z2X+/2Rj/f9iYf3/Xl/+/11c//9ZWv//Vlj+/1VU/v9SUv7/T0/+/0xM/v9LSf//SEj+/0VF/v9BQ/7/QED+/zw8//87Ov7/OTj9/zUz/v8xMP7/Li7+/ywr/v8pKv7/KCj+/ycn/f8nJ/3/KSr+/yws/v8uLv7/MTH9/zMz/f83Nv7/Ojn+/zw7//8/Pv//QUD//0JC/v9EQ/3/Q0L9/zo9+v8mJfv/IiL9/yMk/f8nJv7/KCj+/yor/v8rLf7/LjH9/zE1/v80Pv7/NFH8/yOI9P8R9/3/KIr0/0Fb/P9FUv3/S07//1BR//9TU/7/Vlf+/1la/v9dXf//YGD+/2Ni/v9lZv7/Z2j+/2tr/v9sbf7/a2v+/2pp/f9MO/j/Uj/z/93Z9v/9////////////////////////////////////////////////////////////////////+/z+/5SK8/9wW/r/mJD4/+jp+P/7/f7/+vz9/6+x9/+TlP7/iIz8/4SE/f+Cgv//f4D+/358/v97e/7/eXn//3Z2/v9zc/7/cHH+/29w/v9ubv7/a2v+/2lp/v9nZv7/ZGP9/2Fh/f9eX/7/XFz//1la/v9VWP3/VFT+/1JS//9PT/7/TEz+/0tJ//9ISP7/RUX+/0JD/v9AQf7/PD3+/zs7/v85OP3/NDP+/zAw/v8vLv3/LCv9/ykr/f8oKP7/Jyf9/yco/f8pKv7/LCz+/y4u/v8xMf3/MzP9/zc2/v86Of7/PDz+/z8+//9BQf//Q0T9/0RG/v9HR/3/R0b9/0JE+/8sLPn/JCT9/yYm/f8pKP7/Kiv//yst/v8tMP//MjT+/zY8/v80SP3/K1v0/yfM+f8yXvb/RVL+/0dP/v9LTv7/UFH//1NT/v9WV/7/WVr+/11d//9gYP7/Y2L+/2Vm/v9naP7/a2v+/2xt/v9ra///a2r9/0c1+P9XRfL/6uj7//3////////////////////////////////////////////////////////////////////8/f3/p57z/25Y+f+RiPj/3N35//z+///9/v7/wcH1/5WV/f+Liv3/hIT+/4KB/v+Af/3/fn39/3p7/v95ev//dnf9/3N0/v9xcv//b2///25t//9sbP//aWn+/2Vm/v9iZP3/YGH+/15e//9aW///V1f//1VU/v9UUv3/UVD+/05O/v9NTf7/S0r+/0hI/v9FRf3/Q0L9/0JB/v89P/3/PDz+/zk4/v82NPv/MTD5/zEx8v8uMfT/LSz6/ykr+/8pKf//KSr//yor/v8tLf7/Ly/+/zIy/f80NP3/ODf+/zs7/v89Pf7/QD/+/0JC//9EQ/7/R0f//0hJ//9KSf//S0n//0ZI/P8yM/j/KCv7/ykq/f8rLP//LC3+/y8v/f80Mv3/Njn9/zhC/v83Svz/Nmvx/0BP/f9FTf7/SE3+/0tO//9QUf//U1T+/1ZY/v9ZWv7/Xl3//2Bg/v9jYv3/ZWb+/2do/v9ra/7/bG3+/2tq/v9qZ/3/QzH2/2BQ8P/29/3//v/9//7//v////////////////////////////////////////////////////////////z+/f+9tvD/alb4/4p++P/P0Pj//P7///7//v/S1Pf/lpn8/4qM+/+EhP3/gIL+/3+A/v99fv7/eXv+/3h5//92d/3/c3T+/3Fy//9vb/7/bm3+/2xs//9paf7/Zmf+/2Nk/f9gYv3/Xl7+/1hZ/v9VVvn/TVDu/0pO8P9PT/z/Tk7+/01N//9LSv7/SEn//0ZG/v9EQ/7/QkL+/z4//f88PP7/Ojn+/zY0/v8rLNv/BARs/wQFZ/8iILv/LSv7/ysr/v8rLP7/LC39/y8v/f8xMf3/MzP+/zY2/f86Of7/PDv+/z09/v9BQP7/QUL+/0VE/f9HR/7/SUr+/0tL/v9NTf7/Tk7+/01O/f82OPn/LS39/yst/v8tLf3/Li/8/zIx/P82Nvz/ODz9/z9B/f8+Rvz/QUj8/0ZK/f9JTP7/Tk7//1BR//9UVP7/Vlj//1la//9eXf//YGD+/2Ni/f9lZv7/aGn+/2tr/v9sbP7/amr9/2di/f9BLvX/dWfu//n7/f/+/////////////////////////////////////////////////////////////////////f3+/9bS9v9nVvT/gnP4/7+/8//8/v7//v7+/+bo+v+amPL/ioj3/4OC/f+Cgv7/gYD+/39+/v96e/7/eHn//3Z3/f9zdP7/cXL//29v/v9ubf7/bGz//2lp/v9mZ/7/Y2X9/2Bi/P9eXv7/WFj+/0JD0f8KC2z/IiKf/09O+/9OTv7/TU3//0tK/v9ISf//Rkb+/0RD//9CQv7/PkD+/z08//87Ov//NzX9/zM08f8GBl3/AQI9/xQShP8wL/f/LS39/y0u/v8vL/7/MTD9/zMz/v80NP3/Njf+/zo6//88Pf7/Pj/+/0FB/v9BQv3/RUX+/0dI//9JSv7/TE39/05O//9QUv3/UlH+/05Q/f85Ovr/LzD8/y4t/P8lJs7/Fxij/ygr0v86O/3/Pj/+/0RC/f9ERf7/SEn+/0tL/v9OTv//UFH//1RU/v9WWP//WVr//15d//9gYP7/Y2L9/2Vm/v9oaf7/a2v+/2xr//9qav7/Xlj5/0Qx+f+Rh+///Pz///3+//////7////////////////////////////////////////////////////////////9/v7/7+z//2lZ6/97aPn/r633//v8/v/+//z/+Pj8/15fhv9eX7H/goD9/4CA/v9/gP7/fX79/3t7/v96ef7/dnf+/3N1/f9xc/7/cXD+/21u/v9sbP7/amr+/2hn/v9mZP7/YGP7/15d/v9UVvr/MzKs/wIDUf8pKqj/Tk78/09Q/v9OTv//TEz+/0lJ//9HSP//RUT+/0NC/f9AQP7/Pj7//zw7/v84OP7/NTT5/xgWgv8CAjX/BgVN/zEx5/8tMPz/LzD9/zEy/v8zM/7/NTT+/zg2/v86Of7/PDv//z49/v9BQP3/Q0L9/0RD/f9IRv7/SUj+/0tK/v9NTf7/UFD+/1NT/v9TU/7/VFX9/09R/f87OPj/MDD3/xgWlP8BAVz/KCnE/zo5/f8+P/7/Q0L9/0RE/f9ISf7/S0z9/09P/v9SUv3/VVX+/1hY/v9bWv//Xl3//2Bg/v9jY/3/Zmf9/2pp//9ra///bGr+/2po/v9VS/X/SzX6/7Cn8v/9/f7//v///////v////////////////////////////////////////////////////////////3//v/6+///fG/r/3Je+f+gnPf/8vT9//79/v/8/f3/jo2h/0JDff+CgPn/fX79/35//v9+fP//fHv//3p5/v92d/7/dHX9/3Fy/v9vcP7/bm7+/2xs/v9qav7/aGf+/2Vl/f9eYv3/XFv+/1VV9/8aGnn/AQFM/zw+y/9PTv3/T1D+/09P//9NTf7/SUr9/0dI/v9GRv7/REP+/0FB/v8/P/7/PT3+/zo7/f82Nf3/KCu//wIBOP8CATL/JCOs/zAx+v8xMf7/MzP+/zY1/v84N/7/Ojn+/zs7/v88PP7/QD79/0NB/v9EQ/3/RUT9/0lH//9KSf7/TEz+/05P/v9RUf//VFT//1RV/v9WV///VFX+/09Q+/82NOv/CAdk/wUDV/8zM+T/Ojn9/z8+//9DQv7/RUT9/0hJ/v9LTP3/T0/+/1JS/f9VVf7/WFj+/1ta//9eXf//YGD+/2Nj/f9mZ/3/amn//2tr//9raf7/a2n7/0w99v9NPfX/0M30//v9/f/+//7//////////////////////////////////////////////////////////////////v////z+/v+cku7/blz4/5OJ9//f4fr//v79//39/v/Ix87/ODde/2xr0P96ev3/e33+/39+/f99fP7/e3r//3h4//91dv7/cnP//29x//9vb///bW3//2tr//9paP7/ZmX+/19g/v9aWfz/SknY/wQETP8LDGL/Tk31/09S/P9QUv7/T1D//05O/v9KS/7/SEn+/0dI//9FRf3/REP9/0JC/v8/P/7/PTz9/zg4/f81N/H/Dw1j/wEBLf8KCVn/NTXu/zMy/f82Nv//OTj+/zs6/v88O///PDz+/z4//v9CQf//Q0L+/0VE/v9GRv7/S0n//0tK/v9NTf7/T1D+/1FS/v9UVf7/Vlj//1ZY/v9WVv7/VFT7/zk4wf8CAkj/ExF7/zc39/87O/3/QED//0RD/v9GR/7/SEn//0xN/v9PUP7/U1P9/1VW/v9ZWf//W1v//19f/v9gYf3/ZGT+/2Zn/f9qaf//a2v//2lp/f9qZv3/QzL1/1xK8f/u7v3//P79//3//v/+//////////////////////////////////////////////////////////////////7//f/+/8O/9P9pVvf/iHf4/8nJ9v/8/v7//v39//X29/9RT2r/PDx//3t69f97e/7/fH3+/3t7//97ev//eHj//3Z2/v9zdP//cHH//29v//9tbf//a2z+/2ho/v9mZP7/YV7+/1dY9/8gIYb/AgJI/zAwqf9QUvv/UlT9/1JT//9RUf7/T0///0xN/v9KSv7/SUn//0dG/v9FRP3/REP+/0FC/v8+QP3/Ozv+/zg3/P8pKbr/AwA5/wEBM/8hIJ3/NjX6/zg3/f86Ov7/PTz//z09//8+P/7/QEH+/0ND/v9FRP7/R0b+/0hH//9LSf7/TEv+/05O//9QUf//UlP+/1VW//9XWP//V1j+/1ZW/f9VVfX/FBRv/wMCS/8oJ77/ODf7/z09/v9BQf//RET9/0dH/v9JSf//TU3+/09Q/v9UVP7/Vlf//1lZ//9bXP//X1/+/2Fh/f9kZf3/Z2j+/2tq//9rav//aWj+/2Jb+v9BLff/fnHv//r7/v///v7//v/+//7///////////////////////////////////////////////////////////////7+///+//3/5+b7/2pZ8P97afn/s6/3//v8/P/8/v7//v39/6CguP8vLVj/T0+t/3l5+f96ef3/eXr+/3p6//94eP7/dXj8/3R0//9xcv7/b3D+/21u/f9ra/7/aGb//2Ri/f9aXPn/Pzy3/wQDSv8QEGj/UFDx/1RU/f9VV/7/VVX+/1NT/v9SUf7/T07//0xM/v9LSf7/SUj//0ZG/v9FRf3/REP9/0FB/v8/Pv//Ozv9/zk79v8VFXv/AQMz/wUEQf8vL8v/ODf7/zo6/f88Pv3/Pz/+/0JC/v9EQ/3/RUT8/0hG/v9JR/7/Skn//0tL/v9NTf7/T1D+/1JS/v9UVP7/Vlf//1ZX//9VV/z/U1T8/zY1sP8CAkj/FBNw/z8+8P87PP3/QT///0NC/v9FRf7/SUj+/0xL//9OTv7/UFH+/1RU/v9XV///WVr+/1xe/v9fYP7/YmP9/2Vl/v9paf3/a2v//2pp//9oaP7/VEj3/0w0+v+po/D//////////////////////////////////////////////////////////////////////////////////v7///7//v/5+f7/hHju/3Be+f+ck/X/8PD8//z//f/+/v3/5eX2/1dXjf8iIlf/U1K3/3V1+v93d/z/d3n9/3h3/v92dv//cnT//3By/v9ucP7/bG39/2pp/v9kZPz/XV/7/0ZFx/8HBlP/BgVV/0VFz/9WV/v/V1j+/1VZ//9WV///VFT+/1NT//9QUP//Tk7+/0xM/v9KSf7/SEj+/0dG/v9FRf3/RET9/0FC/f8/P///PTz9/zk34f8LCFr/AgI0/wgJUv81Ndj/PDr8/z0+/P9AQP7/QkP+/0VE/f9GRv3/SEj+/0hJ/v9KS///TU3+/09P/v9QUv//U1T+/1RV/v9VVv//VVb+/1VT/P9HRtP/BgZS/wMETf9FRsv/U1H7/0JA/P9DQv7/RET9/0ZH/v9KSf7/TEz+/05P/v9RUv7/VVX+/1dY/v9ZW/7/XV/+/2Bh/v9jY/3/Zmb+/2pq/f9qav7/aWn+/2ln/f9HOPX/UT70/9rX+P/////////////////////////////////////////////////////////////////////////////////+/v7//f7+//38/f+0rfH/a1f4/4h9+P/V1fb//v7///v+/v/6+v3/qann/0RBhf8ZGVb/QUGf/3Nw8f90c/z/cnT8/3Fy/v9vcP7/bW7//2tr/v9paP3/ZGT8/2Bf9P84OK3/BwhR/wUFUv89Prr/V1n6/1tZ/v9aXPz/WVr+/1dY/v9VVf7/U1P//1FS//9PUP7/Tk7+/0tM/v9ISf//SEj//0dH//9FRf7/RET9/0JD/f8/QP3/PTz8/zQ00P8IBUz/AwI1/wwKV/8zNND/Pj36/z8//f9CQv7/RUT+/0hH/v9KSP//S0r+/01M//9OTv7/T1D//1BS//9TVP7/VFT+/1RU//9SUf3/RkbW/wsKXP8EAkf/MTCh/1tc+f9fX/z/TU36/0VF/v9FRv3/R0j+/0pK//9NTf//T1D+/1FU//9WV/7/WFn+/1pc/v9eYP7/YGH+/2Nj/v9mZv//amr+/2pq/v9paP7/Y1/7/0Ms9/9tX+3/9/f+/////////////////////////////////////////////////////////////////////////////////////////////v7+/+jm+v9nV/D/e2n5/7e19//7/P7//f39//v9/f/a3Pn/j43u/0ZEk/8VFFb/Hh1s/0xKtP9paOj/b2/4/21t+v9qavr/aGj5/2Bg6/9FRbv/GRhy/wYFS/8NDFz/RkXF/1pa/P9cXP3/Xl3+/11d/v9cW///WFn+/1dY/v9VVv7/U1P+/1FS/v9RUP7/T07+/0tL/v9LSv7/Skn+/0hI/v9HR/7/RUX9/0RF/f9BQf3/Pj/6/zUwy/8HBlP/AgI2/wYFSv8oKaz/QD/y/0BB/P9FQ/3/RUf9/0hJ/v9LS/7/TU3//09O//9QUP7/UFH+/1JS/v9QUf3/UVH3/zs8vf8JCVf/BANG/yQli/9cXfj/YWH8/2Nj/v9fX/z/Skr7/0dI/f9KSvz/S0r//05O/v9RUv7/U1T+/1dX//9ZWf7/XF3//19g/v9iYf3/ZGT+/2hm//9qaf7/amn+/2ln/f9TR/f/SzP4/6Sf8P/7/P3/////////////////////////////////////////////////////////////////////////////////////////////////+/v+/4+B7v9xXvn/lo72/+7w/f/+/f3//v/9//n6/v+nqvT/ior2/15ew/8kIHH/Dw1W/xERWv8eH2//KSmC/ysnhf8eHXH/DQ5a/wgHTv8ICFP/KCiO/1VW4/9eYPv/YWH+/2Bg/v9fYP7/X17+/11d/v9aW///WFr//1dZ/v9UVf7/U1P+/1JR//9QUP7/Tk7+/01N/v9LS/7/SUr+/0hJ/v9HSP7/R0j//0dG/f9CQ/z/P0H6/zg50/8ODWX/AwI7/wICPv8REW3/MTG//0ND8v9CRPv/Rkf9/0lI/P9KSf7/S0z9/01M/f9OTP3/T074/0NE1f8dHYP/AwJI/wMDR/8qK5X/WFnz/2Fg/v9kZf7/Z2j+/2Vn/v9RUvr/SUr9/0tK/v9NTP3/T0///1JT/v9VVf7/WFj//1pa/v9dXf7/YGD+/2Nj/v9mZf7/aWj+/2pp//9qaP7/aGT9/0Qz9f9XRPH/3tz5//z8/f/////////////////////////////////////////////////////////////////////////////////////////////////7/v7/yMT0/2hX9v+EdPb/zcz3//38/v/+/////v7+/9/f+v+Ulvr/hYX5/3Z69f9YWcf/OTmW/yAhc/8UFWP/ExRi/xcUaP8kJID/PTys/1pa4f9iZvn/Y2b7/2Rl/v9kZf3/YmT//2Bi/v9fYP3/X1/+/11c//9bW///WVr+/1ZY/v9VVv7/U1P+/1JS/v9PUP7/T0/+/05O/v9NTf7/TEv+/0tK/v9KSf7/SUn9/0pJ+/9HRf7/REP+/z9B6f8iI5f/BAVK/wICO/8CAkH/CgtZ/x8gj/8vMLX/OTrP/z4/1v8+P9X/Nzi+/ykrnf8TFW//AgJI/wICQv8LClv/Pj25/1tb+P9iYP3/ZmT+/2lo/v9ra///a2r//15g/P9LTfv/TU3+/09O/v9QUf//U1T+/1ZX/v9ZWf//W1z+/19f/v9hYf3/ZGT+/2dn/v9qaf7/amr+/2hm/v9aUvj/Qy/4/4R27v/6+v///f7+//////////////////////////////////////////////////////////////////////////////////////////////////3+///08/3/dWvt/3Rh+f+jnPT/9vb9//z//v/+//7/+/v+/7689f+Rkfr/g4T7/3h8/P90dfv/dnL7/3Bw9v9tbvX/bGz4/21r+/9pZ/z/aWr8/2lq/f9paf7/amn+/2ho/v9lZv7/YmP+/2Bh/P9gYP7/Xl3//1xc//9aWv7/WFr+/1dY/v9VVv7/VFX+/1JT//9RUv//T1D+/05P/v9OTv7/TU3+/01M/v9MTP7/TEz9/0tL/v9ISf3/SUf8/0ZF+v8+Pdr/ICGR/wUFU/8CAkH/AwE+/wIBQf8BAUP/AQFF/wICRf8BAUL/AgFE/wICRP8JCVj/LSyf/1JT5/9bXPr/YmD9/2Rl/f9oaf7/a2v+/2xs/v9sbP7/Z2n9/09R+/9OUPz/UE///1FS//9VVf7/V1j+/1pa//9cXf7/X2D+/2Ji/v9lZf7/Z2j+/2pp/v9pZ///aWb+/0g39/9NO/X/x8Tz//v9/v/9/v7//v////////////////////////////////////////////////////////////////////////////////////////////////7///v9/v+1sPL/alf2/4V4+P/Rz/f//P3+//3++//+/v7/8PL8/6Sh9/+Qjv3/goP+/3t8/v93eP3/dXX+/3Nz/v9wcv//bm/+/25w/v9tb/3/bG79/2xt/f9ra/7/amn+/2hn/f9nZf7/ZmP+/2Jh/f9fX///Xl7//11c/v9bW/7/WVn+/1dY/v9WV/7/VVX+/1RU/v9TU/7/UFH+/1BR//9PT///Tk7+/05O//9OTv//Tk7+/01N/v9NTf//S0v+/0lK/v9HSvv/SUnu/zg2wv8mJZb/Ghh7/w8OZ/8MDGP/EA9p/xsae/8oKZv/PD3F/1RW8P9XWP3/XFv+/2Bh/v9lZf//Z2j+/2tq/f9tbP7/bm3+/25u/v9sbf3/W1n8/1FS/v9RU/7/U1T9/1ZW/v9YWf7/XFv+/15e/v9hYf7/ZGP+/2hm/v9paP7/aWj+/2hn/f9cV/n/Qiz4/3Bj7P/39v3/+/7+//7//v/////////////////////////////////////////////////////////////////////////////////////////////////+/////f79//Px/f9xZOr/dWL5/6Gc9P/x8/3//f79//7//v/9/f//1db2/5iY+/+Ki/z/goL//3x9/v97e/7/eHn//3Z3//9zdP//cnP//3Bx/v9ucP7/bW7+/2xs//9ra/7/aGn+/2dn/v9lZf7/YmL+/2Bh/v9fYP7/Xl/+/11c/v9bW/7/WVr+/1dZ/v9VWP7/VVb+/1VV/v9TVP7/UlP+/1JS//9RUv//UVL//1FS//9RUf7/T1H//1BR//9RUf//UVD+/1BQ/f9OT/3/TU79/01O/P9NT/n/T1H3/1BR+P9SVPf/U1T5/1hW/P9ZWP3/XFr+/2Be/v9jY/z/ZWX+/2do//9qav7/bGv+/21t/v9ubv7/bnD+/25w/v9iYvv/VFX+/1NU/v9VVf7/V1j+/1pa//9dXf7/X2D+/2Ji/v9lZP7/aGf+/2lo/v9pZ///Z2X9/0Y69f9QOPj/vrfz//z9/f/8//7//v/+//7///////////////////////////////////////////////////////////////////////////////////////////////7////+//7/+vz9/7iw8f9qVvb/hHT6/8fG9v/8/f3//v////3+/f/4+/3/urv1/5OU/P+Iifz/goH+/319//97ev//eHn//3V2/v90df7/c3P//3Fx//9ucP7/bW7+/2xs//9ra/7/aWj+/2hm//9mZf//YWP+/2Bi/f9fYf3/X1///15d//9cXP//Wlv+/1ha/v9XWf7/V1j//1ZX/v9VVv7/VFX+/1RU/v9UVP3/VFT9/1RU/v9TVP7/U1T//1RU/f9TVf3/U1X8/1RV/f9VVvz/Vlb8/1VV/v9VVv//V1f9/1lZ/f9ZW/7/XF3+/15f/v9eYv3/YWT9/2dl//9naP7/amr+/2xr//9ubf7/bm7+/3Bw//9xcv//cHH+/2hr/P9WVv7/VVb9/1ZX//9YWv//W1v//15e/v9fYP7/Y2P+/2Zl/v9oZ/3/aWf+/2hm//9cU/n/Qy74/3Jm7P/09P7//f7+//3//f/+//7////////////////////////////////////////////////////////////////////////////////////////////////////////////9/v7/9PP9/3ps7f9zYPj/mpH1/+np+//9/vz//f79//z+/f/z8/z/pqf1/4+P/P+Hh/3/goD+/358/v95ev//d3n//3d2/v91df7/cnP+/3Bx//9vcP7/bm7+/2xs/v9rav7/aWn+/2dn/v9kZf7/Y2T+/2Ji/v9gYf7/X2D+/15d/v9dXf7/W1v+/1ta/v9aWv7/WVn+/1dY/v9XV/7/V1f+/1ZY/v9WWP7/Vlj+/1dY/v9WWP7/Vlj+/1ZY/v9YWP7/WFn9/1lZ/v9ZWv7/Wlv+/1tc/f9dXP7/YF7//2Bg/v9hYP3/ZGL9/2Zk/f9mZv7/aWj+/2pq/v9sbP7/bW3//25u/v9vcP3/cXL+/3Jz/v9zc/7/cHH9/1hZ+/9YWP7/WFn+/1tb/v9dXf7/X2D+/2Fh/v9kZP7/Z2b+/2hm/v9pZv//Z2T9/0Y09f9QO/X/wsDz//v9/f////7///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////7+/v/+/v7/x8P0/2dV8/98a/f/s7D3//n6/f///f3//f7+//v9+//m5Pr/nJ73/42M/f+FhP7/gH/9/3x8/f93e/7/d3j+/3Z1/f9zc/7/cXL+/3Bx/v9vb/7/bW3+/2xs/v9ra/7/aWn+/2dn//9lZv7/ZGP+/2Ji/v9gYf3/YGD+/2Bg/v9eXv//Xl3//11c//9bW///WVr+/1la/v9ZWv7/WVn+/1lZ/v9YWf7/WFn+/1hZ/v9ZWf7/WVn+/1la//9ZW/7/W1z//1xd/v9eXv//X1///19g/v9iYf7/YmH9/2Nj/v9mZf7/aGb+/2ln/v9qaf7/bGz+/21t//9tbv7/bnD9/3Bx/f9yc/7/c3X//3V1/f90dP//XF38/1lZ/v9ZWv7/XVz+/19f//9gYf7/Y2P+/2Zm//9oZ/7/aGb+/2hm+/9TR/f/RTH4/4V57P/4+f3//f7+///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////3+f7/jIPu/25b9/+LfPf/0tH3//v8/f/9/v7//f7///z9/v/S1vf/l5f6/4qL/f+DhP3/f37+/3l7//93ev//d3f+/3Z1/v9yc///cXL+/3Bx//9ub///bW3+/2xs/v9rav7/amn//2hn/v9nZf7/ZGT+/2Nj/f9jYv3/YWH9/19g/v9fX///X1///15e//9cXf//W1z+/1tc/v9aXP7/Wlz+/1pc/v9aXP7/Wlz+/1tc/v9bXP7/XV3+/11e/v9eX/7/X1/+/2Bg/v9hYf7/YWL9/2Ni/f9jZP3/ZWX+/2hn/v9paP7/amr//2xs/v9tbf//bW7+/25w//9vcf7/cXP+/3N1/v90dv7/dnf+/3V2/v9fYfz/Wlv+/1tc//9eXv7/X2D+/2Fi/f9lZf7/Z2f+/2hn/v9nZv3/YVr7/0Et9v9ZSPH/3Nr5//39/v/8//3///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////38/v/h4/n/bF/t/3Ri+P+ak/b/5+n7//7+//////7//f7+//z7/v/HyvX/lZf5/4mL/f+Cg/3/fn3+/3l7/v93ef//dXf+/3N1//9yc///cXL//29x//9ub///bW7+/2xs/v9ra///amn+/2lo/v9nZ/7/Zmb+/2Rk/v9jY/3/YGL9/2Bh/v9fYP7/X2D//15f/v9fX/7/X1/+/15e/v9eXv7/Xl7+/15e/v9eXv7/X17//19f//9fYP7/X2D+/2Bh/f9hYf3/YmH9/2Nj/v9jY/3/ZWX+/2Zn/v9naP7/aWr+/2pq/v9sbP7/bW3//21u/v9ub/7/b3H//3Fz/v9zdP7/dXf//3Z5//94ef//dnj9/2Fi/P9cXf//XV7//19g/v9gYv//YmT+/2Vm//9nZ/3/Z2b9/2Vj/P9GNfX/Sjj4/6qj8P/8+/3//f///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////P/9//39/v+7t/T/ZlXy/3tq+P+rqfT/9vT9//7+/v/+/v///v7///r8/v/ExfX/lZb6/4yK/f+Bg/3/fn79/3t7/v92ef7/dXf9/3V1/v9zdP//cXL+/3Bx/v9vcP7/bm7+/25t/v9ta///a2n+/2pp/v9oZ/7/aGb+/2Zl/v9kZP7/Y2P9/2Ni/f9iYv7/YWL9/2Bh/f9gYf3/YWD+/2Fg/v9hYP3/YWD+/2Bg/v9gYf7/YGH+/2Jh/f9iYf3/Y2L+/2Rj/v9kZP3/ZWX+/2Zn/v9pZ///aWj+/2pp/v9sbP7/bW39/25u/v9ub/3/b3D+/3Fy//9xc///c3T9/3Z2/v94eP//eHn//3t6/v95ef7/ZmT8/2Bf/v9fYP7/X2H9/2Fj/v9lZf7/ZWb9/2hm/f9mZf7/UUb1/0Yw+f96buz/9PP8//79/P/+/////v/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+/v3//P79//n4/f+Riu3/a1j3/4Nz+P+6u/T/+vv8//7+/v/9//3//f3+//v7/f/Dx/T/lZb6/4mK/f+Dgv7/f339/3t7/v93ev7/dnf+/3Z1/v9zc///cXL+/3Bx/v9ub/7/bm/+/21t/v9sbP7/a2v+/2pq/v9qaf7/aGf+/2dn/v9mZf7/ZWT+/2Vk/v9kZP7/Y2P9/2Nj/f9jYv3/Y2L9/2Ji/f9iYv3/YmL9/2Nj/v9jY/7/Y2T9/2Rk/v9lZf//Zmb//2dn/v9naP7/aGn+/2pp//9qav7/bGz//21t/v9tbv7/bnD+/29w/v9wc/7/cnP+/3R0//92dv7/eHn//3l6//95e///e3v9/3p6/f9nZv3/YmH+/2Fg/f9iYv3/ZGX//2Vm/f9nZv7/Z2X9/1xS+P9ALvX/Xk7u/97c+v/9/fz//v79///+///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+/v/9/v7/+v39/+3s+/94bun/cFr4/4p/9//Hx/X//Pr9//3//f/+/v7/+/79//v7///Lzvj/mpr3/4yM/f+Fhfz/gH/+/3t8/v94ef7/eHf+/3R1//9ydP//cnP+/3Bx/v9vcf7/bm/+/25u/v9tbf7/bGz+/2xs//9rav//amn+/2lo/v9pZ///aGf//2dm//9mZv7/Zmb+/2Vl/v9lZf7/ZGX+/2Vl/v9mZf7/ZmX//2Zl//9nZv7/Z2b+/2hn//9paP7/amn+/2tq/v9ra/7/bGz//2xt/v9tbv//bm///29w//9wcf//cXL+/3N0/v90df3/dnb+/3d5//95ev//enz+/3p8/v99ff7/e3z+/2dm/P9jYv7/Y2L+/2Rk/v9mZv//Z2X//2dl/f9hXPj/QS71/1I+9P+/u/P/+vz9///+///9//7//v///////v///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v/////////+/v7//f39/9jY+f9uXe//cl/4/5CG9f/S0Pb//Pz+//v+/v///v///v7+//z+/P/b3fn/oaH2/46P/P+GhPz/gX7//3t7/v95ev3/d3f//3V2//90dP7/cnP+/3Fy/v9wcf7/b3D+/29v/v9ubv//bm3//21t//9sbP//a2v+/2tq/v9qaf7/amn+/2lo/v9paP7/aGj+/2ho/v9oZ/7/aGf+/2hn/v9pZ/7/aWj+/2lp/v9paf7/amr+/2tr//9sbP//bGz+/2xs/v9ubv7/bm7+/29v//9wcf//cXL+/3Jz//9zdP//d3X+/3Z3/v93ef//eXr+/3t7/v99ff7/fH7//31+/v97e/7/ZmX8/2Nl/f9jZP3/ZWX9/2Zl/v9nZfz/Y1/8/0Uy9P9LOfX/oZnw//r7/f/9/v3///////7//v/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+//7//Pv9/8nF8/9mV+//dF/5/5SL9//T0fb//f39//7//f/8//7//f7///39/f/u7/r/tLT0/46O+v+FhP7/fn3+/3t7/v94ev//eHj//3Z2/v91df7/cnT+/3Jz/v9xcv7/cHH+/3Bw//9vb/7/b27//21t//9sbP7/bW3+/2xs//9sbP//a2v+/2tr/v9ra/7/a2v+/2pq/v9qav7/amr+/2tr/v9ra/7/a2v+/2tr/v9sbP//bW3+/21t/v9ubv//bm7//29w/v9vcP7/cHH//3Jz//9ydP7/c3X+/3R2/v93eP7/eXn//3p6//98fP7/fX3+/4B//v9/gP//fn/+/3l5/f9nZv3/ZmX//2Vl/v9mZP//ZmP//2Zh+f9HNPT/STP4/4yA7//29v3//v7+//7///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////7////8/v3//fv9/7q18v9oVfH/dGL5/5SM9//S0vb//Pz8//3+/v/9/v3////8//7//v/5+v7/vr/1/4iI/P9/gP7/fH3+/3p7/v96ev//eXn+/3h4//92dv7/dHT+/3R0/v9yc/7/cXL+/3Bx/v9wcf//b3D//29v//9ub/7/bW7+/21u/v9sbf7/bG3+/2xt/v9sbf7/bG3+/2xt/v9sbf7/bG3+/2xt/v9tbv7/bW7+/21u/v9ub/7/b3D+/29w//9vcP7/cXL+/3Fy/v9yc///c3T+/3V1/v93d/7/d3j+/3l6/v97e///fHz+/399/v9/f///f4H+/4GA/v+Agf7/dHX8/2dn/f9mZv3/ZWX+/2Vi/v9lYPz/Rjbz/0gy+P99cOz/8e/9//z+/v/9//3////+/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v////7+/v/8/f3/+vv9/7Wt8P9nVvH/dWL4/5KK9//JyPb/+vv9//7+/f/+//7//f////Dy/P+en/P/iYn9/4KC/f99gPz/fHz+/3x8/v97ev//enr//3h5//92dv7/dXX9/3N1/v9ydP7/cnP//3Jz//9wcf//cHH//3Bx/v9vcP7/bnD+/25v/v9ub/7/bW7+/21u/v9tbv7/bm/+/25v/v9ub/7/bm/+/25w/v9ucP7/bnD+/29x/v9wcf7/cnP//3Jz//9ydP7/cnT+/3N1//91dv7/d3j+/3l6//95e///fXv+/359//99fv7/f3///4CB//+Bgv//goL+/4GB/f9wcfz/aGn+/2hm/v9lZP//ZF/8/0c28/9IM/j/fGnt/+zt+//8/f7//f7+//7//v/+//3/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+fr+/7Or8P9mVvD/c2D6/46F9/+/vfL/9fb8//39/P/4+vz/ubrz/5KR/P+Jif3/hIP//4CB/f9/f/3/f379/359/v96e/7/eXv//3h5//94ef//d3j+/3Z2/v91df7/dHX+/3J0/v9ydP7/cXP+/3Fy/v9wcf3/cHH9/3Bx/f9wcf7/cHH+/3Bx/v9wcf7/cHH+/3Bx//9wcf//cHH9/3Bx/f9xcv7/c3P+/3R0/v91df//dXX//3V1/f92dv3/d3j+/3l5//97ev//e3v//3t7/v98ff7/fn///3+A//+Cgf//hIL+/4WD/v+Fg/7/gIL8/2xq/P9oZv7/ZWP+/2Rc+/9ENPT/SDP5/3ps6//s6vv//f3+//3//v/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////7/v7/+/z8/7uz9f9oVe7/cF33/4h8+f+rqfP/6er7/8zO9v+YmPj/j4/9/4mI/v+EhP//goL+/4CC//9/gP7/f37+/359/v98fP7/e3v+/3t6//95ev//eHn//3d4//93d///dXX//3V1//90dP7/c3T//3N0/v9zdP7/c3T+/3Jz//9yc///cnP//3Jz//9yc///cnP//3Jz//9zdP7/c3T+/3N0/v90df7/dXb9/3Z3/v92d/7/eXn//3l6//96ev//e3v//3x8/v98ff7/fH3+/39//v+BgP7/goL//4OD//+EhP//hYX//4SE//96ef3/aWb9/2Zl/f9eV/n/QzD0/0k0+P+Bdez/8PD7//79/P/9//7//v/+//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////3//v/+/v7/+/z7/8XE8/9rXO7/bln5/35t9/+XlPb/lpL5/46N/f+Kiv3/h4f+/4WF//+EhP//g4L//4CB/v9/gP7/gID//35+/v99ff7/fXz+/3x7/v97e///e3r//3p6//94ef//eHn//3Z3/f92dv7/dnb+/3Z2/v92dv7/dXX+/3V1/v91df7/dXX+/3V1/v91df7/dXX+/3Z2/v92dv7/dnb+/3d3/v93eP7/eHn//3h5//97ev//e3v+/3x8/v98ff7/fX7+/36A/v9+gP7/goH+/4KC/v+DhP7/hYX+/4aF/v+GhP//g4L9/3Fw+/9nZvr/V074/0Is+P9NOvf/j4fu//Hz/f/9/v7//f/+//3+//////7///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////7////9/v7//f3+/9rY9/93ae7/alP3/21e+P+FfPr/iIX+/4aF/v+Ghv3/h4X+/4eF/v+GhP7/hIP//4KC/v+Cgf7/gIH+/39//v9/f/7/fn3+/359/v99e/7/fHv+/3p6//96ev//enr//3h5/v94ef7/eHn+/3h5//95eP//eXj//3h4//94eP7/d3j+/3h4//94eP//eHn+/3h5/v95ev//env+/3p7/v97fP7/e3z+/3x8/v99ff7/fX7+/35//v+AgP7/gYL+/4GC/v+Eg/7/hYT//4aG/v+Hhf7/hIX8/4SC/v9+fPz/aGP7/05A9/9DLvb/VkLy/6qk8f/5+v7//f79//////////7//v///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v//+vz7/+zq+/+Nhez/Yk/y/2hT+f9zaff/hYL9/4WE/v+Ghf3/h4X+/4eG/v+Hhf7/hoT+/4SD/v+Cg/7/gYH+/4GB/v+AgP7/gH/+/35+/v9+ff//fHz+/3x8/v98fP7/e3v+/3t7/v97ev7/e3r+/3t6//97ev//enn//3p6//96ev//enr//3p6//98ev7/fHr+/3x7//98fP7/fH3+/319/v99ff7/fn7//3+A//9/gP7/gYH+/4KB/v+Dg///g4T+/4aE/v+GhP//h4b+/4aF/v+Dgv7/g4H7/2dh9/9GNfX/STT3/2ZX7//JxvX/+vv8//7+/v/+/v/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////9//7//P7+//n6/f+2sfL/ZFfv/2ZO+P9qWfr/fHT7/4aC/v+GhP3/hoX9/4aF/v+Hhv7/hob+/4SF/v+EhP//g4L//4GC/v+Bgv7/gID+/3+A//9+f/7/fn/+/31+/f9+ff7/fn3+/358/v9+fP7/fHz//3x8//98fP7/fHz+/3x8/v98fP7/fHz+/359/v9+ff7/fn7+/35//f9+f/3/f4D+/3+A/v+BgP//goH+/4KC/v+Dg///hIT+/4WF/v+Fhf7/h4b+/4aG/f+Ghfz/g4L+/4J9/P9pWvj/STP2/1A99f+Lf+3/5+b5//39/v/+/vz//f/+/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v////7//f/9/v///v/9//37/v/g3/j/hn3u/2BN8v9kUfn/bWH1/4B5/P+Fg///hYP+/4aE//+Ghf7/h4X+/4eF//+GhP7/g4T+/4OD/v+Cgv7/gYH+/3+B/v9/gf7/gIH+/3+A//9/gP//fn///35///9+f/7/fn/+/31+/v9+fv7/f37+/4B//v+Af/7/foD+/36A/v9/gf//gIH+/4CC/v+Agv7/gYL+/4OD//+DhP7/hIX//4aE//+Ghf7/h4b9/4eG/f+Fg///hYP+/4OA/f91bPf/ZlL4/1hC+P9oWO3/v7jz//j3/v/8/Pz//v79//7//v/+//7//v/+/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////P/+//79/f/4+P3/wbzz/3Fj7v9iTvb/Z1L5/3Bh+P+Bevv/hYT8/4OD/P+Fg/7/hoT+/4aF/f+Ghf3/hoX+/4aE/f+Gg/7/hIP+/4SD/v+Egv7/goL//4CC//+Agv7/gIL+/4KC/v+Cgv7/gYH+/4GB/v+Bgf3/goL+/4KB/v+Cgv7/goL+/4KC/v+Dgv//hIP+/4WD/v+FhP7/hoT+/4aF/v+Hhv7/hoX+/4aE/f+Fg/3/hIP8/4N//f93bPf/alf5/2JP+f9iUfH/nZLu/+vp+v/+/v7//v7+///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////+//7//f/9//79+//9/P3/8PH+/7Go8f9sXOz/YU72/2dS+f9wYPf/fXT6/4SA/f+Ggv7/hYL+/4aE/v+GhP3/hoX+/4aF/f+GhP//hoT//4aE/v+Fg/7/hIP+/4SD/v+Eg/7/g4P//4OD//+Cgv7/goL+/4KC/v+Dg///g4P//4SE/v+EhP7/hYX//4WE//+GhP7/hoT//4aF/v+GhP7/hoX8/4WC/f+Dgf7/hIH+/4F7/f9zaPn/Z1b4/2JP+v9iT/H/j4Xt/9zZ+f/6+/3//P3+/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v/9/v///f7+//v+/v/7//3/+/3+/+7s+/+vqfH/cGLs/2BO9f9jT/n/aVn4/3Jn+P9+d/r/hIH8/4SD/P+Fgf//hYP+/4WD//+Fg///hoT//4aE//+GhP//hoT//4aE//+GhP//hoT//4aE//+FhP//hYT//4aE//+GhP//hoT//4aE//+GhP7/hYT+/4WE/v+Fg/7/hYP+/4SB/f+Fgf3/gn77/3lv+f9uXvf/ZlL5/2JO9/9iUu//kIvq/9fW9//7+/7//f/8//7+//////7//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v////////////7//v////7//f/9/v7//f7+//z9/v/08/7/wb7z/4N47f9jUfD/YU74/2RT+P9pWPj/cmX4/3tx+v+Cff3/g4D+/4SC/f+Egv7/hIL+/4OD/f+Dgv//hIL+/4WD/v+GhP//hYT+/4WD/v+Egv3/hYP+/4SD//+Fg/7/hIP+/4KC/v+Dgf3/hYH+/4R//f99dvz/dWr5/21d+P9mVPr/Y0/5/2BO8/9wYu3/p6Hx/+bl+v/8+v///v79//7//v////7//v////3//v///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////v/+//7+/P/8/P3/+Pr8/9/f+f+up/H/e27u/19N7/9fSfn/YEz5/2NP+P9nVvf/bV/5/3Fm+v91bfj/e3P7/4F4/f+De/7/g33+/4N+/v+Dfv7/gn3+/4N+/v+EfP7/gHj+/3x2+/95b/r/dWn6/3Ji+f9rW/f/ZVP3/2FN+v9gTPj/Xkzy/2tc7P+WjvD/zMn1//Tz/P/6/P3///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////7//f////3+/v/+/v7//f7+//7+/P/8+v7/5uP7/7m18P+OhPH/alnq/1ZD7v9UPPT/Vj73/1U9+v9VPPr/Vz/4/1hA+P9YRPf/WUb3/1lF+P9ZRPj/V0T3/1VD9/9VQPj/Vj75/1U9+f9UPPj/Uz71/1I+8f9fTer/gHLv/6if8P/X0vj/9vT+//z9/f/8/f7//P79//3//v////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////7//////////v7///7+/v/+/v///f/+//3//f/8/v3//fz9//v7/f/19v3/5eT7/8bE8/+oofD/i4Hv/3Vm6/9eTOP/Tjfq/0Ar8P87JPT/OSD2/zsj9P89J/L/RzPs/1ZE5f9qXOX/gnft/5yT8f+5te//29n4//Hw/f/4+/3//P39//v+/f/9/v7//f7+//z9/v/+/v7//v7+/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////w=="
Private Const BS64_OEM_ini = "W0dlbmVyYWxdDQpNYW51ZmFjdHVyZXI9IkPDtG5nIFBoxrDGocyjbmcgRm9vZCINCk1vZGVsPSJMYcyAbyBDYWkgLSBWacOqzKN0IE5hbSINClN1cHBvcnRVUkwgPSJodHRwOi8vY29uZ3BodW9uZ2Zvb2QuYmxvZ3Nwb3QuY29tLyINCltJQ1ddDQpQcm9kdWN0PSIiDQpbU3VwcG9ydCBJbmZvcm1hdGlvbl0NCkxpbmUxPSJTw7TMgSDEkWnDqsyjbiB0aG9hzKNpIDogMDE2OTczOTk4MjMgaG/Eg8yjYyAwMTY4NjUyNTU2NCINCg=="
   
'Reset
Set WS = Nothing
Set FSO = Nothing
Set WMI = Nothing
Set SA = Nothing
Set REG = Nothing
Set NAC = Nothing