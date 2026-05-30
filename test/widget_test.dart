import 'package:eco_customer_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders splash screen', (tester) async {
    await tester.pumpWidget(const EcoCustomerApp());

    expect(find.text('ECO Cliente'), findsOneWidget);
  });
}
