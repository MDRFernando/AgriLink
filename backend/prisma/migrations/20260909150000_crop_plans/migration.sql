-- CreateTable
CREATE TABLE "CropPlan" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "farmerId" TEXT NOT NULL,
    "cropType" TEXT NOT NULL,
    "cultivationYear" INTEGER NOT NULL,
    "cultivationMonth" INTEGER NOT NULL,
    "season" TEXT,
    "areaAcres" REAL NOT NULL,
    "province" TEXT NOT NULL,
    "district" TEXT NOT NULL,
    "dsDivision" TEXT NOT NULL,
    "village" TEXT NOT NULL,
    "locationNotes" TEXT,
    "expectedYieldKg" REAL,
    "status" TEXT NOT NULL DEFAULT 'planned',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "CropPlan_farmerId_fkey" FOREIGN KEY ("farmerId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "CropPlan_district_cropType_cultivationYear_cultivationMonth_idx" ON "CropPlan"("district", "cropType", "cultivationYear", "cultivationMonth");

-- CreateIndex
CREATE INDEX "CropPlan_farmerId_idx" ON "CropPlan"("farmerId");
