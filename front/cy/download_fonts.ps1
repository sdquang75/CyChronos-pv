# Set working directories
$tempDir = Join-Path $PSScriptRoot "temp_fonts"
$fontsDir = Join-Path $PSScriptRoot "assets/fonts"

# Create directories
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Force -Path $tempDir
}
if (-not (Test-Path $fontsDir)) {
    New-Item -ItemType Directory -Force -Path $fontsDir
}

# Define font families to download from gwfh (google webfonts helper)
$families = @(
    @{
        Name = "hanken-grotesk"
        Url = "https://gwfh.mranftl.com/api/fonts/hanken-grotesk?download=zip&subsets=latin&variants=regular,600,700,800"
    },
    @{
        Name = "inter"
        Url = "https://gwfh.mranftl.com/api/fonts/inter?download=zip&subsets=latin&variants=regular,500"
    },
    @{
        Name = "jetbrains-mono"
        Url = "https://gwfh.mranftl.com/api/fonts/jetbrains-mono?download=zip&subsets=latin&variants=regular,500"
    },
    @{
        Name = "noto-sans-jp"
        Url = "https://gwfh.mranftl.com/api/fonts/noto-sans-jp?download=zip&subsets=japanese&variants=regular,500,700"
    }
)

foreach ($family in $families) {
    $zipPath = Join-Path $tempDir "$($family.Name).zip"
    $extractPath = Join-Path $tempDir $family.Name
    
    Write-Host "Downloading $($family.Name)..."
    & curl.exe -L -s -o $zipPath $family.Url
    
    Write-Host "Extracting $($family.Name)..."
    if (Test-Path $extractPath) {
        Remove-Item -Recurse -Force $extractPath
    }
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
}

# Copy and rename fonts to assets/fonts/
Write-Host "Copying and renaming fonts to assets/fonts/..."

function Copy-Font($pattern, $destName) {
    $file = Get-ChildItem -Path $tempDir -Filter $pattern -Recurse | Select-Object -First 1
    if ($file) {
        Copy-Item -Path $file.FullName -Destination (Join-Path $fontsDir $destName) -Force
        Write-Host "Copied and renamed $destName successfully."
    } else {
        Write-Warning "Could not find font matching pattern: $pattern"
    }
}

# Hanken Grotesk
Copy-Font "*hanken-grotesk*regular.ttf" "HankenGrotesk-Regular.ttf"
Copy-Font "*hanken-grotesk*600.ttf" "HankenGrotesk-SemiBold.ttf"
Copy-Font "*hanken-grotesk*700.ttf" "HankenGrotesk-Bold.ttf"
Copy-Font "*hanken-grotesk*800.ttf" "HankenGrotesk-ExtraBold.ttf"

# Inter
Copy-Font "*inter*regular.ttf" "Inter-Regular.ttf"
Copy-Font "*inter*500.ttf" "Inter-Medium.ttf"

# JetBrains Mono
Copy-Font "*jetbrains-mono*regular.ttf" "JetBrainsMono-Regular.ttf"
Copy-Font "*jetbrains-mono*500.ttf" "JetBrainsMono-Medium.ttf"

# Noto Sans JP
Copy-Font "*noto-sans-jp*regular.ttf" "NotoSansJP-Regular.ttf"
Copy-Font "*noto-sans-jp*500.ttf" "NotoSansJP-Medium.ttf"
Copy-Font "*noto-sans-jp*700.ttf" "NotoSansJP-Bold.ttf"

# Clean up
Write-Host "Cleaning up temporary files..."
Remove-Item -Recurse -Force $tempDir

Write-Host "Font update completed successfully!"
