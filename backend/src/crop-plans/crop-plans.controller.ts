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
import { CropPlansService } from './crop-plans.service';
import {
  CreateCropPlanDto,
  CropPlanQueryDto,
  UpdateCropPlanDto,
} from './dto/crop-plan.dto';

@Controller('crop-plans')
export class CropPlansController {
  constructor(private cropPlansService: CropPlansService) {}

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.farmer)
  @Get('mine')
  mine(@Request() req: AuthRequest) {
    return this.cropPlansService.findMine(req.user.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.government)
  @Get('aggregates')
  aggregates(@Query() query: CropPlanQueryDto) {
    return this.cropPlansService.aggregates(query);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.government)
  @Get('dashboard')
  dashboard(@Query() query: CropPlanQueryDto) {
    return this.cropPlansService.dashboard(query);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.government)
  @Get('insights')
  insights(@Query() query: CropPlanQueryDto) {
    return this.cropPlansService.insights(query);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.farmer)
  @Post()
  create(@Request() req: AuthRequest, @Body() dto: CreateCropPlanDto) {
    return this.cropPlansService.create(req.user, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.farmer)
  @Patch(':id')
  update(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: UpdateCropPlanDto,
  ) {
    return this.cropPlansService.update(req.user, id, dto);
  }
}
