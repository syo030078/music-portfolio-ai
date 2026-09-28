import { apiPost, apiPostForm } from './client';

export type TrackUploadResult = {
  uuid: string;
  bpm?: number | null;
  key?: string | null;
  genre?: string | null;
  yt_url?: string;
  title?: string;
};

type TrackCreateResponse = {
  message: string;
  data: TrackUploadResult;
};

export async function uploadAudio(token: string, file: File): Promise<TrackUploadResult> {
  const formData = new FormData();
  formData.append('audio_file', file);
  const res = await apiPostForm<TrackCreateResponse>('/api/v1/tracks', token, formData);
  return res.data;
}

export async function registerYoutube(token: string, ytUrl: string): Promise<TrackUploadResult> {
  const res = await apiPost<TrackCreateResponse>('/api/v1/tracks', token, {
    yt_url: ytUrl,
    title: 'YouTube Video',
  });
  return res.data;
}
