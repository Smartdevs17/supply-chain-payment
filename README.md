# Supply Chain Payment Automation on Base

Automated supply chain payment system with milestone-based payments and escrow functionality.

## Features

- 🔐 Milestone-based automated payments
- 💰 Escrow functionality for secure transactions
- 👥 Supplier registration and verification
- 📊 Real-time order tracking
- ⚖️ Dispute resolution mechanism

## Tech Stack

- **Smart Contracts**: Solidity 0.8.20
- **Framework**: Hardhat
- **Network**: Base Sepolia (testnet) / Base (mainnet)
- **Libraries**: OpenZeppelin Contracts

## Setup

```bash
npm install
cp .env.example .env
# Add your private key and API keys to .env
```

## Compile

```bash
npm run compile
```

## Test

```bash
npm test
npm run test:coverage
npm run test:gas
```

## Deploy

```bash
npm run deploy:sepolia
```

## License

MIT
