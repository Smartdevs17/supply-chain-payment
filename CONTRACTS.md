# Supply Chain Payment Automation - Smart Contract Documentation

## Overview

The `SupplyChainPayment` contract enables automated, milestone-based payments between buyers and suppliers on Base Ethereum. Funds are held in escrow and released automatically when predefined milestones are completed and approved.

## Contract Address

**Base Sepolia**: TBD (deploy with `npm run deploy:sepolia`)

## Core Features

- ✅ Supplier registration and verification
- ✅ Escrow-based order creation
- ✅ Milestone-based payment releases
- ✅ Automated payment distribution
- ✅ Dispute resolution mechanism
- ✅ Platform fee collection (1% default)

## Functions

### Supplier Management

#### `registerSupplier(string _name, string _contactInfo)`
Register as a supplier on the platform.
- **Access**: Public
- **Parameters**:
  - `_name`: Supplier business name
  - `_contactInfo`: Contact information
- **Emits**: `SupplierRegistered`

#### `verifySupplier(address _supplier)`
Verify a registered supplier (owner only).
- **Access**: Owner only
- **Parameters**:
  - `_supplier`: Address of supplier to verify
- **Emits**: `SupplierVerified`

### Order Management

#### `createOrder(address _supplier, string _productDescription)`
Create a new order with escrow payment.
- **Access**: Public (payable)
- **Parameters**:
  - `_supplier`: Verified supplier address
  - `_productDescription`: Description of goods/services
- **Value**: Order amount in ETH
- **Emits**: `OrderCreated`

#### `addMilestone(uint256 _orderId, string _description, uint256 _paymentPercentage)`
Add a payment milestone to an order.
- **Access**: Buyer only
- **Parameters**:
  - `_orderId`: Order ID
  - `_description`: Milestone description
  - `_paymentPercentage`: Percentage of total (0-100)
- **Emits**: `MilestoneAdded`

#### `startOrder(uint256 _orderId)`
Start order execution (milestones must total 100%).
- **Access**: Buyer only
- **Parameters**:
  - `_orderId`: Order ID

#### `completeMilestone(uint256 _orderId, uint256 _milestoneIndex)`
Mark milestone as completed.
- **Access**: Supplier only
- **Parameters**:
  - `_orderId`: Order ID
  - `_milestoneIndex`: Milestone index
- **Emits**: `MilestoneCompleted`

#### `approveMilestone(uint256 _orderId, uint256 _milestoneIndex)`
Approve completed milestone and release payment.
- **Access**: Buyer only
- **Parameters**:
  - `_orderId`: Order ID
  - `_milestoneIndex`: Milestone index
- **Emits**: `MilestoneApproved`, `PaymentReleased`, potentially `OrderCompleted`

### Dispute Management

#### `raiseDispute(uint256 _orderId, string _reason)`
Raise a dispute for an in-progress order.
- **Access**: Buyer or Supplier
- **Parameters**:
  - `_orderId`: Order ID
  - `_reason`: Dispute reason
- **Emits**: `DisputeRaised`

#### `resolveDispute(uint256 _orderId, bool _inFavorOfSupplier)`
Resolve a dispute (owner only).
- **Access**: Owner only
- **Parameters**:
  - `_orderId`: Order ID
  - `_inFavorOfSupplier`: True to pay supplier, false to refund buyer
- **Emits**: `DisputeResolved`

#### `cancelOrder(uint256 _orderId)`
Cancel an order before it starts.
- **Access**: Buyer only
- **Parameters**:
  - `_orderId`: Order ID
- **Emits**: `OrderCancelled`

### Platform Management

#### `withdrawPlatformFees()`
Withdraw accumulated platform fees.
- **Access**: Owner only

#### `updatePlatformFee(uint256 _newFeePercentage)`
Update platform fee percentage (max 10%).
- **Access**: Owner only
- **Parameters**:
  - `_newFeePercentage`: New fee percentage

### View Functions

#### `getSupplier(address _supplier) returns (Supplier)`
Get supplier details.

#### `getOrder(uint256 _orderId) returns (...)`
Get order details.

#### `getMilestone(uint256 _orderId, uint256 _milestoneIndex) returns (Milestone)`
Get milestone details.

#### `getMilestoneCount(uint256 _orderId) returns (uint256)`
Get number of milestones for an order.

#### `getBuyerOrders(address _buyer) returns (uint256[])`
Get all order IDs for a buyer.

#### `getSupplierOrders(address _supplier) returns (uint256[])`
Get all order IDs for a supplier.

## Events

- `SupplierRegistered(address indexed supplier, string name, uint256 timestamp)`
- `SupplierVerified(address indexed supplier, uint256 timestamp)`
- `OrderCreated(uint256 indexed orderId, address indexed buyer, address indexed supplier, uint256 amount)`
- `MilestoneAdded(uint256 indexed orderId, uint256 milestoneIndex, string description, uint256 percentage)`
- `MilestoneCompleted(uint256 indexed orderId, uint256 milestoneIndex, uint256 timestamp)`
- `MilestoneApproved(uint256 indexed orderId, uint256 milestoneIndex, uint256 paymentAmount)`
- `PaymentReleased(uint256 indexed orderId, address indexed supplier, uint256 amount)`
- `DisputeRaised(uint256 indexed orderId, address indexed raisedBy, string reason)`
- `DisputeResolved(uint256 indexed orderId, address indexed resolvedBy, bool inFavorOfSupplier)`
- `OrderCompleted(uint256 indexed orderId, uint256 timestamp)`
- `OrderCancelled(uint256 indexed orderId, uint256 refundAmount)`

## Usage Example

```javascript
// 1. Supplier registers
await contract.registerSupplier("ACME Corp", "contact@acme.com");

// 2. Owner verifies supplier
await contract.verifySupplier(supplierAddress);

// 3. Buyer creates order with 1 ETH
await contract.createOrder(supplierAddress, "100 widgets", { value: ethers.parseEther("1") });

// 4. Buyer adds milestones
await contract.addMilestone(0, "Design approval", 30);
await contract.addMilestone(0, "Prototype delivery", 40);
await contract.addMilestone(0, "Final delivery", 30);

// 5. Buyer starts order
await contract.startOrder(0);

// 6. Supplier completes milestone
await contract.completeMilestone(0, 0);

// 7. Buyer approves and payment is released
await contract.approveMilestone(0, 0);
```

## Security Features

- ✅ ReentrancyGuard on payment functions
- ✅ Access control modifiers
- ✅ Input validation
- ✅ Safe ETH transfers
- ✅ Escrow mechanism

## Gas Optimization

- Efficient storage patterns
- Minimal external calls
- Optimized loops

## License

MIT
<- Added validation Validated -->
