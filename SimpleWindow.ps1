Add-Type -AssemblyName System.Windows.Forms
$form = New-Object Windows.Forms.Form
$form.Size = New-Object Drawing.Size @(200,100)
$form.StartPosition = "CenterScreen"
$Icon = New-Object system.drawing.icon ("C:\Users\erudakov\Documents\PS\favicon.ico")
$form.Icon = $Icon
$btn = New-Object System.Windows.Forms.Button
$btn.add_click({Get-Date|Out-Host})
$btn.Text = "Click here"
$form.Controls.Add($btn)
$drc = $form.ShowDialog()

$Form.Dispose()