// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @title Raffle
 * @author KatrixReloaded
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */  
contract Raffle {
    uint256 private immutable i_entranceFee;

    /** CONSTRUCTOR */
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    /** FUNCTIONS */
    function enterRaffle() public payable {}

    function pickWinner() public {}

    /** GETTER FUNCTIONS */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}