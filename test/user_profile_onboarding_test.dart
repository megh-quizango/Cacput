import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capcut2/models/user_profile.dart';
import 'package:capcut2/providers/user_provider.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('Default user profile has clean, empty fields without hardcoded values', () {
      const profile = UserProfile();
      expect(profile.name, isEmpty);
      expect(profile.country, isEmpty);
      expect(profile.birthDate, isEmpty);
      expect(profile.gender, isEmpty);
      expect(profile.interests, isEmpty);
      expect(profile.experience, isEmpty);
      expect(profile.favoriteContent, isEmpty);
      expect(profile.aiPreferences, isEmpty);
    });

    test('displayName returns Creator when name is empty, and user name when set', () {
      const emptyProfile = UserProfile();
      expect(emptyProfile.displayName, equals('Creator'));

      final namedProfile = emptyProfile.copyWith(name: 'Sarah Connor');
      expect(namedProfile.displayName, equals('Sarah Connor'));
    });

    test('avatarInitial returns C when empty, and first letter capitalized when set', () {
      const emptyProfile = UserProfile();
      expect(emptyProfile.avatarInitial, equals('C'));

      final profileWithInitial = emptyProfile.copyWith(name: 'david');
      expect(profileWithInitial.avatarInitial, equals('D'));
    });
  });

  group('UserNotifier and userProvider Tests', () {
    test('Can update all user onboarding fields individually and together', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial state
      expect(container.read(userProvider).name, isEmpty);

      // Update Name
      container.read(userProvider.notifier).updateName('Alex Rivera');
      expect(container.read(userProvider).name, equals('Alex Rivera'));
      expect(container.read(userProvider).displayName, equals('Alex Rivera'));
      expect(container.read(userProvider).avatarInitial, equals('A'));

      // Update Birth Date
      container.read(userProvider.notifier).updateBirthDate('15 Aug 1999');
      expect(container.read(userProvider).birthDate, equals('15 Aug 1999'));

      // Update Country
      container.read(userProvider.notifier).updateCountry('Canada');
      expect(container.read(userProvider).country, equals('Canada'));

      // Update Gender
      container.read(userProvider.notifier).updateGender('Non-Binary');
      expect(container.read(userProvider).gender, equals('Non-Binary'));

      // Update Experience
      container.read(userProvider.notifier).updateExperience('Advanced');
      expect(container.read(userProvider).experience, equals('Advanced'));

      // Toggle Interests & Custom Interests
      container.read(userProvider.notifier).toggleInterest('Gaming');
      container.read(userProvider.notifier).toggleInterest('Travel');
      container.read(userProvider.notifier).addCustomInterest('Anime Editing');
      expect(container.read(userProvider).interests,
          containsAll(['Gaming', 'Travel', 'Anime Editing']));

      // Toggle Content Formats & Custom Content
      container.read(userProvider.notifier).toggleFavoriteContent('YouTube Shorts');
      container.read(userProvider.notifier).addCustomFavoriteContent('Cinematic Reels');
      expect(container.read(userProvider).favoriteContent,
          containsAll(['YouTube Shorts', 'Cinematic Reels']));

      // Toggle AI Preferences
      container.read(userProvider.notifier).toggleAiPreference('Auto Caption');
      container.read(userProvider.notifier).toggleAiPreference('Video Upscaler');
      expect(container.read(userProvider).aiPreferences,
          containsAll(['Auto Caption', 'Video Upscaler']));

      // Update Profile full method
      container.read(userProvider.notifier).updateProfile(
            name: 'Jordan Miller',
            country: 'Australia',
          );
      expect(container.read(userProvider).name, equals('Jordan Miller'));
      expect(container.read(userProvider).country, equals('Australia'));
    });
  });
}
