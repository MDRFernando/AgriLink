import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/providers/app_providers.dart';
import 'package:my_app/shared/providers/logistics_provider.dart';

void main() {
  UserProfile farmer() => const UserProfile(
        id: 'farmer-test',
        name: 'Test Farmer',
        email: 'farmer-test@agrilink.lk',
        phone: '0770000001',
        role: UserRole.farmer,
        isVerified: true,
      );

  UserProfile buyer() => const UserProfile(
        id: 'buyer-test',
        name: 'Test Buyer',
        email: 'buyer-test@agrilink.lk',
        phone: '0770000002',
        role: UserRole.business,
        organizationName: 'Test Mart',
        isVerified: true,
      );

  Production tomatoListing() => Production(
        id: 'prod-tomato',
        farmerId: farmer().id,
        farmerName: farmer().name,
        cropType: 'Tomato',
        quantity: 500,
        unit: 'kg',
        harvestDate: DateTime.now().add(const Duration(days: 10)),
        region: 'Central Province',
        location: 'Nuwara Eliya',
        status: ProductionStatus.available,
        createdAt: DateTime.now(),
        reservePrice: 80,
        minIncrement: 5,
        biddingWindowEnd: DateTime.now().add(const Duration(hours: 48)),
        auctionStatus: ListingAuctionStatus.open,
      );

  test('farmer sees a 100 kg bid, accepts it, and remaining stock is 400 kg', () async {
    final data = AppDataNotifier();
    final logistics = LogisticsNotifier();
    final listing = tomatoListing();
    data.addProduction(listing);

    final placeError = await data.placeBid(
      listing: listing,
      buyer: buyer(),
      amount: 90,
      quantity: 100,
      notify: logistics.notify,
    );
    expect(placeError, isNull);

    final bids = data.state.bids.where((b) => b.farmerId == farmer().id).toList();
    expect(bids, isNotEmpty);
    expect(bids.first.quantity, 100);
    expect(bids.first.totalAmount, 9000);
    expect(bids.first.status, BidStatus.pending);

    expect(await data.acceptBid(bidId: bids.first.id, farmerId: 'someone-else'), isNotNull);

    final acceptError = await data.acceptBid(
      bidId: bids.first.id,
      farmerId: farmer().id,
      notify: logistics.notify,
    );
    expect(acceptError, isNull);
    expect(
      await data.acceptBid(bidId: bids.first.id, farmerId: farmer().id),
      'This bid has already been accepted',
    );

    final updated = data.getProduction(listing.id)!;
    expect(updated.quantity, 400);
    expect(updated.status, ProductionStatus.available);
    expect(data.getBid(bids.first.id)!.status, BidStatus.accepted);

    final order = logistics.createBuyOrder(
      production: listing,
      buyer: buyer(),
      quantityKg: 100,
      unitPrice: 90,
      acceptedBidId: bids.first.id,
    );
    expect(order.quantityKg, 100);
    expect(order.listingId, listing.id);
    expect(order.acceptedBidId, bids.first.id);
    expect(order.buyerId, buyer().id);
    expect(order.farmerId, farmer().id);

    logistics.payProduct(order.id, 'Card');
    final address = DeliveryAddress(
      id: 'addr-test',
      buyerId: buyer().id,
      businessName: 'Test Mart',
      contactPerson: buyer().name,
      phone: buyer().phone,
      address: '1 Market Street',
      city: 'Colombo',
    );
    logistics.addAddress(address);
    final job = logistics.createTransportRequest(order: order, address: address);
    expect(job.orderId, order.id);
    expect(job.farmerId, farmer().id);
    expect(job.buyerId, buyer().id);
    expect(job.transporterId, isNull);
  });

  test('accepting the full remaining quantity marks the listing sold', () async {
    final data = AppDataNotifier();
    data.addProduction(tomatoListing());
    await data.placeBid(
      listing: data.getProduction('prod-tomato')!,
      buyer: buyer(),
      amount: 90,
      quantity: 500,
    );
    final bid = data.state.bids.first;
    expect(await data.acceptBid(bidId: bid.id, farmerId: farmer().id), isNull);
    final updated = data.getProduction('prod-tomato')!;
    expect(updated.quantity, 0);
    expect(updated.status, ProductionStatus.sold);
    expect(updated.auctionStatus, ListingAuctionStatus.sold);
  });

  test('rejects overselling, zero quantity, and bids after the window', () async {
    final data = AppDataNotifier();
    data.addProduction(tomatoListing());
    expect(
      await data.placeBid(
        listing: data.getProduction('prod-tomato')!,
        buyer: buyer(),
        amount: 90,
        quantity: 600,
      ),
      'Quantity exceeds available stock',
    );
    expect(
      await data.placeBid(
        listing: data.getProduction('prod-tomato')!,
        buyer: buyer(),
        amount: 90,
        quantity: 0,
      ),
      'Quantity must be greater than zero',
    );

    final closed = Production(
      id: 'prod-closed',
      farmerId: farmer().id,
      farmerName: farmer().name,
      cropType: 'Tomato',
      quantity: 500,
      unit: 'kg',
      harvestDate: DateTime.now(),
      region: 'Central Province',
      location: 'Nuwara Eliya',
      status: ProductionStatus.available,
      createdAt: DateTime.now(),
      reservePrice: 80,
      biddingWindowEnd: DateTime.now().subtract(const Duration(hours: 1)),
      auctionStatus: ListingAuctionStatus.open,
    );
    data.addProduction(closed);
    expect(
      await data.placeBid(
        listing: closed,
        buyer: buyer(),
        amount: 90,
        quantity: 100,
      ),
      'Bidding window has closed',
    );
  });

  test('a buyer only sees their own bid on a listing', () async {
    final data = AppDataNotifier();
    data.addProduction(tomatoListing());
    await data.placeBid(
      listing: data.getProduction('prod-tomato')!,
      buyer: buyer(),
      amount: 90,
      quantity: 100,
    );
    await data.placeBid(
      listing: data.getProduction('prod-tomato')!,
      buyer: const UserProfile(
        id: 'buyer-other',
        name: 'Other Buyer',
        email: 'other@agrilink.lk',
        phone: '0770000003',
        role: UserRole.business,
        isVerified: true,
      ),
      amount: 95,
      quantity: 50,
    );

    final mine = data.state.bids.where((b) => b.buyerId == buyer().id).toList();
    expect(mine, hasLength(1));
    expect(mine.first.quantity, 100);
    expect(mine.first.amount, 90);
    expect(data.state.bids, hasLength(2));
    expect(
      await data.acceptBid(bidId: data.state.bids.first.id, farmerId: buyer().id),
      isNotNull,
    );
  });
}
