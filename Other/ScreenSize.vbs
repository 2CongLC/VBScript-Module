Option Explicit

Dim WMI : Set WMI = GetObject("winmgmts:\\.\root\cimv2")

Dim CurSize : CurSize = GetScreenSize

'WScript.Echo "Width = " & CurSize(0) & " Height = " & CurSize(1)
WScript.Echo CurSize(0)



Private Function GetScreenSize()
 Dim i
 For Each i in WMI.ExecQuery("Select * from Win32_Desktopmonitor")
  GetScreenSize = Array(i.ScreenWidth, i.ScreenHeight)
 Next
End Function


Set WMI = Nothing