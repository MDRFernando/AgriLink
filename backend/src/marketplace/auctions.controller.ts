import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { IsNumber, Min } from 'class-validator';
import { JwtAuthGuard, Roles, RolesGuard } from '../common/guards/roles.guard';
import { AuthRequest } from '../common/types';
import { AuctionsService } from './auctions.service';

class PlaceBidDto {
  @IsNumber()
  @Min(0.01)
  amount!: number;
}

@Controller()
export class AuctionsController {
  constructor(private auctions: AuctionsService) {}

  @Get('productions/:id/auction')
  getAuction(@Param('id') id: string) {
    return this.auctions.getByProduction(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.business)
  @Post('productions/:id/bids')
  placeBid(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: PlaceBidDto,
  ) {
    return this.auctions.placeBid(req.user, id, dto.amount);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.government)
  @Post('auctions/:id/close')
  close(@Param('id') id: string) {
    return this.auctions.closeAuction(id);
  }
}
