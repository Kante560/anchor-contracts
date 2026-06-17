// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title AnchorV2 — On-Chain Escrow on Base with Arbitration
/// @notice Trustless freelance payment protocol with dispute resolution
contract AnchorV2 {

    // ─── Types ───────────────────────────────────────────────
    enum Status { Active, Approved, Disputed, Refunded, Resolved }

    struct Job {
        address client;
        address freelancer;
        uint256 amount;
        uint256 deadline;
        Status  status;
    }

    // ─── Storage ─────────────────────────────────────────────
    mapping(uint256 => Job) public jobs;
    uint256 public jobCount;
    address public immutable arbitrator;

    // ─── Events ──────────────────────────────────────────────
    event JobCreated(
        uint256 indexed jobId,
        address indexed client,
        address indexed freelancer,
        uint256 amount,
        uint256 deadline
    );
    event WorkApproved(uint256 indexed jobId, address freelancer, uint256 amount);
    event DisputeRaised(uint256 indexed jobId, address raisedBy);
    event RefundClaimed(uint256 indexed jobId, address client, uint256 amount);
    event DisputeResolved(uint256 indexed jobId, address winner, uint256 amount);

    // ─── Errors ──────────────────────────────────────────────
    error NotAuthorized();
    error NotClient();
    error NotActive();
    error NotDisputed();
    error NotArbitrator();
    error DeadlineNotPassed();
    error DeadlinePassed();
    error ZeroValue();
    error InvalidFreelancer();
    error InvalidArbitrator();

    // ─── Modifiers ───────────────────────────────────────────
    modifier onlyClient(uint256 jobId) {
        if (msg.sender != jobs[jobId].client) revert NotClient();
        _;
    }

    modifier onlyActive(uint256 jobId) {
        if (jobs[jobId].status != Status.Active) revert NotActive();
        _;
    }

    modifier onlyDisputed(uint256 jobId) {
        if (jobs[jobId].status != Status.Disputed) revert NotDisputed();
        _;
    }

    modifier onlyArbitrator() {
        if (msg.sender != arbitrator) revert NotArbitrator();
        _;
    }

    // ─── Constructor ─────────────────────────────────────────
    constructor(address _arbitrator) {
        if (_arbitrator == address(0)) revert InvalidArbitrator();
        arbitrator = _arbitrator;
    }

    // ─── Functions ───────────────────────────────────────────

    /// @notice Client creates a job and locks ETH as escrow
    function createJob(
        address _freelancer,
        uint256 _deadline
    ) external payable returns (uint256 jobId) {
        if (msg.value == 0) revert ZeroValue();
        if (_freelancer == address(0) || _freelancer == msg.sender)
            revert InvalidFreelancer();
        if (_deadline <= block.timestamp) revert DeadlinePassed();

        jobId = ++jobCount;
        jobs[jobId] = Job({
            client:     msg.sender,
            freelancer: _freelancer,
            amount:     msg.value,
            deadline:   _deadline,
            status:     Status.Active
        });

        emit JobCreated(jobId, msg.sender, _freelancer, msg.value, _deadline);
    }

    /// @notice Client approves work — releases ETH to freelancer instantly
    function approveWork(uint256 jobId)
        external onlyClient(jobId) onlyActive(jobId)
    {
        Job storage job = jobs[jobId];
        job.status = Status.Approved;

        (bool ok,) = job.freelancer.call{value: job.amount}("");
        require(ok, "Transfer failed");

        emit WorkApproved(jobId, job.freelancer, job.amount);
    }

    /// @notice Client or Freelancer raises a dispute — freezes funds pending resolution
    function raiseDispute(uint256 jobId) external onlyActive(jobId) {
        Job storage job = jobs[jobId];
        if (msg.sender != job.client && msg.sender != job.freelancer) {
            revert NotAuthorized();
        }
        
        job.status = Status.Disputed;
        emit DisputeRaised(jobId, msg.sender);
    }

    /// @notice Arbitrator resolves a dispute, favoring client or freelancer
    function resolveDispute(uint256 jobId, bool favorClient)
        external onlyArbitrator onlyDisputed(jobId)
    {
        Job storage job = jobs[jobId];
        job.status = Status.Resolved;
        
        address winner = favorClient ? job.client : job.freelancer;

        (bool ok,) = winner.call{value: job.amount}("");
        require(ok, "Transfer failed");

        emit DisputeResolved(jobId, winner, job.amount);
    }

    /// @notice Client reclaims ETH after deadline passes with no approval and no dispute
    function claimRefund(uint256 jobId)
        external onlyClient(jobId) onlyActive(jobId)
    {
        Job storage job = jobs[jobId];
        if (block.timestamp <= job.deadline) revert DeadlineNotPassed();
        job.status = Status.Refunded;

        (bool ok,) = job.client.call{value: job.amount}("");
        require(ok, "Transfer failed");

        emit RefundClaimed(jobId, job.client, job.amount);
    }

    /// @notice Read full job details
    function getJob(uint256 jobId) external view returns (Job memory) {
        return jobs[jobId];
    }
}
