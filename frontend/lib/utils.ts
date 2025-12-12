import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"
import { cookieStorage, createStorage } from '@wagmi/core'
import { WagmiAdapter } from '@reown/appkit-adapter-wagmi'
import { baseSepolia, base } from '@reown/appkit/networks'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// export const config = getDefaultConfig({
//   appName: 'My RainbowKit App',
//   projectId: 'YOUR_PROJECT_ID',
//   chains: [base, baseSepolia],
//   ssr:true
// })

export const wagmiAdapter = new WagmiAdapter({
  storage: createStorage({
    storage: cookieStorage
  }),
  ssr: true,
  projectId: "project id",
  networks: [base, baseSepolia]
})

export const config = wagmiAdapter.wagmiConfig