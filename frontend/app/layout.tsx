import type React from "react";
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { Analytics } from "@vercel/analytics/next";
import { NotificationsProvider } from "@/components/notifications-provider";
import { NotificationsDisplay } from "@/components/notifications-display";
import { Providers } from "@/components/providers";
import "./globals.css";
import "@rainbow-me/rainbowkit/styles.css";

const _geist = Geist({ subsets: ["latin"] });
const _geistMono = Geist_Mono({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "FUNDit - Automated Savings on Base",
  description:
    "Secure, automated savings platform with Spend & Save automation on Base blockchain",
  generator: "v0.app",
  icons: {
    icon: [
      {
        url: "/icon-light-32x32.png",
        media: "(prefers-color-scheme: light)",
      },
      {
        url: "/icon-dark-32x32.png",
        media: "(prefers-color-scheme: dark)",
      },
      {
        url: "/icon.svg",
        type: "image/svg+xml",
      },
    ],
    apple: "/apple-icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`font-sans antialiased`}>
        <Providers>
          <NotificationsProvider>
            {children}
            <NotificationsDisplay />
            <Analytics />
          </NotificationsProvider>
        </Providers>
      </body>
    </html>
  );
}