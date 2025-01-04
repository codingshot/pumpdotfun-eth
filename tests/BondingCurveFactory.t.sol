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

    // New test cases for 100% coverage

    function testDeployBondingCurveInvalidRouter() public {
        // Test with invalid Uniswap router address
        vm.expectRevert("Invalid Uniswap router");
        factory.deployBondingCurve(
            address(0),
            address(0x5),
            address(0x6),
            100 ether,
            5000
        );
    }

    function testDeployBondingCurveInvalidLiquidityToken() public {
        // Test with invalid liquidity token address
        vm.expectRevert("Invalid liquidity token");
        factory.deployBondingCurve(
            address(0x4),
            address(0),
            address(0x6),
            100 ether,
            5000
        );
    }

    function testDeployBondingCurveInvalidGovernanceToken() public {
        // Test with invalid governance token address
        vm.expectRevert("Invalid governance token");
        factory.deployBondingCurve(
            address(0x4),
            address(0x5),
            address(0),
            100 ether,
            5000
        );
    }

    function testDeployBondingCurveInvalidQuorum() public {
        // Test with invalid DAO quorum
        vm.expectRevert("Invalid DAO quorum");
        factory.deployBondingCurve(
            address(0x4),
            address(0x5),
            address(0x6),
            100 ether,
            0
        );
    }

    function testUpdateProtocolFeeExceedsLimit() public {
        // Test updating protocol fee beyond the limit
        uint256 excessiveFee = 1100;
        governance.createProposal("Excessive protocol fee", excessiveFee, 0);
        governance.vote(0, true);
        vm.expectRevert("Fee exceeds max limit");
        governance.executeProposal(0);
    }

    function testUpdateProtocolFeeRecipient() public {
        // Test updating the protocol fee recipient
        address newRecipient = address(0x7);
        governance.createProposal("Update fee recipient", 0, newRecipient);
        governance.vote(0, true);
        governance.executeProposal(0);

        assertEq(factory.protocolFeeRecipient(), newRecipient, "Protocol fee recipient update failed");
    }

    function testUpdateProtocolFeeRecipientInvalid() public {
        // Test updating the protocol fee recipient to an invalid address
        governance.createProposal("Invalid fee recipient", 0, address(0));
        governance.vote(0, true);
        vm.expectRevert("Invalid recipient address");
        governance.executeProposal(0);
    }

    function testTriggerEmergencyMode() public {
        // Test triggering emergency mode
        factory.triggerEmergencyMode();
        // Assuming governance has a method to check emergency status
        assertTrue(governance.isEmergency(), "Emergency mode not triggered");
    }

    function testGetDeployedBondingCurves() public {
        // Test retrieving deployed bonding curves
        address[] memory curves = factory.getDeployedBondingCurves(admin);
        assertEq(curves.length, 0, "Deployed bonding curves list should be empty initially");
    }

    function testGetAllBondingCurves() public {
        // Test retrieving all deployed bonding curves
        address[] memory allCurves = factory.getAllBondingCurves();
        assertEq(allCurves.length, 0, "All bonding curves list should be empty initially");
    }
} 