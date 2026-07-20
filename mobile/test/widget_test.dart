// Basic smoke test: the app boots on the homepage route and renders its
// core content.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('renders the homepage', (WidgetTester tester) async {
    await tester.pumpWidget(const KnightRateApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to KnightRate!'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}