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
 
If IsPermission = "Yes" Then AD()

'https://msdn.microsoft.com/en-us/library/aa394135(v=vs.85).aspx 
Private Function GetUSB(cmd)
 Dim SingleDiskDrive
 For Each SingleDiskDrive In WMI.ExecQuery("SELECT * FROM Win32_DiskDrive where InterfaceType='USB'")   
  Dim Partition
  For Each Partition In WMI.ExecQuery("ASSOCIATORS OF {Win32_DiskDrive.DeviceID='" + SingleDiskDrive.DeviceID + "'} WHERE AssocClass = Win32_DiskDriveToDiskPartition" ) 
   Dim SingleLogicalDisk 
   For Each SingleLogicalDisk In WMI.ExecQuery("ASSOCIATORS OF {Win32_DiskPartition.DeviceID='" + Partition.DeviceID + "'} WHERE AssocClass = Win32_LogicalDiskToPartition")    
	 If cmd = "DiskID" Then GetUSB = SingleDiskDrive.DeviceID
	 If cmd = "PartionID" Then GetUSB = SingleLogicalDisk.DeviceID
	 If cmd = "Info" Then
	  GetUSB = "============================================" & VbCr & _ 
						"DeviceID: " & SingleDiskDrive.DeviceID & VbCr & _ 
						"Logical Drive: " & SingleLogicalDisk.DeviceID  & VbCr & _ 
						"Model: " & SingleDiskDrive.Model & VbCr & _ 
						"Manufacturer: " & SingleDiskDrive.Manufacturer & VbCr & _
						"MediaType: " & SingleDiskDrive.MediaType & VbCr & _
						"FirmwareRevision: " & SingleDiskDrive.FirmwareRevision & VbCr & _
						"SerialNumber: " & SingleDiskDrive.SerialNumber & VbCr & _
						"Status: " & SingleDiskDrive.Status & VbCr & _
						"---------------------------------------------" & VbCr & _
						"Bootable: " & Partition.Bootable & VbCr & _
						"BootPartition: " & Partition.BootPartition & VbCr & _
						"PrimaryPartition: " & Partition.PrimaryPartition & VbCr & _
						"Size: " & ConvertSize(Partition.Size) & VbCr & _
						"============================================"
	  End if
    Next
   Next 
  Next 
 End Function

Private Function Eject() ' 0 = ok  
  Eject = SA.NameSpace(17).ParseName(GetUSB("PartionID")).InvokeVerb("Eject")
 End Function
 
If GetUSB("PartionID") <> "" Then
 'If Eject() = "" Then WSsript.Echo "OK"
 Else
 WSCript.Echo "Not Find USB Device !"
 End if