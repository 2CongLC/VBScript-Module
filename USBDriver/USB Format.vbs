Option Explicit

Dim WS : Set WS = CreateObject("WSCript.Shell")
Dim WMI : Set WMI = GetObject("winmgmts:\\.\root\cimv2")
Dim SA : Set SA = CreateObject("Shell.Application")
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")


Private Function IsPermission()
 If Err.Number <> 0 Then
  IsPermission = "No"
  Else
  IsPermission = "Yes"
  End if
 End Function

Private Sub AD()
 If WScript.Arguments.length = 0 Then
   SA.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34) & Chr(32) & "RunAsAdministrator", , "runas", 1
   WSCript.Quit
  End if
 End Sub
 
If IsPermission = "Yes" Then AD()

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
 For Each SingleDiskDrive In WMI.ExecQuery("SELECT * FROM Win32_DiskDrive where InterfaceType='IDE'")   
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

Private Function Accept(msg) ' 6 = yes | 7 = no
 If msg <> "" Then
  Accept = Msgbox(msg & vbnewline & " Are you sure?",vbYesNo+vbInformation, "< 2CongLC.Vn > USB Format")
  End if
 End Function

Private Function Format(cmd) ' 0 = ok | https://msdn.microsoft.com/en-us/library/windows/desktop/aa390432(v=vs.85).aspx
 Dim i
 For Each i in WMI.ExecQuery("Select * from Win32_Volume Where Name ='" & GetUSB("PartionID") & "\\'")
  Format  = i.format(cmd,True,4096,"USB-GRUB2",False)
  Next
 End Function
 
If GetUSB("PartionID") <> "" Then
 Dim message : message = GetUSB("Info") & VbCr & "WARNING : Formatting will ease All data on this disk."
 If Accept(message) = 6 Then
   If Format("FAT32") = "0" Then
    Wscript.Echo "ok"    	
	End if  
   End if
 Else
 WSCript.Echo "Not Find USB Device !"
 End if