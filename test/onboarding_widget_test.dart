import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capcut2/screens/onboarding/onboarding_wrapper_screen.dart';

void main() {
  testWidgets('Onboarding name step starts empty and allows user to fill in details',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingWrapperScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Name step header is displayed
    expect(find.text('Your Name'), findsOneWidget);

    // Verify text field is empty (not pre-filled with "megh")
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    final textField = tester.widget<TextField>(textFieldFinder);
    expect(textField.controller?.text, isEmpty);

    // Type a name
    await tester.enterText(textFieldFinder, 'Alex Creator');
    await tester.pumpAndSettle();

    // Button should be enabled and say "Continue"
    expect(find.text('Continue'), findsOneWidget);
  });
}
