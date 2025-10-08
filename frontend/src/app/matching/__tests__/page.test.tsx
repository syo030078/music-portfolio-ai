import { render, screen } from "@testing-library/react";
import MatchingPage from "../page";

describe("MatchingPage", () => {
  it("renders matching page title", () => {
    render(<MatchingPage />);
    expect(screen.getByText("音楽家マッチング支援")).toBeInTheDocument();
  });

  it("renders search form with genre select", () => {
    render(<MatchingPage />);
    expect(screen.getByLabelText("ジャンル")).toBeInTheDocument();
  });

  it("renders search form with budget select", () => {
    render(<MatchingPage />);
    expect(screen.getByLabelText("予算")).toBeInTheDocument();
  });

  it("renders search form with experience select", () => {
    render(<MatchingPage />);
    expect(screen.getByLabelText("実績")).toBeInTheDocument();
  });

  it("renders search button", () => {
    render(<MatchingPage />);
    expect(screen.getByRole("button", { name: "検索する" })).toBeInTheDocument();
  });

  it("renders navigation links", () => {
    render(<MatchingPage />);
    expect(screen.getByText("音楽家向け")).toBeInTheDocument();
    expect(screen.getByText("企業向け")).toBeInTheDocument();
  });
});
