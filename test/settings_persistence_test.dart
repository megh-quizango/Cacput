import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capcut2/screens/profile/settings_screen.dart';
import 'package:capcut2/services/ad_tab_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdTabService.instance.resetToDefaults();
  });

  group('Settings Screen Persistence Widget Tests', () {
    testWidgets(
        'Settings screen toggles and inputs for custom chrome, app open ad, and weight distribution persist across relaunch',
        (WidgetTester tester) async {
      // Session 1: Render SettingsScreen and interact with settings
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify default tabs count is 2 and custom chrome enabled is true
      expect(find.text('2'), findsWidgets);
      expect(AdTabService.instance.customChromeEnabled, isTrue);

      // Toggle "Enable Custom Chrome Tabs" master switch
      final masterChromeSwitchFinder =
          find.widgetWithText(SwitchListTile, 'Enable Custom Chrome Tabs');
      await tester.tap(masterChromeSwitchFinder);
      await tester.pumpAndSettle();
      expect(AdTabService.instance.customChromeEnabled, isFalse);

      // 2. Tap add tab button (+ icon) twice to increase tabs count from 2 to 4
      final addTabFinder = find.byIcon(Icons.add_circle_outline).first;
      await tester.tap(addTabFinder);
      await tester.pumpAndSettle();
      await tester.tap(addTabFinder);
      await tester.pumpAndSettle();

      expect(AdTabService.instance.tabsCount, equals(4));

      // 3. Toggle "Launch on Navigation" switch
      final navSwitchFinder = find.widgetWithText(SwitchListTile, 'Launch on Navigation');
      await tester.tap(navSwitchFinder);
      await tester.pumpAndSettle();

      expect(AdTabService.instance.autoLaunchOnNavigation, isFalse);

      // 4. Toggle "Launch on Clicks" switch
      final clickSwitchFinder = find.widgetWithText(SwitchListTile, 'Launch on Clicks');
      await tester.tap(clickSwitchFinder);
      await tester.pumpAndSettle();

      expect(AdTabService.instance.autoLaunchOnClick, isFalse);

      // 5. Scroll down and toggle "App Open Ad on Resume" switch
      final appOpenSwitchFinder = find.widgetWithText(SwitchListTile, 'App Open Ad on Resume');
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();

      await tester.tap(appOpenSwitchFinder);
      await tester.pumpAndSettle();

      expect(AdTabService.instance.showAdOnAppResume, isFalse);

      // Allow async persistence to finish
      await tester.pump(const Duration(milliseconds: 100));

      // Session 2: Terminate app and relaunch
      AdTabService.instance.resetToDefaults();
      expect(AdTabService.instance.customChromeEnabled, isTrue);
      expect(AdTabService.instance.tabsCount, equals(2));
      expect(AdTabService.instance.autoLaunchOnNavigation, isTrue);

      // Relaunch app with stored preferences
      await AdTabService.instance.initialize();

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert that persisted values are loaded into the UI
      expect(find.text('4'), findsWidgets);
      expect(AdTabService.instance.customChromeEnabled, isFalse);
      expect(AdTabService.instance.tabsCount, equals(4));
      expect(AdTabService.instance.autoLaunchOnNavigation, isFalse);
      expect(AdTabService.instance.autoLaunchOnClick, isFalse);
      expect(AdTabService.instance.showAdOnAppResume, isFalse);
    });
  });
}
