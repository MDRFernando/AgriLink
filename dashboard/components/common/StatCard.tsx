import React from 'react';
import { LucideIcon, TrendingUp, TrendingDown } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  change?: {
    value: string;
    isPositive: boolean;
    label?: string;
  };
  icon: LucideIcon;
  badge?: string;
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'info';
}

export function StatCard({
  title,
  value,
  subtitle,
  change,
  icon: Icon,
  badge,
  variant = 'default',
}: StatCardProps) {
  const iconVariantStyles: Record<string, string> = {
    default: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/70 dark:text-emerald-300',
    success: 'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/70 dark:text-emerald-300',
    warning: 'bg-amber-50 text-amber-700 dark:bg-amber-950/70 dark:text-amber-300',
    danger: 'bg-rose-50 text-rose-700 dark:bg-rose-950/70 dark:text-rose-300',
    info: 'bg-sky-50 text-sky-700 dark:bg-sky-950/70 dark:text-sky-300',
  };

  return (
    <div className="relative overflow-hidden rounded-xl border border-zinc-200 bg-white p-5 shadow-xs transition-colors hover:border-zinc-300 dark:border-zinc-800 dark:bg-zinc-900 dark:hover:border-zinc-700">
      <div className="flex items-start justify-between">
        <div className="space-y-1">
          <p className="text-xs font-semibold tracking-wider text-zinc-500 uppercase dark:text-zinc-400">
            {title}
          </p>
          <div className="flex items-baseline gap-2">
            <h3 className="text-2xl font-bold tracking-tight text-zinc-900 dark:text-zinc-50">
              {value}
            </h3>
            {badge && (
              <span className="rounded-md bg-emerald-50 px-1.5 py-0.5 text-xs font-medium text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300">
                {badge}
              </span>
            )}
          </div>
        </div>
        <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${iconVariantStyles[variant] || iconVariantStyles.default}`}>
          <Icon className="h-5 w-5" />
        </div>
      </div>

      {(subtitle || change) && (
        <div className="mt-4 flex items-center gap-2 border-t border-zinc-100 pt-3 text-xs text-zinc-600 dark:border-zinc-800/80 dark:text-zinc-400">
          {change && (
            <span
              className={`inline-flex items-center gap-0.5 font-medium ${
                change.isPositive ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-400'
              }`}
            >
              {change.isPositive ? (
                <TrendingUp className="h-3.5 w-3.5" />
              ) : (
                <TrendingDown className="h-3.5 w-3.5" />
              )}
              {change.value}
            </span>
          )}
          <span>{change?.label || subtitle}</span>
        </div>
      )}
    </div>
  );
}
