'use server';

import { revalidatePath } from 'next/cache';
import { prisma } from '@/lib/db';
import { getSession } from '@/lib/auth';
import { ProductionListing, DemandRequest, OrderItem, QualityGrade } from '@/lib/types';
import { DemandStatus } from '@prisma/client';

export async function getBuyerDataAction(): Promise<{
  productions: ProductionListing[];
  demands: DemandRequest[];
  orders: OrderItem[];
}> {
  try {
    // 1. Fetch marketplace listings (productions with auctions)
    const dbProductions = await prisma.production.findMany({
      include: {
        farmer: {
          select: { id: true, name: true, phone: true, region: true, district: true },
        },
        auction: {
          include: {
            bids: {
              include: {
                buyer: { select: { id: true, name: true, organizationName: true } },
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
      } else if (cropLower.includes('chili') || cropLower.includes('pepper') || cropLower.includes('spice')) {
        category = 'Spices';
      } else if (cropLower.includes('banana') || cropLower.includes('mango') || cropLower.includes('fruit')) {
        category = 'Fruits';
      }

      const minPrice = p.minAcceptablePrice ?? 150;

      return {
        id: p.id,
        listingCode: p.listingCode || `LST-2026-${p.id.slice(0, 4).toUpperCase()}`,
        farmerName: p.farmer?.name || 'Local Producer',
        farmerPhone: p.farmer?.phone || '+94 77 123 4567',
        cropType: p.cropType,
        variety: p.variety || 'Certified Commercial',
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
        description: p.notes || p.description || `Direct farmgate listing of ${p.cropType}, grade ${p.qualityGrade}.`,
        activeAuction: p.auction
          ? {
              id: p.auction.id,
              openingBid: p.auction.openingBid,
              currentHighestBid: highestBid,
              bidCount: p.auction.bids?.length || 0,
              endsInMinutes,
              status: (p.auction.status as any) || 'open',
              highestBidderName:
                topBid?.buyer?.organizationName || topBid?.buyer?.name || 'Keells Foods',
            }
          : undefined,
      };
    });

    // 2. Fetch Demands from DB
    const dbDemands = await prisma.demandRequest.findMany({
      include: {
        requester: { select: { id: true, name: true, organizationName: true, district: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    const demands: DemandRequest[] = dbDemands.map((d) => ({
      id: d.id,
      buyerName: d.requester?.name || 'Procurement Officer',
      buyerCompany: d.requester?.organizationName || 'Keells Wholesale Consortium',
      cropType: d.cropType,
      quantityNeededKg: d.quantityNeeded,
      fulfilledKg: Math.round(d.quantityNeeded * 0.45),
      targetPriceKg: 250,
      deadline: d.deadline ? new Date(d.deadline).toISOString().split('T')[0] : '2026-10-15',
      district: d.region || d.requester?.district || 'Colombo',
      status: (d.status as any) || 'open',
      notes: d.notes || 'Island-wide supermarket supply requirement.',
    }));

    // 3. Fetch Orders from DB
    const dbOrders = await prisma.order.findMany({
      include: {
        farmer: { select: { name: true, phone: true, district: true } },
        buyer: { select: { name: true, organizationName: true } },
        transportRequests: {
          include: { transporter: { select: { name: true, organizationName: true } } },
        },
        payment: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    const orders: OrderItem[] = dbOrders.map((ord) => {
      const transporter = ord.transportRequests?.[0]?.transporter;
      const orderStatus = (ord.status as any) || 'confirmed';

      return {
        id: ord.id,
        orderCode: `ORD-2026-${ord.id.slice(0, 4).toUpperCase()}`,
        cropType: 'Wholesale Produce',
        variety: 'Standard Lot',
        quantityKg: ord.quantityKg,
        pricePerKg: ord.winningPriceKg,
        totalAmount: ord.quantityKg * ord.winningPriceKg,
        farmerName: ord.farmer?.name || 'Farmer',
        buyerName: ord.buyer?.organizationName || ord.buyer?.name || 'Buyer',
        transporterName: transporter?.organizationName || transporter?.name || 'Rajarata Express Logistics',
        orderStatus,
        paymentStatus: ord.payment?.status === 'paid' ? 'settled' : 'sandbox_paid',
        deliveryMethod: 'bit_app_transport',
        createdAt: ord.createdAt ? new Date(ord.createdAt).toISOString().replace('T', ' ').slice(0, 16) : '2026-09-18 10:00',
        pickupLocation: `${ord.farmer?.district || 'Anuradhapura'} Farmgate Hub`,
        deliveryLocation: 'Colombo Wholesale Distribution Center',
        disputeNotes: ord.remarks || undefined,
      };
    });

    return { productions, demands, orders };
  } catch (error) {
    console.error('Error fetching buyer data from DB:', error);
    return { productions: [], demands: [], orders: [] };
  }
}

export async function placeBidAction(productionId: string, amount: number, quantity?: number) {
  try {
    const sessionData = await getSession();
    let buyerId = sessionData?.user?.id;

    if (!buyerId) {
      const fallbackBuyer = await prisma.user.findFirst({ where: { role: 'business' } });
      buyerId = fallbackBuyer?.id;
    }

    if (!buyerId) {
      return { success: false, error: 'Buyer account required to place bids' };
    }

    const production = await prisma.production.findUnique({
      where: { id: productionId },
      include: { auction: true },
    });

    if (!production || !production.auction) {
      return { success: false, error: 'Auction listing not found' };
    }

    const bidQuantity = quantity || production.quantity;
    const bidAmount = Number(amount);

    await prisma.bid.create({
      data: {
        auctionId: production.auction.id,
        productionId: production.id,
        buyerId,
        farmerId: production.farmerId,
        amount: bidAmount,
        quantity: bidQuantity,
        totalAmount: bidAmount * bidQuantity,
        status: 'pending',
      },
    });

    revalidatePath('/');
    return { success: true };
  } catch (error: any) {
    console.error('Error placing bid in DB:', error);
    return { success: false, error: error?.message || 'Failed to place bid' };
  }
}

export async function createDemandRequestAction(formData: {
  cropType: string;
  quantityNeededKg: number;
  targetPriceKg: number;
  deadline: string;
  district: string;
  notes?: string;
}) {
  try {
    const sessionData = await getSession();
    let requesterId = sessionData?.user?.id;

    if (!requesterId) {
      const fallbackBuyer = await prisma.user.findFirst({ where: { role: 'business' } });
      requesterId = fallbackBuyer?.id;
    }

    if (!requesterId) {
      return { success: false, error: 'Buyer account required' };
    }

    await prisma.demandRequest.create({
      data: {
        requesterId,
        cropType: formData.cropType,
        quantityNeeded: Number(formData.quantityNeededKg),
        unit: 'kg',
        deadline: new Date(formData.deadline || Date.now() + 14 * 24 * 60 * 60 * 1000),
        region: formData.district || 'Colombo',
        status: DemandStatus.open,
        notes: formData.notes || 'Consolidated wholesale order.',
      },
    });

    revalidatePath('/');
    return { success: true };
  } catch (error: any) {
    console.error('Error creating demand request in DB:', error);
    return { success: false, error: error?.message || 'Failed to create demand' };
  }
}
