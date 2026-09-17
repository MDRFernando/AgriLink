/// AgriLink bidding engine — Chapter 5.2 (time-bounded ascending auction).
///
/// Matches the thesis submit_bid / close_expired_listings pseudocode.
class BidEngine {
  const BidEngine._();

  static const kAnonymityThreshold = 5;

  /// minimum_acceptable = current_highest_bid + min_increment
  static double minimumAcceptable({
    required double currentHighestBid,
    required double minIncrement,
  }) {
    return currentHighestBid + minIncrement;
  }

  /// Returns a thesis-aligned error, or null if the bid may be recorded.
  static String? submitBidError({
    required bool listingActive,
    required DateTime now,
    DateTime? biddingWindowEnd,
    required double currentHighestBid,
    required double minIncrement,
    required double reservePrice,
    required double bidAmount,
  }) {
    if (!listingActive) {
      return 'Listing is not open for bidding';
    }
    if (biddingWindowEnd != null && now.isAfter(biddingWindowEnd)) {
      return 'Bidding window has closed';
    }
    final floor = BidEngine.minimumAcceptable(
      currentHighestBid: currentHighestBid,
      minIncrement: minIncrement,
    );
    if (bidAmount < floor) {
      return 'Bid must be at least ${floor.toStringAsFixed(0)}';
    }
    if (bidAmount < reservePrice) {
      return "Bid is below farmer's reserve price";
    }
    return null;
  }

  /// Offer-style bid: quantity + price, reviewed by the farmer.
  static String? submitOfferError({
    required bool listingActive,
    required DateTime now,
    DateTime? biddingWindowEnd,
    required double reservePrice,
    required double bidAmount,
    required double quantity,
    required double availableQuantity,
  }) {
    if (!listingActive) {
      return 'Listing is not open for bidding';
    }
    if (biddingWindowEnd != null && now.isAfter(biddingWindowEnd)) {
      return 'Bidding window has closed';
    }
    if (quantity <= 0) {
      return 'Quantity must be greater than zero';
    }
    if (quantity > availableQuantity) {
      return 'Quantity exceeds available stock';
    }
    if (bidAmount <= 0) {
      return 'Enter a valid bid price';
    }
    if (bidAmount < reservePrice) {
      return "Bid is below farmer's reserve price";
    }
    return null;
  }

  static bool qualifiesForFarmerConfirmation({
    required double currentHighestBid,
    required double reservePrice,
  }) {
    return currentHighestBid >= reservePrice && currentHighestBid > 0;
  }
}

/// Back-compat name used by older call sites.
typedef BidValidation = BidEngine;
