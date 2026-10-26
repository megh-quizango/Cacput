class UserProfile {
  final String name;
  final String country;
  final String birthDate;
  final String gender;
  final List<String> interests;
  final String experience;
  final List<String> favoriteContent;
  final List<String> aiPreferences;
  final int coins;
  final int projectsCount;
  final int exportsCount;
  final int storageUsedMb;

  const UserProfile({
    this.name = "",
    this.country = "",
    this.birthDate = "",
    this.gender = "",
    this.interests = const [],
    this.experience = "",
    this.favoriteContent = const [],
    this.aiPreferences = const [],
    this.coins = 0,
    this.projectsCount = 0,
    this.exportsCount = 0,
    this.storageUsedMb = 0,
  });

  String get displayName => name.trim().isNotEmpty ? name.trim() : "Creator";

  String get avatarInitial {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return "C";
    return cleanName.substring(0, 1).toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? country,
    String? birthDate,
    String? gender,
    List<String>? interests,
    String? experience,
    List<String>? favoriteContent,
    List<String>? aiPreferences,
    int? coins,
    int? projectsCount,
    int? exportsCount,
    int? storageUsedMb,
  }) {
    return UserProfile(
      name: name ?? this.name,
      country: country ?? this.country,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      experience: experience ?? this.experience,
      favoriteContent: favoriteContent ?? this.favoriteContent,
      aiPreferences: aiPreferences ?? this.aiPreferences,
      coins: coins ?? this.coins,
      projectsCount: projectsCount ?? this.projectsCount,
      exportsCount: exportsCount ?? this.exportsCount,
      storageUsedMb: storageUsedMb ?? this.storageUsedMb,
    );
  }
}
