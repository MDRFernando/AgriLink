import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ListingCodeService {
  constructor(private prisma: PrismaService) {}

  async nextCode(date = new Date()): Promise<string> {
    const year = date.getFullYear();
    const seq = await this.prisma.listingSequence.upsert({
      where: { year },
      create: { year, lastNumber: 1 },
      update: { lastNumber: { increment: 1 } },
    });
    return `BIT-${year}-${String(seq.lastNumber).padStart(6, '0')}`;
  }
}
