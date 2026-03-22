# --- Step 1: Get Windows RE location ---
$reagentOutput = reagentc /info

$winRELine = $reagentOutput | Select-String "Windows RE location"
if (-not $winRELine) {
    Write-Error "Windows RE location not found."
    exit
}

# Extract path (remove label + trim)
$winREPath = ($winRELine -split ":")[1].Trim()

Write-Host "Windows RE path: $winREPath"

# --- Step 2: Check BitLocker status ---
$bitlockerEnabled = $false
$recoveryKey = ""

$statusOutput = manage-bde -status C: | Out-String

if ($statusOutput -match "Protection Status:\s+Protection On") {
    $bitlockerEnabled = $true
    Write-Host "BitLocker is ENABLED"
}
else {
    Write-Host "BitLocker is NOT enabled"
}

# --- Step 3: Extract recovery key (Numerical Password) ---
if ($bitlockerEnabled) {
$recoveryKey = (Get-BitLockerVolume -MountPoint "C:").KeyProtector |
    Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" } |
    Select-Object -ExpandProperty RecoveryPassword

Wrtie-Host $recoveryKey
    }

# --- Step 4: Prepare mount directory ---
$mountDir = "C:\mount"
if (-not (Test-Path $mountDir)) {
    New-Item -ItemType Directory -Path $mountDir | Out-Null
}

# --- Step 5: Mount WinRE image ---
# Usually WinRE path ends with Winre.wim already
dism /Mount-Wim /WimFile:$winREPath /index:1 /MountDir:$mountDir

# --- Step 6: Create winpeshi.ini ---
$iniPath = "$mountDir\Windows\System32\winpeshi.ini"

$iniContent = @"
; Customize this file
[LaunchApps]
wpeinit
"@

Set-Content -Path $iniPath -Value $iniContent -Encoding ASCII

Write-Host "winpeshi.ini created"

# --- Step 7: Create recovery key file ---
if ($bitlockerEnabled -and $recoveryKey) {
    $txtPath = "$mountDir\Windows\System32\recovery_key.txt"
    Set-Content -Path $txtPath -Value $recoveryKey -Encoding ASCII

    Write-Host "Recovery key file created"
}
