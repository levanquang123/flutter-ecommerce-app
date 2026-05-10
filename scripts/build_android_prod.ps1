param(
  [ValidateSet("appbundle", "apk")]
  [string]$Target = "appbundle",

  [string]$DefinesFile = "config/dart_defines/prod.local.json",

  [string]$SentryPropertiesFile = "config/sentry/prod.local.properties",

  [string]$SymbolsDir = "build/sentry-debug-info",

  [string]$TargetPlatform = "android-arm,android-arm64"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

if (-not (Test-Path -LiteralPath $DefinesFile)) {
  throw "Missing $DefinesFile. Copy config/dart_defines/prod.example.json to $DefinesFile and fill the production values."
}

if (Test-Path -LiteralPath $SentryPropertiesFile) {
  Get-Content -LiteralPath $SentryPropertiesFile | ForEach-Object {
    $Line = $_.Trim()
    if ($Line -eq "" -or $Line.StartsWith("#")) {
      return
    }

    $Parts = $Line.Split("=", 2)
    if ($Parts.Count -ne 2) {
      return
    }

    $Name = $Parts[0].Trim()
    $Value = $Parts[1].Trim()
    if ($Name -and $Value) {
      [System.Environment]::SetEnvironmentVariable($Name, $Value, "Process")
    }
  }
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
  "--target-platform=$TargetPlatform",
  "--split-debug-info=$SymbolsDir",
  "--dart-define-from-file=$DefinesFile"
)

& flutter @flutterArgs
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$CanUploadSentryFiles = $env:SENTRY_AUTH_TOKEN -and $env:SENTRY_ORG -and $env:SENTRY_PROJECT
if (-not $CanUploadSentryFiles) {
  Write-Host "Skipping Sentry debug file upload. Copy config/sentry/prod.example.properties to $SentryPropertiesFile and fill SENTRY_AUTH_TOKEN, SENTRY_ORG, and SENTRY_PROJECT to enable it."
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
