export type Message = {
  uuid: string;
  sender_uuid: string;
  sender_name: string;
  content: string;
  created_at: string;
};

export type Conversation = {
  uuid: string;
  job_uuid?: string;
  contract_uuid?: string;
  created_at: string;
  updated_at?: string;
  participants: {
    uuid: string;
    name: string;
    bio?: string;
  }[];
  messages?: Message[];
  last_message?: {
    uuid: string;
    content: string;
    sender_uuid: string;
    created_at: string;
  };
  unread_count?: number;
};

export type ConversationsListResponse = {
  conversations: Conversation[];
};

export type ConversationDetailResponse = {
  conversation: Conversation;
};
