import { render, screen } from "@testing-library/react";
import HomePage from "../page";

describe("HomePage", () => {
  it("renders page title", () => {
    render(<HomePage />);

    expect(screen.getByText("Music Portfolio")).toBeInTheDocument();
    expect(screen.getByText("音楽家を探す")).toBeInTheDocument();
  });

  it("renders upload link", () => {
    render(<HomePage />);

    const uploadLink = screen.getByRole("link", { name: /楽曲アップロード/ });
    expect(uploadLink).toHaveAttribute("href", "/upload");
  });

  it("renders musician cards", () => {
    render(<HomePage />);

    expect(screen.getByText("田中 太郎")).toBeInTheDocument();
    expect(screen.getByText("佐藤 花子")).toBeInTheDocument();
    expect(screen.getByText("鈴木 一郎")).toBeInTheDocument();
  });

  it("renders matching link", () => {
    render(<HomePage />);

    const matchingLink = screen.getByRole("link", {
      name: /企業向けマッチング/,
    });
    expect(matchingLink).toHaveAttribute("href", "/matching");
  });
});
