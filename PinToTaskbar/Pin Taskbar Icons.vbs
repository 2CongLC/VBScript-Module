Option Explicit
Dim FSO: Set FSO = CreateObject("Scripting.FileSystemObject")
Dim SA: Set SA = CreateObject("Shell.Application")

If wscript.arguments.count <> 0 then 
Pintotaskbar(wscript.arguments.item(0))
End if 

Private Function Pintotaskbar(File)
Dim Folderpath: set Folderpath = SA.Namespace(FSO.GetParentFolderName(File))
Dim Item: set Item = Folderpath.ParseName(FSO.GetFileName(File))
Dim VerbColl: set VerbColl = Item.Verbs
Dim i
For Each i in VerbColl
    If Replace(i.name, "&", "") = "Pin to taskbar" Then
    i.DoIt
	Pintotaskbar = 1
 End If
Next
    If Pintotaskbar = 1 Then
    wscript.echo "Pin '" & FSO.GetFileName(File) & "' file to taskbar successfully."
   Else
    wscript.echo "Pin '" & FSO.GetFileName(File) & "' file to taskbar Failed."
   End if
End Function