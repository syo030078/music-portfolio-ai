'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

interface ContactButtonProps {
  jobUuid: string;
  clientUuid: string;
}

async function parseJsonSafe(res: Response): Promise<Record<string, unknown>> {
  const text = await res.text();
  try {
    return JSON.parse(text);
  } catch {
    throw new Error(text || `エラーが発生しました (${res.status})`);
  }
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

      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

      // 既存の会話を検索
      const conversationsRes = await fetch(`${apiUrl}/api/v1/conversations`, {
        cache: 'no-store',
        headers: {
          'Content-Type': 'application/json',
          Authorization: token,
        },
      });

      if (conversationsRes.status === 401) {
        setNeedsLogin(true);
        throw new Error('ログインセッションが切れました。再度ログインしてください');
      }

      if (!conversationsRes.ok) {
        throw new Error('会話一覧の取得に失敗しました');
      }

      const conversationsData = await parseJsonSafe(conversationsRes);
      const conversations = conversationsData.conversations as Array<{ job_uuid: string; uuid: string }>;

      // job_uuidが一致する会話を検索
      const existing = conversations.find((c) => c.job_uuid === jobUuid);

      if (existing) {
        router.push(`/messages/${existing.uuid}`);
      } else {
        const createRes = await fetch(`${apiUrl}/api/v1/conversations`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Authorization: token },
          body: JSON.stringify({
            conversation: { job_uuid: jobUuid },
            participant_uuids: [clientUuid]
          })
        });

        if (!createRes.ok) {
          const errorData = await parseJsonSafe(createRes);
          throw new Error((errorData.error as string) || '会話の作成に失敗しました');
        }

        const createData = await parseJsonSafe(createRes);
        const conversation = createData.conversation as { uuid: string };
        router.push(`/messages/${conversation.uuid}`);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : '不明なエラーが発生しました');
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
