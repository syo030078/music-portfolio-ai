import Link from 'next/link';

interface Conversation {
  uuid: string;
  job_uuid: string | null;
  contract_uuid: string | null;
  created_at: string;
  updated_at: string;
  participants: Array<{
    uuid: string;
    name: string;
  }>;
  last_message: {
    uuid: string;
    content: string;
    sender_uuid: string;
    created_at: string;
  } | null;
  unread_count: number;
}

async function getConversations(): Promise<Conversation[]> {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
  const res = await fetch(`${apiUrl}/api/v1/conversations`, {
    cache: 'no-store',
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (!res.ok) {
    throw new Error('Failed to fetch conversations');
  }

  const data = await res.json();
  return data.conversations;
}

function formatDateTime(dateString: string): string {
  const date = new Date(dateString);
  const now = new Date();
  const diffInHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60));

  if (diffInHours < 1) {
    const diffInMinutes = Math.floor((now.getTime() - date.getTime()) / (1000 * 60));
    return `${diffInMinutes}分前`;
  }
  if (diffInHours < 24) {
    return `${diffInHours}時間前`;
  }
  if (diffInHours < 48) {
    return '昨日';
  }
  return date.toLocaleDateString('ja-JP', { month: 'short', day: 'numeric' });
}

export default async function MessagesPage() {
  const conversations = await getConversations();

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">メッセージ</h1>

      {conversations.length === 0 ? (
        <div className="text-center py-12">
          <p className="text-gray-500 mb-4">メッセージはまだありません</p>
          <Link
            href="/jobs"
            className="inline-block bg-blue-600 text-white py-2 px-6 rounded hover:bg-blue-700 transition-colors"
          >
            案件を探す
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          {conversations.map((conversation) => {
            const otherParticipants = conversation.participants;
            const participantNames = otherParticipants
              .map((p) => p.name)
              .join(', ');

            return (
              <Link
                key={conversation.uuid}
                href={`/messages/${conversation.uuid}`}
                className="block bg-white border border-gray-200 rounded-lg p-6 hover:shadow-lg transition-shadow"
              >
                <div className="flex justify-between items-start mb-2">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <h2 className="text-lg font-semibold">
                        {participantNames}
                      </h2>
                      {conversation.unread_count > 0 && (
                        <span className="bg-red-500 text-white text-xs font-bold px-2 py-1 rounded-full">
                          {conversation.unread_count}
                        </span>
                      )}
                    </div>
                    {conversation.job_uuid && (
                      <p className="text-sm text-gray-500">案件に関する会話</p>
                    )}
                  </div>
                  {conversation.last_message && (
                    <span className="text-sm text-gray-500">
                      {formatDateTime(conversation.last_message.created_at)}
                    </span>
                  )}
                </div>

                {conversation.last_message && (
                  <p className="text-gray-700 line-clamp-2">
                    {conversation.last_message.content}
                  </p>
                )}
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
