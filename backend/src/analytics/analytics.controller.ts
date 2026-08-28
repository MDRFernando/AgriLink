import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { JwtAuthGuard, Roles, RolesGuard } from '../common/guards/roles.guard';
import { AnalyticsService } from './analytics.service';

@Controller('analytics')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.government)
export class AnalyticsController {
  constructor(private analyticsService: AnalyticsService) {}

  @Get('dashboard')
  getDashboard() {
    return this.analyticsService.getDashboardSummary();
  }

  @Get('regional')
  getRegional() {
    return this.analyticsService.getRegionalAnalytics();
  }

  @Get('trends/:cropType')
  getTrend(@Param('cropType') cropType: string) {
    return this.analyticsService.getCropTrend(cropType);
  }

  @Get('alerts')
  getAlerts() {
    return this.analyticsService.getAlerts();
  }
}
