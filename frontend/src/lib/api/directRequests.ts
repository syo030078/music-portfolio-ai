import type {
  DirectRequest,
  DirectRequestCreatePayload,
  DirectRequestsListResponse,
  DirectRequestDetailResponse,
} from '@/types';
import { apiGet, apiPost } from './client';

export async function createDirectRequest(
  token: string,
  payload: DirectRequestCreatePayload
): Promise<DirectRequest> {
  const data = await apiPost<{ direct_request: DirectRequest }>(
    '/api/v1/direct_requests',
    token,
    { direct_request: payload }
  );
  return data.direct_request;
}

export async function fetchDirectRequests(
  token: string
): Promise<DirectRequest[]> {
  const data = await apiGet<DirectRequestsListResponse>(
    '/api/v1/direct_requests',
    token
  );
  return data.direct_requests;
}

export async function acceptDirectRequest(
  token: string,
  uuid: string
): Promise<DirectRequestDetailResponse> {
  return apiPost<DirectRequestDetailResponse>(
    `/api/v1/direct_requests/${uuid}/accept`,
    token
  );
}

export async function rejectDirectRequest(
  token: string,
  uuid: string
): Promise<DirectRequest> {
  const data = await apiPost<{ direct_request: DirectRequest }>(
    `/api/v1/direct_requests/${uuid}/reject`,
    token
  );
  return data.direct_request;
}
