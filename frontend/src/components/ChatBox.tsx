'use client';

import Link from 'next/link';
import { useState, useRef, useEffect } from 'react';
import { useChat } from '@/hooks/useChat';
import { useUser } from '@/hooks/useUser';

interface ChatBoxProps {
  conversationUuid: string;
}

export default function ChatBox({ conversationUuid }: ChatBoxProps) {
  const { user } = useUser();
  const token =
    typeof window !== 'undefined' ? localStorage.getItem('jwt') : null;

  const {
    messages,
    loading,
    error,
    isSending,
    sendError,
    sendMessage,
    loadOlderMessages,
    hasMore,
  } = useChat(conversationUuid, token, user?.uuid ?? null);

  const [newMessage, setNewMessage] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const isInitialLoadRef = useRef(true);
  const isLoadingOlderRef = useRef(false);

  // 初回・新メッセージ時に自動スクロール
  useEffect(() => {
    if (isInitialLoadRef.current && !loading && messages.length > 0) {
      messagesEndRef.current?.scrollIntoView();
      isInitialLoadRef.current = false;
      return;
    }
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  // スクロール上端で過去メッセージ読み込み（デバウンス付き）
  useEffect(() => {
    const container = containerRef.current;
    if (!container || !hasMore) return;

    async function handleScroll() {
      if (container!.scrollTop === 0 && !isLoadingOlderRef.current) {
        isLoadingOlderRef.current = true;
        await loadOlderMessages();
        isLoadingOlderRef.current = false;
      }
    }

    container.addEventListener('scroll', handleScroll);
    return () => container.removeEventListener('scroll', handleScroll);
  }, [hasMore, loadOlderMessages]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newMessage.trim() || isSending) return;

    await sendMessage(newMessage);
    setNewMessage('');
  };

  const needsLogin = sendError?.includes('ログイン');

  if (loading) {
    return (
      <div className="flex items-center justify-center h-[400px] md:h-[600px]">
        <p className="text-gray-500">メッセージを読み込み中...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-[400px] md:h-[600px]">
        <p className="text-red-600">{error}</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-[400px] md:h-[600px]">
      <div
        ref={containerRef}
        className="flex-1 overflow-y-auto border border-gray-200 rounded-lg p-4 mb-4 bg-gray-50"
      >
        {hasMore && (
          <button
            type="button"
            onClick={loadOlderMessages}
            className="w-full text-center text-sm text-gray-500 hover:text-gray-700 py-2 mb-2"
          >
            過去のメッセージを読み込む
          </button>
        )}

        {messages.length === 0 ? (
          <p className="text-gray-500 text-center py-8">
            メッセージはまだありません
          </p>
        ) : (
          <div className="space-y-4">
            {messages.map((message) => (
              <div
                key={message.uuid}
                className={`flex flex-col ${message._pending ? 'opacity-60' : ''}`}
              >
                <div className="flex items-baseline gap-2 mb-1">
                  <span className="font-semibold text-sm">
                    {message.sender_name || 'あなた'}
                  </span>
                  <span className="text-xs text-gray-500">
                    {formatTime(message.created_at)}
                  </span>
                </div>
                <div className="bg-white rounded-lg p-3 shadow-sm">
                  <p className="text-gray-800 whitespace-pre-wrap">
                    {message.content}
                  </p>
                </div>
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>
        )}
      </div>

      {sendError && (
        <div className="rounded-lg bg-red-50 p-2 text-sm text-red-800 mb-2">
          <p>{sendError}</p>
          {needsLogin && (
            <Link
              href="/login"
              className="mt-1 inline-block text-red-600 underline hover:text-red-800"
            >
              ログインページへ
            </Link>
          )}
        </div>
      )}

      <form onSubmit={handleSubmit} className="flex gap-2">
        <input
          type="text"
          value={newMessage}
          onChange={(e) => setNewMessage(e.target.value)}
          placeholder="メッセージを入力..."
          className="flex-1 border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
          disabled={isSending}
        />
        <button
          type="submit"
          disabled={isSending || !newMessage.trim()}
          className="bg-green-600 text-white px-6 py-2 rounded-lg hover:bg-green-700 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed"
        >
          {isSending ? '送信中...' : '送信'}
        </button>
      </form>
    </div>
  );
}

function formatTime(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleString('ja-JP', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}
