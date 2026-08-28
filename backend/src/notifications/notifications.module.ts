import { Global, Module } from '@nestjs/common';
import { ListingCodeService } from '../common/listing-code.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

@Global()
@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, ListingCodeService],
  exports: [NotificationsService, ListingCodeService],
})
export class NotificationsModule {}
