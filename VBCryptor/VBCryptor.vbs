Option Explicit

Dim FSO : Set FSO = CreateObject("Scripting.FileSystemObject")
Dim SE : Set SE = CreateObject("Scripting.Encoder")


Dim FileIn
If WScript.Arguments.Count <> 0 Then
 Set FileIn = FSO.GetFile(WScript.Arguments.Item(0))
 If WScript.Arguments.Item(1) = "-e" Then
  Encoder()
 Elseif WScript.Arguments.Item(1) = "-d" Then
  Decoder()
 Else
  WScript.Quit
 End if  
Else
 WScript.Quit
End if

Private Sub Encoder()
 Dim FS : If FSO.FileExists(FileIn) Then Set FS = FileIn.OpenAsTextStream(1)
 Dim Src : Src = FS.ReadAll
 FS.Close()
 Dim E : E = SE.EncodeScriptFile(".vbs",Src,0,"")
 Dim FileOut : FileOut = Left(FileIn, Len(FileIn) - 3) & "vbe" 
 Dim Stream : Set Stream = FSO.OpenTextFile(FileOut,2,True)
 Stream.Write E
 Stream.Close()
End Sub


Private Sub Decoder()
 Dim FS : If FSO.FileExists(FileIn) Then Set FS = FileIn.OpenAsTextStream(1)
 Dim Src : Src = FS.ReadAll
 FS.Close()
 Const TAG_BEGIN1 = "#@~^" 
 Const TAG_BEGIN2 = "==" 
 Const TAG_BEGIN2_OFFSET = 10 
 Const TAG_BEGIN_LEN = 12
 Const TAG_END = "==^#~@" 
 Const TAG_END_LEN = 6
 
 Dim iTagBeginPos : iTagBeginPos = Instr(Src, TAG_BEGIN1)
 If iTagBeginPos <> 0 Then
  If (Instr(iTagBeginPos, Src, TAG_BEGIN2) - iTagBeginPos) = TAG_BEGIN2_OFFSET Then
   Dim iTagEndPos : iTagEndPos = Instr(iTagBeginPos, Src, TAG_END)
   If iTagEndPos <> 0 Then
     Src = Mid(Src, iTagBeginPos + TAG_BEGIN_LEN, iTagEndPos - iTagBeginPos - TAG_BEGIN_LEN - TAG_END_LEN)
	 Dim i,c,j,index,ChaineTemp
	 Dim tDecode(127)
	 Const Combinaison="1231232332321323132311233213233211323231311231321323112331123132"
	 For i=9 to 127
		tDecode(i)="JLA"
	 Next
	 For i=9 to 127
		ChaineTemp=Mid(se.EncodeScriptFile(".vbs",string(3,i),0,""),13,3)
		For j=1 to 3
			c=Asc(Mid(ChaineTemp,j,1))
			tDecode(c)=Left(tDecode(c),j-1) & chr(i) & Mid(tDecode(c),j+1)
		Next
	 Next
	
	 tDecode(42)=Left(tDecode(42),1) & ")" & Right(tDecode(42),1)
	 Set se= Nothing
	 Src=Replace(Replace(Src,"@&",chr(10)),"@#",chr(13))
	 Src=Replace(Replace(Src,"@*",">"),"@!","<")
	 Src=Replace(Src,"@$","@")
	 index=-1
	 For i=1 to Len(Src)
		c=asc(Mid(Src,i,1))
		If c<128 Then index=index+1
		If (c=9) or ((c>31) and (c<128)) Then
			If (c<>60) and (c<>62) and (c<>64) Then
				Src=Left(Src,i-1) & Mid(tDecode(c),Mid(Combinaison,(index mod 64)+1,1),1) & Mid(Src,i+1)
			End If
		End If
	 Next	
     Dim FileOut : FileOut = Left(FileIn, Len(FileIn) - 1) & "s"
     Dim Stream : Set Stream = FSO.OpenTextFile(FileOut,2,True)
     Stream.Write Src
     Stream.Close()
   End if
  End if
 End if 
End Sub 