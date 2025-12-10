import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"
import { base, baseSepolia } from "viem/chains";
import { http } from 'viem';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export const config = getDefaultConfig({
  appName: 'My RainbowKit App',
  projectId: 'YOUR_PROJECT_ID',
  chains: [base, baseSepolia],
   transports: {
    [baseSepolia.id]: http(),
    [base.id]: http(),
  },
  // ssr: true
})