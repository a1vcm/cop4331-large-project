// Basic smoke test: the app boots on the homepage route and renders its
// core content and nav-to-login action.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('renders the homepage with a Log In action', (WidgetTester tester) async {
    await tester.pumpWidget(const KnightRateApp());
    await tester.pumpAndSettle();

    expect(find.text('Find & Review Your Classes'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
  });
}
