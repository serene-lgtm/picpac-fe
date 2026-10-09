class LaunchScreen {
  const LaunchScreen({
    this.enabled = false,
    this.revision = '',
    this.type = '',
    this.mediaUrl = '',
    this.posterUrl = '',
    this.durationMs = 1000,
    this.skipEnabled = true,
  });

  factory LaunchScreen.fromJson(Map<String, dynamic> json) => LaunchScreen(
    enabled: json['enabled'] == true,
    revision: json['revision'] as String? ?? '',
    type: json['type'] as String? ?? '',
    mediaUrl: json['media_url'] as String? ?? '',
    posterUrl: json['poster_url'] as String? ?? '',
    durationMs: (json['duration_ms'] as num?)?.toInt() ?? 1000,
    skipEnabled: json['skip_enabled'] == true,
  );

  final bool enabled;
  final String revision;
  final String type;
  final String mediaUrl;
  final String posterUrl;
  final int durationMs;
  final bool skipEnabled;

  // This image-only client displays the poster for video configurations.
  String get imageUrl => !enabled
      ? ''
      : type == 'image'
      ? mediaUrl
      : type == 'video'
      ? posterUrl
      : '';

  Duration get duration =>
      Duration(milliseconds: enabled && durationMs > 0 ? durationMs : 1000);
}
