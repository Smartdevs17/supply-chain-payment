# Supply Chain Payment Automation on Base

Automated supply chain payment system with milestone-based payments and escrow functionality built on Base Ethereum.

## Features

- 🔐 **Milestone-based Payments**: Define payment milestones with percentage allocations
- 💰 **Escrow Functionality**: Secure fund holding until milestone completion
- 👥 **Supplier Verification**: Owner-verified supplier registration system
- 📊 **Real-time Tracking**: Track order status and payment progress
- ⚖️ **Dispute Resolution**: Built-in dispute mechanism with owner arbitration
- 💸 **Platform Fees**: Configurable platform fee (1% default, max 10%)

## Tech Stack

- **Smart Contracts**: Solidity 0.8.20
- **Framework**: Hardhat
- **Network**: Base Sepolia (testnet) / Base (mainnet)
- **Libraries**: OpenZeppelin Contracts (Ownable, ReentrancyGuard)

## Quick Start

### Installation

```bash
npm install
cp .env.example .env
# Add your PRIVATE_KEY and BASESCAN_API_KEY to .env
```

### Compile

```bash
npm run compile
```

### Test

```bash
npm test
npm run test:coverage
npm run test:gas
```

### Deploy

```bash
# Deploy to Base Sepolia testnet
npm run deploy:sepolia

# Verify on BaseScan
npm run verify
```

## Documentation

- 📖 [Smart Contract Documentation](./CONTRACTS.md) - Detailed function reference
- 🏗️ [Architecture Overview](./ARCHITECTURE.md) - System design and patterns

## Project Structure

```
supply-chain-payment/
├── contracts/
│   └── SupplyChainPayment.sol    # Main contract
├── scripts/
│   └── deploy.js                  # Deployment script
├── test/
│   └── SupplyChainPayment.test.js # Test suite
├── hardhat.config.js              # Hardhat configuration
└── README.md
```

## Usage Example

```javascript
// 1. Register as supplier
await contract.registerSupplier("ACME Corp", "contact@acme.com");

// 2. Create order (buyer)
await contract.createOrder(supplierAddress, "100 widgets", {
  value: ethers.parseEther("1.0")
});

// 3. Add milestones (buyer)
await contract.addMilestone(orderId, "Design approval", 30);
await contract.addMilestone(orderId, "Delivery", 70);

// 4. Start order
await contract.startOrder(orderId);

// 5. Complete & approve milestones
await contract.completeMilestone(orderId, 0); // Supplier
await contract.approveMilestone(orderId, 0);  // Buyer - payment released!
```

## Network Information

### Base Sepolia Testnet
- **Chain ID**: 84532
- **RPC URL**: https://sepolia.base.org
- **Explorer**: https://sepolia.basescan.org
- **Faucet**: https://www.coinbase.com/faucets/base-ethereum-goerli-faucet

### Base Mainnet
- **Chain ID**: 8453
- **RPC URL**: https://mainnet.base.org
- **Explorer**: https://basescan.org

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT

## Security

This contract has not been audited. Use at your own risk in production environments.

