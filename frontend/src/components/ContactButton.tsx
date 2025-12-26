'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';

interface ContactButtonProps {
  jobId: number;
  clientId: number;
}

export default function ContactButton({ jobId, clientId }: ContactButtonProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  const handleClick = async () => {
    setLoading(true);

    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

      console.log('🔍 既存の会話を検索中...', { jobId, clientId });

      // 1. 既存の会話を検索
      const conversationsRes = await fetch(`${apiUrl}/api/v1/conversations`, {
        cache: 'no-store',
      });

      if (!conversationsRes.ok) {
        throw new Error(`会話一覧の取得に失敗: ${conversationsRes.status}`);
      }

      const { conversations } = await conversationsRes.json();
      console.log('📋 会話一覧を取得:', conversations);

      // job_idが一致する会話を検索
      const existing = conversations.find((c: any) => c.job_id === jobId);

      if (existing) {
        console.log('✅ 既存の会話が見つかりました:', existing.id);
        // 既存の会話に遷移
        router.push(`/messages/${existing.id}`);
      } else {
        console.log('➕ 新規会話を作成します...', { jobId, clientId });

        // 新規会話を作成
        const createRes = await fetch(`${apiUrl}/api/v1/conversations`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            conversation: { job_id: jobId },
            participant_ids: [clientId]
          })
        });

        if (!createRes.ok) {
          const errorData = await createRes.json();
          throw new Error(`会話の作成に失敗: ${JSON.stringify(errorData)}`);
        }

        const { conversation } = await createRes.json();
        console.log('✅ 会話を作成しました:', conversation.id);

        router.push(`/messages/${conversation.id}`);
      }
    } catch (error) {
      console.error('❌ エラーが発生しました:', error);
      alert(`メッセージの送信に失敗しました: ${error instanceof Error ? error.message : '不明なエラー'}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      onClick={handleClick}
      disabled={loading}
      className="w-full md:w-auto bg-green-600 text-white py-3 px-8 rounded-lg hover:bg-green-700 transition-colors font-semibold disabled:opacity-50 disabled:cursor-not-allowed"
    >
      {loading ? '処理中...' : 'メッセージを送る'}
    </button>
  );
}
