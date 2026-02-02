import 'package:flutter_test/flutter_test.dart';
// IMPORTANT: Ensure 'uems_project' matches the name in your pubspec.yaml
import 'package:uems_project/main.dart';

void main() {
  testWidgets('UEMS Login Page Load Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the "Welcome Back" text exists on the login screen.
    expect(find.text('Welcome Back'), findsOneWidget);

    // Verify that the "Sign In to Portal" button exists.
    expect(find.text('Sign In to Portal'), findsOneWidget);
  });
}
