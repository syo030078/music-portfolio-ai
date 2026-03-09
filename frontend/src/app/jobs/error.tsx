'use client';

import ErrorWithRetry from '@/components/ui/ErrorWithRetry';

export default function JobsError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="mx-auto max-w-7xl px-4 py-8">
      <ErrorWithRetry
        message={error.message || '案件データの取得に失敗しました'}
        onRetry={reset}
      />
    </div>
  );
}
