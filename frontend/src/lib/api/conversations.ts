import type {
  Conversation,
  ConversationsListResponse,
  ConversationDetailResponse,
  Message,
} from '@/types/conversation';
import { apiGet, apiPost } from './client';

export async function fetchConversations(
  token: string
): Promise<Conversation[]> {
  const data = await apiGet<ConversationsListResponse>(
    '/api/v1/conversations',
    token
  );
  return data.conversations;
}

export async function fetchConversation(
  token: string,
  uuid: string
): Promise<Conversation> {
  const data = await apiGet<ConversationDetailResponse>(
    `/api/v1/conversations/${encodeURIComponent(uuid)}`,
    token
  );
  return data.conversation;
}

type MessagesResponse = {
  messages: Message[];
  meta: {
    has_more: boolean;
    oldest_uuid: string | null;
  };
};

export async function fetchMessages(
  token: string,
  conversationUuid: string,
  options?: { since?: string; before?: string; limit?: number }
): Promise<MessagesResponse> {
  const params = new URLSearchParams();
  if (options?.since) params.set('since', options.since);
  if (options?.before) params.set('before', options.before);
  if (options?.limit) params.set('limit', String(options.limit));

  const query = params.toString();
  const path = `/api/v1/conversations/${encodeURIComponent(conversationUuid)}/messages${query ? `?${query}` : ''}`;

  return apiGet<MessagesResponse>(path, token);
}

export async function sendMessage(
  token: string,
  conversationUuid: string,
  content: string
): Promise<Message> {
  const data = await apiPost<{ message: Message }>(
    `/api/v1/conversations/${encodeURIComponent(conversationUuid)}/messages`,
    token,
    { message: { content } }
  );
  return data.message;
}
