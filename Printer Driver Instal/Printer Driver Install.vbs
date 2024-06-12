' Product : Printer Driver Install
' Version : Release / No Update
' Date : 1-5-2015
' Author : CongCong.LaoCai.Vietnam@gmail.com
' ©2015. All Rights Reserved

Option Explicit
Dim  FSO: Set FSO = CreateObject("Scripting.FileSystemObject")
Dim strComputer: strComputer = "."
Dim objWMIService: Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
objWMIService.Security_.Privileges.AddAsString "SeLoadDriverPrivilege", True


' Tìm & Cài đặt máy in 
Dim Printers: Set Printers = objWMIService.Get("Win32_PrinterDriver")
Dim Result
With Printers

If (.Name = "HP Color LaserJet 1020" And .SupportedPlatform = "Windows NT x86" And .Version = "3") Then
.DriverPath = "Drivers\HP\CLJ1020\"
.Infname = "Drivers\HP\CLJ1020\CLJ1600.inf"
Result = Printers.AddPrinterDriver(Printers)
ElseIf (.Name = "HP Color LaserJet 1024" And .SupportedPlatform = "Windows NT x86" And .Version = "3") Then
.DriverPath = "Drivers\HP\CLJ1020\"
.Infname = "Drivers\HP\CLJ1020\CLJ1600.inf"
Result = Printers.AddPrinterDriver(Printers)

Else
WSCript.Echo "Can't Install"
End If

End With










