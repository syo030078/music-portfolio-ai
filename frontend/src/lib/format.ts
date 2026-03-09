import type { Job } from '@/types';

type BudgetInfo = Pick<Job, 'budget_jpy' | 'budget_min_jpy' | 'budget_max_jpy'>;

export function formatBudget(job: BudgetInfo): string {
  if (job.budget_jpy) return `¥${job.budget_jpy.toLocaleString()}`;
  if (job.budget_min_jpy && job.budget_max_jpy) {
    return `¥${job.budget_min_jpy.toLocaleString()} - ¥${job.budget_max_jpy.toLocaleString()}`;
  }
  return '要相談';
}

export function formatDate(dateString: string | null | undefined): string {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleDateString('ja-JP');
}
