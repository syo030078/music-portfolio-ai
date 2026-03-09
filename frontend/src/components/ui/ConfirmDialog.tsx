'use client';

import { useEffect, useRef } from 'react';

interface ConfirmDialogProps {
  readonly isOpen: boolean;
  readonly title: string;
  readonly message: string;
  readonly confirmLabel?: string;
  readonly cancelLabel?: string;
  readonly variant?: 'default' | 'danger';
  readonly isLoading?: boolean;
  readonly onConfirm: () => void;
  readonly onCancel: () => void;
}

export default function ConfirmDialog({
  isOpen,
  title,
  message,
  confirmLabel = '確認',
  cancelLabel = 'キャンセル',
  variant = 'default',
  isLoading = false,
  onConfirm,
  onCancel,
}: ConfirmDialogProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    if (isOpen) {
      dialog.showModal();
    } else {
      dialog.close();
    }
  }, [isOpen]);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    const handleClose = () => {
      if (!isLoading) {
        onCancel();
      }
    };

    dialog.addEventListener('close', handleClose);
    return () => dialog.removeEventListener('close', handleClose);
  }, [onCancel, isLoading]);

  if (!isOpen) return null;

  const confirmStyles =
    variant === 'danger'
      ? 'bg-red-600 text-white hover:bg-red-700'
      : 'bg-green-600 text-white hover:bg-green-700';

  return (
    <dialog
      ref={dialogRef}
      className="rounded-lg border-0 bg-white p-0 shadow-xl backdrop:bg-black/50"
    >
      <div className="w-[min(400px,90vw)] p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-2">{title}</h3>
        <p className="text-sm text-gray-600 mb-6">{message}</p>
        <div className="flex justify-end gap-3">
          <button
            type="button"
            onClick={onCancel}
            disabled={isLoading}
            className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-semibold text-gray-700 transition-colors hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {cancelLabel}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={isLoading}
            className={`rounded-lg px-4 py-2 text-sm font-semibold transition-colors disabled:opacity-50 disabled:cursor-not-allowed ${confirmStyles}`}
          >
            {isLoading ? '処理中...' : confirmLabel}
          </button>
        </div>
      </div>
    </dialog>
  );
}
