// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZephyriaCommunityFunds is ERC20, Ownable {
    uint256 public constant MINIMUM_VOTERS = 1000;
    uint256 public constant MINIMUM_TOKEN_AMOUNT = 0.01 ether;
    address public predefinedAddr;
    uint256 public proposalCount;

    struct Proposal {
        string description;
        uint256 funds;
        uint256 voteCount;
        bool executed;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed proposalId, string description, uint256 funds);
    event Voted(address indexed voter, uint256 indexed proposalId);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address _predefinedAddr) ERC20("Zephyria Community", "ZEELC") Ownable(_predefinedAddr) {
        predefinedAddr = _predefinedAddr;
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Initial supply of 1,000,000 ZC tokens
    }

    function createProposal(string memory description, uint256 funds) external onlyOwner {
        require(funds >= MINIMUM_TOKEN_AMOUNT, "Funds must be at least 0.01 ETH");

        Proposal storage proposal = proposals[proposalCount++];
        proposal.description = description;
        proposal.funds = funds;
        proposal.voteCount = 0;
        proposal.executed = false;

        emit ProposalCreated(proposalCount - 1, description, funds);
    }

    function vote(uint256 proposalId) external payable {
        require(proposalId < proposalCount, "Invalid proposal ID");
        require(msg.value == MINIMUM_TOKEN_AMOUNT, "You must send exactly 0.01 ETH");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.voters[msg.sender], "You have already voted");
        require(!proposal.executed, "Proposal already executed");

        proposal.voters[msg.sender] = true;
        proposal.voteCount++;

        // Mint and transfer Zephyria Community token as a reward
        _mint(msg.sender, 1 * 10 ** decimals());

        emit Voted(msg.sender, proposalId);
    }

    function executeProposal(uint256 proposalId) external onlyOwner {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount >= MINIMUM_VOTERS, "Not enough votes");

        proposal.executed = true;
        payable(predefinedAddr).transfer(proposal.funds);

        emit ProposalExecuted(proposalId);
    }

    // Fallback function to accept ETH
    receive() external payable {}
}
