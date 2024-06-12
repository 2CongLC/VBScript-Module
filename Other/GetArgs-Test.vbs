Option Explicit

Dim WS : Set WS = CreateObject("WSCript.Shell")
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")


Dim Args : Set Args = WSCript.Arguments

If Args.Count <> 0 Then
 WSCript.Echo Args.Item(0)
 End if
