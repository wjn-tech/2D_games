$ErrorActionPreference = "Stop"

Write-Host "Fetching latest release info from GitHub..."
try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/TakWolf/ark-pixel-font/releases/latest" -Headers @{ "User-Agent" = "PowerShell" }
    $asset = $response.assets | Where-Object { $_.name -match "ark-pixel-font-12px-monospaced-otf-v.*\.zip" } | Select-Object -First 1

    if ($asset) {
        Write-Host "Found font: $($asset.name)"
        $zipPath = Join-Path $PSScriptRoot "..\assets\fonts\ark-pixel.zip"
        
        Write-Host "Downloading to $zipPath..."
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -Headers @{ "User-Agent" = "PowerShell" }
        
        Write-Host "Extracting..."
        Expand-Archive -Path $zipPath -DestinationPath (Join-Path $PSScriptRoot "..\assets\fonts") -Force
        
        Write-Host "Cleaning up..."
        Remove-Item $zipPath
        
        Write-Host "Done! Font installed to assets/fonts/"
    } else {
        Write-Error "Could not find a suitable asset in the latest release."
    }
} catch {
    Write-Error "Failed to download font: $_"
}
