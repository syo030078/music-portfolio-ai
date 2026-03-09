interface CardSkeletonProps {
  readonly count?: number;
}

function SingleSkeleton() {
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-6">
      <div className="flex items-start justify-between mb-4">
        <div className="space-y-2 flex-1">
          <div className="skeleton h-5 w-2/3" />
          <div className="skeleton h-4 w-1/3" />
        </div>
        <div className="skeleton h-6 w-16 rounded-full" />
      </div>
      <div className="space-y-2">
        <div className="skeleton h-4 w-full" />
        <div className="skeleton h-4 w-4/5" />
      </div>
      <div className="mt-4 grid grid-cols-2 gap-4">
        <div className="skeleton h-16 rounded-lg" />
        <div className="skeleton h-16 rounded-lg" />
      </div>
    </div>
  );
}

export default function CardSkeleton({ count = 3 }: CardSkeletonProps) {
  return (
    <div className="space-y-4">
      {Array.from({ length: count }, (_, i) => (
        <SingleSkeleton key={i} />
      ))}
    </div>
  );
}
