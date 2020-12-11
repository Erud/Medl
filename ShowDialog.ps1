# THIS CODE CANNOT BE COPY/PASTED INTO THE CONSOLE. PLEASE SAVE IT AS A FILE AND EXECUTE.
 
# Add required assemblies
Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration
 
# Setup the XAML
[xml]$script:xaml = '<window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" title="Acadiana (Cajun) Flag" height="240" width="320" background="Gray">
 <window.taskbariteminfo>
         <taskbariteminfo></taskbariteminfo>
 </window.taskbariteminfo>
    <grid>
        <img name="image" height="64" width="64"/>
    </grid>
</window>'
 
# Create the form and set variables
$script:window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$xaml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name ($_.Name) -Value $window.FindName($_.Name) -Scope Script }
 
# here's the base64 string of the image
$base64 = "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"
 
 
# Create a streaming image by streaming the base64 string to a bitmap streamsource
$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64)
$bitmap.EndInit()
$bitmap.Freeze()
 
# This is the pic in the middle
$image.source = $bitmap
 
# This is the icon in the upper left hand corner of the app
$window.Icon = $bitmap
 
# This is the toolbar icon and description
$window.TaskbarItemInfo.Overlay = $bitmap
$window.TaskbarItemInfo.Description = $window.Title
 
# Add Exit (Thanks, Ryan!)
$window.Add_Closing({[System.Windows.Forms.Application]::Exit(); Stop-Process $pid})
 
# Make PowerShell Disappear 
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);' 
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru 
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0) 

# Allow input to window for TextBoxes, etc
[System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($window)

# Running this without $appContext and ::Run would actually cause a really poor response.
$window.Show()

# This makes it pop up
$window.Activate()
 
# Create an application context for it to all run within. 
# This helps with responsiveness and threading.
$appContext = New-Object System.Windows.Forms.ApplicationContext 
[void][System.Windows.Forms.Application]::Run($appContext)