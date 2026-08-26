class AppVersion {
  static const String major = '1';
  static const String minor = '0';
  static const String patch = '0';
  static const int buildNumber = 2;
  static const String releaseType = 'Production Release';

  static String get versionName => '$major.$minor.$patch';
  static String get fullVersion => 'v$versionName+$buildNumber';
  static String get displayTag => 'v$versionName ($releaseType)';
  static String get fullWithBuild => 'v$versionName (Build $buildNumber)';
}
