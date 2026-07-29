import 'package:flutter_test/flutter_test.dart';
import 'package:grame_one/main.dart';

void main() {
  testWidgets('GrameOneApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GrameOneApp());
    expect(find.byType(GrameOneApp), findsOneWidget);
  });
}
