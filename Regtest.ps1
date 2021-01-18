$session = New-PSSession -Computer l80934
foreach ($test in $pendingRebootTests) {
    $result = Invoke-Command -Session $session -ScriptBlock $test.Test
    if ($test.TestType -eq 'ValueExists' -and $result) {
        $true
    } elseif ($test.TestType -eq 'NonNullValue' -and $result -and $result.($test.Name)) {
        $true
    } else {
        $false
    }
}
$session | Remove-PSSession