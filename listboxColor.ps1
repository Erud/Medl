$status='logged','disconnected','locked'

function add {
 $index=Get-Random -max 3
 $state = "$Index-$($Status[$index])"
 $listbox.Items.Add($state)
}

$listBox_DrawItem={
 param(
  [System.Object] $sender, 
  [System.Windows.Forms.DrawItemEventArgs] $e
 )
   #Suppose Sender de type Listbox
 if ($Sender.Items.Count -eq 0) {return}

   #Suppose item de type String
 $lbItem=$Sender.Items[$e.Index]
 if ( $lbItem -match 'locked$')  
 { 
    $Color=[System.Drawing.Color]::yellowgreen       
    try
    {
      $brush = new-object System.Drawing.SolidBrush($Color)
      $e.Graphics.FillRectangle($brush, $e.Bounds)
    }
    finally
    {
      $brush.Dispose()
    }
   }
 $e.Graphics.DrawString($lbItem, $e.Font, [System.Drawing.SystemBrushes]::ControlText, (new-object System.Drawing.PointF($e.Bounds.X, $e.Bounds.Y)))
}     

#Generated Form Function
function GenerateForm {


#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
#endregion

#region Generated Form Objects
$form1 = New-Object System.Windows.Forms.Form
$add = New-Object System.Windows.Forms.Button
$listbox = New-Object System.Windows.Forms.ListBox
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------
#Provide Custom Code for events specified in PrimalForms.
$handler_form1_Load= 
{
#TODO: Place custom script here

}

$handler_btnRechercher_Click= 
{
add
#TODO: Place custom script here

}

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
    $form1.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#region Generated Form Code
$form1.BackColor = [System.Drawing.Color]::FromArgb(255,240,240,240)
$form1.Text = "Move VM"
$form1.Name = "form1"
$form1.AutoScaleMode = 3

$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$form1.AutoScroll = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 357
$System_Drawing_Size.Height = 486
$form1.ClientSize = $System_Drawing_Size
$form1.add_Load($handler_form1_Load)

$add.TabIndex = 8
$add.Name = "add"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 130
$System_Drawing_Size.Height = 23
$add.Size = $System_Drawing_Size
$add.UseVisualStyleBackColor = $True

$add.Text = "add"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 104
$System_Drawing_Point.Y = 448
$add.Location = $System_Drawing_Point
$add.DataBindings.DefaultDataSourceUpdateMode = 0
$add.add_Click($handler_btnRechercher_Click)

$form1.Controls.Add($add)

$listbox.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 330
$System_Drawing_Size.Height = 407
$listbox.Size = $System_Drawing_Size
$listbox.DataBindings.DefaultDataSourceUpdateMode = 0
$listbox.Name = "listbox"

$listBox.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
$listBox.Add_DrawItem($listBox_DrawItem)

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 21
$listbox.Location = $System_Drawing_Point
$listbox.TabIndex = 4
$listbox.add_Click($action_si_click_sur_VMKO)

$form1.Controls.Add($listbox)

#endregion Generated Form Code

#Save the initial state of the form
$InitialFormWindowState = $form1.WindowState
#Init the OnLoad event to correct the initial state of the form
$form1.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$form1.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm