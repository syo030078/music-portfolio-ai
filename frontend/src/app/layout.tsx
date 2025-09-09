import type { Metadata } from "next";
// import "./globals.css"; // 必要なら残す

export const metadata: Metadata = {
  title: "Music Portfolio AI",
  description: "MVP Frontend",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ja">
      <body
        style={{
          margin: 0,
          fontFamily:
            'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif',
        }}
      >
        {children}
      </body>
    </html>
  );
}
