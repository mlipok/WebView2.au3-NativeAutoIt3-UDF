param(
    [Parameter(Mandatory=$true)][string]$Package,
    [Parameter(Mandatory=$true)][string]$Destination,
    [Parameter(Mandatory=$true)][ValidateSet('x86','x64')][string]$Architecture,
    [Parameter(Mandatory=$true)][string]$Version
)
$ErrorActionPreference = 'Stop'
try {
    if (-not (Test-Path -LiteralPath $Package -PathType Leaf)) { throw 'CAB missing' }
    if (Test-Path -LiteralPath $Destination) { throw 'Extraction destination must be new' }
    New-Item -ItemType Directory -Path $Destination | Out-Null
    & "$env:SystemRoot\System32\expand.exe" $Package '-F:*' $Destination | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "expand failed: $LASTEXITCODE" }
    $executables = @(Get-ChildItem -LiteralPath $Destination -Filter msedgewebview2.exe -Recurse -File)
    if ($executables.Count -ne 1) { throw 'Expected exactly one Runtime executable' }
    $exe = $executables[0]
    $signature = Get-AuthenticodeSignature -LiteralPath $exe.FullName
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
        throw 'Runtime executable Microsoft signature verification failed'
    }
    if ($exe.VersionInfo.FileVersion -ne $Version) { throw 'Unexpected Runtime version' }
    $stream = [IO.File]::OpenRead($exe.FullName)
    $reader = [IO.BinaryReader]::new($stream)
    try {
        $stream.Position = 0x3c
        $offset = $reader.ReadInt32()
        $stream.Position = $offset
        if ($reader.ReadUInt32() -ne 0x4550) { throw 'Invalid PE signature' }
        $machine = $reader.ReadUInt16()
    } finally { $reader.Dispose(); $stream.Dispose() }
    $expected = if ($Architecture -eq 'x64') { 0x8664 } else { 0x14c }
    if ($machine -ne $expected) { throw 'Runtime architecture mismatch' }
    $root = Split-Path -Parent $Destination
    [IO.File]::WriteAllText((Join-Path $root 'ready.txt'), $exe.DirectoryName, [Text.UTF8Encoding]::new($false))
    exit 0
} catch {
    [IO.File]::WriteAllText((Join-Path (Split-Path -Parent $Destination) 'prepare-error.txt'), $_.Exception.Message)
    exit 1
}
