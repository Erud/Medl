﻿Get-Content C:\Temp\ipTST.txt | ForEach-Object {"$_,"+([system.net.dns]::GetHostByAddress($_)).hostname >> c:\temp\ipHTST.txt}