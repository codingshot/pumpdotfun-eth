// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.28 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { BondingCurveWithDAO } from "../src/BondingCurveWithDAO.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract BondingCurveWithDAOTest is Test {
    BondingCurveWithDAO bondingCurve;
    address uniswapRouter = address(0x1);
    address liquidityToken = address(0x2);
    address governance = address(this); // Use the test contract as governance for simplicity
    uint256 targetLiquidity = 100 ether;
    uint256 daoQuorum = 5000;

    function setUp() public {
        bondingCurve = new BondingCurveWithDAO(
            uniswapRouter,
            liquidityToken,
            governance,
            targetLiquidity,
            daoQuorum
        );
    }

    function testBuyTokens() public {
        uint256 amount = 100;
        uint256 maxCost = 1 ether;

        bondingCurve.buy{value: maxCost}(amount, maxCost);
        assertEq(bondingCurve.balances(address(this)), amount, "Token purchase failed");
    }

    function testBuyTokensExcessEthRefunded() public {
        uint256 amount = 100;
        uint256 maxCost = 1 ether;

        uint256 initialBalance = address(this).balance;
        bondingCurve.buy{value: maxCost + 0.1 ether}(amount, maxCost);
        uint256 finalBalance = address(this).balance;

        assertEq(finalBalance, initialBalance - maxCost, "Excess ETH not refunded");
    }

    function testBuyTokensSlippageTooHigh() public {
        uint256 amount = 100;
        uint256 maxCost = 0.5 ether; // Intentionally low to trigger slippage

        vm.expectRevert("Slippage too high");
        bondingCurve.buy{value: maxCost}(amount, maxCost);
    }

    function testSellTokens() public {
        uint256 amount = 50;
        uint256 minReward = 0.5 ether;

        bondingCurve.buy{value: 1 ether}(amount, 1 ether); // Buy tokens first
        bondingCurve.sell(amount, minReward);
        assertEq(bondingCurve.balances(address(this)), 0, "Token sale failed");
    }

    function testSellTokensInsufficientBalance() public {
        uint256 amount = 50;
        uint256 minReward = 0.5 ether;

        vm.expectRevert("Insufficient token balance");
        bondingCurve.sell(amount, minReward);
    }

    function testSellTokensSlippageTooHigh() public {
        uint256 amount = 50;
        uint256 minReward = 1 ether; // Intentionally high to trigger slippage

        bondingCurve.buy{value: 1 ether}(amount, 1 ether); // Buy tokens first
        vm.expectRevert("Slippage too high");
        bondingCurve.sell(amount, minReward);
    }

    function testUpdateProtocolFee() public {
        uint256 newFee = 150;
        bondingCurve.updateProtocolFee(newFee);
        assertEq(bondingCurve.feePercentage(), newFee, "Protocol fee update failed");
    }

    function testUpdateProtocolFeeUnauthorized() public {
        uint256 newFee = 150;
        address unauthorized = address(0x4);

        vm.prank(unauthorized);
        vm.expectRevert("Not authorized");
        bondingCurve.updateProtocolFee(newFee);
    }

    function testAddLiquidity() public {
        // Simulate conditions for adding liquidity
        bondingCurve.buy{value: 200 ether}(1000, 200 ether); // Buy enough to trigger liquidity

        // Check if liquidity was added (mocked, as actual Uniswap interaction is not tested here)
        // This would require a mock or interface to simulate Uniswap behavior
    }

    function testCalculatePurchaseCost() public {
        uint256 amount = 100;
        uint256 cost = bondingCurve.calculatePurchaseCost(amount);
        assertTrue(cost > 0, "Purchase cost calculation failed");
    }

    function testCalculateSellReward() public {
        uint256 amount = 50;
        bondingCurve.buy{value: 1 ether}(amount, 1 ether); // Buy tokens first
        uint256 reward = bondingCurve.calculateSellReward(amount);
        assertTrue(reward > 0, "Sell reward calculation failed");
    }

    function testLockedLiquidity() public {
        uint256 amount = 1000;
        uint256 maxCost = 10 ether;

        // Deploy a bonding curve with locked liquidity
        BondingCurveWithDAO lockedBondingCurve = new BondingCurveWithDAO(
            uniswapRouter,
            liquidityToken,
            governance,
            targetLiquidity,
            daoQuorum,
            true // Locked liquidity
        );

        // Buy tokens to trigger liquidity addition
        lockedBondingCurve.buy{value: maxCost}(amount, maxCost);

        // Check if liquidity is locked (mocked, as actual Uniswap interaction is not tested here)
        // This would require a mock or interface to simulate Uniswap behavior
    }

    function testRedistributeFees() public {
        // Test fee redistribution logic
        bondingCurve.redistributeFees();
        // Assertions to verify redistribution
    }

    function testProposalStatusFunctions() public {
        governance.createProposal("Test proposal", 150, 0);
        assertFalse(governance.hasProposalPassed(0), "Proposal should not have passed yet");
        assertFalse(governance.isProposalExecuted(0), "Proposal should not be executed yet");
    }
} 