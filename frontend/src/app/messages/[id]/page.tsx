'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import ChatBox from '@/components/ChatBox';

interface Message {
  uuid: string;
  sender_uuid: string;
  sender_name: string;
  content: string;
  created_at: string;
}

interface Conversation {
  uuid: string;
  job_uuid: string | null;
  contract_uuid: string | null;
  created_at: string;
  participants: Array<{
    uuid: string;
    name: string;
    bio: string | null;
  }>;
  messages: Message[];
}

export default function ConversationPage({
  params,
}: {
  params: { id: string };
}) {
  const [conversation, setConversation] = useState<Conversation | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchConversation = async () => {
      setError(null);
      const token = localStorage.getItem('jwt');
      if (!token) {
        setError('ログインしてください');
        setLoading(false);
        return;
      }

      try {
        const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
        const res = await fetch(`${apiUrl}/api/v1/conversations/${params.id}`, {
          cache: 'no-store',
          headers: {
            'Content-Type': 'application/json',
            Authorization: token,
          },
        });

        if (!res.ok) {
          throw new Error('会話の取得に失敗しました');
        }

        const data = await res.json();
        setConversation(data.conversation || null);
      } catch (err) {
        setError(err instanceof Error ? err.message : '不明なエラーが発生しました');
      } finally {
        setLoading(false);
      }
    };

    fetchConversation();
  }, [params.id]);

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <p className="text-gray-500">読み込み中...</p>
      </div>
    );
  }

  if (error || !conversation) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="rounded-lg bg-red-50 p-4 text-red-800">
          {error || '会話が見つかりません'}
        </div>
      </div>
    );
  }

  const participantNames = conversation.participants.map((p) => p.name).join(', ');

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
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
                <div key={participant.uuid} className="bg-gray-50 rounded-lg p-4">
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

          <ChatBox
            conversationUuid={conversation.uuid}
            initialMessages={conversation.messages}
          />
        </div>
      </div>
    </div>
  );
}
