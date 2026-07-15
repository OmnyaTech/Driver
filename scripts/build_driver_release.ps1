param(
  [string]$ApkName = "",
  [switch]$SplitPerAbi
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

  $buildArgs = @(
    "build",
    "apk",
    "--release",
    "--dart-define=SUPABASE_URL=$($values["SUPABASE_URL"])",
    "--dart-define=SUPABASE_ANON_KEY=$($values["SUPABASE_ANON_KEY"])",
    "--dart-define=TURNSTILE_SITE_KEY=$($values["TURNSTILE_SITE_KEY"])"
  )

  if ($values.ContainsKey("DRIVER_APK_URL") -and -not [string]::IsNullOrWhiteSpace($values["DRIVER_APK_URL"])) {
    $buildArgs += "--dart-define=DRIVER_APK_URL=$($values["DRIVER_APK_URL"])"
  }
  if ($SplitPerAbi) {
    $buildArgs += "--split-per-abi"
  }

  & flutter @buildArgs

  if ($SplitPerAbi) {
    $outputDir = Join-Path $repoRoot "build/app/outputs/flutter-apk"
    $versionBase = [System.IO.Path]::GetFileNameWithoutExtension($ApkName)
    $targets = @(
      @{ Source = "app-armeabi-v7a-release.apk"; Suffix = "armeabi-v7a" },
      @{ Source = "app-arm64-v8a-release.apk"; Suffix = "arm64-v8a" },
      @{ Source = "app-x86_64-release.apk"; Suffix = "x86_64" }
    )
    foreach ($item in $targets) {
      $source = Join-Path $outputDir $item.Source
      $target = Join-Path $outputDir "$versionBase-$($item.Suffix).apk"
      Copy-Item -LiteralPath $source -Destination $target -Force
      Get-Item -LiteralPath $target | Select-Object FullName, Length, LastWriteTime
    }
  } else {
    $source = Join-Path $repoRoot "build/app/outputs/flutter-apk/app-release.apk"
    $target = Join-Path $repoRoot "build/app/outputs/flutter-apk/$ApkName"
    Copy-Item -LiteralPath $source -Destination $target -Force
    Get-Item -LiteralPath $target | Select-Object FullName, Length, LastWriteTime
  }
} finally {
  Pop-Location
}
