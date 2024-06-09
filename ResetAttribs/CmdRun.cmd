@SetLocal EnableExtensions
@Echo Off
Pushd "%~dp0"
Reg.exe add "HKCR\*\shell\ResetAttribs" /ve /t REG_SZ /d "ResetAttribs" /f
Reg.exe add "HKCR\*\shell\ResetAttribs\command" /ve /t REG_SZ /d "wscript.exe \"%CD%\ResetAttribs.vbs\" \"%%1\"" /f
Reg.exe add "HKCR\Directory\shell\ResetAttribs" /ve /t REG_SZ /d "ResetAttribs" /f
Reg.exe add "HKCR\Directory\shell\ResetAttribs\command" /ve /t REG_SZ /d "wscript.exe \"%CD%\ResetAttribs.vbs\" \"%%L\"" /f
Exit