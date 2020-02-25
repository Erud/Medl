$cred = Get-Credential "MEDLINE-NT\SVC_Simpana_CV"

Start-Process -FilePath "C:\Windows\System32\mmc.exe" -Credential $cred