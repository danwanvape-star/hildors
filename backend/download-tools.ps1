$ErrorActionPreference = 'Stop'
# Small pinned Windows build from the provider linked by ffmpeg.org.
$taskDirectory = Join-Path $PSScriptRoot 'data/tools'
New-Item -ItemType Directory -Force $taskDirectory | Out-Null
$taskArchive = Join-Path $taskDirectory 'ffmpeg.7z'
$taskExpectedHash = '49a73bdf0850092a252ac4641d922f3048d63ed113e196cc65ce1e4f7fb33e85'
$taskUrl = 'https://www.gyan.dev/ffmpeg/builds/packages/ffmpeg-9.0.1-essentials_build.7z'
if (!(Test-Path -LiteralPath $taskArchive) -or (Get-FileHash -LiteralPath $taskArchive -Algorithm SHA256).Hash -ne $taskExpectedHash) {
    & curl.exe -L --fail --silent --show-error --max-time 600 -C - $taskUrl -o $taskArchive
    if ($LASTEXITCODE -ne 0) { throw 'Tool download incomplete; no archive extracted.' }
}
if ((Get-FileHash -LiteralPath $taskArchive -Algorithm SHA256).Hash -ne $taskExpectedHash) { throw 'Checksum mismatch; no archive extracted.' }
$taskExtractor = Join-Path $taskDirectory '7zr.exe'
if (!(Test-Path -LiteralPath $taskExtractor)) {
    & curl.exe -L --fail --silent --show-error --max-time 60 'https://www.7-zip.org/a/7zr.exe' -o $taskExtractor
    if ($LASTEXITCODE -ne 0) { throw 'Extractor download failed.' }
}
$taskListing = & $taskExtractor l -slt $taskArchive
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect archive.' }
$taskEntries = $taskListing | Where-Object { $_ -like 'Path = *' } | Select-Object -Skip 1
foreach ($taskEntry in $taskEntries) {
    $taskEntry = $taskEntry.Substring(7).Replace('\', '/')
    if ($taskEntry -notmatch '^ffmpeg-9\.0\.1-essentials_build(/|$)' -or $taskEntry -match '(^|/)\.\.(/|$)') { throw 'Unexpected archive path.' }
}
& $taskExtractor x $taskArchive "-o$taskDirectory" -y
if ($LASTEXITCODE -ne 0) { throw 'Tool extraction failed.' }
& node (Join-Path $PSScriptRoot 'check-tools.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Tool execution check failed.' }
Write-Output 'FFmpeg archive verified, extracted and ready.'
