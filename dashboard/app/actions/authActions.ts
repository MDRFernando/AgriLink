'use server';

import { compare } from 'bcryptjs';
import { redirect } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { prisma } from '@/lib/db';
import { signSession, setSessionCookie, destroySession, getSession } from '@/lib/auth';

export async function loginAction(formData: FormData | { email: string; password: string }) {
  let email = '';
  let password = '';

  if (formData instanceof FormData) {
    email = (formData.get('email') as string) || '';
    password = (formData.get('password') as string) || '';
  } else {
    email = formData.email || '';
    password = formData.password || '';
  }

  email = email.trim().toLowerCase();

  if (!email || !password) {
    return { success: false, error: 'Email and password are required' };
  }

  try {
    const user = await prisma.user.findUnique({
      where: { email },
      include: {
        farmerProfile: true,
        buyerProfile: true,
        transporterProfile: true,
      },
    });

    if (!user) {
      return { success: false, error: 'Invalid credentials. User not found.' };
    }

    const isMatch = await compare(password, user.passwordHash);
    if (!isMatch) {
      return { success: false, error: 'Invalid credentials. Incorrect password.' };
    }

    const token = await signSession({
      sub: user.id,
      email: user.email,
      role: user.role,
      name: user.name,
    });

    await setSessionCookie(token);
    revalidatePath('/', 'layout');

    return {
      success: true,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        organizationName: user.organizationName,
        district: user.district,
        isVerified: user.isVerified,
      },
    };
  } catch (error: any) {
    console.error('Login action error:', error);
    return { success: false, error: error?.message || 'Login failed. Please try again.' };
  }
}

export async function logoutAction() {
  await destroySession();
  revalidatePath('/', 'layout');
  redirect('/login');
}

export async function getCurrentUserAction() {
  const sessionData = await getSession();
  return sessionData?.user ?? null;
}
