// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Anchor.sol";

contract AnchorTest is Test {
    Anchor anchor;
    address client     = makeAddr("client");
    address freelancer = makeAddr("freelancer");
    address stranger   = makeAddr("stranger");
    uint256 deadline;

    function setUp() public {
        anchor   = new Anchor();
        deadline = block.timestamp + 7 days;
        vm.deal(client, 10 ether);
    }

    function testCreateJob() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        Anchor.Job memory job = anchor.getJob(jobId);
        assertEq(job.client,     client);
        assertEq(job.freelancer, freelancer);
        assertEq(job.amount,     1 ether);
        assertEq(uint(job.status), uint(Anchor.Status.Active));
    }

    function testApproveWork() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        uint256 before = freelancer.balance;
        vm.prank(client);
        anchor.approveWork(jobId);

        assertEq(freelancer.balance, before + 1 ether);
        assertEq(uint(anchor.getJob(jobId).status), uint(Anchor.Status.Approved));
    }

    function testRaiseDispute() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.prank(client);
        anchor.raiseDispute(jobId);

        assertEq(uint(anchor.getJob(jobId).status), uint(Anchor.Status.Disputed));
        assertEq(address(anchor).balance, 1 ether);
    }

    function testClaimRefund_AfterDeadline() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        uint256 before = client.balance;
        vm.warp(deadline + 1);
        vm.prank(client);
        anchor.claimRefund(jobId);

        assertEq(client.balance, before + 1 ether);
        assertEq(uint(anchor.getJob(jobId).status), uint(Anchor.Status.Refunded));
    }

    function testClaimRefund_BeforeDeadline() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.expectRevert(Anchor.DeadlineNotPassed.selector);
        vm.prank(client);
        anchor.claimRefund(jobId);
    }

    function testApproveWork_NotClient() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.expectRevert(Anchor.NotClient.selector);
        vm.prank(stranger);
        anchor.approveWork(jobId);
    }

    function testApproveWork_AlreadyApproved() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.prank(client);
        anchor.approveWork(jobId);

        vm.expectRevert(Anchor.NotActive.selector);
        vm.prank(client);
        anchor.approveWork(jobId);
    }

    function testCreateJob_ZeroValue() public {
        vm.expectRevert(Anchor.ZeroValue.selector);
        vm.prank(client);
        anchor.createJob{value: 0}(freelancer, deadline);
    }

    function testCreateJob_SelfFreelancer() public {
        vm.expectRevert(Anchor.InvalidFreelancer.selector);
        vm.prank(client);
        anchor.createJob{value: 1 ether}(client, deadline);
    }

    function testDisputedJob_CannotRefund() public {
        vm.prank(client);
        uint256 jobId = anchor.createJob{value: 1 ether}(freelancer, deadline);

        vm.prank(client);
        anchor.raiseDispute(jobId);

        vm.warp(deadline + 1);
        vm.expectRevert(Anchor.NotActive.selector);
        vm.prank(client);
        anchor.claimRefund(jobId);
    }
}