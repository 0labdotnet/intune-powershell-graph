#
# Assign all applications in Intune to a group
#

####################################################

#region Load Intune functions from intune-powershell-graph.ps1

. .\intune-graph-functions.ps1

#endregion

####################################################

#region Authentication

write-host

# Checking if authToken exists before running authentication
if($global:authToken){

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

            # Defining User Principal Name if not present

            if($User -eq $null -or $User -eq ""){

            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

            }

        $global:authToken = Get-AuthToken -User $User

        }
}

# Authentication doesn't exist, calling Get-AuthToken function

else {

    if($User -eq $null -or $User -eq ""){

    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host

    }

# Getting the authorization token
$global:authToken = Get-AuthToken -User $User

}

#endregion

####################################################

#region Do the work

####################################################

# Prompting for AAD group, making sure it's valid.

Write-Host
Write-Warning "This will assign all applications in Intune as 'available' to the group you specify here- do so carefully."
Write-Host

$AADGroup = Read-Host -Prompt "Enter the Azure AD Group name where applications will be assigned"

$TargetGroupId = (get-AADGroup -GroupName "$AADGroup").id

    if($TargetGroupId -eq $null -or $TargetGroupId -eq ""){

    Write-Host "AAD Group - '$AADGroup' doesn't exist, please specify a valid AAD Group and try again..." -ForegroundColor Red
    Write-Host
    exit

    }

Write-Host

####################################################

# Now we grab all of the applications in Intune, then loop through and assign them all to $TargetGroupId

$Applications = Get-IntuneApplication

foreach ($Application in $Applications){

	$Assign = Add-ApplicationAssignment -ApplicationId $Application.id -TargetGroupId $TargetGroupId -InstallIntent "available"
	Write-Host "Successfully assigned '$AADGroup' to $($Application.displayName)/$($Application.id) with" $Application.InstallIntent "installation action"

	Write-Host

}

#endregion

####################################################

# Clear out the authToken so you don't accidentally run it against the wrong tenant

Clear-Variable -Name "authToken" -Scope global