import type {
  User,
  Track,
  TracksListResponse,
  TrackDetailResponse,
  ApiErrorResponse,
} from "../index";

describe("TypeScript Type Definitions", () => {
  describe("User type", () => {
    it("should accept valid user object", () => {
      const user: User = {
        id: 1,
        email: "test@example.com",
        name: "Test User",
        bio: "Test bio",
      };

      expect(user.id).toBe(1);
      expect(user.email).toBe("test@example.com");
      expect(user.name).toBe("Test User");
      expect(user.bio).toBe("Test bio");
    });

    it("should accept user without optional bio", () => {
      const user: User = {
        id: 1,
        email: "test@example.com",
        name: "Test User",
      };

      expect(user.bio).toBeUndefined();
    });
  });

  describe("Track type", () => {
    it("should accept valid track object", () => {
      const track: Track = {
        id: 1,
        title: "Test Track",
        description: "Test description",
        yt_url: "https://www.youtube.com/watch?v=test123",
        bpm: 120,
        key: "C",
        genre: "Rock",
        ai_text: "AI generated text",
        created_at: "2025-01-01T00:00:00Z",
        updated_at: "2025-01-02T00:00:00Z",
        user: {
          id: 1,
          email: "test@example.com",
          name: "Test User",
        },
      };

      expect(track.id).toBe(1);
      expect(track.title).toBe("Test Track");
      expect(track.user.name).toBe("Test User");
    });

    it("should accept track with minimal required fields", () => {
      const track: Track = {
        id: 1,
        title: "Test Track",
        yt_url: "https://www.youtube.com/watch?v=test123",
        created_at: "2025-01-01T00:00:00Z",
        user: {
          id: 1,
          email: "test@example.com",
          name: "Test User",
        },
      };

      expect(track.description).toBeUndefined();
      expect(track.bpm).toBeUndefined();
      expect(track.key).toBeUndefined();
      expect(track.genre).toBeUndefined();
    });
  });

  describe("TracksListResponse type", () => {
    it("should accept valid tracks list response", () => {
      const response: TracksListResponse = {
        tracks: [
          {
            id: 1,
            title: "Track 1",
            yt_url: "https://www.youtube.com/watch?v=test1",
            created_at: "2025-01-01T00:00:00Z",
            user: {
              id: 1,
              email: "user1@example.com",
              name: "User 1",
            },
          },
        ],
        pagination: {
          current_page: 1,
          total_pages: 1,
          total_count: 1,
          per_page: 10,
        },
      };

      expect(response.tracks).toHaveLength(1);
      expect(response.pagination.current_page).toBe(1);
    });
  });

  describe("TrackDetailResponse type", () => {
    it("should accept valid track detail response", () => {
      const response: TrackDetailResponse = {
        track: {
          id: 1,
          title: "Test Track",
          yt_url: "https://www.youtube.com/watch?v=test123",
          created_at: "2025-01-01T00:00:00Z",
          user: {
            id: 1,
            email: "test@example.com",
            name: "Test User",
          },
        },
      };

      expect(response.track.id).toBe(1);
      expect(response.track.title).toBe("Test Track");
    });
  });

  describe("ApiErrorResponse type", () => {
    it("should accept valid error response", () => {
      const response: ApiErrorResponse = {
        error: "Something went wrong",
      };

      expect(response.error).toBe("Something went wrong");
    });
  });
});
