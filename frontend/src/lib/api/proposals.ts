import type {
  Proposal,
  ProposalCreatePayload,
  ProposalsListResponse,
  ProposalAcceptResponse,
} from '@/types';
import { apiGet, apiPost } from './client';

export async function createProposal(
  token: string,
  jobUuid: string,
  payload: ProposalCreatePayload
): Promise<Proposal> {
  const data = await apiPost<{ proposal: Proposal }>(
    `/api/v1/jobs/${jobUuid}/proposals`,
    token,
    { proposal: payload }
  );
  return data.proposal;
}

export async function fetchProposals(
  token: string,
  jobUuid: string
): Promise<Proposal[]> {
  const data = await apiGet<ProposalsListResponse>(
    `/api/v1/jobs/${jobUuid}/proposals`,
    token
  );
  return data.proposals;
}

export async function acceptProposal(
  token: string,
  uuid: string
): Promise<ProposalAcceptResponse> {
  return apiPost<ProposalAcceptResponse>(`/api/v1/proposals/${uuid}/accept`, token);
}

export async function rejectProposal(
  token: string,
  uuid: string
): Promise<Proposal> {
  const data = await apiPost<{ proposal: Proposal }>(
    `/api/v1/proposals/${uuid}/reject`,
    token
  );
  return data.proposal;
}
