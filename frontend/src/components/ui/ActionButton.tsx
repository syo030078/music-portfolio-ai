import Spinner from './Spinner';

interface ActionButtonProps {
  readonly children: React.ReactNode;
  readonly isLoading?: boolean;
  readonly loadingText?: string;
  readonly type?: 'button' | 'submit';
  readonly variant?: 'primary' | 'secondary' | 'danger';
  readonly disabled?: boolean;
  readonly className?: string;
  readonly onClick?: () => void;
}

const VARIANT_STYLES = {
  primary:
    'bg-[var(--color-primary)] text-white hover:bg-[var(--color-primary-dark)] disabled:opacity-50',
  secondary:
    'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 disabled:opacity-50',
  danger:
    'bg-red-600 text-white hover:bg-red-700 disabled:opacity-50',
} as const;

export default function ActionButton({
  children,
  isLoading = false,
  loadingText,
  type = 'button',
  variant = 'primary',
  disabled = false,
  className = '',
  onClick,
}: ActionButtonProps) {
  return (
    <button
      type={type}
      disabled={disabled || isLoading}
      onClick={onClick}
      className={`inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2 font-semibold transition-colors disabled:cursor-not-allowed ${VARIANT_STYLES[variant]} ${className}`}
    >
      {isLoading && <Spinner size="sm" />}
      {isLoading && loadingText ? loadingText : children}
    </button>
  );
}
