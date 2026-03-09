import { toast } from "sonner";

export function showSuccess(title: string, description?: string): void {
  toast.success(title, { description });
}

export function showError(title: string, description?: string): void {
  toast.error(title, { description });
}

export function showInfo(title: string, description?: string): void {
  toast.info(title, { description });
}

export function showAuthError(): void {
  toast.error("ログインセッションが切れました", {
    description: "再度ログインしてください",
    action: {
      label: "ログインページへ",
      onClick: () => {
        window.location.href = "/login";
      },
    },
  });
}
