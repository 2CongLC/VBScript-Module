FOR /F "delims=" %%G in ('FORFILES /P "%CD%" /M *.EXE /S') DO (
    TASKKILL /F /IM %%G /T
)

pause>nul