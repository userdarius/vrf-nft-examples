// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRF} from "src/GelatoVRF.sol";

// This contract is an example contract that uses GelatoVRF to
// demonstrate the ways of integrating GelatoVRF into your own contracts.
// This contract is not audited and should not be used in production.
contract GelatoLottery {
    address public deployer;
    address[] public players;
    LotteryState public state;
    uint256 public lotteryStartTime;
    uint256 public lotteryEndTime;
    uint256 public lotteryDuration;
    uint256 public minDepositAmount;
    address public previousWinner;

    VRF public vrf;

    enum LotteryState {
        NOTRUNNING,
        RUNNING
    }

    event LotteryStarted(uint256 startTime, uint256 endTime, address LotteryDeployer);
    event WinnerSelected(address indexed winner, uint256 amount);
    event LotteryEnded(uint256 timestamp);

    constructor(address _vrf, uint256 _lotteryDuration, uint256 _minDepositAmount) {
        vrf = VRF(_vrf);
        deployer = msg.sender;
        state = LotteryState.NOTRUNNING;
        lotteryDuration = _lotteryDuration;
        minDepositAmount = _minDepositAmount;
    }

    function startLottery() public {
        require(state == LotteryState.NOTRUNNING, "Lottery is already running");
        state = LotteryState.RUNNING;
        lotteryStartTime = block.timestamp;
        lotteryEndTime = block.timestamp + lotteryDuration;
        emit LotteryStarted(lotteryStartTime, lotteryEndTime, deployer);
    }

    function endLotteryIfNoOneJoins() public {
        require(state == LotteryState.RUNNING, "Lottery is not running");
        require(block.timestamp >= lotteryEndTime, "Lottery time has not ended");
        require(players.length == 0, "No players in the lottery");
        players = new address[](0);
        state = LotteryState.NOTRUNNING;
        emit LotteryEnded(block.timestamp);
    }

    function enter() public payable {
        require(msg.value >= minDepositAmount, "Please deposit the minimum amount required");
        require(state == LotteryState.RUNNING, "Lottery is not running");
        require(block.timestamp < lotteryEndTime, "Lottery entry time has ended");

        players.push(msg.sender);
    }

    function pickWinner() public {
        require(state == LotteryState.RUNNING, "Lottery is not running");
        require(block.timestamp >= lotteryEndTime, "Lottery time has not ended");
        require(players.length > 0, "No players in the lottery");

        uint256 randomWinner = vrf.getRandom("gelatoLottery") % players.length;
        address winner = players[randomWinner];
        previousWinner = winner;
        uint256 amountWon = address(this).balance;
        payable(winner).transfer(amountWon);

        emit WinnerSelected(winner, amountWon);
        emit LotteryEnded(block.timestamp);

        players = new address[](0);
        state = LotteryState.NOTRUNNING;
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function getLotteryTimes() public view returns (uint256 startTime, uint256 endTime) {
        if (state == LotteryState.NOTRUNNING) {
            return (0, 0);
        } else {
            return (lotteryStartTime, lotteryEndTime);
        }
    }

    function getLotteryManager() public view returns (address LotteryDeployer) {
        if (state == LotteryState.NOTRUNNING) {
            return address(0);
        } else {
            return deployer;
        }
    }

    function getPreviousWinner() public view returns (address) {
        return previousWinner;
    }
}