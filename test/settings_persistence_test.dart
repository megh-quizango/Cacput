import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capcut2/screens/profile/settings_screen.dart';
import 'package:capcut2/services/firebase_remote_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Settings Screen Widget Tests', () {
    testWidgets(
        'Hides custom tabs, app open testing, and network & orientation sections while keeping core settings',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Core sections remain visible
      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Default Frame Rate'), findsOneWidget);
      expect(find.text('STORAGE'), findsOneWidget);
      expect(find.text('LEGAL'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('SUPPORT'), 200);
      expect(find.text('SUPPORT'), findsOneWidget);

      // Removed testing/status sections and toggles must not appear
      expect(find.text('CUSTOM TABS & APP OPEN AD (TESTING)'), findsNothing);
      expect(find.text('Enable Custom Chrome Tabs'), findsNothing);
      expect(find.text('Tabs to Launch (N)'), findsNothing);
      expect(find.text('Launch on Navigation'), findsNothing);
      expect(find.text('Launch on Clicks'), findsNothing);
      expect(find.text('Launch on Back Press / Gesture'), findsNothing);
      expect(find.text('App Open Ad on Resume'), findsNothing);
      expect(find.text('Weighted URL Distribution'), findsNothing);
      expect(find.text('Launch N Tabs'), findsNothing);
      expect(find.text('Preview Ad'), findsNothing);

      expect(find.text('NETWORK & ORIENTATION'), findsNothing);
      expect(find.text('Device Screen Type'), findsNothing);
      expect(find.text('Internet Status'), findsNothing);
      // Legal keeps only Privacy Policy & Terms; Rate App, Send Feedback, Licenses are gone
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Licenses'), findsNothing);
      expect(find.text('Rate App'), findsNothing);
      expect(find.text('Send Feedback'), findsNothing);
    });

    test('Legal page URLs come from Remote Config keys', () {
      final rc = FirebaseRemoteConfigService.instance;
      rc.setMockValue(FirebaseRemoteConfigService.keyPrivacyPolicyUrl, ' https://example.com/privacy ');
      rc.setMockValue(FirebaseRemoteConfigService.keyTermsOfServiceUrl, 'https://example.com/terms');
      expect(rc.getPrivacyPolicyUrl(), 'https://example.com/privacy');
      expect(rc.getTermsOfServiceUrl(), 'https://example.com/terms');
      rc.clearMockValues();
    });
  });
}
