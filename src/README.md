## **Overview**
This system includes three interconnected contracts: 
1. **Governance Contract**: Manages proposals, voting, and execution for protocol changes.
2. **Bonding Curve Contract**: Implements a bonding curve with DAO-based fee governance.
3. **Factory Contract**: Deploys bonding curve instances and reuses the governance system.

## **Contract Relationships**

### **Governance**
- Shared between the factory and bonding curve contracts.
- Handles proposals for updating protocol fees or quorum.

### **Bonding Curve**
- Each deployed curve integrates with the governance system.
- Protocol fees are governed via DAO proposals.

### **Factory**
- Deploys bonding curves.
- Connects deployed bonding curves to the shared governance system.

# **Bonding Curve Factory with Admin and DAO Governance**

## **Overview**
This factory contract allows deploying bonding curve tokens with an initial admin. The governance can be toggled to DAO mode, where a governance token is used to manage all decisions, including protocol fee and quorum updates.

---

## **Features**

### **1. Initial Admin Governance**
- The factory is initialized with an admin who can control settings like protocol fees and fee recipient addresses.

### **2. DAO Governance**
- The admin can transfer control to the DAO.
- Once DAO mode is enabled:
  - Protocol fees and quorum changes require DAO proposals and voting.
  - The admin loses control over governance.

### **3. Flexible Proposal System**
- DAO token holders can create proposals for:
  - Updating protocol fees.
  - Changing the DAO quorum.

### **4. Deployment of Bonding Curves**
- Users can deploy bonding curve tokens, which inherit the factory's configurations.

---

## **Functions**

### **Admin Functions**
- `toggleGovernance()`: Switches governance between admin and DAO.
- `updateProtocolFeeRecipient(address _newRecipient)`: Updates the protocol fee recipient.

### **DAO Functions**
- `createProposal(string _description, uint256 _newFee, uint256 _newQuorum)`: Creates a proposal for fee or quorum updates.
- `vote(uint256 _proposalId, bool _support)`: Votes on a proposal.
- `executeProposal(uint256 _proposalId)`: Executes a proposal if voting conditions are met.

### **User Functions**
- `deployBondingCurve(...)`: Deploys a new bonding curve token.


# **Bonding Curve with Enhanced DAO Governance**

## **Overview**
This smart contract implements a bonding curve mechanism with dynamic token pricing and a flexible governance structure. It supports both admin-controlled and DAO-based governance modes, allowing for centralized or decentralized decision-making. The contract also integrates with Uniswap for automatic liquidity addition.

---

## **Features**

### **1. Bonding Curve**
- Implements a quadratic bonding curve for dynamic token pricing.
- **Token Sale Launch**: Tokens are initially sold directly through the bonding curve, allowing users to purchase tokens as soon as the curve is deployed.
- **Liquidity Addition**: Once a target amount of tokens or ETH is reached, liquidity is automatically added to a DEX like Uniswap, enabling trading on the open market.
- **Locked Liquidity**: If the `lockedLiquidity` parameter is set to true, the liquidity added to Uniswap is locked, preventing it from being withdrawn.
- Token prices increase with supply growth, incentivizing early participation.
- Token sell rewards decrease with supply reduction, discouraging mass sell-offs.

### **2. Governance System**
- **Admin-Controlled Governance**: 
  - The contract starts with admin governance.
  - Admin can manage fees, liquidity thresholds, and other configurations.
- **DAO-Based Governance**:
  - Once switched to DAO mode, all decisions are governed by token-weighted voting.
  - Includes the ability to update fees, reserve ratio, quorum, and toggle governance mode.

### **3. DAO Quorum Management**
- The DAO quorum determines the minimum token weight required to approve proposals.
- Admin or the DAO can dynamically update the quorum (expressed in basis points).

### **4. Slippage Protection**
- Slippage thresholds for token purchases, sales, and liquidity additions.
- Protects users from adverse price movements during volatile market conditions.

### **5. Fee Management**
- Transaction fees can be toggled on/off and adjusted (max: 10%).
- Fee proposals are subject to DAO voting when in DAO mode.

### **6. Uniswap Liquidity Integration**
- **Automatic Liquidity Addition**: Liquidity is added to Uniswap when the reserve balance reaches a target threshold, ensuring that the tokens can be traded on the open market.
- Customizable slippage tolerance for liquidity additions to ensure optimal pricing.

