'use client';

import Link from 'next/link';
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

const STATUS_LABELS: Record<string, { label: string; color: string }> = {
  submitted: { label: '審査中', color: 'bg-yellow-100 text-yellow-800' },
  shortlisted: { label: '候補', color: 'bg-blue-100 text-blue-800' },
  accepted: { label: '承諾済み', color: 'bg-green-100 text-green-800' },
  rejected: { label: '不採用', color: 'bg-red-100 text-red-800' },
  withdrawn: { label: '取り下げ', color: 'bg-gray-100 text-gray-800' },
};

export default function ProposalCard({ proposal, onAccepted, onRejected }: ProposalCardProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [needsLogin, setNeedsLogin] = useState(false);
  const isPending = proposal.status === 'submitted' || proposal.status === 'shortlisted';
  const statusInfo = STATUS_LABELS[proposal.status] ?? { label: proposal.status, color: 'bg-gray-100 text-gray-800' };

  const handleAction = async (action: 'accept' | 'reject') => {
    setLoading(true);
    setError(null);
    setNeedsLogin(false);

    const token = localStorage.getItem('jwt');
    if (!token) {
      setNeedsLogin(true);
      setError('ログインしてください');
      setLoading(false);
      return;
    }

    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || '';
      const res = await fetch(`${apiUrl}/api/v1/proposals/${proposal.uuid}/${action}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: token,
        },
      });

      if (!res.ok) {
        const data = await res.json();
        const message = data.error || data.errors?.join(', ') || '操作に失敗しました';
        if (res.status === 401 || message.toLowerCase().includes('signature has expired')) {
          setNeedsLogin(true);
          throw new Error('ログインセッションが切れました。再度ログインしてください');
        }
        throw new Error(message);
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
        <span className={`text-xs font-semibold px-2 py-1 rounded-full ${statusInfo.color}`}>
          {statusInfo.label}
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

      {isPending && (
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
      )}

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
