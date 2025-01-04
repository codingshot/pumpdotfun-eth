// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.28 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { BondingCurveWithDAO } from "../src/BondingCurveWithDAO.sol";

contract BondingCurveWithDAOTest is Test {
    BondingCurveWithDAO bondingCurve;
    address uniswapRouter = address(0x1);
    address liquidityToken = address(0x2);
    address governance = address(0x3);

    function setUp() public {
        bondingCurve = new BondingCurveWithDAO(
            uniswapRouter,
            liquidityToken,
            governance,
            100 ether,
            5000
        );
    }

    function testBuyTokens() public {
        uint256 amount = 100;
        uint256 maxCost = 1 ether;

        bondingCurve.buy{value: maxCost}(amount, maxCost);
        assertEq(bondingCurve.balances(address(this)), amount, "Token purchase failed");
    }

    function testSellTokens() public {
        uint256 amount = 50;
        uint256 minReward = 0.5 ether;

        bondingCurve.sell(amount, minReward);
        assertEq(bondingCurve.balances(address(this)), 0, "Token sale failed");
    }

    function testUpdateProtocolFee() public {
        uint256 newFee = 150;
        bondingCurve.updateProtocolFee(newFee);
        assertEq(bondingCurve.feePercentage(), newFee, "Protocol fee update failed");
    }
} 