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


import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";


/**
 * @title Raffle
 * @author KatrixReloaded
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerV2Plus {
    /**
     * ERRORS
     * @notice add a prefix of the contract name to the error name so that users can identify where the revert came from
     */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__LotteryTimePending();

    /**
     * STATE VARIABLES
     */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    // @dev The duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    /**
     * EVENTS
     */
    event EnteredRaffle(address indexed player);

    /**
     * CONSTRUCTOR
     */
    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    /**
     * FUNCTIONS
     */
    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        // using custom errors is more efficient cost-wise
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        // 0.8.26 introduces including custom errors in the require statements as: require(msg.value >= i_entranceFee, SendMoreToEnterRaffle()); BUT this is not as gas efficient as using the statement above

        s_players.push(payable(msg.sender));
        // 1. Makes migrations easier
        // 2. Makes front-end "indexing" easier
        emit EnteredRaffle(msg.sender);
    }

    // 1. Generate a random number
    // 2. Use the random number to pick a winning player
    // 3. Be automatically called
    function pickWinner() external returns{
        if((block.timestamp - s_lastTimeStamp > i_interval) {
            revert Raffle__LotteryTimePending();
        }
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
    }

    /**
     * GETTER FUNCTIONS
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
