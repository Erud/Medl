#$computer = "MUNPRDPASHRINK1"
$computer = "MUNCPDB1"
$Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
$RegKey= $Reg.OpenSubKey("System\\CurrentControlSet\\Control\\Lsa\\FIPSAlgorithmPolicy")
$Val = $RegKey.GetValue("Enabled")
$Val
