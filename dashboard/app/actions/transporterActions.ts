'use server';

import { revalidatePath } from 'next/cache';
import { prisma } from '@/lib/db';
import { getSession } from '@/lib/auth';
import { TransportJob, Vehicle, TransportStatus, VehicleType } from '@/lib/types';

export async function getTransporterDataAction(): Promise<{
  jobs: TransportJob[];
  fleet: Vehicle[];
}> {
  try {
    // 1. Fetch Transport Requests from DB
    let dbJobs = await prisma.transportRequest.findMany({
      include: {
        order: true,
        farmer: { select: { name: true, phone: true, district: true } },
        buyer: { select: { name: true, organizationName: true, district: true } },
        transporter: { select: { name: true, organizationName: true } },
        vehicle: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    // If no transport requests exist yet, synthesize one from the existing order in DB
    if (dbJobs.length === 0) {
      const order = await prisma.order.findFirst({
        include: { farmer: true, buyer: true },
      });
      const transporterUser = await prisma.user.findFirst({
        where: { role: 'transporter' },
        include: { transporterProfile: true },
      });
      const vehicle = await prisma.vehicle.findFirst();

      if (order && transporterUser) {
        try {
          const newRequest = await prisma.transportRequest.create({
            data: {
              requestCode: `TRP-2026-001`,
              orderId: order.id,
              buyerId: order.buyerId,
              farmerId: order.farmerId,
              transporterId: transporterUser.id,
              vehicleId: vehicle?.id,
              pickupLabel: `${order.farmer.region || 'Anuradhapura'} Farmgate Hub`,
              pickupCity: order.farmer.district || 'Anuradhapura',
              deliveryLabel: `${order.buyer.organizationName || 'Keells'} Central Depot`,
              deliveryCity: order.buyer.district || 'Colombo',
              product: 'Banana / Samba (500kg Lot)',
              quantityKg: order.quantityKg,
              requiredVehicleType: 'small_lorry',
              requiredCapacityKg: 2000,
              distanceKm: 185,
              estimatedCost: 32500,
              status: 'in_transit',
              driverName: transporterUser.name || 'Ruwan Fernando',
            },
            include: {
              order: true,
              farmer: { select: { name: true, phone: true, district: true } },
              buyer: { select: { name: true, organizationName: true, district: true } },
              transporter: { select: { name: true, organizationName: true } },
              vehicle: true,
            },
          });
          dbJobs = [newRequest];
        } catch (e) {
          console.warn('Auto-init transport request skipped:', e);
        }
      }
    }

    const jobs: TransportJob[] = dbJobs.map((j) => ({
      id: j.id,
      requestCode: j.requestCode,
      product: j.product,
      quantityKg: j.quantityKg,
      requiredVehicle: (j.requiredVehicleType as VehicleType) || 'medium_lorry',
      pickupDistrict: j.pickupCity,
      pickupAddress: j.pickupLabel,
      farmerName: j.farmer?.name || 'Farmer',
      farmerPhone: j.farmer?.phone || '+94 77 123 4567',
      deliveryDistrict: j.deliveryCity,
      deliveryAddress: j.deliveryLabel,
      buyerName: j.buyer?.organizationName || j.buyer?.name || 'Buyer',
      distanceKm: j.distanceKm,
      estimatedEarnings: j.estimatedCost,
      status: (j.status as TransportStatus) || 'in_transit',
      driverName: j.driverName || j.transporter?.name || undefined,
      vehicleNumber: j.vehicle?.vehicleNumber || undefined,
      updatedAt: j.updatedAt ? new Date(j.updatedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Recently',
      otpCode: '5821',
    }));

    // 2. Fetch Fleet from DB
    const dbVehicles = await prisma.vehicle.findMany({
      include: {
        transporter: {
          include: { user: { select: { name: true } } },
        },
      },
    });

    const fleet: Vehicle[] = dbVehicles.map((v) => ({
      id: v.id,
      vehicleNumber: v.vehicleNumber,
      vehicleType: (v.vehicleType as VehicleType) || 'medium_lorry',
      capacityKg: v.capacityKg,
      status: (v.status as any) || 'active',
      currentDriver: v.transporter?.user?.name || 'Assigned Driver',
      fuelEfficiencyKmPerL: v.vehicleType === 'pickup' ? 11.2 : v.vehicleType === 'small_lorry' ? 8.5 : 6.5,
    }));

    return { jobs, fleet };
  } catch (error) {
    console.error('Error fetching transporter data from DB:', error);
    return { jobs: [], fleet: [] };
  }
}

export async function updateTransportStatusAction(
  jobId: string,
  newStatus: TransportStatus,
  driverName?: string,
  vehicleNumber?: string
) {
  try {
    await prisma.$transaction([
      prisma.transportRequest.update({
        where: { id: jobId },
        data: {
          status: newStatus as any,
          driverName: driverName || undefined,
        },
      }),
      prisma.deliveryTracking.create({
        data: {
          transportRequestId: jobId,
          status: newStatus as any,
          note: `Trip advanced to ${newStatus.replace(/_/g, ' ')}`,
        },
      }),
    ]);

    revalidatePath('/');
    return { success: true };
  } catch (error: any) {
    console.error('Error updating transport status:', error);
    return { success: false, error: error?.message || 'Failed to update transport status' };
  }
}

export async function createVehicleAction(formData: {
  vehicleNumber: string;
  vehicleType: VehicleType;
  capacityKg: number;
}) {
  try {
    const sessionData = await getSession();
    let transporterProfile = sessionData?.user?.transporterProfile;

    if (!transporterProfile) {
      const anyProfile = await prisma.transporterProfile.findFirst();
      transporterProfile = anyProfile || undefined;
    }

    if (!transporterProfile) {
      return { success: false, error: 'Transporter profile required to register vehicles' };
    }

    await prisma.vehicle.create({
      data: {
        transporterId: transporterProfile.id,
        vehicleNumber: formData.vehicleNumber.toUpperCase(),
        vehicleType: formData.vehicleType,
        capacityKg: Number(formData.capacityKg),
        status: 'active',
      },
    });

    revalidatePath('/');
    return { success: true };
  } catch (error: any) {
    console.error('Error creating vehicle:', error);
    return { success: false, error: error?.message || 'Failed to add vehicle' };
  }
}
