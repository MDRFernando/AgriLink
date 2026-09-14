import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/features/onboarding/screens/profile_setup_screen.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

AuthNotifier _transporterSession({
  String email = 'driver@test.lk',
  String name = 'Saman Perera',
}) {
  final auth = AuthNotifier();
  auth.selectRole(UserRole.transporter);
  auth.login(email: email, name: name);
  return auth;
}

AuthNotifier _buyerSession() {
  final auth = AuthNotifier();
  auth.selectRole(UserRole.business);
  auth.login(email: 'buyer@test.lk', name: 'Kasun Silva');
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
            path: '/transporter',
            builder: (_, __) => const Scaffold(body: Text('Transporter Home')),
          ),
          GoRoute(
            path: '/business',
            builder: (_, __) => const Scaffold(body: Text('Buyer Home')),
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
  group('AuthNotifier transporter type', () {
    test('stores company transporter details and restores them after login', () {
      final auth = _transporterSession(email: 'company-t@test.lk');
      auth.completeProfile(
        name: 'Ruwan Fernando',
        phone: '0777771111',
        organizationName: 'ABC Logistics',
        region: 'North Western Province',
        transporterType: TransporterType.company,
      );

      expect(auth.state.profile!.isCompanyTransporter, isTrue);
      expect(auth.state.profile!.organizationName, 'ABC Logistics');

      auth.logout();
      auth.selectRole(UserRole.transporter);
      auth.login(email: 'company-t@test.lk');

      expect(auth.state.profile!.transporterType, TransporterType.company);
      expect(auth.state.profile!.organizationName, 'ABC Logistics');
      expect(auth.state.profile!.displayName, 'ABC Logistics');
      expect(auth.state.isAuthenticated, isTrue);
    });

    test('lets individual transporters register without a company name', () {
      final auth = _transporterSession(email: 'individual-t@test.lk');
      auth.completeProfile(
        name: 'Saman Perera',
        phone: '0777772222',
        organizationName: null,
        region: 'Western Province',
        transporterType: TransporterType.individual,
      );

      expect(auth.state.profile!.isIndividualTransporter, isTrue);
      expect(auth.state.profile!.organizationName, isNull);
      expect(auth.state.profile!.name, 'Saman Perera');

      auth.logout();
      auth.selectRole(UserRole.transporter);
      auth.login(email: 'individual-t@test.lk');

      expect(auth.state.profile!.transporterType, TransporterType.individual);
      expect(auth.state.profile!.organizationName, isNull);
      expect(auth.state.profile!.displayName, 'Saman Perera');
    });
  });

  group('Transporter profile setup UI', () {
    testWidgets('requires transporter type before continuing', (tester) async {
      await _prepareSurface(tester);
      await tester.pumpWidget(_profileApp(_transporterSession()));
      await tester.pumpAndSettle();

      await _continue(tester);

      expect(find.text('Transport provider type is required'), findsOneWidget);
      expect(find.text('Please select how you provide transport'), findsOneWidget);
    });

    testWidgets('shows company name only for transport companies and requires it', (tester) async {
      await _prepareSurface(tester);
      await tester.pumpWidget(_profileApp(_transporterSession()));
      await tester.pumpAndSettle();

      expect(find.text('How do you provide transport?'), findsOneWidget);
      expect(find.text('Company Name'), findsNothing);

      await tester.tap(find.text('Transport Company / Business'));
      await tester.pumpAndSettle();
      expect(find.text('Company Name'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Ruwan Fernando');
      await tester.enterText(find.byType(TextFormField).at(1), '0777771111');
      await _selectRegion(tester);

      await _continue(tester);
      expect(find.text('Company name is required'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(2), 'ABC Logistics');
      await _continue(tester);

      expect(find.text('Transporter Home'), findsOneWidget);
    });

    testWidgets('hides company name for individual transporters and completes registration', (tester) async {
      await _prepareSurface(tester);
      await tester.pumpWidget(_profileApp(_transporterSession()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Individual Transport Provider'));
      await tester.pumpAndSettle();

      expect(find.text('Company Name'), findsNothing);
      expect(find.text('Full Name'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Saman Perera');
      await tester.enterText(find.byType(TextFormField).at(1), '0777772222');
      await _selectRegion(tester);

      await _continue(tester);

      expect(find.text('Transporter Home'), findsOneWidget);
    });

    testWidgets('does not change the buyer profile setup form', (tester) async {
      await _prepareSurface(tester);
      await tester.pumpWidget(_profileApp(_buyerSession()));
      await tester.pumpAndSettle();

      expect(find.text('How do you provide transport?'), findsNothing);
      expect(find.text('Transport Company / Business'), findsNothing);
      expect(find.text('Individual Transport Provider'), findsNothing);
      expect(find.text('How are you buying?'), findsOneWidget);
    });
  });
}
