import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/shared/data/mock_data.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/logic/aggregation_logic.dart';
import 'package:my_app/shared/logic/bidding_logic.dart';
import 'package:my_app/shared/logic/crop_planning_aggregation.dart';

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
        ? (normalized == 'farmer@agrilink.lk' ? _farmerDemo() : null)
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

  static UserProfile _farmerDemo() {
    return const UserProfile(
      id: MockData.farmerUserId,
      name: 'Sunil Perera',
      email: 'farmer@agrilink.lk',
      phone: '0771234567',
      role: UserRole.farmer,
      region: 'North Western Province',
      isVerified: true,
    );
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
      case 'admin@agrilink.lk':
      case 'admin@bit.app':
        return const UserProfile(
          id: 'admin-demo',
          name: 'Platform Moderator',
          email: 'admin@agrilink.lk',
          phone: '+94110000000',
          role: UserRole.admin,
          organizationName: 'AgriLink Operations',
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
    required this.cropPlans,
    this.bids = const [],
  });

  final List<Production> productions;
  final List<DemandRequest> demands;
  final List<PurchaseInterest> interests;
  final List<CropPlan> cropPlans;
  final List<MarketBid> bids;

  AppDataState copyWith({
    List<Production>? productions,
    List<DemandRequest>? demands,
    List<PurchaseInterest>? interests,
    List<CropPlan>? cropPlans,
    List<MarketBid>? bids,
  }) {
    return AppDataState(
      productions: productions ?? this.productions,
      demands: demands ?? this.demands,
      interests: interests ?? this.interests,
      cropPlans: cropPlans ?? this.cropPlans,
      bids: bids ?? this.bids,
    );
  }
}

class AppDataNotifier extends StateNotifier<AppDataState> {
  AppDataNotifier()
      : super(AppDataState(
          productions: List.from(MockData.productions),
          demands: List.from(MockData.demands),
          interests: List.from(MockData.interests),
          cropPlans: List.from(MockData.cropPlans),
        ));

  void addProduction(Production production) {
    state = state.copyWith(
      productions: [production, ...state.productions],
    );
  }

  void addCropPlan(CropPlan plan) {
    state = state.copyWith(cropPlans: [plan, ...state.cropPlans]);
  }

  void updateCropPlan(CropPlan plan) {
    state = state.copyWith(
      cropPlans: state.cropPlans
          .map((p) => p.id == plan.id ? plan : p)
          .toList(),
    );
  }

  void cancelCropPlan(String id) {
    state = state.copyWith(
      cropPlans: state.cropPlans
          .map(
            (p) => p.id == id
                ? p.copyWith(status: CropPlanStatus.cancelled)
                : p,
          )
          .toList(),
    );
  }

  void closeExpiredAuctions({
    void Function(String userId, String title, String body)? notify,
  }) {
    final now = DateTime.now();
    var changed = false;
    final listings = state.productions.map((listing) {
      final due = (listing.auctionStatus == ListingAuctionStatus.open ||
              listing.auctionStatus == ListingAuctionStatus.expiredPendingClose) &&
          listing.biddingWindowEnd != null &&
          now.isAfter(listing.biddingWindowEnd!);
      if (!due) return listing;
      changed = true;
      final qualifies = BidEngine.qualifiesForFarmerConfirmation(
        currentHighestBid: listing.currentHighestBid,
        reservePrice: listing.reservePrice,
      );
      if (qualifies) {
        notify?.call(
          listing.farmerId,
          'listing_closed_winner',
          'Bidding closed on ${listing.cropType}. Highest bid LKR ${listing.currentHighestBid.toStringAsFixed(0)}/kg — confirm or decline.',
        );
        return listing.copyWith(
          auctionStatus: ListingAuctionStatus.awaitingFarmerConfirmation,
        );
      }
      notify?.call(
        listing.farmerId,
        'listing_expired',
        'Your ${listing.cropType} listing expired with no bid at or above the reserve.',
      );
      return listing.copyWith(
        auctionStatus: ListingAuctionStatus.expiredNoSale,
        status: ProductionStatus.expired,
      );
    }).toList();
    if (changed) state = state.copyWith(productions: listings);
  }

