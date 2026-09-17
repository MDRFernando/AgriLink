import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/entities/models.dart';
import 'package:my_app/shared/logic/aggregation_logic.dart';
import 'package:my_app/shared/logic/bidding_logic.dart';

void main() {
  group('submit_bid (Ch. 5.2)', () {
    test('rejects inactive listings', () {
      expect(
        BidEngine.submitBidError(
          listingActive: false,
          now: DateTime(2026, 9, 1, 10),
          biddingWindowEnd: DateTime(2026, 9, 2),
          currentHighestBid: 0,
          minIncrement: 5,
          reservePrice: 150,
          bidAmount: 150,
        ),
        'Listing is not open for bidding',
      );
    });

    test('rejects bids after the window and signals close', () {
      expect(
        BidEngine.submitBidError(
          listingActive: true,
          now: DateTime(2026, 9, 2, 12),
          biddingWindowEnd: DateTime(2026, 9, 2, 10),
          currentHighestBid: 180,
          minIncrement: 5,
          reservePrice: 150,
          bidAmount: 200,
        ),
        'Bidding window has closed',
      );
    });

    test('requires highest + increment', () {
      expect(
        BidEngine.minimumAcceptable(currentHighestBid: 180, minIncrement: 5),
        185,
      );
      expect(
        BidEngine.submitBidError(
          listingActive: true,
          now: DateTime(2026, 9, 1),
          biddingWindowEnd: DateTime(2026, 9, 3),
          currentHighestBid: 180,
          minIncrement: 5,
          reservePrice: 150,
          bidAmount: 184,
        ),
        'Bid must be at least 185',
      );
    });

    test('rejects bids below reserve even if increment is met', () {
      expect(
        BidEngine.submitBidError(
          listingActive: true,
          now: DateTime(2026, 9, 1),
          biddingWindowEnd: DateTime(2026, 9, 3),
          currentHighestBid: 0,
          minIncrement: 5,
          reservePrice: 150,
          bidAmount: 20,
        ),
        "Bid is below farmer's reserve price",
      );
    });

    test('accepts a first bid at reserve when increment is also met', () {
      expect(
        BidEngine.submitBidError(
          listingActive: true,
          now: DateTime(2026, 9, 1),
          biddingWindowEnd: DateTime(2026, 9, 3),
          currentHighestBid: 0,
          minIncrement: 5,
          reservePrice: 150,
          bidAmount: 150,
        ),
        isNull,
      );
    });
  });

  group('submit_offer (quantity bids)', () {
    test('rejects zero and negative quantity', () {
      expect(
        BidEngine.submitOfferError(
          listingActive: true,
          now: DateTime(2026, 9, 1),
          biddingWindowEnd: DateTime(2026, 9, 3),
          reservePrice: 80,
          bidAmount: 90,
          quantity: 0,
          availableQuantity: 500,
        ),
        'Quantity must be greater than zero',
      );
      expect(
        BidEngine.submitOfferError(
          listingActive: true,
          now: DateTime(2026, 9, 1),
          biddingWindowEnd: DateTime(2026, 9, 3),
          reservePrice: 80,
          bidAmount: 90,
          quantity: -10,
          availableQuantity: 500,
        ),
        'Quantity must be greater than zero',
      );
    });

    test('rejects quantity above available stock', () {
      expect(
        BidEngine.submitOfferError(
          listingActive: true,
          now: DateTime(2026, 9, 1),
          biddingWindowEnd: DateTime(2026, 9, 3),
          reservePrice: 80,
          bidAmount: 90,
          quantity: 600,
          availableQuantity: 500,
        ),
        'Quantity exceeds available stock',
      );
    });

    test('rejects invalid price and bids after closing', () {
      expect(
        BidEngine.submitOfferError(
          listingActive: true,
          now: DateTime(2026, 9, 1),
          biddingWindowEnd: DateTime(2026, 9, 3),
          reservePrice: 80,
          bidAmount: 0,
          quantity: 100,
          availableQuantity: 500,
        ),
        'Enter a valid bid price',
      );
      expect(
        BidEngine.submitOfferError(
          listingActive: true,
          now: DateTime(2026, 9, 4),
          biddingWindowEnd: DateTime(2026, 9, 3),
          reservePrice: 80,
          bidAmount: 90,
          quantity: 100,
          availableQuantity: 500,
        ),
        'Bidding window has closed',
      );
    });

    test('accepts a 100 kg tomato offer at or above reserve', () {
      expect(
        BidEngine.submitOfferError(
          listingActive: true,
          now: DateTime(2026, 9, 1),
          biddingWindowEnd: DateTime(2026, 9, 3),
          reservePrice: 80,
          bidAmount: 90,
          quantity: 100,
          availableQuantity: 500,
        ),
        isNull,
      );
    });
  });

  group('generate_aggregated_report (Ch. 5.3)', () {
    Production listing(String id, String farmer) => Production(
          id: id,
          farmerId: farmer,
          farmerName: farmer,
          cropType: 'Rice',
          quantity: 1000,
          unit: 'kg',
          harvestDate: DateTime(2026, 9, 10),
          region: 'North Central Province',
          location: 'Anuradhapura',
          status: ProductionStatus.available,
          createdAt: DateTime(2026, 9, 1),
        );

    test('suppresses cells with fewer than 5 farmers', () {
      final report = generateAggregatedReport(
        region: 'North Central Province',
        cropType: 'Rice',
        period: '2026-09',
        listings: [listing('1', 'a'), listing('2', 'b')],
        transactions: const [],
      );
      expect(report.suppressed, isTrue);
      expect(report.reason, 'Insufficient contributors to preserve anonymity');
    });

    test('publishes quantity and average clearing price at k = 5', () {
      final listings = List.generate(5, (i) => listing('$i', 'farmer-$i'));
      final report = generateAggregatedReport(
        region: 'North Central Province',
        cropType: 'Rice',
        period: '2026-09',
        listings: listings,
        transactions: [
          const ClearingTransaction(
            region: 'North Central Province',
            cropType: 'Rice',
            period: '2026-09',
            farmerId: 'farmer-0',
            clearingPrice: 180,
          ),
          const ClearingTransaction(
            region: 'North Central Province',
            cropType: 'Rice',
            period: '2026-09',
            farmerId: 'farmer-1',
            clearingPrice: 200,
          ),
        ],
      );
      expect(report.suppressed, isFalse);
      expect(report.totalQuantity, 5000);
      expect(report.contributorCount, 5);
      expect(report.avgPrice, 190);
    });
  });
}
