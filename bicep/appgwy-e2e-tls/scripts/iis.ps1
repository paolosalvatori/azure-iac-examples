param (
    [string]$PfxThumbprint,
    [string]$WebSiteName = "Default Web Site"
)

Import-Module WebAdministration

try {
$ErrorActionPreference = 'Stop'

# create https binding
if (!$(Get-WebBinding -Name $WebSiteName -IPAddress * -Port 443 -Protocol https)) {
    New-WebBinding -Name $WebSiteName -IPAddress * -Port 443 -Protocol https
}

# bind certificate to SSL port
if (!$(Get-Item -Path $providerPath)) {
    Get-Item $certPath | New-Item $providerPath
}

# stop all sites & start
Get-Website | Stop-Website | Start-WebSite

# allow inbound 443 traffic
New-NetFirewallRule -Name 'Allow-Inbound-HTTPS' `
    -DisplayName 'Allow-Inbound-HTTPS' `
    -Description 'Allow inbound traffic on port 443 (HTTPS)' `
    -Enabled True `
    -Profile Any `
    -Direction Inbound `
    -Action Allow `
    -LocalPort 443 `
    -Protocol TCP
} catch {
    "Error: $_"
}