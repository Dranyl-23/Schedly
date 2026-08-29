import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Sidebar } from "@/components/Sidebar";
import { AuthProvider } from "@/context/AuthContext";
import { ThemeProvider } from "@/context/ThemeContext";
import { AuthGuard } from "@/components/AuthGuard";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata: Metadata = {
  title: "Reminda Analytics — Executive Command Center",
  description: "Ultra-clean real-time executive dashboard for Reminda / Schedly",
  icons: {
    icon: [
      { url: "/icon.png", type: "image/png" },
      { url: "/favicon.ico" }
    ],
    shortcut: "/icon.png",
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
      <head>
        <link rel="icon" href="/icon.png" sizes="any" />
        <link rel="apple-touch-icon" href="/apple-icon.png" />
      </head>
      <body className={`${inter.className} bg-[#F8FAFC] dark:bg-[#0B0F17] text-slate-900 dark:text-slate-100 antialiased min-h-screen selection:bg-blue-100 dark:selection:bg-blue-900 selection:text-blue-900 dark:selection:text-blue-100 transition-colors duration-300`}>
        <ThemeProvider>
          <AuthProvider>
            <AuthGuard>
              <div className="flex min-h-screen">
                <Sidebar />
                <div className="flex-1 flex flex-col min-h-screen overflow-x-hidden">
                  {children}
                </div>
              </div>
            </AuthGuard>
          </AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
