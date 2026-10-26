import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capcut2/core/theme/responsive_orientation_manager.dart';
import 'package:capcut2/widgets/no_internet_dialog.dart';
import 'package:capcut2/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResponsiveOrientationHelper Tests', () {
    late List<MethodCall> platformCalls;

    setUp(() {
      platformCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
        platformCalls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('Correctly identifies mobile phone and locks to portrait only',
        (WidgetTester tester) async {
      late bool isMobile;
      late bool isLargeScreen;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)), // Mobile dimensions
            child: Builder(
              builder: (context) {
                isMobile = ResponsiveOrientationHelper.isMobile(context);
                isLargeScreen = ResponsiveOrientationHelper.isLargeScreen(context);
                ResponsiveOrientationHelper.enforce(context);
                return const Scaffold(body: Text('Mobile Test Screen'));
              },
            ),
          ),
        ),
      );

      expect(isMobile, isTrue);
      expect(isLargeScreen, isFalse);

      // Verify that SystemChrome set preferred orientations to portraitUp and portraitDown only
      final orientationCalls = platformCalls.where(
        (call) => call.method == 'SystemChrome.setPreferredOrientations',
      ).toList();

      expect(orientationCalls, isNotEmpty);
      final lastCallArgs = orientationCalls.last.arguments as List<dynamic>;
      expect(lastCallArgs, contains('DeviceOrientation.portraitUp'));
      expect(lastCallArgs, contains('DeviceOrientation.portraitDown'));
      expect(lastCallArgs, isNot(contains('DeviceOrientation.landscapeLeft')));
      expect(lastCallArgs, isNot(contains('DeviceOrientation.landscapeRight')));
    });

    testWidgets('Correctly identifies tablet/large screen and unlocks all orientations',
        (WidgetTester tester) async {
      late bool isMobile;
      late bool isLargeScreen;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(900, 1200)), // Tablet dimensions
            child: Builder(
              builder: (context) {
                isMobile = ResponsiveOrientationHelper.isMobile(context);
                isLargeScreen = ResponsiveOrientationHelper.isLargeScreen(context);
                ResponsiveOrientationHelper.enforce(context);
                return const Scaffold(body: Text('Tablet Test Screen'));
              },
            ),
          ),
        ),
      );

      expect(isMobile, isFalse);
      expect(isLargeScreen, isTrue);

      // Verify that SystemChrome set preferred orientations to all 4 orientations (unlocked)
      final orientationCalls = platformCalls.where(
        (call) => call.method == 'SystemChrome.setPreferredOrientations',
      ).toList();

      expect(orientationCalls, isNotEmpty);
      final lastCallArgs = orientationCalls.last.arguments as List<dynamic>;
      expect(lastCallArgs, contains('DeviceOrientation.portraitUp'));
      expect(lastCallArgs, contains('DeviceOrientation.portraitDown'));
      expect(lastCallArgs, contains('DeviceOrientation.landscapeLeft'));
      expect(lastCallArgs, contains('DeviceOrientation.landscapeRight'));
    });
  });

  group('NoInternetDialog Widget Tests', () {
    testWidgets('Renders all visual elements matching CapCut dark neon styling without offline mode bypass',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoInternetDialog(),
          ),
        ),
      );

      // Verify icon
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

      // Verify header texts
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(
        find.textContaining('An active internet connection is required'),
        findsOneWidget,
      );

      // Verify status tag
      expect(find.text('Device Offline'), findsOneWidget);

      // Verify Try Again button is present
      expect(find.text('Try Again'), findsOneWidget);

      // Verify "Continue in Offline Mode" is explicitly NOT present
      expect(find.text('Continue in Offline Mode'), findsNothing);
    });

    testWidgets('Calls onRetry when Try Again button is pressed',
        (WidgetTester tester) async {
      final retryCompleter = Completer<bool>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoInternetDialog(
              onRetry: () => retryCompleter.future,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Try Again'));
      await tester.pump(); // Advance frame to show progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      retryCompleter.complete(false);
      await tester.pump(const Duration(milliseconds: 100)); // Advance frame after complete
      expect(find.textContaining('Still offline'), findsOneWidget);
    });
  });

  group('ConnectivityService State Tests', () {
    test('Simulate offline and online toggles connection status', () {
      final service = ConnectivityService.instance;

      service.simulateOffline();
      expect(service.isOnline, isFalse);
      expect(service.connectionNotifier.value, isFalse);

      service.simulateOnline();
      expect(service.isOnline, isTrue);
      expect(service.connectionNotifier.value, isTrue);
    });
  });
}
