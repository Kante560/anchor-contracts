// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AnchorV2.sol";

contract AnchorV2Test is Test {
    AnchorV2 anchor;
    address client     = makeAddr("client");
    address freelancer = makeAddr("freelancer");
    address stranger   = makeAddr("stranger");
    address arbitrator = makeAddr("arbitrator");
    uint256 deadline;

    function setUp() public {
        anchor   = new AnchorV2(arbitrator);
        deadline = block.timestamp + 7 days;
        vm.deal(client, 10 ether);
    }

    function testConstructorRevertsIfZeroAddress() public {
        vm.expectRevert(AnchorV2.InvalidArbitrator.selector);
        new AnchorV2(address(0));
    }

    function testArbitratorSet() public view {
        assertEq(anchor.arbitrator(), arbitrator);
    }

    function testCreateJob() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        AnchorV2.Job memory job = anchor.getJob(jobId);
        assertEq(job.client,     client);
        assertEq(job.freelancer, freelancer);
        assertEq(job.amount,     1 ether);
        assertEq(uint(job.status), uint(AnchorV2.Status.Active));
    }

    function testApproveWork() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        uint256 before = freelancer.balance;
        vm.prank(client);
        anchor.approveWork(jobId);

        assertEq(freelancer.balance, before + 1 ether);
        assertEq(uint(anchor.getJob(jobId).status), uint(AnchorV2.Status.Approved));
    }

    function testRaiseDisputeByClient() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.prank(client);
        anchor.raiseDispute(jobId);

        assertEq(uint(anchor.getJob(jobId).status), uint(AnchorV2.Status.Disputed));
        assertEq(address(anchor).balance, 1 ether);
    }

    function testRaiseDisputeByFreelancer() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.prank(freelancer);
        anchor.raiseDispute(jobId);

        assertEq(uint(anchor.getJob(jobId).status), uint(AnchorV2.Status.Disputed));
        assertEq(address(anchor).balance, 1 ether);
    }

    function testRaiseDisputeByStrangerReverts() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.expectRevert(AnchorV2.NotAuthorized.selector);
        vm.prank(stranger);
        anchor.raiseDispute(jobId);
    }

    function testResolveDisputeFavorClient() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.prank(client);
        anchor.raiseDispute(jobId);

        uint256 before = client.balance;

        vm.prank(arbitrator);
        anchor.resolveDispute(jobId, true);

        assertEq(client.balance, before + 1 ether);
        assertEq(uint(anchor.getJob(jobId).status), uint(AnchorV2.Status.Resolved));
    }

    function testResolveDisputeFavorFreelancer() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.prank(freelancer);
        anchor.raiseDispute(jobId);

        uint256 before = freelancer.balance;

        vm.prank(arbitrator);
        anchor.resolveDispute(jobId, false);

        assertEq(freelancer.balance, before + 1 ether);
        assertEq(uint(anchor.getJob(jobId).status), uint(AnchorV2.Status.Resolved));
    }

    function testResolveDisputeNotArbitratorReverts() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.prank(client);
        anchor.raiseDispute(jobId);

        vm.expectRevert(AnchorV2.NotArbitrator.selector);
        vm.prank(client);
        anchor.resolveDispute(jobId, true);
    }

    function testResolveDisputeNotDisputedReverts() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.expectRevert(AnchorV2.NotDisputed.selector);
        vm.prank(arbitrator);
        anchor.resolveDispute(jobId, true);
    }

    function testClaimRefund_AfterDeadline() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        uint256 before = client.balance;
        vm.warp(deadline + 1);
        vm.prank(client);
        anchor.claimRefund(jobId);

        assertEq(client.balance, before + 1 ether);
        assertEq(uint(anchor.getJob(jobId).status), uint(AnchorV2.Status.Refunded));
    }

    function testClaimRefund_BeforeDeadline() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.expectRevert(AnchorV2.DeadlineNotPassed.selector);
        vm.prank(client);
        anchor.claimRefund(jobId);
    }

    function testApproveWork_NotClient() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.expectRevert(AnchorV2.NotClient.selector);
        vm.prank(stranger);
        anchor.approveWork(jobId);
    }

    function testApproveWork_AlreadyApproved() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.prank(client);
        anchor.approveWork(jobId);

        vm.expectRevert(AnchorV2.NotActive.selector);
        vm.prank(client);
        anchor.approveWork(jobId);
    }

    function testCreateJob_ZeroValue() public {
        vm.expectRevert(AnchorV2.ZeroValue.selector);
        vm.prank(client);
        anchor.createJob{value: 0}(freelancer, deadline);
    }

    function testCreateJob_SelfFreelancer() public {
        vm.expectRevert(AnchorV2.InvalidFreelancer.selector);
        vm.prank(client);
        anchor.createJob{value: 1 ether}(client, deadline);
    }

    function testDisputedJob_CannotRefund() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.prank(client);
        anchor.raiseDispute(jobId);

        vm.warp(deadline + 1);
        vm.expectRevert(AnchorV2.NotActive.selector);
        vm.prank(client);
        anchor.claimRefund(jobId);
    }
}
