import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/roles.guard';
import { AuthRequest } from '../common/types';
import { OrdersService } from './orders.service';

@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
  constructor(private orders: OrdersService) {}

  @Get()
  list(@Request() req: AuthRequest) {
    return this.orders.listMine(req.user);
  }

  @Get('intermediary-index')
  intermediary() {
    return this.orders.intermediaryIndex();
  }

  @Get(':id')
  getOne(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.orders.getOne(req.user, id);
  }

  @Post(':id/confirm')
  confirm(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.orders.confirm(req.user, id);
  }

  @Post(':id/pay')
  pay(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Query('succeed') succeed?: string,
    @Body() body?: { method?: string },
  ) {
    return this.orders.sandboxPay(req.user, id, succeed !== 'false', body?.method);
  }

  @Get(':id/income-impact')
  income(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.orders.incomeImpact(req.user, id);
  }
}
