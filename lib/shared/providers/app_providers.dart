import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/api/api_client.dart';
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

  final Map<String, UserProfile> _savedProfiles = {};

  void selectRole(UserRole role) {
    state = state.copyWith(selectedRole: role);
  }

  void login({required String email, String? name}) {
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

    final saved = _savedProfiles[normalized];
    if (saved != null) {
      state = AuthState(
        isAuthenticated: true,
        selectedRole: saved.role,
        profile: saved,
      );
      return;
    }

    final role = state.selectedRole ?? UserRole.farmer;
    final profile = UserProfile(
      id: _accountId(role, email),
      name: name?.trim() ?? '',
      email: email.trim(),
      phone: '',
      role: role,
      isVerified: false,
    );
    _savedProfiles[normalized] = profile;
    state = AuthState(
      isAuthenticated: true,
      selectedRole: role,
      profile: profile,
    );
  }

  Future<String?> signIn({
    required String email,
    required String password,
    String? name,
    bool register = false,
  }) async {
    final role = state.selectedRole ?? UserRole.farmer;
    try {
      final profile = register
          ? await AgriLinkApi.instance.register(
              email: email,
              password: password,
              name: name ?? '',
              role: role,
            )
          : await AgriLinkApi.instance.login(email, password);
      _savedProfiles[profile.email.trim().toLowerCase()] = profile;
      state = AuthState(
        isAuthenticated: true,
        selectedRole: profile.role,
        profile: profile,
      );
      return null;
    } on AgriLinkApiException catch (error) {
      if (register) return error.message;
      login(email: email, name: name);
      if (state.isAuthenticated) return null;
      return error.message;
    }
  }

  Future<String?> completeProfileRemote({
    required String name,
    required String phone,
    String? organizationName,
    String? region,
    String? address,
    BuyerType? buyerType,
    TransporterType? transporterType,
  }) async {
    completeProfile(
      name: name,
      phone: phone,
      organizationName: organizationName,
      region: region,
      address: address,
      buyerType: buyerType,
      transporterType: transporterType,
    );
    if (!AgriLinkApi.instance.hasToken) return null;
    try {
      final profile = await AgriLinkApi.instance.updateProfile(
        name: name,
        phone: phone,
        region: region ?? '',
        organizationName: organizationName,
        address: address,
        buyerType: buyerType,
        transporterType: transporterType,
      );
      _savedProfiles[profile.email.trim().toLowerCase()] = profile;
      state = state.copyWith(profile: profile.copyWith(isVerified: true));
      return null;
    } on AgriLinkApiException catch (error) {
      return error.message;
    }
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
          buyerType: BuyerType.company,
          address: '123 Main Street, Colombo',
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
          transporterType: TransporterType.company,
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
    String? address,
    BuyerType? buyerType,
    TransporterType? transporterType,
  }) {
    final current = state.profile;
    if (current == null) return;

    final clearOrg = buyerType == BuyerType.individual ||
        transporterType == TransporterType.individual;
    final updated = current.copyWith(
      name: name,
      phone: phone,
      organizationName: clearOrg ? null : organizationName,
      clearOrganizationName: clearOrg,
      region: region,
      address: address,
      buyerType: buyerType,
      transporterType: transporterType,
      isVerified: true,
    );
    _savedProfiles[updated.email.trim().toLowerCase()] = updated;
    state = state.copyWith(profile: updated);
  }

  void logout() {
    AgriLinkApi.instance.clear();
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

  Future<String?> publishProduction(Production production) async {
    if (!AgriLinkApi.instance.hasToken) {
      addProduction(production);
      return null;
    }
    try {
      final created = await AgriLinkApi.instance.createProduction({
        'cropType': production.cropType,
        'quantity': production.quantity,
        'unit': production.unit,
        'harvestDate': production.harvestDate.toIso8601String(),
        'region': production.region,
        'location': production.location,
        'status': 'available',
        'notes': production.notes,
        'qualityGrade': production.qualityGrade.name.toUpperCase(),
        'minAcceptablePrice': production.reservePrice,
        'openingBid': production.reservePrice,
        'minIncrement': production.minIncrement,
        if (production.biddingWindowEnd != null)
          'auctionEndTime': production.biddingWindowEnd!.toIso8601String(),
      });
      addProduction(created);
      return null;
    } on AgriLinkApiException catch (error) {
      return error.message;
    }
  }

  Future<void> syncFromApi(UserRole? role) async {
    if (!AgriLinkApi.instance.hasToken) return;
    try {
      final listings = role == UserRole.farmer
          ? await AgriLinkApi.instance.fetchMyProductions()
          : await AgriLinkApi.instance.fetchAvailableProductions();
      List<MarketBid> bids = const [];
      if (role == UserRole.farmer) {
        bids = await AgriLinkApi.instance.fetchFarmerBids();
      } else if (role == UserRole.business) {
        bids = await AgriLinkApi.instance.fetchBuyerBids();
      }
      state = state.copyWith(productions: listings, bids: bids);
    } on AgriLinkApiException {
      // Keep local data if the API is briefly unavailable.
    }
  }

  Future<void> refreshBids(UserRole? role) => syncFromApi(role);

  void upsertProduction(Production listing) {
    final listings = [...state.productions];
    final index = listings.indexWhere((p) => p.id == listing.id);
    if (index >= 0) {
      listings[index] = listing;
    } else {
      listings.insert(0, listing);
    }
    state = state.copyWith(productions: listings);
  }

  Future<void> refreshListingAndBuyerBids(String listingId) async {
    closeExpiredAuctions();
    if (!AgriLinkApi.instance.hasToken) return;
    try {
      final listing = await AgriLinkApi.instance.fetchProduction(listingId);
      upsertProduction(listing);
    } on AgriLinkApiException {
      // Listing may have been removed.
    }
    try {
      final mine = await AgriLinkApi.instance.fetchBuyerBids();
      state = state.copyWith(bids: mine);
    } on AgriLinkApiException {
      // Keep local bids if the API is briefly unavailable.
    }
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
    var listingsChanged = false;
    var bidsChanged = false;
    final listings = state.productions.map((listing) {
      final due = (listing.auctionStatus == ListingAuctionStatus.open ||
              listing.auctionStatus == ListingAuctionStatus.expiredPendingClose) &&
          listing.biddingWindowEnd != null &&
          now.isAfter(listing.biddingWindowEnd!);
      if (!due) return listing;
      listingsChanged = true;
      final pending = state.bids.where(
        (b) => b.listingId == listing.id && b.status == BidStatus.pending,
      );
      if (listing.quantity <= 0) {
        return listing.copyWith(
          auctionStatus: ListingAuctionStatus.sold,
          status: ProductionStatus.sold,
        );
      }
      if (pending.isNotEmpty) {
        notify?.call(
          listing.farmerId,
          'listing_closed_winner',
          'Bidding closed on ${listing.cropType}. Review pending bids to accept or decline.',
        );
        return listing.copyWith(
          auctionStatus: ListingAuctionStatus.awaitingFarmerConfirmation,
        );
      }
      notify?.call(
        listing.farmerId,
        'listing_expired',
        'Your ${listing.cropType} listing expired with no pending bids.',
      );
      return listing.copyWith(
        auctionStatus: ListingAuctionStatus.expiredNoSale,
        status: ProductionStatus.expired,
      );
    }).toList();

    final listingsById = {for (final listing in listings) listing.id: listing};
    final bids = state.bids.map((bid) {
      if (bid.status != BidStatus.pending) return bid;
      final listing = listingsById[bid.listingId];
      if (listing == null) return bid;
      final soldOut = listing.quantity <= 0 ||
          listing.auctionStatus == ListingAuctionStatus.sold;
      final listingExpired =
          listing.auctionStatus == ListingAuctionStatus.expiredNoSale;
      if (soldOut || listingExpired) {
        bidsChanged = true;
        return bid.copyWith(status: BidStatus.expired);
      }
      return bid;
    }).toList();

    if (listingsChanged || bidsChanged) {
      state = state.copyWith(
        productions: listingsChanged ? listings : null,
        bids: bidsChanged ? bids : null,
      );
    }
  }

  Future<String?> placeBid({
    required Production listing,
    required UserProfile buyer,
    required double amount,
    required double quantity,
    void Function(String userId, String title, String body)? notify,
  }) async {
    closeExpiredAuctions(notify: notify);
    final current = getProduction(listing.id);
    if (current == null) return 'Listing not found';
    if (current.farmerId == buyer.id) {
      return 'Farmers cannot bid on their own listings';
    }
    if (current.moderated || current.auctionStatus == ListingAuctionStatus.hidden) {
      return 'Listing is not open for bidding';
    }

    final now = DateTime.now();
    final windowClosed = current.biddingWindowEnd != null &&
        now.isAfter(current.biddingWindowEnd!);
    if (windowClosed) {
      return 'Bidding window has closed';
    }
    if (current.status == ProductionStatus.sold ||
        current.status == ProductionStatus.expired ||
        current.quantity <= 0 ||
        current.auctionStatus != ListingAuctionStatus.open) {
      return 'Listing is not open for bidding';
    }

    final error = BidEngine.submitOfferError(
      listingActive: current.auctionStatus == ListingAuctionStatus.open,
      now: now,
      biddingWindowEnd: current.biddingWindowEnd,
      reservePrice: current.reservePrice,
      bidAmount: amount,
      quantity: quantity,
      availableQuantity: current.quantity,
    );
    if (error != null) return error;
    if (!buyer.isVerified) {
      return 'Only verified buyers can bid';
    }
    if (buyer.role != UserRole.business) {
      return 'Only buyers can place bids';
    }

    if (AgriLinkApi.instance.hasToken) {
      try {
        await AgriLinkApi.instance.placeBid(
          listingId: current.id,
          amount: amount,
          quantity: quantity,
        );
        final updatedListing = await AgriLinkApi.instance.fetchProduction(current.id);
        final mine = await AgriLinkApi.instance.fetchBuyerBids();
        final listings = <Production>[
          for (final p in state.productions)
            if (p.id == updatedListing.id) updatedListing else p,
        ];
        if (!listings.any((p) => p.id == updatedListing.id)) {
          listings.insert(0, updatedListing);
        }
        state = state.copyWith(productions: listings, bids: mine);
        notify?.call(
          updatedListing.farmerId,
          'new_bid',
          '${buyer.displayName} bid LKR ${amount.toStringAsFixed(0)}/${updatedListing.unit} for ${quantity.toStringAsFixed(0)} ${updatedListing.unit} of ${updatedListing.cropType}.',
        );
        return null;
      } on AgriLinkApiException catch (error) {
        return error.message;
      }
    }

    final bid = MarketBid(
      id: 'bid-${DateTime.now().millisecondsSinceEpoch}',
      listingId: current.id,
      farmerId: current.farmerId,
      buyerId: buyer.id,
      buyerName: buyer.displayName,
      cropType: current.cropType,
      quantity: quantity,
      unit: current.unit,
      amount: amount,
      createdAt: now,
      status: BidStatus.pending,
      biddingWindowEnd: current.biddingWindowEnd,
    );

    final highest = amount > current.currentHighestBid
        ? amount
        : current.currentHighestBid;

    state = state.copyWith(
      bids: [bid, ...state.bids],
      productions: state.productions
          .map(
            (p) => p.id == current.id
                ? p.copyWith(
                    currentHighestBid: highest,
                    currentHighestBidderId: amount >= current.currentHighestBid
                        ? buyer.id
                        : current.currentHighestBidderId,
                  )
                : p,
          )
          .toList(),
    );

    notify?.call(
      current.farmerId,
      'new_bid',
      '${bid.buyerName} bid LKR ${amount.toStringAsFixed(0)}/kg for ${quantity.toStringAsFixed(0)} ${current.unit} of ${current.cropType}.',
    );
    return null;
  }

  MarketBid? getBid(String bidId) {
    try {
      return state.bids.firstWhere((b) => b.id == bidId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> acceptBid({
    required String bidId,
    required String farmerId,
    String? orderId,
    void Function(String userId, String title, String body)? notify,
  }) async {
    closeExpiredAuctions(notify: notify);
    final bid = getBid(bidId);
    if (bid == null) return 'Bid not found';
    if (bid.farmerId != farmerId) {
      return "You can only accept bids on your own listings";
    }
    if (bid.status == BidStatus.accepted) {
      return 'This bid has already been accepted';
    }
    if (bid.status != BidStatus.pending) {
      return 'Only pending bids can be accepted';
    }

    if (AgriLinkApi.instance.hasToken) {
      try {
        await AgriLinkApi.instance.acceptBid(bidId);
        await syncFromApi(UserRole.farmer);
        notify?.call(
          bid.buyerId,
          'Bid accepted',
          'Your bid for ${bid.quantity.toStringAsFixed(0)} ${bid.unit} of ${bid.cropType} was accepted. An order has been created.',
        );
        return null;
      } on AgriLinkApiException catch (error) {
        return error.message;
      }
    }

    final listing = getProduction(bid.listingId);
    if (listing == null) return 'Listing not found';
    if (listing.farmerId != farmerId) {
      return "You can only accept bids on your own listings";
    }
    if (bid.quantity > listing.quantity) {
      return 'Quantity exceeds available stock';
    }

    final remaining = listing.quantity - bid.quantity;
    final soldOut = remaining <= 0;
    final windowClosed = listing.biddingWindowEnd != null &&
        DateTime.now().isAfter(listing.biddingWindowEnd!);

    final bids = state.bids.map((b) {
      if (b.id == bid.id) {
        return b.copyWith(status: BidStatus.accepted, orderId: orderId);
      }
      if (b.listingId != listing.id || b.status != BidStatus.pending) {
        return b;
      }
      if (soldOut || b.quantity > remaining) {
        return b.copyWith(status: BidStatus.expired);
      }
      return b;
    }).toList();

    state = state.copyWith(
      bids: bids,
      productions: state.productions
          .map(
            (p) => p.id == listing.id
                ? p.copyWith(
                    quantity: remaining,
                    status: soldOut ? ProductionStatus.sold : p.status,
                    auctionStatus: soldOut
                        ? ListingAuctionStatus.sold
                        : (windowClosed
                            ? ListingAuctionStatus.awaitingFarmerConfirmation
                            : p.auctionStatus),
                  )
                : p,
          )
          .toList(),
    );

    notify?.call(
      bid.buyerId,
      'Bid accepted',
      'Your bid for ${bid.quantity.toStringAsFixed(0)} ${bid.unit} of ${bid.cropType} was accepted. An order has been created.',
    );
    notify?.call(
      farmerId,
      'Order created',
      'Accepted ${bid.buyerName}\'s bid for ${bid.quantity.toStringAsFixed(0)} ${bid.unit} of ${bid.cropType}.',
    );
    return null;
  }

  Future<String?> declineBid({
    required String bidId,
    required String farmerId,
    void Function(String userId, String title, String body)? notify,
  }) async {
    closeExpiredAuctions(notify: notify);
    final bid = getBid(bidId);
    if (bid == null) return 'Bid not found';
    if (bid.farmerId != farmerId) {
      return "You can only decline bids on your own listings";
    }
    if (bid.status != BidStatus.pending) {
      return 'Only pending bids can be declined';
    }

    if (AgriLinkApi.instance.hasToken) {
      try {
        await AgriLinkApi.instance.declineBid(bidId);
        await syncFromApi(UserRole.farmer);
        notify?.call(
          bid.buyerId,
          'Bid declined',
          'The farmer declined your bid for ${bid.cropType}.',
        );
        return null;
      } on AgriLinkApiException catch (error) {
        return error.message;
      }
    }

    state = state.copyWith(
      bids: state.bids
          .map(
            (b) => b.id == bid.id ? b.copyWith(status: BidStatus.declined) : b,
          )
          .toList(),
    );

    notify?.call(
      bid.buyerId,
      'Bid declined',
      'The farmer declined your bid for ${bid.cropType}.',
    );
    return null;
  }

  void confirmWinningBid(String listingId) {
    final listing = getProduction(listingId);
    if (listing == null) return;
    final pending = state.bids
        .where(
          (b) =>
              b.listingId == listingId &&
              b.status == BidStatus.pending &&
              b.farmerId == listing.farmerId,
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    if (pending.isEmpty) return;
    acceptBid(bidId: pending.first.id, farmerId: listing.farmerId);
  }

  void declineWinningBid(String listingId) {
    final listing = getProduction(listingId);
    if (listing == null) return;
    final pending = state.bids
        .where(
          (b) =>
              b.listingId == listingId &&
              b.status == BidStatus.pending &&
              b.farmerId == listing.farmerId,
        )
        .toList();
    for (final bid in pending) {
      declineBid(bidId: bid.id, farmerId: listing.farmerId);
    }
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
    if (p.quantity <= 0) return false;
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

final buyerListingBidsProvider = Provider.family<List<MarketBid>, String>((ref, listingId) {
  final buyerId = ref.watch(authProvider).profile?.id;
  if (buyerId == null) return const [];
  return ref
      .watch(appDataProvider)
      .bids
      .where((b) => b.listingId == listingId && b.buyerId == buyerId)
      .toList();
});

final farmerBidsProvider = Provider<List<MarketBid>>((ref) {
  final farmerId = ref.watch(authProvider).profile?.id;
  if (farmerId == null) return const [];
  return ref
      .watch(appDataProvider)
      .bids
      .where((b) => b.farmerId == farmerId)
      .toList();
});

final buyerBidsProvider = Provider<List<MarketBid>>((ref) {
  final buyerId = ref.watch(authProvider).profile?.id;
  if (buyerId == null) return const [];
  return ref
      .watch(appDataProvider)
      .bids
      .where((b) => b.buyerId == buyerId)
      .toList();
});

final farmerPendingConfirmationsProvider = Provider<List<Production>>((ref) {
  final farmerId = ref.watch(authProvider).profile?.id;
  if (farmerId == null) return const [];
  final pendingListingIds = ref
      .watch(farmerBidsProvider)
      .where((b) => b.status == BidStatus.pending)
      .map((b) => b.listingId)
      .toSet();
  return ref
      .watch(appDataProvider)
      .productions
      .where((p) => p.farmerId == farmerId && pendingListingIds.contains(p.id))
      .toList();
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
