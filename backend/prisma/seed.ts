import {
  AuctionStatus,
  BidStatus,
  CropPlanStatus,
  CultivationSeason,
  DemandStatus,
  OrderStatus,
  PaymentStatus,
  PrismaClient,
  ProductionStatus,
  UserRole,
  VehicleType,
  VerificationStatus,
  BuyerType,
  TransporterType,
} from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  await prisma.cropPlan.deleteMany();
  await prisma.deliveryDispute.deleteMany();
  await prisma.deliveryProof.deleteMany();
  await prisma.deliveryTracking.deleteMany();
  await prisma.transportPayment.deleteMany();
  await prisma.transportRequest.deleteMany();
  await prisma.vehicle.deleteMany();
  await prisma.transporterProfile.deleteMany();
  await prisma.deliveryAddress.deleteMany();
  await prisma.transportPricingRule.deleteMany();
  await prisma.review.deleteMany();
  await prisma.appNotification.deleteMany();
  await prisma.payment.deleteMany();
  await prisma.orderEvent.deleteMany();
  await prisma.order.deleteMany();
  await prisma.bid.deleteMany();
  await prisma.auction.deleteMany();
  await prisma.purchaseInterest.deleteMany();
  await prisma.demandRequest.deleteMany();
  await prisma.production.deleteMany();
  await prisma.farmerProfile.deleteMany();
  await prisma.buyerProfile.deleteMany();
  await prisma.user.deleteMany();

  const passwordHash = await bcrypt.hash('password123', 10);

  await prisma.transportPricingRule.createMany({
    data: [
      { vehicleType: VehicleType.pickup, baseCharge: 1500, perKm: 35, perKg: 3, loadingFee: 250, fuelSurchargePercent: 5 },
      { vehicleType: VehicleType.small_lorry, baseCharge: 2500, perKm: 40, perKg: 2, loadingFee: 400, fuelSurchargePercent: 5 },
      { vehicleType: VehicleType.medium_lorry, baseCharge: 3500, perKm: 45, perKg: 1.5, loadingFee: 500, fuelSurchargePercent: 5 },
      { vehicleType: VehicleType.large_lorry, baseCharge: 5000, perKm: 55, perKg: 1, loadingFee: 800, fuelSurchargePercent: 6 },
    ],
  });

  const farmer1 = await prisma.user.create({
    data: {
      email: 'farmer@agrilink.lk',
      passwordHash,
      name: 'Sunil Perera',
      phone: '+94771234567',
      role: UserRole.farmer,
      region: 'North Western Province',
      district: 'Kurunegala',
      isVerified: true,
      farmerProfile: {
        create: {
          farmLocation: 'Kurunegala Farm',
          farmSizeAcres: 4.5,
          traditionalFarmgatePriceKg: 120,
          harvestingCostPerKg: 8,
          lat: 7.4863,
          lng: 80.3623,
        },
      },
    },
  });

  const farmer2 = await prisma.user.create({
    data: {
      email: 'farmer2@agrilink.lk',
      passwordHash,
      name: 'Kamal Silva',
      phone: '+94772345678',
      role: UserRole.farmer,
      region: 'Central Province',
      isVerified: true,
      farmerProfile: {
        create: { farmLocation: 'Kandy Highlands', lat: 7.2906, lng: 80.6337 },
      },
    },
  });

  const business = await prisma.user.create({
    data: {
      email: 'business@agrilink.lk',
      passwordHash,
      name: 'Nimal Jayasuriya',
      phone: '+94771239876',
      role: UserRole.business,
      organizationName: 'ABC Supermarket',
      region: 'Western Province',
      isVerified: true,
      buyerProfile: {
        create: {
          businessName: 'ABC Supermarket',
          businessType: 'Supermarket',
          buyerType: BuyerType.company,
          location: '123 Main Street, Colombo',
          verificationStatus: VerificationStatus.approved,
          lat: 6.9271,
          lng: 79.8612,
        },
      },
    },
  });

  await prisma.user.create({
    data: {
      email: 'gov@agrilink.lk',
      passwordHash,
      name: 'Agri Officer',
      phone: '+94113456789',
      role: UserRole.government,
      organizationName: 'Ministry of Agriculture',
      region: 'Western Province',
      isVerified: true,
    },
  });

  const abcLogistics = await prisma.user.create({
    data: {
      email: 'transporter@agrilink.lk',
      passwordHash,
      name: 'Ruwan Fernando',
      phone: '+94777771111',
      role: UserRole.transporter,
      organizationName: 'ABC Logistics',
      region: 'North Western Province',
      isVerified: true,
      transporterProfile: {
        create: {
          company: 'ABC Logistics',
          transporterType: TransporterType.company,
          rating: 4.8,
          availabilityStatus: 'available',
          serviceAreasJson: JSON.stringify(['Kurunegala', 'Colombo', 'Kandy']),
          lat: 7.48,
          lng: 80.35,
          vehicles: {
            create: {
              vehicleNumber: 'NW-1234',
              vehicleType: VehicleType.medium_lorry,
              capacityKg: 5000,
            },
          },
        },
      },
    },
  });

  await prisma.user.create({
    data: {
      email: 'transporter2@agrilink.lk',
      passwordHash,
      name: 'Saman Perera',
      phone: '+94777772222',
      role: UserRole.transporter,
      organizationName: 'GreenHaul Lanka',
      isVerified: true,
      transporterProfile: {
        create: {
          company: 'GreenHaul Lanka',
          transporterType: TransporterType.company,
          rating: 4.4,
          availabilityStatus: 'available',
          lat: 7.25,
          lng: 80.2,
          vehicles: {
            create: {
              vehicleNumber: 'WP-8890',
              vehicleType: VehicleType.small_lorry,
              capacityKg: 1500,
            },
          },
        },
      },
    },
  });

  await prisma.deliveryAddress.create({
    data: {
      buyerId: business.id,
      businessName: 'ABC Supermarket',
      contactPerson: 'Nimal Jayasuriya',
      phone: '0771239876',
      address: '123 Main Street, Colombo',
      city: 'Colombo',
      latitude: 6.9271,
      longitude: 79.8612,
      instructions: 'Unload at the rear goods bay. Call 10 minutes before arrival.',
      isDefault: true,
    },
  });

  const bananaPlanRows: Array<{
    name: string;
    village: string;
    ds: string;
    acres: number;
  }> = [
    { name: 'Amal Wickramasinghe', village: 'Wehera', ds: 'Kurunegala', acres: 1.8 },
    { name: 'Priyani Jayasuriya', village: 'Kurunegala', ds: 'Kurunegala', acres: 3.2 },
    { name: 'Harsha Gunasekara', village: 'Mawathagama', ds: 'Mawathagama', acres: 2.0 },
    { name: 'Lakmali Senanayake', village: 'Wewagedara', ds: 'Mawathagama', acres: 1.5 },
    { name: 'Tharindu Herath', village: 'Polgahawela', ds: 'Polgahawela', acres: 4.0 },
    { name: 'Ishara Bandara', village: 'Pothuhera', ds: 'Polgahawela', acres: 2.4 },
    { name: 'Chathura Wijesinghe', village: 'Alawwa', ds: 'Polgahawela', acres: 1.6 },
  ];

  for (const [index, row] of bananaPlanRows.entries()) {
    const user = await prisma.user.create({
      data: {
        email: `banana${index + 1}@agrilink.lk`,
        passwordHash,
        name: row.name,
        role: UserRole.farmer,
        region: 'North Western Province',
        district: 'Kurunegala',
        isVerified: true,
        farmerProfile: { create: { farmLocation: `${row.village}, Kurunegala` } },
      },
    });
    await prisma.cropPlan.create({
      data: {
        farmerId: user.id,
        cropType: 'Banana',
        cultivationYear: 2026,
        cultivationMonth: 10,
        season: CultivationSeason.maha,
        areaAcres: row.acres,
        province: 'North Western Province',
        district: 'Kurunegala',
        dsDivision: row.ds,
        village: row.village,
        status: CropPlanStatus.planned,
      },
    });
  }

  await prisma.cropPlan.createMany({
    data: [
      {
        farmerId: farmer1.id,
        cropType: 'Banana',
        cultivationYear: 2026,
        cultivationMonth: 10,
        season: CultivationSeason.maha,
        areaAcres: 2.5,
        province: 'North Western Province',
        district: 'Kurunegala',
        dsDivision: 'Kurunegala',
        village: 'Malkaduwawa',
        locationNotes: 'Lowland plot near Deduru Oya',
        expectedYieldKg: 18000,
        status: CropPlanStatus.planned,
      },
      {
        farmerId: farmer1.id,
        cropType: 'Rice',
        cultivationYear: 2026,
        cultivationMonth: 10,
        season: CultivationSeason.maha,
        areaAcres: 3,
        province: 'North Western Province',
        district: 'Kurunegala',
        dsDivision: 'Mawathagama',
        village: 'Pilessa',
        status: CropPlanStatus.planned,
      },
      {
        farmerId: farmer2.id,
        cropType: 'Tea',
        cultivationYear: 2026,
        cultivationMonth: 9,
        season: CultivationSeason.yala,
        areaAcres: 1.2,
        province: 'Central Province',
        district: 'Kandy',
        dsDivision: 'Udunuwara',
        village: 'Gelioya',
        status: CropPlanStatus.cultivating,
      },
    ],
  });

  await prisma.demandRequest.createMany({
    data: [
      {
        requesterId: business.id,
        cropType: 'Rice',
        quantityNeeded: 10000,
        unit: 'kg',
        deadline: daysFromNow(30),
        region: 'Western Province',
        status: DemandStatus.open,
      },
      {
        requesterId: business.id,
        cropType: 'Banana',
        quantityNeeded: 8000,
        unit: 'kg',
        deadline: daysFromNow(60),
        region: 'Western Province',
        status: DemandStatus.open,
      },
    ],
  });

  const banana = await prisma.production.create({
    data: {
      listingCode: 'BIT-BAN-001',
      farmerId: farmer1.id,
      cropType: 'Banana',
      quantity: 500,
      unit: 'kg',
      harvestDate: daysFromNow(1),
      region: 'North Western Province',
      location: 'Kurunegala Farm',
      status: ProductionStatus.sold,
      notes: 'Embul banana, harvest-ready',
    },
  });

  await prisma.production.create({
    data: {
      listingCode: 'BIT-TOM-002',
      farmerId: farmer1.id,
      cropType: 'Tomato',
      quantity: 1200,
      unit: 'kg',
      harvestDate: daysFromNow(7),
      region: 'Central Province',
      location: 'Nuwara Eliya',
      status: ProductionStatus.available,
    },
  });

  await prisma.production.create({
    data: {
      listingCode: 'BIT-TEA-003',
      farmerId: farmer2.id,
      cropType: 'Tea',
      quantity: 800,
      unit: 'kg',
      harvestDate: daysFromNow(21),
      region: 'Central Province',
      location: 'Kandy',
      status: ProductionStatus.available,
    },
  });

  const auction = await prisma.auction.create({
    data: {
      productionId: banana.id,
      openingBid: 150,
      minBid: 150,
      minIncrement: 5,
      startTime: daysFromNow(-2),
      endTime: daysFromNow(-1),
      status: AuctionStatus.closed,
      closedAt: daysFromNow(-1),
    },
  });

  const winningBid = await prisma.bid.create({
    data: {
      auctionId: auction.id,
      productionId: banana.id,
      buyerId: business.id,
      farmerId: farmer1.id,
      quantity: 500,
      amount: 180,
      totalAmount: 90000,
      status: BidStatus.accepted,
    },
  });

  await prisma.auction.update({
    where: { id: auction.id },
    data: { winningBidId: winningBid.id },
  });

  const order = await prisma.order.create({
    data: {
      auctionId: auction.id,
      acceptedBidId: winningBid.id,
      productionId: banana.id,
      farmerId: farmer1.id,
      buyerId: business.id,
      winningPriceKg: 180,
      quantityKg: 500,
      status: OrderStatus.delivery_required,
      farmerConfirmed: true,
      buyerConfirmed: true,
      events: {
        create: [
          { status: OrderStatus.pending_farmer, action: 'AUCTION_CLOSED', actorId: business.id },
          { status: OrderStatus.payment_pending, action: 'BUYER_CONFIRM', actorId: business.id },
          { status: OrderStatus.delivery_required, action: 'PRODUCT_PAID', actorId: business.id },
        ],
      },
      transportation: {
        create: {
          farmerLocation: 'Kurunegala Farm',
          buyerLocation: 'ABC Supermarket, Colombo',
          distanceKm: 94,
          quantityKg: 500,
          estimatedCost: 7500,
          vehicleRequirement: 'Medium Lorry',
        },
      },
      payment: {
        create: {
          buyerId: business.id,
          farmerId: farmer1.id,
          amount: 90000,
          status: PaymentStatus.paid,
          reference: 'PAY-PROD-005421',
          paidAt: new Date(),
          receiptNote: 'Product payment LKR 90,000 — separate from transport.',
        },
      },
    },
  });

  await prisma.appNotification.createMany({
    data: [
      {
        userId: business.id,
        audience: 'buyer',
        title: 'Payment successful',
        body: 'Your products are ready to be delivered.',
      },
      {
        userId: farmer1.id,
        audience: 'farmer',
        title: 'Order purchased',
        body: 'ABC Supermarket paid LKR 90,000 for 500 kg Banana.',
      },
      {
        userId: abcLogistics.id,
        audience: 'transporter',
        title: 'New jobs nearby',
        body: 'Open the dashboard to accept farm-to-business deliveries.',
      },
    ],
  });

  console.log('Seed complete.');
  console.log('Demo accounts (password: password123):');
  console.log('  Farmer:      farmer@agrilink.lk');
  console.log('  Buyer:       business@agrilink.lk');
  console.log('  Transporter: transporter@agrilink.lk');
  console.log('  Government:  gov@agrilink.lk');
  console.log(`Demo order ${order.id} — Banana 500kg @ LKR 180, PAID / Delivery Required`);
}

function daysFromNow(days: number) {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date;
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
