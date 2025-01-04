// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.28 <0.9.0;

import { Test } from "forge-std/src/Test.sol";
import { Governance } from "../src/Governance.sol";

contract GovernanceTest is Test {
    Governance governance;
    address daoToken = address(0x1);

    function setUp() public {
        governance = new Governance(daoToken, 5000);
    }

    function testCreateProposal() public {
        governance.createProposal("Update protocol fee", 150, 0);
        (,, uint256 newFee,,,) = governance.proposals(0);
        assertEq(newFee, 150, "Proposal creation failed");
    }

    function testVoteOnProposal() public {
        governance.createProposal("Update protocol fee", 150, 0);
        governance.vote(0, true);
        (, uint256 votesFor,,) = governance.proposals(0);
        assertEq(votesFor, 1, "Voting failed");
    }

    function testExecuteProposal() public {
        governance.createProposal("Update protocol fee", 150, 0);
        governance.vote(0, true);
        governance.executeProposal(0);
        (, bool executed) = governance.proposals(0);
        assertTrue(executed, "Proposal execution failed");
    }
} 