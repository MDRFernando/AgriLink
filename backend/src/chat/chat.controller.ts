import { Body, Controller, Post } from '@nestjs/common';
import { ChatService } from './chat.service';
import { FarmerChatDto } from './dto/chat.dto';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('farmer')
  farmer(@Body() dto: FarmerChatDto) {
    return this.chatService.farmerReply(dto.messages ?? [], dto.userText);
  }
}
