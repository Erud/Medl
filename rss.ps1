function Restart-ISE
{
    Start-Process PowerShell_ISE.exe
    exit
}
New-Alias "iss" "Restart-ISE"