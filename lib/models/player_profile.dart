class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.displayName,
    required this.bio,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String bio;
  final String? avatarUrl;

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    bio: (json['bio'] as String?) ?? '',
    avatarUrl: json['avatarUrl'] as String?,
  );
}
