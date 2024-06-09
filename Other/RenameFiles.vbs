'Coder : 2CongLc.Vn
'File Name : RenameFiles.vbs
'Version : Public/Release 1.5.17
Option Explicit

Dim WS : Set WS = CreateObject("WSCript.Shell")
Dim SA : Set SA = CreateObject("Shell.Application")
Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

Dim Root
If WScript.Arguments.Count <> 0 Then
 Set Root = FSO.GetFolder(FSO.GetParentFolderName(WScript.Arguments.Item(0)))
Else
 Set Root = FSO.GetFolder(FSO.GetParentFolderName(WScript.ScriptFullName))
End if 

Dim NameC, NameN, ExtC, ExtN
NameC = "" : NameN = "" 'Đổi tên tệp tin ví dụ test.txt -- > foo.log : NameC = "test.txt" : NameN = "foo.log"
ExtC = ".log" : ExtN = ".txt" 'Đổi đuôi tệp tin ví dụ .txt --> .log : ExtC = ".txt" : ExtN = ".log"

'Chú ý : Áp dụng cho tất cả tệp tin trong toàn thư mục tại vị trí dùng script.
ScanFolders Root


Private Sub ScanFolders(cmd)
 Processes cmd.Path
 Dim i
 For Each i In cmd.SubFolders
    ScanFolders i
  Next
End Sub


Private Sub Processes(ByRef cmd)
 Dim CDir : Set CDir = FSO.GetFolder(cmd)
 Dim i
 For Each i in CDir.Files
  If FSO.FileExists(i) Then Rename(i)
 Next
End Sub

Private Sub Rename(ByRef File)
 If Instr(1,File.Name,NameC) <> 0 Then
  If (ExtC <> "" And ExtN <> "") Then
   File.Move Replace(Replace(File.Path, NameC, NameN), ExtC, ExtN)
  Else
   File.Move Replace(File.Path, NameC, NameN)
  End if
 Else
 End if
End Sub


Set WS = Nothing
Set SA = Nothing
Set FSO = Nothing
