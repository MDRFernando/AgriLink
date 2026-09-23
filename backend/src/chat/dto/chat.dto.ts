import { IsArray, IsIn, IsString, MinLength, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class ChatTurnDto {
  @IsIn(['user', 'model'])
  role!: string;

  @IsString()
  @MinLength(1)
  text!: string;
}

export class FarmerChatDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ChatTurnDto)
  messages!: ChatTurnDto[];

  @IsString()
  @MinLength(1)
  userText!: string;
}
