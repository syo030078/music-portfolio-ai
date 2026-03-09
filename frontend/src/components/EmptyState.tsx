import Link from "next/link";

type EmptyStateProps = {
  icon: string;
  title: string;
  description?: string;
  actionLabel?: string;
  actionHref?: string;
};

export default function EmptyState({
  icon,
  title,
  description,
  actionLabel,
  actionHref,
}: EmptyStateProps) {
  return (
    <div className="animate-fade-up text-center py-16">
      <div className="text-5xl mb-4">{icon}</div>
      <h3 className="text-lg font-semibold text-gray-900 mb-2">{title}</h3>
      {description && (
        <p className="text-gray-500 mb-6 max-w-md mx-auto">{description}</p>
      )}
      {actionLabel && actionHref && (
        <Link href={actionHref} className="btn-primary px-6 py-2.5">
          {actionLabel}
        </Link>
      )}
    </div>
  );
}
