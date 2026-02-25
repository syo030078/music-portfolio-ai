import type { Track, TracksListResponse, MusicianSummary } from '@/types';
import { apiGet } from './client';

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

export async function fetchMusicianByUuid(uuid: string): Promise<MusicianSummary | null> {
  const musicians = await fetchMusicians();
  return musicians.find((m) => m.uuid === uuid) ?? null;
}
