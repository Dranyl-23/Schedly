// ignore_for_file: avoid_print
import 'dart:io';

void main(List<String> args) {
  final pubspecFile = File('pubspec.yaml');
  final appVersionFile = File('lib/core/constants/app_version.dart');

  if (!pubspecFile.existsSync()) {
    print('❌ pubspec.yaml not found!');
    exit(1);
  }

  final content = pubspecFile.readAsStringSync();
  final versionRegex = RegExp(r'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)');
  final match = versionRegex.firstMatch(content);

  if (match == null) {
    print('❌ Could not parse version in pubspec.yaml');
    exit(1);
  }

  int major = int.parse(match.group(1)!);
  int minor = int.parse(match.group(2)!);
  int patch = int.parse(match.group(3)!);
  int build = int.parse(match.group(4)!);

  if (args.contains('--major')) {
    major++;
    minor = 0;
    patch = 0;
  } else if (args.contains('--minor')) {
    minor++;
    patch = 0;
  } else if (args.contains('--patch')) {
    patch++;
  }

  build++;

  final newVersion = '$major.$minor.$patch+$build';
  final updatedContent = content.replaceFirst(versionRegex, 'version: $newVersion');
  pubspecFile.writeAsStringSync(updatedContent);

  final dartContent = '''
class AppVersion {
  static const String major = '$major';
  static const String minor = '$minor';
  static const String patch = '$patch';
  static const int buildNumber = $build;
  static const String releaseType = 'Production Release';

  static String get versionName => '\$major.\$minor.\$patch';
  static String get fullVersion => 'v\$versionName+\$buildNumber';
  static String get displayTag => 'v\$versionName (\$releaseType)';
  static String get fullWithBuild => 'v\$versionName (Build \$buildNumber)';
}
''';

  appVersionFile.writeAsStringSync(dartContent);

  print('==========================================');
  print('🚀 Schedly Version Bumped Successfully!');
  print('📦 New Version: v$major.$minor.$patch (Build $build)');
  print('==========================================');
}
