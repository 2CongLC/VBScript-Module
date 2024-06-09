@SetLocal EnableExtensions
@Echo Off
@CD /d "%~dp0"
Reg.exe add "HKCR\Directory\shell\KillAutorun" /ve /t REG_SZ /d "KillAutorun" /f
Reg.exe add "HKCR\Directory\shell\KillAutorun\command" /ve /t REG_SZ /d "wscript.exe \"%CD%\KillAutorun.vbs\" \"%%1\"" /f
Reg.exe add "HKCR\Drive\shell\KillAutorun" /ve /t REG_SZ /d "KillAutorun" /f
Reg.exe add "HKCR\Drive\shell\KillAutorun\command" /ve /t REG_SZ /d "wscript.exe \"%CD%\KillAutorun.vbs\" \"%%1\"" /f
Exit