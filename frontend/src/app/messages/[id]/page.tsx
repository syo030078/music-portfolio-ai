'use client';

import Link from 'next/link';
import { use } from 'react';
import ChatBox from '@/components/ChatBox';
import AuthGuard from '@/components/AuthGuard';
import { useAsyncData } from '@/hooks/useAsyncData';
import { fetchConversation } from '@/lib/api/conversations';
import type { Conversation } from '@/types/conversation';

export default function ConversationPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);

  const { data: conversation, loading, error } = useAsyncData<Conversation>(
    () => {
      const token = localStorage.getItem('jwt');
      if (!token) throw new Error('ログインが必要です');
      return fetchConversation(token, id);
    },
    [id]
  );

  if (loading) {
    return (
      <div className="mx-auto max-w-4xl px-4 py-8">
        <p className="text-gray-500">読み込み中...</p>
      </div>
    );
  }

  if (error || !conversation) {
    return (
      <div className="mx-auto max-w-4xl px-4 py-8">
        <div className="rounded-lg bg-red-50 p-4 text-red-800">
          {error || '会話が見つかりません'}
        </div>
      </div>
    );
  }

  const participantNames = conversation.participants
    .map((p) => p.name)
    .join(', ');

  return (
    <AuthGuard>
      <div className="mx-auto max-w-4xl px-4 py-8">
        <div className="mb-6">
          <Link href="/messages" className="text-blue-600 hover:underline">
            ← メッセージ一覧に戻る
          </Link>
        </div>

        <div className="bg-white border border-gray-200 rounded-lg">
          <div className="border-b border-gray-200 p-6">
            <h1 className="text-2xl font-bold mb-2">{participantNames}</h1>
            {conversation.job_uuid && (
              <p className="text-sm text-gray-500">案件に関する会話</p>
            )}
          </div>

          <div className="p-6">
            <div className="mb-6">
              <h2 className="text-lg font-semibold mb-3">参加者</h2>
              <div className="space-y-3">
                {conversation.participants.map((participant) => (
                  <div
                    key={participant.uuid}
                    className="bg-gray-50 rounded-lg p-4"
                  >
                    <p className="font-medium">{participant.name}</p>
                    {participant.bio && (
                      <p className="text-sm text-gray-600 mt-1">
                        {participant.bio}
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </div>

            <ChatBox conversationUuid={conversation.uuid} />
          </div>
        </div>
      </div>
    </AuthGuard>
  );
}