### **7. Security Features**
- Prevents accidental ETH transfers using fallback and receive functions.
- Implements the `nonReentrant` modifier to protect against reentrancy attacks.
- Voting mechanisms use snapshots of token balances for fairness.

### **8. New Features**
- **Security Enhancements**: Reentrancy guards and access control using OpenZeppelin's `AccessControl`.
- **Functionality Enhancements**: Fee redistribution mechanism, enhanced proposal system for complex governance actions, functions to check proposal status.

---

## **How to Get Tokens from the Bonding Curve**

1. **Understand the Bonding Curve**:
   - The bonding curve dynamically prices tokens based on their supply.
   - As the total supply increases, the price of new tokens also increases.

2. **Buying Tokens**:
   - Call the `buy` function with the following parameters:
     - `_amount`: The number of tokens you want to buy.
     - `_maxCost`: The maximum amount of ETH you are willing to spend.
   - Example:
     ```solidity
     bondingCurve.buy(100, 5 ether);
     ```
   - The contract calculates the cost using the bonding curve formula:
     \[
     \text{Cost} = \frac{{\left(NewSupply^2 - TotalSupply^2\right) \cdot 1 \text{ ETH}}}{{ReserveRatio \cdot 10000}}
     \]

3. **Liquidity Addition**:
   - Once the reserve balance reaches the target liquidity threshold, the contract automatically adds liquidity to Uniswap, allowing for open market trading.
   - This process includes slippage protection to ensure optimal pricing.

---

## **How to Initialize the Bonding Curve**

### **Deployment Steps**

1. **Prerequisites**:
   - Ensure you have the following:
     - Address of the Uniswap V2 Router (`_uniswapRouter`).
     - Address of the liquidity token to pair with (`_liquidityToken`), e.g., WETH or USDC.
     - Address of the governance token (`_governanceToken`).
     - Target liquidity threshold (`_targetLiquidity`), e.g., 100 ETH.
     - DAO quorum (`_daoQuorum`), e.g., 5000 for 50%.

2. **Deploy the Contract**:
   ```solidity
   BondingCurveWithEnhancedDAO bondingCurve = new BondingCurveWithEnhancedDAO(
       uniswapRouterAddress,
       liquidityTokenAddress,
       governanceTokenAddress,
       100 ether, // Target liquidity
       5000       // DAO quorum (50%)
   );
   ```


# **Governance Contract Documentation**

## **Overview**
The `Governance` contract is a modular system for managing DAO-based decision-making. It facilitates proposals, voting, and execution of critical protocol changes such as updating protocol fees and quorum thresholds. The contract integrates with a governance token (`ERC20Votes`) to ensure decentralized and fair voting.

---

## **Key Features**
1. **Proposals and Voting**:
   - Allows DAO token holders to create and vote on proposals.
   - Supports token-weighted voting with snapshots to prevent double voting.
2. **Quorum Management**:
   - DAO quorum can be updated via proposals to ensure governance reflects the token holder distribution.
3. **Emergency Recovery**:
   - Includes an emergency override mechanism triggered by the factory in critical situations.
4. **Transparency**:
   - Events are emitted for all major actions, including proposal creation, voting, and execution.

---

## **Contract Variables**

| **Variable**        | **Type**          | **Description**                                                                 |
|----------------------|-------------------|---------------------------------------------------------------------------------|
| `factory`           | `address`         | Address of the Bonding Curve Factory contract.                                  |
| `daoToken`          | `address`         | Address of the governance token used for DAO voting.                           |
| `daoQuorum`         | `uint256`         | Quorum required for proposals, in basis points (e.g., 5000 = 50%).             |
| `nextProposalId`    | `uint256`         | Incremental ID used to track proposals.                                        |
| `proposals`         | `mapping`         | Stores proposal details by ID.                                                 |
| `hasVoted`          | `mapping`         | Tracks if a specific address has voted on a given proposal.                    |

---

## **Structures**

### **Proposal**
| **Variable**     | **Type**          | **Description**                                              |
|-------------------|-------------------|--------------------------------------------------------------|
| `description`    | `string`          | Description of the proposal.                                 |
| `newFee`         | `uint256`         | Proposed new protocol fee (optional).                        |
| `newQuorum`      | `uint256`         | Proposed new DAO quorum (optional).                          |
| `endTime`        | `uint256`         | Proposal voting deadline (Unix timestamp).                   |
| `snapshotId`     | `uint256`         | Snapshot ID for token balances during the proposal.           |
| `votesFor`       | `uint256`         | Total votes in favor of the proposal.                        |
| `votesAgainst`   | `uint256`         | Total votes against the proposal.                            |
| `executed`       | `bool`            | Whether the proposal has been executed.                      |

