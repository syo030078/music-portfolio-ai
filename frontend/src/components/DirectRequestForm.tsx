'use client';

import Link from 'next/link';
import { useState } from 'react';
import { z } from 'zod';
import { createDirectRequest } from '@/lib/api/directRequests';

const directRequestSchema = z.object({
  title: z.string().min(1, 'タイトルを入力してください').max(100, '100文字以内で入力してください'),
  description: z.string().min(10, '10文字以上で入力してください'),
  budget_jpy: z.number().int().min(1000, '1000円以上を入力してください'),
  delivery_days: z.number().int().min(1, '1日以上を入力してください').max(365, '365日以内で入力してください'),
});

interface DirectRequestFormProps {
  musicianUuid: string;
  musicianName: string;
}

export default function DirectRequestForm({ musicianUuid, musicianName }: DirectRequestFormProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [budgetJpy, setBudgetJpy] = useState('');
  const [deliveryDays, setDeliveryDays] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [needsLogin, setNeedsLogin] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(false);
    setNeedsLogin(false);

    try {
      const token = localStorage.getItem('jwt');
      if (!token) {
        setNeedsLogin(true);
        throw new Error('ログインしてください');
      }

      const parsed = directRequestSchema.safeParse({
        title,
        description,
        budget_jpy: budgetJpy ? Number(budgetJpy) : 0,
        delivery_days: deliveryDays ? Number(deliveryDays) : 0,
      });

      if (!parsed.success) {
        const messages = parsed.error.issues.map((issue) => issue.message);
        throw new Error(messages.join(', '));
      }

      await createDirectRequest(token, {
        musician_uuid: musicianUuid,
        ...parsed.data,
      });

      setSuccess(true);
      setTitle('');
      setDescription('');
      setBudgetJpy('');
      setDeliveryDays('');
    } catch (err) {
      setError(err instanceof Error ? err.message : '不明なエラーが発生しました');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-6 md:p-8">
      <h2 className="text-lg font-semibold mb-4">
        {musicianName} さんに制作を依頼する
      </h2>

      {success && (
        <div className="rounded-lg bg-green-50 p-4 mb-4">
          <p className="text-green-800 font-medium">制作依頼を送信しました！</p>
          <Link href="/requests" className="text-green-600 underline hover:text-green-800 text-sm">
            依頼管理ページで確認する
          </Link>
        </div>
      )}

      {error && (
        <div className="rounded-lg bg-red-50 p-3 text-sm text-red-800 mb-4">
          <p>{error}</p>
          {needsLogin && (
            <Link href="/login" className="mt-1 inline-block text-red-600 underline hover:text-red-800">
              ログインページへ
            </Link>
          )}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="dr-title" className="block text-sm font-medium text-gray-700 mb-1">
            タイトル
          </label>
          <input
            id="dr-title"
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="例: CM用BGM制作"
            className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-purple-500"
            required
          />
        </div>

        <div>
          <label htmlFor="dr-description" className="block text-sm font-medium text-gray-700 mb-1">
            依頼内容
          </label>
          <textarea
            id="dr-description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="依頼の詳細を記入してください（10文字以上）"
            rows={4}
            className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-purple-500"
            required
          />
        </div>

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label htmlFor="dr-budget" className="block text-sm font-medium text-gray-700 mb-1">
              予算（円）
            </label>
            <input
              id="dr-budget"
              type="number"
              value={budgetJpy}
              onChange={(e) => setBudgetJpy(e.target.value)}
              placeholder="例: 50000"
              min="1000"
              className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-purple-500"
              required
            />
          </div>

          <div>
            <label htmlFor="dr-delivery" className="block text-sm font-medium text-gray-700 mb-1">
              納期（日数）
            </label>
            <input
              id="dr-delivery"
              type="number"
              value={deliveryDays}
              onChange={(e) => setDeliveryDays(e.target.value)}
              placeholder="例: 14"
              min="1"
              max="365"
              className="w-full rounded-lg border border-gray-300 px-4 py-2 focus:outline-none focus:ring-2 focus:ring-purple-500"
              required
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full rounded-lg bg-purple-600 px-8 py-3 font-semibold text-white transition-colors hover:bg-purple-700 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {loading ? '送信中...' : '制作を依頼する'}
        </button>
      </form>
    </div>
  );
}
