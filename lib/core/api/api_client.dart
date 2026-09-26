import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';

class AgriLinkApiException implements Exception {
  AgriLinkApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AgriLinkApi {
  AgriLinkApi._();
  static final AgriLinkApi instance = AgriLinkApi._();

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Browser chat must call the API on the same host the page was opened with.
  /// Chrome blocks `localhost` pages from calling `127.0.0.1`.
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) {
      final host = Uri.base.host;
      final name = host.isEmpty ? 'localhost' : host;
      return 'http://$name:3000/api/v1';
    }
    return 'http://127.0.0.1:3000/api/v1';
  }

  String? token;

  bool get hasToken => token != null && token!.isNotEmpty;

  void clear() => token = null;

  Future<UserProfile> login(String email, String password) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return _authProfile(data);
  }

  Future<UserProfile> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final data = await _post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
      'role': role == UserRole.admin ? 'government' : role.name,
    });
    return _authProfile(data);
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String phone,
    required String region,
    String? organizationName,
    String? address,
    BuyerType? buyerType,
    TransporterType? transporterType,
  }) async {
    final data = await _patch('/auth/profile', {
      'name': name,
      'phone': phone,
      'region': region,
      if (organizationName != null) 'organizationName': organizationName,
      if (organizationName != null) 'businessName': organizationName,
      if (address != null && address.isNotEmpty) 'address': address,
      if (address != null && address.isNotEmpty) 'buyerLocation': address,
      if (buyerType != null) 'buyerType': buyerType.name,
      if (transporterType != null) 'transporterType': transporterType.name,
    });
    return mapUser(data);
  }

  Future<List<Production>> fetchAvailableProductions() async {
    final data = await _get('/productions');
    return _asList(data).map((item) => mapProduction(item as Map<String, dynamic>)).toList();
  }

  Future<List<Production>> fetchMyProductions() async {
    final data = await _get('/productions/mine');
    return _asList(data).map((item) => mapProduction(item as Map<String, dynamic>)).toList();
  }

  Future<Production> fetchProduction(String id) async {
    final data = await _get('/productions/$id');
    return mapProduction(data as Map<String, dynamic>);
  }

  Future<Production> createProduction(Map<String, dynamic> body) async {
    final data = await _post('/productions', body);
    return mapProduction(data as Map<String, dynamic>);
  }

  Future<void> placeBid({
    required String listingId,
    required double amount,
    required double quantity,
  }) async {
    await _post('/productions/$listingId/bids', {
      'amount': amount,
      'quantity': quantity,
    });
  }

  Future<List<MarketBid>> fetchFarmerBids() async {
    final data = await _get('/bids/farmer');
    return _asList(data).map((item) => mapBid(item as Map<String, dynamic>)).toList();
  }

  Future<List<MarketBid>> fetchBuyerBids() async {
    final data = await _get('/bids/mine');
    return _asList(data).map((item) => mapBid(item as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> acceptBid(String bidId) async {
    final data = await _post('/bids/$bidId/accept', {});
    return data as Map<String, dynamic>;
  }

  Future<MarketBid> declineBid(String bidId) async {
    final data = await _patchOrPostDecline(bidId);
    return mapBid(data as Map<String, dynamic>);
  }

  Future<dynamic> _patchOrPostDecline(String bidId) {
    return _post('/bids/$bidId/decline', {});
  }

  Future<List<MarketOrder>> fetchOrders() async {
    final data = await _get('/orders');
    return _asList(data).map((item) => mapOrder(item as Map<String, dynamic>)).toList();
  }

  Future<String> farmerChat({
    required List<Map<String, String>> messages,
    required String userText,
  }) async {
    final data = await _post(
      '/chat/farmer',
      {
        'messages': messages,
        'userText': userText,
      },
      timeout: const Duration(seconds: 45),
    );
    if (data is Map && data['text'] is String && (data['text'] as String).trim().isNotEmpty) {
      return data['text'] as String;
    }
    throw AgriLinkApiException(
      'පිළිතුරක් ලැබුණේ නැත. කරුණාකර ප්‍රශ්නය නැවත අසන්න.',
    );
  }

  UserProfile _authProfile(dynamic data) {
    final map = data as Map<String, dynamic>;
    token = map['accessToken'] as String?;
    return mapUser(map['user'] as Map<String, dynamic>);
  }

  Future<dynamic> _get(String path) => _send('GET', path);
  Future<dynamic> _post(
    String path,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) =>
      _send('POST', path, body: body, timeout: timeout);
  Future<dynamic> _patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (hasToken) 'Authorization': 'Bearer $token',
    };
    late http.Response res;
    try {
      Future<http.Response> request;
      if (method == 'GET') {
        request = http.get(uri, headers: headers);
      } else if (method == 'PATCH') {
        request = http.patch(uri, headers: headers, body: jsonEncode(body));
      } else {
        request = http.post(uri, headers: headers, body: jsonEncode(body));
      }
      res = timeout == null ? await request : await request.timeout(timeout);
    } on TimeoutException {
      throw AgriLinkApiException(
        'පිළිතුර ලැබීමට වැඩි කාලයක් ගත විය. කරුණාකර නැවත උත්සාහ කරන්න.',
      );
    } catch (error) {
      if (error is AgriLinkApiException) rethrow;
      throw AgriLinkApiException('Could not reach AgriLink. Is the API running?');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AgriLinkApiException(_readError(res));
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  String _readError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        final message = body['message'];
        if (message is List) return message.join(', ');
        return message.toString();
      }
    } catch (_) {}
    return 'Request failed (${res.statusCode})';
  }

  List<dynamic> _asList(dynamic data) => data is List ? data : const [];
}

