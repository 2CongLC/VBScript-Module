

Option Explicit

Dim NAC : Set NAC = GetObject("winmgmts:").InstancesOf("Win32_NetworkAdapterConfiguration WHERE IPEnabled = True")



If GetNetStatus("http://2conglcvn.blogspot.com/") = "NO" Then SetDNS("Google")
If GetNetStatus("https://www.facebook.com/") = "NO" Then SetDNS("Google") 
WScript.Echo "Done !"

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

Set NAC = Nothing