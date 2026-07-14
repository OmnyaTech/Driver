param(
  [string]$ApkName = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $repoRoot ".env"

if (-not (Test-Path -LiteralPath $envPath)) {
  throw ".env not found at $envPath"
}

$values = @{}
Get-Content -LiteralPath $envPath | ForEach-Object {
  $line = $_.Trim()
  if (-not $line -or $line.StartsWith("#") -or -not $line.Contains("=")) {
    return
  }

  $index = $line.IndexOf("=")
  $key = $line.Substring(0, $index).Trim()
  $value = $line.Substring($index + 1).Trim().Trim('"').Trim("'")
  $values[$key] = $value
}

foreach ($key in @("SUPABASE_URL", "SUPABASE_ANON_KEY", "TURNSTILE_SITE_KEY")) {
  if (-not $values.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($values[$key])) {
    throw "$key is missing in .env"
  }
}

Push-Location $repoRoot
try {
  if ([string]::IsNullOrWhiteSpace($ApkName)) {
    $pubspec = Get-Content -LiteralPath (Join-Path $repoRoot "pubspec.yaml")
    $versionLine = $pubspec | Where-Object { $_ -match "^version:\s*(.+)$" } | Select-Object -First 1
    if (-not $versionLine) {
      throw "Could not find version in pubspec.yaml"
    }
    $versionName = (($versionLine -replace "^version:\s*", "") -split "\+")[0]
    $ApkName = "driver-v$versionName.apk"
  }

  flutter build apk --release `
    --dart-define="SUPABASE_URL=$($values["SUPABASE_URL"])" `
    --dart-define="SUPABASE_ANON_KEY=$($values["SUPABASE_ANON_KEY"])" `
    --dart-define="TURNSTILE_SITE_KEY=$($values["TURNSTILE_SITE_KEY"])"

  $source = Join-Path $repoRoot "build/app/outputs/flutter-apk/app-release.apk"
  $target = Join-Path $repoRoot "build/app/outputs/flutter-apk/$ApkName"
  Copy-Item -LiteralPath $source -Destination $target -Force
  Get-Item -LiteralPath $target | Select-Object FullName, Length, LastWriteTime
} finally {
  Pop-Location
}