---

## **Events**

| **Event**                 | **Parameters**                                                                                   | **Description**                                     |
|---------------------------|--------------------------------------------------------------------------------------------------|---------------------------------------------------|
| `ProposalCreated`         | `uint256 proposalId`, `string description`, `uint256 endTime`, `uint256 snapshotId`             | Emitted when a new proposal is created.           |
| `ProposalExecuted`        | `uint256 proposalId`, `bool approved`                                                           | Emitted when a proposal is executed.              |
| `ProposalRejected`        | `uint256 proposalId`                                                                            | Emitted when a proposal fails or is rejected.     |
| `QuorumUpdated`           | `uint256 oldQuorum`, `uint256 newQuorum`                                                        | Emitted when the DAO quorum is updated.           |
| `EmergencyTriggered`      | `address triggeredBy`                                                                           | Emitted when the factory triggers emergency mode. |

---

## **Functions**

### **1. `createProposal`**
Creates a new proposal for updating the protocol fee or DAO quorum.

| **Parameter**      | **Type**    | **Description**                                                       |
|---------------------|-------------|-----------------------------------------------------------------------|
| `_description`     | `string`    | Description of the proposal.                                          |
| `_newFee`          | `uint256`   | New protocol fee to set (set to `0` if not changing).                 |
| `_newQuorum`       | `uint256`   | New DAO quorum to set (set to `0` if not changing).                   |

**Requirements**:
- Must hold governance tokens.
- Only one parameter can be updated per proposal.

**Example**:
```solidity
governance.createProposal("Update protocol fee to 3%", 300, 0);
```

### 2. Vote
Casts a vote on a proposal.

| **Parameter**   | **Type**  | **Description**                             |
|-----------------|-----------|---------------------------------------------|
| `_proposalId`   | `uint256` | ID of the proposal to vote on.              |
| `_support`      | `bool`    | `true` for a positive vote, `false` for a negative vote. |

**Requirements**:
- Must hold governance tokens at the snapshot for the proposal.
- Cannot vote more than once on the same proposal.

**Example**:
```solidity
governance.vote(1, true);
```

### 3. Execute Proposal
Executes a proposal after the voting period ends.

| **Parameter**   | **Type**  | **Description**                             |
|-----------------|-----------|---------------------------------------------|
| `_proposalId`   | `uint256` | ID of the proposal to execute.              |

**Requirements**:
- Voting period must have ended.
- Proposal must not have been executed.
- Proposal must meet quorum and pass with a majority vote.

**Example**:
```solidity
governance.executeProposal(1);
```

### 4. Trigger Emergency
Triggers emergency mode, allowing the factory to override governance in extreme situations.

**Requirements**:
- Only callable by the factory.

**Example**:
```solidity
governance.triggerEmergency();
```

### Helper Functions

#### Proposal Status
- `isVotingOpen(uint256 proposalId)`: Returns whether the voting period is still active.
- `hasProposalPassed(uint256 proposalId)`: Returns whether a proposal has passed based on quorum and majority.

### Security Features

- **Snapshot Voting**: Prevents double voting by using ERC20Votes for balance snapshots at the proposal creation time.
- **Time-Locked Execution**: Proposals cannot be executed before the voting period ends.
- **Emergency Recovery**: Allows the factory to trigger emergency mode for recovery in critical situations.

### Usage Examples

**Create a Proposal**
```solidity
governance.createProposal("Update protocol fee to 2%", 200, 0);
```

**Vote on a Proposal**
```solidity
governance.vote(0, true); // Vote in favor of proposal ID 0
```

**Execute a Proposal**
```solidity
governance.executeProposal(0); // Execute proposal ID 0
```

**Trigger Emergency Mode**
```solidity
governance.triggerEmergency();
```

### Conclusion
The Governance contract provides a secure, transparent, and modular system for managing DAO-based decisions. Its integration with ERC20Votes ensures fairness and decentralization, while the emergency mechanism allows recovery in extreme cases.


# Usage Example

## Usage Examples for Bonding Curve System

Below are usage examples for deploying and managing bonding curves, updating protocol settings, and interacting with DAO governance.

### Factory Contract Usage

