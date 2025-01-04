// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BondingCurveWithDAO is AccessControl, ReentrancyGuard {
    // Define roles
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    // State variables
    uint256 public totalSupply; // Tracks the total token supply
    uint256 public reserveBalance; // Tracks the ETH reserve balance
    uint256 public targetLiquidity; // Threshold to trigger liquidity addition
    uint256 public feePercentage; // Transaction fee in basis points (e.g., 200 = 2%)
    bool public feesEnabled = false; // Toggle for enabling/disabling fees
    uint256 public reserveRatio = 5000; // Reserve ratio in basis points (default: 50%)
    address public uniswapRouter; // Address of the Uniswap V2 router
    address public liquidityToken; // Token to pair with for liquidity (e.g., WETH or USDC)
    address public liquidityRecipient; // Address to receive LP tokens
    address public governance; // Shared governance contract
    uint256 public daoQuorum; // Minimum token quorum (in basis points) required for DAO decisions
    bool public lockedLiquidity;

    mapping(address => uint256) public balances; // Tracks token balances for each address

    // Events
    event TokensMinted(address indexed buyer, uint256 amount, uint256 cost);
    event TokensBurned(address indexed seller, uint256 amount, uint256 reward);
    event LiquidityAdded(uint256 tokenAmount, uint256 ethAmount);
    event ReserveRatioUpdated(uint256 oldRatio, uint256 newRatio);
    event FeeUpdated(uint256 oldFee, uint256 newFee);

    constructor(
        address _uniswapRouter,
        address _liquidityToken,
        address _governance,
        uint256 _targetLiquidity,
        uint256 _daoQuorum,
        bool _lockedLiquidity
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GOVERNANCE_ROLE, _governance);

        uniswapRouter = _uniswapRouter;
        liquidityToken = _liquidityToken;
        governance = _governance;
        targetLiquidity = _targetLiquidity;
        liquidityRecipient = msg.sender; // Default recipient of LP tokens is the contract owner
        daoQuorum = _daoQuorum; // Initialize DAO quorum
        lockedLiquidity = _lockedLiquidity; // Initialize locked liquidity
    }

    /**
     * @dev Allows users to buy tokens based on the bonding curve price.
     * @param _amount Amount of tokens to purchase.
     * @param _maxCost Maximum acceptable cost for the transaction.
     */
    function buy(uint256 _amount, uint256 _maxCost) external payable nonReentrant {
        uint256 cost = calculatePurchaseCost(_amount);
        uint256 finalCost = feesEnabled ? cost + (cost * feePercentage / 10000) : cost;

        require(finalCost <= _maxCost, "Slippage too high");
        require(msg.value >= finalCost, "Insufficient ETH sent");

        totalSupply += _amount;
        reserveBalance += msg.value;
        balances[msg.sender] += _amount;

        emit TokensMinted(msg.sender, _amount, finalCost);

        // Trigger liquidity addition if target reserve is reached
        if (reserveBalance >= targetLiquidity) {
            addLiquidity(500); // Default 5% slippage for liquidity addition
        }

        // Refund any excess ETH
        if (msg.value > finalCost) {
            payable(msg.sender).transfer(msg.value - finalCost);
        }
    }

    /**
     * @dev Allows users to sell tokens and receive ETH based on the bonding curve reward.
     * @param _amount Amount of tokens to sell.
     * @param _minReward Minimum acceptable reward for the transaction.
     */
    function sell(uint256 _amount, uint256 _minReward) external nonReentrant {
        require(balances[msg.sender] >= _amount, "Insufficient token balance");

        uint256 reward = calculateSellReward(_amount);
        uint256 finalReward = feesEnabled ? reward - (reward * feePercentage / 10000) : reward;

        require(finalReward >= _minReward, "Slippage too high");

        totalSupply -= _amount;
        reserveBalance -= reward;
        balances[msg.sender] -= _amount;

        emit TokensBurned(msg.sender, _amount, finalReward);

        // Transfer ETH to the seller
        payable(msg.sender).transfer(finalReward);
    }

    /**
     * @dev Calculates the cost of purchasing tokens based on the bonding curve.
     */
    function calculatePurchaseCost(uint256 _amount) public view returns (uint256) {
        uint256 newSupply = totalSupply + _amount;
        uint256 cost = ((newSupply ** 2 - totalSupply ** 2) * 1 ether) / (reserveRatio * 10000);
        return cost;
    }

    /**
     * @dev Calculates the reward for selling tokens based on the bonding curve.
     */
    function calculateSellReward(uint256 _amount) public view returns (uint256) {
        uint256 newSupply = totalSupply - _amount;
        uint256 reward = ((totalSupply ** 2 - newSupply ** 2) * 1 ether) / (reserveRatio * 10000);
        return reward;
    }

    /**
     * @dev Internal function to add liquidity to Uniswap with customizable slippage tolerance.
     * @param _slippageTolerance Slippage tolerance in basis points (e.g., 500 = 5%).
     */
    function addLiquidity(uint256 _slippageTolerance) internal {
        uint256 ethAmount = reserveBalance / 2; // Use half of the reserve for liquidity
        uint256 tokenAmount = totalSupply / 2; // Pair with equivalent token amount

        reserveBalance -= ethAmount;

        IUniswapV2Router02 router = IUniswapV2Router02(uniswapRouter);
        address factory = router.factory();
        address pair = IUniswapV2Factory(factory).getPair(address(this), liquidityToken);

        require(pair == address(0), "Liquidity pool already exists");

        // Add liquidity to Uniswap
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            (tokenAmount * (10000 - _slippageTolerance)) / 10000, // Minimum tokens
            (ethAmount * (10000 - _slippageTolerance)) / 10000,   // Minimum ETH
            lockedLiquidity ? address(this) : liquidityRecipient, // Lock liquidity if required
            block.timestamp
        );

        emit LiquidityAdded(tokenAmount, ethAmount);
    }

    /**
     * @dev Updates the protocol fee. Can only be called by the governance contract.
     * @param _newFee New protocol fee in basis points.
     */
    function updateProtocolFee(uint256 _newFee) external onlyRole(GOVERNANCE_ROLE) {
        require(_newFee <= 1000, "Fee exceeds max limit");
        emit FeeUpdated(feePercentage, _newFee);
        feePercentage = _newFee;
    }

    /**
     * @dev Implements fee redistribution. Can only be called by the governance contract.
     */
    function redistributeFees() external onlyRole(GOVERNANCE_ROLE) {
        // Logic for fee redistribution
    }
}
