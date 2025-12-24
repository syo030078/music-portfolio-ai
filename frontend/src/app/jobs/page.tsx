import Link from 'next/link';

interface Job {
  uuid: string;
  title: string;
  description: string;
  budget_jpy: number | null;
  budget_min_jpy: number | null;
  budget_max_jpy: number | null;
  is_remote: boolean;
  published_at: string;
  client: {
    id: number;
    name: string;
  };
}

async function getJobs(): Promise<Job[]> {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';
  const res = await fetch(`${apiUrl}/api/v1/jobs`, {
    cache: 'no-store',
  });

  if (!res.ok) {
    throw new Error('Failed to fetch jobs');
  }

  const data = await res.json();
  return data.jobs;
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

export default async function JobsPage() {
  const jobs = await getJobs();

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">案件一覧</h1>

      {jobs.length === 0 ? (
        <p className="text-gray-500">現在公開中の案件はありません。</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {jobs.map((job) => (
            <div
              key={job.uuid}
              className="border border-gray-200 rounded-lg p-6 hover:shadow-lg transition-shadow"
            >
              <h2 className="text-xl font-semibold mb-2">{job.title}</h2>

              <p className="text-gray-600 mb-4 line-clamp-3">
                {job.description}
              </p>

              <div className="space-y-2 mb-4">
                <div className="flex items-center text-sm">
                  <span className="font-medium mr-2">予算:</span>
                  <span className="text-green-600">{formatBudget(job)}</span>
                </div>

                <div className="flex items-center text-sm">
                  <span className="font-medium mr-2">リモート:</span>
                  <span className={job.is_remote ? 'text-blue-600' : 'text-gray-500'}>
                    {job.is_remote ? '可' : '不可'}
                  </span>
                </div>

                <div className="flex items-center text-sm">
                  <span className="font-medium mr-2">依頼者:</span>
                  <span className="text-gray-700">{job.client.name}</span>
                </div>
              </div>

              <Link
                href={`/jobs/${job.uuid}`}
                className="inline-block w-full text-center bg-blue-600 text-white py-2 px-4 rounded hover:bg-blue-700 transition-colors"
              >
                詳細を見る
              </Link>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
