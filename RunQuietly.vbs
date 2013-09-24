ret=-1
if WScript.Arguments.Count > 0 then
	set objShell=wscript.createObject("wscript.shell")
	ret=objShell.Run(WScript.Arguments.Item(0), 0, TRUE)
	set objShell=Nothing
end if
wscript.quit ret
