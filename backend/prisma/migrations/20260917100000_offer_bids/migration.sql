-- AlterTable Bid: offer-style quantity bids with farmer/listing linkage and status.
-- Recreate Bid and drop Order.auctionId uniqueness so a listing can yield multiple orders.

PRAGMA foreign_keys=OFF;

CREATE TABLE "new_Bid" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "auctionId" TEXT NOT NULL,
    "productionId" TEXT NOT NULL,
    "buyerId" TEXT NOT NULL,
    "farmerId" TEXT NOT NULL,
    "quantity" REAL NOT NULL,
    "amount" REAL NOT NULL,
    "totalAmount" REAL NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Bid_auctionId_fkey" FOREIGN KEY ("auctionId") REFERENCES "Auction" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Bid_buyerId_fkey" FOREIGN KEY ("buyerId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Bid_farmerId_fkey" FOREIGN KEY ("farmerId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO "new_Bid" (
    "id", "auctionId", "productionId", "buyerId", "farmerId",
    "quantity", "amount", "totalAmount", "status", "createdAt", "updatedAt"
)
SELECT
    b."id",
    b."auctionId",
    a."productionId",
    b."buyerId",
    p."farmerId",
    COALESCE(p."quantity", 0),
    b."amount",
    COALESCE(p."quantity", 0) * b."amount",
    CASE WHEN a."winningBidId" = b."id" THEN 'accepted' ELSE 'pending' END,
    b."createdAt",
    CURRENT_TIMESTAMP
FROM "Bid" b
JOIN "Auction" a ON a."id" = b."auctionId"
JOIN "Production" p ON p."id" = a."productionId";

DROP TABLE "Bid";
ALTER TABLE "new_Bid" RENAME TO "Bid";

CREATE INDEX "Bid_auctionId_createdAt_idx" ON "Bid"("auctionId", "createdAt");
CREATE INDEX "Bid_farmerId_status_idx" ON "Bid"("farmerId", "status");
CREATE INDEX "Bid_buyerId_status_idx" ON "Bid"("buyerId", "status");
CREATE INDEX "Bid_productionId_status_idx" ON "Bid"("productionId", "status");

CREATE TABLE "new_Order" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "auctionId" TEXT NOT NULL,
    "acceptedBidId" TEXT,
    "productionId" TEXT NOT NULL,
    "farmerId" TEXT NOT NULL,
    "buyerId" TEXT NOT NULL,
    "winningPriceKg" REAL NOT NULL,
    "quantityKg" REAL NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending_farmer',
    "farmerConfirmed" BOOLEAN NOT NULL DEFAULT false,
    "buyerConfirmed" BOOLEAN NOT NULL DEFAULT false,
    "remarks" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Order_acceptedBidId_fkey" FOREIGN KEY ("acceptedBidId") REFERENCES "Bid" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Order_farmerId_fkey" FOREIGN KEY ("farmerId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Order_buyerId_fkey" FOREIGN KEY ("buyerId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

INSERT INTO "new_Order" (
    "id", "auctionId", "acceptedBidId", "productionId", "farmerId", "buyerId",
    "winningPriceKg", "quantityKg", "status", "farmerConfirmed", "buyerConfirmed",
    "remarks", "createdAt", "updatedAt"
)
SELECT
    o."id",
    o."auctionId",
    a."winningBidId",
    o."productionId",
    o."farmerId",
    o."buyerId",
    o."winningPriceKg",
    o."quantityKg",
    o."status",
    o."farmerConfirmed",
    o."buyerConfirmed",
    o."remarks",
    o."createdAt",
    o."updatedAt"
FROM "Order" o
LEFT JOIN "Auction" a ON a."id" = o."auctionId";

DROP TABLE "Order";
ALTER TABLE "new_Order" RENAME TO "Order";

CREATE UNIQUE INDEX "Order_acceptedBidId_key" ON "Order"("acceptedBidId");

PRAGMA foreign_keys=ON;
