'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { apiGet, apiPost } from '@/lib/api/client';

interface ContactButtonProps {
  jobUuid: string;
  clientUuid: string;
}

interface ConversationListResponse {
  conversations: Array<{ job_uuid: string; uuid: string }>;
}

interface ConversationCreateResponse {
  conversation: { uuid: string };
}

export default function ContactButton({ jobUuid, clientUuid }: ContactButtonProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [needsLogin, setNeedsLogin] = useState(false);

  const handleClick = async () => {
    setLoading(true);
    setError(null);
    setNeedsLogin(false);

    try {
      const token = localStorage.getItem('jwt');
      if (!token) {
        setNeedsLogin(true);
        throw new Error('ログインしてください');
      }

      // 既存の会話を検索
      const data = await apiGet<ConversationListResponse>('/api/v1/conversations', token);
      const existing = data.conversations.find((c) => c.job_uuid === jobUuid);

      if (existing) {
        router.push(`/messages/${existing.uuid}`);
      } else {
        const createData = await apiPost<ConversationCreateResponse>(
          '/api/v1/conversations',
          token,
          { conversation: { job_uuid: jobUuid }, participant_uuids: [clientUuid] }
        );
        router.push(`/messages/${createData.conversation.uuid}`);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : '不明なエラーが発生しました';
      if (message.includes('ログイン')) {
        setNeedsLogin(true);
      }
      setError(message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-3">
      <button
        onClick={handleClick}
        disabled={loading}
        className="w-full rounded-lg bg-green-600 px-8 py-3 font-semibold text-white transition-colors hover:bg-green-700 disabled:cursor-not-allowed disabled:opacity-50 md:w-auto"
      >
        {loading ? '処理中...' : 'メッセージを送る'}
      </button>

      {error && (
        <div className="rounded-lg bg-red-50 p-3 text-sm text-red-800">
          <p>{error}</p>
          {needsLogin && (
            <Link href="/login" className="mt-1 inline-block text-red-600 underline hover:text-red-800">
              ログインページへ
            </Link>
          )}
        </div>
      )}
    </div>
  );
}
