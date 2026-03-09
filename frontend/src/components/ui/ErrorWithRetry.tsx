import ActionButton from './ActionButton';

interface ErrorWithRetryProps {
  readonly message: string;
  readonly onRetry: () => void;
  readonly isRetrying?: boolean;
}

export default function ErrorWithRetry({
  message,
  onRetry,
  isRetrying = false,
}: ErrorWithRetryProps) {
  return (
    <div className="rounded-lg bg-red-50 border border-red-200 p-6 text-center">
      <p className="text-red-800 mb-4">{message}</p>
      <ActionButton
        variant="secondary"
        onClick={onRetry}
        isLoading={isRetrying}
        loadingText="再読み込み中..."
      >
        再試行
      </ActionButton>
    </div>
  );
}
