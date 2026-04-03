import type { Track, TracksListResponse, MusicianSummary } from '@/types';
import { apiGet, apiPost } from './client';

function groupTracksByMusician(tracks: Track[]): MusicianSummary[] {
  const musicianMap = new Map<string, MusicianSummary>();

  for (const track of tracks) {
    const existing = musicianMap.get(track.user.uuid);

    if (existing) {
      const updatedTracks = [...existing.tracks, track];
      const genre = track.genre;
      const updatedGenres = genre && !existing.genres.includes(genre)
        ? [...existing.genres, genre]
        : existing.genres;

      musicianMap.set(track.user.uuid, {
        ...existing,
        trackCount: updatedTracks.length,
        genres: updatedGenres,
        tracks: updatedTracks,
      });
    } else {
      musicianMap.set(track.user.uuid, {
        uuid: track.user.uuid,
        name: track.user.name,
        bio: track.user.bio ?? null,
        trackCount: 1,
        genres: track.genre ? [track.genre] : [],
        tracks: [track],
      });
    }
  }

  return Array.from(musicianMap.values());
}

export async function fetchMusicians(): Promise<MusicianSummary[]> {
  const data = await apiGet<TracksListResponse>('/api/v1/tracks?per_page=50');
  return groupTracksByMusician(data.tracks);
}

type UserProfile = {
  uuid: string;
  name: string;
  bio?: string;
  is_musician: boolean;
  is_client: boolean;
};

export async function fetchMusicianByUuid(uuid: string): Promise<MusicianSummary | null> {
  const data = await apiGet<TracksListResponse>(`/api/v1/tracks?user_uuid=${encodeURIComponent(uuid)}&per_page=50`);
  const musicians = groupTracksByMusician(data.tracks);
  const found = musicians.find((m) => m.uuid === uuid);
  if (found) return found;

  // 楽曲0件の場合はユーザープロフィールAPIから取得
  const profile = await apiGet<UserProfile>(`/api/v1/users/${encodeURIComponent(uuid)}`);
  return {
    uuid: profile.uuid,
    name: profile.name,
    bio: profile.bio ?? null,
    trackCount: 0,
    genres: [],
    tracks: [],
  };
}

export async function generateAiText(trackUuid: string, token: string): Promise<{ uuid: string; ai_text: string }> {
  const data = await apiPost<{ track: { uuid: string; ai_text: string } }>(
    `/api/v1/tracks/${encodeURIComponent(trackUuid)}/generate_ai_text`,
    token
  );
  return data.track;
}