1. **Deploy a Bonding Curve**

   Deploy a new bonding curve through the factory by specifying key parameters like the Uniswap router, liquidity token, governance token, target liquidity, and DAO quorum.

   ```solidity
   factory.deployBondingCurve(
       uniswapRouterAddress,      // Address of the Uniswap V2 router
       liquidityTokenAddress,     // Address of the token to pair with (e.g., WETH or USDC)
       governanceTokenAddress,    // Address of the governance token for DAO control
       100 ether,                 // Target liquidity (ETH reserve threshold)
       5000                       // DAO quorum in basis points (50%)
   );
   ```

2. **Update Protocol Fee**

   The protocol fee can be updated through the shared governance system.

   **Step 1: Create a Proposal**

   A proposal must be created in the Governance contract to update the protocol fee.

   ```solidity
   governance.createProposal("Update protocol fee to 1.5%", 150, 0); // 1.5% fee
   ```

   **Step 2: Vote on the Proposal**

   Token holders vote on the proposal using their governance tokens.

   ```solidity
   governance.vote(proposalId, true); // Vote in favor of the proposal
   ```

   **Step 3: Execute the Proposal**

   After the voting period ends, the proposal can be executed to apply the changes.

   ```solidity
   governance.executeProposal(proposalId);
   ```

3. **Update Protocol Fee Recipient**

   The recipient of the protocol fee can also be updated through DAO governance.

   **Step 1: Create a Proposal**

   Create a proposal to update the fee recipient (e.g., as part of a custom proposal logic).

   ```solidity
   governance.createProposal("Update fee recipient", 0, 0); // Include recipient change logic
   ```

   **Step 2: Vote and Execute**

   Follow the same steps as updating the protocol fee: vote on the proposal and execute it after the voting period ends.

4. **Retrieve Deployed Bonding Curves**

   Retrieve a list of bonding curves deployed by a specific address or all bonding curves deployed through the factory.

   **Retrieve by Specific Deployer**

   ```solidity
   address[] memory deployerCurves = factory.getDeployedBondingCurves(deployerAddress);
   ```

   **Retrieve All Bonding Curves**

   ```solidity
   address[] memory allCurves = factory.getAllBondingCurves();
   ```

### Bonding Curve Contract Usage

1. **Buy Tokens**

   Buy tokens from the bonding curve by sending ETH. Specify the number of tokens to purchase and the maximum acceptable cost to protect against slippage.

   ```solidity
   bondingCurve.buy(
       100,    // Amount of tokens to purchase
       1 ether // Maximum cost in ETH
   );
   ```

2. **Sell Tokens**

   Sell tokens back to the bonding curve and receive ETH. Specify the number of tokens to sell and the minimum acceptable reward to protect against slippage.

   ```solidity
   bondingCurve.sell(
       50,      // Amount of tokens to sell
       0.5 ether // Minimum acceptable reward in ETH
   );
   ```

3. **Add Liquidity to Uniswap**

   Liquidity is added automatically when the ETH reserve meets or exceeds the target liquidity threshold. This process includes slippage protection and is handled internally by the bonding curve contract.

### Governance Contract Usage

1. **Create a Proposal**

   A proposal can be created for various changes, such as updating the protocol fee or DAO quorum.

   ```solidity
   governance.createProposal(
       "Update DAO quorum to 60%", // Proposal description
       0,                          // Protocol fee update (set to 0 if unused)
       6000                        // New quorum value in basis points (60%)
   );
   ```

2. **Vote on a Proposal**

   Vote on a specific proposal using your governance tokens. Votes are token-weighted.

   ```solidity
   governance.vote(proposalId, true); // Vote in favor of the proposal
   ```

3. **Execute a Proposal**

   After the voting period ends, execute the proposal to apply its changes.

   ```solidity
   governance.executeProposal(proposalId);
   ```

4. **Trigger Emergency Mode**

   In case of misconfiguration or critical failures, the factory can trigger emergency mode in the governance system.

   ```solidity
   factory.triggerEmergencyMode();
   ```

### New Features

- **Security Enhancements**: Reentrancy guards and access control using OpenZeppelin's `AccessControl`.
- **Functionality Enhancements**: Fee redistribution mechanism, enhanced proposal system for complex governance actions, functions to check proposal status.
- **Usage**: Use the `redistributeFees` function to distribute collected fees to token holders. Check proposal status using `hasProposalPassed` and `isProposalExecuted`.

# BondingCurveFactory Contract Documentation

## Overview

