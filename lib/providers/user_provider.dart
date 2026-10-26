import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';

class UserNotifier extends StateNotifier<UserProfile> {
  UserNotifier() : super(const UserProfile());

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateCountry(String country) {
    state = state.copyWith(country: country);
  }

  void updateBirthDate(String date) {
    state = state.copyWith(birthDate: date);
  }

  void updateGender(String gender) {
    state = state.copyWith(gender: gender);
  }

  void toggleInterest(String interest) {
    final list = List<String>.from(state.interests);
    if (list.contains(interest)) {
      list.remove(interest);
    } else {
      list.add(interest);
    }
    state = state.copyWith(interests: list);
  }

  void addCustomInterest(String interest) {
    final trimmed = interest.trim();
    if (trimmed.isEmpty) return;
    final list = List<String>.from(state.interests);
    if (!list.contains(trimmed)) {
      list.add(trimmed);
      state = state.copyWith(interests: list);
    }
  }

  void setInterests(List<String> interests) {
    state = state.copyWith(interests: List<String>.from(interests));
  }

  void updateExperience(String experience) {
    state = state.copyWith(experience: experience);
  }

  void toggleFavoriteContent(String content) {
    final list = List<String>.from(state.favoriteContent);
    if (list.contains(content)) {
      list.remove(content);
    } else {
      list.add(content);
    }
    state = state.copyWith(favoriteContent: list);
  }

  void addCustomFavoriteContent(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final list = List<String>.from(state.favoriteContent);
    if (!list.contains(trimmed)) {
      list.add(trimmed);
      state = state.copyWith(favoriteContent: list);
    }
  }

  void setFavoriteContent(List<String> content) {
    state = state.copyWith(favoriteContent: List<String>.from(content));
  }

  void toggleAiPreference(String pref) {
    final list = List<String>.from(state.aiPreferences);
    if (list.contains(pref)) {
      list.remove(pref);
    } else {
      list.add(pref);
    }
    state = state.copyWith(aiPreferences: list);
  }

  void setAiPreferences(List<String> prefs) {
    state = state.copyWith(aiPreferences: List<String>.from(prefs));
  }

  void updateProfile({
    String? name,
    String? country,
    String? birthDate,
    String? gender,
    String? experience,
    List<String>? interests,
    List<String>? favoriteContent,
    List<String>? aiPreferences,
  }) {
    state = state.copyWith(
      name: name,
      country: country,
      birthDate: birthDate,
      gender: gender,
      experience: experience,
      interests: interests,
      favoriteContent: favoriteContent,
      aiPreferences: aiPreferences,
    );
  }

  void addCoins(int amount) {
    state = state.copyWith(coins: state.coins + amount);
  }

  void incrementProjects() {
    state = state.copyWith(projectsCount: state.projectsCount + 1);
  }

  void incrementExports() {
    state = state.copyWith(exportsCount: state.exportsCount + 1);
  }

  void updateStorageUsed(int mb) {
    state = state.copyWith(storageUsedMb: mb);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserProfile>((ref) {
  return UserNotifier();
});
