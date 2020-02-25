#Get UserB credential
$Credential = Get-Credential itdroplets\UserB

#Define a result file where to temporarily store the output of the process.
#Remove the file if it already exists
$ResultFile = "$($env:temp)\_tmpresult.txt"
If (Test-Path $ResultFile)  {
	Remove-Item $ResultFile
}

#Set the Arguments for the process
$ProcessArguments = "Get-Process Explorer"
#Start the process and specify %WINDIR% as working directory
(Start-Process -FilePath "powershell.exe" -Credential $Credential -ArgumentList $ProcessArguments -WorkingDirectory $env:windir -NoNewWindow -PassThru -RedirectStandardOutput $ResultFile).WaitForExit()

#Read the file, if it exists and remove it afterwards
If (Test-Path $ResultFile)  {
	$Result = Get-Content $ResultFile
	Remove-Item $ResultFile
	$Result
}Else  {
	write-error "File $($ResultFile) does not exist!"
}