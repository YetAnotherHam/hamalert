### env:PSExecutionPolicyPreference = "Unrestricted"
### Script to set one trigger for missing DXCCs
### in HamAlert


#########################################################
#########################################################
### Copy and paste the line below without the # into the
### powershell where you want to run the script to allow
### script execution on your system
###
### $env:PSExecutionPolicyPreference = 'Unrestricted'


#########################################################
#########################################################
### Edit these variables according to your file locations
### Login to hamalert.org with your account credentials
### and copy the session ID from the browsers cookie store

$time = Get-Date -Format HH:mm:ss
Write-Host $time ": Define Variables"

$sessionID = 'session ID from cookie'
$jsonTemplate = 'path to json.txt'
$dxccReferenceFile = 'path to dxcc.csv'
$adifFile = 'path to your logfile in adi'
$mode = "ssb"

### I strongly recommend to test the script first,
### before firing the web requests to the server.
### After the successful test, remove the comment in line
### 106

#########################################################
#########################################################

$time = Get-Date -Format HH:mm:ss
Write-Host $time ": Reading Templates"

### Import JSON template
$json = Get-Content -Raw -Path $jsonTemplate | ConvertFrom-Json

### Read DXCC Reference List
$dxcc_ref = Import-Csv -Delimiter ';' -Path $dxccReferenceFile

$time = Get-Date -Format HH:mm:ss
Write-Host $time ": Importing Logfile"

### Read ADIF-File
$infile = Get-Content -Path $adifFile

### Split infile into array for easier parsing
$data = $infile -split " "

### Define some stuff
$worked = @()

$time = Get-Date -Format HH:mm:ss
Write-Host $time ": Build Web-Session"

### Create the web session
$url = "https://hamalert.org/ajax/trigger_update"
$session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
$cookie = [System.Net.Cookie]::new('PHPSESSID', $sessionID)
$session.Cookies.Add('https://hamalert.org/', $cookie)

$time = Get-Date -Format HH:mm:ss
Write-Host $time ": Parsing Logfile"

### Find DXCCs and bands from ADIF logfile
foreach ($line in $data)
{
    ### Set worked band
    if ($line | Select-String -Pattern 'band')
    {
        $band = $line -split '>'        
    }
    ### Set worked dxcc
    if ($line | Select-String -Pattern 'dxcc')
    {
        $dxcc = $line -split '>'        
    }
    ### At end of adif record, add worked dxcc and band to worked list 
    ### and clear band / dxcc for next lines
    if ($line | Select-String -Pattern '<EOR>')
    {
        $worked += New-Object -TypeName psobject -Property @{dxcc=$dxcc[1];band=$band[1].ToLower()}
        $band = ""
        $dxcc = ""
    }
}

### sort worked records
#$worked = $worked | Sort-Object
$triggercount = 0

### check all / desired bands for DXCCs

$time = Get-Date -Format HH:mm:ss
Write-Host $time ": Creating Trigger"

[System.Collections.ArrayList]$wanted_dxccs = $dxcc_ref.dxcc
$trigger = $json.psobject.copy()
$trigger.conditions.mode = $mode
$trigger.conditions.dxcc = $dxcc_ref.dxcc
$trigger.conditions.band = $band
$trigger.comment = "new dxcc"

$band_dxccs = @()
$band_dxccs += $worked | Select-Object -Property dxcc

if ($band_dxccs.Count -gt 0)
{
    foreach ($worked_dxcc in $band_dxccs)
    {
        #Write-Host 'Removing worked DXCC: '$worked_dxcc.dxcc' from wanted DXCCs'
        $wanted_dxccs.Remove($worked_dxcc.dxcc)
    }

$trigger.conditions.dxcc = $wanted_dxccs
    
}
### Convert dxccs from string to integer
[int[]] $trigger.conditions.dxcc = $trigger.conditions.dxcc
if ($trigger.conditions.dxcc.Count -gt 0)
{
    $body = $trigger | ConvertTo-Json
    ### Uncomment next line to send the request to the server
    #Invoke-WebRequest -Uri $url -WebSession $session -Method Post -ContentType 'application/json' -Body $body
}