The `BondingCurveFactory` contract is a smart contract designed to deploy and manage bonding curve contracts. It supports both admin-controlled and DAO-based governance modes, allowing for flexible management of protocol settings and deployment of new bonding curves.
#### Key Features
- **Admin and DAO Governance**: The factory is initialized with an admin who can control settings. Governance can be toggled to DAO mode, where a governance token is used to manage all decisions.
- **Deployment of Bonding Curves**: Users can deploy bonding curve tokens, which inherit the factory's configurations.

#### Functions
- **toggleGovernance**: Switches governance between admin and DAO. Once DAO mode is enabled, the admin loses control over governance.
- **updateProtocolFee**: Updates the global protocol fee. Only callable by DAO governance.
- **updateProtocolFeeRecipient**: Updates the protocol fee recipient address. Only callable by DAO governance.
- **triggerEmergencyMode**: Triggers emergency mode in the shared Governance contract. Only callable by the admin.


## Key Features

- **Admin and DAO Governance**: The factory can operate under an initial admin who has control over settings. Governance can be toggled to DAO mode, where a governance token is used to manage all decisions.
- **Deployment of Bonding Curves**: Users can deploy bonding curve tokens, which inherit the factory's configurations.
- **Protocol Fee Management**: The factory manages a global protocol fee, which can be updated through DAO governance.
- **Emergency Mode**: The factory can trigger an emergency mode in the shared governance contract to handle critical situations.

## Contract Variables

- `admin`: The address of the factory admin.
- `useDAO`: A boolean indicating if DAO governance is active.
- `governance`: The shared governance contract instance.
- `protocolFee`: The global protocol fee in basis points.
- `protocolFeeRecipient`: The address that receives protocol fees.

## Events

- `BondingCurveDeployed`: Emitted when a new bonding curve is deployed.
- `ProtocolFeeUpdated`: Emitted when the protocol fee is updated.
- `ProtocolFeeRecipientUpdated`: Emitted when the protocol fee recipient is updated.
- `GovernanceToggled`: Emitted when governance is toggled between admin and DAO.
- `EmergencyModeTriggered`: Emitted when emergency mode is triggered.

## Functions

### Constructor

Initializes the factory with the following parameters:

- `_protocolFee`: Initial protocol fee in basis points.
- `_protocolFeeRecipient`: Address to receive protocol fees.
- `_daoToken`: Address of the governance token used for shared governance.
- `_initialQuorum`: Initial DAO quorum in basis points.

### toggleGovernance

Toggles governance between admin and DAO. Once DAO governance is active, admin control is disabled.

### deployBondingCurve

Deploys a new Bonding Curve contract with the following parameters:

- `_uniswapRouter`: Address of the Uniswap V2 router.
- `_liquidityToken`: Address of the liquidity token to pair with.
- `_governanceToken`: Address of the governance token for DAO voting.
- `_targetLiquidity`: Threshold reserve balance to trigger liquidity addition.
- `_daoQuorum`: Initial quorum for the Bonding Curve's DAO.

Returns the address of the newly deployed bonding curve contract.

### updateProtocolFee

Updates the global protocol fee. Only callable by DAO governance.

### updateProtocolFeeRecipient

Updates the protocol fee recipient address. Only callable by DAO governance.

### triggerEmergencyMode

Triggers emergency mode in the shared Governance contract. Only callable by the admin.

### getDeployedBondingCurves

Returns all bonding curve contracts deployed by a specific address.

### getAllBondingCurves

Returns all bonding curve contracts deployed through the factory.

## Usage Examples

### Deploy a Bonding Curve

To deploy a new bonding curve, call the `deployBondingCurve` function with the required parameters:

```solidity
factory.deployBondingCurve(
    uniswapRouterAddress,
    liquidityTokenAddress,
    governanceTokenAddress,
    100 ether, // Target liquidity
    5000       // DAO quorum (50%)
);
```

### Update Protocol Fee

To update the protocol fee, create a proposal in the Governance contract and follow the voting process:

```solidity
governance.createProposal("Update protocol fee to 1.5%", 150, 0);
governance.vote(proposalId, true);
governance.executeProposal(proposalId);
```

### Trigger Emergency Mode

In case of an emergency, the admin can trigger emergency mode:

```solidity
factory.triggerEmergencyMode();
```

## Conclusion

The `BondingCurveFactory` contract provides a robust framework for deploying and managing bonding curves with flexible governance options. Its integration with a shared governance system ensures decentralized decision-making and adaptability to various protocol needs.