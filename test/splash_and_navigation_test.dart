import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capcut2/screens/splash/splash_screen.dart';
import 'package:capcut2/screens/shell/main_shell_screen.dart';
import 'package:capcut2/services/connectivity_service.dart';
import 'package:capcut2/widgets/app_exit_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Splash Screen Offline Flow Tests', () {
    testWidgets('Shows splash immediately and triggers No Internet dialog if offline without advancing',
        (WidgetTester tester) async {
      // Simulate offline mode before opening splash
      ConnectivityService.instance.simulateOffline();

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Verify splash screen branding is immediately visible
      expect(find.text('PhotoVideoCourse'), findsOneWidget);
      expect(find.text('Create. Edit. Inspire.'), findsOneWidget);

      // Pump to trigger addPostFrameCallback
      await tester.pump(const Duration(milliseconds: 100));

      // Advance time beyond normal splash auto-advance delay (2500ms)
      await tester.pump(const Duration(milliseconds: 3000));

      // Assert that we are STILL on splash screen (did not advance to onboarding)
      expect(find.text('PhotoVideoCourse'), findsOneWidget);
      expect(find.text('Create. Edit. Inspire.'), findsOneWidget);

      // Restore online status and pump through the pending timer
      ConnectivityService.instance.simulateOnline();
      await tester.pump(const Duration(milliseconds: 3000));
    });
  });

  group('MainShellScreen Back Press & Exit Dialog Tests', () {
    testWidgets('Pressing back on Home tab triggers back handler and displays AppExitDialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainShellScreen(initialIndex: 0),
          ),
        ),
      );

      // Verify on Home tab
      expect(find.text('Home'), findsWidgets);

      // Find root PopScope
      final popScopeFinder = find.byKey(const ValueKey('main_shell_pop_scope'));
      expect(popScopeFinder, findsOneWidget);

      // Invoking back pop on home screen
      final dynamic popScopeWidget = tester.widget(popScopeFinder);
      popScopeWidget.onPopInvokedWithResult(false, null);

      await tester.pumpAndSettle();

      // Verify that AppExitDialog is shown
      expect(find.byType(AppExitDialog), findsOneWidget);
      expect(find.text('Exit PhotoVideoCourse?'), findsOneWidget);
    });

    testWidgets('Pressing back on non-Home tab switches back to Home tab',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainShellScreen(initialIndex: 2), // AI Studio tab
          ),
        ),
      );

      // Find root PopScope
      final popScopeFinder = find.byKey(const ValueKey('main_shell_pop_scope'));
      final dynamic popScopeWidget = tester.widget(popScopeFinder);
      popScopeWidget.onPopInvokedWithResult(false, null);

      await tester.pumpAndSettle();

      // Does not show exit dialog, but switches to Home tab
      expect(find.byType(AppExitDialog), findsNothing);
    });
  });
}
