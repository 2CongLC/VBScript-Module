@Echo off

pushd %CD%
FOR %%A IN (*.exe) do (
tasklist /FI "IMAGENAME eq %%A" 2>NUL | find /I /N "%%A">NUL
if "%ERRORLEVEL%"=="0" taskkill /f /im %%A
)
Exit