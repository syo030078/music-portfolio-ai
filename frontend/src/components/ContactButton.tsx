'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';

interface ContactButtonProps {
  jobUuid: string;
  clientUuid: string;
}

export default function ContactButton({ jobUuid, clientUuid }: ContactButtonProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleClick = async () => {
    setLoading(true);
    setError(null);

    try {
      const token = localStorage.getItem('jwt');
      if (!token) {
        throw new Error('ログインしてください');
      }

      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

      // 既存の会話を検索
      const conversationsRes = await fetch(`${apiUrl}/api/v1/conversations`, {
        cache: 'no-store',
        headers: {
          'Content-Type': 'application/json',
          Authorization: token,
        },
      });

      if (!conversationsRes.ok) {
        throw new Error('会話一覧の取得に失敗しました');
      }

      const { conversations } = await conversationsRes.json();

      // job_uuidが一致する会話を検索
      const existing = conversations.find((c: { job_uuid: string; uuid: string }) => c.job_uuid === jobUuid);

      if (existing) {
        // 既存の会話に遷移
        router.push(`/messages/${existing.uuid}`);
      } else {
        // 新規会話を作成（バックエンドは内部でjob_idに変換）
        const createRes = await fetch(`${apiUrl}/api/v1/conversations`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Authorization: token },
          body: JSON.stringify({
            conversation: { job_uuid: jobUuid },
            participant_uuids: [clientUuid]
          })
        });

        if (!createRes.ok) {
          const errorData = await createRes.json();
          throw new Error(errorData.error || '会話の作成に失敗しました');
        }

        const { conversation } = await createRes.json();
        router.push(`/messages/${conversation.uuid}`);
      }
    } catch (err) {
      console.error('ContactButton error:', err);
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
          {error}
        </div>
      )}
    </div>
  );
}