  String? placeBid({
    required Production listing,
    required UserProfile buyer,
    required double amount,
    void Function(String userId, String title, String body)? notify,
  }) {
    closeExpiredAuctions(notify: notify);
    final current = getProduction(listing.id);
    if (current == null) return 'Listing not found';
    if (current.moderated || current.auctionStatus == ListingAuctionStatus.hidden) {
      return 'Listing is not open for bidding';
    }

    final now = DateTime.now();
    final windowClosed = current.biddingWindowEnd != null &&
        now.isAfter(current.biddingWindowEnd!);
    if (windowClosed && current.auctionStatus == ListingAuctionStatus.open) {
      state = state.copyWith(
        productions: state.productions
            .map(
              (p) => p.id == current.id
                  ? p.copyWith(auctionStatus: ListingAuctionStatus.expiredPendingClose)
                  : p,
            )
            .toList(),
      );
      closeExpiredAuctions(notify: notify);
      return 'Bidding window has closed';
    }

    final error = BidEngine.submitBidError(
      listingActive: current.auctionStatus == ListingAuctionStatus.open,
      now: now,
      biddingWindowEnd: current.biddingWindowEnd,
      currentHighestBid: current.currentHighestBid,
      minIncrement: current.minIncrement,
      reservePrice: current.reservePrice,
      bidAmount: amount,
    );
    if (error != null) return error;
    if (!buyer.isVerified) {
      return 'Only verified buyers can bid';
    }

    final previousBidders = state.bids
        .where((b) => b.listingId == current.id && b.buyerId != buyer.id)
        .map((b) => b.buyerId)
        .toSet();
    if (current.currentHighestBidderId != null &&
        current.currentHighestBidderId != buyer.id) {
      previousBidders.add(current.currentHighestBidderId!);
    }
    final bid = MarketBid(
      id: 'bid-${DateTime.now().millisecondsSinceEpoch}',
      listingId: current.id,
      buyerId: buyer.id,
      buyerName: buyer.organizationName ?? buyer.name,
      amount: amount,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      bids: [bid, ...state.bids],
      productions: state.productions
          .map(
            (p) => p.id == current.id
                ? p.copyWith(
                    currentHighestBid: amount,
                    currentHighestBidderId: buyer.id,
                  )
                : p,
          )
          .toList(),
    );

    notify?.call(
      current.farmerId,
      'new_highest_bid',
      'New highest bid LKR ${amount.toStringAsFixed(0)}/kg on ${current.cropType}.',
    );
    for (final bidderId in previousBidders) {
      notify?.call(
        bidderId,
        'You were outbid',
        'A higher bid of LKR ${amount.toStringAsFixed(0)}/kg was placed on ${current.cropType}.',
      );
    }
    return null;
  }

  void confirmWinningBid(String listingId) {
    closeExpiredAuctions();
    final listing = getProduction(listingId);
    if (listing == null) return;
    state = state.copyWith(
      productions: state.productions
          .map(
            (p) => p.id == listingId
                ? p.copyWith(
                    auctionStatus: ListingAuctionStatus.sold,
                    status: ProductionStatus.sold,
                  )
                : p,
          )
          .toList(),
    );
  }

  void declineWinningBid(String listingId) {
    state = state.copyWith(
      productions: state.productions
          .map(
            (p) => p.id == listingId
                ? p.copyWith(
                    auctionStatus: ListingAuctionStatus.cancelled,
                    status: ProductionStatus.available,
                    currentHighestBid: 0,
                    clearHighestBidder: true,
                  )
                : p,
          )
          .toList(),
    );
  }

  void moderateListing(String listingId, {required bool hidden}) {
    state = state.copyWith(
      productions: state.productions
          .map(
            (p) => p.id == listingId
                ? p.copyWith(
                    moderated: hidden,
                    auctionStatus: hidden
                        ? ListingAuctionStatus.hidden
                        : ListingAuctionStatus.open,
                  )
                : p,
          )
          .toList(),
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
  final now = DateTime.now();
  return data.productions.where((p) {
    if (p.moderated) return false;
    if (p.auctionStatus != ListingAuctionStatus.open) return false;
    if (p.biddingWindowEnd != null && now.isAfter(p.biddingWindowEnd!)) {
      return false;
    }
    return p.status == ProductionStatus.available ||
        p.status == ProductionStatus.readyForHarvest;
  }).toList();
});

final listingBidsProvider = Provider.family<List<MarketBid>, String>((ref, listingId) {
  return ref
      .watch(appDataProvider)
      .bids
      .where((b) => b.listingId == listingId)
      .toList();
});

final farmerPendingConfirmationsProvider = Provider<List<Production>>((ref) {
  final farmerId = ref.watch(authProvider).profile?.id;
  if (farmerId == null) return const [];
  final now = DateTime.now();
  return ref.watch(appDataProvider).productions.where((p) {
    if (p.farmerId != farmerId) return false;
    if (p.auctionStatus == ListingAuctionStatus.awaitingFarmerConfirmation) {
      return true;
    }
    if (p.auctionStatus == ListingAuctionStatus.open &&
        p.biddingWindowEnd != null &&
        now.isAfter(p.biddingWindowEnd!) &&
        p.currentHighestBid >= p.reservePrice &&
        p.currentHighestBid > 0) {
      return true;
    }
    return false;
  }).toList();
});

final aggregatedSupplyProvider = Provider<List<AggregatedReport>>((ref) {
  final data = ref.watch(appDataProvider);
  final sold = data.productions.where(
    (p) =>
        p.auctionStatus == ListingAuctionStatus.sold && p.currentHighestBid > 0,
  );
  final transactions = sold
      .map(
        (p) => ClearingTransaction(
          region: p.region,
          cropType: p.cropType,
          period: reportPeriod(p.createdAt ?? p.harvestDate),
          farmerId: p.farmerId,
          clearingPrice: p.currentHighestBid,
        ),
      )
      .toList();
  return generateAllAggregatedReports(
    listings: data.productions,
    transactions: transactions,
  );
});

final publishedRegionalAnalyticsProvider = Provider<List<RegionalAnalytics>>((ref) {
  return MockData.regionalAnalytics
      .where((a) => a.farmerCount >= BidValidation.kAnonymityThreshold)
      .toList();
});

final farmerCropPlansProvider = Provider<List<CropPlan>>((ref) {
  final farmerId = ref.watch(authProvider).profile?.id;
  if (farmerId == null) return const [];
  return ref
      .watch(appDataProvider)
      .cropPlans
      .where((p) => p.farmerId == farmerId)
      .toList();
});

final cropPlanInsightsProvider = Provider<List<CropDemandInsight>>((ref) {
  final data = ref.watch(appDataProvider);
  return cropDemandInsights(plans: data.cropPlans, demands: data.demands);
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
