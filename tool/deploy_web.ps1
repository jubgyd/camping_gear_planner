# Build the Flutter web release and upload it to the Hetzner server over scp.
# Usage:  ./tool/deploy_web.ps1 -Server root@camp.example.tld -Dest /var/www/camp
param(
    [Parameter(Mandatory = $true)][string]$Server,
    [string]$Dest = "/var/www/camp"
)
$flutter = "D:\Flutter\flutter\bin\flutter.bat"
& $flutter build web --release
if ($LASTEXITCODE -ne 0) { Write-Error "flutter build web failed"; exit 1 }

# Upload the contents of build/web into $Dest on the server.
# (-r recurses; the trailing /. copies the directory contents, not the folder.)
scp -r "build/web/." "${Server}:${Dest}/"
if ($LASTEXITCODE -ne 0) { Write-Error "scp upload failed"; exit 1 }
Write-Host "Deployed to ${Server}:${Dest}"
