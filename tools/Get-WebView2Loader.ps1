[CmdletBinding()]
param(
    [string]$Version = "1.0.4191.47"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$TempRoot = Join-Path $ProjectRoot ".tmp\Microsoft.Web.WebView2-$Version"
$PackageFile = Join-Path $TempRoot "Microsoft.Web.WebView2.$Version.nupkg"
$ZipFile = Join-Path $TempRoot "Microsoft.Web.WebView2.$Version.zip"
$ExtractDir = Join-Path $TempRoot "package"
$PackageUri = "https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/$Version"

Write-Host "WebView2.au3 - WebView2Loader setup"
Write-Host "Package: Microsoft.Web.WebView2 $Version"
Write-Host "Source : $PackageUri"

if (Test-Path $TempRoot) {
    Remove-Item $TempRoot -Recurse -Force
}
New-Item $TempRoot -ItemType Directory -Force | Out-Null

Invoke-WebRequest -Uri $PackageUri -OutFile $PackageFile -UseBasicParsing
Copy-Item $PackageFile $ZipFile -Force
Expand-Archive -Path $ZipFile -DestinationPath $ExtractDir -Force

$Files = @(
    @{
        Source = Join-Path $ExtractDir "runtimes\win-x86\native\WebView2Loader.dll"
        Target = Join-Path $ProjectRoot "bin\x86\WebView2Loader.dll"
    },
    @{
        Source = Join-Path $ExtractDir "runtimes\win-x64\native\WebView2Loader.dll"
        Target = Join-Path $ProjectRoot "bin\x64\WebView2Loader.dll"
    }
)

foreach ($File in $Files) {
    if (-not (Test-Path $File.Source)) {
        throw "Loader not found in NuGet package: $($File.Source)"
    }

    $Signature = Get-AuthenticodeSignature -FilePath $File.Source
    if ($Signature.Status -ne "Valid") {
        throw "Authenticode signature validation failed for $($File.Source): $($Signature.Status)"
    }

    New-Item (Split-Path -Parent $File.Target) -ItemType Directory -Force | Out-Null
    Copy-Item $File.Source $File.Target -Force

    $Hash = Get-FileHash -Path $File.Target -Algorithm SHA256
    Write-Host "Installed: $($File.Target)"
    Write-Host "SHA256   : $($Hash.Hash)"
}

$ThirdPartyDir = Join-Path $ProjectRoot "third_party\Microsoft.Web.WebView2"
New-Item $ThirdPartyDir -ItemType Directory -Force | Out-Null

$LicenseCandidates = @(
    (Join-Path $ExtractDir "LICENSE.txt"),
    (Join-Path $ExtractDir "LICENSE")
)
foreach ($Candidate in $LicenseCandidates) {
    if (Test-Path $Candidate) {
        Copy-Item $Candidate (Join-Path $ThirdPartyDir (Split-Path -Leaf $Candidate)) -Force
        break
    }
}

$Hashes = @()
foreach ($File in $Files) {
    $Hash = Get-FileHash -Path $File.Target -Algorithm SHA256
    $Hashes += "SHA256  $($Hash.Hash)  $($File.Target.Substring($ProjectRoot.Length + 1))"
}
$Hashes | Set-Content -Path (Join-Path $ThirdPartyDir "WebView2Loader-SHA256.txt") -Encoding UTF8

Write-Host ""
Write-Host "WebView2Loader.dll is ready for x86 and x64 AutoIt."
