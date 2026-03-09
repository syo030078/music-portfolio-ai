import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  output: "standalone",
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: "http://localhost:3000/api/:path*",
      },
      {
        source: "/auth/:path*",
        destination: "http://localhost:3000/auth/:path*",
      },
    ];
  },
};

export default nextConfig;
