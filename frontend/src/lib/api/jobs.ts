import type { JobsListResponse, JobDetailResponse, Job } from '@/types';
import { apiGet } from './client';

export async function fetchJobs(): Promise<Job[]> {
  const data = await apiGet<JobsListResponse>('/api/v1/jobs');
  return data.jobs;
}

export async function fetchJob(uuid: string): Promise<Job> {
  const data = await apiGet<JobDetailResponse>(
    `/api/v1/jobs/${encodeURIComponent(uuid)}`
  );
  return data.job;
}
