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
  ConfirmDeliveryDto,
  ConfirmTransportDto,
  CreateAddressDto,
  CreateDisputeDto,
  CreateTransportRequestDto,
  HandoverDto,
  PricingRuleDto,
  RateTransporterDto,
  TrackingUpdateDto,
} from './dto/logistics.dto';
import { LogisticsService } from './logistics.service';

@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class LogisticsController {
  constructor(private logistics: LogisticsService) {}

  @Roles(UserRole.business)
  @Get('delivery-addresses')
  addresses(@Request() req: AuthRequest) {
    return this.logistics.listAddresses(req.user.id);
  }

  @Roles(UserRole.business)
  @Post('delivery-addresses')
  createAddress(@Request() req: AuthRequest, @Body() dto: CreateAddressDto) {
    return this.logistics.createAddress(req.user.id, dto);
  }

  @Get('orders/:orderId/transport-quote')
  quote(@Param('orderId') orderId: string) {
    return this.logistics.quote(orderId);
  }

  @Get('transport-requests')
  list(@Request() req: AuthRequest) {
    return this.logistics.listRequests(req.user);
  }

  @Roles(UserRole.business)
  @Post('transport-requests')
  create(@Request() req: AuthRequest, @Body() dto: CreateTransportRequestDto) {
    return this.logistics.createRequest(req.user, dto);
  }

  @Get('transport-requests/:id')
  getOne(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.logistics.getRequest(req.user, id);
  }

  @Get('transport-requests/:id/matches')
  matches(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.logistics.match(req.user, id);
  }

  @Roles(UserRole.transporter)
  @Get('transporter/jobs')
  jobs(@Request() req: AuthRequest) {
    return this.logistics.availableJobs(req.user);
  }

  @Roles(UserRole.transporter)
  @Get('transporter/my-jobs')
  myJobs(@Request() req: AuthRequest) {
    return this.logistics.myJobs(req.user);
  }

  @Roles(UserRole.transporter)
  @Get('transporter/earnings')
  earnings(@Request() req: AuthRequest) {
    return this.logistics.earnings(req.user);
  }

  @Roles(UserRole.transporter)
  @Post('transport-requests/:id/accept')
  accept(@Request() req: AuthRequest, @Param('id') id: string) {
    return this.logistics.acceptJob(req.user, id);
  }

  @Roles(UserRole.business)
  @Post('transport-requests/:id/confirm')
  confirm(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: ConfirmTransportDto,
  ) {
    return this.logistics.confirmTransport(req.user, id, dto);
  }

  @Patch('transport-requests/:id/status')
  status(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: TrackingUpdateDto,
  ) {
    return this.logistics.updateStatus(req.user, id, dto);
  }

  @Roles(UserRole.farmer)
  @Post('transport-requests/:id/handover')
  handover(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: HandoverDto,
  ) {
    return this.logistics.farmerHandover(req.user, id, dto);
  }

  @Roles(UserRole.business)
  @Post('transport-requests/:id/confirm-delivery')
  confirmDelivery(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: ConfirmDeliveryDto,
  ) {
    return this.logistics.confirmDelivery(req.user, id, dto);
  }

  @Roles(UserRole.business)
  @Post('transport-requests/:id/disputes')
  dispute(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: CreateDisputeDto,
  ) {
    return this.logistics.createDispute(req.user, id, dto);
  }

  @Roles(UserRole.business)
  @Post('transport-requests/:id/rate')
  rate(
    @Request() req: AuthRequest,
    @Param('id') id: string,
    @Body() dto: RateTransporterDto,
  ) {
    return this.logistics.rate(req.user, id, dto);
  }

  @Roles(UserRole.government)
  @Get('admin/logistics')
  admin() {
    return this.logistics.adminOverview();
  }

  @Roles(UserRole.government)
  @Post('admin/transport-pricing')
  pricing(@Body() dto: PricingRuleDto) {
    return this.logistics.upsertPricing(dto);
  }

  @Roles(UserRole.government)
  @Patch('admin/disputes/:id')
  resolve(
    @Param('id') id: string,
    @Body() body: { status: 'resolved' | 'rejected'; remarks?: string },
  ) {
    return this.logistics.resolveDispute(id, body.status, body.remarks);
  }
}
