# CryptoDemonz, Slot machine 

## resultOf
``` javascript
function resultOf(address player) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](3);

        result[0] = results[addressToRequestId[player]].left;
        result[1] = results[addressToRequestId[player]].center;
        result[2] = results[addressToRequestId[player]].right;

        return result;
    }
```

## getRandomNumber
``` javascript
    function getRandomNumber(address player) public {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK.");
        bytes32 requestId = requestRandomness(keyHash, fee);
        addressToRequestId[player] = requestId;
        requestIdToAddress[requestId] = player;

        emit RequestIdIsCreated(player, requestId);
    }
```

## fulfillRandomness
``` javascript
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
```

# calculatePrize
``` javascript
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

        delete currency[player];
    }
```

## placeBet
``` javascript
function placeBet() external {
        _LLTH.transferFrom(msg.sender, address(this), betAmount);
        bets[msg.sender] = betAmount;
        currency[msg.sender] = "LLTH";
        getRandomNumber(msg.sender);
    }
```

## withdraw
``` javascript

    function withdraw(uint256 amount) external onlyOwner {
        require(_LLTH.balanceOf(address(this)) >= amount);
        require(
            betAmount <= _LLTH.balanceOf(address(this)),
            "Not enough LLTH in game's wallet to play."
        );

        _LLTH.transfer(owner(), amount);
    }
```
