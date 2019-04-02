$members | ForEach-Object {
$name = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
$class = $_.GetType().InvokeMember("ObjectClass", 'GetProperty', $null, $_, $null)
$name
}