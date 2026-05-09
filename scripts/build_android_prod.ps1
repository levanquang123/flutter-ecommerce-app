param(
  [ValidateSet("appbundle", "apk")]
  [string]$Target = "appbundle",

  [string]$DefinesFile = "config/dart_defines/prod.local.json"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

if (-not (Test-Path -LiteralPath $DefinesFile)) {
  throw "Missing $DefinesFile. Copy config/dart_defines/prod.example.json to $DefinesFile and fill the production values."
}

$flutterArgs = @(
  "build",
  $Target,
  "--release",
  "--dart-define-from-file=$DefinesFile"
)

& flutter @flutterArgs
