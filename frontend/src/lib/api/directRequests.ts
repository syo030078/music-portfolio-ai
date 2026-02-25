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
  const data = await apiPost<{ production_request: DirectRequest }>(
    '/api/v1/production_requests',
    token,
    { production_request: payload }
  );
  return data.production_request;
}

export async function fetchDirectRequests(
  token: string
): Promise<DirectRequest[]> {
  const data = await apiGet<DirectRequestsListResponse>(
    '/api/v1/production_requests',
    token
  );
  return data.production_requests;
}

export async function acceptDirectRequest(
  token: string,
  uuid: string
): Promise<DirectRequestDetailResponse> {
  return apiPost<DirectRequestDetailResponse>(
    `/api/v1/production_requests/${uuid}/accept`,
    token
  );
}

export async function rejectDirectRequest(
  token: string,
  uuid: string
): Promise<DirectRequest> {
  const data = await apiPost<{ production_request: DirectRequest }>(
    `/api/v1/production_requests/${uuid}/reject`,
    token
  );
  return data.production_request;
}
