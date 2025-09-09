"use client";
import { useState, useEffect } from "react";

const API = process.env.NEXT_PUBLIC_API_BASE_URL || "";

type Track = {
  id: number;
  title?: string | null;
  yt_url: string;
  bpm?: number | null;
  key?: string | null;
  genre?: string | null;
  ai_text?: string | null;
};

export default function Page() {
  const [url, setUrl] = useState("");
  const [tracks, setTracks] = useState<Track[]>([]);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);

  async function fetchTracks() {
    try {
      const res = await fetch(`${API}/api/v1/tracks`);
      if (!res.ok) throw new Error(await res.text());
      setTracks(await res.json());
      setError("");
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  async function createTrack() {
    if (!url.trim()) return;
    try {
      const res = await fetch(`${API}/api/v1/tracks`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ yt_url: url }),
      });
      if (!res.ok) throw new Error(await res.text());
      setUrl("");
      await fetchTracks();
    } catch (e: any) {
      alert(e.message);
    }
  }

  useEffect(() => {
    fetchTracks();
    const id = setInterval(fetchTracks, 15000);
    return () => clearInterval(id);
  }, []);

  return (
    <div
      style={{ maxWidth: 700, margin: "20px auto", fontFamily: "sans-serif" }}
    >
      <h1>Music Portfolio AI (MVP)</h1>

      {!API && (
        <p style={{ color: "red" }}>
          NEXT_PUBLIC_API_BASE_URL が未設定です (.env.local)
        </p>
      )}

      <div style={{ marginTop: 12 }}>
        <input
          style={{ padding: 6, width: "70%" }}
          placeholder="YouTube URL"
          value={url}
          onChange={(e) => setUrl(e.target.value)}
        />
        <button
          style={{ padding: "6px 12px", marginLeft: 8 }}
          onClick={createTrack}
        >
          登録して解析
        </button>
      </div>

      <h2 style={{ marginTop: 24 }}>登録済みトラック</h2>
      {loading ? (
        <p>読み込み中...</p>
      ) : error ? (
        <p style={{ color: "red" }}>{error}</p>
      ) : tracks.length === 0 ? (
        <p>まだありません</p>
      ) : (
        <ul style={{ padding: 0, listStyle: "none" }}>
          {tracks.map((t) => (
            <li
              key={t.id}
              style={{ border: "1px solid #ddd", margin: "8px 0", padding: 8 }}
            >
              <div>
                <b>{t.title || "(no title)"}</b>
              </div>
              <div>
                <a href={t.yt_url} target="_blank">
                  {t.yt_url}
                </a>
              </div>
              <div>
                BPM: {t.bpm ?? "-"}, Key: {t.key ?? "-"}, Genre:{" "}
                {t.genre ?? "-"}
              </div>
              {t.ai_text && (
                <div
                  style={{ marginTop: 6, background: "#f5f5f5", padding: 6 }}
                >
                  {t.ai_text}
                </div>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

// import Image from "next/image";

// export default function Home() {
//   return (
//     <div className="font-sans grid grid-rows-[20px_1fr_20px] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20">
//       <main className="flex flex-col gap-[32px] row-start-2 items-center sm:items-start">
//         <Image
//           className="dark:invert"
//           src="/next.svg"
//           alt="Next.js logo"
//           width={180}
//           height={38}
//           priority
//         />
//         <ol className="font-mono list-inside list-decimal text-sm/6 text-center sm:text-left">
//           <li className="mb-2 tracking-[-.01em]">
//             Get started by editing{" "}
//             <code className="bg-black/[.05] dark:bg-white/[.06] font-mono font-semibold px-1 py-0.5 rounded">
//               src/app/page.tsx
//             </code>
//             .
//           </li>
//           <li className="tracking-[-.01em]">
//             Save and see your changes instantly.
//           </li>
//         </ol>

//         <div className="flex gap-4 items-center flex-col sm:flex-row">
//           <a
//             className="rounded-full border border-solid border-transparent transition-colors flex items-center justify-center bg-foreground text-background gap-2 hover:bg-[#383838] dark:hover:bg-[#ccc] font-medium text-sm sm:text-base h-10 sm:h-12 px-4 sm:px-5 sm:w-auto"
//             href="https://vercel.com/new?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
//             target="_blank"
//             rel="noopener noreferrer"
//           >
//             <Image
//               className="dark:invert"
//               src="/vercel.svg"
//               alt="Vercel logomark"
//               width={20}
//               height={20}
//             />
//             Deploy now
//           </a>
//           <a
//             className="rounded-full border border-solid border-black/[.08] dark:border-white/[.145] transition-colors flex items-center justify-center hover:bg-[#f2f2f2] dark:hover:bg-[#1a1a1a] hover:border-transparent font-medium text-sm sm:text-base h-10 sm:h-12 px-4 sm:px-5 w-full sm:w-auto md:w-[158px]"
//             href="https://nextjs.org/docs?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
//             target="_blank"
//             rel="noopener noreferrer"
//           >
//             Read our docs
//           </a>
//         </div>
//       </main>
//       <footer className="row-start-3 flex gap-[24px] flex-wrap items-center justify-center">
//         <a
//           className="flex items-center gap-2 hover:underline hover:underline-offset-4"
//           href="https://nextjs.org/learn?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
//           target="_blank"
//           rel="noopener noreferrer"
//         >
//           <Image
//             aria-hidden
//             src="/file.svg"
//             alt="File icon"
//             width={16}
//             height={16}
//           />
//           Learn
//         </a>
//         <a
//           className="flex items-center gap-2 hover:underline hover:underline-offset-4"
//           href="https://vercel.com/templates?framework=next.js&utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
//           target="_blank"
//           rel="noopener noreferrer"
//         >
//           <Image
//             aria-hidden
//             src="/window.svg"
//             alt="Window icon"
//             width={16}
//             height={16}
//           />
//           Examples
//         </a>
//         <a
//           className="flex items-center gap-2 hover:underline hover:underline-offset-4"
//           href="https://nextjs.org?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
//           target="_blank"
//           rel="noopener noreferrer"
//         >
//           <Image
//             aria-hidden
//             src="/globe.svg"
//             alt="Globe icon"
//             width={16}
//             height={16}
//           />
//           Go to nextjs.org →
//         </a>
//       </footer>
//     </div>
//   );
// }
