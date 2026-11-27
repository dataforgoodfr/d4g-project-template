import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Projet Data For Good",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="fr">
      <body>{children}</body>
    </html>
  );
}
