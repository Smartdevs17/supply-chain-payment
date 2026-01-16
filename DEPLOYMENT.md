# Deployment Record

## Base Sepolia Testnet

### Deployment Details
- **Network**: Base Sepolia (Chain ID: 84532)

#### 1. SupplyChainPayment
- **Contract Address**: `0x539653dd4b32F34A8a319FCE7963D60Aa78040a1`
- **Deployer Address**: `0x575109e921C6d6a1Cb7cA60Be0191B10950AfA6C`
- **Deployment Date**: 2026-01-16

#### 2. SupplierRegistry
- **Contract Address**: `0xD6A411ABaA95f017961083583cCbECbB07e8BD30`
- **Deployer Address**: `0x575109e921C6d6a1Cb7cA60Be0191B10950AfA6C`
- **Deployment Date**: 2026-01-16
- **Transaction Hash**: (Check BaseScan for details)

### Contract Configuration
- **Platform Fee**: 2% (default)
- **Compiler Version**: 0.8.20
- **Optimizer**: Enabled (200 runs)

### Verification
To verify the contracts on BaseScan:
```bash
# SupplyChainPayment
npx hardhat verify --network baseSepolia 0x539653dd4b32F34A8a319FCE7963D60Aa78040a1

# SupplierRegistry
npx hardhat verify --network baseSepolia 0xD6A411ABaA95f017961083583cCbECbB07e8BD30
```

### Contract Links
- **SupplyChainPayment**: https://sepolia.basescan.org/address/0x539653dd4b32F34A8a319FCE7963D60Aa78040a1
- **SupplierRegistry**: https://sepolia.basescan.org/address/0xD6A411ABaA95f017961083583cCbECbB07e8BD30
- **Network Explorer**: https://sepolia.base.org

### Next Steps
1. ✅ Contract deployed successfully
2. ⏳ Verify contract on BaseScan
3. ⏳ Test contract functions on testnet
4. ⏳ Integrate with frontend
5. ⏳ Deploy to Base mainnet (when ready)

### Environment Variables Required
```
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASESCAN_API_KEY=<your-api-key>
PRIVATE_KEY=<your-private-key>
```

### Important Notes
- Contract is deployed on testnet for testing purposes
- Ensure sufficient ETH balance for gas fees
- Keep private keys secure and never commit to repository
- Test all functions thoroughly before mainnet deployment
