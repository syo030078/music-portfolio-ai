import Link from "next/link";

type MusicianCardProps = {
  id: number;
  name: string;
  bio: string;
  genre: string;
  trackCount: number;
};

export default function MusicianCard({
  id,
  name,
  bio,
  genre,
  trackCount,
}: MusicianCardProps) {
  return (
    <Link href={`/musicians/${id}`} className="group block">
      <div className="overflow-hidden rounded-lg border border-gray-200 bg-white transition-all hover:border-purple-500 hover:shadow-xl">
        {/* プロフィール画像エリア */}
        <div className="flex h-48 items-center justify-center bg-gradient-to-br from-purple-500 to-blue-500">
          <div className="flex h-20 w-20 items-center justify-center rounded-full bg-white text-3xl font-bold text-purple-600">
            {name.charAt(0)}
          </div>
        </div>

        {/* 情報エリア */}
        <div className="p-5">
          <h3 className="mb-2 text-xl font-bold text-gray-900 group-hover:text-purple-600">
            {name}
          </h3>
          <p className="mb-4 line-clamp-2 text-sm text-gray-600">{bio}</p>

          <div className="mb-4 flex flex-wrap gap-2">
            {genre.split(', ').map((g) => (
              <span
                key={g}
                className="rounded-full bg-gray-100 px-3 py-1 text-xs font-medium text-gray-700"
              >
                {g}
              </span>
            ))}
          </div>

          <div className="flex items-center justify-between border-t pt-4">
            <span className="text-sm text-gray-500">{trackCount}曲登録</span>
            <span className="text-sm font-medium text-purple-600 group-hover:underline">
              詳細を見る →
            </span>
          </div>
        </div>
      </div>
    </Link>
  );
}
