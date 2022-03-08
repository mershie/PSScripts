#Create new AD user using a import-csv

$ADUsers = Import-csv C:\Users\ecatapang.BEL\Documents\Script\add-aduser-import2.csv

foreach ($User in $ADUsers)
{

       $Username = $User.Username
       $Password = $User.Password
       $Firstname = $User.FirstName
       $Lastname = $User.LastName
       $Department = $User.Department
       $OU = $User.OU
       $Description = $User.Description
       $Title = $User.Title
       $Email = $User.Email
       #$UPN = $User.UserPrincipalName
       #$Extension = $User.telephone
       $Mobile = $User.MobilePhone
       $Company = $User.Company
       $Address = $User.Street
       $City = $User.City
       $State = $User.State
       $ZipCode = $User.PostalCode
       $Country = $User.Country

       #Check if the user account already exists in AD
       if (Get-ADUser -F {SamAccountName -eq $Username})
       {
               #If user does exist, output a warning message
               Write-Warning "A user account $Username has already exist in Active Directory."
       }
       else
       {
              #If a user does not exist then create a new user account
          
        #Account will be created in the OU listed in the $OU variable in the CSV file; don’t forget to change the domain name in the"-UserPrincipalName" variable
            New-ADUser `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@bluepackmarketing.com" `
            -Name "$Firstname $Lastname" `
            -GivenName $Firstname `
            -Surname $Lastname `
            -Enabled $True `
            -Description $Description `
            -ChangePasswordAtLogon $False `
            -DisplayName "$Firstname $Lastname" `
            -EmailAddress $Email `
            -Title $Title `
            -Department $Department `
            -Company $Company `
            -State $State `
            -Path $OU `
            -AccountPassword (convertto-securestring $Password -AsPlainText -Force)

       }
}
