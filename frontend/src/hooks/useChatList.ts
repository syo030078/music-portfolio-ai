'use client';

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import type { Conversation } from '@/types/conversation';
import { fetchConversations } from '@/lib/api/conversations';

const POLL_INTERVAL_MS = 10000;

interface UseChatListResult {
  readonly conversations: readonly Conversation[];
  readonly loading: boolean;
  readonly error: string | null;
  readonly retry: () => void;
  readonly totalUnread: number;
}

export function useChatList(token: string | null): UseChatListResult {
  const [conversations, setConversations] = useState<readonly Conversation[]>(
    []
  );
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const isPollingRef = useRef(false);

  const load = useCallback(
    async (isInitial: boolean) => {
      if (!token) return;

      try {
        if (isInitial) {
          setLoading(true);
          setError(null);
        }

        const data = await fetchConversations(token);
        setConversations(data);
        if (isInitial) setError(null);
      } catch (err) {
        if (isInitial) {
          setError(
            err instanceof Error
              ? err.message
              : '会話一覧の取得に失敗しました'
          );
        }
        // ポーリング中のエラーはサイレント
      } finally {
        if (isInitial) setLoading(false);
      }
    },
    [token]
  );

  // 初回読み込み
  useEffect(() => {
    load(true);
  }, [load]);

  // ポーリング
  useEffect(() => {
    if (!token || loading) return;

    const intervalId = setInterval(async () => {
      if (isPollingRef.current || document.hidden) return;
      isPollingRef.current = true;
      try {
        await load(false);
      } finally {
        isPollingRef.current = false;
      }
    }, POLL_INTERVAL_MS);

    return () => clearInterval(intervalId);
  }, [token, loading, load]);

  const retry = useCallback(() => {
    load(true);
  }, [load]);

  const totalUnread = useMemo(
    () => conversations.reduce((sum, c) => sum + (c.unread_count ?? 0), 0),
    [conversations]
  );

  return { conversations, loading, error, retry, totalUnread };
}
