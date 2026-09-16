import React from 'react';
import { SearchX, RotateCcw } from 'lucide-react';

interface EmptyStateProps {
  title?: string;
  description?: string;
  onReset?: () => void;
  resetText?: string;
}

export function EmptyState({
  title = 'No records found',
  description = 'No matching items found for your current search criteria.',
  onReset,
  resetText = 'Clear filters'
}: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center rounded-xl border border-dashed border-zinc-200 bg-white/50 p-8 text-center dark:border-zinc-800 dark:bg-zinc-900/30">
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-zinc-100 text-zinc-500 dark:bg-zinc-800 dark:text-zinc-400">
        <SearchX className="h-6 w-6" />
      </div>
      <h4 className="mt-3 text-sm font-semibold text-zinc-900 dark:text-zinc-100">
        {title}
      </h4>
      <p className="mt-1 max-w-sm text-xs text-zinc-500 dark:text-zinc-400">
        {description}
      </p>
      {onReset && (
        <button
          type="button"
          onClick={onReset}
          className="mt-4 inline-flex items-center gap-1.5 rounded-lg border border-zinc-200 bg-white px-3 py-1.5 text-xs font-medium text-zinc-700 shadow-2xs hover:bg-zinc-50 dark:border-zinc-700 dark:bg-zinc-800 dark:text-zinc-200 dark:hover:bg-zinc-700"
        >
          <RotateCcw className="h-3.5 w-3.5" />
          {resetText}
        </button>
      )}
    </div>
  );
}
