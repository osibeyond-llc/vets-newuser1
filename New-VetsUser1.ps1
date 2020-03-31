

<#
This function performs the following tasks:
- Prompts for input of needed information
- Checks AD for existing username, exits if found
- Creates new mailbox and AD user account in the correct OU
- Adds mailbox to Clarksville database
- Sets the password to a temporary default and sets requirement to change at first login
- Sets Custom Attribute 1 to VETS-All
- Sets Custom Attribute 5 to Employee or Affiliate
- Sets Custom Attribute 14 to user's alternate phone number
- Sets Custom Attribute 15 to user's alternate email address
- Adds new user to ChaplainsList Distribution Group
- Sends instructions for setting up mailbox access to new user
- Sends instructions for accessing SharePoint to user 
#>

$Password = "Password1!"
$secure_string_pwd = convertto-securestring $Password -asplaintext -force

$Type = Read-Host "
(1) - Employee
(2) - Affiliate
Type?"

Switch ($Type){
1 {$Type = "Employee"}
2 {$Type = "Affiliate"}
}

# This is not used yet, need code to add user without mailbox via AD modules.
# Mailbox will be created but instructions will not be sent.
If ($Type -eq "Affiliate") {
    $NeedsMailbox = Read-Host "
    A mailbox will be created.
    Send mailbox instructions to affiliate?
    1 - Yes
    2 - No
    ?"
}

If ($Type -eq "Employee") {
    $NeedsMailbox = 1
}

If ($Type -eq "Affiliate") {
    $NeedsSharePoint = Read-Host "
    SharePoint access must be configured manually after this script is run.
    Send SharePoint access instructions to affiliate?
    (1) - Yes
    (2) - No
    ?"
}

If ($Type -eq "Employee") {
    $NeedsSharePoint = 1
}

$FirstName = read-host "First name?"
$Initials = read-host "Middle initial?"
$LastName = read-host "Last name?"

$Alias = read-host "Alias (username)?"
While (Test-ADUserName $Alias) {
Write-Host "Username already in use - choose a different username." -ForegroundColor DarkYellow
$Alias = read-host "Alias (username)?"
}

$UPN = "$Alias@ad.vets-inc.com"
$AltEmail = Read-Host "Alternate email address (not vets-inc.com)?"
$AltPhone = Read-Host "Alternate phone number?"
$Office = read-host "

1 - Clarksville
2 - Reston
3 - O'Fallon
4 - Other or Off-Site

Office number?"

Switch ($Office){
1 {$Office = "Clarksville"}
2 {$Office = "Reston"}
3 {$Office = "O'Fallon"}
4 {$Office = "Off-Site"}
}

$Database = "Mailbox Database 1394102387"
	
$OU = "ad.vets-inc.com/$Office/Users"

$NM1 = @{
        Name = "$FirstName $LastName";
        Alias = $Alias;
        OrganizationalUnit = $OU;
        Database = $Database;
        UserPrincipalName = $UPN;
        SamAccountName = $Alias;
        FirstName = $FirstName;
        Initials = $Initials;
        LastName = $LastName;
        Password = $secure_string_pwd;
        ResetPasswordOnNextLogon = $true
        }
New-Mailbox @NM1

Start-Sleep -seconds 15

$SM1 = @{
        Identity = $Alias;
        CustomAttribute1 = "VETS-All";
        CustomAttribute5 = $Type;
        CustomAttribute14 = $AltPhone;
        CustomAttribute15 = $AltEmail
        }
Set-Mailbox @SM1

$AD1 = @{
        Identity = 'ad.vets-inc.com/users/ChaplainsList';
        Member = "$OU/$FirstName $LastName"
        }
Add-DistributionGroupMember @AD1 -BypassSecurityGroupManagerCheck

$Sender = 'IT@vets-inc.com'

If ($NeedsMailbox -eq 1) {

$Body = "
$FirstName,

Your VETS email account has been set up with the address $Alias@vets-inc.com .  You will be prompted to change your password the first time you log on.  The easiest way to complete the password change and gain immediate access to your mailbox is to use the VETS Outlook Web App:  https://mail.vets-inc.com .

Username: $Alias
Temporary Password: $Password


Please let us know if you need any assistance.

--------------------------------------
To contact the VETS Service Desk:
help@vets-inc.com
855-483-8746  x140
--------------------------------------

"

send-mailmessage -to $AltEmail -subject 'Your VETS email account is ready' -smtpserver 'vets-mail1.ad.vets-inc.com' -from $Sender -Body $Body -Cc $Sender
Start-Sleep -Seconds 10
}

If ($NeedsSharePoint -eq 1) {
$Body = "
$FirstName,

Please observe the following instructions to avoid the most common problems when accessing SharePoint.  If you have tried these and have trouble using SharePoint, please contact us at the email address below.

- Use the same credentials as you use for your VETS email account.

- The username format must be `'vets-ad\username`', where `'username`' is the first part of the email address before the @ sign.

- Internet Explorer must be used.

- https must be used.  The correct URL is https://sharepoint.vets-inc.com.

- The domain vets-inc.com must be in the Compatibility View list.  Go to https://sharepoint.vets-inc.com, then click the gear icon in the upper right corner of the Internet Explorer window, then click Compatibility View settings.  If vets-inc.com doesn`’t appear in the list, click Add so the domain vets-inc.com is added to the list.  The browser window should refresh and display the site.

- Certain networks have strict controls in place that can prevent a computer from connecting to our SharePoint site.  You may need to use a computer that is not connected to the Internet through a restricted network.

Please let us know if you need any assistance.

--------------------------------------
To contact the VETS Service Desk:
help@vets-inc.com
855-483-8746  x140
--------------------------------------

--
Dave Winn
IT Manager
Veterans Enterprise Technology Solutions, Inc.
434-374-5899 x110
dwinn@vets-inc.com"

send-mailmessage -to $Alias@vets-inc.com -subject 'SharePoint access instructions' -smtpserver 'vets-mail1.ad.vets-inc.com' -from $Sender -Body $Body -Cc $Sender
}
