#VARs
 
#SMTP Host
$SMTPHost = "srv-dc2.bel.local"
#Who is the e-mail from
$FromEmail = "itadmin@belusallc.com"
#Password expiry days
$expireindays = 15
 
#Program File Path
$DirPath = "C:\Scripts\PasswordNotificationEmail"
 
$Date = Get-Date
#Check if program dir is present
$DirPathCheck = Test-Path -Path $DirPath
If (!($DirPathCheck))
{
 Try
 {
 #If not present then create the dir
 New-Item -ItemType Directory $DirPath -Force
 }
 Catch
 {
 $_ | Out-File ($DirPath + "\" + "Log.txt") -Append
 }
}
 
# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired
"$Date - INFO: Importing AD Module" | Out-File ($DirPath + "\" + "Log.txt") -Append
Import-Module ActiveDirectory
"$Date - INFO: Getting users" | Out-File ($DirPath + "\" + "Log.txt") -Append
#$users = Get-Aduser -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress -filter { (Enabled -eq 'True') -and (PasswordNeverExpires -eq 'False') } | Where-Object { $_.PasswordExpired -eq $False }
$users = Get-ADUser -SearchBase 'OU=Local_users,DC=bel,DC=local' -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress -filter { (Enabled -eq 'True') -and (PasswordNeverExpires -eq 'False') } | Where-Object { $_.PasswordExpired -eq $False }
 
$maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
 
# Process Each User for Password Expiry
foreach ($user in $users)
{
 $Name = (Get-ADUser $user | ForEach-Object { $_.Name })
 Write-Host "Working on $Name..." -ForegroundColor White
 Write-Host "Getting e-mail address for $Name..." -ForegroundColor Yellow
 $emailaddress = $user.emailaddress
 If (!($emailaddress))
 {
 Write-Host "$Name has no E-Mail address listed, sending email to Service Desk..." -ForegroundColor Red
 Try
 {
 #$emailaddress = (Get-ADUser $user -Properties proxyaddresses | Select-Object -ExpandProperty proxyaddresses | Where-Object { $_ -cmatch '^SMTP' }).Trim("SMTP:")
 $emailaddress = "servicedesk@belusallc.com"
 }
 Catch
 {
 $_ | Out-File ($DirPath + "\" + "Log.txt") -Append
 }
 If (!($emailaddress))
 {
 Write-Host "$Name has no email addresses to send an e-mail to!" -ForegroundColor Red
 #Don't continue on as we can't email $Null, but if there is an e-mail found it will email that address
 "$Date - WARNING: No email found for $Name" | Out-File ($DirPath + "\" + "Log.txt") -Append
 }
 
 }
 #Get Password last set date
 $passwordSetDate = (Get-ADUser $user -properties * | ForEach-Object { $_.PasswordLastSet })
 #Check for Fine Grained Passwords
 $PasswordPol = (Get-ADUserResultantPasswordPolicy $user)
 if (($PasswordPol) -ne $null)
 {
 $maxPasswordAge = ($PasswordPol).MaxPasswordAge
 }
 
 $expireson = $passwordsetdate + $maxPasswordAge
 $today = (get-date)
 #Gets the count on how many days until the password expires and stores it in the $daystoexpire var
 $daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days
 
 If (($daystoexpire -ge "0") -and ($daystoexpire -lt $expireindays))
 {
 "$Date - INFO: Sending expiry notice email to $Name" | Out-File ($DirPath + "\" + "Log.txt") -Append
 Write-Host "Sending Password expiry email to $name" -ForegroundColor Yellow
 
 $SmtpClient = new-object system.net.mail.smtpClient
 $MailMessage = New-Object system.net.mail.mailmessage
 $attach1 = 'C:\Scripts\PasswordNotificationEmail\changePW-CyberArk.png'
 $attach2 = 'C:\Scripts\PasswordNotificationEmail\changePW-Windows.png'
 $attach3 = 'C:\Scripts\PasswordNotificationEmail\forgotPW-CyberArk.png'
 
 #Who is the e-mail sent from
 $mailmessage.From = $FromEmail
 #SMTP server to send email
 $SmtpClient.Host = $SMTPHost
 ########################################################
 #Disabl Secure Connection
 #SMTP SSL
 ##$SMTPClient.EnableSsl = $true
 ########################################################
 #SMTP credentials
 $SMTPClient.Credentials = $cred
 #Send e-mail to the users email
 $mailmessage.To.add("$emailaddress")
 #Email subject
 $mailmessage.Subject = "Your password will expire in $daystoexpire days"
 ##########################################################
 #Disable the notification email
 #Notification email on delivery / failure
 ##$MailMessage.DeliveryNotificationOptions = ("onSuccess", "onFailure")
 ##########################################################
 #Send e-mail with high priority
 $MailMessage.Priority = "High"
 $MailMessage.Attachments.Add($attach1)
 $MailMessage.Attachments.Add($attach2)
 $MailMessage.Attachments.Add($attach3)
 $mailmessage.Body =
 "Dear $Name,
Your Domain password will expire in $daystoexpire days. Please change it as soon as possible.
 
To change your password, follow a method below:

1. Via CyberArk Portal (See the attachment).
 a. Log into mfa.belusallc.com using your email account.
 b. Select the Authentication method, we suggest Mobile Authentication.
 c. Once logged in, go to the Account tab, then select Authentication factors.
 d. Click the EDIT button in the PASSWORD column.
 e. Type your Current Password, and then the New Password and Confirm New Password. Click OK.
 f. Once changed, please make sure you also update password for O365 (Outlook, Web), Microsoft Teams, AmazonConnect, VPN, RDP, PC Login.

2. Selecting 'Forgot your password?' option in CyberArk.
 a. Log into mfa.belusallc.com using your email account.
 b. In the password dialog box, click on 'Forget your password?' link
 c. Select 'Text Message' as the second authentication method, then hit 'Send me a message'
 d. Check your phone for the code and put it in the 'Enter Code:' box, click Authenticate
 e. Enter the new password twice, New Password and Confirm Password.
 f. Once changed, please make sure you also update password for O365 (Outlook, Web), Microsoft Teams, AmazonConnect, VPN, RDP, PC Login.
  
3. On your Windows computer.
 a. If you are not in the office, logon and connect to VPN. 
 b. Log onto your computer as usual and make sure you are connected to the internet.
 c. Press Ctrl-Alt-Del and click on ""Change Password"".
 d. Fill in your old password and set a new password.  See the password requirements below.
 e. Press OK to return to your desktop. 
 
The new password must meet the minimum requirements set forth in our corporate policies including:
 1.	It must be at least 8 characters long.
 2.	It must contain at least one character from 3 of the 4 following groups of characters:
      a.  Uppercase letters (A-Z)
      b.  Lowercase letters (a-z)
      c.  Numbers (0-9)
      d.  Symbols (!@#$%^&*...)
 3.	It cannot match any of your past 24 passwords.
 4.	It cannot contain characters which match 3 or more consecutive characters of your username.
 5.	You cannot change your password more often than once in a 24 hour period.
 
If you have any questions please contact our Support team at servicedesk@belusallc.com or call us at (305)593-0911 Ext. 4357
 
Thanks,
BEL USA Service Desk Team
servicedesk@belusallc.com
(305)593-0911 Ext. 4357"

 Write-Host "Sending E-mail to $emailaddress..." -ForegroundColor Green
 Try
 {
 $Smtpclient.Send($mailmessage)
 }
 Catch
 {
 $_ | Out-File ($DirPath + "\" + "Log.txt") -Append
 }
 }
 Else
 {
 "$Date - INFO: Password for $Name not expiring for $daystoexpire days" | Out-File ($DirPath + "\" + "Log.txt") -Append
 Write-Host "Password for $Name does not expire for $daystoexpire days" -ForegroundColor White
 }
}