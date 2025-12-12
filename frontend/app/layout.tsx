import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/providers/themeProvider";
import { headers } from 'next/headers';
import WalletProvider from "@/lib/walletProvider";


const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "ChainSkills",
  description: "Games for all, all for games",
};

export default async function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const headersObj = await headers()
  const cookies = headersObj.get('cookie')
  
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${geistSans.variable} ${geistMono.variable} antialiased`}>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange >
          <WalletProvider cookies={cookies}>
            <div className="body">
              {children}
            </div>
          </WalletProvider>
        </ThemeProvider>
      </body>
    </html >
  );
}
