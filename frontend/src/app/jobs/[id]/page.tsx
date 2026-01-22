import Link from 'next/link';
import { notFound } from 'next/navigation';
import ContactButton from '@/components/ContactButton';

interface Job {
  uuid: string;
  title: string;
  description: string;
  budget_jpy: number | null;
  budget_min_jpy: number | null;
  budget_max_jpy: number | null;
  is_remote: boolean;
  delivery_due_on: string | null;
  published_at: string;
  created_at: string;
  client: {
    uuid: string;
    name: string;
    bio: string | null;
  };
}

async function getJob(id: string): Promise<Job | null> {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';
  const res = await fetch(`${apiUrl}/api/v1/jobs/${id}`, {
    cache: 'no-store',
  });

  if (!res.ok) {
    return null;
  }

  const data = await res.json();
  return data.job;
}

function formatBudget(job: Job): string {
  if (job.budget_jpy) {
    return `¥${job.budget_jpy.toLocaleString()}`;
  }
  if (job.budget_min_jpy && job.budget_max_jpy) {
    return `¥${job.budget_min_jpy.toLocaleString()} - ¥${job.budget_max_jpy.toLocaleString()}`;
  }
  return '要相談';
}

function formatDate(dateString: string | null): string {
  if (!dateString) return '-';
  const date = new Date(dateString);
  return date.toLocaleDateString('ja-JP');
}

export default async function JobDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const job = await getJob(params.id);

  if (!job) {
    notFound();
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-6">
        <Link href="/jobs" className="text-blue-600 hover:underline">
          ← 案件一覧に戻る
        </Link>
      </div>

      <div className="bg-white border border-gray-200 rounded-lg p-8">
        <h1 className="text-3xl font-bold mb-6">{job.title}</h1>

        <div className="space-y-6">
          <div>
            <h2 className="text-lg font-semibold mb-2">案件詳細</h2>
            <p className="text-gray-700 whitespace-pre-wrap">{job.description}</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 border-t pt-6">
            <div>
              <span className="font-medium">予算:</span>
              <span className="ml-2 text-green-600 font-semibold">
                {formatBudget(job)}
              </span>
            </div>

            <div>
              <span className="font-medium">リモート:</span>
              <span
                className={`ml-2 font-semibold ${
                  job.is_remote ? 'text-blue-600' : 'text-gray-500'
                }`}
              >
                {job.is_remote ? '可' : '不可'}
              </span>
            </div>

            <div>
              <span className="font-medium">納期:</span>
              <span className="ml-2 text-gray-700">
                {formatDate(job.delivery_due_on)}
              </span>
            </div>

            <div>
              <span className="font-medium">公開日:</span>
              <span className="ml-2 text-gray-700">
                {formatDate(job.published_at)}
              </span>
            </div>
          </div>

          <div className="border-t pt-6">
            <h2 className="text-lg font-semibold mb-3">依頼者情報</h2>
            <div className="bg-gray-50 rounded-lg p-4">
              <p className="font-medium text-lg mb-2">{job.client.name}</p>
              {job.client.bio && (
                <p className="text-gray-600">{job.client.bio}</p>
              )}
            </div>
          </div>

          <div className="border-t pt-6">
            <ContactButton jobUuid={job.uuid} clientUuid={job.client.uuid} />
          </div>
        </div>
      </div>
    </div>
  );
}
