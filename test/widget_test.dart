import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Ensure 'hangman_game' matches the name in pubspec.yaml
import 'package:hangman_game/main.dart';

void main() {
  testWidgets('Game smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HangmanApp());

    // Verify that the initial lives indicator is present
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
