import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  experimental: {
    // パッケージの最適化インポート
    optimizePackageImports: ['react', 'react-dom', 'next'],
  },

  // 開発時のファストリフレッシュを最適化
  reactStrictMode: true,
};

export default nextConfig;
