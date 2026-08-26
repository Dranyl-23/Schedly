param (
    [switch]$patch,
    [switch]$minor,
    [switch]$major
)

$pubspecPath = "pubspec.yaml"
$versionFile = "lib\core\constants\app_version.dart"

if (-not (Test-Path $pubspecPath)) {
    Write-Error "pubspec.yaml not found!"
    exit 1
}

$content = Get-Content $pubspecPath -Raw
if ($content -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    [int]$maj = $matches[1]
    [int]$min = $matches[2]
    [int]$pat = $matches[3]
    [int]$bld = $matches[4]

    if ($major) {
        $maj++
        $min = 0
        $pat = 0
    } elseif ($minor) {
        $min++
        $pat = 0
    } elseif ($patch) {
        $pat++
    }

    $bld++

    $newVersionStr = "$maj.$min.$pat+$bld"
    $content = $content -replace 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)', "version: $newVersionStr"
    Set-Content -Path $pubspecPath -Value $content -NoNewline

    # Update app_version.dart
    $dartContent = @"
class AppVersion {
  static const String major = '$maj';
  static const String minor = '$min';
  static const String patch = '$pat';
  static const int buildNumber = $bld;
  static const String releaseType = 'Production Release';

  static String get versionName => '`$major.`$minor.`$patch';
  static String get fullVersion => 'v`$versionName+`$buildNumber';
  static String get displayTag => 'v`$versionName (`$releaseType)';
  static String get fullWithBuild => 'v`$versionName (Build `$buildNumber)';
}
"@
    Set-Content -Path $versionFile -Value $dartContent -Encoding UTF8

    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "🚀 Schedly Version Bumped Successfully!" -ForegroundColor Green
    Write-Host "📦 New Version: v$maj.$min.$pat (Build $bld)" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
} else {
    Write-Error "Could not parse version from pubspec.yaml"
}
