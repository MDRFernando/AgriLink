import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';

export {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
  UnauthorizedException,
};

export const CROP_TYPES = [
  'Rice',
  'Wheat',
  'Maize',
  'Potato',
  'Tomato',
  'Onion',
  'Tea',
  'Coconut',
  'Chilli',
  'Banana',
];

export const REGIONS = [
  'Western Province',
  'Central Province',
  'Southern Province',
  'Northern Province',
  'Eastern Province',
  'North Western Province',
  'North Central Province',
  'Uva Province',
  'Sabaragamuwa Province',
];

export const QUANTITY_UNITS = ['kg', 'ton', 'bushel', 'crate'];
