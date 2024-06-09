@SetLocal EnableExtensions
@Echo Off
Pushd "%~dp0"
Reg.exe add "HKCR\Directory\shell\ResetNTFSPermission" /ve /t REG_SZ /d "ResetPermission" /f
Reg.exe add "HKCR\Directory\shell\ResetNTFSPermission\command" /ve /t REG_SZ /d "wscript.exe \"%CD%\ResetNTFSPermission.vbs\" \"%%L\"" /f
Exit