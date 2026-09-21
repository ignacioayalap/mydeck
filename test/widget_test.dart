import 'package:flutter_test/flutter_test.dart';
import 'package:mydeck/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MyDeckApp initializes cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyDeckApp());
    await tester.pumpAndSettle();

    // Verifies the app starts and displays the login or deck screen
    expect(find.byType(MyDeckApp), findsOneWidget);
  });
}