UserProfile mapUser(Map<String, dynamic> json) {
  final role = _role(json['role']?.toString());
  final buyer = json['buyerProfile'] as Map<String, dynamic>?;
  final transporter = json['transporterProfile'] as Map<String, dynamic>?;
  return UserProfile(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    role: role,
    organizationName: json['organizationName']?.toString() ??
        buyer?['businessName']?.toString() ??
        transporter?['company']?.toString(),
    region: json['region']?.toString(),
    isVerified: json['isVerified'] == true,
    buyerType: _buyerType(buyer?['buyerType']?.toString()),
    transporterType: _transporterType(transporter?['transporterType']?.toString()),
    address: json['address']?.toString() ?? buyer?['location']?.toString(),
  );
}

Production mapProduction(Map<String, dynamic> json) {
  final auction = json['auction'] as Map<String, dynamic>?;
  final status = _productionStatus(json['status']?.toString());
  final auctionStatus = _auctionStatus(auction?['status']?.toString(), status);
  final end = DateTime.tryParse(auction?['endTime']?.toString() ?? '');
  final reserve = (auction?['minBid'] as num?)?.toDouble() ??
      (json['minAcceptablePrice'] as num?)?.toDouble() ??
      0;
  return Production(
    id: json['id']?.toString() ?? '',
    farmerId: json['farmerId']?.toString() ?? '',
    farmerName: json['farmerName']?.toString() ?? 'Farmer',
    cropType: json['cropType']?.toString() ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    unit: json['unit']?.toString() ?? 'kg',
    harvestDate: DateTime.tryParse(json['harvestDate']?.toString() ?? '') ??
        DateTime.now(),
    region: json['region']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
    status: status,
    notes: json['notes']?.toString(),
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    qualityGrade: _grade(json['qualityGrade']?.toString()),
    reservePrice: reserve,
    minIncrement: (auction?['minIncrement'] as num?)?.toDouble() ?? 5,
    biddingWindowEnd: end,
    auctionStatus: auctionStatus,
    currentHighestBid: (auction?['highestBid'] as num?)?.toDouble() ?? 0,
  );
}

MarketBid mapBid(Map<String, dynamic> json) {
  return MarketBid(
    id: json['id']?.toString() ?? '',
    listingId: (json['listingId'] ?? json['productionId'])?.toString() ?? '',
    farmerId: json['farmerId']?.toString() ?? '',
    buyerId: json['buyerId']?.toString() ?? '',
    buyerName: json['buyerName']?.toString() ?? 'Buyer',
    cropType: json['cropType']?.toString() ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    unit: json['unit']?.toString() ?? 'kg',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now(),
    status: _bidStatus(json['status']?.toString()),
    biddingWindowEnd: DateTime.tryParse(json['biddingWindowEnd']?.toString() ?? ''),
    orderId: json['orderId']?.toString(),
  );
}

