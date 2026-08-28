import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { User, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { ConflictException } from '../common/constants';
import { JwtPayload, SafeUser, toSafeUser } from '../common/types';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto, RegisterDto, UpdateProfileDto } from './dto/auth.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });
    if (existing) throw new ConflictException('Email already registered');

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase(),
        passwordHash,
        name: dto.name,
        role: dto.role,
        phone: dto.phone,
        nic: dto.nic,
      },
    });

    if (dto.role === UserRole.farmer) {
      await this.prisma.farmerProfile.create({ data: { userId: user.id } });
    }
    if (dto.role === UserRole.business) {
      await this.prisma.buyerProfile.create({
        data: { userId: user.id, businessName: dto.name },
      });
    }
    if (dto.role === UserRole.transporter) {
      await this.prisma.transporterProfile.create({
        data: { userId: user.id, company: dto.name, availabilityStatus: 'available' },
      });
    }

    return this.buildAuthResponse(user);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });
    if (!user) throw new UnauthorizedException('Invalid credentials');

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('Invalid credentials');

    return this.buildAuthResponse(user);
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { farmerProfile: true, buyerProfile: true, transporterProfile: true },
    });
    if (!user) throw new UnauthorizedException('User not found');
    const { passwordHash: _, ...safe } = user;
    return safe;
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('User not found');

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        name: dto.name,
        phone: dto.phone,
        organizationName: dto.organizationName,
        region: dto.region,
        nic: dto.nic,
        address: dto.address,
        district: dto.district,
        province: dto.province ?? dto.region,
        isVerified: user.role === UserRole.business ? user.isVerified : true,
      },
    });

    if (user.role === UserRole.farmer) {
      await this.prisma.farmerProfile.upsert({
        where: { userId },
        create: {
          userId,
          farmLocation: dto.farmLocation,
          farmSizeAcres: dto.farmSizeAcres,
          cropTypesJson: dto.cropTypesJson,
          preferredCropsJson: dto.preferredCropsJson,
          estimatedCapacityKg: dto.estimatedCapacityKg,
          traditionalFarmgatePriceKg: dto.traditionalFarmgatePriceKg,
          harvestingCostPerKg: dto.harvestingCostPerKg,
          incomeBeforeBitApp: dto.incomeBeforeBitApp,
          lat: dto.lat,
          lng: dto.lng,
        },
        update: {
          farmLocation: dto.farmLocation,
          farmSizeAcres: dto.farmSizeAcres,
          cropTypesJson: dto.cropTypesJson,
          preferredCropsJson: dto.preferredCropsJson,
          estimatedCapacityKg: dto.estimatedCapacityKg,
          traditionalFarmgatePriceKg: dto.traditionalFarmgatePriceKg,
          harvestingCostPerKg: dto.harvestingCostPerKg,
          incomeBeforeBitApp: dto.incomeBeforeBitApp,
          lat: dto.lat,
          lng: dto.lng,
        },
      });
    }

    if (user.role === UserRole.business) {
      await this.prisma.buyerProfile.upsert({
        where: { userId },
        create: {
          userId,
          nicOrBrn: dto.nicOrBrn,
          businessName: dto.businessName ?? dto.organizationName,
          businessType: dto.businessType,
          location: dto.buyerLocation ?? dto.address,
          preferredCropsJson: dto.preferredCropsJson,
          preferredPriceMin: dto.preferredPriceMin,
          preferredPriceMax: dto.preferredPriceMax,
          requiredQuantityKg: dto.requiredQuantityKg,
          lat: dto.lat,
          lng: dto.lng,
        },
        update: {
          nicOrBrn: dto.nicOrBrn,
          businessName: dto.businessName ?? dto.organizationName,
          businessType: dto.businessType,
          location: dto.buyerLocation ?? dto.address,
          preferredCropsJson: dto.preferredCropsJson,
          preferredPriceMin: dto.preferredPriceMin,
          preferredPriceMax: dto.preferredPriceMax,
          requiredQuantityKg: dto.requiredQuantityKg,
          lat: dto.lat,
          lng: dto.lng,
        },
      });
    }

    return this.getProfile(updated.id);
  }

  private buildAuthResponse(user: User) {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };
    return {
      accessToken: this.jwtService.sign(payload),
      user: toSafeUser(user),
    };
  }
}
