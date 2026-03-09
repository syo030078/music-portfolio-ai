type SkeletonCardProps = {
  variant: "musician" | "job";
};

export default function SkeletonCard({ variant }: SkeletonCardProps) {
  if (variant === "musician") {
    return (
      <div className="overflow-hidden rounded-lg border border-gray-200 bg-white">
        <div className="skeleton h-48" style={{ borderRadius: 0 }} />
        <div className="p-5 space-y-3">
          <div className="skeleton h-6 w-2/3" />
          <div className="skeleton h-4 w-full" />
          <div className="flex gap-2">
            <div className="skeleton h-6 w-16 rounded-full" />
            <div className="skeleton h-6 w-20 rounded-full" />
          </div>
          <div className="skeleton h-4 w-1/3 mt-4" />
        </div>
      </div>
    );
  }

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-6">
      <div className="space-y-3">
        <div className="skeleton h-6 w-3/4" />
        <div className="skeleton h-4 w-full" />
        <div className="skeleton h-4 w-2/3" />
        <div className="flex justify-between mt-4">
          <div className="skeleton h-5 w-16" />
          <div className="skeleton h-5 w-24" />
        </div>
      </div>
    </div>
  );
}
