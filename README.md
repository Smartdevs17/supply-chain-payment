# Supply Chain Payment - Automated Payment System

Blockchain-based supply chain payment system with milestone tracking and escrow on Base network.

## 📊 Project Statistics

- **Commits**: 80+
- **Contracts**: 10
- **Deployed**: 5 contracts on Base Sepolia
- **Test Suites**: 4 (40+ test cases)

## 🚀 Quick Start

```bash
npm install
npx hardhat compile
npx hardhat test
```

## 📝 Contracts

### Deployed (Base Sepolia)
- **SupplyChainToken** - `0x1950165684c38B849186F8b6a5100593EF4733f9`
- **SupplierRegistry** - `0x4775C2b1530Ff7CAD6b3143cfF8fa0e05585c785`
- **ReputationSystem** - `0xDAC9bf1AEd5328B9aB0ad8238D6E7FC41B778a33`
- **ProductCatalog** - `0x2274E10680A92a4BEC4fBfE758A2e73E0145e862`
- **SupplyChainPayment** - `0xC664C097FadE25F9A6bFC20C4490697aA399578C`

### Additional Contracts
- ShippingTracker
- WarehouseRegistry
- InsuranceEscrow
- CustomsCompliance
- LogisticsProvider

## ✨ Features

- ✅ Milestone-based payments
- ✅ Escrow system
- ✅ Supplier verification
- ✅ Reputation tracking
- ✅ Shipping management
- ✅ Warehouse registry
- ✅ Insurance coverage
- ✅ Customs compliance

## 🧪 Testing

```bash
# Run all tests
npm test

# Run specific test
npx hardhat test test/integration.test.js

# With gas reporting
REPORT_GAS=true npm test
```

## 🌐 Deployment

```bash
# Deploy to Base Sepolia
npx hardhat run scripts/deploy-all-smart.js --network baseSepolia

# Deploy to Base Mainnet
npx hardhat run scripts/deploy-all-smart.js --network base
```

## 🔗 Network Info

- **Base Sepolia**: Chain ID 84532
- **Base Mainnet**: Chain ID 8453
- **Explorer**: https://basescan.org

## 📄 License

MIT
