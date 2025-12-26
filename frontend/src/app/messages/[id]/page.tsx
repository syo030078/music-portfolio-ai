import Link from 'next/link';
import { notFound } from 'next/navigation';
import ChatBox from '@/components/ChatBox';

interface Message {
  id: number;
  sender_id: number;
  sender_name: string;
  content: string;
  created_at: string;
}

interface Conversation {
  id: number;
  job_id: number | null;
  contract_id: number | null;
  created_at: string;
  participants: Array<{
    id: number;
    name: string;
    bio: string | null;
  }>;
  messages: Message[];
}

async function getConversation(id: string): Promise<Conversation | null> {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
  const res = await fetch(`${apiUrl}/api/v1/conversations/${id}`, {
    cache: 'no-store',
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (!res.ok) {
    return null;
  }

  const data = await res.json();
  return data.conversation;
}

export default async function ConversationPage({
  params,
}: {
  params: { id: string };
}) {
  const conversation = await getConversation(params.id);

  if (!conversation) {
    notFound();
  }

  const participantNames = conversation.participants
    .map((p) => p.name)
    .join(', ');

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
          {conversation.job_id && (
            <p className="text-sm text-gray-500">案件に関する会話</p>
          )}
        </div>

        <div className="p-6">
          <div className="mb-6">
            <h2 className="text-lg font-semibold mb-3">参加者</h2>
            <div className="space-y-3">
              {conversation.participants.map((participant) => (
                <div key={participant.id} className="bg-gray-50 rounded-lg p-4">
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
            conversationId={conversation.id}
            initialMessages={conversation.messages}
          />
        </div>
      </div>
    </div>
  );
}
