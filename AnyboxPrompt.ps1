Import-Module AnyBox
$ans = Show-AnyBox -Title 'Credentials' -Buttons 'Cancel','Submit' -MinWidth 100 -Prompts @(
    New-AnyBoxPrompt -Group 'Connection Info' -Message 'User Name:' -DefaultValue "medline/pa-erudakov"
    New-AnyBoxPrompt -Group 'Connection Info' -Message 'Password:' -InputType Password
)