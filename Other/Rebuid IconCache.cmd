@SetLocal EnableExtensions
@Echo Off

cd /d %userprofile%\AppData\Local\Microsoft\Windows\Explorer
attrib –h iconcache_*.db
del iconcache_*.db 
start explorer