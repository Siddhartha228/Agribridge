import 'package:agribridge/core/services/security/biometric_auth_service.dart';
import 'package:agribridge/core/services/storage/user_session_service.dart';
import 'package:agribridge/core/widgets/my_button.dart';
import 'package:agribridge/core/widgets/my_textformfield.dart';
import 'package:agribridge/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:agribridge/features/auth/presentation/pages/login_screen.dart';
import 'package:agribridge/features/auth/presentation/pages/register_screen.dart';
import 'package:agribridge/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:agribridge/features/dashboard/presentation/pages/cart_screen.dart';
import 'package:agribridge/features/dashboard/presentation/pages/payment_screen.dart';
import 'package:agribridge/features/dashboard/presentation/pages/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_fakes.dart';
import '../helpers/test_widget_helpers.dart';

Future<List<Override>> _defaultOverrides() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final userSessionService = TestUserSessionService(prefs: prefs);
  final authViewModel = buildTestAuthViewModel(
    repository: TestAuthRepository(),
    userSessionService: userSessionService,
  );

  return [
    userSessionServiceProvider.overrideWithValue(userSessionService),
    biometricAuthServiceProvider.overrideWithValue(
      TestBiometricAuthService(canUseBiometricLoginResult: false),
    ),
    authViewModelProvider.overrideWith((ref) => authViewModel),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('MyButton widget tests', () {
    testWidgets('1. renders text label', (tester) async {
      await pumpTestApp(
        tester,
        Scaffold(
          body: MyButton(
            onPressed: () {},
            text: 'Checkout',
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Checkout'), findsOneWidget);
    });

    testWidgets('2. uses default amber background color', (tester) async {
      await pumpTestApp(
        tester,
        Scaffold(
          body: MyButton(
            onPressed: () {},
            text: 'Default Color',
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final color =
          (button.style?.backgroundColor as dynamic)?.resolve(<WidgetState>{})
              as Color?;

      expect(color, Colors.amber);
    });

    testWidgets('3. uses provided custom background color', (tester) async {
      await pumpTestApp(
        tester,
        Scaffold(
          body: MyButton(
            onPressed: () {},
            text: 'Custom Color',
            color: Colors.green,
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final color =
          (button.style?.backgroundColor as dynamic)?.resolve(<WidgetState>{})
              as Color?;

      expect(color, Colors.green);
    });

    testWidgets('4. calls onPressed when tapped', (tester) async {
      var tapped = false;

      await pumpTestApp(
        tester,
        Scaffold(
          body: MyButton(
            onPressed: () {
              tapped = true;
            },
            text: 'Tap Me',
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('MyTextformfield widget tests', () {
    testWidgets('5. renders label and hint texts', (tester) async {
      final controller = TextEditingController();

      await pumpTestApp(
        tester,
        Scaffold(
          body: MyTextformfield(
            labelText: 'Email',
            hintText: 'Enter your email',
            controller: controller,
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('6. shows initial controller value', (tester) async {
      final controller = TextEditingController(text: 'preset@agribridge.com');

      await pumpTestApp(
        tester,
        Scaffold(
          body: MyTextformfield(
            labelText: 'Email',
            hintText: 'Enter your email',
            controller: controller,
          ),
        ),
      );

      expect(find.text('preset@agribridge.com'), findsOneWidget);
    });

    testWidgets('7. updates controller when user types', (tester) async {
      final controller = TextEditingController();

      await pumpTestApp(
        tester,
        Scaffold(
          body: MyTextformfield(
            labelText: 'Name',
            hintText: 'Enter your name',
            controller: controller,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Alice');
      await tester.pump();

      expect(controller.text, 'Alice');
    });
  });

  group('LoginScreen widget tests', () {
    testWidgets('8. shows login form fields and actions', (tester) async {
      final overrides = await _defaultOverrides();

      await pumpTestApp(
        tester,
        const LoginScreen(),
        overrides: overrides,
      );

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('9. validates empty login fields', (tester) async {
      final overrides = await _defaultOverrides();

      await pumpTestApp(
        tester,
        const LoginScreen(),
        overrides: overrides,
      );

      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('10. toggles password visibility', (tester) async {
      final overrides = await _defaultOverrides();

      await pumpTestApp(
        tester,
        const LoginScreen(),
        overrides: overrides,
      );

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });

  group('RegisterScreen widget tests', () {
    testWidgets('11. shows registration form and sign up button', (
      tester,
    ) async {
      final overrides = await _defaultOverrides();

      await pumpTestApp(
        tester,
        const RegisterScreen(),
        overrides: overrides,
      );

      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Create a Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('12. validates empty registration form', (tester) async {
      final overrides = await _defaultOverrides();

      await pumpTestApp(
        tester,
        const RegisterScreen(),
        overrides: overrides,
      );

      final signupButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signupButton);
      await tester.tap(signupButton);
      await tester.pump();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('13. validates password mismatch in registration', (
      tester,
    ) async {
      final overrides = await _defaultOverrides();

      await pumpTestApp(
        tester,
        const RegisterScreen(),
        overrides: overrides,
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@user.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password999');

      final signupButton = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signupButton);
      await tester.tap(signupButton);
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen widget tests', () {
    testWidgets('14. shows forgot password initial step', (tester) async {
      final overrides = await _defaultOverrides();

      await pumpTestApp(
        tester,
        const ForgotPasswordScreen(),
        overrides: overrides,
      );

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('1. Email'), findsOneWidget);
      expect(find.text('2. OTP'), findsOneWidget);
      expect(find.text('3. Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Send OTP'), findsOneWidget);
    });

    testWidgets('15. validates invalid email before sending OTP', (
      tester,
    ) async {
      final overrides = await _defaultOverrides();

      await pumpTestApp(
        tester,
        const ForgotPasswordScreen(),
        overrides: overrides,
      );

      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send OTP'));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });
  });

  group('ProductDetailScreen widget tests', () {
    testWidgets('16. disables CTA for out-of-stock product', (tester) async {
      final overrides = await _defaultOverrides();

      await pumpTestApp(
        tester,
        const ProductDetailScreen(
          name: 'Potato',
          price: 80,
          stockQuantity: 0,
          availability: 'out-of-stock',
        ),
        overrides: overrides,
      );

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Out of stock'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('17. increases quantity and updates total price', (
      tester,
    ) async {
      final overrides = await _defaultOverrides();

      await pumpTestApp(
        tester,
        const ProductDetailScreen(
          name: 'Tomato',
          price: 100,
          stockQuantity: 5,
          availability: 'in-stock',
        ),
        overrides: overrides,
      );

      expect(find.text('Rs 100'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Rs 200'), findsOneWidget);
    });

    testWidgets('18. shows snackbar when adding product to cart', (
      tester,
    ) async {
      final overrides = await _defaultOverrides();

      await pumpTestApp(
        tester,
        const ProductDetailScreen(
          name: 'Tomato',
          price: 100,
          stockQuantity: 5,
          availability: 'in-stock',
        ),
        overrides: overrides,
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add to cart'));
      await tester.pump();

      expect(find.text('Tomato x1 added to cart'), findsOneWidget);
    });
  });

  group('PaymentScreen widget tests', () {
    testWidgets('19. shows payment summary and disabled Pay Now button', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const PaymentScreen(subtotal: 500, deliveryFee: 120, total: 620),
      );

      expect(find.text('Choose payment method'), findsOneWidget);
      expect(find.text('Rs 620'), findsOneWidget);

      final payNowButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Pay Now'),
      );
      expect(payNowButton.onPressed, isNull);
    });
  });

  group('CartScreen widget tests', () {
    testWidgets('20. shows empty cart and handles start shopping callback', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final userSessionService = TestUserSessionService(prefs: prefs);
      var tapped = false;

      await pumpTestApp(
        tester,
        CartScreen(
          onStartShopping: () {
            tapped = true;
          },
        ),
        overrides: [
          userSessionServiceProvider.overrideWithValue(userSessionService),
        ],
      );

      expect(find.text('Your cart is empty'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Shopping'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
