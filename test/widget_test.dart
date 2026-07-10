import 'package:flutter_test/flutter_test.dart';

import 'package:omnyadriver/app.dart';

void main() {
  testWidgets('renders Omnya Driver shell', (tester) async {
    await tester.pumpWidget(const OmnyaDriverApp());
    await tester.pumpAndSettle();

    expect(find.text('Omnya Driver'), findsOneWidget);
    expect(
      find.textContaining('Entre com seguranca para acessar seu painel.'),
      findsOneWidget,
    );
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Microsoft'), findsOneWidget);
  });
}
