import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { JwtAuthGuard, Roles, RolesGuard } from '../common/guards/roles.guard';
import { AuthRequest } from '../common/types';
import {
  CreateInterestDto,
  UpdateInterestStatusDto,
} from './dto/interest.dto';
import { InterestsService } from './interests.service';

@Controller('interests')
@UseGuards(JwtAuthGuard, RolesGuard)
export class InterestsController {
  constructor(private interestsService: InterestsService) {}

  @Roles(UserRole.business)
  @Get('mine')
  findMine(@Request() req: AuthRequest) {
    return this.interestsService.findMine(req.user.id);
  }

  @Roles(UserRole.farmer)
  @Get('received')
  findReceived(@Request() req: AuthRequest) {
    return this.interestsService.findReceived(req.user.id);
  }

  @Roles(UserRole.business)
  @Post()
  create(@Request() req: AuthRequest, @Body() dto: CreateInterestDto) {
    return this.interestsService.create(req.user, dto);
  }

  @Roles(UserRole.farmer)
  @Patch(':id/status')
  updateStatus(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: UpdateInterestStatusDto,
  ) {
    return this.interestsService.updateStatus(req.user, id, dto);
  }
}
