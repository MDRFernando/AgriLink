import React from 'react';
import { QualityGrade, ProductionStatus, OrderStatus, TransportStatus } from '@/lib/types';

interface BadgeProps {
  children: React.ReactNode;
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'info' | 'neutral' | 'gradeA' | 'gradeB' | 'gradeC';
  className?: string;
  size?: 'sm' | 'md';
}

export function Badge({ children, variant = 'default', className = '', size = 'sm' }: BadgeProps) {
  const sizeClasses = size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-sm font-medium';

  const variantStyles: Record<string, string> = {
    default: 'bg-emerald-50 text-emerald-800 border-emerald-200 dark:bg-emerald-950/50 dark:text-emerald-300 dark:border-emerald-800/60',
    success: 'bg-emerald-50 text-emerald-800 border-emerald-200 dark:bg-emerald-950/50 dark:text-emerald-300 dark:border-emerald-800/60',
    warning: 'bg-amber-50 text-amber-800 border-amber-200 dark:bg-amber-950/50 dark:text-amber-300 dark:border-amber-800/60',
    danger: 'bg-rose-50 text-rose-800 border-rose-200 dark:bg-rose-950/50 dark:text-rose-300 dark:border-rose-800/60',
    info: 'bg-sky-50 text-sky-800 border-sky-200 dark:bg-sky-950/50 dark:text-sky-300 dark:border-sky-800/60',
    neutral: 'bg-zinc-100 text-zinc-700 border-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:border-zinc-700',
    gradeA: 'bg-emerald-100 text-emerald-900 border-emerald-300 font-semibold dark:bg-emerald-900/60 dark:text-emerald-200 dark:border-emerald-700',
    gradeB: 'bg-blue-100 text-blue-900 border-blue-300 font-semibold dark:bg-blue-900/60 dark:text-blue-200 dark:border-blue-700',
    gradeC: 'bg-amber-100 text-amber-900 border-amber-300 font-semibold dark:bg-amber-900/60 dark:text-amber-200 dark:border-amber-700',
  };

  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full border ${variantStyles[variant] || variantStyles.default} ${sizeClasses} ${className}`}
    >
      {children}
    </span>
  );
}

export function GradeBadge({ grade }: { grade: QualityGrade }) {
  if (grade === 'A') {
    return <Badge variant="gradeA">Grade A (Premium)</Badge>;
  }
  if (grade === 'B') {
    return <Badge variant="gradeB">Grade B (Standard)</Badge>;
  }
  return <Badge variant="gradeC">Grade C (Processing)</Badge>;
}

export function StatusBadge({ status }: { status: ProductionStatus | OrderStatus | TransportStatus | string }) {
  switch (status) {
    case 'available':
    case 'completed':
    case 'delivered':
    case 'settled':
    case 'sandbox_paid':
    case 'paid':
    case 'approved':
      return <Badge variant="success">{formatStatusLabel(status)}</Badge>;

    case 'growing':
    case 'in_transit':
    case 'loaded':
    case 'assigned':
    case 'cultivating':
    case 'open':
      return <Badge variant="info">{formatStatusLabel(status)}</Badge>;

    case 'planned':
    case 'readyForHarvest':
    case 'pending':
    case 'pending_farmer':
    case 'pending_buyer':
    case 'requested':
    case 'arrived_at_pickup':
    case 'payment_pending':
      return <Badge variant="warning">{formatStatusLabel(status)}</Badge>;

    case 'disputed':
    case 'cancelled':
    case 'expired':
    case 'rejected':
      return <Badge variant="danger">{formatStatusLabel(status)}</Badge>;

    default:
      return <Badge variant="neutral">{formatStatusLabel(status)}</Badge>;
  }
}

function formatStatusLabel(str: string): string {
  return str
    .replace(/_/g, ' ')
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .split(' ')
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}
