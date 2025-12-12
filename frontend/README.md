# CeloPOSh - Frontend

A web3-powered gaming hub frontend built with **Next.js**, **TypeScript**, and **Tailwind CSS**. Connect your wallet, play games, and earn cryptocurrency rewards on the Celo blockchain.

## Features

- 🎮 **Multi-Game Platform** - Host and play various blockchain games
- 🔗 **Web3 Integration** - Seamless wallet connectivity (Celo network)
- 💰 **Earn & Stake** - Play for fun, earn OCT tokens
- 📊 **Live Leaderboard** - Track player rankings and XP
- ⚡ **Daily Power-ups** - Claim boosts to enhance gameplay
- 🎯 **Pong Game** - Featured arcade-style game with blockchain rewards

## Tech Stack

- **Framework**: Next.js 14
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Web3**: Wallet integration for Celo blockchain
- **State Management**: React Hooks & Context API

## Getting Started

### Prerequisites
- Node.js 18+ 
- pnpm or npm

### Installation

```bash
# Install dependencies
pnpm install

# Run development server
pnpm run dev

# Build for production
pnpm run build

# Start production server
pnpm start
```

The application will be available at `http://localhost:3000`

## Project Structure

```
frontend/
├── app/              # Next.js app directory
├── components/       # Reusable React components
│   ├── pong/        # Pong game components
│   ├── commons/     # Common components (navbar)
│   ├── ui/          # UI primitives
│   └── providers/   # Context providers
├── lib/             # Utilities & configurations
├── pages/           # Page components
├── types/           # TypeScript type definitions
└── public/          # Static assets
```

## Game Features

### Pong
- Classic arcade gameplay with web3 integration
- Stake OCT tokens for competitive matches
- Real-time leaderboard tracking
- Power-up system for enhanced performance

## Contributing

This is part of the CeloPOSh ecosystem. For contribution guidelines, see the main repository.

## License

MIT
