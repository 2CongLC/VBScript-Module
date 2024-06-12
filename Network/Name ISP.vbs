'Lấy tên nhà cung cấp dịch vụ mạng - ISP
'Tác giả : 2CongLC
'Phiên bản : 30.4.2019
Option ExPlicit

Dim HTTP : Set HTTP = CreateObject("MSXML2.XMLHTTP")
HTTP.Open "GET", "https://www.whoismyisp.org", False
HTTP.Send
Dim S : S = HTTP.responseText
Dim RE : Set RE = New RegExp
With RE
	.Pattern = "<p class=""isp"">(.*)</p>"
	.IgnoreCase = False
	.Global = False
End With
Dim Result : Set Result = RE.Execute(S)
 
WScript.Echo "ISP Is : " & Result.Item(0).SubMatches(0)