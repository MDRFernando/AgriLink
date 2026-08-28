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
  CreateProductionDto,
  ProductionQueryDto,
  UpdateProductionDto,
  UpdateProductionStatusDto,
} from './dto/production.dto';
import { ProductionsService } from './productions.service';

@Controller('productions')
export class ProductionsController {
  constructor(private productionsService: ProductionsService) {}

  @Get()
  findAll(@Query() query: ProductionQueryDto) {
    return this.productionsService.findAvailable(query);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.farmer)
  @Get('mine')
  findMine(@Request() req: AuthRequest) {
    return this.productionsService.findMine(req.user.id);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.productionsService.findOne(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.farmer)
  @Post()
  create(@Request() req: AuthRequest, @Body() dto: CreateProductionDto) {
    return this.productionsService.create(req.user, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.farmer)
  @Patch(':id')
  update(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: UpdateProductionDto,
  ) {
    return this.productionsService.update(req.user, id, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.farmer)
  @Patch(':id/status')
  updateStatus(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: UpdateProductionStatusDto,
  ) {
    return this.productionsService.updateStatus(req.user, id, dto);
  }
}
