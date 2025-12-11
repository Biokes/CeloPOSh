'use client'

import { wagmiAdapter } from './utils'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { createAppKit } from '@reown/appkit/react'
import { baseSepolia, base } from '@reown/appkit/networks'
import { cookieToInitialState, WagmiProvider, type Config } from 'wagmi'

const queryClient = new QueryClient()


const metadata = {
  name: 'appkit-example',
  description: 'AppKit Example',
  url: 'https://appkitexampleapp.com',
  icons: ['https://avatars.githubusercontent.com/u/179229932']
}

const modal = createAppKit({
  adapters: [wagmiAdapter],
  projectId: "project id",
  networks: [base, baseSepolia],
  defaultNetwork: baseSepolia,
  metadata: metadata,
})

function WalletProvider({ children, cookies }: { children: React.ReactNode; cookies: string | null }) {
  const initialState = cookieToInitialState(wagmiAdapter.wagmiConfig as Config, cookies)

  return (
    <WagmiProvider config={wagmiAdapter.wagmiConfig as Config} initialState={initialState}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </WagmiProvider>
  )
}

export default WalletProvider;