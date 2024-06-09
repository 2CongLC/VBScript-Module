@SetLocal EnableExtensions
@Echo Off
@CD /d "%~dp0"
Reg.exe add "HKCR\*\shell\File2Base64" /ve /t REG_SZ /d "Base64Encode" /f
Reg.exe add "HKCR\*\shell\File2Base64\command" /ve /t REG_SZ /d "wscript.exe \"%CD%\File2Base64.vbs\" \"%%1\"" /f
Exit