import type { NextConfig } from "next";
import { PHASE_DEVELOPMENT_SERVER } from "next/constants";

export default function config(phase: string): NextConfig {
  return {
    output: "export",
    trailingSlash: true,
    skipTrailingSlashRedirect: true,
    turbopack: {
      rules: {
        "*.css": {
          loaders: ["@tailwindcss/turbopack"],
          as: "*.css",
        },
      },
    },
    ...(phase === PHASE_DEVELOPMENT_SERVER && {
      rewrites: async () => [
        {
          source: "/api/:path*",
          destination: `${process.env.API_URL ?? "http://localhost:8000"}/api/:path*`,
        },
      ],
    }),
  };
}
