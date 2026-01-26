'use client';

import { useState } from 'react';

interface Proposal {
  uuid: string;
  quote_total_jpy: number;
  delivery_days: number;
  cover_message: string | null;
  status: string;
  musician: {
    uuid: string;
    name: string;
  };
  created_at: string;
}

interface ProposalCardProps {
  proposal: Proposal;
  onAccepted: (conversationUuid: string) => void;
  onRejected: (proposalUuid: string) => void;
}

export default function ProposalCard({ proposal, onAccepted, onRejected }: ProposalCardProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleAction = async (action: 'accept' | 'reject') => {
    setLoading(true);
    setError(null);

    const token = localStorage.getItem('jwt');
    if (!token) {
      setError('ログインしてください');
      setLoading(false);
      return;
    }

    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
      const res = await fetch(`${apiUrl}/api/v1/proposals/${proposal.uuid}/${action}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: token,
        },
      });

      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || data.errors?.join(', ') || '操作に失敗しました');
      }

      const data = await res.json();
      if (action === 'accept') {
        onAccepted(data.conversation_uuid);
      } else {
        onRejected(proposal.uuid);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : '不明なエラーが発生しました');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white border border-gray-200 rounded-lg p-6 space-y-4">
      <div className="flex justify-between items-start">
        <div>
          <p className="text-lg font-semibold">{proposal.musician.name}</p>
          <p className="text-sm text-gray-500">
            応募日: {new Date(proposal.created_at).toLocaleDateString('ja-JP')}
          </p>
        </div>
        <span className="text-sm font-semibold text-gray-700">
          {proposal.status}
        </span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <p className="text-sm text-gray-500">見積金額</p>
          <p className="font-semibold">¥{proposal.quote_total_jpy.toLocaleString()}</p>
        </div>
        <div>
          <p className="text-sm text-gray-500">納期</p>
          <p className="font-semibold">{proposal.delivery_days}日</p>
        </div>
      </div>

      {proposal.cover_message && (
        <div className="bg-gray-50 rounded-md p-3 text-sm text-gray-700 whitespace-pre-wrap">
          {proposal.cover_message}
        </div>
      )}

      <div className="flex gap-3">
        <button
          onClick={() => handleAction('accept')}
          disabled={loading}
          className="rounded-md bg-green-600 px-4 py-2 text-white font-semibold hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          承諾する
        </button>
        <button
          onClick={() => handleAction('reject')}
          disabled={loading}
          className="rounded-md bg-gray-200 px-4 py-2 text-gray-800 font-semibold hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          拒否する
        </button>
      </div>

      {error && (
        <div className="rounded-lg bg-red-50 p-3 text-sm text-red-800">
          {error}
        </div>
      )}
    </div>
  );
}