MarketOrder mapOrder(Map<String, dynamic> json) {
  final payment = json['payment'] as Map<String, dynamic>?;
  return MarketOrder(
    id: json['id']?.toString() ?? '',
    code: json['code']?.toString() ??
        'ORD-${(json['id']?.toString() ?? '000000').substring(0, 6).toUpperCase()}',
    buyerId: json['buyerId']?.toString() ?? '',
    farmerId: json['farmerId']?.toString() ?? '',
    farmerName: json['farmerName']?.toString() ?? 'Farmer',
    buyerName: json['buyerName']?.toString() ?? 'Buyer',
    product: json['cropType']?.toString() ?? json['product']?.toString() ?? 'Produce',
    quantityKg: (json['quantityKg'] as num?)?.toDouble() ?? 0,
    unitPrice: (json['winningPriceKg'] as num?)?.toDouble() ?? 0,
    orderStatus: _orderStatus(json['status']?.toString()),
    productPaymentStatus: _paymentStatus(payment?['status']?.toString()),
    listingId: json['productionId']?.toString(),
    acceptedBidId: json['acceptedBidId']?.toString(),
    pickupLabel: json['pickupLabel']?.toString() ?? '',
    pickupCity: json['pickupCity']?.toString() ?? '',
  );
}

UserRole _role(String? value) {
  switch (value) {
    case 'business':
      return UserRole.business;
    case 'transporter':
      return UserRole.transporter;
    case 'government':
      return UserRole.government;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.farmer;
  }
}

BuyerType? _buyerType(String? value) {
  if (value == 'individual') return BuyerType.individual;
  if (value == 'company') return BuyerType.company;
  return null;
}

TransporterType? _transporterType(String? value) {
  if (value == 'individual') return TransporterType.individual;
  if (value == 'company') return TransporterType.company;
  return null;
}

ProductionStatus _productionStatus(String? value) {
  return ProductionStatus.values.firstWhere(
    (s) => s.name.toLowerCase() == value?.toLowerCase(),
    orElse: () => ProductionStatus.available,
  );
}

ListingAuctionStatus _auctionStatus(String? auction, ProductionStatus status) {
  if (status == ProductionStatus.sold) return ListingAuctionStatus.sold;
  if (status == ProductionStatus.expired) return ListingAuctionStatus.expiredNoSale;
  switch (auction) {
    case 'closed':
      return ListingAuctionStatus.awaitingFarmerConfirmation;
    case 'cancelled':
      return ListingAuctionStatus.cancelled;
    case 'scheduled':
      return ListingAuctionStatus.open;
    default:
      return ListingAuctionStatus.open;
  }
}

QualityGrade _grade(String? value) {
  switch (value?.toUpperCase()) {
    case 'A':
      return QualityGrade.a;
    case 'C':
      return QualityGrade.c;
    default:
      return QualityGrade.b;
  }
}

BidStatus _bidStatus(String? value) {
  switch (value) {
    case 'accepted':
      return BidStatus.accepted;
    case 'declined':
      return BidStatus.declined;
    case 'expired':
      return BidStatus.expired;
    default:
      return BidStatus.pending;
  }
}

OrderStatus _orderStatus(String? value) {
  switch (value) {
    case 'delivery_required':
      return OrderStatus.deliveryRequired;
    case 'in_transit':
      return OrderStatus.inTransit;
    case 'delivered':
      return OrderStatus.delivered;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'disputed':
      return OrderStatus.disputed;
    case 'paid':
      return OrderStatus.paid;
    default:
      return OrderStatus.confirmed;
  }
}

PaymentRecordStatus _paymentStatus(String? value) {
  switch (value) {
    case 'sandbox_success':
    case 'paid':
      return PaymentRecordStatus.paid;
    case 'sandbox_failed':
    case 'failed':
      return PaymentRecordStatus.failed;
    default:
      return PaymentRecordStatus.pending;
  }
}
