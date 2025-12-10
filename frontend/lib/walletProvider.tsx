"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WagmiProvider } from "wagmi";
import { RainbowKitProvider, lightTheme } from '@rainbow-me/rainbowkit';
import { config } from "./utils";

const queryClient = new QueryClient();

export default function WalletProvider({ children }: {children: React.ReactNode}) { 
    return (
        <WagmiProvider config={config}>
            <QueryClientProvider client={queryClient}>
              <RainbowKitProvider coolMode
                theme={lightTheme({ accentColor: '#045d67', accentColorForeground: 'white' })}> 
                {children}
            </RainbowKitProvider>
          </QueryClientProvider>
        </WagmiProvider> 
    )
}