Function Test-IsWsman3 {
[cmdletbinding()]
Param(
[Parameter(Position=0,ValueFromPipeline)]
[string]$Computername=$env:computername
)
 
Begin {
    #a regular expression pattern to match the ending
    [regex]$rx="\d\.\d$"
}
Process {
    Try {
        $result = Test-WSMan -ComputerName $Computername -ErrorAction Stop
    }
    Catch {
        Write-Error $_.exception.message
    }
    if ($result) {
        $m = $rx.match($result.productversion).value
        if ($m -eq '3.0') {
            $True
        }
        else {
            $False
        }
    }
} #process
End {
 #not used
}
} #end Test-IsWSMan

Test-IsWsman3 -Computername MUNANALYTICS1-O