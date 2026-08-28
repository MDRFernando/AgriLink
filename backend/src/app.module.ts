import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AnalyticsModule } from './analytics/analytics.module';
import { AuthModule } from './auth/auth.module';
import { DemandsModule } from './demands/demands.module';
import { InterestsModule } from './interests/interests.module';
import { LogisticsModule } from './logistics/logistics.module';
import { MarketplaceModule } from './marketplace/marketplace.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProductionsModule } from './productions/productions.module';
import { ReferenceModule } from './reference/reference.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    NotificationsModule,
    AuthModule,
    ProductionsModule,
    DemandsModule,
    InterestsModule,
    AnalyticsModule,
    ReferenceModule,
    MarketplaceModule,
    LogisticsModule,
  ],
})
export class AppModule {}
