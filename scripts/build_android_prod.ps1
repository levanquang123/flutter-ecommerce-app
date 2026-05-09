param(
  [ValidateSet("appbundle", "apk")]
  [string]$Target = "appbundle",

  [string]$DefinesFile = "config/dart_defines/prod.local.json",

  [string]$SymbolsDir = "build/sentry-debug-info"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

if (-not (Test-Path -LiteralPath $DefinesFile)) {
  throw "Missing $DefinesFile. Copy config/dart_defines/prod.example.json to $DefinesFile and fill the production values."
}

$VersionLine = Get-Content -Path "pubspec.yaml" | Select-String -Pattern "^version:\s*(.+)$" | Select-Object -First 1
if (-not $VersionLine) {
  throw "Missing version in pubspec.yaml."
}

$PackageVersion = $VersionLine.Matches[0].Groups[1].Value.Trim()
$SentryRelease = "mobile-client@$PackageVersion"
$SentryDist = if ($PackageVersion -match "\+(.+)$") { $Matches[1] } else { "" }

New-Item -ItemType Directory -Force -Path $SymbolsDir | Out-Null

$flutterArgs = @(
  "build",
  $Target,
  "--release",
  "--split-debug-info=$SymbolsDir",
  "--dart-define-from-file=$DefinesFile"
)

& flutter @flutterArgs
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$CanUploadSentryFiles = $env:SENTRY_AUTH_TOKEN -and $env:SENTRY_ORG -and $env:SENTRY_PROJECT
if (-not $CanUploadSentryFiles) {
  Write-Host "Skipping Sentry debug file upload. Set SENTRY_AUTH_TOKEN, SENTRY_ORG, and SENTRY_PROJECT to enable it."
  exit 0
}

$sentryArgs = @(
  "run",
  "sentry_dart_plugin",
  "--sentry-define=release=$SentryRelease",
  "--sentry-define=symbols_path=$SymbolsDir"
)

if ($SentryDist) {
  $sentryArgs += "--sentry-define=dist=$SentryDist"
}

& dart @sentryArgs
