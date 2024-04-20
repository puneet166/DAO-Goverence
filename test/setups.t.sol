// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {Box} from "../src/Box.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {GovToken} from "../src/GovToken.sol";

contract GovernorTest is Test {
    MyGovernor governor;
    Box box;
    TimeLock timeLock;
    GovToken govToken;

    address public USER = makeAddr("USER");
    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 3600; // 3600 blocks mean 1 day if 12 sec per block
    uint256 public constant VOTING_DELAY = 1; // 1 block, blocks till a proposal is active
    uint256 public constant VOTING_PERIOD = 50400; //50400 blocks mean 7days if 12 sec per block// 1 week in block

    address[] public proposers;
    address[] public executors;

    uint256[] public values;
    bytes[] public calldatas;
    address[] public targets;

    function setUp() public {
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);

        vm.startPrank(USER);
        govToken.delegate(USER); // to allow ourselves to vote
        timeLock = new TimeLock(MIN_DELAY, proposers, executors, USER); // everyone can propose and execute
        governor = new MyGovernor(govToken, timeLock);

        // roles
        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();

        timeLock.grantRole(proposerRole, address(governor));
        timeLock.grantRole(executorRole, address(0)); // anyone can execute
        timeLock.revokeRole(adminRole, USER); // remove the default admin role => no more admin
        vm.stopPrank();

        box = new Box(address(this));
        box.transferOwnership(address(timeLock)); // timeLock owns the DAO and DAO owns the timeLock
            // timeLock ultimately controls the box
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        box.store(1);
    }

    function test_GovernanceUpdateBox() public {
        uint256 valueToStore = 888;
        string memory description = "store 888 in the box";
        bytes memory encodedFunctionCall = abi.encodeWithSignature("store(uint256)", valueToStore);

        values.push(0); // no value to send
        calldatas.push(encodedFunctionCall);
        targets.push(address(box));

        // 1. propose
        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        // Proposal state : 0/Pending, 1/Active, 2/Cancelled, 3/Defeated, 4/Succeeded, 5/Queued, 6/Expired, 7/Executed
        console.log("GovernorTest / Proposal state :", uint256(governor.state(proposalId)));

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);
        console.log("GovernorTest / Proposal state :", uint256(governor.state(proposalId)));

        // 2. vote
        string memory reason = "888 is froggy!";
        // support => VoteType : 0/Against, 1/For, 2/Abstain
        uint8 voteWay = 1; // for

        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);
        console.log("GovernorTest / Proposal state :", uint256(governor.state(proposalId)));

        // 3. queue
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);
        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);
        console.log("GovernorTest / Proposal state :", uint256(governor.state(proposalId)));

        // 4. execute
        governor.execute(targets, values, calldatas, descriptionHash);

        assert(box.retrieve() == valueToStore);
        console.log("GovernorTest / Box value :", box.retrieve());
    }
}
