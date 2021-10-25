/**
 *   _____________   _______ _____ ___________ ________  ________ _   _ ______
 *  /  __ | ___ \ \ / | ___ |_   _|  _  |  _  |  ___|  \/  |  _  | \ | |___  /
 *  | /  \| |_/ /\ V /| |_/ / | | | | | | | | | |__ |      | | | |  \| |  / /
 *  | |   |    /  \ / |  __/  | | | | | | | | |  __|| |\/| | | | |     | / /
 *  \ \__/| |\ \  | | | |     | | \ \_/ | |/ /| |___| |  | \ \_/ | |\  |/ /___
 *   \____\_| \_| \_/ \_|     \_/  \___/|___/ \____/\_|  |_/\___/\_| \_\_____/
 *
 *
 *  #CryptoDemonz, Slot Machine
 *
 *  This game has 3 circular, independently operated reels.
 *  A series of 6 different symbols (1, 2, 3, 4, 5, 6) is put on each reel.
 *  The player places a certain amount of bet and starts the round. During the game,
 *  reels are spinning & spinning then they stop at a random symbol.
 *  There are a series of rules on which results payout and how much.
 *  Different combinations offer different payouts.
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Slots is Ownable, VRFConsumerBase {
    using SafeMath for uint256;
    using Address for address;

    // three symbols that appears as result or winning result
    // symbols can be integers between 1 and 6
    struct Combination {
        uint256 left;
        uint256 center;
        uint256 right;
    }

    // each winning result has a multiplier for calculating the player's winning amount
    struct Multiplier {
        uint256 first; // multiplier for result: 6-6-6
        uint256 second; // multiplier for these results: 5-5-5, 4-4-4, 3-3-3, 2-2-2, 1-1-1
        uint256 third; // multiplier for these results: 6-6-x, 6-x-6, x-6-6
        uint256 fourth; // multiplier for these results: 6-x-x, x-6-x, x-x-6
    }

    // instance of $LLTH token
    IERC20 internal _LLTH;

    // multipliers that are used for calculating the prize
    Multiplier public multiplier;

    // fixed amount of $LLTH tokens that a player can place as bet for a spin
    uint256 public betAmount = 10 * 10**18;

    // fee required to fulfill a VRF request
    uint256 public fee;

    // max value on a reel
    uint256 public maxSymbolValue = 6;

    // min value on a reel
    uint256 public minSymbolValue = 1;

    // public key against which randomness is generated
    bytes32 public keyHash;

    // the address of the smart contract which verifies if the numbers returned from Chainlink are actually random
    address public VRFCoordinator = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;

    // LINK token's address
    address public LINKToken = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // players' dedicated result by reqest ID that appears in the end of a spin
    mapping(bytes32 => Combination) public results;

    // players' bet amount in a spin
    mapping(address => uint256) public bets;

    // mapping of player's address to requestId
    mapping(address => bytes32) public addressToRequestId;

    // mapping of requestId to player's address
    mapping(bytes32 => address) public requestIdToAddress;

    // mapping of requestId to the returned random number
    mapping(bytes32 => uint256[]) public requestIdToRandomNumbers;

    // sending random numbers for front-end
    event RandomsAreArrived(bytes32 requestId, uint256[] randomNumbers);

    // sending request ID for front-end
    event RequestIdIsCreated(address player, bytes32 requestId);

    // sending the calculated prize of player for front-end
    event PrizeOfPlayer(bytes32 requestId, uint256 amount);

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    constructor(address LLTH_) VRFConsumerBase(VRFCoordinator, LINKToken) {
        _LLTH = IERC20(LLTH_);
        multiplier = Multiplier(20, 5, 4, 1);
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10**18; // 0.0001 LINK
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getBetAmount() external view returns (uint256) {
        return betAmount;
    }

    function resultOf(address player) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](3);

        result[0] = results[addressToRequestId[player]].left;
        result[1] = results[addressToRequestId[player]].center;
        result[2] = results[addressToRequestId[player]].right;

        return result;
    }

    function betOf(address player) external view returns (uint256) {
        return bets[player];
    }

    //-------------------------------------------------------------------------
    // SET FUNCTIONS
    //-------------------------------------------------------------------------

    function setLLTH(address LLTH_) external onlyOwner {
        _LLTH = IERC20(LLTH_);
    }

    function setMultiplier(
        uint256 first_,
        uint256 second_,
        uint256 third_,
        uint256 fourth_
    ) external onlyOwner {
        multiplier = Multiplier(first_, second_, third_, fourth_);
    }

    function setBetAmount(uint256 betAmount_) external onlyOwner {
        betAmount = betAmount_;
    }

    function setMaxSymbolValue(uint256 maxSymbolValue_) external onlyOwner {
        maxSymbolValue = maxSymbolValue_;
    }

    function setMinSymbolValue(uint256 minSymbolValue_) external onlyOwner {
        minSymbolValue = minSymbolValue_;
    }

    //-------------------------------------------------------------------------
    // RANDOM NUMBER FUNCTIONS
    //-------------------------------------------------------------------------

    function getRandomNumber(address player) public {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK.");
        bytes32 requestId = requestRandomness(keyHash, fee);
        addressToRequestId[player] = requestId;
        requestIdToAddress[requestId] = player;

        emit RequestIdIsCreated(player, requestId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256[] memory randomNumbers = new uint256[](3);
        uint256 randomNumber = (randomness %
            (maxSymbolValue.add(1) - minSymbolValue)) + minSymbolValue; // random number between 1 and 6
        randomNumbers[0] = randomNumber;

        // getting 2 more random numbers out of 1 truly random
        for (uint256 i = 1; i < randomNumbers.length; i++) {
            randomNumbers[i] = uint256(
                (uint256(keccak256(abi.encode(randomNumber, i))) %
                    (maxSymbolValue.add(1) - minSymbolValue)) + minSymbolValue
            );
        }
        requestIdToRandomNumbers[requestId] = randomNumbers;
        Combination memory result = Combination(
            randomNumbers[0],
            randomNumbers[1],
            randomNumbers[2]
        );
        results[requestId] = result;

        calculatePrize(requestId);

        emit RandomsAreArrived(requestId, randomNumbers);
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    function calculatePrize(bytes32 requestId) internal {
        require(
            requestIdToAddress[requestId] != address(0),
            "Player cannot be null address."
        );
        address player = requestIdToAddress[requestId];

        // 6-6-6
        // --> Pays: 20x
        if (
            results[requestId].left == 6 &&
            results[requestId].center == 6 &&
            results[requestId].right == 6
        ) {
            _LLTH.transfer(player, bets[player].mul(multiplier.first));

            emit PrizeOfPlayer(requestId, bets[player].mul(multiplier.first));
        }
        // 5-5-5, 4-4-4, 3-3-3, 2-2-2, 1-1-1
        // --> Pays: 5x
        else if (
            results[requestId].left == results[requestId].center &&
            results[requestId].left == results[requestId].right &&
            results[requestId].left != 6
        ) {
            _LLTH.transfer(player, bets[player].mul(multiplier.second));

            emit PrizeOfPlayer(requestId, bets[player].mul(multiplier.second));
        }
        // 6-6-x, 6-x-6, x-6-6
        // --> Pays: 4x
        else if (
            (results[requestId].left == 6 &&
                results[requestId].center == 6 &&
                results[requestId].right != 6) ||
            // ----------------------------------
            (results[requestId].left == 6 &&
                results[requestId].center != 6 &&
                results[requestId].right == 6) ||
            // ----------------------------------
            (results[requestId].left != 6 &&
                results[requestId].center == 6 &&
                results[requestId].right == 6)
        ) {
            _LLTH.transfer(player, bets[player].mul(multiplier.third));

            emit PrizeOfPlayer(requestId, bets[player].mul(multiplier.third));
        }
        // 6-x-x, x-6-x, x-x-6
        // --> Pays: 1x
        else if (
            (results[requestId].left == 6 &&
                results[requestId].center != 6 &&
                results[requestId].right != 6) ||
            // ----------------------------------
            (results[requestId].left != 6 &&
                results[requestId].center == 6 &&
                results[requestId].right != 6) ||
            // ----------------------------------
            (results[requestId].left != 6 &&
                results[requestId].center != 6 &&
                results[requestId].right == 6)
        ) {
            _LLTH.transfer(player, bets[player].mul(multiplier.fourth));

            emit PrizeOfPlayer(requestId, bets[player].mul(multiplier.fourth));
        } else {
            emit PrizeOfPlayer(requestId, 0);
        }
    }

    //-------------------------------------------------------------------------
    // EXTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    function placeBet() external {
        _LLTH.transferFrom(msg.sender, address(this), betAmount);
        bets[msg.sender] = betAmount;
        getRandomNumber(msg.sender);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(_LLTH.balanceOf(address(this)) >= amount);

        _LLTH.transfer(owner(), amount);
    }
}
