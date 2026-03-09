import { useState, useEffect, useCallback } from 'react';

interface AsyncDataState<T> {
  readonly data: T | null;
  readonly loading: boolean;
  readonly error: string | null;
  readonly retry: () => void;
}

export function useAsyncData<T>(
  fetcher: () => Promise<T>,
  deps: readonly unknown[] = []
): AsyncDataState<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [retryCount, setRetryCount] = useState(0);

  const retry = useCallback(() => {
    setRetryCount((prev) => prev + 1);
  }, []);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);

    fetcher()
      .then((result) => {
        if (!cancelled) {
          setData(result);
        }
      })
      .catch((err) => {
        if (!cancelled) {
          setError(
            err instanceof Error ? err.message : 'データの取得に失敗しました'
          );
        }
      })
      .finally(() => {
        if (!cancelled) {
          setLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [retryCount, ...deps]);

  return { data, loading, error, retry };
}
