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

    function testCreateProposalWithInvalidFee() public {
        // Test creating a proposal with an invalid fee (e.g., negative or too high)
        // Assuming the contract has a max fee limit, otherwise adjust the test
        try governance.createProposal("Invalid fee", type(uint256).max, 0) {
            fail("Expected revert due to invalid fee");
        } catch Error(string memory reason) {
            assertEq(reason, "Invalid fee", "Unexpected revert reason");
        }
    }

    function testVoteOnProposal() public {
        governance.createProposal("Update protocol fee", 150, 0);
        governance.vote(0, true);
        (, uint256 votesFor,,) = governance.proposals(0);
        assertEq(votesFor, 1, "Voting failed");
    }

    function testVoteOnNonExistentProposal() public {
        // Test voting on a non-existent proposal
        try governance.vote(999, true) {
            fail("Expected revert due to non-existent proposal");
        } catch Error(string memory reason) {
            assertEq(reason, "Proposal does not exist", "Unexpected revert reason");
        }
    }

    function testExecuteProposal() public {
        governance.createProposal("Update protocol fee", 150, 0);
        governance.vote(0, true);
        governance.executeProposal(0);
        (, bool executed) = governance.proposals(0);
        assertTrue(executed, "Proposal execution failed");
    }

    function testExecuteProposalWithoutVotes() public {
        // Test executing a proposal without any votes
        governance.createProposal("Update protocol fee", 150, 0);
        try governance.executeProposal(0) {
            fail("Expected revert due to no votes");
        } catch Error(string memory reason) {
            assertEq(reason, "Not enough votes", "Unexpected revert reason");
        }
    }

    function testExecuteAlreadyExecutedProposal() public {
        // Test executing an already executed proposal
        governance.createProposal("Update protocol fee", 150, 0);
        governance.vote(0, true);
        governance.executeProposal(0);
        try governance.executeProposal(0) {
            fail("Expected revert due to already executed proposal");
        } catch Error(string memory reason) {
            assertEq(reason, "Proposal already executed", "Unexpected revert reason");
        }
    }
} 