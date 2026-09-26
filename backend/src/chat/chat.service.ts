import {
  Injectable,
  ServiceUnavailableException,
  BadRequestException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AGRILINK_FARMER_CHAT_PROMPT } from './agri-link-guide';
import { ChatTurnDto } from './dto/chat.dto';

@Injectable()
export class ChatService {
  constructor(private readonly config: ConfigService) {}

  async farmerReply(messages: ChatTurnDto[], userText: string): Promise<{ text: string }> {
    const apiKey = this.config.get<string>('GEMINI_API_KEY')?.trim();
    if (!apiKey) {
      throw new ServiceUnavailableException(
        'AgriLink chat is not configured. Add GEMINI_API_KEY to the API environment.',
      );
    }

    const contents = [
      ...messages
        .filter((item) => item.text?.trim())
        .map((item) => ({
          role: item.role === 'model' ? 'model' : 'user',
          parts: [{ text: item.text.trim() }],
        })),
      { role: 'user', parts: [{ text: userText.trim() }] },
    ];

    const body = JSON.stringify({
      system_instruction: {
        parts: [{ text: AGRILINK_FARMER_CHAT_PROMPT }],
      },
      contents,
      generationConfig: {
        temperature: 0.3,
        maxOutputTokens: 2048,
        thinkingConfig: { thinkingBudget: 0 },
      },
    });

    const preferred = this.config.get<string>('GEMINI_MODEL', 'gemini-2.5-flash-lite');
    const fallbacks = [
      'gemini-2.5-flash-lite',
      'gemini-3.5-flash',
      'gemini-2.5-flash',
      'gemini-flash-latest',
    ];
    const uniqueModels = [...new Set([preferred, ...fallbacks].map((item) => item.trim()).filter(Boolean))];

    let lastMessage =
      'දැන් පිළිතුර ලබා දිය නොහැක. මොහොතකින් නැවත උත්සාහ කරන්න.';
    for (const model of uniqueModels) {
      try {
        return { text: await this.callGemini(model, apiKey, body) };
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        lastMessage = message;
        if (!this.shouldRetryModel(message)) {
          throw error;
        }
      }
    }
    throw new ServiceUnavailableException(lastMessage);
  }

  private async callGemini(model: string, apiKey: string, body: string): Promise<string> {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
    let response: Response;
    try {
      response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body,
        signal: AbortSignal.timeout(45000),
      });
    } catch (error) {
      const raw = error instanceof Error ? error.message : String(error);
      const timedOut =
        (error instanceof Error && error.name === 'TimeoutError') ||
        raw.toLowerCase().includes('timeout') ||
        raw.toLowerCase().includes('aborted');
      throw new ServiceUnavailableException(
        timedOut
          ? 'පිළිතුර ලැබීමට වැඩි කාලයක් ගත විය. කරුණාකර නැවත උත්සාහ කරන්න.'
          : 'Gemini සම්බන්ධ කර ගත නොහැකි විය. කරුණාකර නැවත උත්සාහ කරන්න.',
      );
    }

    const json = (await response.json()) as Record<string, unknown>;
    if (!response.ok) {
      throw this.httpError(response.status, json);
    }
    return this.parseText(json);
  }

  private httpError(status: number, json: Record<string, unknown>): Error {
    const error = json.error as { message?: string } | undefined;
    if (status === 401 || status === 403) {
      return new ServiceUnavailableException(
        'Chat access was refused. The Gemini API key may be invalid.',
      );
    }
    if (status === 404) {
      return new ServiceUnavailableException(
        'The selected Gemini model is not available for this key.',
      );
    }
    if (status === 429 || this.shouldRetryModel(error?.message ?? '')) {
      return new ServiceUnavailableException(
        error?.message ?? 'Too many questions right now. Try again in a moment.',
      );
    }
    return new BadRequestException(
      error?.message ?? `AgriLink chat is unavailable right now (HTTP ${status}).`,
    );
  }

  private parseText(json: Record<string, unknown>): string {
    const feedback = json.promptFeedback as { blockReason?: string } | undefined;
    if (feedback?.blockReason) {
      throw new BadRequestException(
        'Please ask a general question about using AgriLink.',
      );
    }
    const candidates = json.candidates as Array<Record<string, unknown>> | undefined;
    const first = candidates?.[0];
    const finishReason = first?.finishReason?.toString();
    if (finishReason === 'SAFETY' || finishReason === 'BLOCKLIST') {
      throw new BadRequestException(
        'Please ask a general question about using AgriLink.',
      );
    }
    const content = first?.content as {
      parts?: Array<{ text?: string; thought?: boolean }>;
    } | undefined;
    const text = stripMeta(
      (content?.parts ?? [])
        .filter((part) => part.thought !== true)
        .map((part) => part.text ?? '')
        .join(''),
    );
    if (!text) {
      throw new ServiceUnavailableException(
        'පිළිතුරක් ලැබුණේ නැත. කරුණාකර ප්‍රශ්නය නැවත අසන්න.',
      );
    }
    return text;
  }

  private shouldRetryModel(message: string): boolean {
    const raw = message.toLowerCase();
    return (
      raw.includes('not available') ||
      raw.includes('404') ||
      raw.includes('high demand') ||
      raw.includes('try again later') ||
      raw.includes('overloaded') ||
      raw.includes('unavailable') ||
      raw.includes('timed out') ||
      raw.includes('could not reach') ||
      raw.includes('aborted') ||
      raw.includes('පිළිතුර ලැබීමට')
    );
  }
}

function stripMeta(raw: string): string {
  return raw
    .replaceAll('**', '')
    .replace(/^#{1,6}\s*/gm, '')
    .split('\n')
    .filter((line) => !isMetaLine(line))
    .join('\n')
    .trim();
}

function isMetaLine(line: string): boolean {
  const text = line.trim();
  return /^(\*\s*)?(let's|let us|i will|i'll|here's how i|here is how i)\b/i.test(text)
    || /\b(write it in|internal thought|reasoning:|draft:)\b/i.test(text);
}
