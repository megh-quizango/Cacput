import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capcut2/screens/shell/main_shell_screen.dart';

void main() {
  testWidgets('MainShellScreen bottom navigation bar includes SafeArea to prevent overlap',
      (tester) async {
    // Simulate a device with 48px system bottom navigation bar (e.g. Android 3-button nav)
    tester.view.padding = const FakeViewPadding(bottom: 48);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainShellScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify navigation items exist in bottom navigation bar
    final navBarFinder = find.byKey(const ValueKey('bottom_nav_safe_area'));
    expect(find.descendant(of: navBarFinder, matching: find.text('Home')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Explore')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('AI')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Studio')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Me')), findsOneWidget);

    // Verify a SafeArea with bottom=true is present in the bottom navigation bar hierarchy
    final safeAreaFinder = find.descendant(
      of: find.byType(Scaffold),
      matching: find.byType(SafeArea),
    );
    expect(safeAreaFinder, findsWidgets);

    final safeAreas = tester.widgetList<SafeArea>(safeAreaFinder);
    final bottomNavSafeArea = safeAreas.firstWhere((sa) => sa.bottom == true);
    expect(bottomNavSafeArea.bottom, isTrue);

    // Verify nav item is positioned above the bottom inset (not cut off at the bottom 48px)
    final homeTextRect = tester.getRect(find.text('Home'));
    final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(homeTextRect.bottom, lessThan(screenSize.height - 10));

    // Reset view padding
    tester.view.resetPadding();
  });
}
