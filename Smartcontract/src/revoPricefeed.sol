// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract CustomPriceFeed is Ownable, AggregatorV3Interface {
    int256 private price; // Price of TOKEN/ETH (e.g., 0.05 ETH per RVL, scaled by 10^8)
    uint80 private roundId = 1; // Mock round ID
    uint256 private lastUpdateTimestamp;
    uint8 public constant override decimals = 8; // Standard for ETH-based Chainlink feeds
    string public tokenPair; // e.g., "RVL/ETH", "DAI/ETH"
    address public dao; // DAO address for price updates

    // Events
    event PriceUpdated(int256 newPrice, uint80 roundId, uint256 timestamp);
    event DaoSet(address newDao);

    constructor(address _owner, string memory _tokenPair, int256 _initialPrice) Ownable(_owner) {
        require(_initialPrice > 0, "Initial price must be positive");
        price = _initialPrice;
        tokenPair = _tokenPair;
        lastUpdateTimestamp = block.timestamp;
    }

    function setDao(address _dao) external onlyOwner {
        require(_dao != address(0), "Invalid DAO address");
        dao = _dao;
        emit DaoSet(_dao);
    }

    function setPrice(int256 _newPrice) external {
        require(msg.sender == owner() || msg.sender == dao, "Unauthorized");
        require(_newPrice > 0, "Price must be positive");
        price = _newPrice;
        roundId++;
        lastUpdateTimestamp = block.timestamp;
        emit PriceUpdated(_newPrice, roundId, lastUpdateTimestamp);
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 _roundId,
            int256 _price,
            uint256 _startedAt,
            uint256 _timestamp,
            uint80 _answeredInRound
        )
    {
        require(lastUpdateTimestamp >= block.timestamp - 1 hours, "Price data stale");
        return (roundId, price, 0, lastUpdateTimestamp, roundId);
    }

    function description() external view override returns (string memory) {
        return tokenPair;
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 _returnRoundId,
            int256 _price,
            uint256 _startedAt,
            uint256 _timestamp,
            uint80 _answeredInRound
        )
    {
        require(_roundId <= roundId, "Invalid round ID");
        return (_roundId, price, 0, lastUpdateTimestamp, _roundId);
    }
}