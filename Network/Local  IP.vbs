'Lấy địa chỉ Local IP
'Tác giả : 2CongLC
'Phiên bản : 30.4.2019
Option Explicit

Dim WMI : Set WMI = GetObject("winmgmts:\\.\root\cimv2")
Dim NET : Set NET = WMI.ExecQuery("Select IPAddress,description from Win32_NetworkAdapterConfiguration WHERE IPEnabled = 'True'")

Dim msg, i, j
For Each i in NET
	If Not IsNull(i.IPAddress) Then
	For j = LBound(i.IPAddress) to UBound(i.IPAddress)
		If Not Instr(i.IPAddress(j), ":") > 0 Then
			If InStr(1, i.description(j), "VMware") = 0 Then
				msg = msg & i.IPAddress(j)
				If j > 0 Then
					msg = msg & vbcrlf & VBTab
				End If
			End If
		End If
	Next
	End If
Next

WScript.Echo "Local IP : " & vbCr & msg

Set WMI = Nothing
Set NET = Nothing