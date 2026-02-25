'use client';

import { useState } from 'react';
import type { DirectRequest } from '@/types';
import { acceptDirectRequest, rejectDirectRequest } from '@/lib/api/directRequests';

interface DirectRequestCardProps {
  request: DirectRequest;
  isReceived: boolean;
  onAccepted: (requestUuid: string, conversationUuid: string) => void;
  onRejected: (uuid: string) => void;
}

const STATUS_LABELS: Record<DirectRequest['status'], { text: string; className: string }> = {
  pending: { text: '確認待ち', className: 'bg-yellow-100 text-yellow-800' },
  accepted: { text: '承諾済み', className: 'bg-green-100 text-green-800' },
  rejected: { text: '辞退済み', className: 'bg-gray-100 text-gray-600' },
};

export default function DirectRequestCard({
  request,
  isReceived,
  onAccepted,
  onRejected,
}: DirectRequestCardProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const statusInfo = STATUS_LABELS[request.status];

  const handleAccept = async () => {
    setLoading(true);
    setError(null);

    try {
      const token = localStorage.getItem('jwt');
      if (!token) {
        throw new Error('ログインしてください');
      }

      const data = await acceptDirectRequest(token, request.uuid);
      if (!data.conversation_uuid) {
        throw new Error('会話の作成に失敗しました。ページを再読み込みしてください');
      }
      onAccepted(request.uuid, data.conversation_uuid);
    } catch (err) {
      setError(err instanceof Error ? err.message : '承諾に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const handleReject = async () => {
    setLoading(true);
    setError(null);

    try {
      const token = localStorage.getItem('jwt');
      if (!token) {
        throw new Error('ログインしてください');
      }

      await rejectDirectRequest(token, request.uuid);
      onRejected(request.uuid);
    } catch (err) {
      setError(err instanceof Error ? err.message : '辞退に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-6">
      <div className="flex items-start justify-between mb-3">
        <h3 className="text-lg font-semibold text-gray-900">{request.title}</h3>
        <span className={`rounded-full px-3 py-1 text-xs font-medium ${statusInfo.className}`}>
          {statusInfo.text}
        </span>
      </div>

      <p className="text-gray-700 text-sm mb-4 whitespace-pre-wrap">{request.description}</p>

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div className="rounded-lg bg-gray-50 p-3">
          <p className="text-xs text-gray-500">予算</p>
          <p className="text-sm font-semibold text-gray-900">
            ¥{request.budget_jpy.toLocaleString()}
          </p>
        </div>
        <div className="rounded-lg bg-gray-50 p-3">
          <p className="text-xs text-gray-500">納期</p>
          <p className="text-sm font-semibold text-gray-900">
            {request.delivery_days}日
          </p>
        </div>
      </div>

      <div className="text-sm text-gray-500 mb-4">
        {isReceived ? (
          <p>依頼者: {request.client.name}</p>
        ) : (
          <p>音楽家: {request.musician.name}</p>
        )}
        <p className="text-xs mt-1">
          {new Date(request.created_at).toLocaleDateString('ja-JP')}
        </p>
      </div>

      {error && (
        <div className="rounded-lg bg-red-50 p-3 text-sm text-red-800 mb-3">
          {error}
        </div>
      )}

      {isReceived && request.status === 'pending' && (
        <div className="flex gap-3">
          <button
            onClick={handleAccept}
            disabled={loading}
            className="flex-1 rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-green-700 disabled:opacity-50"
          >
            {loading ? '処理中...' : '承諾する'}
          </button>
          <button
            onClick={handleReject}
            disabled={loading}
            className="flex-1 rounded-lg border border-gray-300 px-4 py-2 text-sm font-semibold text-gray-700 transition-colors hover:bg-gray-50 disabled:opacity-50"
          >
            {loading ? '処理中...' : '辞退する'}
          </button>
        </div>
      )}
    </div>
  );
}
