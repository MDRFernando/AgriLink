import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/shared/data/mock_data.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.selectedRole,
    this.profile,
  });

  final bool isAuthenticated;
  final UserRole? selectedRole;
  final UserProfile? profile;

  AuthState copyWith({
    bool? isAuthenticated,
    UserRole? selectedRole,
    UserProfile? profile,
    bool clearProfile = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      selectedRole: selectedRole ?? this.selectedRole,
      profile: clearProfile ? null : (profile ?? this.profile),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void selectRole(UserRole role) {
    state = state.copyWith(selectedRole: role);
  }

  void login({required String email}) {
    final normalized = email.trim().toLowerCase();
    final demo = state.selectedRole == UserRole.farmer
        ? null
        : _demoProfile(normalized);
    if (demo != null) {
      state = AuthState(
        isAuthenticated: true,
        selectedRole: demo.role,
        profile: demo,
      );
      return;
    }

    final role = state.selectedRole ?? UserRole.farmer;
    state = AuthState(
      isAuthenticated: true,
      selectedRole: role,
      profile: UserProfile(
        id: _accountId(role, email),
        name: '',
        email: email,
        phone: '',
        role: role,
        isVerified: false,
      ),
    );
  }

  static String _accountId(UserRole role, String email) {
    final slug = email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
    return '${role.name}-$slug';
  }

  static UserProfile? _demoProfile(String email) {
    switch (email) {
      case 'business@agrilink.lk':
        return const UserProfile(
          id: 'business-demo',
          name: 'Nimal Jayasuriya',
          email: 'business@agrilink.lk',
          phone: '0771239876',
          role: UserRole.business,
          organizationName: 'ABC Supermarket',
          region: 'Western Province',
          isVerified: true,
        );
      case 'transporter@agrilink.lk':
        return const UserProfile(
          id: 'transporter-demo',
          name: 'Ruwan Fernando',
          email: 'transporter@agrilink.lk',
          phone: '0777771111',
          role: UserRole.transporter,
          organizationName: 'ABC Logistics',
          region: 'North Western Province',
          isVerified: true,
        );
      case 'gov@agrilink.lk':
        return const UserProfile(
          id: 'government-demo',
          name: 'Agri Officer',
          email: 'gov@agrilink.lk',
          phone: '+94113456789',
          role: UserRole.government,
          organizationName: 'Ministry of Agriculture',
          region: 'Western Province',
          isVerified: true,
        );
      default:
        return null;
    }
  }

  void completeProfile({
    required String name,
    required String phone,
    String? organizationName,
    String? region,
  }) {
    final current = state.profile;
    if (current == null) return;

    state = state.copyWith(
      profile: current.copyWith(
        name: name,
        phone: phone,
        organizationName: organizationName,
        region: region,
        isVerified: true,
      ),
    );
  }

  void logout() {
    state = const AuthState();
  }
}

class AppDataState {
  const AppDataState({
    required this.productions,
    required this.demands,
    required this.interests,
  });

  final List<Production> productions;
  final List<DemandRequest> demands;
  final List<PurchaseInterest> interests;

  AppDataState copyWith({
    List<Production>? productions,
    List<DemandRequest>? demands,
    List<PurchaseInterest>? interests,
  }) {
    return AppDataState(
      productions: productions ?? this.productions,
      demands: demands ?? this.demands,
      interests: interests ?? this.interests,
    );
  }
}

class AppDataNotifier extends StateNotifier<AppDataState> {
  AppDataNotifier()
      : super(AppDataState(
          productions: List.from(MockData.productions),
          demands: List.from(MockData.demands),
          interests: List.from(MockData.interests),
        ));

  void addProduction(Production production) {
    state = state.copyWith(
      productions: [production, ...state.productions],
    );
  }

  void updateProduction(Production production) {
    state = state.copyWith(
      productions: state.productions
          .map((p) => p.id == production.id ? production : p)
          .toList(),
    );
  }

  void updateProductionStatus(String id, ProductionStatus status) {
    state = state.copyWith(
      productions: state.productions
          .map((p) => p.id == id ? p.copyWith(status: status) : p)
          .toList(),
    );
  }

  void addInterest(PurchaseInterest interest) {
    state = state.copyWith(
      interests: [interest, ...state.interests],
    );
  }

  void updateInterestStatus(String id, InterestStatus status) {
    state = state.copyWith(
      interests: state.interests
          .map((i) => i.id == id ? i.copyWith(status: status) : i)
          .toList(),
    );
  }

  Production? getProduction(String id) {
    try {
      return state.productions.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final appDataProvider = StateNotifierProvider<AppDataNotifier, AppDataState>((ref) {
  return AppDataNotifier();
});

final farmerProductionsProvider = Provider<List<Production>>((ref) {
  final farmerId = ref.watch(authProvider).profile?.id;
  if (farmerId == null) return const [];
  return ref
      .watch(appDataProvider)
      .productions
      .where((p) => p.farmerId == farmerId)
      .toList();
});

final availableProductionsProvider = Provider<List<Production>>((ref) {
  final data = ref.watch(appDataProvider);
  return data.productions
      .where((p) =>
          p.status == ProductionStatus.available ||
          p.status == ProductionStatus.readyForHarvest)
      .toList();
});

final farmerInterestsProvider = Provider<List<PurchaseInterest>>((ref) {
  final farmerId = ref.watch(authProvider).profile?.id;
  if (farmerId == null) return const [];
  final data = ref.watch(appDataProvider);
  final farmerProductionIds = data.productions
      .where((p) => p.farmerId == farmerId)
      .map((p) => p.id)
      .toSet();
  return data.interests
      .where((i) => farmerProductionIds.contains(i.productionId))
      .toList();
});

final businessInterestsProvider = Provider<List<PurchaseInterest>>((ref) {
  final auth = ref.watch(authProvider);
  final data = ref.watch(appDataProvider);
  final businessId = auth.profile?.id ?? MockData.businessUserId;
  return data.interests.where((i) => i.businessId == businessId).toList();
});
