import { User } from '@prisma/client';

export type SafeUser = Omit<User, 'passwordHash'>;

export function toSafeUser(user: User): SafeUser {
  const { passwordHash: _, ...safe } = user;
  return safe;
}

export interface JwtPayload {
  sub: string;
  email: string;
  role: string;
}

export interface AuthRequest {
  user: SafeUser;
}
