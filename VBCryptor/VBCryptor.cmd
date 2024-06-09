@SetLocal EnableExtensions
@Echo Off
Pushd "%~dp0"
Reg.exe add "HKCR\VBSFile\shell\VBEncoder" /ve /t REG_SZ /d "Encoder" /f
Reg.exe add "HKCR\VBSFile\shell\VBEncoder\command" /ve /t REG_SZ /d "wscript.exe \"%CD%\VBCryptor.vbs\" \"%%1\" -e" /f
Reg.exe add "HKCR\VBEFile\shell\VBDecoder" /ve /t REG_SZ /d "Decoder" /f
Reg.exe add "HKCR\VBEFile\shell\VBDecoder\command" /ve /t REG_SZ /d "wscript.exe \"%CD%\VBCryptor.vbs\" \"%%1\" -d" /f
::Exit