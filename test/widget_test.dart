import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:omnyadriver/app.dart';

void main() {
  testWidgets('renders Fluxi shell', (tester) async {
    await tester.pumpWidget(const OmnyaDriverApp());
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
