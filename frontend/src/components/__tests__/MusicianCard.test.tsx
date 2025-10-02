import { render, screen } from "@testing-library/react";
import MusicianCard from "../MusicianCard";

describe("MusicianCard", () => {
  const mockProps = {
    id: 1,
    name: "田中 太郎",
    bio: "ロック・ポップス専門の作曲家",
    genre: "Rock, Pop",
    trackCount: 15,
  };

  it("renders musician information correctly", () => {
    render(<MusicianCard {...mockProps} />);

    expect(screen.getByText("田中 太郎")).toBeInTheDocument();
    expect(screen.getByText(/ロック・ポップス専門の作曲家/)).toBeInTheDocument();
    expect(screen.getByText(/Rock, Pop/)).toBeInTheDocument();
    expect(screen.getByText(/15曲/)).toBeInTheDocument();
  });

  it("renders link to musician detail page", () => {
    render(<MusicianCard {...mockProps} />);

    const link = screen.getByRole("link", { name: /詳細を見る/ });
    expect(link).toHaveAttribute("href", "/musicians/1");
  });
});
