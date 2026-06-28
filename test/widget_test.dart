import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bear_bell/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBearBellApp());
    expect(find.text('Smart Bear Bell'), findsOneWidget);
  });
}
