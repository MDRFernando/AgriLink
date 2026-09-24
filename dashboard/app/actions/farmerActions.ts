'use server';

import { revalidatePath } from 'next/cache';
import { prisma } from '@/lib/db';
import { getSession } from '@/lib/auth';
import { ProductionListing, CropPlan, QualityGrade } from '@/lib/types';
import { CultivationSeason, ProductionStatus } from '@prisma/client';

export async function getFarmerDataAction(): Promise<{
  productions: ProductionListing[];
  cropPlans: CropPlan[];
}> {
  try {
    const sessionData = await getSession();
    const userId = sessionData?.user?.id;

    // Fetch productions from PostgreSQL
    const dbProductions = await prisma.production.findMany({
      include: {
        farmer: {
          select: { id: true, name: true, phone: true, region: true, district: true },
        },
        auction: {
          include: {
            bids: {
              include: {
                buyer: {
                  select: { id: true, name: true, organizationName: true },
                },
              },
              orderBy: { amount: 'desc' },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const productions: ProductionListing[] = dbProductions.map((p) => {
      const topBid = p.auction?.bids?.[0];
      const highestBid = topBid?.amount || p.auction?.minBid || p.minAcceptablePrice || 180;
      const endsInMinutes = p.auction?.endTime
        ? Math.max(0, Math.round((new Date(p.auction.endTime).getTime() - Date.now()) / (1000 * 60)))
        : 60;

      let category: 'Vegetables' | 'Paddy & Rice' | 'Fruits' | 'Spices' = 'Vegetables';
      const cropLower = p.cropType.toLowerCase();
      if (cropLower.includes('paddy') || cropLower.includes('rice') || cropLower.includes('samba')) {
        category = 'Paddy & Rice';
      } else if (cropLower.includes('chili') || cropLower.includes('pepper') || cropLower.includes('spice') || cropLower.includes('cinnamon')) {
        category = 'Spices';
      } else if (cropLower.includes('banana') || cropLower.includes('mango') || cropLower.includes('papaya') || cropLower.includes('fruit')) {
        category = 'Fruits';
      }

      const minPrice = p.minAcceptablePrice ?? 150;

      return {
        id: p.id,
        listingCode: p.listingCode || `LST-2026-${p.id.slice(0, 4).toUpperCase()}`,
        farmerName: p.farmer?.name || 'Local Farmer',
        farmerPhone: p.farmer?.phone || '+94 77 123 4567',
        cropType: p.cropType,
        variety: p.variety || 'Certified Standard',
        category,
        quantityKg: p.quantity,
        qualityGrade: (p.qualityGrade as QualityGrade) || 'A',
        harvestDate: p.harvestDate ? new Date(p.harvestDate).toISOString().split('T')[0] : '2026-09-30',
        region: p.region || 'North Central',
        district: p.location || p.farmer?.district || 'Anuradhapura',
        status: (p.status as any) || 'available',
        minAcceptablePriceKg: minPrice,
        traditionalFarmgatePriceKg: Math.round(minPrice * 0.78),
        projectedRevenue: p.quantity * highestBid,
        description: p.notes || p.description || `Direct farmgate listing of ${p.cropType}, graded ${p.qualityGrade}.`,
        activeAuction: p.auction
          ? {
              id: p.auction.id,
              openingBid: p.auction.openingBid,
              currentHighestBid: highestBid,
              bidCount: p.auction.bids?.length || 0,
              endsInMinutes,
              status: (p.auction.status as any) || 'open',
              highestBidderName:
                topBid?.buyer?.organizationName || topBid?.buyer?.name || 'Verified Buyer',
            }
          : undefined,
      };
    });

    // Fetch crop plans from PostgreSQL
    const dbCropPlans = await prisma.cropPlan.findMany({
      where: userId ? { farmerId: userId } : undefined,
      orderBy: { createdAt: 'desc' },
    });

    const effectivePlans = dbCropPlans.length > 0
      ? dbCropPlans
      : await prisma.cropPlan.findMany({ orderBy: { createdAt: 'desc' }, take: 10 });

    const cropPlans: CropPlan[] = effectivePlans.map((cp) => {
      let seasonName: 'Maha 2026' | 'Yala 2026' | 'Off-Season' = 'Maha 2026';
      if (cp.season === CultivationSeason.yala) seasonName = 'Yala 2026';
      else if (cp.season === CultivationSeason.off_season) seasonName = 'Off-Season';

      return {
        id: cp.id,
        cropType: cp.cropType,
        season: seasonName,
        areaAcres: cp.areaAcres,
        expectedYieldKg: cp.expectedYieldKg || Math.round(cp.areaAcres * 1500),
        district: cp.district || 'Anuradhapura',
        dsDivision: cp.dsDivision || 'Central Division',
        status: (cp.status as any) || 'cultivating',
        sowingDate: cp.createdAt ? new Date(cp.createdAt).toISOString().split('T')[0] : '2026-05-10',
        harvestTargetDate: '2026-09-30',
      };
    });

    return { productions, cropPlans };
  } catch (error) {
    console.error('Error fetching farmer data from DB:', error);
    return { productions: [], cropPlans: [] };
  }
}

export async function createProductionListingAction(formData: {
  cropType: string;
  variety: string;
  quantityKg: number;
  qualityGrade: QualityGrade;
  minPrice: number;
  harvestDate: string;
  region?: string;
  district?: string;
  notes?: string;
}) {
  try {
    const sessionData = await getSession();
    let farmerId = sessionData?.user?.id;

    if (!farmerId) {
      const fallbackFarmer = await prisma.user.findFirst({ where: { role: 'farmer' } });
      farmerId = fallbackFarmer?.id;
    }

    if (!farmerId) {
      return { success: false, error: 'No farmer profile found to associate this listing.' };
    }

    const harvestDate = new Date(formData.harvestDate || Date.now());
    const endTime = new Date(Date.now() + 24 * 60 * 60 * 1000);
    const minPrice = Number(formData.minPrice);

    const production = await prisma.production.create({
      data: {
        farmerId,
        cropType: formData.cropType,
        variety: formData.variety,
        quantity: Number(formData.quantityKg),
        unit: 'kg',
        qualityGrade: formData.qualityGrade,
        harvestDate,
        region: formData.region || 'North Central',
        location: formData.district || 'Anuradhapura',
        status: ProductionStatus.available,
        minAcceptablePrice: minPrice,
        notes: formData.notes || `Grade ${formData.qualityGrade} fresh harvest.`,
        auction: {
          create: {
            openingBid: minPrice,
            minIncrement: 5,
            minBid: minPrice,
            startTime: new Date(),
            endTime,
            status: 'open',
          },
        },
      },
    });

    revalidatePath('/');
    return { success: true, productionId: production.id };
  } catch (error: any) {
    console.error('Error creating production listing:', error);
    return { success: false, error: error?.message || 'Failed to create listing' };
  }
}

export async function acceptBidAction(listingId: string, bidId?: string) {
  try {
    const production = await prisma.production.findUnique({
      where: { id: listingId },
      include: {
        auction: {
          include: {
            bids: { orderBy: { amount: 'desc' }, take: 1 },
          },
        },
      },
    });

    if (!production || !production.auction) {
      return { success: false, error: 'Listing or auction not found' };
    }

    const targetBid = bidId
      ? await prisma.bid.findUnique({ where: { id: bidId } })
      : production.auction.bids[0];

    if (!targetBid) {
      return { success: false, error: 'No active bids to accept' };
    }

    await prisma.$transaction([
      prisma.bid.update({
        where: { id: targetBid.id },
        data: { status: 'accepted' },
      }),
      prisma.auction.update({
        where: { id: production.auction.id },
        data: { status: 'closed', winningBidId: targetBid.id },
      }),
      prisma.production.update({
        where: { id: production.id },
        data: { status: ProductionStatus.sold },
      }),
      prisma.order.create({
        data: {
          auctionId: production.auction.id,
          acceptedBidId: targetBid.id,
          productionId: production.id,
          farmerId: production.farmerId,
          buyerId: targetBid.buyerId,
          winningPriceKg: targetBid.amount,
          quantityKg: targetBid.quantity,
          status: 'confirmed',
          farmerConfirmed: true,
          buyerConfirmed: false,
        },
      }),
    ]);

    revalidatePath('/');
    return { success: true };
  } catch (error: any) {
    console.error('Error accepting bid:', error);
    return { success: false, error: error?.message || 'Failed to accept bid' };
  }
}

export async function createCropPlanAction(formData: {
  cropType: string;
  season: 'Maha 2026' | 'Yala 2026' | 'Off-Season';
  areaAcres: number;
  expectedYieldKg: number;
  district: string;
  dsDivision: string;
}) {
  try {
    const sessionData = await getSession();
    let farmerId = sessionData?.user?.id;

    if (!farmerId) {
      const fallback = await prisma.user.findFirst({ where: { role: 'farmer' } });
      farmerId = fallback?.id;
    }

    if (!farmerId) {
      return { success: false, error: 'Farmer profile not found' };
    }

    let seasonEnum: CultivationSeason = CultivationSeason.maha;
    if (formData.season === 'Yala 2026') seasonEnum = CultivationSeason.yala;
    else if (formData.season === 'Off-Season') seasonEnum = CultivationSeason.off_season;

    await prisma.cropPlan.create({
      data: {
        farmerId,
        cropType: formData.cropType,
        season: seasonEnum,
        cultivationYear: 2026,
        cultivationMonth: 5,
        areaAcres: Number(formData.areaAcres),
        expectedYieldKg: Number(formData.expectedYieldKg),
        province: 'North Central',
        district: formData.district,
        dsDivision: formData.dsDivision,
        village: 'Agri Zone',
        status: 'cultivating',
      },
    });

    revalidatePath('/');
    return { success: true };
  } catch (error: any) {
    console.error('Error creating crop plan:', error);
    return { success: false, error: error?.message || 'Failed to create crop plan' };
  }
}
