import type { Metadata } from "next";
import Header from "@/components/Header";
import "./globals.css";

export const metadata: Metadata = {
  title: "Music Portfolio AI - AI 楽曲解析つきの受発注マッチング",
  description: "音楽家と依頼者をつなぐ、AI 楽曲解析つきの受発注マッチングプラットフォーム",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ja" suppressHydrationWarning>
      <body
        className="min-h-screen bg-gray-50"
        suppressHydrationWarning
      >
        <Header />
        {children}
      </body>
    </html>
  );
}
