'use client';

import Link from 'next/link';
import { useState } from 'react';

interface ProposalFormProps {
  jobUuid: string;
}

function isAuthError(status: number, message: string): boolean {
  return status === 401 || message.toLowerCase().includes('signature has expired');
}

export default function ProposalForm({ jobUuid }: ProposalFormProps) {
  const [quoteTotalJpy, setQuoteTotalJpy] = useState('');
  const [deliveryDays, setDeliveryDays] = useState('');
  const [coverMessage, setCoverMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [needsLogin, setNeedsLogin] = useState(false);
  const [success, setSuccess] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setNeedsLogin(false);

    const token = localStorage.getItem('jwt');
    if (!token) {
      setNeedsLogin(true);
      setError('ログインしてください');
      return;
    }

    setLoading(true);
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';
      const res = await fetch(`${apiUrl}/api/v1/jobs/${jobUuid}/proposals`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: token,
        },
        body: JSON.stringify({
          proposal: {
            quote_total_jpy: Number(quoteTotalJpy),
            delivery_days: Number(deliveryDays),
            cover_message: coverMessage,
          },
        }),
      });

      if (!res.ok) {
        const text = await res.text();
        let message = `応募に失敗しました (${res.status})`;
        try {
          const data = JSON.parse(text);
          message = data.error || data.errors?.join(', ') || message;
        } catch {
          if (text) message = text;
        }

        if (isAuthError(res.status, message)) {
          setNeedsLogin(true);
          throw new Error('ログインセッションが切れました。再度ログインしてください');
        }
        throw new Error(message);
      }

      setSuccess('応募が完了しました');
      setQuoteTotalJpy('');
      setDeliveryDays('');
      setCoverMessage('');
    } catch (err) {
      setError(err instanceof Error ? err.message : '不明なエラーが発生しました');
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="bg-white border border-gray-200 rounded-lg p-6">
        <div className="rounded-lg bg-green-50 p-4 text-green-800">
          <p className="font-medium">応募が完了しました</p>
          <p className="text-sm mt-1">クライアントからの返答をお待ちください</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white border border-gray-200 rounded-lg p-6">
      <h2 className="text-lg font-semibold mb-4">応募する</h2>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            見積金額（円）
          </label>
          <input
            type="number"
            min="1"
            required
            value={quoteTotalJpy}
            onChange={(e) => setQuoteTotalJpy(e.target.value)}
            className="w-full rounded-md border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            disabled={loading}
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            納期（日数）
          </label>
          <input
            type="number"
            min="1"
            required
            value={deliveryDays}
            onChange={(e) => setDeliveryDays(e.target.value)}
            className="w-full rounded-md border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            disabled={loading}
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            カバーメッセージ
          </label>
          <textarea
            value={coverMessage}
            onChange={(e) => setCoverMessage(e.target.value)}
            className="w-full rounded-md border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-green-500"
            rows={4}
            disabled={loading}
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          className="rounded-lg bg-green-600 px-6 py-2 font-semibold text-white transition-colors hover:bg-green-700 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {loading ? '送信中...' : '応募を送信'}
        </button>
      </form>

      {error && (
        <div className="mt-4 rounded-lg bg-red-50 p-3 text-sm text-red-800">
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
