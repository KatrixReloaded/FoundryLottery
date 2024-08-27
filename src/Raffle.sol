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

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle
 * @author KatrixReloaded
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /**
     * ERRORS
     * @notice add a prefix of the contract name to the error name so that users can identify where the revert came from
     */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__LotteryTimePending();
    error Raffle__FundsFailedToTransfer();
    error Raffle__NotOpen();

    /**
     * TYPE DECLARATIONS
     */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /**
     * STATE VARIABLES
     */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    // @dev The duration of the lottery in seconds
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /**
     * EVENTS
     */
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);

    /**
     * CONSTRUCTOR
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
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
        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        // 0.8.26 introduces including custom errors in the require statements as: require(msg.value >= i_entranceFee, SendMoreToEnterRaffle()); BUT this is not as gas efficient as using the statement above

        s_players.push(payable(msg.sender));
        // 1. Makes migrations easier
        // 2. Makes front-end "indexing" easier
        emit EnteredRaffle(msg.sender);
    }

    // 1. Generate a random number; done
    // 2. Use the random number to pick a winning player; done
    // 3. Be automatically called; remaining
    function pickWinner() external {
        if ((block.timestamp - s_lastTimeStamp) > i_interval) {
            revert Raffle__LotteryTimePending();
        }

        s_raffleState = RaffleState.CALCULATING;
        // Refer to docs.chain.link/vrf for details on what each of these values of the struct are required for
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    /// @notice in the abstract contract inherited from VRFConsumerBaseV2Plus, we have to implement the fulfillRandomWords function using the override keyword as it was declared virtual in the parent contract. virtusal keyword specifies that the  function needs to be overwritten.
    /// @notice CEI: Checks, Effects, Interactions pattern
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // Checks
        //requires, conditions, etc.

        //Effects (Internal Contract State)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner); // technically works internally, thus, bumped up to effects instead of interactions

        // Interactions (External Contract Interactions)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if(!success) {
            revert Raffle__FundsFailedToTransfer();
        }
    }

    /**
     * GETTER FUNCTIONS
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}