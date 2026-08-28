import { Injectable } from '@nestjs/common';
import { NotificationAudience } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private prisma: PrismaService) {}

  async notify(
    userId: string,
    audience: NotificationAudience,
    title: string,
    body: string,
  ) {
    return this.prisma.appNotification.create({
      data: { userId, audience, title, body },
    });
  }

  async listMine(userId: string) {
    return this.prisma.appNotification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async markRead(userId: string, id: string) {
    return this.prisma.appNotification.updateMany({
      where: { id, userId },
      data: { readAt: new Date() },
    });
  }
}
