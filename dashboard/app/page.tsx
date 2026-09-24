import { redirect } from 'next/navigation';
import { getSession } from '@/lib/auth';
import { DashboardClient } from '@/components/DashboardClient';
import { UserRole } from '@/lib/types';

export const dynamic = 'force-dynamic';

export default async function Page() {
  const sessionData = await getSession();

  if (!sessionData?.user) {
    redirect('/login');
  }

  const { user } = sessionData;

  let initialRole: UserRole = 'government';
  if (user.role === 'farmer') {
    initialRole = 'farmer';
  } else if (user.role === 'business') {
    initialRole = 'buyer';
  } else if (user.role === 'transporter') {
    initialRole = 'transporter';
  } else if (user.role === 'government' || (user.role as any) === 'admin') {
    initialRole = 'government';
  }

  return (
    <DashboardClient
      initialUser={{
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        organizationName: user.organizationName,
        district: user.district,
        isVerified: user.isVerified,
      }}
      initialRole={initialRole}
    />
  );
}
