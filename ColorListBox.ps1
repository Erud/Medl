function Call-Demo-ListboxDrawItem {
	
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	#endregion Import Assemblies
	
	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$form1 = New-Object 'System.Windows.Forms.Form'
	$listbox1 = New-Object 'System.Windows.Forms.ListBox'
	$buttonOK = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects
	
	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$form1_Load = {
		$items = @(
        'This is red','This is blue','This is green'
		)
		$listbox1.Items.AddRange($items)
	}
	
	
	$listbox1_DrawItem = [System.Windows.Forms.DrawItemEventHandler]{
		#Event Argument: $_ = [System.Windows.Forms.DrawItemEventArgs]
		
        $p = New-Object System.Drawing.PointF($_.Bounds.X, $_.Bounds.Y)
		#$b = New-Object System.Drawing.SolidBrush($listbox1.Items[$_.Index].Color)
		
        $text = $listbox1.Items[$_.Index]
        if ($text.Contains('red')) {
            $b = New-Object System.Drawing.SolidBrush('Red')
        } else {
            $b = New-Object System.Drawing.SolidBrush('Black')
        }

		$_.Graphics.DrawString($text, $_.Font, $b, $p)
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load =
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$form1.WindowState = $InitialFormWindowState
	}
	
	#endregion Generated Events
	
	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$form1.SuspendLayout()
	#
	# form1
	#
	$form1.Controls.Add($listbox1)
	$form1.Controls.Add($buttonOK)
	$form1.AcceptButton = $buttonOK
	$form1.ClientSize = '141, 190'
	$form1.FormBorderStyle = 'FixedDialog'
	$form1.MaximizeBox = $False
	$form1.MinimizeBox = $False
	$form1.Name = 'form1'
	$form1.StartPosition = 'CenterScreen'
	$form1.Text = 'Form'
	$form1.add_Load($form1_Load)
	#
	# listbox1
	#
	$listbox1.DrawMode = 'OwnerDrawFixed'
	$listbox1.FormattingEnabled = $True
	$listbox1.Location = '12, 12'
	$listbox1.Name = 'listbox1'
	$listbox1.Size = '118, 121'
	$listbox1.TabIndex = 1
	$listbox1.add_DrawItem($listbox1_DrawItem)
	#
	# buttonOK
	#
	$buttonOK.Anchor = 'Bottom, Right'
	$buttonOK.DialogResult = 'OK'
	$buttonOK.Location = '54, 155'
	$buttonOK.Name = 'buttonOK'
	$buttonOK.Size = '75, 23'
	$buttonOK.TabIndex = 0
	$buttonOK.Text = '&OK'
	$buttonOK.UseVisualStyleBackColor = $True
	$form1.ResumeLayout()
	#endregion Generated Form Code
	
	#----------------------------------------------
	
	#Save the initial state of the form
	$InitialFormWindowState = $form1.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$form1.add_Load($Form_StateCorrection_Load)
	return $form1.ShowDialog()
	
} #End Function

Call-Demo-ListboxDrawItem