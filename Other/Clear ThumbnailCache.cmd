@SetLocal EnableExtensions
@Echo Off
cd /d %userprofile%\AppData\Local\Microsoft\Windows\Explorer 
attrib –h 
thumbcache_*.db 
del thumbcache_*.db 
start explorer