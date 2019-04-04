
# List certificates
# dir cert:\localmachine\my

# Usage: createsite.ps1 -hostname localhost -iisSiteName NewWebsite -iisAppPoolName NewWebsiteAppPool -certHash A29A3DD5B1D6BAEDF002F5EF6816EB5633835E40

Param(
    [string]$wwwroot = "C:\inetpub\wwwroot\", 
    [string]$hostname = "localhost", 
    [string]$iisSiteName = "NewWebsite", 
    [string]$iisAppPoolName = "DefaultAppPool", 
    [string]$certHash = ""
)


$directoryPath = $wwwroot + $iisSiteName

$IISWebsitePath = "iis:\Sites\$iisSiteName"
$IISAppPoolPath = "IIS:\AppPools\$iisAppPoolName"


Import-Module "WebAdministration"


Write-Host "hostname: "$hostname
Write-Host "iisSiteName: "$iisSiteName
Write-Host "iisAppPoolName: "$iisAppPoolName
Write-Host "certHash: "$certHash

# remove default site if exists
# if ((Test-Path "iis:\Sites\Default Web Site") -eq $True) { 
#     Remove-WebSite -Name "Default Web Site"
# }

# check if exists a certificate for the specified hostname
if ([string]::IsNullOrEmpty($certHash)) {
    $certHash = (Get-ChildItem cert:\LocalMachine\My | where-object { $_.Subject -like "*$hostname*" } | Select-Object -First 1).Thumbprint
}

# create site folder
if ((Test-Path $directoryPath) -eq $False) { 
    New-Item $directoryPath -type Directory
}
else {
    Write-Host "folder $directoryPath already exists."
}

# create iis website
if ((Test-Path $IISWebsitePath) -eq $False) { 
    $bindings = @(
        @{protocol = "http"; bindingInformation = "*:80:" + $hostname },
        @{protocol = "https"; bindingInformation = "*:443:" + $hostname }
    )
    New-Item $IISWebsitePath -bindings $bindings -physicalPath $directoryPath

    if (-not ([string]::IsNullOrEmpty($certHash))) {
        # get the web binding of the site
        $binding = Get-WebBinding -Name $iisSiteName -Protocol "https"
    
        # set the ssl certificate
        $binding.AddSslCertificate($certHash, "my")
    }
}
else {
    Write-Host "website $iisSiteName already exists."
}

# create iis app pool
if ((Test-Path $IISAppPoolPath) -eq $False) {
    New-Item $IISAppPoolPath
}
else {
    Write-Host "application pool $iisAppPoolName already exists."
}

# set applicatio pool to website
Set-ItemProperty IIS:\Sites\$iisSiteName -name applicationPool -value $iisAppPoolName


# Set-Content $directoryPath\Default.html "My Dockerization works!"


# enable anonymous authentication
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name Enabled -Value True -PSPath $IISWebsitePath

