import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { JwtAuthGuard, Roles, RolesGuard } from '../common/guards/roles.guard';
import { AuthRequest } from '../common/types';
import {
  CreateDemandDto,
  DemandQueryDto,
  UpdateDemandStatusDto,
} from './dto/demand.dto';
import { DemandsService } from './demands.service';

@Controller('demands')
export class DemandsController {
  constructor(private demandsService: DemandsService) {}

  @Get()
  findAll(@Query() query: DemandQueryDto) {
    return this.demandsService.findAll(query);
  }

  @UseGuards(JwtAuthGuard)
  @Get('mine')
  findMine(@Request() req: AuthRequest) {
    return this.demandsService.findMine(req.user.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.business, UserRole.government)
  @Post()
  create(@Request() req: AuthRequest, @Body() dto: CreateDemandDto) {
    return this.demandsService.create(req.user, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.business, UserRole.government)
  @Patch(':id/status')
  updateStatus(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: UpdateDemandStatusDto,
  ) {
    return this.demandsService.updateStatus(req.user, id, dto);
  }
}
