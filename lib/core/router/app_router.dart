import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/core/router/router_notifier.dart';
import 'package:my_app/features/admin/screens/admin_shell.dart';
import 'package:my_app/features/auth/screens/login_screen.dart';
import 'package:my_app/features/auth/screens/register_screen.dart';
import 'package:my_app/features/business/screens/business_demand_screen.dart';
import 'package:my_app/features/business/screens/business_interests_screen.dart';
import 'package:my_app/features/business/screens/business_production_detail_screen.dart';
import 'package:my_app/features/business/screens/business_shell.dart';
import 'package:my_app/features/business/screens/marketplace_screen.dart';
import 'package:my_app/features/farmer/screens/add_production_screen.dart';
import 'package:my_app/features/farmer/screens/crop_plan_form_screen.dart';
import 'package:my_app/features/farmer/screens/crop_plan_list_screen.dart';
import 'package:my_app/features/farmer/screens/farmer_demand_screen.dart';
import 'package:my_app/features/farmer/screens/farmer_production_detail_screen.dart';
import 'package:my_app/features/farmer/screens/farmer_shell.dart';
import 'package:my_app/features/government/screens/government_alerts_screen.dart';
import 'package:my_app/features/government/screens/government_analytics_screen.dart';
import 'package:my_app/features/government/screens/government_crop_planning_screen.dart';
import 'package:my_app/features/government/screens/government_logistics_screen.dart';
import 'package:my_app/features/government/screens/government_reports_screen.dart';
import 'package:my_app/features/government/screens/government_shell.dart';
import 'package:my_app/features/logistics/screens/buyer_checkout_screens.dart';
import 'package:my_app/features/logistics/screens/buyer_delivery_screens.dart';
import 'package:my_app/features/logistics/screens/farmer_logistics_screens.dart';
import 'package:my_app/features/logistics/screens/notifications_screen.dart';
import 'package:my_app/features/onboarding/screens/profile_setup_screen.dart';
import 'package:my_app/features/onboarding/screens/role_selection_screen.dart';
import 'package:my_app/features/onboarding/screens/splash_screen.dart';
import 'package:my_app/features/transporter/screens/transporter_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(state.uri.toString()),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.splash),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmerHome,
        builder: (context, state) => const FarmerShell(),
      ),
      GoRoute(
        path: AppRoutes.farmerAddProduction,
        builder: (context, state) => const AddProductionScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmerCropPlanNew,
        builder: (context, state) => const CropPlanFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmerCropPlanDetail,
        builder: (context, state) {
          return CropPlanFormScreen(planId: state.pathParameters['id']);
        },
      ),
      GoRoute(
        path: AppRoutes.farmerCropPlans,
        builder: (context, state) => const CropPlanListScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmerProductionDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FarmerProductionDetailScreen(productionId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.farmerDemand,
        builder: (context, state) => const FarmerDemandScreen(),
      ),
      GoRoute(
        path: AppRoutes.businessHome,
        builder: (context, state) => const BusinessShell(),
      ),
      GoRoute(
        path: AppRoutes.businessMarketplace,
        builder: (context, state) => const MarketplaceScreen(),
      ),
      GoRoute(
        path: AppRoutes.businessProductionDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BusinessProductionDetailScreen(productionId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.businessInterests,
        builder: (context, state) => const BusinessInterestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.businessDemand,
        builder: (context, state) => const BusinessDemandScreen(),
      ),
      GoRoute(
        path: AppRoutes.governmentHome,
        builder: (context, state) => const GovernmentShell(),
      ),
      GoRoute(
        path: AppRoutes.governmentAnalytics,
        builder: (context, state) => const GovernmentAnalyticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.governmentCropPlanning,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Crop planning insights')),
          body: const GovernmentCropPlanningScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.governmentReports,
        builder: (context, state) => const GovernmentReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.governmentAlerts,
        builder: (context, state) => const GovernmentAlertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.transporterHome,
        builder: (context, state) => const TransporterShell(),
      ),
      GoRoute(
        path: AppRoutes.transporterJobDetail,
        builder: (context, state) => TransporterJobDetailScreen(
          jobId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.farmerOrderDetail,
        builder: (context, state) => FarmerOrderDetailScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.businessPay,
        builder: (context, state) => BuyerPaymentScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.businessDeliveryMethod,
        builder: (context, state) => DeliveryMethodScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.businessAddress,
        builder: (context, state) => DeliveryAddressScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.businessMatches,
        builder: (context, state) => TransportMatchesScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.businessConfirmTransport,
        builder: (context, state) => TransportConfirmScreen(
          jobId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.businessTracking,
        builder: (context, state) => DeliveryTrackingScreen(
          jobId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.businessReceive,
        builder: (context, state) => ConfirmDeliveryScreen(
          jobId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.businessIssue,
        builder: (context, state) => ReportIssueScreen(
          jobId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.governmentLogistics,
        builder: (context, state) => const GovernmentLogisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminShell(),
      ),
    ],
  );
});
