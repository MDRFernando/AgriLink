import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/features/onboarding/screens/profile_setup_screen.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

AuthNotifier _buyerSession({String email = 'buyer@test.lk', String name = 'Kasun Silva'}) {
  final auth = AuthNotifier();
  auth.selectRole(UserRole.business);
  auth.login(email: email, name: name);
  return auth;
}

AuthNotifier _farmerSession() {
  final auth = AuthNotifier();
  auth.selectRole(UserRole.farmer);
  auth.login(email: 'newfarmer@test.lk', name: 'Sunil Perera');
  return auth;
}

Widget _profileApp(AuthNotifier auth) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => auth),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: GoRouter(
        initialLocation: '/profile-setup',
        routes: [
          GoRoute(
            path: '/profile-setup',
            builder: (_, __) => const ProfileSetupScreen(),
          ),
          GoRoute(
            path: '/business',
            builder: (_, __) => const Scaffold(body: Text('Buyer Home')),
          ),
          GoRoute(
            path: '/farmer',
            builder: (_, __) => const Scaffold(body: Text('Farmer Home')),
          ),
        ],
      ),
    ),
  );
}

Future<void> _prepareSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _selectRegion(WidgetTester tester) async {
  final dropdown = find.byType(DropdownButton<String>);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Western Province').last);
  await tester.pumpAndSettle();
}

Future<void> _continue(WidgetTester tester) async {
  final button = find.text('Continue');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('AuthNotifier buyer type', () {
    test('stores company buyer details and restores them after login', () {
      final auth = _buyerSession(email: 'company@test.lk', name: 'Nimal Jayasuriya');
      auth.completeProfile(
        name: 'Nimal Jayasuriya',
        phone: '0771239876',
        organizationName: 'FreshMart Lanka',
        region: 'Western Province',
        address: '45 Market Street, Colombo',
        buyerType: BuyerType.company,
      );

      expect(auth.state.profile!.isCompanyBuyer, isTrue);
      expect(auth.state.profile!.organizationName, 'FreshMart Lanka');
      expect(auth.state.profile!.isVerified, isTrue);

      auth.logout();
      auth.selectRole(UserRole.business);
      auth.login(email: 'company@test.lk');

      expect(auth.state.profile!.buyerType, BuyerType.company);
      expect(auth.state.profile!.organizationName, 'FreshMart Lanka');
      expect(auth.state.profile!.displayName, 'FreshMart Lanka');
      expect(auth.state.isAuthenticated, isTrue);
    });

    test('lets individual buyers register without a company name', () {
      final auth = _buyerSession(email: 'individual@test.lk');
      auth.completeProfile(
        name: 'Kasun Silva',
        phone: '0771112222',
        organizationName: null,
        region: 'Western Province',
        address: '12 Lake Road, Kandy',
        buyerType: BuyerType.individual,
      );

      expect(auth.state.profile!.isIndividualBuyer, isTrue);
      expect(auth.state.profile!.organizationName, isNull);
      expect(auth.state.profile!.name, 'Kasun Silva');
      expect(auth.state.profile!.address, '12 Lake Road, Kandy');

      auth.logout();
      auth.selectRole(UserRole.business);
      auth.login(email: 'individual@test.lk');

      expect(auth.state.profile!.buyerType, BuyerType.individual);
      expect(auth.state.profile!.organizationName, isNull);
      expect(auth.state.profile!.displayName, 'Kasun Silva');
    });

    test('does not attach a buyer type to farmer profiles', () {
      final auth = _farmerSession();
      auth.completeProfile(
        name: 'Sunil Perera',
        phone: '0771234567',
        region: 'North Western Province',
      );

      expect(auth.state.profile!.role, UserRole.farmer);
      expect(auth.state.profile!.buyerType, isNull);
      expect(auth.state.profile!.organizationName, isNull);
    });
  });

  group('Buyer profile setup UI', () {
    testWidgets('requires buyer type before continuing', (tester) async {
      await _prepareSurface(tester);
      await tester.pumpWidget(_profileApp(_buyerSession()));
      await tester.pumpAndSettle();

      await _continue(tester);

      expect(find.text('Buyer type is required'), findsOneWidget);
      expect(find.text('Please select how you are buying'), findsOneWidget);
    });

    testWidgets('shows company name only for company buyers and requires it', (tester) async {
      await _prepareSurface(tester);
      await tester.pumpWidget(_profileApp(_buyerSession()));
      await tester.pumpAndSettle();

      expect(find.text('How are you buying?'), findsOneWidget);
      expect(find.text('Company Name'), findsNothing);

      await tester.tap(find.text('Company / Business'));
      await tester.pumpAndSettle();
      expect(find.text('Company Name'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Nimal Jayasuriya');
      await tester.enterText(find.byType(TextFormField).at(2), '0771239876');
      await tester.enterText(find.byType(TextFormField).at(4), '45 Market Street, Colombo');
      await _selectRegion(tester);

      await _continue(tester);
      expect(find.text('Company name is required'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(3), 'FreshMart Lanka');
      await _continue(tester);

      expect(find.text('Buyer Home'), findsOneWidget);
    });

    testWidgets('hides company name for individual buyers and completes registration', (tester) async {
      await _prepareSurface(tester);
      await tester.pumpWidget(_profileApp(_buyerSession()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Individual Buyer'));
      await tester.pumpAndSettle();

      expect(find.text('Company Name'), findsNothing);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Contact Number'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Kasun Silva');
      await tester.enterText(find.byType(TextFormField).at(2), '0771112222');
      await tester.enterText(find.byType(TextFormField).at(3), '12 Lake Road, Kandy');
      await _selectRegion(tester);

      await _continue(tester);

      expect(find.text('Buyer Home'), findsOneWidget);
    });

    testWidgets('does not change the farmer profile setup form', (tester) async {
      await _prepareSurface(tester);
      await tester.pumpWidget(_profileApp(_farmerSession()));
      await tester.pumpAndSettle();

      expect(find.text('How are you buying?'), findsNothing);
      expect(find.text('How do you provide transport?'), findsNothing);
      expect(find.text('Company / Business'), findsNothing);
      expect(find.text('Individual Buyer'), findsNothing);
      expect(find.text('Transport Company / Business'), findsNothing);
      expect(find.text('Individual Transport Provider'), findsNothing);
      expect(find.text('Company Name'), findsNothing);
      expect(find.text('Complete Your Profile'), findsOneWidget);
    });
  });
}
