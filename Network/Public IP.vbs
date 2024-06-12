'Lấy địa chỉ - Public IP
'Tác giả : 2CongLC
'Phiên bản : 30.4.2019
Option Explicit

Dim HTTP : Set HTTP = Createobject("MSXML2.XMLHTTP")

HTTP.Open "GET", "https://api.ipify.org", False
HTTP.Send

WScript.Echo "Extenal IP : " & vbcr & HTTP.ResponseText
