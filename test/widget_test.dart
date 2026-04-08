import 'package:flutter_test/flutter_test.dart';
import 'package:weather/main.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherApp());
    expect(find.text('날씨'), findsOneWidget);
  });
}
