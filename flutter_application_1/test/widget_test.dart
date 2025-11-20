import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('MQTT App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp()); // ← CHANGE: CraneIQApp to MyApp

    // Wait for frames to settle
    await tester.pumpAndSettle();

    // Verify that the app loads with correct title
    expect(
      find.text('MQTT Demo'),
      findsOneWidget,
    ); // ← CHANGE: CraneIQ to MQTT Demo
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
