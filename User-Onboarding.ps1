#Create a new AD user using a template

$user_template = Get-ADUser -Identity _Template_IT-Coordin -Properties State,Department,Country,City,Description,MemberOf
$user_template.UserPrincipalName = $null

New-ADUser `
    -Instance $user_template `
    -Name 'Elmer Test' `
    -SamAccountName 'etest' `
    -UserPrincipalName 'etest@belusallc.com' `
    -AccountPassword (Read-Host -AsSecureString "Password input") `
    -Enabled $True