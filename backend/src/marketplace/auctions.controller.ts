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
import { Type } from 'class-transformer';
import { IsNumber, Min } from 'class-validator';
import { JwtAuthGuard, OptionalJwtAuthGuard, Roles, RolesGuard } from '../common/guards/roles.guard';
import { AuthRequest } from '../common/types';
import { AuctionsService } from './auctions.service';

class PlaceBidDto {
  @Type(() => Number)
  @IsNumber()
  @Min(0.01)
  amount!: number;

  @Type(() => Number)
  @IsNumber()
  @Min(0.01)
  quantity!: number;
}

@Controller()
export class AuctionsController {
  constructor(private auctions: AuctionsService) {}

  @UseGuards(OptionalJwtAuthGuard)
  @Get('productions/:id/auction')
  getAuction(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.auctions.getByProduction(id, req.user ?? null);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.business)
  @Post('productions/:id/bids')
  placeBid(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: PlaceBidDto,
  ) {
    return this.auctions.placeBid(req.user, id, dto.amount, dto.quantity);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.farmer)
  @Get('bids/farmer')
  farmerBids(@Request() req: AuthRequest) {
    return this.auctions.listForFarmer(req.user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.business)
  @Get('bids/mine')
  buyerBids(@Request() req: AuthRequest) {
    return this.auctions.listForBuyer(req.user);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.farmer)
  @Post('bids/:id/accept')
  accept(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.auctions.acceptBid(req.user, id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.farmer)
  @Post('bids/:id/decline')
  decline(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.auctions.declineBid(req.user, id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.government)
  @Post('auctions/:id/close')
  close(@Param('id') id: string) {
    return this.auctions.closeAuction(id);
  }
}
