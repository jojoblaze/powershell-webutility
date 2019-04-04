# physical path to the certificate .cer file
param([string]$certificatePath = "")

$ErrorActionPreference = "Stop"

if ((Test-Path $certificatePath) -eq $False) { 
    Write-Host "cannot find certificate at path $certificatePath."
    exit
}

$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import($certificatePath)
$bin = $cert.GetRawCertData()
$base64Value = [System.Convert]::ToBase64String($bin)
$bin = $cert.GetCertHash()
$base64Thumbprint = [System.Convert]::ToBase64String($bin)
$keyid = [System.Guid]::NewGuid().ToString()
#echo "base64Thumbprint" $base64Thumbprint,'*******' "keyid" $keyid ,**********, "base64Value" $base64Value  

$jsonObj = @{customKeyIdentifier = $base64Thumbprint; keyId = $keyid; type = "AsymmetricX509Cert"; usage = "Verify"; value = $base64Value }
$keyCredentials = ConvertTo-Json @($jsonObj) | Out-File "keyCredentials.txt"
$cert.Thumbprint
