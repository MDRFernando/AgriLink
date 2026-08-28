import { Controller, Get } from '@nestjs/common';
import {
  CROP_TYPES,
  QUANTITY_UNITS,
  REGIONS,
} from '../common/constants';

@Controller('reference')
export class ReferenceController {
  @Get('crops')
  getCrops() {
    return CROP_TYPES;
  }

  @Get('regions')
  getRegions() {
    return REGIONS;
  }

  @Get('units')
  getUnits() {
    return QUANTITY_UNITS;
  }
}
