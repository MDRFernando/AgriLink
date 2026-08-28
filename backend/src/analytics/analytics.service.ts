import { Injectable } from '@nestjs/common';
import { ProductionStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type AlertType = 'shortage' | 'surplus' | 'stable';

@Injectable()
export class AnalyticsService {
  constructor(private prisma: PrismaService) {}

  async getRegionalAnalytics() {
    const productions = await this.prisma.production.findMany({
      where: {
        status: {
          in: [ProductionStatus.available, ProductionStatus.readyForHarvest],
        },
      },
      include: { farmer: { select: { id: true } } },
    });

    const grouped = new Map<
      string,
      { region: string; cropType: string; totalQuantity: number; unit: string; farmers: Set<string> }
    >();

    for (const p of productions) {
      const key = `${p.region}::${p.cropType}`;
      const entry = grouped.get(key) ?? {
        region: p.region,
        cropType: p.cropType,
        totalQuantity: 0,
        unit: p.unit,
        farmers: new Set<string>(),
      };
      entry.totalQuantity += p.quantity;
      entry.farmers.add(p.farmerId);
      grouped.set(key, entry);
    }

    return Array.from(grouped.values()).map((entry) => ({
      region: entry.region,
      cropType: entry.cropType,
      totalQuantity: entry.totalQuantity,
      unit: entry.unit,
      farmerCount: entry.farmers.size,
      alertType: this.classifyAlert(entry.totalQuantity),
    }));
  }

  async getCropTrend(cropType: string) {
    const productions = await this.prisma.production.findMany({
      where: { cropType },
      orderBy: { createdAt: 'asc' },
    });

    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const buckets = new Map<string, number>();

    for (const p of productions) {
      const month = monthNames[p.createdAt.getMonth()];
      buckets.set(month, (buckets.get(month) ?? 0) + p.quantity);
    }

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    return months.map((month) => ({
      month,
      quantity: buckets.get(month) ?? 0,
    }));
  }

  async getAlerts() {
    const regional = await this.getRegionalAnalytics();
    return {
      alerts: regional.filter((r) => r.alertType !== 'stable'),
      stable: regional.filter((r) => r.alertType === 'stable'),
    };
  }

  async getDashboardSummary() {
    const [productionCount, demandCount, interestCount, userCount] =
      await Promise.all([
        this.prisma.production.count(),
        this.prisma.demandRequest.count({ where: { status: 'open' } }),
        this.prisma.purchaseInterest.count({ where: { status: 'pending' } }),
        this.prisma.user.count(),
      ]);

    return {
      totalProductions: productionCount,
      openDemands: demandCount,
      pendingInterests: interestCount,
      registeredUsers: userCount,
    };
  }

  private classifyAlert(quantity: number): AlertType {
    if (quantity < 5000) return 'shortage';
    if (quantity > 20000) return 'surplus';
    return 'stable';
  }
}
