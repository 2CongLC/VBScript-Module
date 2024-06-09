@SetLocal EnableExtensions
@Echo Off
Pushd "%~dp0"
Reg.exe add "HKCR\Directory\shell\TaskillFolder" /ve /t REG_SZ /d "TaskillFolder" /f
Reg.exe add "HKCR\Directory\shell\TaskillFolder\command" /ve /t REG_SZ /d "cmd.exe \"%CD%\TaskillFolder.cmd\" \"%%1\"" /f
Exit