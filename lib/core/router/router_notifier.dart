import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/core/router/routes.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

/// Keeps [GoRouter] stable while auth changes trigger redirect re-evaluation.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.read(authProvider);
    final path = _normalizePath(state.uri.path);
    final isAuthenticated = auth.isAuthenticated;
    final hasProfile = auth.profile?.isVerified ?? false;
    final role = auth.selectedRole ?? auth.profile?.role;

    final isAuthRoute = path == AppRoutes.login ||
        path == AppRoutes.register ||
        path == AppRoutes.roleSelection ||
        path == AppRoutes.splash;

    if (!isAuthenticated && !isAuthRoute) {
      return AppRoutes.splash;
    }

    if (isAuthenticated && !hasProfile && path != AppRoutes.profileSetup) {
      return AppRoutes.profileSetup;
    }

    if (isAuthenticated && hasProfile && isAuthRoute) {
      return _homeForRole(role);
    }

    if (isAuthenticated && hasProfile) {
      if (path.startsWith('/farmer') && role != UserRole.farmer) {
        return _homeForRole(role);
      }
      if (path.startsWith('/business') && role != UserRole.business) {
        return _homeForRole(role);
      }
      if (path.startsWith('/government') && role != UserRole.government) {
        return _homeForRole(role);
      }
      if (path.startsWith('/admin') && role != UserRole.admin) {
        return _homeForRole(role);
      }
    }

    return null;
  }

  /// Web path URLs may include trailing slashes or empty segments.
  String _normalizePath(String path) {
    if (path.isEmpty || path == '/') return AppRoutes.splash;
    return path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
  }
}

String _homeForRole(UserRole? role) {
  switch (role) {
    case UserRole.business:
      return AppRoutes.businessHome;
    case UserRole.government:
      return AppRoutes.governmentHome;
    case UserRole.transporter:
      return AppRoutes.transporterHome;
    case UserRole.admin:
      return AppRoutes.adminHome;
    case UserRole.farmer:
    default:
      return AppRoutes.farmerHome;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});
