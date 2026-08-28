import { Controller, Get, Param, Patch, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/roles.guard';
import { AuthRequest } from '../common/types';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private notifications: NotificationsService) {}

  @Get()
  list(@Request() req: AuthRequest) {
    return this.notifications.listMine(req.user.id);
  }

  @Patch(':id/read')
  read(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.notifications.markRead(req.user.id, id);
  }
}
