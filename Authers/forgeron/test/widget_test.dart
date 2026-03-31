import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forgeron/main.dart';

void main() {
  testWidgets('Application forgeron lance correctement', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ForgeronApp()));

    // Verify that our title exists.
    expect(find.text('FORGERON'), findsOneWidget);
  });
}

