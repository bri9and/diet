import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Fuelvio - AI-Powered Nutrition Tracking",
  description: "Track your nutrition effortlessly. Snap a photo of your meal and let AI do the rest.",
  icons: {
    icon: "/favicon.png",
    apple: "/logo.png",
  },
  openGraph: {
    title: "Fuelvio - AI-Powered Nutrition Tracking",
    description: "Track your nutrition effortlessly. Snap a photo of your meal and let AI do the rest.",
    images: ["/logo.png"],
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <main>{children}</main>
      </body>
    </html>
  );
}
