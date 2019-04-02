function Tabify-PS {
	
	Param($ScriptText) 
	
	$CurrentLevel = 0
	$ParseError = $null
	$Tokens = $null
	$AST = [System.Management.Automation.Language.Parser]::ParseInput($ScriptText, [ref]$Tokens, [ref]$ParseError) 
	
	if($ParseError) { 
		$ParseError | Write-Error
		throw 'The parser will not work properly with errors in the script, please modify based on the above errors and retry.'
	}
	
	for($t = $Tokens.Count -2; $t -ge 1; $t--) {
		
		$Token = $Tokens[$t]
		$NextToken = $Tokens[$t-1]
		
		if ($token.Kind -match '(L|At)Curly') { 
			$CurrentLevel-- 
		}  
		
		if ($NextToken.Kind -eq 'NewLine' ) {
			# Grab Placeholders for the Space Between the New Line and the next token.
			$RemoveStart = $NextToken.Extent.EndOffset  
			$RemoveEnd = $Token.Extent.StartOffset - $RemoveStart
			$tabText = "`t" * $CurrentLevel 
			$ScriptText = $ScriptText.Remove($RemoveStart,$RemoveEnd).Insert($RemoveStart,$tabText)
		}
		
		if ($token.Kind -eq 'RCurly') { 
			$CurrentLevel++ 
		}     
	}
	
	$ScriptText
}


$psISE.CurrentFile.Editor.Text = Tabify-PS $psISE.CurrentFile.Editor.Text 
#or
$psISE.CurrentFile.Editor.Text = Tabify-PS $psISE.CurrentFile.Editor.Text