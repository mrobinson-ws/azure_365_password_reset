#Requires -Module AzureAD

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

try {
    Write-Verbose -Message "Testing connection to Azure AD"
    Get-AzureAdDomain -ErrorAction Stop | Out-Null
    Write-Verbose -Message "Already connected to Azure AD"
}
catch {
    Write-Verbose -Message "Connecting to Azure AD"
    Connect-AzureAD
}

  #Pull All Azure AD Users and Store In Hash Table Instead Of Calling Get-AzureADUser Multiple Times
  Write-Verbose "Pulling Users, Storing in a Hash Table"
  $allUsers = @{}    
  foreach ($user in Get-AzureADUser -All $true){ $allUsers[$user.UserPrincipalName] = $user }
  Write-Verbose "Hash Table Filled"

#Request Username(s) To Be Terminated From Script Runner (Hold Ctrl To Select Multiples)
$usernames = $allUsers.Values | Where-Object {$_.AccountEnabled } | Sort-Object DisplayName | Select-Object -Property DisplayName,UserPrincipalName | Out-Gridview -Passthru -Title "Please select the user(s) to be terminated" | Select-Object -ExpandProperty UserPrincipalName
#Kill Script If Ok Button Not Clicked
if ($null -eq $usernames) { Throw }
##### Start User(s) Loop #####
foreach ($username in $usernames) {
    $PasswordEntry = New-Object System.Windows.Forms.Form
    $PasswordEntry.Text = "Password Entry"
    $PasswordEntry.Size = New-Object System.Drawing.Size(300,200)
    $PasswordEntry.StartPosition = 'CenterScreen'

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75,120)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $PasswordEntry.AcceptButton = $okButton
    $PasswordEntry.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(150,120)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $PasswordEntry.CancelButton = $cancelButton
    $PasswordEntry.Controls.Add($cancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,30)
    $label.Text = "Please enter the new password for $username below"
    $PasswordEntry.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10,60)
    $textBox.Size = New-Object System.Drawing.Size(260,20)
    $PasswordEntry.Controls.Add($textBox)

    $PasswordEntry.Topmost = $true

    $PasswordEntry.Add_Shown({$textBox.Select()})
    $result = $PasswordEntry.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $password = $textBox.Text
        $securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    }
    else { Throw }
    $UserInfo = $allusers[$username]
    Set-AzureADUserPassword -ObjectID $UserInfo.ObjectID -Password $securepassword -ForceChangePasswordNextLogin $false
}