'use client';

import Link from 'next/link';
import { useState } from 'react';

interface ProposalFormProps {
  jobUuid: string;
}

export default function ProposalForm({ jobUuid }: ProposalFormProps) {
  const [quoteTotalJpy, setQuoteTotalJpy] = useState('');
  const [deliveryDays, setDeliveryDays] = useState('');
  const [coverMessage, setCoverMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    const token = localStorage.getItem('jwt');
    if (!token) {
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
        if (res.status === 401) {
          throw new Error('ログインが必要です。ログインしてから再度お試しください。');
        }
        const text = await res.text();
        try {
          const data = JSON.parse(text);
          throw new Error(data.error || data.errors?.join(', ') || '応募に失敗しました');
        } catch (parseErr) {
          if (parseErr instanceof SyntaxError) {
            throw new Error('応募に失敗しました。ログイン状態を確認してください。');
          }
          throw parseErr;
        }
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
            className="w-full rounded-md border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
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
            className="w-full rounded-md border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
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
            className="w-full rounded-md border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
            rows={4}
            disabled={loading}
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          className="rounded-lg bg-blue-600 px-6 py-2 font-semibold text-white transition-colors hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {loading ? '送信中...' : '応募を送信'}
        </button>
      </form>

      {error && (
        <div className="mt-4 rounded-lg bg-red-50 p-3 text-sm text-red-800">
          <p>{error}</p>
          {error.includes('ログイン') && (
            <Link href="/login" className="mt-1 inline-block text-red-600 underline hover:text-red-800">
              ログインページへ
            </Link>
          )}
        </div>
      )}
      {success && (
        <div className="mt-4 rounded-lg bg-green-50 p-3 text-sm text-green-800">
          {success}
        </div>
      )}
    </div>
  );
}
