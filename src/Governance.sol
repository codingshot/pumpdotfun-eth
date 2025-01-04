// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Governance is ReentrancyGuard {
    address public daoToken;
    uint256 public daoQuorum;
    uint256 public nextProposalId;

    struct Proposal {
        address proposer;
        string description;
        uint256 newFee;
        uint256 newQuorum;
        uint256 endTime;
        uint256 snapshotId;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        uint256 endTime,
        uint256 snapshotId
    );
    event ProposalExecuted(uint256 indexed proposalId, bool approved);
    event ProposalRejected(uint256 indexed proposalId);
    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);

    constructor(address _daoToken, uint256 _initialQuorum) {
        require(_initialQuorum > 0 && _initialQuorum <= 10000, "Invalid quorum");
        daoToken = _daoToken;
        daoQuorum = _initialQuorum;
    }

    function createProposal(
        string memory _description,
        uint256 _newFee,
        uint256 _newQuorum
    ) external {
        require(IERC20(daoToken).balanceOf(msg.sender) > 0, "Must hold governance tokens");
        require(
            (_newFee > 0 && _newQuorum == 0) || (_newFee == 0 && _newQuorum > 0),
            "Only one parameter can be updated"
        );

        uint256 snapshotId = ERC20Votes(daoToken).getPastVotes(msg.sender, block.number - 1);

        proposals[nextProposalId] = Proposal({
            proposer: msg.sender,
            description: _description,
            newFee: _newFee,
            newQuorum: _newQuorum,
            endTime: block.timestamp + 3 days,
            snapshotId: snapshotId,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });

        emit ProposalCreated(nextProposalId, msg.sender, _description, block.timestamp + 3 days, snapshotId);
        nextProposalId++;
    }

    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.endTime, "Voting ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");

        uint256 voterWeight = ERC20Votes(daoToken).getPastVotes(msg.sender, proposal.snapshotId);
        require(voterWeight > 0, "No governance tokens at snapshot");

        hasVoted[_proposalId][msg.sender] = true;
        if (_support) {
            proposal.votesFor += voterWeight;
        } else {
            proposal.votesAgainst += voterWeight;
        }
    }

    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumThreshold = (ERC20Votes(daoToken).totalSupply() * daoQuorum) / 10000;

        if (proposal.votesFor > proposal.votesAgainst && totalVotes >= quorumThreshold) {
            if (proposal.newFee > 0) {
                FactoryOrBondingCurve(proposal.proposer).updateProtocolFee(proposal.newFee);
            }
            if (proposal.newQuorum > 0) {
                emit QuorumUpdated(daoQuorum, proposal.newQuorum);
                daoQuorum = proposal.newQuorum;
            }
            emit ProposalExecuted(_proposalId, true);
        } else {
            emit ProposalRejected(_proposalId);
        }

        proposal.executed = true;
    }

    function hasProposalPassed(uint256 _proposalId) external view returns (bool) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumThreshold = (ERC20Votes(daoToken).totalSupply() * daoQuorum) / 10000;
        return proposal.votesFor > proposal.votesAgainst && totalVotes >= quorumThreshold;
    }

    function isProposalExecuted(uint256 _proposalId) external view returns (bool) {
        return proposals[_proposalId].executed;
    }
}

interface FactoryOrBondingCurve {
    function updateProtocolFee(uint256 newFee) external;
}
