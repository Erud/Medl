# https://stackoverflow.com/questions/38225874/mouse-click-automation-with-powershell-or-other-non-external-software
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$signature=@'
[DllImport("user32.dll",CharSet=CharSet.Auto,CallingConvention=CallingConvention.StdCall)]
public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);
'@

$SendMouseClick = Add-Type -memberDefinition $signature -name "Win32MouseEventNew" -namespace Win32Functions -passThru

$X = [System.Windows.Forms.Cursor]::Position.X
$Y = [System.Windows.Forms.Cursor]::Position.Y
Write-Output "X: $X | Y: $Y"

$x = -1558
$y = 51
[System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
sleep -Seconds 01
$SendMouseClick::mouse_event(0x00000002, 0, 0, 0, 0);
$SendMouseClick::mouse_event(0x00000004, 0, 0, 0, 0);