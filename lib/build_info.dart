// lib/build_info.dart
// This file is auto-generated before each build. DO NOT EDIT manually.

class BuildInfo {
  static const String gitCommit =
      String.fromEnvironment('GIT_COMMIT', defaultValue: 'unknown');
  static const String buildTime =
      String.fromEnvironment('BUILD_TIME', defaultValue: 'unknown');
  static const String appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  /// Get formatted build info string
  static String get summary => '''
Commit: $gitCommit
Built: $buildTime
Version: $appVersion
''';
}
