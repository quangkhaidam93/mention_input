class MentionData {
  MentionData({
    required this.id,
    required this.display,
    this.imageUrl,
    this.customData,
  });

  final String id;
  final String display;
  final String? imageUrl;

  /// Custom payload for the mention data, allowing additional fields like title, description etc.
  final Map<String, dynamic>? customData;
}
