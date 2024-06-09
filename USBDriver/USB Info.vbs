Option Explicit

Dim WS : Set WS = CreateObject("WSCript.Shell")
Dim WMI : Set WMI = GetObject("winmgmts:\\.\root\cimv2")

Private Function ConvertSize(Size) 'Nguồn tham khảo : http://goo.gl/UBJEY0
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

If GetUSB("PartionID") <> "" Then
 WSCript.Echo GetUSB("Info")
 Else
 WSCript.Echo "Not Find USB Device !"
 End if