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
    <div className="bg-white rounded-2xl p-6 hover:shadow-lg transition-shadow duration-200">
      <h3 className="text-xl font-bold text-gray-900 mb-2">{name}</h3>
      <p className="text-gray-600 text-sm mb-4 line-clamp-2">{bio}</p>

      <div className="flex items-center gap-4 text-sm text-gray-500 mb-4">
        <span>得意: {genre}</span>
        <span>{trackCount}曲</span>
      </div>

      <Link
        href={`/musicians/${id}`}
        className="inline-block w-full text-center bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded-lg transition-colors duration-200"
      >
        詳細を見る
      </Link>
    </div>
  );
}
