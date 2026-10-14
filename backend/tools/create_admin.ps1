param(
    [Parameter(Mandatory = $true)][string]$Email,
    [Parameter(Mandatory = $true)][string]$FullName
)

$first = Read-Host 'New admin password (12+ characters)' -AsSecureString
$second = Read-Host 'Enter it again' -AsSecureString
$credential = [System.Net.NetworkCredential]::new('', $first)
$confirm = [System.Net.NetworkCredential]::new('', $second)
if ($credential.Password -ne $confirm.Password) {
    throw 'The passwords did not match.'
}

$env:ADMIN_BOOTSTRAP_PASSWORD = $credential.Password
try {
    & php (Join-Path $PSScriptRoot 'create_admin.php') $Email $FullName
    if ($LASTEXITCODE -ne 0) { throw 'Admin account creation failed.' }
}
finally {
    Remove-Item Env:\ADMIN_BOOTSTRAP_PASSWORD -ErrorAction SilentlyContinue
    $credential = $null
    $confirm = $null
    $first = $null
    $second = $null
}
