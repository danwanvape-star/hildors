[CmdletBinding()]
param(
    [ValidateSet('DebugApk', 'ReleaseBundle')][string]$Mode = 'DebugApk',
    [Parameter(Mandatory = $true)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$BuildName,
    [Parameter(Mandatory = $true)][ValidateRange(1, 2100000000)][int]$BuildNumber,
    [string]$Flutter = 'flutter'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if ($Mode -eq 'ReleaseBundle') {
    foreach ($name in @('HILDORS_UPLOAD_STORE_FILE', 'HILDORS_UPLOAD_STORE_PASSWORD', 'HILDORS_UPLOAD_KEY_ALIAS', 'HILDORS_UPLOAD_KEY_PASSWORD')) {
        if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
            throw "Missing $name. Release has no debug-signing fallback."
        }
    }
    $storePath = [Environment]::GetEnvironmentVariable('HILDORS_UPLOAD_STORE_FILE')
    if (-not [IO.Path]::IsPathRooted($storePath) -or -not (Test-Path -LiteralPath $storePath -PathType Leaf)) {
        throw 'Upload keystore must be an existing absolute external path.'
    }
}
$kind = if ($Mode -eq 'ReleaseBundle') { 'appbundle' } else { 'apk' }
$buildMode = if ($Mode -eq 'ReleaseBundle') { '--release' } else { '--debug' }
Push-Location $projectRoot
try {
    & $Flutter build $kind $buildMode "--build-name=$BuildName" "--build-number=$BuildNumber" '--dart-define=HILDORS_RELEASE_PROFILE=us_free' '--dart-define=HILDORS_API_BASE_URL=https://api.hildors.com'
    if ($LASTEXITCODE -ne 0) { throw "Flutter build failed (exit $LASTEXITCODE)." }
    $relativeArtifact = if ($Mode -eq 'ReleaseBundle') { 'build/app/outputs/bundle/release/app-release.aab' } else { 'build/app/outputs/flutter-apk/app-debug.apk' }
    $artifact = Join-Path $projectRoot $relativeArtifact
    if (-not (Test-Path -LiteralPath $artifact -PathType Leaf)) { throw 'Expected build artifact missing.' }
    Write-Output $artifact
    Get-FileHash -LiteralPath $artifact -Algorithm SHA256
} finally { Pop-Location }
