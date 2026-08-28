import { Module } from '@nestjs/common';
import { AuctionsController } from './auctions.controller';
import { AuctionsService } from './auctions.service';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';

@Module({
  controllers: [AuctionsController, OrdersController],
  providers: [AuctionsService, OrdersService],
  exports: [AuctionsService, OrdersService],
})
export class MarketplaceModule {}
