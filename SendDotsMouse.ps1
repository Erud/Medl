param($minutes = 160)

# https://stackoverflow.com/questions/38225874/mouse-click-automation-with-powershell-or-other-non-external-software
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$signature=@'
[DllImport("user32.dll",CharSet=CharSet.Auto,CallingConvention=CallingConvention.StdCall)]
public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);
'@

$SendMouseClick = Add-Type -memberDefinition $signature -name "Win32MouseEventNew" -namespace Win32Functions -passThru

$myshell = New-Object -com "Wscript.Shell"

for ($i = 0; $i -lt $minutes; $i++) {	
	Start-Sleep -Seconds 60
	$X = [System.Windows.Forms.Cursor]::Position.X
	$Y = [System.Windows.Forms.Cursor]::Position.Y
	if (($i -gt 0) -and ($X -ne $Xold) -and ($Y -ne $Yold)) { Exit }
	$Xold = $X
	$Yold = $Y
	# X: $X | Y: $Y
	$myshell.sendkeys("$i")
	$myshell.sendkeys("`b")
	#if ($i%2) {
	#$myshell.sendkeys("<")
	#} 
	#else {
	#	$myshell.sendkeys(".")
	#}
}