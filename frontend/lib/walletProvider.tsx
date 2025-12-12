'use client'

import { wagmiAdapter } from './utils'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { createAppKit } from '@reown/appkit/react'
import { baseSepolia, base } from '@reown/appkit/networks'
import { cookieToInitialState, WagmiProvider, type Config } from 'wagmi'

const queryClient = new QueryClient()


const metadata = {
  name: 'Chainskill Games',
  description: 'Games for all , all for Games',
  url: 'https://chainskills-mauve.vercel.app',
  icons: ['https://avatars.githubusercontent.com/u/179229932']
}

createAppKit({
  adapters: [wagmiAdapter],
  projectId: process.env.NEXT_PUBLIC_PROJECT_ID!,
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