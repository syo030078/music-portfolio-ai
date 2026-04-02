'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import type { Message } from '@/types/conversation';
import {
  fetchMessages,
  sendMessage as apiSendMessage,
} from '@/lib/api/conversations';

const POLL_INTERVAL_MS = 5000;

type PendingMessage = Message & { readonly _pending?: true };

interface UseChatResult {
  readonly messages: readonly PendingMessage[];
  readonly loading: boolean;
  readonly error: string | null;
  readonly isSending: boolean;
  readonly sendError: string | null;
  readonly sendMessage: (content: string) => Promise<void>;
  readonly loadOlderMessages: () => Promise<void>;
  readonly hasMore: boolean;
}

export function useChat(
  conversationUuid: string,
  token: string | null,
  currentUserUuid: string | null
): UseChatResult {
  const [messages, setMessages] = useState<readonly PendingMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isSending, setIsSending] = useState(false);
  const [sendError, setSendError] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const lastMessageTimeRef = useRef<string | null>(null);
  const oldestUuidRef = useRef<string | null>(null);
  const isPollingRef = useRef(false);

  // oldestUuidRef を messages 変更時に更新（stale closure回避）
  useEffect(() => {
    const first = messages[0];
    oldestUuidRef.current =
      first && !first.uuid.startsWith('pending-') ? first.uuid : null;
  }, [messages]);

  // 初回メッセージ読み込み
  useEffect(() => {
    if (!token || !conversationUuid) return;

    let cancelled = false;

    async function loadInitial() {
      try {
        setLoading(true);
        setError(null);
        const data = await fetchMessages(token!, conversationUuid, {
          limit: 50,
        });
        if (cancelled) return;

        setMessages(data.messages);
        setHasMore(data.meta.has_more);

        const lastMsg = data.messages[data.messages.length - 1];
        if (lastMsg) {
          lastMessageTimeRef.current = lastMsg.created_at;
        }
      } catch (err) {
        if (cancelled) return;
        setError(
          err instanceof Error ? err.message : 'メッセージの取得に失敗しました'
        );
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    loadInitial();
    return () => {
      cancelled = true;
    };
  }, [token, conversationUuid]);

  // ポーリング: 新着メッセージ取得（タブ非表示時は停止）
  useEffect(() => {
    if (!token || !conversationUuid || loading) return;

    const intervalId = setInterval(async () => {
      if (isPollingRef.current || document.hidden) return;
      isPollingRef.current = true;

      try {
        const since = lastMessageTimeRef.current;
        if (!since) return;

        const data = await fetchMessages(token, conversationUuid, { since });

        if (data.messages.length > 0) {
          setMessages((prev) => {
            const existingUuids = new Set(prev.map((m) => m.uuid));
            const newMessages = data.messages.filter(
              (m) => !existingUuids.has(m.uuid)
            );
            if (newMessages.length === 0) return prev;

            // 楽観的メッセージ（_pending）を確定メッセージで置き換え
            const withoutPending = prev.filter((m) => !m._pending);
            return [...withoutPending, ...newMessages];
          });

          const lastNew = data.messages[data.messages.length - 1];
          if (lastNew) {
            lastMessageTimeRef.current = lastNew.created_at;
          }
        }
      } catch {
        // ポーリングエラーはサイレントに無視（UIを壊さない）
      } finally {
        isPollingRef.current = false;
      }
    }, POLL_INTERVAL_MS);

    return () => clearInterval(intervalId);
  }, [token, conversationUuid, loading]);

  // メッセージ送信（楽観的更新）
  const sendMessage = useCallback(
    async (content: string) => {
      const trimmed = content.trim();
      if (!trimmed || !token || !currentUserUuid) return;

      setSendError(null);
      setIsSending(true);

      // 楽観的にUIに追加
      const optimisticUuid = `pending-${Date.now()}`;
      const optimistic: PendingMessage = {
        uuid: optimisticUuid,
        sender_uuid: currentUserUuid,
        sender_name: '',
        content: trimmed,
        created_at: new Date().toISOString(),
        _pending: true,
      };
      setMessages((prev) => [...prev, optimistic]);

      try {
        const confirmed = await apiSendMessage(
          token,
          conversationUuid,
          trimmed
        );

        // 楽観的メッセージを確定メッセージに差し替え
        setMessages((prev) =>
          prev.map((m) => (m.uuid === optimisticUuid ? confirmed : m))
        );
        lastMessageTimeRef.current = confirmed.created_at;
      } catch (err) {
        // 送信失敗: 楽観的メッセージを除去
        setMessages((prev) => prev.filter((m) => m.uuid !== optimisticUuid));
        setSendError(
          err instanceof Error ? err.message : 'メッセージの送信に失敗しました'
        );
      } finally {
        setIsSending(false);
      }
    },
    [token, conversationUuid, currentUserUuid]
  );

  // 過去メッセージ読み込み（refで stale closure 回避）
  const loadOlderMessages = useCallback(async () => {
    if (!token || !hasMore || !oldestUuidRef.current) return;

    try {
      const data = await fetchMessages(token, conversationUuid, {
        before: oldestUuidRef.current,
        limit: 50,
      });

      setMessages((prev) => [...data.messages, ...prev]);
      setHasMore(data.meta.has_more);
    } catch {
      // 過去メッセージ取得エラーはサイレント
    }
  }, [token, conversationUuid, hasMore]);

  return {
    messages,
    loading,
    error,
    isSending,
    sendError,
    sendMessage,
    loadOlderMessages,
    hasMore,
  };
}
