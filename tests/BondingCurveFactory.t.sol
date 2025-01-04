// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.28 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { BondingCurveFactory } from "../src/BondingCurveFactory.sol";
import { Governance } from "../src/Governance.sol";

contract BondingCurveFactoryTest is Test {
    BondingCurveFactory factory;
    Governance governance;
    address admin = address(0x1);
    address daoToken = address(0x2);
    address protocolFeeRecipient = address(0x3);

    function setUp() public {
        governance = new Governance(daoToken, 5000);
        factory = new BondingCurveFactory(200, protocolFeeRecipient, daoToken, 5000);
    }

    function testDeployBondingCurve() public {
        address uniswapRouter = address(0x4);
        address liquidityToken = address(0x5);
        address governanceToken = address(0x6);
        uint256 targetLiquidity = 100 ether;
        uint256 daoQuorum = 5000;

        address bondingCurve = factory.deployBondingCurve(
            uniswapRouter,
            liquidityToken,
            governanceToken,
            targetLiquidity,
            daoQuorum
        );

        assertTrue(bondingCurve != address(0), "Bonding curve deployment failed");
    }

    function testToggleGovernance() public {
        factory.toggleGovernance();
        assertTrue(factory.useDAO(), "Governance toggle failed");
    }

    function testUpdateProtocolFee() public {
        uint256 newFee = 150;
        governance.createProposal("Update protocol fee", newFee, 0);
        governance.vote(0, true);
        governance.executeProposal(0);

        assertEq(factory.protocolFee(), newFee, "Protocol fee update failed");
    }
} 